#!/bin/bash
set -e

# Add logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

set_correct_folder_permission() {
    log_message "Setting correct folder permissions..."
    
    # Verify PGDATA is set
    if [ -z "${PGDATA}" ]; then
        log_message "ERROR: PGDATA environment variable is not set"
        exit 1
    fi

    # Create PGDATA directory if it doesn't exist
    if [ ! -d "${PGDATA}" ]; then
        log_message "Creating PGDATA directory: ${PGDATA}"
        mkdir -p "${PGDATA}"
    fi

    log_message "Setting permissions on ${PGDATA}"
    chmod 700 "${PGDATA}"
}


wait_for_master() {
    log_message "Waiting for primary database..."
    RETRY_COUNT=0
    until nc -z "${PRIMARY_DB_HOST}" "${PRIMARY_DB_PORT}"; do
        check_retry_count $RETRY_COUNT
        RETRY_COUNT=$((RETRY_COUNT+1))
        log_message "Waiting for primary postgres (${PRIMARY_DB_HOST}) to connect... Attempt: $RETRY_COUNT"
        sleep 3
    done
    log_message "Primary database is reachable"
}

check_retry_count() {
    RETRY_COUNT=$1
    MAX_RETRY=10
    if [ $RETRY_COUNT -eq $MAX_RETRY ]; then
        log_message "ERROR: Maximum retry count reached"
        exit 3
    fi
}

take_basebackup() {
    log_message "Starting basebackup process..."
    
    # Check if PGDATA exists
    if [ ! -d "${PGDATA}" ]; then
        log_message "Creating PGDATA directory..."
        mkdir -p "${PGDATA}"
    fi

    log_message "Cleaning PGDATA directory..."
    rm -rf "${PGDATA:?}"/*
    
    log_message "Taking basebackup from primary..."
    export PGPASSWORD="${PRIMARY_DB_REP_PASS}"
    
    # Add verbose flag for more information
    pg_basebackup -v -h "${PRIMARY_DB_HOST}" -p "${PRIMARY_DB_PORT}" \
                 -U "${PRIMARY_DB_REP_USER}" -D "${PGDATA}" \
                 -X stream -P -R \
                 --write-recovery-conf \
                 --progress
    
    if [ $? -eq 0 ]; then
        log_message "Basebackup completed successfully"
    else
        log_message "ERROR: Basebackup failed"
        exit 1
    fi
    
    unset PGPASSWORD
}

configure_replica() {
    log_message "Configuring replica settings..."
    
    # Backup existing postgresql.auto.conf if it exists
    if [ -f "${PGDATA}/postgresql.auto.conf" ]; then
        cp "${PGDATA}/postgresql.auto.conf" "${PGDATA}/postgresql.auto.conf.bak"
    fi

    # Write replica configuration
    cat > "${PGDATA}/postgresql.auto.conf" << EOF
# Replication settings
primary_conninfo = 'host=${PRIMARY_DB_HOST} port=${PRIMARY_DB_PORT} user=${PRIMARY_DB_REP_USER} password=${PRIMARY_DB_REP_PASS} application_name=walreceiver'
hot_standby = on
EOF

    # Create standby.signal file
    touch "${PGDATA}/standby.signal"
    log_message "Replica configuration completed"
}

main() {
    log_message "Starting replica initialization process..."
    
    # Check environment variables
    if [ -z "${PRIMARY_DB_HOST}" ] || [ -z "${PRIMARY_DB_PORT}" ] || \
       [ -z "${PRIMARY_DB_REP_USER}" ] || [ -z "${PRIMARY_DB_REP_PASS}" ]; then
        log_message "ERROR: Required environment variables are not set"
        exit 1
    fi

    # Check if this is a fresh instance
    if [ ! -f "${PGDATA}/PG_VERSION" ]; then
        log_message "Fresh instance detected, setting up replica..."
        set_correct_folder_permission
        wait_for_master
        take_basebackup
        configure_replica
        log_message "Replica setup completed"
    else
        log_message "Existing installation found"
        
        # 檢查是否為複製庫設定
        if [ ! -f "${PGDATA}/standby.signal" ]; then
            log_message "Configuring existing instance as replica..."
            configure_replica
        else
            log_message "Instance already configured as replica"
        fi
        
        # 確保權限正確
        set_correct_folder_permission
    fi

    # 不管是新設定還是舊設定，都啟動 PostgreSQL
    log_message "Starting PostgreSQL in replica mode..."
    exec postgres
}


main "$@"