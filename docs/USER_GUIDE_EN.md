# ZPDF Studio User Guide

ZPDF Studio 2.2.0 · [Türkçe](USER_GUIDE_TR.md)

## Contents

1. [Introduction](#1-introduction)
2. [Installation](#2-installation)
3. [Opening a form](#3-opening-a-form)
4. [The designer screen](#4-the-designer-screen)
5. [Interface tab](#5-interface-tab)
6. [Layout tab](#6-layout-tab)
7. [Alignment and arranging](#7-alignment-and-arranging)
8. [Menu reference](#8-menu-reference)
9. [Saving, versions, preview and transport](#9-saving-versions-preview-and-transport)
10. [Logo and font store](#10-logo-and-font-store)
11. [Printing a form from ABAP](#11-printing-a-form-from-abap)
12. [Demo forms](#12-demo-forms)
13. [Format patterns and keyboard shortcuts](#13-format-patterns-and-keyboard-shortcuts)
14. [Troubleshooting](#14-troubleshooting)
15. [Appendix: test and verification summary](#appendix-test-and-verification-summary)

## 1. Introduction

ZPDF Studio lets you design PDF forms inside SAP GUI and print them entirely in ABAP; no Adobe Document Services, Smart Forms or external service is needed. This guide covers designer version **2.2.0** and contains only features that were tested and verified.

### Components

| Object | Type | Purpose |
| --- | --- | --- |
| `ZPDF_STUDIO` | Program | Form entry screen and the designer |
| `ZPDF_STUDIO_ASSETS` | Program | Store for logos, images and fonts |
| `ZPDF_STUDIO_DEMO` | Program | Six demo forms; sample code that prints a form from a program |
| `ZCL_PDF_STUDIO_API` | Class | API to print forms from your own programs |
| `ZPDF_STUDIO_FORM` | Table | Forms and their versions (transportable) |
| `ZPDF_STUDIO_ASST` | Table | Logos, images, fonts (transportable) |
| `ZPDF_STUDIO_DRFT` | Table | Unsaved drafts (auto save) |
| `ZPDF_STUDIO_USER` | Table | User settings (theme) |
| `/SAP/PUBLIC/ZPDF_STUDIO/designer.html` | MIME object | The designer page |

### Language

With a Turkish (TR) logon the designer, the programs and the error messages are in Turkish. With every other logon language (EN, DE, FR, RU ...) they are in English. The language follows the logon language; there is no switch.

### What "verified" means in this guide

Every feature was checked in two ways:

- **Automated tests:** each of the designer's 103 menu items was clicked with the real mouse (177 checks); in addition 69 browser checks, 13 conversion tests and 59 ABAP Unit tests in SAP were run. All passed.
- **Manual tests in SAP GUI:** saving, transport, PDF preview, the exit question, the theme, TR/EN texts, the logo preview, the designer screen without SAP menus and the demo forms were tried and confirmed in SAP GUI.

Details are in the appendix.

## 2. Installation

ZPDF Studio is installed with [abapGit](https://abapgit.org). One pull brings every ABAP object, the DDIC types, the designer page (MIME repository) and the GUI status of the designer.

### Requirements

- SAP NetWeaver / S/4HANA with ABAP 7.50 syntax or higher. Developed and tested on S/4HANA 2021 (SAP_BASIS 7.56).
- SAP GUI for Windows 7.70 or higher with the **Edge (WebView2)** browser control (SAP GUI Options > Interaction Design > Browser Control).
- [abapGit](https://abapgit.org) (standalone program or developer version).
- Authorization `S_PROGRAM` with `P_ACTION = SUBMIT` and `P_GROUP = ZPDFSEDT` (create and change forms, upload logos and fonts) and `ZPDFSADM` (delete forms and assets).

### Steps

1. **Create a package**, e.g. `$ZPDF_STUDIO` (local) or `ZPDF_STUDIO` (transportable).
2. **Pull the repository with abapGit.** abapGit > New Online > URL `https://github.com/abdullahatan/zpdf-studio` > the package of step 1 > Pull, then activate all objects. Without internet access from SAP: download the repository as ZIP from GitHub, then abapGit > New Offline > Import ZIP.
3. **Check the designer.** Start `ZPDF_STUDIO`, type a form name and press **Create**. The status bar of the designer and Help > About ZPDF Studio show **2.2.0**. If the program reports that the designer page is missing or outdated, use the toolbar button **Install / update designer** and choose `designer/dist/designer.html` of this repository.
4. **Install the demo forms (optional).** `ZPDF_STUDIO_DEMO` > **Install / update demo forms** > `designer/dist/zpdf-demo-pack.txt`. Five demo forms and five images are installed (section 12).
5. **Upload logos and fonts (optional).** `ZPDF_STUDIO` > **Logos and fonts** or `ZPDF_STUDIO_ASSETS` directly (section 10). The designer can upload them too.

The GUI status `ZPDF_DESIGNER` of program `ZPDF_STUDIO` comes with the repository: the designer screen shows no SAP menus Program / Edit / Goto. For a newer designer version, pull again or upload `designer/dist/designer.html` with **Install / update designer**; forms and settings are not affected.

## 3. Opening a form

The entry screen of `ZPDF_STUDIO` works like SFP: type the form name, then press one of three buttons. Execute (F8) is intentionally not offered.

| Button | What it does | Form missing / exists |
| --- | --- | --- |
| **Display** | Opens the form read-only; save, insert and upload are disabled | Missing: "Use Create" |
| **Change** | Opens the form for editing | Missing: "Use Create" |
| **Create** | Opens a new, empty form; the form is created on the first save | Exists: "Use Change" |

- **Form name:** at most 30 characters; only A-Z, 0-9 and underscore. Lower case is converted to upper case.
- **Search help (F4):** lists saved forms with name, description and last changer.
- **Edited by someone else:** if another user has the form open, Change opens it read-only and says who is editing it.
- **Unsaved draft:** if you have an unsaved draft from an earlier session, you are asked when the form opens, with the date of the draft: **Restore** opens the draft, **Discard** opens the last saved version.
- The toolbar button **Logos and fonts** starts `ZPDF_STUDIO_ASSETS`.

## 4. The designer screen

The designer is one screen: the SAP toolbar on top, below it the designer's own menu bar, toolbar and three tabs. When an SAP dialog opens over the designer (transport, the save question) and closes, the design comes back unchanged.

| Area | Content |
| --- | --- |
| SAP toolbar | **Save**, **Preview PDF**, **Refresh page**; Back / Exit / Cancel |
| Menu bar | File, Edit, View, Insert, Table, Layout, Tools, Palettes, Help (section 8). On the right: form name, version and status — ● not saved, ✓ saved or Display only |
| Toolbar | Save, Preview, Undo, Redo, Zoom out, zoom percentage, Zoom in, Fit page, Auto save box, Theme buttons, Warnings (with their number) |
| Tabs | **Form Properties**, **Interface** (with the number of parameters), **Layout** |
| Layout tab, left | **Hierarchy** (pages and objects), **Data View** (interface field tree) |
| Layout tab, centre | The page with rulers; below it the page navigator: ‹ Page 1 / 2 ›, new page (+), delete page (−) |
| Layout tab, right | **Object Library**, **Object** palette (sub-tabs Properties and Data Binding) |
| Status bar | Left: the selected object (name, kind, position, size). Right: paper size, number of objects, version |

### Form Properties tab

- **Form:** form name, description, active version, status; buttons Versions and ABAP call code.
- **Page:** paper size (A3, A4, A5, Letter, Legal), orientation (portrait / landscape), top, bottom, left and right margin (mm). The margins are applied exactly in the PDF preview and in print.
- **Defaults:** font and size of new text objects, grid step (mm). Turkish characters print correctly with the standard fonts as well.

### Zoom

Zoom only enlarges the page; menus and palettes keep their size. The steps run from 25 % to 400 % and pass through 100 %.

- **− / +** in the toolbar, or the **− / +** keys on the Layout tab.
- **Alt + mouse wheel** or **Ctrl + mouse wheel** over the page.
- **Ctrl + − / Ctrl + + / Ctrl + 0** zoom the page, not the browser; Ctrl + 0 and a click on the percentage return to 100 %.
- **Fit page** fits the whole page, **Fit width** the width of the page into the work area.

### Theme

The sun / moon buttons in the toolbar or View > Theme switch between the light and the dark theme. The choice is saved for your user and is kept after you log off and on again. The paper stays white in the dark theme.

### Window size and menus

An application cannot prevent SAP GUI windows from being resized. Instead the designer keeps an area of at least 1120 × 620 pixels; in a smaller window the tools are not squeezed, scroll bars appear. The designer is most comfortable in full screen. With the GUI status `ZPDF_DESIGNER` the SAP menus Program / Edit / Goto are hidden; the System and Help menus belong to SAP GUI and stay on every screen.

## 5. Interface tab

The interface is the data a form receives, like the import parameters of an SFP interface. On the Layout tab objects are bound only to these fields.

### Adding a parameter

1. Enter the **Parameter name** (required).
2. Enter the **DDIC type** or choose it with **Search...**. Supported types: structure, table type, database table / view and data element.
3. Press **Add**. The type is read from SAP; its fields appear in **Context (field tree)** and in the Data View of the Layout tab.

Rules for the parameter name (all tested):

- It cannot be empty; the name of the DDIC type is never used as a default.
- At most 16 characters; starts with a letter, contains only A-Z, 0-9 and _.
- A parameter name cannot be used twice in a form.

Each row of the parameter table has the buttons **Rename** (the bindings of the objects are updated) and **Delete the parameter**. The Used column shows how many different fields of the parameter the design uses.

### DDIC type search

**Search...** searches by name, package or both.

- **Name (* wildcard)** and **Package (* wildcard):** without a wildcard they match from the start; `Z` or `Z*` lists all Z objects. Write `*TEXT*` for names that contain the text (slower). There is no minimum length.
- **Object type:** Structure, Database table, View, Table type, Data element. When none is ticked, all are searched.
- **Maximum rows:** limits the result (default 100). The dialog says when the limit is reached.
- The result list shows name, type, description and package; a click on a row puts the type into the DDIC type field. The parameter name you typed is kept.

### ABAP call

The tab shows ready ABAP code that prints this form from your own program, with the parameter names and types. **Copy to clipboard** copies it. The same code is under Tools > ABAP call code.

### Preview data (JSON)

The view option "show the preview data" and **Preview PDF** use this data; it is stored with the form.

- Dates are written `YYYYMMDD` (e.g. `20261121`), numbers with a decimal point (`1250.50`).
- **Apply** stores the edited JSON; invalid JSON gives an error message.
- **Generate again from the interface** puts a sample value into every field; tables get three rows.

## 6. Layout tab

On the Layout tab you place objects on the page, bind them to interface fields and set their properties. Every change can be undone (Ctrl+Z).

### Adding objects

Objects are added in three ways; all three were tested:

- **Insert menu** or a click on an object in the **Object Library:** the object is added at the top left of the visible part of the page and selected.
- **Double click on a field in the Data View:** adds a text object bound to that field.
- **Drag a table node from the Data View onto the page:** creates a bound table with its columns; amount fields get the format `#.##0,00`.

The Object Library holds 23 objects in four groups; the groups open and close (Barcodes starts closed):

| Group | Objects |
| --- | --- |
| Standard | Text, Data field, Paragraph, Table, Image / Logo, Check box |
| Special fields | Date field (`DD.MM.YYYY`), Amount field (`#.##0,00`, right aligned), Amount in words (`WORDS:TRY\|UPPER`), Page number (on every page), Watermark ("DRAFT", transparent, diagonal, on every page) |
| Shapes | Line, Vertical line, Rectangle, Ellipse |
| Barcodes | QR Code, DataMatrix, Code 128, Code 39, EAN-13, EAN-8, UPC-A, ITF-14 |

When a data field, date, amount, amount in words or table is added, the field picker opens by itself. The picker lists interface fields only.

### Moving and resizing

- Drag with the mouse to move; resize with the corner and edge handles. **Shift + corner handle** keeps the ratio.
- Arrow keys move by the grid step; with **Shift** 5 mm, with **Alt** 0.1 mm.
- With **Snap to grid** the object lands on the grid step; with **Snap to objects** it lands on the edge or centre of a nearby object and a guide line appears. **Alt + drag** moves without snapping to objects.
- Dragging on empty space selects with a frame; **Shift / Ctrl + click** adds to or removes from the selection.
- A double click on an unbound text edits the text in place.

### Properties (Object palette)

The properties of the selected object sit in collapsible groups; only the groups that fit the kind of object are shown. With several objects selected a change applies to all of them.

| Group | Fields |
| --- | --- |
| General | Name, Type, Locked (cannot be moved) |
| Content | Text (`{FIELD}` inserts a field into the text) |
| Barcode | Barcode type, Fixed value, Print human readable text, Error correction (QR) |
| Position and Size | X, Y, Width, Height (mm), Rotation, Opacity |
| Font | Font, Size, Colour, Bold, Italic, Underline |
| Paragraph | Horizontal alignment, Vertical alignment, Wrap lines, Padding |
| Background and Border | Background, Border colour, Border width |
| Fill and Border | Fill and border of shapes |
| Image | Fit |
| Header Row / Data Rows | Tables: print the header row, colours, font size, zebra row colour, line colour and width, cell padding |
| Print Rule (Master Page) | Where it is printed (below) |

### Data Binding tab

- **Data field (from the interface):** binds the object to an interface field; the picker offers interface fields only. A bound object shows as `{PARAMETER.FIELD}` on the page.
- **Format:** date, number and text format (section 13). Presets that fit the type of the field are offered.
- **Image:** a logo / image from the store or a field that holds the image.
- **Table:** Interface table and Columns (title, field, width, alignment, format of each column); **Generate the columns from the table** turns every row field into a column. Column widths can also be dragged on the page.
- **Condition:** *Print only when this field is filled* and *Invert: print when the field is empty*. Example: the "ACİL SİPARİŞ" (urgent order) badge of the demo order prints only when `IS_ORDER.URGENT` is filled.

### Tables break across pages

A table grows with the rows in the data. When it reaches the bottom margin it continues on a new page and the header row is repeated on every page. Objects placed below the table (totals, signatures) follow the end of the table; when they do not fit they move to the next page.

### Print rule (master page objects)

For objects printed at the same place on every page — logo, footer, page number — choose **Where it is printed**:

| Option | Meaning |
| --- | --- |
| Body (in the flow) | Default: the object prints once, where it was designed |
| Every page | All pages |
| First page only / All but the first page | E.g. a "(continued)" heading from page two on |
| Last page only / All but the last page | E.g. a grand total on the last page only |
| Odd pages / Even pages | For duplex printing |

Tables cannot be master page objects. Master page objects show a small **M** in their corner in the design.

### Design pages

A form can have several design pages (e.g. front and back). The **+** of the page navigator or Insert > New design page adds a page; **−** deletes it after a confirmation.

## 7. Alignment and arranging

The Layout menu has two different alignments: **Align objects** changes where the boxes sit on the page, **Align text** changes where the text sits inside its box. To move the text of a text or data field to the left or right, use **Align text**.

| Command | What it changes | Options | How it works |
| --- | --- | --- | --- |
| Align objects | Position of the box | Left, Centre horizontally, Right, Top, Centre vertically, Bottom | Several objects: aligned to the leftmost / rightmost / centre object. One object: aligned to the page margins |
| Align text | Position of the text in its box | Left, Centre, Right, Top, Middle, Bottom | Text and data fields only; the box does not move. The current alignment is ticked in the menu |
| Distribute | Gaps between objects | Horizontally, Vertically | At least 3 objects; the first and last stay, the gaps become equal |
| Same size | Width or height | Width, Height | At least 2 objects; all take the size of the first selected object |
| Centre on the page | Position of the box | Horizontally, Vertically | Exact centre of the paper (margins are ignored) |
| Bring to front / Bring forward / Send backward / Send to back | Drawing order | — | Which of overlapping objects prints on top |
| Lock / unlock | Lock | — | A locked object cannot be dragged, deleted or aligned; it shows a dashed frame |

Text alignment is applied the same way in the PDF; this was tested by reading the position of the text from a PDF printed in SAP. The same setting is in the Object palette under Properties > Paragraph > Horizontal / Vertical alignment.

Alignment and order commands work on the Layout tab only. Without a selection, or when a condition is not met (e.g. at least 3 objects to distribute), the menu item is disabled.

### Context menu

A right click on an object selects it and opens a short menu: Cut, Copy, Paste, Duplicate, Delete, Bring to front, Send to back, Lock / unlock, Align objects, Align text, Centre on the page.

## 8. Menu reference

All 103 items of the nine menus work; each was tested with a real click. In a form opened with Display the items that change the form are disabled; preview, versions, export and ABAP code stay available.

### File

| Item | Shortcut | What it does |
| --- | --- | --- |
| Save | Ctrl+S | Saves the form as a new version (section 9) |
| Preview PDF | Ctrl+P | Creates the PDF with the real ABAP engine from the preview data and opens it |
| Add to a transport request... | | Adds the form and the logos / fonts it uses to a transport request |
| Versions... | | Lists the saved versions; an older version can be restored |
| Export the design as JSON | | Shows the design as JSON text to copy |
| Import JSON... | | Replaces the current design with pasted JSON; Undo brings the old one back. Invalid text leaves the design unchanged |
| Reload the page from SAP | | Shows the page again with the current design |
| Exit | | Leaves the designer; asks first when there are unsaved changes |

### Edit

| Item | Shortcut | What it does |
| --- | --- | --- |
| Undo / Redo | Ctrl+Z / Ctrl+Y | Undoes / redoes the last change (up to 100 steps) |
| Cut / Copy | Ctrl+X / Ctrl+C | Puts the selected objects on the clipboard; Cut removes them from the page |
| Paste | Ctrl+V | Adds the clipboard 4 mm offset and selects it |
| Duplicate | Ctrl+D | Adds a copy of the selected objects |
| Delete | Del | Deletes the selected objects (except locked ones) |
| Select all | Ctrl+A | Selects all objects of the page |

These commands work on the Layout tab only; on the other tabs their shortcuts do nothing.

### View

| Item | What it does |
| --- | --- |
| Form Properties / Interface / Layout | Opens the tab |
| Zoom in / Zoom out / Actual size (100%) | Steps the page zoom up / down / to 100 % (+, −, Ctrl+0) |
| Fit page / Fit width | Fits the whole page / its width into the work area |
| Grid | Shows / hides the grid dots |
| Rulers | Shows / hides the rulers; the position of the selection is marked on them |
| Margins | Shows / hides the margin guide |
| Snap to grid / Snap to objects | Turns snapping to the grid / to nearby objects on or off |
| Show the preview data | Bound fields show the value of the preview data instead of `{FIELD}` |
| Theme > Light / Dark | Switches the theme; the choice is saved for your user |

### Insert

| Item | What it does |
| --- | --- |
| Standard / Special fields / Shapes / Barcodes | Adds the object of the submenu (23 objects, section 6) |
| Logo from the store | Lists the logos of the store; the chosen logo is added with its aspect ratio. With an empty store it shows "(no logo in the store)" |
| New design page | Adds an empty design page and goes to it |

### Table

| Item | What it does |
| --- | --- |
| Insert a table | Adds a table across the page width and opens the interface table picker |
| Add a column / Delete the last column | Adds a column to / deletes the last column of the selected table |
| Generate the columns from the interface table | Turns every row field of the bound table into a column |
| Make the columns equal width | Gives all columns the same width |
| Header row | Turns the header row on / off (design and PDF) |

The column commands are enabled while a table is selected.

### Layout

Align objects, Align text, Distribute, Same size, Centre on the page, the order commands and Lock / unlock: section 7.

### Tools

| Item | What it does |
| --- | --- |
| Upload logo / font... | Lets you choose a PNG, JPEG or TrueType (.ttf) file and stores it (section 10) |
| Asset store (logos, fonts)... | Lists the store with thumbnails; **Insert** adds a logo |
| Preview data... | Opens the Interface tab, where the preview data is edited |
| Warnings... | Lists problems that can affect printing (e.g. an unbound table, a barcode without a value) |
| ABAP call code... | Shows the code that prints the form from a program; Copy to clipboard |
| Generated form HTML... | Shows the form HTML used by the engine, read-only |
| Auto save | On / off; same as the box in the toolbar (section 9) |

### Palettes

| Item | What it does |
| --- | --- |
| Hierarchy / Data View / Object Library / Object | Shows / hides the palette |
| Show all palettes / Hide all palettes | Opens / closes all four palettes |
| Reset the workspace | Resets palettes, view options and zoom; the design does not change |

The arrow in a palette header collapses / expands it, × closes it.

### Help

Keyboard shortcuts, Quick start (a first form in six steps) and About ZPDF Studio (version).

## 9. Saving, versions, preview and transport

Every save creates a new version and the design stays on the screen. With auto save on, unsaved changes are also stored in SAP as a draft within seconds; they survive a lost session.

### Save

- **Save** in the toolbar, **Save** in the SAP toolbar, File > Save or **Ctrl+S**.
- While saving, the page is covered by "SAP is working..."; afterwards the message "FORM saved, version 0004" appears and the status becomes ✓ saved. Selection and undo history are kept.
- In a client with automatic recording SAP asks for a transport request; the message also names the request.
- With no changes, Save in the SAP toolbar says "There is nothing to save".

### Versions

File > Versions (or the Form Properties tab) lists the versions with the user and date; the active one is marked **active**. The last 20 versions are kept. **Return to this version** on an older version → confirm → that version becomes active; unsaved changes are lost.

### Auto save and drafts

- The **Auto save** box in the toolbar or Tools > Auto save; on by default.
- When on, each change is sent to SAP about one second later, and also when the mouse leaves the designer, and stored as a draft per form and user.
- The next time the form is opened you are asked about the draft (section 3). Save deletes the draft.

### Exit

Back / Exit / Cancel in SAP or File > Exit. With unsaved changes you are asked "Form FORM has unsaved changes. Save before leaving?": **Save** or **Don't save**.

### Preview PDF

- **Preview PDF** in the SAP toolbar, **Preview** in the designer, File > Preview PDF or **Ctrl+P**.
- The real ABAP engine creates the PDF from the current design (also when unsaved) and the preview data of the Interface tab. Margins and alignments are as in print.
- The PDF is written to the desktop folder as `FORM_preview.pdf` and opened; the designer stays usable.

### Transport

File > **Add to a transport request...**: with unsaved changes you are first asked "Save and continue". Then the SAP request dialog opens; the form and the logos / fonts it uses are added to the chosen request. If the client does not allow transports (SCC4), a message says what to change.

### Refresh page

**Refresh page** in the SAP toolbar shows the designer again with its last state. Use it when you see "SAP did not answer"; the design is not lost.

## 10. Logo and font store

Logos, images and TrueType fonts are kept in one store in SAP (`ZPDF_STUDIO_ASST`) and are transported with the forms. The store is managed in program `ZPDF_STUDIO_ASSETS` and in the designer.

### Supported files

- **Image / logo:** PNG (including transparent PNG) and JPEG.
- **Font:** TrueType (.ttf). OpenType CFF (.otf) and font collections (.ttc) are not supported; fonts whose licence does not allow embedding are refused.
- The file type is detected from the content, not from the file name; at most 10 MB.
- Name in the store: at most 30 characters, A-Z, 0-9 and _.

### Program ZPDF_STUDIO_ASSETS

| Action | Fields used | Result |
| --- | --- | --- |
| List and preview | IDs, Kind (All / Logos-images / Fonts) | List: ID, Kind, Font family, Bold, Italic, File type, File name, Description, Changed by, Changed at, Size |
| Upload from the PC | ID, File (F4 opens a file dialog), Description; for fonts Font family, Bold, Italic | The file is stored; an existing ID is overwritten |
| Download to the PC | ID | A save dialog opens and the file is downloaded |
| Delete | ID | The entry is deleted |
| Add to a transport request | ID and / or IDs | The selected entries are added to a transport request |

**Preview:** double-click a row of the list. Logos and images are shown on a checkerboard so that transparent parts are visible; fonts are shown with a sample text in the font itself, including Turkish letters. The top of the window shows name, file type, size and description.

All labels and list headings are Turkish with a TR logon and English otherwise.

### From the designer

- **Tools > Upload logo / font...:** choose a file; the dialog proposes the name from the file name (e.g. `zpdf_logo.png` → `ZPDF_LOGO`). For fonts family, bold and italic are guessed from the file name. **Upload** stores it; the design stays on the screen.
- **Tools > Asset store (logos, fonts)...:** lists the store with thumbnails (fonts with sample letters); **Insert** adds a logo.
- **Insert > Logo from the store:** adds a logo directly.

### Use in a form

- A logo is chosen from the store on the Data Binding tab of an Image / Logo object, or added in the ways above; the aspect ratio is kept.
- A font is used by writing its family into the **Font** property of an object. A family that is not in the store shows up under Warnings and Arial is used.
- A form added to a transport request takes the logos and fonts it uses with it.

## 11. Printing a form from ABAP

To print a form from your own program use `ZCL_PDF_STUDIO_API=>RENDER_FORM`: pass every interface parameter by its name with a data reference and get the PDF back as an `XSTRING`. Tools > ABAP call code or the Interface tab give you the ready code.

```abap
DATA ls_order  TYPE zpdf_s_demo_order.          " structure
DATA lt_items  TYPE zpdf_tt_demo_order_items.   " table type
DATA lv_note   TYPE zpdf_demo_note.             " data element
DATA lt_params TYPE zcl_pdf_studio_api=>ty_params.
DATA lv_pdf    TYPE xstring.

" ... fill the data ...

lt_params = VALUE #( ( name = `IS_ORDER` value = REF #( ls_order ) )
                     ( name = `IT_ITEMS` value = REF #( lt_items ) )
                     ( name = `IV_NOTE`  value = REF #( lv_note ) ) ).
TRY.
    lv_pdf = zcl_pdf_studio_api=>render_form(
      iv_form_id = 'ZPDF_DEMO_ORDER'
      it_params  = lt_params ).
    zcl_pdf_studio_api=>download_pdf(
      iv_pdf_xstring = lv_pdf
      iv_filename    = `ZPDF_DEMO_ORDER.pdf`
      iv_open        = abap_true
      iv_dialog      = abap_false ).
  CATCH zcx_pdf_studio INTO DATA(lx_pdf).
    MESSAGE lx_pdf->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
ENDTRY.
```

| Method | When |
| --- | --- |
| `RENDER_FORM` | Forms with an interface: one or more parameters (structure, table type, data element). Parameters you do not pass print empty |
| `RENDER_PDF` | Forms whose data is one structure (e.g. `ZPDF_STUDIO_INVOICE`); with a one-parameter interface the value of that parameter can be passed directly |
| `DOWNLOAD_PDF` | Writes the PDF to the PC. `iv_dialog = abap_true`: save dialog; `abap_false`: desktop folder. `iv_open = abap_true`: opens the file |

- A form always prints with its **active version**; paper size and margins come from the form.
- `IV_LANG` (default: logon language) sets month and day names, amounts in words and upper-case rules.
- Errors raise `ZCX_PDF_STUDIO`; its text is Turkish for a TR logon and English otherwise (e.g. "Form ZPDF_DEMO_ORDER does not exist").
- The `PRINT_*` methods of program `ZPDF_STUDIO_DEMO` are working sample code for every demo (section 12).

## 12. Demo forms

`ZPDF_STUDIO_DEMO` works like SAP's DEMO* programs: choose one of six ready forms and open its PDF, save it, or inspect the form in the designer. All six forms were tested by printing them in SAP.

### Screen

- **Demo form:** six radio buttons (table below).
- **Action:** Create the PDF and open it · Create the PDF and save it as (choose a folder) · Open the form in the designer (`ZPDF_STUDIO`).
- **Demo data:** number of items (invoice, order, delivery, payment; 1-500) and a DRAFT watermark on the invoice.
- **Install / update demo forms:** installs five forms and five images from `designer/dist/zpdf-demo-pack.txt`. When a form that is not installed yet is chosen, the program offers to install it. The invoice form is created automatically on the first run.

### Forms

The demo content (names, addresses, texts) is Turkish sample data.

| Form | Paper | What it shows | Interface |
| --- | --- | --- | --- |
| `ZPDF_STUDIO_INVOICE` Invoice | A4 portrait | Item table across pages, amount in words, conditional DRAFT watermark, DataMatrix, EAN-13, QR, page numbers | One structure (`RENDER_PDF`) |
| `ZPDF_DEMO_ORDER` Purchase order | A4 portrait | Logo, colour header block, info cards, conditional "urgent" badge, totals, QR, a "(continued)" heading on page two | `IS_ORDER` structure, `IT_ITEMS` table type, `IV_NOTE` data element |
| `ZPDF_DEMO_CERT` Certificate | A4 landscape | Double frame, side heading rotated by 90°, seal and signature images, conditional 45° honours ribbon, verification QR | `IS_CERT` structure |
| `ZPDF_DEMO_TICKET` Event ticket | A5 landscape | Text over a poster photo (JPEG), colour blocks, perforated stub, time formats, QR and Code 128 | `IS_TICKET` structure |
| `ZPDF_DEMO_DELIVERY` Delivery note | A4 portrait | Side band and footer on every page, address cards, long item table, Code 128, ITF-14, DataMatrix | `IS_DELIVERY` structure, `IT_ITEMS` table type |
| `ZPDF_DEMO_PAYMENT` Payment order | A4 portrait | A table inside the structure (`INPUT.ITEMS`), check boxes, amount in words, signature and stamp images | `INPUT` (one structure that holds a table) |

### DDIC demo objects

The demo interfaces use real DDIC objects of the package:

- **Data elements:** `ZPDF_DEMO_DOCNO`, `ZPDF_DEMO_NAME`, `ZPDF_DEMO_TEXT`, `ZPDF_DEMO_NOTE`, `ZPDF_DEMO_AMOUNT`, `ZPDF_DEMO_QTY`.
- **Structures:** `ZPDF_S_DEMO_ORDER`, `ZPDF_S_DEMO_ORDER_ITEM`, `ZPDF_S_DEMO_CERT`, `ZPDF_S_DEMO_TICKET`, `ZPDF_S_DEMO_DELIVERY`, `ZPDF_S_DEMO_DELIV_ITEM`, `ZPDF_S_DEMO_PAYMENT`, `ZPDF_S_DEMO_PAY_ITEM`.
- **Table types:** `ZPDF_TT_DEMO_ORDER_ITEMS`, `ZPDF_TT_DEMO_DELIV_ITEMS`, `ZPDF_TT_DEMO_PAY_ITEMS`.
- **Demo data:** `ZCL_PDF_STUDIO_DEMOS` (`ORDER`, `CERTIFICATE`, `TICKET`, `DELIVERY`, `PAYMENT`).
- **Images:** `ZPDF_DEMO_LOGO`, `ZPDF_DEMO_SEAL`, `ZPDF_DEMO_SIGN`, `ZPDF_DEMO_STAMP` (transparent PNG), `ZPDF_DEMO_BANNER` (JPEG).

Once installed, the demo forms are ordinary forms: they can be changed in the designer, versioned and transported. Running **Install / update demo forms** again saves the forms of the pack as a new version; earlier versions can be restored under Versions.

## 13. Format patterns and keyboard shortcuts

A format is written into Data Binding > **Format** of a bound field, or inside a text as `{FIELD | pattern}`. Patterns are chained with `|`: `WORDS:TRY|UPPER`. An empty format uses the user's SAP settings.

| Pattern | Example output (Turkish print) |
| --- | --- |
| `DD.MM.YYYY` | 21.11.2026 |
| `D MMMM YYYY` | 21 Kasım 2026 (21 November 2026 in English) |
| `D MMMM YYYY, dddd` | 19 Aralık 2026, Cumartesi |
| `DD/MM/YYYY` · `YYYY-MM-DD` · `MMMM YYYY` | 21/11/2026 · 2026-11-21 · Kasım 2026 |
| `HH:mm` · `HH:mm:ss` | 19:00 · 19:00:00 |
| `#.##0,00` | 22.380,00 |
| `#,##0.00` | 22,380.00 |
| `#.##0` | 240 |
| `#.##0,00;(#.##0,00)` | Negatives in brackets: (1.250,00) |
| `SAP` / `SAP:EUR` | The user's SAP number / date setting; with the decimals of the currency |
| `WORDS:TRY` | Amount in words: "... Türk lirası ... kuruş" (USD and EUR as well) |
| `UPPER` · `LOWER` · `TITLE` | Upper, lower, first letter upper; follows the Turkish i / İ and ı / I rules |
| `ALPHA` · `TRIM` | Removes leading zeros · trims blanks |

Month and day names and amounts in words follow the language of the print: Turkish, German or English. The texts `{currentPage}` and `{totalPages}` print the page number and the number of pages.

### Keyboard shortcuts

| Shortcut | Function |
| --- | --- |
| Ctrl+S / Ctrl+P | Save / Preview PDF |
| Ctrl+Z / Ctrl+Y (or Ctrl+Shift+Z) | Undo / Redo |
| Ctrl+C / Ctrl+X / Ctrl+V | Copy / Cut / Paste |
| Ctrl+D | Duplicate |
| Del | Delete |
| Ctrl+A | Select all |
| Arrow keys | Move by the grid step (Shift: 5 mm, Alt: 0.1 mm) |
| + / − / Ctrl+0 | Zoom in / Zoom out / 100 % |
| Alt + mouse wheel | Zoom the page in / out |
| Shift / Ctrl + click | Add to / remove from the selection |
| Drag on empty space | Select with a frame |
| Double click | Edit the text in place; in the Data View, insert the field |
| Shift + corner handle | Resize keeping the ratio |
| Alt + drag | Move without snapping to objects |
| Esc | Close a menu or dialog, clear the selection |

Editing shortcuts work on the Layout tab while you are not typing in an input field. Ctrl+S, Ctrl+P and Ctrl+0 work everywhere.

## 14. Troubleshooting

Most messages say what to do. The cases below were met during use.

| Symptom | Cause | Solution |
| --- | --- | --- |
| "The designer page is not installed or is an old version" | The page is missing from the MIME repository or outdated | Pull the repository again, or `ZPDF_STUDIO` → Install / update designer → `designer/dist/designer.html` |
| "This file is not a ZPDF Studio 2 designer page" | Wrong file chosen | Choose `designer/dist/designer.html` |
| The status bar does not show 2.2.0 | An older designer page is installed | Upload it with Install / update designer (section 2, step 3) |
| "SAP did not answer" | A request got no answer within 30 seconds | SAP toolbar → **Refresh page**; the design is not lost |
| "SAP GUI did not pass the page data" | Unsupported GUI or browser control | Use SAP GUI for Windows with the Edge (WebView2) browser control |
| The menus Program / Edit / Goto are shown | GUI status `ZPDF_DESIGNER` is missing or not active | Activate program `ZPDF_STUDIO` with its GUI status (it comes with the repository) |
| The form opened read-only | Opened with Display, or another user has it open | Open it with Change; if it is locked, wait for the other user |
| "FORM was not made with the ZPDF Studio designer" | The name belongs to a form made with another tool | Use a new form name |
| Warnings shows a number | An unbound table, a barcode without a value, a font that is not in the store, ... | Fix the objects listed under Tools > Warnings |
| A font prints as Arial | The family is not in the store | Upload the font, or write the family name of the store into Font |
| The transport message mentions SCC4 or the delivery class | The client does not allow transports, or a table setting is missing | Follow the message (SCC4 setting, or delivery class C in SE11) |
| "Missing authorization: S_PROGRAM ZPDFSEDT / SUBMIT" | The user lacks the ZPDF Studio authorization | Grant `S_PROGRAM` with `P_GROUP` `ZPDFSEDT` (and `ZPDFSADM` for deleting) |
| Demo: "Form FORM is not installed yet" | The demo pack is not installed | Answer Yes and choose `designer/dist/zpdf-demo-pack.txt` |
| Dump `LOAD_PROGRAM_CLASS_MISMATCH` right after an update | Classes changed while the program was running | Restart the program with `/n`; it is not a code error |

## Appendix: test and verification summary

Every feature in this guide was checked by at least one of the tests below; all passed as of 21 November 2026. No feature that failed a test was included.

| Test | Scope | Result |
| --- | --- | --- |
| Menu test (`designer/test/menus.mjs`) | 103 menu items with real clicks; context menu; requests sent to SAP; TR / EN language; display mode | 177 / 177 |
| Browser test (`designer/test/smoke.mjs`) | Interface, drag and drop, binding, zoom, theme, small window, design kept after save | 69 / 69 |
| Conversion test (`designer/test/convert.test.mjs`) | Conversion of the design into engine HTML | 13 / 13 |
| ABAP Unit, ZPDF Studio package | Engine, formats, barcodes, JSON, position of aligned text in the PDF, Turkish error messages, demo data, real print of the five demo forms | 59 / 59 |
| Manual tests in SAP GUI | Save, transport, PDF preview and margins, exit question, theme kept across sessions, TR / EN texts, logo preview, designer without SAP menus, six demo forms | Confirmed |

The line-by-line result of the menu test is in [`test-report/menus-report.json`](test-report/menus-report.json).
