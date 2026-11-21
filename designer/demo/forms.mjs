// The demo forms of ZPDF Studio as designer documents (zpdf:2).
// Interface types: DDIC objects ZPDF_DEMO_* / ZPDF_S_DEMO_* / ZPDF_TT_DEMO_* of package $ZPDF_STUDIO.
// The node trees below repeat those definitions (name, ABAP type kind, length, description).

const E = (n, d, t = 'C', l = 20, dec) => (dec === undefined ? { n, k: 'E', t, l, d } : { n, k: 'E', t, l, dec, d });
const NAME = (n, d) => E(n, d, 'C', 60);
const TEXT = (n, d) => E(n, d, 'C', 120);
const AMOUNT = (n, d) => E(n, d, 'P', 15, 2);
const QTY = (n, d) => E(n, d, 'P', 13, 3);
const DATE = (n, d) => E(n, d, 'D', 8);
const TIME = (n, d) => E(n, d, 'T', 6);
const FLAG = (n, d) => E(n, d, 'C', 1);

export const TYPES = {
  ZPDF_S_DEMO_ORDER: {
    k: 'S', d: 'ZPDF Studio demo: satınalma siparişi', c: [
      E('EBELN', 'Belge numarası', 'C', 16), DATE('BEDAT', 'Sipariş tarihi'), DATE('EINDT', 'Teslim tarihi'), E('LIFNR', 'Satıcı no', 'C', 10),
      NAME('VENDOR_NAME', 'Tedarikçi'), TEXT('VENDOR_ADDR', 'Tedarikçi adresi'), E('VENDOR_TAXNO', 'Vergi no', 'C', 11), NAME('BUYER', 'Satınalmacı'),
      E('PAYTERMS', 'Ödeme koşulu', 'C', 40), E('WAERS', 'Para birimi', 'C', 5), AMOUNT('NETWR', 'Net tutar'), AMOUNT('TAX_AMOUNT', 'KDV tutarı'),
      AMOUNT('TOTAL', 'Genel toplam'), FLAG('URGENT', 'Acil')
    ]
  },
  ZPDF_TT_DEMO_ORDER_ITEMS: {
    k: 'T', d: 'ZPDF Studio demo: sipariş kalemleri', c: [
      E('POSNR', 'Kalem', 'C', 5), E('MATNR', 'Malzeme', 'C', 18), NAME('MAKTX', 'Malzeme tanımı'), QTY('MENGE', 'Miktar'), E('MEINS', 'Birim', 'C', 3),
      AMOUNT('NETPR', 'Birim fiyat'), AMOUNT('NETWR', 'Tutar'), DATE('EINDT', 'Teslim tarihi')
    ]
  },
  ZPDF_DEMO_NOTE: { k: 'E', t: 'C', l: 255, d: 'Not' },
  ZPDF_S_DEMO_CERT: {
    k: 'S', d: 'ZPDF Studio demo: sertifika', c: [
      E('CERT_NO', 'Sertifika no', 'C', 16), NAME('FULL_NAME', 'Ad soyad'), TEXT('COURSE', 'Eğitim'), E('HOURS', 'Süre (saat)', 'I', 10),
      DATE('START_DATE', 'Başlangıç'), DATE('END_DATE', 'Bitiş'), DATE('ISSUE_DATE', 'Düzenleme tarihi'), NAME('TRAINER', 'Eğitmen'),
      NAME('MANAGER', 'Genel müdür'), E('CITY', 'Şehir', 'C', 30), E('SCORE', 'Başarı puanı', 'P', 5, 2), TEXT('VERIFY_URL', 'Doğrulama adresi'), FLAG('HONORS', 'Üstün başarı')
    ]
  },
  ZPDF_S_DEMO_TICKET: {
    k: 'S', d: 'ZPDF Studio demo: etkinlik bileti', c: [
      E('TICKET_NO', 'Bilet no', 'C', 16), NAME('EVENT', 'Etkinlik'), NAME('ARTIST', 'Sanatçı'), NAME('VENUE', 'Mekan'), E('CITY', 'Şehir', 'C', 30),
      DATE('EVENT_DATE', 'Etkinlik tarihi'), TIME('DOORS', 'Kapı açılış'), TIME('START_TIME', 'Başlangıç'), E('BLOCK', 'Blok', 'C', 10), E('SEAT_ROW', 'Sıra', 'C', 4),
      E('SEAT_NO', 'Koltuk', 'C', 4), E('GATE', 'Kapı', 'C', 4), NAME('HOLDER', 'Bilet sahibi'), E('CATEGORY', 'Kategori', 'C', 20), AMOUNT('PRICE', 'Fiyat'),
      E('WAERS', 'Para birimi', 'C', 5), FLAG('VIP', 'VIP'), E('BARCODE', 'Barkod', 'C', 20)
    ]
  },
  ZPDF_S_DEMO_DELIVERY: {
    k: 'S', d: 'ZPDF Studio demo: sevk irsaliyesi', c: [
      E('VBELN', 'İrsaliye no', 'C', 16), DATE('WADAT', 'Sevk tarihi'), NAME('SHIP_TO_NAME', 'Alıcı'), TEXT('SHIP_TO_ADDR', 'Alıcı adresi'), E('SHIP_TO_CITY', 'Şehir', 'C', 30),
      E('SHIP_TO_PHONE', 'Telefon', 'C', 20), NAME('CARRIER', 'Taşıyıcı'), E('TRACKING', 'Takip no', 'C', 20), E('GTIN14', 'Sevk birimi (ITF-14)', 'C', 14), E('PLATE', 'Plaka', 'C', 12),
      NAME('DRIVER', 'Sürücü'), QTY('GROSS_WEIGHT', 'Brüt ağırlık'), E('PACKAGES', 'Koli sayısı', 'I', 10), FLAG('EXPRESS', 'Ekspres'), FLAG('FRAGILE', 'Kırılır')
    ]
  },
  ZPDF_TT_DEMO_DELIV_ITEMS: {
    k: 'T', d: 'ZPDF Studio demo: teslimat kalemleri', c: [
      E('POSNR', 'Kalem', 'C', 5), E('MATNR', 'Malzeme', 'C', 18), NAME('MAKTX', 'Malzeme tanımı'), E('EAN', 'EAN', 'C', 13), E('CHARG', 'Parti', 'C', 10),
      E('LGORT', 'Depo', 'C', 4), QTY('LFIMG', 'Miktar'), E('MEINS', 'Birim', 'C', 3)
    ]
  },
  ZPDF_S_DEMO_PAYMENT: {
    k: 'S', d: 'ZPDF Studio demo: ödeme talimatı', c: [
      E('BUKRS', 'Şirket kodu', 'C', 4), NAME('COMPANY', 'Şirket'), E('ORDER_NO', 'Talimat no', 'C', 16), DATE('ORDER_DATE', 'Talimat tarihi'), DATE('VALUE_DATE', 'Valör'),
      NAME('BANK', 'Banka'), NAME('BRANCH', 'Şube'), E('IBAN', 'IBAN', 'C', 34), E('WAERS', 'Para birimi', 'C', 5), AMOUNT('TOTAL', 'Toplam'), E('ITEM_COUNT', 'Ödeme adedi', 'I', 10),
      FLAG('EFT', 'EFT'), FLAG('HAVALE', 'Havale'), FLAG('SWIFT', 'SWIFT'), NAME('SIGNER1', 'Yetkili 1'), NAME('SIGNER2', 'Yetkili 2'),
      {
        n: 'ITEMS', k: 'T', d: 'Ödeme kalemleri', c: [
          NAME('RECEIVER', 'Alıcı'), E('RECEIVER_IBAN', 'Alıcı IBAN', 'C', 34), NAME('RECEIVER_BANK', 'Alıcı banka'), TEXT('SGTXT', 'Açıklama'), AMOUNT('WRBTR', 'Tutar'), E('WAERS', 'Para birimi', 'C', 5)
        ]
      }
    ]
  }
};

