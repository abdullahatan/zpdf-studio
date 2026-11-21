"! <p class="shorttext synchronized">ZPDF Studio - messages in the logon language</p>
"! The lower layers (form store, assets, transport, binder, renderer, fonts, barcodes) raise
"! their errors with an English text. This class is the catalog that shows them in Turkish for a
"! Turkish logon; every other logon language gets the English text. The English text is the key:
"! variable parts are written as &1 ... &9 in the catalog.
CLASS zcl_pdf_studio_text DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Message in the logon language: Turkish for a Turkish logon, otherwise unchanged (English).
    CLASS-METHODS localize
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rv_text) TYPE string.

    "! Turkish text of an English message; the message itself when the catalog does not know it.
    CLASS-METHODS turkish
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rv_text) TYPE string.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_entry,
        en TYPE string,
        tr TYPE string,
      END OF ty_entry.
    TYPES ty_entries TYPE STANDARD TABLE OF ty_entry WITH EMPTY KEY.

    CLASS-DATA gt_catalog TYPE ty_entries.

    CLASS-METHODS catalog
      RETURNING VALUE(rt_catalog) TYPE ty_entries.

    "Does iv_text have the form of iv_pattern? et_values: the texts at &1, &2 ...
    CLASS-METHODS match
      IMPORTING iv_pattern TYPE string
                iv_text    TYPE string
      EXPORTING ev_match   TYPE abap_bool
                et_values  TYPE string_table.
ENDCLASS.



