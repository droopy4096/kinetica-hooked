ARG platform=intel
ARG release=latest
FROM kinetica/kinetica-${platform}:${release}

COPY gpudb-docker-start.sh /opt/gpudb-docker-start.sh
RUN mkdir -p /docker-entrypoint-initdb.d

VOLUME ["/docker-entrypoint-initdb.d"]
# CMD ["/bin/sh", "/start_node.sh"]