/****************************************************************************
--  PMAPP REPORTS
*****************************************************************************/

--  ****  base query: 1 row per (developer,project,day)
-- VERSION 2
--  Include overtime and lesstime
select * from  pmapp.v_day_prj_dev;

create or replace view pmapp.v_day_prj_dev as
        -- base query: 1 row per (developer,project,day)
        with q1
        as(
            select  date_key,  project_id, developers_id, start_date, end_date, duration, free_of_charge_ind
            from (
                  select  a.developers_id,
                          a.prjs_id project_id,
                          --b.id project_id,                  
                          a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad,
                          free_of_charge_ind
                  from PMAPP.DEV_PRJS a --join pmapp.prjs b on(a.prjs_id =  b.id)
                  where 1=1
                  --order by developers_id, start_date 
                  ) t1
              --partition by (t1.developers_id, t1.prjs_id)
              --right outer 
              join
                      (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
            on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
            order by  date_key,  project_id, developers_id, start_date
        ),
        q2  -- overtime
        as(
            select *
            from pmapp.dev_prjs
            where
              overtime_hrs is not null
              or
              lesstime_hrs is not null
        )
        select  q1.date_key,  q1.project_id, q1.developers_id, q1.start_date, q1.end_date, q1.duration, q1.free_of_charge_ind, q2.overtime_hrs, q2.lesstime_hrs
        from q1 left join q2 on (q1.developers_id = q2.developers_id and q1.project_id =  q2.prjs_id and q1.date_key = q2.start_date);

--  ****  base query: 1 row per (developer,project,day)
-- VERSION 1
select * from  pmapp.v_day_prj_dev;

create or replace view pmapp.v_day_prj_dev as
        -- base query: 1 row per (developer,project,day)
        select  date_key,  project_id, developers_id, start_date, end_date, duration, free_of_charge_ind
        from (
              select  a.developers_id,
                      a.prjs_id project_id,
                      --b.id project_id,                  
                      a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad,
                      free_of_charge_ind
              from PMAPP.DEV_PRJS a --join pmapp.prjs b on(a.prjs_id =  b.id)
              where 1=1
              --order by developers_id, start_date 
              ) t1
          --partition by (t1.developers_id, t1.prjs_id)
          --right outer 
          join
                  (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
        on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
        order by  date_key,  project_id, developers_id, start_date;

--**** DAYS PER DEVELOPER Per Month
-- VERSION 5
--    Add also mandays without overtime or lesstime. Also add overtime and lesstime in hours
-- Previous Version
--    Calculate mandays consumption by counting also unallocated working days and removing leaves. Also you must add overtime and 
--    subtract lesstime. Also remove free of charge tasks
--
select * from pmapp.v_rep_mdays_per_dev_month; 

create or replace view pmapp.v_rep_mdays_per_dev_month as
with wdays
as(
  select date_key 
  from target_dw.date_dim 
  where working_day_ind = 1
    and date_key between date'2015-03-26' and date'2020-03-26'
),
mdays_day_dev  -- no leaves, based on task allocation
as (
    -- 1 row per day, developer
    select  developers_id, 
            date_key, 
            consumed_planned,
            listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects , 
            1 mdays_day_dev, --sum(mdays_prj_day_dev) mdays_day_dev ,  
            sum(nvl(overtime_days,0)) tot_overtime_days_weighted, sum(nvl(lesstime_days,0)) tot_lesstime_days
            , sum(nvl(overtime_hrs,0)) tot_overtime_hrs, sum(nvl(lesstime_hrs,0)) tot_lesstime_hrs
            --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
            --count(distinct project_id) num_projects
    from (
        -- base query: 1 row per (developer,project,day)
        select  t.*,
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev,
                overtime_hrs/8 * (1.5) overtime_days, lesstime_hrs/8 lesstime_days
        from pmapp.v_day_prj_dev t
        where 1=1
          AND project_id <> -2 -- exclude leaves 
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by developers_id, date_key, project_id, start_date
    ) 
    where 1=1
      AND nvl(free_of_charge_ind, 0) <> 1 -- exclude free of charge tasks
    group by developers_id, date_key, consumed_planned
),
leaves_and_foc --leaves and free of charge
as(
-- 1 row per day, developer
    select  developers_id, 
            date_key, 
            consumed_planned,
            listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects  
     --     ,  sum(mdays_prj_day_dev  + nvl(overtime_days,0) - nvl(lesstime_days,0)) mdays_day_dev 
            --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
            --count(distinct project_id) num_projects
    from (
        -- base query: 1 row per (developer,project,day)
        select  t.*,
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev,
                overtime_hrs/8 overtime_days, lesstime_hrs/8 lesstime_days
        from pmapp.v_day_prj_dev t
        where 
            project_id = -2 -- include leaves 
            or (
                -- include free of charge tasks ONLY IF there is no other chargable task in the same day for the same developer
                nvl(free_of_charge_ind, 0) = 1
                AND NOT EXISTS (select 1 from pmapp.v_day_prj_dev where date_key = t.date_key and developers_id = t.developers_id and nvl(free_of_charge_ind, 0) = 0)
            )
            --or nvl(free_of_charge_ind, 0) = 1 -- include free of charge tasks
        order by developers_id, date_key, project_id, start_date
    ) 
    where 1=1
    group by developers_id, date_key, consumed_planned
),
mdays_day_dev_final
as(
select t1.developers_id, 
            t2.date_key, 
            t1.consumed_planned,
            t1.projects , 
            t1.mdays_day_dev, t1.tot_overtime_days_weighted, t1.tot_lesstime_days, t1.tot_overtime_hrs, t1.tot_lesstime_hrs
from 
  mdays_day_dev t1
  partition by (t1.developers_id)
  right outer join   
  wdays t2 --wdays_no_leaves_and_foc t2
  on (t1.date_key = t2.date_key)
),
md_day_dev_fin_no_leaves_foc
as(
  select *
  from mdays_day_dev_final
  where
    (developers_id, date_key) not in (select developers_id, date_key from  leaves_and_foc)
  order by developers_id, date_key
)
select  to_char(date_key, 'YYYY/MM') month, --trunc(date_key, 'MM') month, --
        t2.name dev_name, nvl(t1.consumed_planned, 'UNALLOCATED') consumed_planned, 
          round(sum(nvl(mdays_day_dev,1)),1) mandays, nvl(round(sum(tot_overtime_days_weighted),1),0) overtime_days, nvl(round(sum(tot_lesstime_days),1),0) lesstime_days
          ,nvl(round(sum(tot_overtime_hrs),1),0) overtime_hrs, nvl(round(sum(tot_lesstime_hrs),1),0) lesstime_hrs
from md_day_dev_fin_no_leaves_foc t1
    join developers t2 on(t1.developers_id = t2.id)
  where 1=1
    --AND instr(t1.projects, '-2') = 0 -- exclude days that contain a leave (extra filter on leaves:  This due to the fact that sometimes project assignments appear in the same day with a leave (-2). So the filter at this point gaurantees that we exclude all days with leaves)
  group by to_char(date_key, 'YYYY/MM'), --trunc(date_key, 'MM'), 
            t2.name, t1.consumed_planned
order by month, dev_name, consumed_planned;       


--**** DAYS PER DEVELOPER Per Month
-- VERSION 4
--    Calculate mandays consumption by counting also unallocated working days and removing leaves. Also you must add overtime and 
--    subtract lesstime. Also remove free of charge tasks
--
select * from pmapp.v_rep_mdays_per_dev_month; 

create or replace view pmapp.v_rep_mdays_per_dev_month as
with wdays
as(
  select date_key 
  from target_dw.date_dim 
  where working_day_ind = 1
    and date_key between date'2015-03-26' and date'2016-03-26'
),
mdays_day_dev  -- no leaves, based on task allocation
as (
    -- 1 row per day, developer
    select  developers_id, 
            date_key, 
            consumed_planned,
            listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects , 
            1 mdays_day_dev, --sum(mdays_prj_day_dev) mdays_day_dev ,  
            sum(nvl(overtime_days,0)) overtime, sum(nvl(lesstime_days,0)) lesstime
            --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
            --count(distinct project_id) num_projects
    from (
        -- base query: 1 row per (developer,project,day)
        select  t.*,
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev,
                overtime_hrs/8 * (1.5) overtime_days, lesstime_hrs/8 lesstime_days
        from pmapp.v_day_prj_dev t
        where 1=1
          AND project_id <> -2 -- exclude leaves 
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by developers_id, date_key, project_id, start_date
    ) 
    where 1=1
      AND nvl(free_of_charge_ind, 0) <> 1 -- exclude free of charge tasks
    group by developers_id, date_key, consumed_planned
),
leaves_and_foc --leaves and free of charge
as(
-- 1 row per day, developer
    select  developers_id, 
            date_key, 
            consumed_planned,
            listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects , 
            sum(mdays_prj_day_dev  + nvl(overtime_days,0) - nvl(lesstime_days,0)) mdays_day_dev 
            --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
            --count(distinct project_id) num_projects
    from (
        -- base query: 1 row per (developer,project,day)
        select  t.*,
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev,
                overtime_hrs/8 overtime_days, lesstime_hrs/8 lesstime_days
        from pmapp.v_day_prj_dev t
        where 
            project_id = -2 -- include leaves 
            or (
                -- include free of charge tasks ONLY IF there is no other chargable task in the same day for the same developer
                nvl(free_of_charge_ind, 0) = 1
                AND NOT EXISTS (select 1 from pmapp.v_day_prj_dev where date_key = t.date_key and developers_id = t.developers_id and nvl(free_of_charge_ind, 0) = 0)
            )
            --or nvl(free_of_charge_ind, 0) = 1 -- include free of charge tasks
        order by developers_id, date_key, project_id, start_date
    ) 
    where 1=1
    group by developers_id, date_key, consumed_planned
),
mdays_day_dev_final
as(
select t1.developers_id, 
            t2.date_key, 
            t1.consumed_planned,
            t1.projects , 
            t1.mdays_day_dev, t1.overtime, t1.lesstime 
from 
  mdays_day_dev t1
  partition by (t1.developers_id)
  right outer join   
  wdays t2 --wdays_no_leaves_and_foc t2
  on (t1.date_key = t2.date_key)
),
md_day_dev_fin_no_leaves_foc
as(
  select *
  from mdays_day_dev_final
  where
    (developers_id, date_key) not in (select developers_id, date_key from  leaves_and_foc)
  order by developers_id, date_key
)
select  to_char(date_key, 'YYYY/MM') month, --trunc(date_key, 'MM') month, --
        t2.name dev_name, nvl(t1.consumed_planned, 'UNALLOCATED') consumed_planned, 
          round(sum(nvl(mdays_day_dev,1)),1) mandays, nvl(round(sum(overtime),1),0) overtime_days, nvl(round(sum(lesstime),1),0) lesstime_days
from md_day_dev_fin_no_leaves_foc t1
    join developers t2 on(t1.developers_id = t2.id)
  where 1=1
    --AND instr(t1.projects, '-2') = 0 -- exclude days that contain a leave (extra filter on leaves:  This due to the fact that sometimes project assignments appear in the same day with a leave (-2). So the filter at this point gaurantees that we exclude all days with leaves)
  group by to_char(date_key, 'YYYY/MM'), --trunc(date_key, 'MM'), 
            t2.name, t1.consumed_planned
order by month, dev_name, consumed_planned;       


--**** DAYS PER DEVELOPER Per Month
-- VERSION 3
-- added overtime and lesstime mandays with a more elegant way (compared to version 2)
select * from pmapp.v_rep_mdays_per_dev_month; 

create or replace view pmapp.v_rep_mdays_per_dev_month as
 select  to_char(date_key, 'MM/YYYY') month, nvl(t2.name,'TOTAL') dev_name, nvl(t1.consumed_planned, 'TOTAL') consumed_planned, 
          round(sum(mdays_day_dev),1) mandays--,
          --count(t1.date_key) mandays_old, 
          --round(count(t1.date_key)/sum(case when (t2.name IS NULL OR t1.consumed_planned IS NULL) then 0 else count(t1.date_key) end) over()*100,1) pct_old,          
          --round(round(sum(mdays_day_dev),1)/sum(case when (t2.name IS NULL OR t1.consumed_planned IS NULL) then 0 else round(sum(mdays_day_dev),1) end) over()*100,1) pct
  from (
    -- 1 row per day, developer
    select  developers_id, 
            date_key, 
            consumed_planned,
            listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects , 
            sum(mdays_prj_day_dev  + nvl(overtime_days,0) - nvl(lesstime_days,0)) mdays_day_dev 
            --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
            --count(distinct project_id) num_projects
    from (
        -- base query: 1 row per (developer,project,day)
        select  t.*,
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev,
                overtime_hrs/8 overtime_days, lesstime_hrs/8 lesstime_days
        from pmapp.v_day_prj_dev t
        where 1=1
          AND project_id <> -2 -- exclude leaves 
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by developers_id, date_key, project_id, start_date
    ) 
    where 1=1
      AND nvl(free_of_charge_ind, 0) <> 1 -- exclude free of charge tasks
    group by developers_id, date_key, consumed_planned
  ) t1
    join developers t2 on(t1.developers_id = t2.id)
  where 1=1
    AND instr(t1.projects, '-2') = 0 -- exclude days that contain a leave (extra filter on leaves:  This due to the fact that sometimes project assignments appear in the same day with a leave (-2). So the filter at this point gaurantees that we exclude all days with leaves)
  group by to_char(date_key, 'MM/YYYY'), t2.name, t1.consumed_planned
  order by  month, dev_name, consumed_planned ;

--**** DAYS PER DEVELOPER Per Month
-- VERSION 2 : includes overtime and lesstime
select * from pmapp.v_rep_mdays_per_dev_month; 

create or replace view pmapp.v_rep_mdays_per_dev_month as
 select  to_char(date_key, 'MM/YYYY') month, nvl(t2.name,'TOTAL') dev_name, nvl(t1.consumed_planned, 'TOTAL') consumed_planned, 
          round(sum(mdays_day_dev),1) mandays--,
          --count(t1.date_key) mandays_old, 
          --round(count(t1.date_key)/sum(case when (t2.name IS NULL OR t1.consumed_planned IS NULL) then 0 else count(t1.date_key) end) over()*100,1) pct_old,          
          --round(round(sum(mdays_day_dev),1)/sum(case when (t2.name IS NULL OR t1.consumed_planned IS NULL) then 0 else round(sum(mdays_day_dev),1) end) over()*100,1) pct
  from (
    -- 1 row per day, developer
    select  developers_id, 
            date_key, 
            consumed_planned,
            listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects , 
            sum(mdays_prj_day_dev) mdays_day_dev
            --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
            --count(distinct project_id) num_projects
    from (
        -- base query: 1 row per (developer,project,day)
        select  t.*,
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev
        from pmapp.v_day_prj_dev t
        where 1=1
          AND project_id <> -2 -- exclude leaves 
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by developers_id, date_key, project_id, start_date
    ) 
    where 1=1
      AND nvl(free_of_charge_ind, 0) <> 1 -- exclude free of charge tasks
    group by developers_id, date_key, consumed_planned
    union all
     -- developers overtime
    select developers_id,
            start_date date_key,
            case when start_date < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
            to_char(prjs_id) projects , 
            (nvl(overtime_hrs,0) - nvl(lesstime_hrs,0))/8 mdays_day_dev
    from pmapp.dev_prjs        
    where 1=1
      AND prjs_id <> -2 -- exclude leaves 
  ) t1
    join developers t2 on(t1.developers_id = t2.id)
  where 1=1
    AND instr(t1.projects, '-2') = 0 -- exclude days that contain a leave (extra filter on leaves:  This due to the fact that sometimes project assignments appear in the same day with a leave (-2). So the filter at this point it is not gauranteed to exclude all days with leaves)
  group by to_char(date_key, 'MM/YYYY'), t2.name, t1.consumed_planned
  order by  month, dev_name, consumed_planned ;



--**** DAYS PER DEVELOPER Per Month
-- VERSION 1
select * from pmapp.v_rep_mdays_per_dev_month; 

create or replace view pmapp.v_rep_mdays_per_dev_month as
 select  to_char(date_key, 'MM/YYYY') month, nvl(t2.name,'TOTAL') dev_name, nvl(t1.consumed_planned, 'TOTAL') consumed_planned, 
          round(sum(mdays_day_dev),1) mandays--,
          --count(t1.date_key) mandays_old, 
          --round(count(t1.date_key)/sum(case when (t2.name IS NULL OR t1.consumed_planned IS NULL) then 0 else count(t1.date_key) end) over()*100,1) pct_old,          
          --round(round(sum(mdays_day_dev),1)/sum(case when (t2.name IS NULL OR t1.consumed_planned IS NULL) then 0 else round(sum(mdays_day_dev),1) end) over()*100,1) pct
  from (
    -- 1 row per day, developer
    select  developers_id, 
            date_key, 
            consumed_planned,
            listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects , 
            sum(mdays_prj_day_dev) mdays_day_dev
            --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
            --count(distinct project_id) num_projects
    from (
        -- base query: 1 row per (developer,project,day)
        select  t.*,
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev
        from pmapp.v_day_prj_dev t
        where 1=1
          AND project_id <> -2 -- exclude leaves 
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by developers_id, date_key, project_id, start_date
    ) 
    where 1=1
      AND nvl(free_of_charge_ind, 0) <> 1 -- exclude free of charge tasks
    group by developers_id, date_key, consumed_planned
  ) t1
    join developers t2 on(t1.developers_id = t2.id)
  where 1=1
    AND instr(t1.projects, '-2') = 0 -- exclude days that contain a leave (extra filter on leaves:  This due to the fact that sometimes project assignments appear in the same day with a leave (-2). So the filter at this point it is not gauranteed to exclude all days with leaves)
  group by to_char(date_key, 'MM/YYYY'), t2.name, t1.consumed_planned
  order by  month, dev_name, consumed_planned ;


--  ****  DAYS PER DEVELOPER (i.e., up to sysdate, including today) (excluding leaves, operational support)
-- VERSION 2
--    Make more precise calculation of the consumed manday. Allow a calculation of the type 1/num_of_projects for each
--    assignement within the day
select * from pmapp.v_rep_mdays_per_dev;

create or replace view pmapp.v_rep_mdays_per_dev
as
  select  nvl(t2.name,'TOTAL') dev_name, nvl(t1.consumed_planned, 'TOTAL') consumed_planned, 
          round(sum(mdays_day_dev),1) mandays,
          --count(t1.date_key) mandays_old, 
          --round(count(t1.date_key)/sum(case when (t2.name IS NULL OR t1.consumed_planned IS NULL) then 0 else count(t1.date_key) end) over()*100,1) pct_old,
          round(round(sum(mdays_day_dev),1)/sum(case when (t2.name IS NULL OR t1.consumed_planned IS NULL) then 0 else round(sum(mdays_day_dev),1) end) over()*100,1) pct
  from (
    -- 1 row per day, developer
    select  developers_id, 
            date_key, 
            consumed_planned,
            listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects , 
            sum(mdays_prj_day_dev) mdays_day_dev
            --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
            --count(distinct project_id) num_projects
    from (
        -- base query: 1 row per (developer,project,day)
        select  t.*,
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev
        from pmapp.v_day_prj_dev t
        where 1=1
          AND project_id <> -2 -- exclude leaves 
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by developers_id, date_key, project_id, start_date
    ) 
    where 1=1
      AND nvl(free_of_charge_ind, 0) <> 1 -- exclude free of charge tasks
    group by developers_id, date_key, consumed_planned
  ) t1
    join developers t2 on(t1.developers_id = t2.id)
  where 1=1
    AND instr(t1.projects, '-2') = 0 -- exclude days that contain a leave (extra filter on leaves:  This due to the fact that sometimes project assignments appear in the same day with a leave (-2). So the filter at this point it is not gauranteed to exclude all days with leaves)
  group by rollup(t2.name, t1.consumed_planned)
  order by  dev_name, consumed_planned ;
    
--  ****  DAYS PER DEVELOPER (i.e., up to sysdate, including today) (excluding leaves, operational support)
-- VERSION 1
select * from pmapp.v_rep_mdays_per_dev;

create or replace view pmapp.v_rep_mdays_per_dev
as
  select nvl(t2.name,'TOTAL') dev_name, nvl(t1.consumed_planned, 'TOTAL') consumed_planned, count(t1.date_key) mandays, round(count(t1.date_key)/sum(case when (t2.name IS NULL OR t1.consumed_planned IS NULL) then 0 else count(t1.date_key) end) over()*100,1) pct
  from (
    -- 1 row per day, developer
    select  developers_id, 
            date_key, 
            consumed_planned,
            listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
            --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
            --count(distinct project_id) num_projects
    from (
        -- base query: 1 row per (developer,project,day)
        select  t.*,
                case when DATE_KEY <= SYSDATE + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned
        from pmapp.v_day_prj_dev t
        where 1=1
          --AND project_id <> -2 -- exclude leaves (Comment out this filter because I will put it after list_agg aggregation. This due to the fact that sometimes project assignments appear in the same day with a leave (-2). So the filter at this point it is not gauranteed to exclude all days with leaves)
          AND project_id <> -1 -- exclude operational support
          AND project_id <> 0 -- exclude generic task
          AND nvl(t.free_of_charge_ind, 0) <> 1
          --AND DATE_KEY <= SYSDATE + 1
        order by developers_id, date_key, project_id, start_date
    ) 
    group by developers_id, date_key, consumed_planned
  ) t1
    join developers t2 on(t1.developers_id = t2.id)
  where 1=1
    AND instr(t1.projects, '-2') = 0 -- exclude days that contain a leave 
  group by rollup(t2.name, t1.consumed_planned)
  order by  dev_name, consumed_planned ;

  --  ****  MANDAYS PER CR
--
-- VERSION 5
--    add OP 2016 projects
--    add go live date
--    Στο APEX query έβαλα και "'PLANNED - BUDGETARY" κατηγορία
--
-- VERSION 4
--  add project population date
--
--  VERSION 3
--    added overtime and lesstime mandays
--
--  VERSION 2
--    Include also Operational Support in the calculation. I.e., if a developer in a day has Op Support then this must count
--    in the denominator of the manday allocation i.e., 1/num_of_projs_within_day. Then Operational Support can be filtered out
--    from the final list of projects (since is not a CR).
--    Also, the free_of_charge projects must also be counted in this denominator and be filtered later on from the list.
--    Also, correct calculation for CONSUMED/PLANNED from DATE_KEY <= SYSDATE + 1 to DATE_KEY < trunc(SYSDATE) + 1
--  
--     Notes:
--        Mandays are NOT "Elapsed Days", so we have to calculate the percentage of the day allocated to a CR
--        so as not to double count the days
--        USE a "CONSUMED_PLAN" column so as not to have to use 2 separate views to show consumed vs. plannes mandays

-- APEX query
select rownum r, t.*
from (
  select  "BUSINESS_UNIT", 
          upper("OPERATING_PLAN_ID") OPERATING_PLAN_ID, 
          "OP", 
          "BUGZILLA_ID", 
          "NAME_DESCRIPTION", 
          "PROJECT_ID", 
          "DEPT", 
          "PM", 
          "STATUS", 
          "START_OF_UAT", 
          "GO_LIVE_DATE",
          "COMPLETION_DATE", 
          "MDAYS_PRJ", 
          "CONSUMED_PLANNED", 
          "COMPANY",
          'Time and Material' PTYPE,
          population_date
  from v_rep_mdays_per_cr 
  union all
  select   /* Fixed Price Projects from Q1 2015 */
          business_unit, 
          upper(operating_plan_id) OPERATING_PLAN_ID, 
          case  when operating_plan_id IS NULL then 'NOT IN OP' 
                when operating_plan_id like '%2016%' then 'IN OP 2016'
                when operating_plan_id like '%2015%' then 'IN OP 2015' 
                else 'IN OP (not 2015,2016)' end OP,
          bugzilla_id,
          name_description,
          null project_id,
          null dept,
          pm,
          'COMPLETED' status,
          null start_of_uat,
          null go_live_date,
          date'2015-03-31' completion_date,
          to_number(mdays) MDAYS_PRJ,
          'CONSUMED'  CONSUMED_PLANNED,
           COMPANY,
          'Fixed Price' PTYPE,
          to_date('31/03/3015','dd/mm/yyyy') population_date
  from fixed_price_prjs_from_xls
  union all
  select  "BUSINESS_UNIT", 
          upper("OPERATING_PLAN_ID") OPERATING_PLAN_ID, 
          case  when operating_plan_id IS NULL then 'NOT IN OP' 
                when operating_plan_id like '%2016%' then 'IN OP 2016'
                when operating_plan_id like '%2015%' then 'IN OP 2015' 
                else 'IN OP (not 2015,2016)' end OP,
          "BUGZILLA_ID", 
          "NAME_DESCRIPTION", 
          id "PROJECT_ID", 
          "DEPT", 
          "PM", 
          "STATUS", 
          "START_OF_UAT", 
          "GO_LIVE_DATE",
          "COMPLETION_DATE", 
          "MAN_DAYS", 
          'PLANNED - BUDGETARY' "CONSUMED_PLANNED", 
          null "COMPANY",
          'Time and Material' PTYPE,
          population_date
  from pmapp.prjs
  where 
    status in ('NOT STARTED - NOT PLANNED', 'NOT STARTED - PLANNED')
    and man_days IS NOT NULL
  order by business_unit, bugzilla_id,  project_id desc, name_description,  status, company, consumed_planned
) t;

select * from fixed_price_prjs_from_xls;

select rownum r, t.* from v_rep_mdays_per_cr t;

create or replace view v_rep_mdays_per_cr as
  select  business_unit, 
          operating_plan_id, case when operating_plan_id IS NULL then 'NOT IN OP' 
                                  when operating_plan_id like '%2016%' then 'IN OP 2016' 
                                  when operating_plan_id like '%2015%' then 'IN OP 2015' 
                                  else 'IN OP (not 2015,2016)' end OP,
          bugzilla_id, name_description, project_id, dept, pm, status, start_of_uat, go_live_date, completion_date, population_date,
          round(sum(mdays_prj_day),1) mdays_prj, consumed_planned, company 
  from (
    -- 1 row per day, project
    select  s3.business_unit,
            s3.operating_plan_id,
            s1.project_id, 
            s3.bugzilla_id,
            s1.date_key, 
            s3.name_description,
            s3.dept,
            s3.pm,
            --s3.prj_type,
            s3.status,  
            s3.start_of_uat,
            s3.go_live_date,
            s3.completion_date,
            s3.population_date,
            --sum(mdays_prj_day_dev) mdays_prj_day,
            sum(mdays_prj_day_dev  + nvl(overtime_days,0) - nvl(lesstime_days,0)) mdays_prj_day,
            s1.consumed_planned,
            s2.company
    from (
        -- base query: 1 row per (developer,project,day)
        select  t1.*, 
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev,
                overtime_hrs/8 overtime_days, lesstime_hrs/8 lesstime_days
        from pmapp.v_day_prj_dev t1 
        where 1=1
          AND t1.project_id <> -2  -- exclude leaves          
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by  project_id, date_key, developers_id, start_date
    ) s1 
        join developers s2 on(s1.developers_id = s2.id)
          join prjs s3  on (s1.project_id = s3.id)
    where 1=1
      AND nvl(s1.free_of_charge_ind,0) <> 1  -- exclude free of charge
      AND s3.prj_type = 'Change Request'
      --AND s3.dept <> 'MDW'
    group by s1.project_id, s3.bugzilla_id, s1.date_key, s3.business_unit, s3.operating_plan_id, s3.name_description, s3.dept, s3.pm,  s3.status, 
            s3.start_of_uat, s3.go_live_date,
            s3.completion_date, s3.population_date, s2.company, s1.consumed_planned
    order by business_unit, project_id, date_key, company
  ) p1
  where 1=1
  group by project_id, name_description, bugzilla_id, dept, pm, status, start_of_uat, go_live_date,
           completion_date, population_date, business_unit, operating_plan_id, company, consumed_planned,
           case when operating_plan_id IS NULL then 'NOT IN OP' 
                when operating_plan_id like '%2016%' then 'IN OP 2016' 
                when operating_plan_id like '%2015%' then 'IN OP 2015' 
                else 'IN OP (not 2015,2016)' end
  order by business_unit, bugzilla_id,  project_id desc, name_description,  status, company, consumed_planned;

  --  ****  MANDAYS PER CR
-- VERSION 4
--  add project population date
--
--  VERSION 3
--    added overtime and lesstime mandays
--
--  VERSION 2
--    Include also Operational Support in the calculation. I.e., if a developer in a day has Op Support then this must count
--    in the denominator of the manday allocation i.e., 1/num_of_projs_within_day. Then Operational Support can be filtered out
--    from the final list of projects (since is not a CR).
--    Also, the free_of_charge projects must also be counted in this denominator and be filtered later on from the list.
--    Also, correct calculation for CONSUMED/PLANNED from DATE_KEY <= SYSDATE + 1 to DATE_KEY < trunc(SYSDATE) + 1
--  
--     Notes:
--        Mandays are NOT "Elapsed Days", so we have to calculate the percentage of the day allocated to a CR
--        so as not to double count the days
--        USE a "CONSUMED_PLAN" column so as not to have to use 2 separate views to show consumed vs. plannes mandays

select rownum r, t.*
from (
  select  "BUSINESS_UNIT", 
          upper("OPERATING_PLAN_ID") OPERATING_PLAN_ID, 
          "OP", 
          "BUGZILLA_ID", 
          "NAME_DESCRIPTION", 
          "PROJECT_ID", 
          "DEPT", 
          "PM", 
          "STATUS", 
          "START_OF_UAT", 
          "COMPLETION_DATE", 
          "MDAYS_PRJ", 
          "CONSUMED_PLANNED", 
          "COMPANY",
          'Time and Material' PTYPE,
          population_date
  from v_rep_mdays_per_cr 
  union all
  select   /* Fixed Price Projects from Q1 2015 */
          business_unit, 
          upper(operating_plan_id) OPERATING_PLAN_ID, 
          case when operating_plan_id IS NULL then 'NOT IN OP' when operating_plan_id like '%2015%' then 'IN OP 2015' else 'IN OP (not 2015)' end OP,
          bugzilla_id,
          name_description,
          null project_id,
          null dept,
          pm,
          'COMPLETED' status,
          null start_of_uat,
          date'2015-03-31' completion_date,
          to_number(mdays) MDAYS_PRJ,
          'CONSUMED'  CONSUMED_PLANNED,
           COMPANY,
          'Fixed Price' PTYPE,
          to_date('31/03/3015','dd/mm/yyyy') population_date
  from fixed_price_prjs_from_xls
  order by business_unit, bugzilla_id,  project_id desc, name_description,  status, company, consumed_planned
) t;

select * from fixed_price_prjs_from_xls;

select rownum r, t.* from v_rep_mdays_per_cr t;

create or replace view v_rep_mdays_per_cr as
  select  business_unit, 
          operating_plan_id, case when operating_plan_id IS NULL then 'NOT IN OP' when operating_plan_id like '%2015%' then 'IN OP 2015' else 'IN OP (not 2015)' end OP,
          bugzilla_id, name_description, project_id, dept, pm, status, start_of_uat, completion_date, population_date,
          round(sum(mdays_prj_day),1) mdays_prj, consumed_planned, company 
  from (
    -- 1 row per day, project
    select  s3.business_unit,
            s3.operating_plan_id,
            s1.project_id, 
            s3.bugzilla_id,
            s1.date_key, 
            s3.name_description,
            s3.dept,
            s3.pm,
            --s3.prj_type,
            s3.status,  
            s3.start_of_uat,
            s3.completion_date,
            s3.population_date,
            --sum(mdays_prj_day_dev) mdays_prj_day,
            sum(mdays_prj_day_dev  + nvl(overtime_days,0) - nvl(lesstime_days,0)) mdays_prj_day,
            s1.consumed_planned,
            s2.company
    from (
        -- base query: 1 row per (developer,project,day)
        select  t1.*, 
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev,
                overtime_hrs/8 overtime_days, lesstime_hrs/8 lesstime_days
        from pmapp.v_day_prj_dev t1 
        where 1=1
          AND t1.project_id <> -2  -- exclude leaves          
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by  project_id, date_key, developers_id, start_date
    ) s1 
        join developers s2 on(s1.developers_id = s2.id)
          join prjs s3  on (s1.project_id = s3.id)
    where 1=1
      AND nvl(s1.free_of_charge_ind,0) <> 1  -- exclude free of charge
      AND s3.prj_type = 'Change Request'
      --AND s3.dept <> 'MDW'
    group by s1.project_id, s3.bugzilla_id, s1.date_key, s3.business_unit, s3.operating_plan_id, s3.name_description, s3.dept, s3.pm,  s3.status, s3.start_of_uat,
            s3.completion_date, s3.population_date, s2.company, s1.consumed_planned
    order by business_unit, project_id, date_key, company
  ) p1
  where 1=1
  group by project_id, name_description, bugzilla_id, dept, pm, status, start_of_uat,
           completion_date, population_date, business_unit, operating_plan_id, company, consumed_planned,
           case when operating_plan_id IS NULL then 'NOT IN OP' when operating_plan_id like '%2015%' then 'IN OP 2015' else 'IN OP (not 2015)' end
  order by business_unit, bugzilla_id,  project_id desc, name_description,  status, company, consumed_planned;


  --  ****  MANDAYS PER CR
--  VERSION 3
--    added overtime and lesstime mandays
--
--  VERSION 2
--    Include also Operational Support in the calculation. I.e., if a developer in a day has Op Support then this must count
--    in the denominator of the manday allocation i.e., 1/num_of_projs_within_day. Then Operational Support can be filtered out
--    from the final list of projects (since is not a CR).
--    Also, the free_of_charge projects must also be counted in this denominator and be filtered later on from the list.
--    Also, correct calculation for CONSUMED/PLANNED from DATE_KEY <= SYSDATE + 1 to DATE_KEY < trunc(SYSDATE) + 1
--  
--     Notes:
--        Mandays are NOT "Elapsed Days", so we have to calculate the percentage of the day allocated to a CR
--        so as not to double count the days
--        USE a "CONSUMED_PLAN" column so as not to have to use 2 separate views to show consumed vs. plannes mandays

select rownum r, t.*
from (
  select  "BUSINESS_UNIT", 
          upper("OPERATING_PLAN_ID") OPERATING_PLAN_ID, 
          "OP", 
          "BUGZILLA_ID", 
          "NAME_DESCRIPTION", 
          "PROJECT_ID", 
          "DEPT", 
          "PM", 
          "STATUS", 
          "START_OF_UAT", 
          "COMPLETION_DATE", 
          "MDAYS_PRJ", 
          "CONSUMED_PLANNED", 
          "COMPANY",
          'Time and Material' PTYPE
  from v_rep_mdays_per_cr 
  union all
  select   /* Fixed Price Projects from Q1 2015 */
          business_unit, 
          upper(operating_plan_id) OPERATING_PLAN_ID, 
          case when operating_plan_id IS NULL then 'NOT IN OP' when operating_plan_id like '%2015%' then 'IN OP 2015' else 'IN OP (not 2015)' end OP,
          bugzilla_id,
          name_description,
          null project_id,
          null dept,
          pm,
          'COMPLETED' status,
          null start_of_uat,
          date'2015-03-31' completion_date,
          to_number(mdays) MDAYS_PRJ,
          'CONSUMED'  CONSUMED_PLANNED,
           COMPANY,
          'Fixed Price' PTYPE
  from fixed_price_prjs_from_xls
  order by business_unit, bugzilla_id,  project_id desc, name_description,  status, company, consumed_planned
) t;

select * from fixed_price_prjs_from_xls;

select rownum r, t.* from v_rep_mdays_per_cr t;

create or replace view v_rep_mdays_per_cr as
  select  business_unit, 
          operating_plan_id, case when operating_plan_id IS NULL then 'NOT IN OP' when operating_plan_id like '%2015%' then 'IN OP 2015' else 'IN OP (not 2015)' end OP,
          bugzilla_id, name_description, project_id, dept, pm, status, start_of_uat, completion_date,
          round(sum(mdays_prj_day),1) mdays_prj, consumed_planned, company 
  from (
    -- 1 row per day, project
    select  s3.business_unit,
            s3.operating_plan_id,
            s1.project_id, 
            s3.bugzilla_id,
            s1.date_key, 
            s3.name_description,
            s3.dept,
            s3.pm,
            --s3.prj_type,
            s3.status,  
            s3.start_of_uat,
            s3.completion_date,
            --sum(mdays_prj_day_dev) mdays_prj_day,
            sum(mdays_prj_day_dev  + nvl(overtime_days,0) - nvl(lesstime_days,0)) mdays_prj_day,
            s1.consumed_planned,
            s2.company
    from (
        -- base query: 1 row per (developer,project,day)
        select  t1.*, 
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev,
                overtime_hrs/8 overtime_days, lesstime_hrs/8 lesstime_days
        from pmapp.v_day_prj_dev t1 
        where 1=1
          AND t1.project_id <> -2  -- exclude leaves          
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by  project_id, date_key, developers_id, start_date
    ) s1 
        join developers s2 on(s1.developers_id = s2.id)
          join prjs s3  on (s1.project_id = s3.id)
    where 1=1
      AND nvl(s1.free_of_charge_ind,0) <> 1  -- exclude free of charge
      AND s3.prj_type = 'Change Request'
      --AND s3.dept <> 'MDW'
    group by s1.project_id, s3.bugzilla_id, s1.date_key, s3.business_unit, s3.operating_plan_id, s3.name_description, s3.dept, s3.pm,  s3.status, s3.start_of_uat,
            s3.completion_date, s2.company, s1.consumed_planned
    order by business_unit, project_id, date_key, company
  ) p1
  where 1=1
  group by project_id, name_description, bugzilla_id, dept, pm, status, start_of_uat,
           completion_date, business_unit, operating_plan_id, company, consumed_planned,
           case when operating_plan_id IS NULL then 'NOT IN OP' when operating_plan_id like '%2015%' then 'IN OP 2015' else 'IN OP (not 2015)' end
  order by business_unit, bugzilla_id,  project_id desc, name_description,  status, company, consumed_planned;


  --  ****  MANDAYS PER CR
--  VERSION 2
--    Include also Operational Support in the calculation. I.e., if a developer in a day has Op Support then this must count
--    in the denominator of the manday allocation i.e., 1/num_of_projs_within_day. Then Operational Support can be filtered out
--    from the final list of projects (since is not a CR).
--    Also, the free_of_charge projects must also be counted in this denominator and be filtered later on from the list.
--    Also, correct calculation for CONSUMED/PLANNED from DATE_KEY <= SYSDATE + 1 to DATE_KEY < trunc(SYSDATE) + 1
--  
--  Notes:
--    Mandays are NOT "Elapsed Days", so we have to calculate the percentage of the day allocated to a CR
--    so as not to double count the days
--    USE a "CONSUMED_PLAN" column so as not to have to use 2 separate views to show consumed vs. plannes mandays

select rownum r, t.*
from (
  select  "BUSINESS_UNIT", 
          upper("OPERATING_PLAN_ID") OPERATING_PLAN_ID, 
          "OP", 
          "BUGZILLA_ID", 
          "NAME_DESCRIPTION", 
          "PROJECT_ID", 
          "DEPT", 
          "PM", 
          "STATUS", 
          "START_OF_UAT", 
          "COMPLETION_DATE", 
          "MDAYS_PRJ", 
          "CONSUMED_PLANNED", 
          "COMPANY",
          'Time and Material' PTYPE
  from v_rep_mdays_per_cr 
  union all
  select   /* Fixed Price Projects from Q1 2015 */
          business_unit, 
          upper(operating_plan_id) OPERATING_PLAN_ID, 
          case when operating_plan_id IS NULL then 'NOT IN OP' when operating_plan_id like '%2015%' then 'IN OP 2015' else 'IN OP (not 2015)' end OP,
          bugzilla_id,
          name_description,
          null project_id,
          null dept,
          pm,
          'COMPLETED' status,
          null start_of_uat,
          date'2015-03-31' completion_date,
          to_number(mdays) MDAYS_PRJ,
          'CONSUMED'  CONSUMED_PLANNED,
          'UNISYSTEMS'  COMPANY,
          'Fixed Price' PTYPE
  from fixed_price_prjs_from_xls
  order by business_unit, bugzilla_id,  project_id desc, name_description,  status, company, consumed_planned
) t;

select * from fixed_price_prjs_from_xls;

select rownum r, t.* from v_rep_mdays_per_cr t;

create or replace view v_rep_mdays_per_cr as
  select  business_unit, 
          operating_plan_id, case when operating_plan_id IS NULL then 'NOT IN OP' when operating_plan_id like '%2015%' then 'IN OP 2015' else 'IN OP (not 2015)' end OP,
          bugzilla_id, name_description, project_id, dept, pm, status, start_of_uat, completion_date,
          round(sum(mdays_prj_day),1) mdays_prj, consumed_planned, company 
  from (
    -- 1 row per day, project
    select  s3.business_unit,
            s3.operating_plan_id,
            s1.project_id, 
            s3.bugzilla_id,
            s1.date_key, 
            s3.name_description,
            s3.dept,
            s3.pm,
            --s3.prj_type,
            s3.status,  
            s3.start_of_uat,
            s3.completion_date,
            sum(mdays_prj_day_dev) mdays_prj_day,
            s1.consumed_planned,
            s2.company
    from (
        -- base query: 1 row per (developer,project,day)
        select  t1.*, 
                case when DATE_KEY < trunc(SYSDATE) + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev
        from pmapp.v_day_prj_dev t1 
        where 1=1
          AND t1.project_id <> -2  -- exclude leaves          
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by  project_id, date_key, developers_id, start_date
    ) s1 
        join developers s2 on(s1.developers_id = s2.id)
          join prjs s3  on (s1.project_id = s3.id)
    where 1=1
      AND nvl(s1.free_of_charge_ind,0) <> 1  -- exclude free of charge
      AND s3.prj_type = 'Change Request'
      --AND s3.dept <> 'MDW'
    group by s1.project_id, s3.bugzilla_id, s1.date_key, s3.business_unit, s3.operating_plan_id, s3.name_description, s3.dept, s3.pm,  s3.status, s3.start_of_uat,
            s3.completion_date, s2.company, s1.consumed_planned
    order by business_unit, project_id, date_key, company
  ) p1
  where 1=1
  group by project_id, name_description, bugzilla_id, dept, pm, status, start_of_uat,
           completion_date, business_unit, operating_plan_id, company, consumed_planned,
           case when operating_plan_id IS NULL then 'NOT IN OP' when operating_plan_id like '%2015%' then 'IN OP 2015' else 'IN OP (not 2015)' end
  order by business_unit, bugzilla_id,  project_id desc, name_description,  status, company, consumed_planned;

  --  ****  MANDAYS PER CR
--  VERSION 1 
--    Mandays are NOT "Elapsed Days", so we have to calculate the percentage of the day allocated to a CR
--    so as not to double count the days
--    USE a "CONSUMED_PLAN" column so as not to have to use 2 separate views to show consumed vs. plannes mandays

select * from v_rep_mdays_per_cr;

create or replace view v_rep_mdays_per_cr as
  select  business_unit, 
          operating_plan_id, case when operating_plan_id IS NULL then 'NOT IN OP' when operating_plan_id like '%2015%' then 'IN OP 2015' else 'IN OP (not 2015)' end OP,
          bugzilla_id, name_description, project_id, dept, pm, status, start_of_uat, completion_date,
          round(sum(mdays_prj_day),1) mdays_prj, consumed_planned, company 
  from (
    -- 1 row per day, project
    select  s3.business_unit,
            s3.operating_plan_id,
            s1.project_id, 
            s3.bugzilla_id,
            s1.date_key, 
            s3.name_description,
            s3.dept,
            s3.pm,
            --s3.prj_type,
            s3.status,  
            s3.start_of_uat,
            s3.completion_date,
            sum(mdays_prj_day_dev) mdays_prj_day,
            s1.consumed_planned,
            s2.company
    from (
        -- base query: 1 row per (developer,project,day)
        select  t1.*, 
                case when DATE_KEY <= SYSDATE + 1 then 'CONSUMED' ELSE 'PLANNED' end consumed_planned,
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev
        from pmapp.v_day_prj_dev t1 
        where 1=1
          AND t1.project_id >= 0 -- exclude all "special type" projects
          AND nvl(t1.free_of_charge_ind,0) <> 1
          --AND project_id <> -2 -- exclude leaves 
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by  project_id, date_key, developers_id, start_date
    ) s1 
        join developers s2 on(s1.developers_id = s2.id)
          join prjs s3  on (s1.project_id = s3.id)
    where 1=1
      AND s3.prj_type = 'Change Request'
      --AND s3.dept <> 'MDW'
    group by s1.project_id, s3.bugzilla_id, s1.date_key, s3.business_unit, s3.operating_plan_id, s3.name_description, s3.dept, s3.pm,  s3.status, s3.start_of_uat,
            s3.completion_date, s2.company, s1.consumed_planned
    order by business_unit, project_id, date_key, company
  ) p1
  where 1=1
  group by project_id, name_description, bugzilla_id, dept, pm, status, start_of_uat,
           completion_date, business_unit, operating_plan_id, company, consumed_planned,
           case when operating_plan_id IS NULL then 'NOT IN OP' when operating_plan_id like '%2015%' then 'IN OP 2015' else 'IN OP (not 2015)' end
  order by business_unit, bugzilla_id,  project_id desc, name_description,  status, company, consumed_planned;


/********************************************* OBSOLETE ******************************************************/


--  ****  DAYS ALLOCATED PER DEVELOPER (excluding leaves, operational support): i.e., consumed + planned in the future
select * from pmapp.v_rep_mdays_alloc_per_dev;


create or replace view pmapp.v_rep_mdays_alloc_per_dev
as
  select nvl(t2.name,'TOTAL') dev_name, count(t1.date_key) mandays, round(count(t1.date_key)/sum(case when t2.name IS NULL then 0 else count(t1.date_key) end) over()*100,1) pct
  from (
    select  developers_id, 
            date_key, 
            listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
            --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
            --count(distinct project_id) num_projects
    from (
        -- base query: 1 row per (developer,project,day)
        select *
        from pmapp.v_day_prj_dev 
        where 1=1
          --AND project_id <> -2 -- exclude leaves (Comment out this filter because I will put it after list_agg aggregation. This due to the fact that sometimes project assignments appear in the same day with a leave (-2). So the filter at this point it is not gauranteed to exclude all days with leaves)
          AND project_id <> -1 -- exclude operational support
          AND project_id <> 0 -- exclude generic task
          AND nvl(free_of_charge_ind, 0) <> 1
        order by developers_id, date_key, project_id, start_date
    ) 
    group by developers_id, date_key
  ) t1
    join developers t2 on(t1.developers_id = t2.id)
  where 1=1
    AND instr(t1.projects, '-2') = 0 -- exclude days that contain a leave     
  group by rollup(t2.name)
  order by 2 desc;

--  ****  DAYS CONSUMED PER DEVELOPER (i.e., up to sysdate, including today) (excluding leaves, operational support)
select * from pmapp.v_rep_mdays_cons_per_dev;

create or replace view pmapp.v_rep_mdays_cons_per_dev
as
  select nvl(t2.name,'TOTAL') dev_name, count(t1.date_key) mandays, round(count(t1.date_key)/sum(case when t2.name IS NULL then 0 else count(t1.date_key) end) over()*100,1) pct
  from (
    -- 1 row per day, developer
    select  developers_id, 
            date_key, 
            listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
            --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
            --count(distinct project_id) num_projects
    from (
        -- base query: 1 row per (developer,project,day)
        select *
        from pmapp.v_day_prj_dev 
        where 1=1
          --AND project_id <> -2 -- exclude leaves (Comment out this filter because I will put it after list_agg aggregation. This due to the fact that sometimes project assignments appear in the same day with a leave (-2). So the filter at this point it is not gauranteed to exclude all days with leaves)
          AND project_id <> -1 -- exclude operational support
          AND project_id <> 0 -- exclude generic task
          AND nvl(free_of_charge_ind, 0) <> 1
          AND DATE_KEY <= SYSDATE + 1
        order by developers_id, date_key, project_id, start_date
    ) 
    group by developers_id, date_key
  ) t1
    join developers t2 on(t1.developers_id = t2.id)
  where 1=1
    AND instr(t1.projects, '-2') = 0 -- exclude days that contain a leave 
  group by rollup(t2.name)
  order by 2 desc;


--  ****  MANDAYS ALLOCATED PER CR
--    Mandays are NOT "Elapsed Days", so we have to calculate the percentage of the day allocated to a CR
--    so as not to double count the days

select * from v_rep_mdays_alloc_per_cr;

create or replace view v_rep_mdays_alloc_per_cr as
  select  business_unit, operating_plan_id, bugzilla_id, name_description, project_id, dept, pm, status, start_of_uat, completion_date,
          round(sum(mdays_prj_day),1) mdays_prj, company 
  from (
    -- 1 row per day, project
    select  s3.business_unit,
            s3.operating_plan_id,
            s1.project_id, 
            s3.bugzilla_id,
            s1.date_key, 
            s3.name_description,
            s3.dept,
            s3.pm,
            --s3.prj_type,
            s3.status,  
            s3.start_of_uat,
            s3.completion_date,
            sum(mdays_prj_day_dev) mdays_prj_day,
            s2.company
    from (
        -- base query: 1 row per (developer,project,day)
        select  t1.*,  
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev
        from pmapp.v_day_prj_dev t1 
        where 1=1
          AND t1.project_id > 0 -- exclude all "special type" projects
          AND nvl(t1.free_of_charge_ind, 0) <> 1
          --AND project_id <> -2 -- exclude leaves 
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          --AND DATE_KEY <= SYSDATE + 1
        order by  project_id, date_key, developers_id, start_date
    ) s1 
        join developers s2 on(s1.developers_id = s2.id)
          join prjs s3  on (s1.project_id = s3.id)
    where 1=1
      AND s3.prj_type = 'Change Request'
      --AND s3.dept <> 'MDW'
    group by s1.project_id, s3.bugzilla_id, s1.date_key, s3.business_unit, s3.operating_plan_id, s3.name_description, s3.dept, s3.pm,  s3.status, s3.start_of_uat,
            s3.completion_date, s2.company
    order by business_unit, project_id, date_key, company
  ) p1
  where 1=1
  group by project_id, name_description, bugzilla_id, dept, pm, status, start_of_uat,
           completion_date, business_unit, operating_plan_id, company
  order by business_unit, bugzilla_id,  project_id desc, name_description,  status, company;
  
--  ****  MANDAYS CONSUMED PER CR (i.e., up to today)
--    Mandays are NOT "Elapsed Days", so we have to calculate the percentage of the day allocated to a CR
--    so as not to double count the days

select * from v_rep_mdays_cons_per_cr;

create or replace view v_rep_mdays_cons_per_cr as
  select  business_unit, operating_plan_id, bugzilla_id, name_description, project_id, dept, pm, status, start_of_uat, completion_date,
          round(sum(mdays_prj_day),1) mdays_prj, company 
  from (
    -- 1 row per day, project
    select  s3.business_unit,
            s3.operating_plan_id,
            s1.project_id, 
            s3.bugzilla_id,
            s1.date_key, 
            s3.name_description,
            s3.dept,
            s3.pm,
            --s3.prj_type,
            s3.status,  
            s3.start_of_uat,
            s3.completion_date,
            sum(mdays_prj_day_dev) mdays_prj_day,
            s2.company
    from (
        -- base query: 1 row per (developer,project,day)
        select  t1.*,  
                round(1/count(project_id) over(partition by date_key, developers_id),2) mdays_prj_day_dev
        from pmapp.v_day_prj_dev t1 
        where 1=1
          AND t1.project_id > 0 -- exclude all "special type" projects
          AND t1.free_of_charge_ind <> 1
          --AND project_id <> -2 -- exclude leaves 
          --AND project_id <> -1 -- exclude operational support
          --AND project_id <> 0 -- exclude generic task
          AND DATE_KEY <= SYSDATE + 1
        order by  project_id, date_key, developers_id, start_date
    ) s1 
        join developers s2 on(s1.developers_id = s2.id)
          join prjs s3  on (s1.project_id = s3.id)
    where 1=1
      AND s3.prj_type = 'Change Request'
      --AND s3.dept <> 'MDW'
    group by s1.project_id, s3.bugzilla_id, s1.date_key, s3.business_unit, s3.operating_plan_id, s3.name_description, s3.dept, s3.pm,  s3.status, s3.start_of_uat,
            s3.completion_date, s2.company
    order by business_unit, project_id, date_key, company
  ) p1
  where 1=1
  group by project_id, name_description, bugzilla_id, dept, pm, status, start_of_uat,
           completion_date, business_unit, operating_plan_id, company
  order by business_unit, bugzilla_id,  project_id desc, name_description,  status, company;  
 