CLASS zcl_pdf_studio_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_recipients TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_param,
        name  TYPE string,
        value TYPE REF TO data,
      END OF ty_param,
      ty_params TYPE STANDARD TABLE OF ty_param WITH EMPTY KEY.

    "! Renders a stored form with ABAP data (any structure; fields, tables, nested structures).
    "! A form whose interface has exactly one parameter also accepts the value of that parameter.
    "! @parameter iv_lang | Language of month names, amounts in words, upper case
    "! @parameter is_info | PDF document properties (title, author, ...)
    "! @parameter io_resources | Fonts and images; default: asset store ZPDF_STUDIO_ASST
    CLASS-METHODS render_pdf
      IMPORTING
        iv_form_id          TYPE csequence
        is_data             TYPE any
        iv_lang             TYPE sy-langu DEFAULT sy-langu
        is_info             TYPE zcl_pdf_studio_renderer=>ty_info OPTIONAL
        io_resources        TYPE REF TO zif_pdf_studio_resources OPTIONAL
      RETURNING
        VALUE(rv_pdf_xstring) TYPE xstring
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS render_html
      IMPORTING
        iv_html             TYPE string
        iv_css              TYPE string OPTIONAL
        iv_header           TYPE string OPTIONAL
        iv_footer           TYPE string OPTIONAL
        is_page             TYPE zcl_pdf_studio_renderer=>ty_page OPTIONAL
        is_data             TYPE any
        iv_lang             TYPE sy-langu DEFAULT sy-langu
        is_info             TYPE zcl_pdf_studio_renderer=>ty_info OPTIONAL
        io_resources        TYPE REF TO zif_pdf_studio_resources OPTIONAL
      RETURNING
        VALUE(rv_pdf_xstring) TYPE xstring
      RAISING
        zcx_pdf_studio.

    "! Renders a stored form with JSON data, e.g. {"CUSTOMER":"ACME","ITEMS":[{"NAME":"A","AMOUNT":"1.5"}]}.
    "! Objects become structures, arrays become tables (field names upper case).
    CLASS-METHODS render_json
      IMPORTING
        iv_form_id            TYPE csequence
        iv_json               TYPE string
        iv_lang               TYPE sy-langu DEFAULT sy-langu
        is_info               TYPE zcl_pdf_studio_renderer=>ty_info OPTIONAL
      RETURNING
        VALUE(rv_pdf_xstring) TYPE xstring
      RAISING
        zcx_pdf_studio.

    "! Sends a PDF as e-mail attachment (SAPconnect / BCS).
    CLASS-METHODS send_mail
      IMPORTING
        iv_pdf_xstring TYPE xstring
        it_recipients  TYPE ty_recipients
        iv_subject     TYPE csequence
        iv_body        TYPE string OPTIONAL
        iv_filename    TYPE csequence DEFAULT 'document.pdf'
        iv_immediately TYPE abap_bool DEFAULT abap_true
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS download_pdf
      IMPORTING
        iv_pdf_xstring TYPE xstring
        iv_filename    TYPE string DEFAULT 'document.pdf'
        iv_open        TYPE abap_bool DEFAULT abap_true
        iv_dialog      TYPE abap_bool DEFAULT abap_true
      EXPORTING
        ev_fullpath    TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS expand_layout
      IMPORTING
        is_template        TYPE zcl_pdf_studio_repo=>ty_template
      RETURNING
        VALUE(rs_template) TYPE zcl_pdf_studio_repo=>ty_template.
    "! Interface of a stored form as the designer wrote it: "INPUT=ZPDF_S_INPUT;ITEMS=ZPDF_TT_ITEMS".
    CLASS-METHODS interface_of
      IMPORTING
        iv_html        TYPE string
      RETURNING
        VALUE(rv_spec) TYPE string.
    "! Prints a form whose interface has one or more parameters (like the function module of an
    "! SFP form). Every parameter is passed by its interface name:
    "! it_params = VALUE #( ( name = 'INPUT' value = REF #( ls_input ) ) ).
    "! Interface parameters that are not passed stay initial.
    CLASS-METHODS render_form
      IMPORTING
        iv_form_id            TYPE csequence
        it_params             TYPE ty_params
        iv_lang               TYPE sy-langu DEFAULT sy-langu
        is_info               TYPE zcl_pdf_studio_renderer=>ty_info OPTIONAL
        io_resources          TYPE REF TO zif_pdf_studio_resources OPTIONAL
      RETURNING
        VALUE(rv_pdf_xstring) TYPE xstring
      RAISING
        zcx_pdf_studio.

  PRIVATE SECTION.
    CONSTANTS c_iface_mark TYPE string VALUE '<!--zpdf-iface:'.

    CLASS-METHODS is_form_xml
      IMPORTING
        iv_xml         TYPE string
      RETURNING
        VALUE(rv_yes)  TYPE abap_bool.

    CLASS-METHODS xml_tag
      IMPORTING
        iv_xml         TYPE string
        iv_tag         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS xml_attr
      IMPORTING
        iv_page        TYPE string
        iv_name        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    CLASS-METHODS xml_int
      IMPORTING
        iv_text      TYPE string
      RETURNING
        VALUE(rv_int) TYPE i.
    "! A form with exactly one interface parameter also accepts the value of that parameter
    "! itself as is_data: it is wrapped into a structure with the parameter name.
    CLASS-METHODS wrap_data
      IMPORTING
        iv_html        TYPE string
        is_data        TYPE any
      RETURNING
        VALUE(rr_data) TYPE REF TO data.
