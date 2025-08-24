# Backup script for Strapi Portfolio with Google Drive and email notifications
# Usage: ./backup_strapi.sh

# Variable settings
BACKUP_DIR="/var/Docker/Portfolio/backups"
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT_DIR="."
DB_CONTAINER="strapi_mariadb"
DB_NAME="strapi_database"
DB_USER="strapi_user"
DB_PASS="your_secure_password_here"

# MariaDB specific tools
DB_CLIENT="mariadb"
DUMP_CLIENT="mariadb-dump"

# Google Drive settings
GDRIVE_REMOTE="gdrive"
GDRIVE_FOLDER="strapi-portfolio-backups"
ENABLE_CLOUD_BACKUP=true
KEEP_LOCAL_BACKUPS=5   # Number of local backups to keep
KEEP_CLOUD_BACKUPS=3   # Number of cloud backups to keep (less due to space)

# EMAIL SETTINGS
ENABLE_EMAIL_NOTIFICATIONS=true
EMAIL_TO="your-email@example.com"  # Change to your email
EMAIL_FROM="backup@server.local"
EMAIL_SUBJECT_SUCCESS="✅ Strapi Portfolio - Backup Successful"
EMAIL_SUBJECT_ERROR="❌ Strapi Portfolio - Backup Failed"
SERVER_NAME=$(hostname)

# Function for sending emails
send_email() {
    local subject="$1"
    local message="$2"
    local is_error="$3"
    
    if [ "$ENABLE_EMAIL_NOTIFICATIONS" = true ]; then
        # Create email content
        local email_body="Date: $(date)
Server: $SERVER_NAME
        
$message"
        
        # Attempt to send email using various methods
        if command -v mail &> /dev/null; then
            echo "$email_body" | mail -s "$subject" "$EMAIL_TO"
        elif command -v mailx &> /dev/null; then
            echo "$email_body" | mailx -s "$subject" "$EMAIL_TO"
        elif command -v sendmail &> /dev/null; then
            {
             	echo "To: $EMAIL_TO"
                echo "From: $EMAIL_FROM"
                echo "Subject: $subject"
                echo ""
                echo "$email_body"
            } | sendmail "$EMAIL_TO"
        else
            echo "⚠️  No email client available (mail, mailx, sendmail)"
            return 1
        fi
        
       	if [ $? -eq 0 ]; then
            echo "📧 Email notification sent to $EMAIL_TO"
        else
            echo "❌ Error sending email notification"
        fi
    fi
}

# Variables for tracking status
BACKUP_SUCCESS=true
ERROR_MESSAGES=""

# Create backup directory
mkdir -p "$BACKUP_DIR/$DATE"

echo "🚀 Starting Strapi Portfolio backup - $DATE"

# 1. Backup application files
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
fi

# 2. Database backup
echo "🗄️  Backing up database..."

# First check if container is running
if ! docker ps | grep -q $DB_CONTAINER; then
    echo "⚠️  Container $DB_CONTAINER not running. Starting Docker Compose..."
    if ! docker-compose up -d; then
        BACKUP_SUCCESS=false
        ERROR_MESSAGES="$ERROR_MESSAGES\n- Docker container startup failed"
        echo "❌ Error starting Docker containers"
    else
        echo "⏳ Waiting 30 seconds for database to start..."
        sleep 30
    fi
fi

echo "🔧 Using MariaDB tools"

# Attempt database backup
DB_BACKUP_SUCCESS=false
echo "💾 Backing up database: $DB_NAME"
if docker exec $DB_CONTAINER $DUMP_CLIENT -u $DB_USER -p$DB_PASS $DB_NAME > "$BACKUP_DIR/$DATE/database_$DATE.sql" 2>/dev/null; then
    if [ -s "$BACKUP_DIR/$DATE/database_$DATE.sql" ]; then
        echo "✅ Database successfully backed up ($DB_NAME)"
        DB_BACKUP_SUCCESS=true
    fi
fi

