FROM debian:bookworm-slim

# Install net-snmp daemon and tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends snmpd snmp \
    && rm -rf /var/lib/apt/lists/*

# Default configuration via environment variables
ENV REMOTE_HOST= \
    REMOTE_PORT=161 \
    REMOTE_COMMUNITY=public \
    PROXY_OID=.1.3.6.1.2.1 \
    RO_COMMUNITY=public \
    RO_SOURCE=0.0.0.0/0 \
    SYS_LOCATION="Docker SNMP Proxy" \
    SYS_CONTACT="admin@example.com" \
    LISTEN_ADDRESSES="udp:0.0.0.0:161"

# Copy entrypoint that renders snmpd.conf from env
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# SNMP uses UDP/161
EXPOSE 161/udp

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["snmpd", "-f", "-Lo", "-c", "-C", "/etc/snmp/snmpd.conf"]