const COMPANY = 'Nova Endüstri A.Ş.';
const ADDRESS = 'Organize Sanayi Bölgesi 5. Cad. No:12, Melikgazi / Kayseri';

/** Collects the objects of one form; names are unique, ids are assigned by normalizeDoc. */
function sheet(z) {
  const els = [];
  const names = {};
  function add(type, name, props) {
    let unique = name;
    for (let i = 2; names[unique]; i++) unique = name + '_' + i;
    names[unique] = true;
    els.push(Object.assign(z.defaultsFor(type), props, { name: unique }));
  }
  return {
    els,
    rect: (name, x, y, w, h, fill, o) => add('rect', name, Object.assign({ x, y, w, h, fill: fill || '', bw: 0 }, o)),
    ellipse: (name, x, y, w, h, fill, o) => add('ellipse', name, Object.assign({ x, y, w, h, fill: fill || '', bw: 0 }, o)),
    line: (name, x, y, w, h, color, o) => add('line', name, Object.assign({ x, y, w, h, color }, o)),
    text: (name, x, y, w, h, text, o) => add('text', name, Object.assign({ x, y, w, h, text }, o)),
    field: (name, x, y, w, h, bind, o) => add('text', name, Object.assign({ x, y, w, h, text: '', bind }, o)),
    image: (name, x, y, w, h, asset, o) => add('image', name, Object.assign({ x, y, w, h, asset }, o)),
    code: (name, x, y, w, h, code, o) => add('barcode', name, Object.assign({ x, y, w, h, code }, o)),
    check: (name, x, y, w, h, bind, o) => add('checkbox', name, Object.assign({ x, y, w, h, bind }, o)),
    table: (name, x, y, w, h, bind, cols, o) => add('table', name, Object.assign({ x, y, w, h, bind, cols: cols.map((c) => Object.assign({ align: 'left', fmt: '' }, c)) }, o))
  };
}

function finish(z, id, description, page, iface, s, sample) {
  const doc = z.newDoc();
  doc.description = description;
  doc.page = page;
  doc.iface = iface.map(([name, type]) => ({ name, type, node: JSON.parse(JSON.stringify(TYPES[type])) }));
  doc.pages[0].els = s.els;
  doc.sample = JSON.stringify(sample);
  return { id, description, doc: z.normalizeDoc(doc) };
}

