"! <p>Barcodes of ZPDF Studio besides QR and Code 128 (ZCL_PDF_STUDIO_CODES).</p>
"! Linear: EAN-13, EAN-8, UPC-A, Code 39, Interleaved 2 of 5 (ITF) and ITF-14.
"! 2D: DataMatrix ECC 200, square symbols 10x10 to 132x132 (ASCII encodation).
"! All symbols are returned as modules ('1' dark, '0' light) and drawn as vectors by the engine,
"! so they print sharply on any printer.
CLASS zcl_pdf_studio_barcode DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES ty_rows TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! Modules of a linear barcode without quiet zone and the human readable text.
    "! @parameter iv_type | ean13, ean8, upca, code39, itf, itf14
    "! @parameter iv_value | Data; EAN/UPC/ITF-14 accept the value with or without check digit
    CLASS-METHODS linear
      IMPORTING
        iv_type    TYPE csequence
        iv_value   TYPE csequence
      EXPORTING
        ev_modules TYPE string
        ev_text    TYPE string
      RAISING
        zcx_pdf_studio.

    "! DataMatrix ECC 200: one string of '0'/'1' per module row (no quiet zone).
    CLASS-METHODS datamatrix
      IMPORTING
        iv_text        TYPE csequence
      RETURNING
        VALUE(rt_rows) TYPE ty_rows
      RAISING
        zcx_pdf_studio.

    "! Modulo 10 check digit (GS1): weights 3 and 1 from the right-most digit.
    CLASS-METHODS gs1_check
      IMPORTING
        iv_digits       TYPE csequence
      RETURNING
        VALUE(rv_digit) TYPE i.

    CLASS-METHODS is_linear
      IMPORTING
        iv_type       TYPE csequence
      RETURNING
        VALUE(rv_yes) TYPE abap_bool.

  PRIVATE SECTION.
    TYPES ty_ints TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_size,
        size    TYPE i,
        region  TYPE i,
        regions TYPE i,
        data    TYPE i,
        ecc     TYPE i,
        blocks  TYPE i,
      END OF ty_size,
      ty_sizes TYPE STANDARD TABLE OF ty_size WITH EMPTY KEY.

    CLASS-DATA gt_exp TYPE ty_ints.
    CLASS-DATA gt_log TYPE ty_ints.
    CLASS-DATA gt_sizes TYPE ty_sizes.

    "Placement matrix of DataMatrix (instance per symbol).
    DATA mt_cells TYPE ty_ints.
    DATA mv_nrow TYPE i.
    DATA mv_ncol TYPE i.

    CLASS-METHODS ean
      IMPORTING
        iv_digits  TYPE string
      RETURNING
        VALUE(rv_modules) TYPE string.
    CLASS-METHODS code39
      IMPORTING
        iv_value          TYPE string
      RETURNING
        VALUE(rv_modules) TYPE string
      RAISING
        zcx_pdf_studio.
    CLASS-METHODS itf
      IMPORTING
        iv_digits         TYPE string
      RETURNING
        VALUE(rv_modules) TYPE string.
    CLASS-METHODS wide_narrow
      IMPORTING
        iv_pattern        TYPE string
        iv_bar_first      TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_modules) TYPE string.
    CLASS-METHODS digits_only
      IMPORTING
        iv_value       TYPE csequence
        iv_type        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        zcx_pdf_studio.
    CLASS-METHODS xor
      IMPORTING
        iv_a          TYPE i
        iv_b          TYPE i
      RETURNING
        VALUE(rv_val) TYPE i.
    CLASS-METHODS gf_init.
    CLASS-METHODS gmul
      IMPORTING
        iv_a          TYPE i
        iv_b          TYPE i
      RETURNING
        VALUE(rv_val) TYPE i.
    CLASS-METHODS rs
      IMPORTING
        it_data       TYPE ty_ints
        iv_count      TYPE i
      RETURNING
        VALUE(rt_ecc) TYPE ty_ints.
    CLASS-METHODS sizes_init.
    CLASS-METHODS bytes
      IMPORTING
        iv_text         TYPE csequence
      RETURNING
        VALUE(rt_bytes) TYPE ty_ints.
    METHODS place
      IMPORTING
        it_codewords TYPE ty_ints.
    METHODS module
      IMPORTING
        iv_row TYPE i
        iv_col TYPE i
        iv_chr TYPE i
        iv_bit TYPE i.
    METHODS utah
      IMPORTING
        iv_row TYPE i
        iv_col TYPE i
        iv_chr TYPE i.
    METHODS corner
      IMPORTING
        iv_kind TYPE i
        iv_chr  TYPE i.
    METHODS cell
      IMPORTING
        iv_row        TYPE i
        iv_col        TYPE i
      RETURNING
        VALUE(rv_val) TYPE i.
ENDCLASS.



