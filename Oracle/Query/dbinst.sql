SELECT SYS_CONTEXT('USERENV','DB_NAME')      AS db_name,
       SYS_CONTEXT('USERENV','INSTANCE_NAME') AS inst_name,
       SYS_CONTEXT('USERENV','SERVER_HOST')   AS host_name,
       SYS_CONTEXT('USERENV','IP_ADDRESS')    AS ip_addr
FROM   dual
/
