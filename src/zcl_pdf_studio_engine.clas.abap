CLASS zcl_pdf_studio_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS render
      IMPORTING
        iv_html       TYPE string
        iv_css        TYPE string OPTIONAL
        iv_header     TYPE string OPTIONAL
        iv_footer     TYPE string OPTIONAL
        is_page       TYPE zcl_pdf_studio_renderer=>ty_page
        io_resources  TYPE REF TO zif_pdf_studio_resources OPTIONAL
        is_info       TYPE zcl_pdf_studio_renderer=>ty_info OPTIONAL
      RETURNING
        VALUE(rv_pdf) TYPE xstring
      RAISING
        zcx_pdf_studio.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_token,
        kind  TYPE c LENGTH 1,
        name  TYPE string,
        attrs TYPE string,
        text  TYPE string,
      END OF ty_token,
      ty_tokens TYPE STANDARD TABLE OF ty_token WITH EMPTY KEY,
      BEGIN OF ty_style,
        family    TYPE c LENGTH 1,
        "Uploaded TrueType family (lower case) when family = 'X'.
        custom    TYPE string,
        bold      TYPE abap_bool,
        italic    TYPE abap_bool,
        underline TYPE abap_bool,
        size      TYPE f,
        color     TYPE string,
        align     TYPE string,
        pre       TYPE abap_bool,
        dir       TYPE c LENGTH 1,
      END OF ty_style,
      BEGIN OF ty_box,
        x       TYPE f,
        y       TYPE f,
        w       TYPE f,
        h       TYPE f,
        has_h   TYPE abap_bool,
        border  TYPE f,
        pad     TYPE f,
        fill    TYPE string,
        e_top   TYPE string,
        e_right TYPE string,
        e_bot   TYPE string,
        e_left  TYPE string,
        round   TYPE abap_bool,
        fit     TYPE string,
        "transform:rotate(deg), clockwise as in CSS.
        rotate  TYPE f,
        opacity TYPE f,
        has_opacity TYPE abap_bool,
        "vertical-align of the text in an object: top, middle, bottom.
        valign  TYPE string,
        mt      TYPE f,
        mb      TYPE f,
        no_edge TYPE abap_bool,
        ml      TYPE f,
        "Per-side borders (border-top/-right/-bottom/-left): own width and line style.
        per_edge TYPE abap_bool,
        w_top   TYPE f,
        w_right TYPE f,
        w_bot   TYPE f,
        w_left  TYPE f,
        s_top   TYPE string,
        s_right TYPE string,
        s_bot   TYPE string,
        s_left  TYPE string,
      END OF ty_box,
      BEGIN OF ty_frame,
        name  TYPE string,
        style TYPE ty_style,
        mb    TYPE f,
      END OF ty_frame,
      ty_frames TYPE STANDARD TABLE OF ty_frame WITH EMPTY KEY,
      BEGIN OF ty_piece,
        hex    TYPE string,
        spaces TYPE i,
        brk    TYPE abap_bool,
        font   TYPE i,
        size   TYPE f,
        color  TYPE string,
        under  TYPE abap_bool,
        width  TYPE f,
        x      TYPE f,
        "R = Arabic (right to left), L = Latin letters, N = digits and punctuation.
        bidi   TYPE c LENGTH 1,
        "Paragraph direction from CSS direction: R, L, or empty (first strong letter decides).
        pdir   TYPE c LENGTH 1,
        "Continues the previous piece's word: never a line break in front of it.
        glue   TYPE abap_bool,
      END OF ty_piece,
      ty_pieces TYPE STANDARD TABLE OF ty_piece WITH EMPTY KEY,
      BEGIN OF ty_line,
        pieces TYPE ty_pieces,
        width  TYPE f,
        size   TYPE f,
      END OF ty_line,
      ty_lines TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY,
      BEGIN OF ty_image,
        src    TYPE string,
        name   TYPE string,
        dict   TYPE string,
        data   TYPE xstring,
        width  TYPE i,
        height TYPE i,
      END OF ty_image,
      ty_images TYPE STANDARD TABLE OF ty_image WITH EMPTY KEY,
      BEGIN OF ty_rule,
        tag   TYPE string,
        decls TYPE string,
      END OF ty_rule,
      ty_rules   TYPE STANDARD TABLE OF ty_rule WITH EMPTY KEY,
      ty_strings TYPE STANDARD TABLE OF string WITH EMPTY KEY,
      ty_ints    TYPE STANDARD TABLE OF i WITH EMPTY KEY,
      ty_floats  TYPE STANDARD TABLE OF f WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_tcell,
        row     TYPE i,
        col     TYPE i,
        colspan TYPE i,
        rowspan TYPE i,
        head    TYPE abap_bool,
        tokens  TYPE ty_tokens,
        style   TYPE ty_style,
        box     TYPE ty_box,
        valign  TYPE string,
        nat     TYPE f,
        minw    TYPE f,
        lines   TYPE ty_lines,
        texth   TYPE f,
        pct     TYPE f,
      END OF ty_tcell,
      ty_tcells TYPE STANDARD TABLE OF ty_tcell WITH EMPTY KEY,
      BEGIN OF ty_trow,
        part   TYPE c LENGTH 1,
        height TYPE f,
        fill   TYPE string,
      END OF ty_trow,
      ty_trows TYPE STANDARD TABLE OF ty_trow WITH EMPTY KEY.

    CONSTANTS c_line_factor TYPE f VALUE '1.15'.
    CONSTANTS c_pi TYPE f VALUE '3.14159265358979'.

    CLASS-DATA gt_widths TYPE ty_ints.

    DATA mv_pw TYPE f.
    DATA mv_ph TYPE f.
    DATA mv_ml TYPE f.
    DATA mv_mt TYPE f.
    DATA mv_mr TYPE f.
    DATA mv_mb TYPE f.
    DATA mt_pages TYPE ty_strings.
    DATA mv_page TYPE i.
    DATA mt_images TYPE ty_images.
    DATA mt_rules TYPE ty_rules.
    DATA mv_y TYPE f.
    DATA mv_gap TYPE f.
    DATA mv_pending TYPE i.
    DATA mv_align TYPE string.

    METHODS run
      IMPORTING
        iv_html       TYPE string
        iv_css        TYPE string
        iv_header     TYPE string
        iv_footer     TYPE string
        is_page       TYPE zcl_pdf_studio_renderer=>ty_page
      RETURNING
        VALUE(rv_pdf) TYPE xstring
      RAISING
        zcx_pdf_studio.
    METHODS setup_page
      IMPORTING is_page TYPE zcl_pdf_studio_renderer=>ty_page.
    CLASS-METHODS load_widths.
    CLASS-METHODS tokenize
      IMPORTING iv_html          TYPE string
      RETURNING VALUE(rt_tokens) TYPE ty_tokens.
    CLASS-METHODS attr
      IMPORTING iv_attrs        TYPE string
                iv_name         TYPE string
      RETURNING VALUE(rv_value) TYPE string.
    CLASS-METHODS decode
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS hex_to_int
      IMPORTING iv_hex        TYPE string
      RETURNING VALUE(rv_int) TYPE i.
    CLASS-METHODS encode
      IMPORTING iv_text       TYPE string
      RETURNING VALUE(rv_hex) TYPE string.
    "Text in the encoding of a font: one byte per character for the standard fonts,
    "glyph ids (4 hex digits) for uploaded TrueType fonts.
    METHODS encode_font
      IMPORTING iv_text       TYPE string
                iv_font       TYPE i
      RETURNING VALUE(rv_hex) TYPE string.
    METHODS custom_font
      IMPORTING iv_slot        TYPE i
      RETURNING VALUE(ro_font) TYPE REF TO zcl_pdf_studio_font.
    "PDF text string (UTF-16BE with byte order mark) for the document information.
    CLASS-METHODS pdf_text
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS pdf_date
      RETURNING VALUE(rv_date) TYPE string.
    "Vertical shift of the objects that follow the tables of a section (data-flow="after").
    "May start a new page when the objects do not fit below the table any more.
    METHODS flow_shift
      IMPORTING it_tokens       TYPE ty_tokens
                iv_from         TYPE i
      RETURNING VALUE(rv_shift) TYPE f.
    "Master page rule of an object (data-every): 1/all, first, notfirst, last, notlast, odd, even.
    CLASS-METHODS on_page
      IMPORTING iv_rule       TYPE string
                iv_page       TYPE i
                iv_total      TYPE i
      RETURNING VALUE(rv_yes) TYPE abap_bool.
    "Fills <span class="pageNumber"> and <span class="totalPages"> with the numbers.
    CLASS-METHODS page_tokens
      IMPORTING it_tokens        TYPE ty_tokens
                iv_page          TYPE i
                iv_total         TYPE i
      RETURNING VALUE(rt_tokens) TYPE ty_tokens.
    "PNG with transparency (gray+alpha, RGBA, 8 bit): colour image with a soft mask.
    METHODS png_alpha
      IMPORTING iv_data      TYPE xstring
      CHANGING  cs_image     TYPE ty_image.
    "Graphics states for transparency (opacity of objects and watermarks).
    METHODS gstates
      RETURNING VALUE(rv_dict) TYPE string.
    METHODS gstate_name
      IMPORTING iv_opacity     TYPE f
      RETURNING VALUE(rv_name) TYPE string.
    METHODS char_width
      IMPORTING iv_font         TYPE i
                iv_code         TYPE i
      RETURNING VALUE(rv_width) TYPE f.
    METHODS hex_width
      IMPORTING iv_hex          TYPE string
                iv_font         TYPE i
                iv_size         TYPE f
      RETURNING VALUE(rv_width) TYPE f.
    METHODS font_index
      IMPORTING is_style        TYPE ty_style
      RETURNING VALUE(rv_index) TYPE i.
    CLASS-METHODS length_pt
      IMPORTING iv_value     TYPE string
                iv_base      TYPE f
      RETURNING VALUE(rv_pt) TYPE f.
    CLASS-METHODS color
      IMPORTING iv_value      TYPE string
      RETURNING VALUE(rv_rgb) TYPE string.
    CLASS-METHODS num
      IMPORTING iv_value       TYPE f
      RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS base_style
      RETURNING VALUE(rs_style) TYPE ty_style.
    METHODS parse_css
      IMPORTING iv_css TYPE string.
    METHODS apply_decls
      IMPORTING iv_decls TYPE string
                iv_base  TYPE f
      CHANGING  cs_style TYPE ty_style
                cs_box   TYPE ty_box.
    METHODS tag_style
      IMPORTING iv_name  TYPE string
                iv_attrs TYPE string
                is_parent TYPE ty_style
      EXPORTING es_style TYPE ty_style
                es_box   TYPE ty_box.
    METHODS add_text
      IMPORTING iv_text   TYPE string
                is_style  TYPE ty_style
      CHANGING  ct_pieces TYPE ty_pieces.
    METHODS add_break
      IMPORTING is_style  TYPE ty_style
      CHANGING  ct_pieces TYPE ty_pieces.
    METHODS collect
      IMPORTING it_tokens        TYPE ty_tokens
                is_style         TYPE ty_style
                iv_page          TYPE i DEFAULT 0
                iv_total         TYPE i DEFAULT 0
      EXPORTING ev_align         TYPE string
      RETURNING VALUE(rt_pieces) TYPE ty_pieces.
    METHODS wrap
      IMPORTING it_pieces       TYPE ty_pieces
                iv_width        TYPE f
      RETURNING VALUE(rt_lines) TYPE ty_lines.
    METHODS line_height
      IMPORTING is_line          TYPE ty_line
      RETURNING VALUE(rv_height) TYPE f.
    METHODS draw_line
      IMPORTING is_line  TYPE ty_line
                iv_x     TYPE f
                iv_width TYPE f
                iv_top   TYPE f
                iv_align TYPE string.
    METHODS draw_lines
      IMPORTING it_lines         TYPE ty_lines
                iv_x             TYPE f
                iv_width         TYPE f
                iv_top           TYPE f
                iv_align         TYPE string
      RETURNING VALUE(rv_height) TYPE f.
    METHODS new_page.
    METHODS emit
      IMPORTING iv_ops TYPE string.
    METHODS layout_widgets
      IMPORTING it_tokens TYPE ty_tokens
      RAISING   zcx_pdf_studio.
    METHODS word_pieces
      IMPORTING iv_word          TYPE string
                is_style         TYPE ty_style
                iv_font          TYPE i
      RETURNING VALUE(rt_pieces) TYPE ty_pieces.
    METHODS visual_order
      CHANGING cs_line TYPE ty_line.
    "First / after-last position of a Latin letter or digit.
    CLASS-METHODS alnum_from
      IMPORTING iv_text       TYPE string
      RETURNING VALUE(rv_pos) TYPE i.
    CLASS-METHODS alnum_to
      IMPORTING iv_text       TYPE string
      RETURNING VALUE(rv_pos) TYPE i.
    METHODS append_part
      IMPORTING iv_text   TYPE string
                iv_bidi   TYPE c
                iv_font   TYPE i
                is_style  TYPE ty_style
      CHANGING  ct_pieces TYPE ty_pieces.
    TYPES:
      BEGIN OF ty_font,
        slot   TYPE i,
        family TYPE string,
        bold   TYPE abap_bool,
        italic TYPE abap_bool,
        font   TYPE REF TO zcl_pdf_studio_font,
      END OF ty_font,
      ty_fonts TYPE STANDARD TABLE OF ty_font WITH EMPTY KEY.
    "Uploaded fonts get the resource names /F21, /F22, ...
    CONSTANTS c_first_custom TYPE i VALUE 21.
    DATA mo_res TYPE REF TO zif_pdf_studio_resources.
    DATA mt_families TYPE ty_strings.
    DATA mt_fonts TYPE ty_fonts.
    DATA ms_info TYPE zcl_pdf_studio_renderer=>ty_info.
    "Opacity levels in percent used by the document (graphics states /GS<level>).
    DATA mt_opacity TYPE ty_ints.
    DATA mv_ar_regular TYPE abap_bool.
    DATA mv_ar_bold TYPE abap_bool.
    METHODS draw_widget
      IMPORTING iv_style  TYPE string
                it_tokens TYPE ty_tokens
                iv_attrs  TYPE string OPTIONAL
                iv_shift  TYPE f DEFAULT 0
      RAISING   zcx_pdf_studio.
    METHODS draw_code
      IMPORTING iv_attrs  TYPE string
                it_tokens TYPE ty_tokens
                is_style  TYPE ty_style
                iv_x      TYPE f
                iv_top    TYPE f
                iv_w      TYPE f
                iv_h      TYPE f
      RAISING   zcx_pdf_studio.
    METHODS draw_box
      IMPORTING is_box TYPE ty_box
                iv_x   TYPE f
                iv_top TYPE f.
    METHODS draw_image
      IMPORTING iv_src TYPE string
                iv_x   TYPE f
                iv_top TYPE f
                iv_w   TYPE f
                iv_h   TYPE f
                iv_fit TYPE string
      RAISING   zcx_pdf_studio.
    METHODS load_image
      IMPORTING iv_src         TYPE string
      EXPORTING ev_width       TYPE i
                ev_height      TYPE i
      RETURNING VALUE(rv_name) TYPE string
      RAISING   zcx_pdf_studio.
    CLASS-METHODS parse_jpeg
      IMPORTING iv_data TYPE xstring
      CHANGING  cs_image TYPE ty_image.
    CLASS-METHODS parse_png
      IMPORTING iv_data TYPE xstring
      CHANGING  cs_image TYPE ty_image.
    CLASS-METHODS bytes_int
      IMPORTING iv_data       TYPE xstring
                iv_off        TYPE i
                iv_len        TYPE i
      RETURNING VALUE(rv_int) TYPE i.
    METHODS layout_flow
      IMPORTING it_tokens TYPE ty_tokens
      RAISING   zcx_pdf_studio.
    METHODS flush_block
      CHANGING ct_pieces TYPE ty_pieces.
    METHODS flow_image
      IMPORTING iv_attrs TYPE string
                iv_align TYPE string
      RAISING   zcx_pdf_studio.
    METHODS margin_text
      IMPORTING iv_fragment TYPE string
                iv_page     TYPE i
                iv_total    TYPE i
                iv_top      TYPE abap_bool.
    METHODS assemble
      RETURNING VALUE(rv_pdf) TYPE xstring
      RAISING   zcx_pdf_studio.
    METHODS layout_table
      IMPORTING it_tokens TYPE ty_tokens
                iv_attrs  TYPE string
                is_parent TYPE ty_style
                iv_x      TYPE f
                iv_width  TYPE f.
    METHODS raw_prop
      IMPORTING iv_tag          TYPE string
                iv_attrs        TYPE string
                iv_prop         TYPE string
      RETURNING VALUE(rv_value) TYPE string.
    METHODS draw_table_rows
      IMPORTING it_cells TYPE ty_tcells
                it_rows  TYPE ty_trows
                it_colx  TYPE ty_floats
                it_colw  TYPE ty_floats
                iv_first TYPE i
                iv_last  TYPE i
                iv_x     TYPE f
                iv_top   TYPE f.
    METHODS draw_edges
      IMPORTING is_box TYPE ty_box
                iv_x   TYPE f
                iv_top TYPE f
                iv_w   TYPE f
                iv_h   TYPE f.
    "One side of a cell: a filled bar for solid lines, a dashed stroke otherwise.
    METHODS edge_line
      IMPORTING iv_color TYPE string
                iv_style TYPE string
                iv_b     TYPE f
                iv_x1    TYPE f
                iv_y1    TYPE f
                iv_x2    TYPE f
                iv_y2    TYPE f.
    CLASS-METHODS table_end
      IMPORTING it_tokens     TYPE ty_tokens
                iv_start      TYPE i
      RETURNING VALUE(rv_end) TYPE i.
    CLASS-METHODS is_block
      IMPORTING iv_name       TYPE string
      RETURNING VALUE(rv_yes) TYPE abap_bool.
ENDCLASS.



