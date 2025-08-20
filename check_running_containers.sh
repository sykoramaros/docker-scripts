#!/bin/bash

# Docker Container Health Check and Auto-Restart Script
# Usage: ./check_all_containers.sh

# Configuration
LOG_FILE="/var/log/docker_container_check.log"
EMAIL_TO="your-email@example.com"  # Change to your email address

# Function for logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    log_message "❌ ERROR: Docker is not installed or not in PATH"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    log_message "❌ ERROR: Docker is not running"
    exit 1
fi

log_message "🔍 Starting check of ALL Docker containers..."

# Get list of ALL containers (running and stopped)
ALL_CONTAINERS=($(docker ps -a --format "{{.Names}}"))

if [ ${#ALL_CONTAINERS[@]} -eq 0 ]; then
    log_message "ℹ️  No Docker containers found on the system"
    exit 0
fi

log_message "📋 Found ${#ALL_CONTAINERS[@]} containers: ${ALL_CONTAINERS[*]}"

RESTARTED_COUNT=0
CHECKED_COUNT=0
RESTARTED_CONTAINERS=()

for CONTAINER in "${ALL_CONTAINERS[@]}"; do
    ((CHECKED_COUNT++))
    
    # Get container status
    CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        log_message "⚠️  Container '$CONTAINER' does not exist - skipped"
        continue
    fi
    
    if [ "$CONTAINER_STATUS" = "running" ]; then
        log_message "✅ Container '$CONTAINER' is already running"
    else
        log_message "⚠️  Container '$CONTAINER' is not running (status: $CONTAINER_STATUS). Attempting to start..."
        
        # Start container
        if docker start "$CONTAINER" >/dev/null 2>&1; then
            log_message "✅ Container '$CONTAINER' successfully started"
            ((RESTARTED_COUNT++))
            RESTARTED_CONTAINERS+=("$CONTAINER")
            
            # Short pause for stabilization
            sleep 2
        else
            log_message "❌ Failed to start container '$CONTAINER'"
        fi
    fi
done

# Summary
log_message "📊 Check completed: $CHECKED_COUNT containers checked, $RESTARTED_COUNT restarted"

# Send email notification if any containers were restarted
if [ "$RESTARTED_COUNT" -gt 0 ] && [ -n "$EMAIL_TO" ]; then
    # Prepare list of restarted containers
    RESTARTED_LIST=""
    for container in "${RESTARTED_CONTAINERS[@]}"; do
        RESTARTED_LIST="${RESTARTED_LIST}📦 ${container}"$'\n'
    done
    
    cat << EOF | mail -s "🔄 Docker containers restarted on $(hostname)" "$EMAIL_TO"
Date: $(date)
Server: $(hostname)

$RESTARTED_COUNT Docker containers were restarted because they were not running.

📋 List of restarted containers:
$RESTARTED_LIST
Total containers on system: ${#ALL_CONTAINERS[@]}

Details in log file: $LOG_FILE

This is an automated message from your Docker monitoring system.
EOF
fi

exit 0
