/* ZPDF Studio Designer 2 - conversion.
 *
 *  document  ->  form for ZCL_PDF_STUDIO_ENGINE + ZCL_PDF_STUDIO_BINDER
 *   - every object is an absolutely positioned <div> (mm, relative to the page margins),
 *   - tables are <table> blocks with a {{#each}} loop: they grow, break and repeat their header,
 *   - objects below the first table follow it (data-flow="after"),
 *   - a print rule makes an object a master page object (data-every),
 *   - a condition wraps the object in {{#if}} / {{^}},
 *   - the document itself travels in a leading comment so the form can be opened again,
 *   - the interface (parameter = DDIC type) travels in a second comment for the ABAP API.
 *
 *  pdfme template (forms saved by Studio 1)  ->  document (importPdfme).
 */

var STUDIO_MARK = '<!--zpdf-studio:';
var IFACE_MARK = '<!--zpdf-iface:';

var PAGE_TOKENS = {
  currentPage: '<span class="pageNumber"></span>',
  totalPages: '<span class="totalPages"></span>'
};

function mm(value) {
  return round2(value) + 'mm';
}

/**
 * Literal text -> HTML for the binder: {{...}} tags stay, {FIELD} and {FIELD | pattern} become
 * binder tags, {currentPage}/{totalPages} become page number spans, the rest is escaped.
 */
function bindText(text, used) {
  var out = '';
  var re = /\{\{\{[^{}]*\}\}\}|\{\{[^{}]*\}\}|\{([^{}]*)\}/g;
  var last = 0;
  var m;
  text = String(text === undefined || text === null ? '' : text);
  while ((m = re.exec(text)) !== null) {
    out += esc(text.slice(last, m.index));
    last = m.index + m[0].length;
    if (m[1] === undefined) {
      out += m[0];
      continue;
    }
    var parts = m[1].split('|');
    var key = parts.shift().trim();
    var pattern = parts.join('|').trim();
    if (PAGE_TOKENS[key] && !pattern) {
      out += PAGE_TOKENS[key];
    } else if (isPath(key)) {
      out += pattern ? '{{' + key + ' | ' + esc(pattern) + '}}' : '{{' + key + '}}';
      if (used) used[key] = true;
    } else {
      out += esc(m[0]);
    }
  }
  return out + esc(text.slice(last));
}

/** Placeholders used in a literal text: ["MUSTERI", "INPUT.TARIH"]. */
function placeholdersOf(text) {
  var used = {};
  bindText(text, used);
  return Object.keys(used);
}

function fontCss(family, ctx) {
  var name = String(family || ctx.doc.font.family || 'Arial').trim();
  var lower = name.toLowerCase();
  if (ctx.fonts[lower]) return "font-family:'" + lower + "';";
  if (lower.indexOf('times') >= 0) return "font-family:'Times New Roman';";
  if (lower.indexOf('courier') >= 0) return "font-family:'Courier New';";
  if (lower !== 'arial' && lower !== 'helvetica') {
    ctx.warn(T('Yazı tipi "' + name + '" varlık deposunda yok; Arial kullanılacak.', 'Font "' + name + '" is not in the asset store; Arial is used.'));
  }
  return 'font-family:Arial;';
}

function geometryCss(el, ctx) {
  var css = 'position:absolute;box-sizing:border-box;overflow:hidden;' +
    'left:' + mm(el.x - ctx.doc.page.ml) + ';top:' + mm(el.y - ctx.doc.page.mt) + ';' +
    'width:' + mm(el.w) + ';height:' + mm(el.h) + ';';
  if (num(el.rot)) css += 'transform:rotate(' + round2(el.rot) + 'deg);';
  var op = num(el.op, 1);
  if (op >= 0 && op < 1) css += 'opacity:' + round2(op) + ';';
  return css;
}

