SELECT name,
       db_unique_name,
       open_mode,
       database_role,
       switchover_status,
	   protection_mode
FROM v$database;