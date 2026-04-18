select
 a.group#
 , b.sequence#
 , a.member
 , b.bytes/1024/1024 mb
 , b.status
 , b.archived
 , b.first_change#
 , b.next_change# 
from v$logfile a, v$log b
where a.group# = b.group# order by 1,2;