function textCss(el, ctx) {
  var css = fontCss(el.font, ctx) + 'font-size:' + (num(el.size) || 10) + 'pt;color:' + (el.color || '#000000') + ';' +
    'background:' + (el.bg || 'transparent') + ';text-align:' + (el.align || 'left') + ';' +
    'white-space:' + (el.wrap === false ? 'nowrap' : 'pre-wrap') + ';';
  if (el.bold) css += 'font-weight:bold;';
  if (el.italic) css += 'font-style:italic;';
  if (el.underline) css += 'text-decoration:underline;';
  if (el.valign === 'middle' || el.valign === 'bottom') css += 'vertical-align:' + el.valign + ';';
  if (num(el.bw) > 0) css += 'border-style:solid;border-width:' + mm(el.bw) + ';border-color:' + (el.bc || '#000000') + ';';
  if (num(el.pad) > 0) css += 'padding:' + mm(el.pad) + ';';
  return css;
}

function fieldTag(path, fmt) {
  fmt = String(fmt || '').trim();
  return fmt ? '{{' + path + ' | ' + esc(fmt) + '}}' : '{{' + path + '}}';
}

function everyAttr(el) {
  if (!el.printOn) return '';
  return ' data-every="' + (el.printOn === 'every' ? '1' : el.printOn) + '"';
}

function conditional(el, html, ctx) {
  var raw = String(el.printIf || '').trim();
  if (!raw || !html) return html;
  var negate = raw.charAt(0) === '!';
  var field = raw.replace(/^!/, '').trim();
  if (!isPath(field)) {
    ctx.warn('"' + el.name + '": ' + T('koşul alanı geçersiz; koşul dikkate alınmadı.', 'the condition field is invalid, the condition is ignored.'));
    return html;
  }
  ctx.use(field);
  return negate ? '{{^' + field + '}}' + html + '{{/' + field + '}}' : '{{#if ' + field + '}}' + html + '{{/if}}';
}

function convertElement(el, ctx, attrs) {
  var pos = geometryCss(el, ctx);
  var where = '"' + el.name + '" (' + typeLabel(el) + ')';
  var html = '';
  switch (el.type) {
    case 'text': {
      var body;
      if (el.bind) {
        ctx.use(el.bind);
        body = fieldTag(el.bind, el.fmt);
      } else {
        var used = {};
        body = bindText(el.text, used);
        Object.keys(used).forEach(ctx.use);
      }
      html = '<div' + attrs + ' style="' + pos + textCss(el, ctx) + '">' + body + '</div>';
      break;
    }
    case 'image': {
      var src;
      if (el.asset) {
        src = 'asset:' + String(el.asset).toUpperCase();
        if (!ctx.images[String(el.asset).toUpperCase()]) {
          ctx.warn(where + ': ' + T('varlık deposunda "' + el.asset + '" yok.', 'asset "' + el.asset + '" is not in the asset store.'));
        }
      } else if (el.bind) {
        ctx.use(el.bind);
        src = '{{' + el.bind + '}}';
      } else {
        ctx.warn(where + ': ' + T('resim kaynağı seçilmedi; nesne yazdırılmaz.', 'no image source selected, the object is not printed.'));
        return '';
      }
      html = '<div' + attrs + ' style="' + pos + '"><img src="' + src + '" style="object-fit:' + (el.fit || 'contain') + '"></div>';
      break;
    }
    case 'line':
      html = '<div' + attrs + ' style="' + pos + 'background:' + (el.color || '#000000') + ';"></div>';
      break;
    case 'rect':
    case 'ellipse': {
      var border = num(el.bw) > 0 ? 'border-style:solid;border-width:' + mm(el.bw) + ';border-color:' + (el.bc || '#000000') + ';' : '';
      html = '<div' + attrs + ' style="' + pos + 'background:' + (el.fill || 'transparent') + ';' + border +
        (el.type === 'ellipse' ? 'border-radius:50%;' : '') + '"></div>';
      break;
    }
    case 'checkbox': {
      if (!el.bind) {
        ctx.warn(where + ': ' + T('veri alanı bağlanmadı.', 'no data field bound.'));
        return '';
      }
      ctx.use(el.bind);
      var size = Math.max(6, Math.round(el.h * 2.2));
      html = '<div' + attrs + ' style="' + pos + 'border-style:solid;border-width:0.3mm;border-color:' + (el.color || '#000000') +
        ';font-family:Arial;font-size:' + size + 'pt;text-align:center;">{{#if ' + el.bind + '}}X{{/if}}</div>';
      break;
    }
    case 'barcode': {
      var value;
      if (el.bind) {
        ctx.use(el.bind);
        value = '{{' + el.bind + '}}';
      } else {
        var usedCode = {};
        value = bindText(el.text || '', usedCode);
        Object.keys(usedCode).forEach(ctx.use);
        if (!String(el.text || '').trim()) {
          ctx.warn(where + ': ' + T('barkod değeri veya veri alanı yok.', 'no barcode value or data field.'));
        }
      }
      var two = BARCODES[el.code] && BARCODES[el.code].two;
      var hr = !two && el.hr !== false ? ' data-hr="1"' : '';
      var ecc = el.code === 'qr' && el.ecc ? ' data-ecc="' + el.ecc + '"' : '';
      html = '<div' + attrs + ' data-code="' + el.code + '"' + hr + ecc + ' style="' + pos + 'color:' + (el.color || '#000000') +
        ';background:' + (el.bg || 'transparent') + ';font-family:Arial;font-size:8pt;">' + value + '</div>';
      break;
    }
    default:
      ctx.warn(where + ': ' + T('bu nesne tipi desteklenmiyor; atlandı.', 'this object type is not supported, skipped.'));
      return '';
  }
  return conditional(el, html, ctx);
}

