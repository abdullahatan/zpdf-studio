# ZPDF Studio Kullanım Kılavuzu

ZPDF Studio 2.2.0 · [English](USER_GUIDE_EN.md)

## İçindekiler

1. [Giriş](#1-giriş)
2. [Kurulum](#2-kurulum)
3. [Form açma](#3-form-açma)
4. [Tasarımcı ekranı](#4-tasarımcı-ekranı)
5. [Arayüz sekmesi](#5-arayüz-sekmesi)
6. [Düzen sekmesi](#6-düzen-sekmesi)
7. [Hizalama ve düzenleme](#7-hizalama-ve-düzenleme)
8. [Menü başvurusu](#8-menü-başvurusu)
9. [Kaydetme, sürümler, önizleme ve transport](#9-kaydetme-sürümler-önizleme-ve-transport)
10. [Logo ve font deposu](#10-logo-ve-font-deposu)
11. [Formu ABAP programından yazdırma](#11-formu-abap-programından-yazdırma)
12. [Demo formlar](#12-demo-formlar)
13. [Biçim kalıpları ve klavye kısayolları](#13-biçim-kalıpları-ve-klavye-kısayolları)
14. [Sorun giderme](#14-sorun-giderme)
15. [Ek: Test ve doğrulama özeti](#ek-test-ve-doğrulama-özeti)

## 1. Giriş

ZPDF Studio, PDF formlarını SAP GUI içinde tasarlayıp tamamen ABAP ile PDF'e basan bir araçtır; Adobe Document Services, Smart Forms veya dış bir servis gerekmez. Bu kılavuz tasarımcının **2.2.0** sürümünü anlatır ve yalnızca test edilip doğrulanmış özellikleri içerir.

### Bileşenler

| Nesne | Türü | Görevi |
| --- | --- | --- |
| `ZPDF_STUDIO` | Program | Form açma ekranı ve tasarımcı |
| `ZPDF_STUDIO_ASSETS` | Program | Logo, resim ve font deposu |
| `ZPDF_STUDIO_DEMO` | Program | Altı demo form; formun programdan nasıl basılacağını gösteren örnek kod |
| `ZCL_PDF_STUDIO_API` | Sınıf | Kendi programlarınızdan form basmak için kullanılan arayüz |
| `ZPDF_STUDIO_FORM` | Tablo | Formlar ve sürümleri (transport edilebilir) |
| `ZPDF_STUDIO_ASST` | Tablo | Logolar, resimler, fontlar (transport edilebilir) |
| `ZPDF_STUDIO_DRFT` | Tablo | Kaydedilmemiş taslaklar (otomatik kaydet) |
| `ZPDF_STUDIO_USER` | Tablo | Kullanıcı ayarları (tema) |
| `/SAP/PUBLIC/ZPDF_STUDIO/designer.html` | MIME nesnesi | Tasarımcı sayfası |

### Dil

SAP'ye Türkçe (TR) oturum açtığınızda tasarımcı, programlar ve hata mesajları Türkçe gelir. Diğer tüm oturum dillerinde (EN, DE, FR, RU ...) İngilizce gelir. Dil kullanıcı tarafından değiştirilmez; oturum dilini izler.

### Bu kılavuzdaki "doğrulandı" ne demek

Her özellik iki yoldan sınandı:

- **Otomatik testler:** tasarımcının 103 menü öğesinin her biri gerçek fare tıklamasıyla sınandı (177 kontrol); ayrıca 69 tarayıcı kontrolü, 13 dönüştürme testi ve SAP'de 59 ABAP Unit testi çalıştırıldı. Hepsi geçti.
- **SAP GUI'de elle deneme:** kaydetme, transport, PDF önizleme, çıkış sorusu, tema, TR/EN metinler, logo önizleme, menüsüz tasarımcı ekranı ve demo formlar SAP GUI'de denendi ve onaylandı.

Ayrıntı kılavuzun sonundaki Ek bölümündedir.

## 2. Kurulum

ZPDF Studio [abapGit](https://abapgit.org) ile kurulur. Tek bir pull işlemi tüm ABAP nesnelerini, DDIC tiplerini, tasarımcı sayfasını (MIME deposu) ve tasarımcının GUI durumunu getirir.

### Gereksinimler

- ABAP 7.50 veya üstü sözdizimini destekleyen SAP NetWeaver / S/4HANA. Geliştirme ve testler S/4HANA 2021 (SAP_BASIS 7.56) üzerinde yapıldı.
- **Edge (WebView2)** tarayıcı denetimiyle SAP GUI for Windows 7.70 veya üstü (SAP GUI Seçenekleri > Etkileşim Tasarımı > Tarayıcı denetimi).
- [abapGit](https://abapgit.org) (standalone program veya geliştirici sürümü).
- `S_PROGRAM` yetkisi: `P_ACTION = SUBMIT` ile `P_GROUP = ZPDFSEDT` (form oluşturma ve değiştirme, logo ve font yükleme) ve `ZPDFSADM` (form ve depo kaydı silme).

### Adımlar

1. **Paket oluşturun**, örn. `$ZPDF_STUDIO` (yerel) veya `ZPDF_STUDIO` (transport edilebilir).
2. **Repoyu abapGit ile çekin.** abapGit > New Online > URL `https://github.com/abdullahatan/zpdf-studio` > 1. adımdaki paket > Pull; ardından tüm nesneleri etkinleştirin. SAP'nin internete erişimi yoksa: repoyu GitHub'dan ZIP olarak indirin, abapGit > New Offline > Import ZIP.
3. **Tasarımcıyı kontrol edin.** `ZPDF_STUDIO` programını başlatın, bir form adı yazıp **Yarat**'a basın. Tasarımcının durum çubuğunda ve Yardım > ZPDF Studio hakkında penceresinde **2.2.0** yazar. Program tasarımcı sayfasının eksik veya eski olduğunu söylerse, araç çubuğundaki **Tasarımcıyı kur / güncelle** ile bu repodaki `designer/dist/designer.html` dosyasını seçin.
4. **Demo formları kurun (isteğe bağlı).** `ZPDF_STUDIO_DEMO` > **Demo formlarını kur / güncelle** > `designer/dist/zpdf-demo-pack.txt`. Beş demo form ve beş görsel kurulur (bölüm 12).
5. **Logo ve fontları yükleyin (isteğe bağlı).** `ZPDF_STUDIO` > **Logo ve fontlar** veya doğrudan `ZPDF_STUDIO_ASSETS` (bölüm 10). Tasarımcı içinden de yüklenebilir.

`ZPDF_STUDIO` programının `ZPDF_DESIGNER` GUI durumu repoyla birlikte gelir: tasarımcı ekranında SAP'nin Program / Düzenle / Git menüleri görünmez. Yeni bir tasarımcı sürümü için repoyu yeniden çekin ya da `designer/dist/designer.html` dosyasını **Tasarımcıyı kur / güncelle** ile yükleyin; formlar ve ayarlar etkilenmez.

## 3. Form açma

`ZPDF_STUDIO` programının giriş ekranı SFP'deki gibi çalışır: form adını yazın, sonra üç düğmeden birine basın. F8 (Çalıştır) bu ekranda bilerek yoktur.

| Düğme | Ne yapar | Form yoksa / varsa |
| --- | --- | --- |
| **Görüntüle** | Formu salt okunur açar; kaydetme, ekleme, yükleme pasiftir | Yoksa uyarı: "Yarat düğmesini kullanın" |
| **Değiştir** | Formu düzenlemek için açar | Yoksa uyarı: "Yarat düğmesini kullanın" |
| **Yarat** | Yeni, boş bir form açar; form ilk kaydetmede oluşur | Varsa uyarı: "Değiştir düğmesini kullanın" |

- **Form adı:** en fazla 30 karakter; yalnızca A-Z, 0-9 ve alt çizgi. Küçük harf büyüğe çevrilir.
- **Arama yardımı (F4):** kayıtlı formları adı, açıklaması ve son değiştireni ile listeler.
- **Başkası düzenliyorsa:** form başka bir kullanıcıda açıksa, Değiştir ile açtığınızda form salt okunur açılır ve kimin düzenlediği yazılır.
- **Kaydedilmemiş taslak:** önceki oturumdan kaydedilmemiş bir taslağınız varsa, form açılırken taslak tarihiyle birlikte sorulur: **Geri yükle** taslağı açar, **Taslağı sil** son kayıtlı sürümü açar.
- Araç çubuğundaki **Logo ve fontlar** düğmesi `ZPDF_STUDIO_ASSETS` programını açar.

## 4. Tasarımcı ekranı

Tasarımcı tek bir ekrandır: üstte SAP araç çubuğu, altında tasarımcının kendi menü çubuğu, araç çubuğu ve üç sekme. Tasarımcının üzerinde açılan bir SAP penceresi (transport, kaydetme sorusu) kapanınca tasarım olduğu gibi geri gelir.

| Bölge | İçerik |
| --- | --- |
| SAP araç çubuğu | **Kaydet**, **PDF önizle**, **Sayfayı yenile**; Geri / Çıkış / İptal |
| Menü çubuğu | Dosya, Düzenle, Görünüm, Ekle, Tablo, Düzen, Araçlar, Paletler, Yardım (bölüm 8). Sağda form adı, sürüm ve durum: ● kaydedilmedi, ✓ kaydedildi veya Salt okunur |
| Araç çubuğu | Kaydet, Önizle, Geri al, Yinele, Uzaklaştır, yüzde göstergesi, Yakınlaştır, Sayfayı sığdır, Otomatik kaydet kutusu, Tema düğmeleri, Uyarılar (sayısıyla) |
| Sekmeler | **Form Özellikleri**, **Arayüz** (parametre sayısıyla), **Düzen** |
| Düzen sekmesi, sol | **Hiyerarşi** (sayfalar ve nesneler), **Veri Görünümü** (arayüz alan ağacı) |
| Düzen sekmesi, orta | Cetvelli sayfa; altta sayfa gezgini: ‹ Sayfa 1 / 2 ›, yeni sayfa (+), sayfayı sil (−) |
| Düzen sekmesi, sağ | **Nesne Kitaplığı**, **Nesne** paleti (Özellikler ve Veri Bağlama alt sekmeleri) |
| Durum çubuğu | Solda seçili nesne (ad, tür, konum, boyut), sağda kağıt boyutu, nesne sayısı ve sürüm |

### Form Özellikleri sekmesi

- **Form:** form adı, açıklama, etkin sürüm, durum; Sürümler ve ABAP çağrı kodu düğmeleri.
- **Sayfa:** kağıt boyutu (A3, A4, A5, Letter, Legal), yön (dikey / yatay), üst, alt, sol ve sağ kenar boşluğu (mm). Kenar boşlukları PDF önizlemede ve baskıda aynen uygulanır.
- **Varsayılanlar:** yeni metin nesnelerinin yazı tipi ve boyutu, ızgara aralığı (mm). Türkçe karakterler standart yazı tiplerinde de doğru basılır.

### Yakınlaştırma

Yakınlaştırma yalnızca sayfayı büyütür; menüler ve paletler hep aynı boyutta kalır. Kademeler %25 ile %400 arasındadır ve %100'den geçer.

- Araç çubuğundaki **− / +** veya Düzen sekmesinde klavyedeki **− / +** tuşları.
- **Alt + fare tekerleği** veya **Ctrl + fare tekerleği** (sayfanın üzerinde).
- **Ctrl + − / Ctrl + + / Ctrl + 0:** tarayıcıyı değil sayfayı yakınlaştırır; Ctrl + 0 ve yüzde göstergesine tıklamak %100'e döner.
- **Sayfayı sığdır** sayfanın tamamını, **Genişliğe sığdır** sayfa genişliğini çalışma alanına sığdırır.

### Tema

Araç çubuğundaki güneş / ay düğmeleri veya Görünüm > Tema ile açık ya da koyu tema seçilir. Seçim kullanıcınıza kaydedilir ve SAP'den çıkıp girdiğinizde de korunur. Koyu temada da kağıt beyaz kalır.

### Pencere boyutu ve menüler

SAP GUI penceresinin boyutlandırılması bir uygulama tarafından engellenemez. Bunun yerine tasarımcı en az 1120 × 620 piksel alanı korur; pencere bundan küçükse araçlar sıkışmaz, kaydırma çubuğu çıkar. En rahat kullanım tam ekrandır. `ZPDF_DESIGNER` GUI durumu sayesinde SAP'nin Program / Düzenle / Git menüleri görünmez; Sistem ve Yardım menüleri SAP GUI'ye aittir ve her ekranda kalır.

## 5. Arayüz sekmesi

Arayüz, formun dışarıdan aldığı verilerdir; SFP arayüzündeki Import parametreleri gibi çalışır. Düzen sekmesinde nesneler yalnızca buradaki alanlara bağlanır.

### Parametre ekleme

1. **Parametre adı** yazın (zorunlu).
2. **DDIC tipi** yazın veya **Ara...** ile seçin. Desteklenen tipler: yapı, tablo tipi, veritabanı tablosu / görünüm ve veri öğesi.
3. **Ekle**'ye basın. Tip SAP'den okunur, alanları **Bağlam (alan ağacı)** listesinde ve Düzen sekmesindeki Veri Görünümü'nde görünür.

Parametre adı kuralları (hepsi test edildi):

- Boş bırakılamaz; DDIC tipinin adı ad olarak kullanılmaz.
- En fazla 16 karakter; harfle başlar, yalnızca A-Z, 0-9 ve _ içerir.
- Bir formda aynı parametre adı iki kez kullanılamaz.

Parametre tablosunda her satırın yanında **Yeniden adlandır** (nesnelerin bağlamaları da güncellenir) ve **Parametreyi sil** düğmeleri vardır. Kullanım sütunu, parametrenin kaç farklı alanının tasarımda kullanıldığını gösterir.

### DDIC tipi arama

**Ara...** penceresinde ad, paket veya ikisiyle aranır.

- **Ad (* joker)** ve **Paket (* joker):** joker yazmazsanız baştan eşleşir; `Z` veya `Z*` tüm Z nesnelerini getirir. Adın içinde geçenler için `*METIN*` yazın (daha yavaştır). En az karakter sınırı yoktur.
- **Nesne tipi:** Yapı, Veritabanı tablosu, Görünüm, Tablo tipi, Veri öğesi. Hiçbiri işaretli değilse tümü aranır.
- **En fazla satır:** sonuç sayısını sınırlar (varsayılan 100). Sınıra ulaşılırsa pencere bunu söyler.
- Sonuç listesinde ad, tip, açıklama ve paket görünür; bir satıra tıklamak tipi DDIC tipi alanına yazar. Yazdığınız parametre adı korunur.

### ABAP çağrısı

Sekmede, bu formu kendi programınızdan basmak için hazır ABAP kodu görünür (parametre adları ve tipleriyle). **Panoya kopyala** ile alınır. Aynı kod Araçlar > ABAP çağrı kodu menüsünde de vardır.

### Önizleme verisi (JSON)

Tasarımdaki "önizleme verisini göster" görünümü ve **PDF önizle** bu veriyi kullanır; veri formla birlikte saklanır.

- Tarihler `YYYYMMDD` (ör. `20261121`), sayılar ondalık noktayla (`1250.50`) yazılır.
- **Uygula** düzenlediğiniz JSON'u kaydeder; geçersiz JSON'da hata mesajı verilir.
- **Arayüzden yeniden oluştur** her alana örnek değer koyar; tablolar üç satırla gelir.

## 6. Düzen sekmesi

Düzen sekmesinde sayfaya nesne koyar, nesneleri arayüz alanlarına bağlar ve özelliklerini ayarlarsınız. Her değişiklik geri alınabilir (Ctrl+Z).

### Nesne ekleme

Nesneler üç yoldan eklenir; üçü de test edildi:

- **Ekle menüsü** veya **Nesne Kitaplığı**'nda nesneye tıklamak: nesne sayfanın görünen sol üst köşesine eklenir ve seçilir.
- **Veri Görünümü'nde bir alana çift tıklamak:** o alana bağlı bir metin nesnesi ekler.
- **Veri Görünümü'nden bir tablo düğümünü sayfaya sürüklemek:** sütunları hazır, bağlı bir tablo oluşturur; tutar alanları `#.##0,00` biçimiyle gelir.

Nesne Kitaplığı'nda 23 nesne dört grupta durur; gruplar açılıp kapanır (Barkodlar başta kapalıdır):

| Grup | Nesneler |
| --- | --- |
| Standart | Metin, Veri alanı, Paragraf, Tablo, Resim / Logo, Onay kutusu |
| Özel alanlar | Tarih alanı (`DD.MM.YYYY`), Tutar alanı (`#.##0,00`, sağa yaslı), Yazıyla tutar (`WORDS:TRY\|UPPER`), Sayfa numarası (her sayfada), Filigran ("TASLAK", saydam, çapraz, her sayfada) |
| Şekiller | Çizgi, Dikey çizgi, Dikdörtgen, Elips |
| Barkodlar | QR Kod, DataMatrix, Code 128, Code 39, EAN-13, EAN-8, UPC-A, ITF-14 |

Veri alanı, tarih, tutar, yazıyla tutar ve tablo eklenince alan seçici kendiliğinden açılır. Seçicide yalnızca arayüzdeki alanlar listelenir.

### Taşıma ve boyutlandırma

- Fareyle sürükleyerek taşıyın; köşe ve kenar tutamaçlarından boyutlandırın. **Shift + köşe tutamağı** oranı korur.
- Ok tuşları ızgara adımı kadar taşır; **Shift** ile 5 mm, **Alt** ile 0,1 mm.
- **Izgaraya yasla** açıkken nesne ızgara adımına oturur; **Nesnelere yasla** açıkken yakındaki nesnenin kenarına veya ortasına oturur ve bir kılavuz çizgisi görünür. **Alt + sürükle** nesnelere yaslamadan taşır.
- Boş alanda sürüklemek çerçeve çizerek seçer; **Shift / Ctrl + tıklama** seçime ekler veya seçimden çıkarır.
- Bağlanmamış bir metne çift tıklamak metni yerinde düzenler.

### Özellikler (Nesne paleti)

Seçili nesnenin özellikleri açılıp kapanan gruplarda durur; yalnızca o nesne türüne uyan gruplar görünür. Birden fazla nesne seçiliyse değişiklik hepsine uygulanır.

| Grup | Alanlar |
| --- | --- |
| Genel | Ad, Tür, Kilitli (taşınamaz) |
| İçerik | Metin (`{ALAN}` yazımıyla metnin içine alan eklenebilir) |
| Barkod | Barkod türü, Sabit değer, Değeri barkodun altına yaz, Hata düzeltme düzeyi (QR) |
| Konum ve Boyut | X, Y, Genişlik, Yükseklik (mm), Döndürme, Opaklık |
| Yazı Tipi | Yazı tipi, Boyut, Renk, Kalın, İtalik, Altı çizili |
| Paragraf | Yatay hizalama, Dikey hizalama, Metni satırlara böl, İç boşluk |
| Arka Plan ve Kenarlık | Arka plan, Kenarlık rengi, Kenarlık kalınlığı |
| Dolgu ve Kenarlık | Şekiller için dolgu ve kenarlık |
| Resim | Sığdırma |
| Başlık Satırı / Veri Satırları | Tablolar: başlık satırını yazdır, renkler, yazı boyutu, alternatif satır rengi, çizgi rengi ve kalınlığı, hücre iç boşluğu |
| Yazdırma Kuralı (Ana Sayfa) | Hangi sayfalarda yazdırılır (aşağıda) |

### Veri Bağlama sekmesi

- **Veri alanı (arayüzden):** nesneyi bir arayüz alanına bağlar; seçicide yalnızca arayüzdeki alanlar vardır. Bağlı nesne sayfada `{PARAMETRE.ALAN}` olarak görünür.
- **Biçim:** tarih, sayı ve metin biçimi (bölüm 13). Alanın tipine uyan hazır biçimler listelenir.
- **Resim:** depodaki bir logo / resim ya da resmi taşıyan bir alan.
- **Tablo:** Arayüz tablosu ve Sütunlar (her sütunun başlığı, alanı, genişliği, hizası, biçimi); **Sütunları tablodan oluştur** tablonun tüm satır alanlarını sütun yapar. Sütun genişlikleri sayfada sütun sınırı sürüklenerek de ayarlanır.
- **Koşul:** *Yalnızca bu alan doluysa yazdır* ve *Tersi: alan boşsa yazdır*. Örnek: demo siparişteki "ACİL SİPARİŞ" etiketi yalnızca `IS_ORDER.URGENT` doluysa basılır.

### Tablolar sayfalara bölünür

Bir tablo verideki satır sayısı kadar uzar. Alt kenar boşluğuna ulaşınca yeni sayfada devam eder ve başlık satırı her sayfada tekrarlanır. Tablonun altına yerleştirdiğiniz nesneler (toplamlar, imza alanı) tablonun bittiği yeri izler; sığmazlarsa sonraki sayfaya geçer.

### Yazdırma kuralı (ana sayfa nesneleri)

Logo, altbilgi, sayfa numarası gibi her sayfada aynı yerde basılacak nesneler için **Hangi sayfalarda yazdırılır** seçilir:

| Seçenek | Anlamı |
| --- | --- |
| Gövde (normal akış) | Varsayılan: nesne bir kez, tasarlandığı yerde basılır |
| Her sayfada | Tüm sayfalarda |
| Yalnızca ilk sayfada / İlk sayfa hariç | Ör. ikinci sayfadan itibaren "(devam)" başlığı |
| Yalnızca son sayfada / Son sayfa hariç | Ör. yalnızca son sayfada genel toplam |
| Tek sayfalarda / Çift sayfalarda | Çift taraflı baskı için |

Tablolar ana sayfa nesnesi olamaz. Ana sayfa nesneleri tasarımda köşesinde küçük bir **M** işaretiyle görünür.

### Tasarım sayfaları

Bir form birden fazla tasarım sayfası içerebilir (ör. ön yüz ve arka yüz). Sayfa gezgininin **+** düğmesi veya Ekle > Yeni tasarım sayfası sayfa ekler; **−** onaydan sonra sayfayı siler.

## 7. Hizalama ve düzenleme

Düzen menüsünde iki ayrı hizalama vardır: **Nesneleri hizala** kutuların sayfadaki yerini, **Metni hizala** yazının kutunun içindeki yerini değiştirir. Bir metin ya da veri alanının yazısını sola / sağa almak istiyorsanız **Metni hizala** kullanılır.

| Komut | Neyi değiştirir | Seçenekler | Nasıl çalışır |
| --- | --- | --- | --- |
| Nesneleri hizala | Kutunun konumu | Sola, Yatayda ortala, Sağa, Üste, Dikeyde ortala, Alta | Birden fazla nesne: en soldaki / en sağdaki / ortadaki nesneye göre hizalanır. Tek nesne: sayfanın kenar boşluklarına yaslanır |
| Metni hizala | Yazının kutudaki yeri | Sola, Ortaya, Sağa, Üste, Dikeyde ortaya, Alta | Yalnızca metin ve veri alanlarına uygulanır; kutu yerinden oynamaz. Seçili hizalama menüde ✓ ile gösterilir |
| Eşit aralıkla dağıt | Aradaki boşluklar | Yatayda, Dikeyde | En az 3 nesne gerekir; ilk ve son nesne yerinde kalır, aradaki boşluklar eşitlenir |
| Aynı boyuta getir | Genişlik veya yükseklik | Genişlik, Yükseklik | En az 2 nesne; tümü ilk seçilen nesnenin boyutunu alır |
| Sayfada ortala | Kutunun konumu | Yatayda, Dikeyde | Kağıdın tam ortasına (kenar boşlukları dikkate alınmaz) |
| En öne getir / Bir öne getir / Bir arkaya gönder / En arkaya gönder | Çizim sırası | — | Üst üste binen nesnelerden hangisinin üstte basılacağı |
| Kilitle / kilidi aç | Kilit | — | Kilitli nesne sürüklenemez, silinemez, hizalanamaz; kesik çizgili çerçeveyle görünür |

Metin hizalaması PDF çıktısında da birebir uygulanır; bu, SAP'de basılan PDF'ten yazının konumu okunarak test edildi. Aynı ayar Nesne paletinde Özellikler > Paragraf > Yatay / Dikey hizalama olarak da vardır.

Hizalama ve sıra komutları yalnızca Düzen sekmesinde etkindir. Seçim yoksa veya koşul sağlanmıyorsa (ör. dağıtmak için en az 3 nesne) menü öğesi pasif görünür.

### Sağ tık menüsü

Sayfadaki bir nesneye sağ tıklamak nesneyi seçer ve kısa bir menü açar: Kes, Kopyala, Yapıştır, Çoğalt, Sil, En öne getir, En arkaya gönder, Kilitle / kilidi aç, Nesneleri hizala, Metni hizala, Sayfada ortala.

## 8. Menü başvurusu

Dokuz menünün 103 öğesinin hepsi çalışır; her biri gerçek tıklamayla test edildi. Görüntüle ile açılan formda değişiklik yapan öğeler pasiftir; önizleme, sürümler, dışa aktarma ve ABAP kodu açık kalır.

### Dosya

| Öğe | Kısayol | Ne yapar |
| --- | --- | --- |
| Kaydet | Ctrl+S | Formu yeni bir sürüm olarak kaydeder (bölüm 9) |
| PDF önizle | Ctrl+P | PDF'i gerçek ABAP motoruyla önizleme verisinden oluşturup açar |
| Transport talebine ekle... | | Formu ve kullandığı logo / fontları bir transport talebine ekler |
| Sürümler... | | Kayıtlı sürümleri listeler; eski bir sürüme dönülebilir |
| Tasarımı JSON olarak dışa aktar | | Tasarımı kopyalanabilir JSON metni olarak gösterir |
| JSON içe aktar... | | Yapıştırılan JSON tasarımı mevcut tasarımın yerine koyar; Geri al ile eskisine dönülür. Geçersiz metinde tasarım değişmez |
| Sayfayı SAP'den yeniden yükle | | Sayfayı güncel tasarımla yeniden gösterir |
| Çıkış | | Tasarımcıdan çıkar; kaydedilmemiş değişiklik varsa önce sorar |

### Düzenle

| Öğe | Kısayol | Ne yapar |
| --- | --- | --- |
| Geri al / Yinele | Ctrl+Z / Ctrl+Y | Son değişikliği geri alır / yeniden uygular (100 adıma kadar) |
| Kes / Kopyala | Ctrl+X / Ctrl+C | Seçili nesneleri panoya alır; Kes sayfadan kaldırır |
| Yapıştır | Ctrl+V | Panodakileri 4 mm kaydırarak ekler ve seçer |
| Çoğalt | Ctrl+D | Seçili nesnelerin kopyasını ekler |
| Sil | Del | Seçili nesneleri siler (kilitliler hariç) |
| Tümünü seç | Ctrl+A | Sayfadaki tüm nesneleri seçer |

Bu komutlar yalnızca Düzen sekmesinde etkindir; diğer sekmelerde kısayolları da çalışmaz.

### Görünüm

| Öğe | Ne yapar |
| --- | --- |
| Form Özellikleri / Arayüz / Düzen | İlgili sekmeyi açar |
| Yakınlaştır / Uzaklaştır / Gerçek boyut (%100) | Sayfayı kademeli büyütür / küçültür / %100 yapar (+, −, Ctrl+0) |
| Sayfayı sığdır / Genişliğe sığdır | Sayfanın tamamını / genişliğini çalışma alanına sığdırır |
| Izgara | Izgara noktalarını gösterir / gizler |
| Cetveller | Cetvelleri gösterir / gizler; seçili nesnenin yeri cetvelde işaretlenir |
| Kenar boşlukları | Kenar boşluğu kılavuzunu gösterir / gizler |
| Izgaraya yasla / Nesnelere yasla | Sürüklerken ızgaraya / yakındaki nesnelere oturmayı açar / kapatır |
| Önizleme verisini sayfada göster | Bağlı alanlarda `{ALAN}` yerine önizleme verisinin değerini gösterir |
| Tema > Açık / Koyu | Temayı değiştirir; seçim kullanıcınıza kaydedilir |

### Ekle

| Öğe | Ne yapar |
| --- | --- |
| Standart / Özel alanlar / Şekiller / Barkodlar | Alt menüdeki nesneyi ekler (23 nesne, bölüm 6) |
| Kayıtlı logolar | Depodaki logoları listeler; seçilen logo en-boy oranı korunarak eklenir. Depo boşsa "(depoda logo yok)" yazar |
| Yeni tasarım sayfası | Boş bir tasarım sayfası ekleyip ona geçer |

### Tablo

| Öğe | Ne yapar |
| --- | --- |
| Tablo ekle | Sayfa genişliğinde tablo ekler ve arayüz tablosu seçicisini açar |
| Sütun ekle / Son sütunu sil | Seçili tabloya sütun ekler / son sütunu siler |
| Sütunları arayüz tablosundan oluştur | Bağlı tablonun tüm satır alanlarını sütun yapar |
| Sütunları eşit genişlikte yap | Tüm sütunları eşit genişliğe getirir |
| Başlık satırı | Başlık satırını açar / kapatır (tasarımda ve PDF'te) |

Sütun komutları bir tablo seçiliyken etkindir.

### Düzen

Nesneleri hizala, Metni hizala, Eşit aralıkla dağıt, Aynı boyuta getir, Sayfada ortala, sıra komutları ve Kilitle / kilidi aç: bölüm 7.

### Araçlar

| Öğe | Ne yapar |
| --- | --- |
| Logo / font yükle... | PC'den PNG, JPEG veya TrueType (.ttf) seçtirir ve depoya kaydeder (bölüm 10) |
| Logo ve font deposu... | Depodakileri küçük resimle listeler; **Sayfaya ekle** ile logo eklenir |
| Önizleme verisi... | Arayüz sekmesini açar; önizleme verisi orada düzenlenir |
| Uyarılar... | Baskıyı etkileyebilecek sorunları listeler (ör. bağlanmamış tablo, değeri olmayan barkod) |
| ABAP çağrı kodu... | Formu programdan basacak kodu gösterir; Panoya kopyala |
| Oluşturulan form HTML'i... | Motorun kullanacağı form HTML'ini salt okunur gösterir |
| Otomatik kaydet | Açık / kapalı; araç çubuğundaki kutuyla aynıdır (bölüm 9) |

### Paletler

| Öğe | Ne yapar |
| --- | --- |
| Hiyerarşi / Veri Görünümü / Nesne Kitaplığı / Nesne | Paleti gösterir / gizler |
| Tüm paletleri göster / gizle | Dört paleti birden açar / kapatır |
| Çalışma alanını sıfırla | Paletleri, görünüm seçeneklerini ve yakınlaştırmayı varsayılana döndürür; tasarım değişmez |

Palet başlığındaki ok paleti daraltır / genişletir, × kapatır.

### Yardım

Klavye kısayolları, Hızlı başlangıç (altı adımda ilk form) ve ZPDF Studio hakkında (sürüm).

## 9. Kaydetme, sürümler, önizleme ve transport

Her kaydetme yeni bir sürüm oluşturur ve tasarım ekranda kalır. Otomatik kaydet açıkken kaydetmediğiniz değişiklikler de birkaç saniye içinde SAP'de taslak olarak saklanır; oturum kapansa bile kaybolmaz.

### Kaydet

- Araç çubuğundaki **Kaydet**, SAP araç çubuğundaki **Kaydet**, Dosya > Kaydet veya **Ctrl+S**.
- Kaydetme sırasında sayfa "SAP işlem yapıyor..." perdesiyle örtülür; bitince "FORM kaydedildi, sürüm 0004" mesajı gelir, durum ✓ kaydedildi olur. Seçimler ve geri alma geçmişi korunur.
- Otomatik kayıt açık bir üst birimde (client) SAP transport talebini sorar; mesaj talep numarasını da söyler.
- Değişiklik yokken SAP araç çubuğundaki Kaydet "Kaydedilecek değişiklik yok" der.

### Sürümler

Dosya > Sürümler (veya Form Özellikleri sekmesi) sürümleri kaydeden kullanıcı ve tarihle listeler; etkin sürüm **etkin** etiketiyle görünür. Son 20 sürüm saklanır. Eski bir sürümde **Bu sürüme dön** → onay → o sürüm etkin olur; kaydedilmemiş değişiklikler kaybolur.

### Otomatik kaydet ve taslak

- Araç çubuğundaki **Otomatik kaydet** kutusu veya Araçlar > Otomatik kaydet; başta açıktır.
- Açıkken her değişiklik yaklaşık 1 saniye sonra, ayrıca fare tasarımcıdan çıktığında SAP'ye gönderilir ve form + kullanıcı başına taslak olarak saklanır.
- Form bir sonraki açılışta taslak varsa sorar (bölüm 3). Kaydet taslağı siler.

### Çıkış

SAP'nin Geri / Çıkış / İptal düğmeleri veya Dosya > Çıkış. Kaydedilmemiş değişiklik varsa "FORM formunda kaydedilmemiş değişiklikler var. Çıkmadan önce kaydedilsin mi?" sorulur: **Kaydet** veya **Kaydetme**.

### PDF önizle

- SAP araç çubuğundaki **PDF önizle**, tasarımcıdaki **Önizle**, Dosya > PDF önizle veya **Ctrl+P**.
- Ekrandaki güncel tasarım (kaydedilmemiş olsa da) ve Arayüz sekmesindeki önizleme verisiyle gerçek ABAP motoru PDF üretir. Kenar boşlukları ve hizalamalar baskıdaki gibidir.
- PDF `FORM_preview.pdf` adıyla masaüstü klasörüne yazılır ve açılır; tasarımcı kullanılabilir kalır.

### Transport

Dosya > **Transport talebine ekle...**: kaydedilmemiş değişiklik varsa önce "Kaydet ve devam et" sorulur. Sonra SAP'nin talep seçme penceresi açılır; form ve kullandığı logo / fontlar seçilen talebe eklenir. Üst birim transporta izin vermiyorsa (SCC4) ne yapılması gerektiğini söyleyen bir mesaj gelir.

### Sayfayı yenile

SAP araç çubuğundaki **Sayfayı yenile** tasarımcıyı son durumuyla yeniden gösterir. "SAP yanıt vermedi" uyarısı görürseniz bunu kullanın; tasarım kaybolmaz.

## 10. Logo ve font deposu

Logolar, resimler ve TrueType fontlar SAP'de tek bir depoda (`ZPDF_STUDIO_ASST`) tutulur ve formlarla birlikte transport edilir. Depo hem `ZPDF_STUDIO_ASSETS` programından hem de tasarımcıdan yönetilir.

### Desteklenen dosyalar

- **Resim / logo:** PNG (saydam PNG dahil) ve JPEG.
- **Font:** TrueType (.ttf). OpenType CFF (.otf) ve font koleksiyonları (.ttc) desteklenmez; lisansı belgeye gömülmeye izin vermeyen fontlar reddedilir.
- Dosya türü dosya adından değil içeriğinden anlaşılır; en fazla 10 MB.
- Depodaki ad: en fazla 30 karakter, A-Z, 0-9 ve _.

### ZPDF_STUDIO_ASSETS programı

| İşlem | Kullanılan alanlar | Sonuç |
| --- | --- | --- |
| Listele ve önizle | Adlar, Tür (Tümü / Logolar-resimler / Fontlar) | Liste: Ad, Tür, Font ailesi, Kalın, İtalik, Dosya tipi, Dosya adı, Açıklama, Değiştiren, Değişiklik zamanı, Boyut |
| PC'den yükle | Ad, Dosya (F4 ile dosya seçimi), Açıklama; fontlarda Font ailesi, Kalın, İtalik | Dosya depoya kaydedilir; aynı ad varsa üzerine yazılır |
| PC'ye indir | Ad | Kayıt penceresi açılır, dosya indirilir |
| Sil | Ad | Kayıt silinir |
| Transport talebine ekle | Ad ve / veya Adlar | Seçilenler bir transport talebine eklenir |

**Önizleme:** listede bir satıra çift tıklayın. Logo ve resimler, saydam alanlar görünsün diye damalı zeminde; fontlar kendi yazı tipinde Türkçe harfli örnek metinle gösterilir. Pencerenin üstünde ad, dosya tipi, boyut ve açıklama yazar.

Ekrandaki tüm etiketler ve liste başlıkları TR oturumda Türkçe, diğer dillerde İngilizcedir.

### Tasarımcıdan

- **Araçlar > Logo / font yükle...:** dosya seçilir; pencerede depodaki ad dosya adından önerilir (ör. `zpdf_logo.png` → `ZPDF_LOGO`). Fontta aile adı, kalın ve italik dosya adından tahmin edilir. **Yükle** ile kaydedilir; tasarım ekranda kalır.
- **Araçlar > Logo ve font deposu...:** depodakiler küçük resimle (fontlar örnek harflerle) listelenir; **Sayfaya ekle** logoyu ekler.
- **Ekle > Kayıtlı logolar:** logoyu doğrudan ekler.

### Formda kullanım

- Logo, Resim / Logo nesnesinin Veri Bağlama sekmesinde depodan seçilir ya da yukarıdaki yollarla eklenir; en-boy oranı korunur.
- Font, nesnenin **Yazı tipi** özelliğine ailesi yazılarak kullanılır. Depoda olmayan bir aile yazılırsa Uyarılar'da görünür ve Arial kullanılır.
- Transport talebine eklenen form, kullandığı logo ve fontları da beraberinde götürür.

## 11. Formu ABAP programından yazdırma

Kendi programınızdan form basmak için `ZCL_PDF_STUDIO_API=>RENDER_FORM` kullanılır: arayüzdeki her parametreyi adıyla ve veri referansıyla verirsiniz, PDF `XSTRING` olarak döner. Hazır kodu Araçlar > ABAP çağrı kodu veya Arayüz sekmesi verir.

```abap
DATA ls_order  TYPE zpdf_s_demo_order.          " yapı
DATA lt_items  TYPE zpdf_tt_demo_order_items.   " tablo tipi
DATA lv_note   TYPE zpdf_demo_note.             " veri öğesi
DATA lt_params TYPE zcl_pdf_studio_api=>ty_params.
DATA lv_pdf    TYPE xstring.

" ... verileri doldurun ...

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

| Yöntem | Ne zaman |
| --- | --- |
| `RENDER_FORM` | Arayüzlü formlar: bir veya daha fazla parametre (yapı, tablo tipi, veri öğesi). Verilmeyen parametreler boş basılır |
| `RENDER_PDF` | Verinin tamamı tek bir yapı olan formlar (ör. `ZPDF_STUDIO_INVOICE`); tek parametreli bir arayüzde parametrenin değeri doğrudan verilebilir |
| `DOWNLOAD_PDF` | PDF'i PC'ye yazar. `iv_dialog = abap_true`: kayıt penceresi; `abap_false`: masaüstü klasörü. `iv_open = abap_true`: dosyayı açar |

- Form her zaman **etkin sürümü** ile basılır; sayfa boyutu ve kenar boşlukları formdan gelir.
- `IV_LANG` (varsayılan: oturum dili) ay ve gün adlarını, yazıyla tutarı ve büyük harf kurallarını belirler.
- Hatalar `ZCX_PDF_STUDIO` istisnasıyla gelir; metni TR oturumda Türkçedir (ör. "ZPDF_DEMO_ORDER formu yok").
- `ZPDF_STUDIO_DEMO` programındaki `PRINT_*` yöntemleri her demo için çalışan örnek koddur (bölüm 12).

## 12. Demo formlar

`ZPDF_STUDIO_DEMO`, SAP'nin DEMO* programları gibi çalışır: altı hazır formdan birini seçip PDF'ini açarsınız, kaydedersiniz veya formu tasarımcıda incelersiniz. Altı form da SAP'de basılarak test edildi.

### Ekran

- **Demo form:** altı radyo düğmesi (aşağıdaki tablo).
- **İşlem:** PDF oluştur ve aç · PDF oluştur ve farklı kaydet (klasör seçilir) · Formu tasarımcıda aç (`ZPDF_STUDIO`).
- **Demo verisi:** kalem sayısı (fatura, sipariş, irsaliye, talimat; 1-500) ve faturada TASLAK filigranı.
- **Demo formlarını kur / güncelle:** `designer/dist/zpdf-demo-pack.txt` dosyasından beş formu ve beş görseli kurar. Kurulu olmayan bir form seçildiğinde program kurmayı kendisi önerir. Fatura formu ilk çalıştırmada otomatik oluşur.

### Formlar

| Form | Kağıt | Gösterdikleri | Arayüz |
| --- | --- | --- | --- |
| `ZPDF_STUDIO_INVOICE` Fatura | A4 dikey | Sayfalara bölünen kalem tablosu, yazıyla tutar, koşullu TASLAK filigranı, DataMatrix, EAN-13, QR, sayfa numarası | Tek yapı (`RENDER_PDF`) |
| `ZPDF_DEMO_ORDER` Satınalma siparişi | A4 dikey | Logo, renkli başlık bloğu, bilgi kartları, koşullu "ACİL" etiketi, toplamlar, QR, ikinci sayfada "(devam)" başlığı | `IS_ORDER` yapı, `IT_ITEMS` tablo tipi, `IV_NOTE` veri öğesi |
| `ZPDF_DEMO_CERT` Başarı sertifikası | A4 yatay | Çift çerçeve, 90° döndürülmüş yan başlık, mühür ve imza görseli, 45° "ÜSTÜN BAŞARI" bandı (koşullu), doğrulama QR'ı | `IS_CERT` yapı |
| `ZPDF_DEMO_TICKET` Etkinlik bileti | A5 yatay | Afiş fotoğrafı (JPEG) üzerine yazı, renk blokları, delikli kupon, saat biçimleri, QR ve Code 128 | `IS_TICKET` yapı |
| `ZPDF_DEMO_DELIVERY` Sevk irsaliyesi | A4 dikey | Her sayfada yan şerit ve altbilgi, adres kartları, uzun kalem tablosu, Code 128, ITF-14, DataMatrix | `IS_DELIVERY` yapı, `IT_ITEMS` tablo tipi |
| `ZPDF_DEMO_PAYMENT` Ödeme talimatı | A4 dikey | Yapının içindeki tablo (`INPUT.ITEMS`), onay kutuları, yazıyla tutar, imza ve kaşe görseli | `INPUT` (içinde tablo olan tek yapı) |

### DDIC demo nesneleri

Demo arayüzleri paketteki gerçek DDIC nesnelerini kullanır:

- **Veri öğeleri:** `ZPDF_DEMO_DOCNO`, `ZPDF_DEMO_NAME`, `ZPDF_DEMO_TEXT`, `ZPDF_DEMO_NOTE`, `ZPDF_DEMO_AMOUNT`, `ZPDF_DEMO_QTY`.
- **Yapılar:** `ZPDF_S_DEMO_ORDER`, `ZPDF_S_DEMO_ORDER_ITEM`, `ZPDF_S_DEMO_CERT`, `ZPDF_S_DEMO_TICKET`, `ZPDF_S_DEMO_DELIVERY`, `ZPDF_S_DEMO_DELIV_ITEM`, `ZPDF_S_DEMO_PAYMENT`, `ZPDF_S_DEMO_PAY_ITEM`.
- **Tablo tipleri:** `ZPDF_TT_DEMO_ORDER_ITEMS`, `ZPDF_TT_DEMO_DELIV_ITEMS`, `ZPDF_TT_DEMO_PAY_ITEMS`.
- **Demo verisi:** `ZCL_PDF_STUDIO_DEMOS` (`ORDER`, `CERTIFICATE`, `TICKET`, `DELIVERY`, `PAYMENT`).
- **Görseller:** `ZPDF_DEMO_LOGO`, `ZPDF_DEMO_SEAL`, `ZPDF_DEMO_SIGN`, `ZPDF_DEMO_STAMP` (saydam PNG), `ZPDF_DEMO_BANNER` (JPEG).

Demo formlar kurulduktan sonra sıradan formlardır: tasarımcıda değiştirilebilir, sürümlenebilir ve transport edilebilir. **Demo formlarını kur / güncelle** tekrar çalıştırılırsa formların paketteki hali yeni bir sürüm olarak kaydedilir; eski sürümlere Sürümler'den dönülebilir.

## 13. Biçim kalıpları ve klavye kısayolları

Biçim, bağlı alanın Veri Bağlama > **Biçim** kutusuna veya metnin içinde `{ALAN | kalıp}` olarak yazılır. Kalıplar `|` ile zincirlenir: `WORDS:TRY|UPPER`. Biçim boş bırakılırsa kullanıcının SAP ayarı kullanılır.

| Kalıp | Örnek çıktı |
| --- | --- |
| `DD.MM.YYYY` | 21.11.2026 |
| `D MMMM YYYY` | 21 Kasım 2026 |
| `D MMMM YYYY, dddd` | 19 Aralık 2026, Cumartesi |
| `DD/MM/YYYY` · `YYYY-MM-DD` · `MMMM YYYY` | 21/11/2026 · 2026-11-21 · Kasım 2026 |
| `HH:mm` · `HH:mm:ss` | 19:00 · 19:00:00 |
| `#.##0,00` | 22.380,00 |
| `#,##0.00` | 22,380.00 |
| `#.##0` | 240 |
| `#.##0,00;(#.##0,00)` | Negatifler parantez içinde: (1.250,00) |
| `SAP` / `SAP:EUR` | Kullanıcının SAP sayı / tarih ayarı; para biriminin ondalık sayısıyla |
| `WORDS:TRY` | Yazıyla tutar: "... Türk lirası ... kuruş" (USD, EUR de olur) |
| `UPPER` · `LOWER` · `TITLE` | Büyük, küçük, ilk harf büyük; Türkçede i / İ ve ı / I kurallarına uyar |
| `ALPHA` · `TRIM` | Baştaki sıfırları atar · boşlukları kırpar |

Ay ve gün adları ile yazıyla tutar baskının diline göre Türkçe, Almanca veya İngilizce yazılır. Özel metinler `{currentPage}` ve `{totalPages}` sayfa numarasını ve toplam sayfayı basar.

### Klavye kısayolları

| Kısayol | İşlev |
| --- | --- |
| Ctrl+S / Ctrl+P | Kaydet / PDF önizle |
| Ctrl+Z / Ctrl+Y (veya Ctrl+Shift+Z) | Geri al / Yinele |
| Ctrl+C / Ctrl+X / Ctrl+V | Kopyala / Kes / Yapıştır |
| Ctrl+D | Çoğalt |
| Del | Sil |
| Ctrl+A | Tümünü seç |
| Ok tuşları | Izgara adımı kadar taşı (Shift: 5 mm, Alt: 0,1 mm) |
| + / − / Ctrl+0 | Yakınlaştır / Uzaklaştır / %100 |
| Alt + fare tekerleği | Sayfayı yakınlaştır / uzaklaştır |
| Shift / Ctrl + tıklama | Seçime ekle / seçimden çıkar |
| Boş alanda sürükle | Çerçeve çizerek seç |
| Çift tıklama | Metni yerinde düzenle; Veri Görünümü'nde alanı ekle |
| Shift + köşe tutamağı | Oranı koruyarak boyutlandır |
| Alt + sürükle | Nesnelere yaslamadan taşı |
| Esc | Menüyü veya pencereyi kapat, seçimi kaldır |

Düzenleme kısayolları Düzen sekmesinde ve bir giriş alanına yazmadığınız sırada çalışır. Ctrl+S, Ctrl+P ve Ctrl+0 her yerde çalışır.

## 14. Sorun giderme

Mesajların çoğu ne yapılması gerektiğini kendisi söyler. Aşağıdaki durumlar kullanım sırasında karşılaşılanlardır.

| Belirti | Neden | Çözüm |
| --- | --- | --- |
| "Tasarımcı sayfası kurulu değil veya eski sürüm" | MIME deposunda sayfa yok ya da eski | Repoyu yeniden çekin veya `ZPDF_STUDIO` → Tasarımcıyı kur / güncelle → `designer/dist/designer.html` |
| "Bu dosya ZPDF Studio 2 tasarımcı sayfası değil" | Yanlış dosya seçildi | `designer/dist/designer.html` seçilmeli |
| Durum çubuğunda 2.2.0 yazmıyor | Eski bir tasarımcı sayfası kurulu | Tasarımcıyı kur / güncelle ile yükleyin (bölüm 2, adım 3) |
| "SAP yanıt vermedi" | Bir istek 30 saniyede yanıtlanmadı | SAP araç çubuğu → **Sayfayı yenile**; tasarım kaybolmaz |
| "SAP GUI sayfa verisini iletmedi" | Desteklenmeyen GUI veya tarayıcı denetimi | SAP GUI for Windows ve Edge (WebView2) tarayıcı denetimi kullanılmalı |
| Program / Düzenle / Git menüleri görünüyor | `ZPDF_DESIGNER` GUI durumu yok veya etkin değil | `ZPDF_STUDIO` programını GUI durumuyla birlikte etkinleştirin (repoyla gelir) |
| Form salt okunur açıldı | Görüntüle ile açıldı ya da form başka bir kullanıcıda açık | Değiştir ile açın; kilitliyse diğer kullanıcının çıkmasını bekleyin |
| "FORM ZPDF Studio tasarımcısıyla yapılmamış" | Adı kullanılan form başka bir araçla oluşturulmuş | Yeni bir form adı kullanın |
| Uyarılar düğmesinde sayı var | Bağlanmamış tablo, değeri olmayan barkod, depoda olmayan font gibi durumlar | Araçlar > Uyarılar listesindeki nesneleri düzeltin |
| Font PDF'te Arial çıkıyor | Aile adı depoda yok | Fontu depoya yükleyin veya Yazı tipi'ne depodaki aile adını yazın |
| Transport mesajı SCC4 veya teslimat sınıfından söz ediyor | Üst birim transporta izin vermiyor ya da tablo ayarı eksik | Mesajdaki adımı uygulayın (SCC4 ayarı veya SE11'de teslimat sınıfı C) |
| "Yetki eksik: S_PROGRAM ZPDFSEDT / SUBMIT" | Kullanıcının ZPDF Studio yetkisi yok | `S_PROGRAM` yetkisi verin: `P_GROUP` `ZPDFSEDT` (silme için `ZPDFSADM`) |
| Demo: "FORM formu henüz kurulmamış" | Demo paketi kurulmadı | Soruya Evet deyip `designer/dist/zpdf-demo-pack.txt` seçin |
| Kurulumdan hemen sonra `LOAD_PROGRAM_CLASS_MISMATCH` dumpı | Program açıkken sınıflar güncellendi | `/n` ile programı yeniden başlatın; kod hatası değildir |

## Ek: Test ve doğrulama özeti

Bu kılavuzdaki her özellik aşağıdaki testlerden en az biriyle sınandı; tümü 21.11.2026 itibarıyla başarılıdır. Testi geçmeyen hiçbir özellik kılavuza alınmadı.

| Test | Kapsam | Sonuç |
| --- | --- | --- |
| Menü testi (`designer/test/menus.mjs`) | 103 menü öğesi gerçek tıklamayla; sağ tık menüsü; SAP'ye giden istekler; TR / EN dil; görüntüleme modu | 177 / 177 |
| Tarayıcı testi (`designer/test/smoke.mjs`) | Arayüz, sürükle-bırak, bağlama, yakınlaştırma, tema, küçük pencere, kaydetme sonrası tasarımın korunması | 69 / 69 |
| Dönüştürme testi (`designer/test/convert.test.mjs`) | Tasarımın motor HTML'ine çevrilmesi | 13 / 13 |
| ABAP Unit, ZPDF Studio paketi | Motor, biçimler, barkodlar, JSON, metin hizalamasının PDF'te konumu, Türkçe hata mesajları, demo verisi, beş demo formun gerçek baskısı | 59 / 59 |
| SAP GUI'de elle deneme | Kaydet, transport, PDF önizleme ve kenar boşluğu, çıkış sorusu, tema kalıcılığı, TR / EN metinler, logo önizleme, menüsüz tasarımcı, altı demo form | Onaylandı |

Menü testinin satır satır sonucu [`test-report/menus-report.json`](test-report/menus-report.json) dosyasındadır.
