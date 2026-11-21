"! <p>TrueType font for ZPDF Studio: metrics, glyph lookup, subsetting and PDF embedding.</p>
"! Fonts are embedded as Type0 / CIDFontType2 with Identity-H encoding, so every character of the
"! font can be printed (Turkish, Polish, Greek, Cyrillic, ...). Only the glyphs that are used are
"! kept in the embedded file, and the file is Flate compressed.
"! Supported: TrueType outlines (.ttf). Not supported: CFF based OpenType (.otf) and collections (.ttc).
CLASS zcl_pdf_studio_font DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_obj,
        text   TYPE string,
        stream TYPE xstring,
      END OF ty_obj,
      ty_objs TYPE STANDARD TABLE OF ty_obj WITH EMPTY KEY.

    "! Reads a TrueType file.
    CLASS-METHODS create
      IMPORTING
        iv_data        TYPE xstring
      RETURNING
        VALUE(ro_font) TYPE REF TO zcl_pdf_studio_font
      RAISING
        zcx_pdf_studio.

    "! Glyph id of a Unicode code point (0 when the font has no glyph for it).
    METHODS glyph
      IMPORTING
        iv_cp         TYPE i
      RETURNING
        VALUE(rv_gid) TYPE i.

    "! Advance width of a glyph in 1/1000 em.
    METHODS advance
      IMPORTING
        iv_gid          TYPE i
      RETURNING
        VALUE(rv_width) TYPE i.

    "! Glyph ids of a text as 4-digit hex (Identity-H) and its width in 1/1000 em.
    "! The glyphs are remembered for the embedded subset and the ToUnicode map.
    METHODS encode
      IMPORTING
        iv_text  TYPE csequence
      EXPORTING
        ev_hex   TYPE string
        ev_width TYPE f.

    "! Width in 1/1000 em of glyph ids given as 4-digit hex.
    METHODS hex_width
      IMPORTING
        iv_hex          TYPE string
      RETURNING
        VALUE(rv_width) TYPE f.

    "! True when at least one glyph was encoded (the font must be embedded).
    METHODS is_used
      RETURNING
        VALUE(rv_used) TYPE abap_bool.

    "! The five PDF objects of the font, numbered from iv_first:
    "! Type0 font, CIDFont, font descriptor, font file (subset), ToUnicode CMap.
    "! @parameter iv_tag | Six upper-case letters, the subset prefix of the font name
    METHODS objects
      IMPORTING
        iv_first       TYPE i
        iv_tag         TYPE string
      RETURNING
        VALUE(rt_objs) TYPE ty_objs
      RAISING
        zcx_pdf_studio.

    "! TrueType file that contains only the used glyphs (glyph ids are kept).
    METHODS subset
      RETURNING
        VALUE(rv_font) TYPE xstring
      RAISING
        zcx_pdf_studio.

    "! PostScript name of the font.
    DATA mv_name TYPE string READ-ONLY.
    DATA mv_units TYPE i READ-ONLY.
    DATA mv_glyphs TYPE i READ-ONLY.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_table,
        tag    TYPE string,
        offset TYPE i,
        length TYPE i,
      END OF ty_table,
      ty_tables TYPE HASHED TABLE OF ty_table WITH UNIQUE KEY tag,
      BEGIN OF ty_map,
        cp  TYPE i,
        gid TYPE i,
      END OF ty_map,
      ty_maps TYPE HASHED TABLE OF ty_map WITH UNIQUE KEY cp,
      BEGIN OF ty_used,
        gid TYPE i,
        cp  TYPE i,
      END OF ty_used,
      ty_used_tab TYPE SORTED TABLE OF ty_used WITH UNIQUE KEY gid,
      ty_gids     TYPE SORTED TABLE OF i WITH UNIQUE KEY table_line,
      ty_x4       TYPE x LENGTH 4,
      ty_x4s      TYPE STANDARD TABLE OF ty_x4 WITH EMPTY KEY,
      ty_xstrings TYPE STANDARD TABLE OF xstring WITH EMPTY KEY.

    DATA mv_data TYPE xstring.
    DATA mt_tables TYPE ty_tables.
    DATA mt_cache TYPE ty_maps.
    DATA mt_used TYPE ty_used_tab.
    DATA mv_cmap TYPE i.
    DATA mv_cmap_format TYPE i.
    DATA mv_hmtx TYPE i.
    DATA mv_hmetrics TYPE i.
    DATA mv_loca TYPE i.
    DATA mv_glyf TYPE i.
    DATA mv_long_loca TYPE abap_bool.
    DATA mv_ascent TYPE i.
    DATA mv_descent TYPE i.
    DATA mv_cap TYPE i.
    DATA mv_bbox TYPE string.
    DATA mv_italic TYPE i.
    DATA mv_fixed TYPE abap_bool.

    METHODS parse
      RAISING
        zcx_pdf_studio.
    METHODS u8
      IMPORTING
        iv_off        TYPE i
      RETURNING
        VALUE(rv_val) TYPE i.
    METHODS u16
      IMPORTING
        iv_off        TYPE i
      RETURNING
        VALUE(rv_val) TYPE i.
    METHODS s16
      IMPORTING
        iv_off        TYPE i
      RETURNING
        VALUE(rv_val) TYPE i.
    METHODS u32
      IMPORTING
        iv_off        TYPE i
      RETURNING
        VALUE(rv_val) TYPE i.
    METHODS table_offset
      IMPORTING
        iv_tag        TYPE string
      RETURNING
        VALUE(rv_off) TYPE i.
    METHODS table_data
      IMPORTING
        iv_tag         TYPE string
      RETURNING
        VALUE(rv_data) TYPE xstring.
    METHODS lookup
      IMPORTING
        iv_cp         TYPE i
      RETURNING
        VALUE(rv_gid) TYPE i.
    METHODS glyph_range
      IMPORTING
        iv_gid    TYPE i
      EXPORTING
        ev_offset TYPE i
        ev_length TYPE i.
    METHODS read_name
      RETURNING
        VALUE(rv_name) TYPE string.
    METHODS scale
      IMPORTING
        iv_units      TYPE i
      RETURNING
        VALUE(rv_val) TYPE i.
    CLASS-METHODS checksum
      IMPORTING
        iv_data       TYPE xstring
      RETURNING
        VALUE(rv_sum) TYPE ty_x4.
    CLASS-METHODS x2
      IMPORTING
        iv_val      TYPE i
      RETURNING
        VALUE(rv_x) TYPE xstring.
    CLASS-METHODS x4
      IMPORTING
        iv_val      TYPE i
      RETURNING
        VALUE(rv_x) TYPE xstring.
    CLASS-METHODS pad4
      CHANGING
        cv_data TYPE xstring.