// -------------------------------------------------------------------------------------------------
// 1. Purchase order: structure + table type + data element as three parameters
// -------------------------------------------------------------------------------------------------
function order(z) {
  const s = sheet(z);
  const navy = '#0f2a43', amber = '#f59e0b';
  s.rect('baslik_zemin', 118, 0, 92, 40, navy);
  s.rect('baslik_serit', 118, 40, 92, 1.6, amber);
  s.image('logo', 12, 11, 58, 17.4, 'ZPDF_DEMO_LOGO');
  s.text('baslik', 122, 8, 80, 8, 'SATINALMA SİPARİŞİ', { color: '#ffffff', bold: true, size: 15, align: 'right' });
  s.field('siparis_no', 122, 18, 80, 9, 'IS_ORDER.EBELN', { color: amber, bold: true, size: 18, align: 'right' });
  s.text('para_birimi', 122, 30, 80, 5, 'Para birimi: {IS_ORDER.WAERS}', { color: '#cbd5e1', size: 8, align: 'right' });
  s.text('acil', 12, 33, 36, 6.5, 'ACİL SİPARİŞ', { bg: '#dc2626', color: '#ffffff', bold: true, size: 9, align: 'center', valign: 'middle', printIf: 'IS_ORDER.URGENT' });

  s.rect('tedarikci_kutu', 12, 48, 92, 36, '#f8fafc', { bw: 0.2, bc: '#cbd5e1' });
  s.rect('tedarikci_serit', 12, 48, 1.5, 36, navy);
  s.text('tedarikci_etiket', 17, 50.5, 60, 4, 'TEDARİKÇİ', { size: 7, bold: true, color: '#64748b' });
  s.field('tedarikci_adi', 17, 55, 84, 6, 'IS_ORDER.VENDOR_NAME', { size: 11, bold: true, color: '#0f172a' });
  s.field('tedarikci_adres', 17, 61.5, 84, 9.5, 'IS_ORDER.VENDOR_ADDR', { size: 9, color: '#334155' });
  s.text('tedarikci_vergi', 17, 72, 84, 4.5, 'Vergi no: {IS_ORDER.VENDOR_TAXNO}', { size: 8.5, color: '#334155' });
  s.text('tedarikci_no', 17, 77, 84, 4.5, 'Satıcı no: {IS_ORDER.LIFNR}', { size: 8.5, color: '#334155' });

  [[110, 48, 'SİPARİŞ TARİHİ', '{IS_ORDER.BEDAT | D MMMM YYYY}', 'siparis_tarihi'], [155, 48, 'TESLİM TARİHİ', '{IS_ORDER.EINDT | DD.MM.YYYY}', 'teslim_tarihi'],
    [110, 67, 'SATINALMACI', '{IS_ORDER.BUYER}', 'satinalmaci'], [155, 67, 'ÖDEME KOŞULU', '{IS_ORDER.PAYTERMS}', 'odeme_kosulu']].forEach(([x, y, label, value, name]) => {
    s.rect(name + '_kart', x, y, 43, 17, '#eef4fb');
    s.text(name + '_etiket', x + 3, y + 2.5, 37, 4, label, { size: 7, bold: true, color: '#64748b' });
    s.text(name, x + 3, y + 7.5, 38, 7, value, { size: 10, bold: true, color: navy });
  });

  s.table('kalemler', 12, 92, 186, 26, 'IT_ITEMS', [
    { title: 'Kalem', field: 'POSNR', w: 8 }, { title: 'Malzeme', field: 'MATNR', w: 15 }, { title: 'Tanım', field: 'MAKTX', w: 31 },
    { title: 'Miktar', field: 'MENGE', w: 11, align: 'right', fmt: '#.##0,00' }, { title: 'Birim', field: 'MEINS', w: 7, align: 'center' },
    { title: 'Birim fiyat', field: 'NETPR', w: 13, align: 'right', fmt: '#.##0,00' }, { title: 'Tutar', field: 'NETWR', w: 15, align: 'right', fmt: '#.##0,00' }
  ], { hbg: navy, hfg: '#ffffff', zebra: '#f1f5f9', bc: '#e2e8f0', bw: 0.1, pad: 1.3 });

  // below the table: these objects follow it
  s.rect('not_zemin', 12, 122, 98, 23, '#fffbeb');
  s.rect('not_serit', 12, 122, 1.5, 23, amber);
  s.text('not_etiket', 17, 124, 60, 4, 'SİPARİŞ NOTU', { size: 7, bold: true, color: '#92400e' });
  s.field('siparis_notu', 17, 128.5, 90, 15, 'IV_NOTE', { size: 8.5, color: '#44403c' });
  s.text('ara_toplam_etiket', 118, 122, 40, 5.5, 'Ara toplam', { size: 9, color: '#475569', align: 'right' });
  s.text('ara_toplam', 160, 122, 38, 5.5, '{IS_ORDER.NETWR | #.##0,00} {IS_ORDER.WAERS}', { size: 9, align: 'right' });
  s.text('kdv_etiket', 118, 128, 40, 5.5, 'KDV', { size: 9, color: '#475569', align: 'right' });
  s.text('kdv', 160, 128, 38, 5.5, '{IS_ORDER.TAX_AMOUNT | #.##0,00} {IS_ORDER.WAERS}', { size: 9, align: 'right' });
  s.rect('toplam_zemin', 118, 135, 80, 10, navy);
  s.text('toplam_etiket', 121, 137.3, 34, 6, 'GENEL TOPLAM', { size: 9, bold: true, color: '#ffffff' });
  s.text('toplam', 150, 136.6, 45, 7, '{IS_ORDER.TOTAL | #.##0,00} {IS_ORDER.WAERS}', { size: 12, bold: true, color: amber, align: 'right' });
  s.text('yaziyla', 40, 147.5, 158, 5, 'Yalnız: {IS_ORDER.TOTAL | WORDS:TRY|UPPER}', { size: 7.5, color: '#475569', align: 'right' });
  s.code('takip_qr', 12, 154, 24, 24, 'qr', { text: 'https://example.com/po/{IS_ORDER.EBELN}' });
  s.text('takip_metin', 39, 161, 44, 9, 'Sipariş takibi için\nQR kodu okutun', { size: 7.5, color: '#64748b' });
  s.field('hazirlayan_adi', 112, 166, 38, 5.5, 'IS_ORDER.BUYER', { size: 9, align: 'center' });
  s.line('hazirlayan_cizgi', 112, 172, 38, 0.3, '#94a3b8');
  s.text('hazirlayan', 112, 173.5, 38, 4.5, 'Hazırlayan', { size: 8, color: '#64748b', align: 'center' });
  s.line('onaylayan_cizgi', 160, 172, 38, 0.3, '#94a3b8');
  s.text('onaylayan', 160, 173.5, 38, 4.5, 'Onaylayan', { size: 8, color: '#64748b', align: 'center' });

  // master page objects
  s.text('devam', 12, 7, 110, 5, 'Sipariş {IS_ORDER.EBELN} (devam)', { size: 8, color: navy, printOn: 'notfirst' });
  s.line('alt_cizgi', 12, 281, 186, 0.3, '#cbd5e1', { printOn: 'every' });
  s.text('altbilgi', 12, 283, 186, 5, COMPANY + ' · ' + ADDRESS + ' · Sayfa {currentPage} / {totalPages}', { size: 7.5, color: '#64748b', align: 'center', printOn: 'every' });

  return finish(z, 'ZPDF_DEMO_ORDER', 'ZPDF Studio demo: satınalma siparişi (yapı + tablo tipi + veri öğesi)',
    { size: 'A4', orientation: 'P', mt: 15, mr: 12, mb: 20, ml: 12 },
    [['IS_ORDER', 'ZPDF_S_DEMO_ORDER'], ['IT_ITEMS', 'ZPDF_TT_DEMO_ORDER_ITEMS'], ['IV_NOTE', 'ZPDF_DEMO_NOTE']], s, {
      IS_ORDER: { EBELN: '4500012345', BEDAT: '20261121', EINDT: '20261205', LIFNR: '100245', VENDOR_NAME: 'Yıldız Metal San. ve Tic. Ltd. Şti.', VENDOR_ADDR: 'İkitelli OSB Metal İş Sanayi Sitesi 4. Blok No:17, Başakşehir / İstanbul', VENDOR_TAXNO: '9876543210', BUYER: 'Ayşe Demir', PAYTERMS: '30 gün vadeli havale', WAERS: 'TRY', NETWR: '18650.00', TAX_AMOUNT: '3730.00', TOTAL: '22380.00', URGENT: 'X' },
      IT_ITEMS: [
        { POSNR: '10', MATNR: 'ST-304-2MM', MAKTX: 'Paslanmaz sac 304 kalite 2 mm', MENGE: '120.000', MEINS: 'KG', NETPR: '95.00', NETWR: '11400.00', EINDT: '20261205' },
        { POSNR: '20', MATNR: 'CV-M8X40', MAKTX: 'Altıköşe cıvata M8×40 (çinko kaplı)', MENGE: '2500.000', MEINS: 'AD', NETPR: '1.60', NETWR: '4000.00', EINDT: '20261205' },
        { POSNR: '30', MATNR: 'RL-6204', MAKTX: 'Bilyalı rulman 6204-2RS', MENGE: '50.000', MEINS: 'AD', NETPR: '65.00', NETWR: '3250.00', EINDT: '20261205' }
      ],
      IV_NOTE: 'Malzemeler sertifikalı olarak ve paletli teslim edilecektir. Kısmi teslimat kabul edilmez.'
    });
}

