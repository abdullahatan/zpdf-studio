*&---------------------------------------------------------------------*
*& Report ZPDF_STUDIO_ASSETS
*&---------------------------------------------------------------------*
*& ZPDF Studio logo and font store (like SE78 graphics and SE73 TrueType
*& fonts): upload logos / images (PNG, JPEG) and TrueType fonts from the
*& PC, list and preview them, download, delete and add them to a
*& transport request. Images are used in forms as src="asset:<ID>",
*& fonts by their family name.
*&
*& All texts are set at runtime: Turkish for a Turkish logon, English for
*& every other logon language (no text pool translation is needed).
*&---------------------------------------------------------------------*
REPORT zpdf_studio_assets.

SELECTION-SCREEN BEGIN OF BLOCK act WITH FRAME TITLE gv_tact.
PARAMETERS r_list RADIOBUTTON GROUP act DEFAULT 'X' USER-COMMAND act.
PARAMETERS r_upl RADIOBUTTON GROUP act.
PARAMETERS r_down RADIOBUTTON GROUP act.
PARAMETERS r_del RADIOBUTTON GROUP act.
PARAMETERS r_tran RADIOBUTTON GROUP act.
SELECTION-SCREEN END OF BLOCK act.

SELECTION-SCREEN BEGIN OF BLOCK ast WITH FRAME TITLE gv_tast.
PARAMETERS p_id TYPE c LENGTH 30.
SELECT-OPTIONS s_ids FOR p_id NO INTERVALS.
PARAMETERS p_kind TYPE c LENGTH 10 AS LISTBOX VISIBLE LENGTH 20.
PARAMETERS p_file TYPE string LOWER CASE VISIBLE LENGTH 60.
PARAMETERS p_desc TYPE c LENGTH 80 LOWER CASE.
SELECTION-SCREEN END OF BLOCK ast.

SELECTION-SCREEN BEGIN OF BLOCK fnt WITH FRAME TITLE gv_tfnt.
PARAMETERS p_family TYPE c LENGTH 60 LOWER CASE.
PARAMETERS p_bold AS CHECKBOX.
PARAMETERS p_ital AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK fnt.

CLASS lcl_app DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS t
      IMPORTING iv_tr          TYPE string
                iv_en          TYPE string
      RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS init.
    CLASS-METHODS texts.
    CLASS-METHODS run.
  PRIVATE SECTION.
    CLASS-DATA gt_assets TYPE zcl_pdf_studio_assets=>ty_assets.
    CLASS-DATA go_box TYPE REF TO cl_gui_dialogbox_container.
    CLASS-DATA go_view TYPE REF TO cl_gui_html_viewer.

    CLASS-METHODS upload RAISING zcx_pdf_studio.
    CLASS-METHODS download RAISING zcx_pdf_studio.
    CLASS-METHODS show_list.
    CLASS-METHODS column
      IMPORTING io_columns TYPE REF TO cl_salv_columns_table
                iv_name    TYPE lvc_fname
                iv_text    TYPE string.
    CLASS-METHODS selected_ids
      RETURNING VALUE(rt_ids) TYPE zcl_pdf_studio_assets=>ty_ids.
    "! Preview of a logo / image (or a sample text in a font) in a window over the list.
    CLASS-METHODS preview
      IMPORTING iv_id TYPE string
      RAISING   zcx_pdf_studio.
    CLASS-METHODS load
      IMPORTING iv_data       TYPE xstring
                iv_type       TYPE c
                iv_subtype    TYPE c
      RETURNING VALUE(rv_url) TYPE string.
    CLASS-METHODS esc
      IMPORTING iv_text        TYPE csequence
      RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS on_double_click
      FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row.
    CLASS-METHODS on_close
      FOR EVENT close OF cl_gui_dialogbox_container.
ENDCLASS.

