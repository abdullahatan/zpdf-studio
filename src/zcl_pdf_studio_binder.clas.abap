CLASS zcl_pdf_studio_binder DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_field,
        name      TYPE string,
        path      TYPE string,
        parent    TYPE string,
        kind      TYPE string,
        abap_type TYPE string,
        length    TYPE i,
        insert    TYPE string,
      END OF ty_field,
      ty_fields TYPE STANDARD TABLE OF ty_field WITH EMPTY KEY.

    "! Fills a template. Formats ({{FIELD | pattern}} or data-fmt) use the language iv_lang
    "! for month names, amounts in words and upper case (see ZCL_PDF_STUDIO_FORMAT).
    CLASS-METHODS render
      IMPORTING
        iv_template    TYPE string
        is_data        TYPE any
        iv_lang        TYPE sy-langu DEFAULT sy-langu
      RETURNING
        VALUE(rv_result) TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS serialize_json
      IMPORTING
        is_data      TYPE any
      RETURNING
        VALUE(rv_json) TYPE string
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS field_catalog
      IMPORTING
        iv_type_name   TYPE csequence
      RETURNING
        VALUE(rt_fields) TYPE ty_fields
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS field_catalog_json
      IMPORTING
        iv_type_name TYPE csequence
      RETURNING
        VALUE(rv_json) TYPE string
      RAISING
        zcx_pdf_studio.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_tag,
        kind  TYPE string,
        path  TYPE string,
        close TYPE string,
      END OF ty_tag.

    TYPES:
      BEGIN OF ty_fmt,
        path    TYPE string,
        pattern TYPE string,
      END OF ty_fmt.

    DATA mt_ctx TYPE STANDARD TABLE OF REF TO data WITH EMPTY KEY.
    DATA mt_rowno TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA mt_fields TYPE ty_fields.
    DATA mt_fmt TYPE HASHED TABLE OF ty_fmt WITH UNIQUE KEY path.

    METHODS run
      IMPORTING
        iv_template    TYPE string
        is_data        TYPE any
      RETURNING
        VALUE(rv_result) TYPE string
      RAISING
        zcx_pdf_studio.

    METHODS apply_patterns
      IMPORTING
        iv_template        TYPE string
      RETURNING
        VALUE(rv_template) TYPE string.

    METHODS apply_fmt_marks
      IMPORTING
        iv_html        TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    METHODS format_display
      IMPORTING
        iv_value       TYPE string
        iv_pattern     TYPE string
        iv_kind        TYPE zcl_pdf_studio_format=>ty_kind DEFAULT 'C'
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS remember_pattern
      IMPORTING
        iv_path    TYPE string
        iv_pattern TYPE string.

    METHODS pattern_for
      IMPORTING
        iv_html        TYPE string
        iv_at          TYPE i
        iv_path        TYPE string
      RETURNING
        VALUE(rv_pattern) TYPE string.

    METHODS json_string_value
      IMPORTING
        iv_json        TYPE string
        iv_key         TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    METHODS arabic_digits
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS render_template
      IMPORTING
        iv_template    TYPE string
      RETURNING
        VALUE(rv_result) TYPE string
      RAISING
        zcx_pdf_studio.

    METHODS find_block_end
      IMPORTING
        iv_template  TYPE string
        iv_start     TYPE i
        iv_close     TYPE string
      EXPORTING
        ev_inner     TYPE string
        ev_else      TYPE string
        ev_end       TYPE i
      RAISING
        zcx_pdf_studio.

    METHODS classify_tag
      IMPORTING
        iv_tag       TYPE string
      RETURNING
        VALUE(rs_tag) TYPE ty_tag.

    METHODS render_each
      IMPORTING
        iv_path      TYPE string
        iv_inner     TYPE string
        iv_else      TYPE string
      RETURNING
        VALUE(rv_result) TYPE string
      RAISING
        zcx_pdf_studio.

    METHODS render_if
      IMPORTING
        iv_path      TYPE string
        iv_inner     TYPE string
        iv_else      TYPE string
        iv_inverted  TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_result) TYPE string
      RAISING
        zcx_pdf_studio.

    METHODS resolve_text
      IMPORTING
        iv_path      TYPE string
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        zcx_pdf_studio.

    "Value for a format: dates YYYYMMDD, times HHMMSS, numbers 1234.50, text as is.
    METHODS resolve_raw
      IMPORTING
        iv_path TYPE string
      EXPORTING
        ev_text TYPE string
        ev_kind TYPE zcl_pdf_studio_format=>ty_kind
      RAISING
        zcx_pdf_studio.

    DATA mv_lang TYPE sy-langu.

    METHODS try_resolve
      IMPORTING
        iv_path      TYPE string
      EXPORTING
        eo_data      TYPE REF TO data
        ev_found     TYPE abap_bool.

    METHODS walk
      IMPORTING
        io_data      TYPE REF TO data
        iv_path      TYPE string
      EXPORTING
        eo_data      TYPE REF TO data
      RETURNING
        VALUE(rv_found) TYPE abap_bool.

    METHODS is_truthy
      IMPORTING
        io_data          TYPE REF TO data
      RETURNING
        VALUE(rv_truthy) TYPE abap_bool.

    "Totals at print time: {{sum ITEMS.AMOUNT}} {{count ITEMS}} {{avg|min|max ITEMS.AMOUNT}}.
    CLASS-METHODS is_aggregate
      IMPORTING iv_tag        TYPE string
      RETURNING VALUE(rv_yes) TYPE abap_bool.
    METHODS aggregate
      IMPORTING iv_tag         TYPE string
      RETURNING VALUE(rv_text) TYPE string
      RAISING   zcx_pdf_studio.
    METHODS parse_number
      IMPORTING iv_text     TYPE string
      EXPORTING ev_value    TYPE decfloat34
                ev_ok       TYPE abap_bool
                ev_decimals TYPE i
                ev_dec_sep  TYPE string
                ev_grouped  TYPE abap_bool.
    METHODS format_number
      IMPORTING iv_value       TYPE decfloat34
                iv_decimals    TYPE i
                iv_dec_sep     TYPE string
                iv_group_sep   TYPE string
                iv_arabic      TYPE abap_bool OPTIONAL
      RETURNING VALUE(rv_text) TYPE string.
    "Number masks: #,##0.00  #.##0,00  0.00  0,00  #,##0  #.##0  0  AR#,##0.00
    METHODS number_pattern
      IMPORTING iv_value       TYPE string
                iv_pattern     TYPE string
      RETURNING VALUE(rv_text) TYPE string.

    METHODS value_to_string
      IMPORTING
        io_data          TYPE REF TO data
      RETURNING
        VALUE(rv_text)   TYPE string.

    "{{{FIELD}}} keeps an allow-list of formatting tags and attributes; everything else is removed.
    CLASS-METHODS sanitize_raw
      IMPORTING iv_html        TYPE string
      RETURNING VALUE(rv_html) TYPE string.
    "Reads the attributes of one opening tag. ev_end is the offset of the closing '>' (-1 if none).
    CLASS-METHODS sanitize_tag
      IMPORTING iv_html  TYPE string
                iv_name  TYPE string
                iv_start TYPE i
      EXPORTING ev_tag   TYPE string
                ev_end   TYPE i.
    CLASS-METHODS tag_name
      IMPORTING iv_lower       TYPE string
                iv_start       TYPE i
      RETURNING VALUE(rv_name) TYPE string.
    CLASS-METHODS decode_attr
      IMPORTING iv_value        TYPE string
      RETURNING VALUE(rv_value) TYPE string.
    CLASS-METHODS safe_url
      IMPORTING iv_attr       TYPE string
                iv_value      TYPE string
      RETURNING VALUE(rv_yes) TYPE abap_bool.
    CLASS-METHODS safe_style
      IMPORTING iv_value      TYPE string
      RETURNING VALUE(rv_yes) TYPE abap_bool.
    CLASS-METHODS escape_attr
      IMPORTING iv_value        TYPE string
      RETURNING VALUE(rv_value) TYPE string.
    CONSTANTS:
      "Tags kept (without their unsafe attributes).
      c_raw_tags     TYPE string VALUE '|b|i|u|s|em|strong|small|big|sub|sup|br|hr|p|div|span|font|center|h1|h2|h3|h4|h5|h6|ul|ol|li|dl|dt|dd|table|thead|tbody|tfoot|tr|td|th|caption|colgroup|col|img|a|blockquote|pre|code|strike|del|ins|mark|label|',
      "Tags removed together with their content.
      c_raw_drop     TYPE string VALUE '|script|style|iframe|frame|frameset|object|embed|applet|noscript|noembed|noframes|template|textarea|select|svg|math|title|xmp|plaintext|',
      "Attributes kept; href, src and style are checked further.
      c_raw_attrs    TYPE string VALUE '|class|style|align|valign|width|height|border|cellpadding|cellspacing|colspan|rowspan|dir|lang|title|alt|color|bgcolor|size|face|src|href|start|type|',
      c_raw_letters  TYPE string VALUE 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
      c_raw_namechar TYPE string VALUE 'abcdefghijklmnopqrstuvwxyz0123456789'.
    METHODS escape_html
      IMPORTING
        iv_text          TYPE string
      RETURNING
        VALUE(rv_text)   TYPE string.

    METHODS trim
      IMPORTING
        iv_text          TYPE string
      RETURNING
        VALUE(rv_text)   TYPE string.

    METHODS add_components
      IMPORTING
        io_struct     TYPE REF TO cl_abap_structdescr
        iv_rel_prefix TYPE string
        iv_abs_prefix TYPE string
        iv_parent     TYPE string
        iv_depth      TYPE i.

    METHODS elem_type
      IMPORTING
        io_elem            TYPE REF TO cl_abap_elemdescr
      RETURNING
        VALUE(rv_abap_type) TYPE string.

    CLASS-METHODS json_escape
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS xstring_to_string
      IMPORTING
        iv_xstring       TYPE xstring
      RETURNING
        VALUE(rv_string) TYPE string
      RAISING
        zcx_pdf_studio.
ENDCLASS.



