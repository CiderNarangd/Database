SELECT message,
       timestamp
FROM v$dataguard_status
ORDER BY timestamp DESC;