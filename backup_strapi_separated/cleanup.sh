#!/bin/bash
source config.sh

cleanup_local_backups() {
    echo "🧹 Cleaning old local backups (keeping last $KEEP_LOCAL_BACKUPS)..."
    cd "$BACKUP_DIR"
    ls -t ${BACKUP_BASE_NAME}_*.tar.gz 2>/dev/null | tail -n +$((KEEP_LOCAL_BACKUPS + 1)) | while read -r backup_file; do
        echo "🗑️  Deleting old local backup: $backup_file"
        rm -f "$backup_file"
    done
}

cleanup_uncompressed() {
    # Optional: Remove uncompressed version
    if [ -d "$BACKUP_DIR/$DATE" ] && [ -f "$BACKUP_FILE" ]; then
        echo "🧹 Cleaning up uncompressed backup folder..."
        rm -rf "$BACKUP_DIR/$DATE"
    fi
}