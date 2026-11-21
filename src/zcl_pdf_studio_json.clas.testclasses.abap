CLASS ltc_json DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS nested FOR TESTING RAISING zcx_pdf_studio.
    METHODS invalid FOR TESTING.
    METHODS render FOR TESTING RAISING zcx_pdf_studio.
ENDCLASS.


CLASS ltc_json IMPLEMENTATION.

  METHOD nested.
    DATA lr_data TYPE REF TO data.
    FIELD-SYMBOLS <data> TYPE any.
    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <items> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row> TYPE any.

    lr_data = zcl_pdf_studio_json=>to_data(
      `{"customer":"Acme \"Ltd\"","header":{"no":42,"paid":true},` &&
      `"items":[{"name":"A","amount":1.5},{"name":"B","qty":2}],"tags":["x","y"],"note":null}` ).
    ASSIGN lr_data->* TO <data>.
    ASSIGN COMPONENT 'CUSTOMER' OF STRUCTURE <data> TO <value>.
    cl_abap_unit_assert=>assert_equals( act = <value> exp = `Acme "Ltd"` ).
    ASSIGN COMPONENT 'HEADER' OF STRUCTURE <data> TO <row>.
    ASSIGN COMPONENT 'PAID' OF STRUCTURE <row> TO <value>.
    cl_abap_unit_assert=>assert_equals( act = <value> exp = `X` ).
    ASSIGN COMPONENT 'ITEMS' OF STRUCTURE <data> TO <items>.
    cl_abap_unit_assert=>assert_equals( act = lines( <items> ) exp = 2 ).
    READ TABLE <items> ASSIGNING <row> INDEX 2.
    "Rows share all keys: QTY exists in row 1 too, AMOUNT in row 2.
    ASSIGN COMPONENT 'QTY' OF STRUCTURE <row> TO <value>.
    cl_abap_unit_assert=>assert_equals( act = <value> exp = `2` ).
    ASSIGN COMPONENT 'AMOUNT' OF STRUCTURE <row> TO <value>.
    cl_abap_unit_assert=>assert_subrc( ).
  ENDMETHOD.

  METHOD invalid.
    TRY.
        zcl_pdf_studio_json=>to_data( `{"a": }` ).
        cl_abap_unit_assert=>fail( 'Invalid JSON must be rejected' ).
      CATCH zcx_pdf_studio ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD render.
    DATA lr_data TYPE REF TO data.
    FIELD-SYMBOLS <data> TYPE any.
    lr_data = zcl_pdf_studio_json=>to_data( `{"name":"Ali","items":[{"a":"1"},{"a":"2"}],"total":"1250.5"}` ).
    ASSIGN lr_data->* TO <data>.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_binder=>render(
              iv_template = `{{NAME}}:{{#each ITEMS}}{{A}}{{/each}}:{{TOTAL | #.##0,00}}`
              is_data     = <data> )
      exp = `Ali:12:1.250,50` ).
  ENDMETHOD.

ENDCLASS.
