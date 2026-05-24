select name, value, datum_time
  from v$dataguard_stats
  where name in ('transport lag','apply lag');