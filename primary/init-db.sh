#!/bin/bash
set -e

# Wait for PostgreSQL to be ready
until pg_isready; do
    echo "Waiting for PostgreSQL to start..."
    sleep 1
done

# First create postgres superuser if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'postgres') THEN
            CREATE ROLE postgres WITH SUPERUSER LOGIN;
        END IF;
    END
    \$\$;
    
    -- Create replication user
    CREATE USER ${DB_REP_USER} REPLICATION LOGIN PASSWORD '${DB_REP_PASS}';
EOSQL