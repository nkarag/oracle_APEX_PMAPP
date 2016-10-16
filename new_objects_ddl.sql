-- DEVELOPERS
CREATE
  TABLE DEVELOPERS
  (
    NAME    VARCHAR2 (50) NOT NULL ,
    COMPANY VARCHAR2 (50)
  )
  LOGGING ;

alter table pmapp.developers add id number;

ALTER TABLE DEVELOPERS ADD CONSTRAINT DEVELOPERS_PK PRIMARY KEY ( ID ) ;

alter table DEV_PRJS drop constraint DEV_PRJS_DEVELOPERS_FK;
alter table developers drop constraint developers_pk ;

primary key(id);

alter table developers add mail varchar2(50);

-- DEV_PRJS
CREATE
  TABLE DEV_PRJS
  (
    DEVELOPERS_NAME VARCHAR2 (50) NOT NULL ,
    PRJS_ID         NUMBER NOT NULL ,
    START_DATE      DATE ,
    END_DATE        DATE ,
    ROLE            VARCHAR2 (50) ,
    "COMMENT"       VARCHAR2 (4000)
  )
  LOGGING ;

alter table dev_prjs drop column DEVELOPERS_NAME cascade constraints;

alter table dev_prjs add developers_id number;

alter table dev_prjs add status varchar2(10);

alter table dev_prjs add free_of_charge_ind number;

alter table dev_prjs add overtime_hrs number;

alter table dev_prjs add lesstime_hrs number;
  
ALTER TABLE pmapp.DEV_PRJS ADD CONSTRAINT DEV_PRJS_PK PRIMARY KEY ( DEVELOPERS_ID, PRJS_ID, START_DATE );  

ALTER TABLE pmapp.DEV_PRJS ADD CONSTRAINT DEV_PRJS_DEVELOPERS_FK FOREIGN KEY (
DEVELOPERS_ID ) REFERENCES DEVELOPERS ( ID ) NOT DEFERRABLE ;

ALTER TABLE pmapp.DEV_PRJS ADD CONSTRAINT DEV_PRJS_PRJS_FK FOREIGN KEY ( PRJS_ID )
REFERENCES PMAPP.PRJS ( ID ) NOT DEFERRABLE ;

ALTER TABLE pmapp.DEV_PRJS
ADD CONSTRAINT dates_check CHECK (start_date <= end_date); 

-- PRJS
alter table PMAPP.PRJS add prj_type varchar2(30);

alter table pmapp.prjs add operating_plan_id number;

alter table pmapp.prjs modify operating_plan_id varchar2(50);

alter table pmapp.prjs add main_flow_affected varchar2(100);

alter table pmapp.prjs drop constraint SYS_C00881746;  -- unique remedy_id

alter table pmapp.prjs drop constraint SYS_C00881745;  -- unique bugzilla_id

-- PRJS_DET_COMMENTS
CREATE TABLE PRJS_DET_COMMENTS
  (
    id      NUMBER NOT NULL ,
    PRJS_ID NUMBER NOT NULL ,
    comments CLOB ,
    created_on DATE NOT NULL ,
    created_by VARCHAR2 (100) ,
    updated_on DATE ,
    updated_by VARCHAR2 (100)
  ) ;
ALTER TABLE PRJS_DET_COMMENTS ADD CONSTRAINT PRJS_DET_COMMENTS_PK PRIMARY KEY ( id ) ;
ALTER TABLE PRJS_DET_COMMENTS ADD CONSTRAINT PRJS_DET_COMMENTS__UN UNIQUE ( PRJS_ID , created_on , created_by ) ;
ALTER TABLE PRJS_DET_COMMENTS ADD CONSTRAINT PRJS_DET_COMMENTS_PRJS_FK FOREIGN KEY ( PRJS_ID ) REFERENCES PMAPP.PRJS ( ID ) ;

CREATE SEQUENCE  "PMAPP"."PRJS_DET_COMM_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE ;

create or replace TRIGGER "PMAPP"."PRJS_DET_COMMNTS"  
  before insert on "PRJS_DET_COMMENTS"              
  for each row 
begin  
  if :new."ID" is null then
    select "PRJS_DET_COMM_SEQ".nextval into :new."ID" from dual;
  end if;
end;

-- PRJ_ATTACHEMENTS
CREATE TABLE PRJS_ATTACHMENTS
  (
    id            NUMBER NOT NULL ,
    description   VARCHAR2 (4000) ,
    FILE_NAME     VARCHAR2 (1000) ,
    MIME_TYPE     VARCHAR2 (1000) ,
    character_set VARCHAR2 (200) ,
    blob_size     NUMBER ,
    created_on    DATE ,
    created_by    VARCHAR2 (100) ,
    updated_on    DATE ,
    updated_by    VARCHAR2 (100) ,
    attachment BLOB ,
    PRJS_ID NUMBER NOT NULL
  ) ;
ALTER TABLE PRJS_ATTACHMENTS ADD CONSTRAINT PRJS_ATTACHMENTS_PK PRIMARY KEY ( id ) ;
ALTER TABLE PRJS_ATTACHMENTS ADD CONSTRAINT PRJS_ATTACHMENTS_PRJS_FK FOREIGN KEY ( PRJS_ID ) REFERENCES PMAPP.PRJS ( ID ) ;


CREATE SEQUENCE  "PMAPP"."PRJS_ATTACH_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE ;

create or replace TRIGGER "PMAPP"."PRJS_ATTACH"  
  before insert on "PRJS_ATTACHMENTS"              
  for each row 
begin  
  if :new."ID" is null then
    select "PRJS_ATTACH_SEQ".nextval into :new."ID" from dual;
  end if;
end;

-- DATE_DIM

create synonym pmapp.date_dim for target_dw.date_dim;

grant select on target_dw.date_dim to pmapp;

-- MISC
ALTER TABLE PMAPP.PRJS ADD CONSTRAINT PRJS_MANAGERS_FK FOREIGN KEY (PM) REFERENCES PMAPP.PMANAGERS(NAME) ;

insert into pmanagers (name, dept) 
select distinct pm, 'fdw'
from prjs

commit;

ALTER TABLE PMANAGERS ADD CONSTRAINT PMANAGERS_DEPTS_FK FOREIGN KEY (DEPT) REFERENCES DEPARTMENTS(NAME);

update pmanagers
  set dept = upper(dept);

commit;

grant execute on monitor_dw.my_send_mail to pmapp;

grant execute on monitor_dw.my_send_mail_gr to pmapp;

create or replace view pmapp.DWP_ETL_FLOWS as select * from MONITOR_DW.DWP_ETL_FLOWS;

