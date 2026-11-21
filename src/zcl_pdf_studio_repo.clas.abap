CLASS zcl_pdf_studio_repo DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "Gotenberg is reached only through this SM59 destination (no URL override).
    CONSTANTS gc_gotenberg_dest TYPE c LENGTH 32 VALUE 'ZPDF_STUDIO_GOTENBERG'.
    CONSTANTS gc_gotenberg_url TYPE c LENGTH 200 VALUE 'dest://ZPDF_STUDIO_GOTENBERG'.
    TYPES ty_form_id TYPE string.
    TYPES ty_version TYPE n LENGTH 4.
    TYPES:
      BEGIN OF ty_form,
        form_id        TYPE string,
        description    TYPE string,
        package        TYPE string,
        ddic_structure TYPE string,
        created_by     TYPE syuname,
        created_at     TYPE timestamp,
        changed_by     TYPE syuname,
        changed_at     TYPE timestamp,
      END OF ty_form,
      BEGIN OF ty_template,
        form_id        TYPE string,
        version        TYPE ty_version,
        html_content   TYPE string,
        css_content    TYPE string,
        header_html    TYPE string,
        footer_html    TYPE string,
        page_size      TYPE string,
        orientation    TYPE string,
        margin_top     TYPE i,
        margin_right   TYPE i,
        margin_bottom  TYPE i,
        margin_left    TYPE i,
        sample_json    TYPE string,
        is_active      TYPE c LENGTH 1,
        changed_by     TYPE syuname,
        changed_at     TYPE timestamp,
      END OF ty_template,
      ty_forms     TYPE STANDARD TABLE OF ty_form WITH KEY form_id,
      ty_templates TYPE STANDARD TABLE OF ty_template WITH KEY form_id version.

    CLASS-METHODS set_runtime
      IMPORTING
        iv_url     TYPE string
        iv_timeout TYPE i
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS create_form
      IMPORTING
        iv_form_id        TYPE string
        iv_description    TYPE string OPTIONAL
        iv_package        TYPE string OPTIONAL
        iv_ddic_structure TYPE string OPTIONAL
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS read_form
      IMPORTING
        iv_form_id     TYPE string
      RETURNING
        VALUE(rs_form) TYPE ty_form
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS update_form
      IMPORTING
        iv_form_id        TYPE string
        iv_description    TYPE string OPTIONAL
        iv_ddic_structure TYPE string OPTIONAL
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS delete_form
      IMPORTING
        iv_form_id TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS list_forms
      RETURNING
        VALUE(rt_forms) TYPE ty_forms
      RAISING zcx_pdf_studio.

    CLASS-METHODS save_template
      IMPORTING
        is_template       TYPE ty_template
        iv_new_version    TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_version) TYPE ty_version
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS read_active_template
      IMPORTING
        iv_form_id         TYPE string
      RETURNING
        VALUE(rs_template) TYPE ty_template
      RAISING
        zcx_pdf_studio.

    "! Makes an older version the active one (rollback); the store is saved.
    CLASS-METHODS activate_version
      IMPORTING
        iv_form_id TYPE string
        iv_version TYPE ty_version
      RAISING
        zcx_pdf_studio.

    "! Number of versions kept per form when a template is saved with iv_new_version.
    CONSTANTS c_keep_versions TYPE i VALUE 20.

    CLASS-METHODS list_versions
      IMPORTING
        iv_form_id          TYPE string
      RETURNING
        VALUE(rt_templates) TYPE ty_templates
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS get_config
      IMPORTING
        iv_param        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    CLASS-METHODS set_config
      IMPORTING
        iv_param TYPE string
        iv_value TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS commit_changes RAISING zcx_pdf_studio.
    CLASS-METHODS abort_changes.

    "Transportable store: table ZPDF_STUDIO_FORM (see the program header).
    TYPES:
      BEGIN OF ty_form_request,
        form_id TYPE string,
        request TYPE trkorr,
      END OF ty_form_request,
      ty_form_requests TYPE STANDARD TABLE OF ty_form_request WITH EMPTY KEY.
    CONSTANTS c_table TYPE tabname VALUE 'ZPDF_STUDIO_FORM'.

    "TABLE when ZPDF_STUDIO_FORM exists, INDX otherwise.
    CLASS-METHODS store_mode
      RETURNING VALUE(rv_mode) TYPE string.

    "SCC4 setting of this client: 1 = automatic recording, 2 = no changes allowed.
    CLASS-METHODS client_recording
      RETURNING VALUE(rv_flag) TYPE t000-cccoractiv.

    "The store is set up once per client: old INDX forms are copied, or the demo form is
    "installed. After that an empty store stays empty when all forms are deleted.
    CLASS-METHODS store_initialized
      RETURNING VALUE(rv_done) TYPE abap_bool.
    "Writes the marker; it is saved with the next COMMIT WORK of the caller.
    CLASS-METHODS mark_initialized
      RAISING zcx_pdf_studio.

    "Adds the stored form to a transport request chosen by the user; returns the request.
    CLASS-METHODS transport_form
      IMPORTING iv_form_id        TYPE string
      RETURNING VALUE(rv_request) TYPE trkorr
      RAISING   zcx_pdf_studio.

    "Forms recorded in modifiable requests of this client.
    CLASS-METHODS form_requests
      RETURNING VALUE(rt_requests) TYPE ty_form_requests.

    "Request of the last commit with automatic recording, and one-off store notes.
    CLASS-METHODS last_request
      RETURNING VALUE(rv_request) TYPE trkorr.
    CLASS-METHODS take_note
      RETURNING VALUE(rv_note) TYPE string.

    CLASS-METHODS reset_demo
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS reload
      RAISING
        zcx_pdf_studio.

