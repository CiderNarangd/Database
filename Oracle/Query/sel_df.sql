set echo on

select 
	a.file#
	, a.name
	, a.checkpoint_change#
	, b.status
	, a.status
	, b.change#
	, to_char(b.time, 'yyyy-mm-dd hh24:mi:ss.sssss') bk_time 
from v$datafile a, v$backup b 
where a.file# = b.file#;


