/* ZPDF Studio Designer 2 - application: state, actions, saving, synchronisation with ABAP. */

var S = null;

function defaultUi() {
  return {
    tab: 'layout', zoom: 1, pageIndex: 0, objTab: 'props',
    view: { grid: true, rulers: true, margins: true, snapGrid: true, snapObj: true, sample: false },
    panels: { hier: { open: true, collapsed: false }, data: { open: true, collapsed: false }, lib: { open: true, collapsed: false }, obj: { open: true, collapsed: false } },
    dock: { left: 250, right: 310 },
    acc: { lib_fields: true, lib_shapes: true, lib_codes: true },
    tree: {}
  };
}

var App = {
  syncTimer: 0,
  busyTimer: 0,
  syncPending: false,
  warnTimer: 0,
  cache: null,
  toastTimer: 0,

  // -------------------------------------------------------------------------------------------
  // Access
  // -------------------------------------------------------------------------------------------

  canEdit: function () { return !S.viewOnly; },

  el: function (id) {
    var found = null;
    S.doc.pages.forEach(function (page) { page.els.forEach(function (el) { if (el.id === id) found = el; }); });
    return found;
  },

  selected: function () {
    return S.sel.map(function (id) { return App.el(id); }).filter(Boolean);
  },

  asset: function (id) {
    var key = String(id).toUpperCase();
    return S.assets.filter(function (a) { return a.id === key && a.kind === 'IMAGE'; })[0] || null;
  },

  images: function () { return S.assets.filter(function (a) { return a.kind === 'IMAGE'; }); },

  fontFamilies: function () {
    var seen = {};
    S.assets.forEach(function (a) { if (a.kind === 'FONT' && a.family) seen[String(a.family).toLowerCase()] = true; });
    return Object.keys(seen);
  },

  /** Conversion result of the current document (cached until the document changes). */
  converted: function () {
    var snap = JSON.stringify(S.doc);
    if (!this.cache || this.cache.snap !== snap) {
      try {
        this.cache = { snap: snap, result: convert(S.doc, { fonts: this.fontFamilies(), images: this.images().map(function (a) { return a.id; }) }) };
      } catch (err) {
        this.cache = { snap: snap, result: null };
        this.toast(T('Dönüştürme hatası: ', 'Conversion error: ') + err.message, true);
      }
    }
    return this.cache.result;
  },

  sample: function () {
    if (S.doc.sample && S.doc.sample.trim()) {
      try { return JSON.parse(S.doc.sample); } catch (err) { /* fall back to the generated data */ }
    }
    var result = this.converted();
    return result ? result.sample : {};
  },

  sampleJson: function () {
    if (S.doc.sample && S.doc.sample.trim()) return S.doc.sample;
    var result = this.converted();
    return JSON.stringify(result ? result.sample : {});
  },

  // -------------------------------------------------------------------------------------------
  // State that travels to ABAP
  // -------------------------------------------------------------------------------------------

  uiState: function () {
    var scroller = document.getElementById('scroller');
    return {
      lang: LANG, tab: S.tab, zoom: S.zoom, pageIndex: S.pageIndex, objTab: S.objTab, view: S.view, panels: S.panels, dock: S.dock,
      acc: S.acc, tree: S.tree, sel: S.sel, scroll: scroller ? [scroller.scrollLeft, scroller.scrollTop] : [0, 0],
      pendingParam: S.pendingParam || null, pendingSearch: S.pendingSearch || null, ifDraft: S.ifDraft || null
    };
  },

  stateLines: function () {
    var r = this.converted() || { html: embedDoc(S.doc), page: { page_size: 'A4', orientation: 'P', margin_top: 0, margin_right: 0, margin_bottom: 0, margin_left: 0 } };
    return [
      ['html', r.html], ['header', ''], ['footer', ''], ['css', ''],
      ['page_size', r.page.page_size], ['orientation', r.page.orientation],
      ['margin_top', r.page.margin_top], ['margin_right', r.page.margin_right],
      ['margin_bottom', r.page.margin_bottom], ['margin_left', r.page.margin_left],
      ['sample', this.sampleJson()], ['iface', ifaceSpec(S.doc)], ['description', S.doc.description || ''],
      ['ui', JSON.stringify(this.uiState())], ['dirty', S.dirty ? 'X' : ''], ['autosave', S.autosave ? 'X' : '']
    ];
  },

  /** Pushes the current state to ABAP: it is what "save on exit" and the draft store use. */
  sync: function () {
    window.clearTimeout(this.syncTimer);
    if (!this.syncPending || S.viewOnly) return;
    this.syncPending = false;
    Bridge.send('SYNC', { lines: this.stateLines(), quiet: true });
    this.renderBadge();
  },

  scheduleSync: function () {
    if (S.viewOnly) return;
    this.syncPending = true;
    window.clearTimeout(this.syncTimer);
    var self = this;
    this.syncTimer = window.setTimeout(function () { self.sync(); }, 1200);
  },

  uiChanged: function () { /* UI state travels with the next request; nothing to do now. */ },

  // -------------------------------------------------------------------------------------------
  // Change handling
  // -------------------------------------------------------------------------------------------

  updateDirty: function () {
    S.dirty = S.baseDirty || JSON.stringify(S.doc) !== S.savedSnap;
  },

  /** A finished change: one undo step, everything is drawn again, ABAP gets the new state. */
  commit: function () {
    S.history.push(S.doc);
    this.updateDirty();
    this.refresh();
    this.scheduleSync();
  },

  /** A change in progress (typing, dragging): only the page is drawn again. */
  touch: function () {
    Canvas.render();
  },

  refresh: function () {
    S.sel = S.sel.filter(function (id) { return !!App.el(id); });
    S.pageIndex = clamp(S.pageIndex, 0, S.doc.pages.length - 1);
    if (S.tab === 'layout') Canvas.render();
    Panels.hier();
    Panels.data();
    Panels.lib();
    if (S.tab === 'form') Tabs.form();
    if (S.tab === 'iface') Tabs.iface();
    this.renderChrome();
    window.setTimeout(function () { Panels.obj(); }, 0);
    var self = this;
    window.clearTimeout(this.warnTimer);
    this.warnTimer = window.setTimeout(function () { self.renderChrome(); }, 350);
  },

  select: function (ids, reveal) {
    S.sel = ids.filter(function (id) { return !!App.el(id); });
    if (reveal && S.sel.length) {
      var first = this.el(S.sel[0]);
      S.doc.pages.forEach(function (page, i) { if (page.els.indexOf(first) >= 0) S.pageIndex = i; });
      Canvas.render();
    } else {
      Canvas.renderOverlay();
      Canvas.drawRulers();
    }
    Panels.hier();
    Panels.obj();
    var sel = this.selected();
    this.status(sel.length === 1 ? sel[0].name + ' · ' + typeLabel(sel[0]) + ' · ' + sel[0].x + ' × ' + sel[0].y + ' mm, ' + sel[0].w + ' × ' + sel[0].h + ' mm'
      : sel.length ? sel.length + ' ' + T('nesne seçili', 'objects selected') : '');
  },

  gotoPage: function (index) {
    S.pageIndex = clamp(index, 0, S.doc.pages.length - 1);
    S.sel = [];
    this.refresh();
  },

  showTab: function (tab) {
    S.tab = tab;
    ['form', 'iface', 'layout'].forEach(function (name) {
      document.getElementById(name + 'Tab').style.display = name === tab ? '' : 'none';
    });
    if (tab === 'form') Tabs.form();
    if (tab === 'iface') Tabs.iface();
    if (tab === 'layout') { Panels.layout(); Canvas.render(); }
    this.renderChrome();
  },

  showObjectTab: function (tab) {
    S.objTab = tab;
    if (!S.panels.obj.open || S.panels.obj.collapsed) {
      S.panels.obj.open = true;
      S.panels.obj.collapsed = false;
      Panels.layout();
    } else {
      Panels.obj();
    }
  },

  // -------------------------------------------------------------------------------------------
  // Chrome: toolbar, tabs, badge, status, toast
  // -------------------------------------------------------------------------------------------

  renderBadge: function () {
    var badge = document.getElementById('formBadge');
    if (!badge) return;
    setHtml(badge, '<b>' + esc(S.form || T('Tarayıcı modu', 'Browser mode')) + '</b>' + (S.version ? ' · v' + esc(S.version) : '') +
      (S.viewOnly ? ' · <span class="ro">' + esc(T('Salt okunur', 'Display only')) + '</span>'
        : S.dirty ? ' · <span class="dirty">● ' + esc(T('kaydedilmedi', 'not saved')) + '</span>' : ' · <span class="clean">✓ ' + esc(T('kaydedildi', 'saved')) + '</span>'));
  },

  renderChrome: function () {
    // An open menu is not rebuilt under the mouse by a background refresh; it is rebuilt when it closes.
    if (!Menus.openId) Menus.render();
    var result = this.cache && this.cache.snap === JSON.stringify(S.doc) ? this.cache.result : this.converted();
    var warnings = result ? result.warnings.length : 0;
    var edit = this.canEdit();
    function btn(act, ico, label, opts) {
      opts = opts || {};
      return '<button type="button" class="tb' + (opts.primary ? ' primary' : '') + '" data-act="' + act + '"' + (opts.dis ? ' disabled' : '') + ' title="' + esc(opts.title || label) + '">' + icon(ico) + (opts.text === false ? '' : '<span>' + esc(label) + '</span>') + '</button>';
    }
    var toolbarHtml =
      btn('save', 'save', T('Kaydet', 'Save'), { primary: true, dis: !edit, title: T('Kaydet (Ctrl+S): yeni sürüm oluşturur', 'Save (Ctrl+S): creates a new version') }) +
      btn('preview', 'pdf', T('Önizle', 'Preview'), { title: T('PDF önizle (Ctrl+P): gerçek ABAP motoruyla', 'Preview PDF (Ctrl+P): with the real ABAP engine') }) +
      '<span class="tsep"></span>' +
      btn('undo', 'undo', T('Geri al', 'Undo'), { text: false, dis: !edit || !S.history.canUndo() }) +
      btn('redo', 'redo', T('Yinele', 'Redo'), { text: false, dis: !edit || !S.history.canRedo() }) +
      '<span class="tsep"></span>' +
      btn('zoomOut', 'minus', T('Uzaklaştır', 'Zoom out'), { text: false }) +
      '<button type="button" class="tb zoomv" data-act="zoom100" title="' + esc(T('Sayfa yakınlaştırması. %100 için tıklayın. Alt + fare tekerleği veya + / − ile kademeli değişir.', 'Page zoom. Click: 100 %. Alt + mouse wheel or + / − to step.')) + '">' + Math.round(S.zoom * 100) + '%</button>' +
      btn('zoomIn', 'plus', T('Yakınlaştır', 'Zoom in'), { text: false }) +
      btn('fitPage', 'fit', T('Sayfayı sığdır', 'Fit page'), { text: false }) +
      '<span class="tsep"></span>' +
      '<label class="autosave" title="' + esc(T('Açıkken her değişiklik birkaç saniye içinde SAP\'de taslak olarak saklanır; oturum kapansa bile kaybolmaz. Kaydet yeni sürüm oluşturur.', 'When on, every change is stored in SAP as a draft within seconds; it survives a lost session. Save creates a new version.')) + '">' +
      '<input type="checkbox" id="autosave"' + (S.autosave ? ' checked' : '') + (edit ? '' : ' disabled') + '> ' + esc(T('Otomatik kaydet', 'Auto save')) + '</label>' +
      '<span class="spacer"></span>' +
      '<span class="theme" title="' + esc(T('Görünüm teması. Seçiminiz kullanıcınıza kaydedilir ve sonraki oturumlarda da geçerlidir.', 'Colour theme; your choice is remembered for your user.')) + '">' + icon('theme') + '<span>' + esc(T('Tema', 'Theme')) + '</span><span class="tsw">' +
      '<button type="button" data-act="theme" data-arg="light" class="' + (S.theme === 'dark' ? '' : 'on') + '" title="' + esc(T('Açık tema', 'Light theme')) + '">' + icon('sun') + '</button>' +
      '<button type="button" data-act="theme" data-arg="dark" class="' + (S.theme === 'dark' ? 'on' : '') + '" title="' + esc(T('Koyu tema', 'Dark theme')) + '">' + icon('moon') + '</button></span></span>' +
      '<button type="button" class="tb' + (warnings ? ' warn' : '') + '" data-act="warnings" title="' + esc(T('Çıktıyı etkileyebilecek uyarılar', 'Warnings that can affect printing')) + '">' + icon('warn') + '<span>' + esc(T('Uyarılar', 'Warnings')) + '</span><em>' + warnings + '</em></button>';
    setHtml(document.getElementById('toolbar'), toolbarHtml);

    var tabs = [['form', 'form', T('Form Özellikleri', 'Form Properties')], ['iface', 'iface', T('Arayüz', 'Interface') + (S.doc.iface.length ? ' (' + S.doc.iface.length + ')' : '')], ['layout', 'page', T('Düzen', 'Layout')]];
    setHtml(document.getElementById('maintabs'), tabs.map(function (t) {
      return '<button type="button" class="mtab' + (S.tab === t[0] ? ' on' : '') + '" data-tab="' + t[0] + '">' + icon(t[1]) + esc(t[2]) + '</button>';
    }).join(''));
    document.getElementById('statusRight').textContent = pageDims(S.doc.page).w + ' × ' + pageDims(S.doc.page).h + ' mm · ' + allElements(S.doc).length + ' ' + T('nesne', 'objects') + ' · ZPDF Studio ' + VERSION;
  },

  status: function (text) {
    document.getElementById('status').textContent = text || '';
  },

  toast: function (message, error) {
    if (!message) return;
    var el = document.getElementById('toast');
    el.textContent = message;
    el.className = error ? 'error' : '';
    window.clearTimeout(this.toastTimer);
    this.toastTimer = window.setTimeout(function () { el.className = 'hidden'; }, error ? 9000 : 4500);
    this.status(message);
  },

  // -------------------------------------------------------------------------------------------
  // Adding objects
  // -------------------------------------------------------------------------------------------

  /** Top left corner of the visible part of the page, in mm (where new objects appear). */
  freeSpot: function () {
    var scroller = document.getElementById('scroller');
    var paper = Canvas.paper();
    var px = Canvas.px();
    var x = S.doc.page.ml;
    var y = S.doc.page.mt;
    if (scroller && paper && scroller.clientWidth) {
      var sb = scroller.getBoundingClientRect();
      var pb = paper.getBoundingClientRect();
      x = Math.max(x, (sb.left - pb.left) / px + 5);
      y = Math.max(y, (sb.top - pb.top) / px + 5);
    }
    var taken = Canvas.page().els;
    for (var guard = 0; guard < 40; guard++) {
      var hit = taken.some(function (el) { return Math.abs(el.x - x) < 1 && Math.abs(el.y - y) < 1; });
      if (!hit) break;
      x += 4;
      y += 4;
    }
    return { x: Math.round(x), y: Math.round(y) };
  },

  place: function (el, x, y) {
    var dims = pageDims(S.doc.page);
    el.x = round2(clamp(Canvas.snapValue(x), 0, Math.max(0, dims.w - Math.min(el.w, dims.w))));
    el.y = round2(clamp(Canvas.snapValue(y), 0, Math.max(0, dims.h - Math.min(el.h, dims.h))));
    el.id = 'e' + (++S.doc.seq);
    el.name = uniqueName(S.doc, el.name || baseName(el));
    Canvas.page().els.push(el);
    return el;
  },

  libItem: function (id) {
    var hit = null;
    paletteGroups().forEach(function (g) { g.items.forEach(function (item) { if (item.id === id) hit = item; }); });
    return hit;
  },

  addFromLibrary: function (id, x, y) {
    if (!this.canEdit()) return;
    var item = this.libItem(id);
    if (!item) return;
    var props = clone(item.props);
    var needBind = props.needBind;
    delete props.needBind;
    if (item.type === 'text' && props.size === undefined) props.size = num(S.doc.font.size) || 10;
    var el = defaultsFor(item.type, props);
    if (item.type === 'table') {
      el.x = S.doc.page.ml;
      el.w = pageDims(S.doc.page).w - S.doc.page.ml - S.doc.page.mr;
    }
    var spot = x === undefined ? this.freeSpot() : { x: x, y: y };
    this.place(el, item.type === 'table' ? S.doc.page.ml : spot.x, spot.y);
    S.sel = [el.id];
    if (S.tab !== 'layout') this.showTab('layout');
    if (needBind || item.type === 'table' || item.type === 'image' || item.type === 'checkbox' || item.type === 'barcode') S.objTab = 'bind';
    this.commit();
    if (needBind || item.type === 'table') {
      window.setTimeout(function () {
        var btn = document.querySelector('#pb_obj [data-pick="bind"]');
        if (btn && S.doc.iface.length) btn.click();
      }, 60);
    }
  },

  defaultFormat: function (target, node) {
    if (!node || target.fmt) return;
    if (node.t === 'D') target.fmt = 'DD.MM.YYYY';
    else if (node.t === 'T') target.fmt = 'HH:mm';
    else if (node.t === 'P' && num(node.dec) > 0) target.fmt = '#.##0,00';
    if ((node.t === 'P' || node.t === 'I' || node.t === 'F') && target.align === 'left') target.align = 'right';
  },

  columnsFor: function (tablePath, limit) {
    var fields = rowFields(S.doc, tablePath).slice(0, limit || 8);
    var width = round2(100 / Math.max(1, fields.length));
    return fields.map(function (f) {
      var col = { title: f.node.d || f.path, field: f.path, w: width, align: 'left', fmt: '' };
      App.defaultFormat(col, f.node);
      return col;
    });
  },

  /** Something from the Object Library or the Data View was dropped on the page. */
  dropped: function (data, x, y) {
    if (!this.canEdit()) return;
    if (data.kind === 'lib') return this.addFromLibrary(data.id, x, y);
    var node = data.kind === 'rowfield' ? findNode(S.doc, data.path, data.table) : findNode(S.doc, data.path, '');
    if (!node) return;
    var size = num(S.doc.font.size) || 10;
    if (data.kind === 'field') {
      var el = defaultsFor('text', { text: '', bind: data.path, size: size, w: clamp((node.l || 20) * 2, 20, 90) });
      this.defaultFormat(el, node);
      this.place(el, x, y);
      S.sel = [el.id];
    } else if (data.kind === 'table') {
      var tbl = defaultsFor('table', { bind: data.path, cols: this.columnsFor(data.path) });
      tbl.w = pageDims(S.doc.page).w - S.doc.page.ml - S.doc.page.mr;
      this.place(tbl, S.doc.page.ml, y);
      S.sel = [tbl.id];
    } else if (data.kind === 'struct') {
      var ids = [];
      var row = 0;
      (node.c || []).filter(function (c) { return c.k === 'E'; }).slice(0, 14).forEach(function (child) {
        var label = App.place(defaultsFor('text', { text: child.d || child.n, size: size, w: 40, color: '#52606d' }), x, y + row * 7);
        var field = defaultsFor('text', { text: '', bind: data.path + '.' + child.n, size: size, w: 70 });
        App.defaultFormat(field, child);
        App.place(field, x + 42, y + row * 7);
        ids.push(label.id, field.id);
        row++;
      });
      if (!ids.length) return this.toast(T('Bu yapıda doğrudan yazdırılabilecek alan yok; alt düğümlerini sürükleyin.', 'This structure has no directly printable fields; drag its child nodes.'), true);
      S.sel = ids;
    } else if (data.kind === 'rowfield') {
      var target = this.selected().filter(function (e) { return e.type === 'table' && e.bind === data.table; })[0] ||
        Canvas.page().els.filter(function (e) { return e.type === 'table' && e.bind === data.table; })[0];
      if (!target) return this.toast(T('Bu alan "' + data.table + '" tablosunun satır alanıdır. Önce tabloyu sayfaya sürükleyin.', 'This is a row field of table "' + data.table + '". Drag the table onto the page first.'), true);
      var col = { title: node.d || data.path, field: data.path, w: round2(100 / (target.cols.length + 1)), align: 'left', fmt: '' };
      this.defaultFormat(col, node);
      target.cols.push(col);
      S.sel = [target.id];
    }
    this.commit();
  },

  /** Double click in the Data View: bind the selected object, otherwise insert the field. */
  useDataNode: function (data) {
    if (!this.canEdit()) return;
    var sel = this.selected();
    var one = sel.length === 1 ? sel[0] : null;
    if (one && data.kind === 'field' && one.type !== 'table' && 'bind' in one) return this.bindSelection(data.path, findNode(S.doc, data.path, ''));
    if (one && data.kind === 'table' && one.type === 'table') return this.bindSelection(data.path, findNode(S.doc, data.path, ''));
    var spot = this.freeSpot();
    this.dropped(data, spot.x, spot.y);
  },

  bindSelection: function (path, node) {
    var changed = false;
    this.selected().forEach(function (el) {
      if (!('bind' in el)) return;
      var before = el.bind;
      el.bind = path;
      if (el.type === 'text') {
        if (path) {
          App.defaultFormat(el, node);
          if (/^(metin|text|alan|field)(_\d+)?$/i.test(el.name)) el.name = uniqueName(S.doc, path.split('.').pop());
        } else if (!el.text) {
          el.text = before ? '{' + before + '}' : T('Metin', 'Text');
          el.fmt = '';
        }
      }
      if (el.type === 'table' && path && path !== before) {
        var known = rowFields(S.doc, path).map(function (f) { return f.path; });
        var keep = el.cols.some(function (c) { return c.field && known.indexOf(c.field) >= 0; });
        if (!keep && known.length) el.cols = App.columnsFor(path);
      }
      changed = true;
    });
    if (changed) this.commit();
  },

  columnAction: function (action, index) {
    var tbl = this.selected()[0];
    if (!tbl || tbl.type !== 'table' || !this.canEdit()) return;
    var cols = tbl.cols;
    if (action === 'add') cols.push({ title: T('Sütun', 'Column') + ' ' + (cols.length + 1), field: '', w: round2(100 / (cols.length + 1)), align: 'left', fmt: '' });
    else if (action === 'del') { if (cols.length > 1) cols.splice(index, 1); }
    else if (action === 'up' && index > 0) cols.splice(index - 1, 0, cols.splice(index, 1)[0]);
    else if (action === 'down' && index < cols.length - 1) cols.splice(index + 1, 0, cols.splice(index, 1)[0]);
    else return;
    this.commit();
  },

  nudge: function (dx, dy) {
    var els = this.selected().filter(function (el) { return !el.locked; });
    if (!els.length || !this.canEdit()) return;
    els.forEach(function (el) { el.x = round2(el.x + dx); el.y = round2(el.y + dy); });
    this.commit();
  },

  // -------------------------------------------------------------------------------------------
  // Host actions
  // -------------------------------------------------------------------------------------------

  flushEdits: function () {
    var active = document.activeElement;
    if (active && active !== document.body && active.blur) active.blur();
  },

  markSaved: function (snap, version) {
    S.savedSnap = snap;
    S.baseDirty = false;
    if (version) S.version = version;
    this.updateDirty();
    this.renderChrome();
    if (S.tab === 'form') Tabs.form();
  },

  save: function () {
    if (S.viewOnly) return this.toast(T('Form salt okunur açıldı.', 'The form is opened for display only.'), true);
    this.flushEdits();
    window.clearTimeout(this.syncTimer);
    this.syncPending = false;
    this.status(T('Kaydediliyor...', 'Saving...'));
    Bridge.send('SAVE', { lines: this.stateLines() });
  },

  preview: function () {
    this.flushEdits();
    this.toast(T('PDF ABAP motoruyla oluşturuluyor; hazır olunca açılır.', 'The PDF is being created by the ABAP engine; it opens when ready.'));
    Bridge.send('PREVIEW', { lines: this.stateLines(), quiet: true });
  },

  transport: function () {
    if (!Bridge.isSap) return this.toast(T('Transport yalnızca SAP içinde yapılabilir.', 'Transport is only available inside SAP.'), true);
    var self = this;
    function go(save) {
      self.flushEdits();
      Bridge.send('TRANSPORT', { lines: self.stateLines().concat([['save', save ? 'X' : '']]) });
    }
    if (S.dirty || !S.version) {
      Dialog.confirm(T('Transport', 'Transport'), T('Kaydedilmemiş değişiklikler var. Transport talebine eklenmeden önce form kaydedilsin mi?', 'There are unsaved changes. Save the form before it is added to the transport request?'), T('Kaydet ve devam et', 'Save and continue'), function () { go(true); });
    } else {
      go(false);
    }
  },

  versions: function () {
    this.flushEdits();
    Bridge.send('VERSIONS', { lines: this.stateLines() });
  },

  showVersions: function (answer) {
    var self = this;
    {
      {
        var rows = answer.data || [];
        if (!answer.ok) return self.toast(answer.message, true);
        var html = rows.length ? '<table class="grid"><thead><tr><th>' + esc(T('Sürüm', 'Version')) + '</th><th>' + esc(T('Değiştiren', 'Changed by')) + '</th><th>' + esc(T('Tarih', 'Date')) + '</th><th></th></tr></thead><tbody>' +
          rows.map(function (r) {
            var at = String(r.at || '');
            var when = at.length >= 12 ? at.slice(6, 8) + '.' + at.slice(4, 6) + '.' + at.slice(0, 4) + ' ' + at.slice(8, 10) + ':' + at.slice(10, 12) : at;
            return '<tr><td><b>' + esc(r.version) + '</b>' + (r.active ? ' <span class="pill">' + esc(T('etkin', 'active')) + '</span>' : '') + '</td><td>' + esc(r.user || '') + '</td><td>' + esc(when) + '</td><td class="acts">' +
              (r.active || !self.canEdit() ? '' : '<button type="button" class="btn" data-ver="' + esc(r.version) + '">' + esc(T('Bu sürüme dön', 'Return to this version')) + '</button>') + '</td></tr>';
          }).join('') + '</tbody></table><p class="hint">' + esc(T('Her kaydetme yeni bir sürüm oluşturur; son 20 sürüm saklanır.', 'Every save creates a new version; the last 20 versions are kept.')) + '</p>'
          : '<div class="empty">' + esc(T('Form henüz kaydedilmedi.', 'The form has not been saved yet.')) + '</div>';
        var box = Dialog.open(T('Sürümler', 'Versions'), html, [{ label: T('Kapat', 'Close') }], { wide: true });
        box.addEventListener('click', function (ev) {
          var b = ev.target.closest('[data-ver]');
          if (!b) return;
          var version = b.dataset.ver;
          Dialog.confirm(T('Sürüme dön', 'Return to version'), T('Sürüm ' + version + ' etkinleştirilsin mi? Kaydedilmemiş değişiklikler kaybolur.', 'Activate version ' + version + '? Unsaved changes are lost.'), T('Etkinleştir', 'Activate'), function () {
            Bridge.send('ACTIVATE_VERSION', { lines: [['version', version]].concat(self.stateLines()) });
          });
        });
      }
    }
  },

  uploadAsset: function (file) {
    var self = this;
    var reader = new FileReader();
    reader.onload = function () {
      var bytes = new Uint8Array(reader.result);
      var hex = Array.prototype.map.call(bytes.subarray(0, 8), function (b) { return ('0' + b.toString(16)).slice(-2); }).join('');
      var kind = hex.indexOf('89504e470d0a1a0a') === 0 ? ['IMAGE', 'image/png'] : hex.indexOf('ffd8ff') === 0 ? ['IMAGE', 'image/jpeg']
        : (hex.indexOf('00010000') === 0 || hex.indexOf('74727565') === 0) ? ['FONT', 'font/ttf'] : null;
      if (!kind) return self.toast(T('Desteklenmeyen dosya: logo için PNG/JPEG, font için TrueType (.ttf).', 'Unsupported file: PNG/JPEG for logos, TrueType (.ttf) for fonts.'), true);
      var stem = file.name.replace(/\.[^.]+$/, '');
      var lower = stem.toLowerCase();
      var family = stem.replace(/[-_ ]?(bold|italic|oblique|regular|black|heavy)+$/i, '').replace(/[-_]+/g, ' ').trim().toLowerCase();
      var body = '<div class="fld"><label>' + esc(T('Depodaki adı (A-Z, 0-9, _)', 'Asset name (A-Z, 0-9, _)')) + '</label><input type="text" id="asId" maxlength="30" value="' + esc(toFieldName(stem)) + '"></div>' +
        (kind[0] === 'FONT' ? '<div class="fld"><label>' + esc(T('Font ailesi', 'Font family')) + '</label><input type="text" id="asFamily" value="' + esc(family) + '"></div>' +
          '<div class="fld chk"><label><input type="checkbox" id="asBold"' + (/bold|black|heavy/.test(lower) ? ' checked' : '') + '> ' + esc(T('Kalın', 'Bold')) + '</label> <label><input type="checkbox" id="asItalic"' + (/italic|oblique/.test(lower) ? ' checked' : '') + '> ' + esc(T('İtalik', 'Italic')) + '</label></div>' : '') +
        '<div class="fld"><label>' + esc(T('Açıklama', 'Description')) + '</label><input type="text" id="asDescr" value="' + esc(file.name) + '"></div>' +
        '<p class="hint">' + esc(T('Dosya logo ve font deposuna kaydedilir; formla birlikte taşınır (transport).', 'The file is saved in the asset store and transported with the form.')) + ' (' + Math.round(bytes.length / 1024) + ' KB)</p>';
      Dialog.open(kind[0] === 'FONT' ? T('Font yükle', 'Upload a font') : T('Logo yükle', 'Upload a logo'), body, [
        {
          label: T('Yükle', 'Upload'), primary: true, run: function (box) {
            var id = box.querySelector('#asId').value.trim().toUpperCase();
            if (!/^[A-Z0-9_]{1,30}$/.test(id)) { self.toast(T('Ad yalnızca A-Z, 0-9 ve _ içerebilir.', 'The asset name may contain only A-Z, 0-9 and _.'), true); return false; }
            var fam = kind[0] === 'FONT' ? box.querySelector('#asFamily').value.trim().toLowerCase() : '';
            if (kind[0] === 'FONT' && !fam) { self.toast(T('Font ailesini yazın.', 'Enter the font family.'), true); return false; }
            var asset = {
              id: id, kind: kind[0], mime: kind[1], family: fam, description: box.querySelector('#asDescr').value.trim(),
              bold: kind[0] === 'FONT' && box.querySelector('#asBold').checked, italic: kind[0] === 'FONT' && box.querySelector('#asItalic').checked,
              data: bytesToBase64(bytes)
            };
            var lines = [['asset_id', id], ['family', fam], ['bold', asset.bold ? 'X' : ''], ['italic', asset.italic ? 'X' : ''], ['filename', file.name], ['asset_descr', asset.description], ['content', asset.data]];
            if (Bridge.isSap) {
              // ABAP stores the file (a transport dialog can appear) and shows the page again.
              Bridge.send('UPLOAD_ASSET', { lines: lines.concat(self.stateLines()) });
            } else {
              self.onHostEvent({ ok: true, kind: 'upload', message: id + T(' eklendi.', ' added.'), data: { asset: asset } });
            }
          }
        },
        { label: T('Vazgeç', 'Cancel') }
      ]);
    };
    reader.readAsArrayBuffer(file);
  },

  installFonts: function () {
    var css = S.assets.filter(function (a) { return a.kind === 'FONT' && a.family; }).map(function (a) {
      return "@font-face{font-family:'" + String(a.family).toLowerCase().replace(/'/g, '') + "';src:url(data:font/ttf;base64," + a.data + ");font-weight:" + (a.bold ? 'bold' : 'normal') + ';font-style:' + (a.italic ? 'italic' : 'normal') + ';}';
    }).join('');
    var node = document.getElementById('assetFonts');
    if (!node) {
      node = document.createElement('style');
      node.id = 'assetFonts';
      document.head.appendChild(node);
    }
    node.textContent = css;
  },

  loadDoc: function (doc, keepHistory) {
    S.doc = doc;
    S.sel = [];
    S.pageIndex = 0;
    this.cache = null;
    if (!keepHistory) S.history.reset(S.doc);
  },

  /** An answer that no request is waiting for: ABAP started it (toolbar of SAP GUI) or the page was shown again. */
  onHostEvent: function (answer) {
    this.busy(false);
    switch (answer.kind) {
      case 'save':
      case 'saved':
        if (answer.ok) this.markSaved(JSON.stringify(S.doc), answer.data && answer.data.version);
        break;
      case 'ddic_resolve':
        return Tabs.paramResolved(answer);
      case 'ddic_search':
        return Tabs.ddicSearch(S.pendingSearch, answer);
      case 'versions':
        return this.showVersions(answer);
      case 'upload':
        if (answer.ok && answer.data && answer.data.asset) {
          S.assets = S.assets.filter(function (a) { return a.id !== answer.data.asset.id; }).concat([answer.data.asset]);
          this.installFonts();
          this.refresh();
        }
        break;
    }
    if (answer.message) this.toast(answer.message, !answer.ok);
  },

  applyTheme: function () {
    if (S.theme === 'dark') document.documentElement.setAttribute('data-theme', 'dark');
    else document.documentElement.removeAttribute('data-theme');
    Canvas.drawRulers();
  },

  /** The theme belongs to the user: ABAP stores it, so it outlives the session. */
  savePrefs: function () {
    Bridge.send('PREFS', { lines: [['prefs', JSON.stringify({ theme: S.theme })]], quiet: true });
  },

  /** "Working" veil while ABAP handles a request and shows the page again. */
  busy: function (on) {
    var el = document.getElementById('busy');
    if (!el) return;
    window.clearTimeout(this.busyTimer);
    el.className = on ? '' : 'hidden';
    if (on) {
      el.querySelector('span').textContent = T('SAP işlem yapıyor...', 'SAP is working...');
      var self = this;
      this.busyTimer = window.setTimeout(function () {
        el.className = 'hidden';
        self.toast(T('SAP yanıt vermedi. Tasarımınız kaybolmadı; SAP araç çubuğundaki "Sayfayı yenile" düğmesiyle sayfayı yeniden yükleyebilirsiniz.', 'SAP did not answer. Your design is still here; "Refresh page" in the SAP toolbar loads the page again.'), true);
      }, 30000);
    }
  },

  /** The undo history survives the next display of the page in window.name. */
  stash: function () {
    try {
      var from = Math.max(0, S.history.index - 25);
      var data = { form: S.form, at: Date.now(), stack: S.history.stack.slice(from, S.history.index + 1), clip: S.clip };
      var text = JSON.stringify(data);
      window.name = text.length < 3000000 ? 'ZPDF2' + text : '';
    } catch (err) { /* the history is a convenience only */ }
  },

  unstash: function () {
    try {
      var raw = window.name || '';
      window.name = '';
      if (raw.indexOf('ZPDF2') !== 0) return;
      var data = JSON.parse(raw.slice(5));
      if (data.form !== S.form || Date.now() - data.at > 120000 || !data.stack || !data.stack.length) return;
      S.history.stack = data.stack;
      S.history.index = data.stack.length - 1;
      S.history.push(S.doc);
      if (Array.isArray(data.clip)) S.clip = data.clip;
    } catch (err) { /* start with an empty history */ }
  },

  // -------------------------------------------------------------------------------------------
  // Commands (menu, toolbar, shortcuts)
  // -------------------------------------------------------------------------------------------

  run: function (act, arg) {
    var self = this;
    var sel = this.selected();
    var edit = this.canEdit();
    var page = Canvas.page();
    var dims = pageDims(S.doc.page);
    var movable = sel.filter(function (el) { return !el.locked; });
    // Commands on the objects of the page belong to the Layout tab (also for their shortcuts).
    var layoutOnly = { cut: 1, copy: 1, paste: 1, duplicate: 1, 'delete': 1, selectAll: 1, colAdd: 1, colDel: 1, colsFromTable: 1, colsEqual: 1, toggleHead: 1,
      align: 1, textAlign: 1, dist: 1, same: 1, centerPage: 1, order: 1, lock: 1 };
    if (layoutOnly[act] && S.tab !== 'layout') return null;

    switch (act) {
      case 'save': return this.save();
      case 'preview': return this.preview();
      case 'transport': return this.transport();
      case 'versions': return this.versions();
      case 'reload': this.flushEdits(); return Bridge.send('RELOAD', { lines: this.stateLines() });
      case 'exit': this.flushEdits(); return Bridge.send('EXIT', { lines: this.stateLines(), quiet: true });
      case 'autosave':
        S.autosave = !S.autosave;
        this.syncPending = true;
        this.sync();
        this.renderChrome();
        return this.toast(S.autosave ? T('Otomatik kaydet açık: değişiklikler SAP\'de taslak olarak saklanır.', 'Auto save is on: changes are stored in SAP as a draft.') : T('Otomatik kaydet kapalı.', 'Auto save is off.'));

      case 'undo':
      case 'redo': {
        if (!edit) return;
        this.flushEdits();
        var doc = act === 'undo' ? S.history.undo() : S.history.redo();
        if (!doc) return;
        S.doc = doc;
        this.cache = null;
        this.updateDirty();
        this.refresh();
        return this.scheduleSync();
      }
      case 'copy':
      case 'cut':
        if (!sel.length) return;
        S.clip = clone(sel);
        S.clipShift = 0;
        if (act === 'cut' && edit) {
          page.els = page.els.filter(function (el) { return sel.indexOf(el) < 0; });
          S.sel = [];
          this.commit();
        }
        return;
      case 'paste':
      case 'duplicate': {
        if (!edit) return;
        var source = act === 'duplicate' ? clone(sel) : clone(S.clip);
        if (!source.length) return;
        S.clipShift = act === 'duplicate' ? 4 : (S.clipShift || 0) + 4;
        var shift = S.clipShift;
        var ids = source.map(function (el) {
          el.name = String(el.name).replace(/_\d+$/, '');
          return self.place(el, el.x + shift, el.y + shift).id;
        });
        S.sel = ids;
        return this.commit();
      }
      case 'delete':
        if (!edit || !sel.length) return;
        S.doc.pages.forEach(function (p) { p.els = p.els.filter(function (el) { return sel.indexOf(el) < 0 || el.locked; }); });
        S.sel = [];
        return this.commit();
      case 'selectAll':
        if (S.tab !== 'layout') return;
        return this.select(page.els.map(function (el) { return el.id; }));

      case 'zoomIn': return Canvas.stepZoom(1);
      case 'zoomOut': return Canvas.stepZoom(-1);
      case 'zoom100': return Canvas.setZoom(1);
      case 'fitPage':
      case 'fitWidth':
        if (S.tab !== 'layout') this.showTab('layout');
        return Canvas.fit(act === 'fitPage' ? 'page' : 'width');
      case 'toggle':
        S.view[arg] = !S.view[arg];
        Canvas.render();
        return this.renderChrome();
      case 'tabForm': return this.showTab('form');
      case 'tabIface': return this.showTab('iface');
      case 'tabLayout': return this.showTab('layout');

      case 'add': return this.addFromLibrary(arg);
      case 'addLogo': {
        if (!edit) return;
        var asset = this.asset(arg);
        if (!asset) return;
        var img = new Image();
        img.onload = function () {
          var w = 45;
          var el = defaultsFor('image', { asset: asset.id, w: w, h: Math.max(5, Math.round(w * img.naturalHeight / Math.max(1, img.naturalWidth))) });
          var spot = self.freeSpot();
          self.place(el, spot.x, spot.y);
          S.sel = [el.id];
          if (S.tab !== 'layout') self.showTab('layout');
          self.commit();
        };
        img.src = 'data:' + (asset.mime || 'image/png') + ';base64,' + asset.data;
        return;
      }
      case 'pageAdd':
        if (!edit) return;
        S.doc.pages.splice(S.pageIndex + 1, 0, { name: '', els: [] });
        S.pageIndex++;
        S.sel = [];
        return this.commit();
      case 'pageDel':
        if (!edit || S.doc.pages.length < 2) return;
        return Dialog.confirm(T('Sayfayı sil', 'Delete the page'), T('Bu tasarım sayfası ve üzerindeki ' + page.els.length + ' nesne silinsin mi?', 'Delete this design page and its ' + page.els.length + ' objects?'), T('Sil', 'Delete'), function () {
          S.doc.pages.splice(S.pageIndex, 1);
          S.sel = [];
          self.commit();
        });
      case 'pagePrev': return this.gotoPage(S.pageIndex - 1);
      case 'pageNext': return this.gotoPage(S.pageIndex + 1);

      case 'colAdd': return this.columnAction('add');
      case 'colDel': return sel[0] && sel[0].cols ? this.columnAction('del', sel[0].cols.length - 1) : null;
      case 'colsFromTable': {
        var tbl = sel[0];
        if (!edit || !tbl || tbl.type !== 'table' || !tbl.bind) return;
        var cols = this.columnsFor(tbl.bind, 12);
        if (!cols.length) return this.toast(T('Arayüzde bu tablonun satır alanı bulunamadı.', 'No row fields of this table were found in the interface.'), true);
        tbl.cols = cols;
        return this.commit();
      }
      case 'colsEqual':
        if (!edit || !sel[0] || !sel[0].cols) return;
        sel[0].cols.forEach(function (c) { c.w = round2(100 / sel[0].cols.length); });
        return this.commit();
      case 'toggleHead':
        if (!edit || !sel[0] || sel[0].type !== 'table') return;
        sel[0].showHead = sel[0].showHead === false;
        return this.commit();

      case 'align': {
        // Several objects are aligned to each other; a single object is aligned to the
        // printable area of the page (inside the margins).
        if (!edit || !movable.length) return;
        var minX = Math.min.apply(null, movable.map(function (e) { return e.x; }));
        var maxX = Math.max.apply(null, movable.map(function (e) { return e.x + e.w; }));
        var minY = Math.min.apply(null, movable.map(function (e) { return e.y; }));
        var maxY = Math.max.apply(null, movable.map(function (e) { return e.y + e.h; }));
        if (movable.length === 1) {
          minX = S.doc.page.ml; maxX = dims.w - S.doc.page.mr;
          minY = S.doc.page.mt; maxY = dims.h - S.doc.page.mb;
        }
        movable.forEach(function (e) {
          if (arg === 'left') e.x = minX;
          if (arg === 'right') e.x = round2(maxX - e.w);
          if (arg === 'center') e.x = round2((minX + maxX) / 2 - e.w / 2);
          if (arg === 'top') e.y = minY;
          if (arg === 'bottom') e.y = round2(maxY - e.h);
          if (arg === 'middle') e.y = round2((minY + maxY) / 2 - e.h / 2);
        });
        return this.commit();
      }
      case 'textAlign': {
        // The text inside the box of the selected text objects (not the position of the box).
        var texts = sel.filter(function (e) { return e.type === 'text'; });
        if (!edit || !texts.length) return;
        var vertical = arg === 'top' || arg === 'middle' || arg === 'bottom';
        texts.forEach(function (e) { if (vertical) e.valign = arg; else e.align = arg; });
        return this.commit();
      }
      case 'dist': {
        if (!edit || movable.length < 3) return;
        var axis = arg === 'h' ? 'x' : 'y';
        var size = arg === 'h' ? 'w' : 'h';
        var sorted = movable.slice().sort(function (a, b) { return a[axis] - b[axis]; });
        var first = sorted[0];
        var last = sorted[sorted.length - 1];
        var span = last[axis] + last[size] - first[axis];
        var used = sorted.reduce(function (s, e) { return s + e[size]; }, 0);
        var gap = (span - used) / (sorted.length - 1);
        var pos = first[axis];
        sorted.forEach(function (e) { e[axis] = round2(pos); pos += e[size] + gap; });
        return this.commit();
      }
      case 'same':
        if (!edit || movable.length < 2) return;
        movable.forEach(function (e) { e[arg] = movable[0][arg]; });
        return this.commit();
      case 'centerPage':
        if (!edit || !movable.length) return;
        movable.forEach(function (e) {
          if (arg === 'h') e.x = round2((dims.w - e.w) / 2); else e.y = round2((dims.h - e.h) / 2);
        });
        return this.commit();
      case 'order': {
        if (!edit || !sel.length) return;
        var list = page.els;
        var picked = list.filter(function (e) { return sel.indexOf(e) >= 0; });
        var rest = list.filter(function (e) { return sel.indexOf(e) < 0; });
        if (arg === 'front') page.els = rest.concat(picked);
        else if (arg === 'back') page.els = picked.concat(rest);
        else {
          var order = arg === 'up' ? list.slice().reverse() : list.slice();
          for (var i = 1; i < order.length; i++) {
            if (sel.indexOf(order[i]) >= 0 && sel.indexOf(order[i - 1]) < 0) {
              var tmp = order[i - 1]; order[i - 1] = order[i]; order[i] = tmp;
            }
          }
          page.els = arg === 'up' ? order.reverse() : order;
        }
        return this.commit();
      }
      case 'lock': {
        if (!edit || !sel.length) return;
        var lock = !sel.every(function (e) { return e.locked; });
        sel.forEach(function (e) { e.locked = lock; });
        return this.commit();
      }

      case 'uploadAsset': return edit ? document.getElementById('assetInput').click() : null;
      case 'assets': {
        var rows = S.assets.map(function (a) {
          var thumb = a.kind === 'IMAGE' && a.data ? '<img class="thumb" alt="" src="data:' + esc(a.mime || 'image/png') + ';base64,' + a.data + '">'
            : '<span class="thumb font" style="font-family:&quot;' + esc(String(a.family || '').toLowerCase()) + '&quot;;' + (a.bold ? 'font-weight:bold;' : '') + (a.italic ? 'font-style:italic;' : '') + '">Aa Çğ</span>';
          return '<tr><td class="thumbcell">' + thumb + '</td><td>' + icon(a.kind === 'FONT' ? 'text' : 'image') + ' <b>' + esc(a.id) + '</b></td><td>' + esc(a.kind === 'FONT' ? T('Font', 'Font') + ': ' + a.family + (a.bold ? ' bold' : '') + (a.italic ? ' italic' : '') : T('Resim', 'Image')) + '</td><td>' + esc(a.description || '') + '</td><td class="acts">' +
            (a.kind === 'IMAGE' && edit ? '<button type="button" class="btn" data-logo="' + esc(a.id) + '">' + esc(T('Sayfaya ekle', 'Insert')) + '</button>' : '') + '</td></tr>';
        }).join('');
        var box = Dialog.open(T('Logo ve font deposu', 'Asset store'), (rows ? '<table class="grid"><tbody>' + rows + '</tbody></table>' : '<div class="empty">' + esc(T('Depoda logo veya font yok.', 'There are no logos or fonts in the store.')) + '</div>') +
          '<p class="hint">' + esc(T('Silme ve toplu işlemler için ZPDF_STUDIO_ASSETS programını kullanın.', 'Use program ZPDF_STUDIO_ASSETS to delete assets or work with many of them.')) + '</p>',
          [{ label: T('Logo / font yükle...', 'Upload logo / font...'), run: function () { self.run('uploadAsset'); } }, { label: T('Kapat', 'Close'), primary: true }], { wide: true });
        box.addEventListener('click', function (ev) {
          var b = ev.target.closest('[data-logo]');
          if (b) { Dialog.close(); self.run('addLogo', b.dataset.logo); }
        });
        return;
      }
      case 'warnings': {
        var result = this.converted();
        var warnings = result ? result.warnings : [];
        return Dialog.info(T('Uyarılar', 'Warnings'), warnings.length ? '<ul class="warnlist">' + warnings.map(function (w) { return '<li>' + icon('warn') + esc(w) + '</li>'; }).join('') + '</ul>'
          : '<div class="empty">' + esc(T('Uyarı yok: tüm nesneler yazdırılabilir.', 'No warnings: every object can be printed.')) + '</div>');
      }
      case 'abapCode':
        return Dialog.open(T('ABAP çağrı kodu', 'ABAP call code'), '<pre class="code" id="dlgCode">' + esc(abapCallCode()) + '</pre>', [
          { label: T('Panoya kopyala', 'Copy to clipboard'), run: function (box) { self.copyText(box.querySelector('#dlgCode').textContent); return false; } },
          { label: T('Kapat', 'Close'), primary: true }
        ], { wide: true });
      case 'copyAbap': return this.copyText(abapCallCode());
      case 'htmlSource': {
        var res = this.converted();
        var html = res ? res.html.replace(/<!--zpdf-studio:[^>]*-->/, '<!--zpdf-studio:...-->') : '';
        return Dialog.open(T('Oluşturulan form HTML\'i', 'Generated form HTML'), '<textarea class="big" readonly spellcheck="false">' + esc(html.replace(/></g, '>\n<')) + '</textarea>', [{ label: T('Kapat', 'Close'), primary: true }], { wide: true });
      }
      case 'exportJson': {
        var json = JSON.stringify(S.doc, null, 1);
        if (!Bridge.isSap) {
          var a = document.createElement('a');
          a.href = URL.createObjectURL(new Blob([json], { type: 'application/json' }));
          a.download = (S.form || 'zpdf-form') + '.json';
          a.click();
          return;
        }
        return Dialog.open(T('Tasarım (JSON)', 'Design (JSON)'), '<textarea class="big" id="dlgJson" readonly spellcheck="false">' + esc(json) + '</textarea>', [
          { label: T('Panoya kopyala', 'Copy to clipboard'), run: function (box) { self.copyText(box.querySelector('#dlgJson').value); return false; } },
          { label: T('Kapat', 'Close'), primary: true }
        ], { wide: true });
      }
      case 'importJson':
        return Dialog.open(T('JSON içe aktar', 'Import JSON'), '<p class="hint">' + esc(T('Dışa aktarılan tasarım JSON\'unu (veya ZPDF Studio 1 / pdfme şablonunu) yapıştırın. Mevcut tasarımın yerini alır; Geri al ile eski tasarıma dönebilirsiniz.', 'Paste an exported design JSON (or a ZPDF Studio 1 / pdfme template). It replaces the current design; Undo brings it back.')) + '</p><textarea class="big" id="dlgJson" spellcheck="false"></textarea>', [
          {
            label: T('İçe aktar', 'Import'), primary: true, run: function (box) {
              try {
                var doc = loadAny(JSON.parse(box.querySelector('#dlgJson').value));
                self.loadDoc(doc, true);
                self.commit();
                self.toast(T('Tasarım içe aktarıldı.', 'The design was imported.'));
              } catch (err) {
                self.toast(T('JSON okunamadı: ', 'The JSON could not be read: ') + err.message, true);
                return false;
              }
            }
          },
          { label: T('Vazgeç', 'Cancel') }
        ], { wide: true });

      case 'ddicSearch': return Tabs.ddicSearch();
      case 'ifaceAdd': return Tabs.addParam();
      case 'sampleApply': return Tabs.applySample(false);
      case 'sampleReset': return Tabs.applySample(true);

      case 'lang':
        LANG = arg === 'EN' ? 'EN' : 'TR';
        document.documentElement.lang = LANG === 'EN' ? 'en' : 'tr';
        return this.showTab(S.tab);
      case 'theme':
        S.theme = arg === 'dark' ? 'dark' : 'light';
        this.applyTheme();
        this.savePrefs();
        return this.renderChrome();
      case 'panel':
        S.panels[arg].open = !S.panels[arg].open;
        S.panels[arg].collapsed = false;
        if (S.tab !== 'layout') return this.showTab('layout');
        Panels.layout();
        return this.renderChrome();
      case 'panelsAll':
      case 'panelsNone':
        Object.keys(S.panels).forEach(function (id) { S.panels[id].open = act === 'panelsAll'; S.panels[id].collapsed = false; });
        Panels.layout();
        return this.renderChrome();
      case 'resetWorkspace': {
        var ui = defaultUi();
        S.view = ui.view; S.panels = ui.panels; S.dock = ui.dock; S.acc = ui.acc; S.tree = {}; S.objTab = 'props';
        this.showTab('layout');
        return Canvas.setZoom(1);
      }

      case 'shortcuts':
        return Dialog.info(T('Klavye kısayolları', 'Keyboard shortcuts'), '<table class="grid keys"><tbody>' + [
          ['Ctrl+S', T('Kaydet', 'Save')], ['Ctrl+P', T('PDF önizle', 'Preview PDF')], ['Ctrl+Z / Ctrl+Y', T('Geri al / Yinele', 'Undo / Redo')],
          ['Ctrl+C / X / V', T('Kopyala / Kes / Yapıştır', 'Copy / Cut / Paste')], ['Ctrl+D', T('Çoğalt', 'Duplicate')], ['Del', T('Sil', 'Delete')], ['Ctrl+A', T('Tümünü seç', 'Select all')],
          [T('Ok tuşları', 'Arrow keys'), T('Izgara adımı kadar taşı (Shift: 5 mm, Alt: 0,1 mm)', 'Move by the grid step (Shift: 5 mm, Alt: 0.1 mm)')],
          [T('Shift / Ctrl + tıklama', 'Shift / Ctrl + click'), T('Seçime ekle / seçimden çıkar', 'Add to / remove from the selection')],
          [T('Boş alanda sürükle', 'Drag on empty space'), T('Çerçeve çizerek seç', 'Select with a frame')],
          [T('Çift tıklama', 'Double click'), T('Metni yerinde düzenle / veri bağlamayı aç', 'Edit the text in place / open data binding')],
          [T('Shift + köşe tutamağı', 'Shift + corner handle'), T('Oranı koruyarak boyutlandır', 'Resize keeping the ratio')],
          [T('Alt + sürükle', 'Alt + drag'), T('Nesnelere yaslamadan taşı', 'Move without snapping to objects')],
          [T('Alt + fare tekerleği, + / −', 'Alt + mouse wheel, + / −'), T('Sayfayı yakınlaştır / uzaklaştır (kademeli; araçlar aynı boyutta kalır)', 'Zoom the page in / out (in steps; the tools keep their size)')], ['Ctrl+0', T('Sayfa %100', 'Page 100 %')], ['Esc', T('Seçimi kaldır / pencereyi kapat', 'Clear the selection / close a window')]
        ].map(function (r) { return '<tr><td><kbd>' + esc(r[0]) + '</kbd></td><td>' + esc(r[1]) + '</td></tr>'; }).join('') + '</tbody></table>');
      case 'quickStart':
        return Dialog.info(T('Hızlı başlangıç', 'Quick start'), '<ol class="steps">' + [
          T('Arayüz sekmesinde formun alacağı verileri tanımlayın: parametre adı + DDIC tipi (yapı, tablo tipi). "Ara" ile tipi bulabilirsiniz.', 'On the Interface tab define the data of the form: parameter name + DDIC type (structure, table type). "Search" finds the type.'),
          T('Düzen sekmesinde Veri Görünümü\'nden alanları sayfaya sürükleyin. Tablo düğümünü sürüklerseniz sütunları hazır bir tablo oluşur.', 'On the Layout tab drag fields from the Data View onto the page. Dragging a table node creates a table with its columns.'),
          T('Nesne Kitaplığı\'ndan metin, çizgi, logo, barkod ekleyin. Bir nesneyi seçip Nesne > Veri Bağlama sekmesinden arayüz alanına bağlayın.', 'Add text, lines, logos and barcodes from the Object Library. Select an object and bind it to an interface field on Object > Data Binding.'),
          T('Her sayfada yazdırılacak nesneler (logo, altbilgi, sayfa numarası) için Özellikler > Yazdırma Kuralı\'nı kullanın.', 'For objects printed on every page (logo, footer, page number) use Properties > Print Rule.'),
          T('Önizle gerçek ABAP motoruyla PDF üretir. Kaydet yeni sürüm oluşturur; Dosya > Transport formu ve kullandığı logo/fontları talebe ekler.', 'Preview creates the PDF with the real ABAP engine. Save creates a new version; File > Transport adds the form with its logos/fonts to a request.'),
          T('Formu kendi programınızdan yazdırmak için: Araçlar > ABAP çağrı kodu.', 'To print from your program see Tools > ABAP call code.')
        ].map(function (s) { return '<li>' + esc(s) + '</li>'; }).join('') + '</ol>');
      case 'about':
        return Dialog.info(T('ZPDF Studio hakkında', 'About ZPDF Studio'), '<p><b>ZPDF Studio</b> ' + VERSION + '</p><p>' +
          esc(T('SAP için PDF form tasarımcısı ve saf ABAP PDF motoru. Adobe Document Services veya Smart Forms çalışma zamanı gerekmez.', 'PDF form designer and pure ABAP PDF engine for SAP. No Adobe Document Services or Smart Forms runtime is needed.')) + '</p><p class="hint">MIT · ' +
          esc(T('abapPDF (MIT) motorundan türetilmiştir.', 'Derived from the abapPDF (MIT) engine.')) + '</p>');
      default:
        return null;
    }
  },

  copyText: function (text) {
    var self = this;
    function fallback() {
      var area = document.createElement('textarea');
      area.value = text;
      area.style.position = 'fixed';
      area.style.opacity = '0';
      document.body.appendChild(area);
      area.select();
      var ok = false;
      try { ok = document.execCommand('copy'); } catch (err) { ok = false; }
      area.remove();
      self.toast(ok ? T('Panoya kopyalandı.', 'Copied to the clipboard.') : T('Kopyalanamadı; metni seçip Ctrl+C kullanın.', 'Could not copy; select the text and press Ctrl+C.'), !ok);
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(function () { self.toast(T('Panoya kopyalandı.', 'Copied to the clipboard.')); }, fallback);
    } else {
      fallback();
    }
  },

  // -------------------------------------------------------------------------------------------
  // Start
  // -------------------------------------------------------------------------------------------

  init: function () {
    var boot = readBoot();
    Bridge.boot = boot;
    var ui = defaultUi();
    var stored = null;
    if (boot.ui64) {
      try { stored = JSON.parse(fromBase64(boot.ui64)); } catch (err) { stored = null; }
    }
    if (stored) {
      ['tab', 'zoom', 'pageIndex', 'objTab'].forEach(function (k) { if (stored[k] !== undefined) ui[k] = stored[k]; });
      ['view', 'dock', 'acc', 'tree'].forEach(function (k) { if (stored[k]) ui[k] = Object.assign(ui[k], stored[k]); });
      if (stored.panels) Object.keys(ui.panels).forEach(function (id) { if (stored.panels[id]) ui.panels[id] = stored.panels[id]; });
    }
    // Settings of the user (stored in SAP): theme and language.
    var prefs = {};
    try {
      var rawPrefs = boot.prefs64 ? fromBase64(boot.prefs64) : (Bridge.isSap ? '' : Mock.store('prefs'));
      if (rawPrefs) prefs = JSON.parse(rawPrefs) || {};
    } catch (err) { prefs = {}; }
    // Inside SAP the language is the logon language: Turkish for TR, English for everything else.
    // (In the browser, without SAP, Turkish unless a test switched it.)
    LANG = Bridge.isSap ? (boot.lang === 'TR' ? 'TR' : 'EN') : ((stored && stored.lang) === 'EN' ? 'EN' : 'TR');
    document.documentElement.lang = LANG === 'EN' ? 'en' : 'tr';

    var doc = null;
    var problem = '';
    var raw = boot.doc64 ? fromBase64(boot.doc64) : '';
    if (!raw && !Bridge.isSap) {
      var saved = Mock.store('draft') || Mock.store('saved');
      if (saved) { try { doc = extractDoc(saved); } catch (err) { doc = null; } }
    }
    if (raw) {
      try { doc = JSON.parse(raw); } catch (err) { problem = T('Kayıtlı tasarım okunamadı; boş form açıldı.', 'The stored design could not be read; an empty form was opened.'); }
    }
    var imported = isPdfme(doc);
    doc = doc ? loadAny(doc) : newDoc();
    if (boot.sample64 && !doc.sample) {
      try {
        var sampleText = fromBase64(boot.sample64);
        // Forms of Studio 1 have no interface: their stored sample data stays the preview data.
        if (imported && sampleText.trim()) doc.sample = sampleText;
      } catch (err) { /* ignore */ }
    }
    if (boot.description && !doc.description) doc.description = boot.description;

    S = Object.assign(ui, {
      doc: doc, history: new History(100), sel: [], clip: [], clipShift: 0,
      assets: (boot.assets || []).map(function (a) { return Object.assign({}, a, { id: String(a.id).toUpperCase() }); }),
      form: boot.form || '', version: boot.version || '', viewOnly: !!boot.viewOnly, user: boot.user || '',
      theme: prefs.theme === 'dark' ? 'dark' : 'light',
      autosave: boot.autosave !== false, baseDirty: !!boot.dirty, dirty: false, savedSnap: '', dataQuery: '',
      pendingParam: stored ? stored.pendingParam : null, pendingSearch: stored ? stored.pendingSearch || null : null,
      ifDraft: stored ? stored.ifDraft || null : null
    });
    S.history.reset(S.doc);
    this.unstash();
    S.savedSnap = JSON.stringify(S.doc);
    this.updateDirty();
    if (stored && Array.isArray(stored.sel)) S.sel = stored.sel.filter(function (id) { return !!App.el(id); });
    this.installFonts();
    this.applyTheme();

    Menus.init();
    Panels.init();
    Tabs.init();
    Canvas.init();

    var self = this;
    document.getElementById('toolbar').addEventListener('click', function (ev) {
      var b = ev.target.closest('[data-act]');
      if (b && !b.disabled) self.run(b.dataset.act, b.dataset.arg);
    });
    document.getElementById('toolbar').addEventListener('change', function (ev) {
      if (ev.target.id === 'autosave') self.run('autosave');
    });
    document.getElementById('maintabs').addEventListener('click', function (ev) {
      var b = ev.target.closest('[data-tab]');
      if (b) self.showTab(b.dataset.tab);
    });
    document.getElementById('assetInput').addEventListener('change', function (ev) {
      var file = ev.target.files && ev.target.files[0];
      if (file) self.uploadAsset(file);
      ev.target.value = '';
    });

    // The state reaches ABAP before the user can press a SAP GUI button (Back, Exit, Save).
    window.addEventListener('blur', function () { self.sync(); });
    document.documentElement.addEventListener('mouseleave', function () { self.sync(); });

    this.showTab(S.tab);
    if (stored && stored.scroll) {
      var scroller = document.getElementById('scroller');
      scroller.scrollLeft = stored.scroll[0];
      scroller.scrollTop = stored.scroll[1];
      Canvas.drawRulers();
    }
    this.select(S.sel);

    if (problem) this.toast(problem, true);
    else if (boot.message && boot.message.text) this.toast(boot.message.text, boot.message.type === 'E');
    else if (imported) this.toast(T('Bu form ZPDF Studio 1 ile hazırlanmıştı; yeni tasarımcıya dönüştürüldü. Kaydettiğinizde yeni biçimde saklanır.', 'This form was made with ZPDF Studio 1; it was converted for the new designer. Saving stores it in the new format.'));
    if (boot.reply) this.onHostEvent(Bridge.decode(boot.reply));
    if (boot.bootError) this.toast('Boot: ' + boot.bootError, true);
  }
};

// Test and automation hooks.
window.ZPDF = { App: App, Bridge: Bridge, Canvas: Canvas, Menus: Menus, convert: convert, loadAny: loadAny, paletteGroups: paletteGroups, state: function () { return S; } };

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', function () { App.init(); });
else App.init();
