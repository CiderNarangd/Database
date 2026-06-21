accept v_tab prompt 'Enter value for tab_name: ';
col table_name for a30
col blocks for 9999999999
SELECT
    table_name,
    index_name,
    leaf_blocks,
    blevel
FROM dba_indexes
WHERE table_name = upper('&v_tab');