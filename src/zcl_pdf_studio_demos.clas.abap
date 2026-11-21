"! <p class="shorttext synchronized">ZPDF Studio - demo forms: data and installation</p>
"! Demo forms of ZPDF Studio (see program ZPDF_STUDIO_DEMO):
"! <ul>
"! <li>ZPDF_DEMO_ORDER - purchase order: structure + table type + data element as parameters</li>
"! <li>ZPDF_DEMO_CERT - certificate: landscape, frames, rotated text, seal and signature images</li>
"! <li>ZPDF_DEMO_TICKET - event ticket: A5, photo, colour blocks, QR and Code 128</li>
"! <li>ZPDF_DEMO_DELIVERY - delivery note: master page objects, Code 128, ITF-14, DataMatrix</li>
"! <li>ZPDF_DEMO_PAYMENT - payment order: one deep structure with a table, check boxes, stamp</li>
"! </ul>
"! The forms and their images are delivered as a file (dist\zpdf-demo-pack.txt of the designer
"! project) that INSTALL_PACK stores as ordinary forms; they can be changed in ZPDF_STUDIO.
"! The other methods return typed demo data (DDIC types ZPDF_S_DEMO_*, ZPDF_TT_DEMO_*, ZPDF_DEMO_*).
CLASS zcl_pdf_studio_demos DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CONSTANTS c_invoice TYPE string VALUE 'ZPDF_STUDIO_INVOICE'.
    CONSTANTS c_order TYPE string VALUE 'ZPDF_DEMO_ORDER'.
    CONSTANTS c_cert TYPE string VALUE 'ZPDF_DEMO_CERT'.
    CONSTANTS c_ticket TYPE string VALUE 'ZPDF_DEMO_TICKET'.
    CONSTANTS c_delivery TYPE string VALUE 'ZPDF_DEMO_DELIVERY'.
    CONSTANTS c_payment TYPE string VALUE 'ZPDF_DEMO_PAYMENT'.
    CONSTANTS c_pack_mark TYPE string VALUE 'ZPDF-DEMO-PACK'.

    TYPES:
      BEGIN OF ty_form,
        description TYPE string,
        template    TYPE zcl_pdf_studio_repo=>ty_template,
      END OF ty_form,
      ty_forms TYPE STANDARD TABLE OF ty_form WITH EMPTY KEY,
      BEGIN OF ty_image,
        asset   TYPE zcl_pdf_studio_assets=>ty_asset,
        content TYPE xstring,
      END OF ty_image,
      ty_images TYPE STANDARD TABLE OF ty_image WITH EMPTY KEY.

    "! Reads the demo pack (text of dist\zpdf-demo-pack.txt): forms and images.
    CLASS-METHODS parse_pack
      IMPORTING
        iv_pack   TYPE string
      EXPORTING
        et_forms  TYPE ty_forms
        et_images TYPE ty_images
      RAISING
        zcx_pdf_studio.

    "! Stores the images and the forms of the demo pack (a new version for forms that exist).
    CLASS-METHODS install_pack
      IMPORTING
        iv_pack           TYPE string
      RETURNING
        VALUE(rv_message) TYPE string
      RAISING
        zcx_pdf_studio.

    "! abap_true when the form is stored and can be printed.
    CLASS-METHODS installed
      IMPORTING
        iv_form_id    TYPE csequence
      RETURNING
        VALUE(rv_yes) TYPE abap_bool.

    "! Purchase order with iv_rows items.
    CLASS-METHODS order
      IMPORTING
        iv_rows  TYPE i DEFAULT 8
      EXPORTING
        es_order TYPE zpdf_s_demo_order
        et_items TYPE zpdf_tt_demo_order_items
        ev_note  TYPE zpdf_demo_note.

    CLASS-METHODS certificate
      RETURNING
        VALUE(rs_cert) TYPE zpdf_s_demo_cert.

    CLASS-METHODS ticket
      RETURNING
        VALUE(rs_ticket) TYPE zpdf_s_demo_ticket.

    "! Delivery note with iv_rows items.
    CLASS-METHODS delivery
      IMPORTING
        iv_rows     TYPE i DEFAULT 8
      EXPORTING
        es_delivery TYPE zpdf_s_demo_delivery
        et_items    TYPE zpdf_tt_demo_deliv_items.

    "! Payment order with iv_rows payments (the items are a table inside the structure).
    CLASS-METHODS payment
      IMPORTING
        iv_rows           TYPE i DEFAULT 5
      RETURNING
        VALUE(rs_payment) TYPE zpdf_s_demo_payment.