ENDCLASS.



CLASS zcl_pdf_studio_api IMPLEMENTATION.

  METHOD render_pdf.
    DATA lv_form_id TYPE string.
    DATA ls_template TYPE zcl_pdf_studio_repo=>ty_template.
    DATA ls_page TYPE zcl_pdf_studio_renderer=>ty_page.
    DATA lr_wrapped TYPE REF TO data.
    FIELD-SYMBOLS <data> TYPE any.

    lv_form_id = iv_form_id.
    CONDENSE lv_form_id.
    IF lv_form_id IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = 'Form ID is empty'.
    ENDIF.

    "Page size, orientation and margins are taken from the saved form.
    ls_template = zcl_pdf_studio_repo=>read_active_template( to_upper( lv_form_id ) ).
    ls_page-page_size = ls_template-page_size.
    ls_page-orientation = ls_template-orientation.
    ls_page-margin_top = ls_template-margin_top.
    ls_page-margin_right = ls_template-margin_right.
    ls_page-margin_bottom = ls_template-margin_bottom.
    ls_page-margin_left = ls_template-margin_left.

    lr_wrapped = wrap_data( iv_html = ls_template-html_content is_data = is_data ).
    IF lr_wrapped IS BOUND.
      ASSIGN lr_wrapped->* TO <data>.
    ELSE.
      ASSIGN is_data TO <data>.
    ENDIF.

    rv_pdf_xstring = render_html(
      iv_html      = ls_template-html_content
      iv_css       = ls_template-css_content
      iv_header    = ls_template-header_html
      iv_footer    = ls_template-footer_html
      is_page      = ls_page
      is_data      = <data>
      iv_lang      = iv_lang
      is_info      = is_info
      io_resources = io_resources ).
  ENDMETHOD.


  METHOD render_json.
    DATA lr_data TYPE REF TO data.
    FIELD-SYMBOLS <data> TYPE any.
    lr_data = zcl_pdf_studio_json=>to_data( iv_json ).
    ASSIGN lr_data->* TO <data>.
    rv_pdf_xstring = render_pdf(
      iv_form_id = iv_form_id
      is_data    = <data>
      iv_lang    = iv_lang
      is_info    = is_info ).
  ENDMETHOD.


  METHOD send_mail.
    DATA lt_text TYPE bcsy_text.
    DATA lt_lines TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_line TYPE string.
    DATA lv_to TYPE string.
    DATA lo_doc TYPE REF TO cl_document_bcs.
    DATA lo_send TYPE REF TO cl_bcs.
    DATA lv_address TYPE adr6-smtp_addr.
    DATA lx_bcs TYPE REF TO cx_root.

    IF iv_pdf_xstring IS INITIAL OR it_recipients IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'PDF and at least one recipient are needed'.
    ENDIF.
    SPLIT iv_body AT cl_abap_char_utilities=>newline INTO TABLE lt_lines.
    LOOP AT lt_lines INTO lv_line.
      APPEND VALUE #( line = lv_line ) TO lt_text.
    ENDLOOP.
    TRY.
        lo_doc = cl_document_bcs=>create_document(
          i_type    = 'RAW'
          i_text    = lt_text
          i_subject = CONV so_obj_des( iv_subject ) ).
        lo_doc->add_attachment(
          i_attachment_type    = 'PDF'
          i_attachment_subject = CONV so_obj_des( iv_filename )
          i_attachment_size    = CONV so_obj_len( xstrlen( iv_pdf_xstring ) )
          i_att_content_hex    = cl_bcs_convert=>xstring_to_solix( iv_pdf_xstring ) ).
        lo_send = cl_bcs=>create_persistent( ).
        lo_send->set_document( lo_doc ).
        LOOP AT it_recipients INTO lv_to.
          lv_address = lv_to.
          lo_send->add_recipient( cl_cam_address_bcs=>create_internet_address( lv_address ) ).
        ENDLOOP.
        lo_send->set_send_immediately( iv_immediately ).
        lo_send->send( ).
        COMMIT WORK.
      CATCH cx_root INTO lx_bcs.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING previous = lx_bcs
                    message  = |E-mail could not be sent: { lx_bcs->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.


  METHOD render_html.
    "Bind the data into each part, then render (native engine unless ENGINE = GOTENBERG).
    DATA lo_renderer TYPE REF TO zcl_pdf_studio_renderer.
    DATA lo_resources TYPE REF TO zif_pdf_studio_resources.

    lo_resources = io_resources.
    IF lo_resources IS NOT BOUND.
      lo_resources = NEW zcl_pdf_studio_assets( ).
    ENDIF.
    CREATE OBJECT lo_renderer.
    rv_pdf_xstring = lo_renderer->render(
      iv_html      = zcl_pdf_studio_binder=>render( iv_template = iv_html   is_data = is_data iv_lang = iv_lang )
      iv_css       = zcl_pdf_studio_binder=>render( iv_template = iv_css    is_data = is_data iv_lang = iv_lang )
      iv_header    = zcl_pdf_studio_binder=>render( iv_template = iv_header is_data = is_data iv_lang = iv_lang )
      iv_footer    = zcl_pdf_studio_binder=>render( iv_template = iv_footer is_data = is_data iv_lang = iv_lang )
      is_page      = is_page
      io_resources = lo_resources
      is_info      = is_info ).
  ENDMETHOD.


  METHOD download_pdf.
    DATA lv_file TYPE string.
    DATA lv_path TYPE string.
    DATA lv_full TYPE string.
    DATA lv_action TYPE i.
    DATA lv_len TYPE i.
    DATA lv_off TYPE i.
    DATA lv_chunk TYPE i.
    TYPES ty_raw TYPE x LENGTH 255.
    DATA lt_bin TYPE STANDARD TABLE OF ty_raw WITH EMPTY KEY.

    IF iv_pdf_xstring IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = 'PDF payload is empty'.
    ENDIF.

    IF iv_dialog = abap_false.
      cl_gui_frontend_services=>get_desktop_directory(
        CHANGING
          desktop_directory = lv_path
        EXCEPTIONS
          OTHERS            = 1 ).
      IF lv_path IS INITIAL.
        cl_gui_frontend_services=>get_temp_directory(
          CHANGING
            temp_dir = lv_path
          EXCEPTIONS
            OTHERS   = 1 ).
      ENDIF.
      IF lv_path IS INITIAL.
        lv_path = 'C:\Temp\'.
      ENDIF.
      lv_len = strlen( lv_path ) - 1.
      IF lv_path+lv_len(1) <> '\' AND lv_path+lv_len(1) <> '/'.
        lv_path = lv_path && '\'.
      ENDIF.
      lv_full = lv_path && iv_filename.
    ELSE.
      cl_gui_frontend_services=>file_save_dialog(
        EXPORTING
          window_title         = 'Save PDF'
          default_extension    = 'pdf'
          default_file_name    = iv_filename
          file_filter          = 'PDF (*.pdf)|*.pdf'
        CHANGING
          filename             = lv_file
          path                 = lv_path
          fullpath             = lv_full
          user_action          = lv_action
        EXCEPTIONS
          cntl_error           = 1
          error_no_gui         = 2
          not_supported_by_gui = 3
          OTHERS               = 4 ).
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING
            message = 'Save dialog failed'.
      ENDIF.
      IF lv_action <> cl_gui_frontend_services=>action_ok OR lv_full IS INITIAL.
        RETURN.
      ENDIF.
    ENDIF.

    lv_len = xstrlen( iv_pdf_xstring ).
    WHILE lv_off < lv_len.
      lv_chunk = lv_len - lv_off.
      IF lv_chunk > 255.
        lv_chunk = 255.
      ENDIF.
      APPEND iv_pdf_xstring+lv_off(lv_chunk) TO lt_bin.
      lv_off = lv_off + lv_chunk.
    ENDWHILE.

    cl_gui_frontend_services=>gui_download(
      EXPORTING
        bin_filesize     = lv_len
        filename         = lv_full
        filetype         = 'BIN'
      CHANGING
        data_tab         = lt_bin
      EXCEPTIONS
        file_write_error = 1
        no_batch         = 2
        gui_refuse_filetransfer = 3
        invalid_type     = 4
        no_authority     = 5
        unknown_error    = 6
        OTHERS           = 7 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = |Could not write { lv_full }|.
    ENDIF.

    IF iv_open = abap_true.
      cl_gui_frontend_services=>execute(
        EXPORTING
          document = lv_full
        EXCEPTIONS
          OTHERS   = 1 ).
    ENDIF.
    ev_fullpath = lv_full.
  ENDMETHOD.


  METHOD expand_layout.
    DATA lv_xml TYPE string.
    DATA lv_page TYPE string.
    DATA lv_start TYPE i.
    DATA lv_end TYPE i.
    DATA lv_rest TYPE string.

    rs_template = is_template.
    lv_xml = is_template-html_content.
    IF is_form_xml( lv_xml ) = abap_false.
      RETURN.
    ENDIF.

    rs_template-html_content = xml_tag( iv_xml = lv_xml iv_tag = 'body' ).
    rs_template-css_content = xml_tag( iv_xml = lv_xml iv_tag = 'style' ).
    rs_template-header_html = xml_tag( iv_xml = lv_xml iv_tag = 'header' ).
    rs_template-footer_html = xml_tag( iv_xml = lv_xml iv_tag = 'footer' ).
    rs_template-sample_json = xml_tag( iv_xml = lv_xml iv_tag = 'sample' ).

    FIND '<page' IN lv_xml MATCH OFFSET lv_start.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lv_rest = substring( val = lv_xml off = lv_start ).
    FIND '>' IN lv_rest MATCH OFFSET lv_end.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lv_page = substring( val = lv_rest len = lv_end ).
    rs_template-page_size = xml_attr( iv_page = lv_page iv_name = 'size' ).
    rs_template-orientation = xml_attr( iv_page = lv_page iv_name = 'orientation' ).
    rs_template-margin_top = xml_int( xml_attr( iv_page = lv_page iv_name = 'top' ) ).
    rs_template-margin_right = xml_int( xml_attr( iv_page = lv_page iv_name = 'right' ) ).
    rs_template-margin_bottom = xml_int( xml_attr( iv_page = lv_page iv_name = 'bottom' ) ).
    rs_template-margin_left = xml_int( xml_attr( iv_page = lv_page iv_name = 'left' ) ).
  ENDMETHOD.


  METHOD is_form_xml.
    DATA lv_text TYPE string.
    lv_text = iv_xml.
    SHIFT lv_text LEFT DELETING LEADING space.
    IF strlen( lv_text ) >= 5 AND substring( val = lv_text len = 5 ) = '<?xml'.
      rv_yes = abap_true.
      RETURN.
    ENDIF.
    IF strlen( lv_text ) >= 8 AND substring( val = lv_text len = 8 ) = '<abappdf'.
      rv_yes = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD xml_tag.
    DATA lv_open TYPE string.
    DATA lv_close TYPE string.
    DATA lv_rest TYPE string.
    DATA lv_start TYPE i.
    DATA lv_end TYPE i.

    lv_open = '<' && iv_tag && '>'.
    lv_close = '</' && iv_tag && '>'.
    FIND lv_open IN iv_xml MATCH OFFSET lv_start.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lv_start = lv_start + strlen( lv_open ).
    lv_rest = substring( val = iv_xml off = lv_start ).
    FIND lv_close IN lv_rest MATCH OFFSET lv_end.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    rv_text = substring( val = lv_rest len = lv_end ).
    IF strlen( rv_text ) >= 9 AND substring( val = rv_text len = 9 ) = '<![CDATA['.
      rv_text = substring( val = rv_text off = 9 ).
    ENDIF.
    lv_end = strlen( rv_text ).
    IF lv_end >= 3.
      lv_start = lv_end - 3.
      IF substring( val = rv_text off = lv_start len = 3 ) = ']]>'.
        rv_text = substring( val = rv_text len = lv_start ).
      ENDIF.
    ENDIF.
    REPLACE ALL OCCURRENCES OF ']]]]><![CDATA[>' IN rv_text WITH ']]>'.
  ENDMETHOD.


  METHOD xml_attr.
    DATA lv_key TYPE string.
    DATA lv_rest TYPE string.
    DATA lv_start TYPE i.
    DATA lv_end TYPE i.

    lv_key = iv_name && '="'.
    FIND lv_key IN iv_page MATCH OFFSET lv_start.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lv_start = lv_start + strlen( lv_key ).
    lv_rest = substring( val = iv_page off = lv_start ).
    FIND '"' IN lv_rest MATCH OFFSET lv_end.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    rv_value = substring( val = lv_rest len = lv_end ).
    CONDENSE rv_value.
  ENDMETHOD.


  METHOD xml_int.
    DATA lv_text TYPE string.
    lv_text = iv_text.
    CONDENSE lv_text NO-GAPS.
    IF lv_text IS NOT INITIAL AND lv_text CO '0123456789'.
      rv_int = lv_text.
    ENDIF.
  ENDMETHOD.

  METHOD interface_of.
    DATA lv_start TYPE i.
    DATA lv_end TYPE i.

    lv_start = find( val = iv_html sub = c_iface_mark ).
    IF lv_start < 0.
      RETURN.
    ENDIF.
    lv_start = lv_start + strlen( c_iface_mark ).
    lv_end = find( val = iv_html sub = `-->` off = lv_start ).
    IF lv_end <= lv_start.
      RETURN.
    ENDIF.
    rv_spec = to_upper( substring( val = iv_html off = lv_start len = lv_end - lv_start ) ).
  ENDMETHOD.

  METHOD render_form.
    DATA lv_form_id TYPE string.
    DATA ls_template TYPE zcl_pdf_studio_repo=>ty_template.
    DATA ls_page TYPE zcl_pdf_studio_renderer=>ty_page.
    DATA lt_comp TYPE cl_abap_structdescr=>component_table.
    DATA ls_comp TYPE cl_abap_structdescr=>component.
    DATA ls_param TYPE ty_param.
    DATA lt_spec TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_spec TYPE string.
    DATA lv_name TYPE string.
    DATA lv_type TYPE string.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lr_data TYPE REF TO data.
    DATA lx_create TYPE REF TO cx_root.
    FIELD-SYMBOLS <data> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.
    FIELD-SYMBOLS <value> TYPE any.

    lv_form_id = iv_form_id.
    CONDENSE lv_form_id.
    IF lv_form_id IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = 'Form ID is empty'.
    ENDIF.
    ls_template = zcl_pdf_studio_repo=>read_active_template( to_upper( lv_form_id ) ).
    ls_page-page_size = ls_template-page_size.
    ls_page-orientation = ls_template-orientation.
    ls_page-margin_top = ls_template-margin_top.
    ls_page-margin_right = ls_template-margin_right.
    ls_page-margin_bottom = ls_template-margin_bottom.
    ls_page-margin_left = ls_template-margin_left.

    "One structure whose components are the parameters: the binder addresses INPUT.FIELD.
    LOOP AT it_params INTO ls_param.
      IF ls_param-value IS NOT BOUND OR ls_param-name IS INITIAL.
        CONTINUE.
      ENDIF.
      ls_comp-name = to_upper( ls_param-name ).
      TRY.
          ls_comp-type ?= cl_abap_typedescr=>describe_by_data_ref( ls_param-value ).
          APPEND ls_comp TO lt_comp.
        CATCH cx_sy_move_cast_error.
          CONTINUE.
      ENDTRY.
    ENDLOOP.
    "Parameters of the interface that the caller did not pass are printed empty.
    SPLIT interface_of( ls_template-html_content ) AT ';' INTO TABLE lt_spec.
    LOOP AT lt_spec INTO lv_spec.
      CLEAR: lv_name, lv_type.
      SPLIT lv_spec AT '=' INTO lv_name lv_type.
      IF lv_name IS INITIAL OR lv_type IS INITIAL.
        CONTINUE.
      ENDIF.
      READ TABLE lt_comp TRANSPORTING NO FIELDS WITH KEY name = lv_name.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.
      cl_abap_typedescr=>describe_by_name(
        EXPORTING
          p_name         = lv_type
        RECEIVING
          p_descr_ref    = lo_type
        EXCEPTIONS
          type_not_found = 1
          OTHERS         = 2 ).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      TRY.
          ls_comp-name = lv_name.
          ls_comp-type ?= lo_type.
          APPEND ls_comp TO lt_comp.
        CATCH cx_sy_move_cast_error.
          CONTINUE.
      ENDTRY.
    ENDLOOP.
    IF lt_comp IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = |Form { lv_form_id }: no parameters were passed|.
    ENDIF.
    TRY.
        lo_struct = cl_abap_structdescr=>create( lt_comp ).
        CREATE DATA lr_data TYPE HANDLE lo_struct.
      CATCH cx_root INTO lx_create.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING
            message = |Form { lv_form_id }: parameters are not valid ({ lx_create->get_text( ) })|.
    ENDTRY.
    ASSIGN lr_data->* TO <data>.
    LOOP AT it_params INTO ls_param.
      IF ls_param-value IS NOT BOUND OR ls_param-name IS INITIAL.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT to_upper( ls_param-name ) OF STRUCTURE <data> TO <comp>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      ASSIGN ls_param-value->* TO <value>.
      <comp> = <value>.
    ENDLOOP.

    rv_pdf_xstring = render_html(
      iv_html      = ls_template-html_content
      iv_css       = ls_template-css_content
      iv_header    = ls_template-header_html
      iv_footer    = ls_template-footer_html
      is_page      = ls_page
      is_data      = <data>
      iv_lang      = iv_lang
      is_info      = is_info
      io_resources = io_resources ).
  ENDMETHOD.

  METHOD wrap_data.
    DATA lv_spec TYPE string.
    DATA lv_name TYPE string.
    DATA lv_type TYPE string.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lt_comp TYPE cl_abap_structdescr=>component_table.
    DATA ls_comp TYPE cl_abap_structdescr=>component.
    FIELD-SYMBOLS <wrap> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.

    CLEAR rr_data.
    lv_spec = interface_of( iv_html ).
    IF lv_spec IS INITIAL OR lv_spec CS ';'.
      RETURN.
    ENDIF.
    SPLIT lv_spec AT '=' INTO lv_name lv_type.
    IF lv_name IS INITIAL.
      RETURN.
    ENDIF.
    lo_type = cl_abap_typedescr=>describe_by_data( is_data ).
    IF lo_type->kind = cl_abap_typedescr=>kind_struct.
      ASSIGN COMPONENT lv_name OF STRUCTURE is_data TO <comp>.
      IF sy-subrc = 0.
        "The caller already passes a structure that holds the parameter.
        RETURN.
      ENDIF.
    ENDIF.
    TRY.
        ls_comp-name = lv_name.
        ls_comp-type ?= lo_type.
        APPEND ls_comp TO lt_comp.
        lo_struct = cl_abap_structdescr=>create( lt_comp ).
        CREATE DATA rr_data TYPE HANDLE lo_struct.
        ASSIGN rr_data->* TO <wrap>.
        ASSIGN COMPONENT 1 OF STRUCTURE <wrap> TO <comp>.
        <comp> = is_data.
      CATCH cx_root.
        CLEAR rr_data.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
