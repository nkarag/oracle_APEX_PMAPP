CREATE OR REPLACE PACKAGE PMAPP.PMAPP_PKG  AS

  ----------------
  --  insertPrjsDetComment
  --    Inserts a detailed project comment
  ----------------
  procedure insertPrjsDetComment (
    PRJS_ID_IN IN NUMBER,
    COMMENT_IN CLOB,
    CREATED_BY_IN VARCHAR2
  );
  
  ----------------
  --  updatePrjsDetComment
  --    Updates a detailed project comment
  ----------------
  procedure updatePrjsDetComment (
    ID_IN IN NUMBER,
    COMMENT_IN CLOB,
    UPDATED_BY_IN VARCHAR2
  );  

  ----------------
  --  insertPrjsAttachment
  --    Inserts an attachement to a project
  ----------------
  procedure insertPrjsAttachment (
    PRJS_ID_IN IN NUMBER,
    DESCR_IN IN VARCHAR2,
    FILE_NAME_IN IN VARCHAR2,
    ATTACHMENT_IN  IN BLOB DEFAULT NULL,
    CREATED_BY_IN IN VARCHAR2,
    MIME_TYPE_IN IN VARCHAR2,
    CHARACTER_SET_IN IN VARCHAR2,
    BLOB_SIZE_IN IN NUMBER    
  );
 
END PMAPP_PKG;