ENDCLASS.



CLASS zcl_pdf_studio_demos IMPLEMENTATION.

  METHOD parse_pack.
    DATA lt_rows TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lt_cells TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_row TYPE string.
    DATA lv_kind TYPE string.
    DATA lv_id TYPE string.
    DATA lv_text TYPE string.
    DATA lv_data TYPE string.
    DATA lv_cr TYPE c LENGTH 1.
    DATA ls_form TYPE ty_form.
    DATA ls_image TYPE ty_image.
    DATA lt_lines TYPE zcl_pdf_studio_ui=>ty_lines.

    CLEAR: et_forms, et_images.
    lv_cr = cl_abap_char_utilities=>cr_lf(1).
    SPLIT iv_pack AT cl_abap_char_utilities=>newline INTO TABLE lt_rows.
    READ TABLE lt_rows INTO lv_row INDEX 1.
    IF sy-subrc <> 0 OR find( val = lv_row sub = c_pack_mark ) < 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = zcl_pdf_studio_ui=>txt(
            iv_tr = `Bu dosya ZPDF Studio demo paketi değil (dist\zpdf-demo-pack.txt seçilmeli).`
            iv_en = `This file is not a ZPDF Studio demo pack (choose dist\zpdf-demo-pack.txt).` ).
    ENDIF.

    LOOP AT lt_rows INTO lv_row FROM 2.
      REPLACE ALL OCCURRENCES OF lv_cr IN lv_row WITH ``.
      IF lv_row IS INITIAL.
        CONTINUE.
      ENDIF.
      SPLIT lv_row AT cl_abap_char_utilities=>horizontal_tab INTO TABLE lt_cells.
      READ TABLE lt_cells INTO lv_kind INDEX 1.
      READ TABLE lt_cells INTO lv_id INDEX 2.
      CLEAR lv_text.
      READ TABLE lt_cells INTO lv_text INDEX 3.
      CASE lv_kind.
        WHEN 'FORM'.
          CLEAR: ls_form, lv_data.
          READ TABLE lt_cells INTO lv_data INDEX 4.
          lt_lines = zcl_pdf_studio_ui=>parse_envelope( lv_data ).
          ls_form-template = zcl_pdf_studio_ui=>template_from_lines( lt_lines ).
          ls_form-template-form_id = to_upper( lv_id ).
          IF lv_text IS NOT INITIAL.
            ls_form-description = zcl_pdf_studio_conv=>base64_decode( lv_text ).
          ENDIF.
          IF zcl_pdf_studio_ui=>studio_payload( ls_form-template-html_content ) IS INITIAL.
            RAISE EXCEPTION TYPE zcx_pdf_studio
              EXPORTING
                message = zcl_pdf_studio_ui=>txt(
                  iv_tr = |Demo paketi: { lv_id } formunun geçerli bir tasarımı yok.|
                  iv_en = |Demo pack: form { lv_id } has no valid design.| ).
          ENDIF.
          APPEND ls_form TO et_forms.
        WHEN 'ASSET'.
          CLEAR: ls_image, lv_data.
          ls_image-asset-asset_id = to_upper( lv_id ).
          IF lv_text IS NOT INITIAL.
            ls_image-asset-description = zcl_pdf_studio_conv=>base64_decode( lv_text ).
          ENDIF.
          READ TABLE lt_cells INTO ls_image-asset-filename INDEX 4.
          READ TABLE lt_cells INTO lv_data INDEX 5.
          ls_image-content = cl_http_utility=>decode_x_base64( lv_data ).
          APPEND ls_image TO et_images.
      ENDCASE.
    ENDLOOP.
    IF et_forms IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = zcl_pdf_studio_ui=>txt( iv_tr = `Demo paketinde form yok.` iv_en = `The demo pack contains no forms.` ).
    ENDIF.
  ENDMETHOD.


  METHOD install_pack.
    DATA lt_forms TYPE ty_forms.
    DATA lt_images TYPE ty_images.
    DATA ls_form TYPE ty_form.
    DATA ls_image TYPE ty_image.
    DATA lt_ids TYPE zcl_pdf_studio_assets=>ty_ids.
    DATA lv_request TYPE trkorr.

    parse_pack( EXPORTING iv_pack = iv_pack IMPORTING et_forms = lt_forms et_images = lt_images ).

    "The images first: the forms refer to them. One transport request for all of them.
    LOOP AT lt_images INTO ls_image.
      zcl_pdf_studio_assets=>save(
        is_asset   = ls_image-asset
        iv_content = ls_image-content
        iv_record  = abap_false ).
      APPEND ls_image-asset-asset_id TO lt_ids.
    ENDLOOP.
    IF lt_ids IS NOT INITIAL AND zcl_pdf_studio_transport=>client_recording( ) = '1'.
      lv_request = zcl_pdf_studio_assets=>transport( lt_ids ).
    ENDIF.

    LOOP AT lt_forms INTO ls_form.
      IF installed( ls_form-template-form_id ) = abap_true.
        zcl_pdf_studio_repo=>update_form(
          iv_form_id     = ls_form-template-form_id
          iv_description = ls_form-description ).
      ELSE.
        TRY.
            zcl_pdf_studio_repo=>create_form(
              iv_form_id     = ls_form-template-form_id
              iv_description = ls_form-description ).
          CATCH zcx_pdf_studio.
            "The form exists without a design: it only gets the new design.
            zcl_pdf_studio_repo=>update_form(
              iv_form_id     = ls_form-template-form_id
              iv_description = ls_form-description ).
        ENDTRY.
      ENDIF.
      zcl_pdf_studio_repo=>save_template(
        is_template    = ls_form-template
        iv_new_version = abap_true ).
    ENDLOOP.
    zcl_pdf_studio_repo=>commit_changes( ).

    rv_message = zcl_pdf_studio_ui=>txt(
      iv_tr = |{ lines( lt_forms ) } demo form ve { lines( lt_images ) } görsel kuruldu.|
      iv_en = |{ lines( lt_forms ) } demo forms and { lines( lt_images ) } images were installed.| ).
    IF lv_request IS NOT INITIAL.
      rv_message = |{ rv_message } Transport: { lv_request }.|.
    ENDIF.
  ENDMETHOD.


  METHOD installed.
    DATA ls_template TYPE zcl_pdf_studio_repo=>ty_template.
    DATA lv_form_id TYPE string.

    rv_yes = abap_false.
    lv_form_id = iv_form_id.
    TRY.
        ls_template = zcl_pdf_studio_repo=>read_active_template( lv_form_id ).
        rv_yes = xsdbool( ls_template-html_content IS NOT INITIAL ).
      CATCH zcx_pdf_studio.
        rv_yes = abap_false.
    ENDTRY.
  ENDMETHOD.


  METHOD order.
    TYPES:
      BEGIN OF ty_material,
        matnr TYPE c LENGTH 18,
        maktx TYPE string,
        meins TYPE c LENGTH 3,
        netpr TYPE zpdf_demo_amount,
        menge TYPE zpdf_demo_qty,
      END OF ty_material.
    DATA lt_materials TYPE STANDARD TABLE OF ty_material WITH EMPTY KEY.
    DATA ls_material TYPE ty_material.
    DATA ls_item TYPE zpdf_s_demo_order_item.
    DATA lv_index TYPE i.

    CLEAR: es_order, et_items, ev_note.
    lt_materials = VALUE #(
      ( matnr = 'ST-304-2MM' maktx = `Paslanmaz sac 304 kalite 2 mm` meins = 'KG' netpr = '95.00' menge = 120 )
      ( matnr = 'CV-M8X40' maktx = `Altıköşe cıvata M8×40 (çinko kaplı)` meins = 'AD' netpr = '1.60' menge = 2500 )
      ( matnr = 'RL-6204' maktx = `Bilyalı rulman 6204-2RS` meins = 'AD' netpr = '65.00' menge = 50 )
      ( matnr = 'BY-RAL7035' maktx = `Elektrostatik toz boya RAL 7035` meins = 'KG' netpr = '185.50' menge = 25 )
      ( matnr = 'KY-V13X1250' maktx = `V kayış 13×1250` meins = 'AD' netpr = '48.75' menge = 16 )
      ( matnr = 'HR-12MM' maktx = `Hidrolik hortum 12 mm` meins = 'M' netpr = '72.40' menge = 80 ) ).

    es_order-ebeln = '4500012345'.
    es_order-bedat = sy-datum.
    es_order-eindt = sy-datum + 14.
    es_order-lifnr = '100245'.
    es_order-vendor_name = `Yıldız Metal San. ve Tic. Ltd. Şti.`.
    es_order-vendor_addr = `İkitelli OSB Metal İş Sanayi Sitesi 4. Blok No:17, Başakşehir / İstanbul`.
    es_order-vendor_taxno = '9876543210'.
    es_order-buyer = `Ayşe Demir`.
    es_order-payterms = `30 gün vadeli havale`.
    es_order-waers = 'TRY'.
    es_order-urgent = abap_true.
    DO iv_rows TIMES.
      lv_index = sy-index.
      READ TABLE lt_materials INTO ls_material INDEX ( lv_index - 1 ) MOD lines( lt_materials ) + 1.
      CLEAR ls_item.
      ls_item-posnr = |{ lv_index * 10 }|.
      ls_item-matnr = ls_material-matnr.
      ls_item-maktx = ls_material-maktx.
      ls_item-menge = ls_material-menge + ( ( lv_index - 1 ) DIV lines( lt_materials ) ) * 5.
      ls_item-meins = ls_material-meins.
      ls_item-netpr = ls_material-netpr.
      ls_item-netwr = ls_item-menge * ls_item-netpr.
      ls_item-eindt = es_order-eindt.
      APPEND ls_item TO et_items.
      es_order-netwr = es_order-netwr + ls_item-netwr.
    ENDDO.
    es_order-tax_amount = es_order-netwr * 20 / 100.
    es_order-total = es_order-netwr + es_order-tax_amount.
    ev_note = `Malzemeler sertifikalı olarak ve paletli teslim edilecektir. Kısmi teslimat kabul edilmez.`.
  ENDMETHOD.


  METHOD certificate.
    rs_cert-cert_no = 'SRT-2026-0147'.
    rs_cert-full_name = `Elif Kaya`.
    rs_cert-course = `ABAP ile PDF Form Geliştirme`.
    rs_cert-hours = 40.
    rs_cert-end_date = sy-datum - 8.
    rs_cert-start_date = rs_cert-end_date - 11.
    rs_cert-issue_date = sy-datum.
    rs_cert-trainer = `Dr. Mehmet Aydın`.
    rs_cert-manager = `Zeynep Arslan`.
    rs_cert-city = `Kayseri`.
    rs_cert-score = '94.50'.
    rs_cert-verify_url = `https://example.com/sertifika/SRT-2026-0147`.
    rs_cert-honors = abap_true.
  ENDMETHOD.


  METHOD ticket.
    rs_ticket-ticket_no = 'BLT-00482719'.
    rs_ticket-event = `Anadolu Senfoni Gecesi`.
    rs_ticket-artist = `Kayseri Filarmoni Orkestrası`.
    rs_ticket-venue = `Kadir Has Kongre Merkezi`.
    rs_ticket-city = `Kayseri`.
    rs_ticket-event_date = sy-datum + 28.
    rs_ticket-doors = '190000'.
    rs_ticket-start_time = '203000'.
    rs_ticket-block = 'B'.
    rs_ticket-seat_row = '12'.
    rs_ticket-seat_no = '27'.
    rs_ticket-gate = '3'.
    rs_ticket-holder = `Elif Kaya`.
    rs_ticket-category = `Parter`.
    rs_ticket-price = '750.00'.
    rs_ticket-waers = 'TRY'.
    rs_ticket-vip = abap_true.
    rs_ticket-barcode = 'BLT00482719'.
  ENDMETHOD.


  METHOD delivery.
    TYPES:
      BEGIN OF ty_material,
        matnr TYPE c LENGTH 18,
        maktx TYPE string,
        ean   TYPE c LENGTH 13,
        charg TYPE c LENGTH 10,
        lgort TYPE c LENGTH 4,
        lfimg TYPE zpdf_demo_qty,
        meins TYPE c LENGTH 3,
      END OF ty_material.
    DATA lt_materials TYPE STANDARD TABLE OF ty_material WITH EMPTY KEY.
    DATA ls_material TYPE ty_material.
    DATA ls_item TYPE zpdf_s_demo_deliv_item.
    DATA lv_index TYPE i.

    CLEAR: es_delivery, et_items.
    lt_materials = VALUE #(
      ( matnr = 'MT-5M-KLT' maktx = `Şerit metre 5 m (kilitli)` ean = '8690000000019' charg = 'P2611A' lgort = '1000' lfimg = 240 meins = 'AD' )
      ( matnr = 'DB-8MM-100' maktx = `Plastik dübel 8 mm (100 lü kutu)` ean = '8690000000026' charg = 'P2610C' lgort = '1000' lfimg = 60 meins = 'KT' )
      ( matnr = 'EL-IS-L' maktx = `İş eldiveni nitril kaplı (L)` ean = '8690000000033' charg = 'P2611B' lgort = '2000' lfimg = 500 meins = 'ÇFT' )
      ( matnr = 'TK-TRN-6' maktx = `Tornavida takımı 6 parça` ean = '8690000000040' charg = 'P2609D' lgort = '1000' lfimg = 36 meins = 'TK' )
      ( matnr = 'BT-SLK-310' maktx = `Şeffaf silikon 310 ml` ean = '8690000000057' charg = 'P2611C' lgort = '3000' lfimg = 144 meins = 'AD' )
      ( matnr = 'ZM-P120' maktx = `Zımpara kağıdı P120 (50 li paket)` ean = '8690000000064' charg = 'P2608A' lgort = '2000' lfimg = 20 meins = 'PK' ) ).

    es_delivery-vbeln = '8000456789'.
    es_delivery-wadat = sy-datum.
    es_delivery-ship_to_name = `Ege Yapı Market A.Ş.`.
    es_delivery-ship_to_addr = `Atatürk Organize Sanayi Bölgesi 10003 Sok. No:8`.
    es_delivery-ship_to_city = `Çiğli / İzmir`.
    es_delivery-ship_to_phone = '0232 000 00 00'.
    es_delivery-carrier = `Anadolu Lojistik`.
    es_delivery-tracking = 'AL2611210047'.
    "13 digits: the check digit of the ITF-14 code is added when it is printed.
    es_delivery-gtin14 = '1869000000001'.
    es_delivery-plate = '38 ABC 123'.
    es_delivery-driver = `Hasan Yılmaz`.
    es_delivery-express = abap_true.
    es_delivery-fragile = abap_true.
    DO iv_rows TIMES.
      lv_index = sy-index.
      READ TABLE lt_materials INTO ls_material INDEX ( lv_index - 1 ) MOD lines( lt_materials ) + 1.
      CLEAR ls_item.
      ls_item-posnr = |{ lv_index * 10 }|.
      ls_item-matnr = ls_material-matnr.
      ls_item-maktx = ls_material-maktx.
      ls_item-ean = ls_material-ean.
      ls_item-charg = ls_material-charg.
      ls_item-lgort = ls_material-lgort.
      ls_item-lfimg = ls_material-lfimg.
      ls_item-meins = ls_material-meins.
      APPEND ls_item TO et_items.
      es_delivery-gross_weight = es_delivery-gross_weight + ls_material-lfimg / 4.
    ENDDO.
    es_delivery-packages = ( iv_rows + 1 ) * 2.
  ENDMETHOD.


  METHOD payment.
    DATA lt_receivers TYPE zpdf_tt_demo_pay_items.
    DATA ls_item TYPE zpdf_s_demo_pay_item.
    DATA lv_index TYPE i.

    lt_receivers = VALUE #(
      ( receiver = `Yıldız Metal San. ve Tic. Ltd. Şti.` receiver_iban = 'TR00 0000 0000 0000 0000 0000 02' receiver_bank = `Marmara Bank`
        sgtxt = `Fatura FT-2026-1184` wrbtr = '22380.00' waers = 'TRY' )
      ( receiver = `Anadolu Lojistik A.Ş.` receiver_iban = 'TR00 0000 0000 0000 0000 0000 03' receiver_bank = `Ege Bank`
        sgtxt = `Kasım nakliye bedeli` wrbtr = '41370.00' waers = 'TRY' )
      ( receiver = `Öztürk Enerji Dağıtım A.Ş.` receiver_iban = 'TR00 0000 0000 0000 0000 0000 04' receiver_bank = `Anadolu Ticaret Bankası`
        sgtxt = `Ekim elektrik faturası` wrbtr = '85000.00' waers = 'TRY' )
      ( receiver = `Çınar Ambalaj Ltd. Şti.` receiver_iban = 'TR00 0000 0000 0000 0000 0000 05' receiver_bank = `Marmara Bank`
        sgtxt = `Koli ve streç film` wrbtr = '12640.50' waers = 'TRY' )
      ( receiver = `Güneş Bilişim Hizmetleri A.Ş.` receiver_iban = 'TR00 0000 0000 0000 0000 0000 06' receiver_bank = `Ege Bank`
        sgtxt = `Yıllık bakım sözleşmesi` wrbtr = '36900.00' waers = 'TRY' ) ).

    rs_payment-bukrs = '1000'.
    rs_payment-company = `Nova Endüstri A.Ş.`.
    rs_payment-order_no = 'OT-2026-0318'.
    rs_payment-order_date = sy-datum.
    rs_payment-value_date = sy-datum + 3.
    rs_payment-bank = `Anadolu Ticaret Bankası A.Ş.`.
    rs_payment-branch = `Kayseri Organize Sanayi`.
    rs_payment-iban = 'TR00 0000 0000 0000 0000 0000 01'.
    rs_payment-waers = 'TRY'.
    rs_payment-eft = abap_true.
    rs_payment-signer1 = `Zeynep Arslan`.
    rs_payment-signer2 = `Murat Çelik`.
    DO iv_rows TIMES.
      lv_index = sy-index.
      READ TABLE lt_receivers INTO ls_item INDEX ( lv_index - 1 ) MOD lines( lt_receivers ) + 1.
      APPEND ls_item TO rs_payment-items.
      rs_payment-total = rs_payment-total + ls_item-wrbtr.
    ENDDO.
    rs_payment-item_count = lines( rs_payment-items ).
  ENDMETHOD.

ENDCLASS.
