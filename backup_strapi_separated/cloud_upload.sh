#!/bin/bash
source config.sh

cloud_upload() {
    if [ "$ENABLE_CLOUD_BACKUP" != true ]; then
        echo "ℹ️  Cloud backup is disabled"
        return 0
    fi

    if [ ! -f "$BACKUP_FILE" ]; then
        CLOUD_BACKUP_SUCCESS=false
        ERROR_MESSAGES="$ERROR_MESSAGES\n- Backup file doesn't exist for cloud upload"
        return 1
    fi

    echo "☁️  Uploading backup to Google Drive..."
    
    if ! command -v rclone &> /dev/null; then
        CLOUD_BACKUP_SUCCESS=false
        ERROR_MESSAGES="$ERROR_MESSAGES\n- rclone not installed for cloud backup"
        echo "⚠️  rclone not installed. Skipping cloud backup."
        echo "💡 For installation run: curl https://rclone.org/install.sh | sudo bash"
        return 1
    fi

    # Create folder in Google Drive (if it doesn't exist)
    rclone mkdir "$GDRIVE_REMOTE:$GDRIVE_FOLDER" 2>/dev/null
    
    # Upload backup
    if rclone copy "$BACKUP_FILE_PATH" "$GDRIVE_REMOTE:$GDRIVE_FOLDER/" --progress; then
        echo "✅ Backup successfully uploaded to Google Drive"
        echo "📁 Cloud location: $CLOUD_BACKUP_PATH"
        return 0
    else
        CLOUD_BACKUP_SUCCESS=false
        ERROR_MESSAGES="$ERROR_MESSAGES\n- Google Drive upload failed"
        echo "❌ Error uploading to Google Drive"
        echo "ℹ️  Local backup is still available"
        return 1
    fi
}

cleanup_cloud_backups() {
    if [ "$ENABLE_CLOUD_BACKUP" = true ] && command -v rclone &> /dev/null; then
        echo "🧹 Cleaning old cloud backups (keeping last $KEEP_CLOUD_BACKUPS)..."
        rclone ls "$GDRIVE_REMOTE:$GDRIVE_FOLDER/" | grep "$BACKUP_BASE_NAME" | sort -k2 -r | tail -n +$((KEEP_CLOUD_BACKUPS + 1)) | while read size filename; do
            echo "🗑️  Deleting old cloud backup: $filename"
            rclone delete "$GDRIVE_REMOTE:$GDRIVE_FOLDER/$filename"
        done
    fi
}

# 🚀 MAIN EXECUTION - CALL THE FUNCTIONS
cloud_upload
cleanup_cloud_backups