// -------------------------------------------------------------------------------------------------
// 2. Certificate: landscape, frames, rotated text, seal and signature images, QR
// -------------------------------------------------------------------------------------------------
function certificate(z) {
  const s = sheet(z);
  const navy = '#1e3a5f', gold = '#c9a227';
  s.rect('zemin', 0, 0, 297, 210, '#fdfbf5');
  s.rect('cerceve_dis', 8, 8, 281, 194, '', { bw: 1.2, bc: navy });
  s.rect('cerceve_ic', 11.5, 11.5, 274, 187, '', { bw: 0.3, bc: gold });
  s.rect('yan_bant', 11.5, 11.5, 46, 187, navy);
  [[5, 5], [286, 5], [5, 199], [286, 199]].forEach(([x, y], i) => s.rect('kose_' + (i + 1), x, y, 6, 6, gold, { rot: 45 }));
  s.image('muhur', 16, 22, 37, 37, 'ZPDF_DEMO_SEAL');
  s.text('yan_baslik', -20.5, 123.5, 110, 9, 'BAŞARI SERTİFİKASI', { rot: -90, color: '#ffffff', size: 15, bold: true, align: 'center', valign: 'middle' });
  s.text('sertifika_no', 11.5, 186, 46, 5, 'No: {IS_CERT.CERT_NO}', { size: 8, color: '#e2e8f0', align: 'center' });

  s.image('logo', 66, 18, 50, 15, 'ZPDF_DEMO_LOGO');
  s.text('onur', 222, 30.5, 80, 9, 'ÜSTÜN BAŞARI', { rot: 45, bg: gold, color: '#ffffff', bold: true, size: 11, align: 'center', valign: 'middle', printIf: 'IS_CERT.HONORS' });
  s.text('baslik', 64, 40, 216, 16, 'BAŞARI SERTİFİKASI', { font: 'Times New Roman', size: 32, bold: true, color: navy, align: 'center' });
  s.line('baslik_cizgi', 146, 60, 52, 0.7, gold);
  s.text('giris', 64, 66, 216, 6, 'Bu belge, sayın', { size: 11, italic: true, color: '#64748b', align: 'center' });
  s.field('ad_soyad', 64, 74, 216, 14, 'IS_CERT.FULL_NAME', { font: 'Times New Roman', size: 28, bold: true, color: '#9a7b1a', align: 'center' });
  s.line('ad_cizgi', 104, 90, 136, 0.3, navy);
  s.text('metin_1', 64, 96, 216, 6, '{IS_CERT.START_DATE | D MMMM YYYY} - {IS_CERT.END_DATE | D MMMM YYYY} tarihleri arasında düzenlenen {IS_CERT.HOURS} saatlik', { size: 11, color: '#334155', align: 'center' });
  s.field('egitim', 64, 103, 216, 8, 'IS_CERT.COURSE', { size: 15, bold: true, color: navy, align: 'center' });
  s.text('metin_2', 64, 112.5, 216, 6, 'eğitimini başarıyla tamamlayarak bu sertifikayı almaya hak kazanmıştır.', { size: 11, color: '#334155', align: 'center' });

  s.rect('puan_kart', 66, 128, 42, 22, navy);
  s.text('puan_etiket', 66, 130.5, 42, 4, 'BAŞARI PUANI', { size: 7, bold: true, color: gold, align: 'center' });
  s.text('puan', 66, 136, 42, 11, '{IS_CERT.SCORE | #.##0,00}', { size: 20, bold: true, color: '#ffffff', align: 'center' });
  s.code('dogrulama_qr', 250, 126, 26, 26, 'qr', { bind: 'IS_CERT.VERIFY_URL' });
  s.text('dogrulama', 244, 153, 38, 4, 'Doğrulama kodu', { size: 7, color: '#64748b', align: 'center' });

  s.image('imza', 134, 150, 42, 14, 'ZPDF_DEMO_SIGN');
  s.line('egitmen_cizgi', 126, 166, 58, 0.3, navy);
  s.field('egitmen', 126, 167.5, 58, 5.5, 'IS_CERT.TRAINER', { size: 10, bold: true, align: 'center' });
  s.text('egitmen_unvan', 126, 173, 58, 4.5, 'Eğitmen', { size: 8, color: '#64748b', align: 'center' });
  s.line('mudur_cizgi', 198, 166, 58, 0.3, navy);
  s.field('mudur', 198, 167.5, 58, 5.5, 'IS_CERT.MANAGER', { size: 10, bold: true, align: 'center' });
  s.text('mudur_unvan', 198, 173, 58, 4.5, 'Genel Müdür', { size: 8, color: '#64748b', align: 'center' });
  s.text('yer_tarih', 66, 181, 110, 5.5, '{IS_CERT.CITY}, {IS_CERT.ISSUE_DATE | D MMMM YYYY}', { size: 9.5, color: '#334155' });

  return finish(z, 'ZPDF_DEMO_CERT', 'ZPDF Studio demo: başarı sertifikası (yatay, döndürülmüş metin, mühür, imza)',
    { size: 'A4', orientation: 'L', mt: 8, mr: 8, mb: 8, ml: 8 }, [['IS_CERT', 'ZPDF_S_DEMO_CERT']], s, {
      IS_CERT: { CERT_NO: 'SRT-2026-0147', FULL_NAME: 'Elif Kaya', COURSE: 'ABAP ile PDF Form Geliştirme', HOURS: 40, START_DATE: '20261102', END_DATE: '20261113', ISSUE_DATE: '20261121', TRAINER: 'Dr. Mehmet Aydın', MANAGER: 'Zeynep Arslan', CITY: 'Kayseri', SCORE: '94.50', VERIFY_URL: 'https://example.com/sertifika/SRT-2026-0147', HONORS: 'X' }
    });
}

