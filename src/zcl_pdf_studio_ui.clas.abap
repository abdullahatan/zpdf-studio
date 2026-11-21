"! <p>ZPDF Studio designer in SAP GUI (cl_gui_html_viewer, Edge control).</p>
"! The designer is one HTML page (MIME repository, fixed path C_MIME). ABAP puts the start data
"! into the page (form, language, stored design, assets) and receives SAPEVENT actions:
"! SYNC, SAVE, PREVIEW, TRANSPORT, UPLOAD_ASSET, DDIC_SEARCH, DDIC_RESOLVE, VERSIONS,
"! ACTIVATE_VERSION, RELOAD, EXIT.
"! <ul>
"! <li>The HTML control is created in PBO of the designer screen, so it belongs to that screen
"!     and survives dialogs.</li>
"! <li>The page sends its whole state with every action. After an action that opens a SAP dialog
"!     the page is shown again from that state, so a design is never lost behind a dialog.</li>
"! <li>With "auto save" the state is also stored as a draft (table C_DRAFT_TABLE) per form and
"!     user; the draft is offered when the form is opened again.</li>
"! </ul>
CLASS zcl_pdf_studio_ui DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_line,
        key   TYPE string,
        arg   TYPE string,
        value TYPE string,
      END OF ty_line,
      ty_lines TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.

    CONSTANTS c_mime TYPE string VALUE '/SAP/PUBLIC/ZPDF_STUDIO/designer.html'.
    CONSTANTS c_mime_folder TYPE string VALUE '/SAP/PUBLIC/ZPDF_STUDIO'.
    CONSTANTS c_page_mark TYPE string VALUE 'name="zpdf-designer" content="2.'.
    CONSTANTS c_boot_mark TYPE string VALUE '__ZPDF_BOOT__'.
    CONSTANTS c_studio_mark TYPE string VALUE '<!--zpdf-studio:'.
    CONSTANTS c_sink TYPE string VALUE 'zpdf-sink'.
    CONSTANTS c_draft_table TYPE tabname VALUE 'ZPDF_STUDIO_DRFT'.
    CONSTANTS c_fc_save TYPE sy-ucomm VALUE 'FC01'.
    CONSTANTS c_fc_preview TYPE sy-ucomm VALUE 'FC02'.
    CONSTANTS c_fc_refresh TYPE sy-ucomm VALUE 'FC03'.
    CONSTANTS c_fc_exit TYPE sy-ucomm VALUE 'ZPDFX'.

    "! Prepares the designer for a form (a new form is created on the first save). Call it
    "! before the designer screen; the page is shown by PBO.
    CLASS-METHODS open
      IMPORTING
        iv_form_id   TYPE csequence
        iv_view_only TYPE abap_bool DEFAULT abap_false
      RAISING
        zcx_pdf_studio.

    "! PBO of the designer screen: creates the HTML control once and shows the page.
    CLASS-METHODS pbo.

    "! PAI of the designer screen (function keys Save, Preview, Refresh, exit from the page).
    "! @parameter rv_leave | abap_true: leave the screen
    CLASS-METHODS user_command
      IMPORTING
        iv_ucomm        TYPE sy-ucomm
      RETURNING
        VALUE(rv_leave) TYPE abap_bool.

    "! Back / Exit / Cancel: asks to save unsaved changes. abap_false = stay on the screen.
    CLASS-METHODS may_leave
      RETURNING
        VALUE(rv_leave) TYPE abap_bool.

    CLASS-METHODS free.

    CLASS-METHODS on_sapevent
      FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING
        action
        postdata.

    "! abap_true when the MIME repository holds a designer page of this generation.
    CLASS-METHODS page_installed
      RETURNING
        VALUE(rv_ok) TYPE abap_bool.

    "! Uploads designer.html from the PC into the MIME repository (file dialog when iv_file is empty).
    CLASS-METHODS install_page
      IMPORTING
        iv_file TYPE string OPTIONAL
      RAISING
        zcx_pdf_studio.

    "! Text in the logon language: Turkish for TR, English otherwise.
    CLASS-METHODS txt
      IMPORTING
        iv_tr          TYPE string
        iv_en          TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    "! Decodes the page payload: base64( "KEY<TAB>ARG<TAB>base64(VALUE)" lines ).
    CLASS-METHODS parse_envelope
      IMPORTING
        iv_payload      TYPE string
      RETURNING
        VALUE(rt_lines) TYPE ty_lines
      RAISING
        zcx_pdf_studio.

    "! Builds the form template from the META lines of the payload.
    CLASS-METHODS template_from_lines
      IMPORTING
        it_lines           TYPE ty_lines
      RETURNING
        VALUE(rs_template) TYPE zcl_pdf_studio_repo=>ty_template.

    "! Base64 of the design embedded in a stored form ('' when the form was made elsewhere).
    CLASS-METHODS studio_payload
      IMPORTING
        iv_html       TYPE string
      RETURNING
        VALUE(rv_b64) TYPE string.

    "! DDIC types for the interface of a form (JSON array of name, kind S/T/E for the designer,
    "! type S/D/V/T/E, descr, package). The row limit bounds every search; a name is not required.
    "! @parameter iv_query | Name pattern, * is the wildcard; without * the name starts with the text
    "! @parameter iv_kinds | Object types to search: S structure, D database table, V view,
    "!                       T table type, E data element; empty = all
    "! @parameter iv_package | Package pattern (* wildcard); without * packages starting with it
    "! @parameter iv_max | Maximum number of rows (1 to 500)
    CLASS-METHODS ddic_search
      IMPORTING
        iv_query       TYPE csequence
        iv_kinds       TYPE csequence DEFAULT 'SDVTE'
        iv_package     TYPE csequence OPTIONAL
        iv_max         TYPE i DEFAULT 100
      RETURNING
        VALUE(rv_json) TYPE string.

    "! Field tree of a DDIC type as JSON: nodes n (name), k (S structure, T table, E field),
    "! t (ABAP type), l (length), dec (decimals), d (description), c (children).
    CLASS-METHODS ddic_describe
      IMPORTING
        iv_type        TYPE csequence
      RETURNING
        VALUE(rv_json) TYPE string
      RAISING
        zcx_pdf_studio.
    "! Title of the current screen in the logon language. Assigning SY-TITLE does not change the
    "! title of a selection screen; a title with only a placeholder ("&amp;", title 220 of SE16N,
    "! present in every system) is set with the text instead.
    CLASS-METHODS set_title
      IMPORTING
        iv_title TYPE csequence.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_draft,
        mandt      TYPE mandt,
        form_id    TYPE c LENGTH 30,
        uname      TYPE syuname,
        changed_at TYPE timestamp,
        content    TYPE xstring,
      END OF ty_draft.

    CONSTANTS c_max_depth TYPE i VALUE 6.
    CONSTANTS c_max_nodes TYPE i VALUE 4000.

    CLASS-DATA go_html TYPE REF TO cl_gui_html_viewer.
    CLASS-DATA gv_form TYPE string.
    CLASS-DATA gv_view_only TYPE abap_bool.
    CLASS-DATA gv_page TYPE string.
    CLASS-DATA gt_state TYPE ty_lines.
    CLASS-DATA gv_dirty TYPE abap_bool.
    CLASS-DATA gv_autosave TYPE abap_bool VALUE abap_true.
    CLASS-DATA gv_version TYPE string.
    CLASS-DATA gv_description TYPE string.
    CLASS-DATA gv_msg_text TYPE string.
    CLASS-DATA gv_msg_type TYPE c LENGTH 1.
    CLASS-DATA gv_reply TYPE string.
    CLASS-DATA gv_reply_req TYPE string.
    CLASS-DATA gv_saved_req TYPE string.
    CLASS-DATA gv_locked TYPE abap_bool.
    CLASS-DATA gv_no_draft TYPE abap_bool.
    CLASS-DATA gv_nodes TYPE i.

    CLASS-METHODS page_template
      RETURNING
        VALUE(rv_html) TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS show_page
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS boot_json
      RETURNING
        VALUE(rv_json) TYPE string.

    CLASS-METHODS assets_json
      RETURNING
        VALUE(rv_json) TYPE string.

    CLASS-METHODS display
      IMPORTING
        iv_html  TYPE string
        iv_frame TYPE string OPTIONAL
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS reply
      IMPORTING
        iv_req     TYPE string
        iv_ok      TYPE abap_bool
        iv_message TYPE string OPTIONAL
        iv_data    TYPE string OPTIONAL
        iv_kind    TYPE string OPTIONAL.

    CLASS-METHODS take_state
      IMPORTING
        it_lines TYPE ty_lines.

    CLASS-METHODS load_active
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS save_state
      RETURNING
        VALUE(rv_message) TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS preview_state
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS upload_asset
      IMPORTING
        it_lines          TYPE ty_lines
      RETURNING
        VALUE(rv_message) TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS versions_json
      RETURNING
        VALUE(rv_json) TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS draft_write.
    CLASS-METHODS draft_delete.
    CLASS-METHODS draft_read
      EXPORTING
        et_lines      TYPE ty_lines
        ev_changed_at TYPE timestamp
        ev_found      TYPE abap_bool.

    CLASS-METHODS lock
      RETURNING
        VALUE(rv_user) TYPE string.
    CLASS-METHODS unlock.

    CLASS-METHODS node_json
      IMPORTING
        io_type        TYPE REF TO cl_abap_typedescr
        iv_name        TYPE string
        iv_descr       TYPE string
        iv_depth       TYPE i
      RETURNING
        VALUE(rv_json) TYPE string.

    CLASS-METHODS children_json
      IMPORTING
        io_struct      TYPE REF TO cl_abap_structdescr
        iv_depth       TYPE i
      RETURNING
        VALUE(rv_json) TYPE string.

    CLASS-METHODS type_text
      IMPORTING
        iv_name        TYPE csequence
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS post_to_string
      IMPORTING
        it_post        TYPE STANDARD TABLE
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS payload_of
      IMPORTING
        iv_body       TYPE string
      RETURNING
        VALUE(rv_b64) TYPE string.

    CLASS-METHODS value_of
      IMPORTING
        it_lines        TYPE ty_lines
        iv_arg          TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    CLASS-METHODS set_value
      IMPORTING
        iv_arg   TYPE string
        iv_value TYPE string.

    CLASS-METHODS b64
      IMPORTING
        iv_text       TYPE string
      RETURNING
        VALUE(rv_b64) TYPE string.

    CLASS-METHODS js
      IMPORTING
        iv_text        TYPE csequence
      RETURNING
        VALUE(rv_json) TYPE string.

    CLASS-METHODS bool
      IMPORTING
        iv_flag        TYPE abap_bool
      RETURNING
        VALUE(rv_json) TYPE string.
    "! Settings of the current user (JSON: theme, language); empty when nothing is stored.
    CLASS-METHODS prefs_read
      RETURNING
        VALUE(rv_json) TYPE string.
    "! Stores the settings of the current user (table ZPDF_STUDIO_USER); they outlive the session.
    CLASS-METHODS prefs_write
      IMPORTING
        iv_json TYPE string.
