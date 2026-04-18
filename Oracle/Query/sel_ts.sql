select a.file#, b.name tbs_name
, a.name file_name
, a.checkpoint_change#
, a.status 
from v$datafile a,v$tablespace b 
where a.ts# = b.ts#;
