#!/bin/bash

SOURCE_DIR="/u02/oradata/ORCL"
BACKUP_BASE_DIR="/home/oracle/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TARGET_DIR="$BACKUP_BASE_DIR/$TIMESTAMP"

mkdir -p "$TARGET_DIR"

echo "ShutDown Oracle Database.."
sqlplus -s / as sysdba <<EOF
shutdown immediate;
exit;
EOF


echo "Start Copy Files.."
cp -av "$SOURCE_DIR"/* "$TARGET_DIR"

# 3. DB 다시 시작
echo "Startup Oracle Database.."
sqlplus -s / as sysdba <<EOF
startup;
exit;
EOF

echo "Backup Completed: $TARGET_DIR"

echo "Deleting backups older than 3 days.."
find "$BACKUP_BASE_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +2 -exec rm -rf {} \;
echo "Old backups deleted."