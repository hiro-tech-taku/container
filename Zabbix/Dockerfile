# Simple Zabbix Manager (all-in-one) based on the official Zabbix Appliance
# This image includes Zabbix Server, Web UI (NGINX + PHP-FPM), and an embedded DB.

FROM zabbix/zabbix-appliance:alpine-latest

# Set timezone for the OS and PHP (Web UI)
ENV TZ=Asia/Tokyo \
    PHP_TZ=Asia/Tokyo

# Web UI and Zabbix server ports
EXPOSE 80 10051

# The base image defines its own entrypoint/CMD to start all services via supervisor.
# No further commands required for a basic setup.

