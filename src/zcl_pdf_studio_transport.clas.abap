"! <p>Transport requests for ZPDF Studio customizing tables (forms, logos, fonts).</p>
"! Entries are recorded as R3TR TABU with table keys, in a customizing request chosen by the user,
"! like changes in SM30 / SPRO.
CLASS zcl_pdf_studio_transport DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_entry,
        tabname TYPE tabname,
        "Key after the client, '*' allowed at the end.
        key     TYPE string,
      END OF ty_entry,
      ty_entries TYPE STANDARD TABLE OF ty_entry WITH EMPTY KEY.

    CONSTANTS c_forms TYPE tabname VALUE 'ZPDF_STUDIO_FORM'.
    CONSTANTS c_assets TYPE tabname VALUE 'ZPDF_STUDIO_ASST'.

    "! SCC4 setting of the client: '1' automatic recording, '2' no changes, '3' no transports.
    CLASS-METHODS client_recording
      RETURNING
        VALUE(rv_flag) TYPE t000-cccoractiv.

    "! Lets the user choose a customizing request (popup) and returns the task.
    CLASS-METHODS choose_request
      RETURNING
        VALUE(rv_task) TYPE trkorr
      RAISING
        zcx_pdf_studio.

    "! Records table entries in a task.
    CLASS-METHODS record
      IMPORTING
        iv_task    TYPE trkorr
        it_entries TYPE ty_entries
      RAISING
        zcx_pdf_studio.

    "! Chooses a request and records the entries; returns the request (not the task).
    CLASS-METHODS transport
      IMPORTING
        it_entries        TYPE ty_entries
      RETURNING
        VALUE(rv_request) TYPE trkorr
      RAISING
        zcx_pdf_studio.

    "! In clients with automatic recording a changed entry must go into a request at once.
    CLASS-METHODS record_if_automatic
      IMPORTING
        it_entries        TYPE ty_entries
      RETURNING
        VALUE(rv_request) TYPE trkorr
      RAISING
        zcx_pdf_studio.
ENDCLASS.



CLASS zcl_pdf_studio_transport IMPLEMENTATION.

  METHOD client_recording.
    SELECT SINGLE cccoractiv FROM t000 INTO rv_flag WHERE mandt = sy-mandt.
  ENDMETHOD.


  METHOD choose_request.
    DATA lv_order TYPE trkorr.
    DATA lv_task TYPE trkorr.
    DATA lv_text TYPE string.
    DATA lx_call TYPE REF TO cx_sy_dyn_call_error.

    IF client_recording( ) = '3'.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |Client { sy-mandt } does not allow transports (SCC4). | &&
                            |Set "Automatic recording of changes" or "Changes without automatic recording" and try again.|.
    ENDIF.
    TRY.
        CALL FUNCTION 'TR_ORDER_CHOICE_CORRECTION'
          EXPORTING
            iv_category            = 'CUST'
            iv_cli_dep             = abap_true
          IMPORTING
            ev_order               = lv_order
            ev_task                = lv_task
          EXCEPTIONS
            invalid_category       = 1
            no_correction_selected = 2
            OTHERS                 = 3.
      CATCH cx_sy_dyn_call_error INTO lx_call.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING previous = lx_call
                    message  = |Transport request could not be chosen: { lx_call->get_text( ) }|.
    ENDTRY.
    IF sy-subrc = 2.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'No transport request was chosen.'.
    ELSEIF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_text.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |Transport request could not be chosen: { lv_text }|.
    ENDIF.
    rv_task = lv_task.
    IF rv_task IS INITIAL.
      rv_task = lv_order.
    ENDIF.
  ENDMETHOD.


  METHOD record.
    "TABLES parameters of the transport API need standard tables with a default key.
    DATA lt_e071 TYPE STANDARD TABLE OF e071 WITH DEFAULT KEY.
    DATA lt_e071k TYPE STANDARD TABLE OF e071k WITH DEFAULT KEY.
    DATA ls_e071 TYPE e071.
    DATA ls_e071k TYPE e071k.
    DATA ls_entry TYPE ty_entry.
    DATA lv_text TYPE string.
    DATA lx_call TYPE REF TO cx_sy_dyn_call_error.

    LOOP AT it_entries INTO ls_entry.
      READ TABLE lt_e071 TRANSPORTING NO FIELDS WITH KEY obj_name = ls_entry-tabname.
      IF sy-subrc <> 0.
        CLEAR ls_e071.
        ls_e071-trkorr = iv_task.
        ls_e071-pgmid = 'R3TR'.
        ls_e071-object = 'TABU'.
        ls_e071-obj_name = ls_entry-tabname.
        ls_e071-objfunc = 'K'.
        APPEND ls_e071 TO lt_e071.
      ENDIF.
      CLEAR ls_e071k.
      ls_e071k-trkorr = iv_task.
      ls_e071k-pgmid = 'R3TR'.
      ls_e071k-object = 'TABU'.
      ls_e071k-objname = ls_entry-tabname.
      ls_e071k-mastertype = 'TABU'.
      ls_e071k-mastername = ls_entry-tabname.
      CONCATENATE sy-mandt ls_entry-key INTO ls_e071k-tabkey RESPECTING BLANKS.
      APPEND ls_e071k TO lt_e071k.
    ENDLOOP.
    IF lt_e071k IS INITIAL.
      RETURN.
    ENDIF.
    TRY.
        CALL FUNCTION 'TR_APPEND_TO_COMM_OBJS_KEYS'
          EXPORTING
            wi_trkorr = iv_task
          TABLES
            wt_e071   = lt_e071
            wt_e071k  = lt_e071k
          EXCEPTIONS
            OTHERS    = 1.
      CATCH cx_sy_dyn_call_error INTO lx_call.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING previous = lx_call
                    message  = |Entries could not be added to request { iv_task }: { lx_call->get_text( ) }|.
    ENDTRY.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_text.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |Entries could not be added to request { iv_task }: { lv_text }|.
    ENDIF.
  ENDMETHOD.


  METHOD transport.
    DATA lv_task TYPE trkorr.
    lv_task = choose_request( ).
    record( iv_task = lv_task it_entries = it_entries ).
    SELECT SINGLE strkorr FROM e070 INTO rv_request WHERE trkorr = lv_task.
    IF rv_request IS INITIAL.
      rv_request = lv_task.
    ENDIF.
  ENDMETHOD.


  METHOD record_if_automatic.
    IF client_recording( ) = '1'.
      rv_request = transport( it_entries ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
