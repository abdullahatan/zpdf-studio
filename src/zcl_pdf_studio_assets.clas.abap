"! <p>Asset store of ZPDF Studio (table ZPDF_STUDIO_ASST): logos, images and TrueType fonts.</p>
"! Comparable to SE78 (graphics) and SE73 (TrueType fonts), but transportable as customizing
"! together with the forms that use them. Images are referenced in forms as src="asset:LOGO",
"! fonts by their family name in CSS font-family.
"! An instance is the default ZIF_PDF_STUDIO_RESOURCES of the engine.
CLASS zcl_pdf_studio_assets DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_pdf_studio_resources.

    CONSTANTS c_image TYPE string VALUE 'IMAGE'.
    CONSTANTS c_font TYPE string VALUE 'FONT'.
    CONSTANTS c_max_size TYPE i VALUE 10000000.

    TYPES:
      BEGIN OF ty_asset,
        asset_id    TYPE string,
        kind        TYPE string,
        family      TYPE string,
        bold        TYPE abap_bool,
        italic      TYPE abap_bool,
        mime        TYPE string,
        filename    TYPE string,
        description TYPE string,
        changed_by  TYPE syuname,
        changed_at  TYPE timestamp,
        size        TYPE i,
      END OF ty_asset,
      ty_assets TYPE STANDARD TABLE OF ty_asset WITH EMPTY KEY,
      ty_ids    TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! Stores an image (PNG, JPEG) or a TrueType font. The kind and MIME type are detected.
    "! In clients with automatic recording the entry is added to a transport request.
    "! @parameter is_asset | ID (A-Z, 0-9, _), family and style for fonts, description
    "! @parameter rv_request | Transport request when the change was recorded
    CLASS-METHODS save
      IMPORTING
        is_asset          TYPE ty_asset
        iv_content        TYPE xstring
        iv_record         TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_request) TYPE trkorr
      RAISING
        zcx_pdf_studio.

    CLASS-METHODS delete
      IMPORTING
        iv_asset_id       TYPE csequence
      RETURNING
        VALUE(rv_request) TYPE trkorr
      RAISING
        zcx_pdf_studio.

    "! Assets without content; iv_kind IMAGE or FONT filters.
    CLASS-METHODS list
      IMPORTING
        iv_kind          TYPE csequence OPTIONAL
      RETURNING
        VALUE(rt_assets) TYPE ty_assets.

    CLASS-METHODS read
      IMPORTING
        iv_asset_id   TYPE csequence
      EXPORTING
        es_asset      TYPE ty_asset
        ev_content    TYPE xstring
      RAISING
        zcx_pdf_studio.

    "! Adds assets to a transport request chosen by the user.
    CLASS-METHODS transport
      IMPORTING
        it_ids            TYPE ty_ids
      RETURNING
        VALUE(rv_request) TYPE trkorr
      RAISING
        zcx_pdf_studio.

    "! Adds a form and every asset it uses (images, fonts) to one transport request.
    CLASS-METHODS transport_form
      IMPORTING
        iv_form_id        TYPE csequence
      RETURNING
        VALUE(rv_request) TYPE trkorr
      RAISING
        zcx_pdf_studio.

    "! Assets used by form HTML: asset:NAME images and font families.
    CLASS-METHODS used_assets
      IMPORTING
        iv_html       TYPE string
      RETURNING
        VALUE(rt_ids) TYPE ty_ids.

    "! Kind and MIME type from the file content (PNG, JPEG, TrueType); empty when unsupported.
    CLASS-METHODS detect
      IMPORTING
        iv_content TYPE xstring
      EXPORTING
        ev_kind    TYPE string
        ev_mime    TYPE string.

    CLASS-METHODS normalize_id
      IMPORTING
        iv_id        TYPE csequence
      RETURNING
        VALUE(rv_id) TYPE string
      RAISING
        zcx_pdf_studio.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_cache,
        key  TYPE string,
        data TYPE xstring,
      END OF ty_cache,
      ty_caches TYPE HASHED TABLE OF ty_cache WITH UNIQUE KEY key.
    DATA mt_cache TYPE ty_caches.
    DATA mt_families TYPE zif_pdf_studio_resources=>ty_families.
    DATA mv_families_read TYPE abap_bool.

    CLASS-METHODS check_authority
      IMPORTING
        iv_group TYPE csequence
      RAISING
        zcx_pdf_studio.
    CLASS-METHODS entry
      IMPORTING
        iv_asset_id     TYPE string
      RETURNING
        VALUE(rs_entry) TYPE zcl_pdf_studio_transport=>ty_entry.
ENDCLASS.