// -------------------------------------------------------------------------------------------------
// 3. Event ticket: A5 landscape, photo, colour blocks, perforation, QR and Code 128
// -------------------------------------------------------------------------------------------------
function ticket(z) {
  const s = sheet(z);
  const night = '#0b1020', indigo = '#312e81';
  s.rect('zemin', 0, 0, 210, 148, night);
  s.rect('bilet', 8, 10, 194, 128, '#ffffff');
  s.image('afis', 8, 10, 140, 52, 'ZPDF_DEMO_BANNER', { fit: 'fill' });
  s.field('etkinlik', 14, 37, 128, 10.5, 'IS_TICKET.EVENT', { size: 20, bold: true, color: '#ffffff' });
  s.field('sanatci', 14, 49.5, 128, 6, 'IS_TICKET.ARTIST', { size: 11, color: '#fde68a' });
  s.text('vip', 126, 15, 16, 7, 'VIP', { bg: '#f59e0b', color: '#111827', bold: true, size: 10, align: 'center', valign: 'middle', printIf: 'IS_TICKET.VIP' });

  const label = (name, x, y, w, text) => s.text(name + '_etiket', x, y, w, 3.6, text, { size: 6.5, bold: true, color: '#64748b' });
  label('tarih', 14, 66, 80, 'TARİH');
  s.text('tarih', 14, 70, 82, 6, '{IS_TICKET.EVENT_DATE | D MMMM YYYY, dddd}', { size: 10.5, bold: true, color: '#0f172a' });
  label('kapi_acilis', 98, 66, 22, 'KAPI AÇILIŞ');
  s.text('kapi_acilis', 98, 70, 22, 6, '{IS_TICKET.DOORS | HH:mm}', { size: 10.5, bold: true, color: '#0f172a' });
  label('baslangic', 122, 66, 22, 'BAŞLANGIÇ');
  s.text('baslangic', 122, 70, 22, 6, '{IS_TICKET.START_TIME | HH:mm}', { size: 10.5, bold: true, color: '#0f172a' });
  label('mekan', 14, 80, 60, 'MEKAN');
  s.text('mekan', 14, 84, 130, 6, '{IS_TICKET.VENUE}, {IS_TICKET.CITY}', { size: 10.5, bold: true, color: '#0f172a' });

  [[14, 30, 'BLOK', 'IS_TICKET.BLOCK', 'blok'], [47, 22, 'SIRA', 'IS_TICKET.SEAT_ROW', 'sira'], [72, 22, 'KOLTUK', 'IS_TICKET.SEAT_NO', 'koltuk'], [97, 22, 'KAPI', 'IS_TICKET.GATE', 'kapi']].forEach(([x, w, text, bind, name]) => {
    s.rect(name + '_kart', x, 95, w, 24, '#eef2ff');
    s.text(name + '_etiket', x, 97.5, w, 3.6, text, { size: 6.5, bold: true, color: '#64748b', align: 'center' });
    s.field(name, x, 103, w, 11, bind, { size: 17, bold: true, color: indigo, align: 'center' });
  });
  label('fiyat', 123, 96, 22, 'FİYAT');
  s.text('fiyat', 123, 100, 23, 6, '{IS_TICKET.PRICE | #.##0,00}', { size: 10.5, bold: true, color: '#0f172a' });
  s.field('para_birimi', 123, 106, 23, 5, 'IS_TICKET.WAERS', { size: 9, color: '#475569' });
  label('sahip', 14, 123, 60, 'BİLET SAHİBİ');
  s.field('sahip', 14, 127, 80, 6, 'IS_TICKET.HOLDER', { size: 10.5, bold: true, color: '#0f172a' });
  label('kategori', 98, 123, 46, 'KATEGORİ');
  s.field('kategori', 98, 127, 46, 6, 'IS_TICKET.CATEGORY', { size: 10.5, bold: true, color: '#0f172a' });

  // perforation between the ticket and its stub
  s.ellipse('centik_ust', 143, 5, 10, 10, night);
  s.ellipse('centik_alt', 143, 133, 10, 10, night);
  for (let y = 19, i = 1; y <= 128; y += 5, i++) s.ellipse('delik_' + i, 147, y, 2, 2, night);

  s.text('kupon_baslik', 154, 14, 44, 5, 'GİRİŞ KUPONU', { size: 8, bold: true, color: '#64748b', align: 'center' });
  s.code('kupon_qr', 159, 22, 34, 34, 'qr', { text: 'ZPDF-TICKET:{IS_TICKET.TICKET_NO}' });
  s.text('bilet_no', 154, 58, 44, 5, 'No: {IS_TICKET.TICKET_NO}', { size: 8.5, bold: true, align: 'center' });
  s.line('kupon_cizgi', 156, 66, 40, 0.2, '#cbd5e1');
  s.text('kupon_koltuk', 152, 69, 48, 5, '{IS_TICKET.BLOCK} · Sıra {IS_TICKET.SEAT_ROW} · No {IS_TICKET.SEAT_NO}', { size: 8.5, bold: true, color: indigo, align: 'center' });
  s.text('kupon_tarih', 152, 75, 48, 5, '{IS_TICKET.EVENT_DATE | DD.MM.YYYY} · {IS_TICKET.START_TIME | HH:mm}', { size: 8, align: 'center' });
  s.code('kupon_barkod', 155, 86, 42, 18, 'code128', { bind: 'IS_TICKET.BARCODE' });
  s.text('kupon_not', 152, 124, 48, 9, 'Bu bilet tek girişliktir.\nGirişte kupon görevliye teslim edilir.', { size: 6.5, color: '#64748b', align: 'center' });

  return finish(z, 'ZPDF_DEMO_TICKET', 'ZPDF Studio demo: etkinlik bileti (A5 yatay, resim, renk blokları, QR ve Code 128)',
    { size: 'A5', orientation: 'L', mt: 5, mr: 5, mb: 5, ml: 5 }, [['IS_TICKET', 'ZPDF_S_DEMO_TICKET']], s, {
      IS_TICKET: { TICKET_NO: 'BLT-00482719', EVENT: 'Anadolu Senfoni Gecesi', ARTIST: 'Kayseri Filarmoni Orkestrası', VENUE: 'Kadir Has Kongre Merkezi', CITY: 'Kayseri', EVENT_DATE: '20261219', DOORS: '190000', START_TIME: '203000', BLOCK: 'B', SEAT_ROW: '12', SEAT_NO: '27', GATE: '3', HOLDER: 'Elif Kaya', CATEGORY: 'Parter', PRICE: '750.00', WAERS: 'TRY', VIP: 'X', BARCODE: 'BLT00482719' }
    });
}

