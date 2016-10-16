/******************************************************************************
        PMAPP.PRJS 
 ******************************************************************************/
ALTER TABLE PMAPP.PRJS
 DROP PRIMARY KEY CASCADE;

DROP TABLE PMAPP.PRJS CASCADE CONSTRAINTS;

CREATE TABLE PMAPP.PRJS
(
  ID                NUMBER,
  DEPT              VARCHAR2(30 BYTE),
  YYCODE            NUMBER,
  NAME_DESCRIPTION  VARCHAR2(255 BYTE),
  START_DATE        VARCHAR2(30 BYTE),
  PM                VARCHAR2(30 BYTE),
  BUSINESS_USER     VARCHAR2(30 BYTE),
  STATUS            VARCHAR2(255 BYTE),
  NEXT_MILESTONE    VARCHAR2(255 BYTE),
  START_OF_UAT      VARCHAR2(255 BYTE),
  GO_LIVE_DATE      VARCHAR2(30 BYTE),
  COMMENTS          VARCHAR2(4000 BYTE)
);

alter table pmapp.prjs add bugzilla_id  varchar2(10) unique;
alter table pmapp.prjs add remedy_id  varchar2(30) unique;
alter table pmapp.prjs add in_portal  varchar2(1 char) default 'N';
alter table pmapp.prjs add NEXT_MSTONE_DATE date

alter table pmapp.prjs RENAME COLUMN GO_LIVE_DATE TO GO_LIVE_DATE_C
alter table pmapp.prjs add GO_LIVE_DATE date

alter table pmapp.prjs RENAME COLUMN START_OF_UAT TO START_OF_UAT_C
alter table pmapp.prjs add START_OF_UAT date

alter table pmapp.prjs RENAME COLUMN START_DATE TO START_DATE_C
alter table pmapp.prjs add START_DATE date

alter table pmapp.prjs add business_unit varchar2(30)

alter table pmapp.prjs modify business_unit varchar2(100)
alter table pmapp.prjs modify business_user varchar2(100)

alter table pmapp.prjs add completion_date date;
alter table pmapp.prjs add man_days number;

alter table pmapp.prjs add population_date date;
alter table pmapp.prjs add last_update_date date;
alter table pmapp.prjs add updated_by varchar2(50);

/*
update pmapp.prjs
    set business_unit = business_user
commit    
*/

/*update pmapp.prjs
    set go_live_date = to_date(go_live_date_c, 'DD/MM/YYYY')
    where go_live_date_c is not null 
*/

CREATE UNIQUE INDEX PMAPP.PRJS_PK ON PMAPP.PRJS
(ID);

DROP SEQUENCE PMAPP.PRJS_SEQ2;

CREATE SEQUENCE PMAPP.PRJS_SEQ2
  START WITH 41
  MAXVALUE 9999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;

DROP TRIGGER PMAPP."bi_PRJS";

CREATE OR REPLACE TRIGGER PMAPP."bi_PRJS"  
  before insert ON PMAPP.PRJS              
  for each row
begin  
  if :new."ID" is null then
    select "PRJS_SEQ2".nextval into :new."ID" from dual;
  end if;
end;
/


ALTER TABLE PMAPP.PRJS ADD (
  CONSTRAINT PRJS_PK
  PRIMARY KEY
  (ID)
  USING INDEX PMAPP.PRJS_PK
  ENABLE VALIDATE);

/******************************************************************************
        PMAPP.PRJ_HIST 

 DESC:
    Logs history of changes in specific columns of the prjs table         
 ******************************************************************************/

drop table pmapp.prj_hist;
  
create table pmapp.prj_hist ( 
    ID                NUMBER,
    VERSION           NUMBER,
    CHANGE_DATE         DATE,
    UAT_CHANGE_IND    NUMBER,
    GOLIVE_CHANGE_IND   NUMBER,
    DEPT              VARCHAR2(30 BYTE),
    YYCODE            NUMBER,
    NAME_DESCRIPTION  VARCHAR2(255 BYTE),
    START_DATE_C      VARCHAR2(30 BYTE),
    PM                VARCHAR2(30 BYTE),
    BUSINESS_USER     VARCHAR2(100 BYTE),
    STATUS            VARCHAR2(255 BYTE),
    NEXT_MILESTONE    VARCHAR2(255 BYTE),
    START_OF_UAT_C    VARCHAR2(255 BYTE),
    GO_LIVE_DATE_C    VARCHAR2(30 BYTE),
    COMMENTS          VARCHAR2(4000 BYTE),
    BUGZILLA_ID       VARCHAR2(10 BYTE),
    REMEDY_ID         VARCHAR2(30 BYTE),
    IN_PORTAL         VARCHAR2(1 CHAR),
    GO_LIVE_DATE      DATE,
    GO_LIVE_PREV       DATE,
    START_OF_UAT      DATE,
    START_OF_UAT_PREV   DATE,
    NEXT_MSTONE_DATE  DATE,
    START_DATE        DATE,
    BUSINESS_UNIT     VARCHAR2(100 BYTE),
    COMPLETION_DATE   DATE,
    MAN_DAYS          NUMBER 
);

