#!/bin/bash
set -e

# Wait for PostgreSQL to be ready
until pg_isready -U postgres; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 1
done

# Modify pg_hba.conf
cat >> "${PGDATA}/pg_hba.conf" << EOF
host replication ${DB_REP_USER} 0.0.0.0/0 scram-sha-256
EOF

# Modify postgresql.conf
cat >> "${PGDATA}/postgresql.conf" << EOF
# Replication settings
wal_level = replica
max_wal_senders = 10
hot_standby = on

# WAL settings
wal_keep_size = '1GB'

# Connection settings
listen_addresses = '*'
max_connections = 100

# Authentication
password_encryption = 'scram-sha-256'
EOF

# Reload PostgreSQL configuration
pg_ctl reload