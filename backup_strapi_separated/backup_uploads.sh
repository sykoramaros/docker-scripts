#!/bin/bash
source config.sh

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

backup_uploads() {
    echo "📸 Backing up upload files..."
    if [ -d "backend-strapi/public/uploads" ]; then
        if tar czf "$BACKUP_DIR/$DATE/uploads_$DATE.tar.gz" -C "backend-strapi/public" uploads/; then
            echo "✅ Upload files backed up"
            return 0
        else
            BACKUP_SUCCESS=false
            ERROR_MESSAGES="$ERROR_MESSAGES\n- Upload files backup failed"
            echo "❌ Error backing up upload files"
            return 1
        fi
    else
        echo "ℹ️  Uploads directory not found, skipping..."
        return 0
    fi
}

backup_docker_config() {
    echo "🐳 Backing up Docker configuration..."
    if ! cp "docker-compose.yml" "$BACKUP_DIR/$DATE/"; then
        BACKUP_SUCCESS=false
        ERROR_MESSAGES="$ERROR_MESSAGES\n- Docker configuration backup failed"
        echo "❌ Error copying docker-compose.yml"
        return 1
    fi
    echo "✅ Docker configuration backed up"
    return 0
}