/*
GOAL:
  generate some test developer to projects assignments and then 
  create developers availabilility query
*/

-- generate test data = developers to projects assignments
ALTER TABLE pmapp.DEV_PRJS disable CONSTRAINT DEV_PRJS_PK 
ALTER TABLE pmapp.DEV_PRJS disable CONSTRAINT DEV_PRJS_DEVELOPERS_FK
ALTER TABLE pmapp.DEV_PRJS disable CONSTRAINT DEV_PRJS_PRJS_FK

ALTER TABLE pmapp.DEV_PRJS enable CONSTRAINT DEV_PRJS_PK;
ALTER TABLE pmapp.DEV_PRJS enable CONSTRAINT DEV_PRJS_DEVELOPERS_FK;
ALTER TABLE pmapp.DEV_PRJS enable CONSTRAINT DEV_PRJS_PRJS_FK;

insert into PMAPP.DEV_PRJS (developers_id, prjs_id, start_date)
with q as
(select id from (select id from pmapp.prjs order by dbms_random.random) where rownum = 1)  
select  abs(mod(dbms_random.random,9)) d_id,
        12 p_id,
        sysdate + abs(mod(dbms_random.random,30)) sd
from q
connect by level < 100     

commit;


update PMAPP.DEV_PRJS
 set prjs_id =  abs(mod(dbms_random.random,11))  

commit;

update PMAPP.DEV_PRJS
  set end_date = start_date + abs(mod(dbms_random.random,50));  

update PMAPP.DEV_PRJS
  set duration = end_date - start_date;

commit;

update PMAPP.DEV_PRJS
 set developers_id =  1 + abs(mod(dbms_random.random,8)) 
 where developers_id = 0;

select *
from PMAPP.DEV_PRJS t
where
  t.PRJS_ID not in (select distinct id from PMAPP.PRJS);
  
update PMAPP.DEV_PRJS
  set prjs_id = 4 + abs(mod(dbms_random.random,7)) 
where prjs_id < 5;

commit;


-- clear the tables
create table pmapp.DEV_PRJS_TEST
as select * from  DEV_PRJS;

select * from pmapp.DEV_PRJS_TEST;

delete from  DEV_PRJS;
commit;

select *
from prjs
where
  id <= 0;
  
create table pmapp.prjs_old
as select * from prjs where id > 0;

delete from prjs
where id > 0;


commit;
------------------------------------------------------------------------------------------
-- these are the raw data
select developers_id, prjs_id, start_date, end_date
from PMAPP.DEV_PRJS
order by developers_id, prjs_id, start_date;


---------------------------------
-- VERSION 10 
--    *add Yannis.Lazaridis@gr.ey.com   цИэММГР кАФАЯъДГР YANNIS LAZARIDIS
--    Yiannis.G.Panselinas@gr.ey.com цИэММГР пАМСЕКГМэР YANNIS PANSELINAS
--    as developers
--
---------------------------------

-- ****************************
-- THIS IS the CORRECT UNPIVOTED query
-- It shows per day the projects for each developer
-- we DONT need an partition OUTER JOIN. We just need to join to date_dim with a "between predicate" instead of an equality join
-- *****************************
select  developers_id, 
        date_key, 
        listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
        --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
        --count(distinct project_id) num_projects
