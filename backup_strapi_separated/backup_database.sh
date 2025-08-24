#!/bin/bash
source config.sh

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

start_docker_container() {
    if ! docker ps | grep -q $DB_CONTAINER; then
        echo "⚠️  Container $DB_CONTAINER not running. Starting Docker Compose..."
        if ! docker-compose up -d; then
            BACKUP_SUCCESS=false
            ERROR_MESSAGES="$ERROR_MESSAGES\n- Docker container startup failed"
            echo "❌ Error starting Docker containers"
            return 1
        else
            echo "⏳ Waiting 30 seconds for database to start..."
            sleep 30
        fi
    fi
    return 0
}

backup_database() {
    echo "🗄️  Backing up database..."
    
    if ! start_docker_container; then
        return 1
    fi

    echo "🔧 Using MariaDB tools"
    local db_backup_success=false

    echo "💾 Backing up database: $DB_NAME"
    if docker exec $DB_CONTAINER $DUMP_CLIENT -u $DB_USER -p$DB_PASS $DB_NAME > "$BACKUP_DIR/$DATE/database_$DATE.sql" 2>/dev/null; then
        if [ -s "$BACKUP_DIR/$DATE/database_$DATE.sql" ]; then
            echo "✅ Database successfully backed up ($DB_NAME)"
            db_backup_success=true
        fi
    fi

    if [ "$db_backup_success" = false ]; then
        echo "❌ Error backing up database. Trying all databases..."
        
        if docker exec $DB_CONTAINER $DUMP_CLIENT -u $DB_USER -p$DB_PASS --all-databases > "$BACKUP_DIR/$DATE/database_all_$DATE.sql" 2>/dev/null; then
            if [ -s "$BACKUP_DIR/$DATE/database_all_$DATE.sql" ]; then
                echo "✅ Backed up all databases as fallback"
                rm -f "$BACKUP_DIR/$DATE/database_$DATE.sql" 2>/dev/null
                db_backup_success=true
            fi
        fi
        
        if [ "$db_backup_success" = false ]; then
            BACKUP_SUCCESS=false
            ERROR_MESSAGES="$ERROR_MESSAGES\n- Database backup failed"
            echo "❌ Failed to backup database"
            echo "ℹ️  Continuing without database backup..."
            rm -f "$BACKUP_DIR/$DATE/database_$DATE.sql" "$BACKUP_DIR/$DATE/database_all_$DATE.sql" 2>/dev/null
            return 1
        fi
    fi
    return 0
}