#!/bin/bash
# Configuration file for Strapi Backup System

export DATE=$(date +%Y%m%d_%H%M%S)

# Application settings
export APP_NAME="your-app-name"
export BACKUP_BASE_NAME="${APP_NAME}_backup"
export BACKUP_FILENAME="${BACKUP_BASE_NAME}_${DATE}.tar.gz"
export BACKUP_FILE_PATH="/$BACKUP_FILENAME"

# Backup settings
export BACKUP_DIR="/var/Docker/${APP_NAME}/backups"
export PROJECT_DIR="."

# Database settings
export DB_CONTAINER="my_${APP_NAME}_mariadb"
export DB_NAME="${APP_NAME}_database"
export DB_USER="strapi_user"
export DB_PASS="your_secure_password_here"
export DB_CLIENT="mariadb"
export DUMP_CLIENT="mariadb-dump"

# Google Drive settings
export GDRIVE_REMOTE="gdrive"
export GDRIVE_FOLDER="${APP_NAME}_backups"
export CLOUD_BACKUP_PATH="$GDRIVE_REMOTE:$GDRIVE_FOLDER/$BACKUP_FILENAME"
export ENABLE_CLOUD_BACKUP=true
export KEEP_LOCAL_BACKUPS=5
export KEEP_CLOUD_BACKUPS=3

# Email settings
export ENABLE_EMAIL_NOTIFICATIONS=true
export EMAIL_TO="your-email@example.com"
export EMAIL_FROM="backup@server.local"
export EMAIL_SUBJECT_SUCCESS="✅ ${APP_NAME} - Backup Successful"
export EMAIL_SUBJECT_ERROR="❌ ${APP_NAME} - Backup Failed"
export SERVER_NAME=$(hostname)

# Status variables
export BACKUP_SUCCESS=true
export ERROR_MESSAGES=""
export CLOUD_BACKUP_SUCCESS=true
export BACKUP_FILE=""