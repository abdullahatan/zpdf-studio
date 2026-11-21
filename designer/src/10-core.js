/* ZPDF Studio Designer 2 - core: language, helpers, document model, history.
 * Everything lives in one shared scope (the build wraps all files in a single IIFE). */

var VERSION = '2.2.0';
var LANG = 'TR';

/** Bilingual text: T('Kaydet', 'Save'). The product has exactly two languages. */
function T(tr, en) {
  return LANG === 'EN' ? (en === undefined ? tr : en) : tr;
}

// ---------------------------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------------------------

function esc(text) {
  return String(text === undefined || text === null ? '' : text)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function round2(value) {
  return Math.round((Number(value) || 0) * 100) / 100;
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function num(value, fallback) {
  var n = parseFloat(String(value).replace(',', '.'));
  return isFinite(n) ? n : (fallback === undefined ? 0 : fallback);
}

function bytesToBase64(bytes) {
  var bin = '';
  for (var i = 0; i < bytes.length; i += 0x8000) {
    bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
  }
  return btoa(bin);
}

function base64ToBytes(b64) {
  var bin = atob(String(b64).replace(/\s+/g, ''));
  var bytes = new Uint8Array(bin.length);
  for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

function toBase64(text) {
  return bytesToBase64(new TextEncoder().encode(String(text)));
}

function fromBase64(b64) {
  return new TextDecoder().decode(base64ToBytes(b64));
}

/** "Birim fiyat (TL)" -> "BIRIM_FIYAT_TL": a name ABAP accepts as a component name. */
function toFieldName(label) {
  var map = { 'ç': 'C', 'Ç': 'C', 'ğ': 'G', 'Ğ': 'G', 'ı': 'I', 'İ': 'I', 'ö': 'O', 'Ö': 'O', 'ş': 'S', 'Ş': 'S', 'ü': 'U', 'Ü': 'U' };
  var ascii = String(label).split('').map(function (ch) { return map[ch] || ch; }).join('')
    .normalize('NFKD').replace(/[̀-ͯ]/g, '');
  var name = ascii.toUpperCase().replace(/[^A-Z0-9]+/g, '_').replace(/^_+|_+$/g, '');
  if (!name) return 'FIELD';
  return (/^[0-9]/.test(name) ? 'F_' + name : name).slice(0, 30);
}

function isPath(name) {
  return /^[A-Za-z_][A-Za-z0-9_\-.]*$/.test(String(name));
}

// ---------------------------------------------------------------------------------------------
// Pages
// ---------------------------------------------------------------------------------------------

var PAGE_SIZES = {
  A3: [297, 420], A4: [210, 297], A5: [148, 210], LETTER: [215.9, 279.4], LEGAL: [215.9, 355.6]
};

function pageDims(page) {
  var s = PAGE_SIZES[page.size] || PAGE_SIZES.A4;
  return page.orientation === 'L' ? { w: s[1], h: s[0] } : { w: s[0], h: s[1] };
}

function detectPage(width, height) {
  var found = null;
  Object.keys(PAGE_SIZES).forEach(function (key) {
    var s = PAGE_SIZES[key];
    if (Math.abs(s[0] - width) < 1 && Math.abs(s[1] - height) < 1) found = { size: key, orientation: 'P' };
    if (Math.abs(s[1] - width) < 1 && Math.abs(s[0] - height) < 1) found = { size: key, orientation: 'L' };
  });
  return found;
}

// ---------------------------------------------------------------------------------------------
// Object catalogue: palette groups, defaults per type
// ---------------------------------------------------------------------------------------------

var BARCODES = {
  qr: { tr: 'QR Kod', en: 'QR Code', two: true, sample: 'https://example.com/123' },
  datamatrix: { tr: 'DataMatrix', en: 'DataMatrix', two: true, sample: 'ZPDF-0001' },
  code128: { tr: 'Code 128', en: 'Code 128', sample: 'ZPDF-0001' },
  code39: { tr: 'Code 39', en: 'Code 39', sample: 'ZPDF0001' },
  ean13: { tr: 'EAN-13', en: 'EAN-13', sample: '8690000000019' },
  ean8: { tr: 'EAN-8', en: 'EAN-8', sample: '86900003' },
  upca: { tr: 'UPC-A', en: 'UPC-A', sample: '036000291452' },
  itf14: { tr: 'ITF-14', en: 'ITF-14', sample: '18690000000016' }
};

var PRINT_RULES = [
  ['', 'Gövde (normal akış)', 'Body (in the flow)'],
  ['every', 'Her sayfada', 'Every page'],
  ['first', 'Yalnızca ilk sayfada', 'First page only'],
  ['notfirst', 'İlk sayfa hariç', 'All but the first page'],
  ['last', 'Yalnızca son sayfada', 'Last page only'],
  ['notlast', 'Son sayfa hariç', 'All but the last page'],
  ['odd', 'Tek sayfalarda', 'Odd pages'],
  ['even', 'Çift sayfalarda', 'Even pages']
];

/** Format presets offered in the binding tab, by ABAP type kind. */
var FORMAT_PRESETS = {
  D: ['DD.MM.YYYY', 'D MMMM YYYY', 'D MMMM YYYY, dddd', 'DD/MM/YYYY', 'YYYY-MM-DD', 'MMMM YYYY', 'SAP'],
  T: ['HH:mm', 'HH:mm:ss'],
  N: ['#.##0,00', '#.##0', '#,##0.00', '0,00', '#.##0,00;(#.##0,00)', 'SAP', 'WORDS:TRY', 'WORDS:TRY|UPPER', 'WORDS:USD', 'WORDS:EUR'],
  C: ['UPPER', 'LOWER', 'TITLE', 'ALPHA', 'TRIM']
};

function formatGroup(abapType) {
  if (abapType === 'D') return 'D';
  if (abapType === 'T') return 'T';
  if ('PIFbs8ae'.indexOf(abapType) >= 0 && abapType) return 'N';
  return 'C';
}

var TEXT_DEFAULTS = {
  text: '', bind: '', fmt: '', font: '', size: 10, bold: false, italic: false, underline: false,
  color: '#000000', bg: '', align: 'left', valign: 'top', wrap: true, pad: 0, bw: 0, bc: '#000000'
};

function defaultsFor(type, extra) {
  var base = { type: type, x: 20, y: 20, w: 50, h: 6, rot: 0, op: 1, printOn: '', printIf: '', locked: false };
  var spec;
  switch (type) {
    case 'text':
      spec = Object.assign({}, TEXT_DEFAULTS, { text: T('Metin', 'Text') });
      break;
    case 'table':
      spec = {
        w: 170, h: 24, bind: '', font: '', showHead: true,
        cols: [
          { title: T('Sütun 1', 'Column 1'), field: '', w: 34, align: 'left', fmt: '' },
          { title: T('Sütun 2', 'Column 2'), field: '', w: 33, align: 'left', fmt: '' },
          { title: T('Sütun 3', 'Column 3'), field: '', w: 33, align: 'right', fmt: '' }
        ],
        hbg: '#1d4e89', hfg: '#ffffff', hsize: 9, hbold: true,
        bsize: 9, bfg: '#000000', bbg: '', zebra: '#f3f6fa', bw: 0.1, bc: '#9aa5b1', pad: 1
      };
      break;
    case 'image':
      spec = { w: 40, h: 20, asset: '', bind: '', fit: 'contain' };
      break;
    case 'line':
      spec = { w: 80, h: 0.3, color: '#000000' };
      break;
    case 'rect':
      spec = { w: 50, h: 25, fill: '', bw: 0.3, bc: '#000000' };
      break;
    case 'ellipse':
      spec = { w: 30, h: 30, fill: '', bw: 0.3, bc: '#000000' };
      break;
    case 'checkbox':
      spec = { w: 5, h: 5, bind: '', color: '#000000' };
      break;
    case 'barcode':
      spec = { w: 50, h: 18, code: 'code128', bind: '', text: '', hr: true, ecc: 'M', color: '#000000', bg: '' };
      break;
    default:
      spec = {};
  }
  var el = Object.assign(base, spec, extra || {});
  if (el.type === 'barcode' && BARCODES[el.code] && BARCODES[el.code].two && !(extra && extra.w)) {
    el.w = 25;
    el.h = 25;
  }
  return el;
}

/**
 * Palette: groups of objects. Every item creates an element of a base type with a few preset
 * properties, so "Tarih alanı" and "Sayfa numarası" are just preconfigured text objects.
 */
function paletteGroups() {
  var codes = Object.keys(BARCODES).map(function (code) {
    return { id: 'bc_' + code, icon: BARCODES[code].two ? 'qr' : 'barcode', label: T(BARCODES[code].tr, BARCODES[code].en), type: 'barcode', props: { code: code } };
  });
  return [
    {
      id: 'std', label: T('Standart', 'Standard'), items: [
        { id: 'text', icon: 'text', label: T('Metin', 'Text'), type: 'text', props: {} },
        { id: 'field', icon: 'field', label: T('Veri alanı', 'Data field'), type: 'text', props: { text: '', needBind: true } },
        { id: 'para', icon: 'para', label: T('Paragraf', 'Paragraph'), type: 'text', props: { w: 120, h: 24, text: T('Çok satırlı metin. {ALAN} yazarak veri alanı ekleyebilirsiniz.', 'Multi-line text. Type {FIELD} to insert a data field.') } },
        { id: 'table', icon: 'table', label: T('Tablo', 'Table'), type: 'table', props: {} },
        { id: 'image', icon: 'image', label: T('Resim / Logo', 'Image / Logo'), type: 'image', props: {} },
        { id: 'checkbox', icon: 'check', label: T('Onay kutusu', 'Check box'), type: 'checkbox', props: {} }
      ]
    },
    {
      id: 'fields', label: T('Özel alanlar', 'Special fields'), items: [
        { id: 'date', icon: 'date', label: T('Tarih alanı', 'Date field'), type: 'text', props: { text: '', fmt: 'DD.MM.YYYY', needBind: true } },
        { id: 'amount', icon: 'amount', label: T('Tutar alanı', 'Amount field'), type: 'text', props: { text: '', fmt: '#.##0,00', align: 'right', needBind: true } },
        { id: 'words', icon: 'words', label: T('Yazıyla tutar', 'Amount in words'), type: 'text', props: { w: 120, text: '', fmt: 'WORDS:TRY|UPPER', needBind: true } },
        { id: 'pageno', icon: 'pageno', label: T('Sayfa numarası', 'Page number'), type: 'text', props: { w: 40, text: T('Sayfa {currentPage} / {totalPages}', 'Page {currentPage} / {totalPages}'), printOn: 'every', align: 'right', size: 8 } },
        { id: 'watermark', icon: 'water', label: T('Filigran', 'Watermark'), type: 'text', props: { w: 140, h: 30, text: T('TASLAK', 'DRAFT'), size: 64, color: '#d00000', op: 0.15, rot: -35, align: 'center', printOn: 'every' } }
      ]
    },
    {
      id: 'shapes', label: T('Şekiller', 'Shapes'), items: [
        { id: 'line', icon: 'line', label: T('Çizgi', 'Line'), type: 'line', props: {} },
        { id: 'vline', icon: 'vline', label: T('Dikey çizgi', 'Vertical line'), type: 'line', props: { w: 0.3, h: 40 } },
        { id: 'rect', icon: 'rect', label: T('Dikdörtgen', 'Rectangle'), type: 'rect', props: {} },
        { id: 'ellipse', icon: 'ellipse', label: T('Elips', 'Ellipse'), type: 'ellipse', props: {} }
      ]
    },
    { id: 'codes', label: T('Barkodlar', 'Barcodes'), items: codes }
  ];
}

function typeLabel(el) {
  switch (el.type) {
    case 'text': return el.bind ? T('Veri alanı', 'Data field') : T('Metin', 'Text');
    case 'table': return T('Tablo', 'Table');
    case 'image': return T('Resim', 'Image');
    case 'line': return T('Çizgi', 'Line');
    case 'rect': return T('Dikdörtgen', 'Rectangle');
    case 'ellipse': return T('Elips', 'Ellipse');
    case 'checkbox': return T('Onay kutusu', 'Check box');
    case 'barcode': return (BARCODES[el.code] ? T(BARCODES[el.code].tr, BARCODES[el.code].en) : T('Barkod', 'Barcode'));
    default: return el.type;
  }
}

function typeIcon(el) {
  if (el.type === 'text') return el.bind ? 'field' : 'text';
  if (el.type === 'barcode') return BARCODES[el.code] && BARCODES[el.code].two ? 'qr' : 'barcode';
  if (el.type === 'checkbox') return 'check';
  return el.type;
}

// ---------------------------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------------------------

function newDoc() {
  return {
    zpdf: 2,
    description: '',
    page: { size: 'A4', orientation: 'P', mt: 15, mr: 12, mb: 15, ml: 12 },
    grid: 1,
    font: { family: 'Arial', size: 10 },
    iface: [],
    pages: [{ name: '', els: [] }],
    sample: '',
    seq: 0
  };
}

/** Repairs a loaded document so that the rest of the code can rely on every property. */
function normalizeDoc(doc) {
  var base = newDoc();
  doc = Object.assign(base, doc || {});
  doc.zpdf = 2;
  doc.page = Object.assign({ size: 'A4', orientation: 'P', mt: 15, mr: 12, mb: 15, ml: 12 }, doc.page || {});
  doc.font = Object.assign({ family: 'Arial', size: 10 }, doc.font || {});
  if (!Array.isArray(doc.iface)) doc.iface = [];
  if (!Array.isArray(doc.pages) || !doc.pages.length) doc.pages = [{ name: '', els: [] }];
  var seen = {};
  doc.pages.forEach(function (page) {
    if (!Array.isArray(page.els)) page.els = [];
    page.els = page.els.filter(function (el) { return el && el.type; }).map(function (el) {
      var full = Object.assign(defaultsFor(el.type), el);
      if (!full.id || seen[full.id]) full.id = 'e' + (++doc.seq);
      seen[full.id] = true;
      var n = parseInt(String(full.id).slice(1), 10);
      if (isFinite(n) && n > doc.seq) doc.seq = n;
      if (full.type === 'table' && !Array.isArray(full.cols)) full.cols = [];
      return full;
    });
  });
  return doc;
}

function allElements(doc) {
  var list = [];
  doc.pages.forEach(function (page) { page.els.forEach(function (el) { list.push(el); }); });
  return list;
}

function uniqueName(doc, base) {
  var names = {};
  allElements(doc).forEach(function (el) { names[el.name] = true; });
  if (!names[base]) return base;
  for (var i = 2; ; i++) {
    if (!names[base + '_' + i]) return base + '_' + i;
  }
}

function baseName(el) {
  if (el.bind) return el.bind.split('.').pop();
  switch (el.type) {
    case 'text': return T('metin', 'text');
    case 'table': return T('tablo', 'table');
    case 'image': return el.asset ? 'logo_' + el.asset.toLowerCase() : T('resim', 'image');
    case 'line': return T('cizgi', 'line');
    case 'rect': return T('kutu', 'box');
    case 'ellipse': return T('elips', 'ellipse');
    case 'checkbox': return T('onay', 'check');
    case 'barcode': return el.code || 'barcode';
    default: return el.type;
  }
}

// ---------------------------------------------------------------------------------------------
// Interface tree (resolved DDIC types): nodes { n, k: S|T|E, t, l, dec, d, c: [] }
// ---------------------------------------------------------------------------------------------

/** Calls fn(node, path, tableContext) for every node; tableContext is the path of the nearest table. */
function walkIface(doc, fn) {
  function visit(node, path, table) {
    fn(node, path, table);
    var inner = node.k === 'T' ? path : table;
    (node.c || []).forEach(function (child) {
      // Fields of a table row are addressed relative to the row inside {{#each}}.
      visit(child, node.k === 'T' ? child.n : path + '.' + child.n, inner);
    });
  }
  (doc.iface || []).forEach(function (param) {
    if (param.node) visit(Object.assign({}, param.node, { n: param.name }), param.name, '');
  });
}

/** Finds the node of an absolute path ("INPUT.ITEMS") or of a row field ("ALICI" within a table). */
function findNode(doc, path, tablePath) {
  var found = null;
  walkIface(doc, function (node, p, table) {
    if (found) return;
    if (tablePath) {
      if (table === tablePath && p === path && node.k !== 'T') found = node;
    } else if (!table && p === path) {
      found = node;
    }
  });
  return found;
}

function tableNodes(doc) {
  var list = [];
  walkIface(doc, function (node, path, table) {
    if (node.k === 'T' && !table) list.push({ path: path, node: node });
  });
  return list;
}

function scalarPaths(doc) {
  var list = [];
  walkIface(doc, function (node, path, table) {
    if (node.k === 'E' && !table) list.push({ path: path, node: node });
  });
  return list;
}

function rowFields(doc, tablePath) {
  var list = [];
  walkIface(doc, function (node, path, table) {
    if (node.k === 'E' && table === tablePath) list.push({ path: path, node: node });
  });
  return list;
}

/** "INPUT=ZPDF_S_INPUT;ITEMS=ZPDF_TT_ITEMS": read by the ABAP API to map the caller's data. */
function ifaceSpec(doc) {
  return (doc.iface || []).map(function (p) { return p.name + '=' + (p.type || ''); }).join(';');
}

// ---------------------------------------------------------------------------------------------
// History (undo / redo): snapshots of the serialized document
// ---------------------------------------------------------------------------------------------

function History(limit) {
  this.limit = limit || 100;
  this.stack = [];
  this.index = -1;
}

History.prototype.reset = function (doc) {
  this.stack = [JSON.stringify(doc)];
  this.index = 0;
};

History.prototype.push = function (doc) {
  var snap = JSON.stringify(doc);
  if (this.stack[this.index] === snap) return false;
  this.stack = this.stack.slice(0, this.index + 1);
  this.stack.push(snap);
  if (this.stack.length > this.limit) this.stack.shift();
  this.index = this.stack.length - 1;
  return true;
};

History.prototype.canUndo = function () { return this.index > 0; };
History.prototype.canRedo = function () { return this.index < this.stack.length - 1; };
History.prototype.undo = function () { return this.canUndo() ? JSON.parse(this.stack[--this.index]) : null; };
History.prototype.redo = function () { return this.canRedo() ? JSON.parse(this.stack[++this.index]) : null; };
