#!/bin/sh

for i in /docker-entrypoint-initdb.d/*.sh
do
  . ${i}
done

ldconfig && /opt/gpudb-docker-start.sh