if [ "$DB_BACKUP_SUCCESS" = false ]; then
    echo "❌ Error backing up database. Trying all databases..."
    
    # Backup all databases as last resort
    if docker exec $DB_CONTAINER $DUMP_CLIENT -u $DB_USER -p$DB_PASS --all-databases > "$BACKUP_DIR/$DATE/database_all_$DATE.sql" 2>/dev/null; then
        if [ -s "$BACKUP_DIR/$DATE/database_all_$DATE.sql" ]; then
            echo "✅ Backed up all databases as fallback"
            rm -f "$BACKUP_DIR/$DATE/database_$DATE.sql" 2>/dev/null
            DB_BACKUP_SUCCESS=true
        fi
    fi
    
    if [ "$DB_BACKUP_SUCCESS" = false ]; then
        BACKUP_SUCCESS=false
        ERROR_MESSAGES="$ERROR_MESSAGES\n- Database backup failed"
        echo "❌ Failed to backup database"
        echo "ℹ️  Continuing without database backup..."
        rm -f "$BACKUP_DIR/$DATE/database_$DATE.sql" "$BACKUP_DIR/$DATE/database_all_$DATE.sql" 2>/dev/null
    fi
fi

# 3. Upload files backup (extra precaution)
echo "📸 Backing up upload files..."
if [ -d "backend-strapi/public/uploads" ]; then
    if tar czf "$BACKUP_DIR/$DATE/uploads_$DATE.tar.gz" -C "backend-strapi/public" uploads/; then
        echo "✅ Upload files backed up"
    else
        BACKUP_SUCCESS=false
        ERROR_MESSAGES="$ERROR_MESSAGES\n- Upload files backup failed"
        echo "❌ Error backing up upload files"
    fi
fi

# 4. Copy docker-compose.yml
echo "🐳 Backing up Docker configuration..."
if ! cp "docker-compose.yml" "$BACKUP_DIR/$DATE/"; then
    BACKUP_SUCCESS=false
    ERROR_MESSAGES="$ERROR_MESSAGES\n- Docker configuration backup failed"
    echo "❌ Error copying docker-compose.yml"
fi

# 5. Create README with restore information
cat > "$BACKUP_DIR/$DATE/RESTORE_README.md" << EOF
# Strapi Portfolio Backup Restoration

Backup date: $DATE

## Restoration steps:

