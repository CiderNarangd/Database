SELECT inst_id, xidusn, xidslot, status
FROM   gv$transaction
ORDER BY inst_id
/