// -------------------------------------------------------------------------------------------------
// 4. Delivery note: master page side band, address cards, three barcode types, long table
// -------------------------------------------------------------------------------------------------
function delivery(z) {
  const s = sheet(z);
  const teal = '#0f766e';
  s.rect('yan_serit', 0, 0, 6, 297, teal, { printOn: 'every' });
  s.image('logo', 14, 10, 52, 15.6, 'ZPDF_DEMO_LOGO');
  s.text('baslik', 100, 9, 98, 9, 'SEVK İRSALİYESİ', { size: 19, bold: true, color: teal, align: 'right' });
  s.text('irsaliye_no', 100, 19, 98, 6, 'No: {IS_DELIVERY.VBELN}', { size: 11, bold: true, color: '#0f172a', align: 'right' });
  s.text('sevk_tarihi', 100, 25.5, 98, 5, 'Sevk tarihi: {IS_DELIVERY.WADAT | D MMMM YYYY}', { size: 9, color: '#475569', align: 'right' });
  s.code('irsaliye_barkod', 138, 32, 60, 13, 'code128', { bind: 'IS_DELIVERY.VBELN', hr: false });

  [[14, 'GÖNDEREN', 'gonderen'], [110, 'ALICI', 'alici']].forEach(([x, title, name]) => {
    s.rect(name + '_kutu', x, 50, 88, 30, '#ffffff', { bw: 0.2, bc: '#99f6e4' });
    s.rect(name + '_baslik_zemin', x, 50, 88, 6, teal);
    s.text(name + '_baslik', x + 3, 51.2, 60, 4, title, { size: 7.5, bold: true, color: '#ffffff' });
  });
  s.text('gonderen_adi', 17, 58, 82, 5.5, COMPANY, { size: 10, bold: true });
  s.text('gonderen_adres', 17, 64, 82, 14, 'Organize Sanayi Bölgesi 5. Cad. No:12\nMelikgazi / Kayseri\nTel: 0352 000 00 00', { size: 8.5, color: '#334155' });
  s.field('alici_adi', 113, 58, 82, 5.5, 'IS_DELIVERY.SHIP_TO_NAME', { size: 10, bold: true });
  s.text('alici_adres', 113, 64, 82, 14, '{IS_DELIVERY.SHIP_TO_ADDR}\n{IS_DELIVERY.SHIP_TO_CITY}\nTel: {IS_DELIVERY.SHIP_TO_PHONE}', { size: 8.5, color: '#334155' });

  s.rect('sevk_serit', 14, 84, 184, 15, '#f0fdfa', { bw: 0.2, bc: '#99f6e4' });
  [[17, 40, 'TAŞIYICI', '{IS_DELIVERY.CARRIER}', 'tasiyici'], [58, 36, 'TAKİP NO', '{IS_DELIVERY.TRACKING}', 'takip_no'], [95, 24, 'PLAKA', '{IS_DELIVERY.PLATE}', 'plaka'],
    [120, 36, 'SÜRÜCÜ', '{IS_DELIVERY.DRIVER}', 'surucu'], [157, 14, 'KOLİ', '{IS_DELIVERY.PACKAGES}', 'koli'], [172, 25, 'BRÜT KG', '{IS_DELIVERY.GROSS_WEIGHT | #.##0,00}', 'brut']].forEach(([x, w, text, value, name]) => {
    s.text(name + '_etiket', x, 86, w, 3.6, text, { size: 6.5, bold: true, color: teal });
    s.text(name, x, 90.5, w, 6, value, { size: 9, bold: true, color: '#0f172a' });
  });
  s.text('ekspres', 14, 102, 26, 6, 'EKSPRES', { bg: '#dc2626', color: '#ffffff', bold: true, size: 8.5, align: 'center', valign: 'middle', printIf: 'IS_DELIVERY.EXPRESS' });
  s.text('kirilir', 43, 102, 38, 6, 'KIRILIR - DİKKAT', { bg: '#f59e0b', color: '#1f2937', bold: true, size: 8.5, align: 'center', valign: 'middle', printIf: 'IS_DELIVERY.FRAGILE' });

  s.table('kalemler', 14, 112, 184, 26, 'IT_ITEMS', [
    { title: 'Kalem', field: 'POSNR', w: 7 }, { title: 'Malzeme', field: 'MATNR', w: 15 }, { title: 'Tanım', field: 'MAKTX', w: 29 }, { title: 'EAN', field: 'EAN', w: 15 },
    { title: 'Parti', field: 'CHARG', w: 11 }, { title: 'Depo', field: 'LGORT', w: 7, align: 'center' }, { title: 'Miktar', field: 'LFIMG', w: 10, align: 'right', fmt: '#.##0' }, { title: 'Birim', field: 'MEINS', w: 6, align: 'center' }
  ], { hbg: teal, hfg: '#ffffff', zebra: '#f0fdfa', bc: '#ccfbf1', bw: 0.1, pad: 1.3 });

  s.text('toplam', 14, 142, 184, 6, 'Toplam {IS_DELIVERY.PACKAGES} koli · brüt {IS_DELIVERY.GROSS_WEIGHT | #.##0,00} kg', { size: 10, bold: true, color: teal, align: 'right' });
  s.code('sevk_birimi', 14, 152, 72, 24, 'itf14', { bind: 'IS_DELIVERY.GTIN14' });
  s.text('sevk_birimi_etiket', 14, 177, 72, 4, 'Sevk birimi (ITF-14)', { size: 7, color: '#64748b', align: 'center' });
  s.code('veri_matrisi', 94, 152, 24, 24, 'datamatrix', { text: '{IS_DELIVERY.VBELN};{IS_DELIVERY.TRACKING}' });
  s.text('veri_matrisi_etiket', 88, 177, 36, 4, 'DataMatrix', { size: 7, color: '#64748b', align: 'center' });
  s.rect('teslim_eden_kutu', 128, 150, 33, 26, '', { bw: 0.2, bc: '#94a3b8' });
  s.text('teslim_eden', 128, 151.5, 33, 4, 'Teslim eden', { size: 7, color: '#64748b', align: 'center' });
  s.rect('teslim_alan_kutu', 165, 150, 33, 26, '', { bw: 0.2, bc: '#94a3b8' });
  s.text('teslim_alan', 165, 151.5, 33, 4, 'Teslim alan (ad, imza)', { size: 7, color: '#64748b', align: 'center' });

  s.text('devam', 14, 7, 120, 5, 'İrsaliye {IS_DELIVERY.VBELN} (devam)', { size: 8, color: teal, printOn: 'notfirst' });
  s.text('altbilgi', 14, 283, 184, 5, COMPANY + ' · İrsaliye {IS_DELIVERY.VBELN} · Sayfa {currentPage} / {totalPages}', { size: 7.5, color: '#64748b', align: 'center', printOn: 'every' });

  return finish(z, 'ZPDF_DEMO_DELIVERY', 'ZPDF Studio demo: sevk irsaliyesi (ana sayfa nesneleri, Code 128, ITF-14, DataMatrix)',
    { size: 'A4', orientation: 'P', mt: 15, mr: 12, mb: 20, ml: 14 },
    [['IS_DELIVERY', 'ZPDF_S_DEMO_DELIVERY'], ['IT_ITEMS', 'ZPDF_TT_DEMO_DELIV_ITEMS']], s, {
      IS_DELIVERY: { VBELN: '8000456789', WADAT: '20261121', SHIP_TO_NAME: 'Ege Yapı Market A.Ş.', SHIP_TO_ADDR: 'Atatürk Organize Sanayi Bölgesi 10003 Sok. No:8', SHIP_TO_CITY: 'Çiğli / İzmir', SHIP_TO_PHONE: '0232 000 00 00', CARRIER: 'Anadolu Lojistik', TRACKING: 'AL2611210047', GTIN14: '1869000000001', PLATE: '38 ABC 123', DRIVER: 'Hasan Yılmaz', GROSS_WEIGHT: '486.500', PACKAGES: 12, EXPRESS: 'X', FRAGILE: 'X' },
      IT_ITEMS: [
        { POSNR: '10', MATNR: 'MT-5M-KLT', MAKTX: 'Şerit metre 5 m (kilitli)', EAN: '8690000000019', CHARG: 'P2611A', LGORT: '1000', LFIMG: '240.000', MEINS: 'AD' },
        { POSNR: '20', MATNR: 'DB-8MM-100', MAKTX: 'Plastik dübel 8 mm (100 lü kutu)', EAN: '8690000000026', CHARG: 'P2610C', LGORT: '1000', LFIMG: '60.000', MEINS: 'KT' },
        { POSNR: '30', MATNR: 'EL-IS-L', MAKTX: 'İş eldiveni nitril kaplı (L)', EAN: '8690000000033', CHARG: 'P2611B', LGORT: '2000', LFIMG: '500.000', MEINS: 'ÇFT' }
      ]
    });
}

