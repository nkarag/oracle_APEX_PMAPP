-- goal:  update DEV_PRJS with operational support rows
-- start at 1/4/2015
-- each date assign a different developer
-- exclude non-working days and holidays

update pmapp.developers
  set id = id - 1;
  
  commit;

SELECT NAME, COMPANY, ID, MAIL FROM DEVELOPERS ;

with q as
(
  select date'2015-04-01' + level - 1 as day, mod(level-1, 7) id
  from dual
  connect by level < 20
)
select q.day, q.id
from pmapp.date_dim d, q
where
  d.date_key = q.day
  and d.working_day_ind = 1
  and d.holiday_ind = 0
order by 1;  

-- FINAL QUERY to generate rows
select day, mod((rownum - 1),7) id
from (
  select date_key day
  from pmapp.date_dim d
  where 1=1
    and d.working_day_ind = 1
    and d.holiday_ind = 0
    and date_key between date'2015-04-01' and date'2016-04-01'
  order by date_key
);  

-- INSERT STATEMENT
INSERT INTO DEV_PRJS (prjs_id, start_date, end_date, role, developers_id)
SELECT -1,
  DAY,
  DAY,
  'Senior Developer',
  mod((rownum - 1),7) id
FROM
  (SELECT date_key DAY
  FROM pmapp.date_dim d
  WHERE 1               =1
  AND d.working_day_ind = 1
  AND d.holiday_ind     = 0
  AND date_key BETWEEN DATE'2015-04-01' AND DATE'2016-04-01'
  ORDER BY date_key
  );
  
  commit;
  
  -- tasks beyond the scope of the contract
  select *
  from DEV_PRJS
  where
    start_date > date'2015-12-31';
  
  delete from DEV_PRJS
  where 
    start_date > date'2015-12-31';
    
commit;    