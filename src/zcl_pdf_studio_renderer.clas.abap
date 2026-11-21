CLASS zcl_pdf_studio_renderer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_page,
        page_size     TYPE string,
        orientation   TYPE c LENGTH 1,
        margin_top    TYPE i,
        margin_right  TYPE i,
        margin_bottom TYPE i,
        margin_left   TYPE i,
      END OF ty_page,
      "Document properties written into the PDF.
      BEGIN OF ty_info,
        title    TYPE string,
        author   TYPE string,
        subject  TYPE string,
        keywords TYPE string,
      END OF ty_info.

    CLASS-METHODS validate_page
      IMPORTING is_page TYPE ty_page
      RAISING zcx_pdf_studio.

    METHODS render
      IMPORTING
        iv_html          TYPE string
        iv_css           TYPE string OPTIONAL
        iv_header        TYPE string OPTIONAL
        iv_footer        TYPE string OPTIONAL
        is_page          TYPE ty_page OPTIONAL
        io_resources     TYPE REF TO zif_pdf_studio_resources OPTIONAL
        is_info          TYPE ty_info OPTIONAL
      RETURNING
        VALUE(rv_pdf)    TYPE xstring
      RAISING
        zcx_pdf_studio.

    "Calls Gotenberg /health through the SM59 destination.
    CLASS-METHODS ping
      RAISING
        zcx_pdf_studio.

  PRIVATE SECTION.
    CONSTANTS c_path TYPE string VALUE '/forms/chromium/convert/html'.

    CLASS-METHODS endpoint
      IMPORTING
        iv_path        TYPE string
      RETURNING
        VALUE(rv_url)  TYPE string.

    CLASS-METHODS page_spec
      IMPORTING
        is_page          TYPE ty_page
      EXPORTING
        ev_width         TYPE string
        ev_height        TYPE string
        ev_page_css      TYPE string.

    CLASS-METHODS compose_document
      IMPORTING
        iv_html          TYPE string
        iv_css           TYPE string
        iv_page_css      TYPE string
      RETURNING
        VALUE(rv_html)   TYPE string.

    CLASS-METHODS compose_fragment
      IMPORTING
        iv_html          TYPE string
      RETURNING
        VALUE(rv_html)   TYPE string.

    CLASS-METHODS append_file
      IMPORTING
        iv_boundary TYPE string
        iv_filename TYPE string
        iv_content  TYPE string
      CHANGING
        cv_body     TYPE string.

    CLASS-METHODS append_field
      IMPORTING
        iv_boundary TYPE string
        iv_name     TYPE string
        iv_value    TYPE string
      CHANGING
        cv_body     TYPE string.

    CLASS-METHODS post
      IMPORTING
        iv_url          TYPE string
        iv_content_type TYPE string
        iv_body         TYPE xstring
        iv_timeout      TYPE i
        iv_accept_pdf   TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_body)  TYPE xstring
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS post_classic
      IMPORTING
        iv_url          TYPE string
        iv_content_type TYPE string
        iv_body         TYPE xstring
        iv_timeout      TYPE i
      RETURNING
        VALUE(rv_body)  TYPE xstring
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS post_cloud
      IMPORTING
        iv_url          TYPE string
        iv_content_type TYPE string
        iv_body         TYPE xstring
        iv_timeout      TYPE i
      RETURNING
        VALUE(rv_body)  TYPE xstring
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS contains_html
      IMPORTING
        iv_html          TYPE string
      RETURNING
        VALUE(rv_yes)    TYPE abap_bool.
ENDCLASS.



