"! <p>JSON to ABAP data for ZPDF Studio (no dependency on /UI2/CL_JSON).</p>
"! Objects become structures, arrays of objects become tables of structures (all keys of all
"! rows), arrays of values become string tables, values become strings. Keys are converted to
"! ABAP component names: upper case, A-Z 0-9 _, max. 30 characters.
CLASS zcl_pdf_studio_json DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS to_data
      IMPORTING
        iv_json        TYPE string
      RETURNING
        VALUE(rr_data) TYPE REF TO data
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS component_name
      IMPORTING
        iv_key         TYPE string
      RETURNING
        VALUE(rv_name) TYPE string.

  PRIVATE SECTION.
    TYPES ty_ints TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_node,
        "O object, A array, S string, N number, B boolean, Z null
        kind     TYPE c LENGTH 1,
        key      TYPE string,
        value    TYPE string,
        children TYPE ty_ints,
      END OF ty_node,
      ty_nodes TYPE STANDARD TABLE OF ty_node WITH EMPTY KEY.

    DATA mv_json TYPE string.
    DATA mv_pos TYPE i.
    DATA mv_len TYPE i.
    DATA mt_nodes TYPE ty_nodes.

    METHODS parse_value
      RETURNING
        VALUE(rv_index) TYPE i
      RAISING
        zcx_pdf_studio.
    METHODS parse_string
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        zcx_pdf_studio.
    METHODS skip_ws.
    METHODS peek
      RETURNING
        VALUE(rv_char) TYPE string.
    METHODS expect
      IMPORTING
        iv_char TYPE string
      RAISING
        zcx_pdf_studio.
    METHODS add_node
      IMPORTING
        is_node         TYPE ty_node
      RETURNING
        VALUE(rv_index) TYPE i.
    METHODS type_of
      IMPORTING
        it_indexes     TYPE ty_ints
      RETURNING
        VALUE(ro_type) TYPE REF TO cl_abap_datadescr
      RAISING
        zcx_pdf_studio.
    METHODS fill
      IMPORTING
        iv_index TYPE i
      CHANGING
        cv_data  TYPE any.
    METHODS fail
      IMPORTING
        iv_text TYPE string
      RAISING
        zcx_pdf_studio.
ENDCLASS.