protected section.
  PRIVATE SECTION.
    TYPES ty_varkey TYPE c LENGTH 250.
    TYPES:
      BEGIN OF ty_page,
        page_size     TYPE string,
        orientation   TYPE c LENGTH 1,
        margin_top    TYPE i,
        margin_right  TYPE i,
        margin_bottom TYPE i,
        margin_left   TYPE i,
      END OF ty_page.
    "S_PROGRAM groups ZPDFSVIW / ZPDFSEDT / ZPDFSADM, action SUBMIT.
    CLASS-METHODS check_authority
      IMPORTING iv_group TYPE csequence
      RAISING   zcx_pdf_studio.
    CLASS-METHODS validate_page
      IMPORTING is_page TYPE ty_page
      RAISING   zcx_pdf_studio.
    CLASS-DATA gv_url TYPE string.
    CLASS-DATA gv_timeout TYPE i.
    CLASS-DATA gv_stack TYPE string.
    CLASS-DATA gv_engine_mode TYPE string.
    CONSTANTS c_store_id TYPE indx-srtfd VALUE 'ZPDF_STUDIO_FORMS'.
    CONSTANTS c_setup_id TYPE indx-srtfd VALUE 'ZPDF_STUDIO_SETUP'.
    CLASS-DATA gt_forms TYPE ty_forms.
    CLASS-DATA gt_templates TYPE ty_templates.
    CLASS-DATA gv_loaded TYPE abap_bool.
    CLASS-DATA gt_base_forms TYPE ty_forms.
    CLASS-DATA gt_base_templates TYPE ty_templates.
    CLASS-DATA gv_dirty TYPE abap_bool.
    CLASS-DATA gv_locked TYPE abap_bool.
    CLASS-METHODS unlock_store.
    CLASS-METHODS lock_key RETURNING VALUE(rv_key) TYPE ty_varkey.

    CLASS-METHODS normalize_id
      IMPORTING
        iv_form_id        TYPE string
      RETURNING
        VALUE(rv_form_id) TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS check_ddic
      IMPORTING
        iv_type_name TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS timestamp
      RETURNING
        VALUE(rv_ts) TYPE timestamp.

    CLASS-METHODS insert_version
      IMPORTING
        is_template       TYPE ty_template
        iv_keep           TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_version) TYPE ty_version
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS prepare_template
      CHANGING
        cs_template TYPE ty_template
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS seed_demo
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS load_store RAISING zcx_pdf_studio.

    CLASS-METHODS persist
      RAISING
        zcx_pdf_studio.

    CLASS-DATA gv_mode TYPE string.
    CLASS-DATA gv_mode_error TYPE string.
    CLASS-DATA gv_lock_tab TYPE tabname.
    CLASS-DATA gv_lock_key TYPE ty_varkey.
    CLASS-DATA gt_lock_keys TYPE string_table.
    CLASS-DATA gv_last_request TYPE trkorr.
    CLASS-DATA gv_note TYPE string.

    CLASS-METHODS table_ready
      RETURNING VALUE(rv_ready) TYPE abap_bool
      RAISING   zcx_pdf_studio.
    CLASS-METHODS db_read
      EXPORTING et_forms     TYPE ty_forms
                et_templates TYPE ty_templates
      RAISING   zcx_pdf_studio.
    CLASS-METHODS db_write_form
      IMPORTING iv_form_id TYPE string
      RAISING   zcx_pdf_studio.
    CLASS-METHODS pack
      IMPORTING is_form           TYPE ty_form
                is_template       TYPE ty_template
      RETURNING VALUE(rv_content) TYPE xstring
      RAISING   zcx_pdf_studio.
    CLASS-METHODS unpack
      IMPORTING iv_content  TYPE xstring
      EXPORTING es_form     TYPE ty_form
                es_template TYPE ty_template
      RAISING   zcx_pdf_studio.
    CLASS-METHODS same_form
      IMPORTING iv_form_id     TYPE string
                it_forms_a     TYPE ty_forms
                it_templates_a TYPE ty_templates
                it_forms_b     TYPE ty_forms
                it_templates_b TYPE ty_templates
      RETURNING VALUE(rv_same) TYPE abap_bool.
    CLASS-METHODS changed_forms
      RETURNING VALUE(rt_ids) TYPE string_table.
    CLASS-METHODS is_local
      IMPORTING iv_form_id      TYPE string
      RETURNING VALUE(rv_local) TYPE abap_bool.
    CLASS-METHODS commit_table
      IMPORTING iv_record TYPE abap_bool DEFAULT abap_true
      RAISING   zcx_pdf_studio.
    CLASS-METHODS choose_request
      RETURNING VALUE(rv_task) TYPE trkorr
      RAISING   zcx_pdf_studio.
    CLASS-METHODS record_forms
      IMPORTING it_ids  TYPE string_table
                iv_task TYPE trkorr
      RAISING   zcx_pdf_studio.
    CLASS-METHODS lock_store
      IMPORTING iv_tab TYPE tabname
                iv_key TYPE ty_varkey
      RAISING   zcx_pdf_studio.
    CLASS-METHODS read_active_row
      IMPORTING iv_form_id         TYPE string
      RETURNING VALUE(rs_template) TYPE ty_template
      RAISING   zcx_pdf_studio.
ENDCLASS.



