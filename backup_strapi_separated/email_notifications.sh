#!/bin/bash
source config.sh

send_email() {
    local subject="$1"
    local message="$2"
    local is_error="$3"
    
    if [ "$ENABLE_EMAIL_NOTIFICATIONS" != true ]; then
        return 0
    fi

    local email_body="Date: $(date)
Server: $SERVER_NAME
        
$message"
        
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
}

send_backup_report() {
    local email_message="Strapi Portfolio backup on server $SERVER_NAME completed.

STATUS: "

    if [ "$BACKUP_SUCCESS" = true ] && [ "$CLOUD_BACKUP_SUCCESS" = true ]; then
        email_message="${email_message}✅ SUCCESSFUL

Details:
- Date: $DATE
- Backup size: $(ls -lh "$BACKUP_FILE" 2>/dev/null | awk '{print $5}' || echo 'N/A')
- Local path: $BACKUP_FILE"
        
        if [ "$ENABLE_CLOUD_BACKUP" = true ] && command -v rclone &> /dev/null; then
            email_message="${email_message}
- Cloud location: $CLOUD_BACKUP_PATH"
        fi
        
        send_email "$EMAIL_SUBJECT_SUCCESS" "$email_message" false
        
    elif [ "$BACKUP_SUCCESS" = true ] && [ "$CLOUD_BACKUP_SUCCESS" = false ]; then
        email_message="${email_message}⚠️  PARTIALLY SUCCESSFUL (local backup OK, cloud failed)

Details:
- Date: $DATE
- Backup size: $(ls -lh "$BACKUP_FILE" 2>/dev/null | awk '{print $5}' || echo 'N/A')
- Local path: $BACKUP_FILE

CLOUD BACKUP ISSUES:$ERROR_MESSAGES"
        
        send_email "⚠️ Strapi Portfolio - Backup Partially Successful" "$email_message" false
        
    else
        email_message="${email_message}❌ FAILED

ERRORS:$ERROR_MESSAGES

Please check the server and fix the issues."
        
        send_email "$EMAIL_SUBJECT_ERROR" "$email_message" true
    fi
}