function convertTable(el, ctx, marginTop) {
  var cols = el.cols || [];
  var total = cols.reduce(function (sum, c) { return sum + (num(c.w) || 0); }, 0) || 1;
  var border = num(el.bw) > 0 ? 'border:' + mm(el.bw) + ' solid ' + (el.bc || '#000000') + ';' : '';
  var pad = num(el.pad) > 0 ? 'padding:' + mm(el.pad) + ';' : '';
  var td = border + pad + 'vertical-align:middle;overflow:hidden;';
  var font = fontCss(el.font, ctx);
  var where = '"' + el.name + '" (' + T('tablo', 'table') + ')';

  if (!el.bind) {
    ctx.warn(where + ': ' + T('tablo bir arayüz tablosuna bağlanmadı; satır yazdırılmaz.', 'the table is not bound to an interface table; no rows are printed.'));
  } else {
    ctx.useTable(el.bind);
  }

  var colgroup = '<colgroup>' + cols.map(function (c) {
    return '<col style="width:' + mm(el.w * (num(c.w) || 0) / total) + '">';
  }).join('') + '</colgroup>';

  var thead = '';
  if (el.showHead !== false) {
    thead = '<thead style="display:table-header-group"><tr>' + cols.map(function (c) {
      return '<td style="' + td + 'background:' + (el.hbg || 'transparent') + ';"><div style="' + font + 'font-size:' + (num(el.hsize) || 9) +
        'pt;color:' + (el.hfg || '#000000') + ';text-align:' + (c.align || 'left') + ';' + (el.hbold === false ? '' : 'font-weight:bold;') + '">' +
        bindText(c.title) + '</div></td>';
    }).join('') + '</tr></thead>';
  }

  var plain = el.bbg || 'transparent';
  var bg = el.zebra && el.zebra !== el.bbg ? '{{#if ROW_EVEN}}' + el.zebra + '{{else}}' + plain + '{{/if}}' : plain;
  var cells = cols.map(function (c, i) {
    var tag = '';
    if (c.field) {
      tag = fieldTag(c.field, c.fmt);
      ctx.useRow(el.bind, c.field);
    } else {
      ctx.warn(where + ': ' + T((i + 1) + '. sütuna alan bağlanmadı.', 'column ' + (i + 1) + ' has no field.'));
    }
    return '<td style="' + td + 'background:' + bg + ';"><div style="' + font + 'font-size:' + (num(el.bsize) || 9) + 'pt;color:' +
      (el.bfg || '#000000') + ';text-align:' + (c.align || 'left') + ';">' + tag + '</div></td>';
  }).join('');

  var rows = el.bind ? '{{#each ' + el.bind + '}}<tr>' + cells + '</tr>{{/each}}' : '';
  var html = '<table style="margin-left:' + mm(el.x - ctx.doc.page.ml) + ';margin-top:' + mm(marginTop) + ';width:' + mm(el.w) +
    ';border-collapse:collapse;">' + colgroup + thead + '<tbody>' + rows + '</tbody></table>';
  return conditional(el, html, ctx);
}