1. Copy the 'app/' folder to target location
2. Run docker-compose up -d to create containers
3. Import database:
   \`\`\`bash
   docker exec -i strapi_mariadb mysql -u $DB_USER -p$DB_PASS $DB_NAME < database_$DATE.sql
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

# 6. Create compressed backup
echo "🗜️  Compressing entire backup..."
cd "$BACKUP_DIR"
if tar czf "strapi_portfolio_backup_$DATE.tar.gz" "$DATE/"; then
    BACKUP_FILE="$BACKUP_DIR/strapi_portfolio_backup_$DATE.tar.gz"
    echo "✅ Backup successfully compressed"
else
    BACKUP_SUCCESS=false
    ERROR_MESSAGES="$ERROR_MESSAGES\n- Backup compression failed"
    echo "❌ Error compressing backup"
fi

# 7. Upload to Google Drive
CLOUD_BACKUP_SUCCESS=true
if [ "$ENABLE_CLOUD_BACKUP" = true ] && [ -f "$BACKUP_FILE" ]; then
    echo "☁️  Uploading backup to Google Drive..."
    
    # Check rclone availability
    if command -v rclone &> /dev/null; then
        # Create folder in Google Drive (if it doesn't exist)
        rclone mkdir "$GDRIVE_REMOTE:$GDRIVE_FOLDER" 2>/dev/null
        
        # Upload backup
        if rclone copy "$BACKUP_FILE" "$GDRIVE_REMOTE:$GDRIVE_FOLDER/" --progress; then
            echo "✅ Backup successfully uploaded to Google Drive"
            echo "📁 Cloud location: $GDRIVE_FOLDER/strapi_portfolio_backup_$DATE.tar.gz"
            
            # Clean up old cloud backups
            echo "🧹 Cleaning old cloud backups (keeping last $KEEP_CLOUD_BACKUPS)..."
            rclone ls "$GDRIVE_REMOTE:$GDRIVE_FOLDER/" | grep "strapi_portfolio_backup_" | sort -k2 -r | tail -n +$((KEEP_CLOUD_BACKUPS + 1)) | while read size filename; do
                echo "🗑️  Deleting old cloud backup: $filename"
                rclone delete "$GDRIVE_REMOTE:$GDRIVE_FOLDER/$filename"
            done
        else
            CLOUD_BACKUP_SUCCESS=false
            ERROR_MESSAGES="$ERROR_MESSAGES\n- Google Drive upload failed"
            echo "❌ Error uploading to Google Drive"
            echo "ℹ️  Local backup is still available"
        fi
    else
        CLOUD_BACKUP_SUCCESS=false
        ERROR_MESSAGES="$ERROR_MESSAGES\n- rclone not installed for cloud backup"
        echo "⚠️  rclone not installed. Skipping cloud backup."
        echo "💡 For installation run: curl https://rclone.org/install.sh | sudo bash"
    fi
elif [ "$ENABLE_CLOUD_BACKUP" = true ]; then
    CLOUD_BACKUP_SUCCESS=false
    ERROR_MESSAGES="$ERROR_MESSAGES\n- Backup file doesn't exist for cloud upload"
else
    echo "ℹ️  Cloud backup is disabled"
fi

# 8. Clean up uncompressed version (optional)
# rm -rf "$DATE"

# Display results
if [ "$BACKUP_SUCCESS" = true ] && [ -f "$BACKUP_FILE" ]; then
    echo "✅ Backup completed!"
    echo "📍 Local location: $BACKUP_FILE"
    echo "📊 Backup size:"
    ls -lh "$BACKUP_FILE"
else
    echo "❌ Backup completed with errors!"
fi

# Optional: Keep only last 5 local backups
echo "🧹 Cleaning old local backups (keeping last $KEEP_LOCAL_BACKUPS)..."
cd "$BACKUP_DIR"
ls -t strapi_portfolio_backup_*.tar.gz 2>/dev/null | tail -n +$((KEEP_LOCAL_BACKUPS + 1)) | xargs -r rm

# Prepare email message
EMAIL_MESSAGE="Strapi Portfolio backup on server $SERVER_NAME completed.

STATUS: "

if [ "$BACKUP_SUCCESS" = true ] && [ "$CLOUD_BACKUP_SUCCESS" = true ]; then
    EMAIL_MESSAGE="${EMAIL_MESSAGE}✅ SUCCESSFUL

Details:
- Date: $DATE
- Backup size: $(ls -lh "$BACKUP_FILE" 2>/dev/null | awk '{print $5}' || echo 'N/A')
- Local path: $BACKUP_FILE"
    
    if [ "$ENABLE_CLOUD_BACKUP" = true ] && command -v rclone &> /dev/null; then
        EMAIL_MESSAGE="${EMAIL_MESSAGE}
- Cloud location: $GDRIVE_FOLDER/strapi_portfolio_backup_$DATE.tar.gz"
    fi
    
    # Send success email
    send_email "$EMAIL_SUBJECT_SUCCESS" "$EMAIL_MESSAGE" false
    
elif [ "$BACKUP_SUCCESS" = true ] && [ "$CLOUD_BACKUP_SUCCESS" = false ]; then
    EMAIL_MESSAGE="${EMAIL_MESSAGE}⚠️  PARTIALLY SUCCESSFUL (local backup OK, cloud failed)

Details:
- Date: $DATE
- Backup size: $(ls -lh "$BACKUP_FILE" 2>/dev/null | awk '{print $5}' || echo 'N/A')
- Local path: $BACKUP_FILE

CLOUD BACKUP ISSUES:$ERROR_MESSAGES"
    
    # Send warning email
    send_email "⚠️ Strapi Portfolio - Backup Partially Successful" "$EMAIL_MESSAGE" false
    
else
    EMAIL_MESSAGE="${EMAIL_MESSAGE}❌ FAILED

ERRORS:$ERROR_MESSAGES

Please check the server and fix the issues."
    
    # Send error email
    send_email "$EMAIL_SUBJECT_ERROR" "$EMAIL_MESSAGE" true
fi

# Summary
echo ""
echo "📋 Backup summary:"
echo "   📅 Date: $DATE"
if [ -f "$BACKUP_FILE" ]; then
    echo "   📦 Size: $(ls -lh "$BACKUP_FILE" | awk '{print $5}')"
    echo "   💾 Local: $BACKUP_FILE"
fi
if [ "$ENABLE_CLOUD_BACKUP" = true ] && [ "$CLOUD_BACKUP_SUCCESS" = true ] && command -v rclone &> /dev/null; then
    echo "   ☁️  Cloud: $GDRIVE_FOLDER/strapi_portfolio_backup_$DATE.tar.gz"
fi

if [ "$BACKUP_SUCCESS" = false ]; then
    echo "   ❌ Status: ERRORS DURING BACKUP"
    exit 1
else
    echo "   ✅ Status: COMPLETED"
    exit 0
fi
