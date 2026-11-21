CLASS ltc_binder DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS escaped_fields FOR TESTING RAISING zcx_pdf_studio.
    METHODS missing_field FOR TESTING.
    METHODS nested_tables FOR TESTING RAISING zcx_pdf_studio.
    METHODS invalid_hidden_block FOR TESTING.
    METHODS total_sum_char FOR TESTING RAISING zcx_pdf_studio.
    METHODS total_sum_packed FOR TESTING RAISING zcx_pdf_studio.
    METHODS total_designer_table FOR TESTING RAISING zcx_pdf_studio.
    METHODS total_count_avg_format FOR TESTING RAISING zcx_pdf_studio.
    METHODS raw_keeps_formatting FOR TESTING RAISING zcx_pdf_studio.
    METHODS raw_blocks_attacks FOR TESTING RAISING zcx_pdf_studio.
    METHODS raw_embedded_image FOR TESTING RAISING zcx_pdf_studio.
ENDCLASS.

CLASS ltc_binder IMPLEMENTATION.

  METHOD escaped_fields.
    TYPES: BEGIN OF ty_data, name TYPE string, END OF ty_data.
    DATA ls_data TYPE ty_data.
    ls_data-name = `<A&B>"'`.
    DATA(lv_html) = zcl_pdf_studio_binder=>render(
      iv_template = '{{name}}' is_data = ls_data ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_html exp = '&lt;A&amp;B&gt;&quot;&#39;' ).
  ENDMETHOD.

  METHOD missing_field.
    DATA lv_data TYPE string.
    TRY.
        zcl_pdf_studio_binder=>render(
          iv_template = '{{missing}}' is_data = lv_data ).
        cl_abap_unit_assert=>fail( 'Missing field must fail' ).
      CATCH zcx_pdf_studio INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_true(
          act = xsdbool( lx_error->get_text( ) CS 'Unknown template field' ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD nested_tables.
    TYPES: BEGIN OF ty_item, name TYPE string, END OF ty_item.
    TYPES ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.
    TYPES: BEGIN OF ty_data, items TYPE ty_items, END OF ty_data.
    DATA ls_data TYPE ty_data.
    APPEND VALUE #( name = 'A&B' ) TO ls_data-items.
    APPEND VALUE #( name = 'Second' ) TO ls_data-items.
    DATA(lv_html) = zcl_pdf_studio_binder=>render(
      iv_template = '{{#each items}}<p>{{ROW}}:{{name}}</p>{{else}}Empty{{/each}}'
      is_data = ls_data ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_html exp = '<p>1:A&amp;B</p><p>2:Second</p>' ).
  ENDMETHOD.

  METHOD invalid_hidden_block.
    TYPES: BEGIN OF ty_data, enabled TYPE abap_bool, END OF ty_data.
    DATA ls_data TYPE ty_data.
    TRY.
        zcl_pdf_studio_binder=>render(
          iv_template = '{{#if enabled}}{{#each items}}{{/if}}{{/if}}'
          is_data = ls_data ).
        cl_abap_unit_assert=>fail( 'Wrong closing tag in hidden branch must fail' ).
      CATCH zcx_pdf_studio INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_true(
          act = xsdbool( lx_error->get_text( ) CS 'Expected /EACH' ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD total_sum_char.
    "Same data as the invoice report: amounts as text.
    TYPES: BEGIN OF ty_item, material TYPE c LENGTH 18, amount TYPE c LENGTH 20, END OF ty_item,
           ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,
           BEGIN OF ty_doc, items TYPE ty_items, END OF ty_doc.
    DATA ls_doc TYPE ty_doc.
    ls_doc-items = VALUE #( ( material = 'MAT-100' amount = '50.00' ) ( material = 'MAT-200' amount = '91.00' )
                            ( material = 'MAT-300' amount = '16.25' ) ( material = 'MAT-400' amount = '22.00' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_binder=>render( iv_template = '{{sum ITEMS.AMOUNT}}' is_data = ls_doc )
      exp = '179.25'
      msg = 'sum over a text AMOUNT field' ).
  ENDMETHOD.

  METHOD total_sum_packed.
    "Amounts as packed numbers (CURR/DEC fields); the separator follows the user's number format.
    TYPES: BEGIN OF ty_item, amount TYPE p LENGTH 13 DECIMALS 2, END OF ty_item,
           ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,
           BEGIN OF ty_doc, items TYPE ty_items, END OF ty_doc.
    DATA ls_doc TYPE ty_doc.
    DATA lv_out TYPE string.
    ls_doc-items = VALUE #( ( amount = '50.00' ) ( amount = '91.00' ) ( amount = '16.25' ) ( amount = '22.00' ) ).
    lv_out = zcl_pdf_studio_binder=>render( iv_template = '{{sum ITEMS.AMOUNT}}' is_data = ls_doc ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lv_out = '179.25' OR lv_out = '179,25' )
      msg = |sum over a packed AMOUNT field returned "{ lv_out }"| ).
  ENDMETHOD.

  METHOD total_designer_table.
    "The shape the designer saves: metadata comment, data row, total in a footer row.
    TYPES: BEGIN OF ty_item, material TYPE c LENGTH 18, qty TYPE c LENGTH 15, amount TYPE c LENGTH 20, END OF ty_item,
           ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,
           BEGIN OF ty_doc, items TYPE ty_items, END OF ty_doc.
    DATA ls_doc TYPE ty_doc.
    DATA lv_out TYPE string.
    ls_doc-items = VALUE #( ( material = 'MAT-100' qty = '10' amount = '50.00' ) ( material = 'MAT-200' qty = '2' amount = '91.00' )
                            ( material = 'MAT-300' qty = '5' amount = '16.25' ) ( material = 'MAT-400' qty = '20' amount = '22.00' ) ).
    lv_out = zcl_pdf_studio_binder=>render(
      iv_template = '<!--abappdf64:eyJ1bml0IjoicHgiLCJ3aWRnZXRzIjpbXX0--><table><tbody>' &&
                    '{{#each ITEMS}}<tr><td><div>{{material}}</div></td><td><div>{{QTY}}</div></td><td><div>{{AMOUNT}}</div></td></tr>{{/each}}' &&
                    '<tr class="tfoot"><td colspan="2"><div>Total</div></td><td><div>{{sum ITEMS.AMOUNT}}</div></td></tr></tbody></table>'
      is_data     = ls_doc ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lv_out CS '<div>Total</div></td><td><div>179.25</div>' )
      msg = |designer table total missing: { lv_out }| ).
  ENDMETHOD.

  METHOD total_count_avg_format.
    TYPES: BEGIN OF ty_item, amount TYPE c LENGTH 20, END OF ty_item,
           ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,
           BEGIN OF ty_doc, items TYPE ty_items, END OF ty_doc.
    DATA ls_doc TYPE ty_doc.
    ls_doc-items = VALUE #( ( amount = '1000.00' ) ( amount = '234.50' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_binder=>render(
              iv_template = '{{count ITEMS}}|{{avg ITEMS.AMOUNT}}|<span data-fmt="#,##0.00">{{sum ITEMS.AMOUNT}}</span>|<span data-fmt="#.##0,00">{{max ITEMS.AMOUNT}}</span>'
              is_data     = ls_doc )
      exp = '2|617.25|<span data-fmt="#,##0.00">1,234.50</span>|<span data-fmt="#.##0,00">1.000,00</span>'
      msg = 'count, average and number formats' ).
  ENDMETHOD.

  METHOD raw_keeps_formatting.
    TYPES: BEGIN OF ty_doc, raw TYPE string, END OF ty_doc.
    DATA ls_doc TYPE ty_doc.
    ls_doc-raw = `<B>Total</B> <table border=1><tr><td colspan='2' style="color:red">x &amp; y</td></tr></table>`.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_binder=>render( iv_template = '{{{RAW}}}' is_data = ls_doc )
      exp = `<b>Total</b> <table border="1"><tr><td colspan="2" style="color:red">x &amp; y</td></tr></table>` ).
  ENDMETHOD.

  METHOD raw_blocks_attacks.
    TYPES: BEGIN OF ty_doc, raw TYPE string, END OF ty_doc.
    DATA ls_doc TYPE ty_doc.
    DATA lt_inputs TYPE string_table.
    DATA lv_input TYPE string.
    DATA lv_out TYPE string.
    lt_inputs = VALUE #(
      ( `<img src=x"onerror=alert(1)>` )
      ( `<a href="java&#115;cript:alert(1)">x</a>` )
      ( `<a href="java&#x09;script:alert(1)">x</a>` )
      ( |<a href="java\tscript:alert(1)">x</a>| )
      ( `<a href=" JaVaScRiPt:alert(1)">x</a>` )
      ( `<a href="data:text/html,<script>alert(1)</script>">x</a>` )
      ( `<script>alert(1)</script>` )
      ( `<ScRiPt src=//evil></ScRiPt>` )
      ( `<svg onload=alert(1)><circle/></svg>` )
      ( `<iframe src="https://intranet/"></iframe>` )
      ( `<meta http-equiv="refresh" content="0;url=javascript:alert(1)">` )
      ( `<img src="http://intranet/secret.png">` )
      ( `<div style="background:url(http://intranet/x)">t</div>` )
      ( `<div style="background:u\72l(http://intranet/x)">t</div>` )
      ( `<div style="width:expression(alert(1))">t</div>` )
      ( `<b onclick="alert(1)" onmouseover=alert(1)>t</b>` )
      ( `<form action="https://intranet/"><input name=x></form>` ) ).
    LOOP AT lt_inputs INTO lv_input.
      ls_doc-raw = lv_input.
      lv_out = to_lower( zcl_pdf_studio_binder=>render( iv_template = '{{{RAW}}}' is_data = ls_doc ) ).
      cl_abap_unit_assert=>assert_true(
        act = xsdbool( lv_out NS '<script' AND lv_out NS 'javascript' AND lv_out NS 'onerror'
                   AND lv_out NS 'onload' AND lv_out NS 'onclick' AND lv_out NS 'onmouseover'
                   AND lv_out NS 'intranet' AND lv_out NS 'evil' AND lv_out NS '<iframe'
                   AND lv_out NS '<meta' AND lv_out NS '<svg' AND lv_out NS '<form'
                   AND lv_out NS 'expression' AND lv_out NS 'data:text' )
        msg = |Not sanitized: { lv_input } -> { lv_out }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD raw_embedded_image.
    TYPES: BEGIN OF ty_doc, raw TYPE string, END OF ty_doc.
    DATA ls_doc TYPE ty_doc.
    ls_doc-raw = `<img src="data:image/png;base64,iVBORw0KGgo=" width="20">`.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_studio_binder=>render( iv_template = '{{{RAW}}}' is_data = ls_doc )
      exp = ls_doc-raw ).
  ENDMETHOD.

ENDCLASS.