// ---------------------------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------------------------

function sampleValue(node, name) {
  var t = node ? node.t : 'C';
  var len = node && node.l ? node.l : 20;
  if (t === 'D') {
    var d = new Date();
    return '' + d.getFullYear() + ('0' + (d.getMonth() + 1)).slice(-2) + ('0' + d.getDate()).slice(-2);
  }
  if (t === 'T') return '143000';
  if (t === 'P' || t === 'F' || t === 'a' || t === 'e') return 1234.56;
  if (t === 'I' || t === 'b' || t === 's' || t === '8') return 12;
  if (t === 'N') return '1'.padStart(Math.min(len, 6), '0');
  if (t === 'X' || t === 'y') return '';
  var text = '[' + name + ']';
  return len && text.length > len ? name.slice(0, len) : text;
}

/** Sample data built from the interface: every field, three rows per table. */
function sampleFromIface(doc) {
  function build(node, name) {
    if (node.k === 'E') return sampleValue(node, name);
    var obj = {};
    (node.c || []).forEach(function (child) { obj[child.n] = build(child, child.n); });
    if (node.k !== 'T') return obj;
    return [1, 2, 3].map(function (i) {
      var row = clone(obj);
      Object.keys(row).forEach(function (key) {
        if (typeof row[key] === 'number') row[key] = round2(row[key] * i);
      });
      return row;
    });
  }
  var sample = {};
  (doc.iface || []).forEach(function (param) {
    if (param.node) sample[param.name] = build(param.node, param.name);
  });
  return sample;
}

function setPath(target, path, value) {
  var parts = String(path).replace(/-/g, '.').split('.');
  var node = target;
  parts.forEach(function (part, i) {
    if (i === parts.length - 1) {
      if (!(part in node)) node[part] = value;
    } else {
      if (typeof node[part] !== 'object' || node[part] === null || Array.isArray(node[part])) node[part] = {};
      node = node[part];
    }
  });
}

function getPath(source, path) {
  var parts = String(path).replace(/-/g, '.').split('.');
  var node = source;
  for (var i = 0; i < parts.length; i++) {
    if (node === null || typeof node !== 'object') return undefined;
    node = node[parts[i]];
  }
  return node;
}

// ---------------------------------------------------------------------------------------------
// Public: convert
// ---------------------------------------------------------------------------------------------

function embedDoc(doc) {
  return STUDIO_MARK + toBase64(JSON.stringify(doc)) + '-->';
}

function extractDoc(html) {
  var start = String(html).indexOf(STUDIO_MARK);
  if (start < 0) return null;
  var end = html.indexOf('-->', start);
  if (end < 0) return null;
  return JSON.parse(fromBase64(html.slice(start + STUDIO_MARK.length, end)));
}

/**
 * @param doc     the document
 * @param options { fonts: ['roboto'], images: ['LOGO'] } - what the asset store holds
 * @returns { html, header, footer, css, page, sample, fields, warnings }
 */
