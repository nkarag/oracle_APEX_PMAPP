create user PMAPP identified by pmapp;

grant connect to pmapp;

grant resource to pmapp;

grant create any view to pmapp;

alter user pmapp quota unlimited on users;

grant select on target_dw.date_Dim to pmapp;

grant select on monitor_dw.DWP_ETL_FLOWS to pmapp;

select * from dba_users where username = 'PMAPP' 