CLASS zcl_pdf_studio_text IMPLEMENTATION.

  METHOD localize.
    rv_text = iv_text.
    IF sy-langu <> 'T'.
      RETURN.
    ENDIF.
    TRY.
        rv_text = turkish( iv_text ).
      CATCH cx_root.
        "A message must never fail because of its translation.
        rv_text = iv_text.
    ENDTRY.
  ENDMETHOD.


  METHOD turkish.
    DATA lt_values TYPE string_table.
    DATA lv_match TYPE abap_bool.
    DATA lv_value TYPE string.
    DATA lv_hole TYPE string.
    FIELD-SYMBOLS <ls_entry> TYPE ty_entry.

    rv_text = iv_text.
    IF iv_text IS INITIAL.
      RETURN.
    ENDIF.
    IF gt_catalog IS INITIAL.
      gt_catalog = catalog( ).
    ENDIF.
    LOOP AT gt_catalog ASSIGNING <ls_entry>.
      match(
        EXPORTING
          iv_pattern = <ls_entry>-en
          iv_text    = iv_text
        IMPORTING
          ev_match   = lv_match
          et_values  = lt_values ).
      IF lv_match = abap_false.
        CONTINUE.
      ENDIF.
      rv_text = <ls_entry>-tr.
      LOOP AT lt_values INTO lv_value.
        lv_hole = |&{ sy-tabix }|.
        REPLACE ALL OCCURRENCES OF lv_hole IN rv_text WITH lv_value.
      ENDLOOP.
      RETURN.
    ENDLOOP.
  ENDMETHOD.


  METHOD match.
    DATA lv_pattern TYPE string.
    DATA lv_hole TYPE string.
    DATA lt_parts TYPE string_table.
    DATA lv_part TYPE string.
    DATA lv_rest TYPE string.
    DATA lv_value TYPE string.
    DATA lv_holes TYPE i.
    DATA lv_last TYPE i.
    DATA lv_off TYPE i.
    DATA lv_len TYPE i.
    DATA lv_index TYPE i.

    ev_match = abap_false.
    CLEAR et_values.

    "The holes &1 ... &9 become one separator; the texts between them must occur in this order.
    lv_pattern = iv_pattern.
    DO 9 TIMES.
      lv_hole = |&{ sy-index }|.
      REPLACE ALL OCCURRENCES OF lv_hole IN lv_pattern WITH cl_abap_char_utilities=>horizontal_tab.
    ENDDO.
    lv_holes = count( val = lv_pattern sub = cl_abap_char_utilities=>horizontal_tab ).
    SPLIT lv_pattern AT cl_abap_char_utilities=>horizontal_tab INTO TABLE lt_parts.
    WHILE lines( lt_parts ) < lv_holes + 1.
      APPEND `` TO lt_parts.
    ENDWHILE.
    lv_last = lines( lt_parts ).

    lv_rest = iv_text.
    LOOP AT lt_parts INTO lv_part.
      lv_index = sy-tabix.
      lv_len = strlen( lv_part ).
      IF lv_index = 1.
        "The text starts with the first part.
        IF strlen( lv_rest ) < lv_len.
          RETURN.
        ENDIF.
        IF lv_len > 0.
          IF lv_rest(lv_len) <> lv_part.
            RETURN.
          ENDIF.
          IF strlen( lv_rest ) = lv_len.
            CLEAR lv_rest.
          ELSE.
            lv_rest = lv_rest+lv_len.
          ENDIF.
        ENDIF.
        IF lv_last = 1 AND lv_rest IS NOT INITIAL.
          RETURN.
        ENDIF.
      ELSEIF lv_index = lv_last.
        "The text ends with the last part; what is before it is the last value.
        lv_off = strlen( lv_rest ) - lv_len.
        IF lv_off < 0.
          RETURN.
        ENDIF.
        IF lv_len > 0.
          IF lv_rest+lv_off(lv_len) <> lv_part.
            RETURN.
          ENDIF.
        ENDIF.
        IF lv_off > 0.
          lv_value = lv_rest(lv_off).
        ELSE.
          CLEAR lv_value.
        ENDIF.
        APPEND lv_value TO et_values.
      ELSE.
        IF lv_len = 0.
          RETURN.
        ENDIF.
        lv_off = find( val = lv_rest sub = lv_part ).
        IF lv_off < 0.
          RETURN.
        ENDIF.
        IF lv_off > 0.
          lv_value = lv_rest(lv_off).
        ELSE.
          CLEAR lv_value.
        ENDIF.
        APPEND lv_value TO et_values.
        lv_off = lv_off + lv_len.
        IF strlen( lv_rest ) = lv_off.
          CLEAR lv_rest.
        ELSE.
          lv_rest = lv_rest+lv_off.
        ENDIF.
      ENDIF.
    ENDLOOP.
    ev_match = abap_true.
  ENDMETHOD.


  METHOD catalog.
    rt_catalog = VALUE #(
      "Form store
      ( en = `Form &1 already exists`
        tr = `&1 formu zaten var` )
      ( en = `Form &1 does not exist`
        tr = `&1 formu yok` )
      ( en = `Form &1 has no template`
        tr = `&1 formunun kayıtlı bir tasarımı yok` )
      ( en = `Form &1 has no version &2`
        tr = `&1 formunun &2 sürümü yok` )
      ( en = `Form ID must contain only A-Z, 0-9, and underscore`
        tr = `Form adı yalnızca A-Z, 0-9 ve alt çizgi (_) içerebilir` )
      ( en = `Form ID is empty`
        tr = `Form adı boş` )
      ( en = `DDIC type &1 does not exist`
        tr = `&1 adında bir DDIC tipi yok` )
      ( en = `&1 is not a structure or table type`
        tr = `&1 bir yapı veya tablo tipi değil` )
      ( en = `Template exceeds 2 million characters`
        tr = `Form tasarımı 2 milyon karakteri aşıyor` )
      ( en = `Commit or discard pending changes before reload`
        tr = `Yeniden yüklemeden önce bekleyen değişiklikleri kaydedin veya geri alın` )
      ( en = `Client does not allow changes`
        tr = `Bu üst birimde (client) değişikliğe izin verilmiyor` )
      ( en = `Cannot read template store; no data was overwritten`
        tr = `Form deposu okunamadı; hiçbir verinin üzerine yazılmadı` )
      ( en = `Template store is busy. Your draft is retained; retry Save.`
        tr = `Form deposu şu anda meşgul. Taslağınız korunuyor; yeniden kaydetmeyi deneyin.` )
      ( en = `Another session changed the store. Copy your draft, reopen the form, and reapply your changes.`
        tr = `Depo başka bir oturumda değiştirildi. Taslağınızı kopyalayın, formu yeniden açın ve ` &&
             `değişikliklerinizi yeniden uygulayın.` )
      ( en = `Could not persist templates`
        tr = `Form tasarımları kaydedilemedi` )
      ( en = `Commit reported an update failure; verify the saved store before retrying`
        tr = `Kayıt sırasında güncelleme hatası bildirildi; yeniden denemeden önce kaydedilen veriyi kontrol edin` )
      ( en = `Cannot store form &1: &2`
        tr = `&1 formu saklanamadı: &2` )
      ( en = `A row of &1 cannot be read: &2`
        tr = `&1 tablosunun bir satırı okunamadı: &2` )
      ( en = `Form &1 could not be written to &2`
        tr = `&1 formu &2 tablosuna yazılamadı` )
      ( en = `Forms cannot be changed in this client (SCC4: no changes allowed). ` &&
             `Change them in the development system and transport them.`
        tr = `Bu üst birimde formlar değiştirilemez (SCC4: değişikliğe izin verilmiyor). ` &&
             `Formları geliştirme sisteminde değiştirip taşıyın.` )
      ( en = `Form &1 is being saved by another user. Your draft is retained; retry Save.`
        tr = `&1 formu şu anda başka bir kullanıcı tarafından kaydediliyor. Taslağınız korunuyor; ` &&
             `yeniden kaydetmeyi deneyin.` )
      ( en = `Form &1 was changed in another session or by a transport. ` &&
             `Copy your draft, reopen the form, and reapply your changes.`
        tr = `&1 formu başka bir oturumda veya bir transportla değiştirildi. Taslağınızı kopyalayın, ` &&
             `formu yeniden açın ve değişikliklerinizi yeniden uygulayın.` )
      ( en = `Could not save the form store setup marker`
        tr = `Form deposunun kurulum işareti kaydedilemedi` )
      ( en = `Missing authorization: S_PROGRAM &1 / SUBMIT`
        tr = `Yetki eksik: S_PROGRAM &1 / SUBMIT` )
      "Page
      ( en = `Unsupported page size`
        tr = `Desteklenmeyen sayfa boyutu` )
      ( en = `Orientation must be P or L`
        tr = `Yön P (dikey) veya L (yatay) olmalıdır` )
      ( en = `Margins must be between 0 and 500 mm`
        tr = `Kenar boşlukları 0 ile 500 mm arasında olmalıdır` )
      ( en = `Margins leave no printable page area`
        tr = `Kenar boşlukları yazdırılabilir alan bırakmıyor` )
      "Transport
      ( en = `Set the delivery class of &1 to C (customizing) in SE11 to transport forms.`
        tr = `Formları taşıyabilmek için SE11'de &1 tablosunun teslimat sınıfını C (uyarlama) yapın.` )
      ( en = `This client does not allow transports (SCC4: changes without automatic recording, no transports allowed). ` &&
             `In SCC4 set client &1 to "Automatic recording of changes" or "Changes without automatic recording", then try again.`
        tr = `Bu üst birim transporta izin vermiyor (SCC4: otomatik kayıt olmadan değişiklik, transporta izin yok). ` &&
             `SCC4'te &1 üst birimini "Değişikliklerin otomatik kaydı" veya "Otomatik kayıt olmadan değişiklik" ` &&
             `olarak ayarlayıp yeniden deneyin.` )
      ( en = `Client &1 does not allow transports (SCC4). ` &&
             `Set "Automatic recording of changes" or "Changes without automatic recording" and try again.`
        tr = `&1 üst birimi transporta izin vermiyor (SCC4). "Değişikliklerin otomatik kaydı" veya ` &&
             `"Otomatik kayıt olmadan değişiklik" seçeneğini ayarlayıp yeniden deneyin.` )
      ( en = `Transport request could not be chosen: &1`
        tr = `Transport talebi seçilemedi: &1` )
      ( en = `No transport request was chosen; nothing was saved or recorded.`
        tr = `Transport talebi seçilmedi; hiçbir şey kaydedilmedi ve talebe eklenmedi.` )
      ( en = `No transport request was chosen.`
        tr = `Transport talebi seçilmedi.` )
      ( en = `Form could not be added to request &1: &2 (message &3 &4)`
        tr = `Form &1 talebine eklenemedi: &2 (ileti &3 &4)` )
      ( en = `Form could not be added to request &1: &2`
        tr = `Form &1 talebine eklenemedi: &2` )
      ( en = `Entries could not be added to request &1: &2`
        tr = `Kayıtlar &1 talebine eklenemedi: &2` )
      ( en = `Forms are kept in INDX, which cannot be transported. ` &&
             `Create table &1 (see the program header) and start the designer again.`
        tr = `Formlar INDX'te tutuluyor ve bu şekilde taşınamaz. &1 tablosunu oluşturun ` &&
             `(program başlığına bakın) ve tasarımcıyı yeniden başlatın.` )
      ( en = `Save the form before adding it to a transport request.`
        tr = `Formu transport talebine eklemeden önce kaydedin.` )
      "Logos and fonts
      ( en = `Asset ID "&1" is invalid: use A-Z, 0-9 and _ (max. 30 characters)`
        tr = `"&1" adı geçersiz: A-Z, 0-9 ve _ kullanın (en fazla 30 karakter)` )
      ( en = `Client &1 does not allow changes (SCC4)`
        tr = `&1 üst biriminde değişikliğe izin verilmiyor (SCC4)` )
      ( en = `File is empty or larger than 10 MB`
        tr = `Dosya boş veya 10 MB'den büyük` )
      ( en = `Unsupported file: use PNG or JPEG for images and TrueType (.ttf) for fonts`
        tr = `Desteklenmeyen dosya: resimler için PNG veya JPEG, fontlar için TrueType (.ttf) kullanın` )
      ( en = `Asset &1 could not be saved`
        tr = `&1 kaydedilemedi` )
      ( en = `Asset &1 does not exist`
        tr = `&1 adında bir logo veya font yok` )
      ( en = `No asset selected`
        tr = `Logo veya font seçilmedi` )
      ( en = `Enter an asset ID and choose a file`
        tr = `Bir ad girin ve bir dosya seçin` )
      ( en = `File &1 could not be read`
        tr = `&1 dosyası okunamadı` )
      ( en = `File &1 could not be written`
        tr = `&1 dosyası yazılamadı` )
      ( en = `Font file is empty or too short`
        tr = `Font dosyası boş veya çok kısa` )
      ( en = `OpenType fonts with CFF outlines (.otf) are not supported; use the TrueType (.ttf) file`
        tr = `CFF dış hatlı OpenType fontlar (.otf) desteklenmez; TrueType (.ttf) dosyasını kullanın` )
      ( en = `Font collections (.ttc) are not supported; use a single .ttf file`
        tr = `Font koleksiyonları (.ttc) desteklenmez; tek bir .ttf dosyası kullanın` )
      ( en = `File is not a TrueType font`
        tr = `Dosya bir TrueType font değil` )
      ( en = `TrueType font is missing a required table`
        tr = `TrueType fontta zorunlu bir tablo eksik` )
      ( en = `Font has no TrueType outlines (glyf); use a .ttf file`
        tr = `Fontta TrueType dış hatları (glyf) yok; bir .ttf dosyası kullanın` )
      ( en = `The license of this font does not allow embedding it in documents (OS/2 fsType)`
        tr = `Bu fontun lisansı belgelere gömülmesine izin vermiyor (OS/2 fsType)` )
      ( en = `Font has no Unicode character map`
        tr = `Fontta Unicode karakter eşlemesi yok` )
      "Printing a form
      ( en = `Form &1: no parameters were passed`
        tr = `&1 formu: hiçbir parametre aktarılmadı` )
      ( en = `Form &1: parameters are not valid (&2)`
        tr = `&1 formu: parametreler geçersiz (&2)` )
      ( en = `PDF and at least one recipient are needed`
        tr = `PDF ve en az bir alıcı gerekli` )
      ( en = `E-mail could not be sent: &1`
        tr = `E-posta gönderilemedi: &1` )
      ( en = `PDF payload is empty`
        tr = `PDF içeriği boş` )
      ( en = `Save dialog failed`
        tr = `Kaydetme penceresi açılamadı` )
      ( en = `Could not write &1`
        tr = `&1 dosyası yazılamadı` )
      ( en = `Unclosed {{{ in template`
        tr = `Form tasarımında kapatılmamış {{{ var` )
      ( en = `Unclosed {{ in template`
        tr = `Form tasarımında kapatılmamış {{ var` )
      ( en = `Unexpected template tag at offset &1: &2`
        tr = `&1 konumunda beklenmeyen şablon etiketi: &2` )
      ( en = `Unclosed block /&1`
        tr = `Kapatılmamış blok: /&1` )
      ( en = `Template nesting exceeds 50 levels`
        tr = `Şablonda iç içe blok sayısı 50 düzeyi aşıyor` )
      ( en = `Expected /&1 but found /&2`
        tr = `/&1 bekleniyordu, /&2 bulundu` )
      ( en = `Duplicate else in template block`
        tr = `Şablon bloğunda birden fazla else var` )
      ( en = `Unknown template field in &1: &2`
        tr = `&1 işlevinde bilinmeyen alan: &2 (arayüzde böyle bir alan yok)` )
      ( en = `Unknown template field: &1`
        tr = `Bilinmeyen alan: &1 (arayüzde böyle bir alan yok)` )
      ( en = `JSON serialization failed: &1`
        tr = `JSON oluşturulamadı: &1` )
      ( en = `Invalid JSON at position &1: &2`
        tr = `&1 konumunda geçersiz JSON: &2` )
      ( en = `Rendered HTML/CSS exceeds 2 million characters`
        tr = `Oluşturulan HTML/CSS 2 milyon karakteri aşıyor` )
      "Barcodes
      ( en = `QR code text is too long (&1 bytes)`
        tr = `QR kod metni çok uzun (&1 bayt)` )
      ( en = `&1: only digits are allowed ("&2")`
        tr = `&1: yalnızca rakam kullanılabilir ("&2")` )
      ( en = `&1: wrong check digit in &2`
        tr = `&1: &2 değerinde kontrol basamağı yanlış` )
      ( en = `&1: &2 or &3 digits are needed ("&4")`
        tr = `&1: &2 veya &3 basamak gerekli ("&4")` )
      ( en = `Unknown barcode type &1`
        tr = `Bilinmeyen barkod tipi: &1` )
      ( en = `Code 39 cannot encode "&1" (allowed: 0-9 A-Z - . space $ / + %)`
        tr = `Code 39, "&1" karakterini kodlayamaz (izin verilenler: 0-9 A-Z - . boşluk $ / + %)` )
      ( en = `DataMatrix: no data`
        tr = `DataMatrix: veri yok` )
      ( en = `DataMatrix: too much data (max. 1304 codewords)`
        tr = `DataMatrix: veri çok fazla (en fazla 1304 kod sözcüğü)` )
      "Gotenberg engine and configuration
      ( en = `Only the configured destination &1 is allowed`
        tr = `Yalnızca yapılandırılmış &1 hedefine izin verilir` )
      ( en = `Timeout must be between 1 and 300 seconds`
        tr = `Zaman aşımı 1 ile 300 saniye arasında olmalıdır` )
      ( en = `Invalid HTTP timeout`
        tr = `HTTP zaman aşımı geçersiz` )
      ( en = `Only the CLASSIC HTTP stack is supported`
        tr = `Yalnızca CLASSIC HTTP yığını desteklenir` )
      ( en = `PDF engine must be NATIVE or GOTENBERG`
        tr = `PDF motoru NATIVE veya GOTENBERG olmalıdır` )
      ( en = `Unknown config parameter &1`
        tr = `Bilinmeyen yapılandırma parametresi: &1` )
      ( en = `Gotenberg returned an empty PDF`
        tr = `Gotenberg boş bir PDF döndürdü` )
      ( en = `Response is not a PDF (%PDF- signature missing)`
        tr = `Yanıt bir PDF değil (%PDF- imzası yok)` )
      ( en = `PDF exceeds the 50 MB application limit`
        tr = `PDF, 50 MB'lik uygulama sınırını aşıyor` )
      ( en = `Unapproved rendering endpoint`
        tr = `Onaylanmamış PDF oluşturma adresi` )
      ( en = `Configure SM59 destination &1 before rendering`
        tr = `PDF oluşturmadan önce SM59'da &1 hedefini tanımlayın` )
      ( en = `HTTP send to Gotenberg failed (&1)`
        tr = `Gotenberg'e HTTP isteği gönderilemedi (&1)` )
      ( en = `HTTP receive from Gotenberg failed (&1)`
        tr = `Gotenberg'den HTTP yanıtı alınamadı (&1)` )
      ( en = `Expected application/pdf, received &1`
        tr = `application/pdf bekleniyordu, &1 alındı` ) ).
  ENDMETHOD.

ENDCLASS.
