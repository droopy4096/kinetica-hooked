ARG platform=intel
ARG release=latest
FROM kinetica/kinetica-${platform}:${release}

COPY gpudb-docker-start.sh /opt/gpudb-docker-start.sh

VOLUME ["/docker-entrypoint-initdb.d"]
# CMD ["/bin/sh", "/start_node.sh"]