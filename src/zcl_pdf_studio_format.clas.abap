"! <p>Output formats of ZPDF Studio (data-fmt="..." or {{FIELD | pattern}}).</p>
"! <ul>
"! <li>Dates and times: DD.MM.YYYY, D MMMM YYYY, dddd, DD/MM/YY, YYYY-MM-DD HH:mm, 'quoted text',
"!     ISO (YYYY-MM-DD), SAP (user settings of the printing user). Month and day names: Turkish,
"!     German or English (language of the output, see iv_lang).</li>
"! <li>Numbers: #,##0.00  #.##0,00  0.000  #,##0  with literal prefix or suffix (₺ #.##0,00 / %),
"!     an optional negative part after ';' ( #,##0.00;(#,##0.00) ), AR prefix for Arabic digits.</li>
"! <li>Keywords: SAP (user number format), SAP:EUR (decimals of a currency, table TCURX),
"!     WORDS / WORDS:TRY (amount in words), UPPER, LOWER, TITLE (Turkish aware), ALPHA (no leading zeros),
"!     TRIM. Steps can be chained with '|': WORDS:TRY|UPPER.</li>
"! </ul>
CLASS zcl_pdf_studio_format DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Kind of the raw value: D date (YYYYMMDD), T time (HHMMSS), N number (1234.50), C text.
    TYPES ty_kind TYPE c LENGTH 1.

    CLASS-METHODS format
      IMPORTING
        iv_value       TYPE string
        iv_pattern     TYPE string
        iv_kind        TYPE ty_kind DEFAULT 'C'
        iv_lang        TYPE sy-langu DEFAULT sy-langu
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS format_date
      IMPORTING
        iv_date        TYPE d
        iv_time        TYPE t OPTIONAL
        iv_pattern     TYPE string
        iv_lang        TYPE sy-langu DEFAULT sy-langu
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS format_number
      IMPORTING
        iv_value       TYPE decfloat34
        iv_pattern     TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    "! Amount in words, e.g. 1250.50 TRY -> "bin iki yüz elli Türk lirası elli kuruş".
    CLASS-METHODS amount_in_words
      IMPORTING
        iv_amount      TYPE decfloat34
        iv_currency    TYPE csequence OPTIONAL
        iv_lang        TYPE sy-langu DEFAULT sy-langu
      RETURNING
        VALUE(rv_text) TYPE string.

    "! Whole number in words (Turkish, German or English).
    CLASS-METHODS number_in_words
      IMPORTING
        iv_number      TYPE decfloat34
        iv_lang        TYPE sy-langu DEFAULT sy-langu
      RETURNING
        VALUE(rv_text) TYPE string.

    "! Reads YYYYMMDD, YYYY-MM-DD, DD.MM.YYYY, DD/MM/YYYY (optionally followed by a time).
    CLASS-METHODS parse_date
      IMPORTING
        iv_text TYPE csequence
      EXPORTING
        ev_date TYPE d
        ev_time TYPE t
        ev_ok   TYPE abap_bool.

    "! Reads 1234.5, 1.234,50, 1,234.50, -12 ...
    CLASS-METHODS parse_number
      IMPORTING
        iv_text  TYPE csequence
      EXPORTING
        ev_value TYPE decfloat34
        ev_ok    TYPE abap_bool.

    "! Upper case with the Turkish rules (i -> İ, ı -> I) when the language is Turkish.
    CLASS-METHODS upper
      IMPORTING
        iv_text        TYPE csequence
        iv_lang        TYPE sy-langu DEFAULT sy-langu
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS lower
      IMPORTING
        iv_text        TYPE csequence
        iv_lang        TYPE sy-langu DEFAULT sy-langu
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS is_date_pattern
      IMPORTING
        iv_pattern    TYPE csequence
      RETURNING
        VALUE(rv_yes) TYPE abap_bool.

  PRIVATE SECTION.
    TYPES ty_strings TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    CLASS-METHODS step
      IMPORTING
        iv_value       TYPE string
        iv_pattern     TYPE string
        iv_kind        TYPE ty_kind
        iv_lang        TYPE sy-langu
      RETURNING
        VALUE(rv_text) TYPE string.
    CLASS-METHODS names
      IMPORTING
        iv_kind         TYPE string
        iv_lang         TYPE sy-langu
      RETURNING
        VALUE(rt_names) TYPE ty_strings.
    CLASS-METHODS words_below_1000
      IMPORTING
        iv_number      TYPE i
        iv_lang        TYPE sy-langu
      RETURNING
        VALUE(rv_text) TYPE string.
    CLASS-METHODS currency_names
      IMPORTING
        iv_currency TYPE csequence
        iv_lang     TYPE sy-langu
      EXPORTING
        ev_major    TYPE string
        ev_minor    TYPE string.
    CLASS-METHODS lang
      IMPORTING
        iv_lang        TYPE sy-langu
      RETURNING
        VALUE(rv_lang) TYPE string.
    CLASS-METHODS group
      IMPORTING
        iv_digits      TYPE string
        iv_sep         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
    "Case-sensitive prefix test (CP ignores the case: MM month, mm minutes).
    CLASS-METHODS starts
      IMPORTING
        iv_text       TYPE string
        iv_prefix     TYPE string
      RETURNING
        VALUE(rv_yes) TYPE abap_bool.
    CLASS-METHODS pad2
      IMPORTING
        iv_value       TYPE i
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.