CLASS zcl_pdf_studio_binder IMPLEMENTATION.

  METHOD render.
    DATA lo_binder TYPE REF TO zcl_pdf_studio_binder.
    CREATE OBJECT lo_binder.
    lo_binder->mv_lang = iv_lang.
    rv_result = lo_binder->run(
      iv_template = iv_template
      is_data     = is_data ).
  ENDMETHOD.

  METHOD run.
    DATA lr_root TYPE REF TO data.
    GET REFERENCE OF is_data INTO lr_root.
    APPEND lr_root TO mt_ctx.
    CLEAR mt_fmt.
    rv_result = render_template( apply_patterns( iv_template ) ).
  ENDMETHOD.


  METHOD apply_fmt_marks.
    DATA lv_kind TYPE zcl_pdf_studio_format=>ty_kind.
    DATA lv_pos TYPE i.
    DATA lv_at TYPE i.
    DATA lv_endq TYPE i.
    DATA lv_fmt TYPE string.
    DATA lv_gt TYPE i.
    DATA lv_close TYPE i.
    DATA lv_path TYPE string.
    DATA lv_token TYPE string.
    DATA lv_value TYPE string.
    DATA lv_shown TYPE string.
    DATA lv_mark TYPE string VALUE 'data-fmt="'.

    rv_html = iv_html.
    WHILE lv_pos < strlen( rv_html ).
      lv_at = find( val = rv_html sub = lv_mark off = lv_pos ).
      IF lv_at < 0.
        RETURN.
      ENDIF.
      lv_endq = find(
        val = rv_html
        sub = '"'
        off = lv_at + strlen( lv_mark ) ).
      IF lv_endq < 0.
        RETURN.
      ENDIF.
      lv_fmt = substring(
        val = rv_html
        off = lv_at + strlen( lv_mark )
        len = lv_endq - lv_at - strlen( lv_mark ) ).
      lv_gt = lv_endq + 1.
      IF lv_gt < strlen( rv_html )
        AND substring( val = rv_html off = lv_gt len = 1 ) = '>'.
        lv_gt = lv_gt + 1.
      ENDIF.
      IF lv_gt + 2 > strlen( rv_html )
        OR substring( val = rv_html off = lv_gt len = 2 ) <> '{{'.
        lv_pos = lv_endq + 1.
        CONTINUE.
      ENDIF.
      lv_close = find( val = rv_html sub = '}}' off = lv_gt + 2 ).
      IF lv_close < 0.
        RETURN.
      ENDIF.
      lv_path = trim( substring(
        val = rv_html
        off = lv_gt + 2
        len = lv_close - lv_gt - 2 ) ).
      "Totals keep the format of their own span only; block tags carry none.
      IF lv_path(1) CA '#/^' OR is_aggregate( lv_path ) = abap_true.
        lv_pos = lv_close + 2.
        CONTINUE.
      ENDIF.
      remember_pattern( iv_path = lv_path iv_pattern = lv_fmt ).
      lv_token = substring(
        val = rv_html
        off = lv_gt
        len = lv_close + 2 - lv_gt ).
      "Fields inside {{#each}} are formatted later, at render time.
      TRY.
          resolve_raw( EXPORTING iv_path = lv_path IMPORTING ev_text = lv_value ev_kind = lv_kind ).
        CATCH zcx_pdf_studio.
          lv_pos = lv_close + 2.
          CONTINUE.
      ENDTRY.
      lv_shown = format_display( iv_value = lv_value iv_pattern = lv_fmt iv_kind = lv_kind ).
      IF lv_shown <> lv_value.
        rv_html = substring( val = rv_html off = 0 len = lv_gt ) &&
          lv_shown &&
          substring( val = rv_html off = lv_close + 2 ).
        lv_pos = lv_gt + strlen( lv_shown ).
      ELSE.
        lv_pos = lv_close + 2.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.


  METHOD apply_patterns.
    DATA lv_kind TYPE zcl_pdf_studio_format=>ty_kind.
    DATA lv_mark TYPE string VALUE '<!--abappdf:'.
    DATA lv_at TYPE i.
    DATA lv_end TYPE i.
    DATA lv_json TYPE string.
    DATA lv_body TYPE string.
    DATA lv_pos TYPE i.
    DATA lv_len TYPE i.
    DATA lv_obj_at TYPE i.
    DATA lv_depth TYPE i.
    DATA lv_in_str TYPE abap_bool.
    DATA lv_esc TYPE abap_bool.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lv_obj TYPE string.
    DATA lv_text TYPE string.
    DATA lv_fmt TYPE string.
    DATA lv_path TYPE string.
    DATA lv_value TYPE string.
    DATA lv_shown TYPE string.

    rv_template = iv_template.
    lv_at = find( val = iv_template sub = '<!--abappdf64:' ).
    IF lv_at >= 0.
      lv_mark = '<!--abappdf64:'.
    ELSE.
      lv_at = find( val = iv_template sub = lv_mark ).
      IF lv_at < 0.
        rv_template = apply_fmt_marks( iv_template ).
        RETURN.
      ENDIF.
    ENDIF.
    lv_end = find( val = iv_template sub = '-->' off = lv_at ).
    IF lv_end < 0.
      RETURN.
    ENDIF.
    lv_json = substring(
      val = iv_template
      off = lv_at + strlen( lv_mark )
      len = lv_end - lv_at - strlen( lv_mark ) ).
    IF lv_mark = '<!--abappdf64:'.
      TRY.
          lv_json = zcl_pdf_studio_conv=>base64url_decode( lv_json ).
        CATCH zcx_pdf_studio.
          rv_template = substring( val = iv_template off = 0 len = lv_end + 3 ) &&
            apply_fmt_marks( substring( val = iv_template off = lv_end + 3 ) ).
          RETURN.
      ENDTRY.
    ELSE.
      REPLACE ALL OCCURRENCES OF '- -' IN lv_json WITH '--'.
    ENDIF.
    "Skip the widget scan when no widget carries a date format.
    IF lv_json NS '"dateFmt"' AND lv_json NS 'Date/Time Field'.
      rv_template = substring( val = iv_template off = 0 len = lv_end + 3 ) &&
        apply_fmt_marks( substring( val = iv_template off = lv_end + 3 ) ).
      RETURN.
    ENDIF.
    lv_body = apply_fmt_marks( substring( val = iv_template off = lv_end + 3 ) ).

    lv_pos = find( val = lv_json sub = '"widgets":[' ).
    IF lv_pos < 0.
      rv_template = substring( val = iv_template off = 0 len = lv_end + 3 ) && lv_body.
      RETURN.
    ENDIF.
    lv_pos = lv_pos + strlen( '"widgets":[' ).
    lv_len = strlen( lv_json ).

    WHILE lv_pos < lv_len.
      lv_ch = substring( val = lv_json off = lv_pos len = 1 ).
      IF lv_ch = ']'.
        EXIT.
      ENDIF.
      IF lv_ch <> '{'.
        lv_pos = lv_pos + 1.
        CONTINUE.
      ENDIF.

      lv_obj_at = lv_pos.
      lv_depth = 0.
      lv_in_str = abap_false.
      lv_esc = abap_false.
      WHILE lv_pos < lv_len.
        lv_ch = substring( val = lv_json off = lv_pos len = 1 ).
        IF lv_in_str = abap_true.
          IF lv_esc = abap_true.
            lv_esc = abap_false.
          ELSEIF lv_ch = '\'.
            lv_esc = abap_true.
          ELSEIF lv_ch = '"'.
            lv_in_str = abap_false.
          ENDIF.
        ELSEIF lv_ch = '"'.
          lv_in_str = abap_true.
        ELSEIF lv_ch = '{'.
          lv_depth = lv_depth + 1.
        ELSEIF lv_ch = '}'.
          lv_depth = lv_depth - 1.
          IF lv_depth = 0.
            lv_obj = substring(
              val = lv_json
              off = lv_obj_at
              len = lv_pos - lv_obj_at + 1 ).
            lv_pos = lv_pos + 1.
            EXIT.
          ENDIF.
        ENDIF.
        lv_pos = lv_pos + 1.
      ENDWHILE.

      lv_fmt = json_string_value( iv_json = lv_obj iv_key = 'dateFmt' ).
      lv_text = json_string_value( iv_json = lv_obj iv_key = 'text' ).
      IF lv_fmt IS INITIAL
        AND json_string_value( iv_json = lv_obj iv_key = 'type' ) = 'Date/Time Field'.
        lv_fmt = 'YYYY-MM-DD'.
      ENDIF.
      lv_text = trim( lv_text ).
      IF lv_fmt IS INITIAL
        OR strlen( lv_text ) < 5
        OR lv_text(2) <> '{{'
        OR substring( val = lv_text off = strlen( lv_text ) - 2 ) <> '}}'.
        CONTINUE.
      ENDIF.
      lv_path = trim( substring( val = lv_text off = 2 len = strlen( lv_text ) - 4 ) ).
      IF lv_path IS INITIAL OR lv_path CS ' '.
        CONTINUE.
      ENDIF.
      remember_pattern( iv_path = lv_path iv_pattern = lv_fmt ).
      TRY.
          resolve_raw( EXPORTING iv_path = lv_path IMPORTING ev_text = lv_value ev_kind = lv_kind ).
        CATCH zcx_pdf_studio.
          CONTINUE.
      ENDTRY.
      lv_shown = format_display( iv_value = lv_value iv_pattern = lv_fmt iv_kind = lv_kind ).
      IF lv_shown <> lv_value.
        REPLACE FIRST OCCURRENCE OF lv_text IN lv_body WITH lv_shown.
      ENDIF.
    ENDWHILE.

    rv_template = substring( val = iv_template off = 0 len = lv_end + 3 ) && lv_body.
  ENDMETHOD.


  METHOD format_display.
    DATA lv_pattern TYPE string.
    DATA lv_lang TYPE sy-langu.
    lv_pattern = iv_pattern.
    "Patterns of the first designer: HH:MM means hours and minutes.
    REPLACE ALL OCCURRENCES OF 'HH:MM' IN lv_pattern WITH 'HH:mm'.
    REPLACE ALL OCCURRENCES OF ':SS' IN lv_pattern WITH ':ss'.
    lv_lang = mv_lang.
    IF lv_lang IS INITIAL.
      lv_lang = sy-langu.
    ENDIF.
    IF lv_pattern = 'AR' AND ( iv_kind = 'D' OR zcl_pdf_studio_format=>is_date_pattern( `DD` ) = abap_true AND iv_value CO '0123456789' ).
      rv_text = arabic_digits( zcl_pdf_studio_format=>format(
        iv_value = iv_value iv_pattern = `YYYY/MM/DD` iv_kind = iv_kind iv_lang = lv_lang ) ).
      RETURN.
    ENDIF.
    rv_text = zcl_pdf_studio_format=>format(
      iv_value   = iv_value
      iv_pattern = lv_pattern
      iv_kind    = iv_kind
      iv_lang    = lv_lang ).
  ENDMETHOD.


  METHOD remember_pattern.
    DATA ls_fmt TYPE ty_fmt.
    FIELD-SYMBOLS <fmt> TYPE ty_fmt.

    IF iv_pattern IS INITIAL OR iv_path IS INITIAL.
      RETURN.
    ENDIF.
    ls_fmt-path = to_upper( trim( iv_path ) ).
    ls_fmt-pattern = trim( iv_pattern ).
    IF ls_fmt-path IS INITIAL OR ls_fmt-pattern IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE mt_fmt ASSIGNING <fmt> WITH TABLE KEY path = ls_fmt-path.
    IF sy-subrc = 0.
      <fmt>-pattern = ls_fmt-pattern.
    ELSE.
      INSERT ls_fmt INTO TABLE mt_fmt.
    ENDIF.
  ENDMETHOD.


  METHOD pattern_for.
    DATA lv_from TYPE i.
    DATA lv_prefix TYPE string.
    DATA lv_len TYPE i.
    DATA lv_at TYPE i.
    DATA lv_hit TYPE i.
    DATA lv_endq TYPE i.
    DATA lv_key TYPE string VALUE 'data-fmt="'.
    DATA lv_prev TYPE i.
    DATA lv_ch TYPE c LENGTH 1.
    FIELD-SYMBOLS <fmt> TYPE ty_fmt.

    IF iv_at > 0.
      lv_from = iv_at - 120.
      IF lv_from < 0.
        lv_from = 0.
      ENDIF.
      lv_prefix = substring( val = iv_html off = lv_from len = iv_at - lv_from ).
      lv_len = strlen( lv_prefix ).
      WHILE lv_len > 0.
        lv_ch = substring( val = lv_prefix off = lv_len - 1 len = 1 ).
        IF lv_ch <> ' '.
          EXIT.
        ENDIF.
        lv_len = lv_len - 1.
        lv_prefix = substring( val = lv_prefix off = 0 len = lv_len ).
      ENDWHILE.
      IF lv_len > 1
        AND substring( val = lv_prefix off = lv_len - 1 len = 1 ) = '>'.
        lv_prefix = substring( val = lv_prefix off = 0 len = lv_len - 1 ).
        lv_len = strlen( lv_prefix ).
        IF lv_len > 1
          AND substring( val = lv_prefix off = lv_len - 1 len = 1 ) = '"'.
          lv_hit = -1.
          lv_at = 0.
          WHILE lv_at < lv_len.
            lv_endq = find( val = lv_prefix sub = lv_key off = lv_at ).
            IF lv_endq < 0.
              EXIT.
            ENDIF.
            lv_hit = lv_endq.
            lv_at = lv_endq + 1.
          ENDWHILE.
          IF lv_hit >= 0.
            lv_at = lv_hit + strlen( lv_key ).
            lv_endq = find( val = lv_prefix sub = '"' off = lv_at ).
            IF lv_endq = lv_len - 1.
              rv_pattern = trim( substring(
                val = lv_prefix
                off = lv_at
                len = lv_endq - lv_at ) ).
              IF rv_pattern IS NOT INITIAL.
                RETURN.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      lv_prev = iv_at - 1.
      WHILE lv_prev >= 0.
        lv_ch = substring( val = iv_html off = lv_prev len = 1 ).
        IF lv_ch <> ' '.
          EXIT.
        ENDIF.
        lv_prev = lv_prev - 1.
      ENDWHILE.
      IF lv_prev >= 0 AND lv_ch = '"'.
        RETURN.
      ENDIF.
    ENDIF.

    READ TABLE mt_fmt ASSIGNING <fmt>
      WITH TABLE KEY path = to_upper( trim( iv_path ) ).
    IF sy-subrc = 0.
      rv_pattern = <fmt>-pattern.
    ENDIF.
  ENDMETHOD.


  METHOD json_string_value.
    DATA lv_key TYPE string.
    DATA lv_at TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_len TYPE i.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lv_esc TYPE abap_bool.

    lv_key = |"{ iv_key }":"|.
    lv_at = find( val = iv_json sub = lv_key ).
    IF lv_at < 0.
      RETURN.
    ENDIF.
    lv_pos = lv_at + strlen( lv_key ).
    lv_len = strlen( iv_json ).
    WHILE lv_pos < lv_len.
      lv_ch = substring( val = iv_json off = lv_pos len = 1 ).
      IF lv_esc = abap_true.
        rv_value = rv_value && lv_ch.
        lv_esc = abap_false.
      ELSEIF lv_ch = '\'.
        lv_esc = abap_true.
      ELSEIF lv_ch = '"'.
        RETURN.
      ELSE.
        rv_value = rv_value && lv_ch.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.
  ENDMETHOD.


  METHOD arabic_digits.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_ch TYPE c LENGTH 1.

    lv_len = strlen( iv_text ).
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_ch = substring( val = iv_text off = lv_i len = 1 ).
      CASE lv_ch.
        WHEN '0'. rv_text = rv_text && '٠'.
        WHEN '1'. rv_text = rv_text && '١'.
        WHEN '2'. rv_text = rv_text && '٢'.
        WHEN '3'. rv_text = rv_text && '٣'.
        WHEN '4'. rv_text = rv_text && '٤'.
        WHEN '5'. rv_text = rv_text && '٥'.
        WHEN '6'. rv_text = rv_text && '٦'.
        WHEN '7'. rv_text = rv_text && '٧'.
        WHEN '8'. rv_text = rv_text && '٨'.
        WHEN '9'. rv_text = rv_text && '٩'.
        WHEN OTHERS. rv_text = rv_text && lv_ch.
      ENDCASE.
    ENDDO.
  ENDMETHOD.

  METHOD render_template.
    DATA lv_pos TYPE i VALUE 0.
    DATA lv_len TYPE i.
    DATA lv_open TYPE i.
    DATA lv_end TYPE i.
    DATA lv_after TYPE i.
    DATA lv_tag_text TYPE string.
    DATA lv_var_path TYPE string.
    DATA lv_var_kind TYPE zcl_pdf_studio_format=>ty_kind.
    DATA ls_tag TYPE ty_tag.
    DATA lv_inner TYPE string.
    DATA lv_else TYPE string.
    DATA lv_block_end TYPE i.
    DATA lv_piece TYPE string.
    DATA lv_fmt TYPE string.
    DATA lr_section TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    FIELD-SYMBOLS <section> TYPE any.

    lv_len = strlen( iv_template ).

    WHILE lv_pos < lv_len.
      lv_open = find(
        val = iv_template
        sub = '{{'
        off = lv_pos ).
      IF lv_open < 0.
        rv_result = rv_result && substring(
          val = iv_template
          off = lv_pos ).
        RETURN.
      ENDIF.

      IF lv_open > lv_pos.
        rv_result = rv_result && substring(
          val = iv_template
          off = lv_pos
          len = lv_open - lv_pos ).
      ENDIF.

      IF lv_open + 3 <= lv_len AND iv_template+lv_open(3) = '{{{'.
        lv_end = find(
          val = iv_template
          sub = '}}}'
          off = lv_open + 3 ).
        IF lv_end < 0.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING
              message = 'Unclosed {{{ in template'.
        ENDIF.
        lv_tag_text = substring(
          val = iv_template
          off = lv_open + 3
          len = lv_end - lv_open - 3 ).
        rv_result = rv_result && sanitize_raw( resolve_text( trim( lv_tag_text ) ) ).
        lv_pos = lv_end + 3.
        CONTINUE.
      ENDIF.

      lv_end = find(
        val = iv_template
        sub = '}}'
        off = lv_open + 2 ).
      IF lv_end < 0.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING
            message = 'Unclosed {{ in template'.
      ENDIF.

      lv_tag_text = trim( substring(
        val = iv_template
        off = lv_open + 2
        len = lv_end - lv_open - 2 ) ).
      lv_after = lv_end + 2.
      ls_tag = classify_tag( lv_tag_text ).

      CASE ls_tag-kind.
        WHEN 'comment'.
          lv_pos = lv_after.
        WHEN 'close' OR 'else'.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING message = |Unexpected template tag at offset { lv_open }: { lv_tag_text }|.
        WHEN 'var'.
          "{{FIELD | pattern}}: inline format.
          CLEAR: lv_fmt, lv_var_kind.
          lv_var_path = ls_tag-path.
          IF lv_var_path CS '|'.
            SPLIT lv_var_path AT '|' INTO lv_var_path lv_fmt.
            lv_var_path = condense( lv_var_path ).
            lv_fmt = condense( lv_fmt ).
          ENDIF.
          IF lv_fmt IS INITIAL.
            lv_fmt = pattern_for(
              iv_html = iv_template
              iv_at   = lv_open
              iv_path = lv_var_path ).
          ENDIF.
          IF is_aggregate( lv_var_path ) = abap_true.
            lv_piece = aggregate( lv_var_path ).
          ELSEIF lv_fmt IS NOT INITIAL.
            resolve_raw( EXPORTING iv_path = lv_var_path IMPORTING ev_text = lv_piece ev_kind = lv_var_kind ).
          ELSE.
            lv_piece = resolve_text( lv_var_path ).
          ENDIF.
          IF lv_fmt IS NOT INITIAL.
            lv_piece = format_display( iv_value = lv_piece iv_pattern = lv_fmt iv_kind = lv_var_kind ).
          ENDIF.
          rv_result = rv_result && escape_html( lv_piece ).
          lv_pos = lv_after.
        WHEN 'each' OR 'if' OR 'section' OR 'inverted'.
          find_block_end(
            EXPORTING
              iv_template = iv_template
              iv_start    = lv_after
              iv_close    = ls_tag-close
            IMPORTING
              ev_inner    = lv_inner
              ev_else     = lv_else
              ev_end      = lv_block_end ).
          CASE ls_tag-kind.
            WHEN 'each'.
              rv_result = rv_result && render_each(
                iv_path  = ls_tag-path
                iv_inner = lv_inner
                iv_else  = lv_else ).
            WHEN 'if'.
              rv_result = rv_result && render_if(
                iv_path  = ls_tag-path
                iv_inner = lv_inner
                iv_else  = lv_else ).
            WHEN 'inverted'.
              rv_result = rv_result && render_if(
                iv_path     = ls_tag-path
                iv_inner    = lv_inner
                iv_else     = lv_else
                iv_inverted = abap_true ).
            WHEN 'section'.
              CLEAR lr_section.
              CLEAR lv_found.
              try_resolve(
                EXPORTING
                  iv_path  = ls_tag-path
                IMPORTING
                  eo_data  = lr_section
                  ev_found = lv_found ).
              IF lv_found = abap_true.
                ASSIGN lr_section->* TO <section>.
                IF sy-subrc <> 0.
                  CLEAR lv_found.
                ELSEIF cl_abap_typedescr=>describe_by_data( <section> )->kind
                    <> cl_abap_typedescr=>kind_table.
                  CLEAR lv_found.
                ENDIF.
              ENDIF.
              IF lv_found = abap_true.
                rv_result = rv_result && render_each(
                  iv_path  = ls_tag-path
                  iv_inner = lv_inner
                  iv_else  = lv_else ).
              ELSE.
                rv_result = rv_result && render_if(
                  iv_path  = ls_tag-path
                  iv_inner = lv_inner
                  iv_else  = lv_else ).
              ENDIF.
          ENDCASE.
          lv_pos = lv_block_end.
      ENDCASE.
    ENDWHILE.
  ENDMETHOD.

  METHOD find_block_end.
    DATA lv_pos TYPE i.
    DATA lv_len TYPE i.
    DATA lv_depth TYPE i VALUE 1.
    DATA lv_open TYPE i.
    DATA lv_end TYPE i.
    DATA lv_tag_text TYPE string.
    DATA ls_tag TYPE ty_tag.
    DATA lv_else_open TYPE i VALUE -1.
    DATA lv_else_after TYPE i.
    DATA lt_closes TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_expected TYPE string.
    APPEND to_upper( iv_close ) TO lt_closes.

    lv_pos = iv_start.
    lv_len = strlen( iv_template ).

    WHILE lv_pos < lv_len.
      lv_open = find(
        val = iv_template
        sub = '{{'
        off = lv_pos ).
      IF lv_open < 0.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING
            message = |Unclosed block /{ iv_close }|.
      ENDIF.

      IF lv_open + 3 <= lv_len AND iv_template+lv_open(3) = '{{{'.
        lv_end = find(
          val = iv_template
          sub = '}}}'
          off = lv_open + 3 ).
        IF lv_end < 0.
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING
              message = 'Unclosed {{{ in template'.
        ENDIF.
        lv_pos = lv_end + 3.
        CONTINUE.
      ENDIF.

      lv_end = find(
        val = iv_template
        sub = '}}'
        off = lv_open + 2 ).
      IF lv_end < 0.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING
            message = 'Unclosed {{ in template'.
      ENDIF.

      lv_tag_text = trim( substring(
        val = iv_template
        off = lv_open + 2
        len = lv_end - lv_open - 2 ) ).
      ls_tag = classify_tag( lv_tag_text ).

      IF ls_tag-kind = 'each'
          OR ls_tag-kind = 'if'
          OR ls_tag-kind = 'section'
          OR ls_tag-kind = 'inverted'.
        lv_depth = lv_depth + 1.
        IF lv_depth > 50.
          RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Template nesting exceeds 50 levels'.
        ENDIF.
        APPEND to_upper( ls_tag-close ) TO lt_closes.
      ELSEIF ls_tag-kind = 'close'.
        READ TABLE lt_closes INDEX lv_depth INTO lv_expected.
        IF lv_expected <> to_upper( ls_tag-path ).
          RAISE EXCEPTION TYPE zcx_pdf_studio
            EXPORTING message = |Expected /{ lv_expected } but found /{ ls_tag-path }|.
        ENDIF.
        DELETE lt_closes INDEX lv_depth.
        lv_depth = lv_depth - 1.
        IF lv_depth = 0.
          IF to_upper( ls_tag-path ) <> to_upper( iv_close ).
            RAISE EXCEPTION TYPE zcx_pdf_studio
              EXPORTING
                message = |Expected /{ iv_close } but found /{ ls_tag-path }|.
          ENDIF.
          IF lv_else_open < 0.
            ev_inner = substring(
              val = iv_template
              off = iv_start
              len = lv_open - iv_start ).
            CLEAR ev_else.
          ELSE.
            ev_inner = substring(
              val = iv_template
              off = iv_start
              len = lv_else_open - iv_start ).
            ev_else = substring(
              val = iv_template
              off = lv_else_after
              len = lv_open - lv_else_after ).
          ENDIF.
          ev_end = lv_end + 2.
          RETURN.
        ENDIF.
      ELSEIF ls_tag-kind = 'else' AND lv_depth = 1.
        IF lv_else_open >= 0.
          RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'Duplicate else in template block'.
        ENDIF.
        lv_else_open = lv_open.
        lv_else_after = lv_end + 2.
      ENDIF.

      lv_pos = lv_end + 2.
    ENDWHILE.

    RAISE EXCEPTION TYPE zcx_pdf_studio
      EXPORTING
        message = |Unclosed block /{ iv_close }|.
  ENDMETHOD.

  METHOD classify_tag.
    DATA lv_tag TYPE string.
    DATA lv_len TYPE i.

    lv_tag = trim( iv_tag ).
    lv_len = strlen( lv_tag ).

    IF lv_len = 0.
      rs_tag-kind = 'var'.
      RETURN.
    ENDIF.

    IF lv_tag(1) = '!'.
      rs_tag-kind = 'comment'.
      RETURN.
    ENDIF.

    IF lv_tag = 'else'.
      rs_tag-kind = 'else'.
      RETURN.
    ENDIF.

    IF lv_tag(1) = '/'.
      rs_tag-kind = 'close'.
      rs_tag-path = trim( substring( val = lv_tag off = 1 ) ).
      rs_tag-close = rs_tag-path.
      RETURN.
    ENDIF.

    "A trailing blank in a text literal is ignored in comparisons, so test the blank explicitly.
    IF lv_tag = '#each' OR ( lv_len >= 6 AND lv_tag(5) = '#each' AND find( val = lv_tag sub = ` ` ) = 5 ).
      rs_tag-kind = 'each'.
      rs_tag-close = 'each'.
      IF lv_len > 5.
        rs_tag-path = trim( substring( val = lv_tag off = 5 ) ).
      ENDIF.
      IF rs_tag-path IS INITIAL.
        rs_tag-path = '.'.
      ENDIF.
      RETURN.
    ENDIF.

    IF lv_tag = '#if' OR ( lv_len >= 4 AND lv_tag(3) = '#if' AND find( val = lv_tag sub = ` ` ) = 3 ).
      rs_tag-kind = 'if'.
      rs_tag-close = 'if'.
      IF lv_len > 3.
        rs_tag-path = trim( substring( val = lv_tag off = 3 ) ).
      ENDIF.
      IF rs_tag-path IS INITIAL.
        rs_tag-path = '.'.
      ENDIF.
      RETURN.
    ENDIF.

    IF lv_tag(1) = '#'.
      rs_tag-kind = 'section'.
      rs_tag-path = trim( substring( val = lv_tag off = 1 ) ).
      rs_tag-close = rs_tag-path.
      RETURN.
    ENDIF.

    IF lv_tag(1) = '^'.
      rs_tag-kind = 'inverted'.
      rs_tag-path = trim( substring( val = lv_tag off = 1 ) ).
      rs_tag-close = rs_tag-path.
      RETURN.
    ENDIF.

    rs_tag-kind = 'var'.
    rs_tag-path = lv_tag.
  ENDMETHOD.

  METHOD render_each.
    DATA lr_data TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    DATA lr_row TYPE REF TO data.
    FIELD-SYMBOLS <node> TYPE any.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.
    FIELD-SYMBOLS <row> TYPE any.

    try_resolve(
      EXPORTING
        iv_path  = iv_path
      IMPORTING
        eo_data  = lr_data
        ev_found = lv_found ).

    IF lv_found = abap_false.
      rv_result = render_template( iv_else ).
      RETURN.
    ENDIF.

    ASSIGN lr_data->* TO <node>.
    IF sy-subrc <> 0.
      rv_result = render_template( iv_else ).
      RETURN.
    ENDIF.

    IF cl_abap_typedescr=>describe_by_data( <node> )->kind
        = cl_abap_typedescr=>kind_struct.
      APPEND 1 TO mt_rowno.
      APPEND lr_data TO mt_ctx.
      rv_result = render_template( iv_inner ).
      DELETE mt_ctx INDEX lines( mt_ctx ).
      DELETE mt_rowno INDEX lines( mt_rowno ).
      RETURN.
    ENDIF.

    ASSIGN <node> TO <table>.
    IF sy-subrc <> 0.
      rv_result = render_template( iv_else ).
      RETURN.
    ENDIF.

    IF lines( <table> ) = 0.
      rv_result = render_template( iv_else ).
      RETURN.
    ENDIF.

    DATA lv_row_number TYPE i.
    LOOP AT <table> ASSIGNING <row>.
      lv_row_number = lv_row_number + 1.
      APPEND lv_row_number TO mt_rowno.
      GET REFERENCE OF <row> INTO lr_row.
      APPEND lr_row TO mt_ctx.
      rv_result = rv_result && render_template( iv_inner ).
      DELETE mt_ctx INDEX lines( mt_ctx ).
      DELETE mt_rowno INDEX lines( mt_rowno ).
    ENDLOOP.
  ENDMETHOD.

  METHOD render_if.
    DATA lr_data TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    DATA lv_yes TYPE abap_bool.
    DATA lv_upper TYPE string.
    DATA lv_row TYPE i.

    "{{#if ROW_EVEN}} / {{#if ROW_ODD}}: position inside the current {{#each}}.
    lv_upper = to_upper( trim( iv_path ) ).
    IF ( lv_upper = 'ROW_EVEN' OR lv_upper = 'ROW_ODD' ) AND lines( mt_rowno ) > 0.
      READ TABLE mt_rowno INDEX lines( mt_rowno ) INTO lv_row.
      lv_yes = xsdbool( lv_row MOD 2 = 0 ).
      IF lv_upper = 'ROW_ODD'.
        lv_yes = xsdbool( lv_yes = abap_false ).
      ENDIF.
      IF iv_inverted = abap_true.
        lv_yes = xsdbool( lv_yes = abap_false ).
      ENDIF.
      IF lv_yes = abap_true.
        rv_result = render_template( iv_inner ).
      ELSE.
        rv_result = render_template( iv_else ).
      ENDIF.
      RETURN.
    ENDIF.

    try_resolve(
      EXPORTING
        iv_path  = iv_path
      IMPORTING
        eo_data  = lr_data
        ev_found = lv_found ).

    IF lv_found = abap_true.
      lv_yes = is_truthy( lr_data ).
    ENDIF.

    IF iv_inverted = abap_true.
      lv_yes = xsdbool( lv_yes = abap_false ).
    ENDIF.

    IF lv_yes = abap_true.
      rv_result = render_template( iv_inner ).
    ELSE.
      rv_result = render_template( iv_else ).
    ENDIF.
  ENDMETHOD.

  METHOD resolve_raw.
    DATA lr_data TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA lv_dec TYPE decfloat34.
    FIELD-SYMBOLS <value> TYPE any.

    ev_kind = 'C'.
    IF to_upper( trim( iv_path ) ) = 'ROW' AND lines( mt_rowno ) > 0.
      ev_text = resolve_text( iv_path ).
      ev_kind = 'N'.
      RETURN.
    ENDIF.
    try_resolve( EXPORTING iv_path = iv_path IMPORTING eo_data = lr_data ev_found = lv_found ).
    IF lv_found = abap_false OR lr_data IS NOT BOUND.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |Unknown template field: { iv_path }|.
    ENDIF.
    ASSIGN lr_data->* TO <value>.
    lo_type = cl_abap_typedescr=>describe_by_data( <value> ).
    IF lo_type->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.
    CASE lo_type->type_kind.
      WHEN cl_abap_typedescr=>typekind_date.
        ev_text = <value>.
        ev_kind = 'D'.
      WHEN cl_abap_typedescr=>typekind_time.
        ev_text = <value>.
        ev_kind = 'T'.
      WHEN cl_abap_typedescr=>typekind_packed OR cl_abap_typedescr=>typekind_int
        OR cl_abap_typedescr=>typekind_int1 OR cl_abap_typedescr=>typekind_int2
        OR cl_abap_typedescr=>typekind_float OR cl_abap_typedescr=>typekind_decfloat
        OR cl_abap_typedescr=>typekind_decfloat16 OR cl_abap_typedescr=>typekind_decfloat34.
        lv_dec = <value>.
        ev_text = |{ lv_dec }|.
        ev_kind = 'N'.
      WHEN OTHERS.
        ev_text = <value>.
    ENDCASE.
  ENDMETHOD.

  METHOD resolve_text.
    DATA lr_data TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    IF to_upper( trim( iv_path ) ) = 'ROW' AND lines( mt_rowno ) > 0.
      READ TABLE mt_rowno INDEX lines( mt_rowno ) INTO DATA(lv_row).
      rv_text = |{ lv_row }|.
      RETURN.
    ENDIF.

    try_resolve(
      EXPORTING
        iv_path  = iv_path
      IMPORTING
        eo_data  = lr_data
        ev_found = lv_found ).
    IF lv_found = abap_false.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |Unknown template field: { iv_path }|.
    ENDIF.
    rv_text = value_to_string( lr_data ).
  ENDMETHOD.

  METHOD try_resolve.
    DATA lv_path TYPE string.
    DATA lv_skip TYPE i.
    DATA lv_index TYPE i.
    DATA lv_walk TYPE abap_bool.
    DATA lr_ctx TYPE REF TO data.
    DATA lr_found TYPE REF TO data.

    CLEAR eo_data.
    ev_found = abap_false.
    lv_path = trim( iv_path ).

    WHILE strlen( lv_path ) >= 3 AND lv_path(3) = '../'.
      lv_skip = lv_skip + 1.
      lv_path = substring( val = lv_path off = 3 ).
    ENDWHILE.
    lv_path = trim( lv_path ).

    lv_index = lines( mt_ctx ) - lv_skip.
    WHILE lv_index >= 1.
      READ TABLE mt_ctx INDEX lv_index INTO lr_ctx.
      CLEAR lr_found.
      CLEAR lv_walk.
      CALL METHOD walk
        EXPORTING
          io_data  = lr_ctx
          iv_path  = lv_path
        IMPORTING
          eo_data  = lr_found
        RECEIVING
          rv_found = lv_walk.
      IF lv_walk = abap_true.
        eo_data = lr_found.
        ev_found = abap_true.
        RETURN.
      ENDIF.
      lv_index = lv_index - 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD walk.
    DATA lv_path TYPE string.
    DATA lt_parts TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_part TYPE string.
    DATA lr_cur TYPE REF TO data.
    FIELD-SYMBOLS <node> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.

    rv_found = abap_false.
    CLEAR eo_data.
    IF io_data IS NOT BOUND.
      RETURN.
    ENDIF.

    lv_path = trim( iv_path ).
    REPLACE ALL OCCURRENCES OF '-' IN lv_path WITH '.'.
    IF lv_path IS INITIAL OR lv_path = '.'.
      eo_data = io_data.
      rv_found = abap_true.
      RETURN.
    ENDIF.

    lr_cur = io_data.
    SPLIT lv_path AT '.' INTO TABLE lt_parts.

    LOOP AT lt_parts INTO lv_part.
      lv_part = trim( lv_part ).
      IF lv_part IS INITIAL OR lv_part = '.'.
        CONTINUE.
      ENDIF.
      ASSIGN lr_cur->* TO <node>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF cl_abap_typedescr=>describe_by_data( <node> )->kind
          <> cl_abap_typedescr=>kind_struct.
        RETURN.
      ENDIF.
      ASSIGN COMPONENT to_upper( lv_part ) OF STRUCTURE <node> TO <comp>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      GET REFERENCE OF <comp> INTO lr_cur.
    ENDLOOP.

    eo_data = lr_cur.
    rv_found = abap_true.
  ENDMETHOD.

  METHOD is_truthy.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.

    rv_truthy = abap_false.
    IF io_data IS NOT BOUND.
      RETURN.
    ENDIF.

    ASSIGN io_data->* TO <value>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    lo_type = cl_abap_typedescr=>describe_by_data( <value> ).
    CASE lo_type->kind.
      WHEN cl_abap_typedescr=>kind_table.
        ASSIGN io_data->* TO <table>.
        IF sy-subrc = 0 AND lines( <table> ) > 0.
          rv_truthy = abap_true.
        ENDIF.
      WHEN cl_abap_typedescr=>kind_struct.
        rv_truthy = abap_true.
      WHEN OTHERS.
        IF <value> IS NOT INITIAL.
          rv_truthy = abap_true.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD value_to_string.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    FIELD-SYMBOLS <value> TYPE any.
    DATA lv_text TYPE string.
    DATA lv_char TYPE c LENGTH 255.

    IF io_data IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN io_data->* TO <value>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    lo_type = cl_abap_typedescr=>describe_by_data( <value> ).
    IF lo_type->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.

    CASE lo_type->type_kind.
      WHEN cl_abap_typedescr=>typekind_char
        OR cl_abap_typedescr=>typekind_string
        OR cl_abap_typedescr=>typekind_num.
        lv_text = <value>.
      WHEN OTHERS.
        WRITE <value> TO lv_char LEFT-JUSTIFIED.
        CONDENSE lv_char.
        lv_text = lv_char.
    ENDCASE.
    rv_text = lv_text.
  ENDMETHOD.

  METHOD sanitize_raw.
    "Allow-list sanitizer in one pass: text is copied, known tags are rebuilt from their
    "allowed attributes, dangerous elements are removed with their content, every other
    "tag is dropped (its text stays), and a stray '<' is escaped.
    DATA lt_out TYPE string_table.
    DATA lv_lower TYPE string.
    DATA lv_len TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_lt TYPE i.
    DATA lv_gt TYPE i.
    DATA lv_end TYPE i.
    DATA lv_next TYPE string.
    DATA lv_name TYPE string.
    DATA lv_tag TYPE string.

    IF iv_html NA '<'.
      rv_html = iv_html.
      RETURN.
    ENDIF.
    lv_lower = to_lower( iv_html ).
    lv_len = strlen( iv_html ).

    WHILE lv_pos < lv_len.
      lv_lt = find( val = iv_html sub = `<` off = lv_pos ).
      IF lv_lt < 0.
        APPEND substring( val = iv_html off = lv_pos ) TO lt_out.
        EXIT.
      ENDIF.
      IF lv_lt > lv_pos.
        APPEND substring( val = iv_html off = lv_pos len = lv_lt - lv_pos ) TO lt_out.
      ENDIF.
      lv_pos = lv_lt + 1.
      IF lv_pos >= lv_len.
        APPEND `&lt;` TO lt_out.
        EXIT.
      ENDIF.
      lv_next = substring( val = iv_html off = lv_pos len = 1 ).

      IF lv_next = `!` OR lv_next = `?`.
        "Comments, doctype, CDATA and processing instructions are removed.
        IF lv_pos + 3 <= lv_len AND substring( val = iv_html off = lv_pos len = 3 ) = `!--`.
          lv_end = find( val = iv_html sub = `-->` off = lv_pos + 3 ).
          IF lv_end < 0.
            EXIT.
          ENDIF.
          lv_pos = lv_end + 3.
        ELSE.
          lv_gt = find( val = iv_html sub = `>` off = lv_pos ).
          IF lv_gt < 0.
            EXIT.
          ENDIF.
          lv_pos = lv_gt + 1.
        ENDIF.

      ELSEIF lv_next = `/`.
        "Closing tag: kept only for allowed tags, without attributes.
        lv_gt = find( val = iv_html sub = `>` off = lv_pos ).
        IF lv_gt < 0.
          EXIT.
        ENDIF.
        lv_name = tag_name( iv_lower = lv_lower iv_start = lv_pos + 1 ).
        IF lv_name IS NOT INITIAL AND c_raw_tags CS |\|{ lv_name }\||.
          APPEND |</{ lv_name }>| TO lt_out.
        ENDIF.
        lv_pos = lv_gt + 1.

      ELSEIF lv_next CA c_raw_letters.
        lv_name = tag_name( iv_lower = lv_lower iv_start = lv_pos ).
        sanitize_tag(
          EXPORTING iv_html  = iv_html
                    iv_name  = lv_name
                    iv_start = lv_pos + strlen( lv_name )
          IMPORTING ev_tag   = lv_tag
                    ev_end   = lv_gt ).
        IF lv_gt < 0.
          "Unterminated tag: the rest of the value is dropped.
          EXIT.
        ENDIF.
        lv_pos = lv_gt + 1.
        IF c_raw_drop CS |\|{ lv_name }\||.
          lv_end = find( val = lv_lower sub = |</{ lv_name }| off = lv_pos ).
          IF lv_end < 0.
            EXIT.
          ENDIF.
          lv_gt = find( val = lv_lower sub = `>` off = lv_end ).
          IF lv_gt < 0.
            EXIT.
          ENDIF.
          lv_pos = lv_gt + 1.
        ELSEIF c_raw_tags CS |\|{ lv_name }\||.
          APPEND lv_tag TO lt_out.
        ENDIF.

      ELSE.
        "'<' that does not start a tag is text.
        APPEND `&lt;` TO lt_out.
      ENDIF.
    ENDWHILE.

    rv_html = concat_lines_of( table = lt_out ).
  ENDMETHOD.

  METHOD tag_name.
    DATA lv_pos TYPE i.
    DATA lv_len TYPE i.
    lv_len = strlen( iv_lower ).
    lv_pos = iv_start.
    WHILE lv_pos < lv_len.
      IF substring( val = iv_lower off = lv_pos len = 1 ) NA c_raw_namechar.
        EXIT.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.
    IF lv_pos > iv_start.
      rv_name = substring( val = iv_lower off = iv_start len = lv_pos - iv_start ).
    ENDIF.
  ENDMETHOD.

  METHOD sanitize_tag.
    "Attribute syntax as browsers read it: name, optional '=' and a quoted or unquoted value.
    DATA lv_sep TYPE string.
    DATA lv_stop TYPE string.
    DATA lv_len TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_start TYPE i.
    DATA lv_close TYPE i.
    DATA lv_ch TYPE string.
    DATA lv_attr TYPE string.
    DATA lv_value TYPE string.
    DATA lv_clean TYPE string.
    DATA lv_has_value TYPE abap_bool.

    lv_sep = | /\t\n\r| && cl_abap_char_utilities=>form_feed.
    lv_stop = lv_sep && `=>`.
    ev_tag = |<{ iv_name }|.
    ev_end = -1.
    lv_len = strlen( iv_html ).
    lv_pos = iv_start.

    WHILE lv_pos < lv_len.
      lv_ch = substring( val = iv_html off = lv_pos len = 1 ).
      IF lv_ch = `>`.
        ev_end = lv_pos.
        ev_tag = ev_tag && `>`.
        RETURN.
      ENDIF.
      IF lv_ch CA lv_sep.
        lv_pos = lv_pos + 1.
        CONTINUE.
      ENDIF.

      "Attribute name.
      lv_start = lv_pos.
      WHILE lv_pos < lv_len.
        IF substring( val = iv_html off = lv_pos len = 1 ) CA lv_stop.
          EXIT.
        ENDIF.
        lv_pos = lv_pos + 1.
      ENDWHILE.
      lv_attr = to_lower( substring( val = iv_html off = lv_start len = lv_pos - lv_start ) ).
      IF lv_attr IS INITIAL.
        "A lone '=' is skipped.
        lv_pos = lv_pos + 1.
        CONTINUE.
      ENDIF.

      "Optional value.
      CLEAR: lv_value, lv_has_value.
      WHILE lv_pos < lv_len.
        IF substring( val = iv_html off = lv_pos len = 1 ) NA lv_sep.
          EXIT.
        ENDIF.
        lv_pos = lv_pos + 1.
      ENDWHILE.
      IF lv_pos < lv_len AND substring( val = iv_html off = lv_pos len = 1 ) = `=`.
        lv_has_value = abap_true.
        lv_pos = lv_pos + 1.
        WHILE lv_pos < lv_len.
          IF substring( val = iv_html off = lv_pos len = 1 ) NA lv_sep.
            EXIT.
          ENDIF.
          lv_pos = lv_pos + 1.
        ENDWHILE.
        IF lv_pos < lv_len.
          lv_ch = substring( val = iv_html off = lv_pos len = 1 ).
          IF lv_ch = `"` OR lv_ch = `'`.
            lv_close = find( val = iv_html sub = lv_ch off = lv_pos + 1 ).
            IF lv_close < 0.
              RETURN.
            ENDIF.
            lv_value = substring( val = iv_html off = lv_pos + 1 len = lv_close - lv_pos - 1 ).
            lv_pos = lv_close + 1.
          ELSE.
            lv_start = lv_pos.
            WHILE lv_pos < lv_len.
              lv_ch = substring( val = iv_html off = lv_pos len = 1 ).
              IF lv_ch CA lv_sep OR lv_ch = `>`.
                EXIT.
              ENDIF.
              lv_pos = lv_pos + 1.
            ENDWHILE.
            lv_value = substring( val = iv_html off = lv_start len = lv_pos - lv_start ).
          ENDIF.
        ENDIF.
      ENDIF.

      "Keep allowed attributes only, with checked and re-escaped values.
      IF c_raw_attrs NS |\|{ lv_attr }\||.
        CONTINUE.
      ENDIF.
      lv_clean = decode_attr( lv_value ).
      IF ( lv_attr = `href` OR lv_attr = `src` )
          AND safe_url( iv_attr = lv_attr iv_value = lv_clean ) = abap_false.
        CONTINUE.
      ENDIF.
      IF lv_attr = `style` AND safe_style( lv_clean ) = abap_false.
        CONTINUE.
      ENDIF.
      IF lv_has_value = abap_true.
        ev_tag = ev_tag && | { lv_attr }="{ escape_attr( lv_clean ) }"|.
      ELSE.
        ev_tag = ev_tag && | { lv_attr }|.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

  METHOD decode_attr.
    "Character references as browsers decode them in attribute values (';' optional).
    DATA lv_len TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_amp TYPE i.
    DATA lv_stop TYPE i.
    DATA lv_ent TYPE string.
    DATA lv_num TYPE string.
    DATA lv_hex TYPE x LENGTH 4.
    DATA lv_code TYPE i.
    DATA lv_char TYPE string.

    lv_len = strlen( iv_value ).
    WHILE lv_pos < lv_len.
      lv_amp = find( val = iv_value sub = `&` off = lv_pos ).
      IF lv_amp < 0.
        rv_value = rv_value && substring( val = iv_value off = lv_pos ).
        RETURN.
      ENDIF.
      rv_value = rv_value && substring( val = iv_value off = lv_pos len = lv_amp - lv_pos ).
      lv_stop = lv_amp + 1.
      WHILE lv_stop < lv_len AND lv_stop - lv_amp <= 10.
        IF substring( val = iv_value off = lv_stop len = 1 ) NA |#{ c_raw_letters }0123456789|.
          EXIT.
        ENDIF.
        lv_stop = lv_stop + 1.
      ENDWHILE.
      lv_ent = to_lower( substring( val = iv_value off = lv_amp + 1 len = lv_stop - lv_amp - 1 ) ).
      lv_code = -1.
      IF strlen( lv_ent ) > 2 AND lv_ent(2) = `#x`.
        lv_num = to_upper( substring( val = lv_ent off = 2 ) ).
        IF lv_num CO '0123456789ABCDEF' AND strlen( lv_num ) <= 6.
          lv_num = |{ lv_num ALIGN = RIGHT WIDTH = 8 PAD = '0' }|.
          lv_hex = lv_num.
          lv_code = lv_hex.
        ENDIF.
      ELSEIF strlen( lv_ent ) > 1 AND lv_ent(1) = `#`.
        lv_num = substring( val = lv_ent off = 1 ).
        IF lv_num CO '0123456789' AND strlen( lv_num ) <= 7.
          lv_code = lv_num.
        ENDIF.
      ELSE.
        CASE lv_ent.
          WHEN `amp`.     lv_code = 38.
          WHEN `lt`.      lv_code = 60.
          WHEN `gt`.      lv_code = 62.
          WHEN `quot`.    lv_code = 34.
          WHEN `apos`.    lv_code = 39.
          WHEN `nbsp`.    lv_code = 160.
          WHEN `colon`.   lv_code = 58.
          WHEN `tab`.     lv_code = 9.
          WHEN `newline`. lv_code = 10.
          WHEN `sol`.     lv_code = 47.
          WHEN `lpar`.    lv_code = 40.
          WHEN `rpar`.    lv_code = 41.
          WHEN `semi`.    lv_code = 59.
        ENDCASE.
      ENDIF.
      IF lv_code < 0.
        "Not a character reference: the '&' is text.
        rv_value = rv_value && `&`.
        lv_pos = lv_amp + 1.
        CONTINUE.
      ENDIF.
      IF lv_code = 32.
        lv_char = ` `.
      ELSEIF lv_code > 0 AND lv_code < 65536 AND ( lv_code < 55296 OR lv_code > 57343 ).
        lv_char = cl_abap_conv_in_ce=>uccpi( lv_code ).
      ELSE.
        CLEAR lv_char.
      ENDIF.
      rv_value = rv_value && lv_char.
      lv_pos = lv_stop.
      IF lv_pos < lv_len AND substring( val = iv_value off = lv_pos len = 1 ) = `;`.
        lv_pos = lv_pos + 1.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

  METHOD safe_url.
    "Browsers ignore whitespace and control characters inside a URL scheme.
    DATA lv_url TYPE string.
    lv_url = to_lower( iv_value ).
    REPLACE ALL OCCURRENCES OF REGEX '[[:cntrl:][:space:]]' IN lv_url WITH ``.
    IF lv_url IS INITIAL.
      rv_yes = abap_true.
      RETURN.
    ENDIF.
    IF iv_attr = `src`.
      "Images must be embedded: no external or local URLs (no requests from the renderer).
      rv_yes = xsdbool( lv_url CP 'data:image/png;*' OR lv_url CP 'data:image/jpeg;*'
                     OR lv_url CP 'data:image/jpg;*' OR lv_url CP 'data:image/gif;*'
                     OR lv_url CP 'data:image/webp;*' ).
    ELSE.
      rv_yes = xsdbool( lv_url CP 'http://*' OR lv_url CP 'https://*'
                     OR lv_url CP 'mailto:*' OR lv_url CP '#*' ).
    ENDIF.
  ENDMETHOD.

  METHOD safe_style.
    DATA lv_css TYPE string.
    lv_css = to_lower( iv_value ).
    "Comments and escapes can split keywords (ur/**/l, \75rl), so both are removed first.
    REPLACE ALL OCCURRENCES OF REGEX '/\*[^*]*\*+([^/*][^*]*\*+)*/' IN lv_css WITH ``.
    REPLACE ALL OCCURRENCES OF REGEX '[[:cntrl:][:space:]]' IN lv_css WITH ``.
    rv_yes = xsdbool( lv_css NS '\' AND lv_css NS 'url(' AND lv_css NS 'expression('
                  AND lv_css NS 'javascript:' AND lv_css NS 'vbscript:' AND lv_css NS '@import'
                  AND lv_css NS 'behavior' AND lv_css NS '-moz-binding' AND lv_css NS 'image-set(' ).
  ENDMETHOD.

  METHOD escape_attr.
    rv_value = iv_value.
    REPLACE ALL OCCURRENCES OF '&' IN rv_value WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_value WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_value WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_value WITH '&quot;'.
    REPLACE ALL OCCURRENCES OF `'` IN rv_value WITH '&#39;'.
  ENDMETHOD.

  METHOD escape_html.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '&' IN rv_text WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_text WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_text WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_text WITH '&quot;'.
    REPLACE ALL OCCURRENCES OF `'` IN rv_text WITH '&#39;'.
  ENDMETHOD.

  METHOD trim.
    rv_text = iv_text.
    SHIFT rv_text LEFT DELETING LEADING space.
    SHIFT rv_text RIGHT DELETING TRAILING space.
  ENDMETHOD.

  METHOD serialize_json.
    DATA lo_writer TYPE REF TO cl_sxml_string_writer.
    DATA lv_json TYPE string.
    DATA lv_key_at TYPE i.
    DATA lv_from TYPE i.
    DATA lv_len TYPE i.

    TRY.
        lo_writer = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_json ).
        CALL TRANSFORMATION id
          SOURCE data = is_data
          RESULT XML lo_writer.
        lv_json = xstring_to_string( lo_writer->get_output( ) ).
      CATCH cx_root INTO DATA(lx_error).
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING
            previous = lx_error
            message  = |JSON serialization failed: { lx_error->get_text( ) }|.
    ENDTRY.

    lv_key_at = find( val = lv_json sub = '"DATA":' ).
    IF lv_key_at >= 0.
      lv_from = lv_key_at + 7.
      lv_len = strlen( lv_json ).
      IF lv_from < lv_len.
        lv_json = substring( val = lv_json off = lv_from ).
        lv_len = strlen( lv_json ).
        IF lv_len > 0 AND substring( val = lv_json off = lv_len - 1 ) = '}'.
          lv_json = substring( val = lv_json len = lv_len - 1 ).
        ENDIF.
      ENDIF.
    ENDIF.

    SHIFT lv_json LEFT DELETING LEADING space.
    rv_json = lv_json.
  ENDMETHOD.

  METHOD xstring_to_string.
    rv_string = zcl_pdf_studio_conv=>xstring_to_string( iv_xstring ).
  ENDMETHOD.

  METHOD field_catalog.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA lo_self TYPE REF TO zcl_pdf_studio_binder.
    DATA lv_name TYPE string.

    lv_name = to_upper( iv_type_name ).
    SHIFT lv_name LEFT DELETING LEADING space.
    SHIFT lv_name RIGHT DELETING TRAILING space.
    IF lv_name IS INITIAL.
      RETURN.
    ENDIF.

    CALL METHOD cl_abap_typedescr=>describe_by_name
      EXPORTING
        p_name         = lv_name
      RECEIVING
        p_descr_ref    = lo_type
      EXCEPTIONS
        type_not_found = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING
          message = |DDIC type { lv_name } does not exist|.
    ENDIF.

    lo_self = NEW zcl_pdf_studio_binder( ).
    CASE lo_type->kind.
      WHEN cl_abap_typedescr=>kind_struct.
        lo_self->add_components(
          io_struct     = CAST cl_abap_structdescr( lo_type )
          iv_rel_prefix = ''
          iv_abs_prefix = ''
          iv_parent     = ''
          iv_depth      = 0 ).
      WHEN cl_abap_typedescr=>kind_table.
        DATA(lo_line) = CAST cl_abap_tabledescr( lo_type )->get_table_line_type( ).
        IF lo_line->kind = cl_abap_typedescr=>kind_struct.
          lo_self->add_components(
            io_struct     = CAST cl_abap_structdescr( lo_line )
            iv_rel_prefix = ''
            iv_abs_prefix = ''
            iv_parent     = ''
            iv_depth      = 0 ).
        ENDIF.
      WHEN OTHERS.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING
            message = |{ lv_name } is not a structure or table type|.
    ENDCASE.
    rt_fields = lo_self->mt_fields.
  ENDMETHOD.

  METHOD field_catalog_json.
    DATA lt_fields TYPE ty_fields.
    DATA ls_field TYPE ty_field.
    DATA lv_sep TYPE string.

    lt_fields = field_catalog( iv_type_name ).
    rv_json = '['.
    LOOP AT lt_fields INTO ls_field.
      rv_json = rv_json && lv_sep &&
        '{"name":"' && json_escape( ls_field-name ) &&
        '","path":"' && json_escape( ls_field-path ) &&
        '","parent":"' && json_escape( ls_field-parent ) &&
        '","kind":"' && json_escape( ls_field-kind ) &&
        '","abapType":"' && json_escape( ls_field-abap_type ) &&
        '","length":' && |{ ls_field-length }| &&
        ',"insert":"' && json_escape( ls_field-insert ) && '"}'.
      lv_sep = ','.
    ENDLOOP.
    rv_json = rv_json && ']'.
  ENDMETHOD.

  METHOD json_escape.
    rv_text = escape( val = iv_text format = cl_abap_format=>e_json_string ).
  ENDMETHOD.

  METHOD add_components.
    DATA ls_comp TYPE abap_compdescr.
    DATA lo_comp TYPE REF TO cl_abap_datadescr.
    DATA ls_field TYPE ty_field.
    DATA lv_rel TYPE string.
    DATA lv_abs TYPE string.
    DATA lv_nl TYPE string.

    IF iv_depth > 8.
      RETURN.
    ENDIF.

    lv_nl = cl_abap_char_utilities=>newline.

    LOOP AT io_struct->components INTO ls_comp.
      lo_comp = io_struct->get_component_type( ls_comp-name ).
      IF iv_rel_prefix IS INITIAL.
        lv_rel = ls_comp-name.
      ELSE.
        lv_rel = iv_rel_prefix && '.' && ls_comp-name.
      ENDIF.
      IF iv_abs_prefix IS INITIAL.
        lv_abs = ls_comp-name.
      ELSE.
        lv_abs = iv_abs_prefix && '.' && ls_comp-name.
      ENDIF.

      CLEAR ls_field.
      ls_field-name = ls_comp-name.
      ls_field-path = lv_abs.
      ls_field-parent = iv_parent.

      CASE lo_comp->kind.
        WHEN cl_abap_typedescr=>kind_elem.
          ls_field-kind = 'field'.
          ls_field-abap_type = elem_type( CAST cl_abap_elemdescr( lo_comp ) ).
          ls_field-length = CAST cl_abap_elemdescr( lo_comp )->length.
          ls_field-insert = '{{' && lv_rel && '}}'.
          APPEND ls_field TO mt_fields.
        WHEN cl_abap_typedescr=>kind_struct.
          ls_field-kind = 'structure'.
          ls_field-abap_type = 'STRUCTURE'.
          APPEND ls_field TO mt_fields.
          add_components(
            io_struct     = CAST cl_abap_structdescr( lo_comp )
            iv_rel_prefix = lv_rel
            iv_abs_prefix = lv_abs
            iv_parent     = lv_abs
            iv_depth      = iv_depth + 1 ).
        WHEN cl_abap_typedescr=>kind_table.
          DATA(lo_line) = CAST cl_abap_tabledescr( lo_comp )->get_table_line_type( ).
          ls_field-kind = 'table'.
          ls_field-abap_type = 'TABLE'.
          ls_field-insert = '{{#each ' && lv_rel && '}}' && lv_nl && '{{/each}}'.
          APPEND ls_field TO mt_fields.
          IF lo_line->kind = cl_abap_typedescr=>kind_struct.
            add_components(
              io_struct     = CAST cl_abap_structdescr( lo_line )
              iv_rel_prefix = ''
              iv_abs_prefix = lv_abs
              iv_parent     = lv_abs
              iv_depth      = iv_depth + 1 ).
          ELSEIF lo_line->kind = cl_abap_typedescr=>kind_elem.
            CLEAR ls_field.
            ls_field-name = '.'.
            ls_field-path = lv_abs && '.'.
            ls_field-parent = lv_abs.
            ls_field-kind = 'field'.
            ls_field-abap_type = elem_type( CAST cl_abap_elemdescr( lo_line ) ).
            ls_field-insert = '{{.}}'.
            APPEND ls_field TO mt_fields.
          ENDIF.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD elem_type.
    CASE io_elem->type_kind.
      WHEN cl_abap_typedescr=>typekind_char.
        rv_abap_type = 'CHAR'.
      WHEN cl_abap_typedescr=>typekind_num.
        rv_abap_type = 'NUMC'.
      WHEN cl_abap_typedescr=>typekind_date.
        rv_abap_type = 'DATE'.
      WHEN cl_abap_typedescr=>typekind_time.
        rv_abap_type = 'TIME'.
      WHEN cl_abap_typedescr=>typekind_packed.
        rv_abap_type = 'DEC'.
      WHEN cl_abap_typedescr=>typekind_int
        OR cl_abap_typedescr=>typekind_int1
        OR cl_abap_typedescr=>typekind_int2.
        rv_abap_type = 'INT'.
      WHEN cl_abap_typedescr=>typekind_float
        OR cl_abap_typedescr=>typekind_decfloat
        OR cl_abap_typedescr=>typekind_decfloat16
        OR cl_abap_typedescr=>typekind_decfloat34.
        rv_abap_type = 'FLOAT'.
      WHEN cl_abap_typedescr=>typekind_string.
        rv_abap_type = 'STRING'.
      WHEN cl_abap_typedescr=>typekind_xstring
        OR cl_abap_typedescr=>typekind_hex.
        rv_abap_type = 'RAW'.
      WHEN OTHERS.
        rv_abap_type = io_elem->type_kind.
    ENDCASE.
  ENDMETHOD.

  METHOD is_aggregate.
    DATA lv_tag TYPE string.
    DATA lv_word TYPE string.
    DATA lv_rest TYPE string.

    lv_tag = condense( iv_tag ).
    SPLIT lv_tag AT ` ` INTO lv_word lv_rest.
    lv_word = to_lower( lv_word ).
    IF lv_rest IS NOT INITIAL
        AND ( lv_word = 'sum' OR lv_word = 'count' OR lv_word = 'avg' OR lv_word = 'min' OR lv_word = 'max' ).
      rv_yes = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD parse_number.
    DATA lv_text TYPE string.
    DATA lv_clean TYPE string.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_neg TYPE abap_bool.
    DATA lv_dot TYPE i.
    DATA lv_comma TYPE i.
    DATA lv_dots TYPE i.
    DATA lv_commas TYPE i.
    DATA lv_dec TYPE string.
    DATA lv_grp TYPE string.
    DATA lv_at TYPE i.
    DATA lv_digit TYPE c LENGTH 1.
    DATA lv_code TYPE i.

    CLEAR: ev_value, ev_ok, ev_decimals, ev_dec_sep, ev_grouped.
    lv_text = iv_text.
    "Arabic-Indic digits and separators.
    DO 10 TIMES.
      lv_code = 1631 + sy-index.
      lv_digit = cl_abap_conv_in_ce=>uccpi( lv_code ).
      lv_c = sy-index - 1.
      REPLACE ALL OCCURRENCES OF lv_digit IN lv_text WITH lv_c.
    ENDDO.
    lv_digit = cl_abap_conv_in_ce=>uccpi( 1643 ).
    REPLACE ALL OCCURRENCES OF lv_digit IN lv_text WITH '.'.
    lv_digit = cl_abap_conv_in_ce=>uccpi( 1644 ).
    REPLACE ALL OCCURRENCES OF lv_digit IN lv_text WITH ','.

    lv_len = strlen( lv_text ).
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_c = lv_text+lv_i(1).
      IF lv_c CA '0123456789'.
        lv_clean = lv_clean && lv_c.
      ELSEIF lv_c = '.'.
        lv_clean = lv_clean && lv_c.
        lv_dots = lv_dots + 1.
      ELSEIF lv_c = ','.
        lv_clean = lv_clean && lv_c.
        lv_commas = lv_commas + 1.
      ELSEIF lv_c = '-'.
        lv_neg = abap_true.
      ENDIF.
    ENDDO.
    IF lv_clean NA '0123456789'.
      RETURN.
    ENDIF.

    lv_dot = find( val = lv_clean sub = '.' occ = -1 ).
    lv_comma = find( val = lv_clean sub = ',' occ = -1 ).
    IF lv_dot >= 0 AND lv_comma >= 0.
      IF lv_dot > lv_comma.
        lv_dec = '.'.
        lv_grp = ','.
      ELSE.
        lv_dec = ','.
        lv_grp = '.'.
      ENDIF.
    ELSEIF lv_comma >= 0.
      "One comma not followed by exactly three digits is a decimal comma.
      IF lv_commas = 1 AND strlen( lv_clean ) - lv_comma - 1 <> 3.
        lv_dec = ','.
      ELSE.
        lv_grp = ','.
      ENDIF.
    ELSEIF lv_dot >= 0.
      IF lv_dots = 1.
        lv_dec = '.'.
      ELSE.
        lv_grp = '.'.
      ENDIF.
    ENDIF.
    IF lv_grp IS NOT INITIAL.
      REPLACE ALL OCCURRENCES OF lv_grp IN lv_clean WITH ``.
      ev_grouped = abap_true.
    ENDIF.
    IF lv_dec IS NOT INITIAL.
      lv_at = find( val = lv_clean sub = lv_dec occ = -1 ).
      ev_decimals = strlen( lv_clean ) - lv_at - 1.
      REPLACE ALL OCCURRENCES OF lv_dec IN lv_clean WITH '.'.
      ev_dec_sep = lv_dec.
    ENDIF.
    IF lv_clean(1) = '.'.
      lv_clean = '0' && lv_clean.
    ENDIF.
    IF substring( val = lv_clean off = strlen( lv_clean ) - 1 len = 1 ) = '.'.
      lv_clean = lv_clean && '0'.
    ENDIF.
    IF lv_clean CN '0123456789.' OR strlen( lv_clean ) > 30.
      RETURN.
    ENDIF.
    TRY.
        ev_value = lv_clean.
      CATCH cx_root.
        RETURN.
    ENDTRY.
    IF lv_neg = abap_true.
      ev_value = 0 - ev_value.
    ENDIF.
    ev_ok = abap_true.
  ENDMETHOD.

  METHOD format_number.
    DATA lv_p TYPE p LENGTH 16 DECIMALS 6.
    DATA lv_raw TYPE string.
    DATA lv_int TYPE string.
    DATA lv_frac TYPE string.
    DATA lv_out TYPE string.
    DATA lv_len TYPE i.
    DATA lv_count TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_decimals TYPE i.
    DATA lv_neg TYPE abap_bool.
    DATA lv_dec TYPE string.
    DATA lv_grp TYPE string.

    lv_decimals = iv_decimals.
    IF lv_decimals < 0.
      lv_decimals = 0.
    ELSEIF lv_decimals > 6.
      lv_decimals = 6.
    ENDIF.
    lv_p = round( val = iv_value dec = lv_decimals ).
    IF lv_p < 0.
      lv_neg = abap_true.
      lv_p = 0 - lv_p.
    ENDIF.
    lv_raw = |{ lv_p }|.
    SPLIT lv_raw AT '.' INTO lv_int lv_frac.
    IF lv_decimals > 0.
      lv_frac = lv_frac && '000000'.
      lv_frac = lv_frac(lv_decimals).
    ELSE.
      CLEAR lv_frac.
    ENDIF.

    lv_dec = iv_dec_sep.
    IF lv_dec IS INITIAL.
      lv_dec = '.'.
    ENDIF.
    lv_grp = iv_group_sep.
    IF iv_arabic = abap_true.
      lv_dec = cl_abap_conv_in_ce=>uccpi( 1643 ).
      IF lv_grp IS NOT INITIAL.
        lv_grp = cl_abap_conv_in_ce=>uccpi( 1644 ).
      ENDIF.
    ENDIF.

    lv_len = strlen( lv_int ).
    lv_i = lv_len.
    WHILE lv_i > 0.
      lv_i = lv_i - 1.
      lv_c = lv_int+lv_i(1).
      IF lv_count > 0 AND lv_count MOD 3 = 0 AND lv_grp IS NOT INITIAL.
        lv_out = lv_grp && lv_out.
      ENDIF.
      lv_out = lv_c && lv_out.
      lv_count = lv_count + 1.
    ENDWHILE.
    IF lv_frac IS NOT INITIAL.
      lv_out = lv_out && lv_dec && lv_frac.
    ENDIF.
    IF lv_neg = abap_true AND lv_p <> 0.
      lv_out = '-' && lv_out.
    ENDIF.
    IF iv_arabic = abap_true.
      lv_out = arabic_digits( lv_out ).
    ENDIF.
    rv_text = lv_out.
  ENDMETHOD.

  METHOD number_pattern.
    DATA lv_pattern TYPE string.
    DATA lv_arabic TYPE abap_bool.
    DATA lv_value TYPE decfloat34.
    DATA lv_ok TYPE abap_bool.
    DATA lv_decimals TYPE i.
    DATA lv_dec_sep TYPE string.
    DATA lv_grouped TYPE abap_bool.
    DATA lv_dot TYPE i.
    DATA lv_comma TYPE i.
    DATA lv_last TYPE i.
    DATA lv_sep TYPE string.
    DATA lv_after TYPE string.
    DATA lv_dec TYPE string.
    DATA lv_grp TYPE string.
    DATA lv_places TYPE i.

    rv_text = iv_value.
    lv_pattern = condense( iv_pattern ).
    IF strlen( lv_pattern ) > 2 AND lv_pattern(2) = 'AR'.
      lv_arabic = abap_true.
      lv_pattern = substring( val = lv_pattern off = 2 ).
    ENDIF.
    parse_number(
      EXPORTING iv_text = iv_value
      IMPORTING ev_value = lv_value ev_ok = lv_ok ev_decimals = lv_decimals
                ev_dec_sep = lv_dec_sep ev_grouped = lv_grouped ).
    IF lv_ok = abap_false.
      RETURN.
    ENDIF.

    "#,##0.00 / #.##0,00 / 0.00 / 0,00 / #,##0 / #.##0 / 0
    lv_dot = find( val = lv_pattern sub = '.' occ = -1 ).
    lv_comma = find( val = lv_pattern sub = ',' occ = -1 ).
    IF lv_dot >= 0 AND lv_comma >= 0.
      IF lv_dot > lv_comma.
        lv_dec = '.'.
        lv_grp = ','.
        lv_last = lv_dot.
      ELSE.
        lv_dec = ','.
        lv_grp = '.'.
        lv_last = lv_comma.
      ENDIF.
    ELSEIF lv_dot >= 0 OR lv_comma >= 0.
      lv_last = nmax( val1 = lv_dot val2 = lv_comma ).
      lv_sep = lv_pattern+lv_last(1).
      lv_after = substring( val = lv_pattern off = lv_last + 1 ).
      IF lv_after CO '0' AND ( lv_pattern(1) = '0' OR strlen( lv_after ) <> 3 ).
        lv_dec = lv_sep.
      ELSE.
        lv_grp = lv_sep.
        lv_last = -1.
      ENDIF.
    ELSE.
      lv_last = -1.
    ENDIF.
    IF lv_dec IS NOT INITIAL AND lv_last >= 0.
      lv_places = strlen( lv_pattern ) - lv_last - 1.
    ENDIF.
    rv_text = format_number( iv_value = lv_value iv_decimals = lv_places
                             iv_dec_sep = lv_dec iv_group_sep = lv_grp iv_arabic = lv_arabic ).
  ENDMETHOD.

  METHOD aggregate.
    DATA lt_words TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_op TYPE string.
    DATA lv_term TYPE string.
    DATA lv_table TYPE string.
    DATA lv_field TYPE string.
    DATA lv_at TYPE i.
    DATA lr_data TYPE REF TO data.
    DATA lr_row TYPE REF TO data.
    DATA lr_value TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    DATA lt_texts TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_text TYPE string.
    DATA lv_rows TYPE i.
    DATA lv_value TYPE decfloat34.
    DATA lv_ok TYPE abap_bool.
    DATA lv_decimals TYPE i.
    DATA lv_dec_sep TYPE string.
    DATA lv_grouped TYPE abap_bool.
    DATA lv_sum TYPE decfloat34.
    DATA lv_min TYPE decfloat34.
    DATA lv_max TYPE decfloat34.
    DATA lv_result TYPE decfloat34.
    DATA lv_numbers TYPE i.
    DATA lv_places TYPE i.
    DATA lv_dec TYPE string.
    DATA lv_any_group TYPE abap_bool.
    DATA lv_grp TYPE string.
    FIELD-SYMBOLS <lv_node> TYPE any.
    FIELD-SYMBOLS <lt_table> TYPE ANY TABLE.
    FIELD-SYMBOLS <lv_row> TYPE any.

    lv_text = condense( iv_tag ).
    SPLIT lv_text AT ` ` INTO TABLE lt_words.
    DELETE lt_words WHERE table_line IS INITIAL.
    READ TABLE lt_words INTO lv_op INDEX 1.
    lv_op = to_lower( lv_op ).
    DELETE lt_words INDEX 1.

    "Collect the values (or row counts) of every term.
    LOOP AT lt_words INTO lv_term.
      IF lv_term CO '0123456789.,-'.
        IF lv_op = 'count'.
          parse_number( EXPORTING iv_text = lv_term IMPORTING ev_value = lv_value ev_ok = lv_ok ).
          IF lv_ok = abap_true.
            lv_rows = lv_rows + lv_value.
          ENDIF.
        ELSE.
          APPEND lv_term TO lt_texts.
        ENDIF.
        CONTINUE.
      ENDIF.
      IF lv_op = 'count'.
        lv_table = lv_term.
        CLEAR lv_field.
      ELSE.
        lv_at = find( val = lv_term sub = '.' occ = -1 ).
        IF lv_at > 0.
          lv_table = substring( val = lv_term len = lv_at ).
          lv_field = substring( val = lv_term off = lv_at + 1 ).
        ELSE.
          lv_table = lv_term.
          CLEAR lv_field.
        ENDIF.
      ENDIF.
      try_resolve( EXPORTING iv_path = lv_table IMPORTING eo_data = lr_data ev_found = lv_found ).
      IF lv_found = abap_false.
        RAISE EXCEPTION TYPE zcx_pdf_studio
          EXPORTING message = |Unknown template field in { lv_op }: { lv_table }|.
      ENDIF.
      ASSIGN lr_data->* TO <lv_node>.
      IF cl_abap_typedescr=>describe_by_data( <lv_node> )->kind = cl_abap_typedescr=>kind_table.
        ASSIGN lr_data->* TO <lt_table>.
        IF lv_op = 'count'.
          lv_rows = lv_rows + lines( <lt_table> ).
          CONTINUE.
        ENDIF.
        LOOP AT <lt_table> ASSIGNING <lv_row>.
          GET REFERENCE OF <lv_row> INTO lr_row.
          IF lv_field IS INITIAL.
            APPEND value_to_string( lr_row ) TO lt_texts.
          ELSEIF walk( EXPORTING io_data = lr_row iv_path = lv_field IMPORTING eo_data = lr_value ) = abap_true.
            APPEND value_to_string( lr_value ) TO lt_texts.
          ENDIF.
        ENDLOOP.
      ELSE.
        IF lv_op = 'count'.
          lv_rows = lv_rows + 1.
        ELSEIF lv_field IS INITIAL.
          APPEND value_to_string( lr_data ) TO lt_texts.
        ELSEIF walk( EXPORTING io_data = lr_data iv_path = lv_field IMPORTING eo_data = lr_value ) = abap_true.
          APPEND value_to_string( lr_value ) TO lt_texts.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF lv_op = 'count'.
      rv_text = |{ lv_rows }|.
      RETURN.
    ENDIF.

    LOOP AT lt_texts INTO lv_text.
      parse_number(
        EXPORTING iv_text = lv_text
        IMPORTING ev_value = lv_value ev_ok = lv_ok ev_decimals = lv_decimals
                  ev_dec_sep = lv_dec_sep ev_grouped = lv_grouped ).
      IF lv_ok = abap_false.
        CONTINUE.
      ENDIF.
      IF lv_numbers = 0.
        lv_min = lv_value.
        lv_max = lv_value.
      ELSE.
        lv_min = nmin( val1 = lv_min val2 = lv_value ).
        lv_max = nmax( val1 = lv_max val2 = lv_value ).
      ENDIF.
      lv_sum = lv_sum + lv_value.
      lv_numbers = lv_numbers + 1.
      lv_places = nmax( val1 = lv_places val2 = lv_decimals ).
      IF lv_dec IS INITIAL AND lv_dec_sep IS NOT INITIAL.
        lv_dec = lv_dec_sep.
      ENDIF.
      IF lv_grouped = abap_true.
        lv_any_group = abap_true.
      ENDIF.
    ENDLOOP.

    CASE lv_op.
      WHEN 'sum'.
        lv_result = lv_sum.
      WHEN 'avg'.
        IF lv_numbers = 0.
          RETURN.
        ENDIF.
        lv_result = lv_sum / lv_numbers.
        lv_places = nmax( val1 = lv_places val2 = 2 ).
      WHEN 'min'.
        IF lv_numbers = 0.
          RETURN.
        ENDIF.
        lv_result = lv_min.
      WHEN 'max'.
        IF lv_numbers = 0.
          RETURN.
        ENDIF.
        lv_result = lv_max.
    ENDCASE.
    IF lv_dec IS INITIAL.
      lv_dec = '.'.
    ENDIF.
    IF lv_any_group = abap_true.
      lv_grp = COND #( WHEN lv_dec = ',' THEN '.' ELSE ',' ).
    ENDIF.
    rv_text = format_number( iv_value = lv_result iv_decimals = lv_places
                             iv_dec_sep = lv_dec iv_group_sep = lv_grp ).
  ENDMETHOD.
ENDCLASS.