CLASS zcl_pdf_studio_barcode IMPLEMENTATION.

  METHOD is_linear.
    DATA lv_type TYPE string.
    lv_type = to_lower( iv_type ).
    rv_yes = xsdbool( lv_type = `ean13` OR lv_type = `ean8` OR lv_type = `upca`
                   OR lv_type = `code39` OR lv_type = `itf` OR lv_type = `itf14` ).
  ENDMETHOD.


  METHOD digits_only.
    rv_text = iv_value.
    CONDENSE rv_text NO-GAPS.
    IF rv_text IS INITIAL OR rv_text CN '0123456789'.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |{ iv_type }: only digits are allowed ("{ iv_value }")|.
    ENDIF.
  ENDMETHOD.


  METHOD gs1_check.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_sum TYPE i.
    DATA lv_digit TYPE i.
    DATA lv_weight TYPE i VALUE 3.
    lv_len = strlen( iv_digits ).
    lv_i = lv_len - 1.
    WHILE lv_i >= 0.
      lv_digit = iv_digits+lv_i(1).
      lv_sum = lv_sum + lv_digit * lv_weight.
      lv_weight = 4 - lv_weight.
      lv_i = lv_i - 1.
    ENDWHILE.
    rv_digit = ( 10 - lv_sum MOD 10 ) MOD 10.
  ENDMETHOD.


  METHOD linear.
    DATA lv_type TYPE string.
    DATA lv_digits TYPE string.
    DATA lv_len TYPE i.
    DATA lv_body TYPE string.

    CLEAR: ev_modules, ev_text.
    lv_type = to_lower( iv_type ).
    CASE lv_type.
      WHEN `ean13` OR `upca`.
        lv_digits = digits_only( iv_value = iv_value iv_type = lv_type ).
        lv_len = COND #( WHEN lv_type = `ean13` THEN 12 ELSE 11 ).
        IF strlen( lv_digits ) = lv_len + 1.
          lv_body = substring( val = lv_digits len = lv_len ).
          IF gs1_check( lv_body ) <> substring( val = lv_digits off = lv_len len = 1 ).
            RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |{ lv_type }: wrong check digit in { lv_digits }|.
          ENDIF.
        ELSEIF strlen( lv_digits ) = lv_len.
          lv_digits = |{ lv_digits }{ gs1_check( lv_digits ) }|.
        ELSE.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING message = |{ lv_type }: { lv_len } or { lv_len + 1 } digits are needed ("{ iv_value }")|.
        ENDIF.
        ev_text = lv_digits.
        IF lv_type = `upca`.
          lv_digits = |0{ lv_digits }|.
        ENDIF.
        ev_modules = ean( lv_digits ).
      WHEN `ean8`.
        lv_digits = digits_only( iv_value = iv_value iv_type = lv_type ).
        IF strlen( lv_digits ) = 8.
          IF gs1_check( substring( val = lv_digits len = 7 ) ) <> substring( val = lv_digits off = 7 len = 1 ).
            RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |ean8: wrong check digit in { lv_digits }|.
          ENDIF.
        ELSEIF strlen( lv_digits ) = 7.
          lv_digits = |{ lv_digits }{ gs1_check( lv_digits ) }|.
        ELSE.
          RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |ean8: 7 or 8 digits are needed ("{ iv_value }")|.
        ENDIF.
        ev_text = lv_digits.
        ev_modules = ean( lv_digits ).
      WHEN `code39`.
        ev_text = to_upper( iv_value ).
        ev_modules = code39( ev_text ).
      WHEN `itf` OR `itf14`.
        lv_digits = digits_only( iv_value = iv_value iv_type = lv_type ).
        IF lv_type = `itf14`.
          IF strlen( lv_digits ) = 13.
            lv_digits = |{ lv_digits }{ gs1_check( lv_digits ) }|.
          ELSEIF strlen( lv_digits ) <> 14.
            RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |itf14: 13 or 14 digits are needed ("{ iv_value }")|.
          ENDIF.
        ELSEIF strlen( lv_digits ) MOD 2 = 1.
          lv_digits = |0{ lv_digits }|.
        ENDIF.
        ev_text = lv_digits.
        ev_modules = itf( lv_digits ).
      WHEN OTHERS.
        RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |Unknown barcode type { iv_type }|.
    ENDCASE.
  ENDMETHOD.


  METHOD ean.
    "L, G and R patterns of the digits 0-9; first digit of EAN-13 selects the L/G parity.
    CONSTANTS lc_l TYPE string VALUE '0001101001100100100110111101010001101100010101111011101101101110001011'.
    CONSTANTS lc_g TYPE string VALUE '0100111011001100110110100001001110101110010000101001000100010010010111'.
    CONSTANTS lc_r TYPE string VALUE '1110010110011011011001000010101110010011101010000100010010010001110100'.
    CONSTANTS lc_parity TYPE string VALUE 'LLLLLLLLGLGGLLGGLGLLGGGLLGLLGGLGGLLGLGGGLLLGLGLGLGLGGLLGGLGL'.
    DATA lv_digits TYPE string.
    DATA lv_parity TYPE string.
    DATA lv_half TYPE i.
    DATA lv_i TYPE i.
    DATA lv_d TYPE i.
    DATA lv_set TYPE c LENGTH 1.

    lv_digits = iv_digits.
    IF strlen( lv_digits ) = 13.
      lv_d = lv_digits(1).
      lv_parity = substring( val = lc_parity off = lv_d * 6 len = 6 ).
      lv_digits = lv_digits+1.
    ELSE.
      lv_parity = `LLLL`.
    ENDIF.
    lv_half = strlen( lv_digits ) / 2.
    rv_modules = `101`.
    DO lv_half TIMES.
      lv_i = sy-index - 1.
      lv_d = lv_digits+lv_i(1).
      lv_set = lv_parity+lv_i(1).
      IF lv_set = 'G'.
        rv_modules = rv_modules && substring( val = lc_g off = lv_d * 7 len = 7 ).
      ELSE.
        rv_modules = rv_modules && substring( val = lc_l off = lv_d * 7 len = 7 ).
      ENDIF.
    ENDDO.
    rv_modules = rv_modules && `01010`.
    DO lv_half TIMES.
      lv_i = lv_half + sy-index - 1.
      lv_d = lv_digits+lv_i(1).
      rv_modules = rv_modules && substring( val = lc_r off = lv_d * 7 len = 7 ).
    ENDDO.
    rv_modules = rv_modules && `101`.
  ENDMETHOD.


  METHOD wide_narrow.
    "n = narrow (1 module), w = wide (3 modules); elements alternate bar / space.
    DATA lv_i TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_bar TYPE abap_bool.
    DATA lv_unit TYPE string.
    lv_bar = iv_bar_first.
    DO strlen( iv_pattern ) TIMES.
      lv_i = sy-index - 1.
      lv_c = iv_pattern+lv_i(1).
      lv_unit = COND #( WHEN lv_bar = abap_true THEN `1` ELSE `0` ).
      rv_modules = rv_modules && lv_unit.
      IF lv_c = 'w'.
        rv_modules = rv_modules && lv_unit && lv_unit.
      ENDIF.
      lv_bar = xsdbool( lv_bar = abap_false ).
    ENDDO.
  ENDMETHOD.


  METHOD code39.
    CONSTANTS lc_chars TYPE string VALUE '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%*'.
    DATA lt_patterns TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_value TYPE string.
    DATA lv_i TYPE i.
    DATA lv_c TYPE string.
    DATA lv_pos TYPE i.
    DATA lv_pattern TYPE string.

    lt_patterns = VALUE #(
      ( `nnnwwnwnn` ) ( `wnnwnnnnw` ) ( `nnwwnnnnw` ) ( `wnwwnnnnn` ) ( `nnnwwnnnw` )
      ( `wnnwwnnnn` ) ( `nnwwwnnnn` ) ( `nnnwnnwnw` ) ( `wnnwnnwnn` ) ( `nnwwnnwnn` )
      ( `wnnnnwnnw` ) ( `nnwnnwnnw` ) ( `wnwnnwnnn` ) ( `nnnnwwnnw` ) ( `wnnnwwnnn` )
      ( `nnwnwwnnn` ) ( `nnnnnwwnw` ) ( `wnnnnwwnn` ) ( `nnwnnwwnn` ) ( `nnnnwwwnn` )
      ( `wnnnnnnww` ) ( `nnwnnnnww` ) ( `wnwnnnnwn` ) ( `nnnnwnnww` ) ( `wnnnwnnwn` )
      ( `nnwnwnnwn` ) ( `nnnnnnwww` ) ( `wnnnnnwwn` ) ( `nnwnnnwwn` ) ( `nnnnwnwwn` )
      ( `wwnnnnnnw` ) ( `nwwnnnnnw` ) ( `wwwnnnnnn` ) ( `nwnnwnnnw` ) ( `wwnnwnnnn` )
      ( `nwwnwnnnn` ) ( `nwnnnnwnw` ) ( `wwnnnnwnn` ) ( `nwwnnnwnn` ) ( `nwnwnwnnn` )
      ( `nwnwnnnwn` ) ( `nwnnnwnwn` ) ( `nnnwnwnwn` ) ( `nwnnwnwnn` ) ).

    lv_value = |*{ iv_value }*|.
    DO strlen( lv_value ) TIMES.
      lv_i = sy-index - 1.
      lv_c = substring( val = lv_value off = lv_i len = 1 ).
      lv_pos = find( val = lc_chars sub = lv_c ).
      IF lv_pos < 0 OR ( lv_c = '*' AND lv_i > 0 AND lv_i < strlen( lv_value ) - 1 ).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING message = |Code 39 cannot encode "{ lv_c }" (allowed: 0-9 A-Z - . space $ / + %)|.
      ENDIF.
      READ TABLE lt_patterns INTO lv_pattern INDEX lv_pos + 1.
      IF lv_i > 0.
        rv_modules = rv_modules && `0`.
      ENDIF.
      rv_modules = rv_modules && wide_narrow( lv_pattern ).
    ENDDO.
  ENDMETHOD.


  METHOD itf.
    DATA lt_patterns TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_i TYPE i.
    DATA lv_k TYPE i.
    DATA lv_d1 TYPE i.
    DATA lv_d2 TYPE i.
    DATA lv_p1 TYPE string.
    DATA lv_p2 TYPE string.
    DATA lv_mixed TYPE string.

    lt_patterns = VALUE #( ( `nnwwn` ) ( `wnnnw` ) ( `nwnnw` ) ( `wwnnn` ) ( `nnwnw` )
                           ( `wnwnn` ) ( `nwwnn` ) ( `nnnww` ) ( `wnnwn` ) ( `nwnwn` ) ).
    rv_modules = `1010`.
    lv_i = 0.
    WHILE lv_i + 1 < strlen( iv_digits ).
      lv_d1 = iv_digits+lv_i(1).
      lv_k = lv_i + 1.
      lv_d2 = iv_digits+lv_k(1).
      READ TABLE lt_patterns INTO lv_p1 INDEX lv_d1 + 1.
      READ TABLE lt_patterns INTO lv_p2 INDEX lv_d2 + 1.
      CLEAR lv_mixed.
      DO 5 TIMES.
        lv_k = sy-index - 1.
        lv_mixed = lv_mixed && substring( val = lv_p1 off = lv_k len = 1 ) && substring( val = lv_p2 off = lv_k len = 1 ).
      ENDDO.
      rv_modules = rv_modules && wide_narrow( lv_mixed ).
      lv_i = lv_i + 2.
    ENDWHILE.
    rv_modules = rv_modules && `11101`.
  ENDMETHOD.


  METHOD xor.
    DATA lv_a TYPE x LENGTH 4.
    DATA lv_b TYPE x LENGTH 4.
    lv_a = iv_a.
    lv_b = iv_b.
    lv_a = lv_a BIT-XOR lv_b.
    rv_val = lv_a.
  ENDMETHOD.


  METHOD gf_init.
    DATA lv_v TYPE i VALUE 1.
    IF gt_exp IS NOT INITIAL.
      RETURN.
    ENDIF.
    DO 256 TIMES.
      APPEND 0 TO gt_log.
    ENDDO.
    DO 255 TIMES.
      APPEND lv_v TO gt_exp.
      gt_log[ lv_v + 1 ] = sy-index - 1.
      lv_v = lv_v * 2.
      IF lv_v >= 256.
        lv_v = xor( iv_a = lv_v iv_b = 301 ).
      ENDIF.
    ENDDO.
  ENDMETHOD.


  METHOD gmul.
    IF iv_a = 0 OR iv_b = 0.
      RETURN.
    ENDIF.
    rv_val = gt_exp[ ( gt_log[ iv_a + 1 ] + gt_log[ iv_b + 1 ] ) MOD 255 + 1 ].
  ENDMETHOD.


  METHOD rs.
    "Reed-Solomon over GF(256), polynomial 0x12D, generator roots 2^1 .. 2^n.
    DATA lt_gen TYPE ty_ints.
    DATA lt_next TYPE ty_ints.
    DATA lv_i TYPE i.
    DATA lv_j TYPE i.
    DATA lv_root TYPE i.
    DATA lv_data TYPE i.
    DATA lv_factor TYPE i.
    DATA lv_val TYPE i.

    gf_init( ).
    lt_gen = VALUE #( ( 1 ) ).
    DO iv_count TIMES.
      lv_root = gt_exp[ sy-index MOD 255 + 1 ].
      CLEAR lt_next.
      DO lines( lt_gen ) + 1 TIMES.
        APPEND 0 TO lt_next.
      ENDDO.
      LOOP AT lt_gen INTO lv_val.
        lv_j = sy-tabix.
        lt_next[ lv_j ] = xor( iv_a = lt_next[ lv_j ] iv_b = lv_val ).
        lt_next[ lv_j + 1 ] = xor( iv_a = lt_next[ lv_j + 1 ] iv_b = gmul( iv_a = lv_val iv_b = lv_root ) ).
      ENDLOOP.
      lt_gen = lt_next.
    ENDDO.

    DO iv_count TIMES.
      APPEND 0 TO rt_ecc.
    ENDDO.
    LOOP AT it_data INTO lv_data.
      lv_factor = xor( iv_a = lv_data iv_b = rt_ecc[ 1 ] ).
      DELETE rt_ecc INDEX 1.
      APPEND 0 TO rt_ecc.
      lv_i = 1.
      WHILE lv_i <= iv_count.
        rt_ecc[ lv_i ] = xor( iv_a = rt_ecc[ lv_i ] iv_b = gmul( iv_a = lt_gen[ lv_i + 1 ] iv_b = lv_factor ) ).
        lv_i = lv_i + 1.
      ENDWHILE.
    ENDLOOP.
  ENDMETHOD.


  METHOD sizes_init.
    IF gt_sizes IS NOT INITIAL.
      RETURN.
    ENDIF.
    "Square ECC 200 symbols: size, data region, regions per side, data, ECC codewords, blocks.
    gt_sizes = VALUE #(
      ( size = 10  region = 8  regions = 1 data = 3    ecc = 5   blocks = 1 )
      ( size = 12  region = 10 regions = 1 data = 5    ecc = 7   blocks = 1 )
      ( size = 14  region = 12 regions = 1 data = 8    ecc = 10  blocks = 1 )
      ( size = 16  region = 14 regions = 1 data = 12   ecc = 12  blocks = 1 )
      ( size = 18  region = 16 regions = 1 data = 18   ecc = 14  blocks = 1 )
      ( size = 20  region = 18 regions = 1 data = 22   ecc = 18  blocks = 1 )
      ( size = 22  region = 20 regions = 1 data = 30   ecc = 20  blocks = 1 )
      ( size = 24  region = 22 regions = 1 data = 36   ecc = 24  blocks = 1 )
      ( size = 26  region = 24 regions = 1 data = 44   ecc = 28  blocks = 1 )
      ( size = 32  region = 14 regions = 2 data = 62   ecc = 36  blocks = 1 )
      ( size = 36  region = 16 regions = 2 data = 86   ecc = 42  blocks = 1 )
      ( size = 40  region = 18 regions = 2 data = 114  ecc = 48  blocks = 1 )
      ( size = 44  region = 20 regions = 2 data = 144  ecc = 56  blocks = 1 )
      ( size = 48  region = 22 regions = 2 data = 174  ecc = 68  blocks = 1 )
      ( size = 52  region = 24 regions = 2 data = 204  ecc = 84  blocks = 2 )
      ( size = 64  region = 14 regions = 4 data = 280  ecc = 112 blocks = 2 )
      ( size = 72  region = 16 regions = 4 data = 368  ecc = 144 blocks = 4 )
      ( size = 80  region = 18 regions = 4 data = 456  ecc = 192 blocks = 4 )
      ( size = 88  region = 20 regions = 4 data = 576  ecc = 224 blocks = 4 )
      ( size = 96  region = 22 regions = 4 data = 696  ecc = 272 blocks = 4 )
      ( size = 104 region = 24 regions = 4 data = 816  ecc = 336 blocks = 6 )
      ( size = 120 region = 18 regions = 6 data = 1050 ecc = 408 blocks = 6 )
      ( size = 132 region = 20 regions = 6 data = 1304 ecc = 496 blocks = 8 ) ).
  ENDMETHOD.


  METHOD bytes.
    "Latin-1 when every character fits, UTF-8 otherwise.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_cp TYPE i.
    DATA lv_utf8 TYPE abap_bool.
    DATA lv_x TYPE xstring.
    DATA lv_b TYPE x LENGTH 1.
    DATA lv_text TYPE string.

    lv_text = iv_text.
    lv_len = strlen( lv_text ).
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_c = lv_text+lv_i(1).
      lv_cp = cl_abap_conv_out_ce=>uccpi( lv_c ).
      IF lv_cp > 255.
        lv_utf8 = abap_true.
        EXIT.
      ENDIF.
      APPEND lv_cp TO rt_bytes.
    ENDDO.
    IF lv_utf8 = abap_true.
      CLEAR rt_bytes.
      TRY.
          lv_x = zcl_pdf_studio_conv=>string_to_xstring( lv_text ).
        CATCH zcx_pdf_studio.
          RETURN.
      ENDTRY.
      DO xstrlen( lv_x ) TIMES.
        lv_i = sy-index - 1.
        lv_b = lv_x+lv_i(1).
        lv_cp = lv_b.
        APPEND lv_cp TO rt_bytes.
      ENDDO.
    ENDIF.
  ENDMETHOD.


  METHOD datamatrix.
    DATA lt_bytes TYPE ty_ints.
    DATA lt_data TYPE ty_ints.
    DATA lt_block TYPE ty_ints.
    DATA lt_ecc TYPE ty_ints.
    DATA lt_all TYPE ty_ints.
    DATA ls_size TYPE ty_size.
    DATA lv_found TYPE abap_bool.
    DATA lv_i TYPE i.
    DATA lv_b1 TYPE i.
    DATA lv_b2 TYPE i.
    DATA lv_count TYPE i.
    DATA lv_pad TYPE i.
    DATA lv_block TYPE i.
    DATA lv_k TYPE i.
    DATA lv_per TYPE i.
    DATA lo_dm TYPE REF TO zcl_pdf_studio_barcode.
    DATA lv_row TYPE i.
    DATA lv_col TYPE i.
    DATA lv_val TYPE i.
    DATA lv_line TYPE string.
    DATA lv_r TYPE i.
    DATA lv_c TYPE i.
    DATA lv_size TYPE i.
    DATA lv_rr TYPE i.
    DATA lv_cc TYPE i.
    DATA lv_dark TYPE abap_bool.

    "1. ASCII encodation: digit pairs are packed (130 + value), bytes > 127 use Upper Shift.
    lt_bytes = bytes( iv_text ).
    IF lt_bytes IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'DataMatrix: no data'.
    ENDIF.
    lv_count = lines( lt_bytes ).
    lv_i = 1.
    WHILE lv_i <= lv_count.
      lv_b1 = lt_bytes[ lv_i ].
      IF lv_i < lv_count.
        lv_b2 = lt_bytes[ lv_i + 1 ].
      ELSE.
        lv_b2 = -1.
      ENDIF.
      IF lv_b1 >= 48 AND lv_b1 <= 57 AND lv_b2 >= 48 AND lv_b2 <= 57.
        APPEND 130 + ( lv_b1 - 48 ) * 10 + lv_b2 - 48 TO lt_data.
        lv_i = lv_i + 2.
      ELSEIF lv_b1 < 128.
        APPEND lv_b1 + 1 TO lt_data.
        lv_i = lv_i + 1.
      ELSE.
        APPEND 235 TO lt_data.
        APPEND lv_b1 - 127 TO lt_data.
        lv_i = lv_i + 1.
      ENDIF.
    ENDWHILE.

    "2. Smallest square symbol, padding (129, then pseudo random).
    sizes_init( ).
    LOOP AT gt_sizes INTO ls_size.
      IF ls_size-data >= lines( lt_data ).
        lv_found = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF lv_found = abap_false.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'DataMatrix: too much data (max. 1304 codewords)'.
    ENDIF.
    IF lines( lt_data ) < ls_size-data.
      APPEND 129 TO lt_data.
    ENDIF.
    WHILE lines( lt_data ) < ls_size-data.
      lv_k = lines( lt_data ) + 1.
      lv_pad = 129 + ( 149 * lv_k ) MOD 253 + 1.
      IF lv_pad > 254.
        lv_pad = lv_pad - 254.
      ENDIF.
      APPEND lv_pad TO lt_data.
    ENDWHILE.

    "3. Error correction per interleaved block.
    lt_all = lt_data.
    DO ls_size-ecc TIMES.
      APPEND 0 TO lt_all.
    ENDDO.
    lv_per = ls_size-ecc / ls_size-blocks.
    DO ls_size-blocks TIMES.
      lv_block = sy-index - 1.
      CLEAR lt_block.
      lv_k = lv_block + 1.
      WHILE lv_k <= ls_size-data.
        APPEND lt_data[ lv_k ] TO lt_block.
        lv_k = lv_k + ls_size-blocks.
      ENDWHILE.
      lt_ecc = rs( it_data = lt_block iv_count = lv_per ).
      LOOP AT lt_ecc INTO lv_val.
        lv_k = ls_size-data + ( sy-tabix - 1 ) * ls_size-blocks + lv_block + 1.
        lt_all[ lv_k ] = lv_val.
      ENDLOOP.
    ENDDO.

    "4. Module placement in the data area, then the finder patterns of every region.
    CREATE OBJECT lo_dm.
    lo_dm->mv_nrow = ls_size-region * ls_size-regions.
    lo_dm->mv_ncol = lo_dm->mv_nrow.
    lo_dm->place( lt_all ).

    lv_size = ls_size-size.
    DO lv_size TIMES.
      lv_r = sy-index - 1.
      CLEAR lv_line.
      DO lv_size TIMES.
        lv_c = sy-index - 1.
        lv_rr = lv_r MOD ( ls_size-region + 2 ).
        lv_cc = lv_c MOD ( ls_size-region + 2 ).
        IF lv_rr = ls_size-region + 1 OR lv_cc = 0.
          lv_dark = abap_true.                                  "solid bottom row and left column
        ELSEIF lv_rr = 0.
          lv_dark = xsdbool( lv_cc MOD 2 = 0 ).                 "dotted top row
        ELSEIF lv_cc = ls_size-region + 1.
          lv_dark = xsdbool( lv_rr MOD 2 = 1 ).                 "dotted right column
        ELSE.
          lv_row = lv_r DIV ( ls_size-region + 2 ) * ls_size-region + lv_rr - 1.
          lv_col = lv_c DIV ( ls_size-region + 2 ) * ls_size-region + lv_cc - 1.
          lv_val = lo_dm->cell( iv_row = lv_row iv_col = lv_col ).
          IF lv_val = 1.
            lv_dark = abap_true.
          ELSEIF lv_val >= 10.
            lv_k = lv_val DIV 10.
            lv_b1 = lt_all[ lv_k ].
            lv_b2 = lv_val MOD 10.
            "Bit 1 is the most significant bit of the codeword.
            lv_dark = xsdbool( ( lv_b1 DIV ipow( base = 2 exp = 8 - lv_b2 ) ) MOD 2 = 1 ).
          ELSE.
            lv_dark = abap_false.
          ENDIF.
        ENDIF.
        lv_line = lv_line && COND string( WHEN lv_dark = abap_true THEN `1` ELSE `0` ).
      ENDDO.
      APPEND lv_line TO rt_rows.
    ENDDO.
  ENDMETHOD.


  METHOD cell.
    rv_val = mt_cells[ iv_row * mv_ncol + iv_col + 1 ].
  ENDMETHOD.


  METHOD module.
    DATA lv_row TYPE i.
    DATA lv_col TYPE i.
    lv_row = iv_row.
    lv_col = iv_col.
    IF lv_row < 0.
      lv_row = lv_row + mv_nrow.
      lv_col = lv_col + 4 - ( mv_nrow + 4 ) MOD 8.
    ENDIF.
    IF lv_col < 0.
      lv_col = lv_col + mv_ncol.
      lv_row = lv_row + 4 - ( mv_ncol + 4 ) MOD 8.
    ENDIF.
    mt_cells[ lv_row * mv_ncol + lv_col + 1 ] = 10 * iv_chr + iv_bit.
  ENDMETHOD.


  METHOD utah.
    module( iv_row = iv_row - 2 iv_col = iv_col - 2 iv_chr = iv_chr iv_bit = 1 ).
    module( iv_row = iv_row - 2 iv_col = iv_col - 1 iv_chr = iv_chr iv_bit = 2 ).
    module( iv_row = iv_row - 1 iv_col = iv_col - 2 iv_chr = iv_chr iv_bit = 3 ).
    module( iv_row = iv_row - 1 iv_col = iv_col - 1 iv_chr = iv_chr iv_bit = 4 ).
    module( iv_row = iv_row - 1 iv_col = iv_col     iv_chr = iv_chr iv_bit = 5 ).
    module( iv_row = iv_row     iv_col = iv_col - 2 iv_chr = iv_chr iv_bit = 6 ).
    module( iv_row = iv_row     iv_col = iv_col - 1 iv_chr = iv_chr iv_bit = 7 ).
    module( iv_row = iv_row     iv_col = iv_col     iv_chr = iv_chr iv_bit = 8 ).
  ENDMETHOD.


  METHOD corner.
    DATA lv_r TYPE i.
    DATA lv_c TYPE i.
    lv_r = mv_nrow.
    lv_c = mv_ncol.
    CASE iv_kind.
      WHEN 1.
        module( iv_row = lv_r - 1 iv_col = 0 iv_chr = iv_chr iv_bit = 1 ).
        module( iv_row = lv_r - 1 iv_col = 1 iv_chr = iv_chr iv_bit = 2 ).
        module( iv_row = lv_r - 1 iv_col = 2 iv_chr = iv_chr iv_bit = 3 ).
        module( iv_row = 0 iv_col = lv_c - 2 iv_chr = iv_chr iv_bit = 4 ).
        module( iv_row = 0 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 5 ).
        module( iv_row = 1 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 6 ).
        module( iv_row = 2 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 7 ).
        module( iv_row = 3 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 8 ).
      WHEN 2.
        module( iv_row = lv_r - 3 iv_col = 0 iv_chr = iv_chr iv_bit = 1 ).
        module( iv_row = lv_r - 2 iv_col = 0 iv_chr = iv_chr iv_bit = 2 ).
        module( iv_row = lv_r - 1 iv_col = 0 iv_chr = iv_chr iv_bit = 3 ).
        module( iv_row = 0 iv_col = lv_c - 4 iv_chr = iv_chr iv_bit = 4 ).
        module( iv_row = 0 iv_col = lv_c - 3 iv_chr = iv_chr iv_bit = 5 ).
        module( iv_row = 0 iv_col = lv_c - 2 iv_chr = iv_chr iv_bit = 6 ).
        module( iv_row = 0 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 7 ).
        module( iv_row = 1 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 8 ).
      WHEN 3.
        module( iv_row = lv_r - 3 iv_col = 0 iv_chr = iv_chr iv_bit = 1 ).
        module( iv_row = lv_r - 2 iv_col = 0 iv_chr = iv_chr iv_bit = 2 ).
        module( iv_row = lv_r - 1 iv_col = 0 iv_chr = iv_chr iv_bit = 3 ).
        module( iv_row = 0 iv_col = lv_c - 2 iv_chr = iv_chr iv_bit = 4 ).
        module( iv_row = 0 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 5 ).
        module( iv_row = 1 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 6 ).
        module( iv_row = 2 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 7 ).
        module( iv_row = 3 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 8 ).
      WHEN 4.
        module( iv_row = lv_r - 1 iv_col = 0 iv_chr = iv_chr iv_bit = 1 ).
        module( iv_row = lv_r - 1 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 2 ).
        module( iv_row = 0 iv_col = lv_c - 3 iv_chr = iv_chr iv_bit = 3 ).
        module( iv_row = 0 iv_col = lv_c - 2 iv_chr = iv_chr iv_bit = 4 ).
        module( iv_row = 0 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 5 ).
        module( iv_row = 1 iv_col = lv_c - 3 iv_chr = iv_chr iv_bit = 6 ).
        module( iv_row = 1 iv_col = lv_c - 2 iv_chr = iv_chr iv_bit = 7 ).
        module( iv_row = 1 iv_col = lv_c - 1 iv_chr = iv_chr iv_bit = 8 ).
    ENDCASE.
  ENDMETHOD.


  METHOD place.
    "ECC 200 module placement (ISO/IEC 16022, Annex F).
    DATA lv_row TYPE i VALUE 4.
    DATA lv_col TYPE i.
    DATA lv_chr TYPE i VALUE 1.
    DATA lv_last TYPE i.

    CLEAR mt_cells.
    DO mv_nrow * mv_ncol TIMES.
      APPEND 0 TO mt_cells.
    ENDDO.
    DO.
      IF lv_row = mv_nrow AND lv_col = 0.
        corner( iv_kind = 1 iv_chr = lv_chr ).
        lv_chr = lv_chr + 1.
      ENDIF.
      IF lv_row = mv_nrow - 2 AND lv_col = 0 AND mv_ncol MOD 4 <> 0.
        corner( iv_kind = 2 iv_chr = lv_chr ).
        lv_chr = lv_chr + 1.
      ENDIF.
      IF lv_row = mv_nrow - 2 AND lv_col = 0 AND mv_ncol MOD 8 = 4.
        corner( iv_kind = 3 iv_chr = lv_chr ).
        lv_chr = lv_chr + 1.
      ENDIF.
      IF lv_row = mv_nrow + 4 AND lv_col = 2 AND mv_ncol MOD 8 = 0.
        corner( iv_kind = 4 iv_chr = lv_chr ).
        lv_chr = lv_chr + 1.
      ENDIF.
      "Sweep up and to the right.
      DO.
        IF lv_row < mv_nrow AND lv_col >= 0 AND lv_row >= 0 AND lv_col < mv_ncol.
          IF cell( iv_row = lv_row iv_col = lv_col ) = 0.
            utah( iv_row = lv_row iv_col = lv_col iv_chr = lv_chr ).
            lv_chr = lv_chr + 1.
          ENDIF.
        ENDIF.
        lv_row = lv_row - 2.
        lv_col = lv_col + 2.
        IF lv_row < 0 OR lv_col >= mv_ncol.
          EXIT.
        ENDIF.
      ENDDO.
      lv_row = lv_row + 1.
      lv_col = lv_col + 3.
      "Sweep down and to the left.
      DO.
        IF lv_row >= 0 AND lv_col < mv_ncol AND lv_row < mv_nrow AND lv_col >= 0.
          IF cell( iv_row = lv_row iv_col = lv_col ) = 0.
            utah( iv_row = lv_row iv_col = lv_col iv_chr = lv_chr ).
            lv_chr = lv_chr + 1.
          ENDIF.
        ENDIF.
        lv_row = lv_row + 2.
        lv_col = lv_col - 2.
        IF lv_row >= mv_nrow OR lv_col < 0.
          EXIT.
        ENDIF.
      ENDDO.
      lv_row = lv_row + 3.
      lv_col = lv_col + 1.
      IF lv_row >= mv_nrow AND lv_col >= mv_ncol.
        EXIT.
      ENDIF.
    ENDDO.
    "Unused lower right corner: fixed pattern.
    lv_last = mv_nrow * mv_ncol.
    IF mt_cells[ lv_last ] = 0.
      mt_cells[ lv_last ] = 1.
      mt_cells[ lv_last - mv_ncol - 1 ] = 1.
    ENDIF.
    "it_codewords is used by the caller to resolve the bit references.
    IF it_codewords IS INITIAL.
      RETURN.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