ENDCLASS.



CLASS zcl_pdf_studio_font IMPLEMENTATION.

  METHOD create.
    IF xstrlen( iv_data ) < 12.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Font file is empty or too short'.
    ENDIF.
    CREATE OBJECT ro_font.
    ro_font->mv_data = iv_data.
    ro_font->parse( ).
  ENDMETHOD.


  METHOD u8.
    DATA lv_x TYPE x LENGTH 1.
    IF iv_off < 0 OR iv_off + 1 > xstrlen( mv_data ).
      RETURN.
    ENDIF.
    lv_x = mv_data+iv_off(1).
    rv_val = lv_x.
  ENDMETHOD.


  METHOD u16.
    rv_val = u8( iv_off ) * 256 + u8( iv_off + 1 ).
  ENDMETHOD.


  METHOD s16.
    rv_val = u16( iv_off ).
    IF rv_val >= 32768.
      rv_val = rv_val - 65536.
    ENDIF.
  ENDMETHOD.


  METHOD u32.
    "Offsets and lengths in a font file stay below 2^31.
    rv_val = u16( iv_off ) * 65536 + u16( iv_off + 2 ).
  ENDMETHOD.


  METHOD table_offset.
    DATA ls_table TYPE ty_table.
    READ TABLE mt_tables INTO ls_table WITH TABLE KEY tag = iv_tag.
    IF sy-subrc = 0.
      rv_off = ls_table-offset.
    ELSE.
      rv_off = -1.
    ENDIF.
  ENDMETHOD.


  METHOD table_data.
    DATA ls_table TYPE ty_table.
    READ TABLE mt_tables INTO ls_table WITH TABLE KEY tag = iv_tag.
    IF sy-subrc = 0 AND ls_table-offset + ls_table-length <= xstrlen( mv_data ).
      rv_data = mv_data+ls_table-offset(ls_table-length).
    ENDIF.
  ENDMETHOD.


  METHOD parse.
    DATA lv_version TYPE xstring.
    DATA lv_count TYPE i.
    DATA lv_rec TYPE i.
    DATA ls_table TYPE ty_table.
    DATA lv_tag_x TYPE xstring.
    DATA lv_head TYPE i.
    DATA lv_hhea TYPE i.
    DATA lv_maxp TYPE i.
    DATA lv_os2 TYPE i.
    DATA lv_post TYPE i.
    DATA lv_n TYPE i.
    DATA lv_rec_off TYPE i.
    DATA lv_platform TYPE i.
    DATA lv_encoding TYPE i.
    DATA lv_sub TYPE i.
    DATA lv_format TYPE i.
    DATA lv_best TYPE i.
    DATA lv_rank TYPE i.
    DATA lv_fstype TYPE i.

    lv_version = mv_data(4).
    IF lv_version = '4F54544F'. "OTTO
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = 'OpenType fonts with CFF outlines (.otf) are not supported; use the TrueType (.ttf) file'.
    ELSEIF lv_version = '74746366'. "ttcf
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = 'Font collections (.ttc) are not supported; use a single .ttf file'.
    ELSEIF lv_version <> '00010000' AND lv_version <> '74727565'.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'File is not a TrueType font'.
    ENDIF.

    lv_count = u16( 4 ).
    DO lv_count TIMES.
      lv_rec = 12 + ( sy-index - 1 ) * 16.
      CLEAR ls_table.
      lv_tag_x = mv_data+lv_rec(4).
      TRY.
          ls_table-tag = zcl_pdf_studio_conv=>xstring_to_string( lv_tag_x ).
        CATCH zcx_pdf_studio.
          CONTINUE.
      ENDTRY.
      ls_table-offset = u32( lv_rec + 8 ).
      ls_table-length = u32( lv_rec + 12 ).
      INSERT ls_table INTO TABLE mt_tables.
    ENDDO.

    lv_head = table_offset( `head` ).
    lv_hhea = table_offset( `hhea` ).
    lv_maxp = table_offset( `maxp` ).
    mv_hmtx = table_offset( `hmtx` ).
    mv_loca = table_offset( `loca` ).
    mv_glyf = table_offset( `glyf` ).
    mv_cmap = table_offset( `cmap` ).
    IF lv_head < 0 OR lv_hhea < 0 OR lv_maxp < 0 OR mv_hmtx < 0 OR mv_cmap < 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'TrueType font is missing a required table'.
    ENDIF.
    IF mv_loca < 0 OR mv_glyf < 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = 'Font has no TrueType outlines (glyf); use a .ttf file'.
    ENDIF.

    mv_units = u16( lv_head + 18 ).
    IF mv_units <= 0.
      mv_units = 1000.
    ENDIF.
    mv_bbox = |{ scale( s16( lv_head + 36 ) ) } { scale( s16( lv_head + 38 ) ) } | &&
              |{ scale( s16( lv_head + 40 ) ) } { scale( s16( lv_head + 42 ) ) }|.
    mv_long_loca = xsdbool( s16( lv_head + 50 ) = 1 ).
    mv_ascent = scale( s16( lv_hhea + 4 ) ).
    mv_descent = scale( s16( lv_hhea + 6 ) ).
    mv_hmetrics = u16( lv_hhea + 34 ).
    mv_glyphs = u16( lv_maxp + 4 ).
    mv_cap = mv_ascent * 7 / 10.

    lv_os2 = table_offset( `OS/2` ).
    IF lv_os2 >= 0.
      lv_fstype = u16( lv_os2 + 8 ).
      "fsType bit 1 = restricted license: the font must not be embedded.
      IF lv_fstype MOD 4 >= 2 AND lv_fstype MOD 16 < 4.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING message = 'The license of this font does not allow embedding it in documents (OS/2 fsType)'.
      ENDIF.
      IF u16( lv_os2 ) >= 2.
        mv_cap = scale( s16( lv_os2 + 88 ) ).
      ENDIF.
    ENDIF.
    lv_post = table_offset( `post` ).
    IF lv_post >= 0.
      mv_italic = s16( lv_post + 4 ).
      mv_fixed = xsdbool( u32( lv_post + 12 ) <> 0 ).
    ENDIF.

    "cmap: prefer full Unicode (3,10 format 12), then BMP (3,1 format 4), then any Unicode platform.
    lv_n = u16( mv_cmap + 2 ).
    lv_best = 0.
    DO lv_n TIMES.
      lv_rec_off = mv_cmap + 4 + ( sy-index - 1 ) * 8.
      lv_platform = u16( lv_rec_off ).
      lv_encoding = u16( lv_rec_off + 2 ).
      lv_sub = mv_cmap + u32( lv_rec_off + 4 ).
      lv_format = u16( lv_sub ).
      CLEAR lv_rank.
      IF lv_format = 12 AND ( lv_platform = 3 AND lv_encoding = 10 OR lv_platform = 0 ).
        lv_rank = 4.
      ELSEIF lv_format = 4 AND lv_platform = 3 AND lv_encoding = 1.
        lv_rank = 3.
      ELSEIF lv_format = 4 AND lv_platform = 0.
        lv_rank = 2.
      ENDIF.
      IF lv_rank > lv_best.
        lv_best = lv_rank.
        mv_cmap_format = lv_format.
        mv_cmap = lv_sub.
      ENDIF.
    ENDDO.
    IF lv_best = 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Font has no Unicode character map'.
    ENDIF.

    mv_name = read_name( ).
  ENDMETHOD.


  METHOD read_name.
    DATA lv_name_tab TYPE i.
    DATA lv_count TYPE i.
    DATA lv_strings TYPE i.
    DATA lv_rec TYPE i.
    DATA lv_platform TYPE i.
    DATA lv_id TYPE i.
    DATA lv_len TYPE i.
    DATA lv_off TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE i.
    DATA lv_step TYPE i.
    DATA lv_char TYPE string.

    lv_name_tab = table_offset( `name` ).
    IF lv_name_tab >= 0.
      lv_count = u16( lv_name_tab + 2 ).
      lv_strings = lv_name_tab + u16( lv_name_tab + 4 ).
      DO lv_count TIMES.
        lv_rec = lv_name_tab + 6 + ( sy-index - 1 ) * 12.
        lv_platform = u16( lv_rec ).
        lv_id = u16( lv_rec + 6 ).
        IF lv_id <> 6 OR ( lv_platform <> 3 AND lv_platform <> 1 ).
          CONTINUE.
        ENDIF.
        lv_len = u16( lv_rec + 8 ).
        lv_off = lv_strings + u16( lv_rec + 10 ).
        lv_step = COND #( WHEN lv_platform = 3 THEN 2 ELSE 1 ).
        CLEAR rv_name.
        lv_i = 0.
        WHILE lv_i < lv_len.
          lv_c = COND #( WHEN lv_step = 2 THEN u16( lv_off + lv_i ) ELSE u8( lv_off + lv_i ) ).
          IF lv_c >= 48 AND lv_c <= 57 OR lv_c >= 65 AND lv_c <= 90 OR lv_c >= 97 AND lv_c <= 122 OR lv_c = 45.
            lv_char = cl_abap_conv_in_ce=>uccpi( lv_c ).
            rv_name = rv_name && lv_char.
          ENDIF.
          lv_i = lv_i + lv_step.
        ENDWHILE.
        IF rv_name IS NOT INITIAL.
          EXIT.
        ENDIF.
      ENDDO.
    ENDIF.
    IF rv_name IS INITIAL.
      rv_name = `ZPDFStudioFont`.
    ENDIF.
    IF strlen( rv_name ) > 60.
      rv_name = rv_name(60).
    ENDIF.
  ENDMETHOD.


  METHOD scale.
    rv_val = iv_units * 1000 / mv_units.
  ENDMETHOD.


  METHOD glyph.
    DATA ls_map TYPE ty_map.
    READ TABLE mt_cache INTO ls_map WITH TABLE KEY cp = iv_cp.
    IF sy-subrc = 0.
      rv_gid = ls_map-gid.
      RETURN.
    ENDIF.
    rv_gid = lookup( iv_cp ).
    ls_map-cp = iv_cp.
    ls_map-gid = rv_gid.
    INSERT ls_map INTO TABLE mt_cache.
  ENDMETHOD.


  METHOD lookup.
    DATA lv_segx2 TYPE i.
    DATA lv_segs TYPE i.
    DATA lv_lo TYPE i.
    DATA lv_hi TYPE i.
    DATA lv_mid TYPE i.
    DATA lv_end TYPE i.
    DATA lv_start TYPE i.
    DATA lv_delta TYPE i.
    DATA lv_range TYPE i.
    DATA lv_addr TYPE i.
    DATA lv_groups TYPE i.
    DATA lv_rec TYPE i.

    IF mv_cmap_format = 4.
      IF iv_cp > 65535 OR iv_cp < 0.
        RETURN.
      ENDIF.
      lv_segx2 = u16( mv_cmap + 6 ).
      lv_segs = lv_segx2 / 2.
      "Binary search for the first segment whose end code is >= cp.
      lv_lo = 0.
      lv_hi = lv_segs - 1.
      WHILE lv_lo < lv_hi.
        lv_mid = ( lv_lo + lv_hi ) DIV 2.
        IF u16( mv_cmap + 14 + 2 * lv_mid ) < iv_cp.
          lv_lo = lv_mid + 1.
        ELSE.
          lv_hi = lv_mid.
        ENDIF.
      ENDWHILE.
      lv_end = u16( mv_cmap + 14 + 2 * lv_lo ).
      lv_start = u16( mv_cmap + 16 + lv_segx2 + 2 * lv_lo ).
      IF iv_cp > lv_end OR iv_cp < lv_start.
        RETURN.
      ENDIF.
      lv_delta = u16( mv_cmap + 16 + 2 * lv_segx2 + 2 * lv_lo ).
      lv_addr = mv_cmap + 16 + 3 * lv_segx2 + 2 * lv_lo.
      lv_range = u16( lv_addr ).
      IF lv_range = 0.
        rv_gid = ( iv_cp + lv_delta ) MOD 65536.
      ELSE.
        rv_gid = u16( lv_addr + lv_range + 2 * ( iv_cp - lv_start ) ).
        IF rv_gid <> 0.
          rv_gid = ( rv_gid + lv_delta ) MOD 65536.
        ENDIF.
      ENDIF.
    ELSE.
      lv_groups = u32( mv_cmap + 12 ).
      lv_lo = 0.
      lv_hi = lv_groups - 1.
      WHILE lv_lo <= lv_hi.
        lv_mid = ( lv_lo + lv_hi ) DIV 2.
        lv_rec = mv_cmap + 16 + 12 * lv_mid.
        IF iv_cp < u32( lv_rec ).
          lv_hi = lv_mid - 1.
        ELSEIF iv_cp > u32( lv_rec + 4 ).
          lv_lo = lv_mid + 1.
        ELSE.
          rv_gid = u32( lv_rec + 8 ) + iv_cp - u32( lv_rec ).
          EXIT.
        ENDIF.
      ENDWHILE.
    ENDIF.
    IF rv_gid >= mv_glyphs.
      rv_gid = 0.
    ENDIF.
  ENDMETHOD.


  METHOD advance.
    DATA lv_index TYPE i.
    lv_index = iv_gid.
    IF lv_index >= mv_hmetrics.
      lv_index = mv_hmetrics - 1.
    ENDIF.
    rv_width = u16( mv_hmtx + 4 * lv_index ) * 1000 / mv_units.
  ENDMETHOD.


  METHOD encode.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_cp TYPE i.
    DATA lv_gid TYPE i.
    DATA lv_x TYPE x LENGTH 2.
    DATA ls_used TYPE ty_used.

    CLEAR: ev_hex, ev_width.
    lv_len = strlen( iv_text ).
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_c = iv_text+lv_i(1).
      lv_cp = cl_abap_conv_out_ce=>uccpi( lv_c ).
      CASE lv_cp.
        WHEN 9 OR 160.
          lv_cp = 32.
        WHEN 10 OR 13.
          CONTINUE.
        WHEN 8722.
          IF glyph( lv_cp ) = 0.
            lv_cp = 45.
          ENDIF.
      ENDCASE.
      lv_gid = glyph( lv_cp ).
      lv_x = lv_gid.
      ev_hex = ev_hex && |{ lv_x }|.
      ev_width = ev_width + advance( lv_gid ).
      READ TABLE mt_used TRANSPORTING NO FIELDS WITH TABLE KEY gid = lv_gid.
      IF sy-subrc <> 0.
        ls_used-gid = lv_gid.
        ls_used-cp = lv_cp.
        INSERT ls_used INTO TABLE mt_used.
      ENDIF.
    ENDDO.
  ENDMETHOD.


  METHOD hex_width.
    DATA lv_off TYPE i.
    DATA lv_x TYPE x LENGTH 2.
    DATA lv_gid TYPE i.
    WHILE lv_off + 4 <= strlen( iv_hex ).
      lv_x = iv_hex+lv_off(4).
      lv_gid = lv_x.
      rv_width = rv_width + advance( lv_gid ).
      lv_off = lv_off + 4.
    ENDWHILE.
  ENDMETHOD.


  METHOD is_used.
    rv_used = xsdbool( mt_used IS NOT INITIAL ).
  ENDMETHOD.


  METHOD glyph_range.
    DATA lv_next TYPE i.
    CLEAR: ev_offset, ev_length.
    IF iv_gid < 0 OR iv_gid >= mv_glyphs.
      RETURN.
    ENDIF.
    IF mv_long_loca = abap_true.
      ev_offset = u32( mv_loca + 4 * iv_gid ).
      lv_next = u32( mv_loca + 4 * iv_gid + 4 ).
    ELSE.
      ev_offset = u16( mv_loca + 2 * iv_gid ) * 2.
      lv_next = u16( mv_loca + 2 * iv_gid + 2 ) * 2.
    ENDIF.
    ev_length = lv_next - ev_offset.
    IF ev_length < 0.
      ev_length = 0.
    ENDIF.
  ENDMETHOD.


  METHOD subset.
    DATA lt_gids TYPE ty_gids.
    DATA lt_work TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA ls_used TYPE ty_used.
    DATA lv_gid TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_length TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_flags TYPE i.
    DATA lv_component TYPE i.
    DATA lt_loca TYPE ty_x4s.
    DATA lt_glyf TYPE ty_xstrings.
    DATA lv_part TYPE xstring.
    DATA lv_glyf TYPE xstring.
    DATA lv_loca TYPE xstring.
    DATA lv_head TYPE xstring.
    DATA lv_x4 TYPE ty_x4.
    DATA lv_written TYPE i.
    DATA lt_tags TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_tag TYPE string.
    DATA lt_data TYPE ty_xstrings.
    DATA lv_count TYPE i.
    DATA lv_pow TYPE i.
    DATA lv_log TYPE i.
    DATA lv_dir TYPE xstring.
    DATA lv_body TYPE xstring.
    DATA lv_table_off TYPE i.
    DATA lv_tag_x TYPE xstring.
    DATA lv_zero4 TYPE x LENGTH 4.
    DATA lv_one TYPE x LENGTH 2.
    DATA lv_a TYPE xstring.
    DATA lv_b TYPE xstring.
    DATA lv_c TYPE xstring.
    DATA lv_d TYPE xstring.

    "1. Used glyphs plus the components of composite glyphs (and .notdef).
    INSERT 0 INTO TABLE lt_gids.
    APPEND 0 TO lt_work.
    LOOP AT mt_used INTO ls_used.
      APPEND ls_used-gid TO lt_work.
    ENDLOOP.
    WHILE lt_work IS NOT INITIAL.
      READ TABLE lt_work INTO lv_gid INDEX 1.
      DELETE lt_work INDEX 1.
      INSERT lv_gid INTO TABLE lt_gids.
      glyph_range( EXPORTING iv_gid = lv_gid IMPORTING ev_offset = lv_offset ev_length = lv_length ).
      IF lv_length < 10 OR s16( mv_glyf + lv_offset ) >= 0.
        CONTINUE.
      ENDIF.
      "Composite glyph: flags, glyph index, arguments, optional transformation, repeated.
      lv_pos = mv_glyf + lv_offset + 10.
      DO.
        lv_flags = u16( lv_pos ).
        lv_component = u16( lv_pos + 2 ).
        READ TABLE lt_gids TRANSPORTING NO FIELDS WITH TABLE KEY table_line = lv_component.
        IF sy-subrc <> 0.
          APPEND lv_component TO lt_work.
        ENDIF.
        lv_pos = lv_pos + 4.
        lv_pos = lv_pos + COND i( WHEN lv_flags MOD 2 = 1 THEN 4 ELSE 2 ).
        IF ( lv_flags DIV 8 ) MOD 2 = 1.
          lv_pos = lv_pos + 2.
        ELSEIF ( lv_flags DIV 64 ) MOD 2 = 1.
          lv_pos = lv_pos + 4.
        ELSEIF ( lv_flags DIV 128 ) MOD 2 = 1.
          lv_pos = lv_pos + 8.
        ENDIF.
        IF ( lv_flags DIV 32 ) MOD 2 = 0 OR lv_pos >= mv_glyf + lv_offset + lv_length.
          EXIT.
        ENDIF.
      ENDDO.
    ENDWHILE.

    "2. New glyf and loca (long format): unused glyphs become empty.
    DO mv_glyphs TIMES.
      lv_gid = sy-index - 1.
      lv_x4 = x4( lv_written ).
      APPEND lv_x4 TO lt_loca.
      READ TABLE lt_gids TRANSPORTING NO FIELDS WITH TABLE KEY table_line = lv_gid.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      glyph_range( EXPORTING iv_gid = lv_gid IMPORTING ev_offset = lv_offset ev_length = lv_length ).
      IF lv_length <= 0.
        CONTINUE.
      ENDIF.
      lv_pos = mv_glyf + lv_offset.
      lv_part = mv_data+lv_pos(lv_length).
      pad4( CHANGING cv_data = lv_part ).
      APPEND lv_part TO lt_glyf.
      lv_written = lv_written + xstrlen( lv_part ).
    ENDDO.
    lv_x4 = x4( lv_written ).
    APPEND lv_x4 TO lt_loca.
    CONCATENATE LINES OF lt_glyf INTO lv_glyf IN BYTE MODE.
    CONCATENATE LINES OF lt_loca INTO lv_loca IN BYTE MODE.

    "3. head: checksum adjustment 0, long loca format.
    lv_head = table_data( `head` ).
    IF xstrlen( lv_head ) >= 54.
      lv_zero4 = '00000000'.
      lv_one = '0001'.
      CONCATENATE lv_head(8) lv_zero4 lv_head+12(38) lv_one lv_head+52 INTO lv_head IN BYTE MODE.
    ENDIF.

    "4. The tables a PDF CIDFontType2 needs, in tag order.
    lt_tags = VALUE #( ( `cvt ` ) ( `fpgm` ) ( `glyf` ) ( `head` ) ( `hhea` ) ( `hmtx` ) ( `loca` ) ( `maxp` ) ( `prep` ) ).
    LOOP AT lt_tags INTO lv_tag.
      CASE lv_tag.
        WHEN `glyf`.
          lv_part = lv_glyf.
        WHEN `loca`.
          lv_part = lv_loca.
        WHEN `head`.
          lv_part = lv_head.
        WHEN OTHERS.
          IF table_offset( lv_tag ) < 0.
            DELETE lt_tags.
            CONTINUE.
          ENDIF.
          lv_part = table_data( lv_tag ).
      ENDCASE.
      APPEND lv_part TO lt_data.
    ENDLOOP.

    lv_count = lines( lt_tags ).
    lv_pow = 1.
    lv_log = 0.
    WHILE lv_pow * 2 <= lv_count.
      lv_pow = lv_pow * 2.
      lv_log = lv_log + 1.
    ENDWHILE.
    lv_zero4 = '00010000'.
    lv_a = x2( lv_count ).
    lv_b = x2( lv_pow * 16 ).
    lv_c = x2( lv_log ).
    lv_d = x2( lv_count * 16 - lv_pow * 16 ).
    CONCATENATE lv_zero4 lv_a lv_b lv_c lv_d INTO lv_dir IN BYTE MODE.
    lv_table_off = 12 + 16 * lv_count.
    LOOP AT lt_tags INTO lv_tag.
      READ TABLE lt_data INTO lv_part INDEX sy-tabix.
      lv_tag_x = zcl_pdf_studio_conv=>string_to_xstring( lv_tag ).
      lv_x4 = checksum( lv_part ).
      lv_a = x4( lv_table_off ).
      lv_b = x4( xstrlen( lv_part ) ).
      CONCATENATE lv_dir lv_tag_x lv_x4 lv_a lv_b INTO lv_dir IN BYTE MODE.
      pad4( CHANGING cv_data = lv_part ).
      CONCATENATE lv_body lv_part INTO lv_body IN BYTE MODE.
      lv_table_off = lv_table_off + xstrlen( lv_part ).
    ENDLOOP.
    CONCATENATE lv_dir lv_body INTO rv_font IN BYTE MODE.
  ENDMETHOD.


  METHOD objects.
    DATA lv_name TYPE string.
    DATA lv_widths TYPE string.
    DATA ls_used TYPE ty_used.
    DATA lv_flags TYPE i.
    DATA ls_obj TYPE ty_obj.
    DATA lv_font TYPE xstring.
    DATA lv_nl TYPE string.
    DATA lv_cmap TYPE string.
    DATA lv_block TYPE string.
    DATA lv_count TYPE i.
    DATA lv_xg TYPE x LENGTH 2.
    DATA lv_xc TYPE x LENGTH 2.
    DATA lv_zip TYPE xstring.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_name = |{ iv_tag }+{ mv_name }|.
    LOOP AT mt_used INTO ls_used.
      lv_widths = |{ lv_widths }{ ls_used-gid } [{ advance( ls_used-gid ) }] |.
    ENDLOOP.
    lv_flags = 32.
    IF mv_fixed = abap_true.
      lv_flags = lv_flags + 1.
    ENDIF.
    IF mv_italic <> 0.
      lv_flags = lv_flags + 64.
    ENDIF.

    ls_obj-text = |<< /Type /Font /Subtype /Type0 /BaseFont /{ lv_name } /Encoding /Identity-H | &&
                  |/DescendantFonts [{ iv_first + 1 } 0 R] /ToUnicode { iv_first + 4 } 0 R >>|.
    APPEND ls_obj TO rt_objs.
    CLEAR ls_obj.
    ls_obj-text = |<< /Type /Font /Subtype /CIDFontType2 /BaseFont /{ lv_name } | &&
                  |/CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >> | &&
                  |/FontDescriptor { iv_first + 2 } 0 R /CIDToGIDMap /Identity /DW 1000 /W [{ lv_widths }] >>|.
    APPEND ls_obj TO rt_objs.
    CLEAR ls_obj.
    ls_obj-text = |<< /Type /FontDescriptor /FontName /{ lv_name } /Flags { lv_flags } /FontBBox [{ mv_bbox }] | &&
                  |/ItalicAngle { mv_italic } /Ascent { mv_ascent } /Descent { mv_descent } /CapHeight { mv_cap } | &&
                  |/StemV 80 /FontFile2 { iv_first + 3 } 0 R >>|.
    APPEND ls_obj TO rt_objs.
    CLEAR ls_obj.
    lv_font = subset( ).
    lv_zip = zcl_pdf_studio_conv=>deflate( lv_font ).
    IF lv_zip IS INITIAL.
      ls_obj-stream = lv_font.
      ls_obj-text = |<< /Length { xstrlen( lv_font ) } /Length1 { xstrlen( lv_font ) } >>|.
    ELSE.
      ls_obj-stream = lv_zip.
      ls_obj-text = |<< /Length { xstrlen( lv_zip ) } /Length1 { xstrlen( lv_font ) } /Filter /FlateDecode >>|.
    ENDIF.
    APPEND ls_obj TO rt_objs.
    CLEAR ls_obj.

    "ToUnicode: glyph -> character, so the text can be searched and copied.
    LOOP AT mt_used INTO ls_used WHERE gid > 0 AND cp > 0 AND cp <= 65535.
      lv_xg = ls_used-gid.
      lv_xc = ls_used-cp.
      lv_block = |{ lv_block }<{ lv_xg }> <{ lv_xc }>{ lv_nl }|.
      lv_count = lv_count + 1.
      IF lv_count = 100.
        lv_cmap = |{ lv_cmap }100 beginbfchar{ lv_nl }{ lv_block }endbfchar{ lv_nl }|.
        CLEAR: lv_block, lv_count.
      ENDIF.
    ENDLOOP.
    IF lv_count > 0.
      lv_cmap = |{ lv_cmap }{ lv_count } beginbfchar{ lv_nl }{ lv_block }endbfchar{ lv_nl }|.
    ENDIF.
    lv_cmap = |/CIDInit /ProcSet findresource begin{ lv_nl }12 dict begin{ lv_nl }begincmap{ lv_nl }| &&
              |/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def{ lv_nl }| &&
              |/CMapName /Adobe-Identity-UCS def{ lv_nl }/CMapType 2 def{ lv_nl }| &&
              |1 begincodespacerange{ lv_nl }<0000> <FFFF>{ lv_nl }endcodespacerange{ lv_nl }| &&
              |{ lv_cmap }endcmap{ lv_nl }CMapName currentdict /CMap defineresource pop{ lv_nl }end{ lv_nl }end|.
    ls_obj-stream = zcl_pdf_studio_conv=>string_to_xstring( lv_cmap ).
    ls_obj-text = |<< /Length { xstrlen( ls_obj-stream ) } >>|.
    APPEND ls_obj TO rt_objs.
  ENDMETHOD.


  METHOD checksum.
    DATA lv_data TYPE xstring.
    DATA lv_off TYPE i.
    DATA lv_word TYPE ty_x4.
    DATA lv_int TYPE i.
    DATA lv_sum TYPE p LENGTH 16 DECIMALS 0.
    CONSTANTS lc_mod TYPE p LENGTH 16 DECIMALS 0 VALUE 4294967296.

    lv_data = iv_data.
    pad4( CHANGING cv_data = lv_data ).
    WHILE lv_off < xstrlen( lv_data ).
      lv_word = lv_data+lv_off(4).
      lv_int = lv_word.
      IF lv_int < 0.
        lv_sum = lv_sum + lv_int + lc_mod.
      ELSE.
        lv_sum = lv_sum + lv_int.
      ENDIF.
      lv_off = lv_off + 4.
    ENDWHILE.
    lv_sum = lv_sum MOD lc_mod.
    IF lv_sum >= 2147483648.
      lv_int = lv_sum - lc_mod.
    ELSE.
      lv_int = lv_sum.
    ENDIF.
    rv_sum = lv_int.
  ENDMETHOD.


  METHOD x2.
    DATA lv_x TYPE x LENGTH 2.
    lv_x = iv_val.
    rv_x = lv_x.
  ENDMETHOD.


  METHOD x4.
    DATA lv_x TYPE x LENGTH 4.
    lv_x = iv_val.
    rv_x = lv_x.
  ENDMETHOD.


  METHOD pad4.
    DATA lv_zero TYPE x LENGTH 1 VALUE '00'.
    WHILE xstrlen( cv_data ) MOD 4 <> 0.
      CONCATENATE cv_data lv_zero INTO cv_data IN BYTE MODE.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