function convert(doc, options) {
  options = options || {};
  var warnings = [];
  var fields = {};
  var sample = sampleFromIface(doc);
  var hasIface = (doc.iface || []).length > 0;
  var known = {};
  var knownTables = {};
  var knownRows = {};
  walkIface(doc, function (node, path, table) {
    if (table) knownRows[table + '>' + path] = true;
    else if (node.k === 'T') knownTables[path] = true;
    else known[path] = true;
  });

  var ctx = {
    doc: doc,
    fonts: {},
    images: {},
    warn: function (message) { if (warnings.indexOf(message) < 0) warnings.push(message); },
    use: function (path) {
      fields[path] = true;
      if (hasIface && !known[path] && !knownTables[path]) {
        ctx.warn(T('"' + path + '" arayüzde tanımlı değil.', '"' + path + '" is not defined in the interface.'));
      }
      if (getPath(sample, path) === undefined) setPath(sample, path, '[' + path.split('.').pop() + ']');
    },
    useTable: function (path) {
      fields[path] = true;
      if (hasIface && !knownTables[path]) {
        ctx.warn(T('Tablo "' + path + '" arayüzde tanımlı değil.', 'Table "' + path + '" is not defined in the interface.'));
      }
      if (!Array.isArray(getPath(sample, path))) {
        var holder = {};
        setPath(holder, path, [{}, {}, {}]);
        var parts = path.split('.');
        var node = sample;
        parts.forEach(function (part, i) {
          if (i === parts.length - 1) node[part] = [{}, {}, {}];
          else {
            if (typeof node[part] !== 'object' || node[part] === null) node[part] = {};
            node = node[part];
          }
        });
      }
    },
    useRow: function (tablePath, field) {
      if (!tablePath) return;
      if (hasIface && knownTables[tablePath] && !knownRows[tablePath + '>' + field]) {
        ctx.warn(T('"' + field + '", "' + tablePath + '" tablosunun satırında yok.', '"' + field + '" is not a row field of table "' + tablePath + '".'));
      }
      var rows = getPath(sample, tablePath);
      if (Array.isArray(rows)) {
        rows.forEach(function (row, i) {
          if (getPath(row, field) === undefined) setPath(row, field, '[' + field + ' ' + (i + 1) + ']');
        });
      }
    }
  };
  (options.fonts || []).forEach(function (f) { ctx.fonts[String(f).toLowerCase()] = true; });
  (options.images || []).forEach(function (id) { ctx.images[String(id).toUpperCase()] = true; });

  var dims = pageDims(doc.page);
  var body = '';
  var names = {};
  doc.pages.forEach(function (page, index) {
    var tables = page.els.filter(function (el) { return el.type === 'table' && !el.printOn; })
      .sort(function (a, b) { return a.y - b.y; });
    var firstTableTop = tables.length ? tables[0].y : Infinity;
    var master = [];
    var before = [];
    var after = [];
    page.els.forEach(function (el) {
      if (names[el.name]) ctx.warn(T('"' + el.name + '" adı birden fazla nesnede kullanılmış.', 'The name "' + el.name + '" is used by more than one object.'));
      names[el.name] = true;
      if (el.x + el.w < 0 || el.y + el.h < 0 || el.x > dims.w || el.y > dims.h) {
        ctx.warn(T('"' + el.name + '" sayfanın dışında.', '"' + el.name + '" is outside the page.'));
      }
      if (el.type === 'table') {
        if (el.printOn) ctx.warn(T('"' + el.name + '": tablolar ana sayfa nesnesi olamaz; basım kuralı yok sayıldı.', '"' + el.name + '": tables cannot be master page objects; the print rule is ignored.'));
        return;
      }
      // Master page objects are drawn on every sheet, under the content. Objects above the
      // first table stay where they are; objects below it follow the tables.
      if (el.printOn) master.push(convertElement(el, ctx, everyAttr(el)));
      else if (el.y >= firstTableTop) after.push(convertElement(el, ctx, ' data-flow="after"'));
      else before.push(convertElement(el, ctx, ''));
    });
    var flow = '';
    var lastBottom = doc.page.mt;
    page.els.filter(function (el) { return el.type === 'table'; })
      .sort(function (a, b) { return a.y - b.y; })
      .forEach(function (el, i) {
        if (i > 0) ctx.warn(T('Sayfa ' + (index + 1) + ': birden fazla tablo alt alta akar; aradaki boşluk yaklaşık korunur.', 'Page ' + (index + 1) + ': several tables flow one after the other; the gap is kept roughly.'));
        flow += convertTable(el, ctx, Math.max(0, el.y - lastBottom));
        lastBottom = el.y + el.h;
      });
    body += '<section>' + master.join('') + before.join('') + flow + after.join('') + '</section>';
  });

  var spec = ifaceSpec(doc);
  var html = embedDoc(doc) + (spec ? IFACE_MARK + spec + '-->' : '') + body;
  return {
    html: html,
    header: '',
    footer: '',
    css: '',
    page: {
      page_size: doc.page.size,
      orientation: doc.page.orientation,
      margin_top: Math.round(num(doc.page.mt)),
      margin_right: Math.round(num(doc.page.mr)),
      margin_bottom: Math.round(num(doc.page.mb)),
      margin_left: Math.round(num(doc.page.ml))
    },
    sample: sample,
    fields: Object.keys(fields).sort(),
    warnings: warnings
  };
}