CLASS zcl_pdf_studio_format IMPLEMENTATION.

  METHOD lang.
    CASE iv_lang.
      WHEN 'T'.
        rv_lang = `TR`.
      WHEN 'D'.
        rv_lang = `DE`.
      WHEN OTHERS.
        rv_lang = `EN`.
    ENDCASE.
  ENDMETHOD.


  METHOD format.
    DATA lt_steps TYPE ty_strings.
    DATA lv_step TYPE string.
    DATA lv_kind TYPE ty_kind.

    rv_text = iv_value.
    IF iv_pattern IS INITIAL.
      RETURN.
    ENDIF.
    lv_kind = iv_kind.
    SPLIT iv_pattern AT '|' INTO TABLE lt_steps.
    LOOP AT lt_steps INTO lv_step.
      lv_step = condense( lv_step ).
      IF lv_step IS INITIAL.
        CONTINUE.
      ENDIF.
      rv_text = step( iv_value = rv_text iv_pattern = lv_step iv_kind = lv_kind iv_lang = iv_lang ).
      "After the first step the value is text.
      lv_kind = 'C'.
    ENDLOOP.
  ENDMETHOD.


  METHOD step.
    DATA lv_upper TYPE string.
    DATA lv_date TYPE d.
    DATA lv_time TYPE t.
    DATA lv_ok TYPE abap_bool.
    DATA lv_number TYPE decfloat34.
    DATA lv_cur TYPE string.
    DATA lv_p TYPE p LENGTH 16 DECIMALS 6.
    DATA lv_out TYPE c LENGTH 64.
    DATA lv_waers TYPE c LENGTH 5.
    DATA lv_amount TYPE p LENGTH 16 DECIMALS 2.

    rv_text = iv_value.
    lv_upper = to_upper( iv_pattern ).

    "Text keywords.
    CASE lv_upper.
      WHEN `UPPER`.
        rv_text = upper( iv_text = iv_value iv_lang = iv_lang ).
        RETURN.
      WHEN `LOWER`.
        rv_text = lower( iv_text = iv_value iv_lang = iv_lang ).
        RETURN.
      WHEN `TITLE`.
        rv_text = lower( iv_text = iv_value iv_lang = iv_lang ).
        IF rv_text IS NOT INITIAL.
          rv_text = upper( iv_text = substring( val = rv_text len = 1 ) iv_lang = iv_lang ) && substring( val = rv_text off = 1 ).
        ENDIF.
        RETURN.
      WHEN `TRIM`.
        rv_text = condense( iv_value ).
        RETURN.
      WHEN `ALPHA`.
        rv_text = iv_value.
        SHIFT rv_text LEFT DELETING LEADING '0 '.
        IF rv_text IS INITIAL AND iv_value IS NOT INITIAL.
          rv_text = `0`.
        ENDIF.
        RETURN.
    ENDCASE.

    "Amount in words.
    IF lv_upper = `WORDS` OR lv_upper CP 'WORDS:*'.
      parse_number( EXPORTING iv_text = iv_value IMPORTING ev_value = lv_number ev_ok = lv_ok ).
      IF lv_ok = abap_true.
        IF lv_upper CP 'WORDS:*'.
          lv_cur = substring( val = lv_upper off = 6 ).
        ENDIF.
        rv_text = amount_in_words( iv_amount = lv_number iv_currency = lv_cur iv_lang = iv_lang ).
      ENDIF.
      RETURN.
    ENDIF.

    "Dates and times.
    IF iv_kind = 'D' OR iv_kind = 'T' OR is_date_pattern( iv_pattern ) = abap_true
        OR ( lv_upper = `ISO` AND iv_kind <> 'N' ).
      IF iv_kind = 'T'.
        lv_time = iv_value.
        lv_ok = abap_true.
      ELSE.
        parse_date( EXPORTING iv_text = iv_value IMPORTING ev_date = lv_date ev_time = lv_time ev_ok = lv_ok ).
      ENDIF.
      IF lv_ok = abap_false.
        RETURN.
      ENDIF.
      IF lv_upper = `SAP`.
        IF iv_kind = 'T'.
          WRITE lv_time TO lv_out.
        ELSE.
          WRITE lv_date TO lv_out.
        ENDIF.
        rv_text = condense( lv_out ).
      ELSEIF lv_upper = `ISO`.
        rv_text = format_date( iv_date = lv_date iv_time = lv_time iv_pattern = `YYYY-MM-DD` iv_lang = iv_lang ).
      ELSE.
        rv_text = format_date( iv_date = lv_date iv_time = lv_time iv_pattern = iv_pattern iv_lang = iv_lang ).
      ENDIF.
      RETURN.
    ENDIF.

    "Numbers.
    parse_number( EXPORTING iv_text = iv_value IMPORTING ev_value = lv_number ev_ok = lv_ok ).
    IF lv_ok = abap_false.
      RETURN.
    ENDIF.
    IF lv_upper = `SAP`.
      lv_p = lv_number.
      WRITE lv_p TO lv_out DECIMALS 2 LEFT-JUSTIFIED.
      rv_text = condense( lv_out ).
    ELSEIF lv_upper CP 'SAP:*'.
      "Currency amount with the decimals of the currency (TCURX) and the user's notation.
      lv_waers = substring( val = lv_upper off = 4 ).
      lv_amount = lv_number.
      WRITE lv_amount TO lv_out CURRENCY lv_waers LEFT-JUSTIFIED.
      rv_text = condense( lv_out ).
    ELSE.
      rv_text = format_number( iv_value = lv_number iv_pattern = iv_pattern ).
    ENDIF.
  ENDMETHOD.


  METHOD is_date_pattern.
    DATA lv_pattern TYPE string.
    lv_pattern = iv_pattern.
    "Quoted text does not count.
    REPLACE ALL OCCURRENCES OF REGEX `'[^']*'` IN lv_pattern WITH ``.
    rv_yes = xsdbool( lv_pattern CS 'YY' OR lv_pattern CS 'DD' OR lv_pattern CS 'MM' OR lv_pattern CS 'HH'
                   OR lv_pattern CS 'dd' OR lv_pattern CS 'mm' OR lv_pattern CS 'ss'
                   OR ( lv_pattern CA 'DMY' AND lv_pattern NA '#0' ) ).
    IF to_upper( iv_pattern ) = `SAP` OR to_upper( iv_pattern ) CP 'SAP:*'.
      rv_yes = abap_false.
    ENDIF.
  ENDMETHOD.


  METHOD names.
    DATA lv_lang TYPE string.
    lv_lang = lang( iv_lang ).
    CASE iv_kind && lv_lang.
      WHEN `MONTHTR`.
        rt_names = VALUE #( ( `Ocak` ) ( `Şubat` ) ( `Mart` ) ( `Nisan` ) ( `Mayıs` ) ( `Haziran` )
                            ( `Temmuz` ) ( `Ağustos` ) ( `Eylül` ) ( `Ekim` ) ( `Kasım` ) ( `Aralık` ) ).
      WHEN `MONTHDE`.
        rt_names = VALUE #( ( `Januar` ) ( `Februar` ) ( `März` ) ( `April` ) ( `Mai` ) ( `Juni` )
                            ( `Juli` ) ( `August` ) ( `September` ) ( `Oktober` ) ( `November` ) ( `Dezember` ) ).
      WHEN `MONTHEN`.
        rt_names = VALUE #( ( `January` ) ( `February` ) ( `March` ) ( `April` ) ( `May` ) ( `June` )
                            ( `July` ) ( `August` ) ( `September` ) ( `October` ) ( `November` ) ( `December` ) ).
      WHEN `DAYTR`.
        rt_names = VALUE #( ( `Pazartesi` ) ( `Salı` ) ( `Çarşamba` ) ( `Perşembe` ) ( `Cuma` ) ( `Cumartesi` ) ( `Pazar` ) ).
      WHEN `DAYDE`.
        rt_names = VALUE #( ( `Montag` ) ( `Dienstag` ) ( `Mittwoch` ) ( `Donnerstag` ) ( `Freitag` ) ( `Samstag` ) ( `Sonntag` ) ).
      WHEN OTHERS.
        rt_names = VALUE #( ( `Monday` ) ( `Tuesday` ) ( `Wednesday` ) ( `Thursday` ) ( `Friday` ) ( `Saturday` ) ( `Sunday` ) ).
    ENDCASE.
  ENDMETHOD.


  METHOD starts.
    rv_yes = xsdbool( strlen( iv_text ) >= strlen( iv_prefix )
                      AND substring( val = iv_text len = strlen( iv_prefix ) ) = iv_prefix ).
  ENDMETHOD.


  METHOD pad2.
    rv_text = |{ iv_value }|.
    IF strlen( rv_text ) < 2.
      rv_text = |0{ rv_text }|.
    ENDIF.
  ENDMETHOD.


  METHOD format_date.
    DATA lt_months TYPE ty_strings.
    DATA lt_days TYPE ty_strings.
    DATA lv_pos TYPE i.
    DATA lv_len TYPE i.
    DATA lv_rest TYPE string.
    DATA lv_c TYPE string.
    DATA lv_end TYPE i.
    DATA lv_year TYPE i.
    DATA lv_month TYPE i.
    DATA lv_day TYPE i.
    DATA lv_hour TYPE i.
    DATA lv_min TYPE i.
    DATA lv_sec TYPE i.
    DATA lv_weekday TYPE i.
    DATA lv_base TYPE d VALUE '19000101'.
    DATA lv_name TYPE string.

    lv_year = iv_date(4).
    lv_month = iv_date+4(2).
    lv_day = iv_date+6(2).
    lv_hour = iv_time(2).
    lv_min = iv_time+2(2).
    lv_sec = iv_time+4(2).
    lt_months = names( iv_kind = `MONTH` iv_lang = iv_lang ).
    lt_days = names( iv_kind = `DAY` iv_lang = iv_lang ).
    "1900-01-01 was a Monday.
    IF iv_date IS NOT INITIAL AND iv_date <> '00000000'.
      lv_weekday = ( iv_date - lv_base ) MOD 7 + 1.
    ENDIF.

    lv_len = strlen( iv_pattern ).
    WHILE lv_pos < lv_len.
      lv_rest = substring( val = iv_pattern off = lv_pos ).
      lv_c = substring( val = lv_rest len = 1 ).
      IF lv_c = `'`.
        lv_end = find( val = lv_rest sub = `'` off = 1 ).
        IF lv_end < 0.
          lv_end = strlen( lv_rest ).
        ENDIF.
        rv_text = rv_text && substring( val = lv_rest off = 1 len = lv_end - 1 ).
        lv_pos = lv_pos + lv_end + 1.
        CONTINUE.
      ENDIF.
      IF starts( iv_text = lv_rest iv_prefix = `YYYY` ) = abap_true.
        rv_text = rv_text && |{ lv_year WIDTH = 4 ALIGN = RIGHT PAD = '0' }|.
        lv_pos = lv_pos + 4.
      ELSEIF starts( iv_text = lv_rest iv_prefix = `MMMM` ) = abap_true.
        READ TABLE lt_months INTO lv_name INDEX lv_month.
        rv_text = rv_text && lv_name.
        lv_pos = lv_pos + 4.
      ELSEIF starts( iv_text = lv_rest iv_prefix = `dddd` ) = abap_true.
        READ TABLE lt_days INTO lv_name INDEX lv_weekday.
        rv_text = rv_text && lv_name.
        lv_pos = lv_pos + 4.
      ELSEIF starts( iv_text = lv_rest iv_prefix = `MMM` ) = abap_true.
        READ TABLE lt_months INTO lv_name INDEX lv_month.
        rv_text = rv_text && substring( val = lv_name len = nmin( val1 = 3 val2 = strlen( lv_name ) ) ).
        lv_pos = lv_pos + 3.
      ELSEIF starts( iv_text = lv_rest iv_prefix = `ddd` ) = abap_true.
        READ TABLE lt_days INTO lv_name INDEX lv_weekday.
        rv_text = rv_text && substring( val = lv_name len = nmin( val1 = 3 val2 = strlen( lv_name ) ) ).
        lv_pos = lv_pos + 3.
      ELSEIF starts( iv_text = lv_rest iv_prefix = `YY` ) = abap_true.
        rv_text = rv_text && pad2( lv_year MOD 100 ).
        lv_pos = lv_pos + 2.
      ELSEIF starts( iv_text = lv_rest iv_prefix = `MM` ) = abap_true.
        rv_text = rv_text && pad2( lv_month ).
        lv_pos = lv_pos + 2.
      ELSEIF starts( iv_text = lv_rest iv_prefix = `DD` ) = abap_true.
        rv_text = rv_text && pad2( lv_day ).
        lv_pos = lv_pos + 2.
      ELSEIF starts( iv_text = lv_rest iv_prefix = `HH` ) = abap_true.
        rv_text = rv_text && pad2( lv_hour ).
        lv_pos = lv_pos + 2.
      ELSEIF starts( iv_text = lv_rest iv_prefix = `mm` ) = abap_true.
        rv_text = rv_text && pad2( lv_min ).
        lv_pos = lv_pos + 2.
      ELSEIF starts( iv_text = lv_rest iv_prefix = `ss` ) = abap_true.
        rv_text = rv_text && pad2( lv_sec ).
        lv_pos = lv_pos + 2.
      ELSEIF lv_c = `M`.
        rv_text = rv_text && |{ lv_month }|.
        lv_pos = lv_pos + 1.
      ELSEIF lv_c = `D`.
        rv_text = rv_text && |{ lv_day }|.
        lv_pos = lv_pos + 1.
      ELSEIF lv_c = `H`.
        rv_text = rv_text && |{ lv_hour }|.
        lv_pos = lv_pos + 1.
      ELSE.
        rv_text = rv_text && lv_c.
        lv_pos = lv_pos + 1.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.


  METHOD group.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_count TYPE i.
    lv_len = strlen( iv_digits ).
    lv_i = lv_len.
    WHILE lv_i > 0.
      lv_i = lv_i - 1.
      IF lv_count > 0 AND lv_count MOD 3 = 0 AND iv_sep IS NOT INITIAL.
        rv_text = iv_sep && rv_text.
      ENDIF.
      rv_text = substring( val = iv_digits off = lv_i len = 1 ) && rv_text.
      lv_count = lv_count + 1.
    ENDWHILE.
  ENDMETHOD.


  METHOD format_number.
    DATA lv_pattern TYPE string.
    DATA lv_negative TYPE string.
    DATA lv_arabic TYPE abap_bool.
    DATA lv_start TYPE i.
    DATA lv_end TYPE i.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE string.
    DATA lv_core TYPE string.
    DATA lv_prefix TYPE string.
    DATA lv_suffix TYPE string.
    DATA lv_dot TYPE i.
    DATA lv_comma TYPE i.
    DATA lv_dec TYPE string.
    DATA lv_grp TYPE string.
    DATA lv_last TYPE i.
    DATA lv_after TYPE string.
    DATA lv_places TYPE i.
    DATA lv_value TYPE decfloat34.
    DATA lv_p TYPE p LENGTH 16 DECIMALS 6.
    DATA lv_raw TYPE string.
    DATA lv_int TYPE string.
    DATA lv_frac TYPE string.
    DATA lv_out TYPE string.
    DATA lv_neg TYPE abap_bool.
    DATA lv_digit TYPE string.
    DATA lv_code TYPE i.

    SPLIT iv_pattern AT ';' INTO lv_pattern lv_negative.
    IF strlen( lv_pattern ) > 2 AND lv_pattern(2) = 'AR'.
      lv_arabic = abap_true.
      lv_pattern = substring( val = lv_pattern off = 2 ).
    ENDIF.
    lv_value = iv_value.
    IF lv_value < 0.
      lv_neg = abap_true.
      lv_value = - lv_value.
      IF lv_negative IS NOT INITIAL.
        lv_pattern = lv_negative.
      ENDIF.
    ENDIF.

    "Numeric core: the run of # 0 , . characters; the rest is literal text.
    lv_len = strlen( lv_pattern ).
    lv_start = -1.
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_c = substring( val = lv_pattern off = lv_i len = 1 ).
      IF lv_c CA '#0'.
        IF lv_start < 0.
          lv_start = lv_i.
        ENDIF.
        lv_end = lv_i.
      ELSEIF lv_c CA ',.' AND lv_start >= 0.
        lv_end = lv_i.
      ELSEIF lv_start >= 0.
        EXIT.
      ENDIF.
    ENDDO.
    IF lv_start < 0.
      rv_text = |{ iv_value }|.
      RETURN.
    ENDIF.
    lv_prefix = substring( val = lv_pattern len = lv_start ).
    lv_core = substring( val = lv_pattern off = lv_start len = lv_end - lv_start + 1 ).
    lv_suffix = substring( val = lv_pattern off = lv_end + 1 ).

    lv_dot = find( val = lv_core sub = '.' occ = -1 ).
    lv_comma = find( val = lv_core sub = ',' occ = -1 ).
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
      lv_after = substring( val = lv_core off = lv_last + 1 ).
      IF lv_after CO '0#' AND ( lv_core(1) = '0' OR strlen( lv_after ) <> 3 ).
        lv_dec = substring( val = lv_core off = lv_last len = 1 ).
      ELSE.
        lv_grp = substring( val = lv_core off = lv_last len = 1 ).
        lv_last = -1.
      ENDIF.
    ELSE.
      lv_last = -1.
    ENDIF.
    IF lv_dec IS NOT INITIAL AND lv_last >= 0.
      lv_places = strlen( lv_core ) - lv_last - 1.
    ENDIF.
    IF lv_places > 6.
      lv_places = 6.
    ENDIF.

    lv_p = round( val = lv_value dec = lv_places ).
    lv_raw = |{ lv_p }|.
    SPLIT lv_raw AT '.' INTO lv_int lv_frac.
    IF lv_places > 0.
      lv_frac = lv_frac && '000000'.
      lv_frac = substring( val = lv_frac len = lv_places ).
    ELSE.
      CLEAR lv_frac.
    ENDIF.
    lv_out = group( iv_digits = lv_int iv_sep = lv_grp ).
    IF lv_frac IS NOT INITIAL.
      lv_out = lv_out && lv_dec && lv_frac.
    ENDIF.
    IF lv_arabic = abap_true.
      DO 10 TIMES.
        lv_code = 1631 + sy-index.
        lv_digit = cl_abap_conv_in_ce=>uccpi( lv_code ).
        lv_c = |{ sy-index - 1 }|.
        REPLACE ALL OCCURRENCES OF lv_c IN lv_out WITH lv_digit.
      ENDDO.
    ENDIF.
    rv_text = lv_prefix && lv_out && lv_suffix.
    IF lv_neg = abap_true AND lv_negative IS INITIAL AND lv_p <> 0.
      rv_text = `-` && rv_text.
    ENDIF.
  ENDMETHOD.


  METHOD parse_date.
    DATA lv_text TYPE string.
    DATA lv_date TYPE string.
    DATA lv_time TYPE string.
    DATA lt_parts TYPE ty_strings.
    DATA lv_a TYPE string.
    DATA lv_b TYPE string.
    DATA lv_c TYPE string.
    DATA lv_digits TYPE string.

    CLEAR: ev_date, ev_time, ev_ok.
    lv_text = condense( iv_text ).
    IF lv_text IS INITIAL OR lv_text CO '0 '.
      RETURN.
    ENDIF.
    SPLIT lv_text AT ` ` INTO lv_date lv_time.
    IF lv_time IS INITIAL AND lv_date CS 'T' AND strlen( lv_date ) > 10.
      SPLIT lv_date AT 'T' INTO lv_date lv_time.
    ENDIF.

    IF lv_date CO '0123456789'.
      IF strlen( lv_date ) = 8.
        ev_date = lv_date.
      ELSEIF strlen( lv_date ) = 14.
        "Timestamp YYYYMMDDHHMMSS.
        ev_date = lv_date(8).
        ev_time = lv_date+8(6).
      ELSE.
        RETURN.
      ENDIF.
    ELSE.
      SPLIT lv_date AT '-' INTO TABLE lt_parts.
      IF lines( lt_parts ) <> 3.
        SPLIT lv_date AT '.' INTO TABLE lt_parts.
      ENDIF.
      IF lines( lt_parts ) <> 3.
        SPLIT lv_date AT '/' INTO TABLE lt_parts.
      ENDIF.
      IF lines( lt_parts ) <> 3.
        RETURN.
      ENDIF.
      READ TABLE lt_parts INTO lv_a INDEX 1.
      READ TABLE lt_parts INTO lv_b INDEX 2.
      READ TABLE lt_parts INTO lv_c INDEX 3.
      IF lv_a CN '0123456789' OR lv_b CN '0123456789' OR lv_c CN '0123456789'.
        RETURN.
      ENDIF.
      IF strlen( lv_a ) = 4.
        ev_date = |{ lv_a }{ lv_b WIDTH = 2 ALIGN = RIGHT PAD = '0' }{ lv_c WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
      ELSE.
        IF strlen( lv_c ) = 2.
          lv_c = |20{ lv_c }|.
        ENDIF.
        ev_date = |{ lv_c }{ lv_b WIDTH = 2 ALIGN = RIGHT PAD = '0' }{ lv_a WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
      ENDIF.
    ENDIF.
    IF lv_time IS NOT INITIAL.
      lv_digits = lv_time.
      REPLACE ALL OCCURRENCES OF ':' IN lv_digits WITH ``.
      IF lv_digits CO '0123456789' AND strlen( lv_digits ) >= 4.
        lv_digits = lv_digits && '00'.
        ev_time = lv_digits(6).
      ENDIF.
    ENDIF.
    "Plausibility.
    IF ev_date+4(2) < '01' OR ev_date+4(2) > '12' OR ev_date+6(2) < '01' OR ev_date+6(2) > '31'.
      CLEAR ev_date.
      RETURN.
    ENDIF.
    ev_ok = abap_true.
  ENDMETHOD.


  METHOD parse_number.
    DATA lv_clean TYPE string.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE string.
    DATA lv_neg TYPE abap_bool.
    DATA lv_dot TYPE i.
    DATA lv_comma TYPE i.
    DATA lv_dots TYPE i.
    DATA lv_commas TYPE i.
    DATA lv_dec TYPE string.
    DATA lv_grp TYPE string.
    DATA lv_text TYPE string.

    CLEAR: ev_value, ev_ok.
    lv_text = iv_text.
    lv_len = strlen( lv_text ).
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_c = substring( val = lv_text off = lv_i len = 1 ).
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
      ELSEIF lv_c CA 'eE' AND lv_clean IS NOT INITIAL.
        "Exponent notation is not a formatted number.
        RETURN.
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
    ENDIF.
    IF lv_dec = ','.
      REPLACE ALL OCCURRENCES OF ',' IN lv_clean WITH '.'.
    ENDIF.
    IF lv_clean(1) = '.'.
      lv_clean = '0' && lv_clean.
    ENDIF.
    IF strlen( lv_clean ) > 30.
      RETURN.
    ENDIF.
    TRY.
        ev_value = lv_clean.
      CATCH cx_root.
        RETURN.
    ENDTRY.
    IF lv_neg = abap_true.
      ev_value = - ev_value.
    ENDIF.
    ev_ok = abap_true.
  ENDMETHOD.


  METHOD upper.
    DATA lv_i TYPE string.
    DATA lv_dotless TYPE string.
    DATA lv_dotted TYPE string.
    rv_text = iv_text.
    IF iv_lang = 'T'.
      lv_i = cl_abap_conv_in_ce=>uccpi( 105 ).        "i
      lv_dotted = cl_abap_conv_in_ce=>uccpi( 304 ).   "İ
      lv_dotless = cl_abap_conv_in_ce=>uccpi( 305 ).  "ı
      REPLACE ALL OCCURRENCES OF lv_i IN rv_text WITH lv_dotted.
      REPLACE ALL OCCURRENCES OF lv_dotless IN rv_text WITH `I`.
    ENDIF.
    rv_text = to_upper( rv_text ).
  ENDMETHOD.


  METHOD lower.
    DATA lv_dotless TYPE string.
    DATA lv_dotted TYPE string.
    rv_text = iv_text.
    IF iv_lang = 'T'.
      lv_dotted = cl_abap_conv_in_ce=>uccpi( 304 ).   "İ
      lv_dotless = cl_abap_conv_in_ce=>uccpi( 305 ).  "ı
      REPLACE ALL OCCURRENCES OF lv_dotted IN rv_text WITH `i`.
      REPLACE ALL OCCURRENCES OF `I` IN rv_text WITH lv_dotless.
    ENDIF.
    rv_text = to_lower( rv_text ).
  ENDMETHOD.


  METHOD words_below_1000.
    DATA lt_ones TYPE ty_strings.
    DATA lt_tens TYPE ty_strings.
    DATA lv_hundreds TYPE i.
    DATA lv_rest TYPE i.
    DATA lv_word TYPE string.
    DATA lv_lang TYPE string.

    lv_lang = lang( iv_lang ).
    lv_hundreds = iv_number DIV 100.
    lv_rest = iv_number MOD 100.
    CASE lv_lang.
      WHEN `TR`.
        lt_ones = VALUE #( ( `bir` ) ( `iki` ) ( `üç` ) ( `dört` ) ( `beş` ) ( `altı` ) ( `yedi` ) ( `sekiz` ) ( `dokuz` ) ).
        lt_tens = VALUE #( ( `on` ) ( `yirmi` ) ( `otuz` ) ( `kırk` ) ( `elli` ) ( `altmış` ) ( `yetmiş` ) ( `seksen` ) ( `doksan` ) ).
        IF lv_hundreds = 1.
          rv_text = `yüz`.
        ELSEIF lv_hundreds > 1.
          READ TABLE lt_ones INTO lv_word INDEX lv_hundreds.
          rv_text = |{ lv_word } yüz|.
        ENDIF.
        IF lv_rest >= 10.
          READ TABLE lt_tens INTO lv_word INDEX lv_rest DIV 10.
          rv_text = condense( |{ rv_text } { lv_word }| ).
        ENDIF.
        IF lv_rest MOD 10 > 0.
          READ TABLE lt_ones INTO lv_word INDEX lv_rest MOD 10.
          rv_text = condense( |{ rv_text } { lv_word }| ).
        ENDIF.
      WHEN `DE`.
        lt_ones = VALUE #( ( `ein` ) ( `zwei` ) ( `drei` ) ( `vier` ) ( `fünf` ) ( `sechs` ) ( `sieben` ) ( `acht` ) ( `neun` )
                           ( `zehn` ) ( `elf` ) ( `zwölf` ) ( `dreizehn` ) ( `vierzehn` ) ( `fünfzehn` ) ( `sechzehn` )
                           ( `siebzehn` ) ( `achtzehn` ) ( `neunzehn` ) ).
        lt_tens = VALUE #( ( `zehn` ) ( `zwanzig` ) ( `dreißig` ) ( `vierzig` ) ( `fünfzig` ) ( `sechzig` )
                           ( `siebzig` ) ( `achtzig` ) ( `neunzig` ) ).
        IF lv_hundreds > 0.
          READ TABLE lt_ones INTO lv_word INDEX lv_hundreds.
          rv_text = |{ lv_word }hundert|.
        ENDIF.
        IF lv_rest > 0 AND lv_rest < 20.
          READ TABLE lt_ones INTO lv_word INDEX lv_rest.
          rv_text = rv_text && lv_word.
        ELSEIF lv_rest >= 20.
          IF lv_rest MOD 10 > 0.
            READ TABLE lt_ones INTO lv_word INDEX lv_rest MOD 10.
            rv_text = |{ rv_text }{ lv_word }und|.
          ENDIF.
          READ TABLE lt_tens INTO lv_word INDEX lv_rest DIV 10.
          rv_text = rv_text && lv_word.
        ENDIF.
      WHEN OTHERS.
        lt_ones = VALUE #( ( `one` ) ( `two` ) ( `three` ) ( `four` ) ( `five` ) ( `six` ) ( `seven` ) ( `eight` ) ( `nine` )
                           ( `ten` ) ( `eleven` ) ( `twelve` ) ( `thirteen` ) ( `fourteen` ) ( `fifteen` ) ( `sixteen` )
                           ( `seventeen` ) ( `eighteen` ) ( `nineteen` ) ).
        lt_tens = VALUE #( ( `ten` ) ( `twenty` ) ( `thirty` ) ( `forty` ) ( `fifty` ) ( `sixty` )
                           ( `seventy` ) ( `eighty` ) ( `ninety` ) ).
        IF lv_hundreds > 0.
          READ TABLE lt_ones INTO lv_word INDEX lv_hundreds.
          rv_text = |{ lv_word } hundred|.
        ENDIF.
        IF lv_rest > 0 AND lv_rest < 20.
          READ TABLE lt_ones INTO lv_word INDEX lv_rest.
          rv_text = condense( |{ rv_text } { lv_word }| ).
        ELSEIF lv_rest >= 20.
          READ TABLE lt_tens INTO lv_word INDEX lv_rest DIV 10.
          IF lv_rest MOD 10 > 0.
            DATA(lv_tens) = lv_word.
            READ TABLE lt_ones INTO lv_word INDEX lv_rest MOD 10.
            lv_word = |{ lv_tens }-{ lv_word }|.
          ENDIF.
          rv_text = condense( |{ rv_text } { lv_word }| ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.


  METHOD number_in_words.
    DATA lv_lang TYPE string.
    DATA lv_rest TYPE p LENGTH 16 DECIMALS 0.
    DATA lv_group TYPE i.
    DATA lv_index TYPE i.
    DATA lv_part TYPE string.
    DATA lt_scales TYPE ty_strings.
    DATA lv_scale TYPE string.

    lv_lang = lang( iv_lang ).
    lv_rest = trunc( abs( iv_number ) ).
    IF lv_rest = 0.
      rv_text = COND #( WHEN lv_lang = `TR` THEN `sıfır` WHEN lv_lang = `DE` THEN `null` ELSE `zero` ).
      RETURN.
    ENDIF.
    CASE lv_lang.
      WHEN `TR`.
        lt_scales = VALUE #( ( `` ) ( `bin` ) ( `milyon` ) ( `milyar` ) ( `trilyon` ) ).
      WHEN `DE`.
        lt_scales = VALUE #( ( `` ) ( `tausend` ) ( `Millionen` ) ( `Milliarden` ) ( `Billionen` ) ).
      WHEN OTHERS.
        lt_scales = VALUE #( ( `` ) ( `thousand` ) ( `million` ) ( `billion` ) ( `trillion` ) ).
    ENDCASE.
    lv_index = 0.
    WHILE lv_rest > 0 AND lv_index < 5.
      lv_group = lv_rest MOD 1000.
      lv_rest = lv_rest DIV 1000.
      lv_index = lv_index + 1.
      IF lv_group = 0.
        CONTINUE.
      ENDIF.
      READ TABLE lt_scales INTO lv_scale INDEX lv_index.
      "Turkish: 1000 is "bin", not "bir bin".
      IF lv_lang = `TR` AND lv_index = 2 AND lv_group = 1.
        lv_part = lv_scale.
      ELSEIF lv_lang = `DE`.
        lv_part = words_below_1000( iv_number = lv_group iv_lang = iv_lang ).
        CASE lv_index.
          WHEN 1.
            IF lv_group MOD 100 = 1.
              lv_part = lv_part && `s`.
            ENDIF.
          WHEN 2.
            lv_part = |{ lv_part }tausend|.
          WHEN OTHERS.
            IF lv_group = 1.
              lv_part = COND #( WHEN lv_index = 3 THEN `eine Million` WHEN lv_index = 4 THEN `eine Milliarde` ELSE `eine Billion` ).
            ELSE.
              lv_part = |{ lv_part } { lv_scale }|.
            ENDIF.
        ENDCASE.
      ELSE.
        lv_part = condense( |{ words_below_1000( iv_number = lv_group iv_lang = iv_lang ) } { lv_scale }| ).
      ENDIF.
      IF lv_lang = `DE` AND lv_index <= 2.
        "German writes numbers below one million as one word.
        rv_text = lv_part && rv_text.
      ELSE.
        rv_text = condense( |{ lv_part } { rv_text }| ).
      ENDIF.
    ENDWHILE.
    IF iv_number < 0.
      rv_text = COND #( WHEN lv_lang = `TR` THEN |eksi { rv_text }| WHEN lv_lang = `DE` THEN |minus { rv_text }|
                        ELSE |minus { rv_text }| ).
    ENDIF.
  ENDMETHOD.


  METHOD currency_names.
    DATA lv_lang TYPE string.
    lv_lang = lang( iv_lang ).
    CASE to_upper( iv_currency ) && lv_lang.
      WHEN `TRYTR` OR `TLTR`.
        ev_major = `Türk lirası`.
        ev_minor = `kuruş`.
      WHEN `EURTR`.
        ev_major = `avro`.
        ev_minor = `sent`.
      WHEN `USDTR`.
        ev_major = `Amerikan doları`.
        ev_minor = `sent`.
      WHEN `GBPTR`.
        ev_major = `İngiliz sterlini`.
        ev_minor = `peni`.
      WHEN `TRYEN` OR `TRYDE`.
        ev_major = `Turkish lira`.
        ev_minor = `kuruş`.
      WHEN `EUREN`.
        ev_major = `euros`.
        ev_minor = `cents`.
      WHEN `EURDE`.
        ev_major = `Euro`.
        ev_minor = `Cent`.
      WHEN `USDEN`.
        ev_major = `US dollars`.
        ev_minor = `cents`.
      WHEN `USDDE`.
        ev_major = `US-Dollar`.
        ev_minor = `Cent`.
      WHEN `GBPEN`.
        ev_major = `pounds sterling`.
        ev_minor = `pence`.
      WHEN OTHERS.
        ev_major = to_upper( iv_currency ).
        ev_minor = COND #( WHEN iv_currency IS INITIAL THEN `` ELSE `/100` ).
    ENDCASE.
  ENDMETHOD.


  METHOD amount_in_words.
    DATA lv_major TYPE string.
    DATA lv_minor TYPE string.
    DATA lv_whole TYPE decfloat34.
    DATA lv_cents TYPE i.
    DATA lv_and TYPE string.
    DATA lv_lang TYPE string.

    lv_lang = lang( iv_lang ).
    lv_whole = trunc( abs( iv_amount ) ).
    lv_cents = round( val = ( abs( iv_amount ) - lv_whole ) * 100 dec = 0 ).
    IF lv_cents = 100.
      lv_whole = lv_whole + 1.
      lv_cents = 0.
    ENDIF.
    IF iv_amount < 0.
      lv_whole = - lv_whole.
    ENDIF.
    currency_names( EXPORTING iv_currency = iv_currency iv_lang = iv_lang IMPORTING ev_major = lv_major ev_minor = lv_minor ).
    rv_text = condense( |{ number_in_words( iv_number = lv_whole iv_lang = iv_lang ) } { lv_major }| ).
    IF lv_cents > 0.
      IF lv_minor = `/100`.
        rv_text = |{ rv_text } { lv_cents }/100|.
      ELSE.
        lv_and = COND #( WHEN lv_lang = `EN` THEN ` and` WHEN lv_lang = `DE` THEN ` und` ELSE `` ).
        rv_text = |{ rv_text }{ lv_and } { number_in_words( iv_number = CONV decfloat34( lv_cents ) iv_lang = iv_lang ) } { lv_minor }|.
      ENDIF.
    ENDIF.
    rv_text = condense( rv_text ).
  ENDMETHOD.

ENDCLASS.
