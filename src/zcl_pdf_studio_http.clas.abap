"! <p>Online PDF service of ZPDF Studio (ICF handler, transaction SICF).</p>
"! <pre>
"! GET  /                       service information
"! GET  /forms                  forms as JSON
"! POST /render/ZMY_FORM        body: JSON data      -> application/pdf
"!      ?lang=TR  ?download=1  ?filename=invoice.pdf  ?title=...
"! POST /html                   body: {"html":"...","css":"...","page":{...},"data":{...}} -> PDF
"! </pre>
"! Authorization: S_PROGRAM ZPDFSVIW (render), ZPDFSEDT (/html with own markup).
"! Create the node in SICF (e.g. /sap/zpdf_studio) with this class as handler.
CLASS zcl_pdf_studio_http DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.

    "! JSON string literal (with quotes).
    CLASS-METHODS json_string
      IMPORTING
        iv_text        TYPE csequence
      RETURNING
        VALUE(rv_json) TYPE string.

  PRIVATE SECTION.
    DATA mo_server TYPE REF TO if_http_server.

    METHODS reply
      IMPORTING
        iv_status       TYPE i
        iv_content_type TYPE string
        iv_text         TYPE string OPTIONAL
        iv_data         TYPE xstring OPTIONAL.
    METHODS reply_error
      IMPORTING
        iv_status TYPE i
        iv_text   TYPE string.
    METHODS reply_pdf
      IMPORTING
        iv_pdf  TYPE xstring
        iv_name TYPE string.
    METHODS language
      RETURNING
        VALUE(rv_lang) TYPE sy-langu.
    METHODS forms_json
      RETURNING
        VALUE(rv_json) TYPE string
      RAISING
        zcx_pdf_studio.
    METHODS render_html_request
      IMPORTING
        iv_body       TYPE string
      RETURNING
        VALUE(rv_pdf) TYPE xstring
      RAISING
        zcx_pdf_studio.
    CLASS-METHODS check_authority
      IMPORTING
        iv_group TYPE csequence
      RAISING
        zcx_pdf_studio.
ENDCLASS.



