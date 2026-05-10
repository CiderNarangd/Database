accept v_tab prompt 'Enter value for tab_name: ';
col index_name for a30
col index_type for a50
col columns for a50
select ix.index_name, ix.index_type,
       listagg(ic.column_name, '+') within group (order by ic.column_position) columns
from user_indexes ix, user_ind_columns ic
where ix.index_name = ic.index_name
and ix.table_name = upper('&v_tab')
group by ix.index_name, ix.index_type;
