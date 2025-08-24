#!/bin/bash
source config.sh

compress_backup() {
    echo "🗜️  Compressing entire backup..."
    cd "$BACKUP_DIR"
    if tar czf "$BACKUP_FILENAME" "$DATE/"; then
    BACKUP_FILE="$BACKUP_FILE_PATH"
        echo "✅ Backup successfully compressed"
        echo "📊 Backup size: $(ls -lh "$BACKUP_FILE" | awk '{print $5}')"
        return 0
    else
        BACKUP_SUCCESS=false
        ERROR_MESSAGES="$ERROR_MESSAGES\n- Backup compression failed"
        echo "❌ Error compressing backup"
        return 1
    fi
}

# 🚀 MAIN EXECUTION - CALL THE FUNCTIONS
compress_backup