CLASS zcl_pdf_studio_http IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    DATA lv_path TYPE string.
    DATA lv_method TYPE string.
    DATA lv_form TYPE string.
    DATA lv_body TYPE string.
    DATA lv_pdf TYPE xstring.
    DATA ls_info TYPE zcl_pdf_studio_renderer=>ty_info.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.
    DATA lx_root TYPE REF TO cx_root.

    mo_server = server.
    lv_path = server->request->get_header_field( '~path_info' ).
    lv_method = to_upper( server->request->get_method( ) ).
    SHIFT lv_path LEFT DELETING LEADING '/'.
    IF strlen( lv_path ) > 0 AND substring( val = lv_path off = strlen( lv_path ) - 1 ) = `/`.
      lv_path = substring( val = lv_path len = strlen( lv_path ) - 1 ).
    ENDIF.

    TRY.
        IF lv_path IS INITIAL AND lv_method = `GET`.
          reply( iv_status = 200 iv_content_type = `application/json`
                 iv_text = `{"service":"ZPDF Studio","endpoints":["GET /forms","POST /render/{form}","POST /html"]}` ).
        ELSEIF lv_path = `forms` AND lv_method = `GET`.
          check_authority( 'ZPDFSVIW' ).
          reply( iv_status = 200 iv_content_type = `application/json` iv_text = forms_json( ) ).
        ELSEIF lv_path CP 'render*' AND lv_method = `POST`.
          check_authority( 'ZPDFSVIW' ).
          lv_form = server->request->get_form_field( 'form' ).
          IF lv_path CP 'render/*'.
            lv_form = substring( val = lv_path off = 7 ).
          ENDIF.
          IF lv_form IS INITIAL.
            reply_error( iv_status = 400 iv_text = `Form name missing: POST /render/{form}` ).
            RETURN.
          ENDIF.
          lv_body = server->request->get_cdata( ).
          IF lv_body IS INITIAL.
            lv_body = `{}`.
          ENDIF.
          ls_info-title = server->request->get_form_field( 'title' ).
          lv_pdf = zcl_pdf_studio_api=>render_json(
            iv_form_id = to_upper( lv_form )
            iv_json    = lv_body
            iv_lang    = language( )
            is_info    = ls_info ).
          reply_pdf( iv_pdf = lv_pdf iv_name = |{ to_lower( lv_form ) }.pdf| ).
        ELSEIF lv_path = `html` AND lv_method = `POST`.
          check_authority( 'ZPDFSEDT' ).
          lv_pdf = render_html_request( server->request->get_cdata( ) ).
          reply_pdf( iv_pdf = lv_pdf iv_name = `document.pdf` ).
        ELSE.
          reply_error( iv_status = 404 iv_text = |Unknown request { lv_method } /{ lv_path }| ).
        ENDIF.
      CATCH zcx_pdf_studio INTO lx_pdf.
        IF lx_pdf->get_text( ) CS 'authorization'.
          reply_error( iv_status = 403 iv_text = lx_pdf->get_text( ) ).
        ELSE.
          reply_error( iv_status = 400 iv_text = lx_pdf->get_text( ) ).
        ENDIF.
      CATCH cx_root INTO lx_root.
        reply_error( iv_status = 500 iv_text = lx_root->get_text( ) ).
    ENDTRY.
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


  METHOD language.
    DATA lv_lang TYPE string.
    DATA lv_iso TYPE laiso.
    lv_lang = to_upper( mo_server->request->get_form_field( 'lang' ) ).
    rv_lang = sy-langu.
    IF strlen( lv_lang ) = 1.
      rv_lang = lv_lang.
    ELSEIF strlen( lv_lang ) = 2.
      lv_iso = lv_lang.
      CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
        EXPORTING
          input            = lv_iso
        IMPORTING
          output           = rv_lang
        EXCEPTIONS
          unknown_language = 1
          OTHERS           = 2.
      IF sy-subrc <> 0.
        rv_lang = sy-langu.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD forms_json.
    DATA lt_forms TYPE zcl_pdf_studio_repo=>ty_forms.
    DATA ls_form TYPE zcl_pdf_studio_repo=>ty_form.
    DATA lv_sep TYPE string.
    lt_forms = zcl_pdf_studio_repo=>list_forms( ).
    rv_json = `[`.
    LOOP AT lt_forms INTO ls_form.
      rv_json = |{ rv_json }{ lv_sep }\{"form":{ json_string( ls_form-form_id ) },| &&
                |"description":{ json_string( ls_form-description ) },"changed_by":{ json_string( ls_form-changed_by ) }\}|.
      lv_sep = `,`.
    ENDLOOP.
    rv_json = rv_json && `]`.
  ENDMETHOD.


  METHOD render_html_request.
    "Body: {"html":"...","css":"...","header":"...","footer":"...","page":{"page_size":"A4",...},"data":{...}}
    DATA lr_body TYPE REF TO data.
    DATA ls_page TYPE zcl_pdf_studio_renderer=>ty_page.
    DATA lv_html TYPE string.
    DATA lv_css TYPE string.
    DATA lv_header TYPE string.
    DATA lv_footer TYPE string.
    DATA lr_empty TYPE REF TO data.
    FIELD-SYMBOLS <body> TYPE any.
    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <page> TYPE any.
    FIELD-SYMBOLS <data> TYPE any.

    lr_body = zcl_pdf_studio_json=>to_data( iv_body ).
    ASSIGN lr_body->* TO <body>.
    ASSIGN COMPONENT 'HTML' OF STRUCTURE <body> TO <value>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Field "html" is missing'.
    ENDIF.
    lv_html = <value>.
    ASSIGN COMPONENT 'CSS' OF STRUCTURE <body> TO <value>.
    IF sy-subrc = 0.
      lv_css = <value>.
    ENDIF.
    ASSIGN COMPONENT 'HEADER' OF STRUCTURE <body> TO <value>.
    IF sy-subrc = 0.
      lv_header = <value>.
    ENDIF.
    ASSIGN COMPONENT 'FOOTER' OF STRUCTURE <body> TO <value>.
    IF sy-subrc = 0.
      lv_footer = <value>.
    ENDIF.
    ls_page = VALUE #( page_size = 'A4' orientation = 'P' margin_top = 15 margin_right = 15
                       margin_bottom = 15 margin_left = 15 ).
    ASSIGN COMPONENT 'PAGE' OF STRUCTURE <body> TO <page>.
    IF sy-subrc = 0.
      MOVE-CORRESPONDING <page> TO ls_page.
    ENDIF.
    ASSIGN COMPONENT 'DATA' OF STRUCTURE <body> TO <data>.
    IF sy-subrc <> 0.
      lr_empty = zcl_pdf_studio_json=>to_data( `{}` ).
      ASSIGN lr_empty->* TO <data>.
    ENDIF.
    rv_pdf = zcl_pdf_studio_api=>render_html(
      iv_html   = lv_html
      iv_css    = lv_css
      iv_header = lv_header
      iv_footer = lv_footer
      is_page   = ls_page
      is_data   = <data>
      iv_lang   = language( ) ).
  ENDMETHOD.


  METHOD reply.
    mo_server->response->set_status( code = iv_status reason = COND #( WHEN iv_status = 200 THEN `OK` ELSE `Error` ) ).
    mo_server->response->set_header_field( name = 'Content-Type' value = iv_content_type ).
    mo_server->response->set_header_field( name = 'Cache-Control' value = 'no-store' ).
    IF iv_data IS NOT INITIAL.
      mo_server->response->set_data( iv_data ).
    ELSE.
      mo_server->response->set_cdata( iv_text ).
    ENDIF.
  ENDMETHOD.


  METHOD reply_error.
    reply( iv_status = iv_status iv_content_type = `application/json; charset=utf-8`
           iv_text = |\{"error":{ json_string( iv_text ) }\}| ).
  ENDMETHOD.


  METHOD reply_pdf.
    DATA lv_name TYPE string.
    DATA lv_disposition TYPE string.
    lv_name = mo_server->request->get_form_field( 'filename' ).
    IF lv_name IS INITIAL.
      lv_name = iv_name.
    ENDIF.
    REPLACE ALL OCCURRENCES OF REGEX '[^A-Za-z0-9._-]' IN lv_name WITH '_'.
    lv_disposition = COND #( WHEN mo_server->request->get_form_field( 'download' ) IS NOT INITIAL
                             THEN `attachment` ELSE `inline` ).
    reply( iv_status = 200 iv_content_type = `application/pdf` iv_data = iv_pdf ).
    mo_server->response->set_header_field( name = 'Content-Disposition' value = |{ lv_disposition }; filename="{ lv_name }"| ).
  ENDMETHOD.


  METHOD json_string.
    DATA lv_text TYPE string.
    lv_text = iv_text.
    REPLACE ALL OCCURRENCES OF `\` IN lv_text WITH `\\`.
    REPLACE ALL OCCURRENCES OF `"` IN lv_text WITH `\"`.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_text WITH `\n`.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_text WITH `\n`.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_text WITH `\t`.
    REPLACE ALL OCCURRENCES OF `<` IN lv_text WITH `\u003c`.
    rv_json = |"{ lv_text }"|.
  ENDMETHOD.

ENDCLASS.