CLASS zcl_pdf_studio_assets IMPLEMENTATION.

  METHOD check_authority.
    AUTHORITY-CHECK OBJECT 'S_PROGRAM'
      ID 'P_GROUP' FIELD iv_group
      ID 'P_ACTION' FIELD 'SUBMIT'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |Missing authorization: S_PROGRAM { iv_group } / SUBMIT|.
    ENDIF.
  ENDMETHOD.


  METHOD normalize_id.
    rv_id = to_upper( condense( iv_id ) ).
    IF rv_id IS INITIAL OR strlen( rv_id ) > 30 OR NOT matches( val = rv_id regex = `[A-Z0-9_]+` ).
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = |Asset ID "{ iv_id }" is invalid: use A-Z, 0-9 and _ (max. 30 characters)|.
    ENDIF.
  ENDMETHOD.


  METHOD detect.
    CLEAR: ev_kind, ev_mime.
    IF xstrlen( iv_content ) < 8.
      RETURN.
    ENDIF.
    IF iv_content(8) = '89504E470D0A1A0A'.
      ev_kind = c_image.
      ev_mime = `image/png`.
    ELSEIF iv_content(3) = 'FFD8FF'.
      ev_kind = c_image.
      ev_mime = `image/jpeg`.
    ELSEIF iv_content(4) = '00010000' OR iv_content(4) = '74727565'.
      ev_kind = c_font.
      ev_mime = `font/ttf`.
    ENDIF.
  ENDMETHOD.


  METHOD entry.
    DATA lv_key TYPE c LENGTH 30.
    lv_key = iv_asset_id.
    rs_entry-tabname = zcl_pdf_studio_transport=>c_assets.
    rs_entry-key = lv_key.
  ENDMETHOD.


  METHOD save.
    DATA ls_row TYPE zpdf_studio_asst.
    DATA lv_kind TYPE string.
    DATA lv_mime TYPE string.
    DATA lt_entries TYPE zcl_pdf_studio_transport=>ty_entries.
    DATA lo_font TYPE REF TO zcl_pdf_studio_font.

    check_authority( 'ZPDFSEDT' ).
    IF zcl_pdf_studio_transport=>client_recording( ) = '2'.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |Client { sy-mandt } does not allow changes (SCC4)|.
    ENDIF.
    IF iv_content IS INITIAL OR xstrlen( iv_content ) > c_max_size.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'File is empty or larger than 10 MB'.
    ENDIF.
    detect( EXPORTING iv_content = iv_content IMPORTING ev_kind = lv_kind ev_mime = lv_mime ).
    IF lv_kind IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio
        EXPORTING message = 'Unsupported file: use PNG or JPEG for images and TrueType (.ttf) for fonts'.
    ENDIF.

    ls_row-mandt = sy-mandt.
    ls_row-asset_id = normalize_id( is_asset-asset_id ).
    ls_row-kind = lv_kind.
    ls_row-mime = lv_mime.
    ls_row-filename = is_asset-filename.
    ls_row-description = is_asset-description.
    IF lv_kind = c_font.
      "Reading the font checks the file and the embedding permission of its license.
      lo_font = zcl_pdf_studio_font=>create( iv_content ).
      ls_row-family = to_lower( condense( is_asset-family ) ).
      IF ls_row-family IS INITIAL.
        ls_row-family = to_lower( lo_font->mv_name ).
      ENDIF.
      ls_row-bold = is_asset-bold.
      ls_row-italic = is_asset-italic.
    ENDIF.
    ls_row-changed_by = sy-uname.
    GET TIME STAMP FIELD ls_row-changed_at.
    ls_row-content = iv_content.
    MODIFY zpdf_studio_asst FROM ls_row.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |Asset { ls_row-asset_id } could not be saved|.
    ENDIF.
    "iv_record = abap_false: the caller saves several assets and records them in one request
    "(method TRANSPORT) instead of one request dialog per asset.
    IF iv_record = abap_true.
      APPEND entry( CONV #( ls_row-asset_id ) ) TO lt_entries.
      rv_request = zcl_pdf_studio_transport=>record_if_automatic( lt_entries ).
    ENDIF.
    COMMIT WORK.
  ENDMETHOD.


  METHOD delete.
    DATA lv_id TYPE string.
    DATA lt_entries TYPE zcl_pdf_studio_transport=>ty_entries.
    check_authority( 'ZPDFSEDT' ).
    check_authority( 'ZPDFSADM' ).
    lv_id = normalize_id( iv_asset_id ).
    DELETE FROM zpdf_studio_asst WHERE asset_id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |Asset { lv_id } does not exist|.
    ENDIF.
    "A deleted entry is transported as a deletion.
    APPEND entry( lv_id ) TO lt_entries.
    rv_request = zcl_pdf_studio_transport=>record_if_automatic( lt_entries ).
    COMMIT WORK.
  ENDMETHOD.


  METHOD list.
    DATA lt_rows TYPE STANDARD TABLE OF zpdf_studio_asst WITH EMPTY KEY.
    DATA ls_row TYPE zpdf_studio_asst.
    DATA ls_asset TYPE ty_asset.
    DATA lv_kind TYPE c LENGTH 10.

    lv_kind = to_upper( iv_kind ).
    IF lv_kind IS INITIAL.
      SELECT * FROM zpdf_studio_asst INTO TABLE lt_rows ORDER BY asset_id.
    ELSE.
      SELECT * FROM zpdf_studio_asst INTO TABLE lt_rows WHERE kind = lv_kind ORDER BY asset_id.
    ENDIF.
    LOOP AT lt_rows INTO ls_row.
      CLEAR ls_asset.
      ls_asset-asset_id = ls_row-asset_id.
      ls_asset-kind = ls_row-kind.
      ls_asset-family = ls_row-family.
      ls_asset-bold = ls_row-bold.
      ls_asset-italic = ls_row-italic.
      ls_asset-mime = ls_row-mime.
      ls_asset-filename = ls_row-filename.
      ls_asset-description = ls_row-description.
      ls_asset-changed_by = ls_row-changed_by.
      ls_asset-changed_at = ls_row-changed_at.
      ls_asset-size = xstrlen( ls_row-content ).
      APPEND ls_asset TO rt_assets.
    ENDLOOP.
  ENDMETHOD.


  METHOD read.
    DATA ls_row TYPE zpdf_studio_asst.
    DATA lv_id TYPE string.
    lv_id = normalize_id( iv_asset_id ).
    SELECT SINGLE * FROM zpdf_studio_asst INTO ls_row WHERE asset_id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = |Asset { lv_id } does not exist|.
    ENDIF.
    es_asset-asset_id = ls_row-asset_id.
    es_asset-kind = ls_row-kind.
    es_asset-family = ls_row-family.
    es_asset-bold = ls_row-bold.
    es_asset-italic = ls_row-italic.
    es_asset-mime = ls_row-mime.
    es_asset-filename = ls_row-filename.
    es_asset-description = ls_row-description.
    es_asset-changed_by = ls_row-changed_by.
    es_asset-changed_at = ls_row-changed_at.
    es_asset-size = xstrlen( ls_row-content ).
    ev_content = ls_row-content.
  ENDMETHOD.


  METHOD transport.
    DATA lt_entries TYPE zcl_pdf_studio_transport=>ty_entries.
    DATA lv_id TYPE string.
    check_authority( 'ZPDFSEDT' ).
    LOOP AT it_ids INTO lv_id.
      APPEND entry( normalize_id( lv_id ) ) TO lt_entries.
    ENDLOOP.
    IF lt_entries IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pdf_studio EXPORTING message = 'No asset selected'.
    ENDIF.
    rv_request = zcl_pdf_studio_transport=>transport( lt_entries ).
    COMMIT WORK.
  ENDMETHOD.


  METHOD used_assets.
    DATA lv_html TYPE string.
    DATA lt_matches TYPE match_result_tab.
    DATA ls_match TYPE match_result.
    DATA ls_sub TYPE submatch_result.
    DATA lv_id TYPE string.
    DATA lt_fonts TYPE STANDARD TABLE OF zpdf_studio_asst WITH EMPTY KEY.
    DATA ls_font TYPE zpdf_studio_asst.
    DATA lv_family TYPE string.

    lv_html = iv_html.
    FIND ALL OCCURRENCES OF REGEX 'asset:([A-Za-z0-9_]+)' IN lv_html RESULTS lt_matches.
    LOOP AT lt_matches INTO ls_match.
      READ TABLE ls_match-submatches INTO ls_sub INDEX 1.
      lv_id = to_upper( substring( val = lv_html off = ls_sub-offset len = ls_sub-length ) ).
      READ TABLE rt_ids TRANSPORTING NO FIELDS WITH KEY table_line = lv_id.
      IF sy-subrc <> 0.
        APPEND lv_id TO rt_ids.
      ENDIF.
    ENDLOOP.
    "Fonts: every file of a family named in the form.
    SELECT * FROM zpdf_studio_asst INTO TABLE lt_fonts WHERE kind = 'FONT'.
    lv_html = to_lower( iv_html ).
    LOOP AT lt_fonts INTO ls_font.
      lv_family = ls_font-family.
      IF lv_family IS NOT INITIAL AND lv_html CS lv_family.
        lv_id = ls_font-asset_id.
        READ TABLE rt_ids TRANSPORTING NO FIELDS WITH KEY table_line = lv_id.
        IF sy-subrc <> 0.
          APPEND lv_id TO rt_ids.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD transport_form.
    DATA ls_template TYPE zcl_pdf_studio_repo=>ty_template.
    DATA lt_entries TYPE zcl_pdf_studio_transport=>ty_entries.
    DATA ls_entry TYPE zcl_pdf_studio_transport=>ty_entry.
    DATA lv_key TYPE c LENGTH 30.
    DATA lv_id TYPE string.

    check_authority( 'ZPDFSEDT' ).
    ls_template = zcl_pdf_studio_repo=>read_active_template( iv_form_id ).
    "Form: client + form ID + every version.
    lv_key = to_upper( iv_form_id ).
    ls_entry-tabname = zcl_pdf_studio_transport=>c_forms.
    CONCATENATE lv_key '*' INTO ls_entry-key RESPECTING BLANKS.
    APPEND ls_entry TO lt_entries.
    LOOP AT used_assets( ls_template-html_content && ls_template-css_content
                         && ls_template-header_html && ls_template-footer_html ) INTO lv_id.
      APPEND entry( lv_id ) TO lt_entries.
    ENDLOOP.
    rv_request = zcl_pdf_studio_transport=>transport( lt_entries ).
    COMMIT WORK.
  ENDMETHOD.


  METHOD zif_pdf_studio_resources~font_families.
    DATA lt_rows TYPE STANDARD TABLE OF zpdf_studio_asst-family WITH EMPTY KEY.
    DATA lv_family TYPE zpdf_studio_asst-family.
    IF mv_families_read = abap_false.
      SELECT DISTINCT family FROM zpdf_studio_asst INTO TABLE lt_rows WHERE kind = 'FONT'.
      LOOP AT lt_rows INTO lv_family.
        APPEND to_lower( condense( lv_family ) ) TO mt_families.
      ENDLOOP.
      mv_families_read = abap_true.
    ENDIF.
    rt_families = mt_families.
  ENDMETHOD.


  METHOD zif_pdf_studio_resources~font.
    DATA lv_family TYPE zpdf_studio_asst-family.
    DATA lv_bold TYPE c LENGTH 1.
    DATA lv_italic TYPE c LENGTH 1.
    DATA ls_cache TYPE ty_cache.
    DATA lt_rows TYPE STANDARD TABLE OF zpdf_studio_asst WITH EMPTY KEY.
    DATA ls_row TYPE zpdf_studio_asst.

    lv_family = to_lower( condense( iv_family ) ).
    lv_bold = iv_bold.
    lv_italic = iv_italic.
    ls_cache-key = |F:{ lv_family }:{ lv_bold }:{ lv_italic }|.
    READ TABLE mt_cache INTO ls_cache WITH TABLE KEY key = ls_cache-key.
    IF sy-subrc = 0.
      rv_data = ls_cache-data.
      RETURN.
    ENDIF.
    SELECT * FROM zpdf_studio_asst INTO TABLE lt_rows WHERE kind = 'FONT' AND family = lv_family.
    "Exact style, else regular (as with SE73 font families).
    READ TABLE lt_rows INTO ls_row WITH KEY bold = lv_bold italic = lv_italic.
    IF sy-subrc <> 0.
      READ TABLE lt_rows INTO ls_row WITH KEY bold = space italic = space.
      IF sy-subrc <> 0.
        READ TABLE lt_rows INTO ls_row INDEX 1.
      ENDIF.
    ENDIF.
    rv_data = ls_row-content.
    ls_cache-data = rv_data.
    INSERT ls_cache INTO TABLE mt_cache.
  ENDMETHOD.


  METHOD zif_pdf_studio_resources~image.
    DATA lv_id TYPE zpdf_studio_asst-asset_id.
    DATA ls_cache TYPE ty_cache.
    DATA ls_row TYPE zpdf_studio_asst.

    lv_id = to_upper( condense( iv_name ) ).
    ls_cache-key = |I:{ lv_id }|.
    READ TABLE mt_cache INTO ls_cache WITH TABLE KEY key = ls_cache-key.
    IF sy-subrc = 0.
      rv_data = ls_cache-data.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zpdf_studio_asst INTO ls_row WHERE asset_id = lv_id AND kind = 'IMAGE'.
    rv_data = ls_row-content.
    ls_cache-data = rv_data.
    INSERT ls_cache INTO TABLE mt_cache.
  ENDMETHOD.

ENDCLASS.
