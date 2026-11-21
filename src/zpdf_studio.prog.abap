*&---------------------------------------------------------------------*
*& Report ZPDF_STUDIO
*&---------------------------------------------------------------------*
*& ZPDF Studio: PDF form designer for SAP GUI (entry screen like SFP).
*&
*& Form name + Display / Change / Create. The designer page (designer.html)
*& lives at a fixed place in the MIME repository; "Install designer" uploads
*& it from the PC. Forms are stored in ZPDF_STUDIO_FORM (versions, transport)
*& and printed with ZCL_PDF_STUDIO_API. Logos and fonts: ZPDF_STUDIO_ASSETS.
*&
*& GUI status ZPDF_DESIGNER (SE41, optional): the designer screen without
*& the menus Program / Edit / Goto. Application toolbar FC01, FC02, FC03
*& with the dynamic texts SSCRFIELDS-FUNCTXT_01..03; Back = CBAC,
*& Exit = CEND, Cancel = CCAN (function type E). Without it the standard
*& status of the selection screen is used.
*&---------------------------------------------------------------------*
REPORT zpdf_studio.

TABLES sscrfields.

SELECTION-SCREEN BEGIN OF BLOCK frm WITH FRAME TITLE gv_tfrm.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(18) gv_lform FOR FIELD p_form.
PARAMETERS p_form TYPE c LENGTH 30.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON 1(22) gv_bdisp USER-COMMAND disp.
SELECTION-SCREEN PUSHBUTTON 25(22) gv_bchng USER-COMMAND chng.
SELECTION-SCREEN PUSHBUTTON 49(22) gv_bcrea USER-COMMAND crea.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK frm.
SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN FUNCTION KEY 2.

"Empty screen that carries the HTML control of the designer.
SELECTION-SCREEN BEGIN OF SCREEN 1001 TITLE gv_title.
SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN FUNCTION KEY 2.
SELECTION-SCREEN FUNCTION KEY 3.
SELECTION-SCREEN END OF SCREEN 1001.

CLASS lcl_app DEFINITION FINAL.
  PUBLIC SECTION.
    CONSTANTS c_display TYPE c LENGTH 1 VALUE 'D'.
    CONSTANTS c_change TYPE c LENGTH 1 VALUE 'C'.
    CONSTANTS c_create TYPE c LENGTH 1 VALUE 'N'.
    CONSTANTS c_any TYPE c LENGTH 1 VALUE 'X'.
    "Own GUI status of the designer screen: no menus (created in SE41).
    CONSTANTS c_status TYPE sy-pfkey VALUE 'ZPDF_DESIGNER'.
    TYPES ty_codes TYPE STANDARD TABLE OF sy-ucomm WITH EMPTY KEY.

    CLASS-METHODS texts.
    CLASS-METHODS entry_pbo.
    CLASS-METHODS designer_pbo.
    CLASS-METHODS entry_command
      IMPORTING iv_ucomm TYPE sy-ucomm.
    CLASS-METHODS start
      IMPORTING iv_mode TYPE c.
    CLASS-METHODS install
      RETURNING VALUE(rv_ok) TYPE abap_bool.
    CLASS-METHODS f4_form.

  PRIVATE SECTION.
    CLASS-METHODS button
      IMPORTING iv_icon        TYPE icon_d
                iv_text        TYPE string
      RETURNING VALUE(rs_text) TYPE smp_dyntxt.
    CLASS-METHODS exclude
      IMPORTING it_codes  TYPE ty_codes
                iv_status TYPE sy-pfkey OPTIONAL.
    CLASS-METHODS own_status
      RETURNING VALUE(rv_yes) TYPE abap_bool.
ENDCLASS.

