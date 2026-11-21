CLASS zcl_pdf_studio_codes DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES ty_rows TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    "Rows of '0'/'1', one string per module row (no quiet zone).
    CLASS-METHODS qr
      IMPORTING iv_text        TYPE string
                iv_level       TYPE csequence DEFAULT 'M'
      RETURNING VALUE(rt_rows) TYPE ty_rows
      RAISING   zcx_pdf_studio.
    "Bar and space widths in modules, starting with a bar (stop pattern included).
    CLASS-METHODS code128
      IMPORTING iv_text          TYPE string
      RETURNING VALUE(rv_widths) TYPE string.
    "Gotenberg: replaces the content of <div data-code="..."> objects with an inline SVG.
    CLASS-METHODS expand_html
      IMPORTING iv_html        TYPE string
      RETURNING VALUE(rv_html) TYPE string
      RAISING   zcx_pdf_studio.
    CLASS-METHODS decode_entities
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rv_text) TYPE string.
  PRIVATE SECTION.
    TYPES ty_ints TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    CLASS-DATA gt_exp TYPE ty_ints.
    CLASS-DATA gt_log TYPE ty_ints.
    DATA mv_size TYPE i.
    DATA mt_mod TYPE ty_ints.
    DATA mt_fun TYPE ty_ints.
    DATA mv_level TYPE c LENGTH 1.
    CLASS-METHODS xor
      IMPORTING iv_a        TYPE i
                iv_b        TYPE i
      RETURNING VALUE(rv_x) TYPE i.
    CLASS-METHODS bit
      IMPORTING iv_value      TYPE i
                iv_pos        TYPE i
      RETURNING VALUE(rv_bit) TYPE i.
    CLASS-METHODS gf_init.
    CLASS-METHODS digits
      IMPORTING iv_text     TYPE string
                iv_from     TYPE i
      RETURNING VALUE(rv_n) TYPE i.
    CLASS-METHODS gmul
      IMPORTING iv_a        TYPE i
                iv_b        TYPE i
      RETURNING VALUE(rv_p) TYPE i.
    CLASS-METHODS rs_remainder
      IMPORTING it_data       TYPE ty_ints
                iv_degree     TYPE i
      RETURNING VALUE(rt_rem) TYPE ty_ints.
    CLASS-METHODS attr_of
      IMPORTING iv_tag          TYPE string
                iv_name         TYPE string
      RETURNING VALUE(rv_value) TYPE string.
    CLASS-METHODS svg
      IMPORTING iv_code       TYPE string
                iv_value      TYPE string
                iv_level      TYPE string
                iv_text       TYPE abap_bool
      RETURNING VALUE(rv_svg) TYPE string
      RAISING   zcx_pdf_studio.
    METHODS set
      IMPORTING iv_x    TYPE i
                iv_y    TYPE i
                iv_dark TYPE i.
    METHODS finder
      IMPORTING iv_x TYPE i
                iv_y TYPE i.
    METHODS format
      IMPORTING iv_mask TYPE i.
    METHODS masked
      IMPORTING iv_mask        TYPE i
      RETURNING VALUE(rt_grid) TYPE ty_ints.
    METHODS penalty
      IMPORTING it_grid       TYPE ty_ints
      RETURNING VALUE(rv_pen) TYPE i.
    METHODS build
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rt_rows) TYPE ty_rows
      RAISING   zcx_pdf_studio.
ENDCLASS.



