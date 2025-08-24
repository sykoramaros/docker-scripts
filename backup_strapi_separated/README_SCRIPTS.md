# 🗄️ Strapi Portfolio Backup System

Modular backup system for Strapi applications with cloud synchronization and email notifications.

```bash
backup-system/
├── main.sh
├── config.sh
├── backup_app.sh
├── backup_database.sh
├── backup_uploads.sh
├── compress_backup.sh
├── cloud_upload.sh
├── cleanup.sh
├── email_notifications.sh
└── README.md
```

## 📁 Script Structure

### `main.sh` - Main Orchestrator

- Coordinates all backup steps
- Handles error reporting
- Executes modules in correct order

### `config.sh` - Configuration

- All environment variables
- Backup settings
- Email and cloud configuration

### `backup_app.sh` - Application Backup

- RSync of application files
- Creates restore documentation
- Excludes unnecessary directories

### `backup_database.sh` - Database Backup

- MariaDB/MySQL backup
- Docker container management
- Fallback to all-databases backup

### `backup_uploads.sh` - Uploads Backup

- Compresses upload files
- Backs up Docker configuration

### `compress_backup.sh` - Compression

- Creates tar.gz archive
- Manages backup file naming

### `cloud_upload.sh` - Cloud Upload

- Google Drive integration via rclone
- Cloud backup management
- Cleanup of old cloud backups

### `cleanup.sh` - Cleanup Operations

- Removes old local backups
- Cleans up temporary files

### `email_notifications.sh` - Email Reports

- Success/error notifications
- Multiple email client support
- Detailed backup reports

## 🚀 Usage

```bash
# Make all scripts executable
chmod +x *.sh

# Run complete backup
./main.sh

# Or run individual modules
./backup_database.sh
./cloud_upload.sh
```

⚙️ Configuration

Edit config.sh to match your environment:

Database credentials
Backup paths
Cloud settings
Email notifications
🔧 Requirements

Docker and Docker Compose
rclone (for cloud backup)
Email client (mail/mailx/sendmail)
MariaDB/MySQL client tools
📋 Backup Flow

Application files backup
Database backup
Uploads backup
Compression
Cloud upload
Cleanup
Email reporting
