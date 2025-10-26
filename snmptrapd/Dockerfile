FROM debian:bookworm-slim

# Install snmptrapd and tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends snmptrapd snmp zabbix-sender ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Defaults via environment variables
ENV LISTEN_ADDRESSES="udp:0.0.0.0:162" \
    TRAP_COMMUNITY=public \
    TRAP_SOURCE= \
    DISABLE_AUTH=no \
    ZBX_SERVER= \
    ZBX_PORT=10051 \
    ZBX_HOST= \
    ZBX_KEY=snmptrap \
    ZBX_FORWARD=auto

# Copy default config and entrypoint
COPY snmptrapd.conf /etc/snmp/snmptrapd.conf
COPY docker-entrypoint.sh /usr/local/bin/snmptrapd-entrypoint.sh
COPY zbx-trap-forwarder.sh /usr/local/bin/zbx-trap-forwarder.sh
RUN chmod +x /usr/local/bin/zbx-trap-forwarder.sh
RUN chmod +x /usr/local/bin/snmptrapd-entrypoint.sh

# SNMP traps use UDP/162
EXPOSE 162/udp

ENTRYPOINT ["/usr/local/bin/snmptrapd-entrypoint.sh"]
CMD ["snmptrapd", "-f", "-Lo"]
