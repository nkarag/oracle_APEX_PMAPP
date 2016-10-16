------------------------------------------------------------------
--  Procedure: send_notification_mail
--  Description:  Send a notification mail to fdw@ote.gr and the
--                corresponding developer when a task creation/update/deletion
--                takes plac
--  Parameters:
--    apex_request_in:  Provide APEX :request bind variable
--    apex_user_in:     Provide APEX :APP_USER bind variable
--    developers_id_in: Provide APEX item bind variable containing developer id
--    prjs_id_in:       Provide APEX item bind variable containing project id
--    start_date_in:    Provide APEX item bind variable containing task assignment start date
--    end_date_in:      Provide APEX item bind variable containing task assignment end date
------------------------------------------------------------------
create or replace procedure pmapp.send_notification_mail (
 apex_request_in in varchar2,
 apex_user_in in  varchar2,
 developers_id_in  pmapp.developers.id%type,
 prjs_id_in pmapp.prjs.id%type,
 start_date_in  date,
 end_date_in  date
)
IS
  l_sender varchar2(50);
  l_receiver developers.mail%type;
  l_subject varchar2(500);
  l_message varchar2(4000);  
  l_project_name prjs.name_description%type;
  l_project_id  prjs.id%type;
  l_bugzilla  prjs.bugzilla_id%type;
  l_remedy  prjs.remedy_id%type;
  l_project_type prjs.prj_type%type;
  l_prj_name  prjs.name_description%type;
  l_start_date  date;
  l_end_date  date;
  l_developer developers.name%type;
  l_action  varchar2(50);
  l_apex_user varchar2(100);
BEGIN
  l_sender := 'fdw@ote.gr';
  
  -- get developer info 
  select name, mail into l_developer, l_receiver
  from pmapp.developers
  where
     ID = developers_id_in;
  
  -- get project info
  select id,
    prj_type,
    name_description,
    bugzilla_id,
    remedy_id
        into l_project_id, l_project_type, l_project_name, l_bugzilla, l_remedy
  from pmapp."PRJS" 
  where
    ID = prjs_id_in;
    
  -- get assignment info
  l_start_date := start_date_in;
  l_end_date := end_date_in;
  l_action := case 
                when apex_request_in = 'CREATE' then 'CREATED PROJECT ASSIGNMENT' 
                when apex_request_in = 'SAVE' then 'UPDATED PROJECT ASSIGNMENT' 
                when apex_request_in = 'DELETE' then 'DELETED PROJECT ASSIGNEMENT'
                else '' 
              end; 
  l_apex_user :=  apex_user_in;              

  -- construct mail    
  l_subject := 'PMAPP: '||l_action||' '||'-'||'Developer: '||l_developer||', Project: '||l_project_id||' from user '||l_apex_user;
  
  l_message :=  'PROJECT ASSIGNMENT DETAILS'||chr(10)||
                '---------------------------'||chr(10)||
                'PROJECT ID:  '||l_project_id||chr(10)||
                'BUGZILLA:  '||l_bugzilla||chr(10)||
                'REMEDY ID: '||l_remedy||chr(10)||
                'PROJECT TYPE:  '||l_project_type||chr(10)||
                'PROJECT NAME:  '||l_project_name||chr(10)||
                '-------------'||chr(10)|| 
                'ACTION:  '||l_action||chr(10)||
                'FROM APEX USER:  '||l_apex_user||chr(10)||
                '-------------'||chr(10)||
                'DEVELOPER: '||l_developer||chr(10)||
                'START DATE:  '||l_start_date||chr(10)||
                'END DATE:  '||l_end_date||chr(10)||
                '---------------------------';
  
  monitor_dw.my_send_mail_gr(l_sender, l_receiver, l_subject, l_message);
  l_receiver := 'fdw@ote.gr';
  monitor_dw.my_send_mail_gr(l_sender, l_receiver, l_subject, l_message);
END send_notification_mail;