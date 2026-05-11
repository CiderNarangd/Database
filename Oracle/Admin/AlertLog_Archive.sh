#!/bin/bash

ORACLE_SID=orcl
ORACLE_BASE=/u01/app/oracle

ALERT_DIR="$ORACLE_BASE/diag/rdbms/${ORACLE_SID}/${ORACLE_SID}/trace"
BACKUP_DIR="$ORACLE_BASE/diag/rdbms/${ORACLE_SID}/${ORACLE_SID}/alert_archive"
TIMESTAMP=$(date +%Y%m%d)

ALERT_LOG="$ALERT_DIR/alert_${ORACLE_SID}.log"
ARCHIVE_LOG="$BACKUP_DIR/alert_${ORACLE_SID}_${TIMESTAMP}.log"

mkdir -p "$BACKUP_DIR"


if [ -f "$ALERT_LOG" ]; then
  
    cp -a "$ALERT_LOG" "$ARCHIVE_LOG"
    cat /dev/null > "$ALERT_LOG"
    echo "Archived: $ARCHIVE_LOG"
    gzip "$ARCHIVE_LOG"
else
    echo "Alert log not found at $ALERT_LOG"
fi

echo "Cleaning up archives older than 5 days..."
find "$BACKUP_DIR" -name "alert_${ORACLE_SID}_*.log.gz" -mtime +4 -exec rm -f {} \;

echo "--- Alert Log Archive Finished: $(date) ---"