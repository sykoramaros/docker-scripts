#!/bin/bash
# Main backup orchestrator

# Load all modules
source config.sh
source backup_app.sh
source backup_database.sh
source backup_uploads.sh
source compress_backup.sh
source cloud_upload.sh
source cleanup.sh
source email_notifications.sh

# Set error handling
set -e

main() {
    echo "🚀 Starting $APP_NAME backup - $DATE"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR/$DATE"
    
    # Execute backup steps
    backup_application
    create_restore_readme
    backup_database
    backup_uploads
    backup_docker_config
    compress_backup
    cloud_upload
    cleanup_cloud_backups
    cleanup_local_backups
    cleanup_uncompressed
    
    # Send report
    send_backup_report
    
    # Display summary
    echo ""
    echo "📋 Backup summary:"
    echo "   📅 Date: $DATE"
    if [ -f "$BACKUP_FILE" ]; then
        echo "   📦 Size: $(ls -lh "$BACKUP_FILE" | awk '{print $5}')"
        echo "   💾 Local: $BACKUP_FILE"
    fi
    if [ "$ENABLE_CLOUD_BACKUP" = true ] && [ "$CLOUD_BACKUP_SUCCESS" = true ] && command -v rclone &> /dev/null; then
        echo "   ☁️  Cloud: $CLOUD_BACKUP_PATH"
    fi

    if [ "$BACKUP_SUCCESS" = false ]; then
        echo "   ❌ Status: ERRORS DURING BACKUP"
        exit 1
    else
        echo "   ✅ Status: COMPLETED"
        exit 0
    fi
}

# Run main function
main "$@"