#! /usr/bin/env bash

set -o nounset
set -o errexit

MINIMUM_GPU_MEMORY=${MINIMUM_GPU_MEMORY:-1000}

if ! [[ "$MINIMUM_GPU_MEMORY" =~ ^[0-9]+$ ]]; then
    echo "ERROR: MINIMUM_GPU_MEMORY (${MINIMUM_GPU_MEMORY}) must be a positive number!" >&2
    exit 1
fi

# Switch to the gpudb user (without --login) so that we do not lose our environment in the /opt/gpudb/core/bin/gpudb script
if [ "$(whoami)" != "gpudb" ]; then
    su gpudb -c "$0 $@"
fi

GPUDB_DIR="/opt/gpudb"
PERSIST_DIR="${GPUDB_DIR}/persist"

for i in /docker-entrypoint-initdb.d/*.sh
do
  [ -x "${i}" ] && . ${i}
done

DATE="$(date +%Y-%m-%d_%H-%M-%S)"

CONF="${GPUDB_DIR}/core/etc/gpudb.conf"
CONF_BACKUP="${GPUDB_DIR}/core/etc/gpudb-upgrade-backup-${DATE}.conf"
CONF_TEMPLATE="${CONF}.template"
PERSIST_BACKUP_CONF="${PERSIST_DIR}/gpudb/rank-0/gpudb.conf.bak"
PERSIST_CONF="${PERSIST_DIR}/gpudb.conf"

if [ -f "${PERSIST_CONF}" ] && diff "${CONF}" "${CONF_TEMPLATE}" >/dev/null 2>&1; then
    cp -f "${CONF}" "${CONF_BACKUP}"
    ${GPUDB_DIR}/core/bin/gpudb_env.sh ${GPUDB_DIR}/core/bin/gpudb_config_compare.py "${PERSIST_CONF}" "${CONF_TEMPLATE}" "${CONF}"
elif [ -f "${PERSIST_BACKUP_CONF}" ] && diff "${CONF}" "${CONF_TEMPLATE}" >/dev/null 2>&1; then
    cp -f "${PERSIST_BACKUP_CONF}" "/tmp/gpudb-backup.conf"
    ${GPUDB_DIR}/core/bin/gpudb_env.sh ${GPUDB_DIR}/core/bin/gpudb_config_compare.py "/tmp/gpudb-backup.conf" "${CONF_TEMPLATE}" "${CONF}"
fi

if which nvidia-smi >/dev/null 2>&1; then
    ALL_DEVICES="$(nvidia-smi --query-gpu=index,memory.free,name,pci.bus_id --format=csv,nounits,noheader)"
    AVAILABLE_DEVICES="$(echo "${ALL_DEVICES}" | sed 's/,//g' | sort -k2nr,2 -k1bn,1 | awk "{if (\$2 >= $MINIMUM_GPU_MEMORY) print}")"
    MEMORY_CONSTRAINED_DEVICES="$(echo "${ALL_DEVICES}" | sed 's/,//g' | awk "{if (\$2 < $MINIMUM_GPU_MEMORY) print}")"

    export CUDA_VISIBLE_DEVICES=$(echo "$AVAILABLE_DEVICES" | cut -d' ' -f 1 | tr '\n' ',' | sed 's/,$//g')

    if [ -n "$ALL_DEVICES" ]; then
        echo "Found the following cuda devices:"
        echo
        echo "Index, Free Memory (MB), Name, PCI Bus ID"
        echo "$ALL_DEVICES"
        echo

        if [ -n "$AVAILABLE_DEVICES" ]; then
            echo "The following devices meet the free memory requirement of ${MINIMUM_GPU_MEMORY} MB (in order of most free memory to least):"
            echo
            echo "ID, Free Memory (MB), Name, PCI Bus ID"
            echo "${AVAILABLE_DEVICES}"
            echo
            if [ -n "${MEMORY_CONSTRAINED_DEVICES}" ]; then
                echo "WARNING: The following devices do not meet the minimum available RAM requirement of ${MINIMUM_GPU_MEMORY} MB." >&2
                echo "         To change the requirement, add '-e MINIMUM_GPU_MEMORY=xxx' to your docker run command, where xxx is" >&2
                echo "         the number of MB." >&2
                echo >&2
                echo "ID, Free Memory (MB), Name, PCI Bus ID" >&2
                echo "${MEMORY_CONSTRAINED_DEVICES}" >&2
                echo >&2
            fi
            echo "Setting CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"
            echo
        else
            echo "WARNING: There are no devices that meet the minimum free memory requirement of ${MINIMUM_GPU_MEMORY} MB." >&2
            echo
        fi
    else
        echo "WARNING: No CUDA devices were found.  Not setting CUDA_VISIBLE_DEVICES." >&2
    fi
fi

if ! /etc/init.d/gpudb_host_manager start; then
    RET=$?
    echo "ERROR: Cannot start gpudb_host_manager (exit code: $RET)." >&2
    exit $RET
fi

if ( [ "${FULL_START:-}" == "1" ] || [ "${FULL_START:-}" == "TRUE" ] ) && ! /etc/init.d/gpudb start; then
    RET=$?
    echo "ERROR: Cannot start gpudb (exit code: $RET)." >&2
    exit $RET
fi

while true; do
    sleep 30
done