CLASS lcl_app IMPLEMENTATION.

  METHOD texts.
    gv_tfrm = zcl_pdf_studio_ui=>txt( iv_tr = `PDF formu` iv_en = `PDF form` ).
    gv_lform = zcl_pdf_studio_ui=>txt( iv_tr = `Form` iv_en = `Form` ).
    gv_bdisp = |{ icon_display } { zcl_pdf_studio_ui=>txt( iv_tr = `Görüntüle` iv_en = `Display` ) }|.
    gv_bchng = |{ icon_change } { zcl_pdf_studio_ui=>txt( iv_tr = `Değiştir` iv_en = `Change` ) }|.
    gv_bcrea = |{ icon_create } { zcl_pdf_studio_ui=>txt( iv_tr = `Yarat` iv_en = `Create` ) }|.
  ENDMETHOD.

  METHOD button.
    rs_text-icon_id = iv_icon.
    rs_text-icon_text = iv_text.
    rs_text-text = iv_text.
    rs_text-quickinfo = iv_text.
  ENDMETHOD.

  METHOD exclude.
    DATA lv_status TYPE sy-pfkey.
    lv_status = iv_status.
    IF lv_status IS INITIAL.
      lv_status = sy-pfkey.
    ENDIF.
    CALL FUNCTION 'RS_SET_SELSCREEN_STATUS'
      EXPORTING
        p_status  = lv_status
      TABLES
        p_exclude = it_codes.
  ENDMETHOD.

  METHOD own_status.
    DATA lv_program TYPE trdir-name.
    lv_program = sy-repid.
    CALL FUNCTION 'RS_CUA_STATUS_CHECK'
      EXPORTING
        objectname       = c_status
        program          = lv_program
      EXCEPTIONS
        object_not_found = 1
        OTHERS           = 2.
    rv_yes = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD entry_pbo.
    DATA lt_exclude TYPE ty_codes.

    "The button texts are set on every output: they must not depend on INITIALIZATION alone.
    texts( ).
    zcl_pdf_studio_ui=>set_title( zcl_pdf_studio_ui=>txt( iv_tr = `ZPDF Studio - PDF form tasarımcısı` iv_en = `ZPDF Studio - PDF form designer` ) ).
    sscrfields-functxt_01 = button(
      iv_icon = icon_import
      iv_text = zcl_pdf_studio_ui=>txt( iv_tr = `Tasarımcıyı kur / güncelle` iv_en = `Install / update designer` ) ).
    sscrfields-functxt_02 = button(
      iv_icon = icon_attachment
      iv_text = zcl_pdf_studio_ui=>txt( iv_tr = `Logo ve fontlar` iv_en = `Logos and fonts` ) ).
    "A form is opened with Display / Change / Create only: no Execute (F8), no variants,
    "no background processing.
    APPEND 'ONLI' TO lt_exclude.
    APPEND 'SPOS' TO lt_exclude.
    APPEND 'GET' TO lt_exclude.
    APPEND 'VSHO' TO lt_exclude.
    APPEND 'VDEL' TO lt_exclude.
    APPEND 'SJOB' TO lt_exclude.
    APPEND 'PRIN' TO lt_exclude.
    exclude( lt_exclude ).
  ENDMETHOD.

  METHOD designer_pbo.
    DATA lt_exclude TYPE ty_codes.

    sscrfields-functxt_01 = button(
      iv_icon = icon_system_save
      iv_text = zcl_pdf_studio_ui=>txt( iv_tr = `Kaydet` iv_en = `Save` ) ).
    sscrfields-functxt_02 = button(
      iv_icon = icon_pdf
      iv_text = zcl_pdf_studio_ui=>txt( iv_tr = `PDF önizle` iv_en = `Preview PDF` ) ).
    sscrfields-functxt_03 = button(
      iv_icon = icon_refresh
      iv_text = zcl_pdf_studio_ui=>txt( iv_tr = `Sayfayı yenile` iv_en = `Refresh page` ) ).
    IF own_status( ) = abap_true.
      "The designer has its own menus in the page: the SAP menus Program / Edit / Goto are not shown.
      exclude( it_codes = lt_exclude iv_status = c_status ).
    ELSE.
      "Only Back / Exit / Cancel and the three function keys are meaningful on the designer screen.
      APPEND 'CRET' TO lt_exclude.
      APPEND 'ONLI' TO lt_exclude.
      APPEND 'PRIN' TO lt_exclude.
      APPEND 'SPOS' TO lt_exclude.
      APPEND 'GET' TO lt_exclude.
      APPEND 'VSHO' TO lt_exclude.
      APPEND 'VDEL' TO lt_exclude.
      APPEND 'SJOB' TO lt_exclude.
      exclude( lt_exclude ).
    ENDIF.
    "The HTML control is created here, in PBO of this screen (it then survives dialogs).
    zcl_pdf_studio_ui=>pbo( ).
  ENDMETHOD.

  METHOD entry_command.
    CASE iv_ucomm.
      WHEN 'DISP'.
        start( c_display ).
      WHEN 'CHNG'.
        start( c_change ).
      WHEN 'CREA'.
        start( c_create ).
      WHEN 'FC01'.
        IF install( ) = abap_true.
          MESSAGE zcl_pdf_studio_ui=>txt( iv_tr = `Tasarımcı sayfası kuruldu.` iv_en = `The designer page was installed.` ) TYPE 'S'.
        ENDIF.
      WHEN 'FC02'.
        SUBMIT zpdf_studio_assets VIA SELECTION-SCREEN AND RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD install.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.

    rv_ok = abap_false.
    TRY.
        zcl_pdf_studio_ui=>install_page( ).
        rv_ok = abap_true.
      CATCH zcx_pdf_studio INTO lx_pdf.
        MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD start.
    DATA lv_form TYPE string.
    DATA lv_exists TYPE abap_bool.
    DATA lv_answer TYPE c LENGTH 1.
    DATA lv_question TYPE string.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.

    lv_form = to_upper( condense( val = p_form ) ).
    IF lv_form IS INITIAL.
      MESSAGE zcl_pdf_studio_ui=>txt( iv_tr = `Form adını girin.` iv_en = `Enter the form name.` ) TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    p_form = lv_form.

    TRY.
        zcl_pdf_studio_repo=>read_form( lv_form ).
        lv_exists = abap_true.
      CATCH zcx_pdf_studio.
        lv_exists = abap_false.
    ENDTRY.
    IF lv_exists = abap_false AND ( iv_mode = c_display OR iv_mode = c_change ).
      MESSAGE zcl_pdf_studio_ui=>txt( iv_tr = |{ lv_form } formu yok. Yeni form için "Yarat" düğmesini kullanın.|
                                      iv_en = |Form { lv_form } does not exist. Use "Create" for a new form.| ) TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    IF lv_exists = abap_true AND iv_mode = c_create.
      MESSAGE zcl_pdf_studio_ui=>txt( iv_tr = |{ lv_form } formu zaten var. "Değiştir" düğmesini kullanın.|
                                      iv_en = |Form { lv_form } already exists. Use "Change".| ) TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    "The designer page must be in the MIME repository: offer to install it now.
    IF zcl_pdf_studio_ui=>page_installed( ) = abap_false.
      lv_question = zcl_pdf_studio_ui=>txt(
        iv_tr = `Tasarımcı sayfası (designer.html) kurulu değil veya eski sürüm. Şimdi PC'den seçip kurmak ister misiniz?`
        iv_en = `The designer page (designer.html) is not installed or is an old version. Choose it from the PC and install it now?` ).
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'ZPDF Studio'
          text_question         = lv_question
          display_cancel_button = abap_false
        IMPORTING
          answer                = lv_answer
        EXCEPTIONS
          OTHERS                = 1.
      IF sy-subrc <> 0 OR lv_answer <> '1'.
        RETURN.
      ENDIF.
      IF install( ) = abap_false.
        RETURN.
      ENDIF.
    ENDIF.

    TRY.
        zcl_pdf_studio_ui=>open(
          iv_form_id   = lv_form
          iv_view_only = xsdbool( iv_mode = c_display ) ).
        gv_title = |ZPDF Studio - { lv_form }|.
        CALL SELECTION-SCREEN 1001.
        zcl_pdf_studio_ui=>free( ).
      CATCH zcx_pdf_studio INTO lx_pdf.
        zcl_pdf_studio_ui=>free( ).
        MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD f4_form.
    "Dictionary types: the search help derives its columns and headings from them.
    TYPES:
      BEGIN OF ty_f4,
        form_id     TYPE fpname,
        description TYPE ddtext,
        changed_by  TYPE syuname,
      END OF ty_f4.
    DATA lt_f4 TYPE STANDARD TABLE OF ty_f4 WITH DEFAULT KEY.
    DATA ls_f4 TYPE ty_f4.
    DATA lt_forms TYPE zcl_pdf_studio_repo=>ty_forms.
    DATA ls_form TYPE zcl_pdf_studio_repo=>ty_form.
    DATA lt_return TYPE STANDARD TABLE OF ddshretval WITH DEFAULT KEY.
    DATA ls_return TYPE ddshretval.
    DATA lv_repid TYPE sy-repid.
    DATA lv_dynnr TYPE sy-dynnr.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.

    TRY.
        lt_forms = zcl_pdf_studio_repo=>list_forms( ).
      CATCH zcx_pdf_studio INTO lx_pdf.
        MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.
    LOOP AT lt_forms INTO ls_form.
      CLEAR ls_f4.
      ls_f4-form_id = ls_form-form_id.
      ls_f4-description = ls_form-description.
      ls_f4-changed_by = ls_form-changed_by.
      APPEND ls_f4 TO lt_f4.
    ENDLOOP.
    IF lt_f4 IS INITIAL.
      MESSAGE zcl_pdf_studio_ui=>txt( iv_tr = `Henüz kayıtlı form yok.` iv_en = `There are no saved forms yet.` ) TYPE 'S'.
      RETURN.
    ENDIF.
    SORT lt_f4 BY form_id.
    lv_repid = sy-repid.
    lv_dynnr = sy-dynnr.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'FORM_ID'
        dynpprog        = lv_repid
        dynpnr          = lv_dynnr
        dynprofield     = 'P_FORM'
        window_title    = 'ZPDF Studio'
        value_org       = 'S'
      TABLES
        value_tab       = lt_f4
        return_tab      = lt_return
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      MESSAGE zcl_pdf_studio_ui=>txt( iv_tr = |Arama yardımı açılamadı (hata { sy-subrc }).|
                                      iv_en = |The search help could not be opened (error { sy-subrc }).| ) TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    READ TABLE lt_return INTO ls_return INDEX 1.
    IF sy-subrc = 0.
      p_form = ls_return-fieldval.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

INITIALIZATION.
  lcl_app=>texts( ).

AT SELECTION-SCREEN OUTPUT.
  IF sy-dynnr = '1001'.
    lcl_app=>designer_pbo( ).
  ELSE.
    lcl_app=>entry_pbo( ).
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_form.
  lcl_app=>f4_form( ).

AT SELECTION-SCREEN ON EXIT-COMMAND.
  "Back / Exit / Cancel on the designer: unsaved changes are offered for saving first.
  IF sy-dynnr = '1001' AND zcl_pdf_studio_ui=>may_leave( ) = abap_false.
    LEAVE TO SCREEN 1001.
  ENDIF.

AT SELECTION-SCREEN.
  IF sy-dynnr = '1001'.
    IF zcl_pdf_studio_ui=>user_command( sscrfields-ucomm ) = abap_true.
      LEAVE TO SCREEN 0.
    ENDIF.
  ELSE.
    lcl_app=>entry_command( sscrfields-ucomm ).
  ENDIF.

START-OF-SELECTION.
  "Reached only when the program is submitted from outside (Execute is not offered on the screen).
  lcl_app=>start( lcl_app=>c_any ).
