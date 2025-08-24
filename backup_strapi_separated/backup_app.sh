#!/bin/bash
source config.sh

backup_application() {
    echo "📁 Backing up application files..."
    if ! rsync -av --exclude='node_modules' \
              --exclude='*.log' \
              --exclude='.git' \
              --exclude='tmp' \
              --exclude='backups' \
              "$PROJECT_DIR/" "$BACKUP_DIR/$DATE/app/"; then
        BACKUP_SUCCESS=false
        ERROR_MESSAGES="$ERROR_MESSAGES\n- Application files backup failed"
        echo "❌ Error backing up application files"
        return 1
    fi
    echo "✅ Application files backed up successfully"
    return 0
}

create_restore_readme() {
    echo "📋 Creating restore README..."
    cat > "$BACKUP_DIR/$DATE/RESTORE_README.md" << EOF
# Strapi Portfolio Backup Restoration

Backup date: $DATE

## Restoration steps:

1. Copy the 'app/' folder to target location
2. Run docker-compose up -d to create containers
3. Import database:
   \`\`\`bash
   docker exec -i $DB_CONTAINER mysql -u $DB_USER -p$DB_PASS $DB_NAME < database_$DATE.sql
   \`\`\`
4. Extract upload files (if needed):
   \`\`\`bash
   tar xzf uploads_$DATE.tar.gz -C app/backend-strapi/public/
   \`\`\`

## Backup contents:
- Application files: app/
- Database: database_$DATE.sql
- Upload files: uploads_$DATE.tar.gz
- Docker configuration: docker-compose.yml
EOF
    echo "✅ Restore README created"
}