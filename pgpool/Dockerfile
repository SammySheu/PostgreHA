FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install pgpool2 and required packages in a single RUN to reduce image layers
RUN apt-get update && apt-get install -y \
    pgpool2 \
    vim \
    postgresql-client \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY wait-for-db.sh /wait-for-db.sh
RUN chmod +x /wait-for-db.sh

ENTRYPOINT ["/wait-for-db.sh"]
CMD ["pgpool", "-n"]
# CMD ["tail", "-f", "/dev/null"]