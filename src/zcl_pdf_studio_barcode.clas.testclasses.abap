CLASS ltc_barcode DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS check_digits FOR TESTING.
    METHODS ean13 FOR TESTING RAISING zcx_pdf_studio.
    METHODS invalid_input FOR TESTING.
    METHODS datamatrix_size FOR TESTING RAISING zcx_pdf_studio.
ENDCLASS.


CLASS ltc_barcode IMPLEMENTATION.

  METHOD check_digits.
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_barcode=>gs1_check( `400638133393` ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_barcode=>gs1_check( `9638507` ) exp = 4 ).
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_barcode=>gs1_check( `1540014128876` ) exp = 3 ).
  ENDMETHOD.

  METHOD ean13.
    DATA lv_modules TYPE string.
    DATA lv_text TYPE string.
    zcl_pdf_studio_barcode=>linear( EXPORTING iv_type = 'ean13' iv_value = '400638133393'
                                    IMPORTING ev_modules = lv_modules ev_text = lv_text ).
    cl_abap_unit_assert=>assert_equals( act = lv_text exp = `4006381333931` ).
    cl_abap_unit_assert=>assert_equals( act = strlen( lv_modules ) exp = 95 ).
    cl_abap_unit_assert=>assert_equals( act = substring( val = lv_modules len = 3 ) exp = `101` ).
  ENDMETHOD.

  METHOD invalid_input.
    DATA lv_modules TYPE string.
    TRY.
        zcl_pdf_studio_barcode=>linear( EXPORTING iv_type = 'ean13' iv_value = '4006381333930'
                                        IMPORTING ev_modules = lv_modules ).
        cl_abap_unit_assert=>fail( 'Wrong check digit must be rejected' ).
      CATCH zcx_pdf_studio ##NO_HANDLER.
    ENDTRY.
    TRY.
        zcl_pdf_studio_barcode=>linear( EXPORTING iv_type = 'code39' iv_value = 'abc_' IMPORTING ev_modules = lv_modules ).
        cl_abap_unit_assert=>fail( 'Code 39 has no underscore' ).
      CATCH zcx_pdf_studio ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD datamatrix_size.
    "Six digits pack into three codewords: the smallest symbol (10 x 10).
    cl_abap_unit_assert=>assert_equals( act = lines( zcl_pdf_studio_barcode=>datamatrix( `123456` ) ) exp = 10 ).
    cl_abap_unit_assert=>assert_equals( act = lines( zcl_pdf_studio_barcode=>datamatrix( `ABCDEFGHIJ` ) ) exp = 16 ).
  ENDMETHOD.

ENDCLASS.
