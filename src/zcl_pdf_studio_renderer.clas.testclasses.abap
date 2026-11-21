CLASS ltc_renderer DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS invalid_page_area FOR TESTING.
    METHODS native_latin FOR TESTING RAISING zcx_pdf_studio.
    METHODS native_turkish FOR TESTING RAISING zcx_pdf_studio.
    METHODS text_align_horizontal FOR TESTING RAISING zcx_pdf_studio.
    METHODS text_align_vertical FOR TESTING RAISING zcx_pdf_studio.
    METHODS assert_pdf
      IMPORTING iv_pdf TYPE xstring.
    METHODS a4
      RETURNING VALUE(rs_page) TYPE zcl_pdf_studio_renderer=>ty_page.
    "A text object exactly as the designer writes it: 80 x 30 mm at 40 / 50 mm of the page.
    METHODS designer_text
      IMPORTING iv_align       TYPE string
                iv_valign      TYPE string OPTIONAL
      RETURNING VALUE(rv_html) TYPE string.
    "Position (in points) of the first text that the page draws, read from the PDF itself.
    METHODS text_origin
      IMPORTING iv_html TYPE string
      EXPORTING ev_x    TYPE f
                ev_y    TYPE f
      RAISING   zcx_pdf_studio.
ENDCLASS.

