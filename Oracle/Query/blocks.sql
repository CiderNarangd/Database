accept v_tab prompt 'Enter value for tab_name: ';
col table_name for a30
col blocks for 9999999999
select table_name, blocks
from user_tables
where table_name=upper('&v_tab');
