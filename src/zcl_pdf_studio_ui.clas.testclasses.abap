CLASS ltc_studio DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-METHODS b64
      IMPORTING
        iv_text       TYPE string
      RETURNING
        VALUE(rv_b64) TYPE string.
    CLASS-METHODS envelope
      IMPORTING
        it_lines      TYPE zcl_pdf_studio_ui=>ty_lines
      RETURNING
        VALUE(rv_b64) TYPE string.

    METHODS parse_envelope FOR TESTING RAISING zcx_pdf_studio.
    METHODS template_from_lines FOR TESTING.
    METHODS studio_payload FOR TESTING.
    METHODS ddic_describe_structure FOR TESTING RAISING zcx_pdf_studio.
    METHODS ddic_describe_table_type FOR TESTING RAISING zcx_pdf_studio.
    METHODS ddic_describe_unknown FOR TESTING.
    METHODS ddic_search FOR TESTING.
ENDCLASS.


CLASS ltc_studio IMPLEMENTATION.

  METHOD b64.
    DATA lv_x TYPE xstring.
    TRY.
        lv_x = zcl_pdf_studio_conv=>string_to_xstring( iv_text ).
      CATCH zcx_pdf_studio.
        cl_abap_unit_assert=>fail( 'UTF-8' ).
    ENDTRY.
    rv_b64 = cl_http_utility=>encode_x_base64( lv_x ).
  ENDMETHOD.

  METHOD envelope.
    DATA ls_line TYPE zcl_pdf_studio_ui=>ty_line.
    DATA lv_text TYPE string.
    LOOP AT it_lines INTO ls_line.
      IF lv_text IS NOT INITIAL.
        lv_text = lv_text && cl_abap_char_utilities=>newline.
      ENDIF.
      lv_text = lv_text && ls_line-key && cl_abap_char_utilities=>horizontal_tab && ls_line-arg &&
                cl_abap_char_utilities=>horizontal_tab && b64( ls_line-value ).
    ENDLOOP.
    rv_b64 = b64( lv_text ).
  ENDMETHOD.

  METHOD parse_envelope.
    DATA lt_in TYPE zcl_pdf_studio_ui=>ty_lines.
    DATA lt_out TYPE zcl_pdf_studio_ui=>ty_lines.
    DATA ls_line TYPE zcl_pdf_studio_ui=>ty_line.

    ls_line-key = `META`.
    ls_line-arg = `html`.
    ls_line-value = `<div>Şube: {{INPUT.GONDEREN_SUBE}} ğüşiöç İ</div>`.
    APPEND ls_line TO lt_in.
    ls_line-arg = `dirty`.
    ls_line-value = ``.
    APPEND ls_line TO lt_in.
    ls_line-arg = `page_size`.
    ls_line-value = `A4`.
    APPEND ls_line TO lt_in.

    lt_out = zcl_pdf_studio_ui=>parse_envelope( envelope( lt_in ) ).
    cl_abap_unit_assert=>assert_equals( exp = lt_in act = lt_out ).
    cl_abap_unit_assert=>assert_initial( zcl_pdf_studio_ui=>parse_envelope( `` ) ).
  ENDMETHOD.

  METHOD template_from_lines.
    DATA lt_lines TYPE zcl_pdf_studio_ui=>ty_lines.
    DATA ls_line TYPE zcl_pdf_studio_ui=>ty_line.
    DATA ls_template TYPE zcl_pdf_studio_repo=>ty_template.

    ls_line-key = `META`.
    ls_line-arg = `html`.
    ls_line-value = `<p>x</p>`.
    APPEND ls_line TO lt_lines.
    ls_line-arg = `orientation`.
    ls_line-value = `l`.
    APPEND ls_line TO lt_lines.
    ls_line-arg = `margin_top`.
    ls_line-value = `15`.
    APPEND ls_line TO lt_lines.
    ls_line-arg = `margin_left`.
    ls_line-value = `x1`.
    APPEND ls_line TO lt_lines.
    ls_line-arg = `sample`.
    ls_line-value = `{"A":1}`.
    APPEND ls_line TO lt_lines.

    ls_template = zcl_pdf_studio_ui=>template_from_lines( lt_lines ).
    cl_abap_unit_assert=>assert_equals( exp = `<p>x</p>` act = ls_template-html_content ).
    cl_abap_unit_assert=>assert_equals( exp = `A4` act = ls_template-page_size ).
    cl_abap_unit_assert=>assert_equals( exp = `L` act = ls_template-orientation ).
    cl_abap_unit_assert=>assert_equals( exp = 15 act = ls_template-margin_top ).
    cl_abap_unit_assert=>assert_equals( exp = 0 act = ls_template-margin_left ).
    cl_abap_unit_assert=>assert_equals( exp = `{"A":1}` act = ls_template-sample_json ).
  ENDMETHOD.

  METHOD studio_payload.
    cl_abap_unit_assert=>assert_equals(
      exp = `eyJ6cGRmIjoyfQ==`
      act = zcl_pdf_studio_ui=>studio_payload( `<!--zpdf-studio:eyJ6cGRmIjoyfQ==--><!--zpdf-iface:INPUT=T001--><section></section>` ) ).
    cl_abap_unit_assert=>assert_initial( zcl_pdf_studio_ui=>studio_payload( `<h1>made elsewhere</h1>` ) ).
    cl_abap_unit_assert=>assert_initial( zcl_pdf_studio_ui=>studio_payload( `<!--zpdf-studio:broken` ) ).
  ENDMETHOD.

  METHOD ddic_describe_structure.
    DATA lv_json TYPE string.

    lv_json = zcl_pdf_studio_ui=>ddic_describe( 'bapiret2' ).
    cl_abap_unit_assert=>assert_char_cp( exp = `{"k":"S",*` act = lv_json ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*"n":"MESSAGE","k":"E","t":"C","l":220,*` act = lv_json ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*"n":"ROW","k":"E","t":"I",*` act = lv_json ).
  ENDMETHOD.

  METHOD ddic_describe_table_type.
    DATA lv_json TYPE string.

    "A table type: the children are the fields of a row.
    lv_json = zcl_pdf_studio_ui=>ddic_describe( 'BAPIRET2_T' ).
    cl_abap_unit_assert=>assert_char_cp( exp = `{"k":"T",*` act = lv_json ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*"c":[{"n":"TYPE","k":"E",*` act = lv_json ).
  ENDMETHOD.

  METHOD ddic_describe_unknown.
    TRY.
        zcl_pdf_studio_ui=>ddic_describe( 'ZZ_NO_SUCH_TYPE_XYZ' ).
        cl_abap_unit_assert=>fail( 'An unknown type must raise an exception' ).
      CATCH zcx_pdf_studio ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD ddic_search.
    DATA lv_json TYPE string.

    lv_json = zcl_pdf_studio_ui=>ddic_search( 'bapiret2*' ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*"name":"BAPIRET2","kind":"S","type":"S",*` act = lv_json ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*"name":"BAPIRET2_T","kind":"T","type":"T",*` act = lv_json ).

    "No minimum length for the name: Z* lists customer objects, bounded by the row limit.
    lv_json = zcl_pdf_studio_ui=>ddic_search( iv_query = 'z*' iv_kinds = 'D' iv_max = 3 ).
    cl_abap_unit_assert=>assert_char_cp( exp = `[{"name":"Z*` act = lv_json ).

    "Object type filter: table types only. No type chosen means every type.
    lv_json = zcl_pdf_studio_ui=>ddic_search( iv_query = 'bapiret2*' iv_kinds = 'T' ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*"name":"BAPIRET2_T",*` act = lv_json ).
    cl_abap_unit_assert=>assert_char_np( exp = `*"kind":"S"*` act = lv_json ).
    lv_json = zcl_pdf_studio_ui=>ddic_search( iv_query = 'bapiret2*' iv_kinds = '' ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*"name":"BAPIRET2","kind":"S",*"name":"BAPIRET2_T","kind":"T",*` act = lv_json ).

    "Package filter: nothing lives in a package that does not exist.
    cl_abap_unit_assert=>assert_equals(
      exp = `[]`
      act = zcl_pdf_studio_ui=>ddic_search( iv_query = 'bapiret2*' iv_package = 'ZZ_NO_SUCH_PACKAGE_X' ) ).

    "The tables of this product are found by their package alone, as database tables.
    lv_json = zcl_pdf_studio_ui=>ddic_search( iv_query = '' iv_kinds = 'D' iv_package = '$ZPDF_STUDIO' ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*"name":"ZPDF_STUDIO_FORM","kind":"S","type":"D",*"package":"$ZPDF_STUDIO"*` act = lv_json ).

    "Row limit: one row means no second object in the array.
    lv_json = zcl_pdf_studio_ui=>ddic_search( iv_query = 'b' iv_kinds = 'S' iv_max = 1 ).
    cl_abap_unit_assert=>assert_char_cp( exp = `[{*}]` act = lv_json ).
    cl_abap_unit_assert=>assert_char_np( exp = `*},{*` act = lv_json ).
  ENDMETHOD.

ENDCLASS.