from (
    -- base query: 1 row per (developer,project,day)
    select * 
    from (
          select  a.developers_id, 
                  '<i title ="'||b.name_description||'">'||
                  case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'CR'||b.bugzilla_id||'</a>'
                        when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                        else  to_char(b.id)
                  end || 
                    decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', '(ED)', 'йоутяас', '(DK)', 'йкеисоуяа', '(TK)', 'цеыяциоу', '(KG)', 'папабасикеиоу', '(SP)', 'савимоцкоу', '(MS)' , 'DAUBILLY', '(CD)', b.pm) 
                    ||'</i>'
                  project_id,                  
                  a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
          from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
          --order by developers_id, start_date 
          ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id, date_key, project_id, start_date
) 
group by developers_id, date_key;

------------------------
-- PIVOT query  - to show developers availability
--------------------
-- highlight per PM (this is the APEX query)
select  sysdate today, date_key,  
        case when "GEORGE PAPOUTSOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE PAPOUTSOPOULOS"||'</font></b>' ELSE "GEORGE PAPOUTSOPOULOS" END "GEORGE PAPOUTSOPOULOS",
        case when "IOANNIS MAVRAKAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS MAVRAKAKIS"||'</font></b>' ELSE "IOANNIS MAVRAKAKIS" END "IOANNIS MAVRAKAKIS",
        case when "IOANNIS THEODORAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS THEODORAKIS"||'</font></b>' ELSE "IOANNIS THEODORAKIS" END "IOANNIS THEODORAKIS",
        case when "THEMIS BACHOUROS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEMIS BACHOUROS"||'</font></b>' ELSE "THEMIS BACHOUROS" END "THEMIS BACHOUROS",
        case when "DIMITRIS PSYCHOGIOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS PSYCHOGIOPOULOS"||'</font></b>' ELSE "DIMITRIS PSYCHOGIOPOULOS" END "DIMITRIS PSYCHOGIOPOULOS",
        case when "LAMBROS ALEXIOY" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"LAMBROS ALEXIOY"||'</font></b>' ELSE "LAMBROS ALEXIOY" END "LAMBROS ALEXIOY",
        case when "APOSTOLOS MANTES" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"APOSTOLOS MANTES"||'</font></b>' ELSE "APOSTOLOS MANTES" END "APOSTOLOS MANTES",
        case when "MARIA APOSTOLOPOULOU" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"MARIA APOSTOLOPOULOU"||'</font></b>' ELSE "MARIA APOSTOLOPOULOU" END "MARIA APOSTOLOPOULOU",
        case when "YEVGENIYA VASYLYEVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"YEVGENIYA VASYLYEVA"||'</font></b>' ELSE "YEVGENIYA VASYLYEVA" END "YEVGENIYA VASYLYEVA",
        case when "GEORGE TZEDAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE TZEDAKIS"||'</font></b>' ELSE "GEORGE TZEDAKIS" END "GEORGE TZEDAKIS",
        case when "RANIA GALANI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"RANIA GALANI"||'</font></b>' ELSE "RANIA GALANI" END "RANIA GALANI",
        case when "DIMITRIS AKRIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS AKRIOTIS"||'</font></b>' ELSE "DIMITRIS AKRIOTIS" END "DIMITRIS AKRIOTIS",
        case when "ALEXANDRA KALIVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ALEXANDRA KALIVA"||'</font></b>' ELSE "ALEXANDRA KALIVA" END "ALEXANDRA KALIVA",
        case when "STAMATIS CHRYSIKOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"STAMATIS CHRYSIKOPOULOS"||'</font></b>' ELSE "STAMATIS CHRYSIKOPOULOS" END "STAMATIS CHRYSIKOPOULOS",
        case when "KOSTAS TSIGOUNIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"KOSTAS TSIGOUNIS"||'</font></b>' ELSE "KOSTAS TSIGOUNIS" END "KOSTAS TSIGOUNIS",
        case when "SOTIRIA PLATI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"SOTIRIA PLATI"||'</font></b>' ELSE "SOTIRIA PLATI" END "SOTIRIA PLATI",   --     "IOANNIS MAVRAKAKIS" , "IOANNIS THEODORAKIS", "THEMIS BACHOUROS", "DIMITRIS PSYCHOGIOPOULOS", "LAMBROS ALEXIOY", "APOSTOLOS MANTES", "NIKOLAOS KOYROYNIS"       
        case when "THEODOROS PANAGIOTAKOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEODOROS PANAGIOTAKOS"||'</font></b>' ELSE "THEODOROS PANAGIOTAKOS" END "THEODOROS PANAGIOTAKOS",
        case when "EFSTRATIOS DERMITZIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"EFSTRATIOS DERMITZIOTIS"||'</font></b>' ELSE "EFSTRATIOS DERMITZIOTIS" END "EFSTRATIOS DERMITZIOTIS",
        case when "ELENI KAPODISTRIA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ELENI KAPODISTRIA"||'</font></b>' ELSE "ELENI KAPODISTRIA" END "ELENI KAPODISTRIA",
        case when "GEORGIOS XANTHOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGIOS XANTHOPOULOS"||'</font></b>' ELSE "GEORGIOS XANTHOPOULOS" END "GEORGIOS XANTHOPOULOS",
        case when "MANOS PAPANDREOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"MANOS PAPANDREOPOULOS"||'</font></b>' ELSE "MANOS PAPANDREOPOULOS" END "MANOS PAPANDREOPOULOS",
        case when "NIKOS MAKRIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"NIKOS MAKRIS"||'</font></b>' ELSE "NIKOS MAKRIS" END "NIKOS MAKRIS",
        case when "EIRINI CHARKIANAKI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"EIRINI CHARKIANAKI"||'</font></b>' ELSE "EIRINI CHARKIANAKI" END "EIRINI CHARKIANAKI",
        case when "YANNIS LAZARIDIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"YANNIS LAZARIDIS"||'</font></b>' ELSE "YANNIS LAZARIDIS" END "YANNIS LAZARIDIS",
        case when "YANNIS PANSELINAS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"YANNIS PANSELINAS"||'</font></b>' ELSE "YANNIS PANSELINAS" END "YANNIS PANSELINAS"
from PMAPP.V_DEVELOPERS_AVAILABILITY10;

select *
from PMAPP.V_DEVELOPERS_AVAILABILITY10;

create or replace view pmapp.v_developers_availability10 (
  date_key,  
  "GEORGE PAPOUTSOPOULOS", 
  "IOANNIS MAVRAKAKIS", 
  "IOANNIS THEODORAKIS", 
  "THEMIS BACHOUROS", 
  "DIMITRIS PSYCHOGIOPOULOS", 
  "LAMBROS ALEXIOY", 
  "APOSTOLOS MANTES", 
  "MARIA APOSTOLOPOULOU", 
  "YEVGENIYA VASYLYEVA", 
  "GEORGE TZEDAKIS", 
  "RANIA GALANI", 
  "DIMITRIS AKRIOTIS", 
  "ALEXANDRA KALIVA", 
  "STAMATIS CHRYSIKOPOULOS", 
  "KOSTAS TSIGOUNIS", 
  "SOTIRIA PLATI" ,
  "THEODOROS PANAGIOTAKOS",
  "EFSTRATIOS DERMITZIOTIS",
  "ELENI KAPODISTRIA",
  "GEORGIOS XANTHOPOULOS",
  "MANOS PAPANDREOPOULOS",
  "NIKOS MAKRIS",
  "EIRINI CHARKIANAKI",
  "YANNIS LAZARIDIS",
  "YANNIS PANSELINAS"
)as
select *
from (
  select  developers_id, 
          date_key, 
          listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
          --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
          --count(distinct project_id) num_projects
  from (
      -- base query: 1 row per (developer,project,day)
      select * 
      from (
            select  a.developers_id, 
                    '<i title ="'||b.name_description||' - ' ||"COMMENT"  || '">'||
                    case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'BZ'||b.bugzilla_id||'</a>'
                          --when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                          when b.id = -2 THEN 'апоусиа'
                          when b.id = -1 THEN '<b><font color="green">'||'OpSup'||'</font></b>'
                          when b.id = 0 THEN 'GenTask'  --1041332975875001
                          else  '<a href="http://ex1-scan.ote.gr:'||&prod_or_preprod||'/apex/f?p=113:15:'||v('APP_SESSION')||'::NO::P15_PRJS_ID:'||to_char(b.id)||'">'||'PM'||to_char(b.id)||'</a>'
                    end || 
                      decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', '(ED)', 'йоутяас', '(DK)', 'йкеисоуяа', '(TK)', 'цеыяциоу', '(KG)', 'папабасикеиоу', '(SP)', 'савимоцкоу', '(MS)' , 'DAUBILLY', '(CD)', b.pm) 
                      ||'</i>'
                    project_id,                  
                    a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
            from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
            --order by developers_id, start_date 
            ) t1
        --partition by (t1.developers_id, t1.prjs_id)
        --right outer 
        join
                (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
      on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
      order by developers_id, date_key, project_id, start_date
  ) 
  group by developers_id, date_key
) s 
PIVOT (
 max(projects) as projects 
 for developers_id in ( 0 as "GEORGE PAPOUTSOPOULOS", 
                        1 as "IOANNIS MAVRAKAKIS", 
                        2 as "IOANNIS THEODORAKIS", 
                        3 as "THEMIS BACHOUROS", 
                        4 as "DIMITRIS PSYCHOGIOPOULOS", 
                        5 as "LAMBROS ALEXIOY", 
                        6 as "APOSTOLOS MANTES", 
                        7 as "MARIA APOSTOLOPOULOU", 
                        8 as "YEVGENIYA VASYLYEVA", 
                        9 as "GEORGE TZEDAKIS", 
                        10 as "RANIA GALANI", 
                        11 as "DIMITRIS AKRIOTIS", 
                        12 as "ALEXANDRA KALIVA", 
                        13 as "STAMATIS CHRYSIKOPOULOS", 
                        14 as "KOSTAS TSIGOUNIS", 
                        15 as "SOTIRIA PLATI",
                        16 as "THEODOROS PANAGIOTAKOS",
                        17 as "EFSTRATIOS DERMITZIOTIS",
                        18 as "ELENI KAPODISTRIA",
                        19 as "GEORGIOS XANTHOPOULOS",
                        20 as "MANOS PAPANDREOPOULOS",
                        21 as  "NIKOS MAKRIS",
                        22 as "EIRINI CHARKIANAKI",
                        23 as "YANNIS LAZARIDIS",
                        24 as "YANNIS PANSELINAS")
)
order by date_key;

---------------------------------
-- VERSION 9 
--    *add Corentin Daubilly as PM

-- ****************************
-- THIS IS the CORRECT UNPIVOTED query
-- It shows per day the projects for each developer
-- we DONT need an partition OUTER JOIN. We just need to join to date_dim with a "between predicate" instead of an equality join
-- *****************************
select  developers_id, 
        date_key, 
        listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
        --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
        --count(distinct project_id) num_projects
from (
    -- base query: 1 row per (developer,project,day)
    select * 
    from (
          select  a.developers_id, 
                  '<i title ="'||b.name_description||'">'||
                  case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'CR'||b.bugzilla_id||'</a>'
                        when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                        else  to_char(b.id)
                  end || 
                    decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', '(ED)', 'йоутяас', '(DK)', 'йкеисоуяа', '(TK)', 'цеыяциоу', '(KG)', 'папабасикеиоу', '(SP)', 'савимоцкоу', '(MS)' , 'DAUBILLY', '(CD)', b.pm) 
                    ||'</i>'
                  project_id,                  
                  a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
          from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
          --order by developers_id, start_date 
          ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id, date_key, project_id, start_date
) 
group by developers_id, date_key;

------------------------
-- PIVOT query  - to show developers availability
--------------------
-- highlight per PM (this is the APEX query)
select  sysdate today, date_key,  
        case when "GEORGE PAPOUTSOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE PAPOUTSOPOULOS"||'</font></b>' ELSE "GEORGE PAPOUTSOPOULOS" END "GEORGE PAPOUTSOPOULOS",
        case when "IOANNIS MAVRAKAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS MAVRAKAKIS"||'</font></b>' ELSE "IOANNIS MAVRAKAKIS" END "IOANNIS MAVRAKAKIS",
        case when "IOANNIS THEODORAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS THEODORAKIS"||'</font></b>' ELSE "IOANNIS THEODORAKIS" END "IOANNIS THEODORAKIS",
        case when "THEMIS BACHOUROS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEMIS BACHOUROS"||'</font></b>' ELSE "THEMIS BACHOUROS" END "THEMIS BACHOUROS",
        case when "DIMITRIS PSYCHOGIOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS PSYCHOGIOPOULOS"||'</font></b>' ELSE "DIMITRIS PSYCHOGIOPOULOS" END "DIMITRIS PSYCHOGIOPOULOS",
        case when "LAMBROS ALEXIOY" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"LAMBROS ALEXIOY"||'</font></b>' ELSE "LAMBROS ALEXIOY" END "LAMBROS ALEXIOY",
        case when "APOSTOLOS MANTES" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"APOSTOLOS MANTES"||'</font></b>' ELSE "APOSTOLOS MANTES" END "APOSTOLOS MANTES",
        case when "MARIA APOSTOLOPOULOU" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"MARIA APOSTOLOPOULOU"||'</font></b>' ELSE "MARIA APOSTOLOPOULOU" END "MARIA APOSTOLOPOULOU",
        case when "YEVGENIYA VASYLYEVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"YEVGENIYA VASYLYEVA"||'</font></b>' ELSE "YEVGENIYA VASYLYEVA" END "YEVGENIYA VASYLYEVA",
        case when "GEORGE TZEDAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE TZEDAKIS"||'</font></b>' ELSE "GEORGE TZEDAKIS" END "GEORGE TZEDAKIS",
        case when "RANIA GALANI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"RANIA GALANI"||'</font></b>' ELSE "RANIA GALANI" END "RANIA GALANI",
        case when "DIMITRIS AKRIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS AKRIOTIS"||'</font></b>' ELSE "DIMITRIS AKRIOTIS" END "DIMITRIS AKRIOTIS",
        case when "ALEXANDRA KALIVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ALEXANDRA KALIVA"||'</font></b>' ELSE "ALEXANDRA KALIVA" END "ALEXANDRA KALIVA",
        case when "STAMATIS CHRYSIKOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"STAMATIS CHRYSIKOPOULOS"||'</font></b>' ELSE "STAMATIS CHRYSIKOPOULOS" END "STAMATIS CHRYSIKOPOULOS",
        case when "KOSTAS TSIGOUNIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"KOSTAS TSIGOUNIS"||'</font></b>' ELSE "KOSTAS TSIGOUNIS" END "KOSTAS TSIGOUNIS",
        case when "SOTIRIA PLATI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"SOTIRIA PLATI"||'</font></b>' ELSE "SOTIRIA PLATI" END "SOTIRIA PLATI",   --     "IOANNIS MAVRAKAKIS" , "IOANNIS THEODORAKIS", "THEMIS BACHOUROS", "DIMITRIS PSYCHOGIOPOULOS", "LAMBROS ALEXIOY", "APOSTOLOS MANTES", "NIKOLAOS KOYROYNIS"       
        case when "THEODOROS PANAGIOTAKOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEODOROS PANAGIOTAKOS"||'</font></b>' ELSE "THEODOROS PANAGIOTAKOS" END "THEODOROS PANAGIOTAKOS",
        case when "EFSTRATIOS DERMITZIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"EFSTRATIOS DERMITZIOTIS"||'</font></b>' ELSE "EFSTRATIOS DERMITZIOTIS" END "EFSTRATIOS DERMITZIOTIS",
        case when "ELENI KAPODISTRIA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ELENI KAPODISTRIA"||'</font></b>' ELSE "ELENI KAPODISTRIA" END "ELENI KAPODISTRIA",
        case when "GEORGIOS XANTHOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGIOS XANTHOPOULOS"||'</font></b>' ELSE "GEORGIOS XANTHOPOULOS" END "GEORGIOS XANTHOPOULOS",
        case when "MANOS PAPANDREOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"MANOS PAPANDREOPOULOS"||'</font></b>' ELSE "MANOS PAPANDREOPOULOS" END "MANOS PAPANDREOPOULOS",
        case when "NIKOS MAKRIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"NIKOS MAKRIS"||'</font></b>' ELSE "NIKOS MAKRIS" END "NIKOS MAKRIS",
        case when "EIRINI CHARKIANAKI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"EIRINI CHARKIANAKI"||'</font></b>' ELSE "EIRINI CHARKIANAKI" END "EIRINI CHARKIANAKI"
from PMAPP.V_DEVELOPERS_AVAILABILITY9;

select *
from PMAPP.V_DEVELOPERS_AVAILABILITY9;

create or replace view pmapp.v_developers_availability9 (
  date_key,  
  "GEORGE PAPOUTSOPOULOS", 
  "IOANNIS MAVRAKAKIS", 
  "IOANNIS THEODORAKIS", 
  "THEMIS BACHOUROS", 
  "DIMITRIS PSYCHOGIOPOULOS", 
  "LAMBROS ALEXIOY", 
  "APOSTOLOS MANTES", 
  "MARIA APOSTOLOPOULOU", 
  "YEVGENIYA VASYLYEVA", 
  "GEORGE TZEDAKIS", 
  "RANIA GALANI", 
  "DIMITRIS AKRIOTIS", 
  "ALEXANDRA KALIVA", 
  "STAMATIS CHRYSIKOPOULOS", 
  "KOSTAS TSIGOUNIS", 
  "SOTIRIA PLATI" ,
  "THEODOROS PANAGIOTAKOS",
  "EFSTRATIOS DERMITZIOTIS",
  "ELENI KAPODISTRIA",
  "GEORGIOS XANTHOPOULOS",
  "MANOS PAPANDREOPOULOS",
  "NIKOS MAKRIS",
  "EIRINI CHARKIANAKI"
)as
select *
from (
  select  developers_id, 
          date_key, 
          listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
          --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
          --count(distinct project_id) num_projects
  from (
      -- base query: 1 row per (developer,project,day)
      select * 
      from (
            select  a.developers_id, 
                    '<i title ="'||b.name_description||' - ' ||"COMMENT"  || '">'||
                    case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'BZ'||b.bugzilla_id||'</a>'
                          --when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                          when b.id = -2 THEN 'апоусиа'
                          when b.id = -1 THEN '<b><font color="green">'||'OpSup'||'</font></b>'
                          when b.id = 0 THEN 'GenTask'  --1041332975875001
                          else  '<a href="http://ex1-scan.ote.gr:'||&prod_or_preprod||'/apex/f?p=113:15:'||v('APP_SESSION')||'::NO::P15_PRJS_ID:'||to_char(b.id)||'">'||'PM'||to_char(b.id)||'</a>'
                    end || 
                      decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', '(ED)', 'йоутяас', '(DK)', 'йкеисоуяа', '(TK)', 'цеыяциоу', '(KG)', 'папабасикеиоу', '(SP)', 'савимоцкоу', '(MS)' , 'DAUBILLY', '(CD)', b.pm) 
                      ||'</i>'
                    project_id,                  
                    a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
            from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
            --order by developers_id, start_date 
            ) t1
        --partition by (t1.developers_id, t1.prjs_id)
        --right outer 
        join
                (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
      on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
      order by developers_id, date_key, project_id, start_date
  ) 
  group by developers_id, date_key
) s 
PIVOT (
 max(projects) as projects 
 for developers_id in ( 0 as "GEORGE PAPOUTSOPOULOS", 
                        1 as "IOANNIS MAVRAKAKIS", 
                        2 as "IOANNIS THEODORAKIS", 
                        3 as "THEMIS BACHOUROS", 
                        4 as "DIMITRIS PSYCHOGIOPOULOS", 
                        5 as "LAMBROS ALEXIOY", 
                        6 as "APOSTOLOS MANTES", 
                        7 as "MARIA APOSTOLOPOULOU", 
                        8 as "YEVGENIYA VASYLYEVA", 
                        9 as "GEORGE TZEDAKIS", 
                        10 as "RANIA GALANI", 
                        11 as "DIMITRIS AKRIOTIS", 
                        12 as "ALEXANDRA KALIVA", 
                        13 as "STAMATIS CHRYSIKOPOULOS", 
                        14 as "KOSTAS TSIGOUNIS", 
                        15 as "SOTIRIA PLATI",
                        16 as "THEODOROS PANAGIOTAKOS",
                        17 as "EFSTRATIOS DERMITZIOTIS",
                        18 as "ELENI KAPODISTRIA",
                        19 as "GEORGIOS XANTHOPOULOS",
                        20 as "MANOS PAPANDREOPOULOS",
                        21 as  "NIKOS MAKRIS",
                        22 as "EIRINI CHARKIANAKI")
)
order by date_key;


---------------------------------
-- VERSION 8 
--    *add Eirini Charkianaki (Relational)

-- ****************************
-- THIS IS the CORRECT UNPIVOTED query
-- It shows per day the projects for each developer
-- we DONT need an partition OUTER JOIN. We just need to join to date_dim with a "between predicate" instead of an equality join
-- *****************************
select  developers_id, 
        date_key, 
        listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
        --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
        --count(distinct project_id) num_projects
from (
    -- base query: 1 row per (developer,project,day)
    select * 
    from (
          select  a.developers_id, 
                  '<i title ="'||b.name_description||'">'||
                  case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'CR'||b.bugzilla_id||'</a>'
                        when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                        else  to_char(b.id)
                  end || 
                    decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', 'ED', 'йоутяас', 'DK', 'йкеисоуяа', 'TK', 'цеыяциоу', 'KG', 'папабасикеиоу', 'SP', 'савимоцкоу', 'MS' ,b.pm) 
                    ||'</i>'
                  project_id,                  
                  a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
          from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
          --order by developers_id, start_date 
          ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id, date_key, project_id, start_date
) 
group by developers_id, date_key;

------------------------
-- PIVOT query  - to show developers availability
--------------------
-- highlight per PM (this is the APEX query)
select  sysdate today, date_key,  
        case when "GEORGE PAPOUTSOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE PAPOUTSOPOULOS"||'</font></b>' ELSE "GEORGE PAPOUTSOPOULOS" END "GEORGE PAPOUTSOPOULOS",
        case when "IOANNIS MAVRAKAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS MAVRAKAKIS"||'</font></b>' ELSE "IOANNIS MAVRAKAKIS" END "IOANNIS MAVRAKAKIS",
        case when "IOANNIS THEODORAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS THEODORAKIS"||'</font></b>' ELSE "IOANNIS THEODORAKIS" END "IOANNIS THEODORAKIS",
        case when "THEMIS BACHOUROS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEMIS BACHOUROS"||'</font></b>' ELSE "THEMIS BACHOUROS" END "THEMIS BACHOUROS",
        case when "DIMITRIS PSYCHOGIOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS PSYCHOGIOPOULOS"||'</font></b>' ELSE "DIMITRIS PSYCHOGIOPOULOS" END "DIMITRIS PSYCHOGIOPOULOS",
        case when "LAMBROS ALEXIOY" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"LAMBROS ALEXIOY"||'</font></b>' ELSE "LAMBROS ALEXIOY" END "LAMBROS ALEXIOY",
        case when "APOSTOLOS MANTES" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"APOSTOLOS MANTES"||'</font></b>' ELSE "APOSTOLOS MANTES" END "APOSTOLOS MANTES",
        case when "MARIA APOSTOLOPOULOU" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"MARIA APOSTOLOPOULOU"||'</font></b>' ELSE "MARIA APOSTOLOPOULOU" END "MARIA APOSTOLOPOULOU",
        case when "YEVGENIYA VASYLYEVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"YEVGENIYA VASYLYEVA"||'</font></b>' ELSE "YEVGENIYA VASYLYEVA" END "YEVGENIYA VASYLYEVA",
        case when "GEORGE TZEDAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE TZEDAKIS"||'</font></b>' ELSE "GEORGE TZEDAKIS" END "GEORGE TZEDAKIS",
        case when "RANIA GALANI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"RANIA GALANI"||'</font></b>' ELSE "RANIA GALANI" END "RANIA GALANI",
        case when "DIMITRIS AKRIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS AKRIOTIS"||'</font></b>' ELSE "DIMITRIS AKRIOTIS" END "DIMITRIS AKRIOTIS",
        case when "ALEXANDRA KALIVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ALEXANDRA KALIVA"||'</font></b>' ELSE "ALEXANDRA KALIVA" END "ALEXANDRA KALIVA",
        case when "STAMATIS CHRYSIKOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"STAMATIS CHRYSIKOPOULOS"||'</font></b>' ELSE "STAMATIS CHRYSIKOPOULOS" END "STAMATIS CHRYSIKOPOULOS",
        case when "KOSTAS TSIGOUNIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"KOSTAS TSIGOUNIS"||'</font></b>' ELSE "KOSTAS TSIGOUNIS" END "KOSTAS TSIGOUNIS",
        case when "SOTIRIA PLATI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"SOTIRIA PLATI"||'</font></b>' ELSE "SOTIRIA PLATI" END "SOTIRIA PLATI",   --     "IOANNIS MAVRAKAKIS" , "IOANNIS THEODORAKIS", "THEMIS BACHOUROS", "DIMITRIS PSYCHOGIOPOULOS", "LAMBROS ALEXIOY", "APOSTOLOS MANTES", "NIKOLAOS KOYROYNIS"       
        case when "THEODOROS PANAGIOTAKOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEODOROS PANAGIOTAKOS"||'</font></b>' ELSE "THEODOROS PANAGIOTAKOS" END "THEODOROS PANAGIOTAKOS",
        case when "EFSTRATIOS DERMITZIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"EFSTRATIOS DERMITZIOTIS"||'</font></b>' ELSE "EFSTRATIOS DERMITZIOTIS" END "EFSTRATIOS DERMITZIOTIS",
        case when "ELENI KAPODISTRIA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ELENI KAPODISTRIA"||'</font></b>' ELSE "ELENI KAPODISTRIA" END "ELENI KAPODISTRIA",
        case when "GEORGIOS XANTHOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGIOS XANTHOPOULOS"||'</font></b>' ELSE "GEORGIOS XANTHOPOULOS" END "GEORGIOS XANTHOPOULOS",
        case when "MANOS PAPANDREOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"MANOS PAPANDREOPOULOS"||'</font></b>' ELSE "MANOS PAPANDREOPOULOS" END "MANOS PAPANDREOPOULOS",
        case when "NIKOS MAKRIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"NIKOS MAKRIS"||'</font></b>' ELSE "NIKOS MAKRIS" END "NIKOS MAKRIS",
        case when "EIRINI CHARKIANAKI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"EIRINI CHARKIANAKI"||'</font></b>' ELSE "EIRINI CHARKIANAKI" END "EIRINI CHARKIANAKI"
from PMAPP.V_DEVELOPERS_AVAILABILITY8;

select *
from PMAPP.V_DEVELOPERS_AVAILABILITY8;

create or replace view pmapp.v_developers_availability8 (
  date_key,  
  "GEORGE PAPOUTSOPOULOS", 
  "IOANNIS MAVRAKAKIS", 
  "IOANNIS THEODORAKIS", 
  "THEMIS BACHOUROS", 
  "DIMITRIS PSYCHOGIOPOULOS", 
  "LAMBROS ALEXIOY", 
  "APOSTOLOS MANTES", 
  "MARIA APOSTOLOPOULOU", 
  "YEVGENIYA VASYLYEVA", 
  "GEORGE TZEDAKIS", 
  "RANIA GALANI", 
  "DIMITRIS AKRIOTIS", 
  "ALEXANDRA KALIVA", 
  "STAMATIS CHRYSIKOPOULOS", 
  "KOSTAS TSIGOUNIS", 
  "SOTIRIA PLATI" ,
  "THEODOROS PANAGIOTAKOS",
  "EFSTRATIOS DERMITZIOTIS",
  "ELENI KAPODISTRIA",
  "GEORGIOS XANTHOPOULOS",
  "MANOS PAPANDREOPOULOS",
  "NIKOS MAKRIS",
  "EIRINI CHARKIANAKI"
)as
select *
from (
  select  developers_id, 
          date_key, 
          listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
          --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
          --count(distinct project_id) num_projects
  from (
      -- base query: 1 row per (developer,project,day)
      select * 
      from (
            select  a.developers_id, 
                    '<i title ="'||b.name_description||' - ' ||"COMMENT"  || '">'||
                    case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'BZ'||b.bugzilla_id||'</a>'
                          --when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                          when b.id = -2 THEN 'апоусиа'
                          when b.id = -1 THEN '<b><font color="green">'||'OpSup'||'</font></b>'
                          when b.id = 0 THEN 'GenTask'  --1041332975875001
                          else  '<a href="http://ex1-scan.ote.gr:'||&prod_or_preprod||'/apex/f?p=113:15:'||v('APP_SESSION')||'::NO::P15_PRJS_ID:'||to_char(b.id)||'">'||'PM'||to_char(b.id)||'</a>'
                    end || 
                      decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', '(ED)', 'йоутяас', '(DK)', 'йкеисоуяа', '(TK)', 'цеыяциоу', '(KG)', 'папабасикеиоу', '(SP)', 'савимоцкоу', '(MS)' ,b.pm) 
                      ||'</i>'
                    project_id,                  
                    a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
            from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
            --order by developers_id, start_date 
            ) t1
        --partition by (t1.developers_id, t1.prjs_id)
        --right outer 
        join
                (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
      on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
      order by developers_id, date_key, project_id, start_date
  ) 
  group by developers_id, date_key
) s 
PIVOT (
 max(projects) as projects 
 for developers_id in ( 0 as "GEORGE PAPOUTSOPOULOS", 
                        1 as "IOANNIS MAVRAKAKIS", 
                        2 as "IOANNIS THEODORAKIS", 
                        3 as "THEMIS BACHOUROS", 
                        4 as "DIMITRIS PSYCHOGIOPOULOS", 
                        5 as "LAMBROS ALEXIOY", 
                        6 as "APOSTOLOS MANTES", 
                        7 as "MARIA APOSTOLOPOULOU", 
                        8 as "YEVGENIYA VASYLYEVA", 
                        9 as "GEORGE TZEDAKIS", 
                        10 as "RANIA GALANI", 
                        11 as "DIMITRIS AKRIOTIS", 
                        12 as "ALEXANDRA KALIVA", 
                        13 as "STAMATIS CHRYSIKOPOULOS", 
                        14 as "KOSTAS TSIGOUNIS", 
                        15 as "SOTIRIA PLATI",
                        16 as "THEODOROS PANAGIOTAKOS",
                        17 as "EFSTRATIOS DERMITZIOTIS",
                        18 as "ELENI KAPODISTRIA",
                        19 as "GEORGIOS XANTHOPOULOS",
                        20 as "MANOS PAPANDREOPOULOS",
                        21 as  "NIKOS MAKRIS",
                        22 as "EIRINI CHARKIANAKI")
)
order by date_key;


---------------------------------
-- VERSION 7 
--    *add Microsoft developers

-- ****************************
-- THIS IS the CORRECT UNPIVOTED query
-- It shows per day the projects for each developer
-- we DONT need an partition OUTER JOIN. We just need to join to date_dim with a "between predicate" instead of an equality join
-- *****************************
select  developers_id, 
        date_key, 
        listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
        --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
        --count(distinct project_id) num_projects
from (
    -- base query: 1 row per (developer,project,day)
    select * 
    from (
          select  a.developers_id, 
                  '<i title ="'||b.name_description||'">'||
                  case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'CR'||b.bugzilla_id||'</a>'
                        when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                        else  to_char(b.id)
                  end || 
                    decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', 'ED', 'йоутяас', 'DK', 'йкеисоуяа', 'TK', 'цеыяциоу', 'KG', 'папабасикеиоу', 'SP', 'савимоцкоу', 'MS' ,b.pm) 
                    ||'</i>'
                  project_id,                  
                  a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
          from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
          --order by developers_id, start_date 
          ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id, date_key, project_id, start_date
) 
group by developers_id, date_key;

------------------------
-- PIVOT query  - to show developers availability
--------------------
-- highlight per PM (this is the APEX query)
select  sysdate today, date_key,  
        case when "GEORGE PAPOUTSOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE PAPOUTSOPOULOS"||'</font></b>' ELSE "GEORGE PAPOUTSOPOULOS" END "GEORGE PAPOUTSOPOULOS",
        case when "IOANNIS MAVRAKAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS MAVRAKAKIS"||'</font></b>' ELSE "IOANNIS MAVRAKAKIS" END "IOANNIS MAVRAKAKIS",
        case when "IOANNIS THEODORAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS THEODORAKIS"||'</font></b>' ELSE "IOANNIS THEODORAKIS" END "IOANNIS THEODORAKIS",
        case when "THEMIS BACHOUROS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEMIS BACHOUROS"||'</font></b>' ELSE "THEMIS BACHOUROS" END "THEMIS BACHOUROS",
        case when "DIMITRIS PSYCHOGIOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS PSYCHOGIOPOULOS"||'</font></b>' ELSE "DIMITRIS PSYCHOGIOPOULOS" END "DIMITRIS PSYCHOGIOPOULOS",
        case when "LAMBROS ALEXIOY" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"LAMBROS ALEXIOY"||'</font></b>' ELSE "LAMBROS ALEXIOY" END "LAMBROS ALEXIOY",
        case when "APOSTOLOS MANTES" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"APOSTOLOS MANTES"||'</font></b>' ELSE "APOSTOLOS MANTES" END "APOSTOLOS MANTES",
        case when "MARIA APOSTOLOPOULOU" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"MARIA APOSTOLOPOULOU"||'</font></b>' ELSE "MARIA APOSTOLOPOULOU" END "MARIA APOSTOLOPOULOU",
        case when "YEVGENIYA VASYLYEVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"YEVGENIYA VASYLYEVA"||'</font></b>' ELSE "YEVGENIYA VASYLYEVA" END "YEVGENIYA VASYLYEVA",
        case when "GEORGE TZEDAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE TZEDAKIS"||'</font></b>' ELSE "GEORGE TZEDAKIS" END "GEORGE TZEDAKIS",
        case when "RANIA GALANI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"RANIA GALANI"||'</font></b>' ELSE "RANIA GALANI" END "RANIA GALANI",
        case when "DIMITRIS AKRIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS AKRIOTIS"||'</font></b>' ELSE "DIMITRIS AKRIOTIS" END "DIMITRIS AKRIOTIS",
        case when "ALEXANDRA KALIVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ALEXANDRA KALIVA"||'</font></b>' ELSE "ALEXANDRA KALIVA" END "ALEXANDRA KALIVA",
        case when "STAMATIS CHRYSIKOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"STAMATIS CHRYSIKOPOULOS"||'</font></b>' ELSE "STAMATIS CHRYSIKOPOULOS" END "STAMATIS CHRYSIKOPOULOS",
        case when "KOSTAS TSIGOUNIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"KOSTAS TSIGOUNIS"||'</font></b>' ELSE "KOSTAS TSIGOUNIS" END "KOSTAS TSIGOUNIS",
        case when "SOTIRIA PLATI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"SOTIRIA PLATI"||'</font></b>' ELSE "SOTIRIA PLATI" END "SOTIRIA PLATI",   --     "IOANNIS MAVRAKAKIS" , "IOANNIS THEODORAKIS", "THEMIS BACHOUROS", "DIMITRIS PSYCHOGIOPOULOS", "LAMBROS ALEXIOY", "APOSTOLOS MANTES", "NIKOLAOS KOYROYNIS"       
        case when "THEODOROS PANAGIOTAKOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEODOROS PANAGIOTAKOS"||'</font></b>' ELSE "THEODOROS PANAGIOTAKOS" END "THEODOROS PANAGIOTAKOS",
        case when "EFSTRATIOS DERMITZIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"EFSTRATIOS DERMITZIOTIS"||'</font></b>' ELSE "EFSTRATIOS DERMITZIOTIS" END "EFSTRATIOS DERMITZIOTIS",
        case when "ELENI KAPODISTRIA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ELENI KAPODISTRIA"||'</font></b>' ELSE "ELENI KAPODISTRIA" END "ELENI KAPODISTRIA",
        case when "GEORGIOS XANTHOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGIOS XANTHOPOULOS"||'</font></b>' ELSE "GEORGIOS XANTHOPOULOS" END "GEORGIOS XANTHOPOULOS",
        case when "MANOS PAPANDREOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGIOS XANTHOPOULOS"||'</font></b>' ELSE "GEORGIOS XANTHOPOULOS" END "MANOS PAPANDREOPOULOS",
        case when "NIKOS MAKRIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGIOS XANTHOPOULOS"||'</font></b>' ELSE "GEORGIOS XANTHOPOULOS" END "NIKOS MAKRIS"
from PMAPP.V_DEVELOPERS_AVAILABILITY7;

select *
from PMAPP.V_DEVELOPERS_AVAILABILITY7;

create or replace view pmapp.v_developers_availability7 (
  date_key,  
  "GEORGE PAPOUTSOPOULOS", 
  "IOANNIS MAVRAKAKIS", 
  "IOANNIS THEODORAKIS", 
  "THEMIS BACHOUROS", 
  "DIMITRIS PSYCHOGIOPOULOS", 
  "LAMBROS ALEXIOY", 
  "APOSTOLOS MANTES", 
  "MARIA APOSTOLOPOULOU", 
  "YEVGENIYA VASYLYEVA", 
  "GEORGE TZEDAKIS", 
  "RANIA GALANI", 
  "DIMITRIS AKRIOTIS", 
  "ALEXANDRA KALIVA", 
  "STAMATIS CHRYSIKOPOULOS", 
  "KOSTAS TSIGOUNIS", 
  "SOTIRIA PLATI" ,
  "THEODOROS PANAGIOTAKOS",
  "EFSTRATIOS DERMITZIOTIS",
  "ELENI KAPODISTRIA",
  "GEORGIOS XANTHOPOULOS",
  "MANOS PAPANDREOPOULOS",
  "NIKOS MAKRIS"
)as
select *
from (
  select  developers_id, 
          date_key, 
          listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
          --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
          --count(distinct project_id) num_projects
  from (
      -- base query: 1 row per (developer,project,day)
      select * 
      from (
            select  a.developers_id, 
                    '<i title ="'||b.name_description||' - ' ||"COMMENT"  || '">'||
                    case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'BZ'||b.bugzilla_id||'</a>'
                          --when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                          when b.id = -2 THEN 'апоусиа'
                          when b.id = -1 THEN '<b><font color="green">'||'OpSup'||'</font></b>'
                          when b.id = 0 THEN 'GenTask'  --1041332975875001
                          else  '<a href="http://ex1-scan.ote.gr:'||&prod_or_preprod||'/apex/f?p=113:15:'||v('APP_SESSION')||'::NO::P15_PRJS_ID:'||to_char(b.id)||'">'||'PM'||to_char(b.id)||'</a>'
                    end || 
                      decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', '(ED)', 'йоутяас', '(DK)', 'йкеисоуяа', '(TK)', 'цеыяциоу', '(KG)', 'папабасикеиоу', '(SP)', 'савимоцкоу', '(MS)' ,b.pm) 
                      ||'</i>'
                    project_id,                  
                    a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
            from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
            --order by developers_id, start_date 
            ) t1
        --partition by (t1.developers_id, t1.prjs_id)
        --right outer 
        join
                (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
      on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
      order by developers_id, date_key, project_id, start_date
  ) 
  group by developers_id, date_key
) s 
PIVOT (
 max(projects) as projects 
 for developers_id in ( 0 as "GEORGE PAPOUTSOPOULOS", 
                        1 as "IOANNIS MAVRAKAKIS", 
                        2 as "IOANNIS THEODORAKIS", 
                        3 as "THEMIS BACHOUROS", 
                        4 as "DIMITRIS PSYCHOGIOPOULOS", 
                        5 as "LAMBROS ALEXIOY", 
                        6 as "APOSTOLOS MANTES", 
                        7 as "MARIA APOSTOLOPOULOU", 
                        8 as "YEVGENIYA VASYLYEVA", 
                        9 as "GEORGE TZEDAKIS", 
                        10 as "RANIA GALANI", 
                        11 as "DIMITRIS AKRIOTIS", 
                        12 as "ALEXANDRA KALIVA", 
                        13 as "STAMATIS CHRYSIKOPOULOS", 
                        14 as "KOSTAS TSIGOUNIS", 
                        15 as "SOTIRIA PLATI",
                        16 as "THEODOROS PANAGIOTAKOS",
                        17 as "EFSTRATIOS DERMITZIOTIS",
                        18 as "ELENI KAPODISTRIA",
                        19 as "GEORGIOS XANTHOPOULOS",
                        20 as "MANOS PAPANDREOPOULOS",
                        21 as  "NIKOS MAKRIS")
)
order by date_key;


---------------------------------
-- VERSION 6 
--    *add link based on PMAPP id

-- ****************************
-- THIS IS the CORRECT UNPIVOTED query
-- It shows per day the projects for each developer
-- we DONT need an partition OUTER JOIN. We just need to join to date_dim with a "between predicate" instead of an equality join
-- *****************************
select  developers_id, 
        date_key, 
        listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
        --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
        --count(distinct project_id) num_projects
from (
    -- base query: 1 row per (developer,project,day)
    select * 
    from (
          select  a.developers_id, 
                  '<i title ="'||b.name_description||'">'||
                  case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'CR'||b.bugzilla_id||'</a>'
                        when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                        else  to_char(b.id)
                  end || 
                    decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', 'ED', 'йоутяас', 'DK', 'йкеисоуяа', 'TK', 'цеыяциоу', 'KG', 'папабасикеиоу', 'SP', 'савимоцкоу', 'MS' ,b.pm) 
                    ||'</i>'
                  project_id,                  
                  a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
          from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
          --order by developers_id, start_date 
          ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id, date_key, project_id, start_date
) 
group by developers_id, date_key;

------------------------
-- PIVOT query  - to show developers availability
--------------------
-- highlight per PM (this is the APEX query)
select  sysdate today, date_key,  
        case when "GEORGE PAPOUTSOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE PAPOUTSOPOULOS"||'</font></b>' ELSE "GEORGE PAPOUTSOPOULOS" END "GEORGE PAPOUTSOPOULOS",
        case when "IOANNIS MAVRAKAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS MAVRAKAKIS"||'</font></b>' ELSE "IOANNIS MAVRAKAKIS" END "IOANNIS MAVRAKAKIS",
        case when "IOANNIS THEODORAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS THEODORAKIS"||'</font></b>' ELSE "IOANNIS THEODORAKIS" END "IOANNIS THEODORAKIS",
        case when "THEMIS BACHOUROS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEMIS BACHOUROS"||'</font></b>' ELSE "THEMIS BACHOUROS" END "THEMIS BACHOUROS",
        case when "DIMITRIS PSYCHOGIOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS PSYCHOGIOPOULOS"||'</font></b>' ELSE "DIMITRIS PSYCHOGIOPOULOS" END "DIMITRIS PSYCHOGIOPOULOS",
        case when "LAMBROS ALEXIOY" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"LAMBROS ALEXIOY"||'</font></b>' ELSE "LAMBROS ALEXIOY" END "LAMBROS ALEXIOY",
        case when "APOSTOLOS MANTES" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"APOSTOLOS MANTES"||'</font></b>' ELSE "APOSTOLOS MANTES" END "APOSTOLOS MANTES",
        case when "MARIA APOSTOLOPOULOU" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"MARIA APOSTOLOPOULOU"||'</font></b>' ELSE "MARIA APOSTOLOPOULOU" END "MARIA APOSTOLOPOULOU",
        case when "YEVGENIYA VASYLYEVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"YEVGENIYA VASYLYEVA"||'</font></b>' ELSE "YEVGENIYA VASYLYEVA" END "YEVGENIYA VASYLYEVA",
        case when "GEORGE TZEDAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE TZEDAKIS"||'</font></b>' ELSE "GEORGE TZEDAKIS" END "GEORGE TZEDAKIS",
        case when "RANIA GALANI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"RANIA GALANI"||'</font></b>' ELSE "RANIA GALANI" END "RANIA GALANI",
        case when "DIMITRIS AKRIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS AKRIOTIS"||'</font></b>' ELSE "DIMITRIS AKRIOTIS" END "DIMITRIS AKRIOTIS",
        case when "ALEXANDRA KALIVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ALEXANDRA KALIVA"||'</font></b>' ELSE "ALEXANDRA KALIVA" END "ALEXANDRA KALIVA",
        case when "STAMATIS CHRYSIKOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"STAMATIS CHRYSIKOPOULOS"||'</font></b>' ELSE "STAMATIS CHRYSIKOPOULOS" END "STAMATIS CHRYSIKOPOULOS",
        case when "KOSTAS TSIGOUNIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"KOSTAS TSIGOUNIS"||'</font></b>' ELSE "KOSTAS TSIGOUNIS" END "KOSTAS TSIGOUNIS",
        case when "SOTIRIA PLATI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"SOTIRIA PLATI"||'</font></b>' ELSE "SOTIRIA PLATI" END "SOTIRIA PLATI",   --     "IOANNIS MAVRAKAKIS" , "IOANNIS THEODORAKIS", "THEMIS BACHOUROS", "DIMITRIS PSYCHOGIOPOULOS", "LAMBROS ALEXIOY", "APOSTOLOS MANTES", "NIKOLAOS KOYROYNIS"       
        case when "THEODOROS PANAGIOTAKOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEODOROS PANAGIOTAKOS"||'</font></b>' ELSE "THEODOROS PANAGIOTAKOS" END "THEODOROS PANAGIOTAKOS",
        case when "EFSTRATIOS DERMITZIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"EFSTRATIOS DERMITZIOTIS"||'</font></b>' ELSE "EFSTRATIOS DERMITZIOTIS" END "EFSTRATIOS DERMITZIOTIS",
        case when "ELENI KAPODISTRIA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ELENI KAPODISTRIA"||'</font></b>' ELSE "ELENI KAPODISTRIA" END "ELENI KAPODISTRIA",
        case when "GEORGIOS XANTHOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGIOS XANTHOPOULOS"||'</font></b>' ELSE "GEORGIOS XANTHOPOULOS" END "GEORGIOS XANTHOPOULOS"
from PMAPP.V_DEVELOPERS_AVAILABILITY6;

select *
from PMAPP.V_DEVELOPERS_AVAILABILITY6;

create or replace view pmapp.v_developers_availability6 (
  date_key,  
  "GEORGE PAPOUTSOPOULOS", 
  "IOANNIS MAVRAKAKIS", 
  "IOANNIS THEODORAKIS", 
  "THEMIS BACHOUROS", 
  "DIMITRIS PSYCHOGIOPOULOS", 
  "LAMBROS ALEXIOY", 
  "APOSTOLOS MANTES", 
  "MARIA APOSTOLOPOULOU", 
  "YEVGENIYA VASYLYEVA", 
  "GEORGE TZEDAKIS", 
  "RANIA GALANI", 
  "DIMITRIS AKRIOTIS", 
  "ALEXANDRA KALIVA", 
  "STAMATIS CHRYSIKOPOULOS", 
  "KOSTAS TSIGOUNIS", 
  "SOTIRIA PLATI" ,
  "THEODOROS PANAGIOTAKOS",
  "EFSTRATIOS DERMITZIOTIS",
  "ELENI KAPODISTRIA",
  "GEORGIOS XANTHOPOULOS"
)as
select *
from (
  select  developers_id, 
          date_key, 
          listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
          --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
          --count(distinct project_id) num_projects
  from (
      -- base query: 1 row per (developer,project,day)
      select * 
      from (
            select  a.developers_id, 
                    '<i title ="'||b.name_description||' - ' ||"COMMENT"  || '">'||
                    case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'BZ'||b.bugzilla_id||'</a>'
                          --when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                          when b.id = -2 THEN 'апоусиа'
                          when b.id = -1 THEN '<b><font color="green">'||'OpSup'||'</font></b>'
                          when b.id = 0 THEN 'GenTask'  --1041332975875001
                          else  '<a href="http://ex1-scan.ote.gr:'||&prod_or_preprod||'/apex/f?p=113:15:'||v('APP_SESSION')||'::NO::P15_PRJS_ID:'||to_char(b.id)||'">'||'PM'||to_char(b.id)||'</a>'
                    end || 
                      decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', '(ED)', 'йоутяас', '(DK)', 'йкеисоуяа', '(TK)', 'цеыяциоу', '(KG)', 'папабасикеиоу', '(SP)', 'савимоцкоу', '(MS)' ,b.pm) 
                      ||'</i>'
                    project_id,                  
                    a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
            from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
            --order by developers_id, start_date 
            ) t1
        --partition by (t1.developers_id, t1.prjs_id)
        --right outer 
        join
                (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
      on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
      order by developers_id, date_key, project_id, start_date
  ) 
  group by developers_id, date_key
) s 
PIVOT (
 max(projects) as projects 
 for developers_id in ( 0 as "GEORGE PAPOUTSOPOULOS", 
                        1 as "IOANNIS MAVRAKAKIS", 
                        2 as "IOANNIS THEODORAKIS", 
                        3 as "THEMIS BACHOUROS", 
                        4 as "DIMITRIS PSYCHOGIOPOULOS", 
                        5 as "LAMBROS ALEXIOY", 
                        6 as "APOSTOLOS MANTES", 
                        7 as "MARIA APOSTOLOPOULOU", 
                        8 as "YEVGENIYA VASYLYEVA", 
                        9 as "GEORGE TZEDAKIS", 
                        10 as "RANIA GALANI", 
                        11 as "DIMITRIS AKRIOTIS", 
                        12 as "ALEXANDRA KALIVA", 
                        13 as "STAMATIS CHRYSIKOPOULOS", 
                        14 as "KOSTAS TSIGOUNIS", 
                        15 as "SOTIRIA PLATI",
                        16 as "THEODOROS PANAGIOTAKOS",
                        17 as "EFSTRATIOS DERMITZIOTIS",
                        18 as "ELENI KAPODISTRIA",
                        19 as "GEORGIOS XANTHOPOULOS")
)
order by date_key;

---------------------------------
-- VERSION 5 
--    *add more MDW and BI developers

-- ****************************
-- THIS IS the CORRECT UNPIVOTED query
-- It shows per day the projects for each developer
-- we DONT need an partition OUTER JOIN. We just need to join to date_dim with a "between predicate" instead of an equality join
-- *****************************
select  developers_id, 
        date_key, 
        listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
        --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
        --count(distinct project_id) num_projects
from (
    -- base query: 1 row per (developer,project,day)
    select * 
    from (
          select  a.developers_id, 
                  '<i title ="'||b.name_description||'">'||
                  case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'CR'||b.bugzilla_id||'</a>'
                        when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                        else  to_char(b.id)
                  end || 
                    decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', 'ED', 'йоутяас', 'DK', 'йкеисоуяа', 'TK', 'цеыяциоу', 'KG', 'папабасикеиоу', 'SP', 'савимоцкоу', 'MS' ,b.pm) 
                    ||'</i>'
                  project_id,                  
                  a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
          from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
          --order by developers_id, start_date 
          ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id, date_key, project_id, start_date
) 
group by developers_id, date_key;

------------------------
-- PIVOT query  - to show developers availability
--------------------
-- highlight per PM (this is the APEX query)
select  sysdate today, date_key,  
        case when "GEORGE PAPOUTSOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE PAPOUTSOPOULOS"||'</font></b>' ELSE "GEORGE PAPOUTSOPOULOS" END "GEORGE PAPOUTSOPOULOS",
        case when "IOANNIS MAVRAKAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS MAVRAKAKIS"||'</font></b>' ELSE "IOANNIS MAVRAKAKIS" END "IOANNIS MAVRAKAKIS",
        case when "IOANNIS THEODORAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS THEODORAKIS"||'</font></b>' ELSE "IOANNIS THEODORAKIS" END "IOANNIS THEODORAKIS",
        case when "THEMIS BACHOUROS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEMIS BACHOUROS"||'</font></b>' ELSE "THEMIS BACHOUROS" END "THEMIS BACHOUROS",
        case when "DIMITRIS PSYCHOGIOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS PSYCHOGIOPOULOS"||'</font></b>' ELSE "DIMITRIS PSYCHOGIOPOULOS" END "DIMITRIS PSYCHOGIOPOULOS",
        case when "LAMBROS ALEXIOY" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"LAMBROS ALEXIOY"||'</font></b>' ELSE "LAMBROS ALEXIOY" END "LAMBROS ALEXIOY",
        case when "APOSTOLOS MANTES" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"APOSTOLOS MANTES"||'</font></b>' ELSE "APOSTOLOS MANTES" END "APOSTOLOS MANTES",
        case when "MARIA APOSTOLOPOULOU" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"MARIA APOSTOLOPOULOU"||'</font></b>' ELSE "MARIA APOSTOLOPOULOU" END "MARIA APOSTOLOPOULOU",
        case when "YEVGENIYA VASYLYEVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"YEVGENIYA VASYLYEVA"||'</font></b>' ELSE "YEVGENIYA VASYLYEVA" END "YEVGENIYA VASYLYEVA",
        case when "GEORGE TZEDAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE TZEDAKIS"||'</font></b>' ELSE "GEORGE TZEDAKIS" END "GEORGE TZEDAKIS",
        case when "RANIA GALANI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"RANIA GALANI"||'</font></b>' ELSE "RANIA GALANI" END "RANIA GALANI",
        case when "DIMITRIS AKRIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS AKRIOTIS"||'</font></b>' ELSE "DIMITRIS AKRIOTIS" END "DIMITRIS AKRIOTIS",
        case when "ALEXANDRA KALIVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ALEXANDRA KALIVA"||'</font></b>' ELSE "ALEXANDRA KALIVA" END "ALEXANDRA KALIVA",
        case when "STAMATIS CHRYSIKOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"STAMATIS CHRYSIKOPOULOS"||'</font></b>' ELSE "STAMATIS CHRYSIKOPOULOS" END "STAMATIS CHRYSIKOPOULOS",
        case when "KOSTAS TSIGOUNIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"KOSTAS TSIGOUNIS"||'</font></b>' ELSE "KOSTAS TSIGOUNIS" END "KOSTAS TSIGOUNIS",
        case when "SOTIRIA PLATI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"SOTIRIA PLATI"||'</font></b>' ELSE "SOTIRIA PLATI" END "SOTIRIA PLATI",   --     "IOANNIS MAVRAKAKIS" , "IOANNIS THEODORAKIS", "THEMIS BACHOUROS", "DIMITRIS PSYCHOGIOPOULOS", "LAMBROS ALEXIOY", "APOSTOLOS MANTES", "NIKOLAOS KOYROYNIS"       
        case when "THEODOROS PANAGIOTAKOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEODOROS PANAGIOTAKOS"||'</font></b>' ELSE "THEODOROS PANAGIOTAKOS" END "THEODOROS PANAGIOTAKOS",
        case when "EFSTRATIOS DERMITZIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"EFSTRATIOS DERMITZIOTIS"||'</font></b>' ELSE "EFSTRATIOS DERMITZIOTIS" END "EFSTRATIOS DERMITZIOTIS",
        case when "ELENI KAPODISTRIA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ELENI KAPODISTRIA"||'</font></b>' ELSE "ELENI KAPODISTRIA" END "ELENI KAPODISTRIA",
        case when "GEORGIOS XANTHOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGIOS XANTHOPOULOS"||'</font></b>' ELSE "GEORGIOS XANTHOPOULOS" END "GEORGIOS XANTHOPOULOS"
from PMAPP.V_DEVELOPERS_AVAILABILITY5;

select *
from PMAPP.V_DEVELOPERS_AVAILABILITY5;

create or replace view pmapp.v_developers_availability5 (
  date_key,  
  "GEORGE PAPOUTSOPOULOS", 
  "IOANNIS MAVRAKAKIS", 
  "IOANNIS THEODORAKIS", 
  "THEMIS BACHOUROS", 
  "DIMITRIS PSYCHOGIOPOULOS", 
  "LAMBROS ALEXIOY", 
  "APOSTOLOS MANTES", 
  "MARIA APOSTOLOPOULOU", 
  "YEVGENIYA VASYLYEVA", 
  "GEORGE TZEDAKIS", 
  "RANIA GALANI", 
  "DIMITRIS AKRIOTIS", 
  "ALEXANDRA KALIVA", 
  "STAMATIS CHRYSIKOPOULOS", 
  "KOSTAS TSIGOUNIS", 
  "SOTIRIA PLATI" ,
  "THEODOROS PANAGIOTAKOS",
  "EFSTRATIOS DERMITZIOTIS",
  "ELENI KAPODISTRIA",
  "GEORGIOS XANTHOPOULOS"
)as
select *
from (
  select  developers_id, 
          date_key, 
          listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
          --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
          --count(distinct project_id) num_projects
  from (
      -- base query: 1 row per (developer,project,day)
      select * 
      from (
            select  a.developers_id, 
                    '<i title ="'||b.name_description||' - ' ||"COMMENT"  || '">'||
                    case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'CR'||b.bugzilla_id||'</a>'
                          when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                          when b.id = -2 THEN 'апоусиа'
                          when b.id = -1 THEN '<b><font color="green">'||'OpSup'||'</font></b>'
                          when b.id = 0 THEN 'GenTask'
                          else  to_char(b.id)
                    end || 
                      decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', 'ED', 'йоутяас', 'DK', 'йкеисоуяа', 'TK', 'цеыяциоу', 'KG', 'папабасикеиоу', 'SP', 'савимоцкоу', 'MS' ,b.pm) 
                      ||'</i>'
                    project_id,                  
                    a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
            from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
            --order by developers_id, start_date 
            ) t1
        --partition by (t1.developers_id, t1.prjs_id)
        --right outer 
        join
                (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
      on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
      order by developers_id, date_key, project_id, start_date
  ) 
  group by developers_id, date_key
) s 
PIVOT (
 max(projects) as projects 
 for developers_id in ( 0 as "GEORGE PAPOUTSOPOULOS", 
                        1 as "IOANNIS MAVRAKAKIS", 
                        2 as "IOANNIS THEODORAKIS", 
                        3 as "THEMIS BACHOUROS", 
                        4 as "DIMITRIS PSYCHOGIOPOULOS", 
                        5 as "LAMBROS ALEXIOY", 
                        6 as "APOSTOLOS MANTES", 
                        7 as "MARIA APOSTOLOPOULOU", 
                        8 as "YEVGENIYA VASYLYEVA", 
                        9 as "GEORGE TZEDAKIS", 
                        10 as "RANIA GALANI", 
                        11 as "DIMITRIS AKRIOTIS", 
                        12 as "ALEXANDRA KALIVA", 
                        13 as "STAMATIS CHRYSIKOPOULOS", 
                        14 as "KOSTAS TSIGOUNIS", 
                        15 as "SOTIRIA PLATI",
                        16 as "THEODOROS PANAGIOTAKOS",
                        17 as "EFSTRATIOS DERMITZIOTIS",
                        18 as "ELENI KAPODISTRIA",
                        19 as "GEORGIOS XANTHOPOULOS")
)
order by date_key;

-----------------------------------------------
-- VERSION 4 
--    *add MDW and BI developers and PMs

-- ****************************
-- THIS IS the CORRECT UNPIVOTED query
-- It shows per day the projects for each developer
-- we DONT need an partition OUTER JOIN. We just need to join to date_dim with a "between predicate" instead of an equality join
-- *****************************
select  developers_id, 
        date_key, 
        listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
        --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
        --count(distinct project_id) num_projects
from (
    -- base query: 1 row per (developer,project,day)
    select * 
    from (
          select  a.developers_id, 
                  '<i title ="'||b.name_description||'">'||
                  case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'CR'||b.bugzilla_id||'</a>'
                        when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                        else  to_char(b.id)
                  end || 
                    decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', 'ED', 'йоутяас', 'DK', 'йкеисоуяа', 'TK', 'цеыяциоу', 'KG', 'папабасикеиоу', 'SP', 'савимоцкоу', 'MS' ,b.pm) 
                    ||'</i>'
                  project_id,                  
                  a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
          from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
          --order by developers_id, start_date 
          ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id, date_key, project_id, start_date
) 
group by developers_id, date_key;

------------------------
-- PIVOT query  - to show developers availability
--------------------
-- highlight per PM (this is the APEX query)
select  sysdate today, date_key,  
        case when "GEORGE PAPOUTSOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE PAPOUTSOPOULOS"||'</font></b>' ELSE "GEORGE PAPOUTSOPOULOS" END "GEORGE PAPOUTSOPOULOS",
        case when "IOANNIS MAVRAKAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS MAVRAKAKIS"||'</font></b>' ELSE "IOANNIS MAVRAKAKIS" END "IOANNIS MAVRAKAKIS",
        case when "IOANNIS THEODORAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS THEODORAKIS"||'</font></b>' ELSE "IOANNIS THEODORAKIS" END "IOANNIS THEODORAKIS",
        case when "THEMIS BACHOUROS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEMIS BACHOUROS"||'</font></b>' ELSE "THEMIS BACHOUROS" END "THEMIS BACHOUROS",
        case when "DIMITRIS PSYCHOGIOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS PSYCHOGIOPOULOS"||'</font></b>' ELSE "DIMITRIS PSYCHOGIOPOULOS" END "DIMITRIS PSYCHOGIOPOULOS",
        case when "LAMBROS ALEXIOY" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"LAMBROS ALEXIOY"||'</font></b>' ELSE "LAMBROS ALEXIOY" END "LAMBROS ALEXIOY",
        case when "APOSTOLOS MANTES" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"APOSTOLOS MANTES"||'</font></b>' ELSE "APOSTOLOS MANTES" END "APOSTOLOS MANTES",
        case when "MARIA APOSTOLOPOULOU" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"MARIA APOSTOLOPOULOU"||'</font></b>' ELSE "MARIA APOSTOLOPOULOU" END "MARIA APOSTOLOPOULOU",
        case when "YEVGENIYA VASYLYEVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"YEVGENIYA VASYLYEVA"||'</font></b>' ELSE "YEVGENIYA VASYLYEVA" END "YEVGENIYA VASYLYEVA",
        case when "GEORGE TZEDAKIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE TZEDAKIS"||'</font></b>' ELSE "GEORGE TZEDAKIS" END "GEORGE TZEDAKIS",
        case when "ELENI MANTZIORI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ELENI MANTZIORI"||'</font></b>' ELSE "ELENI MANTZIORI" END "ELENI MANTZIORI",
        case when "DIMITRIS AKRIOTIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS AKRIOTIS"||'</font></b>' ELSE "DIMITRIS AKRIOTIS" END "DIMITRIS AKRIOTIS",
        case when "ALEXANDRA KALIVA" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"ALEXANDRA KALIVA"||'</font></b>' ELSE "ALEXANDRA KALIVA" END "ALEXANDRA KALIVA",
        case when "STAMATIS CHRYSIKOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"STAMATIS CHRYSIKOPOULOS"||'</font></b>' ELSE "STAMATIS CHRYSIKOPOULOS" END "STAMATIS CHRYSIKOPOULOS",
        case when "KOSTAS TSIGOUNIS" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"KOSTAS TSIGOUNIS"||'</font></b>' ELSE "KOSTAS TSIGOUNIS" END "KOSTAS TSIGOUNIS",
        case when "SOTIRIA PLATI" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"SOTIRIA PLATI"||'</font></b>' ELSE "SOTIRIA PLATI" END "SOTIRIA PLATI"   --     "IOANNIS MAVRAKAKIS" , "IOANNIS THEODORAKIS", "THEMIS BACHOUROS", "DIMITRIS PSYCHOGIOPOULOS", "LAMBROS ALEXIOY", "APOSTOLOS MANTES", "NIKOLAOS KOYROYNIS"       
from PMAPP.V_DEVELOPERS_AVAILABILITY4;

select *
from PMAPP.V_DEVELOPERS_AVAILABILITY4;

create or replace view pmapp.v_developers_availability4 (
  date_key,  
  "GEORGE PAPOUTSOPOULOS", 
  "IOANNIS MAVRAKAKIS", 
  "IOANNIS THEODORAKIS", 
  "THEMIS BACHOUROS", 
  "DIMITRIS PSYCHOGIOPOULOS", 
  "LAMBROS ALEXIOY", 
  "APOSTOLOS MANTES", 
  "MARIA APOSTOLOPOULOU", 
  "YEVGENIYA VASYLYEVA", 
  "GEORGE TZEDAKIS", 
  "ELENI MANTZIORI", 
  "DIMITRIS AKRIOTIS", 
  "ALEXANDRA KALIVA", 
  "STAMATIS CHRYSIKOPOULOS", 
  "KOSTAS TSIGOUNIS", 
  "SOTIRIA PLATI" 
)as
select *
from (
  select  developers_id, 
          date_key, 
          listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
          --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
          --count(distinct project_id) num_projects
  from (
      -- base query: 1 row per (developer,project,day)
      select * 
      from (
            select  a.developers_id, 
                    '<i title ="'||b.name_description||'">'||
                    case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'CR'||b.bugzilla_id||'</a>'
                          when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                          when b.id = -2 THEN 'апоусиа'
                          when b.id = -1 THEN '<b><font color="green">'||'OpSup'||'</font></b>'
                          when b.id = 0 THEN 'GenTask'
                          else  to_char(b.id)
                    end || 
                      decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)', 'дглгтяоламыкайг', 'ED', 'йоутяас', 'DK', 'йкеисоуяа', 'TK', 'цеыяциоу', 'KG', 'папабасикеиоу', 'SP', 'савимоцкоу', 'MS' ,b.pm) 
                      ||'</i>'
                    project_id,                  
                    a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
            from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
            --order by developers_id, start_date 
            ) t1
        --partition by (t1.developers_id, t1.prjs_id)
        --right outer 
        join
                (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
      on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
      order by developers_id, date_key, project_id, start_date
  ) 
  group by developers_id, date_key
) s 
PIVOT (
 max(projects) as projects 
 for developers_id in ( 0 as "GEORGE PAPOUTSOPOULOS", 
                        1 as "IOANNIS MAVRAKAKIS", 
                        2 as "IOANNIS THEODORAKIS", 
                        3 as "THEMIS BACHOUROS", 
                        4 as "DIMITRIS PSYCHOGIOPOULOS", 
                        5 as "LAMBROS ALEXIOY", 
                        6 as "APOSTOLOS MANTES", 
                        7 as "MARIA APOSTOLOPOULOU", 
                        8 as "YEVGENIYA VASYLYEVA", 
                        9 as "GEORGE TZEDAKIS", 
                        10 as "ELENI MANTZIORI", 
                        11 as "DIMITRIS AKRIOTIS", 
                        12 as "ALEXANDRA KALIVA", 
                        13 as "STAMATIS CHRYSIKOPOULOS", 
                        14 as "KOSTAS TSIGOUNIS", 
                        15 as "SOTIRIA PLATI")
)
order by date_key;


-- VERSION 3 
--    *add a tooltip with the project name and 
--    *a link to bugzilla for CRs with bugzilla id, 
--    *also add a today column to the APEX query

-- ****************************
-- THIS IS the CORRECT UNPIVOTED query
-- It shows per day the projects for each developer
-- we DONT need an partition OUTER JOIN. We just need to join to date_dim with a "between predicate" instead of an equality join
-- *****************************
select  developers_id, 
        date_key, 
        listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
        --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
        --count(distinct project_id) num_projects
from (
    -- base query: 1 row per (developer,project,day)
    select * 
    from (
          select  a.developers_id, 
                  '<i title ="'||b.name_description||'">'||
                  case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'CR'||b.bugzilla_id||'</a>'
                        when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                        else  to_char(b.id)
                  end || 
                    decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)' ,b.pm) 
                    ||'</i>'
                  project_id,                  
                  a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
          from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
          --order by developers_id, start_date 
          ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id, date_key, project_id, start_date
) 
group by developers_id, date_key;

------------------------
-- PIVOT query  - to show developers availability
--------------------
-- highlight per PM
select  sysdate today, date_key,  
        case when "GEORGE PAPOUTSOPOULOS" like '%('||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"GEORGE PAPOUTSOPOULOS"||'</font></b>' ELSE "GEORGE PAPOUTSOPOULOS" END "GEORGE PAPOUTSOPOULOS", 
        case when "IOANNIS MAVRAKAKIS" like '%('||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS MAVRAKAKIS"||'</font></b>' ELSE "IOANNIS MAVRAKAKIS" END "IOANNIS MAVRAKAKIS", 
        case when "IOANNIS THEODORAKIS" like '%('||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"IOANNIS THEODORAKIS"||'</font></b>' ELSE "IOANNIS THEODORAKIS" END "IOANNIS THEODORAKIS", 
        case when "THEMIS BACHOUROS" like '%('||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"THEMIS BACHOUROS"||'</font></b>' ELSE "THEMIS BACHOUROS" END "THEMIS BACHOUROS", 
        case when "DIMITRIS PSYCHOGIOPOULOS" like '%('||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"DIMITRIS PSYCHOGIOPOULOS"||'</font></b>' ELSE "DIMITRIS PSYCHOGIOPOULOS" END "DIMITRIS PSYCHOGIOPOULOS", 
        case when "LAMBROS ALEXIOY" like '%('||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"LAMBROS ALEXIOY"||'</font></b>' ELSE "LAMBROS ALEXIOY" END "LAMBROS ALEXIOY", 
        case when "APOSTOLOS MANTES" like '%('||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"APOSTOLOS MANTES"||'</font></b>' ELSE "APOSTOLOS MANTES" END "APOSTOLOS MANTES", 
        case when "MARIA APOSTOLOPOULOU" like '%'||substr(upper(:APP_USER),1,2)||')%' then '<b><font color="blue">'||"MARIA APOSTOLOPOULOU"||'</font></b>' ELSE "MARIA APOSTOLOPOULOU" END "MARIA APOSTOLOPOULOU" 
   --     "IOANNIS MAVRAKAKIS" , "IOANNIS THEODORAKIS", "THEMIS BACHOUROS", "DIMITRIS PSYCHOGIOPOULOS", "LAMBROS ALEXIOY", "APOSTOLOS MANTES", "NIKOLAOS KOYROYNIS"       
from PMAPP.V_DEVELOPERS_AVAILABILITY3;

select *
from PMAPP.V_DEVELOPERS_AVAILABILITY3;

create or replace view pmapp.v_developers_availability3 
(date_key,  "GEORGE PAPOUTSOPOULOS", "IOANNIS MAVRAKAKIS" , "IOANNIS THEODORAKIS", "THEMIS BACHOUROS", "DIMITRIS PSYCHOGIOPOULOS", "LAMBROS ALEXIOY", "APOSTOLOS MANTES", "MARIA APOSTOLOPOULOU")
as
select *
from (
  select  developers_id, 
          date_key, 
          listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
          --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
          --count(distinct project_id) num_projects
  from (
      -- base query: 1 row per (developer,project,day)
      select * 
      from (
            select  a.developers_id, 
                    '<i title ="'||b.name_description||'">'||
                    case  when b.bugzilla_id IS NOT NULL THEN '<a href="http://10.101.14.28:8666/bugzilla/show_bug.cgi?id='||b.bugzilla_id||'">'||'CR'||b.bugzilla_id||'</a>'
                          when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                          when b.id = -2 THEN 'апоусиа'
                          when b.id = -1 THEN '<b><font color="green">'||'OpSup'||'</font></b>'
                          when b.id = 0 THEN 'GenTask'
                          else  to_char(b.id)
                    end || 
                      decode(b.pm, 'фоялпас', '(VZ)', 'симос','(LS)', 'йиоусгс', '(PK)', 'бекисйайгс', '(MV)', 'NKARAG','(NK)','жытопоукос', '(EF)','лаккиопоукос', '(CM)' ,b.pm) 
                      ||'</i>'
                    project_id,                  
                    a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
            from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
            --order by developers_id, start_date 
            ) t1
        --partition by (t1.developers_id, t1.prjs_id)
        --right outer 
        join
                (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
      on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
      order by developers_id, date_key, project_id, start_date
  ) 
  group by developers_id, date_key
) s 
PIVOT (
 max(projects) as projects 
 for developers_id in (0 as "GEORGE PAPOUTSOPOULOS",1 as "IOANNIS MAVRAKAKIS" ,2 as "IOANNIS THEODORAKIS",3 as "THEMIS BACHOUROS",4 as "DIMITRIS PSYCHOGIOPOULOS",5 as "LAMBROS ALEXIOY",6 as "APOSTOLOS MANTES",7 as "MARIA APOSTOLOPOULOU")
)
order by date_key;


-- VERSION 2 (include PM info, so as to highlight the Assignments per PM with the help of :APP_USER bind variable)
-- ****************************
-- THIS IS the CORRECT UNPIVOTED query
-- It shows per day the projects for each developer
-- we DONT need an partition OUTER JOIN. We just need to join to date_dim with a "between predicate" instead of an equality join
-- *****************************
select  developers_id, 
        date_key, 
        listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
        --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
        --count(distinct project_id) num_projects
from (
    -- base query: 1 row per (developer,project,day)
    select * 
    from (
          select  a.developers_id, 
                  case  when b.bugzilla_id IS NOT NULL THEN 'CR'||b.bugzilla_id
                        when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                        else  to_char(b.id)
                  end || 
                    decode(b.pm, 'фоялпас', '-VZ', 'симос','-LS', 'йиоусгс', '-PK', 'бекисйайгс', '-MV', 'NKARAG','-NK','жытопоукос', '-EF',b.pm) 
                  project_id,                  
                  a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
          from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
          --order by developers_id, start_date 
          ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id, date_key, project_id, start_date
) 
group by developers_id, date_key;

------------------------
-- PIVOT query  - to show developers availability
--------------------
-- highlight per PM
select  date_key,  
        case when "GEORGE PAPOUTSOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||'%' then '<b><font color="blue">'||"GEORGE PAPOUTSOPOULOS"||'</font></b>' ELSE "GEORGE PAPOUTSOPOULOS" END "GEORGE PAPOUTSOPOULOS", 
        case when "IOANNIS MAVRAKAKIS" like '%'||substr(upper(:APP_USER),1,2)||'%' then '<b><font color="blue">'||"IOANNIS MAVRAKAKIS"||'</font></b>' ELSE "IOANNIS MAVRAKAKIS" END "IOANNIS MAVRAKAKIS", 
        case when "IOANNIS THEODORAKIS" like '%'||substr(upper(:APP_USER),1,2)||'%' then '<b><font color="blue">'||"IOANNIS THEODORAKIS"||'</font></b>' ELSE "IOANNIS THEODORAKIS" END "IOANNIS THEODORAKIS", 
        case when "THEMIS BACHOUROS" like '%'||substr(upper(:APP_USER),1,2)||'%' then '<b><font color="blue">'||"THEMIS BACHOUROS"||'</font></b>' ELSE "THEMIS BACHOUROS" END "THEMIS BACHOUROS", 
        case when "DIMITRIS PSYCHOGIOPOULOS" like '%'||substr(upper(:APP_USER),1,2)||'%' then '<b><font color="blue">'||"DIMITRIS PSYCHOGIOPOULOS"||'</font></b>' ELSE "DIMITRIS PSYCHOGIOPOULOS" END "DIMITRIS PSYCHOGIOPOULOS", 
        case when "LAMBROS ALEXIOY" like '%'||substr(upper(:APP_USER),1,2)||'%' then '<b><font color="blue">'||"LAMBROS ALEXIOY"||'</font></b>' ELSE "LAMBROS ALEXIOY" END "LAMBROS ALEXIOY", 
        case when "APOSTOLOS MANTES" like '%'||substr(upper(:APP_USER),1,2)||'%' then '<b><font color="blue">'||"APOSTOLOS MANTES"||'</font></b>' ELSE "APOSTOLOS MANTES" END "APOSTOLOS MANTES", 
        case when "NIKOLAOS KOYROYNIS" like '%'||substr(upper(:APP_USER),1,2)||'%' then '<b><font color="blue">'||"NIKOLAOS KOYROYNIS"||'</font></b>' ELSE "NIKOLAOS KOYROYNIS" END "NIKOLAOS KOYROYNIS" 
   --     "IOANNIS MAVRAKAKIS" , "IOANNIS THEODORAKIS", "THEMIS BACHOUROS", "DIMITRIS PSYCHOGIOPOULOS", "LAMBROS ALEXIOY", "APOSTOLOS MANTES", "NIKOLAOS KOYROYNIS"       
from PMAPP.V_DEVELOPERS_AVAILABILITY2;

select *
from PMAPP.V_DEVELOPERS_AVAILABILITY2;

create or replace view pmapp.v_developers_availability2 
(date_key,  "GEORGE PAPOUTSOPOULOS", "IOANNIS MAVRAKAKIS" , "IOANNIS THEODORAKIS", "THEMIS BACHOUROS", "DIMITRIS PSYCHOGIOPOULOS", "LAMBROS ALEXIOY", "APOSTOLOS MANTES", "NIKOLAOS KOYROYNIS")
as
select *
from (
  select  developers_id, 
          date_key, 
          listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects --, 
          --listagg(pm, ',') WITHIN GROUP (ORDER BY start_date, pm) pms, 
          --count(distinct project_id) num_projects
  from (
      -- base query: 1 row per (developer,project,day)
      select * 
      from (
            select  a.developers_id, 
                    case  when b.bugzilla_id IS NOT NULL THEN 'CR'||b.bugzilla_id
                          when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                          else  to_char(b.id)
                    end || 
                      decode(b.pm, 'фоялпас', '-VZ', 'симос','-LS', 'йиоусгс', '-PK', 'бекисйайгс', '-MV', 'NKARAG','-NK','жытопоукос', '-EF',b.pm) 
                    project_id,                  
                    a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
            from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
            --order by developers_id, start_date 
            ) t1
        --partition by (t1.developers_id, t1.prjs_id)
        --right outer 
        join
                (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
      on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
      order by developers_id, date_key, project_id, start_date
  ) 
  group by developers_id, date_key
) s 
PIVOT (
 max(projects) as projects 
 for developers_id in (0 as "GEORGE PAPOUTSOPOULOS",1 as "IOANNIS MAVRAKAKIS" ,2 as "IOANNIS THEODORAKIS",3 as "THEMIS BACHOUROS",4 as "DIMITRIS PSYCHOGIOPOULOS",5 as "LAMBROS ALEXIOY",6 as "APOSTOLOS MANTES",7 as "NIKOLAOS KOYROYNIS")
)
order by date_key;

-- VERSION 1
-- ****************************
-- THIS IS the CORRECT UNPIVOTED query
-- It shows per day the projects for each developer
-- we DONT need an partition OUTER JOIN. We just need to join to date_dim with a "between predicate" instead of an equality join
-- *****************************
select developers_id, date_key, listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects, count(distinct project_id) num_projects
from (
    -- base query: 1 row per (developer,project,day)
    select * 
    from (
          select  a.developers_id, 
                  case  when b.bugzilla_id IS NOT NULL THEN 'CR'||b.bugzilla_id
                        when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                        else  to_char(b.id)
                  end project_id,
                  a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
          from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
          --order by developers_id, start_date 
          ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id, date_key, project_id, start_date
) 
group by developers_id, date_key;

------------------------
-- PIVOT query  - to show developers availability
--------------------

select *
from PMAPP.V_DEVELOPERS_AVAILABILITY;

create or replace view pmapp.v_developers_availability
as
select *
from (
select developers_id, date_key, listagg(project_id, ',') WITHIN GROUP (ORDER BY start_date ) projects--, count(distinct project_id) num_projects
from (
    -- base query: 1 row per (developer,project,day)
    select * 
    from (
          select  a.developers_id, 
                  case  when b.bugzilla_id IS NOT NULL THEN 'CR'||b.bugzilla_id
                        when b.bugzilla_id IS  NULL AND b.remedy_id IS NOT NULL THEN b.remedy_id
                        else  to_char(b.id)
                  end project_id,
                  a.start_date, a.end_date, a.end_date - a.start_date duration, rpad('*', a.end_date-a.start_date,'*') pad
          from PMAPP.DEV_PRJS a join pmapp.prjs b on(a.prjs_id =  b.id)
          --order by developers_id, start_date 
          ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where working_day_ind = 1) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id, date_key, project_id, start_date
) 
group by developers_id, date_key
) s 
PIVOT (
 max(projects)  --, sum(num_projects) as tot_prjs 
 for developers_id in (0 as "GEORGE PAPOUTSOPOULOS",1 as "IOANNIS MAVRAKAKIS" ,2 as "IOANNIS THEODORAKIS",3 as "THEMIS BACHOUROS",4 as "DIMITRIS PSYCHOGIOPOULOS",5 as "LAMBROS ALEXIOY",6 as "APOSTOLOS MANTES",7 as "NIKOLAOS KOYROYNIS")
)
order by date_key;

select *
from PMAPP.V_DEVELOPERS_AVAILABILITY;
------------------------------------------------------------------------------------------------------------------------------

  
select developers_id, prjs_id, start_date, end_date, end_date - start_date duration, rpad('*', end_date-start_date,'*') pad
from PMAPP.DEV_PRJS
order by developers_id, prjs_id, start_date, duration desc;



select t1.developers_id, nvl(t1.prjs_id,0) prj, t1.start_date, t1.end_date, t1.duration, t1.pad, t2.date_key    
from
    (select developers_id, prjs_id, start_date, end_date, end_date - start_date duration, rpad('*', end_date-start_date,'*') pad
    from PMAPP.DEV_PRJS) t1
partition by (t1.developers_id)
right outer join
    (select date_key from target_dw.date_dim where date_key between sysdate and sysdate + 40) t2 
on(trunc(t1.start_date) = t2.date_key)
order by developers_id, date_key, start_date, duration desc;


select 'to_date('''||date_key||''', ''dd-mon-yyyy'') AS "'||date_key||'",' from target_dw.date_dim where date_key between sysdate-1 and sysdate + 40
order by date_key   

select *
from (
      select developers_id, prjs_id, to_char(start_date, 'dd-mm-yyyy') sd, end_date, end_date - start_date duration, rpad('*', end_date-start_date,'*') pad
      from PMAPP.DEV_PRJS
      order by developers_id, start_date
) s
    PIVOT (max(prjs_id) for sd in (
    '24-03-2015',
    '25-03-2015',
'26-03-2015',
'27-03-2015',
'28-03-2015',
'29-03-2015',
'30-03-2015',
'31-03-2015',
'01-04-2015',
'02-04-2015',
'03-04-2015',
'04-04-2015',
'05-04-2015',
'06-04-2015',
'07-04-2015',
'08-04-2015',
'09-04-2015',
'10-04-2015',
'11-04-2015',
'12-04-2015',
'13-04-2015',
'14-04-2015',
'15-04-2015',
'16-04-2015',
'17-04-2015',
'18-04-2015',
'19-04-2015',
'20-04-2015',
'21-04-2015',
'22-04-2015',
'23-04-2015',
'24-04-2015',
'25-04-2015',
'26-04-2015',
'27-04-2015',
'28-04-2015',
'29-04-2015',
'30-04-2015',
'01-05-2015',
'02-05-2015',
'03-05-2015')
    )
order by developers_id, duration desc;




select *
from (
      /*select developers_id, prjs_id, to_char(start_date, 'dd-mm-yyyy') sd, end_date, end_date - start_date duration, rpad('*', end_date-start_date,'*') pad
      from PMAPP.DEV_PRJS
      order by developers_id, start_date*/
   select  date_key,  developers_id, prjs_id, to_char(start_date, 'dd-mm-yyyy') sd, start_Date, end_date, end_date - start_date duration, rpad('*', end_date-start_date,'*') pad 
    from (
          select developers_id, prjs_id, to_char(start_date, 'dd-mm-yyyy') sd, start_date, end_date, end_date - start_date duration, rpad('*', end_date-start_date,'*') pad
          from PMAPP.DEV_PRJS
          order by developers_id, start_date ) t1
      --partition by (t1.developers_id, t1.prjs_id)
      --right outer 
      join
              (select date_key from target_dw.date_dim where date_key between sysdate and sysdate + 40) t2 
    on(t2.date_key between trunc(t1.start_date) and trunc(t1.end_date))
    order by developers_id,prjs_id, start_date, date_key      
) s
    PIVOT (max(prjs_id) for sd in (
    '24-03-2015',
    '25-03-2015',
'26-03-2015',
'27-03-2015',
'28-03-2015',
'29-03-2015',
'30-03-2015',
'31-03-2015',
'01-04-2015',
'02-04-2015',
'03-04-2015',
'04-04-2015',
'05-04-2015',
'06-04-2015',
'07-04-2015',
'08-04-2015',
'09-04-2015',
'10-04-2015',
'11-04-2015',
'12-04-2015',
'13-04-2015',
'14-04-2015',
'15-04-2015',
'16-04-2015',
'17-04-2015',
'18-04-2015',
'19-04-2015',
'20-04-2015',
'21-04-2015',
'22-04-2015',
'23-04-2015',
'24-04-2015',
'25-04-2015',
'26-04-2015',
'27-04-2015',
'28-04-2015',
'29-04-2015',
'30-04-2015',
'01-05-2015',
'02-05-2015',
'03-05-2015')
    )
order by developers_id, start_date, date_key

-------  DRAFT

with q as
(
select
prj_type||':'||"ID"||':'||'BGZLLA-'||bugzilla_id||':'||'RMDY-'||remedy_id||':'||name_description d, id r
from pmapp.prjs
)
select d, r
from q
order by 1;

select prj_type||':'||'BGZLLA-'||bugzilla_id||':'||'RMDY-'||remedy_id||':'||name_description d, id r
from pmapp.prjs
order by 1;

select name d, id r
from   PMAPP.DEVELOPERS
order by 1;


select prjs_id, developers_id, start_date, count(*)
from pmapp.dev_prjs
group by prjs_id, developers_id, start_date
having count(*) > 1;

delete from PMAPP.DEV_PRJS
where
  (prjs_id, developers_id) in ((5,4),(6,8),(5,5),(6,1) );
  
  commit;
