CLASS ltc_demos DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    "The parameters of each demo form as one structure: this is how ZCL_PDF_STUDIO_API=>RENDER_FORM
    "hands them to the binder. The templates below use every field that the demo forms use.
    TYPES:
      BEGIN OF ty_order,
        is_order TYPE zpdf_s_demo_order,
        it_items TYPE zpdf_tt_demo_order_items,
        iv_note  TYPE zpdf_demo_note,
      END OF ty_order,
      BEGIN OF ty_cert,
        is_cert TYPE zpdf_s_demo_cert,
      END OF ty_cert,
      BEGIN OF ty_ticket,
        is_ticket TYPE zpdf_s_demo_ticket,
      END OF ty_ticket,
      BEGIN OF ty_delivery,
        is_delivery TYPE zpdf_s_demo_delivery,
        it_items    TYPE zpdf_tt_demo_deliv_items,
      END OF ty_delivery,
      BEGIN OF ty_payment,
        input TYPE zpdf_s_demo_payment,
      END OF ty_payment.

    METHODS pack_is_read FOR TESTING RAISING zcx_pdf_studio.
    METHODS wrong_file_is_refused FOR TESTING.
    METHODS order_fields FOR TESTING RAISING zcx_pdf_studio.
    METHODS certificate_fields FOR TESTING RAISING zcx_pdf_studio.
    METHODS ticket_fields FOR TESTING RAISING zcx_pdf_studio.
    METHODS delivery_fields FOR TESTING RAISING zcx_pdf_studio.
    METHODS payment_fields FOR TESTING RAISING zcx_pdf_studio.
    METHODS order_prints FOR TESTING RAISING zcx_pdf_studio.
    METHODS installed_forms_print FOR TESTING RAISING zcx_pdf_studio.

    METHODS b64
      IMPORTING iv_text       TYPE string
      RETURNING VALUE(rv_b64) TYPE string
      RAISING   zcx_pdf_studio.
    METHODS has
      IMPORTING iv_text TYPE string
                iv_part TYPE string.
ENDCLASS.