CLASS ZCL_PDF_STUDIO_REPO IMPLEMENTATION.


  METHOD set_runtime.
    DATA lv_approved TYPE string.
    gv_url = iv_url.
    SHIFT gv_url LEFT DELETING LEADING space.
    SHIFT gv_url RIGHT DELETING TRAILING space.
    IF gv_url IS INITIAL.
      gv_url = gc_gotenberg_url.
    ENDIF.
    lv_approved = |dest://{ gc_gotenberg_dest }|.
    IF gv_url <> lv_approved.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |Only the configured destination { lv_approved } is allowed|.
    ENDIF.
    gv_timeout = iv_timeout.
    IF gv_timeout < 1 OR gv_timeout > 300.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Timeout must be between 1 and 300 seconds'.
    ENDIF.
    IF gv_stack IS INITIAL.
      gv_stack = 'CLASSIC'.
    ENDIF.
    load_store( ).
  ENDMETHOD.


  METHOD create_form.
    check_authority( 'ZPDFSEDT' ).
    load_store( ).
    DATA ls_form TYPE ty_form.
    DATA lv_id TYPE string.

    lv_id = normalize_id( iv_form_id ).
    check_ddic( iv_ddic_structure ).

    READ TABLE gt_forms TRANSPORTING NO FIELDS WITH KEY form_id = lv_id.
    IF sy-subrc = 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = |Form { lv_id } already exists|.
    ENDIF.

    ls_form-form_id = lv_id.
    ls_form-description = iv_description.
    IF ls_form-description IS INITIAL.
      ls_form-description = lv_id.
    ENDIF.
    ls_form-package = to_upper( iv_package ).
    IF ls_form-package IS INITIAL.
      ls_form-package = '$TMP'.
    ENDIF.
    ls_form-ddic_structure = to_upper( iv_ddic_structure ).
    ls_form-created_by = sy-uname.
    ls_form-changed_by = sy-uname.
    ls_form-created_at = timestamp( ).
    ls_form-changed_at = ls_form-created_at.
    APPEND ls_form TO gt_forms.
    persist( ).
  ENDMETHOD.


  METHOD read_form.
    load_store( ).
    DATA lv_id TYPE string.
    lv_id = normalize_id( iv_form_id ).
    READ TABLE gt_forms INTO rs_form WITH KEY form_id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = |Form { lv_id } does not exist|.
    ENDIF.
  ENDMETHOD.


  METHOD update_form.
    check_authority( 'ZPDFSEDT' ).
    load_store( ).
    DATA lv_id TYPE string.
    DATA lv_ts TYPE timestamp.
    FIELD-SYMBOLS <form> TYPE ty_form.

    lv_id = normalize_id( iv_form_id ).
    read_form( lv_id ).
    check_ddic( iv_ddic_structure ).
    READ TABLE gt_forms ASSIGNING <form> WITH KEY form_id = lv_id.
    lv_ts = timestamp( ).
    <form>-description = iv_description.
    IF <form>-description IS INITIAL.
      <form>-description = lv_id.
    ENDIF.
    <form>-ddic_structure = to_upper( iv_ddic_structure ).
    <form>-changed_by = sy-uname.
    <form>-changed_at = lv_ts.
    persist( ).
  ENDMETHOD.


  METHOD delete_form.
    check_authority( 'ZPDFSADM' ).
    check_authority( 'ZPDFSEDT' ).
    load_store( ).
    DATA lv_id TYPE string.
    lv_id = normalize_id( iv_form_id ).
    read_form( lv_id ).
    DELETE gt_templates WHERE form_id = lv_id.
    DELETE gt_forms WHERE form_id = lv_id.
    persist( ).
  ENDMETHOD.


  METHOD list_forms.
    load_store( ).
    rt_forms = gt_forms.
    SORT rt_forms BY form_id.
  ENDMETHOD.


  METHOD save_template.
    check_authority( 'ZPDFSEDT' ).
    load_store( ).
    DATA ls_template TYPE ty_template.
    FIELD-SYMBOLS <form> TYPE ty_form.

    ls_template = is_template.
    prepare_template( CHANGING cs_template = ls_template ).
    read_form( ls_template-form_id ).
    READ TABLE gt_forms ASSIGNING <form> WITH KEY form_id = ls_template-form_id.
    IF sy-subrc = 0.
      <form>-changed_by = sy-uname.
      <form>-changed_at = timestamp( ).
    ENDIF.

    "iv_new_version keeps the previous versions (the last c_keep_versions), otherwise the
    "stored template is replaced.
    rv_version = insert_version( is_template = ls_template iv_keep = iv_new_version ).
    persist( ).
  ENDMETHOD.


  METHOD read_active_template.
    DATA lv_id TYPE string.
    DATA ls_row TYPE ty_template.
    DATA lv_found TYPE abap_bool.

    "Printing: when the store is not loaded yet, read only the active row of this form
    "instead of loading and unpacking every form and version.
    IF gv_loaded = abap_false AND table_ready( ) = abap_true.
      rs_template = read_active_row( iv_form_id ).
      IF rs_template IS NOT INITIAL.
        RETURN.
      ENDIF.
    ENDIF.
    load_store( ).
    lv_id = normalize_id( iv_form_id ).
    read_form( lv_id ).

    LOOP AT gt_templates INTO ls_row WHERE form_id = lv_id AND is_active = abap_true.
      rs_template = ls_row.
      lv_found = abap_true.
      EXIT.
    ENDLOOP.
    IF lv_found = abap_true.
      RETURN.
    ENDIF.

    LOOP AT gt_templates INTO ls_row WHERE form_id = lv_id.
      IF lv_found = abap_false OR ls_row-version > rs_template-version.
        rs_template = ls_row.
        lv_found = abap_true.
      ENDIF.
    ENDLOOP.
    IF lv_found = abap_false.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = |Form { lv_id } has no template|.
    ENDIF.
  ENDMETHOD.


  METHOD activate_version.
    DATA lv_id TYPE string.
    DATA lv_found TYPE abap_bool.
    check_authority( 'ZPDFSEDT' ).
    load_store( ).
    lv_id = normalize_id( iv_form_id ).
    LOOP AT gt_templates ASSIGNING FIELD-SYMBOL(<row>) WHERE form_id = lv_id.
      <row>-is_active = xsdbool( <row>-version = iv_version ).
      IF <row>-version = iv_version.
        lv_found = abap_true.
      ENDIF.
    ENDLOOP.
    IF lv_found = abap_false.
      abort_changes( ).
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |Form { lv_id } has no version { iv_version }|.
    ENDIF.
    gv_dirty = abap_true.
    persist( ).
    commit_changes( ).
  ENDMETHOD.


  METHOD list_versions.
    load_store( ).
    DATA lv_id TYPE string.
    DATA ls_row TYPE ty_template.
    lv_id = normalize_id( iv_form_id ).
    read_form( lv_id ).
    LOOP AT gt_templates INTO ls_row WHERE form_id = lv_id.
      APPEND ls_row TO rt_templates.
    ENDLOOP.
    SORT rt_templates BY version DESCENDING.
  ENDMETHOD.


  METHOD get_config.
    CASE to_upper( iv_param ).
      WHEN 'GOTENBERG_URL'.
        rv_value = gv_url.
        IF rv_value IS INITIAL.
          rv_value = gc_gotenberg_url.
        ENDIF.
      WHEN 'HTTP_TIMEOUT'.
        IF gv_timeout <= 0.
          rv_value = '60'.
        ELSE.
          rv_value = gv_timeout.
        ENDIF.
      WHEN 'HTTP_STACK'.
        rv_value = gv_stack.
        IF rv_value IS INITIAL.
          rv_value = 'CLASSIC'.
        ENDIF.
      WHEN 'ENGINE'.
        rv_value = gv_engine_mode.
        IF rv_value IS INITIAL.
          rv_value = 'NATIVE'.
        ENDIF.
      WHEN OTHERS.
        CLEAR rv_value.
    ENDCASE.
  ENDMETHOD.


  METHOD set_config.
    DATA lv_timeout TYPE i.
    CASE to_upper( iv_param ).
      WHEN 'GOTENBERG_URL'.
        set_runtime( iv_url = iv_value iv_timeout = CONV i( get_config( 'HTTP_TIMEOUT' ) ) ).
      WHEN 'HTTP_TIMEOUT'.
        TRY.
            lv_timeout = iv_value.
          CATCH cx_root INTO DATA(lx_number).
            RAISE EXCEPTION TYPE zcx_pdf_studio
              EXPORTING previous = lx_number message = 'Invalid HTTP timeout'.
        ENDTRY.
        set_runtime( iv_url = get_config( 'GOTENBERG_URL' ) iv_timeout = lv_timeout ).
      WHEN 'HTTP_STACK'.
        IF to_upper( iv_value ) <> 'CLASSIC'.
          RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Only the CLASSIC HTTP stack is supported'.
        ENDIF.
        gv_stack = to_upper( iv_value ).
      WHEN 'ENGINE'.
        IF to_upper( iv_value ) <> 'NATIVE' AND to_upper( iv_value ) <> 'GOTENBERG'.
          RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'PDF engine must be NATIVE or GOTENBERG'.
        ENDIF.
        gv_engine_mode = to_upper( iv_value ).
      WHEN OTHERS.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING message = |Unknown config parameter { iv_param }|.
    ENDCASE.
  ENDMETHOD.


  METHOD reset_demo.
    check_authority( 'ZPDFSADM' ).
    check_authority( 'ZPDFSEDT' ).
    load_store( ).
    DELETE gt_templates WHERE form_id = 'ZPDF_DEMO'.
    DELETE gt_forms WHERE form_id = 'ZPDF_DEMO'.
    seed_demo( ).
  ENDMETHOD.


  METHOD normalize_id.
    rv_form_id = to_upper( iv_form_id ).
    SHIFT rv_form_id LEFT DELETING LEADING space.
    SHIFT rv_form_id RIGHT DELETING TRAILING space.
    IF rv_form_id IS INITIAL
        OR strlen( rv_form_id ) > 30
        OR rv_form_id CN 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = 'Form ID must contain only A-Z, 0-9, and underscore'.
    ENDIF.
  ENDMETHOD.


  METHOD check_ddic.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA lv_name TYPE string.

    lv_name = to_upper( iv_type_name ).
    SHIFT lv_name LEFT DELETING LEADING space.
    IF lv_name IS INITIAL.
      RETURN.
    ENDIF.

    CALL METHOD cl_abap_typedescr=>describe_by_name
      EXPORTING
        p_name         = lv_name
      RECEIVING
        p_descr_ref    = lo_type
      EXCEPTIONS
        type_not_found = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = |DDIC type { lv_name } does not exist|.
    ENDIF.
    IF lo_type->kind <> cl_abap_typedescr=>kind_struct
        AND lo_type->kind <> cl_abap_typedescr=>kind_table.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = |{ lv_name } is not a structure or table type|.
    ENDIF.
  ENDMETHOD.


  METHOD timestamp.
    GET TIME STAMP FIELD rv_ts.
  ENDMETHOD.


  METHOD prepare_template.
    cs_template-form_id = normalize_id( cs_template-form_id ).
    cs_template-page_size = to_upper( cs_template-page_size ).
    cs_template-orientation = to_upper( cs_template-orientation ).
    IF cs_template-page_size IS INITIAL.
      cs_template-page_size = 'A4'.
    ENDIF.
    IF cs_template-orientation IS INITIAL.
      cs_template-orientation = 'P'.
    ENDIF.
    DATA ls_page TYPE ty_page.
    MOVE-CORRESPONDING cs_template TO ls_page.
    validate_page( ls_page ).
    IF strlen( cs_template-html_content ) + strlen( cs_template-css_content ) +
       strlen( cs_template-header_html ) + strlen( cs_template-footer_html ) +
       strlen( cs_template-sample_json ) > 2000000.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Template exceeds 2 million characters'.
    ENDIF.
  ENDMETHOD.


  METHOD insert_version.
    DATA lt_old TYPE ty_templates.
    DATA ls_template TYPE ty_template.
    DATA ls_row TYPE ty_template.
    DATA lv_max TYPE ty_version.

    ls_template = is_template.
    LOOP AT gt_templates INTO ls_row WHERE form_id = ls_template-form_id.
      IF ls_row-version > lv_max.
        lv_max = ls_row-version.
      ENDIF.
    ENDLOOP.

    IF lv_max >= 9999.
      "Counter exhausted: start again with an empty history.
      lv_max = 0.
      DELETE gt_templates WHERE form_id = ls_template-form_id.
    ELSEIF iv_keep = abap_true.
      "Version history: older versions stay inactive, only the newest ones are kept.
      LOOP AT gt_templates ASSIGNING FIELD-SYMBOL(<old>) WHERE form_id = ls_template-form_id.
        <old>-is_active = abap_false.
      ENDLOOP.
      lt_old = VALUE #( FOR r IN gt_templates WHERE ( form_id = ls_template-form_id ) ( r ) ).
      SORT lt_old BY version DESCENDING.
      LOOP AT lt_old INTO ls_row FROM c_keep_versions.
        DELETE gt_templates WHERE form_id = ls_row-form_id AND version = ls_row-version.
      ENDLOOP.
    ELSE.
      DELETE gt_templates WHERE form_id = ls_template-form_id.
    ENDIF.

    ls_template-version = lv_max + 1.
    ls_template-is_active = abap_true.
    ls_template-changed_by = sy-uname.
    ls_template-changed_at = timestamp( ).
    APPEND ls_template TO gt_templates.
    rv_version = ls_template-version.
  ENDMETHOD.


  METHOD seed_demo.
    DATA ls_template TYPE ty_template.
    READ TABLE gt_forms TRANSPORTING NO FIELDS WITH KEY form_id = 'ZPDF_DEMO'.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    TRY.
        create_form(
          iv_form_id        = 'ZPDF_DEMO'
          iv_description    = 'SFLIGHT boarding card'
          iv_ddic_structure = 'SFLIGHT' ).
      CATCH zcx_pdf_studio.
        create_form(
          iv_form_id     = 'ZPDF_DEMO'
          iv_description = 'SFLIGHT boarding card' ).
    ENDTRY.

    ls_template-form_id = 'ZPDF_DEMO'.
    ls_template-page_size = 'A4'.
    ls_template-orientation = 'P'.
    ls_template-margin_top = 16.
    ls_template-margin_right = 14.
    ls_template-margin_bottom = 18.
    ls_template-margin_left = 14.
    ls_template-html_content =
      '<h1>{{carrid}} {{connid}}</h1>' &&
      '<p>Date {{fldate}}</p>' &&
      '<p>Aircraft {{planetype}}</p>' &&
      '<p>Price {{price}} {{currency}}</p>' &&
      '<p>Seats {{seatsocc}} / {{seatsmax}}</p>'.
    ls_template-css_content =
      'body{font-family:Arial,sans-serif;color:#1f2933;}' &&
      'h1{font-size:28pt;margin:0 0 12px;color:#0f2744;}' &&
      'p{font-size:12pt;margin:4px 0;}'.
    ls_template-footer_html =
      '<div style="width:100%;text-align:center;font-size:9pt;">' &&
      'Page <span class="pageNumber"></span> / <span class="totalPages"></span>' &&
      '</div>'.
    ls_template-sample_json =
      '{"CARRID":"LH","CONNID":"0400","FLDATE":"20260923","PRICE":"345.00","CURRENCY":"EUR"}'.
    save_template(
      is_template    = ls_template
      iv_new_version = abap_true ).
  ENDMETHOD.


  METHOD reload.
    IF gv_dirty = abap_true.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = 'Commit or discard pending changes before reload'.
    ENDIF.
    CLEAR gv_loaded.
    load_store( ).
  ENDMETHOD.


  METHOD load_store.
    DATA lt_old_forms TYPE ty_forms.
    DATA lt_old_templates TYPE ty_templates.

    check_authority( 'ZPDFSVIW' ).
    IF gv_loaded = abap_true.
      RETURN.
    ENDIF.
    CLEAR: gt_forms, gt_templates.
    IF table_ready( ) = abap_true.
      db_read( IMPORTING et_forms = gt_forms et_templates = gt_templates ).
      gt_base_forms = gt_forms.
      gt_base_templates = gt_templates.
      gv_loaded = abap_true.
      IF gt_forms IS NOT INITIAL.
        RETURN.
      ENDIF.
      "First use of the table: copy the forms of the INDX store (INDX itself is kept).
      "Only once: a table emptied by deleting its forms is not filled again.
      IF store_initialized( ) = abap_true.
        RETURN.
      ENDIF.
      TRY.
          IMPORT forms = lt_old_forms templates = lt_old_templates
            FROM DATABASE indx(zp) ID c_store_id.
        CATCH cx_root.
          CLEAR: lt_old_forms, lt_old_templates.
      ENDTRY.
      IF lt_old_forms IS INITIAL.
        RETURN.
      ENDIF.
      gt_forms = lt_old_forms.
      gt_templates = lt_old_templates.
      TRY.
          IF client_recording( ) = '2'.
            RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Client does not allow changes'.
          ENDIF.
          check_authority( 'ZPDFSEDT' ).
          gv_dirty = abap_true.
          commit_table( iv_record = abap_false ).
          "Saved after the forms, so a failed copy is tried again on the next start.
          mark_initialized( ).
          COMMIT WORK.
          gv_note = |{ lines( lt_old_forms ) } forms were copied from the old INDX store to table { c_table }. Use Transport to move them to other systems.|.
        CATCH zcx_pdf_studio INTO DATA(lx_copy).
          "Show the INDX forms read-only; the copy is tried again on the next start.
          gt_forms = lt_old_forms.
          gt_templates = lt_old_templates.
          gt_base_forms = gt_forms.
          gt_base_templates = gt_templates.
          CLEAR gv_dirty.
          gv_note = |Forms are shown from the old INDX store; copying them to { c_table } failed: { lx_copy->get_text( ) }|.
      ENDTRY.
      RETURN.
    ENDIF.
    TRY.
        IMPORT forms = gt_forms templates = gt_templates
          FROM DATABASE indx(zp) ID c_store_id.
      CATCH cx_root INTO DATA(lx_import).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING previous = lx_import
                    message = 'Cannot read template store; no data was overwritten'.
    ENDTRY.
    gt_base_forms = gt_forms.
    gt_base_templates = gt_templates.
    gv_loaded = abap_true.
  ENDMETHOD.


  METHOD persist.
    "Stage only. The caller owns the transaction boundary.
    gv_dirty = abap_true.
  ENDMETHOD.


  METHOD lock_key.
    "Generic prefix covers every SRTF2 chunk of this client/store.
    CONCATENATE sy-mandt 'ZP' c_store_id INTO rv_key RESPECTING BLANKS.
  ENDMETHOD.


  METHOD unlock_store.
    DATA lv_key_text TYPE string.
    IF gv_locked = abap_true.
      LOOP AT gt_lock_keys INTO lv_key_text.
        gv_lock_key = lv_key_text.
        CALL FUNCTION 'DEQUEUE_E_TABLE'
          EXPORTING tabname = gv_lock_tab varkey = conv VIM_ENQKEY( gv_lock_key ) _scope = '1'.
      ENDLOOP.
      CLEAR gt_lock_keys.
      gv_locked = abap_false.
    ENDIF.
  ENDMETHOD.


  METHOD read_active_row.
    DATA lr_rows TYPE REF TO data.
    DATA lv_id TYPE string.
    DATA lv_key TYPE c LENGTH 30.
    DATA lv_content TYPE xstring.
    DATA ls_form TYPE ty_form.
    FIELD-SYMBOLS <lt_rows> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <ls_row> TYPE any.
    FIELD-SYMBOLS <lv_field> TYPE any.

    check_authority( 'ZPDFSVIW' ).
    lv_id = normalize_id( iv_form_id ).
    lv_key = lv_id.
    CREATE DATA lr_rows TYPE STANDARD TABLE OF (c_table).
    ASSIGN lr_rows->* TO <lt_rows>.
    SELECT * FROM (c_table) INTO TABLE <lt_rows> WHERE form_id = lv_key AND is_active = abap_true.
    LOOP AT <lt_rows> ASSIGNING <ls_row>.
      ASSIGN COMPONENT 'CONTENT' OF STRUCTURE <ls_row> TO <lv_field>.
      lv_content = <lv_field>.
      unpack( EXPORTING iv_content = lv_content IMPORTING es_form = ls_form es_template = rs_template ).
      IF rs_template-html_content IS NOT INITIAL OR rs_template-version IS NOT INITIAL.
        RETURN.
      ENDIF.
    ENDLOOP.
    CLEAR rs_template.
  ENDMETHOD.


  METHOD lock_store.
    CALL FUNCTION 'ENQUEUE_E_TABLE'
      EXPORTING tabname = iv_tab varkey = conv VIM_ENQKEY( iv_key )
                _scope = '1' _wait = abap_false
      EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = 'Template store is busy. Your draft is retained; retry Save.'.
    ENDIF.
    gv_lock_tab = iv_tab.
    gv_lock_key = iv_key.
    APPEND CONV string( iv_key ) TO gt_lock_keys.
    gv_locked = abap_true.
  ENDMETHOD.


  METHOD abort_changes.
    "No database writes occur until commit_changes.
    gt_forms = gt_base_forms.
    gt_templates = gt_base_templates.
    CLEAR gv_dirty.
    unlock_store( ).
  ENDMETHOD.


  METHOD commit_changes.
    DATA lv_lock_tab TYPE tabname.
    DATA lt_current_forms TYPE ty_forms.
    DATA lt_current_templates TYPE ty_templates.
    IF gv_dirty = abap_false.
      RETURN.
    ENDIF.
    check_authority( 'ZPDFSEDT' ).
    IF table_ready( ) = abap_true.
      commit_table( ).
      RETURN.
    ENDIF.
    lv_lock_tab = 'INDX'.
    lock_store( iv_tab = lv_lock_tab iv_key = lock_key( ) ).
    TRY.
        IMPORT forms = lt_current_forms templates = lt_current_templates
          FROM DATABASE indx(zp) ID c_store_id.
        IF lt_current_forms <> gt_base_forms OR
           lt_current_templates <> gt_base_templates.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING message = 'Another session changed the store. Copy your draft, reopen the form, and reapply your changes.'.
        ENDIF.
        EXPORT forms = gt_forms templates = gt_templates
          TO DATABASE indx(zp) ID c_store_id.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING message = 'Could not persist templates'.
        ENDIF.
        "This report is the transaction owner. Do not call within a BAPI LUW.
        COMMIT WORK AND WAIT.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Commit reported an update failure; verify the saved store before retrying'.
        ENDIF.
        gt_base_forms = gt_forms.
        gt_base_templates = gt_templates.
        CLEAR gv_dirty.
        unlock_store( ).
      CATCH cx_root INTO DATA(lx_store).
        ROLLBACK WORK.
        unlock_store( ).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING previous = lx_store message = lx_store->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD store_mode.
    TRY.
        IF table_ready( ) = abap_true.
          rv_mode = 'TABLE'.
        ELSE.
          rv_mode = 'INDX'.
        ENDIF.
      CATCH zcx_pdf_studio.
        rv_mode = 'INVALID'.
    ENDTRY.
  ENDMETHOD.


  METHOD table_ready.
    DATA lv_class TYPE dd02l-tabclass.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lt_need TYPE string_table.
    DATA lv_need TYPE string.

    IF gv_mode IS INITIAL.
      gv_mode = 'INDX'.
      SELECT SINGLE tabclass FROM dd02l INTO lv_class
        WHERE tabname = c_table AND as4local = 'A' AND as4vers = '0000'.
      IF sy-subrc = 0 AND lv_class = 'TRANSP'.
        gv_mode = 'TABLE'.
        CALL METHOD cl_abap_typedescr=>describe_by_name
          EXPORTING
            p_name         = c_table
          RECEIVING
            p_descr_ref    = lo_type
          EXCEPTIONS
            type_not_found = 1
            OTHERS         = 2.
        IF sy-subrc = 0 AND lo_type->kind = cl_abap_typedescr=>kind_struct.
          lo_struct ?= lo_type.
          APPEND `MANDT` TO lt_need.
          APPEND `FORM_ID` TO lt_need.
          APPEND `VERSION` TO lt_need.
          APPEND `IS_ACTIVE` TO lt_need.
          APPEND `CHANGED_BY` TO lt_need.
          APPEND `CHANGED_AT` TO lt_need.
          APPEND `CONTENT` TO lt_need.
          LOOP AT lt_need INTO lv_need.
            READ TABLE lo_struct->components TRANSPORTING NO FIELDS WITH KEY name = lv_need.
            IF sy-subrc <> 0.
              gv_mode_error = |Table { c_table } has no field { lv_need }. Create it as described in the program header.|.
              EXIT.
            ENDIF.
          ENDLOOP.
        ELSE.
          gv_mode_error = |Table { c_table } cannot be read. Activate it in SE11.|.
        ENDIF.
      ENDIF.
    ENDIF.
    IF gv_mode_error IS NOT INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = gv_mode_error.
    ENDIF.
    rv_ready = boolc( gv_mode = 'TABLE' ).
  ENDMETHOD.


  METHOD pack.
    DATA lv_xml TYPE xstring.
    TRY.
        CALL TRANSFORMATION id SOURCE form = is_form template = is_template RESULT XML lv_xml.
        cl_abap_gzip=>compress_binary( EXPORTING raw_in = lv_xml IMPORTING gzip_out = rv_content ).
      CATCH cx_root INTO DATA(lx_pack).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING previous = lx_pack
                    message  = |Cannot store form { is_form-form_id }: { lx_pack->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.


  METHOD unpack.
    DATA lv_xml TYPE xstring.
    CLEAR: es_form, es_template.
    TRY.
        cl_abap_gzip=>decompress_binary( EXPORTING gzip_in = iv_content IMPORTING raw_out = lv_xml ).
        CALL TRANSFORMATION id SOURCE XML lv_xml RESULT form = es_form template = es_template.
      CATCH cx_root INTO DATA(lx_unpack).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING previous = lx_unpack
                    message  = |A row of { c_table } cannot be read: { lx_unpack->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.


  METHOD db_read.
    DATA lr_rows TYPE REF TO data.
    DATA ls_form TYPE ty_form.
    DATA ls_template TYPE ty_template.
    DATA lv_version TYPE ty_version.
    DATA lv_content TYPE xstring.
    FIELD-SYMBOLS <lt_rows> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <ls_row> TYPE any.
    FIELD-SYMBOLS <lv_field> TYPE any.

    CLEAR: et_forms, et_templates.
    CREATE DATA lr_rows TYPE STANDARD TABLE OF (c_table).
    ASSIGN lr_rows->* TO <lt_rows>.
    SELECT * FROM (c_table) INTO TABLE <lt_rows>.
    LOOP AT <lt_rows> ASSIGNING <ls_row>.
      ASSIGN COMPONENT 'VERSION' OF STRUCTURE <ls_row> TO <lv_field>.
      lv_version = <lv_field>.
      ASSIGN COMPONENT 'CONTENT' OF STRUCTURE <ls_row> TO <lv_field>.
      lv_content = <lv_field>.
      unpack( EXPORTING iv_content = lv_content IMPORTING es_form = ls_form es_template = ls_template ).
      READ TABLE et_forms TRANSPORTING NO FIELDS WITH KEY form_id = ls_form-form_id.
      IF sy-subrc <> 0.
        APPEND ls_form TO et_forms.
      ENDIF.
      "Version 0000 only carries the form of a form without a saved template.
      IF lv_version <> '0000'.
        APPEND ls_template TO et_templates.
      ENDIF.
    ENDLOOP.
    SORT et_forms BY form_id.
    SORT et_templates BY form_id version.
  ENDMETHOD.


  METHOD db_write_form.
    DATA lr_row TYPE REF TO data.
    DATA ls_form TYPE ty_form.
    DATA ls_template TYPE ty_template.
    DATA lt_rows TYPE ty_templates.
    FIELD-SYMBOLS <ls_row> TYPE any.
    FIELD-SYMBOLS <lv_field> TYPE any.

    "Bind the ID as data, including IDs loaded from legacy storage.
    DELETE FROM (c_table) WHERE form_id = @iv_form_id.
    READ TABLE gt_forms INTO ls_form WITH KEY form_id = iv_form_id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT gt_templates INTO ls_template WHERE form_id = iv_form_id.
      APPEND ls_template TO lt_rows.
    ENDLOOP.
    IF lt_rows IS INITIAL.
      CLEAR ls_template.
      ls_template-form_id = iv_form_id.
      ls_template-version = '0000'.
      APPEND ls_template TO lt_rows.
    ENDIF.
    CREATE DATA lr_row TYPE (c_table).
    ASSIGN lr_row->* TO <ls_row>.
    LOOP AT lt_rows INTO ls_template.
      CLEAR <ls_row>.
      ASSIGN COMPONENT 'FORM_ID' OF STRUCTURE <ls_row> TO <lv_field>.
      <lv_field> = iv_form_id.
      ASSIGN COMPONENT 'VERSION' OF STRUCTURE <ls_row> TO <lv_field>.
      <lv_field> = ls_template-version.
      ASSIGN COMPONENT 'IS_ACTIVE' OF STRUCTURE <ls_row> TO <lv_field>.
      <lv_field> = ls_template-is_active.
      ASSIGN COMPONENT 'CHANGED_BY' OF STRUCTURE <ls_row> TO <lv_field>.
      <lv_field> = ls_form-changed_by.
      ASSIGN COMPONENT 'CHANGED_AT' OF STRUCTURE <ls_row> TO <lv_field>.
      <lv_field> = ls_form-changed_at.
      ASSIGN COMPONENT 'CONTENT' OF STRUCTURE <ls_row> TO <lv_field>.
      <lv_field> = pack( is_form = ls_form is_template = ls_template ).
      INSERT (c_table) FROM <ls_row>.
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING message = |Form { iv_form_id } could not be written to { c_table }|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD same_form.
    DATA ls_a TYPE ty_form.
    DATA ls_b TYPE ty_form.
    DATA ls_template TYPE ty_template.
    DATA lt_a TYPE ty_templates.
    DATA lt_b TYPE ty_templates.

    READ TABLE it_forms_a INTO ls_a WITH KEY form_id = iv_form_id.
    READ TABLE it_forms_b INTO ls_b WITH KEY form_id = iv_form_id.
    LOOP AT it_templates_a INTO ls_template WHERE form_id = iv_form_id.
      APPEND ls_template TO lt_a.
    ENDLOOP.
    LOOP AT it_templates_b INTO ls_template WHERE form_id = iv_form_id.
      APPEND ls_template TO lt_b.
    ENDLOOP.
    SORT lt_a BY version.
    SORT lt_b BY version.
    rv_same = boolc( ls_a = ls_b AND lt_a = lt_b ).
  ENDMETHOD.


  METHOD changed_forms.
    DATA ls_form TYPE ty_form.
    DATA lt_ids TYPE string_table.
    DATA lv_id TYPE string.

    LOOP AT gt_forms INTO ls_form.
      APPEND ls_form-form_id TO lt_ids.
    ENDLOOP.
    LOOP AT gt_base_forms INTO ls_form.
      APPEND ls_form-form_id TO lt_ids.
    ENDLOOP.
    SORT lt_ids.
    DELETE ADJACENT DUPLICATES FROM lt_ids.
    LOOP AT lt_ids INTO lv_id.
      IF same_form( iv_form_id = lv_id
                    it_forms_a = gt_forms it_templates_a = gt_templates
                    it_forms_b = gt_base_forms it_templates_b = gt_base_templates ) = abap_false.
        APPEND lv_id TO rt_ids.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD is_local.
    "Forms in a $ package (default $TMP) are local objects, as in Adobe Forms:
    "they are saved without a transport request. A deleted form uses its stored package.
    DATA ls_form TYPE ty_form.
    DATA lv_package TYPE string.
    READ TABLE gt_forms INTO ls_form WITH KEY form_id = iv_form_id.
    IF sy-subrc <> 0.
      READ TABLE gt_base_forms INTO ls_form WITH KEY form_id = iv_form_id.
    ENDIF.
    lv_package = to_upper( condense( ls_form-package ) ).
    rv_local = boolc( lv_package IS INITIAL OR lv_package CP '$*' ).
  ENDMETHOD.


  METHOD commit_table.
    DATA lt_ids TYPE string_table.
    DATA lt_record TYPE string_table.
    DATA lv_id TYPE string.
    DATA lv_task TYPE trkorr.
    DATA lt_db_forms TYPE ty_forms.
    DATA lt_db_templates TYPE ty_templates.
    DATA lv_lock_key TYPE ty_varkey.
    DATA lv_lock_id TYPE c LENGTH 30.
    DATA ls_saved_form TYPE ty_form.
    DATA ls_saved_template TYPE ty_template.

    CLEAR gv_last_request.
    lt_ids = changed_forms( ).
    IF lt_ids IS INITIAL.
      CLEAR gv_dirty.
      RETURN.
    ENDIF.
    CASE client_recording( ).
      WHEN '2'.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING message = 'Forms cannot be changed in this client (SCC4: no changes allowed). Change them in the development system and transport them.'.
      WHEN '1'.
        "Automatic recording: every change of a form goes into a request, as in SPRO.
        "Local forms ($TMP) are saved without a request.
        IF iv_record = abap_true.
          LOOP AT lt_ids INTO lv_id.
            IF is_local( lv_id ) = abap_false.
              APPEND lv_id TO lt_record.
            ENDIF.
          ENDLOOP.
          IF lt_record IS NOT INITIAL.
            lv_task = choose_request( ).
          ENDIF.
        ENDIF.
    ENDCASE.
    "One lock per changed form, so different forms can be saved at the same time.
    LOOP AT lt_ids INTO lv_id.
      lv_lock_id = lv_id.
      CONCATENATE sy-mandt lv_lock_id INTO lv_lock_key RESPECTING BLANKS.
      TRY.
          lock_store( iv_tab = c_table iv_key = lv_lock_key ).
        CATCH zcx_pdf_studio.
          unlock_store( ).
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING message = |Form { lv_id } is being saved by another user. Your draft is retained; retry Save.|.
      ENDTRY.
    ENDLOOP.
    TRY.
        "Only the changed forms are checked and rewritten; forms that arrived by
        "transport or were saved by someone else meanwhile stay untouched.
        db_read( IMPORTING et_forms = lt_db_forms et_templates = lt_db_templates ).
        LOOP AT lt_ids INTO lv_id.
          IF same_form( iv_form_id = lv_id
                        it_forms_a = lt_db_forms it_templates_a = lt_db_templates
                        it_forms_b = gt_base_forms it_templates_b = gt_base_templates ) = abap_false.
            RAISE EXCEPTION TYPE zcx_pdf_studio
              EXPORTING message = |Form { lv_id } was changed in another session or by a transport. Copy your draft, reopen the form, and reapply your changes.|.
          ENDIF.
        ENDLOOP.
        LOOP AT lt_ids INTO lv_id.
          db_write_form( lv_id ).
        ENDLOOP.
        IF lv_task IS NOT INITIAL.
          record_forms( it_ids = lt_record iv_task = lv_task ).
        ENDIF.
        COMMIT WORK AND WAIT.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Commit reported an update failure; verify the saved store before retrying'.
        ENDIF.
        "The changed forms are now stored as in memory; the others keep their old base,
        "so a later save still notices if they were changed by someone else.
        gt_base_forms = gt_forms.
        gt_base_templates = gt_templates.
        db_read( IMPORTING et_forms = lt_db_forms et_templates = lt_db_templates ).
        LOOP AT lt_ids INTO lv_id.
          DELETE gt_forms WHERE form_id = lv_id.
          DELETE gt_templates WHERE form_id = lv_id.
          DELETE gt_base_forms WHERE form_id = lv_id.
          DELETE gt_base_templates WHERE form_id = lv_id.
          LOOP AT lt_db_forms INTO ls_saved_form WHERE form_id = lv_id.
            APPEND ls_saved_form TO gt_forms.
            APPEND ls_saved_form TO gt_base_forms.
          ENDLOOP.
          LOOP AT lt_db_templates INTO ls_saved_template WHERE form_id = lv_id.
            APPEND ls_saved_template TO gt_templates.
            APPEND ls_saved_template TO gt_base_templates.
          ENDLOOP.
        ENDLOOP.
        SORT gt_forms BY form_id.
        SORT gt_templates BY form_id version.
        SORT gt_base_forms BY form_id.
        SORT gt_base_templates BY form_id version.
        CLEAR gv_dirty.
        unlock_store( ).
        IF lv_task IS NOT INITIAL.
          SELECT SINGLE strkorr FROM e070 INTO gv_last_request WHERE trkorr = lv_task.
          IF gv_last_request IS INITIAL.
            gv_last_request = lv_task.
          ENDIF.
        ENDIF.
      CATCH cx_root INTO DATA(lx_store).
        ROLLBACK WORK.
        unlock_store( ).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING previous = lx_store message = lx_store->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD store_initialized.
    DATA lv_done TYPE abap_bool.
    TRY.
        IMPORT done = lv_done FROM DATABASE indx(zp) ID c_setup_id.
        rv_done = boolc( sy-subrc = 0 AND lv_done = abap_true ).
      CATCH cx_root.
        rv_done = abap_false.
    ENDTRY.
  ENDMETHOD.


  METHOD mark_initialized.
    DATA lv_done TYPE abap_bool VALUE abap_true.
    EXPORT done = lv_done TO DATABASE indx(zp) ID c_setup_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Could not save the form store setup marker'.
    ENDIF.
  ENDMETHOD.


  METHOD client_recording.
    SELECT SINGLE cccoractiv FROM t000 INTO rv_flag WHERE mandt = sy-mandt.
  ENDMETHOD.


  METHOD choose_request.
    DATA lv_flag TYPE dd02l-contflag.
    DATA lv_order TYPE trkorr.
    DATA lv_task TYPE trkorr.
    DATA lv_text TYPE string.

    SELECT SINGLE contflag FROM dd02l INTO lv_flag
      WHERE tabname = c_table AND as4local = 'A' AND as4vers = '0000'.
    IF lv_flag <> 'C' AND lv_flag <> 'G' AND lv_flag <> 'E'.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |Set the delivery class of { c_table } to C (customizing) in SE11 to transport forms.|.
    ENDIF.
    "SCC4 'no transports allowed' (TK432): customizing cannot go into a request in this client.
    IF client_recording( ) = '3'.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |This client does not allow transports (SCC4: changes without automatic recording, no transports allowed). | &&
                            |In SCC4 set client { sy-mandt } to "Automatic recording of changes" or "Changes without automatic recording", then try again.|.
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
      CATCH cx_sy_dyn_call_error INTO DATA(lx_call).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING previous = lx_call
                    message  = |Transport request could not be chosen: { lx_call->get_text( ) }|.
    ENDTRY.
    IF sy-subrc = 2.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = 'No transport request was chosen; nothing was saved or recorded.'.
    ELSEIF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_text.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |Transport request could not be chosen: { lv_text }|.
    ENDIF.
    rv_task = lv_task.
    IF rv_task IS INITIAL.
      rv_task = lv_order.
    ENDIF.
  ENDMETHOD.


  METHOD record_forms.
    "TABLES parameters of the transport API need standard tables with a default key.
    DATA lt_e071 TYPE STANDARD TABLE OF e071 WITH DEFAULT KEY.
    DATA lt_e071k TYPE STANDARD TABLE OF e071k WITH DEFAULT KEY.
    DATA ls_e071 TYPE e071.
    DATA ls_e071k TYPE e071k.
    DATA lv_id TYPE string.
    DATA lv_key TYPE c LENGTH 30.
    DATA lv_text TYPE string.

    ls_e071-trkorr = iv_task.
    ls_e071-pgmid = 'R3TR'.
    ls_e071-object = 'TABU'.
    ls_e071-obj_name = c_table.
    ls_e071-objfunc = 'K'.
    APPEND ls_e071 TO lt_e071.
    LOOP AT it_ids INTO lv_id.
      "Key: client + form ID + any version. A deleted form is transported as a deletion.
      lv_key = lv_id.
      CLEAR ls_e071k.
      ls_e071k-trkorr = iv_task.
      ls_e071k-pgmid = 'R3TR'.
      ls_e071k-object = 'TABU'.
      ls_e071k-objname = c_table.
      ls_e071k-mastertype = 'TABU'.
      ls_e071k-mastername = c_table.
      CONCATENATE sy-mandt lv_key '*' INTO ls_e071k-tabkey RESPECTING BLANKS.
      APPEND ls_e071k TO lt_e071k.
    ENDLOOP.
    TRY.
        CALL FUNCTION 'TR_APPEND_TO_COMM_OBJS_KEYS'
          EXPORTING
            wi_trkorr = iv_task
          TABLES
            wt_e071   = lt_e071
            wt_e071k  = lt_e071k
          EXCEPTIONS
            OTHERS    = 1.
      CATCH cx_sy_dyn_call_error INTO DATA(lx_call).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING previous = lx_call
                    message  = |Form could not be added to request { iv_task }: { lx_call->get_text( ) }|.
    ENDTRY.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_text.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |Form could not be added to request { iv_task }: { lv_text } (message { sy-msgid } { sy-msgno })|.
    ENDIF.
  ENDMETHOD.


  METHOD transport_form.
    DATA lv_id TYPE string.
    DATA lv_task TYPE trkorr.
    DATA lt_ids TYPE string_table.

    check_authority( 'ZPDFSEDT' ).
    load_store( ).
    IF table_ready( ) = abap_false.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |Forms are kept in INDX, which cannot be transported. Create table { c_table } (see the program header) and start the designer again.|.
    ENDIF.
    lv_id = normalize_id( iv_form_id ).
    READ TABLE gt_forms TRANSPORTING NO FIELDS WITH KEY form_id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |Form { lv_id } does not exist|.
    ENDIF.
    IF gv_dirty = abap_true.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Save the form before adding it to a transport request.'.
    ENDIF.
    lv_task = choose_request( ).
    APPEND lv_id TO lt_ids.
    record_forms( it_ids = lt_ids iv_task = lv_task ).
    COMMIT WORK.
    SELECT SINGLE strkorr FROM e070 INTO rv_request WHERE trkorr = lv_task.
    IF rv_request IS INITIAL.
      rv_request = lv_task.
    ENDIF.
  ENDMETHOD.


  METHOD form_requests.
    TYPES:
      BEGIN OF ty_hit,
        tabkey  TYPE e071k-tabkey,
        trkorr  TYPE e071k-trkorr,
        strkorr TYPE e070-strkorr,
      END OF ty_hit.
    DATA lt_hits TYPE STANDARD TABLE OF ty_hit WITH EMPTY KEY.
    DATA ls_hit TYPE ty_hit.
    DATA ls_request TYPE ty_form_request.
    DATA lv_key TYPE string.
    DATA lv_rest TYPE string.

    IF store_mode( ) <> 'TABLE'.
      RETURN.
    ENDIF.
    SELECT k~tabkey k~trkorr h~strkorr INTO TABLE lt_hits
      FROM e071k AS k INNER JOIN e070 AS h ON h~trkorr = k~trkorr
      WHERE k~pgmid = 'R3TR' AND k~object = 'TABU' AND k~objname = c_table
        AND ( h~trstatus = 'D' OR h~trstatus = 'L' ).
    LOOP AT lt_hits INTO ls_hit.
      IF ls_hit-tabkey(3) <> sy-mandt.
        CONTINUE.
      ENDIF.
      lv_key = ls_hit-tabkey+3.
      SPLIT lv_key AT '*' INTO lv_key lv_rest.
      CONDENSE lv_key.
      IF lv_key IS INITIAL.
        CONTINUE.
      ENDIF.
      ls_request-form_id = lv_key.
      ls_request-request = ls_hit-strkorr.
      IF ls_request-request IS INITIAL.
        ls_request-request = ls_hit-trkorr.
      ENDIF.
      READ TABLE rt_requests TRANSPORTING NO FIELDS WITH KEY form_id = ls_request-form_id request = ls_request-request.
      IF sy-subrc <> 0.
        APPEND ls_request TO rt_requests.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD last_request.
    rv_request = gv_last_request.
  ENDMETHOD.


  METHOD take_note.
    rv_note = gv_note.
    CLEAR gv_note.
  ENDMETHOD.


  METHOD check_authority.
    AUTHORITY-CHECK OBJECT 'S_PROGRAM'
      ID 'P_GROUP' FIELD iv_group
      ID 'P_ACTION' FIELD 'SUBMIT'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |Missing authorization: S_PROGRAM { iv_group } / SUBMIT|.
    ENDIF.
  ENDMETHOD.


  METHOD validate_page.
    IF is_page-page_size <> 'A3' AND is_page-page_size <> 'A4' AND
       is_page-page_size <> 'A5' AND is_page-page_size <> 'LETTER' AND
       is_page-page_size <> 'LEGAL'.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Unsupported page size'.
    ENDIF.
    IF is_page-orientation <> 'P' AND is_page-orientation <> 'L'.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Orientation must be P or L'.
    ENDIF.
    IF is_page-margin_top < 0 OR is_page-margin_top > 500 OR
       is_page-margin_right < 0 OR is_page-margin_right > 500 OR
       is_page-margin_bottom < 0 OR is_page-margin_bottom > 500 OR
       is_page-margin_left < 0 OR is_page-margin_left > 500.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Margins must be between 0 and 500 mm'.
    ENDIF.
    DATA lv_width TYPE decfloat34.
    DATA lv_height TYPE decfloat34.
    CASE is_page-page_size.
      WHEN 'A3'. lv_width = 297. lv_height = 420.
      WHEN 'A4'. lv_width = 210. lv_height = 297.
      WHEN 'A5'. lv_width = 148. lv_height = 210.
      WHEN 'LETTER'. lv_width = '215.9'. lv_height = '279.4'.
      WHEN 'LEGAL'. lv_width = '215.9'. lv_height = '355.6'.
    ENDCASE.
    IF is_page-orientation = 'L'.
      DATA(lv_swap) = lv_width.
      lv_width = lv_height.
      lv_height = lv_swap.
    ENDIF.
    IF is_page-margin_left + is_page-margin_right >= lv_width OR
       is_page-margin_top + is_page-margin_bottom >= lv_height.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Margins leave no printable page area'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