CLASS lcl_app IMPLEMENTATION.

  METHOD t.
    rv_text = zcl_pdf_studio_ui=>txt( iv_tr = iv_tr iv_en = iv_en ).
  ENDMETHOD.

  METHOD init.
    DATA lt_values TYPE vrm_values.
    DATA ls_value TYPE vrm_value.

    texts( ).
    ls_value-key = ''.
    ls_value-text = t( iv_tr = `Tümü` iv_en = `All` ).
    APPEND ls_value TO lt_values.
    ls_value-key = 'IMAGE'.
    ls_value-text = t( iv_tr = `Logolar / resimler` iv_en = `Logos / images` ).
    APPEND ls_value TO lt_values.
    ls_value-key = 'FONT'.
    ls_value-text = t( iv_tr = `Fontlar` iv_en = `Fonts` ).
    APPEND ls_value TO lt_values.
    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id     = 'P_KIND'
        values = lt_values
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
  ENDMETHOD.

  METHOD texts.
    "Titles and field labels in the logon language (Turkish, otherwise English).
    zcl_pdf_studio_ui=>set_title( t( iv_tr = `ZPDF Studio - logo ve font deposu` iv_en = `ZPDF Studio - logos and fonts` ) ).
    gv_tact = t( iv_tr = `İşlem` iv_en = `Action` ).
    gv_tast = t( iv_tr = `Logo / font` iv_en = `Logo / font` ).
    gv_tfnt = t( iv_tr = `Font (yalnızca TrueType yüklerken)` iv_en = `Font (only when a TrueType file is uploaded)` ).
    %_r_list_%_app_%-text = t( iv_tr = `Listele ve önizle` iv_en = `List and preview` ).
    %_r_upl_%_app_%-text = t( iv_tr = `PC'den yükle` iv_en = `Upload from the PC` ).
    %_r_down_%_app_%-text = t( iv_tr = `PC'ye indir` iv_en = `Download to the PC` ).
    %_r_del_%_app_%-text = t( iv_tr = `Sil` iv_en = `Delete` ).
    %_r_tran_%_app_%-text = t( iv_tr = `Transport talebine ekle` iv_en = `Add to a transport request` ).
    %_p_id_%_app_%-text = t( iv_tr = `Ad (A-Z, 0-9, _)` iv_en = `ID (A-Z, 0-9, _)` ).
    %_s_ids_%_app_%-text = t( iv_tr = `Adlar (liste / transport)` iv_en = `IDs (list / transport)` ).
    %_p_kind_%_app_%-text = t( iv_tr = `Tür (liste)` iv_en = `Kind (list)` ).
    %_p_file_%_app_%-text = t( iv_tr = `Dosya (PNG, JPEG, TTF)` iv_en = `File (PNG, JPEG, TTF)` ).
    %_p_desc_%_app_%-text = t( iv_tr = `Açıklama` iv_en = `Description` ).
    %_p_family_%_app_%-text = t( iv_tr = `Font ailesi` iv_en = `Font family` ).
    %_p_bold_%_app_%-text = t( iv_tr = `Kalın` iv_en = `Bold` ).
    %_p_ital_%_app_%-text = t( iv_tr = `İtalik` iv_en = `Italic` ).
  ENDMETHOD.

  METHOD selected_ids.
    DATA lt_assets TYPE zcl_pdf_studio_assets=>ty_assets.
    DATA ls_asset TYPE zcl_pdf_studio_assets=>ty_asset.
    DATA lv_id TYPE c LENGTH 30.
    IF p_id IS NOT INITIAL.
      APPEND to_upper( p_id ) TO rt_ids.
    ENDIF.
    IF s_ids[] IS NOT INITIAL.
      lt_assets = zcl_pdf_studio_assets=>list( ).
      LOOP AT lt_assets INTO ls_asset.
        lv_id = ls_asset-asset_id.
        IF lv_id IN s_ids AND NOT line_exists( rt_ids[ table_line = ls_asset-asset_id ] ).
          APPEND ls_asset-asset_id TO rt_ids.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD upload.
    DATA lt_bin TYPE solix_tab.
    DATA lv_length TYPE i.
    DATA lv_content TYPE xstring.
    DATA ls_asset TYPE zcl_pdf_studio_assets=>ty_asset.
    DATA lv_request TYPE trkorr.
    DATA lv_name TYPE string.

    IF p_id IS INITIAL OR p_file IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Enter an asset ID and choose a file'.
    ENDIF.
    cl_gui_frontend_services=>gui_upload(
      EXPORTING
        filename   = p_file
        filetype   = 'BIN'
      IMPORTING
        filelength = lv_length
      CHANGING
        data_tab   = lt_bin
      EXCEPTIONS
        OTHERS     = 1 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |File { p_file } could not be read|.
    ENDIF.
    lv_content = cl_bcs_convert=>solix_to_xstring( it_solix = lt_bin iv_size = lv_length ).
    lv_name = p_file.
    REPLACE ALL OCCURRENCES OF REGEX '^.*[\\/]' IN lv_name WITH ''.
    ls_asset-asset_id = p_id.
    ls_asset-filename = lv_name.
    ls_asset-description = p_desc.
    ls_asset-family = p_family.
    ls_asset-bold = p_bold.
    ls_asset-italic = p_ital.
    lv_request = zcl_pdf_studio_assets=>save( is_asset = ls_asset iv_content = lv_content ).
    IF lv_request IS INITIAL.
      MESSAGE t( iv_tr = |{ to_upper( p_id ) } kaydedildi.| iv_en = |{ to_upper( p_id ) } saved.| ) TYPE 'S'.
    ELSE.
      MESSAGE t( iv_tr = |{ to_upper( p_id ) } kaydedildi ve { lv_request } talebine eklendi.|
                 iv_en = |{ to_upper( p_id ) } saved and recorded in request { lv_request }.| ) TYPE 'S'.
    ENDIF.
  ENDMETHOD.

  METHOD download.
    DATA ls_asset TYPE zcl_pdf_studio_assets=>ty_asset.
    DATA lv_content TYPE xstring.
    DATA lt_bin TYPE solix_tab.
    DATA lv_file TYPE string.
    DATA lv_path TYPE string.
    DATA lv_full TYPE string.
    DATA lv_action TYPE i.

    zcl_pdf_studio_assets=>read( EXPORTING iv_asset_id = p_id IMPORTING es_asset = ls_asset ev_content = lv_content ).
    lv_file = ls_asset-filename.
    IF lv_file IS INITIAL.
      lv_file = ls_asset-asset_id.
    ENDIF.
    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING
        default_file_name = lv_file
      CHANGING
        filename          = lv_file
        path              = lv_path
        fullpath          = lv_full
        user_action       = lv_action
      EXCEPTIONS
        OTHERS            = 1 ).
    IF sy-subrc <> 0 OR lv_action <> cl_gui_frontend_services=>action_ok.
      RETURN.
    ENDIF.
    lt_bin = cl_bcs_convert=>xstring_to_solix( lv_content ).
    cl_gui_frontend_services=>gui_download(
      EXPORTING
        filename     = lv_full
        filetype     = 'BIN'
        bin_filesize = xstrlen( lv_content )
      CHANGING
        data_tab     = lt_bin
      EXCEPTIONS
        OTHERS       = 1 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |File { lv_full } could not be written|.
    ENDIF.
    MESSAGE t( iv_tr = |{ to_upper( p_id ) } indirildi: { lv_full }| iv_en = |{ to_upper( p_id ) } downloaded: { lv_full }| ) TYPE 'S'.
  ENDMETHOD.

  METHOD column.
    DATA lo_column TYPE REF TO cl_salv_column.
    DATA lv_short TYPE scrtext_s.
    DATA lv_medium TYPE scrtext_m.
    DATA lv_long TYPE scrtext_l.
    TRY.
        lo_column = io_columns->get_column( iv_name ).
      CATCH cx_salv_not_found.
        RETURN.
    ENDTRY.
    lv_short = iv_text.
    lv_medium = iv_text.
    lv_long = iv_text.
    lo_column->set_short_text( lv_short ).
    lo_column->set_medium_text( lv_medium ).
    lo_column->set_long_text( lv_long ).
  ENDMETHOD.

  METHOD show_list.
    DATA ls_asset TYPE zcl_pdf_studio_assets=>ty_asset.
    DATA lo_alv TYPE REF TO cl_salv_table.
    DATA lo_columns TYPE REF TO cl_salv_columns_table.
    DATA lo_events TYPE REF TO cl_salv_events_table.
    DATA lx_salv TYPE REF TO cx_salv_msg.
    DATA lv_id TYPE c LENGTH 30.
    DATA lv_header TYPE lvc_title.

    gt_assets = zcl_pdf_studio_assets=>list( p_kind ).
    IF s_ids[] IS NOT INITIAL.
      LOOP AT gt_assets INTO ls_asset.
        lv_id = ls_asset-asset_id.
        IF lv_id NOT IN s_ids.
          DELETE gt_assets.
        ENDIF.
      ENDLOOP.
    ENDIF.
    IF gt_assets IS INITIAL.
      MESSAGE t( iv_tr = `Seçime uyan logo veya font yok.` iv_en = `No logo or font matches the selection.` ) TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv CHANGING t_table = gt_assets ).
        lo_alv->get_functions( )->set_default( abap_true ).
        lo_columns = lo_alv->get_columns( ).
        lo_columns->set_optimize( abap_true ).
        column( io_columns = lo_columns iv_name = 'ASSET_ID' iv_text = t( iv_tr = `Ad` iv_en = `ID` ) ).
        column( io_columns = lo_columns iv_name = 'KIND' iv_text = t( iv_tr = `Tür` iv_en = `Kind` ) ).
        column( io_columns = lo_columns iv_name = 'FAMILY' iv_text = t( iv_tr = `Font ailesi` iv_en = `Font family` ) ).
        column( io_columns = lo_columns iv_name = 'BOLD' iv_text = t( iv_tr = `Kalın` iv_en = `Bold` ) ).
        column( io_columns = lo_columns iv_name = 'ITALIC' iv_text = t( iv_tr = `İtalik` iv_en = `Italic` ) ).
        column( io_columns = lo_columns iv_name = 'MIME' iv_text = t( iv_tr = `Dosya tipi` iv_en = `File type` ) ).
        column( io_columns = lo_columns iv_name = 'FILENAME' iv_text = t( iv_tr = `Dosya adı` iv_en = `File name` ) ).
        column( io_columns = lo_columns iv_name = 'DESCRIPTION' iv_text = t( iv_tr = `Açıklama` iv_en = `Description` ) ).
        column( io_columns = lo_columns iv_name = 'CHANGED_BY' iv_text = t( iv_tr = `Değiştiren` iv_en = `Changed by` ) ).
        column( io_columns = lo_columns iv_name = 'CHANGED_AT' iv_text = t( iv_tr = `Değişiklik zamanı` iv_en = `Changed at` ) ).
        column( io_columns = lo_columns iv_name = 'SIZE' iv_text = t( iv_tr = `Boyut (bayt)` iv_en = `Size (bytes)` ) ).
        lv_header = t( iv_tr = `ZPDF Studio - logo ve font deposu (önizleme için satıra çift tıklayın)`
                       iv_en = `ZPDF Studio - logos and fonts (double-click a row for a preview)` ).
        lo_alv->get_display_settings( )->set_list_header( lv_header ).
        lo_events = lo_alv->get_event( ).
        SET HANDLER on_double_click FOR lo_events.
        lo_alv->display( ).
      CATCH cx_salv_msg INTO lx_salv.
        MESSAGE lx_salv->get_text( ) TYPE 'I'.
    ENDTRY.
  ENDMETHOD.

  METHOD on_double_click.
    DATA ls_asset TYPE zcl_pdf_studio_assets=>ty_asset.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.
    READ TABLE gt_assets INTO ls_asset INDEX row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    TRY.
        preview( ls_asset-asset_id ).
      CATCH zcx_pdf_studio INTO lx_pdf.
        MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD on_close.
    IF go_view IS BOUND.
      go_view->free( EXCEPTIONS OTHERS = 1 ).
      CLEAR go_view.
    ENDIF.
    IF go_box IS BOUND.
      go_box->free( EXCEPTIONS OTHERS = 1 ).
      CLEAR go_box.
    ENDIF.
  ENDMETHOD.

  METHOD esc.
    rv_text = escape( val = iv_text format = cl_abap_format=>e_html_text ).
  ENDMETHOD.

  METHOD load.
    "Loads data into the HTML control and returns its URL (images: binary, the page: UTF-8).
    DATA lt_bin TYPE solix_tab.
    DATA lv_url TYPE c LENGTH 255.
    lt_bin = cl_bcs_convert=>xstring_to_solix( iv_data ).
    go_view->load_data(
      EXPORTING
        type         = iv_type
        subtype      = iv_subtype
        size         = xstrlen( iv_data )
      IMPORTING
        assigned_url = lv_url
      CHANGING
        data_table   = lt_bin
      EXCEPTIONS
        OTHERS       = 1 ).
    rv_url = lv_url.
  ENDMETHOD.

  METHOD preview.
    DATA ls_asset TYPE zcl_pdf_studio_assets=>ty_asset.
    DATA lv_content TYPE xstring.
    DATA lv_html TYPE string.
    DATA lv_body TYPE string.
    DATA lv_url TYPE string.
    DATA lv_page TYPE c LENGTH 255.
    DATA lv_caption TYPE c LENGTH 80.
    DATA lv_subtype TYPE c LENGTH 10.
    DATA lv_style TYPE string.

    zcl_pdf_studio_assets=>read( EXPORTING iv_asset_id = iv_id IMPORTING es_asset = ls_asset ev_content = lv_content ).
    on_close( ).
    lv_caption = |{ ls_asset-asset_id } - { t( iv_tr = `önizleme` iv_en = `preview` ) }|.
    CREATE OBJECT go_box
      EXPORTING
        width   = 640
        height  = 440
        top     = 40
        left    = 160
        caption = lv_caption
      EXCEPTIONS
        OTHERS  = 1.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = t( iv_tr = `Önizleme penceresi açılamadı.` iv_en = `The preview window could not be opened.` ).
    ENDIF.
    SET HANDLER on_close FOR go_box.
    CREATE OBJECT go_view
      EXPORTING
        parent = go_box
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc <> 0.
      on_close( ).
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = t( iv_tr = `HTML kontrolü oluşturulamadı` iv_en = `The HTML control could not be created` ).
    ENDIF.

    IF ls_asset-kind = zcl_pdf_studio_assets=>c_image.
      lv_subtype = COND #( WHEN ls_asset-mime CS 'png' THEN 'png' ELSE 'jpeg' ).
      lv_url = load( iv_data = lv_content iv_type = 'image' iv_subtype = lv_subtype ).
      "A checkerboard shows which parts of a logo are transparent.
      lv_body = |<div class="stage"><img src="{ lv_url }" alt=""></div>|.
    ELSE.
      "A font is shown with a sample text in that font (the page loads it from the data).
      lv_style = |@font-face\{font-family:'zpdfpreview';src:url(data:font/ttf;base64,{ cl_http_utility=>encode_x_base64( lv_content ) }) format('truetype');\}|.
      lv_body = |<div class="font" style="font-family:'zpdfpreview';{ COND #( WHEN ls_asset-bold = abap_true THEN `font-weight:bold;` ) }| &&
                |{ COND #( WHEN ls_asset-italic = abap_true THEN `font-style:italic;` ) }">| &&
                |<div style="font-size:34px">Aa Bb Çç Ğğ İı Öö Şş Üü</div>| &&
                |<div style="font-size:22px">ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ<br>abcçdefgğhıijklmnoöprsştuüvyz<br>0123456789 ₺ € $ % &amp; @</div>| &&
                |<div style="font-size:14px">{ esc( t( iv_tr = `Pijamalı hasta yağız şoföre çabucak güvendi.` iv_en = `The quick brown fox jumps over the lazy dog.` ) ) }</div></div>|.
    ENDIF.
    lv_html = |<!doctype html><html><head><meta charset="utf-8"><style>{ lv_style }| &&
              |body\{margin:0;font:13px "Segoe UI",Arial,sans-serif;color:#1f2933;background:#f4f6f8\}| &&
              |.info\{padding:8px 12px;background:#fff;border-bottom:1px solid #d9dee5\}.info b\{font-size:14px\}.info span\{color:#52606d\}| &&
              |.stage\{margin:12px;height:330px;display:flex;align-items:center;justify-content:center;border:1px solid #d9dee5;| &&
              |background-color:#fff;background-image:linear-gradient(45deg,#eef1f4 25%,transparent 25%),linear-gradient(-45deg,#eef1f4 25%,transparent 25%),| &&
              |linear-gradient(45deg,transparent 75%,#eef1f4 75%),linear-gradient(-45deg,transparent 75%,#eef1f4 75%);| &&
              |background-size:16px 16px;background-position:0 0,0 8px,8px -8px,-8px 0\}| &&
              |.stage img\{max-width:96%;max-height:96%\}.font\{margin:12px;padding:14px;background:#fff;border:1px solid #d9dee5;line-height:1.35\}.font div\{margin-bottom:10px\}| &&
              |</style></head><body><div class="info"><b>{ esc( ls_asset-asset_id ) }</b> &nbsp; <span>{ esc( ls_asset-mime ) } · | &&
              |{ ls_asset-size } { t( iv_tr = `bayt` iv_en = `bytes` ) } · { esc( ls_asset-filename ) }</span><br><span>{ esc( ls_asset-description ) }</span></div>| &&
              |{ lv_body }</body></html>|.
    lv_page = load( iv_data = zcl_pdf_studio_conv=>string_to_xstring( lv_html ) iv_type = 'text' iv_subtype = 'html' ).
    go_view->show_url( EXPORTING url = lv_page EXCEPTIONS OTHERS = 1 ).
  ENDMETHOD.

  METHOD run.
    DATA lv_request TYPE trkorr.
    DATA lt_ids TYPE zcl_pdf_studio_assets=>ty_ids.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.
    TRY.
        CASE abap_true.
          WHEN r_upl.
            upload( ).
          WHEN r_down.
            download( ).
          WHEN r_del.
            zcl_pdf_studio_assets=>delete( p_id ).
            MESSAGE t( iv_tr = |{ to_upper( p_id ) } silindi.| iv_en = |{ to_upper( p_id ) } deleted.| ) TYPE 'S'.
          WHEN r_tran.
            lt_ids = selected_ids( ).
            lv_request = zcl_pdf_studio_assets=>transport( lt_ids ).
            MESSAGE t( iv_tr = |{ lines( lt_ids ) } logo/font { lv_request } talebine eklendi.|
                       iv_en = |{ lines( lt_ids ) } logos/fonts added to request { lv_request }.| ) TYPE 'S'.
          WHEN r_list.
            show_list( ).
        ENDCASE.
      CATCH zcx_pdf_studio INTO lx_pdf.
        MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

INITIALIZATION.
  lcl_app=>init( ).

AT SELECTION-SCREEN OUTPUT.
  lcl_app=>texts( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  DATA gt_files TYPE filetable.
  DATA gv_rc TYPE i.
  DATA gv_dialog TYPE string.
  DATA gv_filter TYPE string.
  gv_dialog = lcl_app=>t( iv_tr = `Logo / resim (PNG, JPEG) veya TrueType font (.ttf)` iv_en = `Logo / image (PNG, JPEG) or TrueType font (.ttf)` ).
  gv_filter = lcl_app=>t( iv_tr = `Resimler ve fontlar (*.png;*.jpg;*.jpeg;*.ttf)|*.png;*.jpg;*.jpeg;*.ttf|Tüm dosyalar (*.*)|*.*`
                          iv_en = `Images and fonts (*.png;*.jpg;*.jpeg;*.ttf)|*.png;*.jpg;*.jpeg;*.ttf|All files (*.*)|*.*` ).
  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title = gv_dialog
      file_filter  = gv_filter
    CHANGING
      file_table   = gt_files
      rc           = gv_rc
    EXCEPTIONS
      OTHERS       = 1 ).
  IF sy-subrc = 0 AND gv_rc = 1.
    READ TABLE gt_files INDEX 1 INTO p_file.
  ENDIF.

START-OF-SELECTION.
  lcl_app=>run( ).
