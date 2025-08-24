# 🗄️ Strapi Portfolio Backup Script

A comprehensive backup solution for Strapi applications with cloud synchronization and email notifications.

## ✨ Features

- 📁 **Application Files Backup** - Excludes unnecessary directories (node_modules, logs, etc.)
- 🗃️ **Database Backup** - MariaDB/MySQL support with fallback to all-databases backup
- ☁️ **Cloud Sync** - Automatic upload to Google Drive using rclone
- 📧 **Email Notifications** - Success/error alerts with multiple email client support
- 🗜️ **Compression** - Creates compressed tar.gz archives
- 🧹 **Automatic Cleanup** - Keeps only specified number of backups (local and cloud)
- 📋 **Restore Guide** - Generates detailed restoration instructions
- 🐳 **Docker Support** - Handles Docker container management

## 🚀 Quick Start

### Make the script executable

```bash
chmod +x backup_strapi.sh
```

### Run the backup

```bash
./backup_strapi.sh
```

## ⚙️ Configuration

### Directory settings

```bash
BACKUP_DIR="/path/to/backups"
PROJECT_DIR="."
```

### Database settings

```bash
DB_CONTAINER="your_mariadb_container"
DB_NAME="your_database"
DB_USER="your_username"
DB_PASS="your_password"
```

### Cloud settings

```bash
GDRIVE_REMOTE="gdrive"
GDRIVE_FOLDER="your-backup-folder"
ENABLE_CLOUD_BACKUP=true
```

### Email settings

```bash
ENABLE_EMAIL_NOTIFICATIONS=true
EMAIL_TO="your-email@example.com"
```

## 📦 Installations

### Install rclone:

```bash
curl https://rclone.org/install.sh | sudo bash
rclone config
Set script permissions:
```

```bash
chmod +x backup_strapi.sh
```

## 📋 Requirements

✅ rclone - For Google Drive integration
✅ Email client - mail/mailx/sendmail for notifications
✅ Docker - For container management
✅ MariaDB/MySQL client - For database backups
📊 Backup Contents

Each backup includes:

📁 Application files (excluding node_modules, logs, etc.)
🗃️ Database dump (.sql file)
📸 Upload files (compressed)
🐳 Docker compose configuration
📋 Restoration guide (README)
🔄 Restoration

## 📝 License

MIT License - feel free to modify for your needs!
