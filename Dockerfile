ARG platform=intel
ARG release=latest
FROM kinetica/kinetica-${platform}:${release}

COPY start_node.sh /

CMD ["/bin/sh", "/start_node.sh"]