CLASS zcl_pdf_studio_json IMPLEMENTATION.

  METHOD to_data.
    DATA lo_json TYPE REF TO zcl_pdf_studio_json.
    DATA lv_root TYPE i.
    DATA lo_type TYPE REF TO cl_abap_datadescr.
    DATA lt_root TYPE ty_ints.
    FIELD-SYMBOLS <data> TYPE any.

    CREATE OBJECT lo_json.
    lo_json->mv_json = iv_json.
    lo_json->mv_len = strlen( iv_json ).
    lv_root = lo_json->parse_value( ).
    lo_json->skip_ws( ).
    IF lo_json->mv_pos < lo_json->mv_len.
      lo_json->fail( `unexpected text after the JSON value` ).
    ENDIF.
    IF lo_json->mt_nodes[ lv_root ]-kind <> 'O'.
      lo_json->fail( `the data must be a JSON object` ).
    ENDIF.
    APPEND lv_root TO lt_root.
    lo_type = lo_json->type_of( lt_root ).
    CREATE DATA rr_data TYPE HANDLE lo_type.
    ASSIGN rr_data->* TO <data>.
    lo_json->fill( EXPORTING iv_index = lv_root CHANGING cv_data = <data> ).
  ENDMETHOD.


  METHOD component_name.
    rv_name = to_upper( iv_key ).
    REPLACE ALL OCCURRENCES OF REGEX `[^A-Z0-9_]` IN rv_name WITH `_`.
    IF rv_name IS INITIAL.
      rv_name = `FIELD`.
    ELSEIF rv_name(1) CA '0123456789_'.
      rv_name = |F{ rv_name }|.
    ENDIF.
    IF strlen( rv_name ) > 30.
      rv_name = rv_name(30).
    ENDIF.
  ENDMETHOD.


  METHOD fail.
    RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |Invalid JSON at position { mv_pos }: { iv_text }|.
  ENDMETHOD.


  METHOD skip_ws.
    WHILE mv_pos < mv_len AND mv_json+mv_pos(1) CA | \t\r\n|.
      mv_pos = mv_pos + 1.
    ENDWHILE.
  ENDMETHOD.


  METHOD peek.
    skip_ws( ).
    IF mv_pos < mv_len.
      rv_char = substring( val = mv_json off = mv_pos len = 1 ).
    ENDIF.
  ENDMETHOD.


  METHOD expect.
    IF peek( ) <> iv_char.
      fail( |"{ iv_char }" expected| ).
    ENDIF.
    mv_pos = mv_pos + 1.
  ENDMETHOD.


  METHOD add_node.
    APPEND is_node TO mt_nodes.
    rv_index = lines( mt_nodes ).
  ENDMETHOD.


  METHOD parse_string.
    DATA lv_c TYPE string.
    DATA lv_hex TYPE string.
    DATA lv_x TYPE x LENGTH 2.
    DATA lv_cp TYPE i.

    expect( `"` ).
    WHILE mv_pos < mv_len.
      lv_c = substring( val = mv_json off = mv_pos len = 1 ).
      mv_pos = mv_pos + 1.
      IF lv_c = `"`.
        RETURN.
      ELSEIF lv_c = `\`.
        IF mv_pos >= mv_len.
          EXIT.
        ENDIF.
        lv_c = substring( val = mv_json off = mv_pos len = 1 ).
        mv_pos = mv_pos + 1.
        CASE lv_c.
          WHEN `n`.
            rv_text = rv_text && cl_abap_char_utilities=>newline.
          WHEN `t`.
            rv_text = rv_text && cl_abap_char_utilities=>horizontal_tab.
          WHEN `r`.
            rv_text = rv_text && cl_abap_char_utilities=>cr_lf(1).
          WHEN `b` OR `f`.
          WHEN `u`.
            IF mv_pos + 4 > mv_len.
              fail( `incomplete \u escape` ).
            ENDIF.
            lv_hex = to_upper( substring( val = mv_json off = mv_pos len = 4 ) ).
            IF lv_hex CN '0123456789ABCDEF'.
              fail( `invalid \u escape` ).
            ENDIF.
            lv_x = lv_hex.
            lv_cp = lv_x.
            rv_text = rv_text && cl_abap_conv_in_ce=>uccpi( lv_cp ).
            mv_pos = mv_pos + 4.
          WHEN OTHERS.
            rv_text = rv_text && lv_c.
        ENDCASE.
      ELSE.
        rv_text = rv_text && lv_c.
      ENDIF.
    ENDWHILE.
    fail( `unterminated string` ).
  ENDMETHOD.


  METHOD parse_value.
    DATA ls_node TYPE ty_node.
    DATA lv_char TYPE string.
    DATA lv_child TYPE i.
    DATA lv_key TYPE string.
    DATA lv_start TYPE i.
    DATA lv_stop TYPE string.
    FIELD-SYMBOLS <node> TYPE ty_node.

    lv_char = peek( ).
    CASE lv_char.
      WHEN `{`.
        mv_pos = mv_pos + 1.
        ls_node-kind = 'O'.
        rv_index = add_node( ls_node ).
        IF peek( ) = `}`.
          mv_pos = mv_pos + 1.
          RETURN.
        ENDIF.
        DO.
          lv_key = parse_string( ).
          expect( `:` ).
          lv_child = parse_value( ).
          mt_nodes[ lv_child ]-key = lv_key.
          READ TABLE mt_nodes ASSIGNING <node> INDEX rv_index.
          APPEND lv_child TO <node>-children.
          IF peek( ) = `,`.
            mv_pos = mv_pos + 1.
            CONTINUE.
          ENDIF.
          expect( `}` ).
          EXIT.
        ENDDO.
      WHEN `[`.
        mv_pos = mv_pos + 1.
        ls_node-kind = 'A'.
        rv_index = add_node( ls_node ).
        IF peek( ) = `]`.
          mv_pos = mv_pos + 1.
          RETURN.
        ENDIF.
        DO.
          lv_child = parse_value( ).
          READ TABLE mt_nodes ASSIGNING <node> INDEX rv_index.
          APPEND lv_child TO <node>-children.
          IF peek( ) = `,`.
            mv_pos = mv_pos + 1.
            CONTINUE.
          ENDIF.
          expect( `]` ).
          EXIT.
        ENDDO.
      WHEN `"`.
        ls_node-kind = 'S'.
        ls_node-value = parse_string( ).
        rv_index = add_node( ls_node ).
      WHEN OTHERS.
        lv_start = mv_pos.
        lv_stop = |,]\}| && | \t\r\n|.
        WHILE mv_pos < mv_len AND mv_json+mv_pos(1) NA lv_stop.
          mv_pos = mv_pos + 1.
        ENDWHILE.
        ls_node-value = substring( val = mv_json off = lv_start len = mv_pos - lv_start ).
        CASE ls_node-value.
          WHEN `true`.
            ls_node-kind = 'B'.
            ls_node-value = `X`.
          WHEN `false`.
            ls_node-kind = 'B'.
            CLEAR ls_node-value.
          WHEN `null`.
            ls_node-kind = 'Z'.
            CLEAR ls_node-value.
          WHEN OTHERS.
            IF ls_node-value IS INITIAL OR ls_node-value CN '0123456789+-.eE'.
              fail( `value expected` ).
            ENDIF.
            ls_node-kind = 'N'.
        ENDCASE.
        rv_index = add_node( ls_node ).
    ENDCASE.
  ENDMETHOD.


  METHOD type_of.
    "Type of a set of nodes that share one ABAP type (the rows of an array, or one value).
    DATA lv_index TYPE i.
    DATA lv_child TYPE i.
    DATA ls_node TYPE ty_node.
    DATA ls_child TYPE ty_node.
    DATA lv_kind TYPE c LENGTH 1.
    DATA lt_comps TYPE cl_abap_structdescr=>component_table.
    DATA lt_names TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_name TYPE string.
    DATA lt_members TYPE ty_ints.
    DATA lt_items TYPE ty_ints.
    DATA lo_line TYPE REF TO cl_abap_datadescr.

    "Kind: object wins over array wins over value.
    LOOP AT it_indexes INTO lv_index.
      ls_node = mt_nodes[ lv_index ].
      IF ls_node-kind = 'O'.
        lv_kind = 'O'.
      ELSEIF ls_node-kind = 'A' AND lv_kind <> 'O'.
        lv_kind = 'A'.
      ENDIF.
    ENDLOOP.

    CASE lv_kind.
      WHEN 'O'.
        "Component names in the order of their first appearance.
        LOOP AT it_indexes INTO lv_index.
          ls_node = mt_nodes[ lv_index ].
          LOOP AT ls_node-children INTO lv_child.
            lv_name = component_name( mt_nodes[ lv_child ]-key ).
            READ TABLE lt_names TRANSPORTING NO FIELDS WITH KEY table_line = lv_name.
            IF sy-subrc <> 0.
              APPEND lv_name TO lt_names.
            ENDIF.
          ENDLOOP.
        ENDLOOP.
        IF lt_names IS INITIAL.
          APPEND `DUMMY` TO lt_names.
        ENDIF.
        LOOP AT lt_names INTO lv_name.
          CLEAR lt_members.
          LOOP AT it_indexes INTO lv_index.
            ls_node = mt_nodes[ lv_index ].
            LOOP AT ls_node-children INTO lv_child.
              ls_child = mt_nodes[ lv_child ].
              IF component_name( ls_child-key ) = lv_name.
                APPEND lv_child TO lt_members.
              ENDIF.
            ENDLOOP.
          ENDLOOP.
          IF lt_members IS INITIAL.
            APPEND VALUE #( name = lv_name type = cl_abap_elemdescr=>get_string( ) ) TO lt_comps.
          ELSE.
            APPEND VALUE #( name = lv_name type = type_of( lt_members ) ) TO lt_comps.
          ENDIF.
        ENDLOOP.
        TRY.
            ro_type = cl_abap_structdescr=>create( lt_comps ).
          CATCH cx_root INTO DATA(lx_struct).
            fail( |structure cannot be built: { lx_struct->get_text( ) }| ).
        ENDTRY.
      WHEN 'A'.
        LOOP AT it_indexes INTO lv_index.
          ls_node = mt_nodes[ lv_index ].
          APPEND LINES OF ls_node-children TO lt_items.
        ENDLOOP.
        IF lt_items IS INITIAL.
          lo_line = cl_abap_elemdescr=>get_string( ).
        ELSE.
          lo_line = type_of( lt_items ).
        ENDIF.
        ro_type = cl_abap_tabledescr=>create( p_line_type = lo_line ).
      WHEN OTHERS.
        ro_type = cl_abap_elemdescr=>get_string( ).
    ENDCASE.
  ENDMETHOD.


  METHOD fill.
    DATA ls_node TYPE ty_node.
    DATA lv_child TYPE i.
    DATA lr_row TYPE REF TO data.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    FIELD-SYMBOLS <comp> TYPE any.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row> TYPE any.

    ls_node = mt_nodes[ iv_index ].
    lo_type = cl_abap_typedescr=>describe_by_data( cv_data ).
    CASE ls_node-kind.
      WHEN 'O'.
        IF lo_type->kind <> cl_abap_typedescr=>kind_struct.
          RETURN.
        ENDIF.
        LOOP AT ls_node-children INTO lv_child.
          ASSIGN COMPONENT component_name( mt_nodes[ lv_child ]-key ) OF STRUCTURE cv_data TO <comp>.
          IF sy-subrc = 0.
            fill( EXPORTING iv_index = lv_child CHANGING cv_data = <comp> ).
          ENDIF.
        ENDLOOP.
      WHEN 'A'.
        IF lo_type->kind <> cl_abap_typedescr=>kind_table.
          RETURN.
        ENDIF.
        ASSIGN cv_data TO <table>.
        LOOP AT ls_node-children INTO lv_child.
          CREATE DATA lr_row LIKE LINE OF <table>.
          ASSIGN lr_row->* TO <row>.
          fill( EXPORTING iv_index = lv_child CHANGING cv_data = <row> ).
          APPEND <row> TO <table>.
        ENDLOOP.
      WHEN OTHERS.
        IF lo_type->kind = cl_abap_typedescr=>kind_elem.
          cv_data = ls_node-value.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
