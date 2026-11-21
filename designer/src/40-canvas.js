/* ZPDF Studio Designer 2 - icons and the design surface (page, objects, selection, rulers). */

var ICONS = {
  text: 'M3 4h10M8 4v9',
  field: 'M2 5h12v6H2zM5 7v2',
  para: 'M3 4h10M3 7h10M3 10h10M3 13h6',
  table: 'M2 3h12v10H2zM2 6.5h12M2 10h12M6 3v10M10 3v10',
  image: 'M2 3h12v10H2zM2 11l3.5-3.5 3 3 2-2L14 11M5.2 6.2h.6',
  check: 'M3 3h10v10H3zM5 8l2 2 4-4.5',
  date: 'M2.5 4h11v9.5h-11zM2.5 7h11M5 2.5v3M11 2.5v3',
  amount: 'M5 13V3h3.5a2.5 2.5 0 0 1 0 5H5M3.5 10.5h5',
  words: 'M2 12l3-8 3 8M3.2 9.5h3.6M10 6h4M10 9h4M10 12h4',
  pageno: 'M4 2h6l3 3v9H4zM10 2v3h3M6.5 11h4',
  water: 'M8 2.5c2.5 3 4 5 4 7a4 4 0 0 1-8 0c0-2 1.5-4 4-7z',
  line: 'M2 8h12',
  vline: 'M8 2v12',
  rect: 'M2.5 4h11v8h-11z',
  ellipse: 'M8 3.5c3 0 5.5 2 5.5 4.5S11 12.5 8 12.5 2.5 10.5 2.5 8 5 3.5 8 3.5z',
  qr: 'M2.5 2.5h4v4h-4zM9.5 2.5h4v4h-4zM2.5 9.5h4v4h-4zM9.5 9.5h1.5v1.5H9.5zM12 12h1.5v1.5H12zM12 9.5h1.5M9.5 12.5h1',
  barcode: 'M2.5 3v10M4.5 3v10M6 3v10M8.5 3v10M10 3v10M12 3v10M13.5 3v10',
  struct: 'M2 3h5v3H2zM9 10h5v3H9zM4.5 6v5.5H9',
  elem: 'M3.5 5.5h9v5h-9z',
  right: 'M6 3l5 5-5 5',
  down: 'M3 6l5 5 5-5',
  close: 'M4 4l8 8M12 4l-8 8',
  lock: 'M4.5 7.5h7v6h-7zM6 7.5V5.5a2 2 0 0 1 4 0v2',
  save: 'M3 2.5h8l2 2v9H3zM5 2.5v4h5v-4M5 13.5v-4h6v4',
  pdf: 'M4 2h6l3 3v9H4zM10 2v3h3M6 9h4M6 11.5h4',
  undo: 'M5 3.5L2 6.5l3 3M2 6.5h7.5a3.5 3.5 0 0 1 0 7H7',
  redo: 'M11 3.5l3 3-3 3M14 6.5H6.5a3.5 3.5 0 0 0 0 7H9',
  warn: 'M8 2.5l6 11H2zM8 6.5v3.5M8 11.8v.4',
  plus: 'M8 3v10M3 8h10',
  minus: 'M3 8h10',
  page: 'M4 2h6l3 3v9H4zM10 2v3h3',
  master: 'M2.5 3h11v10h-11zM2.5 6h11',
  search: 'M7 2.5a4.5 4.5 0 1 0 0 9 4.5 4.5 0 0 0 0-9zM10.5 10.5l3 3',
  trash: 'M3 4.5h10M6 4.5V3h4v1.5M4.5 4.5l.7 9h5.6l.7-9',
  up: 'M8 13V3M4 7l4-4 4 4',
  dn: 'M8 3v10M4 9l4 4 4-4',
  link: 'M6.5 9.5l3-3M5 8L3.5 9.5a2.1 2.1 0 0 0 3 3L8 11M11 8l1.5-1.5a2.1 2.1 0 0 0-3-3L8 5',
  form: 'M3 2.5h10v11H3zM5.5 5.5h5M5.5 8h5M5.5 10.5h3',
  fit: 'M2.5 6V2.5H6M10 2.5h3.5V6M13.5 10v3.5H10M6 13.5H2.5V10',
  transport: 'M1.5 5h8v6h-8zM9.5 7h3l2 2v2h-5M4 12.5h.5M11.5 12.5h.5',
  refresh: 'M13 8a5 5 0 1 1-1.5-3.5M13 3v2.5h-2.5',
  iface: 'M2 4h5M2 8h5M2 12h5M9 4l5 4-5 4z',
  theme: 'M2 3.5h12v9H2zM2 6h12',
  sun: 'M8 5.2a2.8 2.8 0 1 0 0 5.6 2.8 2.8 0 0 0 0-5.6zM8 1.5v1.6M8 12.9v1.6M1.5 8h1.6M12.9 8h1.6M3.4 3.4l1.1 1.1M11.5 11.5l1.1 1.1M3.4 12.6l1.1-1.1M11.5 4.5l1.1-1.1',
  moon: 'M13 9.5A5.5 5.5 0 0 1 6.5 3a5.5 5.5 0 1 0 6.5 6.5z'
};

