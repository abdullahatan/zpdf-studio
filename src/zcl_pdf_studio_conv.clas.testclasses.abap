CLASS ltc_conv DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS adler32_known_values FOR TESTING RAISING zcx_pdf_studio.
    METHODS adler32_long_input FOR TESTING.
    METHODS deflate_round_trip FOR TESTING.
ENDCLASS.

CLASS ltc_conv IMPLEMENTATION.

  METHOD adler32_known_values.
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_conv=>adler32( zcl_pdf_studio_conv=>string_to_xstring( `abc` ) ) exp = '024D0127' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_conv=>adler32( zcl_pdf_studio_conv=>string_to_xstring( `Wikipedia` ) ) exp = '11E60398' ).
  ENDMETHOD.

  METHOD adler32_long_input.
    "100,000 bytes FF: the sums of one 5552-byte block do not fit into type I (dump COMPUTE_INT_PLUS_OVERFLOW
    "with the alpha channel of a transparent PNG). Reference value: zlib.
    DATA lv_data TYPE xstring.
    DATA lv_ff TYPE x LENGTH 1 VALUE 'FF'.
    DO 100000 TIMES.
      CONCATENATE lv_data lv_ff INTO lv_data IN BYTE MODE.
    ENDDO.
    cl_abap_unit_assert=>assert_equals( act = zcl_pdf_studio_conv=>adler32( lv_data ) exp = '149A302C' ).
  ENDMETHOD.

  METHOD deflate_round_trip.
    DATA lv_data TYPE xstring.
    DATA lv_zip TYPE xstring.
    DATA lv_raw TYPE xstring.
    DATA lv_back TYPE xstring.
    DATA lv_sum TYPE xstring.
    DATA lv_len TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DO 60000 TIMES.
      lv_byte = ( sy-index * 7 ) MOD 256.
      CONCATENATE lv_data lv_byte INTO lv_data IN BYTE MODE.
    ENDDO.
    lv_zip = zcl_pdf_studio_conv=>deflate( lv_data ).
    cl_abap_unit_assert=>assert_not_initial( lv_zip ).
    "zlib stream: 2 header bytes, raw deflate, 4 bytes Adler-32 of the data.
    lv_len = xstrlen( lv_zip ) - 6.
    lv_raw = lv_zip+2(lv_len).
    cl_abap_gzip=>decompress_binary( EXPORTING gzip_in = lv_raw IMPORTING raw_out = lv_back ).
    cl_abap_unit_assert=>assert_equals( act = lv_back exp = lv_data ).
    lv_len = xstrlen( lv_zip ) - 4.
    lv_sum = lv_zip+lv_len(4).
    cl_abap_unit_assert=>assert_equals( act = lv_sum exp = zcl_pdf_studio_conv=>adler32( lv_data ) ).
  ENDMETHOD.

ENDCLASS.
