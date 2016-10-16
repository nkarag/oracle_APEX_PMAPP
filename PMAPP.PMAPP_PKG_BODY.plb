CREATE OR REPLACE PACKAGE BODY PMAPP.PMAPP_PKG  AS

  procedure insertPrjsDetComment (
    PRJS_ID_IN IN NUMBER,
    COMMENT_IN CLOB,
    CREATED_BY_IN VARCHAR2
  )
  IS
  BEGIN
    -- id will be created by trigger
    insert into PMAPP.PRJS_DET_COMMENTS (PRJS_ID, COMMENTS, created_on, created_by)
    values (PRJS_ID_IN, COMMENT_IN, sysdate, CREATED_BY_IN);
    
    commit;
  END insertPrjsDetComment;
  
  procedure updatePrjsDetComment (
    ID_IN IN NUMBER,
    COMMENT_IN CLOB,
    UPDATED_BY_IN VARCHAR2
  )
  IS
  BEGIN
    update PMAPP.PRJS_DET_COMMENTS
      set comments = COMMENT_IN,
          updated_on = sysdate,
          updated_by = UPDATED_BY_IN
      where
        id = ID_IN;
        
    commit;
  END updatePrjsDetComment;    

  procedure insertPrjsAttachment (
    PRJS_ID_IN IN NUMBER,
    DESCR_IN IN VARCHAR2,
    FILE_NAME_IN IN VARCHAR2,
    ATTACHMENT_IN  IN BLOB DEFAULT NULL,
    CREATED_BY_IN IN VARCHAR2,
    MIME_TYPE_IN IN VARCHAR2,
    CHARACTER_SET_IN IN VARCHAR2,
    BLOB_SIZE_IN IN NUMBER    
  )
  IS
  BEGIN
    -- id will be created by trigger
    insert into PMAPP.PRJS_ATTACHMENTS (DESCRIPTION, FILE_NAME, MIME_TYPE, CHARACTER_SET, BLOB_SIZE, CREATED_ON, CREATED_BY, ATTACHMENT, PRJS_ID)
    values (
      DESCR_IN,
      FILE_NAME_IN,
      MIME_TYPE_IN,
      CHARACTER_SET_IN,
      BLOB_SIZE_IN,
      SYSDATE,
      CREATED_BY_IN,
      ATTACHMENT_IN,
      PRJS_ID_IN
    );
    
    commit;    
  END insertPrjsAttachment;
  
END PMAPP_PKG;