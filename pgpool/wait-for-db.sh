#!/bin/bash
set -e

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

check_retry_count() {
    local RETRY_COUNT=$1
    local MAX_RETRY=10
    local failed_db_host=$2
    
    if [ $RETRY_COUNT -eq $MAX_RETRY ]; then
        log_message "ERROR: Maximum retry for checking DB($failed_db_host) reached"
        exit 3
    fi
}

check_database_connection() {
    local host=$1
    local port=$2
    local RETRY_COUNT=0
    
    log_message "Checking connection to $host:$port"
    
    until pg_isready -h "$host" -p "$port" -q; do
        check_retry_count $RETRY_COUNT "$host"
        RETRY_COUNT=$((RETRY_COUNT+1))
        log_message "Waiting for $host to be online... Attempt: $RETRY_COUNT"
        sleep 3
    done
    
    log_message "Successfully connected to $host"
}

main() {
    # Define database hosts
    local db_hosts=(
        "postgres-primary:5432"
        "postgres-replica:5432"
    )
    
    # Check each database host
    for host_port in "${db_hosts[@]}"; do
        IFS=: read -r host port <<< "$host_port"
        check_database_connection "$host" "$port"
    done
    
    log_message "All database hosts are online"
    
    # Start pgpool if no other command is provided
    if [ $# -eq 0 ]; then
        log_message "Starting pgpool"
        exec pgpool -n
    else
        log_message "Executing provided command: $*"
        exec "$@"
    fi
}

main "$@"