alter table pmapp.prj_hist add constraint prj_hist_pk primary key(id, version);

-- trigger to log changes on UAT_DATe and Go-live date
CREATE OR REPLACE TRIGGER PMAPP.PRJ_HIST_TRG  
  after update OF START_OF_UAT OR update OF GO_LIVE_DATE ON PMAPP.PRJS                
  for each row
begin
    IF (nvl(:old.START_OF_UAT, date'1900-01-01') <> :new.START_OF_UAT OR nvl(:old.GO_LIVE_DATE,date'1900-01-01') <> :new.GO_LIVE_DATE) then    
          insert into pmapp.prj_hist (
            ID,
            VERSION,
            CHANGE_DATE,
            UAT_CHANGE_IND,
            GOLIVE_CHANGE_IND,
            DEPT,
            YYCODE,
            NAME_DESCRIPTION,
            START_DATE_C,
            PM,
            BUSINESS_USER,
            STATUS,
            NEXT_MILESTONE,
            START_OF_UAT_C,
            GO_LIVE_DATE_C,
            COMMENTS,
            BUGZILLA_ID,
            REMEDY_ID,
            IN_PORTAL,
            GO_LIVE_DATE,
            GO_LIVE_PREV,
            START_OF_UAT,
            START_OF_UAT_PREV,
            NEXT_MSTONE_DATE,
            START_DATE,
            BUSINESS_UNIT,
            COMPLETION_DATE,
            MAN_DAYS     
          )
        values(
            :new.ID,
            (select nvl(max(version),0) + 1 from pmapp.prj_hist where id = :new.id),
            sysdate,
            case when nvl(:old.START_OF_UAT, date'1900-01-01') <> :new.START_OF_UAT then 1 else 0 end,
            case when nvl(:old.GO_LIVE_DATE,date'1900-01-01') <> :new.GO_LIVE_DATE then 1 else 0 end,
            :new.DEPT,
            :new.YYCODE,
            :new.NAME_DESCRIPTION,
            :new.START_DATE_C,
            :new.PM,
            :new.BUSINESS_USER,
            :new.STATUS,
            :new.NEXT_MILESTONE,
            :new.START_OF_UAT_C,
            :new.GO_LIVE_DATE_C,
            :new.COMMENTS,
            :new.BUGZILLA_ID,
            :new.REMEDY_ID,
            :new.IN_PORTAL,
            :new.GO_LIVE_DATE,
            :old.GO_LIVE_DATE,
            :new.START_OF_UAT,
            :old.START_OF_UAT,
            :new.NEXT_MSTONE_DATE,
            :new.START_DATE,
            :new.BUSINESS_UNIT,
            :new.COMPLETION_DATE,
            :new.MAN_DAYS );      
    end if;  
end;


/******************************************************************************
        PMAPP.V_PORTAL_PRJS 

 DESC:
    Returns all projects published in the portal         
 ******************************************************************************/
 
 create or replace view pmapp.V_PORTAL_PRJS 
 as
 select P.ID, P.BUGZILLA_ID, NAME_DESCRIPTION, PM, BUSINESS_UNIT, BUSINESS_USER,STATUS,START_OF_UAT, GO_LIVE_DATE, NEXT_MILESTONE, NEXT_MSTONE_DATE, 
 COMMENTS , MAN_DAYS 
 from pmapp.prjs p
 where 
    P.IN_PORTAL = 'Y' and dept = 'FDW'
    AND NOT(
            P.STATUS  = 'COMPLETED' 
            AND round((sysdate - nvl(P.COMPLETION_DATE, sysdate))/7) > 2    
        )
 order by id 
   
-------------------------------- DRAFT -------------------
drop table pmapp.pmanagers

create table pmapp.pmanagers (
    name    varchar2(100) primary key,
    dept    varchar2(100)
);

create table pmapp.departments (
    name    varchar2(50) primary key
)    

drop table pmapp.projects;

CREATE TABLE pmapp.projects (
    id VARCHAR2 (10) primary key,
    bugzilla_id varchar2(10) unique,
    remedy_id varchar2(20) unique,
    dept        varchar2(50) references pmapp.departments(name),
    descr      varchar2(100) not null,
    start_date  date,
    pm          varchar2(100) references pmapp.pmanagers(name),
    bunit       varchar2(20),
    bowner      varchar2(100),
    status      varchar2(100),
    next_mstone varchar2(100),
    uat_start   date,
    go_live      date,
    change_ind   number(1),
    uat_start_prev  date,
    go_live_prev    date,
    comments    varchar2(4000)
);

alter table pmapp.projects modify change_ind default 0;