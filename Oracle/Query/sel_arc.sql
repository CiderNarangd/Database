SELECT sequence#, name,first_time, next_time, applied, archived, status
FROM v$archived_log
ORDER BY sequence#;