ENDCLASS.



CLASS zcl_pdf_studio_ui IMPLEMENTATION.

  METHOD txt.
    IF sy-langu = 'T'.
      rv_text = iv_tr.
    ELSE.
      rv_text = iv_en.
    ENDIF.
  ENDMETHOD.


  METHOD open.
    DATA lt_draft TYPE ty_lines.
    DATA lv_draft_at TYPE timestamp.
    DATA lv_found TYPE abap_bool.
    DATA lv_answer TYPE c LENGTH 1.
    DATA lv_question TYPE string.
    DATA lv_user TYPE string.
    DATA lv_button_1 TYPE c LENGTH 12.
    DATA lv_button_2 TYPE c LENGTH 12.

    free( ).
    gv_form = to_upper( condense( val = iv_form_id ) ).
    IF gv_form IS INITIAL OR strlen( gv_form ) > 30 OR gv_form CN 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = `Form adı yalnızca A-Z, 0-9 ve _ içerebilir (en fazla 30 karakter).`
                         iv_en = `The form name may contain only A-Z, 0-9 and _ (at most 30 characters).` ).
    ENDIF.
    gv_view_only = iv_view_only.
    gv_autosave = abap_true.
    gv_page = page_template( ).

    IF gv_view_only = abap_false.
      lv_user = lock( ).
      IF lv_user IS NOT INITIAL.
        gv_view_only = abap_true.
        gv_msg_type = 'W'.
        gv_msg_text = txt( iv_tr = |{ gv_form } şu anda { lv_user } tarafından düzenleniyor; salt okunur açıldı.|
                           iv_en = |{ gv_form } is being edited by { lv_user }; opened for display only.| ).
      ENDIF.
    ENDIF.

    load_active( ).

    "An unsaved draft of this user (auto save) is offered once.
    IF gv_view_only = abap_false.
      draft_read( IMPORTING et_lines = lt_draft ev_changed_at = lv_draft_at ev_found = lv_found ).
      IF lv_found = abap_true AND value_of( it_lines = lt_draft iv_arg = `html` ) IS NOT INITIAL.
        lv_question = txt(
          iv_tr = |{ gv_form } için kaydedilmemiş bir taslağınız var ({ lv_draft_at TIMESTAMP = USER }). Taslak geri yüklensin mi?|
          iv_en = |You have an unsaved draft of { gv_form } ({ lv_draft_at TIMESTAMP = USER }). Restore the draft?| ).
        lv_button_1 = txt( iv_tr = `Geri yükle` iv_en = `Restore` ).
        lv_button_2 = txt( iv_tr = `Taslağı sil` iv_en = `Discard` ).
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = 'ZPDF Studio'
            text_question         = lv_question
            text_button_1         = lv_button_1
            text_button_2         = lv_button_2
            display_cancel_button = abap_false
          IMPORTING
            answer                = lv_answer
          EXCEPTIONS
            OTHERS                = 1.
        IF sy-subrc = 0 AND lv_answer = '1'.
          gt_state = lt_draft.
          gv_dirty = abap_true.
          gv_msg_type = 'S'.
          gv_msg_text = txt( iv_tr = `Taslak geri yüklendi. Kalıcı olması için Kaydet'e basın.`
                             iv_en = `The draft was restored. Press Save to keep it.` ).
        ELSE.
          draft_delete( ).
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD load_active.
    DATA ls_template TYPE zcl_pdf_studio_repo=>ty_template.
    DATA ls_form TYPE zcl_pdf_studio_repo=>ty_form.

    CLEAR: gt_state, gv_version, gv_description, gv_dirty.
    TRY.
        ls_template = zcl_pdf_studio_repo=>read_active_template( gv_form ).
        ls_form = zcl_pdf_studio_repo=>read_form( gv_form ).
      CATCH zcx_pdf_studio.
        "New form: it is created on the first save.
        RETURN.
    ENDTRY.
    IF ls_template-html_content IS NOT INITIAL AND studio_payload( ls_template-html_content ) IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = |{ gv_form } ZPDF Studio tasarımcısıyla yapılmamış; yeni bir form adı kullanın.|
                         iv_en = |{ gv_form } was not made with the ZPDF Studio designer; use a new form name.| ).
    ENDIF.
    gv_version = ls_template-version.
    gv_description = ls_form-description.
    "The complete stored form is the first state: preview and save from the SAP toolbar work
    "before the page has sent anything (page size and margins included).
    set_value( iv_arg = `html` iv_value = ls_template-html_content ).
    set_value( iv_arg = `css` iv_value = ls_template-css_content ).
    set_value( iv_arg = `header` iv_value = ls_template-header_html ).
    set_value( iv_arg = `footer` iv_value = ls_template-footer_html ).
    set_value( iv_arg = `sample` iv_value = ls_template-sample_json ).
    set_value( iv_arg = `description` iv_value = ls_form-description ).
    set_value( iv_arg = `page_size` iv_value = ls_template-page_size ).
    set_value( iv_arg = `orientation` iv_value = ls_template-orientation ).
    set_value( iv_arg = `margin_top` iv_value = |{ ls_template-margin_top }| ).
    set_value( iv_arg = `margin_right` iv_value = |{ ls_template-margin_right }| ).
    set_value( iv_arg = `margin_bottom` iv_value = |{ ls_template-margin_bottom }| ).
    set_value( iv_arg = `margin_left` iv_value = |{ ls_template-margin_left }| ).
  ENDMETHOD.


  METHOD pbo.
    DATA lt_events TYPE cntl_simple_events.
    DATA ls_event TYPE cntl_simple_event.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.

    IF go_html IS BOUND OR gv_form IS INITIAL.
      RETURN.
    ENDIF.
    "Created here, in PBO of the designer screen, the control is linked to this screen: it
    "stays visible when a dialog on top of it is closed.
    CREATE OBJECT go_html
      EXPORTING
        parent               = cl_gui_container=>screen0
        query_table_disabled = abap_true
      EXCEPTIONS
        OTHERS               = 1.
    IF sy-subrc <> 0.
      CLEAR go_html.
      MESSAGE txt( iv_tr = `HTML kontrolü oluşturulamadı` iv_en = `The HTML control could not be created` ) TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    "System event: the handler runs at once, without PAI/PBO, so the page keeps the focus.
    ls_event-eventid = cl_gui_html_viewer=>m_id_sapevent.
    ls_event-appl_event = abap_false.
    APPEND ls_event TO lt_events.
    go_html->set_registered_events( EXPORTING events = lt_events EXCEPTIONS OTHERS = 1 ).
    SET HANDLER on_sapevent FOR go_html.
    TRY.
        show_page( ).
      CATCH zcx_pdf_studio INTO lx_pdf.
        MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.


  METHOD free.
    IF go_html IS BOUND.
      go_html->free( EXCEPTIONS OTHERS = 1 ).
      CLEAR go_html.
    ENDIF.
    unlock( ).
    CLEAR: gv_form, gt_state, gv_dirty, gv_version, gv_description, gv_msg_text, gv_msg_type,
           gv_reply, gv_reply_req, gv_saved_req, gv_view_only.
  ENDMETHOD.


  METHOD on_sapevent.
    DATA lt_lines TYPE ty_lines.
    DATA lv_action TYPE string.
    DATA lv_req TYPE string VALUE `0`.
    DATA lv_message TYPE string.
    DATA lv_request TYPE trkorr.
    DATA lv_redraw TYPE abap_bool.
    DATA lv_quiet TYPE abap_bool.
    DATA lv_failed TYPE abap_bool.
    DATA lv_version TYPE zcl_pdf_studio_repo=>ty_version.
    DATA lv_ui TYPE string.
    DATA lv_max TYPE i.
    DATA lv_number TYPE string.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.
    DATA lx_root TYPE REF TO cx_root.

    lv_action = to_upper( action ).
    CLEAR gv_reply.
    "Every answer is a new display of the whole page from the state the page sent with the
    "request. SYNC and PREFS happen in the background; PREVIEW and EXIT leave the page as it is.
    lv_quiet = xsdbool( lv_action = 'SYNC' OR lv_action = 'PREFS' ).
    lv_redraw = xsdbool( lv_quiet = abap_false AND lv_action <> 'PREVIEW' AND lv_action <> 'EXIT' ).
    TRY.
        lt_lines = parse_envelope( payload_of( post_to_string( postdata ) ) ).
        IF lt_lines IS INITIAL.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING
              message = txt( iv_tr = `SAP GUI sayfa verisini iletmedi (SAP GUI for Windows ve Edge tarayıcı denetimi gerekir).`
                             iv_en = `SAP GUI did not pass the page data (SAP GUI for Windows with the Edge browser control is required).` ).
        ENDIF.
        lv_req = value_of( it_lines = lt_lines iv_arg = `req` ).
        IF lv_req IS INITIAL OR lv_req CN '0123456789'.
          lv_req = `0`.
        ENDIF.
        "The state of the page first: whatever happens next, the design is safe.
        take_state( lt_lines ).
        IF gv_view_only = abap_true AND ( lv_action = 'SAVE' OR lv_action = 'TRANSPORT'
            OR lv_action = 'UPLOAD_ASSET' OR lv_action = 'ACTIVATE_VERSION' ).
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING
              message = txt( iv_tr = `Form salt okunur açıldı.` iv_en = `The form is opened for display only.` ).
        ENDIF.

        CASE lv_action.
          WHEN 'SYNC'.
            IF gv_autosave = abap_true AND gv_dirty = abap_true AND gv_view_only = abap_false.
              draft_write( ).
            ENDIF.

          WHEN 'PREFS'.
            "Theme and language of the user: remembered across sessions.
            prefs_write( value_of( it_lines = lt_lines iv_arg = `prefs` ) ).

          WHEN 'SAVE'.
            lv_message = save_state( ).
            reply( iv_req = lv_req iv_ok = abap_true iv_message = lv_message
                   iv_data = |\{"version":"{ gv_version }"\}| iv_kind = `save` ).

          WHEN 'PREVIEW'.
            preview_state( ).
            MESSAGE txt( iv_tr = `PDF oluşturuldu ve açıldı.` iv_en = `The PDF was created and opened.` ) TYPE 'S'.

          WHEN 'TRANSPORT'.
            IF value_of( it_lines = lt_lines iv_arg = `save` ) = `X` OR gv_version IS INITIAL.
              save_state( ).
            ENDIF.
            lv_request = zcl_pdf_studio_assets=>transport_form( gv_form ).
            reply( iv_req = lv_req iv_ok = abap_true iv_kind = `transport`
                   iv_message = txt( iv_tr = |{ gv_form } ve kullandığı logo/fontlar { lv_request } talebine eklendi.|
                                     iv_en = |{ gv_form } and its logos/fonts were added to request { lv_request }.| ) ).

          WHEN 'UPLOAD_ASSET'.
            reply( iv_req = lv_req iv_ok = abap_true iv_kind = `uploaded` iv_message = upload_asset( lt_lines ) ).

          WHEN 'DDIC_SEARCH'.
            lv_number = value_of( it_lines = lt_lines iv_arg = `max` ).
            IF lv_number IS NOT INITIAL AND lv_number CO '0123456789' AND strlen( lv_number ) <= 4.
              lv_max = lv_number.
            ELSE.
              lv_max = 100.
            ENDIF.
            reply( iv_req = lv_req iv_ok = abap_true iv_kind = `ddic_search`
                   iv_data = ddic_search( iv_query   = value_of( it_lines = lt_lines iv_arg = `q` )
                                          iv_kinds   = value_of( it_lines = lt_lines iv_arg = `kinds` )
                                          iv_package = value_of( it_lines = lt_lines iv_arg = `pkg` )
                                          iv_max     = lv_max ) ).

          WHEN 'DDIC_RESOLVE'.
            reply( iv_req = lv_req iv_ok = abap_true iv_kind = `ddic_resolve`
                   iv_data = ddic_describe( value_of( it_lines = lt_lines iv_arg = `type` ) ) ).

          WHEN 'VERSIONS'.
            reply( iv_req = lv_req iv_ok = abap_true iv_kind = `versions` iv_data = versions_json( ) ).

          WHEN 'ACTIVATE_VERSION'.
            lv_version = value_of( it_lines = lt_lines iv_arg = `version` ).
            lv_ui = value_of( it_lines = lt_lines iv_arg = `ui` ).
            zcl_pdf_studio_repo=>activate_version( iv_form_id = gv_form iv_version = lv_version ).
            draft_delete( ).
            load_active( ).
            set_value( iv_arg = `ui` iv_value = lv_ui ).
            reply( iv_req = lv_req iv_ok = abap_true iv_kind = `activated`
                   iv_message = txt( iv_tr = |Sürüm { lv_version } etkinleştirildi.| iv_en = |Version { lv_version } was activated.| ) ).

          WHEN 'RELOAD'.
            "Nothing to do: the page is shown again from its state.

          WHEN 'EXIT'.
            cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = c_fc_exit ).

          WHEN OTHERS.
            reply( iv_req = lv_req iv_ok = abap_false
                   iv_message = txt( iv_tr = |Bilinmeyen işlem: { lv_action }| iv_en = |Unknown action: { lv_action }| ) ).
        ENDCASE.

      CATCH zcx_pdf_studio INTO lx_pdf.
        zcl_pdf_studio_repo=>abort_changes( ).
        lv_message = lx_pdf->get_text( ).
        lv_failed = abap_true.
      CATCH cx_root INTO lx_root.
        zcl_pdf_studio_repo=>abort_changes( ).
        lv_message = lx_root->get_text( ).
        lv_failed = abap_true.
    ENDTRY.

    IF lv_failed = abap_true AND lv_quiet = abap_false.
      "The page shows the error; its own kind lets the page close what it was waiting for.
      reply( iv_req = lv_req iv_ok = abap_false iv_message = lv_message iv_kind = to_lower( lv_action ) ).
      lv_redraw = abap_true.
    ENDIF.

    IF lv_redraw = abap_true.
      TRY.
          show_page( ).
        CATCH zcx_pdf_studio INTO lx_pdf.
          MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
      ENDTRY.
    ENDIF.
    cl_gui_cfw=>flush( EXCEPTIONS OTHERS = 1 ).
  ENDMETHOD.


  METHOD user_command.
    DATA lv_message TYPE string.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.
    DATA lx_root TYPE REF TO cx_root.

    rv_leave = abap_false.
    TRY.
        CASE iv_ucomm.
          WHEN c_fc_save.
            IF gv_view_only = abap_true.
              MESSAGE txt( iv_tr = `Form salt okunur açıldı.` iv_en = `The form is opened for display only.` ) TYPE 'S' DISPLAY LIKE 'W'.
              RETURN.
            ENDIF.
            IF gv_dirty = abap_false.
              MESSAGE txt( iv_tr = `Kaydedilecek değişiklik yok.` iv_en = `There is nothing to save.` ) TYPE 'S'.
              RETURN.
            ENDIF.
            lv_message = save_state( ).
            "The page is shown again and learns with its boot data that the design is saved.
            reply( iv_req = `0` iv_ok = abap_true iv_message = lv_message
                   iv_data = |\{"version":"{ gv_version }"\}| iv_kind = `saved` ).
            show_page( ).
          WHEN c_fc_preview.
            IF value_of( it_lines = gt_state iv_arg = `html` ) IS INITIAL.
              MESSAGE txt( iv_tr = `Form boş.` iv_en = `The form is empty.` ) TYPE 'S'.
              RETURN.
            ENDIF.
            preview_state( ).
            MESSAGE txt( iv_tr = `PDF oluşturuldu ve açıldı.` iv_en = `The PDF was created and opened.` ) TYPE 'S'.
          WHEN c_fc_refresh.
            CLEAR gv_reply.
            show_page( ).
          WHEN c_fc_exit.
            rv_leave = may_leave( ).
        ENDCASE.
      CATCH zcx_pdf_studio INTO lx_pdf.
        zcl_pdf_studio_repo=>abort_changes( ).
        MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
      CATCH cx_root INTO lx_root.
        zcl_pdf_studio_repo=>abort_changes( ).
        MESSAGE lx_root->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
    cl_gui_cfw=>flush( EXCEPTIONS OTHERS = 1 ).
  ENDMETHOD.


  METHOD may_leave.
    DATA lv_answer TYPE c LENGTH 1.
    DATA lv_question TYPE string.
    DATA lv_button_1 TYPE c LENGTH 12.
    DATA lv_button_2 TYPE c LENGTH 12.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.

    rv_leave = abap_true.
    IF gv_view_only = abap_true OR gv_dirty = abap_false.
      RETURN.
    ENDIF.
    lv_question = txt( iv_tr = |{ gv_form } formunda kaydedilmemiş değişiklikler var. Çıkmadan önce kaydedilsin mi?|
                       iv_en = |Form { gv_form } has unsaved changes. Save before leaving?| ).
    lv_button_1 = txt( iv_tr = `Kaydet` iv_en = `Save` ).
    lv_button_2 = txt( iv_tr = `Kaydetme` iv_en = `Don't save` ).
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = 'ZPDF Studio'
        text_question         = lv_question
        text_button_1         = lv_button_1
        text_button_2         = lv_button_2
        display_cancel_button = abap_true
      IMPORTING
        answer                = lv_answer
      EXCEPTIONS
        OTHERS                = 1.
    IF sy-subrc <> 0.
      rv_leave = abap_false.
      RETURN.
    ENDIF.
    CASE lv_answer.
      WHEN '1'.
        TRY.
            MESSAGE save_state( ) TYPE 'S'.
          CATCH zcx_pdf_studio INTO lx_pdf.
            zcl_pdf_studio_repo=>abort_changes( ).
            MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
            rv_leave = abap_false.
        ENDTRY.
      WHEN '2'.
        "The user decided against the changes: the draft goes as well.
        draft_delete( ).
        gv_dirty = abap_false.
      WHEN OTHERS.
        rv_leave = abap_false.
    ENDCASE.
  ENDMETHOD.


  METHOD take_state.
    DATA ls_line TYPE ty_line.

    "Only a request that carries the design replaces the state.
    IF value_of( it_lines = it_lines iv_arg = `html` ) IS INITIAL.
      RETURN.
    ENDIF.
    CLEAR gt_state.
    LOOP AT it_lines INTO ls_line WHERE key = `META`.
      CASE ls_line-arg.
        WHEN `req` OR `save` OR `content` OR `asset_id` OR `asset_descr` OR `family` OR `bold` OR `italic` OR `filename`.
          CONTINUE.
      ENDCASE.
      APPEND ls_line TO gt_state.
    ENDLOOP.
    gv_dirty = xsdbool( value_of( it_lines = gt_state iv_arg = `dirty` ) = `X` ).
    gv_autosave = xsdbool( value_of( it_lines = gt_state iv_arg = `autosave` ) = `X` ).
    IF gv_autosave = abap_false.
      "Auto save was switched off: no stale draft stays behind.
      draft_delete( ).
    ENDIF.
  ENDMETHOD.


  METHOD save_state.
    DATA ls_template TYPE zcl_pdf_studio_repo=>ty_template.
    DATA ls_form TYPE zcl_pdf_studio_repo=>ty_form.
    DATA lv_version TYPE zcl_pdf_studio_repo=>ty_version.
    DATA lv_request TYPE trkorr.
    DATA lv_description TYPE string.

    ls_template = template_from_lines( gt_state ).
    "The form name is the one this session opened, not the one the page sends.
    ls_template-form_id = gv_form.
    IF studio_payload( ls_template-html_content ) IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = `Sayfa geçerli bir tasarım göndermedi.` iv_en = `The page did not send a valid design.` ).
    ENDIF.
    lv_description = value_of( it_lines = gt_state iv_arg = `description` ).
    IF lv_description IS INITIAL.
      lv_description = |{ gv_form } (ZPDF Studio)|.
    ENDIF.

    TRY.
        ls_form = zcl_pdf_studio_repo=>read_form( gv_form ).
        IF ls_form-description <> lv_description.
          zcl_pdf_studio_repo=>update_form(
            iv_form_id        = gv_form
            iv_description    = lv_description
            iv_ddic_structure = ls_form-ddic_structure ).
        ENDIF.
      CATCH zcx_pdf_studio.
        zcl_pdf_studio_repo=>create_form(
          iv_form_id     = gv_form
          iv_description = lv_description ).
    ENDTRY.

    lv_version = zcl_pdf_studio_repo=>save_template(
      is_template    = ls_template
      iv_new_version = abap_true ).
    zcl_pdf_studio_repo=>commit_changes( ).

    gv_version = lv_version.
    gv_description = lv_description.
    gv_dirty = abap_false.
    set_value( iv_arg = `dirty` iv_value = `` ).
    draft_delete( ).

    rv_message = txt( iv_tr = |{ gv_form } kaydedildi, sürüm { lv_version }.|
                      iv_en = |{ gv_form } saved, version { lv_version }.| ).
    lv_request = zcl_pdf_studio_repo=>last_request( ).
    IF lv_request IS NOT INITIAL.
      rv_message = |{ rv_message } Transport: { lv_request }.|.
    ENDIF.
  ENDMETHOD.


  METHOD preview_state.
    DATA lv_sample TYPE string.
    DATA ls_template TYPE zcl_pdf_studio_repo=>ty_template.
    DATA ls_page TYPE zcl_pdf_studio_renderer=>ty_page.
    DATA lr_data TYPE REF TO data.
    DATA lv_pdf TYPE xstring.
    FIELD-SYMBOLS <data> TYPE any.

    ls_template = template_from_lines( gt_state ).
    ls_page-page_size = ls_template-page_size.
    ls_page-orientation = ls_template-orientation.
    ls_page-margin_top = ls_template-margin_top.
    ls_page-margin_right = ls_template-margin_right.
    ls_page-margin_bottom = ls_template-margin_bottom.
    ls_page-margin_left = ls_template-margin_left.

    lv_sample = ls_template-sample_json.
    IF lv_sample IS INITIAL.
      lv_sample = `{}`.
    ENDIF.
    lr_data = zcl_pdf_studio_json=>to_data( lv_sample ).
    ASSIGN lr_data->* TO <data>.
    lv_pdf = zcl_pdf_studio_api=>render_html(
      iv_html   = ls_template-html_content
      iv_css    = ls_template-css_content
      iv_header = ls_template-header_html
      iv_footer = ls_template-footer_html
      is_page   = ls_page
      is_data   = <data> ).
    zcl_pdf_studio_api=>download_pdf(
      iv_pdf_xstring = lv_pdf
      iv_filename    = |{ gv_form }_preview.pdf|
      iv_open        = abap_true
      iv_dialog      = abap_false ).
  ENDMETHOD.


  METHOD upload_asset.
    DATA ls_asset TYPE zcl_pdf_studio_assets=>ty_asset.
    DATA lv_request TYPE trkorr.

    ls_asset-asset_id = value_of( it_lines = it_lines iv_arg = `asset_id` ).
    ls_asset-family = value_of( it_lines = it_lines iv_arg = `family` ).
    ls_asset-bold = xsdbool( value_of( it_lines = it_lines iv_arg = `bold` ) = `X` ).
    ls_asset-italic = xsdbool( value_of( it_lines = it_lines iv_arg = `italic` ) = `X` ).
    ls_asset-filename = value_of( it_lines = it_lines iv_arg = `filename` ).
    ls_asset-description = value_of( it_lines = it_lines iv_arg = `asset_descr` ).
    IF ls_asset-description IS INITIAL.
      ls_asset-description = ls_asset-filename.
    ENDIF.
    lv_request = zcl_pdf_studio_assets=>save(
      is_asset   = ls_asset
      iv_content = cl_http_utility=>decode_x_base64( value_of( it_lines = it_lines iv_arg = `content` ) ) ).
    rv_message = txt( iv_tr = |{ to_upper( ls_asset-asset_id ) } logo ve font deposuna kaydedildi.|
                      iv_en = |{ to_upper( ls_asset-asset_id ) } was saved in the logo and font store.| ).
    IF lv_request IS NOT INITIAL.
      rv_message = |{ rv_message } Transport: { lv_request }.|.
    ENDIF.
  ENDMETHOD.


  METHOD versions_json.
    DATA lt_versions TYPE zcl_pdf_studio_repo=>ty_templates.
    DATA ls_version TYPE zcl_pdf_studio_repo=>ty_template.
    DATA lv_sep TYPE string.

    rv_json = `[`.
    TRY.
        lt_versions = zcl_pdf_studio_repo=>list_versions( gv_form ).
      CATCH zcx_pdf_studio.
        "Not saved yet: no versions.
        CLEAR lt_versions.
    ENDTRY.
    LOOP AT lt_versions INTO ls_version.
      rv_json = |{ rv_json }{ lv_sep }\{"version":"{ ls_version-version }","active":{ bool( xsdbool( ls_version-is_active = abap_true ) ) },| &&
                |"user":{ js( ls_version-changed_by ) },"at":"{ ls_version-changed_at }"\}|.
      lv_sep = `,`.
    ENDLOOP.
    rv_json = rv_json && `]`.
  ENDMETHOD.


  METHOD page_installed.
    TRY.
        page_template( ).
        rv_ok = abap_true.
      CATCH zcx_pdf_studio.
        rv_ok = abap_false.
    ENDTRY.
  ENDMETHOD.


  METHOD page_template.
    DATA lv_x TYPE xstring.
    DATA lo_mime TYPE REF TO if_mr_api.

    IF gv_page IS NOT INITIAL.
      rv_html = gv_page.
      RETURN.
    ENDIF.
    lo_mime = cl_mime_repository_api=>get_api( ).
    lo_mime->get(
      EXPORTING
        i_url              = c_mime
        i_check_authority  = abap_false
      IMPORTING
        e_content          = lv_x
      EXCEPTIONS
        parameter_missing  = 1
        error_occured      = 2
        not_found          = 3
        permission_failure = 4
        OTHERS             = 5 ).
    IF sy-subrc <> 0 OR lv_x IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = `Tasarımcı sayfası (designer.html) henüz kurulmamış.`
                         iv_en = `The designer page (designer.html) is not installed yet.` ).
    ENDIF.
    rv_html = zcl_pdf_studio_conv=>xstring_to_string( lv_x ).
    IF find( val = rv_html sub = c_page_mark ) < 0 OR find( val = rv_html sub = c_boot_mark ) < 0.
      CLEAR rv_html.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = `Kurulu tasarımcı sayfası eski sürüm; yeni designer.html yüklenmeli.`
                         iv_en = `The installed designer page is an old version; the new designer.html must be uploaded.` ).
    ENDIF.
    gv_page = rv_html.
  ENDMETHOD.


  METHOD install_page.
    DATA lt_files TYPE filetable.
    DATA ls_file TYPE file_table.
    DATA lv_rc TYPE i.
    DATA lv_action TYPE i.
    DATA lv_file TYPE string.
    DATA lt_bin TYPE solix_tab.
    DATA lv_length TYPE i.
    DATA lv_x TYPE xstring.
    DATA lv_html TYPE string.
    DATA lv_subrc TYPE sy-subrc.
    DATA lv_try TYPE i.
    DATA lo_mime TYPE REF TO if_mr_api.

    lv_file = iv_file.
    IF lv_file IS INITIAL.
      cl_gui_frontend_services=>file_open_dialog(
        EXPORTING
          window_title = 'ZPDF Studio - designer.html'
          file_filter  = 'HTML (*.html)|*.html'
        CHANGING
          file_table   = lt_files
          rc           = lv_rc
          user_action  = lv_action
        EXCEPTIONS
          OTHERS       = 1 ).
      IF sy-subrc <> 0 OR lv_rc < 1 OR lv_action = cl_gui_frontend_services=>action_cancel.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING
            message = txt( iv_tr = `Dosya seçilmedi.` iv_en = `No file was chosen.` ).
      ENDIF.
      READ TABLE lt_files INDEX 1 INTO ls_file.
      lv_file = ls_file-filename.
    ENDIF.

    cl_gui_frontend_services=>gui_upload(
      EXPORTING
        filename   = lv_file
        filetype   = 'BIN'
      IMPORTING
        filelength = lv_length
      CHANGING
        data_tab   = lt_bin
      EXCEPTIONS
        OTHERS     = 1 ).
    IF sy-subrc <> 0 OR lv_length = 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = |Dosya okunamadı: { lv_file }| iv_en = |The file could not be read: { lv_file }| ).
    ENDIF.
    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_length
      IMPORTING
        buffer       = lv_x
      TABLES
        binary_tab   = lt_bin
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = |Dosya okunamadı: { lv_file }| iv_en = |The file could not be read: { lv_file }| ).
    ENDIF.
    lv_html = zcl_pdf_studio_conv=>xstring_to_string( lv_x ).
    IF find( val = lv_html sub = c_page_mark ) < 0 OR find( val = lv_html sub = c_boot_mark ) < 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = `Bu dosya ZPDF Studio 2 tasarımcı sayfası değil (dist\designer.html seçilmeli).`
                         iv_en = `This file is not a ZPDF Studio 2 designer page (choose dist\designer.html).` ).
    ENDIF.

    lo_mime = cl_mime_repository_api=>get_api( ).
    lo_mime->create_folder(
      EXPORTING
        i_url                     = c_mime_folder
        i_description             = 'ZPDF Studio'
        i_suppress_package_dialog = abap_true
        i_dev_package             = '$ZPDF_STUDIO'
        i_suppress_dialogs        = abap_true
      EXCEPTIONS
        OTHERS                    = 1 ).
    "The folder usually exists already; PUT reports what really matters.
    "Without a language PUT overwrites the content in the original language of the object.
    "With the logon language it fails when the page was first uploaded in another language.
    DO 2 TIMES.
      lv_try = sy-index.
      lo_mime->put(
        EXPORTING
          i_url                     = c_mime
          i_content                 = lv_x
          i_language                = space
          i_description             = 'ZPDF Studio designer'
          i_suppress_package_dialog = abap_true
          i_dev_package             = '$ZPDF_STUDIO'
          i_suppress_dialogs        = abap_true
        EXCEPTIONS
          parameter_missing         = 1
          error_occured             = 2
          cancelled                 = 3
          permission_failure        = 4
          data_inconsistency        = 5
          new_loio_already_exists   = 6
          is_folder                 = 7
          OTHERS                    = 8 ).
      lv_subrc = sy-subrc.
      IF lv_subrc <> 5 OR lv_try = 2.
        EXIT.
      ENDIF.
      "The stored object has no content in its original language: replace the object.
      lo_mime->delete(
        EXPORTING
          i_url              = c_mime
          i_suppress_dialogs = abap_true
        EXCEPTIONS
          OTHERS             = 1 ).
    ENDDO.
    IF lv_subrc <> 0.
      ROLLBACK WORK.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = |Tasarımcı sayfası MIME deposuna yazılamadı ({ c_mime }, hata { lv_subrc }).|
                         iv_en = |The designer page could not be written to the MIME repository ({ c_mime }, error { lv_subrc }).| ).
    ENDIF.
    COMMIT WORK.
    gv_page = lv_html.
  ENDMETHOD.


  METHOD show_page.
    DATA lv_html TYPE string.
    DATA lv_prefs TYPE string.

    lv_html = page_template( ).
    "The dark theme is set on the page element itself, so the page never flashes in the light
    "theme while it is shown again.
    lv_prefs = prefs_read( ).
    REPLACE ALL OCCURRENCES OF ` ` IN lv_prefs WITH ``.
    IF lv_prefs CS `"theme":"dark"`.
      REPLACE FIRST OCCURRENCE OF `<html lang="tr">` IN lv_html WITH `<html lang="tr" data-theme="dark">`.
    ENDIF.
    REPLACE FIRST OCCURRENCE OF c_boot_mark IN lv_html WITH boot_json( ).
    display( lv_html ).
  ENDMETHOD.


  METHOD boot_json.
    DATA lv_message TYPE string VALUE `null`.
    DATA lv_reply TYPE string VALUE `null`.
    DATA lv_description TYPE string.

    IF gv_msg_text IS NOT INITIAL.
      lv_message = |\{"type":"{ gv_msg_type }","text":{ js( gv_msg_text ) }\}|.
    ENDIF.
    IF gv_reply IS NOT INITIAL.
      lv_reply = gv_reply.
    ENDIF.
    lv_description = value_of( it_lines = gt_state iv_arg = `description` ).
    IF lv_description IS INITIAL.
      lv_description = gv_description.
    ENDIF.
    rv_json = |\{"runtime":"sap","lang":"{ txt( iv_tr = `TR` iv_en = `EN` ) }","form":{ js( gv_form ) },| &&
              |"viewOnly":{ bool( gv_view_only ) },"user":{ js( sy-uname ) },"version":{ js( gv_version ) },| &&
              |"description":{ js( lv_description ) },| &&
              |"doc64":"{ studio_payload( value_of( it_lines = gt_state iv_arg = `html` ) ) }",| &&
              |"sample64":"{ b64( value_of( it_lines = gt_state iv_arg = `sample` ) ) }",| &&
              |"ui64":"{ b64( value_of( it_lines = gt_state iv_arg = `ui` ) ) }",| &&
              |"prefs64":"{ b64( prefs_read( ) ) }",| &&
              |"dirty":{ bool( gv_dirty ) },"autosave":{ bool( gv_autosave ) },"assets":{ assets_json( ) },| &&
              |"message":{ lv_message },"reply":{ lv_reply }\}|.
    CLEAR: gv_msg_text, gv_msg_type, gv_reply.
  ENDMETHOD.


  METHOD assets_json.
    DATA lt_assets TYPE zcl_pdf_studio_assets=>ty_assets.
    DATA ls_asset TYPE zcl_pdf_studio_assets=>ty_asset.
    DATA lv_content TYPE xstring.
    DATA lv_sep TYPE string.

    lt_assets = zcl_pdf_studio_assets=>list( ).
    rv_json = `[`.
    LOOP AT lt_assets INTO ls_asset.
      "Very large files are not sent to the designer (they are still printed).
      IF ls_asset-size > 4000000.
        CONTINUE.
      ENDIF.
      TRY.
          zcl_pdf_studio_assets=>read( EXPORTING iv_asset_id = ls_asset-asset_id IMPORTING ev_content = lv_content ).
        CATCH zcx_pdf_studio.
          CONTINUE.
      ENDTRY.
      rv_json = |{ rv_json }{ lv_sep }\{"id":{ js( ls_asset-asset_id ) },"kind":{ js( ls_asset-kind ) },| &&
                |"family":{ js( ls_asset-family ) },"bold":{ bool( ls_asset-bold ) },"italic":{ bool( ls_asset-italic ) },| &&
                |"mime":{ js( ls_asset-mime ) },"description":{ js( ls_asset-description ) },| &&
                |"data":"{ cl_http_utility=>encode_x_base64( lv_content ) }"\}|.
      lv_sep = `,`.
    ENDLOOP.
    rv_json = rv_json && `]`.
  ENDMETHOD.


  METHOD display.
    DATA lt_bin TYPE solix_tab.
    DATA lv_x TYPE xstring.
    DATA lv_size TYPE i.
    DATA lv_url TYPE c LENGTH 255.
    DATA lv_frame TYPE c LENGTH 255.

    IF go_html IS NOT BOUND.
      RETURN.
    ENDIF.
    lv_x = zcl_pdf_studio_conv=>string_to_xstring( iv_html ).
    lv_size = xstrlen( lv_x ).
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer     = lv_x
      TABLES
        binary_tab = lt_bin.
    go_html->load_data(
      EXPORTING
        type         = 'text'
        subtype      = 'html'
        size         = lv_size
      IMPORTING
        assigned_url = lv_url
      CHANGING
        data_table   = lt_bin
      EXCEPTIONS
        OTHERS       = 1 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = `HTML kontrolü sayfayı yükleyemedi` iv_en = `The HTML control could not load the page` ).
    ENDIF.
    IF iv_frame IS INITIAL.
      go_html->show_url( EXPORTING url = lv_url EXCEPTIONS OTHERS = 1 ).
    ELSE.
      lv_frame = iv_frame.
      go_html->show_url( EXPORTING url = lv_url frame = lv_frame EXCEPTIONS OTHERS = 1 ).
    ENDIF.
  ENDMETHOD.


  METHOD reply.
    "The answer travels with the next display of the page (boot data, see boot_json).
    "It is never loaded into a frame: the Edge control of SAP GUI ignores the frame of
    "show_url and replaces the whole page, which wipes the designer.
    gv_reply = |\{"id":{ iv_req },"ok":{ bool( iv_ok ) },"kind":{ js( iv_kind ) },"message":{ js( iv_message ) },| &&
               |"data64":"{ b64( iv_data ) }"\}|.
    gv_reply_req = iv_req.
    "Status bar as well.
    IF iv_message IS NOT INITIAL.
      IF iv_ok = abap_true.
        MESSAGE iv_message TYPE 'S'.
      ELSE.
        MESSAGE iv_message TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD draft_write.
    DATA ls_draft TYPE ty_draft.

    IF gv_no_draft = abap_true OR gt_state IS INITIAL OR gv_view_only = abap_true.
      RETURN.
    ENDIF.
    ls_draft-form_id = gv_form.
    ls_draft-uname = sy-uname.
    GET TIME STAMP FIELD ls_draft-changed_at.
    EXPORT state = gt_state TO DATA BUFFER ls_draft-content COMPRESSION ON.
    TRY.
        MODIFY (c_draft_table) FROM ls_draft.
        COMMIT WORK.
      CATCH cx_sy_dynamic_osql_error.
        "Table not installed: the designer works without drafts.
        gv_no_draft = abap_true.
    ENDTRY.
  ENDMETHOD.


  METHOD draft_delete.
    DATA lv_form TYPE c LENGTH 30.

    IF gv_no_draft = abap_true OR gv_form IS INITIAL.
      RETURN.
    ENDIF.
    lv_form = gv_form.
    TRY.
        DELETE FROM (c_draft_table) WHERE form_id = lv_form AND uname = sy-uname.
        IF sy-subrc = 0.
          COMMIT WORK.
        ENDIF.
      CATCH cx_sy_dynamic_osql_error.
        gv_no_draft = abap_true.
    ENDTRY.
  ENDMETHOD.


  METHOD draft_read.
    DATA ls_draft TYPE ty_draft.
    DATA lv_form TYPE c LENGTH 30.

    CLEAR: et_lines, ev_changed_at.
    ev_found = abap_false.
    IF gv_no_draft = abap_true.
      RETURN.
    ENDIF.
    lv_form = gv_form.
    TRY.
        SELECT SINGLE * FROM (c_draft_table) INTO CORRESPONDING FIELDS OF ls_draft
          WHERE form_id = lv_form AND uname = sy-uname.
        IF sy-subrc <> 0 OR ls_draft-content IS INITIAL.
          RETURN.
        ENDIF.
        IMPORT state = et_lines FROM DATA BUFFER ls_draft-content.
        ev_changed_at = ls_draft-changed_at.
        ev_found = xsdbool( et_lines IS NOT INITIAL ).
      CATCH cx_sy_dynamic_osql_error.
        gv_no_draft = abap_true.
      CATCH cx_sy_import_mismatch_error.
        "A draft of an incompatible release is of no use.
        CLEAR et_lines.
    ENDTRY.
  ENDMETHOD.


  METHOD lock.
    DATA lv_tabname TYPE rstable-tabname.
    DATA lv_varkey TYPE rstable-varkey.

    CLEAR rv_user.
    lv_tabname = c_draft_table.
    CONCATENATE sy-mandt gv_form INTO lv_varkey.
    CALL FUNCTION 'ENQUEUE_E_TABLEE'
      EXPORTING
        mode_rstable   = 'E'
        tabname        = lv_tabname
        varkey         = lv_varkey
        _scope         = '1'
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc = 0.
      gv_locked = abap_true.
    ELSEIF sy-subrc = 1.
      rv_user = sy-msgv1.
    ENDIF.
  ENDMETHOD.


  METHOD unlock.
    DATA lv_tabname TYPE rstable-tabname.
    DATA lv_varkey TYPE rstable-varkey.

    IF gv_locked = abap_false.
      RETURN.
    ENDIF.
    lv_tabname = c_draft_table.
    CONCATENATE sy-mandt gv_form INTO lv_varkey.
    CALL FUNCTION 'DEQUEUE_E_TABLEE'
      EXPORTING
        mode_rstable = 'E'
        tabname      = lv_tabname
        varkey       = lv_varkey
        _scope       = '1'.
    gv_locked = abap_false.
  ENDMETHOD.


  METHOD ddic_search.
    TYPES:
      BEGIN OF ty_hit,
        name    TYPE c LENGTH 30,
        class   TYPE c LENGTH 8,
        descr   TYPE c LENGTH 60,
        package TYPE c LENGTH 30,
      END OF ty_hit.
    DATA lt_hits TYPE STANDARD TABLE OF ty_hit WITH DEFAULT KEY.
    DATA ls_hit TYPE ty_hit.
    DATA lr_class TYPE RANGE OF dd02l-tabclass.
    DATA ls_class LIKE LINE OF lr_class.
    DATA lv_pattern TYPE c LENGTH 40.
    DATA lv_package TYPE c LENGTH 40.
    DATA lv_query TYPE string.
    DATA lv_pkg TYPE string.
    DATA lv_kinds TYPE string.
    DATA lv_max TYPE i.
    DATA lv_left TYPE i.
    DATA lv_count TYPE i.
    DATA lv_kind TYPE c LENGTH 1.
    DATA lv_type TYPE c LENGTH 1.
    DATA lv_sep TYPE string.

    "There is no minimum length for the name: the row limit bounds every search (Z* is fine).
    "Without a wildcard the name starts with the text; that uses the index of the dictionary
    "tables. "Contains" is written *TEXT* and reads the whole table.
    lv_query = to_upper( condense( val = iv_query ) ).
    REPLACE ALL OCCURRENCES OF `%` IN lv_query WITH ``.
    REPLACE ALL OCCURRENCES OF `'` IN lv_query WITH ``.
    lv_pkg = to_upper( condense( val = iv_package ) ).
    REPLACE ALL OCCURRENCES OF `%` IN lv_pkg WITH ``.
    REPLACE ALL OCCURRENCES OF `'` IN lv_pkg WITH ``.

    IF lv_query IS INITIAL.
      lv_query = `%`.
    ELSEIF lv_query CA '*'.
      REPLACE ALL OCCURRENCES OF `*` IN lv_query WITH `%`.
    ELSE.
      lv_query = |{ lv_query }%|.
    ENDIF.
    lv_pattern = lv_query.
    IF lv_pkg IS INITIAL.
      lv_pkg = `%`.
    ELSEIF lv_pkg CA '*'.
      REPLACE ALL OCCURRENCES OF `*` IN lv_pkg WITH `%`.
    ELSE.
      lv_pkg = |{ lv_pkg }%|.
    ENDIF.
    lv_package = lv_pkg.

    "No object type chosen means every object type.
    lv_kinds = to_upper( iv_kinds ).
    IF lv_kinds NA 'SDVTE'.
      lv_kinds = `SDVTE`.
    ENDIF.
    lv_max = iv_max.
    IF lv_max < 1.
      lv_max = 100.
    ELSEIF lv_max > 500.
      lv_max = 500.
    ENDIF.

    ls_class-sign = 'I'.
    ls_class-option = 'EQ'.
    IF lv_kinds CA 'S'.
      ls_class-low = 'INTTAB'.
      APPEND ls_class TO lr_class.
    ENDIF.
    IF lv_kinds CA 'D'.
      ls_class-low = 'TRANSP'.
      APPEND ls_class TO lr_class.
    ENDIF.
    IF lv_kinds CA 'V'.
      ls_class-low = 'VIEW'.
      APPEND ls_class TO lr_class.
    ENDIF.

    rv_json = `[`.
    lv_left = lv_max.

    "Structures, database tables and views.
    IF lr_class IS NOT INITIAL.
      SELECT l~tabname l~tabclass t~ddtext d~devclass
        FROM dd02l AS l
        INNER JOIN tadir AS d
          ON d~obj_name = l~tabname
        LEFT OUTER JOIN dd02t AS t
          ON t~tabname = l~tabname AND t~ddlanguage = sy-langu AND t~as4local = 'A' AND t~as4vers = '0000'
        INTO TABLE lt_hits UP TO lv_left ROWS
        WHERE l~tabname LIKE lv_pattern AND l~as4local = 'A' AND l~as4vers = '0000'
          AND l~tabclass IN lr_class
          AND d~pgmid = 'R3TR' AND d~object IN ('TABL', 'VIEW') AND d~devclass LIKE lv_package
        ORDER BY l~tabname.
      LOOP AT lt_hits INTO ls_hit.
        lv_kind = 'S'.
        CASE ls_hit-class.
          WHEN 'TRANSP'.
            lv_type = 'D'.
          WHEN 'VIEW'.
            lv_type = 'V'.
          WHEN OTHERS.
            lv_type = 'S'.
        ENDCASE.
        rv_json = |{ rv_json }{ lv_sep }\{"name":{ js( ls_hit-name ) },"kind":"{ lv_kind }","type":"{ lv_type }",| &&
                  |"descr":{ js( ls_hit-descr ) },"package":{ js( ls_hit-package ) }\}|.
        lv_sep = `,`.
        lv_count = lv_count + 1.
      ENDLOOP.
    ENDIF.

    "Table types.
    lv_left = lv_max - lv_count.
    IF lv_kinds CA 'T' AND lv_left > 0.
      CLEAR lt_hits.
      SELECT l~typename l~rowkind t~ddtext d~devclass
        FROM dd40l AS l
        INNER JOIN tadir AS d
          ON d~obj_name = l~typename
        LEFT OUTER JOIN dd40t AS t
          ON t~typename = l~typename AND t~ddlanguage = sy-langu AND t~as4local = 'A'
        INTO TABLE lt_hits UP TO lv_left ROWS
        WHERE l~typename LIKE lv_pattern AND l~as4local = 'A'
          AND d~pgmid = 'R3TR' AND d~object = 'TTYP' AND d~devclass LIKE lv_package
        ORDER BY l~typename.
      LOOP AT lt_hits INTO ls_hit.
        rv_json = |{ rv_json }{ lv_sep }\{"name":{ js( ls_hit-name ) },"kind":"T","type":"T",| &&
                  |"descr":{ js( ls_hit-descr ) },"package":{ js( ls_hit-package ) }\}|.
        lv_sep = `,`.
        lv_count = lv_count + 1.
      ENDLOOP.
    ENDIF.

    "Data elements.
    lv_left = lv_max - lv_count.
    IF lv_kinds CA 'E' AND lv_left > 0.
      CLEAR lt_hits.
      SELECT l~rollname l~datatype t~ddtext d~devclass
        FROM dd04l AS l
        INNER JOIN tadir AS d
          ON d~obj_name = l~rollname
        LEFT OUTER JOIN dd04t AS t
          ON t~rollname = l~rollname AND t~ddlanguage = sy-langu AND t~as4local = 'A' AND t~as4vers = '0000'
        INTO TABLE lt_hits UP TO lv_left ROWS
        WHERE l~rollname LIKE lv_pattern AND l~as4local = 'A' AND l~as4vers = '0000'
          AND d~pgmid = 'R3TR' AND d~object = 'DTEL' AND d~devclass LIKE lv_package
        ORDER BY l~rollname.
      LOOP AT lt_hits INTO ls_hit.
        rv_json = |{ rv_json }{ lv_sep }\{"name":{ js( ls_hit-name ) },"kind":"E","type":"E",| &&
                  |"descr":{ js( ls_hit-descr ) },"package":{ js( ls_hit-package ) }\}|.
        lv_sep = `,`.
        lv_count = lv_count + 1.
      ENDLOOP.
    ENDIF.
    rv_json = rv_json && `]`.
  ENDMETHOD.


  METHOD ddic_describe.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA lv_name TYPE string.

    lv_name = to_upper( condense( val = iv_type ) ).
    IF lv_name IS INITIAL OR strlen( lv_name ) > 30.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = `DDIC tipi boş veya çok uzun.` iv_en = `The DDIC type is empty or too long.` ).
    ENDIF.
    cl_abap_typedescr=>describe_by_name(
      EXPORTING
        p_name         = lv_name
      RECEIVING
        p_descr_ref    = lo_type
      EXCEPTIONS
        type_not_found = 1
        OTHERS         = 2 ).
    IF sy-subrc <> 0 OR lo_type IS NOT BOUND.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = |DDIC tipi bulunamadı: { lv_name }| iv_en = |DDIC type not found: { lv_name }| ).
    ENDIF.
    IF lo_type->kind <> cl_abap_typedescr=>kind_struct AND lo_type->kind <> cl_abap_typedescr=>kind_table
        AND lo_type->kind <> cl_abap_typedescr=>kind_elem.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = txt( iv_tr = |{ lv_name } bir yapı, tablo tipi veya veri öğesi değil.|
                         iv_en = |{ lv_name } is not a structure, table type or data element.| ).
    ENDIF.
    gv_nodes = 0.
    rv_json = node_json( io_type = lo_type iv_name = `` iv_descr = type_text( lv_name ) iv_depth = 0 ).
  ENDMETHOD.


  METHOD type_text.
    DATA lv_name TYPE c LENGTH 30.
    DATA lv_text TYPE c LENGTH 60.

    lv_name = iv_name.
    SELECT SINGLE ddtext FROM dd02t INTO lv_text
      WHERE tabname = lv_name AND ddlanguage = sy-langu AND as4local = 'A' AND as4vers = '0000'.
    IF sy-subrc <> 0.
      SELECT SINGLE ddtext FROM dd40t INTO lv_text
        WHERE typename = lv_name AND ddlanguage = sy-langu AND as4local = 'A'.
    ENDIF.
    IF sy-subrc <> 0.
      SELECT SINGLE ddtext FROM dd04t INTO lv_text
        WHERE rollname = lv_name AND ddlanguage = sy-langu AND as4local = 'A' AND as4vers = '0000'.
    ENDIF.
    IF sy-subrc = 0.
      rv_text = lv_text.
    ENDIF.
  ENDMETHOD.


  METHOD node_json.
    DATA lo_elem TYPE REF TO cl_abap_elemdescr.
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lo_table TYPE REF TO cl_abap_tabledescr.
    DATA lo_line TYPE REF TO cl_abap_datadescr.
    DATA ls_field TYPE dfies.
    DATA lv_descr TYPE string.
    DATA lv_length TYPE i.
    DATA lv_name TYPE string.

    CLEAR rv_json.
    gv_nodes = gv_nodes + 1.
    IF gv_nodes > c_max_nodes.
      RETURN.
    ENDIF.
    IF iv_name IS NOT INITIAL.
      lv_name = |"n":{ js( iv_name ) },|.
    ENDIF.
    lv_descr = iv_descr.

    CASE io_type->kind.
      WHEN cl_abap_typedescr=>kind_elem.
        lo_elem ?= io_type.
        IF lv_descr IS INITIAL AND lo_elem->is_ddic_type( ) = abap_true.
          lo_elem->get_ddic_field(
            EXPORTING
              p_langu      = sy-langu
            RECEIVING
              p_flddescr   = ls_field
            EXCEPTIONS
              not_found    = 1
              no_ddic_type = 2
              OTHERS       = 3 ).
          IF sy-subrc = 0.
            lv_descr = ls_field-scrtext_m.
            IF lv_descr IS INITIAL.
              lv_descr = ls_field-fieldtext.
            ENDIF.
          ENDIF.
        ENDIF.
        CASE lo_elem->type_kind.
          WHEN cl_abap_typedescr=>typekind_char OR cl_abap_typedescr=>typekind_num.
            lv_length = lo_elem->length / cl_abap_char_utilities=>charsize.
          WHEN cl_abap_typedescr=>typekind_packed.
            lv_length = lo_elem->length * 2 - 1.
          WHEN OTHERS.
            lv_length = lo_elem->output_length.
        ENDCASE.
        rv_json = |\{{ lv_name }"k":"E","t":"{ lo_elem->type_kind }","l":{ lv_length },"dec":{ lo_elem->decimals },"d":{ js( lv_descr ) }\}|.

      WHEN cl_abap_typedescr=>kind_struct.
        lo_struct ?= io_type.
        rv_json = |\{{ lv_name }"k":"S","d":{ js( lv_descr ) },"c":[{ children_json( io_struct = lo_struct iv_depth = iv_depth ) }]\}|.

      WHEN cl_abap_typedescr=>kind_table.
        lo_table ?= io_type.
        lo_line = lo_table->get_table_line_type( ).
        rv_json = |\{{ lv_name }"k":"T","d":{ js( lv_descr ) },"c":[|.
        IF lo_line->kind = cl_abap_typedescr=>kind_struct.
          lo_struct ?= lo_line.
          rv_json = rv_json && children_json( io_struct = lo_struct iv_depth = iv_depth ).
        ENDIF.
        rv_json = rv_json && `]}`.
    ENDCASE.
  ENDMETHOD.


  METHOD children_json.
    DATA lt_ddic TYPE ddfields.
    DATA ls_ddic TYPE dfies.
    DATA ls_comp TYPE abap_compdescr.
    DATA lo_comp TYPE REF TO cl_abap_datadescr.
    DATA lv_node TYPE string.
    DATA lv_descr TYPE string.
    DATA lv_sep TYPE string.

    CLEAR rv_json.
    IF iv_depth >= c_max_depth.
      RETURN.
    ENDIF.
    IF io_struct->is_ddic_type( ) = abap_true.
      io_struct->get_ddic_field_list(
        EXPORTING
          p_langu                  = sy-langu
          p_including_substructres = abap_false
        RECEIVING
          p_field_list             = lt_ddic
        EXCEPTIONS
          not_found                = 1
          no_ddic_type             = 2
          OTHERS                   = 3 ).
      IF sy-subrc <> 0.
        CLEAR lt_ddic.
      ENDIF.
    ENDIF.
    LOOP AT io_struct->components INTO ls_comp.
      io_struct->get_component_type(
        EXPORTING
          p_name                 = ls_comp-name
        RECEIVING
          p_descr_ref            = lo_comp
        EXCEPTIONS
          component_not_found    = 1
          unsupported_input_type = 2
          OTHERS                 = 3 ).
      IF sy-subrc <> 0 OR lo_comp IS NOT BOUND.
        CONTINUE.
      ENDIF.
      CLEAR lv_descr.
      READ TABLE lt_ddic INTO ls_ddic WITH KEY fieldname = ls_comp-name.
      IF sy-subrc = 0.
        lv_descr = ls_ddic-scrtext_m.
        IF lv_descr IS INITIAL.
          lv_descr = ls_ddic-fieldtext.
        ENDIF.
      ENDIF.
      lv_node = node_json( io_type = lo_comp iv_name = |{ ls_comp-name }| iv_descr = lv_descr iv_depth = iv_depth + 1 ).
      IF lv_node IS NOT INITIAL.
        rv_json = |{ rv_json }{ lv_sep }{ lv_node }|.
        lv_sep = `,`.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD parse_envelope.
    DATA lt_rows TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_row TYPE string.
    DATA lv_value64 TYPE string.
    DATA ls_line TYPE ty_line.

    IF iv_payload IS INITIAL.
      RETURN.
    ENDIF.
    SPLIT zcl_pdf_studio_conv=>base64_decode( iv_payload ) AT cl_abap_char_utilities=>newline INTO TABLE lt_rows.
    LOOP AT lt_rows INTO lv_row.
      IF lv_row IS INITIAL.
        CONTINUE.
      ENDIF.
      CLEAR ls_line.
      CLEAR lv_value64.
      SPLIT lv_row AT cl_abap_char_utilities=>horizontal_tab INTO ls_line-key ls_line-arg lv_value64.
      IF lv_value64 IS NOT INITIAL.
        ls_line-value = zcl_pdf_studio_conv=>base64_decode( lv_value64 ).
      ENDIF.
      APPEND ls_line TO rt_lines.
    ENDLOOP.
  ENDMETHOD.


  METHOD value_of.
    DATA ls_line TYPE ty_line.

    READ TABLE it_lines INTO ls_line WITH KEY key = `META` arg = iv_arg.
    IF sy-subrc = 0.
      rv_value = ls_line-value.
    ENDIF.
  ENDMETHOD.


  METHOD set_value.
    DATA ls_line TYPE ty_line.
    FIELD-SYMBOLS <line> TYPE ty_line.

    READ TABLE gt_state ASSIGNING <line> WITH KEY key = `META` arg = iv_arg.
    IF sy-subrc = 0.
      <line>-value = iv_value.
    ELSEIF iv_value IS NOT INITIAL.
      ls_line-key = `META`.
      ls_line-arg = iv_arg.
      ls_line-value = iv_value.
      APPEND ls_line TO gt_state.
    ENDIF.
  ENDMETHOD.


  METHOD template_from_lines.
    DATA lv_number TYPE string.

    rs_template-form_id = to_upper( value_of( it_lines = it_lines iv_arg = `form_id` ) ).
    rs_template-html_content = value_of( it_lines = it_lines iv_arg = `html` ).
    rs_template-css_content = value_of( it_lines = it_lines iv_arg = `css` ).
    rs_template-header_html = value_of( it_lines = it_lines iv_arg = `header` ).
    rs_template-footer_html = value_of( it_lines = it_lines iv_arg = `footer` ).
    rs_template-sample_json = value_of( it_lines = it_lines iv_arg = `sample` ).
    rs_template-page_size = to_upper( value_of( it_lines = it_lines iv_arg = `page_size` ) ).
    rs_template-orientation = to_upper( value_of( it_lines = it_lines iv_arg = `orientation` ) ).
    IF rs_template-page_size IS INITIAL.
      rs_template-page_size = `A4`.
    ENDIF.
    IF rs_template-orientation IS INITIAL.
      rs_template-orientation = `P`.
    ENDIF.

    lv_number = value_of( it_lines = it_lines iv_arg = `margin_top` ).
    IF lv_number CO '0123456789' AND lv_number IS NOT INITIAL.
      rs_template-margin_top = lv_number.
    ENDIF.
    lv_number = value_of( it_lines = it_lines iv_arg = `margin_right` ).
    IF lv_number CO '0123456789' AND lv_number IS NOT INITIAL.
      rs_template-margin_right = lv_number.
    ENDIF.
    lv_number = value_of( it_lines = it_lines iv_arg = `margin_bottom` ).
    IF lv_number CO '0123456789' AND lv_number IS NOT INITIAL.
      rs_template-margin_bottom = lv_number.
    ENDIF.
    lv_number = value_of( it_lines = it_lines iv_arg = `margin_left` ).
    IF lv_number CO '0123456789' AND lv_number IS NOT INITIAL.
      rs_template-margin_left = lv_number.
    ENDIF.
  ENDMETHOD.


  METHOD studio_payload.
    DATA lv_start TYPE i.
    DATA lv_end TYPE i.

    lv_start = find( val = iv_html sub = c_studio_mark ).
    IF lv_start < 0.
      RETURN.
    ENDIF.
    lv_start = lv_start + strlen( c_studio_mark ).
    lv_end = find( val = iv_html sub = `-->` off = lv_start ).
    IF lv_end <= lv_start.
      RETURN.
    ENDIF.
    rv_b64 = substring( val = iv_html off = lv_start len = lv_end - lv_start ).
  ENDMETHOD.


  METHOD payload_of.
    DATA lv_pos TYPE i.

    rv_b64 = iv_body.
    lv_pos = find( val = rv_b64 sub = `payload=` ).
    IF lv_pos >= 0.
      rv_b64 = substring( val = rv_b64 off = lv_pos + 8 ).
    ENDIF.
    lv_pos = find( val = rv_b64 sub = `&` ).
    IF lv_pos >= 0.
      rv_b64 = substring( val = rv_b64 len = lv_pos ).
    ENDIF.
    "Form encoding: "+", "/" and "=" arrive as %2B, %2F, %3D. Base64 has no spaces.
    IF rv_b64 CS '%'.
      rv_b64 = cl_http_utility=>unescape_url( rv_b64 ).
    ENDIF.
    CONDENSE rv_b64 NO-GAPS.
  ENDMETHOD.


  METHOD post_to_string.
    DATA lo_line TYPE REF TO cl_abap_datadescr.
    DATA lv_x TYPE xstring.
    FIELD-SYMBOLS <line> TYPE any.

    IF it_post IS INITIAL.
      RETURN.
    ENDIF.
    lo_line = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( it_post ) )->get_table_line_type( ).
    IF lo_line->type_kind = cl_abap_typedescr=>typekind_hex.
      LOOP AT it_post ASSIGNING <line>.
        CONCATENATE lv_x <line> INTO lv_x IN BYTE MODE.
      ENDLOOP.
      rv_text = zcl_pdf_studio_conv=>xstring_to_string( lv_x ).
    ELSE.
      "Char lines are filled to their full length; the payload itself has no blanks.
      LOOP AT it_post ASSIGNING <line>.
        rv_text = rv_text && <line>.
      ENDLOOP.
    ENDIF.
    "Hex lines can end with zero bytes.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>minchar IN rv_text WITH ``.
  ENDMETHOD.


  METHOD b64.
    IF iv_text IS INITIAL.
      RETURN.
    ENDIF.
    TRY.
        rv_b64 = cl_http_utility=>encode_x_base64( zcl_pdf_studio_conv=>string_to_xstring( iv_text ) ).
      CATCH zcx_pdf_studio.
        CLEAR rv_b64.
    ENDTRY.
  ENDMETHOD.


  METHOD js.
    rv_json = zcl_pdf_studio_http=>json_string( iv_text ).
  ENDMETHOD.


  METHOD bool.
    IF iv_flag = abap_true.
      rv_json = `true`.
    ELSE.
      rv_json = `false`.
    ENDIF.
  ENDMETHOD.

  METHOD prefs_read.
    SELECT SINGLE settings FROM zpdf_studio_user INTO rv_json WHERE uname = sy-uname.
    IF sy-subrc <> 0.
      CLEAR rv_json.
    ENDIF.
  ENDMETHOD.

  METHOD prefs_write.
    DATA ls_user TYPE zpdf_studio_user.
    DATA lv_json TYPE string.

    "A small JSON object and nothing else is stored.
    lv_json = condense( val = iv_json ).
    IF lv_json IS INITIAL OR strlen( lv_json ) > 2000 OR lv_json(1) <> '{'.
      RETURN.
    ENDIF.
    ls_user-uname = sy-uname.
    GET TIME STAMP FIELD ls_user-changed_at.
    ls_user-settings = lv_json.
    MODIFY zpdf_studio_user FROM ls_user.
    COMMIT WORK.
  ENDMETHOD.

  METHOD set_title.
    DATA lv_title TYPE c LENGTH 70.
    lv_title = iv_title.
    sy-title = lv_title.
    SET TITLEBAR '220' OF PROGRAM 'SAPLSE16N' WITH lv_title.
  ENDMETHOD.
ENDCLASS.
