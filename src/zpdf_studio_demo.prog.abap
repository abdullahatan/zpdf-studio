*&---------------------------------------------------------------------*
*& Report ZPDF_STUDIO_DEMO
*&---------------------------------------------------------------------*
*& ZPDF Studio demo forms. Choose a form and how the PDF is shown; the
*& PRINT_* methods below are the example code for your own programs:
*& fill typed ABAP data, pass it by parameter name, get the PDF.
*&
*&   ZPDF_STUDIO_INVOICE  invoice          one structure (RENDER_PDF)
*&   ZPDF_DEMO_ORDER      purchase order   structure + table type + data element
*&   ZPDF_DEMO_CERT       certificate      landscape, rotated text, seal, signature
*&   ZPDF_DEMO_TICKET     event ticket     A5, photo, colour blocks, QR, Code 128
*&   ZPDF_DEMO_DELIVERY   delivery note    master page objects, three barcode types
*&   ZPDF_DEMO_PAYMENT    payment order    deep structure with a table, check boxes
*&
*& The forms ZPDF_DEMO_* and their images are installed from the file
*& dist\zpdf-demo-pack.txt of the designer project (button "Install /
*& update demo forms", or the question when a form is not installed yet);
*& afterwards they are ordinary forms that can be changed in ZPDF_STUDIO.
*& Interface types: ZPDF_S_DEMO_*, ZPDF_TT_DEMO_*, ZPDF_DEMO_* (DDIC).
*&---------------------------------------------------------------------*
REPORT zpdf_studio_demo.

TABLES sscrfields.

SELECTION-SCREEN BEGIN OF BLOCK frm WITH FRAME TITLE gv_tfrm.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS r_inv RADIOBUTTON GROUP frm DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(76) gv_linv FOR FIELD r_inv.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS r_ord RADIOBUTTON GROUP frm.
SELECTION-SCREEN COMMENT 3(76) gv_lord FOR FIELD r_ord.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS r_cert RADIOBUTTON GROUP frm.
SELECTION-SCREEN COMMENT 3(76) gv_lcert FOR FIELD r_cert.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS r_tick RADIOBUTTON GROUP frm.
SELECTION-SCREEN COMMENT 3(76) gv_ltick FOR FIELD r_tick.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS r_dlv RADIOBUTTON GROUP frm.
SELECTION-SCREEN COMMENT 3(76) gv_ldlv FOR FIELD r_dlv.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS r_pay RADIOBUTTON GROUP frm.
SELECTION-SCREEN COMMENT 3(76) gv_lpay FOR FIELD r_pay.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK frm.

SELECTION-SCREEN BEGIN OF BLOCK out WITH FRAME TITLE gv_tout.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS r_show RADIOBUTTON GROUP out DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(76) gv_lshow FOR FIELD r_show.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS r_save RADIOBUTTON GROUP out.
SELECTION-SCREEN COMMENT 3(76) gv_lsave FOR FIELD r_save.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS r_edit RADIOBUTTON GROUP out.
SELECTION-SCREEN COMMENT 3(76) gv_ledit FOR FIELD r_edit.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK out.

SELECTION-SCREEN BEGIN OF BLOCK opt WITH FRAME TITLE gv_topt.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(50) gv_lrows FOR FIELD p_rows.
PARAMETERS p_rows TYPE i DEFAULT 12.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_draft AS CHECKBOX.
SELECTION-SCREEN COMMENT 3(76) gv_ldrft FOR FIELD p_draft.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK opt.

SELECTION-SCREEN FUNCTION KEY 1.

CLASS lcl_demo DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS t
      IMPORTING iv_tr          TYPE string
                iv_en          TYPE string
      RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS texts.
    CLASS-METHODS run.
    "! Installs the demo forms from dist\zpdf-demo-pack.txt (file dialog).
    CLASS-METHODS install
      RETURNING VALUE(rv_ok) TYPE abap_bool.

  PRIVATE SECTION.
    CLASS-METHODS form_id
      RETURNING VALUE(rv_form) TYPE string.
    CLASS-METHODS rows
      RETURNING VALUE(rv_rows) TYPE i.
    CLASS-METHODS print_invoice
      RETURNING VALUE(rv_pdf) TYPE xstring
      RAISING   zcx_pdf_studio.
    CLASS-METHODS print_order
      RETURNING VALUE(rv_pdf) TYPE xstring
      RAISING   zcx_pdf_studio.
    CLASS-METHODS print_certificate
      RETURNING VALUE(rv_pdf) TYPE xstring
      RAISING   zcx_pdf_studio.
    CLASS-METHODS print_ticket
      RETURNING VALUE(rv_pdf) TYPE xstring
      RAISING   zcx_pdf_studio.
    CLASS-METHODS print_delivery
      RETURNING VALUE(rv_pdf) TYPE xstring
      RAISING   zcx_pdf_studio.
    CLASS-METHODS print_payment
      RETURNING VALUE(rv_pdf) TYPE xstring
      RAISING   zcx_pdf_studio.
ENDCLASS.

CLASS lcl_demo IMPLEMENTATION.

  METHOD t.
    "Turkish for a Turkish logon, English for every other logon language.
    rv_text = zcl_pdf_studio_ui=>txt( iv_tr = iv_tr iv_en = iv_en ).
  ENDMETHOD.

  METHOD texts.
    zcl_pdf_studio_ui=>set_title( t( iv_tr = `ZPDF Studio - demo formlar` iv_en = `ZPDF Studio - demo forms` ) ).
    gv_tfrm = t( iv_tr = `Demo form` iv_en = `Demo form` ).
    gv_linv = t( iv_tr = `Fatura - çok sayfalı tablo, yazıyla tutar, filigran, üç barkod`
                 iv_en = `Invoice - table across pages, amount in words, watermark, three barcodes` ).
    gv_lord = t( iv_tr = `Satınalma siparişi - yapı + tablo tipi + veri öğesi parametreleri, logo`
                 iv_en = `Purchase order - structure + table type + data element parameters, logo` ).
    gv_lcert = t( iv_tr = `Başarı sertifikası - yatay sayfa, çerçeve, döndürülmüş metin, mühür, imza`
                  iv_en = `Certificate - landscape page, frames, rotated text, seal, signature` ).
    gv_ltick = t( iv_tr = `Etkinlik bileti - A5, afiş görseli, renk blokları, QR ve Code 128`
                  iv_en = `Event ticket - A5, poster image, colour blocks, QR and Code 128` ).
    gv_ldlv = t( iv_tr = `Sevk irsaliyesi - her sayfada yinelenen nesneler, Code 128, ITF-14, DataMatrix`
                 iv_en = `Delivery note - objects repeated on every page, Code 128, ITF-14, DataMatrix` ).
    gv_lpay = t( iv_tr = `Ödeme talimatı - yapı içinde tablo, onay kutuları, yazıyla tutar, kaşe`
                 iv_en = `Payment order - table inside a structure, check boxes, amount in words, stamp` ).
    gv_tout = t( iv_tr = `İşlem` iv_en = `Action` ).
    gv_lshow = t( iv_tr = `PDF oluştur ve aç` iv_en = `Create the PDF and open it` ).
    gv_lsave = t( iv_tr = `PDF oluştur ve farklı kaydet (klasör seçilir)` iv_en = `Create the PDF and save it as (choose a folder)` ).
    gv_ledit = t( iv_tr = `Formu tasarımcıda aç (ZPDF_STUDIO)` iv_en = `Open the form in the designer (ZPDF_STUDIO)` ).
    gv_topt = t( iv_tr = `Demo verisi` iv_en = `Demo data` ).
    gv_lrows = t( iv_tr = `Kalem sayısı (fatura, sipariş, irsaliye, talimat)` iv_en = `Number of items (invoice, order, delivery, payment)` ).
    gv_ldrft = t( iv_tr = `Faturada TASLAK filigranı` iv_en = `DRAFT watermark on the invoice` ).
    sscrfields-functxt_01 = VALUE smp_dyntxt(
      icon_id   = icon_import
      icon_text = t( iv_tr = `Demo formlarını kur / güncelle` iv_en = `Install / update demo forms` )
      text      = t( iv_tr = `Demo formlarını kur / güncelle` iv_en = `Install / update demo forms` )
      quickinfo = t( iv_tr = `dist\zpdf-demo-pack.txt dosyasını seçin` iv_en = `Choose the file dist\zpdf-demo-pack.txt` ) ).
  ENDMETHOD.

  METHOD form_id.
    CASE abap_true.
      WHEN r_inv.
        rv_form = zcl_pdf_studio_demos=>c_invoice.
      WHEN r_ord.
        rv_form = zcl_pdf_studio_demos=>c_order.
      WHEN r_cert.
        rv_form = zcl_pdf_studio_demos=>c_cert.
      WHEN r_tick.
        rv_form = zcl_pdf_studio_demos=>c_ticket.
      WHEN r_dlv.
        rv_form = zcl_pdf_studio_demos=>c_delivery.
      WHEN r_pay.
        rv_form = zcl_pdf_studio_demos=>c_payment.
    ENDCASE.
  ENDMETHOD.

  METHOD rows.
    rv_rows = p_rows.
    IF rv_rows < 1.
      rv_rows = 1.
    ELSEIF rv_rows > 500.
      rv_rows = 500.
    ENDIF.
  ENDMETHOD.

  METHOD print_invoice.
    "One structure as the data of the form (forms without named parameters).
    DATA ls_invoice TYPE zcl_pdf_studio_demo=>ty_fatura.

    ls_invoice = zcl_pdf_studio_demo=>invoice( iv_rows = rows( ) iv_draft = p_draft ).
    rv_pdf = zcl_pdf_studio_api=>render_pdf(
      iv_form_id = zcl_pdf_studio_demos=>c_invoice
      is_data    = ls_invoice ).
  ENDMETHOD.

  METHOD print_order.
    "Three parameters of three kinds: a structure, a table type and a data element.
    "Every parameter is passed by the name it has in the interface of the form.
    DATA ls_order TYPE zpdf_s_demo_order.
    DATA lt_items TYPE zpdf_tt_demo_order_items.
    DATA lv_note TYPE zpdf_demo_note.
    DATA lt_params TYPE zcl_pdf_studio_api=>ty_params.

    zcl_pdf_studio_demos=>order(
      EXPORTING iv_rows  = rows( )
      IMPORTING es_order = ls_order
                et_items = lt_items
                ev_note  = lv_note ).
    lt_params = VALUE #( ( name = `IS_ORDER` value = REF #( ls_order ) )
                         ( name = `IT_ITEMS` value = REF #( lt_items ) )
                         ( name = `IV_NOTE`  value = REF #( lv_note ) ) ).
    rv_pdf = zcl_pdf_studio_api=>render_form(
      iv_form_id = zcl_pdf_studio_demos=>c_order
      it_params  = lt_params ).
  ENDMETHOD.

  METHOD print_certificate.
    DATA ls_cert TYPE zpdf_s_demo_cert.
    DATA lt_params TYPE zcl_pdf_studio_api=>ty_params.

    ls_cert = zcl_pdf_studio_demos=>certificate( ).
    lt_params = VALUE #( ( name = `IS_CERT` value = REF #( ls_cert ) ) ).
    rv_pdf = zcl_pdf_studio_api=>render_form(
      iv_form_id = zcl_pdf_studio_demos=>c_cert
      it_params  = lt_params ).
  ENDMETHOD.

  METHOD print_ticket.
    DATA ls_ticket TYPE zpdf_s_demo_ticket.
    DATA lt_params TYPE zcl_pdf_studio_api=>ty_params.

    ls_ticket = zcl_pdf_studio_demos=>ticket( ).
    lt_params = VALUE #( ( name = `IS_TICKET` value = REF #( ls_ticket ) ) ).
    rv_pdf = zcl_pdf_studio_api=>render_form(
      iv_form_id = zcl_pdf_studio_demos=>c_ticket
      it_params  = lt_params ).
  ENDMETHOD.

  METHOD print_delivery.
    DATA ls_delivery TYPE zpdf_s_demo_delivery.
    DATA lt_items TYPE zpdf_tt_demo_deliv_items.
    DATA lt_params TYPE zcl_pdf_studio_api=>ty_params.

    zcl_pdf_studio_demos=>delivery(
      EXPORTING iv_rows     = rows( )
      IMPORTING es_delivery = ls_delivery
                et_items    = lt_items ).
    lt_params = VALUE #( ( name = `IS_DELIVERY` value = REF #( ls_delivery ) )
                         ( name = `IT_ITEMS`    value = REF #( lt_items ) ) ).
    rv_pdf = zcl_pdf_studio_api=>render_form(
      iv_form_id = zcl_pdf_studio_demos=>c_delivery
      it_params  = lt_params ).
  ENDMETHOD.

  METHOD print_payment.
    "One parameter: a structure that contains the table of the payments (INPUT-ITEMS).
    DATA ls_payment TYPE zpdf_s_demo_payment.
    DATA lt_params TYPE zcl_pdf_studio_api=>ty_params.

    ls_payment = zcl_pdf_studio_demos=>payment( rows( ) ).
    lt_params = VALUE #( ( name = `INPUT` value = REF #( ls_payment ) ) ).
    rv_pdf = zcl_pdf_studio_api=>render_form(
      iv_form_id = zcl_pdf_studio_demos=>c_payment
      it_params  = lt_params ).
  ENDMETHOD.

  METHOD run.
    DATA lv_form TYPE string.
    DATA lv_name TYPE c LENGTH 30.
    DATA lv_pdf TYPE xstring.
    DATA lv_answer TYPE c LENGTH 1.
    DATA lv_question TYPE string.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.

    lv_form = form_id( ).
    TRY.
        IF lv_form = zcl_pdf_studio_demos=>c_invoice.
          "The invoice form is part of class ZCL_PDF_STUDIO_DEMO and is created on the first run.
          zcl_pdf_studio_demo=>install( ).
        ELSEIF zcl_pdf_studio_demos=>installed( lv_form ) = abap_false.
          lv_question = t( iv_tr = |{ lv_form } formu henüz kurulmamış. Demo formlarını şimdi kurmak ister misiniz? | &&
                                   |(Tasarımcı projesindeki dist\\zpdf-demo-pack.txt dosyasını seçin.)|
                           iv_en = |Form { lv_form } is not installed yet. Install the demo forms now? | &&
                                   |(Choose the file dist\\zpdf-demo-pack.txt of the designer project.)| ).
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar              = 'ZPDF Studio'
              text_question         = lv_question
              display_cancel_button = abap_false
            IMPORTING
              answer                = lv_answer
            EXCEPTIONS
              OTHERS                = 1.
          IF sy-subrc <> 0 OR lv_answer <> '1' OR install( ) = abap_false
              OR zcl_pdf_studio_demos=>installed( lv_form ) = abap_false.
            RETURN.
          ENDIF.
        ENDIF.

        IF r_edit = abap_true.
          lv_name = lv_form.
          SUBMIT zpdf_studio WITH p_form = lv_name VIA SELECTION-SCREEN AND RETURN.
          RETURN.
        ENDIF.

        CASE abap_true.
          WHEN r_inv.
            lv_pdf = print_invoice( ).
          WHEN r_ord.
            lv_pdf = print_order( ).
          WHEN r_cert.
            lv_pdf = print_certificate( ).
          WHEN r_tick.
            lv_pdf = print_ticket( ).
          WHEN r_dlv.
            lv_pdf = print_delivery( ).
          WHEN r_pay.
            lv_pdf = print_payment( ).
        ENDCASE.

        "Without the dialog the file is written to the desktop folder and opened.
        zcl_pdf_studio_api=>download_pdf(
          iv_pdf_xstring = lv_pdf
          iv_filename    = |{ lv_form }.pdf|
          iv_open        = abap_true
          iv_dialog      = r_save ).
        MESSAGE t( iv_tr = |{ lv_form }: PDF oluşturuldu ({ xstrlen( lv_pdf ) } bayt).|
                   iv_en = |{ lv_form }: the PDF was created ({ xstrlen( lv_pdf ) } bytes).| ) TYPE 'S'.
      CATCH zcx_pdf_studio INTO lx_pdf.
        MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD install.
    DATA lt_files TYPE filetable.
    DATA ls_file TYPE file_table.
    DATA lv_rc TYPE i.
    DATA lv_action TYPE i.
    DATA lv_file TYPE string.
    DATA lv_title TYPE string.
    DATA lt_bin TYPE solix_tab.
    DATA lv_length TYPE i.
    DATA lv_pack TYPE string.
    DATA lv_message TYPE string.
    DATA lx_pdf TYPE REF TO zcx_pdf_studio.

    rv_ok = abap_false.
    lv_title = t( iv_tr = `ZPDF Studio demo paketi (dist\zpdf-demo-pack.txt)` iv_en = `ZPDF Studio demo pack (dist\zpdf-demo-pack.txt)` ).
    cl_gui_frontend_services=>file_open_dialog(
      EXPORTING
        window_title     = lv_title
        default_filename = 'zpdf-demo-pack.txt'
        file_filter      = 'ZPDF Studio demo (*.txt)|*.txt|*.*|*.*'
      CHANGING
        file_table       = lt_files
        rc               = lv_rc
        user_action      = lv_action
      EXCEPTIONS
        OTHERS           = 1 ).
    IF sy-subrc <> 0 OR lv_rc < 1 OR lv_action = cl_gui_frontend_services=>action_cancel.
      RETURN.
    ENDIF.
    READ TABLE lt_files INTO ls_file INDEX 1.
    lv_file = ls_file-filename.
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
      MESSAGE t( iv_tr = |Dosya okunamadı: { lv_file }| iv_en = |The file could not be read: { lv_file }| ) TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    TRY.
        lv_pack = zcl_pdf_studio_conv=>xstring_to_string( cl_bcs_convert=>solix_to_xstring( it_solix = lt_bin iv_size = lv_length ) ).
        lv_message = zcl_pdf_studio_demos=>install_pack( lv_pack ).
        MESSAGE lv_message TYPE 'S'.
        rv_ok = abap_true.
      CATCH zcx_pdf_studio INTO lx_pdf.
        MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

AT SELECTION-SCREEN OUTPUT.
  lcl_demo=>texts( ).

AT SELECTION-SCREEN.
  IF sscrfields-ucomm = 'FC01'.
    lcl_demo=>install( ).
  ENDIF.

START-OF-SELECTION.
  lcl_demo=>run( ).
