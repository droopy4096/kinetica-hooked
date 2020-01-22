#!/bin/sh

for i in /etc/gpudb_hooks/start/*.sh
do
  . ${i}
done

ldconfig && /opt/gpudb-docker-start.sh

for i in /etc/gpudb_hooks/stop/*.sh
do
  . ${i}
done