// ---------------------------------------------------------------------------------------------
// Import: pdfme template of ZPDF Studio 1  ->  document
// ---------------------------------------------------------------------------------------------

function isPdfme(obj) {
  return !!obj && typeof obj === 'object' && obj.zpdf !== 2 && Array.isArray(obj.schemas);
}

function boxMax(value) {
  if (typeof value === 'number') return value;
  var v = value || {};
  return Math.max(v.top || 0, v.right || 0, v.bottom || 0, v.left || 0);
}

function datePatternOf(format) {
  return String(format).replace(/yyyy/g, 'YYYY').replace(/yy/g, 'YY').replace(/dd/g, 'DD')
    .replace(/(^|[^D])d(?!d)/g, '$1D').replace(/EEEE/g, 'dddd').replace(/EEE/g, 'ddd');
}

function importPdfme(template) {
  var doc = newDoc();
  var base = template.basePdf || {};
  if (typeof base.width === 'number' && typeof base.height === 'number') {
    var found = detectPage(base.width, base.height) || { size: 'A4', orientation: 'P' };
    var pad = base.padding || [0, 0, 0, 0];
    doc.page = { size: found.size, orientation: found.orientation, mt: Math.round(pad[0] || 0), mr: Math.round(pad[1] || 0), mb: Math.round(pad[2] || 0), ml: Math.round(pad[3] || 0) };
  }

  function textProps(s) {
    var family = String(s.fontName || '').trim();
    return {
      font: /^roboto$/i.test(family) ? '' : family,
      size: num(s.fontSize) || 10,
      color: s.fontColor || '#000000',
      bg: s.backgroundColor || '',
      align: s.alignment === 'center' || s.alignment === 'right' ? s.alignment : 'left',
      valign: s.verticalAlignment === 'middle' || s.verticalAlignment === 'bottom' ? s.verticalAlignment : 'top',
      underline: !!s.underline,
      bw: boxMax(s.borderWidth),
      bc: s.borderColor || '#000000',
      pad: boxMax(s.padding)
    };
  }

  function one(s, forceRule) {
    var common = {
      name: s.name, x: round2(s.position.x), y: round2(s.position.y), w: round2(s.width), h: round2(s.height),
      rot: num(s.rotate), op: s.opacity === undefined ? 1 : num(s.opacity, 1),
      printOn: s.printOn || forceRule || '', printIf: s.printIf || ''
    };
    var field = isPath(s.name) ? s.name : toFieldName(s.name);
    var code = { qrcode: 'qr', datamatrix: 'datamatrix', gs1datamatrix: 'datamatrix', code128: 'code128', ean13: 'ean13', ean8: 'ean8', upca: 'upca', code39: 'code39', itf14: 'itf14' }[s.type];
    switch (s.type) {
      case 'text':
        return defaultsFor('text', Object.assign(common, textProps(s), s.readOnly
          ? { text: String(s.content || '') }
          : { text: '', bind: field, fmt: String(s.abapFormat || '') }));
      case 'multiVariableText':
        return defaultsFor('text', Object.assign(common, textProps(s), { text: String(s.text || s.content || '') }));
      case 'date':
      case 'time':
      case 'dateTime': {
        var fallback = s.type === 'time' ? 'HH:mm' : s.type === 'dateTime' ? 'DD.MM.YYYY HH:mm' : 'DD.MM.YYYY';
        var fmt = String(s.abapFormat || '').trim() || (s.format ? datePatternOf(s.format) : fallback);
        return defaultsFor('text', Object.assign(common, textProps(s), { text: '', bind: field, fmt: fmt }));
      }
      case 'image':
      case 'signature':
        return defaultsFor('image', Object.assign(common, s.assetId ? { asset: String(s.assetId).toUpperCase() } : (s.readOnly ? {} : { bind: field })));
      case 'line':
        return defaultsFor('line', Object.assign(common, { color: s.color || '#000000' }));
      case 'rectangle':
      case 'ellipse':
        return defaultsFor(s.type === 'ellipse' ? 'ellipse' : 'rect', Object.assign(common, { fill: s.color || '', bw: num(s.borderWidth), bc: s.borderColor || '#000000' }));
      case 'checkbox':
        return defaultsFor('checkbox', Object.assign(common, { bind: field, color: s.color || '#000000' }));
      case 'table': {
        var head = (s.head || []).map(String);
        var spec = String(s.abapColumns || '');
        var parts = (spec.indexOf(';') >= 0 || spec.indexOf('|') >= 0 ? spec.split(';') : spec.split(','))
          .map(function (c) { return c.trim(); }).filter(Boolean);
        var pct = s.headWidthPercentages || head.map(function () { return 100 / Math.max(1, head.length); });
        var aligns = (s.columnStyles && s.columnStyles.alignment) || {};
        var hs = s.headStyles || {};
        var bs = s.bodyStyles || {};
        var ts = s.tableStyles || {};
        return defaultsFor('table', Object.assign(common, {
          bind: field,
          showHead: s.showHead !== false,
          cols: head.map(function (label, i) {
            var p = (parts[i] || '').split('|');
            var name = (p.shift() || '').trim();
            return { title: label, field: name || toFieldName(label || 'COL' + (i + 1)), w: round2(pct[i] || 0), align: aligns[i] || 'left', fmt: p.join('|').trim() };
          }),
          hbg: hs.backgroundColor || '', hfg: hs.fontColor || '#000000', hsize: num(hs.fontSize) || 9,
          bsize: num(bs.fontSize) || 9, bfg: bs.fontColor || '#000000', bbg: bs.backgroundColor || '',
          zebra: bs.alternateBackgroundColor || '',
          bw: boxMax(bs.borderWidth) || num(ts.borderWidth) || 0, bc: bs.borderColor || ts.borderColor || '#000000',
          pad: boxMax(bs.padding)
        }));
      }
      default:
        if (code) {
          return defaultsFor('barcode', Object.assign(common, { code: code, hr: s.includetext !== false, color: s.barColor || '#000000', bg: s.backgroundColor || '' },
            s.readOnly ? { text: String(s.content || '') } : { bind: field }));
        }
        return null;
    }
  }

  var statics = (base.staticSchema || []).map(function (s) { return one(Object.assign({ readOnly: true }, s), 'every'); });
  doc.pages = (template.schemas || []).map(function (page, index) {
    var list = Array.isArray(page) ? page : Object.keys(page).map(function (name) { return Object.assign({}, page[name], { name: name }); });
    var els = (index === 0 ? statics : []).concat(list.map(function (s) { return one(s, ''); })).filter(Boolean);
    return { name: '', els: els };
  });
  if (!doc.pages.length) doc.pages = [{ name: '', els: [] }];
  return normalizeDoc(doc);
}

/** Accepts a Studio 2 document or a pdfme template and always returns a document. */
function loadAny(obj) {
  if (isPdfme(obj)) return importPdfme(obj);
  return normalizeDoc(obj);
}
