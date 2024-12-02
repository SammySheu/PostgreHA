FROM postgres:17

RUN apt-get update && apt-get install -y vim netcat-openbsd ssh \
    && rm -rf /var/lib/apt/lists/*

# Copy initialization scripts
COPY init-db.sh /docker-entrypoint-initdb.d/
COPY master-replication-setup.sh /docker-entrypoint-initdb.d/

# Make scripts executable
RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh \
    && chmod +x /docker-entrypoint-initdb.d/master-replication-setup.sh

# Use default PostgreSQL entrypoint
# Use the default entrypoint (don't override it)
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]
# CMD ["tail", "-f", "/dev/null"]
