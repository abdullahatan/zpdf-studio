CLASS ltc_text DEFINITION DEFERRED.
CLASS zcl_pdf_studio_text DEFINITION LOCAL FRIENDS ltc_text.

CLASS ltc_text DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS fixed_text FOR TESTING.
    METHODS one_value FOR TESTING.
    METHODS value_first FOR TESTING.
    METHODS value_last FOR TESTING.
    METHODS four_values FOR TESTING.
    METHODS long_text FOR TESTING.
    METHODS similar_texts FOR TESTING.
    METHODS unknown_text FOR TESTING.
    METHODS catalog_consistent FOR TESTING.
    METHODS no_entry_hidden FOR TESTING.
ENDCLASS.

CLASS ltc_text IMPLEMENTATION.

  METHOD fixed_text.
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `Form ID is empty` ) exp = `Form adı boş` ).
    "A fixed text must match completely.
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `Form ID is empty!` ) exp = `Form ID is empty!` ).
  ENDMETHOD.

  METHOD one_value.
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `Form ZPDF_DEMO does not exist` ) exp = `ZPDF_DEMO formu yok` ).
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `Asset ID "a b" is invalid: use A-Z, 0-9 and _ (max. 30 characters)` )
                                        exp = `"a b" adı geçersiz: A-Z, 0-9 ve _ kullanın (en fazla 30 karakter)` ).
  ENDMETHOD.

  METHOD value_first.
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `ZPDF_X is not a structure or table type` )
                                        exp = `ZPDF_X bir yapı veya tablo tipi değil` ).
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `ean8: 7 or 8 digits are needed ("12")` )
                                        exp = `ean8: 7 veya 8 basamak gerekli ("12")` ).
  ENDMETHOD.

  METHOD value_last.
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `Unknown template field: INPUT.BUKRS` )
                                        exp = `Bilinmeyen alan: INPUT.BUKRS (arayüzde böyle bir alan yok)` ).
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `Transport request could not be chosen: ` )
                                        exp = `Transport talebi seçilemedi: ` ).
  ENDMETHOD.

  METHOD four_values.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_text=>turkish( `Form could not be added to request DEVK900123: Request is locked (message TK 105)` )
      exp = `Form DEVK900123 talebine eklenemedi: Request is locked (ileti TK 105)` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_text=>turkish( `Form could not be added to request DEVK900123: Request is locked` )
      exp = `Form DEVK900123 talebine eklenemedi: Request is locked` ).
  ENDMETHOD.

  METHOD long_text.
    "The text exactly as ZCL_PDF_STUDIO_REPO builds it from two parts.
    DATA lv_english TYPE string.
    DATA lv_turkish TYPE string.
    lv_english = |This client does not allow transports (SCC4: changes without automatic recording, no transports allowed). | &&
                 |In SCC4 set client 100 to "Automatic recording of changes" or "Changes without automatic recording", then try again.|.
    lv_turkish = zcl_pdf_studio_text=>turkish( lv_english ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_turkish CS `SCC4'te 100 üst birimini` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_turkish CS `client` ) ).
  ENDMETHOD.

  METHOD similar_texts.
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `Unclosed {{ in template` ) exp = `Form tasarımında kapatılmamış {{ var` ).
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `Unclosed {{{ in template` ) exp = `Form tasarımında kapatılmamış {{{ var` ).
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `No transport request was chosen.` ) exp = `Transport talebi seçilmedi.` ).
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `Unknown template field in SUM: ITEMS.X` )
                                        exp = `SUM işlevinde bilinmeyen alan: ITEMS.X (arayüzde böyle bir alan yok)` ).
  ENDMETHOD.

  METHOD unknown_text.
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( `Some other error 4711` ) exp = `Some other error 4711` ).
    cl_abap_unit_assert=>assert_initial( zcl_pdf_studio_text=>turkish( `` ) ).
  ENDMETHOD.

  METHOD catalog_consistent.
    "Every hole of the English text is used in the Turkish text and the other way round.
    DATA lt_catalog TYPE zcl_pdf_studio_text=>ty_entries.
    DATA ls_entry TYPE zcl_pdf_studio_text=>ty_entry.
    DATA lv_hole TYPE string.
    lt_catalog = zcl_pdf_studio_text=>catalog( ).
    cl_abap_unit_assert=>assert_true( xsdbool( lines( lt_catalog ) > 80 ) ).
    LOOP AT lt_catalog INTO ls_entry.
      cl_abap_unit_assert=>assert_not_initial( act = ls_entry-tr msg = ls_entry-en ).
      DO 9 TIMES.
        lv_hole = |&{ sy-index }|.
        cl_abap_unit_assert=>assert_equals(
          act = xsdbool( ls_entry-tr CS lv_hole )
          exp = xsdbool( ls_entry-en CS lv_hole )
          msg = |{ lv_hole }: { ls_entry-en }| ).
      ENDDO.
    ENDLOOP.
  ENDMETHOD.

  METHOD no_entry_hidden.
    "Every entry is found by its own English text: no earlier entry may catch it.
    DATA lt_catalog TYPE zcl_pdf_studio_text=>ty_entries.
    DATA ls_entry TYPE zcl_pdf_studio_text=>ty_entry.
    DATA lv_english TYPE string.
    DATA lv_expected TYPE string.
    DATA lv_hole TYPE string.
    DATA lv_value TYPE string.
    lt_catalog = zcl_pdf_studio_text=>catalog( ).
    LOOP AT lt_catalog INTO ls_entry.
      lv_english = ls_entry-en.
      lv_expected = ls_entry-tr.
      DO 9 TIMES.
        lv_hole = |&{ sy-index }|.
        lv_value = |V{ sy-index }|.
        REPLACE ALL OCCURRENCES OF lv_hole IN lv_english WITH lv_value.
        REPLACE ALL OCCURRENCES OF lv_hole IN lv_expected WITH lv_value.
      ENDDO.
      cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_text=>turkish( lv_english ) exp = lv_expected msg = ls_entry-en ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
