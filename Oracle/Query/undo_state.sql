select s.username, s.sid, s.serial#, t.xidusn undo_seg_num, r.name undo_seg_name, t.ubafil
undo_datafile_num, t.ubablk undo_block, t.used_ublk 
from v$session s, v$transaction t, v$rollname r 
where s.taddr = t.addr and t.xidusn = r.usn;
