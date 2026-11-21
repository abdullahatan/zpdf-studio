CLASS ltc_format DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS dates FOR TESTING.
    METHODS date_texts FOR TESTING.
    METHODS numbers FOR TESTING.
    METHODS words FOR TESTING.
    METHODS texts FOR TESTING.
    METHODS parsing FOR TESTING.
    METHODS binder_formats FOR TESTING RAISING zcx_pdf_studio.
ENDCLASS.


CLASS ltc_format IMPLEMENTATION.

  METHOD dates.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `20261120` iv_pattern = `DD.MM.YYYY` iv_kind = 'D' )
      exp = `20.11.2026` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `20261120` iv_pattern = `MM/DD/YY` iv_kind = 'D' )
      exp = `11/20/26` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `20260105` iv_pattern = `ISO` iv_kind = 'D' )
      exp = `2026-01-05` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `2026-11-20 14:05` iv_pattern = `DD.MM.YYYY HH:mm` )
      exp = `20.11.2026 14:05` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `143005` iv_pattern = `HH:mm:ss` iv_kind = 'T' )
      exp = `14:30:05` ).
  ENDMETHOD.

  METHOD date_texts.
    "20 November 2026 is a Friday.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `20261120` iv_pattern = `D MMMM YYYY dddd` iv_kind = 'D' iv_lang = 'T' )
      exp = `20 Kasım 2026 Cuma` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `20260301` iv_pattern = `dddd, MMMM D, YYYY` iv_kind = 'D' iv_lang = 'E' )
      exp = `Sunday, March 1, 2026` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `20261231` iv_pattern = `DD. MMM YYYY` iv_kind = 'D' iv_lang = 'D' )
      exp = `31. Dez 2026` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `20261120` iv_pattern = `'Tarih:' DD.MM.YYYY` iv_kind = 'D' )
      exp = `Tarih: 20.11.2026` ).
  ENDMETHOD.

  METHOD numbers.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `1234567.891` iv_pattern = `#.##0,00` iv_kind = 'N' )
      exp = `1.234.567,89` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `1234.5` iv_pattern = `#,##0.00 ₺` iv_kind = 'N' )
      exp = `1,234.50 ₺` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `-1234.5` iv_pattern = `€ #,##0.00;(€ #,##0.00)` iv_kind = 'N' )
      exp = `(€ 1,234.50)` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `-7` iv_pattern = `0.0` iv_kind = 'N' )
      exp = `-7.0` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `18` iv_pattern = `%0` iv_kind = 'N' )
      exp = `%18` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `0.125` iv_pattern = `0.00` iv_kind = 'N' )
      exp = `0.13` ).
  ENDMETHOD.

  METHOD words.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>amount_in_words( iv_amount = '1250.50' iv_currency = 'TRY' iv_lang = 'T' )
      exp = `bin iki yüz elli Türk lirası elli kuruş` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>amount_in_words( iv_amount = '2001000' iv_currency = 'TRY' iv_lang = 'T' )
      exp = `iki milyon bin Türk lirası` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>amount_in_words( iv_amount = '71.05' iv_currency = 'EUR' iv_lang = 'E' )
      exp = `seventy-one euros and five cents` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>number_in_words( iv_number = '1021' iv_lang = 'D' )
      exp = `eintausendeinundzwanzig` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `70` iv_pattern = `WORDS:TRY|UPPER` iv_lang = 'T' )
      exp = `YETMİŞ TÜRK LİRASI` ).
  ENDMETHOD.

  METHOD texts.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `0000012345` iv_pattern = `ALPHA` )
      exp = `12345` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>upper( iv_text = `istanbul ılık` iv_lang = 'T' )
      exp = `İSTANBUL ILIK` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_format=>format( iv_value = `İZMİR` iv_pattern = `TITLE` iv_lang = 'T' )
      exp = `İzmir` ).
  ENDMETHOD.

  METHOD parsing.
    DATA lv_date TYPE d.
    DATA lv_ok TYPE abap_bool.
    DATA lv_num TYPE decfloat34.
    zcl_pdf_studio_format=>parse_date( EXPORTING iv_text = `5.3.2026` IMPORTING ev_date = lv_date ev_ok = lv_ok ).
    cl_abap_unit_assert=>assert_equals( act = lv_date exp = '20260305' ).
    zcl_pdf_studio_format=>parse_date( EXPORTING iv_text = `2026-13-01` IMPORTING ev_ok = lv_ok ).
    cl_abap_unit_assert=>assert_false( lv_ok ).
    zcl_pdf_studio_format=>parse_number( EXPORTING iv_text = `1.234,50` IMPORTING ev_value = lv_num ev_ok = lv_ok ).
    cl_abap_unit_assert=>assert_equals( act = lv_num exp = '1234.5' ).
  ENDMETHOD.

  METHOD binder_formats.
    TYPES: BEGIN OF ty_item,
             amount TYPE p LENGTH 8 DECIMALS 2,
           END OF ty_item,
           BEGIN OF ty_doc,
             date  TYPE d,
             total TYPE p LENGTH 8 DECIMALS 2,
             name  TYPE string,
             items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,
           END OF ty_doc.
    DATA ls_doc TYPE ty_doc.
    ls_doc-date = '20261120'.
    ls_doc-total = '1250.5'.
    ls_doc-name = `ılgaz`.
    ls_doc-items = VALUE #( ( amount = '10' ) ( amount = '2.5' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_binder=>render(
              iv_template = `{{DATE | D MMMM YYYY}};{{TOTAL | #.##0,00 ₺}};<span data-fmt="DD/MM/YYYY">{{DATE}}</span>;` &&
                            `{{NAME | UPPER}};{{#each ITEMS}}{{AMOUNT | 0.0}} {{/each}};{{sum ITEMS.AMOUNT | #,##0.00}};{{TOTAL | WORDS:TRY}}`
              is_data     = ls_doc
              iv_lang     = 'T' )
      exp = `20 Kasım 2026;1.250,50 ₺;<span data-fmt="DD/MM/YYYY">20/11/2026</span>;ILGAZ;10.0 2.5 ;12.50;` &&
            `bin iki yüz elli Türk lirası elli kuruş` ).
  ENDMETHOD.

ENDCLASS.
