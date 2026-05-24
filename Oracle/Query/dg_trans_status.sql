SELECT dest_name,
       status,
       error,
       db_unique_name
FROM v$archive_dest_status
WHERE type='PHYSICAL';