// -------------------------------------------------------------------------------------------------
// 5. Payment order: one deep structure (table inside), check boxes, amount in words, stamp
// -------------------------------------------------------------------------------------------------
function payment(z) {
  const s = sheet(z);
  const red = '#7f1d1d';
  s.rect('ust_serit', 0, 0, 210, 5, red, { printOn: 'every' });
  s.image('logo', 15, 12, 52, 15.6, 'ZPDF_DEMO_LOGO');
  s.text('baslik', 105, 12, 90, 9, 'ÖDEME TALİMATI', { size: 18, bold: true, color: red, align: 'right' });
  s.text('talimat_no', 105, 22, 90, 5, 'Talimat no: {INPUT.ORDER_NO}', { size: 9.5, align: 'right' });
  s.text('talimat_tarihi', 105, 27.5, 90, 5, 'Tarih: {INPUT.ORDER_DATE | D MMMM YYYY}', { size: 9.5, align: 'right' });
  s.line('baslik_cizgi', 15, 36, 180, 0.4, red);
  s.field('banka', 15, 42, 150, 6, 'INPUT.BANK', { size: 12, bold: true });
  s.text('sube', 15, 48.5, 150, 5.5, "{INPUT.BRANCH} Şubesi Müdürlüğü'ne", { size: 10 });
  s.text('metin', 15, 58, 180, 20, 'Şirketimizin ({INPUT.COMPANY}, şirket kodu {INPUT.BUKRS}) şubeniz nezdindeki {INPUT.IBAN} numaralı {INPUT.WAERS} hesabından, aşağıda dökümü verilen {INPUT.ITEM_COUNT} adet ödemenin {INPUT.VALUE_DATE | D MMMM YYYY} valörü ile yapılmasını rica ederiz.', { size: 10, color: '#1f2937' });
  s.text('kanal_etiket', 15, 82.5, 28, 5, 'Ödeme kanalı:', { size: 9, bold: true });
  [[45, 'EFT', 'INPUT.EFT', 'eft'], [70, 'Havale', 'INPUT.HAVALE', 'havale'], [100, 'SWIFT', 'INPUT.SWIFT', 'swift']].forEach(([x, text, bind, name]) => {
    s.check(name, x, 82, 5, 5, bind, { color: red });
    s.text(name + '_etiket', x + 7, 82.5, 20, 5, text, { size: 9 });
  });

  s.table('odemeler', 15, 92, 180, 26, 'INPUT.ITEMS', [
    { title: 'Alıcı', field: 'RECEIVER', w: 24 }, { title: 'IBAN', field: 'RECEIVER_IBAN', w: 27 }, { title: 'Banka', field: 'RECEIVER_BANK', w: 15 },
    { title: 'Açıklama', field: 'SGTXT', w: 17 }, { title: 'Tutar', field: 'WRBTR', w: 12, align: 'right', fmt: '#.##0,00' }, { title: 'PB', field: 'WAERS', w: 5, align: 'center' }
  ], { hbg: red, hfg: '#ffffff', zebra: '#fef2f2', bc: '#fecaca', bw: 0.1, pad: 1.2, bsize: 8, hsize: 8.5 });

  s.rect('toplam_zemin', 105, 122, 90, 10, red);
  s.text('toplam_etiket', 108, 124.3, 26, 6, 'TOPLAM', { size: 9, bold: true, color: '#ffffff' });
  s.text('toplam', 134, 123.6, 58, 7, '{INPUT.TOTAL | #.##0,00} {INPUT.WAERS}', { size: 12, bold: true, color: '#ffffff', align: 'right' });
  s.text('yaziyla', 15, 134, 180, 5, 'Yalnız: {INPUT.TOTAL | WORDS:TRY|UPPER}', { size: 8, color: '#475569', align: 'right' });
  s.text('saygi', 15, 144, 60, 5, 'Saygılarımızla,', { size: 10 });
  s.field('sirket', 15, 149.5, 120, 5.5, 'INPUT.COMPANY', { size: 10, bold: true });
  s.image('imza', 22, 158, 40, 13.3, 'ZPDF_DEMO_SIGN');
  s.line('imza_1_cizgi', 15, 173, 55, 0.3, '#1f2937');
  s.field('imza_1', 15, 174.5, 55, 5, 'INPUT.SIGNER1', { size: 9, bold: true, align: 'center' });
  s.text('imza_1_unvan', 15, 179.5, 55, 4.5, 'Yetkili imza', { size: 7.5, color: '#64748b', align: 'center' });
  s.line('imza_2_cizgi', 80, 173, 55, 0.3, '#1f2937');
  s.field('imza_2', 80, 174.5, 55, 5, 'INPUT.SIGNER2', { size: 9, bold: true, align: 'center' });
  s.text('imza_2_unvan', 80, 179.5, 55, 4.5, 'Yetkili imza', { size: 7.5, color: '#64748b', align: 'center' });
  s.image('kase', 142, 152, 50, 30, 'ZPDF_DEMO_STAMP');

  s.text('altbilgi', 15, 283, 180, 5, 'Bu belge ZPDF Studio demo verisiyle üretilmiştir · Sayfa {currentPage} / {totalPages}', { size: 7.5, color: '#64748b', align: 'center', printOn: 'every' });

  return finish(z, 'ZPDF_DEMO_PAYMENT', 'ZPDF Studio demo: ödeme talimatı (iç içe tablo, onay kutuları, yazıyla tutar, kaşe)',
    { size: 'A4', orientation: 'P', mt: 15, mr: 15, mb: 20, ml: 15 }, [['INPUT', 'ZPDF_S_DEMO_PAYMENT']], s, {
      INPUT: {
        BUKRS: '1000', COMPANY: COMPANY, ORDER_NO: 'OT-2026-0318', ORDER_DATE: '20261121', VALUE_DATE: '20261124', BANK: 'Anadolu Ticaret Bankası A.Ş.', BRANCH: 'Kayseri Organize Sanayi',
        IBAN: 'TR00 0000 0000 0000 0000 0000 01', WAERS: 'TRY', TOTAL: '148750.00', ITEM_COUNT: 3, EFT: 'X', HAVALE: '', SWIFT: '', SIGNER1: 'Zeynep Arslan', SIGNER2: 'Murat Çelik',
        ITEMS: [
          { RECEIVER: 'Yıldız Metal San. ve Tic. Ltd. Şti.', RECEIVER_IBAN: 'TR00 0000 0000 0000 0000 0000 02', RECEIVER_BANK: 'Marmara Bank', SGTXT: 'Fatura FT-2026-1184', WRBTR: '22380.00', WAERS: 'TRY' },
          { RECEIVER: 'Anadolu Lojistik A.Ş.', RECEIVER_IBAN: 'TR00 0000 0000 0000 0000 0000 03', RECEIVER_BANK: 'Ege Bank', SGTXT: 'Kasım nakliye bedeli', WRBTR: '41370.00', WAERS: 'TRY' },
          { RECEIVER: 'Öztürk Enerji Dağıtım A.Ş.', RECEIVER_IBAN: 'TR00 0000 0000 0000 0000 0000 04', RECEIVER_BANK: 'Anadolu Ticaret Bankası', SGTXT: 'Ekim elektrik faturası', WRBTR: '85000.00', WAERS: 'TRY' }
        ]
      }
    });
}

export function forms(z) {
  return [order(z), certificate(z), ticket(z), delivery(z), payment(z)];
}

export const ASSETS = [
  { id: 'ZPDF_DEMO_LOGO', file: 'ZPDF_DEMO_LOGO.png', mime: 'image/png', description: 'ZPDF Studio demo: Nova Endüstri logosu' },
  { id: 'ZPDF_DEMO_SEAL', file: 'ZPDF_DEMO_SEAL.png', mime: 'image/png', description: 'ZPDF Studio demo: sertifika mührü' },
  { id: 'ZPDF_DEMO_SIGN', file: 'ZPDF_DEMO_SIGN.png', mime: 'image/png', description: 'ZPDF Studio demo: imza' },
  { id: 'ZPDF_DEMO_STAMP', file: 'ZPDF_DEMO_STAMP.png', mime: 'image/png', description: 'ZPDF Studio demo: onay kaşesi' },
  { id: 'ZPDF_DEMO_BANNER', file: 'ZPDF_DEMO_BANNER.jpg', mime: 'image/jpeg', description: 'ZPDF Studio demo: etkinlik afişi' }
];
