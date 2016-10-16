declare
  l_sender varchar2(50);
  l_receiver developers.mail%type;
  l_subject varchar2(100);
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
  l_action  varchar2(30);
  l_apex_user varchar2(50);
begin
  l_sender := 'fdw@ote.gr';
  
  -- get developer info 
  select name, mail into l_developer, l_receiver
  from pmapp.developers
  where
     ID = :P7_DEVELOPERS_ID;
  
  -- get project info
  select id,
    prj_type,
    name_description,
    bugzilla_id,
    remedy_id
        into l_project_id, l_project_type, l_project_name, l_bugzilla, l_remedy
  from pmapp."PRJS" 
  where
    ID = :P7_PRJS_ID;
    
  -- get assignment info
  l_start_date := :P7_START_DATE;
  l_end_date := :P7_END_DATE;
  l_action := case 
                when :request = 'CREATE' then 'CREATED PRJ ASSIGNMENT' 
                when :request = 'SAVE' then 'UPDATED PRJ ASSIGNMENT' 
                when :request = 'DELETE' then 'DELETED PRJ ASSIGNEMENT'
                else '' 
              end; 
  l_apex_user :=  :APP_USER;              

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
  
  monitor_dw.my_send_mail(l_sender, l_receiver, l_subject, l_message);
  l_receiver := 'fdw@ote.gr';
  monitor_dw.my_send_mail(l_sender, l_receiver, l_subject, l_message);
end;