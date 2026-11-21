class ZCL_PDF_STUDIO_CONV definition
  public
  final
  create private .

public section.

  class-methods STRING_TO_XSTRING
    importing
      !IV_STRING type STRING
    returning
      value(RV_XSTRING) type XSTRING
    raising
      ZCX_PDF_STUDIO .
  class-methods XSTRING_TO_STRING
    importing
      !IV_XSTRING type XSTRING
    returning
      value(RV_STRING) type STRING
    raising
      ZCX_PDF_STUDIO .
  class-methods BASE64URL_DECODE
    importing
      !IV_B64 type STRING
    returning
      value(RV_STRING) type STRING
    raising
      ZCX_PDF_STUDIO .
  class-methods BASE64_DECODE
    importing
      !IV_B64 type STRING
    returning
      value(RV_STRING) type STRING
    raising
      ZCX_PDF_STUDIO .
  "! zlib stream (FlateDecode) of the data: raw deflate from CL_ABAP_GZIP with zlib header and
  "! Adler-32 trailer. Returns nothing when compression is not available.
  class-methods DEFLATE
    importing
      !IV_DATA type XSTRING
    returning
      value(RV_ZLIB) type XSTRING .
  class-methods ADLER32
    importing
      !IV_DATA type XSTRING
    returning
      value(RV_SUM) type XSTRING .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_PDF_STUDIO_CONV IMPLEMENTATION.


  METHOD string_to_xstring.
    IF iv_string IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lo_out) = cl_abap_conv_out_ce=>create( encoding = 'UTF-8' ).
        lo_out->convert(
          EXPORTING
            data   = iv_string
          IMPORTING
            buffer = rv_xstring ).
      CATCH cx_root INTO DATA(lx_error).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING
            previous = lx_error
            message  = |UTF-8 encode failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.


  METHOD xstring_to_string.
    IF iv_xstring IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lo_in) = cl_abap_conv_in_ce=>create(
          input    = iv_xstring
          encoding = 'UTF-8' ).
        lo_in->read( IMPORTING data = rv_string ).
      CATCH cx_root INTO DATA(lx_error).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING
            previous = lx_error
            message  = |UTF-8 decode failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.


  METHOD base64_decode.
    DATA lv_b64 TYPE string.
    lv_b64 = iv_b64.
    CONDENSE lv_b64 NO-GAPS.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_b64 WITH ''.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf+0(1) IN lv_b64 WITH ''.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_b64 WITH ''.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_b64 WITH ''.
    IF lv_b64 IS INITIAL.
      RETURN.
    ENDIF.
    rv_string = xstring_to_string( cl_http_utility=>decode_x_base64( lv_b64 ) ).
  ENDMETHOD.


  METHOD base64url_decode.
    DATA lv_b64 TYPE string.
    DATA lv_len TYPE i.
    DATA lv_mod TYPE i.

    lv_b64 = iv_b64.
    CONDENSE lv_b64 NO-GAPS.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_b64 WITH ''.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf+0(1) IN lv_b64 WITH ''.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_b64 WITH ''.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_b64 WITH ''.
    REPLACE ALL OCCURRENCES OF '-' IN lv_b64 WITH '+'.
    REPLACE ALL OCCURRENCES OF '_' IN lv_b64 WITH '/'.

    IF lv_b64 IS INITIAL.
      RETURN.
    ENDIF.

    lv_len = strlen( lv_b64 ).
    lv_mod = lv_len MOD 4.
    IF lv_mod = 2.
      lv_b64 = lv_b64 && '=='.
    ELSEIF lv_mod = 3.
      lv_b64 = lv_b64 && '='.
    ELSEIF lv_mod = 1.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = 'Designer payload is not valid base64url'.
    ENDIF.

    rv_string = xstring_to_string( cl_http_utility=>decode_x_base64( lv_b64 ) ).
  ENDMETHOD.


  METHOD deflate.
    DATA lv_raw TYPE xstring.
    DATA lv_head TYPE x LENGTH 2.
    DATA lv_sum TYPE xstring.
    IF iv_data IS INITIAL.
      RETURN.
    ENDIF.
    TRY.
        cl_abap_gzip=>compress_binary(
          EXPORTING
            raw_in         = iv_data
            compress_level = 6
          IMPORTING
            gzip_out       = lv_raw ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
    IF lv_raw IS INITIAL.
      RETURN.
    ENDIF.
    lv_head = '789C'.
    lv_sum = adler32( iv_data ).
    CONCATENATE lv_head lv_raw lv_sum INTO rv_zlib IN BYTE MODE.
  ENDMETHOD.


  METHOD adler32.
    CONSTANTS lc_mod TYPE i VALUE 65521.
    "INT8: the sums of a block of 5552 bytes exceed the signed 32-bit range of type I
    "(5552 is the zlib limit for unsigned 32-bit sums).
    DATA lv_a TYPE int8 VALUE 1.
    DATA lv_b TYPE int8.
    DATA lv_len TYPE i.
    DATA lv_off TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_int TYPE i.
    DATA lv_block TYPE i.
    DATA lv_small TYPE i.
    DATA lv_x2 TYPE x LENGTH 2.

    lv_len = xstrlen( iv_data ).
    WHILE lv_off < lv_len.
      lv_block = nmin( val1 = 5552 val2 = lv_len - lv_off ).
      DO lv_block TIMES.
        lv_byte = iv_data+lv_off(1).
        lv_int = lv_byte.
        lv_a = lv_a + lv_int.
        lv_b = lv_b + lv_a.
        lv_off = lv_off + 1.
      ENDDO.
      lv_a = lv_a MOD lc_mod.
      lv_b = lv_b MOD lc_mod.
    ENDWHILE.
    lv_small = lv_b.
    lv_x2 = lv_small.
    rv_sum = lv_x2.
    lv_small = lv_a.
    lv_x2 = lv_small.
    CONCATENATE rv_sum lv_x2 INTO rv_sum IN BYTE MODE.
  ENDMETHOD.
ENDCLASS.
