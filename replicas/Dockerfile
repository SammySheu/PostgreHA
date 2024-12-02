FROM postgres:17
RUN apt-get update && apt-get install -y vim netcat-openbsd

COPY init-replica-server.sh /init-replica-server.sh
RUN chmod +x /init-replica-server.sh

# Override the default entrypoint
ENTRYPOINT ["/init-replica-server.sh"]