/** Sets the content of a node only when it changed (keeps the nodes under the mouse alive). */
function setHtml(node, html) {
  if (!node || (node.zpdfHtml === html && node.firstChild)) return;
  node.innerHTML = html;
  node.zpdfHtml = html;
}

function icon(name, cls) {
  return '<svg class="ic ' + (cls || '') + '" viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"><path d="' +
    (ICONS[name] || ICONS.elem) + '"/></svg>';
}

function cssFont(name) {
  var n = String(name || S.doc.font.family || 'Arial');
  var lower = n.toLowerCase();
  if (lower.indexOf('times') >= 0) return "'Times New Roman',Times,serif";
  if (lower.indexOf('courier') >= 0) return "'Courier New',Courier,monospace";
  if (lower === 'arial' || lower === 'helvetica') return 'Arial,Helvetica,sans-serif';
  return "'" + lower.replace(/'/g, '') + "',Arial,sans-serif";
}

/** Deterministic pseudo random numbers, so a placeholder barcode does not flicker. */
function seeded(seed) {
  var s = 0;
  for (var i = 0; i < seed.length; i++) s = (s * 31 + seed.charCodeAt(i)) >>> 0;
  return function () {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

function barcodeSvg(el) {
  var rnd = seeded(el.code + (el.bind || el.text || ''));
  var color = el.color || '#000000';
  var out = '';
  if (BARCODES[el.code] && BARCODES[el.code].two) {
    var n = el.code === 'qr' ? 25 : 18;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        var on = rnd() > 0.5;
        if (el.code === 'qr') {
          var corner = (x < 7 && y < 7) || (x >= n - 7 && y < 7) || (x < 7 && y >= n - 7);
          if (corner) {
            var cx = x < 7 ? x : x - (n - 7);
            var cy = y < 7 ? y : y - (n - 7);
            on = cx === 0 || cx === 6 || cy === 0 || cy === 6 || (cx >= 2 && cx <= 4 && cy >= 2 && cy <= 4);
          }
        } else {
          on = x === 0 || y === n - 1 || (y === 0 && x % 2 === 0) || (x === n - 1 && y % 2 === 1) || on;
        }
        if (on) out += '<rect x="' + x + '" y="' + y + '" width="1.03" height="1.03"/>';
      }
    }
    return '<svg viewBox="0 0 ' + n + ' ' + n + '" preserveAspectRatio="xMidYMid meet" fill="' + color + '" style="width:100%;height:100%;display:block">' + out + '</svg>';
  }
  var pos = 0;
  while (pos < 100) {
    var w = 1 + Math.floor(rnd() * 3);
    out += '<rect x="' + pos + '" y="0" width="' + w + '" height="10"/>';
    pos += w + 1 + Math.floor(rnd() * 3);
  }
  var hr = el.hr !== false;
  return '<svg viewBox="0 0 100 10" preserveAspectRatio="none" fill="' + color + '" style="width:100%;height:' + (hr ? '78%' : '100%') + ';display:block">' + out + '</svg>' +
    (hr ? '<div class="bc-hr">' + esc(el.bind ? '{' + el.bind + '}' : (el.text || BARCODES[el.code].sample)) + '</div>' : '');
}

var Canvas = {
  drag: null,
  guides: [],

  px: function () { return 96 / 25.4 * S.zoom; },
  page: function () { return S.doc.pages[S.pageIndex] || S.doc.pages[0]; },
  paper: function () { return document.getElementById('paper'); },

  // -------------------------------------------------------------------------------------------
  // Rendering
  // -------------------------------------------------------------------------------------------

  boxStyle: function (el) {
    var px = this.px();
    var style = 'left:' + el.x * px + 'px;top:' + el.y * px + 'px;width:' + Math.max(el.w * px, 1) + 'px;height:' + Math.max(el.h * px, 1) + 'px;';
    if (num(el.rot)) style += 'transform:rotate(' + num(el.rot) + 'deg);';
    return style;
  },

  /** Text shown for a bound field: the sample value when "show sample data" is on. */
  fieldText: function (path, fmt, row) {
    if (S.view.sample) {
      var value = row ? getPath(row, path) : undefined;
      if (value === undefined) value = getPath(App.sample(), path);
      if (value !== undefined && typeof value !== 'object') return esc(String(value));
    }
    return '<span class="tag">{' + esc(path) + (fmt ? ' | ' + esc(fmt) : '') + '}</span>';
  },

  staticText: function (text) {
    var html = '';
    var re = /\{([^{}]*)\}/g;
    var last = 0;
    var m;
    text = String(text || '');
    while ((m = re.exec(text)) !== null) {
      html += esc(text.slice(last, m.index));
      last = m.index + m[0].length;
      var key = m[1].split('|')[0].trim();
      if (key === 'currentPage') html += S.view.sample ? '1' : '<span class="tag">#</span>';
      else if (key === 'totalPages') html += S.view.sample ? '1' : '<span class="tag">##</span>';
      else if (isPath(key)) html += Canvas.fieldText(key, m[1].split('|').slice(1).join('|').trim());
      else html += esc(m[0]);
    }
    return html + esc(text.slice(last));
  },

  inner: function (el) {
    var px = this.px();
    var pt = 96 / 72 * S.zoom;
    switch (el.type) {
      case 'text': {
        var style = 'font-family:' + cssFont(el.font) + ';font-size:' + (num(el.size) || 10) * pt + 'px;color:' + (el.color || '#000') + ';' +
          'background:' + (el.bg || 'transparent') + ';text-align:' + (el.align || 'left') + ';' +
          'white-space:' + (el.wrap === false ? 'nowrap' : 'pre-wrap') + ';' +
          (el.bold ? 'font-weight:bold;' : '') + (el.italic ? 'font-style:italic;' : '') + (el.underline ? 'text-decoration:underline;' : '') +
          (num(el.bw) > 0 ? 'border:' + Math.max(num(el.bw) * px, 1) + 'px solid ' + (el.bc || '#000') + ';' : '') +
          (num(el.pad) > 0 ? 'padding:' + num(el.pad) * px + 'px;' : '') +
          'justify-content:' + (el.valign === 'middle' ? 'center' : el.valign === 'bottom' ? 'flex-end' : 'flex-start') + ';';
        var body = el.bind ? this.fieldText(el.bind, el.fmt)
          : el.text ? this.staticText(el.text) : '<span class="tag dimtag">' + esc(T('(veri alanı seçin)', '(choose a data field)')) + '</span>';
        return '<div class="t" style="' + style + '"><div class="ti">' + body + '</div></div>';
      }
      case 'table': {
        var cols = el.cols || [];
        var total = cols.reduce(function (s, c) { return s + (num(c.w) || 0); }, 0) || 1;
        var bw = num(el.bw) > 0 ? Math.max(num(el.bw) * px, 1) + 'px solid ' + (el.bc || '#000') : '0';
        var pad = num(el.pad) * px;
        var font = 'font-family:' + cssFont(el.font) + ';';
        var rows = S.view.sample && el.bind ? getPath(App.sample(), el.bind) : null;
        if (!Array.isArray(rows) || !rows.length) rows = [null, null];
        var html = '<table style="' + font + '"><colgroup>' + cols.map(function (c) { return '<col style="width:' + (num(c.w) || 0) / total * 100 + '%">'; }).join('') + '</colgroup>';
        if (el.showHead !== false) {
          html += '<tr>' + cols.map(function (c) {
            return '<td style="border:' + bw + ';padding:' + pad + 'px;background:' + (el.hbg || 'transparent') + ';color:' + (el.hfg || '#000') + ';font-size:' +
              (num(el.hsize) || 9) * pt + 'px;text-align:' + (c.align || 'left') + ';' + (el.hbold === false ? '' : 'font-weight:bold;') + '">' + Canvas.staticText(c.title) + '</td>';
          }).join('') + '</tr>';
        }
        rows.slice(0, 6).forEach(function (row, r) {
          var bg = r % 2 === 1 && el.zebra ? el.zebra : (el.bbg || 'transparent');
          html += '<tr>' + cols.map(function (c) {
            return '<td style="border:' + bw + ';padding:' + pad + 'px;background:' + bg + ';color:' + (el.bfg || '#000') + ';font-size:' + (num(el.bsize) || 9) * pt +
              'px;text-align:' + (c.align || 'left') + ';">' + (c.field ? Canvas.fieldText(c.field, c.fmt, row) : '&nbsp;') + '</td>';
          }).join('') + '</tr>';
        });
        return html + '</table><div class="flowmark" title="' + esc(T('Tablo veriye göre uzar ve sayfalara bölünür', 'The table grows with the data and breaks across pages')) + '">' +
          icon('dn') + ' ' + esc(el.bind || T('tablo bağlanmadı', 'table not bound')) + '</div>';
      }
      case 'image': {
        var asset = el.asset ? App.asset(el.asset) : null;
        if (asset) return '<img draggable="false" src="data:' + (asset.mime || 'image/png') + ';base64,' + asset.data + '" style="object-fit:' + (el.fit || 'contain') + '">';
        return '<div class="ph">' + icon('image') + '<span>' + esc(el.asset ? el.asset + ' ?' : el.bind ? '{' + el.bind + '}' : T('Resim seçin', 'Choose an image')) + '</span></div>';
      }
      case 'line':
        return '<div style="width:100%;height:100%;background:' + (el.color || '#000') + '"></div>';
      case 'rect':
      case 'ellipse':
        return '<div style="width:100%;height:100%;box-sizing:border-box;background:' + (el.fill || 'transparent') + ';' +
          (num(el.bw) > 0 ? 'border:' + Math.max(num(el.bw) * px, 1) + 'px solid ' + (el.bc || '#000') + ';' : '') +
          (el.type === 'ellipse' ? 'border-radius:50%;' : '') + '"></div>';
      case 'checkbox':
        return '<div class="cb" style="border-color:' + (el.color || '#000') + ';color:' + (el.color || '#000') + ';font-size:' + el.h * px * 0.8 + 'px">X</div>';
      case 'barcode':
        return '<div class="bc" style="background:' + (el.bg || 'transparent') + ';font-size:' + 7 * pt + 'px">' + barcodeSvg(el) + '</div>';
      default:
        return '';
    }
  },

  render: function () {
    var paper = this.paper();
    if (!paper) return;
    var px = this.px();
    var dims = pageDims(S.doc.page);
    var p = S.doc.page;
    paper.style.width = dims.w * px + 'px';
    paper.style.height = dims.h * px + 'px';
    var grid = 5 * px;
    paper.style.backgroundImage = S.view.grid ? 'radial-gradient(circle,#b9c3cf 0.7px,transparent 0.9px)' : 'none';
    paper.style.backgroundSize = grid + 'px ' + grid + 'px';
    var html = '';
    if (S.view.margins) {
      html += '<div class="margins" style="left:' + p.ml * px + 'px;top:' + p.mt * px + 'px;width:' + (dims.w - p.ml - p.mr) * px + 'px;height:' + (dims.h - p.mt - p.mb) * px + 'px"></div>';
    }
    this.page().els.forEach(function (el) {
      html += '<div class="el el-' + el.type + (el.printOn ? ' is-master' : '') + (el.locked ? ' is-locked' : '') + '" data-id="' + el.id + '" style="' +
        Canvas.boxStyle(el) + (num(el.op, 1) < 1 ? 'opacity:' + num(el.op, 1) + ';' : '') + '">' + Canvas.inner(el) + '</div>';
    });
    html += '<div id="overlay"></div>';
    paper.innerHTML = html;
    this.renderOverlay();
    this.drawRulers();
    var nav = document.getElementById('pageNav');
    if (nav) {
      nav.innerHTML = '<button data-act="pagePrev" title="' + esc(T('Önceki sayfa', 'Previous page')) + '">‹</button><span>' + T('Sayfa', 'Page') + ' ' + (S.pageIndex + 1) + ' / ' + S.doc.pages.length +
        '</span><button data-act="pageNext" title="' + esc(T('Sonraki sayfa', 'Next page')) + '">›</button><button data-act="pageAdd" title="' + esc(T('Yeni tasarım sayfası', 'New design page')) + '">+</button>' +
        (S.doc.pages.length > 1 ? '<button data-act="pageDel" title="' + esc(T('Bu sayfayı sil', 'Delete this page')) + '">−</button>' : '');
    }
  },

  renderOverlay: function () {
    var overlay = document.getElementById('overlay');
    if (!overlay) return;
    var px = this.px();
    var html = '';
    var sel = App.selected().filter(function (el) { return Canvas.page().els.indexOf(el) >= 0; });
    sel.forEach(function (el) {
      html += '<div class="selbox' + (el.locked ? ' locked' : '') + '" style="' + Canvas.boxStyle(el) + '">';
      if (sel.length === 1 && !el.locked && App.canEdit()) {
        var handles = ['nw', 'n', 'ne', 'e', 'se', 's', 'sw', 'w'];
        if (el.type === 'line') handles = el.w >= el.h ? ['w', 'e'] : ['n', 's'];
        handles.forEach(function (h) { html += '<div class="handle h-' + h + '" data-h="' + h + '"></div>'; });
        if (el.type === 'table') {
          var total = (el.cols || []).reduce(function (s, c) { return s + (num(c.w) || 0); }, 0) || 1;
          var acc = 0;
          (el.cols || []).slice(0, -1).forEach(function (c, i) {
            acc += num(c.w) || 0;
            html += '<div class="colgrip" data-col="' + i + '" style="left:' + acc / total * 100 + '%"></div>';
          });
        }
      }
      html += '</div>';
    });
    this.guides.forEach(function (g) {
      html += g.x !== undefined
        ? '<div class="guide gv" style="left:' + g.x * px + 'px"></div>'
        : '<div class="guide gh" style="top:' + g.y * px + 'px"></div>';
    });
    if (this.drag && this.drag.mode === 'marquee' && this.drag.rect) {
      var r = this.drag.rect;
      html += '<div class="marquee" style="left:' + r.x * px + 'px;top:' + r.y * px + 'px;width:' + r.w * px + 'px;height:' + r.h * px + 'px"></div>';
    }
    overlay.innerHTML = html;
  },

  drawRulers: function () {
    var paper = this.paper();
    var px = this.px();
    var dims = pageDims(S.doc.page);
    var sel = App.selected();
    // The rulers are drawn, not styled: their colours come from the theme variables.
    var css = window.getComputedStyle(document.documentElement);
    var ink = function (name, fallback) { return css.getPropertyValue(name).trim() || fallback; };
    var cSel = ink('--rulersel', '#dbe7f5');
    var cTick = ink('--rulertick', '#7b8794');
    var cText = ink('--rulerink', '#52606d');
    ['rulerH', 'rulerV'].forEach(function (id) {
      var cv = document.getElementById(id);
      if (!cv || !paper) return;
      var horizontal = id === 'rulerH';
      var box = cv.getBoundingClientRect();
      var ratio = window.devicePixelRatio || 1;
      cv.width = Math.max(1, Math.round(box.width * ratio));
      cv.height = Math.max(1, Math.round(box.height * ratio));
      var g = cv.getContext('2d');
      g.scale(ratio, ratio);
      g.clearRect(0, 0, box.width, box.height);
      if (!S.view.rulers) return;
      var pb = paper.getBoundingClientRect();
      var origin = horizontal ? pb.left - box.left : pb.top - box.top;
      var length = horizontal ? dims.w : dims.h;
      var size = horizontal ? box.height : box.width;
      g.fillStyle = cSel;
      sel.forEach(function (el) {
        if (horizontal) g.fillRect(origin + el.x * px, 0, el.w * px, size);
        else g.fillRect(0, origin + el.y * px, size, el.h * px);
      });
      g.strokeStyle = cTick;
      g.fillStyle = cText;
      g.font = '9px Segoe UI,Arial,sans-serif';
      g.lineWidth = 1;
      g.beginPath();
      for (var m = 0; m <= length; m++) {
        var big = m % 10 === 0;
        var mid = m % 5 === 0;
        if (!big && !mid && px < 3) continue;
        var pos = Math.round(origin + m * px) + 0.5;
        var len = big ? size : mid ? 6 : 3;
        if (horizontal) { g.moveTo(pos, size); g.lineTo(pos, size - len); }
        else { g.moveTo(size, pos); g.lineTo(size - len, pos); }
        if (big && (px >= 1.6 || m % 50 === 0)) {
          if (horizontal) g.fillText(String(m), pos + 2, 9);
          else { g.save(); g.translate(9, pos + 2); g.rotate(-Math.PI / 2); g.fillText(String(m), -g.measureText(String(m)).width, 0); g.restore(); }
        }
      }
      g.stroke();
    });
  },

  // -------------------------------------------------------------------------------------------
  // Zoom
  // -------------------------------------------------------------------------------------------

  /** Zoom levels of the page; the buttons and the wheel step through them, so 100 % is always reachable. */
  ZOOM_STEPS: [0.25, 0.33, 0.5, 0.67, 0.75, 0.9, 1, 1.1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4],

  /**
   * Zoom of the page only - the tools keep their size.
   * @param anchor optional mouse event: the point under the pointer stays where it is
   */
  setZoom: function (zoom, anchor) {
    var scroller = document.getElementById('scroller');
    var before = anchor && this.paper() ? this.toMm(anchor) : null;
    S.zoom = clamp(Math.round(zoom * 100) / 100, 0.25, 4);
    this.render();
    if (before && scroller) {
      var box = this.paper().getBoundingClientRect();
      var px = this.px();
      scroller.scrollLeft += box.left + before.x * px - anchor.clientX;
      scroller.scrollTop += box.top + before.y * px - anchor.clientY;
      this.drawRulers();
    }
    App.renderChrome();
    App.uiChanged();
  },

  /** One step in (direction 1) or out (-1) on the fixed levels. */
  stepZoom: function (direction, anchor) {
    var steps = this.ZOOM_STEPS;
    var next = S.zoom;
    var i;
    if (direction > 0) {
      for (i = 0; i < steps.length; i++) { if (steps[i] > S.zoom + 0.005) { next = steps[i]; break; } }
    } else {
      for (i = steps.length - 1; i >= 0; i--) { if (steps[i] < S.zoom - 0.005) { next = steps[i]; break; } }
    }
    if (next !== S.zoom) this.setZoom(next, anchor);
  },

  fit: function (mode) {
    var scroller = document.getElementById('scroller');
    if (!scroller || !scroller.clientWidth) return;
    var dims = pageDims(S.doc.page);
    var base = 96 / 25.4;
    var zw = (scroller.clientWidth - 60) / (dims.w * base);
    var zh = (scroller.clientHeight - 60) / (dims.h * base);
    this.setZoom(mode === 'width' ? zw : Math.min(zw, zh));
  },

  // -------------------------------------------------------------------------------------------
  // Pointer interaction: select, move, resize, marquee, column widths
  // -------------------------------------------------------------------------------------------

  toMm: function (ev) {
    var box = this.paper().getBoundingClientRect();
    var px = this.px();
    return { x: (ev.clientX - box.left) / px, y: (ev.clientY - box.top) / px };
  },

  snapValue: function (value) {
    var grid = num(S.doc.grid) || 1;
    return S.view.snapGrid ? Math.round(value / grid) * grid : value;
  },

  /** Snap lines of the page and of the objects that do not move. */
  snapLines: function (moving) {
    var dims = pageDims(S.doc.page);
    var p = S.doc.page;
    var xs = [0, p.ml, dims.w / 2, dims.w - p.mr, dims.w];
    var ys = [0, p.mt, dims.h / 2, dims.h - p.mb, dims.h];
    this.page().els.forEach(function (el) {
      if (moving.indexOf(el) >= 0) return;
      xs.push(el.x, el.x + el.w / 2, el.x + el.w);
      ys.push(el.y, el.y + el.h / 2, el.y + el.h);
    });
    return { xs: xs, ys: ys };
  },

  nearest: function (values, lines, tolerance) {
    var best = null;
    values.forEach(function (v) {
      lines.forEach(function (line) {
        var d = line - v;
        if (Math.abs(d) <= tolerance && (!best || Math.abs(d) < Math.abs(best.d))) best = { d: d, line: line };
      });
    });
    return best;
  },

  onDown: function (ev) {
    if (ev.button !== 0) return;
    var target = ev.target;
    if (target.closest && target.closest('.inline-edit')) return;
    var handle = target.closest('.handle');
    var grip = target.closest('.colgrip');
    var node = target.closest('.el');
    var start = this.toMm(ev);
    var sel = App.selected();

    if (grip && sel.length === 1) {
      var tbl = sel[0];
      this.drag = { mode: 'col', el: tbl, col: Number(grip.dataset.col), start: start, widths: tbl.cols.map(function (c) { return num(c.w) || 0; }) };
    } else if (handle && sel.length === 1) {
      var el = sel[0];
      this.drag = { mode: 'resize', el: el, h: handle.dataset.h, start: start, orig: { x: el.x, y: el.y, w: el.w, h: el.h } };
    } else if (node) {
      var id = node.dataset.id;
      if (ev.shiftKey || ev.ctrlKey) {
        var ids = S.sel.slice();
        var at = ids.indexOf(id);
        if (at >= 0) ids.splice(at, 1); else ids.push(id);
        App.select(ids);
      } else if (S.sel.indexOf(id) < 0) {
        App.select([id]);
      }
      var moving = App.selected().filter(function (e) { return !e.locked; });
      if (App.canEdit() && moving.length && S.sel.indexOf(id) >= 0) {
        this.drag = {
          mode: 'move', start: start, moved: false, els: moving,
          orig: moving.map(function (e) { return { x: e.x, y: e.y }; }),
          lines: this.snapLines(moving)
        };
      }
    } else if (target.closest('#paper') || target.id === 'pad' || target.id === 'scroller') {
      if (!ev.shiftKey) App.select([]);
      this.drag = { mode: 'marquee', start: start, rect: null, base: ev.shiftKey ? S.sel.slice() : [] };
    } else {
      return;
    }
    ev.preventDefault();
    if (document.activeElement && document.activeElement.blur && document.activeElement !== document.body) document.activeElement.blur();
  },

  onMove: function (ev) {
    var d = this.drag;
    if (!d) return;
    var pos = this.toMm(ev);
    var dx = pos.x - d.start.x;
    var dy = pos.y - d.start.y;
    var px = this.px();
    this.guides = [];

    if (d.mode === 'move') {
      if (!d.moved && Math.abs(dx) * px < 3 && Math.abs(dy) * px < 3) return;
      d.moved = true;
      var first = d.orig[0];
      var nx = this.snapValue(first.x + dx);
      var ny = this.snapValue(first.y + dy);
      dx = nx - first.x;
      dy = ny - first.y;
      if (S.view.snapObj && !ev.altKey) {
        var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        d.els.forEach(function (el, i) {
          minX = Math.min(minX, d.orig[i].x + dx); maxX = Math.max(maxX, d.orig[i].x + dx + el.w);
          minY = Math.min(minY, d.orig[i].y + dy); maxY = Math.max(maxY, d.orig[i].y + dy + el.h);
        });
        var tol = 4 / px;
        var sx = this.nearest([minX, (minX + maxX) / 2, maxX], d.lines.xs, tol);
        var sy = this.nearest([minY, (minY + maxY) / 2, maxY], d.lines.ys, tol);
        if (sx) { dx += sx.d; this.guides.push({ x: sx.line }); }
        if (sy) { dy += sy.d; this.guides.push({ y: sy.line }); }
      }
      d.els.forEach(function (el, i) {
        el.x = round2(d.orig[i].x + dx);
        el.y = round2(d.orig[i].y + dy);
        var node = Canvas.paper().querySelector('.el[data-id="' + el.id + '"]');
        if (node) { node.style.left = el.x * px + 'px'; node.style.top = el.y * px + 'px'; }
      });
      this.renderOverlay();
      App.status(T('Konum', 'Position') + ': ' + d.els[0].x + ' × ' + d.els[0].y + ' mm');
    } else if (d.mode === 'resize') {
      var o = d.orig;
      var left = o.x, top = o.y, right = o.x + o.w, bottom = o.y + o.h;
      var thin = d.el.type === 'line' ? 0.1 : 1;
      if (d.h.indexOf('w') >= 0) left = Math.min(this.snapValue(o.x + dx), right - thin);
      if (d.h.indexOf('e') >= 0) right = Math.max(this.snapValue(o.x + o.w + dx), left + thin);
      if (d.h.indexOf('n') >= 0) top = Math.min(this.snapValue(o.y + dy), bottom - thin);
      if (d.h.indexOf('s') >= 0) bottom = Math.max(this.snapValue(o.y + o.h + dy), top + thin);
      if (ev.shiftKey && d.h.length === 2 && o.w > 0 && o.h > 0) {
        var ratio = o.w / o.h;
        var w = right - left;
        var h = w / ratio;
        if (d.h.indexOf('n') >= 0) top = bottom - h; else bottom = top + h;
      }
      d.el.x = round2(left); d.el.y = round2(top); d.el.w = round2(right - left); d.el.h = round2(bottom - top);
      d.changed = true;
      this.render();
      App.status(T('Boyut', 'Size') + ': ' + d.el.w + ' × ' + d.el.h + ' mm');
    } else if (d.mode === 'col') {
      var total = d.widths.reduce(function (s, v) { return s + v; }, 0) || 1;
      var delta = dx / d.el.w * total;
      var a = d.widths[d.col] + delta;
      var b = d.widths[d.col + 1] - delta;
      var min = total * 0.03;
      if (a < min) { b -= min - a; a = min; }
      if (b < min) { a -= min - b; b = min; }
      d.el.cols[d.col].w = round2(a);
      d.el.cols[d.col + 1].w = round2(b);
      d.changed = true;
      this.render();
    } else if (d.mode === 'marquee') {
      d.rect = { x: Math.min(d.start.x, pos.x), y: Math.min(d.start.y, pos.y), w: Math.abs(dx), h: Math.abs(dy) };
      this.renderOverlay();
    }
  },

  onUp: function () {
    var d = this.drag;
    if (!d) return;
    this.drag = null;
    this.guides = [];
    if (d.mode === 'marquee') {
      if (d.rect && (d.rect.w > 0.5 || d.rect.h > 0.5)) {
        var r = d.rect;
        var ids = d.base.slice();
        this.page().els.forEach(function (el) {
          var hit = el.x < r.x + r.w && el.x + el.w > r.x && el.y < r.y + r.h && el.y + el.h > r.y;
          if (hit && ids.indexOf(el.id) < 0) ids.push(el.id);
        });
        App.select(ids);
      } else {
        this.renderOverlay();
      }
      return;
    }
    if ((d.mode === 'move' && d.moved) || d.changed) App.commit();
    else this.renderOverlay();
  },

  // -------------------------------------------------------------------------------------------
  // Inline text editing
  // -------------------------------------------------------------------------------------------

  editText: function (el) {
    if (!App.canEdit() || el.locked || el.type !== 'text' || el.bind) return;
    var paper = this.paper();
    var px = this.px();
    var area = document.createElement('textarea');
    area.className = 'inline-edit';
    area.value = el.text || '';
    area.style.cssText = this.boxStyle(el) + 'font-family:' + cssFont(el.font) + ';font-size:' + (num(el.size) || 10) * 96 / 72 * S.zoom + 'px;text-align:' + (el.align || 'left') + ';' +
      (el.bold ? 'font-weight:bold;' : '') + (el.italic ? 'font-style:italic;' : '') + 'min-height:' + Math.max(el.h * px, 22) + 'px;';
    paper.appendChild(area);
    area.focus();
    area.select();
    var done = false;
    function finish(save) {
      if (done) return;
      done = true;
      var value = area.value;
      area.remove();
      if (save && value !== (el.text || '')) {
        el.text = value;
        App.commit();
      }
    }
    area.addEventListener('blur', function () { finish(true); });
    area.addEventListener('keydown', function (ev) {
      ev.stopPropagation();
      if (ev.key === 'Escape') finish(false);
      if (ev.key === 'Enter' && (ev.ctrlKey || el.wrap === false)) { ev.preventDefault(); finish(true); }
    });
  },

  // -------------------------------------------------------------------------------------------
  // Setup
  // -------------------------------------------------------------------------------------------

  init: function () {
    var self = this;
    var area = document.getElementById('canvasArea');
    area.addEventListener('mousedown', function (ev) { self.onDown(ev); });
    document.addEventListener('mousemove', function (ev) { self.onMove(ev); });
    document.addEventListener('mouseup', function () { self.onUp(); });
    document.getElementById('scroller').addEventListener('scroll', function () { self.drawRulers(); });
    window.addEventListener('resize', function () { self.drawRulers(); });

    area.addEventListener('dblclick', function (ev) {
      var node = ev.target.closest('.el');
      if (!node) return;
      var el = App.el(node.dataset.id);
      if (!el) return;
      if (el.type === 'text' && !el.bind) self.editText(el);
      else App.showObjectTab('bind');
    });

    area.addEventListener('contextmenu', function (ev) {
      var node = ev.target.closest('.el');
      if (node && S.sel.indexOf(node.dataset.id) < 0) App.select([node.dataset.id]);
      ev.preventDefault();
      Menus.context(ev.clientX, ev.clientY);
    });

    area.addEventListener('dragover', function (ev) {
      if (App.canEdit()) { ev.preventDefault(); ev.dataTransfer.dropEffect = 'copy'; }
    });
    area.addEventListener('drop', function (ev) {
      ev.preventDefault();
      var raw = ev.dataTransfer.getData('text/plain');
      if (!raw || raw.indexOf('zpdf:') !== 0) return;
      var pos = self.toMm(ev);
      try {
        App.dropped(JSON.parse(raw.slice(5)), pos.x, pos.y);
      } catch (err) { /* not ours */ }
    });

    // Alt + wheel or Ctrl + wheel over the page zooms the page. Ctrl + wheel anywhere else is
    // swallowed: the browser would shrink or enlarge the whole designer with its tools.
    document.addEventListener('wheel', function (ev) {
      if (!ev.ctrlKey && !ev.altKey) return;
      var onPage = !!(ev.target.closest && ev.target.closest('#canvasArea'));
      if (ev.ctrlKey || onPage) ev.preventDefault();
      if (onPage && S.tab === 'layout' && ev.deltaY !== 0) self.stepZoom(ev.deltaY < 0 ? 1 : -1, ev);
    }, { passive: false });

    document.getElementById('pageNav').addEventListener('click', function (ev) {
      var btn = ev.target.closest('button');
      if (btn) App.run(btn.dataset.act);
    });
  }
};