CLASS zcl_pdf_studio_engine IMPLEMENTATION.

  METHOD render.
    DATA lo_native TYPE REF TO zcl_pdf_studio_engine.
    CREATE OBJECT lo_native.
    lo_native->mo_res = io_resources.
    lo_native->ms_info = is_info.
    IF io_resources IS BOUND.
      lo_native->mt_families = io_resources->font_families( ).
    ENDIF.
    rv_pdf = lo_native->run(
      iv_html   = iv_html
      iv_css    = iv_css
      iv_header = iv_header
      iv_footer = iv_footer
      is_page   = is_page ).
  ENDMETHOD.

  METHOD run.
    DATA lt_tokens TYPE ty_tokens.
    DATA ls_token TYPE ty_token.
    DATA lv_widgets TYPE abap_bool.
    DATA lv_total TYPE i.
    DATA lv_page TYPE i.

    setup_page( is_page ).
    load_widths( ).
    parse_css( iv_css ).

    "Forms of the designers start with their layout comment: objects are placed absolutely.
    IF strlen( iv_html ) >= 11 AND ( iv_html(11) = '<!--abappdf' OR iv_html(11) = '<!--zpdf-st' ).
      lv_widgets = abap_true.
    ENDIF.
    lt_tokens = tokenize( iv_html ).
    IF lv_widgets = abap_false.
      LOOP AT lt_tokens INTO ls_token WHERE kind = 'O' AND name = 'div'.
        IF to_lower( attr( iv_attrs = ls_token-attrs iv_name = `style` ) ) CS 'position:absolute'.
          lv_widgets = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF lv_widgets = abap_true.
      layout_widgets( lt_tokens ).
    ELSE.
      layout_flow( lt_tokens ).
    ENDIF.
    IF mt_pages IS INITIAL.
      new_page( ).
    ENDIF.

    lv_total = lines( mt_pages ).
    DO lv_total TIMES.
      lv_page = sy-index.
      mv_page = lv_page.
      IF iv_header IS NOT INITIAL.
        margin_text( iv_fragment = iv_header iv_page = lv_page iv_total = lv_total iv_top = abap_true ).
      ENDIF.
      IF iv_footer IS NOT INITIAL.
        margin_text( iv_fragment = iv_footer iv_page = lv_page iv_total = lv_total iv_top = abap_false ).
      ENDIF.
    ENDDO.

    rv_pdf = assemble( ).
  ENDMETHOD.

  METHOD setup_page.
    DATA lv_w TYPE f.
    DATA lv_h TYPE f.
    DATA lv_swap TYPE f.
    DATA lv_mm TYPE f.

    CASE to_upper( is_page-page_size ).
      WHEN 'A3'.
        lv_w = 297.
        lv_h = 420.
      WHEN 'A5'.
        lv_w = 148.
        lv_h = 210.
      WHEN 'LETTER'.
        lv_w = '215.9'.
        lv_h = '279.4'.
      WHEN 'LEGAL'.
        lv_w = '215.9'.
        lv_h = '355.6'.
      WHEN OTHERS.
        lv_w = 210.
        lv_h = 297.
    ENDCASE.
    IF is_page-orientation = 'L'.
      lv_swap = lv_w.
      lv_w = lv_h.
      lv_h = lv_swap.
    ENDIF.
    lv_mm = 72 / '25.4'.
    mv_pw = lv_w * lv_mm.
    mv_ph = lv_h * lv_mm.
    mv_mt = is_page-margin_top * lv_mm.
    mv_mr = is_page-margin_right * lv_mm.
    mv_mb = is_page-margin_bottom * lv_mm.
    mv_ml = is_page-margin_left * lv_mm.
  ENDMETHOD.

  METHOD load_widths.
    DATA lv_all TYPE string.
    DATA lt_fonts TYPE ty_strings.
    DATA lt_values TYPE ty_strings.
    DATA lv_font TYPE string.
    DATA lv_value TYPE string.
    DATA lv_width TYPE i.

    IF gt_widths IS NOT INITIAL.
      RETURN.
    ENDIF.
    "Glyph widths (1/1000 em) for WinAnsi codes 32..255, standard PDF fonts.
    lv_all =
      '278,278,355,556,556,889,667,191,333,333,389,584,278,333,278,278,556,556,556,556,556,556,55' &&
      '6,556,556,556,278,278,584,584,584,556,1015,667,667,722,722,667,611,778,722,278,500,667,556' &&
      ',833,722,778,667,778,722,667,611,722,667,944,667,667,611,278,278,278,469,556,333,556,556,5' &&
      '00,556,556,278,556,556,222,222,500,222,833,556,556,556,556,333,500,278,556,500,722,500,500' &&
      ',500,334,260,334,584,761,556,0,222,556,333,1000,556,556,333,1000,667,333,1000,0,611,0,0,22' &&
      '2,222,333,333,350,556,1000,333,1000,500,333,944,0,500,667,278,333,556,556,556,556,260,556,' &&
      '333,737,370,556,584,333,737,333,400,584,333,333,333,556,537,278,333,333,365,556,834,834,83' &&
      '4,611,667,667,667,667,667,667,1000,722,667,667,667,667,278,278,278,278,722,722,778,778,778' &&
      ',778,778,584,778,722,722,722,722,667,667,611,556,556,556,556,556,556,889,500,556,556,556,5' &&
      '56,278,278,278,278,556,556,556,556,556,556,556,584,611,556,556,556,556,500,556,500;' &&
      '278,333,474,556,556,889,722,238,333,333,389,584,278,333,278,278,556,556,556,556,556,556,55' &&
      '6,556,556,556,333,333,584,584,584,611,975,722,722,722,722,667,611,778,722,278,556,722,611,' &&
      '833,722,778,667,778,722,667,611,722,667,944,667,667,611,333,278,333,584,556,333,556,611,55' &&
      '6,611,556,333,611,611,278,278,556,278,889,611,611,611,611,389,556,333,611,556,778,556,556,' &&
      '500,389,280,389,584,761,556,0,278,556,500,1000,556,556,333,1000,667,333,1000,0,611,0,0,278' &&
      ',278,500,500,350,556,1000,333,1000,556,333,944,0,500,667,278,333,556,556,556,556,280,556,3' &&
      '33,737,370,556,584,333,737,333,400,584,333,333,333,611,556,278,333,333,365,556,834,834,834' &&
      ',611,722,722,722,722,722,722,1000,722,667,667,667,667,278,278,278,278,722,722,778,778,778,' &&
      '778,778,584,778,722,722,722,722,667,667,611,556,556,556,556,556,556,889,556,556,556,556,55' &&
      '6,278,278,278,278,611,611,611,611,611,611,611,584,611,611,611,611,611,556,611,556;' &&
      '250,333,408,500,500,833,778,180,333,333,500,564,250,333,250,278,500,500,500,500,500,500,50' &&
      '0,500,500,500,278,278,564,564,564,444,921,722,667,667,722,611,556,722,722,333,389,722,611,' &&
      '889,722,722,556,722,667,556,611,722,722,944,722,722,611,333,278,333,469,500,333,444,500,44' &&
      '4,500,444,333,500,500,278,278,500,278,778,500,500,500,500,333,389,278,500,500,722,500,500,' &&
      '444,480,200,480,541,761,500,0,333,500,444,1000,500,500,333,1000,556,333,889,0,611,0,0,333,' &&
      '333,444,444,350,500,1000,333,980,389,333,722,0,444,722,250,333,500,500,500,500,200,500,333' &&
      ',760,276,500,564,333,760,333,400,564,300,300,333,500,453,250,333,300,310,500,750,750,750,4' &&
      '44,722,722,722,722,722,722,889,667,611,611,611,611,333,333,333,333,722,722,722,722,722,722' &&
      ',722,564,722,722,722,722,722,722,556,500,444,444,444,444,444,444,667,444,444,444,444,444,2' &&
      '78,278,278,278,500,500,500,500,500,500,500,564,500,500,500,500,500,500,500,500;' &&
      '250,333,555,500,500,1000,833,278,333,333,500,570,250,333,250,278,500,500,500,500,500,500,5' &&
      '00,500,500,500,333,333,570,570,570,500,930,722,667,722,722,667,611,778,778,389,500,778,667' &&
      ',944,722,778,611,778,722,556,667,722,722,1000,722,722,667,333,278,333,581,500,333,500,556,' &&
      '444,556,444,333,500,556,278,333,556,278,833,556,500,556,556,444,389,333,556,500,722,500,50' &&
      '0,444,394,220,394,520,761,500,0,333,500,500,1000,500,500,333,1000,556,333,1000,0,667,0,0,3' &&
      '33,333,500,500,350,500,1000,333,1000,389,333,722,0,444,722,250,333,500,500,500,500,220,500' &&
      ',333,747,300,500,570,333,747,333,400,570,300,300,333,556,540,250,333,300,330,500,750,750,7' &&
      '50,500,722,722,722,722,722,722,1000,722,667,667,667,667,389,389,389,389,722,722,778,778,77' &&
      '8,778,778,570,778,722,722,722,722,722,611,556,500,500,500,500,500,500,722,444,444,444,444,' &&
      '444,278,278,278,278,500,556,500,500,500,500,500,570,500,556,556,556,556,500,556,500;' &&
      '250,333,420,500,500,833,778,214,333,333,500,675,250,333,250,278,500,500,500,500,500,500,50' &&
      '0,500,500,500,333,333,675,675,675,500,920,611,611,667,722,611,611,722,722,333,444,667,556,' &&
      '833,667,722,611,722,611,500,556,722,611,833,611,556,556,389,278,389,422,500,333,500,500,44' &&
      '4,500,444,278,500,500,278,278,444,278,722,500,500,500,500,389,389,278,500,444,667,444,444,' &&
      '389,400,275,400,541,761,500,0,333,500,556,889,500,500,333,1000,500,333,944,0,556,0,0,333,3' &&
      '33,556,556,350,500,889,333,980,389,333,667,0,389,556,250,389,500,500,500,500,275,500,333,7' &&
      '60,276,500,675,333,760,333,400,675,300,300,333,500,523,250,333,300,310,500,750,750,750,500' &&
      ',611,611,611,611,611,611,889,667,611,611,611,611,333,333,333,333,722,667,722,722,722,722,7' &&
      '22,675,722,722,722,722,722,556,611,500,500,500,500,500,500,500,667,444,444,444,444,444,278' &&
      ',278,278,278,500,500,500,500,500,500,500,675,500,500,500,500,500,444,500,444;' &&
      '250,389,555,500,500,833,778,278,333,333,500,570,250,333,250,278,500,500,500,500,500,500,50' &&
      '0,500,500,500,333,333,570,570,570,500,832,667,667,667,722,667,667,722,778,389,500,667,611,' &&
      '889,722,722,611,722,667,556,611,722,667,889,667,611,611,333,278,333,570,500,333,500,500,44' &&
      '4,500,444,333,500,556,278,278,500,278,778,556,500,500,500,389,389,278,556,444,667,500,444,' &&
      '389,348,220,348,570,761,500,0,333,500,500,1000,500,500,333,1000,556,333,944,0,611,0,0,333,' &&
      '333,500,500,350,500,1000,333,1000,389,333,722,0,389,611,250,389,500,500,500,500,220,500,33' &&
      '3,747,266,500,606,333,747,333,400,570,300,300,333,576,500,250,333,300,300,500,750,750,750,' &&
      '500,667,667,667,667,667,667,944,667,667,667,667,667,389,389,389,389,722,722,722,722,722,72' &&
      '2,722,570,722,722,722,722,722,611,611,500,500,500,500,500,500,500,722,444,444,444,444,444,' &&
      '278,278,278,278,500,556,500,500,500,500,500,570,500,556,556,556,556,444,500,444;'.
    SPLIT lv_all AT ';' INTO TABLE lt_fonts.
    LOOP AT lt_fonts INTO lv_font.
      IF lv_font IS INITIAL.
        CONTINUE.
      ENDIF.
      SPLIT lv_font AT ',' INTO TABLE lt_values.
      LOOP AT lt_values INTO lv_value.
        lv_width = lv_value.
        APPEND lv_width TO gt_widths.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD tokenize.
    DATA lv_lower TYPE string.
    DATA lv_len TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_lt TYPE i.
    DATA lv_gt TYPE i.
    DATA lv_end TYPE i.
    DATA lv_inner TYPE string.
    DATA lv_rest TYPE string.
    DATA lv_space TYPE i.
    DATA ls_token TYPE ty_token.

    lv_lower = to_lower( iv_html ).
    lv_len = strlen( iv_html ).
    WHILE lv_pos < lv_len.
      lv_lt = find( val = iv_html sub = '<' off = lv_pos ).
      IF lv_lt < 0.
        CLEAR ls_token.
        ls_token-kind = 'T'.
        ls_token-text = substring( val = iv_html off = lv_pos ).
        APPEND ls_token TO rt_tokens.
        EXIT.
      ENDIF.
      IF lv_lt > lv_pos.
        CLEAR ls_token.
        ls_token-kind = 'T'.
        ls_token-text = substring( val = iv_html off = lv_pos len = lv_lt - lv_pos ).
        APPEND ls_token TO rt_tokens.
      ENDIF.
      IF lv_lt + 4 <= lv_len AND substring( val = iv_html off = lv_lt len = 4 ) = '<!--'.
        lv_end = find( val = iv_html sub = '-->' off = lv_lt ).
        IF lv_end < 0.
          EXIT.
        ENDIF.
        lv_pos = lv_end + 3.
        CONTINUE.
      ENDIF.
      lv_gt = find( val = iv_html sub = '>' off = lv_lt ).
      IF lv_gt < 0.
        CLEAR ls_token.
        ls_token-kind = 'T'.
        ls_token-text = substring( val = iv_html off = lv_lt ).
        APPEND ls_token TO rt_tokens.
        EXIT.
      ENDIF.
      lv_inner = substring( val = iv_html off = lv_lt + 1 len = lv_gt - lv_lt - 1 ).
      lv_pos = lv_gt + 1.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_inner WITH ` `.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_inner WITH ` `.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf(1) IN lv_inner WITH ` `.
      CONDENSE lv_inner.
      IF lv_inner IS INITIAL.
        CONTINUE.
      ENDIF.
      CLEAR ls_token.
      IF lv_inner(1) = '/'.
        ls_token-kind = 'C'.
        ls_token-name = to_lower( substring( val = lv_inner off = 1 ) ).
        CONDENSE ls_token-name.
        APPEND ls_token TO rt_tokens.
        CONTINUE.
      ENDIF.
      IF lv_inner(1) = '!' OR lv_inner(1) = '?'.
        CONTINUE.
      ENDIF.
      lv_space = find( val = lv_inner sub = ` ` ).
      IF lv_space < 0.
        ls_token-name = to_lower( lv_inner ).
      ELSE.
        ls_token-name = to_lower( substring( val = lv_inner len = lv_space ) ).
        ls_token-attrs = substring( val = lv_inner off = lv_space + 1 ).
      ENDIF.
      lv_rest = ls_token-name.
      IF lv_rest CP '*/'.
        ls_token-name = substring( val = lv_rest len = strlen( lv_rest ) - 1 ).
      ENDIF.
      CASE ls_token-name.
        WHEN 'br' OR 'img' OR 'hr' OR 'meta' OR 'link' OR 'input' OR 'col' OR 'wbr'.
          ls_token-kind = 'S'.
        WHEN OTHERS.
          IF strlen( lv_inner ) > 0 AND substring( val = lv_inner off = strlen( lv_inner ) - 1 len = 1 ) = '/'.
            ls_token-kind = 'S'.
          ELSE.
            ls_token-kind = 'O'.
          ENDIF.
      ENDCASE.
      IF ls_token-name = 'script' OR ls_token-name = 'style' OR ls_token-name = 'head' OR ls_token-name = 'title'.
        lv_end = find( val = lv_lower sub = |</{ ls_token-name }| off = lv_pos ).
        IF lv_end < 0.
          EXIT.
        ENDIF.
        lv_gt = find( val = iv_html sub = '>' off = lv_end ).
        IF lv_gt < 0.
          EXIT.
        ENDIF.
        lv_pos = lv_gt + 1.
        CONTINUE.
      ENDIF.
      APPEND ls_token TO rt_tokens.
    ENDWHILE.
  ENDMETHOD.

  METHOD attr.
    DATA lv_lower TYPE string.
    DATA lv_at TYPE i.
    DATA lv_off TYPE i.
    DATA lv_quote TYPE c LENGTH 1.
    DATA lv_end TYPE i.
    DATA lv_prev TYPE c LENGTH 1.

    lv_lower = to_lower( iv_attrs ).
    lv_off = 0.
    DO.
      lv_at = find( val = lv_lower sub = |{ iv_name }=| off = lv_off ).
      IF lv_at < 0.
        RETURN.
      ENDIF.
      IF lv_at > 0.
        lv_off = lv_at - 1.
        lv_prev = lv_lower+lv_off(1).
      ELSE.
        lv_prev = ' '.
      ENDIF.
      lv_off = lv_at + strlen( iv_name ) + 1.
      IF lv_prev = ' ' OR lv_prev = '"' OR lv_prev = ''''.
        EXIT.
      ENDIF.
    ENDDO.
    IF lv_off >= strlen( iv_attrs ).
      RETURN.
    ENDIF.
    lv_quote = iv_attrs+lv_off(1).
    IF lv_quote = '"' OR lv_quote = ''''.
      lv_off = lv_off + 1.
      lv_end = find( val = iv_attrs sub = lv_quote off = lv_off ).
      IF lv_end < 0.
        lv_end = strlen( iv_attrs ).
      ENDIF.
    ELSE.
      lv_end = find( val = iv_attrs sub = ` ` off = lv_off ).
      IF lv_end < 0.
        lv_end = strlen( iv_attrs ).
      ENDIF.
    ENDIF.
    rv_value = substring( val = iv_attrs off = lv_off len = lv_end - lv_off ).
  ENDMETHOD.

  METHOD hex_to_int.
    DATA lv_digits TYPE string VALUE '0123456789ABCDEF'.
    DATA lv_hex TYPE string.
    DATA lv_at TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE c LENGTH 1.

    DATA lv_len TYPE i.

    lv_hex = to_upper( iv_hex ).
    lv_len = strlen( lv_hex ).
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_c = lv_hex+lv_i(1).
      lv_at = find( val = lv_digits sub = lv_c ).
      IF lv_at < 0 OR rv_int > 6000000.
        RETURN.
      ENDIF.
      rv_int = rv_int * 16 + lv_at.
    ENDDO.
  ENDMETHOD.

  METHOD decode.
    DATA lv_pos TYPE i.
    DATA lv_amp TYPE i.
    DATA lv_semi TYPE i.
    DATA lv_ent TYPE string.
    DATA lv_code TYPE i.
    DATA lv_char TYPE c LENGTH 1.
    DATA lv_len TYPE i.

    IF iv_text NS '&'.
      rv_text = iv_text.
      RETURN.
    ENDIF.
    lv_len = strlen( iv_text ).
    WHILE lv_pos < lv_len.
      lv_amp = find( val = iv_text sub = '&' off = lv_pos ).
      IF lv_amp < 0.
        rv_text = rv_text && substring( val = iv_text off = lv_pos ).
        RETURN.
      ENDIF.
      rv_text = rv_text && substring( val = iv_text off = lv_pos len = lv_amp - lv_pos ).
      lv_semi = find( val = iv_text sub = ';' off = lv_amp ).
      IF lv_semi < 0 OR lv_semi - lv_amp > 10 OR lv_semi - lv_amp < 2.
        rv_text = rv_text && '&'.
        lv_pos = lv_amp + 1.
        CONTINUE.
      ENDIF.
      lv_ent = substring( val = iv_text off = lv_amp + 1 len = lv_semi - lv_amp - 1 ).
      lv_pos = lv_semi + 1.
      CLEAR lv_code.
      CASE lv_ent.
        WHEN 'amp'.
          rv_text = rv_text && '&'.
        WHEN 'lt'.
          rv_text = rv_text && '<'.
        WHEN 'gt'.
          rv_text = rv_text && '>'.
        WHEN 'quot'.
          rv_text = rv_text && '"'.
        WHEN 'apos'.
          rv_text = rv_text && ''''.
        WHEN 'nbsp'.
          lv_code = 160.
        WHEN 'euro'.
          lv_code = 8364.
        WHEN 'copy'.
          lv_code = 169.
        WHEN 'reg'.
          lv_code = 174.
        WHEN 'mdash'.
          lv_code = 8212.
        WHEN 'ndash'.
          lv_code = 8211.
        WHEN 'bull'.
          lv_code = 8226.
        WHEN 'middot'.
          lv_code = 183.
        WHEN 'hellip'.
          lv_code = 8230.
        WHEN 'times'.
          lv_code = 215.
        WHEN 'deg'.
          lv_code = 176.
        WHEN 'laquo'.
          lv_code = 171.
        WHEN 'raquo'.
          lv_code = 187.
        WHEN 'lsquo'.
          lv_code = 8216.
        WHEN 'rsquo'.
          lv_code = 8217.
        WHEN 'ldquo'.
          lv_code = 8220.
        WHEN 'rdquo'.
          lv_code = 8221.
        WHEN 'pound'.
          lv_code = 163.
        WHEN 'sect'.
          lv_code = 167.
        WHEN 'eacute'.
          lv_code = 233.
        WHEN OTHERS.
          IF lv_ent(1) = '#'.
            IF strlen( lv_ent ) > 1 AND ( lv_ent+1(1) = 'x' OR lv_ent+1(1) = 'X' ).
              lv_code = hex_to_int( substring( val = lv_ent off = 2 ) ).
            ELSEIF substring( val = lv_ent off = 1 ) CO '0123456789' AND strlen( lv_ent ) <= 8.
              lv_code = substring( val = lv_ent off = 1 ).
            ENDIF.
            IF lv_code <= 0.
              lv_code = 63.
            ENDIF.
          ELSE.
            rv_text = rv_text && '&' && lv_ent && ';'.
          ENDIF.
      ENDCASE.
      IF lv_code > 0.
        IF lv_code = 32.
          rv_text = rv_text && ` `.
        ELSEIF lv_code > 65535.
          rv_text = rv_text && '?'.
        ELSE.
          lv_char = cl_abap_conv_in_ce=>uccpi( lv_code ).
          rv_text = rv_text && lv_char.
        ENDIF.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

  METHOD encode.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_cp TYPE i.
    DATA lv_out TYPE i.
    DATA lv_x TYPE x LENGTH 1.

    lv_len = strlen( iv_text ).
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_c = iv_text+lv_i(1).
      lv_cp = cl_abap_conv_out_ce=>uccpi( lv_c ).
      lv_out = 0.
      IF lv_cp = 208 OR lv_cp = 221 OR lv_cp = 222 OR lv_cp = 240 OR lv_cp = 253 OR lv_cp = 254.
        "These codes print Turkish letters (font /Differences); the Icelandic letters get a near form.
        CASE lv_cp.
          WHEN 208. lv_out = 68.
          WHEN 221. lv_out = 89.
          WHEN 222. lv_out = 80.
          WHEN 240. lv_out = 100.
          WHEN 253. lv_out = 121.
          WHEN 254. lv_out = 112.
        ENDCASE.
      ELSEIF lv_cp >= 32 AND lv_cp <= 126 OR lv_cp >= 160 AND lv_cp <= 255.
        lv_out = lv_cp.
      ELSEIF lv_cp >= 1632 AND lv_cp <= 1641.
        lv_out = lv_cp - 1632 + 48.
      ELSEIF lv_cp >= 1776 AND lv_cp <= 1785.
        lv_out = lv_cp - 1776 + 48.
      ELSE.
        CASE lv_cp.
          WHEN 9.
            lv_out = 32.
          WHEN 286.
            lv_out = 208.
          WHEN 304.
            lv_out = 221.
          WHEN 350.
            lv_out = 222.
          WHEN 287.
            lv_out = 240.
          WHEN 305.
            lv_out = 253.
          WHEN 351.
            lv_out = 254.
          WHEN 8364.
            lv_out = 128.
          WHEN 8218.
            lv_out = 130.
          WHEN 402.
            lv_out = 131.
          WHEN 8222.
            lv_out = 132.
          WHEN 8230.
            lv_out = 133.
          WHEN 8224.
            lv_out = 134.
          WHEN 8225.
            lv_out = 135.
          WHEN 710.
            lv_out = 136.
          WHEN 8240.
            lv_out = 137.
          WHEN 352.
            lv_out = 138.
          WHEN 8249.
            lv_out = 139.
          WHEN 338.
            lv_out = 140.
          WHEN 381.
            lv_out = 142.
          WHEN 8216.
            lv_out = 145.
          WHEN 8217.
            lv_out = 146.
          WHEN 8220.
            lv_out = 147.
          WHEN 8221.
            lv_out = 148.
          WHEN 8226 OR 9679 OR 9632.
            lv_out = 149.
          WHEN 8211.
            lv_out = 150.
          WHEN 8212.
            lv_out = 151.
          WHEN 732.
            lv_out = 152.
          WHEN 8482.
            lv_out = 153.
          WHEN 353.
            lv_out = 154.
          WHEN 8250.
            lv_out = 155.
          WHEN 339.
            lv_out = 156.
          WHEN 382.
            lv_out = 158.
          WHEN 376.
            lv_out = 159.
          WHEN 8722.
            lv_out = 45.
          WHEN 1548.
            lv_out = 44.
          WHEN 1643.
            lv_out = 46.
          WHEN 1644.
            lv_out = 44.
          WHEN 9744.
            rv_hex = rv_hex && '5B205D'.
          WHEN 9745 OR 9746.
            rv_hex = rv_hex && '5B585D'.
          WHEN 9675.
            lv_out = 111.
          WHEN 9662.
            lv_out = 118.
          WHEN 10 OR 13.
            lv_out = 0.
          WHEN OTHERS.
            lv_out = 63.
        ENDCASE.
      ENDIF.
      IF lv_out > 0.
        lv_x = lv_out.
        rv_hex = rv_hex && |{ lv_x }|.
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD char_width.
    DATA lv_table TYPE i.
    DATA lv_index TYPE i.
    DATA lv_width TYPE i.
    DATA lv_code TYPE i.
    DATA lo_font TYPE REF TO zcl_pdf_studio_font.

    IF iv_font >= c_first_custom.
      lo_font = custom_font( iv_font ).
      IF lo_font IS BOUND.
        rv_width = lo_font->advance( lo_font->glyph( iv_code ) ).
      ELSE.
        rv_width = 556.
      ENDIF.
      RETURN.
    ENDIF.
    "Turkish letters in the standard fonts (see encode): width of the base letter.
    lv_code = iv_code.
    CASE iv_code.
      WHEN 208.
        lv_code = 71.
      WHEN 221.
        IF iv_font < 9.
          rv_width = 278.
          RETURN.
        ENDIF.
      WHEN 222.
        lv_code = 83.
      WHEN 240.
        lv_code = 103.
      WHEN 253.
        IF iv_font < 9.
          rv_width = 278.
          RETURN.
        ENDIF.
      WHEN 254.
        lv_code = 115.
    ENDCASE.

    IF lv_code < 32 OR lv_code > 255.
      RETURN.
    ENDIF.
    CASE iv_font.
      WHEN 1 OR 3.
        lv_table = 1.
      WHEN 2 OR 4.
        lv_table = 2.
      WHEN 5.
        lv_table = 3.
      WHEN 6.
        lv_table = 4.
      WHEN 7.
        lv_table = 5.
      WHEN 8.
        lv_table = 6.
      WHEN OTHERS.
        rv_width = 600.
        RETURN.
    ENDCASE.
    lv_index = ( lv_table - 1 ) * 224 + lv_code - 31.
    READ TABLE gt_widths INTO lv_width INDEX lv_index.
    IF sy-subrc = 0.
      rv_width = lv_width.
    ELSE.
      rv_width = 556.
    ENDIF.
  ENDMETHOD.

  METHOD hex_width.
    DATA lo_font TYPE REF TO zcl_pdf_studio_font.
    DATA lv_x TYPE x LENGTH 1.
    DATA lv_code TYPE i.
    DATA lv_off TYPE i.
    DATA lv_sum TYPE f.

    IF iv_font >= c_first_custom.
      lo_font = custom_font( iv_font ).
      IF lo_font IS BOUND.
        rv_width = lo_font->hex_width( iv_hex ) * iv_size / 1000.
      ENDIF.
      RETURN.
    ENDIF.

    WHILE lv_off + 2 <= strlen( iv_hex ).
      lv_x = iv_hex+lv_off(2).
      lv_code = lv_x.
      lv_sum = lv_sum + char_width( iv_font = iv_font iv_code = lv_code ).
      lv_off = lv_off + 2.
    ENDWHILE.
    rv_width = lv_sum * iv_size / 1000.
  ENDMETHOD.

  METHOD flow_shift.
    DATA ls_token TYPE ty_token.
    DATA ls_style TYPE ty_style.
    DATA ls_box TYPE ty_box.
    DATA lv_min_top TYPE f VALUE 1000000.
    DATA lv_max_bottom TYPE f.
    DATA lv_need TYPE f.
    DATA lv_any TYPE abap_bool.

    LOOP AT it_tokens INTO ls_token FROM iv_from.
      IF ls_token-kind = 'O' AND ls_token-name = 'section'.
        EXIT.
      ENDIF.
      IF ls_token-kind <> 'O' OR ls_token-name <> 'div'
          OR attr( iv_attrs = ls_token-attrs iv_name = `data-flow` ) <> `after`.
        CONTINUE.
      ENDIF.
      ls_style = base_style( ).
      CLEAR ls_box.
      apply_decls( EXPORTING iv_decls = attr( iv_attrs = ls_token-attrs iv_name = `style` ) iv_base = ls_style-size
                   CHANGING  cs_style = ls_style cs_box = ls_box ).
      lv_any = abap_true.
      IF ls_box-y < lv_min_top.
        lv_min_top = ls_box-y.
      ENDIF.
      IF ls_box-y + ls_box-h > lv_max_bottom.
        lv_max_bottom = ls_box-y + ls_box-h.
      ENDIF.
    ENDLOOP.
    IF lv_any = abap_false.
      RETURN.
    ENDIF.
    "6 pt distance below the end of the table.
    lv_need = mv_y + 6.
    IF lv_need <= mv_mt + lv_min_top.
      RETURN.
    ENDIF.
    rv_shift = lv_need - ( mv_mt + lv_min_top ).
    IF mv_mt + lv_max_bottom + rv_shift > mv_ph - mv_mb.
      "No room on this page: the objects start at the top of a new page.
      new_page( ).
      mv_y = mv_mt.
      rv_shift = - lv_min_top.
    ENDIF.
  ENDMETHOD.

  METHOD on_page.
    CASE to_lower( iv_rule ).
      WHEN `first`.
        rv_yes = xsdbool( iv_page = 1 ).
      WHEN `notfirst`.
        rv_yes = xsdbool( iv_page > 1 ).
      WHEN `last`.
        rv_yes = xsdbool( iv_page = iv_total ).
      WHEN `notlast`.
        rv_yes = xsdbool( iv_page < iv_total ).
      WHEN `odd`.
        rv_yes = xsdbool( iv_page MOD 2 = 1 ).
      WHEN `even`.
        rv_yes = xsdbool( iv_page MOD 2 = 0 ).
      WHEN OTHERS.
        rv_yes = abap_true.
    ENDCASE.
  ENDMETHOD.

  METHOD page_tokens.
    DATA ls_token TYPE ty_token.
    DATA ls_text TYPE ty_token.
    DATA lv_class TYPE string.
    LOOP AT it_tokens INTO ls_token.
      APPEND ls_token TO rt_tokens.
      IF ls_token-kind <> 'O' OR ls_token-name <> 'span'.
        CONTINUE.
      ENDIF.
      lv_class = to_lower( attr( iv_attrs = ls_token-attrs iv_name = `class` ) ).
      CLEAR ls_text.
      ls_text-kind = 'T'.
      IF lv_class CS 'pagenumber'.
        ls_text-text = |{ iv_page }|.
        APPEND ls_text TO rt_tokens.
      ELSEIF lv_class CS 'totalpages'.
        ls_text-text = |{ iv_total }|.
        APPEND ls_text TO rt_tokens.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD pdf_text.
    DATA lv_len TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_x TYPE x LENGTH 2.
    rv_text = `<FEFF`.
    lv_len = strlen( iv_text ).
    DATA lv_i TYPE i.
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_c = iv_text+lv_i(1).
      lv_x = cl_abap_conv_out_ce=>uccpi( lv_c ).
      rv_text = rv_text && |{ lv_x }|.
    ENDDO.
    rv_text = rv_text && `>`.
  ENDMETHOD.

  METHOD pdf_date.
    DATA lv_ts TYPE timestamp.
    DATA lv_text TYPE c LENGTH 14.
    GET TIME STAMP FIELD lv_ts.
    lv_text = lv_ts.
    rv_date = |D:{ lv_text }Z|.
  ENDMETHOD.

  METHOD gstate_name.
    DATA lv_level TYPE i.
    lv_level = iv_opacity * 100.
    IF lv_level < 0.
      lv_level = 0.
    ELSEIF lv_level > 100.
      lv_level = 100.
    ENDIF.
    READ TABLE mt_opacity TRANSPORTING NO FIELDS WITH KEY table_line = lv_level.
    IF sy-subrc <> 0.
      APPEND lv_level TO mt_opacity.
    ENDIF.
    rv_name = |GS{ lv_level }|.
  ENDMETHOD.

  METHOD gstates.
    DATA lv_level TYPE i.
    LOOP AT mt_opacity INTO lv_level.
      rv_dict = |{ rv_dict }/GS{ lv_level } << /Type /ExtGState /ca { num( lv_level / 100 ) } /CA { num( lv_level / 100 ) } >> |.
    ENDLOOP.
  ENDMETHOD.

  METHOD custom_font.
    DATA ls_font TYPE ty_font.
    READ TABLE mt_fonts INTO ls_font WITH KEY slot = iv_slot.
    IF sy-subrc = 0.
      ro_font = ls_font-font.
    ENDIF.
  ENDMETHOD.

  METHOD encode_font.
    DATA lo_font TYPE REF TO zcl_pdf_studio_font.
    DATA lv_width TYPE f.
    IF iv_font >= c_first_custom.
      lo_font = custom_font( iv_font ).
      IF lo_font IS BOUND.
        lo_font->encode( EXPORTING iv_text = iv_text IMPORTING ev_hex = rv_hex ev_width = lv_width ).
        RETURN.
      ENDIF.
    ENDIF.
    rv_hex = encode( iv_text ).
  ENDMETHOD.

  METHOD font_index.
    DATA ls_font TYPE ty_font.
    DATA lv_data TYPE xstring.

    IF is_style-family = 'X' AND is_style-custom IS NOT INITIAL AND mo_res IS BOUND.
      READ TABLE mt_fonts INTO ls_font WITH KEY family = is_style-custom bold = is_style-bold italic = is_style-italic.
      IF sy-subrc = 0.
        rv_index = ls_font-slot.
        RETURN.
      ENDIF.
      lv_data = mo_res->font( iv_family = is_style-custom iv_bold = is_style-bold iv_italic = is_style-italic ).
      IF lv_data IS NOT INITIAL.
        TRY.
            ls_font-font = zcl_pdf_studio_font=>create( lv_data ).
            ls_font-slot = c_first_custom + lines( mt_fonts ).
            ls_font-family = is_style-custom.
            ls_font-bold = is_style-bold.
            ls_font-italic = is_style-italic.
            APPEND ls_font TO mt_fonts.
            rv_index = ls_font-slot.
            RETURN.
          CATCH zcx_pdf_studio ##NO_HANDLER.
            "Invalid font file: the standard font is used.
        ENDTRY.
      ENDIF.
    ENDIF.
    CASE is_style-family.
      WHEN 'T'.
        rv_index = 5.
      WHEN 'C'.
        rv_index = 9.
      WHEN OTHERS.
        rv_index = 1.
    ENDCASE.
    IF is_style-bold = abap_true.
      rv_index = rv_index + 1.
    ENDIF.
    IF is_style-italic = abap_true.
      rv_index = rv_index + 2.
    ENDIF.
  ENDMETHOD.

  METHOD length_pt.
    DATA lv_value TYPE string.
    DATA lv_number TYPE string.
    DATA lv_unit TYPE string.
    DATA lv_f TYPE f.
    DATA lv_len TYPE i.

    lv_value = to_lower( iv_value ).
    CONDENSE lv_value NO-GAPS.
    IF lv_value IS INITIAL.
      RETURN.
    ENDIF.
    lv_len = strlen( lv_value ).
    lv_number = lv_value.
    WHILE lv_len > 0.
      lv_unit = substring( val = lv_value off = lv_len - 1 len = 1 ).
      IF lv_unit CO '0123456789.'.
        EXIT.
      ENDIF.
      lv_len = lv_len - 1.
    ENDWHILE.
    IF lv_len <= 0.
      RETURN.
    ENDIF.
    lv_number = substring( val = lv_value len = lv_len ).
    lv_unit = substring( val = lv_value off = lv_len ).
    IF lv_number CN '0123456789.-'.
      RETURN.
    ENDIF.
    TRY.
        lv_f = lv_number.
      CATCH cx_root.
        RETURN.
    ENDTRY.
    CASE lv_unit.
      WHEN 'pt'.
        rv_pt = lv_f.
      WHEN 'mm'.
        rv_pt = lv_f * 72 / '25.4'.
      WHEN 'cm'.
        rv_pt = lv_f * 72 / '2.54'.
      WHEN 'in'.
        rv_pt = lv_f * 72.
      WHEN 'em' OR 'rem'.
        rv_pt = lv_f * iv_base.
      WHEN '%'.
        rv_pt = lv_f * iv_base / 100.
      WHEN OTHERS.
        rv_pt = lv_f * '0.75'.
    ENDCASE.
  ENDMETHOD.

  METHOD num.
    DATA lv_p TYPE p LENGTH 12 DECIMALS 2.
    lv_p = iv_value.
    rv_text = |{ lv_p }|.
  ENDMETHOD.

  METHOD color.
    DATA lv_value TYPE string.
    DATA lv_hex TYPE string.
    DATA lt_parts TYPE ty_strings.
    DATA lv_part TYPE string.
    DATA lv_p TYPE p LENGTH 5 DECIMALS 3.
    DATA lv_f TYPE f.
    DATA lv_index TYPE i.
    DATA lv_x TYPE x LENGTH 1.
    DATA lv_i TYPE i.
    DATA lv_open TYPE i.

    lv_value = to_lower( iv_value ).
    CONDENSE lv_value NO-GAPS.
    REPLACE ALL OCCURRENCES OF '!important' IN lv_value WITH ``.
    CASE lv_value.
      WHEN '' OR 'transparent' OR 'none' OR 'inherit' OR 'initial'.
        RETURN.
      WHEN 'black'.
        lv_hex = '000000'.
      WHEN 'white'.
        lv_hex = 'FFFFFF'.
      WHEN 'red'.
        lv_hex = 'FF0000'.
      WHEN 'green'.
        lv_hex = '008000'.
      WHEN 'blue'.
        lv_hex = '0000FF'.
      WHEN 'gray' OR 'grey'.
        lv_hex = '808080'.
      WHEN 'silver'.
        lv_hex = 'C0C0C0'.
      WHEN 'navy'.
        lv_hex = '000080'.
      WHEN 'maroon'.
        lv_hex = '800000'.
      WHEN 'orange'.
        lv_hex = 'FFA500'.
      WHEN 'yellow'.
        lv_hex = 'FFFF00'.
      WHEN 'purple'.
        lv_hex = '800080'.
      WHEN 'teal'.
        lv_hex = '008080'.
      WHEN OTHERS.
        IF lv_value(1) = '#'.
          lv_hex = to_upper( substring( val = lv_value off = 1 ) ).
          IF strlen( lv_hex ) = 3 OR strlen( lv_hex ) = 4.
            IF strlen( lv_hex ) = 4 AND lv_hex+3(1) = '0'.
              RETURN.
            ENDIF.
            lv_hex = lv_hex(1) && lv_hex(1) && lv_hex+1(1) && lv_hex+1(1) && lv_hex+2(1) && lv_hex+2(1).
          ELSEIF strlen( lv_hex ) = 8.
            IF lv_hex+6(2) = '00'.
              RETURN.
            ENDIF.
            lv_hex = lv_hex(6).
          ENDIF.
          IF strlen( lv_hex ) <> 6 OR lv_hex CN '0123456789ABCDEF'.
            RETURN.
          ENDIF.
        ELSEIF lv_value CP 'rgb*(*)'.
          lv_open = find( val = lv_value sub = '(' ).
          lv_part = substring( val = lv_value off = lv_open + 1 ).
          REPLACE ALL OCCURRENCES OF ')' IN lv_part WITH ``.
          SPLIT lv_part AT ',' INTO TABLE lt_parts.
          IF lines( lt_parts ) < 3.
            RETURN.
          ENDIF.
          IF lines( lt_parts ) >= 4.
            READ TABLE lt_parts INTO lv_part INDEX 4.
            IF lv_part = '0' OR lv_part = '0.0'.
              RETURN.
            ENDIF.
          ENDIF.
          DO 3 TIMES.
            lv_index = sy-index.
            READ TABLE lt_parts INTO lv_part INDEX lv_index.
            IF lv_part CN '0123456789.'.
              RETURN.
            ENDIF.
            TRY.
                lv_f = lv_part.
              CATCH cx_root.
                RETURN.
            ENDTRY.
            lv_p = lv_f / 255.
            IF lv_p > 1.
              lv_p = 1.
            ENDIF.
            IF rv_rgb IS INITIAL.
              rv_rgb = |{ lv_p }|.
            ELSE.
              rv_rgb = |{ rv_rgb } { lv_p }|.
            ENDIF.
          ENDDO.
          RETURN.
        ELSE.
          RETURN.
        ENDIF.
    ENDCASE.
    DO 3 TIMES.
      lv_index = ( sy-index - 1 ) * 2.
      lv_x = lv_hex+lv_index(2).
      lv_i = lv_x.
      lv_p = lv_i / 255.
      IF rv_rgb IS INITIAL.
        rv_rgb = |{ lv_p }|.
      ELSE.
        rv_rgb = |{ rv_rgb } { lv_p }|.
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD base_style.
    rs_style-family = 'H'.
    rs_style-size = 12.
    rs_style-color = `0 0 0`.
    rs_style-align = `left`.
  ENDMETHOD.

  METHOD is_block.
    CASE iv_name.
      WHEN 'p' OR 'div' OR 'h1' OR 'h2' OR 'h3' OR 'h4' OR 'h5' OR 'h6' OR 'ul' OR 'ol' OR 'li'
          OR 'table' OR 'tr' OR 'thead' OR 'tbody' OR 'tfoot' OR 'section' OR 'article' OR 'header'
          OR 'footer' OR 'blockquote' OR 'pre' OR 'form' OR 'center' OR 'address' OR 'main' OR 'nav'
          OR 'aside' OR 'figure' OR 'figcaption' OR 'dl' OR 'dt' OR 'dd' OR 'body' OR 'html'.
        rv_yes = abap_true.
    ENDCASE.
  ENDMETHOD.

  METHOD parse_css.
    DATA lv_css TYPE string.
    DATA lv_pos TYPE i.
    DATA lv_open TYPE i.
    DATA lv_close TYPE i.
    DATA lv_end TYPE i.
    DATA lv_depth TYPE i.
    DATA lv_scan TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_selectors TYPE string.
    DATA lv_decls TYPE string.
    DATA lt_selectors TYPE ty_strings.
    DATA lv_selector TYPE string.
    DATA ls_rule TYPE ty_rule.

    lv_css = iv_css.
    "Line breaks and tabs inside a style sheet are plain white space.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_css WITH ` `.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_css WITH ` `.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf(1) IN lv_css WITH ` `.
    DO.
      lv_open = find( val = lv_css sub = '/*' ).
      IF lv_open < 0.
        EXIT.
      ENDIF.
      lv_end = find( val = lv_css sub = '*/' off = lv_open ).
      IF lv_end < 0.
        lv_css = substring( val = lv_css len = lv_open ).
        EXIT.
      ENDIF.
      lv_css = substring( val = lv_css len = lv_open ) && substring( val = lv_css off = lv_end + 2 ).
    ENDDO.

    WHILE lv_pos < strlen( lv_css ).
      lv_open = find( val = lv_css sub = '{' off = lv_pos ).
      IF lv_open < 0.
        EXIT.
      ENDIF.
      lv_selectors = substring( val = lv_css off = lv_pos len = lv_open - lv_pos ).
      CONDENSE lv_selectors.
      IF lv_selectors CP '@*'.
        lv_depth = 0.
        lv_scan = lv_open.
        WHILE lv_scan < strlen( lv_css ).
          lv_c = lv_css+lv_scan(1).
          IF lv_c = '{'.
            lv_depth = lv_depth + 1.
          ELSEIF lv_c = '}'.
            lv_depth = lv_depth - 1.
            IF lv_depth = 0.
              EXIT.
            ENDIF.
          ENDIF.
          lv_scan = lv_scan + 1.
        ENDWHILE.
        lv_pos = lv_scan + 1.
        CONTINUE.
      ENDIF.
      lv_close = find( val = lv_css sub = '}' off = lv_open ).
      IF lv_close < 0.
        EXIT.
      ENDIF.
      lv_decls = substring( val = lv_css off = lv_open + 1 len = lv_close - lv_open - 1 ).
      lv_pos = lv_close + 1.
      SPLIT lv_selectors AT ',' INTO TABLE lt_selectors.
      LOOP AT lt_selectors INTO lv_selector.
        lv_selector = to_lower( lv_selector ).
        REPLACE ALL OCCURRENCES OF '>' IN lv_selector WITH ` `.
        CONDENSE lv_selector.
        "Descendant selectors such as '.grid td' apply by their last tag name.
        lv_scan = find( val = lv_selector sub = ` ` occ = -1 ).
        IF lv_scan >= 0.
          lv_selector = substring( val = lv_selector off = lv_scan + 1 ).
        ENDIF.
        CONDENSE lv_selector NO-GAPS.
        IF lv_selector IS INITIAL OR lv_selector CN 'abcdefghijklmnopqrstuvwxyz0123456789'.
          CONTINUE.
        ENDIF.
        ls_rule-tag = lv_selector.
        ls_rule-decls = lv_decls.
        APPEND ls_rule TO mt_rules.
      ENDLOOP.
    ENDWHILE.
  ENDMETHOD.

  METHOD apply_decls.
    DATA lt_decls TYPE ty_strings.
    DATA lv_decl TYPE string.
    DATA lv_prop TYPE string.
    DATA lv_value TYPE string.
    DATA lv_lower TYPE string.
    DATA lv_colon TYPE i.
    DATA lt_words TYPE ty_strings.
    DATA lv_word TYPE string.
    DATA lv_rgb TYPE string.
    DATA lv_base TYPE f.
    DATA lv_weight TYPE i.
    DATA lt_names TYPE ty_strings.
    DATA lv_fam TYPE string.
    DATA lv_ew TYPE f.
    DATA lv_ec TYPE string.
    DATA lv_es TYPE string.
    DATA lv_wl TYPE string.

    lv_base = iv_base.
    IF lv_base <= 0.
      lv_base = cs_style-size.
    ENDIF.
    SPLIT iv_decls AT ';' INTO TABLE lt_decls.
    LOOP AT lt_decls INTO lv_decl.
      lv_colon = find( val = lv_decl sub = ':' ).
      IF lv_colon <= 0.
        CONTINUE.
      ENDIF.
      lv_prop = to_lower( substring( val = lv_decl len = lv_colon ) ).
      CONDENSE lv_prop NO-GAPS.
      lv_value = substring( val = lv_decl off = lv_colon + 1 ).
      REPLACE ALL OCCURRENCES OF '!important' IN lv_value WITH ``.
      CONDENSE lv_value.
      lv_lower = to_lower( lv_value ).
      CASE lv_prop.
        WHEN 'left'.
          cs_box-x = length_pt( iv_value = lv_value iv_base = lv_base ).
        WHEN 'top'.
          cs_box-y = length_pt( iv_value = lv_value iv_base = lv_base ).
        WHEN 'width'.
          IF lv_value NS '%'.
            cs_box-w = length_pt( iv_value = lv_value iv_base = lv_base ).
          ENDIF.
        WHEN 'height'.
          IF lv_value NS '%'.
            cs_box-h = length_pt( iv_value = lv_value iv_base = lv_base ).
            cs_box-has_h = abap_true.
          ENDIF.
        WHEN 'font-size'.
          cs_style-size = length_pt( iv_value = lv_value iv_base = lv_base ).
          IF cs_style-size <= 0.
            cs_style-size = lv_base.
          ENDIF.
        WHEN 'font-family'.
          "An uploaded TrueType family wins: the first name of the list that is known.
          CLEAR cs_style-custom.
          SPLIT lv_lower AT ',' INTO TABLE lt_names.
          LOOP AT lt_names INTO lv_fam.
            REPLACE ALL OCCURRENCES OF `"` IN lv_fam WITH ``.
            REPLACE ALL OCCURRENCES OF `'` IN lv_fam WITH ``.
            CONDENSE lv_fam.
            READ TABLE mt_families TRANSPORTING NO FIELDS WITH KEY table_line = lv_fam.
            IF sy-subrc = 0.
              cs_style-custom = lv_fam.
              EXIT.
            ENDIF.
          ENDLOOP.
          IF cs_style-custom IS NOT INITIAL.
            cs_style-family = 'X'.
          ELSEIF lv_lower CS 'courier' OR lv_lower CS 'mono' OR lv_lower CS 'consolas'.
            cs_style-family = 'C'.
          ELSEIF lv_lower CS 'times' OR lv_lower CS 'georgia' OR lv_lower CS 'garamond'
              OR ( lv_lower CS 'serif' AND lv_lower NS 'sans' ).
            cs_style-family = 'T'.
          ELSE.
            cs_style-family = 'H'.
          ENDIF.
        WHEN 'font-weight'.
          IF lv_lower = 'bold' OR lv_lower = 'bolder'.
            cs_style-bold = abap_true.
          ELSEIF lv_lower CO '0123456789' AND lv_lower IS NOT INITIAL.
            lv_weight = lv_lower.
            cs_style-bold = boolc( lv_weight >= 600 ).
          ELSE.
            cs_style-bold = abap_false.
          ENDIF.
        WHEN 'font-style'.
          cs_style-italic = boolc( lv_lower = 'italic' OR lv_lower = 'oblique' ).
        WHEN 'text-decoration' OR 'text-decoration-line'.
          cs_style-underline = boolc( lv_lower CS 'underline' ).
        WHEN 'color'.
          lv_rgb = color( lv_value ).
          IF lv_rgb IS NOT INITIAL.
            cs_style-color = lv_rgb.
          ENDIF.
        WHEN 'background' OR 'background-color'.
          SPLIT lv_value AT ` ` INTO TABLE lt_words.
          CLEAR cs_box-fill.
          LOOP AT lt_words INTO lv_word.
            lv_rgb = color( lv_word ).
            IF lv_rgb IS NOT INITIAL.
              cs_box-fill = lv_rgb.
              EXIT.
            ENDIF.
          ENDLOOP.
        WHEN 'text-align'.
          cs_style-align = lv_lower.
        WHEN 'direction'.
          cs_style-dir = COND #( WHEN lv_lower CS 'rtl' THEN 'R' WHEN lv_lower CS 'ltr' THEN 'L' ELSE '' ).
        WHEN 'white-space'.
          cs_style-pre = boolc( lv_lower CS 'pre' ).
        WHEN 'padding'.
          SPLIT lv_value AT ` ` INTO TABLE lt_words.
          READ TABLE lt_words INTO lv_word INDEX 1.
          cs_box-pad = length_pt( iv_value = lv_word iv_base = lv_base ).
        WHEN 'margin'.
          SPLIT lv_value AT ` ` INTO TABLE lt_words.
          READ TABLE lt_words INTO lv_word INDEX 1.
          cs_box-mt = length_pt( iv_value = lv_word iv_base = cs_style-size ).
          cs_box-mb = cs_box-mt.
          IF lines( lt_words ) >= 3.
            READ TABLE lt_words INTO lv_word INDEX 3.
            cs_box-mb = length_pt( iv_value = lv_word iv_base = cs_style-size ).
          ENDIF.
        WHEN 'margin-top'.
          cs_box-mt = length_pt( iv_value = lv_value iv_base = cs_style-size ).
        WHEN 'margin-left'.
          cs_box-ml = length_pt( iv_value = lv_value iv_base = cs_style-size ).
        WHEN 'margin-bottom'.
          cs_box-mb = length_pt( iv_value = lv_value iv_base = cs_style-size ).
        WHEN 'border'.
          IF lv_lower = 'none' OR lv_lower = '0'.
            cs_box-no_edge = abap_true.
            CONTINUE.
          ENDIF.
          SPLIT lv_value AT ` ` INTO TABLE lt_words.
          LOOP AT lt_words INTO lv_word.
            "Note: # is the escape character of CP patterns, so test the first character directly.
            IF lv_word CA '0123456789' AND lv_word(1) <> '#' AND to_lower( lv_word ) NP 'rgb*'.
              cs_box-border = length_pt( iv_value = lv_word iv_base = lv_base ).
            ELSE.
              lv_rgb = color( lv_word ).
              IF lv_rgb IS NOT INITIAL.
                cs_box-e_top = lv_rgb.
                cs_box-e_right = lv_rgb.
                cs_box-e_bot = lv_rgb.
                cs_box-e_left = lv_rgb.
              ENDIF.
            ENDIF.
          ENDLOOP.
        WHEN 'border-top' OR 'border-right' OR 'border-bottom' OR 'border-left'.
          CLEAR: lv_ew, lv_ec.
          lv_es = `solid`.
          SPLIT lv_value AT ` ` INTO TABLE lt_words.
          LOOP AT lt_words INTO lv_word.
            IF lv_word IS INITIAL.
              CONTINUE.
            ENDIF.
            lv_wl = to_lower( lv_word ).
            IF lv_wl = 'none' OR lv_wl = 'hidden'.
              lv_es = `none`.
            ELSEIF lv_wl = 'solid' OR lv_wl = 'dashed' OR lv_wl = 'dotted' OR lv_wl = 'double'.
              lv_es = lv_wl.
            ELSEIF lv_word CA '0123456789' AND lv_word(1) <> '#' AND lv_wl NP 'rgb*'.
              lv_ew = length_pt( iv_value = lv_word iv_base = lv_base ).
            ELSE.
              lv_ec = color( lv_word ).
            ENDIF.
          ENDLOOP.
          IF lv_es = `none` OR lv_ew <= 0.
            lv_ew = 0.
            CLEAR lv_ec.
          ENDIF.
          cs_box-per_edge = abap_true.
          CASE lv_prop.
            WHEN 'border-top'.
              cs_box-w_top = lv_ew.
              cs_box-e_top = lv_ec.
              cs_box-s_top = lv_es.
            WHEN 'border-right'.
              cs_box-w_right = lv_ew.
              cs_box-e_right = lv_ec.
              cs_box-s_right = lv_es.
            WHEN 'border-bottom'.
              cs_box-w_bot = lv_ew.
              cs_box-e_bot = lv_ec.
              cs_box-s_bot = lv_es.
            WHEN OTHERS.
              cs_box-w_left = lv_ew.
              cs_box-e_left = lv_ec.
              cs_box-s_left = lv_es.
          ENDCASE.
          cs_box-border = nmax( val1 = cs_box-w_top val2 = cs_box-w_right val3 = cs_box-w_bot val4 = cs_box-w_left ).
        WHEN 'border-width'.
          SPLIT lv_value AT ` ` INTO TABLE lt_words.
          READ TABLE lt_words INTO lv_word INDEX 1.
          cs_box-border = length_pt( iv_value = lv_word iv_base = lv_base ).
        WHEN 'border-style'.
          cs_box-no_edge = boolc( lv_lower = 'none' OR lv_lower = 'hidden' ).
        WHEN 'border-color'.
          SPLIT lv_value AT ` ` INTO TABLE lt_words.
          DELETE lt_words WHERE table_line IS INITIAL.
          CASE lines( lt_words ).
            WHEN 1.
              READ TABLE lt_words INTO lv_word INDEX 1.
              cs_box-e_top = color( lv_word ).
              cs_box-e_right = cs_box-e_top.
              cs_box-e_bot = cs_box-e_top.
              cs_box-e_left = cs_box-e_top.
            WHEN 2.
              READ TABLE lt_words INTO lv_word INDEX 1.
              cs_box-e_top = color( lv_word ).
              cs_box-e_bot = cs_box-e_top.
              READ TABLE lt_words INTO lv_word INDEX 2.
              cs_box-e_right = color( lv_word ).
              cs_box-e_left = cs_box-e_right.
            WHEN 3 OR 4.
              READ TABLE lt_words INTO lv_word INDEX 1.
              cs_box-e_top = color( lv_word ).
              READ TABLE lt_words INTO lv_word INDEX 2.
              cs_box-e_right = color( lv_word ).
              cs_box-e_left = cs_box-e_right.
              READ TABLE lt_words INTO lv_word INDEX 3.
              cs_box-e_bot = color( lv_word ).
              IF lines( lt_words ) = 4.
                READ TABLE lt_words INTO lv_word INDEX 4.
                cs_box-e_left = color( lv_word ).
              ENDIF.
          ENDCASE.
        WHEN 'border-radius'.
          cs_box-round = boolc( lv_lower CS '50%' ).
        WHEN 'object-fit'.
          cs_box-fit = lv_lower.
        WHEN 'transform'.
          FIND REGEX 'rotate\(\s*(-?[0-9.]+)\s*deg' IN lv_lower SUBMATCHES lv_word.
          IF sy-subrc = 0.
            cs_box-rotate = lv_word.
          ENDIF.
        WHEN 'opacity'.
          IF lv_lower CO '0123456789.' AND lv_lower IS NOT INITIAL.
            cs_box-opacity = lv_lower.
            cs_box-has_opacity = abap_true.
          ENDIF.
        WHEN 'vertical-align'.
          cs_box-valign = lv_lower.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD tag_style.
    DATA ls_rule TYPE ty_rule.
    DATA lv_style TYPE string.
    DATA lv_align TYPE string.
    DATA lv_factor TYPE f.
    DATA lv_margin TYPE f.

    es_style = is_parent.
    CLEAR es_box.
    CASE iv_name.
      WHEN 'b' OR 'strong' OR 'th'.
        es_style-bold = abap_true.
      WHEN 'i' OR 'em' OR 'cite' OR 'var'.
        es_style-italic = abap_true.
      WHEN 'u' OR 'ins'.
        es_style-underline = abap_true.
      WHEN 'h1' OR 'h2' OR 'h3' OR 'h4' OR 'h5' OR 'h6'.
        es_style-bold = abap_true.
        CASE iv_name.
          WHEN 'h1'.
            lv_factor = 2.
            lv_margin = '0.67'.
          WHEN 'h2'.
            lv_factor = '1.5'.
            lv_margin = '0.83'.
          WHEN 'h3'.
            lv_factor = '1.17'.
            lv_margin = 1.
          WHEN 'h4'.
            lv_factor = 1.
            lv_margin = '1.33'.
          WHEN 'h5'.
            lv_factor = '0.83'.
            lv_margin = '1.67'.
          WHEN OTHERS.
            lv_factor = '0.67'.
            lv_margin = '2.33'.
        ENDCASE.
        es_style-size = is_parent-size * lv_factor.
        es_box-mt = es_style-size * lv_margin.
        es_box-mb = es_box-mt.
      WHEN 'p' OR 'ul' OR 'ol' OR 'blockquote' OR 'dl'.
        es_box-mt = es_style-size.
        es_box-mb = es_style-size.
      WHEN 'small'.
        es_style-size = is_parent-size * '0.83'.
      WHEN 'big'.
        es_style-size = is_parent-size * '1.2'.
      WHEN 'pre'.
        es_style-family = 'C'.
        es_style-pre = abap_true.
        es_box-mt = es_style-size.
        es_box-mb = es_style-size.
      WHEN 'code' OR 'tt' OR 'kbd' OR 'samp'.
        es_style-family = 'C'.
      WHEN 'center'.
        es_style-align = `center`.
    ENDCASE.

    LOOP AT mt_rules INTO ls_rule WHERE tag = iv_name.
      apply_decls(
        EXPORTING iv_decls = ls_rule-decls iv_base = is_parent-size
        CHANGING  cs_style = es_style cs_box = es_box ).
    ENDLOOP.
    lv_align = to_lower( attr( iv_attrs = iv_attrs iv_name = `align` ) ).
    IF lv_align = 'center' OR lv_align = 'right' OR lv_align = 'left'.
      es_style-align = lv_align.
    ENDIF.
    lv_style = attr( iv_attrs = iv_attrs iv_name = `style` ).
    IF lv_style IS NOT INITIAL.
      apply_decls(
        EXPORTING iv_decls = lv_style iv_base = is_parent-size
        CHANGING  cs_style = es_style cs_box = es_box ).
    ENDIF.
  ENDMETHOD.

  METHOD add_break.
    DATA ls_piece TYPE ty_piece.
    ls_piece-brk = abap_true.
    ls_piece-size = is_style-size.
    APPEND ls_piece TO ct_pieces.
    mv_pending = 0.
  ENDMETHOD.

  METHOD word_pieces.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_cp TYPE i.
    DATA ls_piece TYPE ty_piece.
    DATA lv_lead TYPE i.
    DATA lv_trail TYPE i.

    "The product prints Latin scripts only (Turkish and English): a word is one piece.
    CLEAR ls_piece.
    ls_piece-size = is_style-size.
    ls_piece-color = is_style-color.
    ls_piece-under = is_style-underline.
    ls_piece-pdir = is_style-dir.
    ls_piece-hex = encode_font( iv_text = iv_word iv_font = iv_font ).
    ls_piece-font = iv_font.
    ls_piece-width = hex_width( iv_hex = ls_piece-hex iv_font = iv_font iv_size = is_style-size ).
    ls_piece-bidi = 'N'.
    IF iv_word CA 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.
      ls_piece-bidi = 'L'.
    ELSE.
      "Accented Latin letters (Turkish letters among them) are letters as well.
      lv_len = strlen( iv_word ).
      DO lv_len TIMES.
        lv_i = sy-index - 1.
        lv_c = iv_word+lv_i(1).
        lv_cp = cl_abap_conv_out_ce=>uccpi( lv_c ).
        IF lv_cp >= 192 AND lv_cp <= 591.
          ls_piece-bidi = 'L'.
          EXIT.
        ENDIF.
      ENDDO.
    ENDIF.
    IF ls_piece-bidi = 'L' AND strlen( iv_word ) > 1 AND is_style-dir = 'R'.
      "Inside right-to-left text, punctuation around a Latin word is neutral.
      lv_lead = alnum_from( iv_word ).
      lv_trail = alnum_to( iv_word ).
      IF lv_lead > 0 OR ( lv_trail > 0 AND lv_trail < strlen( iv_word ) ).
        IF lv_lead > 0.
          append_part( EXPORTING iv_text = substring( val = iv_word len = lv_lead ) iv_bidi = 'N'
                                 iv_font = iv_font is_style = is_style CHANGING ct_pieces = rt_pieces ).
        ENDIF.
        append_part( EXPORTING iv_text = substring( val = iv_word off = lv_lead len = lv_trail - lv_lead ) iv_bidi = 'L'
                               iv_font = iv_font is_style = is_style CHANGING ct_pieces = rt_pieces ).
        IF lv_trail < strlen( iv_word ).
          append_part( EXPORTING iv_text = substring( val = iv_word off = lv_trail ) iv_bidi = 'N'
                                 iv_font = iv_font is_style = is_style CHANGING ct_pieces = rt_pieces ).
        ENDIF.
        RETURN.
      ENDIF.
    ENDIF.
    IF ls_piece-hex IS NOT INITIAL.
      APPEND ls_piece TO rt_pieces.
    ENDIF.
  ENDMETHOD.

  METHOD alnum_from.
    WHILE rv_pos < strlen( iv_text ).
      IF iv_text+rv_pos(1) CA 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'.
        RETURN.
      ENDIF.
      rv_pos = rv_pos + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD alnum_to.
    DATA lv_i TYPE i.
    lv_i = strlen( iv_text ) - 1.
    WHILE lv_i >= 0.
      IF iv_text+lv_i(1) CA 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'.
        rv_pos = lv_i + 1.
        RETURN.
      ENDIF.
      lv_i = lv_i - 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD append_part.
    DATA ls_piece TYPE ty_piece.
    ls_piece-size = is_style-size.
    ls_piece-color = is_style-color.
    ls_piece-under = is_style-underline.
    ls_piece-pdir = is_style-dir.
    ls_piece-hex = encode_font( iv_text = iv_text iv_font = iv_font ).
    ls_piece-font = iv_font.
    ls_piece-width = hex_width( iv_hex = ls_piece-hex iv_font = iv_font iv_size = is_style-size ).
    ls_piece-bidi = iv_bidi.
    ls_piece-glue = xsdbool( ct_pieces IS NOT INITIAL ).
    IF ls_piece-hex IS NOT INITIAL.
      APPEND ls_piece TO ct_pieces.
    ENDIF.
  ENDMETHOD.

  METHOD visual_order.
    "Simplified bidi: the first strong piece sets the line direction; Arabic pieces run
    "right to left, Latin runs keep their order, digits and punctuation follow their
    "neighbours. Positions are rewritten, the line width stays the same.
    TYPES: BEGIN OF ty_info,
             dir TYPE c LENGTH 1,
             gap TYPE f,
           END OF ty_info.
    DATA lt_info TYPE STANDARD TABLE OF ty_info WITH EMPTY KEY.
    DATA ls_info TYPE ty_info.
    DATA ls_piece TYPE ty_piece.
    DATA lv_base TYPE c LENGTH 1 VALUE 'L'.
    DATA lv_n TYPE i.
    DATA lv_i TYPE i.
    DATA lv_j TYPE i.
    DATA lv_prev TYPE c LENGTH 1.
    DATA lv_next TYPE c LENGTH 1.
    DATA lv_end TYPE f.
    DATA lv_any_r TYPE abap_bool.
    DATA lv_cursor TYPE f.
    DATA lv_run_end TYPE i.
    DATA lv_block TYPE f.
    DATA lv_start TYPE f.
    DATA lv_k TYPE i.

    lv_n = lines( cs_line-pieces ).
    LOOP AT cs_line-pieces INTO ls_piece.
      IF ls_piece-bidi = 'R'.
        lv_any_r = abap_true.
      ENDIF.
    ENDLOOP.
    IF lv_any_r = abap_false OR lv_n = 0.
      RETURN.
    ENDIF.
    READ TABLE cs_line-pieces INTO ls_piece INDEX 1.
    IF ls_piece-pdir = 'R' OR ls_piece-pdir = 'L'.
      lv_base = ls_piece-pdir.
    ELSE.
      LOOP AT cs_line-pieces INTO ls_piece WHERE bidi = 'R' OR bidi = 'L'.
        lv_base = ls_piece-bidi.
        EXIT.
      ENDLOOP.
    ENDIF.
    "Resolved direction and the gap in front of every piece.
    lv_end = 0.
    LOOP AT cs_line-pieces INTO ls_piece.
      CLEAR ls_info.
      ls_info-dir = ls_piece-bidi.
      ls_info-gap = ls_piece-x - lv_end.
      IF sy-tabix = 1.
        ls_info-gap = 0.
      ENDIF.
      lv_end = ls_piece-x + ls_piece-width.
      APPEND ls_info TO lt_info.
    ENDLOOP.
    lv_i = 1.
    WHILE lv_i <= lv_n.
      IF lt_info[ lv_i ]-dir <> 'R' AND lt_info[ lv_i ]-dir <> 'L'.
        lv_prev = lv_base.
        lv_j = lv_i - 1.
        WHILE lv_j >= 1.
          IF cs_line-pieces[ lv_j ]-bidi = 'R' OR cs_line-pieces[ lv_j ]-bidi = 'L'.
            lv_prev = cs_line-pieces[ lv_j ]-bidi.
            EXIT.
          ENDIF.
          lv_j = lv_j - 1.
        ENDWHILE.
        lv_next = lv_base.
        lv_j = lv_i + 1.
        WHILE lv_j <= lv_n.
          IF cs_line-pieces[ lv_j ]-bidi = 'R' OR cs_line-pieces[ lv_j ]-bidi = 'L'.
            lv_next = cs_line-pieces[ lv_j ]-bidi.
            EXIT.
          ENDIF.
          lv_j = lv_j + 1.
        ENDWHILE.
        IF lv_prev = lv_next.
          lt_info[ lv_i ]-dir = lv_prev.
        ELSE.
          lt_info[ lv_i ]-dir = lv_base.
        ENDIF.
        "Brackets are mirrored inside right-to-left text.
        IF lt_info[ lv_i ]-dir = 'R'.
          CASE cs_line-pieces[ lv_i ]-hex.
            WHEN '28'.
              cs_line-pieces[ lv_i ]-hex = '29'.
            WHEN '29'.
              cs_line-pieces[ lv_i ]-hex = '28'.
            WHEN '5B'.
              cs_line-pieces[ lv_i ]-hex = '5D'.
            WHEN '5D'.
              cs_line-pieces[ lv_i ]-hex = '5B'.
            WHEN '7B'.
              cs_line-pieces[ lv_i ]-hex = '7D'.
            WHEN '7D'.
              cs_line-pieces[ lv_i ]-hex = '7B'.
            WHEN '3C'.
              cs_line-pieces[ lv_i ]-hex = '3E'.
            WHEN '3E'.
              cs_line-pieces[ lv_i ]-hex = '3C'.
          ENDCASE.
        ENDIF.
      ENDIF.
      lv_i = lv_i + 1.
    ENDWHILE.

    "Runs of the direction opposite to the line are laid out as blocks.
    IF lv_base = 'R'.
      lv_cursor = cs_line-width.
    ELSE.
      lv_cursor = 0.
    ENDIF.
    lv_i = 1.
    WHILE lv_i <= lv_n.
      lv_run_end = lv_i.
      WHILE lv_run_end + 1 <= lv_n.
        IF lt_info[ lv_run_end + 1 ]-dir <> lt_info[ lv_i ]-dir.
          EXIT.
        ENDIF.
        lv_run_end = lv_run_end + 1.
      ENDWHILE.
      IF lt_info[ lv_i ]-dir = lv_base.
        "Same direction as the line: piece by piece.
        lv_k = lv_i.
        WHILE lv_k <= lv_run_end.
          IF lv_base = 'R'.
            lv_cursor = lv_cursor - lt_info[ lv_k ]-gap - cs_line-pieces[ lv_k ]-width.
            cs_line-pieces[ lv_k ]-x = lv_cursor.
          ELSE.
            lv_cursor = lv_cursor + lt_info[ lv_k ]-gap.
            cs_line-pieces[ lv_k ]-x = lv_cursor.
            lv_cursor = lv_cursor + cs_line-pieces[ lv_k ]-width.
          ENDIF.
          lv_k = lv_k + 1.
        ENDWHILE.
      ELSE.
        "Opposite direction: the run is one block, its pieces in reverse visual order.
        lv_block = 0.
        lv_k = lv_i.
        WHILE lv_k <= lv_run_end.
          IF lv_k > lv_i.
            lv_block = lv_block + lt_info[ lv_k ]-gap.
          ENDIF.
          lv_block = lv_block + cs_line-pieces[ lv_k ]-width.
          lv_k = lv_k + 1.
        ENDWHILE.
        IF lv_base = 'R'.
          lv_cursor = lv_cursor - lt_info[ lv_i ]-gap - lv_block.
          lv_start = lv_cursor.
          lv_k = lv_i.
          WHILE lv_k <= lv_run_end.
            IF lv_k > lv_i.
              lv_start = lv_start + lt_info[ lv_k ]-gap.
            ENDIF.
            cs_line-pieces[ lv_k ]-x = lv_start.
            lv_start = lv_start + cs_line-pieces[ lv_k ]-width.
            lv_k = lv_k + 1.
          ENDWHILE.
        ELSE.
          lv_cursor = lv_cursor + lt_info[ lv_i ]-gap.
          lv_start = lv_cursor + lv_block.
          lv_k = lv_i.
          WHILE lv_k <= lv_run_end.
            IF lv_k > lv_i.
              lv_start = lv_start - lt_info[ lv_k ]-gap.
            ENDIF.
            lv_start = lv_start - cs_line-pieces[ lv_k ]-width.
            cs_line-pieces[ lv_k ]-x = lv_start.
            lv_k = lv_k + 1.
          ENDWHILE.
          lv_cursor = lv_cursor + lv_block.
        ENDIF.
      ENDIF.
      lv_i = lv_run_end + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD add_text.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_word TYPE string.
    DATA ls_piece TYPE ty_piece.
    DATA ls_last TYPE ty_piece.
    DATA lv_font TYPE i.
    DATA lv_flush TYPE abap_bool.
    DATA lv_spaces TYPE i.
    DATA lt_word TYPE ty_pieces.

    DATA lv_loops TYPE i.

    lv_font = font_index( is_style ).
    lv_len = strlen( iv_text ).
    lv_loops = lv_len + 1.
    DO lv_loops TIMES.
      lv_i = sy-index - 1.
      lv_flush = abap_false.
      IF lv_i >= lv_len.
        lv_flush = abap_true.
        lv_c = ' '.
      ELSE.
        lv_c = iv_text+lv_i(1).
        IF lv_c = ' ' OR lv_c = cl_abap_char_utilities=>horizontal_tab
            OR lv_c = cl_abap_char_utilities=>newline OR lv_c = cl_abap_char_utilities=>cr_lf(1).
          lv_flush = abap_true.
        ENDIF.
      ENDIF.
      IF lv_flush = abap_false.
        lv_word = lv_word && lv_c.
        CONTINUE.
      ENDIF.
      IF lv_word IS NOT INITIAL.
        lv_spaces = mv_pending.
        IF is_style-pre = abap_false AND lv_spaces > 1.
          lv_spaces = 1.
        ENDIF.
        IF is_style-pre = abap_false.
          CLEAR ls_last.
          READ TABLE ct_pieces INTO ls_last INDEX lines( ct_pieces ).
          IF sy-subrc <> 0 OR ls_last-brk = abap_true.
            lv_spaces = 0.
          ENDIF.
        ENDIF.
        "A word can hold Arabic and Latin parts: each part is its own piece, without a gap.
        lt_word = word_pieces( iv_word = lv_word is_style = is_style iv_font = lv_font ).
        LOOP AT lt_word INTO ls_piece.
          IF sy-tabix = 1.
            ls_piece-spaces = lv_spaces.
          ENDIF.
          APPEND ls_piece TO ct_pieces.
        ENDLOOP.
        mv_pending = 0.
        CLEAR lv_word.
      ENDIF.
      IF lv_i >= lv_len.
        EXIT.
      ENDIF.
      IF lv_c = cl_abap_char_utilities=>newline.
        IF is_style-pre = abap_true.
          add_break( EXPORTING is_style = is_style CHANGING ct_pieces = ct_pieces ).
        ELSE.
          mv_pending = mv_pending + 1.
        ENDIF.
      ELSEIF lv_c = cl_abap_char_utilities=>cr_lf(1).
        IF is_style-pre = abap_false.
          mv_pending = mv_pending + 1.
        ENDIF.
      ELSE.
        mv_pending = mv_pending + 1.
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD collect.
    DATA lt_frames TYPE ty_frames.
    DATA ls_frame TYPE ty_frame.
    DATA ls_top TYPE ty_frame.
    DATA ls_token TYPE ty_token.
    DATA ls_box TYPE ty_box.
    DATA ls_last TYPE ty_piece.
    DATA lv_class TYPE string.
    DATA lv_index TYPE i.

    mv_pending = 0.
    ev_align = is_style-align.
    ls_frame-name = `#root`.
    ls_frame-style = is_style.
    APPEND ls_frame TO lt_frames.

    LOOP AT it_tokens INTO ls_token.
      READ TABLE lt_frames INTO ls_top INDEX lines( lt_frames ).
      CASE ls_token-kind.
        WHEN 'T'.
          add_text( EXPORTING iv_text = decode( ls_token-text ) is_style = ls_top-style
                    CHANGING ct_pieces = rt_pieces ).
        WHEN 'O' OR 'S'.
          IF ls_token-name = 'br'.
            add_break( EXPORTING is_style = ls_top-style CHANGING ct_pieces = rt_pieces ).
            CONTINUE.
          ENDIF.
          IF ls_token-name = 'img' OR ls_token-name = 'hr'.
            CONTINUE.
          ENDIF.
          IF is_block( ls_token-name ) = abap_true AND rt_pieces IS NOT INITIAL.
            READ TABLE rt_pieces INTO ls_last INDEX lines( rt_pieces ).
            IF ls_last-brk = abap_false.
              add_break( EXPORTING is_style = ls_top-style CHANGING ct_pieces = rt_pieces ).
            ENDIF.
          ENDIF.
          tag_style(
            EXPORTING iv_name = ls_token-name iv_attrs = ls_token-attrs is_parent = ls_top-style
            IMPORTING es_style = ls_frame-style es_box = ls_box ).
          IF ev_align = is_style-align AND to_lower( ls_token-attrs ) CS 'text-align'.
            ev_align = ls_frame-style-align.
          ENDIF.
          lv_class = to_lower( attr( iv_attrs = ls_token-attrs iv_name = `class` ) ).
          IF iv_page > 0 AND lv_class CS 'pagenumber'.
            add_text( EXPORTING iv_text = |{ iv_page }| is_style = ls_frame-style
                      CHANGING ct_pieces = rt_pieces ).
          ELSEIF iv_total > 0 AND lv_class CS 'totalpages'.
            add_text( EXPORTING iv_text = |{ iv_total }| is_style = ls_frame-style
                      CHANGING ct_pieces = rt_pieces ).
          ENDIF.
          IF ls_token-kind = 'O'.
            ls_frame-name = ls_token-name.
            APPEND ls_frame TO lt_frames.
          ENDIF.
        WHEN 'C'.
          IF ls_token-name = 'td' OR ls_token-name = 'th'.
            mv_pending = mv_pending + 2.
          ELSEIF is_block( ls_token-name ) = abap_true AND rt_pieces IS NOT INITIAL.
            READ TABLE rt_pieces INTO ls_last INDEX lines( rt_pieces ).
            IF ls_last-brk = abap_false.
              add_break( EXPORTING is_style = ls_top-style CHANGING ct_pieces = rt_pieces ).
            ENDIF.
          ENDIF.
          lv_index = lines( lt_frames ).
          WHILE lv_index > 1.
            READ TABLE lt_frames INTO ls_frame INDEX lv_index.
            IF ls_frame-name = ls_token-name.
              DELETE lt_frames FROM lv_index.
              EXIT.
            ENDIF.
            lv_index = lv_index - 1.
          ENDWHILE.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD wrap.
    DATA ls_piece TYPE ty_piece.
    DATA ls_line TYPE ty_line.
    DATA ls_chunk TYPE ty_piece.
    DATA lv_x TYPE f.
    DATA lv_space TYPE f.
    DATA lv_char TYPE f.
    DATA lv_off TYPE i.
    DATA lv_hex TYPE string.
    DATA lv_x1 TYPE x LENGTH 1.
    DATA lv_code TYPE i.
    DATA lv_step TYPE i.
    DATA lv_word_from TYPE i.
    DATA lt_move TYPE ty_pieces.
    DATA ls_move TYPE ty_piece.
    DATA lv_keep TYPE i.

    LOOP AT it_pieces INTO ls_piece.
      IF ls_piece-brk = abap_true.
        IF ls_line-size <= 0.
          ls_line-size = ls_piece-size.
        ENDIF.
        APPEND ls_line TO rt_lines.
        CLEAR ls_line.
        lv_x = 0.
        CONTINUE.
      ENDIF.
      lv_space = ls_piece-spaces * char_width( iv_font = ls_piece-font iv_code = 32 ) * ls_piece-size / 1000.
      IF ls_line-pieces IS NOT INITIAL AND lv_x + lv_space + ls_piece-width > iv_width.
        IF ls_piece-glue = abap_true AND lv_word_from > 1.
          "The word started on this line: move all its parts to the next line.
          CLEAR lt_move.
          LOOP AT ls_line-pieces INTO ls_move FROM lv_word_from.
            APPEND ls_move TO lt_move.
          ENDLOOP.
          DELETE ls_line-pieces FROM lv_word_from.
          lv_keep = lines( ls_line-pieces ).
          READ TABLE ls_line-pieces INTO ls_move INDEX lv_keep.
          ls_line-width = ls_move-x + ls_move-width.
          APPEND ls_line TO rt_lines.
          CLEAR ls_line.
          lv_x = 0.
          LOOP AT lt_move INTO ls_move.
            ls_move-x = lv_x.
            lv_x = lv_x + ls_move-width.
            APPEND ls_move TO ls_line-pieces.
            IF ls_line-size < ls_move-size.
              ls_line-size = ls_move-size.
            ENDIF.
          ENDLOOP.
          ls_line-width = lv_x.
          lv_word_from = 1.
          lv_space = 0.
        ELSE.
          APPEND ls_line TO rt_lines.
          CLEAR ls_line.
          lv_x = 0.
          lv_space = 0.
        ENDIF.
      ENDIF.
      IF ls_line-pieces IS INITIAL AND lv_space + ls_piece-width > iv_width AND iv_width > 0.
        "A word wider than the box is split between characters.
        lv_off = 0.
        CLEAR lv_hex.
        lv_step = COND #( WHEN ls_piece-font >= 13 THEN 4 ELSE 2 ).
        WHILE lv_off + lv_step <= strlen( ls_piece-hex ).
          IF lv_step = 4.
            lv_char = hex_width( iv_hex = substring( val = ls_piece-hex off = lv_off len = 4 )
                                 iv_font = ls_piece-font iv_size = ls_piece-size ).
          ELSE.
            lv_x1 = ls_piece-hex+lv_off(2).
            lv_code = lv_x1.
            lv_char = char_width( iv_font = ls_piece-font iv_code = lv_code ) * ls_piece-size / 1000.
          ENDIF.
          IF lv_hex IS NOT INITIAL AND lv_x + lv_space + lv_char > iv_width.
            ls_chunk = ls_piece.
            ls_chunk-hex = lv_hex.
            ls_chunk-width = lv_x.
            ls_chunk-x = lv_space.
            APPEND ls_chunk TO ls_line-pieces.
            ls_line-width = lv_space + lv_x.
            IF ls_line-size < ls_piece-size.
              ls_line-size = ls_piece-size.
            ENDIF.
            APPEND ls_line TO rt_lines.
            CLEAR ls_line.
            CLEAR lv_hex.
            lv_x = 0.
            lv_space = 0.
          ENDIF.
          lv_hex = lv_hex && substring( val = ls_piece-hex off = lv_off len = lv_step ).
          lv_x = lv_x + lv_char.
          lv_off = lv_off + lv_step.
        ENDWHILE.
        ls_piece-hex = lv_hex.
        ls_piece-width = lv_x.
        lv_x = 0.
      ENDIF.
      ls_piece-x = lv_x + lv_space.
      APPEND ls_piece TO ls_line-pieces.
      IF ls_piece-glue = abap_false.
        lv_word_from = lines( ls_line-pieces ).
      ENDIF.
      lv_x = ls_piece-x + ls_piece-width.
      ls_line-width = lv_x.
      IF ls_line-size < ls_piece-size.
        ls_line-size = ls_piece-size.
      ENDIF.
    ENDLOOP.
    IF ls_line-pieces IS NOT INITIAL.
      APPEND ls_line TO rt_lines.
    ENDIF.
  ENDMETHOD.

  METHOD line_height.
    rv_height = is_line-size * c_line_factor.
    IF rv_height <= 0.
      rv_height = 12 * c_line_factor.
    ENDIF.
  ENDMETHOD.

  METHOD draw_line.
    DATA ls_piece TYPE ty_piece.
    DATA lv_dx TYPE f.
    DATA lv_base TYPE f.
    DATA lv_x TYPE f.
    DATA lv_y TYPE f.
    DATA lv_color TYPE string.
    DATA lv_from TYPE f.
    DATA lv_prev_end TYPE f.
    DATA lv_prev_under TYPE abap_bool.
    DATA ls_line TYPE ty_line.

    ls_line = is_line.
    visual_order( CHANGING cs_line = ls_line ).
    CASE iv_align.
      WHEN 'center'.
        lv_dx = ( iv_width - is_line-width ) / 2.
      WHEN 'right' OR 'end'.
        lv_dx = iv_width - is_line-width.
    ENDCASE.
    IF lv_dx < 0.
      lv_dx = 0.
    ENDIF.
    lv_base = iv_top + ( line_height( is_line ) - is_line-size * '1.117' ) / 2 + is_line-size * '0.905'.
    lv_y = mv_ph - lv_base.
    LOOP AT ls_line-pieces INTO ls_piece WHERE brk = abap_false.
      lv_x = iv_x + lv_dx + ls_piece-x.
      lv_color = ls_piece-color.
      IF lv_color IS INITIAL.
        lv_color = `0 0 0`.
      ENDIF.
      emit( |BT /F{ ls_piece-font } { num( ls_piece-size ) } Tf { lv_color } rg | &&
            |{ num( lv_x ) } { num( lv_y ) } Td <{ ls_piece-hex }> Tj ET| ).
      IF ls_piece-under = abap_true.
        lv_from = lv_x.
        IF lv_prev_under = abap_true.
          lv_from = lv_prev_end.
        ENDIF.
        emit( |{ lv_color } RG { num( ls_piece-size / 18 ) } w { num( lv_from ) } { num( lv_y - ls_piece-size / 9 ) } m | &&
              |{ num( lv_x + ls_piece-width ) } { num( lv_y - ls_piece-size / 9 ) } l S| ).
      ENDIF.
      lv_prev_under = ls_piece-under.
      lv_prev_end = lv_x + ls_piece-width.
    ENDLOOP.
  ENDMETHOD.

  METHOD draw_lines.
    DATA ls_line TYPE ty_line.
    DATA lv_y TYPE f.

    lv_y = iv_top.
    LOOP AT it_lines INTO ls_line.
      draw_line( is_line = ls_line iv_x = iv_x iv_width = iv_width iv_top = lv_y iv_align = iv_align ).
      lv_y = lv_y + line_height( ls_line ).
    ENDLOOP.
    rv_height = lv_y - iv_top.
  ENDMETHOD.

  METHOD new_page.
    APPEND `` TO mt_pages.
    mv_page = lines( mt_pages ).
  ENDMETHOD.

  METHOD emit.
    FIELD-SYMBOLS <lv_page> TYPE string.
    IF mv_page = 0.
      new_page( ).
    ENDIF.
    READ TABLE mt_pages ASSIGNING <lv_page> INDEX mv_page.
    IF sy-subrc = 0.
      <lv_page> = <lv_page> && iv_ops && cl_abap_char_utilities=>newline.
    ENDIF.
  ENDMETHOD.

  METHOD layout_widgets.
    DATA lv_flow_ready TYPE abap_bool.
    DATA lv_flow_shift TYPE f.
    TYPES:
      BEGIN OF ty_every,
        style  TYPE string,
        attrs  TYPE string,
        tokens TYPE ty_tokens,
      END OF ty_every.
    DATA lt_every TYPE STANDARD TABLE OF ty_every WITH DEFAULT KEY.
    DATA ls_every TYPE ty_every.
    DATA lv_pages TYPE i.
    DATA lv_p TYPE i.
    DATA lv_saved TYPE string.
    DATA lv_new TYPE string.
    DATA ls_token TYPE ty_token.
    DATA ls_inner TYPE ty_token.
    DATA lt_inner TYPE ty_tokens.
    DATA lv_i TYPE i.
    DATA lv_j TYPE i.
    DATA lv_depth TYPE i.
    DATA lv_sections TYPE i.
    DATA lv_count TYPE i.
    DATA lv_from TYPE i.
    DATA lv_to TYPE i.

    new_page( ).
    mv_y = mv_mt.
    mv_gap = 0.
    lv_count = lines( it_tokens ).
    lv_i = 1.
    WHILE lv_i <= lv_count.
      READ TABLE it_tokens INTO ls_token INDEX lv_i.
      IF ls_token-kind = 'O' AND ls_token-name = 'section'.
        lv_sections = lv_sections + 1.
        lv_flow_ready = abap_false.
        lv_flow_shift = 0.
        IF lv_sections > 1.
          new_page( ).
          mv_y = mv_mt.
          mv_gap = 0.
        ENDIF.
        lv_i = lv_i + 1.
        CONTINUE.
      ENDIF.
      "Designer tables are exported in normal flow, positioned by their margins.
      IF ls_token-kind = 'O' AND ls_token-name = 'table'.
        lv_j = table_end( it_tokens = it_tokens iv_start = lv_i ).
        CLEAR lt_inner.
        lv_from = lv_i + 1.
        lv_to = lv_j - 1.
        LOOP AT it_tokens INTO ls_inner FROM lv_from TO lv_to.
          APPEND ls_inner TO lt_inner.
        ENDLOOP.
        layout_table( it_tokens = lt_inner iv_attrs = ls_token-attrs is_parent = base_style( )
                      iv_x = mv_ml iv_width = mv_pw - mv_ml - mv_mr ).
        lv_i = lv_j + 1.
        CONTINUE.
      ENDIF.
      IF ls_token-kind = 'O' AND ls_token-name = 'div'.
        CLEAR lt_inner.
        lv_depth = 1.
        lv_j = lv_i + 1.
        WHILE lv_j <= lv_count.
          READ TABLE it_tokens INTO ls_inner INDEX lv_j.
          IF ls_inner-kind = 'O' AND ls_inner-name = 'div'.
            lv_depth = lv_depth + 1.
          ELSEIF ls_inner-kind = 'C' AND ls_inner-name = 'div'.
            lv_depth = lv_depth - 1.
            IF lv_depth = 0.
              EXIT.
            ENDIF.
          ENDIF.
          APPEND ls_inner TO lt_inner.
          lv_j = lv_j + 1.
        ENDWHILE.
        IF attr( iv_attrs = ls_token-attrs iv_name = `data-every` ) IS NOT INITIAL.
          "Shown on every page: drawn once all pages exist.
          ls_every-style = attr( iv_attrs = ls_token-attrs iv_name = `style` ).
          ls_every-attrs = ls_token-attrs.
          ls_every-tokens = lt_inner.
          APPEND ls_every TO lt_every.
        ELSEIF attr( iv_attrs = ls_token-attrs iv_name = `data-flow` ) = `after`.
          "Objects below a table follow it (like "following previous" in Adobe forms): they move
          "down when the table ends lower than designed, or to a new page when there is no room.
          IF lv_flow_ready = abap_false.
            lv_flow_ready = abap_true.
            lv_flow_shift = flow_shift( it_tokens = it_tokens iv_from = lv_i ).
          ENDIF.
          draw_widget( iv_style = attr( iv_attrs = ls_token-attrs iv_name = `style` ) it_tokens = lt_inner
                       iv_attrs = ls_token-attrs iv_shift = lv_flow_shift ).
        ELSE.
          draw_widget( iv_style = attr( iv_attrs = ls_token-attrs iv_name = `style` ) it_tokens = lt_inner
                       iv_attrs = ls_token-attrs ).
        ENDIF.
        lv_i = lv_j + 1.
        CONTINUE.
      ENDIF.
      lv_i = lv_i + 1.
    ENDWHILE.

    "Objects for every page go beneath the page content, at the same place on each page.
    IF lt_every IS NOT INITIAL.
      lv_pages = lines( mt_pages ).
      DO lv_pages TIMES.
        lv_p = sy-index.
        READ TABLE mt_pages INTO lv_saved INDEX lv_p.
        MODIFY mt_pages FROM `` INDEX lv_p.
        mv_page = lv_p.
        LOOP AT lt_every INTO ls_every.
          IF on_page( iv_rule = attr( iv_attrs = ls_every-attrs iv_name = `data-every` )
                      iv_page = lv_p iv_total = lv_pages ) = abap_false.
            CONTINUE.
          ENDIF.
          draw_widget( iv_style  = ls_every-style
                       it_tokens = page_tokens( it_tokens = ls_every-tokens iv_page = lv_p iv_total = lv_pages )
                       iv_attrs  = ls_every-attrs ).
        ENDLOOP.
        READ TABLE mt_pages INTO lv_new INDEX lv_p.
        lv_new = lv_new && lv_saved.
        MODIFY mt_pages FROM lv_new INDEX lv_p.
      ENDDO.
      mv_page = lv_pages.
    ENDIF.
  ENDMETHOD.

  METHOD draw_widget.
    DATA lv_rad TYPE f.
    DATA lv_cos TYPE f.
    DATA lv_sin TYPE f.
    DATA lv_cx TYPE f.
    DATA lv_cy TYPE f.
    DATA ls_line TYPE ty_line.
    DATA lv_text_h TYPE f.
    DATA lv_shift TYPE f.
    DATA ls_style TYPE ty_style.
    DATA ls_box TYPE ty_box.
    DATA ls_token TYPE ty_token.
    DATA ls_img TYPE ty_box.
    DATA ls_dummy TYPE ty_style.
    DATA lt_pieces TYPE ty_pieces.
    DATA lt_lines TYPE ty_lines.
    DATA lv_x TYPE f.
    DATA lv_top TYPE f.
    DATA lv_inset TYPE f.
    DATA lv_iw TYPE f.
    DATA lv_ih TYPE f.
    DATA lv_align TYPE string.
    DATA lv_src TYPE string.

    ls_style = base_style( ).
    ls_style-pre = abap_true.
    apply_decls(
      EXPORTING iv_decls = iv_style iv_base = ls_style-size
      CHANGING  cs_style = ls_style cs_box = ls_box ).
    IF ls_box-e_top IS INITIAL AND ls_box-e_right IS INITIAL
        AND ls_box-e_bot IS INITIAL AND ls_box-e_left IS INITIAL.
      ls_box-e_top = ls_style-color.
      ls_box-e_right = ls_style-color.
      ls_box-e_bot = ls_style-color.
      ls_box-e_left = ls_style-color.
    ENDIF.
    IF ls_box-no_edge = abap_true.
      ls_box-border = 0.
    ENDIF.

    lv_x = mv_ml + ls_box-x.
    lv_top = mv_mt + ls_box-y + iv_shift.
    emit( `q` ).
    IF ls_box-has_opacity = abap_true AND ls_box-opacity < 1.
      emit( |/{ gstate_name( ls_box-opacity ) } gs| ).
    ENDIF.
    IF ls_box-rotate <> 0.
      "Rotate around the centre of the object (CSS degrees are clockwise, PDF angles counter-clockwise).
      lv_rad = - ls_box-rotate * c_pi / 180.
      lv_cos = cos( lv_rad ).
      lv_sin = sin( lv_rad ).
      lv_cx = lv_x + ls_box-w / 2.
      lv_cy = mv_ph - lv_top - ls_box-h / 2.
      emit( |{ num( lv_cos ) } { num( lv_sin ) } { num( - lv_sin ) } { num( lv_cos ) } | &&
            |{ num( lv_cx - lv_cos * lv_cx + lv_sin * lv_cy ) } { num( lv_cy - lv_sin * lv_cx - lv_cos * lv_cy ) } cm| ).
    ENDIF.
    draw_box( is_box = ls_box iv_x = lv_x iv_top = lv_top ).

    lv_inset = ls_box-border + ls_box-pad.
    lv_iw = ls_box-w - 2 * lv_inset.
    lv_ih = ls_box-h - 2 * lv_inset.
    IF ls_box-has_h = abap_true AND ls_box-w > 0 AND ls_box-h > 0.
      emit( |{ num( lv_x + ls_box-border ) } { num( mv_ph - lv_top - ls_box-h + ls_box-border ) } | &&
            |{ num( ls_box-w - 2 * ls_box-border ) } { num( ls_box-h - 2 * ls_box-border ) } re W n| ).
    ENDIF.

    "QR code / barcode object.
    IF iv_attrs IS NOT INITIAL AND attr( iv_attrs = iv_attrs iv_name = `data-code` ) IS NOT INITIAL.
      draw_code( iv_attrs = iv_attrs it_tokens = it_tokens is_style = ls_style
                 iv_x = lv_x + lv_inset iv_top = lv_top + lv_inset iv_w = lv_iw iv_h = lv_ih ).
      emit( `Q` ).
      RETURN.
    ENDIF.

    LOOP AT it_tokens INTO ls_token WHERE name = 'img' AND ( kind = 'S' OR kind = 'O' ).
      lv_src = decode( attr( iv_attrs = ls_token-attrs iv_name = `src` ) ).
      CLEAR ls_img.
      ls_dummy = ls_style.
      apply_decls(
        EXPORTING iv_decls = attr( iv_attrs = ls_token-attrs iv_name = `style` ) iv_base = ls_style-size
        CHANGING  cs_style = ls_dummy cs_box = ls_img ).
      IF ls_img-fit IS INITIAL.
        ls_img-fit = `contain`.
      ENDIF.
      IF lv_ih <= 0.
        lv_ih = lv_iw.
      ENDIF.
      draw_image( iv_src = lv_src iv_x = lv_x + lv_inset iv_top = lv_top + lv_inset
                  iv_w = lv_iw iv_h = lv_ih iv_fit = ls_img-fit ).
      emit( `Q` ).
      RETURN.
    ENDLOOP.

    lt_pieces = collect(
      EXPORTING it_tokens = it_tokens is_style = ls_style
      IMPORTING ev_align = lv_align ).
    lt_lines = wrap( it_pieces = lt_pieces iv_width = lv_iw ).
    IF ls_box-valign = `middle` OR ls_box-valign = `bottom`.
      LOOP AT lt_lines INTO ls_line.
        lv_text_h = lv_text_h + line_height( ls_line ).
      ENDLOOP.
      IF lv_ih > lv_text_h.
        lv_shift = lv_ih - lv_text_h.
        IF ls_box-valign = `middle`.
          lv_shift = lv_shift / 2.
        ENDIF.
      ENDIF.
    ENDIF.
    draw_lines( it_lines = lt_lines iv_x = lv_x + lv_inset iv_width = lv_iw
                iv_top = lv_top + lv_inset + lv_shift iv_align = ls_style-align ).
    emit( `Q` ).
  ENDMETHOD.

  METHOD draw_code.
    DATA lv_quiet TYPE i.
    DATA lv_modules TYPE string.
    DATA lv_hr_text TYPE string.
    DATA lt_hr_tokens TYPE ty_tokens.
    DATA lv_k TYPE i.
    DATA lx_code TYPE REF TO zcx_pdf_studio.
    DATA ls_token TYPE ty_token.
    DATA lv_value TYPE string.
    DATA lv_code TYPE string.
    DATA lt_rows TYPE zcl_pdf_studio_codes=>ty_rows.
    DATA lv_row TYPE string.
    DATA lv_n TYPE i.
    DATA lv_mod TYPE f.
    DATA lv_x0 TYPE f.
    DATA lv_top0 TYPE f.
    DATA lv_y TYPE i.
    DATA lv_x TYPE i.
    DATA lv_run TYPE i.
    DATA lv_i TYPE i.
    DATA lv_ops TYPE string.
    DATA lv_widths TYPE string.
    DATA lv_total TYPE i.
    DATA lv_w TYPE i.
    DATA lv_bar TYPE abap_bool VALUE abap_true.
    DATA lv_bar_h TYPE f.
    DATA lv_text_h TYPE f.
    DATA lt_pieces TYPE ty_pieces.
    DATA lt_lines TYPE ty_lines.
    DATA lv_align TYPE string.

    LOOP AT it_tokens INTO ls_token WHERE kind = 'T'.
      lv_value = lv_value && ls_token-text.
    ENDLOOP.
    lv_value = zcl_pdf_studio_codes=>decode_entities( lv_value ).
    IF lv_value IS INITIAL OR iv_w <= 0 OR iv_h <= 0.
      RETURN.
    ENDIF.
    lv_code = to_lower( attr( iv_attrs = iv_attrs iv_name = `data-code` ) ).
    lt_hr_tokens = it_tokens.

    TRY.
        IF lv_code = `qr`.
          lt_rows = zcl_pdf_studio_codes=>qr( iv_text = lv_value iv_level = attr( iv_attrs = iv_attrs iv_name = `data-ecc` ) ).
          lv_quiet = 4.
        ELSEIF lv_code = `datamatrix`.
          lt_rows = zcl_pdf_studio_barcode=>datamatrix( lv_value ).
          lv_quiet = 1.
        ELSEIF zcl_pdf_studio_barcode=>is_linear( lv_code ) = abap_true.
          zcl_pdf_studio_barcode=>linear( EXPORTING iv_type = lv_code iv_value = lv_value
                                          IMPORTING ev_modules = lv_modules ev_text = lv_hr_text ).
          "Modules -> bar/space widths (as for Code 128).
          lv_i = 0.
          WHILE lv_i < strlen( lv_modules ).
            lv_run = 1.
            WHILE lv_i + lv_run < strlen( lv_modules ).
              lv_k = lv_i + lv_run.
              IF lv_modules+lv_k(1) <> lv_modules+lv_i(1).
                EXIT.
              ENDIF.
              lv_run = lv_run + 1.
            ENDWHILE.
            lv_widths = lv_widths && |{ lv_run }|.
            lv_i = lv_i + lv_run.
          ENDWHILE.
          CLEAR lt_hr_tokens.
          APPEND VALUE #( kind = 'T' text = lv_hr_text ) TO lt_hr_tokens.
        ENDIF.
      CATCH zcx_pdf_studio INTO lx_code.
        "Invalid barcode data: the reason is printed instead of the symbol.
        CLEAR lt_hr_tokens.
        APPEND VALUE #( kind = 'T' text = lx_code->get_text( ) ) TO lt_hr_tokens.
        lt_pieces = collect( EXPORTING it_tokens = lt_hr_tokens is_style = is_style IMPORTING ev_align = lv_align ).
        lt_lines = wrap( it_pieces = lt_pieces iv_width = iv_w ).
        draw_lines( it_lines = lt_lines iv_x = iv_x iv_width = iv_w iv_top = iv_top iv_align = `left` ).
        RETURN.
    ENDTRY.

    IF lt_rows IS NOT INITIAL.
      lv_n = lines( lt_rows ).
      "Quiet zone around the symbol (QR 4, DataMatrix 1 module); the symbol is centred in the box.
      lv_mod = nmin( val1 = iv_w val2 = iv_h ) / ( lv_n + 2 * lv_quiet ).
      lv_x0 = iv_x + ( iv_w - lv_mod * lv_n ) / 2.
      lv_top0 = iv_top + ( iv_h - lv_mod * lv_n ) / 2.
      lv_ops = |{ is_style-color } rg|.
      LOOP AT lt_rows INTO lv_row.
        lv_y = sy-tabix - 1.
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
            lv_ops = |{ lv_ops } { num( lv_x0 + lv_x * lv_mod ) } { num( mv_ph - lv_top0 - ( lv_y + 1 ) * lv_mod ) } | &&
                     |{ num( lv_run * lv_mod ) } { num( lv_mod ) } re|.
            lv_x = lv_x + lv_run.
          ELSE.
            lv_x = lv_x + 1.
          ENDIF.
        ENDWHILE.
      ENDLOOP.
      emit( |{ lv_ops } f| ).
      RETURN.
    ENDIF.

    "Linear codes: 10 modules of quiet zone on each side, optional text line below the bars.
    IF lv_widths IS INITIAL.
      lv_widths = zcl_pdf_studio_codes=>code128( lv_value ).
    ENDIF.
    lv_i = 0.
    WHILE lv_i < strlen( lv_widths ).
      lv_w = lv_widths+lv_i(1).
      lv_total = lv_total + lv_w.
      lv_i = lv_i + 1.
    ENDWHILE.
    lv_mod = iv_w / ( lv_total + 20 ).
    lv_bar_h = iv_h.
    IF attr( iv_attrs = iv_attrs iv_name = `data-hr` ) = `1`.
      lv_text_h = is_style-size * c_line_factor.
      IF lv_text_h < iv_h / 2.
        lv_bar_h = iv_h - lv_text_h.
        lt_pieces = collect( EXPORTING it_tokens = lt_hr_tokens is_style = is_style IMPORTING ev_align = lv_align ).
        lt_lines = wrap( it_pieces = lt_pieces iv_width = iv_w ).
        draw_lines( it_lines = lt_lines iv_x = iv_x iv_width = iv_w iv_top = iv_top + lv_bar_h iv_align = `center` ).
      ENDIF.
    ENDIF.
    lv_ops = |{ is_style-color } rg|.
    lv_x0 = iv_x + 10 * lv_mod.
    lv_i = 0.
    WHILE lv_i < strlen( lv_widths ).
      lv_w = lv_widths+lv_i(1).
      IF lv_bar = abap_true.
        lv_ops = |{ lv_ops } { num( lv_x0 ) } { num( mv_ph - iv_top - lv_bar_h ) } { num( lv_w * lv_mod ) } { num( lv_bar_h ) } re|.
      ENDIF.
      lv_x0 = lv_x0 + lv_w * lv_mod.
      lv_bar = xsdbool( lv_bar = abap_false ).
      lv_i = lv_i + 1.
    ENDWHILE.
    emit( |{ lv_ops } f| ).
  ENDMETHOD.

  METHOD draw_box.
    DATA lv_bottom TYPE f.
    DATA lv_b TYPE f.
    DATA lv_cx TYPE f.
    DATA lv_cy TYPE f.
    DATA lv_rx TYPE f.
    DATA lv_ry TYPE f.
    DATA lv_kx TYPE f.
    DATA lv_ky TYPE f.
    DATA lv_path TYPE string.
    DATA lv_k TYPE f VALUE '0.5523'.

    IF is_box-w <= 0 OR is_box-h <= 0.
      RETURN.
    ENDIF.
    lv_bottom = mv_ph - iv_top - is_box-h.
    lv_b = is_box-border.

    IF is_box-round = abap_true.
      lv_cx = iv_x + is_box-w / 2.
      lv_cy = lv_bottom + is_box-h / 2.
      lv_rx = is_box-w / 2 - lv_b / 2.
      lv_ry = is_box-h / 2 - lv_b / 2.
      IF lv_rx <= 0 OR lv_ry <= 0.
        RETURN.
      ENDIF.
      lv_kx = lv_rx * lv_k.
      lv_ky = lv_ry * lv_k.
      lv_path =
        |{ num( lv_cx + lv_rx ) } { num( lv_cy ) } m | &&
        |{ num( lv_cx + lv_rx ) } { num( lv_cy + lv_ky ) } { num( lv_cx + lv_kx ) } { num( lv_cy + lv_ry ) } { num( lv_cx ) } { num( lv_cy + lv_ry ) } c | &&
        |{ num( lv_cx - lv_kx ) } { num( lv_cy + lv_ry ) } { num( lv_cx - lv_rx ) } { num( lv_cy + lv_ky ) } { num( lv_cx - lv_rx ) } { num( lv_cy ) } c | &&
        |{ num( lv_cx - lv_rx ) } { num( lv_cy - lv_ky ) } { num( lv_cx - lv_kx ) } { num( lv_cy - lv_ry ) } { num( lv_cx ) } { num( lv_cy - lv_ry ) } c | &&
        |{ num( lv_cx + lv_kx ) } { num( lv_cy - lv_ry ) } { num( lv_cx + lv_rx ) } { num( lv_cy - lv_ky ) } { num( lv_cx + lv_rx ) } { num( lv_cy ) } c h|.
      IF is_box-fill IS NOT INITIAL.
        emit( |{ is_box-fill } rg { lv_path } f| ).
      ENDIF.
      IF lv_b > 0 AND is_box-e_top IS NOT INITIAL.
        emit( |{ is_box-e_top } RG { num( lv_b ) } w { lv_path } S| ).
      ENDIF.
      RETURN.
    ENDIF.

    IF is_box-fill IS NOT INITIAL.
      emit( |{ is_box-fill } rg { num( iv_x ) } { num( lv_bottom ) } { num( is_box-w ) } { num( is_box-h ) } re f| ).
    ENDIF.
    IF lv_b > 0.
      IF is_box-e_top IS NOT INITIAL.
        emit( |{ is_box-e_top } rg { num( iv_x ) } { num( lv_bottom + is_box-h - lv_b ) } { num( is_box-w ) } { num( lv_b ) } re f| ).
      ENDIF.
      IF is_box-e_bot IS NOT INITIAL.
        emit( |{ is_box-e_bot } rg { num( iv_x ) } { num( lv_bottom ) } { num( is_box-w ) } { num( lv_b ) } re f| ).
      ENDIF.
      IF is_box-e_left IS NOT INITIAL.
        emit( |{ is_box-e_left } rg { num( iv_x ) } { num( lv_bottom ) } { num( lv_b ) } { num( is_box-h ) } re f| ).
      ENDIF.
      IF is_box-e_right IS NOT INITIAL.
        emit( |{ is_box-e_right } rg { num( iv_x + is_box-w - lv_b ) } { num( lv_bottom ) } { num( lv_b ) } { num( is_box-h ) } re f| ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD draw_image.
    DATA lv_name TYPE string.
    DATA lv_iw TYPE i.
    DATA lv_ih TYPE i.
    DATA lv_sx TYPE f.
    DATA lv_sy TYPE f.
    DATA lv_s TYPE f.
    DATA lv_dw TYPE f.
    DATA lv_dh TYPE f.
    DATA lv_dx TYPE f.
    DATA lv_dy TYPE f.

    IF iv_w <= 0 OR iv_h <= 0.
      RETURN.
    ENDIF.
    lv_name = load_image(
      EXPORTING iv_src = iv_src
      IMPORTING ev_width = lv_iw ev_height = lv_ih ).
    IF lv_name IS INITIAL OR lv_iw <= 0 OR lv_ih <= 0.
      "Unsupported image (for example PNG with transparency): light placeholder.
      emit( |0.93 0.95 0.96 rg { num( iv_x ) } { num( mv_ph - iv_top - iv_h ) } { num( iv_w ) } { num( iv_h ) } re f| ).
      RETURN.
    ENDIF.
    lv_sx = iv_w / lv_iw.
    lv_sy = iv_h / lv_ih.
    CASE iv_fit.
      WHEN 'fill'.
        lv_dw = iv_w.
        lv_dh = iv_h.
      WHEN 'cover'.
        lv_s = nmax( val1 = lv_sx val2 = lv_sy ).
        lv_dw = lv_iw * lv_s.
        lv_dh = lv_ih * lv_s.
      WHEN OTHERS.
        lv_s = nmin( val1 = lv_sx val2 = lv_sy ).
        lv_dw = lv_iw * lv_s.
        lv_dh = lv_ih * lv_s.
    ENDCASE.
    lv_dx = iv_x + ( iv_w - lv_dw ) / 2.
    lv_dy = iv_top + ( iv_h - lv_dh ) / 2.
    emit( |q { num( lv_dw ) } 0 0 { num( lv_dh ) } { num( lv_dx ) } { num( mv_ph - lv_dy - lv_dh ) } cm /{ lv_name } Do Q| ).
  ENDMETHOD.

  METHOD load_image.
    DATA ls_image TYPE ty_image.
    DATA lv_comma TYPE i.
    DATA lv_head TYPE string.
    DATA lv_b64 TYPE string.
    DATA lv_data TYPE xstring.

    READ TABLE mt_images INTO ls_image WITH KEY src = iv_src.
    IF sy-subrc = 0.
      ev_width = ls_image-width.
      ev_height = ls_image-height.
      rv_name = ls_image-name.
      RETURN.
    ENDIF.
    IF to_lower( iv_src ) CP 'asset:*'.
      "Uploaded image (logo, signature, background) from the asset store.
      IF mo_res IS NOT BOUND.
        RETURN.
      ENDIF.
      lv_data = mo_res->image( substring( val = iv_src off = 6 ) ).
      IF xstrlen( lv_data ) > 8 AND lv_data(8) = '89504E470D0A1A0A'.
        lv_head = `png`.
      ELSEIF xstrlen( lv_data ) > 2 AND lv_data(2) = 'FFD8'.
        lv_head = `jpeg`.
      ENDIF.
    ELSE.
      IF to_lower( iv_src ) NP 'data:image/*;base64,*'.
        RETURN.
      ENDIF.
      lv_comma = find( val = iv_src sub = ',' ).
      lv_head = to_lower( substring( val = iv_src len = lv_comma ) ).
      lv_b64 = substring( val = iv_src off = lv_comma + 1 ).
      TRY.
          lv_data = cl_http_utility=>decode_x_base64( lv_b64 ).
        CATCH cx_root.
          RETURN.
      ENDTRY.
    ENDIF.
    IF lv_data IS INITIAL.
      RETURN.
    ENDIF.
    ls_image-src = iv_src.
    IF lv_head CS 'jpeg' OR lv_head CS 'jpg'.
      parse_jpeg( EXPORTING iv_data = lv_data CHANGING cs_image = ls_image ).
    ELSEIF lv_head CS 'png'.
      parse_png( EXPORTING iv_data = lv_data CHANGING cs_image = ls_image ).
      IF ls_image-dict IS INITIAL.
        png_alpha( EXPORTING iv_data = lv_data CHANGING cs_image = ls_image ).
      ENDIF.
    ENDIF.
    IF ls_image-dict IS INITIAL.
      RETURN.
    ENDIF.
    ls_image-name = |Im{ lines( mt_images ) + 1 }|.
    APPEND ls_image TO mt_images.
    ev_width = ls_image-width.
    ev_height = ls_image-height.
    rv_name = ls_image-name.
  ENDMETHOD.

  METHOD bytes_int.
    DATA lv_x TYPE x LENGTH 1.
    DATA lv_i TYPE i.
    DATA lv_off TYPE i.

    IF iv_off + iv_len > xstrlen( iv_data ).
      RETURN.
    ENDIF.
    DO iv_len TIMES.
      lv_off = iv_off + sy-index - 1.
      lv_x = iv_data+lv_off(1).
      lv_i = lv_x.
      rv_int = rv_int * 256 + lv_i.
    ENDDO.
  ENDMETHOD.

  METHOD parse_jpeg.
    DATA lv_len TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_marker TYPE i.
    DATA lv_seg TYPE i.
    DATA lv_comps TYPE i.
    DATA lv_space TYPE string.

    lv_len = xstrlen( iv_data ).
    IF lv_len < 4 OR bytes_int( iv_data = iv_data iv_off = 0 iv_len = 2 ) <> 65496.
      RETURN.
    ENDIF.
    lv_pos = 2.
    WHILE lv_pos + 4 <= lv_len.
      IF bytes_int( iv_data = iv_data iv_off = lv_pos iv_len = 1 ) <> 255.
        lv_pos = lv_pos + 1.
        CONTINUE.
      ENDIF.
      lv_marker = bytes_int( iv_data = iv_data iv_off = lv_pos + 1 iv_len = 1 ).
      IF lv_marker = 255.
        lv_pos = lv_pos + 1.
        CONTINUE.
      ENDIF.
      IF lv_marker = 216 OR lv_marker = 1 OR ( lv_marker >= 208 AND lv_marker <= 215 ).
        lv_pos = lv_pos + 2.
        CONTINUE.
      ENDIF.
      lv_seg = bytes_int( iv_data = iv_data iv_off = lv_pos + 2 iv_len = 2 ).
      IF lv_marker >= 192 AND lv_marker <= 207 AND lv_marker <> 196 AND lv_marker <> 200 AND lv_marker <> 204.
        cs_image-height = bytes_int( iv_data = iv_data iv_off = lv_pos + 5 iv_len = 2 ).
        cs_image-width = bytes_int( iv_data = iv_data iv_off = lv_pos + 7 iv_len = 2 ).
        lv_comps = bytes_int( iv_data = iv_data iv_off = lv_pos + 9 iv_len = 1 ).
        CASE lv_comps.
          WHEN 1.
            lv_space = `/DeviceGray`.
          WHEN 4.
            lv_space = `/DeviceCMYK /Decode [1 0 1 0 1 0 1 0]`.
          WHEN OTHERS.
            lv_space = `/DeviceRGB`.
        ENDCASE.
        cs_image-data = iv_data.
        cs_image-dict = |/Type /XObject /Subtype /Image /Width { cs_image-width } /Height { cs_image-height } | &&
                        |/ColorSpace { lv_space } /BitsPerComponent 8 /Filter /DCTDecode|.
        RETURN.
      ENDIF.
      IF lv_seg < 2.
        RETURN.
      ENDIF.
      lv_pos = lv_pos + 2 + lv_seg.
    ENDWHILE.
  ENDMETHOD.

  METHOD png_alpha.
    DATA lv_len TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_off TYPE i.
    DATA lv_chunk TYPE i.
    DATA lv_type TYPE xstring.
    DATA lv_part TYPE xstring.
    DATA lv_idat TYPE xstring.
    DATA lv_raw TYPE xstring.
    DATA lv_plain TYPE xstring.
    DATA lv_width TYPE i.
    DATA lv_height TYPE i.
    DATA lv_depth TYPE i.
    DATA lv_ctype TYPE i.
    DATA lv_interlace TYPE i.
    DATA lv_bpp TYPE i.
    DATA lv_stride TYPE i.
    DATA lt_prev TYPE ty_ints.
    DATA lt_cur TYPE ty_ints.
    DATA lv_row TYPE i.
    DATA lv_i TYPE i.
    DATA lv_filter TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_x TYPE i.
    DATA lv_a TYPE i.
    DATA lv_b TYPE i.
    DATA lv_c TYPE i.
    DATA lv_v TYPE i.
    DATA lv_p TYPE i.
    DATA lv_pa TYPE i.
    DATA lv_pb TYPE i.
    DATA lv_pc TYPE i.
    DATA lt_hex TYPE ty_strings.
    DATA lt_color TYPE ty_strings.
    DATA lt_alpha TYPE ty_strings.
    DATA lv_color_row TYPE string.
    DATA lv_alpha_row TYPE string.
    DATA lv_hex TYPE string.
    DATA lv_color TYPE xstring.
    DATA lv_alpha TYPE xstring.
    DATA lv_zip TYPE xstring.
    DATA ls_mask TYPE ty_image.
    DATA lv_space TYPE string.
    DATA lv_filter_txt TYPE string.

    lv_len = xstrlen( iv_data ).
    lv_pos = 8.
    WHILE lv_pos + 8 <= lv_len.
      lv_chunk = bytes_int( iv_data = iv_data iv_off = lv_pos iv_len = 4 ).
      lv_off = lv_pos + 4.
      lv_type = iv_data+lv_off(4).
      lv_off = lv_pos + 8.
      IF lv_chunk < 0 OR lv_off + lv_chunk > lv_len.
        RETURN.
      ENDIF.
      CLEAR lv_part.
      IF lv_chunk > 0.
        lv_part = iv_data+lv_off(lv_chunk).
      ENDIF.
      CASE lv_type.
        WHEN '49484452'.
          lv_width = bytes_int( iv_data = lv_part iv_off = 0 iv_len = 4 ).
          lv_height = bytes_int( iv_data = lv_part iv_off = 4 iv_len = 4 ).
          lv_depth = bytes_int( iv_data = lv_part iv_off = 8 iv_len = 1 ).
          lv_ctype = bytes_int( iv_data = lv_part iv_off = 9 iv_len = 1 ).
          lv_interlace = bytes_int( iv_data = lv_part iv_off = 12 iv_len = 1 ).
        WHEN '49444154'.
          CONCATENATE lv_idat lv_part INTO lv_idat IN BYTE MODE.
        WHEN '49454E44'.
          EXIT.
      ENDCASE.
      lv_pos = lv_off + lv_chunk + 4.
    ENDWHILE.
    IF lv_depth <> 8 OR lv_interlace <> 0 OR ( lv_ctype <> 4 AND lv_ctype <> 6 )
        OR xstrlen( lv_idat ) < 7 OR lv_width <= 0 OR lv_height <= 0.
      RETURN.
    ENDIF.

    "zlib stream -> raw deflate -> filtered scanlines.
    lv_len = xstrlen( lv_idat ) - 6.
    lv_raw = lv_idat+2(lv_len).
    TRY.
        cl_abap_gzip=>decompress_binary( EXPORTING gzip_in = lv_raw IMPORTING raw_out = lv_plain ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
    lv_bpp = COND #( WHEN lv_ctype = 6 THEN 4 ELSE 2 ).
    lv_stride = lv_width * lv_bpp.
    IF xstrlen( lv_plain ) < lv_height * ( lv_stride + 1 ).
      RETURN.
    ENDIF.

    DO 256 TIMES.
      lv_byte = sy-index - 1.
      lv_hex = lv_byte.
      APPEND lv_hex TO lt_hex.
    ENDDO.
    DO lv_stride TIMES.
      APPEND 0 TO lt_prev.
    ENDDO.
    lt_cur = lt_prev.

    lv_pos = 0.
    DO lv_height TIMES.
      lv_row = sy-index.
      lv_byte = lv_plain+lv_pos(1).
      lv_filter = lv_byte.
      lv_pos = lv_pos + 1.
      CLEAR: lv_color_row, lv_alpha_row.
      lv_i = 1.
      WHILE lv_i <= lv_stride.
        lv_byte = lv_plain+lv_pos(1).
        lv_x = lv_byte.
        lv_pos = lv_pos + 1.
        IF lv_i > lv_bpp.
          READ TABLE lt_cur INTO lv_a INDEX lv_i - lv_bpp.
          READ TABLE lt_prev INTO lv_c INDEX lv_i - lv_bpp.
        ELSE.
          lv_a = 0.
          lv_c = 0.
        ENDIF.
        READ TABLE lt_prev INTO lv_b INDEX lv_i.
        CASE lv_filter.
          WHEN 1.
            lv_v = lv_x + lv_a.
          WHEN 2.
            lv_v = lv_x + lv_b.
          WHEN 3.
            lv_v = lv_x + ( lv_a + lv_b ) DIV 2.
          WHEN 4.
            lv_p = lv_a + lv_b - lv_c.
            lv_pa = abs( lv_p - lv_a ).
            lv_pb = abs( lv_p - lv_b ).
            lv_pc = abs( lv_p - lv_c ).
            IF lv_pa <= lv_pb AND lv_pa <= lv_pc.
              lv_v = lv_x + lv_a.
            ELSEIF lv_pb <= lv_pc.
              lv_v = lv_x + lv_b.
            ELSE.
              lv_v = lv_x + lv_c.
            ENDIF.
          WHEN OTHERS.
            lv_v = lv_x.
        ENDCASE.
        lv_v = lv_v MOD 256.
        MODIFY lt_cur FROM lv_v INDEX lv_i.
        READ TABLE lt_hex INTO lv_hex INDEX lv_v + 1.
        IF lv_i MOD lv_bpp = 0.
          lv_alpha_row = lv_alpha_row && lv_hex.
        ELSE.
          lv_color_row = lv_color_row && lv_hex.
        ENDIF.
        lv_i = lv_i + 1.
      ENDWHILE.
      APPEND lv_color_row TO lt_color.
      APPEND lv_alpha_row TO lt_alpha.
      lt_prev = lt_cur.
    ENDDO.
    CONCATENATE LINES OF lt_color INTO lv_hex.
    lv_color = lv_hex.
    CONCATENATE LINES OF lt_alpha INTO lv_hex.
    lv_alpha = lv_hex.

    "Soft mask (alpha) image first, the colour image refers to its object number.
    lv_zip = zcl_pdf_studio_conv=>deflate( lv_alpha ).
    IF lv_zip IS NOT INITIAL.
      lv_alpha = lv_zip.
      lv_filter_txt = ` /Filter /FlateDecode`.
    ENDIF.
    ls_mask-src = |{ cs_image-src }#mask|.
    ls_mask-name = |Im{ lines( mt_images ) + 1 }|.
    ls_mask-width = lv_width.
    ls_mask-height = lv_height.
    ls_mask-data = lv_alpha.
    ls_mask-dict = |/Type /XObject /Subtype /Image /Width { lv_width } /Height { lv_height } | &&
                   |/ColorSpace /DeviceGray /BitsPerComponent 8{ lv_filter_txt }|.
    APPEND ls_mask TO mt_images.

    CLEAR lv_filter_txt.
    lv_zip = zcl_pdf_studio_conv=>deflate( lv_color ).
    IF lv_zip IS NOT INITIAL.
      lv_color = lv_zip.
      lv_filter_txt = ` /Filter /FlateDecode`.
    ENDIF.
    lv_space = COND #( WHEN lv_ctype = 6 THEN `/DeviceRGB` ELSE `/DeviceGray` ).
    cs_image-width = lv_width.
    cs_image-height = lv_height.
    cs_image-data = lv_color.
    cs_image-dict = |/Type /XObject /Subtype /Image /Width { lv_width } /Height { lv_height } | &&
                    |/ColorSpace { lv_space } /BitsPerComponent 8{ lv_filter_txt } /SMask { 15 + lines( mt_images ) } 0 R|.
  ENDMETHOD.

  METHOD parse_png.
    DATA lv_len TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_chunk TYPE i.
    DATA lv_type TYPE xstring.
    DATA lv_part TYPE xstring.
    DATA lv_idat TYPE xstring.
    DATA lv_palette TYPE xstring.
    DATA lv_depth TYPE i.
    DATA lv_ctype TYPE i.
    DATA lv_interlace TYPE i.
    DATA lv_colors TYPE i.
    DATA lv_space TYPE string.
    DATA lv_off TYPE i.
    DATA lv_hex TYPE string.

    lv_len = xstrlen( iv_data ).
    IF lv_len < 33 OR iv_data(8) <> '89504E470D0A1A0A'.
      RETURN.
    ENDIF.
    lv_pos = 8.
    WHILE lv_pos + 8 <= lv_len.
      lv_chunk = bytes_int( iv_data = iv_data iv_off = lv_pos iv_len = 4 ).
      lv_off = lv_pos + 4.
      lv_type = iv_data+lv_off(4).
      lv_off = lv_pos + 8.
      IF lv_chunk < 0 OR lv_off + lv_chunk > lv_len.
        RETURN.
      ENDIF.
      CLEAR lv_part.
      IF lv_chunk > 0.
        lv_part = iv_data+lv_off(lv_chunk).
      ENDIF.
      CASE lv_type.
        WHEN '49484452'.
          cs_image-width = bytes_int( iv_data = lv_part iv_off = 0 iv_len = 4 ).
          cs_image-height = bytes_int( iv_data = lv_part iv_off = 4 iv_len = 4 ).
          lv_depth = bytes_int( iv_data = lv_part iv_off = 8 iv_len = 1 ).
          lv_ctype = bytes_int( iv_data = lv_part iv_off = 9 iv_len = 1 ).
          lv_interlace = bytes_int( iv_data = lv_part iv_off = 12 iv_len = 1 ).
        WHEN '504C5445'.
          lv_palette = lv_part.
        WHEN '49444154'.
          CONCATENATE lv_idat lv_part INTO lv_idat IN BYTE MODE.
        WHEN '49454E44'.
          EXIT.
      ENDCASE.
      lv_pos = lv_off + lv_chunk + 4.
    ENDWHILE.

    "Only opaque, non-interlaced PNG can be passed through unchanged.
    IF lv_interlace <> 0 OR lv_idat IS INITIAL.
      RETURN.
    ENDIF.
    CASE lv_ctype.
      WHEN 0.
        lv_colors = 1.
        lv_space = `/DeviceGray`.
      WHEN 2.
        lv_colors = 3.
        lv_space = `/DeviceRGB`.
      WHEN 3.
        IF lv_palette IS INITIAL.
          RETURN.
        ENDIF.
        lv_colors = 1.
        lv_hex = lv_palette.
        lv_space = |[/Indexed /DeviceRGB { xstrlen( lv_palette ) / 3 - 1 } <{ lv_hex }>]|.
      WHEN OTHERS.
        RETURN.
    ENDCASE.
    cs_image-data = lv_idat.
    cs_image-dict = |/Type /XObject /Subtype /Image /Width { cs_image-width } /Height { cs_image-height } | &&
                    |/ColorSpace { lv_space } /BitsPerComponent { lv_depth } /Filter /FlateDecode | &&
                    |/DecodeParms << /Predictor 15 /Colors { lv_colors } /BitsPerComponent { lv_depth } | &&
                    |/Columns { cs_image-width } >>|.
  ENDMETHOD.

  METHOD layout_flow.
    DATA lt_frames TYPE ty_frames.
    DATA ls_frame TYPE ty_frame.
    DATA ls_top TYPE ty_frame.
    DATA ls_token TYPE ty_token.
    DATA ls_box TYPE ty_box.
    DATA ls_rule TYPE ty_rule.
    DATA ls_root TYPE ty_style.
    DATA lt_pieces TYPE ty_pieces.
    DATA lv_index TYPE i.
    DATA lv_width TYPE f.
    DATA ls_dummy TYPE ty_box.
    DATA lv_pos TYPE i.
    DATA lv_skip TYPE i.
    DATA ls_inner TYPE ty_token.
    DATA lt_inner TYPE ty_tokens.
    DATA lv_from TYPE i.
    DATA lv_to TYPE i.

    ls_root = base_style( ).
    "Unstyled HTML uses the browser default serif face, as Chromium does.
    ls_root-family = 'T'.
    LOOP AT mt_rules INTO ls_rule WHERE tag = 'html' OR tag = 'body'.
      apply_decls(
        EXPORTING iv_decls = ls_rule-decls iv_base = ls_root-size
        CHANGING  cs_style = ls_root cs_box = ls_dummy ).
    ENDLOOP.
    ls_frame-name = `#root`.
    ls_frame-style = ls_root.
    APPEND ls_frame TO lt_frames.
    mv_align = ls_root-align.
    mv_pending = 0.
    new_page( ).
    mv_y = mv_mt.
    mv_gap = 0.
    lv_width = mv_pw - mv_ml - mv_mr.

    LOOP AT it_tokens INTO ls_token.
      lv_pos = lv_pos + 1.
      IF lv_pos <= lv_skip.
        CONTINUE.
      ENDIF.
      READ TABLE lt_frames INTO ls_top INDEX lines( lt_frames ).
      IF ls_token-kind = 'O' AND ls_token-name = 'table'.
        flush_block( CHANGING ct_pieces = lt_pieces ).
        lv_skip = table_end( it_tokens = it_tokens iv_start = lv_pos ).
        CLEAR lt_inner.
        lv_from = lv_pos + 1.
        lv_to = lv_skip - 1.
        LOOP AT it_tokens INTO ls_inner FROM lv_from TO lv_to.
          APPEND ls_inner TO lt_inner.
        ENDLOOP.
        layout_table( it_tokens = lt_inner iv_attrs = ls_token-attrs is_parent = ls_top-style
                      iv_x = mv_ml iv_width = lv_width ).
        CONTINUE.
      ENDIF.
      CASE ls_token-kind.
        WHEN 'T'.
          add_text( EXPORTING iv_text = decode( ls_token-text ) is_style = ls_top-style
                    CHANGING ct_pieces = lt_pieces ).
        WHEN 'O' OR 'S'.
          CASE ls_token-name.
            WHEN 'br'.
              add_break( EXPORTING is_style = ls_top-style CHANGING ct_pieces = lt_pieces ).
              CONTINUE.
            WHEN 'img'.
              flush_block( CHANGING ct_pieces = lt_pieces ).
              flow_image( iv_attrs = ls_token-attrs iv_align = ls_top-style-align ).
              CONTINUE.
            WHEN 'hr'.
              flush_block( CHANGING ct_pieces = lt_pieces ).
              mv_y = mv_y + nmax( val1 = mv_gap val2 = 6 ).
              mv_gap = 6.
              emit( |0.6 0.6 0.6 rg { num( mv_ml ) } { num( mv_ph - mv_y ) } { num( lv_width ) } 0.75 re f| ).
              CONTINUE.
          ENDCASE.
          tag_style(
            EXPORTING iv_name = ls_token-name iv_attrs = ls_token-attrs is_parent = ls_top-style
            IMPORTING es_style = ls_frame-style es_box = ls_box ).
          IF is_block( ls_token-name ) = abap_true.
            flush_block( CHANGING ct_pieces = lt_pieces ).
            mv_gap = nmax( val1 = mv_gap val2 = ls_box-mt ).
            mv_align = ls_frame-style-align.
            IF ls_token-name = 'li'.
              add_text( EXPORTING iv_text = |{ cl_abap_conv_in_ce=>uccpi( 8226 ) }| is_style = ls_frame-style
                        CHANGING ct_pieces = lt_pieces ).
              mv_pending = 1.
            ENDIF.
          ENDIF.
          IF ls_token-kind = 'O'.
            ls_frame-name = ls_token-name.
            ls_frame-mb = ls_box-mb.
            APPEND ls_frame TO lt_frames.
          ENDIF.
        WHEN 'C'.
          IF ls_token-name = 'td' OR ls_token-name = 'th'.
            mv_pending = mv_pending + 2.
          ENDIF.
          IF is_block( ls_token-name ) = abap_true.
            flush_block( CHANGING ct_pieces = lt_pieces ).
          ENDIF.
          lv_index = lines( lt_frames ).
          WHILE lv_index > 1.
            READ TABLE lt_frames INTO ls_frame INDEX lv_index.
            IF ls_frame-name = ls_token-name.
              IF is_block( ls_token-name ) = abap_true.
                mv_gap = nmax( val1 = mv_gap val2 = ls_frame-mb ).
              ENDIF.
              DELETE lt_frames FROM lv_index.
              EXIT.
            ENDIF.
            lv_index = lv_index - 1.
          ENDWHILE.
          IF is_block( ls_token-name ) = abap_true.
            READ TABLE lt_frames INTO ls_top INDEX lines( lt_frames ).
            mv_align = ls_top-style-align.
          ENDIF.
      ENDCASE.
    ENDLOOP.
    flush_block( CHANGING ct_pieces = lt_pieces ).
  ENDMETHOD.

  METHOD flush_block.
    DATA lt_lines TYPE ty_lines.
    DATA ls_line TYPE ty_line.
    DATA lv_width TYPE f.
    DATA lv_height TYPE f.
    DATA lv_top TYPE f.

    IF ct_pieces IS INITIAL.
      RETURN.
    ENDIF.
    lv_width = mv_pw - mv_ml - mv_mr.
    lt_lines = wrap( it_pieces = ct_pieces iv_width = lv_width ).
    LOOP AT lt_lines INTO ls_line.
      lv_height = line_height( ls_line ).
      IF mv_y > mv_mt.
        lv_top = mv_y + mv_gap.
      ELSE.
        lv_top = mv_y.
      ENDIF.
      IF lv_top + lv_height > mv_ph - mv_mb AND mv_y > mv_mt.
        new_page( ).
        mv_y = mv_mt.
        lv_top = mv_y.
      ENDIF.
      mv_gap = 0.
      draw_line( is_line = ls_line iv_x = mv_ml iv_width = lv_width iv_top = lv_top iv_align = mv_align ).
      mv_y = lv_top + lv_height.
    ENDLOOP.
    CLEAR ct_pieces.
    mv_pending = 0.
  ENDMETHOD.

  METHOD flow_image.
    DATA lv_src TYPE string.
    DATA lv_name TYPE string.
    DATA lv_iw TYPE i.
    DATA lv_ih TYPE i.
    DATA lv_w TYPE f.
    DATA lv_h TYPE f.
    DATA lv_max TYPE f.
    DATA lv_top TYPE f.
    DATA lv_x TYPE f.
    DATA ls_box TYPE ty_box.
    DATA ls_style TYPE ty_style.
    DATA lv_value TYPE string.

    lv_src = decode( attr( iv_attrs = iv_attrs iv_name = `src` ) ).
    lv_name = load_image(
      EXPORTING iv_src = lv_src
      IMPORTING ev_width = lv_iw ev_height = lv_ih ).
    IF lv_name IS INITIAL OR lv_iw <= 0 OR lv_ih <= 0.
      RETURN.
    ENDIF.
    ls_style = base_style( ).
    apply_decls(
      EXPORTING iv_decls = attr( iv_attrs = iv_attrs iv_name = `style` ) iv_base = ls_style-size
      CHANGING  cs_style = ls_style cs_box = ls_box ).
    lv_w = ls_box-w.
    lv_h = ls_box-h.
    lv_value = attr( iv_attrs = iv_attrs iv_name = `width` ).
    IF lv_w <= 0 AND lv_value IS NOT INITIAL.
      lv_w = length_pt( iv_value = lv_value iv_base = 12 ).
    ENDIF.
    lv_value = attr( iv_attrs = iv_attrs iv_name = `height` ).
    IF lv_h <= 0 AND lv_value IS NOT INITIAL.
      lv_h = length_pt( iv_value = lv_value iv_base = 12 ).
    ENDIF.
    IF lv_w <= 0 AND lv_h <= 0.
      lv_w = lv_iw * '0.75'.
      lv_h = lv_ih * '0.75'.
    ELSEIF lv_w <= 0.
      lv_w = lv_h * lv_iw / lv_ih.
    ELSEIF lv_h <= 0.
      lv_h = lv_w * lv_ih / lv_iw.
    ENDIF.
    lv_max = mv_pw - mv_ml - mv_mr.
    IF lv_w > lv_max.
      lv_h = lv_h * lv_max / lv_w.
      lv_w = lv_max.
    ENDIF.
    IF mv_y > mv_mt.
      lv_top = mv_y + mv_gap.
    ELSE.
      lv_top = mv_y.
    ENDIF.
    IF lv_top + lv_h > mv_ph - mv_mb AND mv_y > mv_mt.
      new_page( ).
      mv_y = mv_mt.
      lv_top = mv_y.
    ENDIF.
    CASE iv_align.
      WHEN 'center'.
        lv_x = mv_ml + ( lv_max - lv_w ) / 2.
      WHEN 'right'.
        lv_x = mv_ml + lv_max - lv_w.
      WHEN OTHERS.
        lv_x = mv_ml.
    ENDCASE.
    draw_image( iv_src = lv_src iv_x = lv_x iv_top = lv_top iv_w = lv_w iv_h = lv_h iv_fit = `fill` ).
    mv_y = lv_top + lv_h.
    mv_gap = 0.
  ENDMETHOD.

  METHOD margin_text.
    DATA lt_tokens TYPE ty_tokens.
    DATA lt_pieces TYPE ty_pieces.
    DATA lt_lines TYPE ty_lines.
    DATA ls_line TYPE ty_line.
    DATA ls_style TYPE ty_style.
    DATA lv_align TYPE string.
    DATA lv_height TYPE f.
    DATA lv_top TYPE f.
    DATA lv_width TYPE f.

    lt_tokens = tokenize( iv_fragment ).
    ls_style = base_style( ).
    ls_style-size = 9.
    lt_pieces = collect(
      EXPORTING it_tokens = lt_tokens is_style = ls_style iv_page = iv_page iv_total = iv_total
      IMPORTING ev_align = lv_align ).
    lv_width = mv_pw - mv_ml - mv_mr.
    lt_lines = wrap( it_pieces = lt_pieces iv_width = lv_width ).
    DELETE lt_lines WHERE pieces IS INITIAL.
    IF lt_lines IS INITIAL.
      RETURN.
    ENDIF.
    LOOP AT lt_lines INTO ls_line.
      lv_height = lv_height + line_height( ls_line ).
    ENDLOOP.
    IF iv_top = abap_true.
      lv_top = ( mv_mt - lv_height ) / 2.
    ELSE.
      lv_top = mv_ph - mv_mb + ( mv_mb - lv_height ) / 2.
    ENDIF.
    IF lv_top < 0.
      lv_top = 0.
    ENDIF.
    draw_lines( it_lines = lt_lines iv_x = mv_ml iv_width = lv_width iv_top = lv_top iv_align = lv_align ).
  ENDMETHOD.

  METHOD assemble.
    DATA lt_offsets TYPE ty_ints.
    DATA lv_nl TYPE string.
    DATA lv_text TYPE string.
    DATA lv_part TYPE xstring.
    DATA lv_stream TYPE xstring.
    DATA lv_fonts TYPE string.
    DATA lv_xobjects TYPE string.
    DATA lv_kids TYPE string.
    DATA lv_pages TYPE i.
    DATA lv_images TYPE i.
    DATA lv_first_page TYPE i.
    DATA lv_count TYPE i.
    DATA lv_obj TYPE i.
    DATA lv_index TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_xref TYPE i.
    DATA lv_n10 TYPE n LENGTH 10.
    DATA ls_image TYPE ty_image.
    DATA lv_content TYPE string.
    DATA lt_names TYPE ty_strings.
    DATA lv_name TYPE string.
    DATA lv_read TYPE i.
    DATA lv_binary TYPE x LENGTH 5 VALUE 'E2E3CFD30A'.
    DATA lt_extra TYPE zcl_pdf_studio_font=>ty_objs.
    DATA ls_extra TYPE zcl_pdf_studio_font=>ty_obj.
    DATA lv_extra_at TYPE i.
    DATA ls_font TYPE ty_font.
    DATA lt_fobjs TYPE zcl_pdf_studio_font=>ty_objs.
    DATA ls_fobj TYPE zcl_pdf_studio_font=>ty_obj.
    DATA lv_font_obj TYPE i.
    DATA lv_custom TYPE string.
    DATA lv_tagno TYPE i.
    DATA lv_info TYPE string.
    DATA lv_zip TYPE xstring.
    DATA lv_gstates TYPE string.
    DATA lv_encoding TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_pages = lines( mt_pages ).
    lv_images = lines( mt_images ).
    "Embedded fonts come after the images.
    lv_extra_at = 16 + lv_images.
    "Uploaded TrueType fonts that were used: five objects each (subset font file).
    LOOP AT mt_fonts INTO ls_font WHERE font IS BOUND.
      IF ls_font-font->is_used( ) = abap_false.
        CONTINUE.
      ENDIF.
      lv_font_obj = lv_extra_at + lines( lt_extra ).
      lt_fobjs = ls_font-font->objects( iv_first = lv_font_obj
                                       iv_tag   = |ZPDFS{ substring( val = sy-abcde off = lv_tagno MOD 26 len = 1 ) }| ).
      lv_tagno = lv_tagno + 1.
      LOOP AT lt_fobjs INTO ls_fobj.
        CLEAR ls_extra.
        ls_extra-text = ls_fobj-text.
        ls_extra-stream = ls_fobj-stream.
        APPEND ls_extra TO lt_extra.
      ENDLOOP.
      lv_custom = |{ lv_custom }/F{ ls_font-slot } { lv_font_obj } 0 R |.
    ENDLOOP.
    lv_first_page = 16 + lv_images + lines( lt_extra ).
    lv_count = lv_first_page + 2 * lv_pages - 1.
    lv_gstates = gstates( ).
    "Standard fonts: WinAnsi, with the Icelandic letters replaced by the six Turkish letters.
    lv_encoding = `<< /Type /Encoding /BaseEncoding /WinAnsiEncoding ` &&
                  `/Differences [208 /Gbreve 221 /Idotaccent 222 /Scedilla 240 /gbreve 253 /dotlessi 254 /scedilla] >>`.

    lt_names = VALUE #( ( `Helvetica` ) ( `Helvetica-Bold` ) ( `Helvetica-Oblique` ) ( `Helvetica-BoldOblique` )
                        ( `Times-Roman` ) ( `Times-Bold` ) ( `Times-Italic` ) ( `Times-BoldItalic` )
                        ( `Courier` ) ( `Courier-Bold` ) ( `Courier-Oblique` ) ( `Courier-BoldOblique` ) ).

    rv_pdf = zcl_pdf_studio_conv=>string_to_xstring( |%PDF-1.4{ lv_nl }%| ).
    CONCATENATE rv_pdf lv_binary INTO rv_pdf IN BYTE MODE.

    DO lv_count TIMES.
      lv_obj = sy-index.
      CLEAR: lv_text, lv_stream.
      CASE lv_obj.
        WHEN 1.
          lv_text = `<< /Type /Catalog /Pages 2 0 R >>`.
        WHEN 2.
          CLEAR lv_kids.
          DO lv_pages TIMES.
            lv_kids = |{ lv_kids }{ lv_first_page + 2 * ( sy-index - 1 ) } 0 R |.
          ENDDO.
          lv_text = |<< /Type /Pages /Kids [ { lv_kids }] /Count { lv_pages } >>|.
        WHEN OTHERS.
          IF lv_obj <= 14.
            lv_read = lv_obj - 2.
            READ TABLE lt_names INTO lv_name INDEX lv_read.
            lv_text = |<< /Type /Font /Subtype /Type1 /BaseFont /{ lv_name } /Encoding { lv_encoding } >>|.
          ELSEIF lv_obj = 15.
            CLEAR lv_fonts.
            DO 12 TIMES.
              lv_fonts = |{ lv_fonts }/F{ sy-index } { sy-index + 2 } 0 R |.
            ENDDO.
            lv_fonts = lv_fonts && lv_custom.
            CLEAR lv_xobjects.
            LOOP AT mt_images INTO ls_image.
              lv_xobjects = |{ lv_xobjects }/{ ls_image-name } { 15 + sy-tabix } 0 R |.
            ENDLOOP.
            lv_text = |<< /ProcSet [/PDF /Text /ImageB /ImageC /ImageI] /Font << { lv_fonts }>>|.
            IF lv_xobjects IS NOT INITIAL.
              lv_text = |{ lv_text } /XObject << { lv_xobjects }>>|.
            ENDIF.
            IF lv_gstates IS NOT INITIAL.
              lv_text = |{ lv_text } /ExtGState << { lv_gstates }>>|.
            ENDIF.
            lv_text = |{ lv_text } >>|.
          ELSEIF lv_obj < lv_extra_at.
            lv_read = lv_obj - 15.
            READ TABLE mt_images INTO ls_image INDEX lv_read.
            lv_stream = ls_image-data.
            lv_text = |<< { ls_image-dict } /Length { xstrlen( lv_stream ) } >>|.
          ELSEIF lv_obj < lv_first_page.
            lv_read = lv_obj - lv_extra_at + 1.
            READ TABLE lt_extra INTO ls_extra INDEX lv_read.
            lv_text = ls_extra-text.
            lv_stream = ls_extra-stream.
          ELSE.
            lv_index = ( lv_obj - lv_first_page ) DIV 2 + 1.
            IF ( lv_obj - lv_first_page ) MOD 2 = 0.
              lv_text = |<< /Type /Page /Parent 2 0 R /MediaBox [0 0 { num( mv_pw ) } { num( mv_ph ) }] | &&
                        |/Resources 15 0 R /Contents { lv_obj + 1 } 0 R >>|.
            ELSE.
              READ TABLE mt_pages INTO lv_content INDEX lv_index.
              lv_stream = zcl_pdf_studio_conv=>string_to_xstring( lv_content ).
              lv_zip = zcl_pdf_studio_conv=>deflate( lv_stream ).
              IF lv_zip IS NOT INITIAL AND xstrlen( lv_zip ) < xstrlen( lv_stream ).
                lv_stream = lv_zip.
                lv_text = |<< /Length { xstrlen( lv_stream ) } /Filter /FlateDecode >>|.
              ELSE.
                lv_text = |<< /Length { xstrlen( lv_stream ) } >>|.
              ENDIF.
            ENDIF.
          ENDIF.
      ENDCASE.

      lv_offset = xstrlen( rv_pdf ).
      APPEND lv_offset TO lt_offsets.
      lv_part = zcl_pdf_studio_conv=>string_to_xstring( |{ lv_obj } 0 obj{ lv_nl }{ lv_text }{ lv_nl }| ).
      CONCATENATE rv_pdf lv_part INTO rv_pdf IN BYTE MODE.
      IF lv_text CS '/Length'.
        lv_part = zcl_pdf_studio_conv=>string_to_xstring( |stream{ lv_nl }| ).
        CONCATENATE rv_pdf lv_part lv_stream INTO rv_pdf IN BYTE MODE.
        lv_part = zcl_pdf_studio_conv=>string_to_xstring( |{ lv_nl }endstream{ lv_nl }| ).
        CONCATENATE rv_pdf lv_part INTO rv_pdf IN BYTE MODE.
      ENDIF.
      lv_part = zcl_pdf_studio_conv=>string_to_xstring( |endobj{ lv_nl }| ).
      CONCATENATE rv_pdf lv_part INTO rv_pdf IN BYTE MODE.
    ENDDO.

    "Document information (title, author, ...), the last object.
    lv_count = lv_count + 1.
    lv_info = |<< /Producer { pdf_text( `ZPDF Studio` ) } /Creator { pdf_text( `ZPDF Studio (SAP ABAP)` ) }| &&
              | /CreationDate ({ pdf_date( ) })|.
    IF ms_info-title IS NOT INITIAL.
      lv_info = |{ lv_info } /Title { pdf_text( ms_info-title ) }|.
    ENDIF.
    IF ms_info-author IS NOT INITIAL.
      lv_info = |{ lv_info } /Author { pdf_text( ms_info-author ) }|.
    ENDIF.
    IF ms_info-subject IS NOT INITIAL.
      lv_info = |{ lv_info } /Subject { pdf_text( ms_info-subject ) }|.
    ENDIF.
    IF ms_info-keywords IS NOT INITIAL.
      lv_info = |{ lv_info } /Keywords { pdf_text( ms_info-keywords ) }|.
    ENDIF.
    lv_info = lv_info && ` >>`.
    lv_offset = xstrlen( rv_pdf ).
    APPEND lv_offset TO lt_offsets.
    lv_part = zcl_pdf_studio_conv=>string_to_xstring( |{ lv_count } 0 obj{ lv_nl }{ lv_info }{ lv_nl }endobj{ lv_nl }| ).
    CONCATENATE rv_pdf lv_part INTO rv_pdf IN BYTE MODE.

    lv_xref = xstrlen( rv_pdf ).
    lv_text = |xref{ lv_nl }0 { lv_count + 1 }{ lv_nl }0000000000 65535 f { lv_nl }|.
    LOOP AT lt_offsets INTO lv_offset.
      lv_n10 = lv_offset.
      lv_text = |{ lv_text }{ lv_n10 } 00000 n { lv_nl }|.
    ENDLOOP.
    lv_text = |{ lv_text }trailer{ lv_nl }<< /Size { lv_count + 1 } /Root 1 0 R /Info { lv_count } 0 R >>{ lv_nl }| &&
              |startxref{ lv_nl }{ lv_xref }{ lv_nl }%%EOF{ lv_nl }|.
    lv_part = zcl_pdf_studio_conv=>string_to_xstring( lv_text ).
    CONCATENATE rv_pdf lv_part INTO rv_pdf IN BYTE MODE.
  ENDMETHOD.

  METHOD table_end.
    DATA ls_token TYPE ty_token.
    DATA lv_depth TYPE i.
    DATA lv_index TYPE i.

    rv_end = lines( it_tokens ).
    lv_index = iv_start.
    WHILE lv_index <= lines( it_tokens ).
      READ TABLE it_tokens INTO ls_token INDEX lv_index.
      IF ls_token-name = 'table'.
        IF ls_token-kind = 'O'.
          lv_depth = lv_depth + 1.
        ELSEIF ls_token-kind = 'C'.
          lv_depth = lv_depth - 1.
          IF lv_depth = 0.
            rv_end = lv_index.
            RETURN.
          ENDIF.
        ENDIF.
      ENDIF.
      lv_index = lv_index + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD raw_prop.
    DATA lt_decls TYPE ty_strings.
    DATA lv_decl TYPE string.
    DATA lv_name TYPE string.
    DATA lv_colon TYPE i.
    DATA ls_rule TYPE ty_rule.
    DATA lv_all TYPE string.

    LOOP AT mt_rules INTO ls_rule WHERE tag = iv_tag.
      lv_all = |{ lv_all };{ ls_rule-decls }|.
    ENDLOOP.
    lv_all = |{ lv_all };{ attr( iv_attrs = iv_attrs iv_name = `style` ) }|.
    SPLIT lv_all AT ';' INTO TABLE lt_decls.
    LOOP AT lt_decls INTO lv_decl.
      lv_colon = find( val = lv_decl sub = ':' ).
      IF lv_colon <= 0.
        CONTINUE.
      ENDIF.
      lv_name = to_lower( substring( val = lv_decl len = lv_colon ) ).
      CONDENSE lv_name NO-GAPS.
      IF lv_name = iv_prop.
        rv_value = substring( val = lv_decl off = lv_colon + 1 ).
        REPLACE ALL OCCURRENCES OF '!important' IN rv_value WITH ``.
        CONDENSE rv_value.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD edge_line.
    DATA lv_half TYPE f.
    DATA lv_dash TYPE string.

    IF iv_b <= 0 OR iv_color IS INITIAL.
      RETURN.
    ENDIF.
    lv_half = iv_b / 2.
    IF iv_style = `dashed` OR iv_style = `dotted`.
      IF iv_style = `dashed`.
        lv_dash = |[{ num( iv_b * 3 ) } { num( iv_b * 2 ) }] 0 d|.
      ELSE.
        lv_dash = |1 J [0 { num( iv_b * 2 ) }] 0 d|.
      ENDIF.
      emit( |q { iv_color } RG { num( iv_b ) } w { lv_dash } { num( iv_x1 ) } { num( iv_y1 ) } m { num( iv_x2 ) } { num( iv_y2 ) } l S Q| ).
      RETURN.
    ENDIF.
    IF iv_y1 = iv_y2.
      emit( |{ iv_color } rg { num( iv_x1 - lv_half ) } { num( iv_y1 - lv_half ) } { num( iv_x2 - iv_x1 + iv_b ) } { num( iv_b ) } re f| ).
    ELSE.
      emit( |{ iv_color } rg { num( iv_x1 - lv_half ) } { num( iv_y1 - lv_half ) } { num( iv_b ) } { num( iv_y2 - iv_y1 + iv_b ) } re f| ).
    ENDIF.
  ENDMETHOD.

  METHOD draw_edges.
    DATA lv_b TYPE f.
    DATA lv_half TYPE f.
    DATA lv_top TYPE f.
    DATA lv_bottom TYPE f.

    lv_b = is_box-border.
    IF lv_b <= 0 OR is_box-no_edge = abap_true.
      RETURN.
    ENDIF.
    IF is_box-per_edge = abap_true.
      lv_top = mv_ph - iv_top.
      lv_bottom = mv_ph - iv_top - iv_h.
      edge_line( iv_color = is_box-e_top iv_style = is_box-s_top iv_b = is_box-w_top
                 iv_x1 = iv_x iv_y1 = lv_top iv_x2 = iv_x + iv_w iv_y2 = lv_top ).
      edge_line( iv_color = is_box-e_bot iv_style = is_box-s_bot iv_b = is_box-w_bot
                 iv_x1 = iv_x iv_y1 = lv_bottom iv_x2 = iv_x + iv_w iv_y2 = lv_bottom ).
      edge_line( iv_color = is_box-e_left iv_style = is_box-s_left iv_b = is_box-w_left
                 iv_x1 = iv_x iv_y1 = lv_bottom iv_x2 = iv_x iv_y2 = lv_top ).
      edge_line( iv_color = is_box-e_right iv_style = is_box-s_right iv_b = is_box-w_right
                 iv_x1 = iv_x + iv_w iv_y1 = lv_bottom iv_x2 = iv_x + iv_w iv_y2 = lv_top ).
      RETURN.
    ENDIF.
    lv_half = lv_b / 2.
    lv_top = mv_ph - iv_top.
    lv_bottom = mv_ph - iv_top - iv_h.
    IF is_box-e_top IS NOT INITIAL.
      emit( |{ is_box-e_top } rg { num( iv_x - lv_half ) } { num( lv_top - lv_half ) } { num( iv_w + lv_b ) } { num( lv_b ) } re f| ).
    ENDIF.
    IF is_box-e_bot IS NOT INITIAL.
      emit( |{ is_box-e_bot } rg { num( iv_x - lv_half ) } { num( lv_bottom - lv_half ) } { num( iv_w + lv_b ) } { num( lv_b ) } re f| ).
    ENDIF.
    IF is_box-e_left IS NOT INITIAL.
      emit( |{ is_box-e_left } rg { num( iv_x - lv_half ) } { num( lv_bottom - lv_half ) } { num( lv_b ) } { num( iv_h + lv_b ) } re f| ).
    ENDIF.
    IF is_box-e_right IS NOT INITIAL.
      emit( |{ is_box-e_right } rg { num( iv_x + iv_w - lv_half ) } { num( lv_bottom - lv_half ) } { num( lv_b ) } { num( iv_h + lv_b ) } re f| ).
    ENDIF.
  ENDMETHOD.

  METHOD draw_table_rows.
    DATA ls_cell TYPE ty_tcell.
    DATA ls_row TYPE ty_trow.
    DATA lt_tops TYPE ty_floats.
    DATA lv_y TYPE f.
    DATA lv_index TYPE i.
    DATA lv_last TYPE i.
    DATA lv_x TYPE f.
    DATA lv_w TYPE f.
    DATA lv_h TYPE f.
    DATA lv_top TYPE f.
    DATA lv_value TYPE f.
    DATA lv_fill TYPE string.
    DATA lv_inset TYPE f.
    DATA lv_text_top TYPE f.
    DATA lv_rows TYPE i.

    lv_rows = lines( it_rows ).
    lv_y = iv_top.
    lv_index = iv_first.
    WHILE lv_index <= iv_last.
      APPEND lv_y TO lt_tops.
      READ TABLE it_rows INTO ls_row INDEX lv_index.
      lv_y = lv_y + ls_row-height.
      lv_index = lv_index + 1.
    ENDWHILE.

    LOOP AT it_cells INTO ls_cell WHERE row >= iv_first AND row <= iv_last.
      lv_index = ls_cell-row - iv_first + 1.
      READ TABLE lt_tops INTO lv_top INDEX lv_index.
      lv_last = nmin( val1 = ls_cell-row + ls_cell-rowspan - 1 val2 = lv_rows ).
      CLEAR lv_h.
      lv_index = ls_cell-row.
      WHILE lv_index <= lv_last.
        READ TABLE it_rows INTO ls_row INDEX lv_index.
        lv_h = lv_h + ls_row-height.
        lv_index = lv_index + 1.
      ENDWHILE.
      lv_index = ls_cell-col + 1.
      READ TABLE it_colx INTO lv_value INDEX lv_index.
      lv_x = iv_x + lv_value.
      CLEAR lv_w.
      DO ls_cell-colspan TIMES.
        lv_index = ls_cell-col + sy-index.
        READ TABLE it_colw INTO lv_value INDEX lv_index.
        IF sy-subrc = 0.
          lv_w = lv_w + lv_value.
        ENDIF.
      ENDDO.

      READ TABLE it_rows INTO ls_row INDEX ls_cell-row.
      lv_fill = ls_cell-box-fill.
      IF lv_fill IS INITIAL.
        lv_fill = ls_row-fill.
      ENDIF.
      IF lv_fill IS NOT INITIAL.
        emit( |{ lv_fill } rg { num( lv_x ) } { num( mv_ph - lv_top - lv_h ) } { num( lv_w ) } { num( lv_h ) } re f| ).
      ENDIF.

      lv_inset = ls_cell-box-pad + ls_cell-box-border / 2.
      CASE ls_cell-valign.
        WHEN 'top'.
          lv_text_top = lv_top + lv_inset.
        WHEN 'bottom'.
          lv_text_top = lv_top + lv_h - lv_inset - ls_cell-texth.
        WHEN OTHERS.
          lv_text_top = lv_top + ( lv_h - ls_cell-texth ) / 2.
      ENDCASE.
      IF ls_cell-lines IS NOT INITIAL.
        emit( |q { num( lv_x ) } { num( mv_ph - lv_top - lv_h ) } { num( lv_w ) } { num( lv_h ) } re W n| ).
        draw_lines( it_lines = ls_cell-lines iv_x = lv_x + lv_inset iv_width = lv_w - 2 * lv_inset
                    iv_top = lv_text_top iv_align = ls_cell-style-align ).
        emit( `Q` ).
      ENDIF.
      draw_edges( is_box = ls_cell-box iv_x = lv_x iv_top = lv_top iv_w = lv_w iv_h = lv_h ).
    ENDLOOP.
  ENDMETHOD.

  METHOD layout_table.
    DATA ls_tstyle TYPE ty_style.
    DATA ls_tbox TYPE ty_box.
    DATA ls_rstyle TYPE ty_style.
    DATA ls_rbox TYPE ty_box.
    DATA lt_rowstyles TYPE STANDARD TABLE OF ty_style WITH EMPTY KEY.
    DATA lt_cells TYPE ty_tcells.
    DATA ls_cell TYPE ty_tcell.
    DATA lt_rows TYPE ty_trows.
    DATA ls_row TYPE ty_trow.
    DATA lt_occ TYPE HASHED TABLE OF i WITH UNIQUE KEY table_line.
    DATA ls_token TYPE ty_token.
    DATA lv_part TYPE c LENGTH 1 VALUE 'B'.
    DATA lv_in_cell TYPE abap_bool.
    DATA lv_nest TYPE i.
    DATA lv_row TYPE i.
    DATA lv_col TYPE i.
    DATA lv_r TYPE i.
    DATA lv_c TYPE i.
    DATA lv_key TYPE i.
    DATA lv_value TYPE string.
    DATA lv_def_border TYPE f.
    DATA lv_def_pad TYPE f.
    DATA lt_explicit TYPE ty_floats.
    DATA lt_colw TYPE ty_floats.
    DATA lt_colx TYPE ty_floats.
    DATA lt_mirror TYPE ty_floats.
    DATA lt_nat TYPE ty_floats.
    DATA lt_fixed TYPE ty_ints.
    DATA lv_ncol TYPE i.
    DATA lv_nrow TYPE i.
    DATA lv_w TYPE f.
    DATA lv_f TYPE f.
    DATA lv_sum TYPE f.
    DATA lv_sum_fixed TYPE f.
    DATA lv_sum_auto TYPE f.
    DATA lv_auto TYPE i.
    DATA lv_rest TYPE f.
    DATA lv_index TYPE i.
    DATA lt_pieces TYPE ty_pieces.
    DATA lt_lines TYPE ty_lines.
    DATA ls_line TYPE ty_line.
    DATA ls_piece TYPE ty_piece.
    DATA lv_align TYPE string.
    DATA lv_need TYPE f.
    DATA lv_inner TYPE f.
    DATA lv_last TYPE i.
    DATA lv_span_h TYPE f.
    DATA lv_first TYPE i.
    DATA lv_end TYPE i.
    DATA lv_y TYPE f.
    DATA lv_x TYPE f.
    DATA lv_gh TYPE f.
    DATA lv_head_first TYPE i.
    DATA lv_head_last TYPE i.
    DATA lv_head_h TYPE f.
    DATA lv_flag TYPE i.
    FIELD-SYMBOLS <ls_cell> TYPE ty_tcell.
    FIELD-SYMBOLS <ls_row> TYPE ty_trow.

    tag_style(
      EXPORTING iv_name = `table` iv_attrs = iv_attrs is_parent = is_parent
      IMPORTING es_style = ls_tstyle es_box = ls_tbox ).
    lv_value = attr( iv_attrs = iv_attrs iv_name = `border` ).
    IF lv_value CO '0123456789' AND lv_value IS NOT INITIAL AND strlen( lv_value ) < 4.
      lv_def_border = lv_value.
      lv_def_border = lv_def_border * '0.75'.
    ENDIF.
    lv_value = attr( iv_attrs = iv_attrs iv_name = `cellpadding` ).
    IF lv_value CO '0123456789' AND lv_value IS NOT INITIAL AND strlen( lv_value ) < 4.
      lv_def_pad = lv_value.
      lv_def_pad = lv_def_pad * '0.75'.
    ELSE.
      lv_def_pad = '0.75'.
    ENDIF.

    "1. Rows and cells, with the grid position of every cell.
    LOOP AT it_tokens INTO ls_token.
      IF lv_in_cell = abap_true.
        IF ls_token-name = 'table'.
          IF ls_token-kind = 'O'.
            lv_nest = lv_nest + 1.
          ELSEIF ls_token-kind = 'C'.
            lv_nest = lv_nest - 1.
          ENDIF.
          APPEND ls_token TO ls_cell-tokens.
          CONTINUE.
        ENDIF.
        IF lv_nest > 0.
          APPEND ls_token TO ls_cell-tokens.
          CONTINUE.
        ENDIF.
        IF ls_token-kind = 'C' AND ( ls_token-name = 'td' OR ls_token-name = 'th' ).
          APPEND ls_cell TO lt_cells.
          lv_in_cell = abap_false.
          CONTINUE.
        ENDIF.
        IF ( ls_token-kind = 'O' AND ( ls_token-name = 'td' OR ls_token-name = 'th' OR ls_token-name = 'tr'
              OR ls_token-name = 'thead' OR ls_token-name = 'tbody' OR ls_token-name = 'tfoot' ) )
            OR ( ls_token-kind = 'C' AND ( ls_token-name = 'tr' OR ls_token-name = 'thead'
              OR ls_token-name = 'tbody' OR ls_token-name = 'tfoot' ) ).
          APPEND ls_cell TO lt_cells.
          lv_in_cell = abap_false.
        ELSE.
          APPEND ls_token TO ls_cell-tokens.
          CONTINUE.
        ENDIF.
      ENDIF.

      CASE ls_token-kind.
        WHEN 'O' OR 'S'.
          CASE ls_token-name.
            WHEN 'thead'.
              lv_part = 'H'.
            WHEN 'tfoot'.
              lv_part = 'F'.
            WHEN 'tbody'.
              lv_part = 'B'.
            WHEN 'col'.
              lv_value = attr( iv_attrs = ls_token-attrs iv_name = `width` ).
              IF lv_value IS INITIAL.
                lv_value = raw_prop( iv_tag = `col` iv_attrs = ls_token-attrs iv_prop = `width` ).
              ENDIF.
              lv_f = length_pt( iv_value = lv_value iv_base = ls_tstyle-size ).
              APPEND lv_f TO lt_explicit.
            WHEN 'tr' OR 'td' OR 'th'.
              IF ls_token-name = 'tr' OR lv_row = 0.
                lv_row = lv_row + 1.
                CLEAR ls_row.
                ls_row-part = lv_part.
                IF ls_token-name = 'tr'.
                  tag_style(
                    EXPORTING iv_name = `tr` iv_attrs = ls_token-attrs is_parent = ls_tstyle
                    IMPORTING es_style = ls_rstyle es_box = ls_rbox ).
                ELSE.
                  ls_rstyle = ls_tstyle.
                  CLEAR ls_rbox.
                ENDIF.
                ls_row-fill = ls_rbox-fill.
                ls_row-height = ls_rbox-h.
                APPEND ls_row TO lt_rows.
                APPEND ls_rstyle TO lt_rowstyles.
              ENDIF.
              IF ls_token-name = 'tr'.
                CONTINUE.
              ENDIF.
              CLEAR ls_cell.
              READ TABLE lt_rowstyles INTO ls_rstyle INDEX lv_row.
              tag_style(
                EXPORTING iv_name = ls_token-name iv_attrs = ls_token-attrs is_parent = ls_rstyle
                IMPORTING es_style = ls_cell-style es_box = ls_cell-box ).
              ls_cell-row = lv_row.
              ls_cell-head = boolc( ls_token-name = 'th' ).
              ls_cell-colspan = 1.
              ls_cell-rowspan = 1.
              lv_value = attr( iv_attrs = ls_token-attrs iv_name = `colspan` ).
              IF lv_value CO '0123456789' AND lv_value IS NOT INITIAL AND strlen( lv_value ) < 3.
                ls_cell-colspan = nmax( val1 = 1 val2 = CONV i( lv_value ) ).
              ENDIF.
              lv_value = attr( iv_attrs = ls_token-attrs iv_name = `rowspan` ).
              IF lv_value CO '0123456789' AND lv_value IS NOT INITIAL AND strlen( lv_value ) < 4.
                ls_cell-rowspan = nmax( val1 = 1 val2 = CONV i( lv_value ) ).
              ENDIF.
              lv_col = 0.
              DO.
                lv_key = lv_row * 1000 + lv_col.
                READ TABLE lt_occ TRANSPORTING NO FIELDS WITH TABLE KEY table_line = lv_key.
                IF sy-subrc <> 0.
                  EXIT.
                ENDIF.
                lv_col = lv_col + 1.
              ENDDO.
              ls_cell-col = lv_col.
              DO ls_cell-rowspan TIMES.
                lv_r = lv_row + sy-index - 1.
                DO ls_cell-colspan TIMES.
                  lv_c = lv_col + sy-index - 1.
                  lv_key = lv_r * 1000 + lv_c.
                  INSERT lv_key INTO TABLE lt_occ.
                ENDDO.
              ENDDO.
              IF ls_cell-head = abap_true
                  AND raw_prop( iv_tag = ls_token-name iv_attrs = ls_token-attrs iv_prop = `text-align` ) IS INITIAL
                  AND attr( iv_attrs = ls_token-attrs iv_name = `align` ) IS INITIAL.
                ls_cell-style-align = `center`.
              ENDIF.
              lv_value = raw_prop( iv_tag = ls_token-name iv_attrs = ls_token-attrs iv_prop = `width` ).
              IF lv_value IS INITIAL.
                lv_value = attr( iv_attrs = ls_token-attrs iv_name = `width` ).
              ENDIF.
              IF lv_value CP '*%'.
                lv_value = substring( val = lv_value len = strlen( lv_value ) - 1 ).
                CONDENSE lv_value NO-GAPS.
                IF lv_value CO '0123456789.' AND lv_value IS NOT INITIAL.
                  ls_cell-pct = lv_value.
                ENDIF.
              ENDIF.
              ls_cell-valign = to_lower( raw_prop( iv_tag = ls_token-name iv_attrs = ls_token-attrs iv_prop = `vertical-align` ) ).
              IF ls_cell-valign IS INITIAL.
                ls_cell-valign = to_lower( attr( iv_attrs = ls_token-attrs iv_name = `valign` ) ).
              ENDIF.
              IF ls_cell-box-per_edge = abap_true.
                "A side with a width but no colour uses the text colour, as in CSS.
                IF ls_cell-box-w_top > 0 AND ls_cell-box-e_top IS INITIAL.
                  ls_cell-box-e_top = ls_cell-style-color.
                ENDIF.
                IF ls_cell-box-w_right > 0 AND ls_cell-box-e_right IS INITIAL.
                  ls_cell-box-e_right = ls_cell-style-color.
                ENDIF.
                IF ls_cell-box-w_bot > 0 AND ls_cell-box-e_bot IS INITIAL.
                  ls_cell-box-e_bot = ls_cell-style-color.
                ENDIF.
                IF ls_cell-box-w_left > 0 AND ls_cell-box-e_left IS INITIAL.
                  ls_cell-box-e_left = ls_cell-style-color.
                ENDIF.
              ENDIF.
              IF ls_cell-box-border <= 0 AND ls_cell-box-no_edge = abap_false AND ls_cell-box-per_edge = abap_false AND lv_def_border > 0.
                ls_cell-box-border = lv_def_border.
                ls_cell-box-e_top = `0.5 0.5 0.5`.
                ls_cell-box-e_right = ls_cell-box-e_top.
                ls_cell-box-e_bot = ls_cell-box-e_top.
                ls_cell-box-e_left = ls_cell-box-e_top.
              ENDIF.
              IF ls_cell-box-border > 0 AND ls_cell-box-per_edge = abap_false AND ls_cell-box-e_top IS INITIAL AND ls_cell-box-e_right IS INITIAL
                  AND ls_cell-box-e_bot IS INITIAL AND ls_cell-box-e_left IS INITIAL.
                ls_cell-box-e_top = ls_cell-style-color.
                ls_cell-box-e_right = ls_cell-style-color.
                ls_cell-box-e_bot = ls_cell-style-color.
                ls_cell-box-e_left = ls_cell-style-color.
              ENDIF.
              IF raw_prop( iv_tag = ls_token-name iv_attrs = ls_token-attrs iv_prop = `padding` ) IS INITIAL.
                ls_cell-box-pad = lv_def_pad.
              ENDIF.
              lv_in_cell = abap_true.
          ENDCASE.
        WHEN 'C'.
          IF ls_token-name = 'thead' OR ls_token-name = 'tfoot' OR ls_token-name = 'tbody'.
            lv_part = 'B'.
          ENDIF.
      ENDCASE.
    ENDLOOP.
    IF lv_in_cell = abap_true.
      APPEND ls_cell TO lt_cells.
    ENDIF.
    lv_nrow = lines( lt_rows ).
    IF lv_nrow = 0 OR lt_cells IS INITIAL.
      RETURN.
    ENDIF.

    "2. Column count, natural widths and fixed widths.
    LOOP AT lt_cells ASSIGNING <ls_cell>.
      IF <ls_cell>-row + <ls_cell>-rowspan - 1 > lv_nrow.
        <ls_cell>-rowspan = lv_nrow - <ls_cell>-row + 1.
      ENDIF.
      lv_ncol = nmax( val1 = lv_ncol val2 = <ls_cell>-col + <ls_cell>-colspan ).
    ENDLOOP.
    DO lv_ncol TIMES.
      lv_f = 0.
      APPEND lv_f TO lt_colw.
      APPEND lv_f TO lt_nat.
      lv_flag = 0.
      APPEND lv_flag TO lt_fixed.
    ENDDO.
    LOOP AT lt_explicit INTO lv_f.
      lv_index = sy-tabix.
      IF lv_index <= lv_ncol AND lv_f > 0.
        MODIFY lt_colw FROM lv_f INDEX lv_index.
        lv_flag = 1.
        MODIFY lt_fixed FROM lv_flag INDEX lv_index.
      ENDIF.
    ENDLOOP.
    LOOP AT lt_cells ASSIGNING <ls_cell>.
      lt_pieces = collect(
        EXPORTING it_tokens = <ls_cell>-tokens is_style = <ls_cell>-style
        IMPORTING ev_align = lv_align ).
      IF lv_align IS NOT INITIAL.
        <ls_cell>-style-align = lv_align.
      ENDIF.
      lt_lines = wrap( it_pieces = lt_pieces iv_width = 100000 ).
      CLEAR lv_w.
      LOOP AT lt_lines INTO ls_line.
        lv_w = nmax( val1 = lv_w val2 = ls_line-width ).
      ENDLOOP.
      <ls_cell>-nat = lv_w + 2 * <ls_cell>-box-pad + <ls_cell>-box-border.
      CLEAR lv_w.
      LOOP AT lt_pieces INTO ls_piece.
        lv_w = nmax( val1 = lv_w val2 = ls_piece-width ).
      ENDLOOP.
      <ls_cell>-minw = lv_w + 2 * <ls_cell>-box-pad + <ls_cell>-box-border.
      IF <ls_cell>-colspan = 1.
        lv_index = <ls_cell>-col + 1.
        READ TABLE lt_nat INTO lv_f INDEX lv_index.
        lv_f = nmax( val1 = lv_f val2 = <ls_cell>-nat ).
        MODIFY lt_nat FROM lv_f INDEX lv_index.
        READ TABLE lt_fixed INTO lv_flag INDEX lv_index.
        IF lv_flag = 0 AND <ls_cell>-box-w > 0.
          MODIFY lt_colw FROM <ls_cell>-box-w INDEX lv_index.
          lv_flag = 1.
          MODIFY lt_fixed FROM lv_flag INDEX lv_index.
        ENDIF.
      ENDIF.
    ENDLOOP.

    "3. Table width: percentage of the available width, fixed, or content based.
    lv_value = raw_prop( iv_tag = `table` iv_attrs = iv_attrs iv_prop = `width` ).
    IF lv_value IS INITIAL.
      lv_value = attr( iv_attrs = iv_attrs iv_name = `width` ).
      IF lv_value CO '0123456789' AND lv_value IS NOT INITIAL.
        lv_value = lv_value && 'px'.
      ENDIF.
    ENDIF.
    CLEAR lv_w.
    IF lv_value CP '*%'.
      lv_value = substring( val = lv_value len = strlen( lv_value ) - 1 ).
      CONDENSE lv_value NO-GAPS.
      IF lv_value CO '0123456789.' AND lv_value IS NOT INITIAL.
        lv_f = lv_value.
        lv_w = ( iv_width - ls_tbox-ml ) * lv_f / 100.
      ENDIF.
    ELSEIF lv_value IS NOT INITIAL.
      lv_w = length_pt( iv_value = lv_value iv_base = ls_tstyle-size ).
    ENDIF.

    "Percentage widths refer to the table width (or the available width).
    lv_rest = lv_w.
    IF lv_rest <= 0.
      lv_rest = iv_width - ls_tbox-ml.
    ENDIF.
    LOOP AT lt_cells INTO ls_cell WHERE colspan = 1 AND pct > 0.
      lv_index = ls_cell-col + 1.
      READ TABLE lt_fixed INTO lv_flag INDEX lv_index.
      IF lv_flag = 0.
        lv_f = lv_rest * ls_cell-pct / 100.
        MODIFY lt_colw FROM lv_f INDEX lv_index.
        lv_flag = 1.
        MODIFY lt_fixed FROM lv_flag INDEX lv_index.
      ENDIF.
    ENDLOOP.
    LOOP AT lt_colw INTO lv_f.
      lv_index = sy-tabix.
      READ TABLE lt_fixed INTO lv_flag INDEX lv_index.
      IF lv_flag = 1.
        lv_sum_fixed = lv_sum_fixed + lv_f.
      ELSE.
        lv_auto = lv_auto + 1.
        READ TABLE lt_nat INTO lv_f INDEX lv_index.
        lv_sum_auto = lv_sum_auto + nmax( val1 = lv_f val2 = 12 ).
      ENDIF.
    ENDLOOP.
    IF lv_w > 0.
      IF lv_auto > 0.
        lv_rest = nmax( val1 = lv_w - lv_sum_fixed val2 = lv_auto * 12 ).
        DO lv_ncol TIMES.
          lv_index = sy-index.
          READ TABLE lt_fixed INTO lv_flag INDEX lv_index.
          IF lv_flag = 0.
            READ TABLE lt_nat INTO lv_f INDEX lv_index.
            lv_f = lv_rest * nmax( val1 = lv_f val2 = 12 ) / lv_sum_auto.
            MODIFY lt_colw FROM lv_f INDEX lv_index.
          ENDIF.
        ENDDO.
      ELSEIF lv_sum_fixed > 0.
        DO lv_ncol TIMES.
          lv_index = sy-index.
          READ TABLE lt_colw INTO lv_f INDEX lv_index.
          lv_f = lv_f * lv_w / lv_sum_fixed.
          MODIFY lt_colw FROM lv_f INDEX lv_index.
        ENDDO.
      ENDIF.
    ELSE.
      DO lv_ncol TIMES.
        lv_index = sy-index.
        READ TABLE lt_fixed INTO lv_flag INDEX lv_index.
        IF lv_flag = 0.
          READ TABLE lt_nat INTO lv_f INDEX lv_index.
          lv_f = nmax( val1 = lv_f val2 = 12 ).
          MODIFY lt_colw FROM lv_f INDEX lv_index.
        ELSE.
          READ TABLE lt_colw INTO lv_f INDEX lv_index.
        ENDIF.
        lv_sum = lv_sum + lv_f.
      ENDDO.
      lv_rest = iv_width - ls_tbox-ml.
      IF lv_sum > lv_rest AND lv_sum > 0.
        DO lv_ncol TIMES.
          lv_index = sy-index.
          READ TABLE lt_colw INTO lv_f INDEX lv_index.
          lv_f = lv_f * lv_rest / lv_sum.
          MODIFY lt_colw FROM lv_f INDEX lv_index.
        ENDDO.
      ENDIF.
    ENDIF.
    "Right-to-left table (direction:rtl): column 1 is on the right. The columns are mirrored
    "here; borders stay physical (left is left), as in the browser.
    IF ls_tstyle-dir = 'R'.
      lt_mirror = lt_colw.
      CLEAR lt_colw.
      lv_index = lines( lt_mirror ).
      WHILE lv_index >= 1.
        READ TABLE lt_mirror INTO lv_w INDEX lv_index.
        APPEND lv_w TO lt_colw.
        lv_index = lv_index - 1.
      ENDWHILE.
      LOOP AT lt_cells ASSIGNING <ls_cell>.
        <ls_cell>-col = lv_ncol - <ls_cell>-col - <ls_cell>-colspan.
      ENDLOOP.
    ENDIF.
    lv_f = 0.
    LOOP AT lt_colw INTO lv_w.
      APPEND lv_f TO lt_colx.
      lv_f = lv_f + lv_w.
    ENDLOOP.

    "4. Wrap cell text at the final widths; row heights.
    LOOP AT lt_cells ASSIGNING <ls_cell>.
      CLEAR lv_w.
      DO <ls_cell>-colspan TIMES.
        lv_index = <ls_cell>-col + sy-index.
        READ TABLE lt_colw INTO lv_f INDEX lv_index.
        IF sy-subrc = 0.
          lv_w = lv_w + lv_f.
        ENDIF.
      ENDDO.
      lv_inner = lv_w - 2 * <ls_cell>-box-pad - <ls_cell>-box-border.
      lt_pieces = collect( it_tokens = <ls_cell>-tokens is_style = <ls_cell>-style ).
      <ls_cell>-lines = wrap( it_pieces = lt_pieces iv_width = lv_inner ).
      DELETE <ls_cell>-lines WHERE pieces IS INITIAL AND size <= 0.
      "Trailing empty lines from closing block tags add no height.
      lv_index = lines( <ls_cell>-lines ).
      WHILE lv_index > 0.
        READ TABLE <ls_cell>-lines INTO ls_line INDEX lv_index.
        IF ls_line-pieces IS NOT INITIAL.
          EXIT.
        ENDIF.
        DELETE <ls_cell>-lines INDEX lv_index.
        lv_index = lv_index - 1.
      ENDWHILE.
      CLEAR <ls_cell>-texth.
      LOOP AT <ls_cell>-lines INTO ls_line.
        <ls_cell>-texth = <ls_cell>-texth + line_height( ls_line ).
      ENDLOOP.
      lv_need = nmax( val1 = <ls_cell>-texth val2 = <ls_cell>-style-size * c_line_factor )
                + 2 * <ls_cell>-box-pad + <ls_cell>-box-border.
      lv_need = nmax( val1 = lv_need val2 = <ls_cell>-box-h ).
      IF <ls_cell>-rowspan = 1.
        READ TABLE lt_rows ASSIGNING <ls_row> INDEX <ls_cell>-row.
        <ls_row>-height = nmax( val1 = <ls_row>-height val2 = lv_need ).
      ENDIF.
    ENDLOOP.
    LOOP AT lt_rows ASSIGNING <ls_row> WHERE height <= 0.
      <ls_row>-height = ls_tstyle-size * c_line_factor + 2 * lv_def_pad.
    ENDLOOP.
    LOOP AT lt_cells ASSIGNING <ls_cell> WHERE rowspan > 1.
      lv_need = nmax( val1 = <ls_cell>-texth + 2 * <ls_cell>-box-pad + <ls_cell>-box-border val2 = <ls_cell>-box-h ).
      lv_last = <ls_cell>-row + <ls_cell>-rowspan - 1.
      CLEAR lv_span_h.
      LOOP AT lt_rows INTO ls_row FROM <ls_cell>-row TO lv_last.
        lv_span_h = lv_span_h + ls_row-height.
      ENDLOOP.
      IF lv_need > lv_span_h.
        READ TABLE lt_rows ASSIGNING <ls_row> INDEX lv_last.
        <ls_row>-height = <ls_row>-height + lv_need - lv_span_h.
      ENDIF.
    ENDLOOP.

    "Leading header rows repeat on every continued page.
    LOOP AT lt_rows INTO ls_row.
      IF ls_row-part <> 'H'.
        EXIT.
      ENDIF.
      IF lv_head_first = 0.
        lv_head_first = sy-tabix.
      ENDIF.
      lv_head_last = sy-tabix.
      lv_head_h = lv_head_h + ls_row-height.
    ENDLOOP.

    "5. Draw row groups (a row plus the rows its row spans cover) page by page.
    lv_x = iv_x + ls_tbox-ml.
    lv_y = mv_y.
    IF mv_y > mv_mt.
      lv_y = lv_y + mv_gap.
    ENDIF.
    lv_y = lv_y + ls_tbox-mt.
    mv_gap = 0.
    lv_first = 1.
    WHILE lv_first <= lv_nrow.
      lv_end = lv_first.
      lv_index = lv_first.
      WHILE lv_index <= lv_end.
        LOOP AT lt_cells INTO ls_cell WHERE row = lv_index.
          lv_end = nmax( val1 = lv_end val2 = ls_cell-row + ls_cell-rowspan - 1 ).
        ENDLOOP.
        lv_index = lv_index + 1.
      ENDWHILE.
      CLEAR lv_gh.
      LOOP AT lt_rows INTO ls_row FROM lv_first TO lv_end.
        lv_gh = lv_gh + ls_row-height.
      ENDLOOP.
      IF lv_y + lv_gh > mv_ph - mv_mb AND lv_y > mv_mt + 1.
        new_page( ).
        lv_y = mv_mt.
        IF lv_head_first > 0 AND lv_first > lv_head_last.
          draw_table_rows( it_cells = lt_cells it_rows = lt_rows it_colx = lt_colx it_colw = lt_colw
                           iv_first = lv_head_first iv_last = lv_head_last iv_x = lv_x iv_top = lv_y ).
          lv_y = lv_y + lv_head_h.
        ENDIF.
      ENDIF.
      draw_table_rows( it_cells = lt_cells it_rows = lt_rows it_colx = lt_colx it_colw = lt_colw
                       iv_first = lv_first iv_last = lv_end iv_x = lv_x iv_top = lv_y ).
      lv_y = lv_y + lv_gh.
      lv_first = lv_end + 1.
    ENDWHILE.
    mv_y = lv_y.
    mv_gap = ls_tbox-mb.
  ENDMETHOD.

ENDCLASS.
