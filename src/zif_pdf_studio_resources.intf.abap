"! <p>Resources a form can use while it is rendered: uploaded fonts and images.</p>
"! The default implementation (ZCL_PDF_STUDIO_ASSETS) reads table ZPDF_STUDIO_ASST.
"! Tests and special callers can pass their own implementation to the engine.
INTERFACE zif_pdf_studio_resources
  PUBLIC.

  TYPES ty_families TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  "! Font families that can be used in CSS font-family (lower case).
  METHODS font_families
    RETURNING
      VALUE(rt_families) TYPE ty_families.

  "! TrueType file of a family and variant. When the variant is missing the regular file is returned.
  "! @parameter iv_family | Family name, case-insensitive
  "! @parameter rv_data | TTF file, empty when the family is unknown
  METHODS font
    IMPORTING
      iv_family      TYPE csequence
      iv_bold        TYPE abap_bool
      iv_italic      TYPE abap_bool
    RETURNING
      VALUE(rv_data) TYPE xstring.

  "! Image file (PNG or JPEG) of an asset, for &lt;img src="asset:NAME"&gt;.
  METHODS image
    IMPORTING
      iv_name        TYPE csequence
    RETURNING
      VALUE(rv_data) TYPE xstring.

ENDINTERFACE.