CLASS zcl_pdf_studio_codes IMPLEMENTATION.

  METHOD qr.
    DATA lo_code TYPE REF TO zcl_pdf_studio_codes.
    CREATE OBJECT lo_code.
    lo_code->mv_level = to_upper( iv_level ).
    IF lo_code->mv_level NA 'LMQH' OR lo_code->mv_level IS INITIAL.
      lo_code->mv_level = 'M'.
    ENDIF.
    rt_rows = lo_code->build( iv_text ).
  ENDMETHOD.

  METHOD xor.
    DATA lv_a TYPE x LENGTH 4.
    DATA lv_b TYPE x LENGTH 4.
    lv_a = iv_a.
    lv_b = iv_b.
    lv_a = lv_a BIT-XOR lv_b.
    rv_x = lv_a.
  ENDMETHOD.

  METHOD bit.
    rv_bit = ( iv_value DIV ipow( base = 2 exp = iv_pos ) ) MOD 2.
  ENDMETHOD.

  METHOD gf_init.
    DATA lv_v TYPE i VALUE 1.
    DATA lv_i TYPE i.
    IF gt_exp IS NOT INITIAL.
      RETURN.
    ENDIF.
    DO 256 TIMES.
      APPEND 0 TO gt_log.
    ENDDO.
    DO 255 TIMES.
      lv_i = sy-index - 1.
      APPEND lv_v TO gt_exp.
      gt_log[ lv_v + 1 ] = lv_i.
      lv_v = lv_v * 2.
      IF lv_v >= 256.
        lv_v = xor( iv_a = lv_v iv_b = 285 ).
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD gmul.
    IF iv_a = 0 OR iv_b = 0.
      rv_p = 0.
      RETURN.
    ENDIF.
    rv_p = gt_exp[ ( gt_log[ iv_a + 1 ] + gt_log[ iv_b + 1 ] ) MOD 255 + 1 ].
  ENDMETHOD.

  METHOD rs_remainder.
    DATA lt_div TYPE ty_ints.
    DATA lv_root TYPE i VALUE 1.
    DATA lv_i TYPE i.
    DATA lv_j TYPE i.
    DATA lv_f TYPE i.
    DATA lv_d TYPE i.

    gf_init( ).
    DO iv_degree - 1 TIMES.
      APPEND 0 TO lt_div.
    ENDDO.
    APPEND 1 TO lt_div.
    DO iv_degree TIMES.
      lv_j = 1.
      WHILE lv_j <= iv_degree.
        lt_div[ lv_j ] = gmul( iv_a = lt_div[ lv_j ] iv_b = lv_root ).
        IF lv_j < iv_degree.
          lt_div[ lv_j ] = xor( iv_a = lt_div[ lv_j ] iv_b = lt_div[ lv_j + 1 ] ).
        ENDIF.
        lv_j = lv_j + 1.
      ENDWHILE.
      lv_root = gmul( iv_a = lv_root iv_b = 2 ).
    ENDDO.
    DO iv_degree TIMES.
      APPEND 0 TO rt_rem.
    ENDDO.
    LOOP AT it_data INTO lv_d.
      lv_f = xor( iv_a = lv_d iv_b = rt_rem[ 1 ] ).
      DELETE rt_rem INDEX 1.
      APPEND 0 TO rt_rem.
      lv_i = 1.
      WHILE lv_i <= iv_degree.
        rt_rem[ lv_i ] = xor( iv_a = rt_rem[ lv_i ] iv_b = gmul( iv_a = lt_div[ lv_i ] iv_b = lv_f ) ).
        lv_i = lv_i + 1.
      ENDWHILE.
    ENDLOOP.
  ENDMETHOD.

  METHOD set.
    DATA lv_idx TYPE i.
    lv_idx = iv_y * mv_size + iv_x + 1.
    mt_mod[ lv_idx ] = iv_dark.
    mt_fun[ lv_idx ] = 1.
  ENDMETHOD.

  METHOD finder.
    DATA lv_dx TYPE i.
    DATA lv_dy TYPE i.
    DATA lv_dist TYPE i.
    DATA lv_xx TYPE i.
    DATA lv_yy TYPE i.
    lv_dy = -4.
    WHILE lv_dy <= 4.
      lv_dx = -4.
      WHILE lv_dx <= 4.
        lv_dist = nmax( val1 = abs( lv_dx ) val2 = abs( lv_dy ) ).
        lv_xx = iv_x + lv_dx.
        lv_yy = iv_y + lv_dy.
        IF lv_xx >= 0 AND lv_xx < mv_size AND lv_yy >= 0 AND lv_yy < mv_size.
          IF lv_dist <> 2 AND lv_dist <> 4.
            set( iv_x = lv_xx iv_y = lv_yy iv_dark = 1 ).
          ELSE.
            set( iv_x = lv_xx iv_y = lv_yy iv_dark = 0 ).
          ENDIF.
        ENDIF.
        lv_dx = lv_dx + 1.
      ENDWHILE.
      lv_dy = lv_dy + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD format.
    DATA lv_data TYPE i.
    DATA lv_rem TYPE i.
    DATA lv_bits TYPE i.
    DATA lv_k TYPE i.

    CASE mv_level.
      WHEN 'L'.
        lv_data = 1.
      WHEN 'M'.
        lv_data = 0.
      WHEN 'Q'.
        lv_data = 3.
      WHEN OTHERS.
        lv_data = 2.
    ENDCASE.
    lv_data = lv_data * 8 + iv_mask.
    lv_rem = lv_data.
    DO 10 TIMES.
      lv_rem = xor( iv_a = lv_rem * 2 iv_b = ( lv_rem DIV 512 ) * 1335 ).
    ENDDO.
    lv_bits = xor( iv_a = lv_data * 1024 + lv_rem iv_b = 21522 ).
    lv_k = 0.
    WHILE lv_k <= 5.
      set( iv_x = 8 iv_y = lv_k iv_dark = bit( iv_value = lv_bits iv_pos = lv_k ) ).
      lv_k = lv_k + 1.
    ENDWHILE.
    set( iv_x = 8 iv_y = 7 iv_dark = bit( iv_value = lv_bits iv_pos = 6 ) ).
    set( iv_x = 8 iv_y = 8 iv_dark = bit( iv_value = lv_bits iv_pos = 7 ) ).
    set( iv_x = 7 iv_y = 8 iv_dark = bit( iv_value = lv_bits iv_pos = 8 ) ).
    lv_k = 9.
    WHILE lv_k < 15.
      set( iv_x = 14 - lv_k iv_y = 8 iv_dark = bit( iv_value = lv_bits iv_pos = lv_k ) ).
      lv_k = lv_k + 1.
    ENDWHILE.
    lv_k = 0.
    WHILE lv_k < 8.
      set( iv_x = mv_size - 1 - lv_k iv_y = 8 iv_dark = bit( iv_value = lv_bits iv_pos = lv_k ) ).
      lv_k = lv_k + 1.
    ENDWHILE.
    lv_k = 8.
    WHILE lv_k < 15.
      set( iv_x = 8 iv_y = mv_size - 15 + lv_k iv_dark = bit( iv_value = lv_bits iv_pos = lv_k ) ).
      lv_k = lv_k + 1.
    ENDWHILE.
    set( iv_x = 8 iv_y = mv_size - 8 iv_dark = 1 ).
  ENDMETHOD.

  METHOD masked.
    DATA lv_r TYPE i.
    DATA lv_c TYPE i.
    DATA lv_idx TYPE i.
    DATA lv_inv TYPE abap_bool.

    rt_grid = mt_mod.
    lv_r = 0.
    WHILE lv_r < mv_size.
      lv_c = 0.
      WHILE lv_c < mv_size.
        lv_idx = lv_r * mv_size + lv_c + 1.
        IF mt_fun[ lv_idx ] = 0.
          CASE iv_mask.
            WHEN 0.
              lv_inv = xsdbool( ( lv_c + lv_r ) MOD 2 = 0 ).
            WHEN 1.
              lv_inv = xsdbool( lv_r MOD 2 = 0 ).
            WHEN 2.
              lv_inv = xsdbool( lv_c MOD 3 = 0 ).
            WHEN 3.
              lv_inv = xsdbool( ( lv_c + lv_r ) MOD 3 = 0 ).
            WHEN 4.
              lv_inv = xsdbool( ( lv_c DIV 3 + lv_r DIV 2 ) MOD 2 = 0 ).
            WHEN 5.
              lv_inv = xsdbool( ( lv_c * lv_r ) MOD 2 + ( lv_c * lv_r ) MOD 3 = 0 ).
            WHEN 6.
              lv_inv = xsdbool( ( ( lv_c * lv_r ) MOD 2 + ( lv_c * lv_r ) MOD 3 ) MOD 2 = 0 ).
            WHEN OTHERS.
              lv_inv = xsdbool( ( ( lv_c + lv_r ) MOD 2 + ( lv_c * lv_r ) MOD 3 ) MOD 2 = 0 ).
          ENDCASE.
          IF lv_inv = abap_true.
            rt_grid[ lv_idx ] = 1 - rt_grid[ lv_idx ].
          ENDIF.
        ENDIF.
        lv_c = lv_c + 1.
      ENDWHILE.
      lv_r = lv_r + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD penalty.
    DATA lv_k TYPE i.
    DATA lv_r TYPE i.
    DATA lv_c TYPE i.
    DATA lv_run TYPE i.
    DATA lv_cur TYPE i.
    DATA lv_prev TYPE i.
    DATA lv_line TYPE string.
    DATA lv_dark TYPE i.
    DATA lv_cnt TYPE i.
    DATA lv_a TYPE i.

    DO 2 TIMES.
      lv_k = sy-index - 1.
      lv_r = 0.
      WHILE lv_r < mv_size.
        lv_run = 1.
        lv_line = `0000`.
        lv_c = 0.
        WHILE lv_c < mv_size.
          IF lv_k = 0.
            lv_cur = it_grid[ lv_r * mv_size + lv_c + 1 ].
          ELSE.
            lv_cur = it_grid[ lv_c * mv_size + lv_r + 1 ].
          ENDIF.
          lv_line = |{ lv_line }{ lv_cur }|.
          IF lv_c > 0.
            IF lv_cur = lv_prev.
              lv_run = lv_run + 1.
              IF lv_run = 5.
                rv_pen = rv_pen + 3.
              ELSEIF lv_run > 5.
                rv_pen = rv_pen + 1.
              ENDIF.
            ELSE.
              lv_run = 1.
            ENDIF.
          ENDIF.
          lv_prev = lv_cur.
          lv_c = lv_c + 1.
        ENDWHILE.
        lv_line = lv_line && `0000`.
        FIND ALL OCCURRENCES OF `10111010000` IN lv_line MATCH COUNT lv_cnt.
        rv_pen = rv_pen + 40 * lv_cnt.
        FIND ALL OCCURRENCES OF `00001011101` IN lv_line MATCH COUNT lv_cnt.
        rv_pen = rv_pen + 40 * lv_cnt.
        lv_r = lv_r + 1.
      ENDWHILE.
    ENDDO.
    lv_r = 0.
    WHILE lv_r < mv_size - 1.
      lv_c = 0.
      WHILE lv_c < mv_size - 1.
        lv_a = it_grid[ lv_r * mv_size + lv_c + 1 ].
        IF lv_a = it_grid[ lv_r * mv_size + lv_c + 2 ]
            AND lv_a = it_grid[ ( lv_r + 1 ) * mv_size + lv_c + 1 ]
            AND lv_a = it_grid[ ( lv_r + 1 ) * mv_size + lv_c + 2 ].
          rv_pen = rv_pen + 3.
        ENDIF.
        lv_c = lv_c + 1.
      ENDWHILE.
      lv_r = lv_r + 1.
    ENDWHILE.
    LOOP AT it_grid INTO lv_a.
      lv_dark = lv_dark + lv_a.
    ENDLOOP.
    rv_pen = rv_pen + ( abs( lv_dark * 20 - mv_size * mv_size * 10 ) DIV ( mv_size * mv_size ) ) * 10.
  ENDMETHOD.

  METHOD build.
    DATA lv_ecc TYPE string.
    DATA lv_align TYPE string.
    DATA lt_ecc TYPE string_table.
    DATA lt_align TYPE string_table.
    DATA lt_pos TYPE string_table.
    DATA lv_utf8 TYPE xstring.
    DATA lv_n TYPE i.
    DATA lv_v TYPE i.
    DATA lv_at TYPE i.
    DATA lv_ec TYPE i.
    DATA lv_b1 TYPE i.
    DATA lv_d1 TYPE i.
    DATA lv_b2 TYPE i.
    DATA lv_cap TYPE i.
    DATA lv_cci TYPE i.
    DATA lv_bits TYPE string.
    DATA lv_i TYPE i.
    DATA lv_j TYPE i.
    DATA lv_k TYPE i.
    DATA lv_byte TYPE i.
    DATA lv_hex TYPE x LENGTH 1.
    DATA lt_data TYPE ty_ints.
    DATA lt_all TYPE ty_ints.
    DATA lv_pos TYPE i.
    DATA lv_len TYPE i.
    DATA lv_maxd TYPE i.
    DATA lv_nblocks TYPE i.
    DATA lv_off TYPE i.
    DATA lt_blockd TYPE STANDARD TABLE OF ty_ints WITH EMPTY KEY.
    DATA lt_blockc TYPE STANDARD TABLE OF ty_ints WITH EMPTY KEY.
    DATA lt_d TYPE ty_ints.
    DATA lv_na TYPE i.
    DATA lv_ax TYPE i.
    DATA lv_ay TYPE i.
    DATA lv_px TYPE i.
    DATA lv_py TYPE i.
    DATA lv_rem TYPE i.
    DATA lv_vb TYPE i.
    DATA lv_a TYPE i.
    DATA lv_b TYPE i.
    DATA lv_right TYPE i.
    DATA lv_vert TYPE i.
    DATA lv_x TYPE i.
    DATA lv_y TYPE i.
    DATA lv_idx TYPE i.
    DATA lv_total TYPE i.
    DATA lv_mask TYPE i.
    DATA lv_pen TYPE i.
    DATA lv_best TYPE i VALUE 999999999.
    DATA lt_grid TYPE ty_ints.
    DATA lt_bestg TYPE ty_ints.
    DATA lv_row TYPE string.
    DATA lv_bit TYPE i.
    DATA lv_cnt TYPE i.

    lv_ecc = ``.
    lv_ecc = lv_ecc && `7 1 19 0 10 1 16 0 13 1 13 0 17 1 9 0 10 1 34 0 16 1 28 0 22 1 22 0 28 1 16 0 15 1 55 0 26 1 44 0 18 2 17 0 22 2 13 0 20 1 80 0 18 2 32 0 26 2 24 0 16 4 9 0 26 1 108 0 24 2 43 0 18 2 15 2 22 2 11 2 18`.
    lv_ecc = lv_ecc && ` 2 68 0 16 4 27 0 24 4 19 0 28 4 15 0 20 2 78 0 18 4 31 0 18 2 14 4 26 4 13 1 24 2 97 0 22 2 38 2 22 4 18 2 26 4 14 2 30 2 116 0 22 3 36 2 20 4 16 4 24 4 12 4 18 2 68 2 26 4 43 1 24 6 19 2 28 6 15 2 2`.
    lv_ecc = lv_ecc && `0 4 81 0 30 1 50 4 28 4 22 4 24 3 12 8 24 2 92 2 22 6 36 2 26 4 20 6 28 7 14 4 26 4 107 0 22 8 37 1 24 8 20 4 22 12 11 4 30 3 115 1 24 4 40 5 20 11 16 5 24 11 12 5 22 5 87 1 24 5 41 5 30 5 24 7 24 11 `.
    lv_ecc = lv_ecc && `12 7 24 5 98 1 28 7 45 3 24 15 19 2 30 3 15 13 28 1 107 5 28 10 46 1 28 1 22 15 28 2 14 17 30 5 120 1 26 9 43 4 28 17 22 1 28 2 14 19 28 3 113 4 26 3 44 11 26 17 21 4 26 9 13 16 28 3 107 5 26 3 41 13 `.
    lv_ecc = lv_ecc && `30 15 24 5 28 15 15 10 28 4 116 4 26 17 42 0 28 17 22 6 30 19 16 6 28 2 111 7 28 17 46 0 30 7 24 16 24 34 13 0 30 4 121 5 28 4 47 14 30 11 24 14 30 16 15 14 30 6 117 4 28 6 45 14 30 11 24 16 30 30 16 `.
    lv_ecc = lv_ecc && `2 26 8 106 4 28 8 47 13 30 7 24 22 30 22 15 13 28 10 114 2 28 19 46 4 28 28 22 6 30 33 16 4 30 8 122 4 28 22 45 3 30 8 23 26 30 12 15 28 30 3 117 10 28 3 45 23 30 4 24 31 30 11 15 31 30 7 116 7 28 21 `.
    lv_ecc = lv_ecc && `45 7 30 1 23 37 30 19 15 26 30 5 115 10 28 19 47 10 30 15 24 25 30 23 15 25 30 13 115 3 28 2 46 29 30 42 24 1 30 23 15 28 30 17 115 0 28 10 46 23 30 10 24 35 30 19 15 35 30 17 115 1 28 14 46 21 30 29 `.
    lv_ecc = lv_ecc && `24 19 30 11 15 46 30 13 115 6 28 14 46 23 30 44 24 7 30 59 16 1 30 12 121 7 28 12 47 26 30 39 24 14 30 22 15 41 30 6 121 14 28 6 47 34 30 46 24 10 30 2 15 64 30 17 122 4 28 29 46 14 30 49 24 10 30 24 `.
    lv_ecc = lv_ecc && `15 46 30 4 122 18 28 13 46 32 30 48 24 14 30 42 15 32 30 20 117 4 28 40 47 7 30 43 24 22 30 10 15 67 30 19 118 6 28 18 47 31 30 34 24 34 30 20 15 61`.
    lv_align = ``.
    lv_align = lv_align && `- 6,18 6,22 6,26 6,30 6,34 6,22,38 6,24,42 6,26,46 6,28,50 6,30,54 6,32,58 6,34,62 6,26,46,66 6,26,48,70 6,26,50,74 6,30,54,78 6,30,56,82 6,30,58,86 6,34,62,90 6,28,50,72,94 6,26,50,74,98 6,30,54,78,1`.
    lv_align = lv_align && `02 6,28,54,80,106 6,32,58,84,110 6,30,58,86,114 6,34,62,90,118 6,26,50,74,98,122 6,30,54,78,102,126 6,26,52,78,104,130 6,30,56,82,108,134 6,34,60,86,112,138 6,30,58,86,114,142 6,34,62,90,118,146 6,30,`.
    lv_align = lv_align && `54,78,102,126,150 6,24,50,76,102,128,154 6,28,54,80,106,132,158 6,32,58,84,110,136,162 6,26,54,82,110,138,166 6,30,58,86,114,142,170`.
    SPLIT lv_ecc AT ` ` INTO TABLE lt_ecc.
    SPLIT lv_align AT ` ` INTO TABLE lt_align.

    lv_utf8 = cl_abap_codepage=>convert_to( source = iv_text codepage = `UTF-8` ).
    lv_n = xstrlen( lv_utf8 ).
    lv_v = 1.
    WHILE lv_v <= 40.
      CASE mv_level.
        WHEN 'L'.
          lv_at = 0.
        WHEN 'M'.
          lv_at = 1.
        WHEN 'Q'.
          lv_at = 2.
        WHEN OTHERS.
          lv_at = 3.
      ENDCASE.
      lv_at = ( ( lv_v - 1 ) * 4 + lv_at ) * 4 + 1.
      lv_ec = lt_ecc[ lv_at ].
      lv_b1 = lt_ecc[ lv_at + 1 ].
      lv_d1 = lt_ecc[ lv_at + 2 ].
      lv_b2 = lt_ecc[ lv_at + 3 ].
      lv_cap = lv_b1 * lv_d1 + lv_b2 * ( lv_d1 + 1 ).
      IF lv_v < 10.
        lv_cci = 8.
      ELSE.
        lv_cci = 16.
      ENDIF.
      IF 4 + lv_cci + 8 * lv_n <= lv_cap * 8.
        EXIT.
      ENDIF.
      lv_v = lv_v + 1.
    ENDWHILE.
    IF lv_v > 40.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |QR code text is too long ({ lv_n } bytes)|.
    ENDIF.

    "Bit stream: byte mode, length, data, terminator, padding.
    lv_bits = `0100`.
    lv_k = lv_cci - 1.
    WHILE lv_k >= 0.
      lv_bit = bit( iv_value = lv_n iv_pos = lv_k ).
      lv_bits = |{ lv_bits }{ lv_bit }|.
      lv_k = lv_k - 1.
    ENDWHILE.
    lv_i = 0.
    WHILE lv_i < lv_n.
      lv_hex = lv_utf8+lv_i(1).
      lv_byte = lv_hex.
      lv_k = 7.
      WHILE lv_k >= 0.
        lv_bit = bit( iv_value = lv_byte iv_pos = lv_k ).
        lv_bits = |{ lv_bits }{ lv_bit }|.
        lv_k = lv_k - 1.
      ENDWHILE.
      lv_i = lv_i + 1.
    ENDWHILE.
    lv_i = 0.
    WHILE lv_i < 4 AND strlen( lv_bits ) < lv_cap * 8.
      lv_bits = lv_bits && `0`.
      lv_i = lv_i + 1.
    ENDWHILE.
    WHILE strlen( lv_bits ) MOD 8 <> 0.
      lv_bits = lv_bits && `0`.
    ENDWHILE.
    lv_i = 0.
    WHILE strlen( lv_bits ) < lv_cap * 8.
      IF lv_i MOD 2 = 0.
        lv_bits = lv_bits && `11101100`.
      ELSE.
        lv_bits = lv_bits && `00010001`.
      ENDIF.
      lv_i = lv_i + 1.
    ENDWHILE.
    lv_i = 0.
    WHILE lv_i < strlen( lv_bits ).
      lv_byte = 0.
      lv_k = 0.
      WHILE lv_k < 8.
        lv_off = lv_i + lv_k.
        lv_bit = lv_bits+lv_off(1).
        lv_byte = lv_byte * 2 + lv_bit.
        lv_k = lv_k + 1.
      ENDWHILE.
      APPEND lv_byte TO lt_data.
      lv_i = lv_i + 8.
    ENDWHILE.

    "Blocks with Reed-Solomon error correction, then interleaving.
    lv_nblocks = lv_b1 + lv_b2.
    lv_pos = 1.
    lv_i = 0.
    WHILE lv_i < lv_nblocks.
      IF lv_i < lv_b1.
        lv_len = lv_d1.
      ELSE.
        lv_len = lv_d1 + 1.
      ENDIF.
      CLEAR lt_d.
      lv_j = 0.
      WHILE lv_j < lv_len.
        APPEND lt_data[ lv_pos + lv_j ] TO lt_d.
        lv_j = lv_j + 1.
      ENDWHILE.
      lv_pos = lv_pos + lv_len.
      APPEND lt_d TO lt_blockd.
      APPEND rs_remainder( it_data = lt_d iv_degree = lv_ec ) TO lt_blockc.
      lv_maxd = nmax( val1 = lv_maxd val2 = lv_len ).
      lv_i = lv_i + 1.
    ENDWHILE.
    lv_i = 1.
    WHILE lv_i <= lv_maxd.
      LOOP AT lt_blockd INTO lt_d.
        IF lv_i <= lines( lt_d ).
          APPEND lt_d[ lv_i ] TO lt_all.
        ENDIF.
      ENDLOOP.
      lv_i = lv_i + 1.
    ENDWHILE.
    lv_i = 1.
    WHILE lv_i <= lv_ec.
      LOOP AT lt_blockc INTO lt_d.
        APPEND lt_d[ lv_i ] TO lt_all.
      ENDLOOP.
      lv_i = lv_i + 1.
    ENDWHILE.

    "Function patterns.
    mv_size = lv_v * 4 + 17.
    lv_total = mv_size * mv_size.
    DO lv_total TIMES.
      APPEND 0 TO mt_mod.
      APPEND 0 TO mt_fun.
    ENDDO.
    lv_i = 0.
    WHILE lv_i < mv_size.
      set( iv_x = 6 iv_y = lv_i iv_dark = 1 - lv_i MOD 2 ).
      set( iv_x = lv_i iv_y = 6 iv_dark = 1 - lv_i MOD 2 ).
      lv_i = lv_i + 1.
    ENDWHILE.
    finder( iv_x = 3 iv_y = 3 ).
    finder( iv_x = mv_size - 4 iv_y = 3 ).
    finder( iv_x = 3 iv_y = mv_size - 4 ).
    IF lt_align[ lv_v ] <> `-`.
      SPLIT lt_align[ lv_v ] AT `,` INTO TABLE lt_pos.
      lv_na = lines( lt_pos ).
      lv_i = 1.
      WHILE lv_i <= lv_na.
        lv_j = 1.
        WHILE lv_j <= lv_na.
          IF NOT ( ( lv_i = 1 AND lv_j = 1 ) OR ( lv_i = 1 AND lv_j = lv_na ) OR ( lv_i = lv_na AND lv_j = 1 ) ).
            lv_px = lt_pos[ lv_i ].
            lv_py = lt_pos[ lv_j ].
            lv_ay = -2.
            WHILE lv_ay <= 2.
              lv_ax = -2.
              WHILE lv_ax <= 2.
                IF nmax( val1 = abs( lv_ax ) val2 = abs( lv_ay ) ) <> 1.
                  set( iv_x = lv_px + lv_ax iv_y = lv_py + lv_ay iv_dark = 1 ).
                ELSE.
                  set( iv_x = lv_px + lv_ax iv_y = lv_py + lv_ay iv_dark = 0 ).
                ENDIF.
                lv_ax = lv_ax + 1.
              ENDWHILE.
              lv_ay = lv_ay + 1.
            ENDWHILE.
          ENDIF.
          lv_j = lv_j + 1.
        ENDWHILE.
        lv_i = lv_i + 1.
      ENDWHILE.
    ENDIF.
    format( 0 ).
    IF lv_v >= 7.
      lv_rem = lv_v.
      DO 12 TIMES.
        lv_rem = xor( iv_a = lv_rem * 2 iv_b = ( lv_rem DIV 2048 ) * 7973 ).
      ENDDO.
      lv_vb = lv_v * 4096 + lv_rem.
      lv_k = 0.
      WHILE lv_k < 18.
        lv_a = mv_size - 11 + lv_k MOD 3.
        lv_b = lv_k DIV 3.
        lv_bit = bit( iv_value = lv_vb iv_pos = lv_k ).
        set( iv_x = lv_a iv_y = lv_b iv_dark = lv_bit ).
        set( iv_x = lv_b iv_y = lv_a iv_dark = lv_bit ).
        lv_k = lv_k + 1.
      ENDWHILE.
    ENDIF.

    "Data modules in the zigzag order.
    lv_cnt = lines( lt_all ) * 8.
    lv_i = 0.
    lv_right = mv_size - 1.
    WHILE lv_right >= 1.
      IF lv_right = 6.
        lv_right = 5.
      ENDIF.
      lv_vert = 0.
      WHILE lv_vert < mv_size.
        lv_j = 0.
        WHILE lv_j < 2.
          lv_x = lv_right - lv_j.
          IF ( lv_right + 1 ) MOD 4 < 2.
            lv_y = mv_size - 1 - lv_vert.
          ELSE.
            lv_y = lv_vert.
          ENDIF.
          lv_idx = lv_y * mv_size + lv_x + 1.
          IF mt_fun[ lv_idx ] = 0 AND lv_i < lv_cnt.
            mt_mod[ lv_idx ] = bit( iv_value = lt_all[ lv_i DIV 8 + 1 ] iv_pos = 7 - lv_i MOD 8 ).
            lv_i = lv_i + 1.
          ENDIF.
          lv_j = lv_j + 1.
        ENDWHILE.
        lv_vert = lv_vert + 1.
      ENDWHILE.
      lv_right = lv_right - 2.
    ENDWHILE.

    "Mask with the lowest penalty.
    lv_mask = 0.
    WHILE lv_mask < 8.
      format( lv_mask ).
      lt_grid = masked( lv_mask ).
      lv_pen = penalty( lt_grid ).
      IF lv_pen < lv_best.
        lv_best = lv_pen.
        lt_bestg = lt_grid.
      ENDIF.
      lv_mask = lv_mask + 1.
    ENDWHILE.
    lv_y = 0.
    WHILE lv_y < mv_size.
      CLEAR lv_row.
      lv_x = 0.
      WHILE lv_x < mv_size.
        lv_bit = lt_bestg[ lv_y * mv_size + lv_x + 1 ].
        lv_row = |{ lv_row }{ lv_bit }|.
        lv_x = lv_x + 1.
      ENDWHILE.
      APPEND lv_row TO rt_rows.
      lv_y = lv_y + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD code128.
    CONSTANTS lc_stop TYPE string VALUE `2331112`.
    DATA lv_tab TYPE string.
    DATA lv_ascii TYPE string.
    DATA lt_vals TYPE ty_ints.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_n TYPE i.
    DATA lv_set TYPE c LENGTH 1.
    DATA lv_sum TYPE i.
    DATA lv_k TYPE i.
    DATA lv_val TYPE i.
    DATA lv_ch TYPE string.
    DATA lv_off TYPE i.

    lv_tab = ``.
    lv_tab = lv_tab && `21222222212222222112122312132213122212221312231213221222121322131223121211223212213212223111322212312212322122321122113222123121321222311231213131122232112232122131221232211232221121212321232123212111`.
    lv_tab = lv_tab && `13231311231313211123131321131323112113132311132313111121331123311321311131231133211331213131212113312311312131132133112131313111233113213311213121133123113321113141112214114311111112241114221211241214`.
    lv_tab = lv_tab && `21141122141221112214112412122114122411142112142211241211221114413111241112134111111242121142121241114212124112124211411212421112421211212141214121412121111143111341131141114113114311411113411311113141`.
    lv_tab = lv_tab && `114131311141411131211412211214211232`.
    lv_ascii = ` !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_` && '`' && `abcdefghijklmnopqrstuvwxyz{|}~`.
    lv_len = strlen( iv_text ).

    lv_i = 0.
    lv_n = digits( iv_text = iv_text iv_from = lv_i ).
    IF lv_n >= 4 OR ( lv_n = lv_len AND lv_n >= 2 AND lv_n MOD 2 = 0 ).
      lv_set = 'C'.
      APPEND 105 TO lt_vals.
    ELSE.
      lv_set = 'B'.
      APPEND 104 TO lt_vals.
    ENDIF.
    WHILE lv_i < lv_len.
      IF lv_set = 'C'.
        lv_n = digits( iv_text = iv_text iv_from = lv_i ).
        IF lv_n >= 2.
          lv_val = iv_text+lv_i(2).
          APPEND lv_val TO lt_vals.
          lv_i = lv_i + 2.
        ELSE.
          APPEND 100 TO lt_vals.
          lv_set = 'B'.
        ENDIF.
        CONTINUE.
      ENDIF.
      lv_n = digits( iv_text = iv_text iv_from = lv_i ).
      IF lv_n >= 4 AND ( lv_n MOD 2 = 0 OR lv_n >= 5 ).
        IF lv_n MOD 2 = 1.
          lv_ch = iv_text+lv_i(1).
          FIND FIRST OCCURRENCE OF lv_ch IN lv_ascii MATCH OFFSET lv_val.
          APPEND lv_val TO lt_vals.
          lv_i = lv_i + 1.
        ENDIF.
        APPEND 99 TO lt_vals.
        lv_set = 'C'.
        CONTINUE.
      ENDIF.
      lv_ch = iv_text+lv_i(1).
      "Characters outside printable ASCII are printed as '?'.
      FIND FIRST OCCURRENCE OF lv_ch IN lv_ascii MATCH OFFSET lv_val RESPECTING CASE.
      IF sy-subrc <> 0.
        lv_val = 31.
      ENDIF.
      APPEND lv_val TO lt_vals.
      lv_i = lv_i + 1.
    ENDWHILE.
    lv_sum = lt_vals[ 1 ].
    lv_k = 1.
    WHILE lv_k < lines( lt_vals ).
      lv_sum = lv_sum + lv_k * lt_vals[ lv_k + 1 ].
      lv_k = lv_k + 1.
    ENDWHILE.
    APPEND lv_sum MOD 103 TO lt_vals.
    LOOP AT lt_vals INTO lv_val.
      lv_off = lv_val * 6.
      rv_widths = rv_widths && lv_tab+lv_off(6).
    ENDLOOP.
    rv_widths = rv_widths && lc_stop.
  ENDMETHOD.

  METHOD digits.
    DATA lv_off TYPE i.
    DATA lv_len TYPE i.
    lv_len = strlen( iv_text ).
    WHILE iv_from + rv_n < lv_len.
      lv_off = iv_from + rv_n.
      IF iv_text+lv_off(1) CN '0123456789'.
        EXIT.
      ENDIF.
      rv_n = rv_n + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD decode_entities.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF `&lt;` IN rv_text WITH `<`.
    REPLACE ALL OCCURRENCES OF `&gt;` IN rv_text WITH `>`.
    REPLACE ALL OCCURRENCES OF `&quot;` IN rv_text WITH `"`.
    REPLACE ALL OCCURRENCES OF `&#39;` IN rv_text WITH `'`.
    REPLACE ALL OCCURRENCES OF `&#x27;` IN rv_text WITH `'`.
    REPLACE ALL OCCURRENCES OF `&nbsp;` IN rv_text WITH ` `.
    REPLACE ALL OCCURRENCES OF `&amp;` IN rv_text WITH `&`.
    rv_text = condense( val = rv_text del = ` ` from = `` to = `` ).
  ENDMETHOD.

  METHOD attr_of.
    DATA lv_at TYPE i.
    DATA lv_rest TYPE string.
    DATA lv_end TYPE i.
    lv_at = find( val = iv_tag sub = | { iv_name }="| ).
    IF lv_at < 0.
      RETURN.
    ENDIF.
    lv_rest = substring( val = iv_tag off = lv_at + strlen( iv_name ) + 3 ).
    lv_end = find( val = lv_rest sub = `"` ).
    IF lv_end > 0.
      rv_value = lv_rest(lv_end).
    ENDIF.
  ENDMETHOD.

  METHOD svg.
    DATA lt_rows TYPE ty_rows.
    DATA lv_row TYPE string.
    DATA lv_n TYPE i.
    DATA lv_y TYPE i.
    DATA lv_x TYPE i.
    DATA lv_run TYPE i.
    DATA lv_path TYPE string.
    DATA lv_widths TYPE string.
    DATA lv_total TYPE i.
    DATA lv_i TYPE i.
    DATA lv_w TYPE i.
    DATA lv_bar TYPE abap_bool VALUE abap_true.
    DATA lv_label TYPE string.

    IF iv_code = `qr`.
      lt_rows = qr( iv_text = iv_value iv_level = iv_level ).
      lv_n = lines( lt_rows ).
      LOOP AT lt_rows INTO lv_row.
        lv_y = sy-tabix + 3.
        lv_x = 0.
        WHILE lv_x < lv_n.
          IF lv_row+lv_x(1) = '1'.
            lv_run = 0.
            WHILE lv_x + lv_run < lv_n.
              lv_i = lv_x + lv_run.
              IF lv_row+lv_i(1) <> '1'.
                EXIT.
              ENDIF.
              lv_run = lv_run + 1.
            ENDWHILE.
            lv_path = |{ lv_path }M{ lv_x + 4 } { lv_y }h{ lv_run }v1h-{ lv_run }z|.
            lv_x = lv_x + lv_run.
          ELSE.
            lv_x = lv_x + 1.
          ENDIF.
        ENDWHILE.
      ENDLOOP.
      rv_svg = |<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 { lv_n + 8 } { lv_n + 8 }" width="100%" height="100%" | &&
               |preserveAspectRatio="xMidYMid meet" shape-rendering="crispEdges" style="display:block">| &&
               |<path fill="currentColor" d="{ lv_path }"/></svg>|.
      RETURN.
    ENDIF.

    lv_widths = code128( iv_value ).
    lv_i = 0.
    WHILE lv_i < strlen( lv_widths ).
      lv_w = lv_widths+lv_i(1).
      IF lv_bar = abap_true.
        lv_path = |{ lv_path }M{ lv_total + 10 } 0h{ lv_w }v100h-{ lv_w }z|.
      ENDIF.
      lv_total = lv_total + lv_w.
      lv_bar = xsdbool( lv_bar = abap_false ).
      lv_i = lv_i + 1.
    ENDWHILE.
    rv_svg = |<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 { lv_total + 20 } 100" width="100%" height="100%" | &&
             |preserveAspectRatio="none" shape-rendering="crispEdges" style="display:block;flex:1 1 auto;min-height:0">| &&
             |<path fill="currentColor" d="{ lv_path }"/></svg>|.
    IF iv_text = abap_true.
      lv_label = escape( val = iv_value format = cl_abap_format=>e_xml_text ).
      rv_svg = |<div style="display:flex;flex-direction:column;width:100%;height:100%">{ rv_svg }| &&
               |<div style="text-align:center;line-height:1.1;white-space:nowrap;overflow:hidden">{ lv_label }</div></div>|.
    ENDIF.
  ENDMETHOD.

  METHOD expand_html.
    DATA lv_from TYPE i.
    DATA lv_at TYPE i.
    DATA lv_start TYPE i.
    DATA lv_open_end TYPE i.
    DATA lv_close TYPE i.
    DATA lv_tag TYPE string.
    DATA lv_inner TYPE string.
    DATA lv_value TYPE string.
    DATA lv_rest TYPE string.

    rv_html = iv_html.
    lv_from = 0.
    DO.
      lv_at = find( val = rv_html sub = ` data-code="` off = lv_from ).
      IF lv_at < 0.
        EXIT.
      ENDIF.
      "The <div that owns the attribute: the last one before it.
      lv_start = -1.
      DO.
        lv_open_end = find( val = rv_html sub = `<div` off = lv_start + 1 ).
        IF lv_open_end < 0 OR lv_open_end > lv_at.
          EXIT.
        ENDIF.
        lv_start = lv_open_end.
      ENDDO.
      lv_open_end = find( val = rv_html sub = `>` off = lv_at ).
      lv_close = find( val = rv_html sub = `</div>` off = lv_open_end ).
      IF lv_start < 0 OR lv_open_end < 0 OR lv_close < 0.
        EXIT.
      ENDIF.
      lv_tag = substring( val = rv_html off = lv_start len = lv_open_end - lv_start + 1 ).
      lv_inner = substring( val = rv_html off = lv_open_end + 1 len = lv_close - lv_open_end - 1 ).
      lv_value = decode_entities( lv_inner ).
      lv_inner = svg( iv_code  = to_lower( attr_of( iv_tag = lv_tag iv_name = `data-code` ) )
                      iv_value = lv_value
                      iv_level = attr_of( iv_tag = lv_tag iv_name = `data-ecc` )
                      iv_text  = xsdbool( attr_of( iv_tag = lv_tag iv_name = `data-hr` ) = `1` ) ).
      lv_rest = substring( val = rv_html off = lv_close ).
      rv_html = substring( val = rv_html len = lv_open_end + 1 ) && lv_inner && lv_rest.
      lv_from = lv_open_end + 1 + strlen( lv_inner ).
    ENDDO.
  ENDMETHOD.

ENDCLASS.
