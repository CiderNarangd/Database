#!/bin/bash

SOURCE_DIR="/u02/oradata/ORCL"
BACKUP_BASE_DIR="/home/oracle/backup/hot"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TARGET_DIR="$BACKUP_BASE_DIR/$TIMESTAMP"

mkdir -p "$TARGET_DIR"

echo "Begin Backup Oracle Database.."
sqlplus -s / as sysdba <<EOF
alter database begin backup;
exit;
EOF

echo "Start Copy Files.."
cp -av "$SOURCE_DIR"/* "$TARGET_DIR"

echo "End Backup Oracle Database.."
sqlplus -s / as sysdba <<EOF
alter database end backup;
alter system archive log current;
exit;
EOF

echo "Backup Completed: $TARGET_DIR"