CLASS ltc_demos IMPLEMENTATION.

  METHOD b64.
    rv_b64 = cl_http_utility=>encode_x_base64( zcl_pdf_studio_conv=>string_to_xstring( iv_text ) ).
  ENDMETHOD.

  METHOD has.
    cl_abap_unit_assert=>assert_true( act = xsdbool( iv_text CS iv_part ) msg = |"{ iv_part }" is missing in: { iv_text }| ).
  ENDMETHOD.

  METHOD pack_is_read.
    DATA lv_html TYPE string.
    DATA lv_state TYPE string.
    DATA lv_pack TYPE string.
    DATA lv_sample TYPE string.
    DATA lv_image TYPE xstring.
    DATA lt_forms TYPE zcl_pdf_studio_demos=>ty_forms.
    DATA lt_images TYPE zcl_pdf_studio_demos=>ty_images.
    DATA ls_form TYPE zcl_pdf_studio_demos=>ty_form.
    DATA ls_image TYPE zcl_pdf_studio_demos=>ty_image.

    lv_sample = `{"A":"ş"}`.
    lv_html = |<!--zpdf-studio:{ b64( `{"zpdf":2}` ) }--><!--zpdf-iface:IS_CERT=ZPDF_S_DEMO_CERT--><section></section>|.
    lv_state = |META\tform_id\t{ b64( `ZPDF_T` ) }\nMETA\thtml\t{ b64( lv_html ) }\nMETA\tpage_size\t{ b64( `A5` ) }\n| &&
               |META\torientation\t{ b64( `L` ) }\nMETA\tmargin_left\t{ b64( `7` ) }\nMETA\tsample\t{ b64( lv_sample ) }|.
    lv_image = '89504E470D0A1A0A0102030405'.
    "Windows line ends and a last empty line must not matter.
    lv_pack = |ZPDF-DEMO-PACK\t1\r\nFORM\tzpdf_t\t{ b64( `Örnek açıklama` ) }\t{ b64( lv_state ) }\r\n| &&
              |ASSET\tzpdf_t_logo\t{ b64( `Logo` ) }\tlogo.png\t{ cl_http_utility=>encode_x_base64( lv_image ) }\r\n\r\n|.

    zcl_pdf_studio_demos=>parse_pack( EXPORTING iv_pack = lv_pack IMPORTING et_forms = lt_forms et_images = lt_images ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_forms ) exp = 1 ).
    READ TABLE lt_forms INTO ls_form INDEX 1.
    cl_abap_unit_assert=>assert_equals( act = ls_form-template-form_id exp = `ZPDF_T` ).
    cl_abap_unit_assert=>assert_equals( act = ls_form-description exp = `Örnek açıklama` ).
    cl_abap_unit_assert=>assert_equals( act = ls_form-template-html_content exp = lv_html ).
    cl_abap_unit_assert=>assert_equals( act = ls_form-template-page_size exp = `A5` ).
    cl_abap_unit_assert=>assert_equals( act = ls_form-template-orientation exp = `L` ).
    cl_abap_unit_assert=>assert_equals( act = ls_form-template-margin_left exp = 7 ).
    cl_abap_unit_assert=>assert_equals( act = ls_form-template-sample_json exp = lv_sample ).
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_api=>interface_of( ls_form-template-html_content ) exp = `IS_CERT=ZPDF_S_DEMO_CERT` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_images ) exp = 1 ).
    READ TABLE lt_images INTO ls_image INDEX 1.
    cl_abap_unit_assert=>assert_equals( act = ls_image-asset-asset_id exp = `ZPDF_T_LOGO` ).
    cl_abap_unit_assert=>assert_equals( act = ls_image-asset-filename exp = `logo.png` ).
    cl_abap_unit_assert=>assert_equals( act = ls_image-asset-description exp = `Logo` ).
    cl_abap_unit_assert=>assert_equals( act = ls_image-content exp = lv_image ).
  ENDMETHOD.

  METHOD wrong_file_is_refused.
    DATA lt_forms TYPE zcl_pdf_studio_demos=>ty_forms.
    TRY.
        zcl_pdf_studio_demos=>parse_pack( EXPORTING iv_pack = `<!doctype html><html></html>` IMPORTING et_forms = lt_forms ).
        cl_abap_unit_assert=>fail( 'A file that is not a demo pack must be refused' ).
      CATCH zcx_pdf_studio.
        cl_abap_unit_assert=>assert_initial( lt_forms ).
    ENDTRY.
  ENDMETHOD.

  METHOD order_fields.
    DATA ls_data TYPE ty_order.
    DATA lv_out TYPE string.
    zcl_pdf_studio_demos=>order( EXPORTING iv_rows = 3 IMPORTING es_order = ls_data-is_order et_items = ls_data-it_items ev_note = ls_data-iv_note ).
    lv_out = zcl_pdf_studio_binder=>render(
      iv_template = `{{IS_ORDER.EBELN}}|{{IS_ORDER.BEDAT | YYYY}}|{{IS_ORDER.EINDT | DD.MM.YYYY}}|{{IS_ORDER.LIFNR}}|{{IS_ORDER.VENDOR_NAME}}|` &&
                    `{{IS_ORDER.VENDOR_ADDR}}|{{IS_ORDER.VENDOR_TAXNO}}|{{IS_ORDER.BUYER}}|{{IS_ORDER.PAYTERMS}}|{{IS_ORDER.WAERS}}|` &&
                    `net={{IS_ORDER.NETWR | #.##0,00}}|tax={{IS_ORDER.TAX_AMOUNT | #.##0,00}}|total={{IS_ORDER.TOTAL | #.##0,00}}|` &&
                    `{{IS_ORDER.TOTAL | WORDS:TRY|UPPER}}|{{#if IS_ORDER.URGENT}}URGENT{{/if}}|{{IV_NOTE}}|` &&
                    `{{#each IT_ITEMS}}[{{POSNR}};{{MATNR}};{{MAKTX}};{{MENGE | #.##0,00}};{{MEINS}};{{NETPR | #.##0,00}};{{NETWR | #.##0,00}}]{{/each}}`
      is_data     = ls_data
      iv_lang     = 'T' ).
    has( iv_text = lv_out iv_part = `4500012345|` && sy-datum(4) ).
    has( iv_text = lv_out iv_part = `net=18.650,00|tax=3.730,00|total=22.380,00|` ).
    has( iv_text = lv_out iv_part = `SEKSEN TÜRK LİRASI` ).
    has( iv_text = lv_out iv_part = `|URGENT|Malzemeler sertifikalı` ).
    has( iv_text = lv_out iv_part = `[10;ST-304-2MM;Paslanmaz sac 304 kalite 2 mm;120,00;KG;95,00;11.400,00]` ).
    has( iv_text = lv_out iv_part = `[30;RL-6204;` ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_data-it_items ) exp = 3 ).
  ENDMETHOD.

  METHOD certificate_fields.
    DATA ls_data TYPE ty_cert.
    DATA lv_out TYPE string.
    ls_data-is_cert = zcl_pdf_studio_demos=>certificate( ).
    lv_out = zcl_pdf_studio_binder=>render(
      iv_template = `{{IS_CERT.CERT_NO}}|{{IS_CERT.FULL_NAME}}|{{IS_CERT.COURSE}}|{{IS_CERT.HOURS}}|{{IS_CERT.START_DATE | D MMMM YYYY}}|` &&
                    `{{IS_CERT.END_DATE | D MMMM YYYY}}|{{IS_CERT.ISSUE_DATE | YYYY}}|{{IS_CERT.TRAINER}}|{{IS_CERT.MANAGER}}|{{IS_CERT.CITY}}|` &&
                    `{{IS_CERT.SCORE | #.##0,00}}|{{IS_CERT.VERIFY_URL}}|{{#if IS_CERT.HONORS}}HONORS{{/if}}`
      is_data     = ls_data
      iv_lang     = 'T' ).
    has( iv_text = lv_out iv_part = `SRT-2026-0147|Elif Kaya|ABAP ile PDF Form Geliştirme|40|` ).
    has( iv_text = lv_out iv_part = `|Dr. Mehmet Aydın|Zeynep Arslan|Kayseri|94,50|https://example.com/sertifika/SRT-2026-0147|HONORS` ).
  ENDMETHOD.

  METHOD ticket_fields.
    DATA ls_data TYPE ty_ticket.
    DATA lv_out TYPE string.
    ls_data-is_ticket = zcl_pdf_studio_demos=>ticket( ).
    lv_out = zcl_pdf_studio_binder=>render(
      iv_template = `{{IS_TICKET.TICKET_NO}}|{{IS_TICKET.EVENT}}|{{IS_TICKET.ARTIST}}|{{IS_TICKET.VENUE}}|{{IS_TICKET.CITY}}|` &&
                    `{{IS_TICKET.EVENT_DATE | D MMMM YYYY, dddd}}|{{IS_TICKET.EVENT_DATE | DD.MM.YYYY}}|{{IS_TICKET.DOORS | HH:mm}}|` &&
                    `{{IS_TICKET.START_TIME | HH:mm}}|{{IS_TICKET.BLOCK}}|{{IS_TICKET.SEAT_ROW}}|{{IS_TICKET.SEAT_NO}}|{{IS_TICKET.GATE}}|` &&
                    `{{IS_TICKET.HOLDER}}|{{IS_TICKET.CATEGORY}}|{{IS_TICKET.PRICE | #.##0,00}}|{{IS_TICKET.WAERS}}|` &&
                    `{{#if IS_TICKET.VIP}}VIP{{/if}}|{{IS_TICKET.BARCODE}}`
      is_data     = ls_data
      iv_lang     = 'T' ).
    has( iv_text = lv_out iv_part = `BLT-00482719|Anadolu Senfoni Gecesi|Kayseri Filarmoni Orkestrası|Kadir Has Kongre Merkezi|Kayseri|` ).
    has( iv_text = lv_out iv_part = `|19:00|20:30|B|12|27|3|Elif Kaya|Parter|750,00|TRY|VIP|BLT00482719` ).
  ENDMETHOD.

  METHOD delivery_fields.
    DATA ls_data TYPE ty_delivery.
    DATA lv_out TYPE string.
    zcl_pdf_studio_demos=>delivery( EXPORTING iv_rows = 3 IMPORTING es_delivery = ls_data-is_delivery et_items = ls_data-it_items ).
    lv_out = zcl_pdf_studio_binder=>render(
      iv_template = `{{IS_DELIVERY.VBELN}}|{{IS_DELIVERY.WADAT | YYYY}}|{{IS_DELIVERY.SHIP_TO_NAME}}|{{IS_DELIVERY.SHIP_TO_ADDR}}|` &&
                    `{{IS_DELIVERY.SHIP_TO_CITY}}|{{IS_DELIVERY.SHIP_TO_PHONE}}|{{IS_DELIVERY.CARRIER}}|{{IS_DELIVERY.TRACKING}}|` &&
                    `{{IS_DELIVERY.GTIN14}}|{{IS_DELIVERY.PLATE}}|{{IS_DELIVERY.DRIVER}}|{{IS_DELIVERY.GROSS_WEIGHT | #.##0,00}}|` &&
                    `{{IS_DELIVERY.PACKAGES}}|{{#if IS_DELIVERY.EXPRESS}}EXPRESS{{/if}}|{{#if IS_DELIVERY.FRAGILE}}FRAGILE{{/if}}|` &&
                    `{{#each IT_ITEMS}}[{{POSNR}};{{MATNR}};{{MAKTX}};{{EAN}};{{CHARG}};{{LGORT}};{{LFIMG | #.##0}};{{MEINS}}]{{/each}}`
      is_data     = ls_data
      iv_lang     = 'T' ).
    has( iv_text = lv_out iv_part = `8000456789|` && sy-datum(4) && `|Ege Yapı Market A.Ş.|` ).
    has( iv_text = lv_out iv_part = `|Anadolu Lojistik|AL2611210047|1869000000001|38 ABC 123|Hasan Yılmaz|200,00|8|EXPRESS|FRAGILE|` ).
    has( iv_text = lv_out iv_part = `[10;MT-5M-KLT;Şerit metre 5 m (kilitli);8690000000019;P2611A;1000;240;AD]` ).
    has( iv_text = lv_out iv_part = `[30;EL-IS-L;` ).
  ENDMETHOD.

  METHOD payment_fields.
    DATA ls_data TYPE ty_payment.
    DATA lv_out TYPE string.
    ls_data-input = zcl_pdf_studio_demos=>payment( 3 ).
    lv_out = zcl_pdf_studio_binder=>render(
      iv_template = `{{INPUT.BUKRS}}|{{INPUT.COMPANY}}|{{INPUT.ORDER_NO}}|{{INPUT.ORDER_DATE | YYYY}}|{{INPUT.VALUE_DATE | DD.MM.YYYY}}|` &&
                    `{{INPUT.BANK}}|{{INPUT.BRANCH}}|{{INPUT.IBAN}}|{{INPUT.WAERS}}|{{INPUT.TOTAL | #.##0,00}}|{{INPUT.TOTAL | WORDS:TRY|UPPER}}|` &&
                    `{{INPUT.ITEM_COUNT}}|{{#if INPUT.EFT}}EFT{{/if}}{{#if INPUT.HAVALE}}HAVALE{{/if}}{{#if INPUT.SWIFT}}SWIFT{{/if}}|` &&
                    `{{INPUT.SIGNER1}}|{{INPUT.SIGNER2}}|` &&
                    `{{#each INPUT.ITEMS}}[{{RECEIVER}};{{RECEIVER_IBAN}};{{RECEIVER_BANK}};{{SGTXT}};{{WRBTR | #.##0,00}};{{WAERS}}]{{/each}}`
      is_data     = ls_data
      iv_lang     = 'T' ).
    has( iv_text = lv_out iv_part = `1000|Nova Endüstri A.Ş.|OT-2026-0318|` && sy-datum(4) ).
    has( iv_text = lv_out iv_part = `|TRY|148.750,00|` ).
    has( iv_text = lv_out iv_part = `|3|EFT|Zeynep Arslan|Murat Çelik|` ).
    has( iv_text = lv_out iv_part = `[Anadolu Lojistik A.Ş.;TR00 0000 0000 0000 0000 0000 03;Ege Bank;Kasım nakliye bedeli;41.370,00;TRY]` ).
  ENDMETHOD.

  METHOD order_prints.
    "The whole way to a PDF, with a table that needs more than one page.
    CONSTANTS lc_magic TYPE x LENGTH 4 VALUE '25504446'.
    DATA ls_data TYPE ty_order.
    DATA lv_pdf TYPE xstring.
    DATA lv_head TYPE x LENGTH 4.
    zcl_pdf_studio_demos=>order( EXPORTING iv_rows = 80 IMPORTING es_order = ls_data-is_order et_items = ls_data-it_items ev_note = ls_data-iv_note ).
    lv_pdf = zcl_pdf_studio_api=>render_html(
      iv_html = `<section><div style="position:absolute;left:0mm;top:0mm;width:80mm;height:8mm;font-size:12pt;">{{IS_ORDER.EBELN}}</div>` &&
                `<table style="margin-top:12mm;width:180mm;border-collapse:collapse;"><thead style="display:table-header-group"><tr><td>Malzeme</td><td>Tutar</td></tr></thead>` &&
                `<tbody>{{#each IT_ITEMS}}<tr><td>{{MAKTX}}</td><td>{{NETWR | #.##0,00}}</td></tr>{{/each}}</tbody></table></section>`
      is_data = ls_data
      iv_lang = 'T' ).
    cl_abap_unit_assert=>assert_true( xsdbool( xstrlen( lv_pdf ) > 2000 ) ).
    lv_head = lv_pdf(4).
    cl_abap_unit_assert=>assert_equals( act = lv_head exp = lc_magic ).
  ENDMETHOD.

  METHOD installed_forms_print.
    "Once the demo pack is installed, every demo form is printed with its demo data (the real
    "forms with their images). Before the installation there is nothing to check.
    CONSTANTS lc_magic TYPE x LENGTH 4 VALUE '25504446'.
    DATA ls_order TYPE ty_order.
    DATA ls_cert TYPE ty_cert.
    DATA ls_ticket TYPE ty_ticket.
    DATA ls_delivery TYPE ty_delivery.
    DATA ls_payment TYPE ty_payment.
    DATA lt_params TYPE zcl_pdf_studio_api=>ty_params.
    DATA lv_pdf TYPE xstring.
    DATA lv_head TYPE x LENGTH 4.
    DATA lv_form TYPE string.
    DATA lt_done TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    zcl_pdf_studio_demos=>order( EXPORTING iv_rows = 30 IMPORTING es_order = ls_order-is_order et_items = ls_order-it_items ev_note = ls_order-iv_note ).
    ls_cert-is_cert = zcl_pdf_studio_demos=>certificate( ).
    ls_ticket-is_ticket = zcl_pdf_studio_demos=>ticket( ).
    zcl_pdf_studio_demos=>delivery( EXPORTING iv_rows = 30 IMPORTING es_delivery = ls_delivery-is_delivery et_items = ls_delivery-it_items ).
    ls_payment-input = zcl_pdf_studio_demos=>payment( 12 ).

    DO 5 TIMES.
      CLEAR lt_params.
      CASE sy-index.
        WHEN 1.
          lv_form = zcl_pdf_studio_demos=>c_order.
          lt_params = VALUE #( ( name = `IS_ORDER` value = REF #( ls_order-is_order ) ) ( name = `IT_ITEMS` value = REF #( ls_order-it_items ) )
                               ( name = `IV_NOTE` value = REF #( ls_order-iv_note ) ) ).
        WHEN 2.
          lv_form = zcl_pdf_studio_demos=>c_cert.
          lt_params = VALUE #( ( name = `IS_CERT` value = REF #( ls_cert-is_cert ) ) ).
        WHEN 3.
          lv_form = zcl_pdf_studio_demos=>c_ticket.
          lt_params = VALUE #( ( name = `IS_TICKET` value = REF #( ls_ticket-is_ticket ) ) ).
        WHEN 4.
          lv_form = zcl_pdf_studio_demos=>c_delivery.
          lt_params = VALUE #( ( name = `IS_DELIVERY` value = REF #( ls_delivery-is_delivery ) ) ( name = `IT_ITEMS` value = REF #( ls_delivery-it_items ) ) ).
        WHEN 5.
          lv_form = zcl_pdf_studio_demos=>c_payment.
          lt_params = VALUE #( ( name = `INPUT` value = REF #( ls_payment-input ) ) ).
      ENDCASE.
      IF zcl_pdf_studio_demos=>installed( lv_form ) = abap_false.
        CONTINUE.
      ENDIF.
      lv_pdf = zcl_pdf_studio_api=>render_form( iv_form_id = lv_form it_params = lt_params iv_lang = 'T' ).
      cl_abap_unit_assert=>assert_true( act = xsdbool( xstrlen( lv_pdf ) > 3000 ) msg = lv_form ).
      lv_head = lv_pdf(4).
      cl_abap_unit_assert=>assert_equals( act = lv_head exp = lc_magic msg = lv_form ).
      APPEND lv_form TO lt_done.
    ENDDO.
    "Nothing installed yet is not an error.
    cl_abap_unit_assert=>assert_true( xsdbool( lines( lt_done ) <= 5 ) ).
  ENDMETHOD.

ENDCLASS.