CLASS zcl_pdf_studio_renderer IMPLEMENTATION.

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

  METHOD render.
    DATA lv_width TYPE string.
    DATA lv_height TYPE string.
    DATA lv_page_css TYPE string.
    DATA lv_html TYPE string.
    DATA lv_header TYPE string.
    DATA lv_footer TYPE string.
    DATA lv_body TYPE string.
    DATA lv_boundary TYPE string.
    DATA lv_url TYPE string.
    DATA lv_timeout TYPE i.
    DATA lv_type TYPE string.
    DATA ls_page TYPE ty_page.
    DATA lv_body_html TYPE string.

    "The leading <!--abappdf...--> layout metadata is not sent to Gotenberg.
    lv_body_html = iv_html.
    IF strlen( lv_body_html ) > 11 AND lv_body_html(11) = '<!--abappdf'.
      DATA(lv_meta_end) = find( val = lv_body_html sub = '-->' ).
      IF lv_meta_end > 0.
        lv_body_html = substring( val = lv_body_html off = lv_meta_end + 3 ).
      ENDIF.
    ENDIF.

    ls_page = is_page.
    IF ls_page-page_size IS INITIAL.
      ls_page-page_size = 'A4'.
      IF ls_page-orientation IS INITIAL.
        ls_page-orientation = 'P'.
      ENDIF.
      IF ls_page-margin_top = 0 AND ls_page-margin_right = 0
          AND ls_page-margin_bottom = 0 AND ls_page-margin_left = 0.
        ls_page-margin_top = 12.
        ls_page-margin_right = 10.
        ls_page-margin_bottom = 16.
        ls_page-margin_left = 10.
      ENDIF.
    ENDIF.

    validate_page( ls_page ).
    "Native engine: the PDF is written in ABAP, no Gotenberg call.
    IF zcl_pdf_studio_repo=>get_config( 'ENGINE' ) = 'NATIVE'.
      rv_pdf = zcl_pdf_studio_engine=>render(
        iv_html   = iv_html
        iv_css    = iv_css
        iv_header = iv_header
        iv_footer = iv_footer
        is_page   = ls_page
        io_resources = io_resources
        is_info   = is_info ).
      RETURN.
    ENDIF.
    IF strlen( iv_html ) + strlen( iv_css ) + strlen( iv_header ) + strlen( iv_footer ) > 2000000.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Rendered HTML/CSS exceeds 2 million characters'.
    ENDIF.
    page_spec(
      EXPORTING
        is_page     = ls_page
      IMPORTING
        ev_width    = lv_width
        ev_height   = lv_height
        ev_page_css = lv_page_css ).

    "QR codes and barcodes become inline SVG for Chromium.
    lv_body_html = zcl_pdf_studio_codes=>expand_html( lv_body_html ).
    lv_html = compose_document(
      iv_html     = lv_body_html
      iv_css      = iv_css
      iv_page_css = lv_page_css ).

    lv_boundary = 'abappdfB7f3a9c2e1b04d88'.
    WHILE lv_html CS lv_boundary OR iv_header CS lv_boundary OR iv_footer CS lv_boundary.
      lv_boundary = lv_boundary && 'Z'.
    ENDWHILE.

    append_file(
      EXPORTING
        iv_boundary = lv_boundary
        iv_filename = 'index.html'
        iv_content  = lv_html
      CHANGING
        cv_body     = lv_body ).

    IF iv_header IS NOT INITIAL.
      lv_header = compose_fragment( iv_header ).
      append_file(
        EXPORTING
          iv_boundary = lv_boundary
          iv_filename = 'header.html'
          iv_content  = lv_header
        CHANGING
          cv_body     = lv_body ).
    ENDIF.

    IF iv_footer IS NOT INITIAL.
      lv_footer = compose_fragment( iv_footer ).
      append_file(
        EXPORTING
          iv_boundary = lv_boundary
          iv_filename = 'footer.html'
          iv_content  = lv_footer
        CHANGING
          cv_body     = lv_body ).
    ENDIF.

    append_field(
      EXPORTING iv_boundary = lv_boundary iv_name = 'paperWidth' iv_value = lv_width
      CHANGING cv_body = lv_body ).
    append_field(
      EXPORTING iv_boundary = lv_boundary iv_name = 'paperHeight' iv_value = lv_height
      CHANGING cv_body = lv_body ).
    append_field(
      EXPORTING iv_boundary = lv_boundary iv_name = 'marginTop'
                iv_value = |{ ls_page-margin_top }mm|
      CHANGING cv_body = lv_body ).
    append_field(
      EXPORTING iv_boundary = lv_boundary iv_name = 'marginBottom'
                iv_value = |{ ls_page-margin_bottom }mm|
      CHANGING cv_body = lv_body ).
    append_field(
      EXPORTING iv_boundary = lv_boundary iv_name = 'marginLeft'
                iv_value = |{ ls_page-margin_left }mm|
      CHANGING cv_body = lv_body ).
    append_field(
      EXPORTING iv_boundary = lv_boundary iv_name = 'marginRight'
                iv_value = |{ ls_page-margin_right }mm|
      CHANGING cv_body = lv_body ).
    append_field(
      EXPORTING iv_boundary = lv_boundary iv_name = 'landscape' iv_value = 'false'
      CHANGING cv_body = lv_body ).
    append_field(
      EXPORTING iv_boundary = lv_boundary iv_name = 'printBackground' iv_value = 'true'
      CHANGING cv_body = lv_body ).
    append_field(
      EXPORTING iv_boundary = lv_boundary iv_name = 'preferCssPageSize' iv_value = 'true'
      CHANGING cv_body = lv_body ).
    append_field(
      EXPORTING iv_boundary = lv_boundary iv_name = 'emulatedMediaType' iv_value = 'print'
      CHANGING cv_body = lv_body ).

    lv_body = lv_body && '--' && lv_boundary && '--' && cl_abap_char_utilities=>cr_lf.
    lv_type = 'multipart/form-data; boundary=' && lv_boundary.
    lv_url = endpoint( c_path ).

    lv_timeout = zcl_pdf_studio_repo=>get_config( 'HTTP_TIMEOUT' ).
    IF lv_timeout <= 0.
      lv_timeout = 60.
    ENDIF.

    rv_pdf = post(
      iv_url          = lv_url
      iv_content_type = lv_type
      iv_body         = zcl_pdf_studio_conv=>string_to_xstring( lv_body )
      iv_timeout      = lv_timeout ).
  ENDMETHOD.

  METHOD ping.
    DATA lv_timeout TYPE i VALUE 5.
    DATA lv_body TYPE xstring.
    lv_body = post(
      iv_url          = endpoint( '/health' )
      iv_content_type = 'text/plain'
      iv_body         = zcl_pdf_studio_conv=>string_to_xstring( '' )
      iv_timeout      = lv_timeout
      iv_accept_pdf   = abap_false ).
  ENDMETHOD.

  METHOD endpoint.
    DATA lv_base TYPE string.
    DATA lv_len TYPE i.
    DATA lv_suffix TYPE string.

    lv_base = zcl_pdf_studio_repo=>get_config( 'GOTENBERG_URL' ).
    SHIFT lv_base LEFT DELETING LEADING space.
    SHIFT lv_base RIGHT DELETING TRAILING space.
    IF lv_base IS INITIAL.
      lv_base = zcl_pdf_studio_repo=>gc_gotenberg_url.
    ENDIF.

    lv_suffix = c_path.
    lv_len = strlen( lv_base ) - strlen( lv_suffix ).
    IF lv_len > 0.
      IF substring( val = lv_base off = lv_len ) = lv_suffix.
        lv_base = substring( val = lv_base len = lv_len ).
      ENDIF.
    ENDIF.
    IF strlen( lv_base ) >= 7.
      IF substring( val = lv_base off = strlen( lv_base ) - 7 ) = '/health'.
        lv_base = substring( val = lv_base len = strlen( lv_base ) - 7 ).
      ENDIF.
    ENDIF.

    lv_len = strlen( lv_base ).
    IF lv_len > 0.
      IF substring( val = lv_base off = lv_len - 1 ) = '/'.
        lv_base = substring( val = lv_base len = lv_len - 1 ).
      ENDIF.
    ENDIF.
    rv_url = lv_base && iv_path.
  ENDMETHOD.

  METHOD page_spec.
    DATA lv_size TYPE string.
    DATA lv_css TYPE string.
    DATA lv_orient TYPE string.
    DATA lv_width TYPE string.
    DATA lv_height TYPE string.

    lv_size = to_upper( is_page-page_size ).
    CASE lv_size.
      WHEN 'A3'.
        lv_width = '297mm'.
        lv_height = '420mm'.
        lv_css = 'A3'.
      WHEN 'A5'.
        lv_width = '148mm'.
        lv_height = '210mm'.
        lv_css = 'A5'.
      WHEN 'LETTER'.
        lv_width = '8.5in'.
        lv_height = '11in'.
        lv_css = 'letter'.
      WHEN 'LEGAL'.
        lv_width = '8.5in'.
        lv_height = '14in'.
        lv_css = 'legal'.
      WHEN OTHERS.
        lv_width = '210mm'.
        lv_height = '297mm'.
        lv_css = 'A4'.
    ENDCASE.

    IF is_page-orientation = 'L'.
      DATA lv_swap TYPE string.
      lv_swap = lv_width.
      lv_width = lv_height.
      lv_height = lv_swap.
      lv_orient = 'landscape'.
    ELSE.
      lv_orient = 'portrait'.
    ENDIF.

    ev_width = lv_width.
    ev_height = lv_height.
    ev_page_css =
      |@page \{ size: { lv_css } { lv_orient }; margin: { is_page-margin_top }mm | &&
      |{ is_page-margin_right }mm { is_page-margin_bottom }mm { is_page-margin_left }mm; \}| &&
      cl_abap_char_utilities=>newline &&
      |html, body \{ margin: 0; padding: 0; \}| &&
      cl_abap_char_utilities=>newline &&
      "A table's top margin must not collapse through body, or it shifts the
      "absolutely positioned designer objects down with it.
      |body \{ display: flow-root; \}|.
  ENDMETHOD.

  METHOD compose_document.
    DATA lv_style TYPE string.
    DATA lv_upper TYPE string.
    DATA lv_pos TYPE i.

    lv_style = '<style>' && iv_page_css && cl_abap_char_utilities=>newline &&
      iv_css && '</style>'.

    IF contains_html( iv_html ) = abap_false.
      rv_html = '<!DOCTYPE html><html><head><meta charset="utf-8">' &&
        lv_style && '</head><body>' && iv_html && '</body></html>'.
      RETURN.
    ENDIF.

    lv_upper = to_upper( iv_html ).
    lv_pos = find( val = lv_upper sub = '</HEAD>' ).
    IF lv_pos >= 0.
      rv_html = substring( val = iv_html len = lv_pos ) &&
        lv_style &&
        substring( val = iv_html off = lv_pos ).
      RETURN.
    ENDIF.

    rv_html = lv_style && iv_html.
  ENDMETHOD.

  METHOD compose_fragment.
    IF contains_html( iv_html ) = abap_true.
      rv_html = iv_html.
      RETURN.
    ENDIF.
    rv_html = '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' &&
      'body{margin:0;padding:0;font-family:sans-serif;font-size:9pt;}' &&
      '</style></head><body>' && iv_html && '</body></html>'.
  ENDMETHOD.

  METHOD contains_html.
    rv_yes = xsdbool( to_upper( iv_html ) CS '<HTML' ).
  ENDMETHOD.

  METHOD append_file.
    DATA lv_crlf TYPE string.
    lv_crlf = cl_abap_char_utilities=>cr_lf.
    cv_body = cv_body && '--' && iv_boundary && lv_crlf &&
      'Content-Disposition: form-data; name="files"; filename="' &&
      iv_filename && '"' && lv_crlf &&
      'Content-Type: text/html; charset=utf-8' && lv_crlf && lv_crlf &&
      iv_content && lv_crlf.
  ENDMETHOD.

  METHOD append_field.
    DATA lv_crlf TYPE string.
    lv_crlf = cl_abap_char_utilities=>cr_lf.
    cv_body = cv_body && '--' && iv_boundary && lv_crlf &&
      'Content-Disposition: form-data; name="' && iv_name && '"' &&
      lv_crlf && lv_crlf && iv_value && lv_crlf.
  ENDMETHOD.

  METHOD post.
    rv_body = post_classic(
      iv_url = iv_url iv_content_type = iv_content_type
      iv_body = iv_body iv_timeout = iv_timeout ).

    IF iv_accept_pdf = abap_true.
      IF xstrlen( rv_body ) < 5.
        RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Gotenberg returned an empty PDF'.
      ENDIF.
      IF rv_body(5) <> '255044462D'.
        RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Response is not a PDF (%PDF- signature missing)'.
      ENDIF.
      IF xstrlen( rv_body ) > 50000000.
        RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'PDF exceeds the 50 MB application limit'.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD post_classic.
    DATA lo_client TYPE REF TO if_http_client.
    DATA lv_code TYPE i.
    DATA lv_reason TYPE string.
    DATA lv_error TYPE string.
    DATA lv_path TYPE string.
    DATA lv_text TYPE string.

    TRY.
        "Recheck at the network boundary; never use a user-supplied destination.
        IF iv_url = |dest://{ zcl_pdf_studio_repo=>gc_gotenberg_dest }{ c_path }|.
          lv_path = c_path.
        ELSEIF iv_url = |dest://{ zcl_pdf_studio_repo=>gc_gotenberg_dest }/health|.
          lv_path = '/health'.
        ELSE.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING message = 'Unapproved rendering endpoint'.
        ENDIF.
        cl_http_client=>create_by_destination(
          EXPORTING destination = zcl_pdf_studio_repo=>gc_gotenberg_dest
          IMPORTING client = lo_client
          EXCEPTIONS argument_not_found = 1 destination_not_found = 2
                     internal_error = 3 plugin_not_active = 4 OTHERS = 5 ).
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING message = |Configure SM59 destination { zcl_pdf_studio_repo=>gc_gotenberg_dest } before rendering|.
        ENDIF.
        lo_client->propertytype_redirect = if_http_client=>co_disabled.
        lo_client->propertytype_logon_popup = if_http_client=>co_disabled.
        cl_http_utility=>set_request_uri( request = lo_client->request uri = lv_path ).
        lo_client->request->set_method( 'GET' ).
        IF iv_body IS NOT INITIAL.
          lo_client->request->set_method( 'POST' ).
        ENDIF.

        lo_client->request->set_header_field(
          name  = 'User-Agent'
          value = 'abapPDF' ).
        IF iv_body IS NOT INITIAL.
          lo_client->request->set_data( iv_body ).
          lo_client->request->set_content_type( iv_content_type ).
        ENDIF.

        lo_client->send(
          EXPORTING
            timeout = iv_timeout
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state = 2
            http_processing_failed = 3
            http_invalid_timeout = 4
            OTHERS = 5 ).
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING
              message = |HTTP send to Gotenberg failed ({ sy-subrc })|.
        ENDIF.

        lo_client->receive(
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state = 2
            http_processing_failed = 3
            OTHERS = 4 ).
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING
              message = |HTTP receive from Gotenberg failed ({ sy-subrc })|.
        ENDIF.

        lo_client->response->get_status(
          IMPORTING
            code   = lv_code
            reason = lv_reason ).
        IF lv_code < 200 OR lv_code >= 300.
          lv_error = lo_client->response->get_cdata( ).
          IF strlen( lv_error ) > 500.
            lv_error = substring( val = lv_error len = 500 ).
          ENDIF.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING
              message = |Gotenberg HTTP { lv_code } { lv_reason }: { lv_error }|.
        ENDIF.

        IF iv_body IS NOT INITIAL.
          DATA(lv_mime) = to_lower( lo_client->response->get_header_field( 'content-type' ) ).
          SPLIT lv_mime AT ';' INTO lv_mime lv_text.
          CONDENSE lv_mime.
          IF lv_mime <> 'application/pdf'.
            RAISE EXCEPTION TYPE zcx_pdf_studio
              EXPORTING message = |Expected application/pdf, received { lv_mime }|.
          ENDIF.
        ENDIF.
        rv_body = lo_client->response->get_data( ).
        lo_client->close( ).
        FREE lo_client.

      CLEANUP.
        IF lo_client IS BOUND.
          lo_client->close( ).
        ENDIF.
    ENDTRY.
  ENDMETHOD.

  METHOD post_cloud.
    DATA lv_pdf TYPE xstring.
    TRY.
        CALL METHOD ('ZCL_PDF_HTTP_CLOUD')=>post
          EXPORTING
            iv_url          = iv_url
            iv_content_type = iv_content_type
            iv_body         = iv_body
            iv_timeout      = iv_timeout
          RECEIVING
            rv_body         = lv_pdf.
        rv_body = lv_pdf.
      CATCH cx_root INTO DATA(lx_error).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING
            previous = lx_error
            message  = |Cloud HTTP stack failed. Activate cloud/zcl_pdf_http_cloud.clas.abap and set HTTP_STACK = CLOUD. { lx_error->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