CLASS ltc_renderer IMPLEMENTATION.

  METHOD invalid_page_area.
    DATA ls_page TYPE zcl_pdf_studio_renderer=>ty_page.
    ls_page-page_size = 'A4'.
    ls_page-orientation = 'P'.
    ls_page-margin_left = 110.
    ls_page-margin_right = 110.
    TRY.
        zcl_pdf_studio_renderer=>validate_page( ls_page ).
        cl_abap_unit_assert=>fail( 'Margins consuming the page must fail' ).
      CATCH zcx_pdf_studio INTO DATA(lx_error).
        "The text is English, or Turkish for a Turkish logon.
        cl_abap_unit_assert=>assert_true(
          act = xsdbool( lx_error->get_text( ) CS 'printable page area' OR lx_error->get_text( ) CS 'yazdırılabilir alan' ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD native_latin.
    "The native engine writes a complete PDF without Gotenberg.
    assert_pdf( zcl_pdf_studio_engine=>render(
      iv_html = `<h1>Invoice</h1><table><tr><td>MAT-100</td><td>50.00</td></tr></table>`
      is_page = a4( ) ) ).
  ENDMETHOD.

  METHOD native_turkish.
    "Turkish letters are printed with the standard fonts (no font upload needed).
    assert_pdf( zcl_pdf_studio_engine=>render(
      iv_html = `<h1>Banka Talimatı</h1><p>Şube: Çağlayan İş Merkezi, Gönderen: Öğüt Işık A.Ş. - 100245</p>`
      is_page = a4( ) ) ).
  ENDMETHOD.

  METHOD text_align_horizontal.
    "Layout > Align text > Left / Centre / Right of the designer: the text moves inside its box.
    CONSTANTS lc_mm TYPE f VALUE '2.834645669'.
    DATA lv_left TYPE f.
    DATA lv_centre TYPE f.
    DATA lv_right TYPE f.
    DATA lv_y TYPE f.
    DATA lv_y_right TYPE f.

    text_origin( EXPORTING iv_html = designer_text( `left` ) IMPORTING ev_x = lv_left ev_y = lv_y ).
    text_origin( EXPORTING iv_html = designer_text( `center` ) IMPORTING ev_x = lv_centre ).
    text_origin( EXPORTING iv_html = designer_text( `right` ) IMPORTING ev_x = lv_right ev_y = lv_y_right ).

    "Left: the text starts at the left edge of the box (40 mm from the paper edge).
    cl_abap_unit_assert=>assert_equals( act = lv_left exp = 40 * lc_mm tol = '0.5' msg = 'left aligned text starts at the box' ).
    "Right: the text ends at the right edge of the box, so it starts far to the right of it.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_right > lv_left + 50 * lc_mm AND lv_right < 120 * lc_mm )
                                      msg = |right aligned text: { lv_right } (left { lv_left })| ).
    "Centre: exactly between the two.
    cl_abap_unit_assert=>assert_equals( act = lv_centre exp = ( lv_left + lv_right ) / 2 tol = '0.5' msg = 'centred text' ).
    "The horizontal alignment does not move the text vertically.
    cl_abap_unit_assert=>assert_equals( act = lv_y_right exp = lv_y tol = '0.01' ).
  ENDMETHOD.

  METHOD text_align_vertical.
    "Layout > Align text > Top / Middle / Bottom.
    CONSTANTS lc_mm TYPE f VALUE '2.834645669'.
    DATA lv_top TYPE f.
    DATA lv_middle TYPE f.
    DATA lv_bottom TYPE f.
    DATA lv_x TYPE f.
    DATA lv_x_bottom TYPE f.

    text_origin( EXPORTING iv_html = designer_text( iv_align = `left` iv_valign = `top` ) IMPORTING ev_x = lv_x ev_y = lv_top ).
    text_origin( EXPORTING iv_html = designer_text( iv_align = `left` iv_valign = `middle` ) IMPORTING ev_y = lv_middle ).
    text_origin( EXPORTING iv_html = designer_text( iv_align = `left` iv_valign = `bottom` ) IMPORTING ev_x = lv_x_bottom ev_y = lv_bottom ).

    "PDF coordinates grow upwards: the top aligned text has the largest y.
    "Top: the first line is inside the first 6 mm of the box (which starts 50 mm below the paper edge).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_top < ( 297 - 50 ) * lc_mm AND lv_top > ( 297 - 56 ) * lc_mm )
                                      msg = |top aligned text: { lv_top }| ).
    "Bottom: the line is inside the last 6 mm of the 30 mm high box.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_bottom > ( 297 - 80 ) * lc_mm AND lv_bottom < ( 297 - 74 ) * lc_mm )
                                      msg = |bottom aligned text: { lv_bottom }| ).
    cl_abap_unit_assert=>assert_equals( act = lv_middle exp = ( lv_top + lv_bottom ) / 2 tol = '0.5' msg = 'middle aligned text' ).
    cl_abap_unit_assert=>assert_equals( act = lv_x_bottom exp = lv_x tol = '0.01' ).
  ENDMETHOD.

  METHOD designer_text.
    rv_html = `<section><div style="position:absolute;box-sizing:border-box;overflow:hidden;left:28mm;top:35mm;` &&
              `width:80mm;height:30mm;font-family:Arial;font-size:10pt;color:#000000;background:transparent;` &&
              |text-align:{ iv_align };white-space:pre-wrap;|.
    IF iv_valign = `middle` OR iv_valign = `bottom`.
      rv_html = |{ rv_html }vertical-align:{ iv_valign };|.
    ENDIF.
    rv_html = |{ rv_html }">HIZA</div></section>|.
  ENDMETHOD.

  METHOD text_origin.
    CONSTANTS lc_stream TYPE x LENGTH 6 VALUE '73747265616D'.
    CONSTANTS lc_end TYPE x LENGTH 3 VALUE '656E64'.
    CONSTANTS lc_zlib TYPE x LENGTH 2 VALUE '789C'.
    DATA ls_page TYPE zcl_pdf_studio_renderer=>ty_page.
    DATA lv_pdf TYPE xstring.
    DATA lt_hits TYPE match_result_tab.
    DATA ls_hit TYPE match_result.
    DATA lv_before TYPE x LENGTH 3.
    DATA lv_head TYPE x LENGTH 2.
    DATA lv_from TYPE i.
    DATA lv_off TYPE i.
    DATA lv_len TYPE i.
    DATA lv_data TYPE xstring.
    DATA lv_plain TYPE xstring.
    DATA lv_text TYPE string.
    DATA lv_x TYPE string.
    DATA lv_y TYPE string.

    CLEAR: ev_x, ev_y.
    "The page of a new form in the designer: A4, margins 15 / 12 / 15 / 12 mm.
    ls_page-page_size = 'A4'.
    ls_page-orientation = 'P'.
    ls_page-margin_top = 15.
    ls_page-margin_right = 12.
    ls_page-margin_bottom = 15.
    ls_page-margin_left = 12.
    lv_pdf = zcl_pdf_studio_engine=>render( iv_html = iv_html is_page = ls_page ).

    "Every "stream ... endstream" of the PDF; the page content is deflated (zlib).
    FIND ALL OCCURRENCES OF lc_stream IN lv_pdf IN BYTE MODE RESULTS lt_hits.
    LOOP AT lt_hits INTO ls_hit.
      CLEAR lv_before.
      IF ls_hit-offset >= 3.
        lv_off = ls_hit-offset - 3.
        lv_before = lv_pdf+lv_off(3).
      ENDIF.
      IF lv_before <> lc_end.
        lv_from = ls_hit-offset + 7.
        CONTINUE.
      ENDIF.
      IF lv_from <= 0.
        CONTINUE.
      ENDIF.
      lv_len = ls_hit-offset - 4 - lv_from.
      IF lv_len <= 6.
        lv_from = 0.
        CONTINUE.
      ENDIF.
      lv_data = lv_pdf+lv_from(lv_len).
      lv_from = 0.
      lv_head = lv_data(2).
      IF lv_head = lc_zlib.
        lv_len = lv_len - 6.
        lv_data = lv_data+2(lv_len).
        TRY.
            cl_abap_gzip=>decompress_binary( EXPORTING gzip_in = lv_data IMPORTING raw_out = lv_plain ).
          CATCH cx_root.
            CONTINUE.
        ENDTRY.
      ELSE.
        lv_plain = lv_data.
      ENDIF.
      TRY.
          lv_text = zcl_pdf_studio_conv=>xstring_to_string( lv_plain ).
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
      FIND FIRST OCCURRENCE OF REGEX `(-?[0-9.]+) (-?[0-9.]+) Td <` IN lv_text SUBMATCHES lv_x lv_y.
      IF sy-subrc = 0.
        ev_x = lv_x.
        ev_y = lv_y.
        RETURN.
      ENDIF.
    ENDLOOP.
    cl_abap_unit_assert=>fail( 'No text was found in the page content of the PDF' ).
  ENDMETHOD.

  METHOD assert_pdf.
    CONSTANTS lc_magic TYPE x LENGTH 4 VALUE '25504446'. "%PDF
    DATA lv_head TYPE x LENGTH 4.
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( xstrlen( iv_pdf ) > 200 )
      msg = 'PDF is empty or too small' ).
    lv_head = iv_pdf(4).
    cl_abap_unit_assert=>assert_equals(
      act = lv_head
      exp = lc_magic
      msg = 'Output does not start with %PDF' ).
  ENDMETHOD.

  METHOD a4.
    rs_page-page_size = 'A4'.
    rs_page-orientation = 'P'.
    rs_page-margin_top = 12.
    rs_page-margin_right = 10.
    rs_page-margin_bottom = 16.
    rs_page-margin_left = 10.
  ENDMETHOD.

ENDCLASS.
