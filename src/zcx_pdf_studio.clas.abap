CLASS zcx_pdf_studio DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "Error text of the exception; get_text( ) returns it.
    DATA message TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        !textid   LIKE textid OPTIONAL
        !previous LIKE previous OPTIONAL
        !message  TYPE string OPTIONAL.

    METHODS if_message~get_text REDEFINITION.
ENDCLASS.



CLASS zcx_pdf_studio IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( textid = textid previous = previous ).
    me->message = message.
  ENDMETHOD.


  METHOD if_message~get_text.
    IF message IS NOT INITIAL.
      "Turkish for a Turkish logon, English for every other logon language.
      result = zcl_pdf_studio_text=>localize( message ).
    ELSE.
      result = super->if_message~get_text( ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
