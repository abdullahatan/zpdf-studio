/* ZPDF Studio Designer 2 - menu bar, context menu and keyboard shortcuts. */

var Menus = {
  openId: null,
  popupNode: null,

  defs: function () {
    // Objects are selected, copied, aligned ... on the Layout tab only.
    var onLayout = S.tab === 'layout';
    var sel = onLayout ? App.selected() : [];
    var one = sel.length === 1 ? sel[0] : null;
    var edit = App.canEdit();
    var some = sel.length > 0 && edit;
    var many = sel.length > 1 && edit;
    var isTable = !!one && one.type === 'table' && edit;
    var firstText = sel.filter(function (el) { return el.type === 'text'; })[0];
    var hasText = edit && !!firstText;
    var sap = Bridge.isSap;
    var defs = panelDefs();
    var lib = paletteGroups();
    var logos = App.images();

    function toggle(label, key, shortcut) {
      return { label: label, act: 'toggle', arg: key, on: !!S.view[key], key: shortcut };
    }

    return [
      { id: 'file', label: T('Dosya', 'File'), items: [
        { label: T('Kaydet', 'Save'), act: 'save', key: 'Ctrl+S', dis: !edit },
        { label: T('PDF önizle', 'Preview PDF'), act: 'preview', key: 'Ctrl+P' },
        '-',
        { label: T('Transport talebine ekle...', 'Add to a transport request...'), act: 'transport', dis: !sap || !edit },
        { label: T('Sürümler...', 'Versions...'), act: 'versions' },
        '-',
        { label: T('Tasarımı JSON olarak dışa aktar', 'Export the design as JSON'), act: 'exportJson' },
        { label: T('JSON içe aktar...', 'Import JSON...'), act: 'importJson', dis: !edit },
        '-',
        { label: T('Sayfayı SAP\'den yeniden yükle', 'Reload the page from SAP'), act: 'reload', dis: !sap },
        { label: T('Çıkış', 'Exit'), act: 'exit', dis: !sap }
      ] },
      { id: 'edit', label: T('Düzenle', 'Edit'), items: [
        { label: T('Geri al', 'Undo'), act: 'undo', key: 'Ctrl+Z', dis: !edit || !S.history.canUndo() },
        { label: T('Yinele', 'Redo'), act: 'redo', key: 'Ctrl+Y', dis: !edit || !S.history.canRedo() },
        '-',
        { label: T('Kes', 'Cut'), act: 'cut', key: 'Ctrl+X', dis: !some },
        { label: T('Kopyala', 'Copy'), act: 'copy', key: 'Ctrl+C', dis: !sel.length },
        { label: T('Yapıştır', 'Paste'), act: 'paste', key: 'Ctrl+V', dis: !edit || !onLayout || !S.clip.length },
        { label: T('Çoğalt', 'Duplicate'), act: 'duplicate', key: 'Ctrl+D', dis: !some },
        { label: T('Sil', 'Delete'), act: 'delete', key: 'Del', dis: !some },
        '-',
        { label: T('Tümünü seç', 'Select all'), act: 'selectAll', key: 'Ctrl+A', dis: !onLayout }
      ] },
      { id: 'view', label: T('Görünüm', 'View'), items: [
        { label: T('Form Özellikleri', 'Form Properties'), act: 'tabForm', on: S.tab === 'form' },
        { label: T('Arayüz', 'Interface'), act: 'tabIface', on: S.tab === 'iface' },
        { label: T('Düzen', 'Layout'), act: 'tabLayout', on: S.tab === 'layout' },
        '-',
        { label: T('Yakınlaştır', 'Zoom in'), act: 'zoomIn', key: '+' },
        { label: T('Uzaklaştır', 'Zoom out'), act: 'zoomOut', key: '−' },
        { label: T('Gerçek boyut (%100)', 'Actual size (100%)'), act: 'zoom100', key: 'Ctrl+0' },
        { label: T('Sayfayı sığdır', 'Fit page'), act: 'fitPage' },
        { label: T('Genişliğe sığdır', 'Fit width'), act: 'fitWidth' },
        '-',
        toggle(T('Izgara', 'Grid'), 'grid'),
        toggle(T('Cetveller', 'Rulers'), 'rulers'),
        toggle(T('Kenar boşlukları', 'Margins'), 'margins'),
        toggle(T('Izgaraya yasla', 'Snap to grid'), 'snapGrid'),
        toggle(T('Nesnelere yasla', 'Snap to objects'), 'snapObj'),
        '-',
        toggle(T('Önizleme verisini sayfada göster', 'Show the preview data'), 'sample'),
        '-',
        { label: T('Tema', 'Theme'), sub: [
          { label: T('Açık', 'Light'), act: 'theme', arg: 'light', on: S.theme !== 'dark', icon: 'sun' },
          { label: T('Koyu', 'Dark'), act: 'theme', arg: 'dark', on: S.theme === 'dark', icon: 'moon' }
        ] }
      ] },
      { id: 'insert', label: T('Ekle', 'Insert'), items: lib.map(function (group) {
        return { label: group.label, sub: group.items.map(function (item) { return { label: item.label, act: 'add', arg: item.id, icon: item.icon, dis: !edit }; }) };
      }).concat([
        { label: T('Kayıtlı logolar', 'Logo from the store'), sub: logos.length
          ? logos.map(function (a) { return { label: a.id, act: 'addLogo', arg: a.id, icon: 'image', dis: !edit }; })
          : [{ label: T('(depoda logo yok)', '(no logo in the store)'), dis: true }] },
        '-',
        { label: T('Yeni tasarım sayfası', 'New design page'), act: 'pageAdd', dis: !edit }
      ]) },
      { id: 'table', label: T('Tablo', 'Table'), items: [
        { label: T('Tablo ekle', 'Insert a table'), act: 'add', arg: 'table', dis: !edit },
        '-',
        { label: T('Sütun ekle', 'Add a column'), act: 'colAdd', dis: !isTable },
        { label: T('Son sütunu sil', 'Delete the last column'), act: 'colDel', dis: !isTable || one.cols.length < 2 },
        { label: T('Sütunları arayüz tablosundan oluştur', 'Generate the columns from the interface table'), act: 'colsFromTable', dis: !isTable || !one.bind },
        { label: T('Sütunları eşit genişlikte yap', 'Make the columns equal width'), act: 'colsEqual', dis: !isTable },
        '-',
        { label: T('Başlık satırı', 'Header row'), act: 'toggleHead', on: isTable && one.showHead !== false, dis: !isTable }
      ] },
      { id: 'layout', label: T('Düzen', 'Layout'), items: [
        { label: T('Nesneleri hizala', 'Align objects'), sub: [
          { label: T('Sola', 'Left'), act: 'align', arg: 'left', dis: !some },
          { label: T('Yatayda ortala', 'Centre horizontally'), act: 'align', arg: 'center', dis: !some },
          { label: T('Sağa', 'Right'), act: 'align', arg: 'right', dis: !some },
          '-',
          { label: T('Üste', 'Top'), act: 'align', arg: 'top', dis: !some },
          { label: T('Dikeyde ortala', 'Centre vertically'), act: 'align', arg: 'middle', dis: !some },
          { label: T('Alta', 'Bottom'), act: 'align', arg: 'bottom', dis: !some }
        ] },
        { label: T('Metni hizala', 'Align text'), sub: [
          { label: T('Sola', 'Left'), act: 'textAlign', arg: 'left', dis: !hasText, on: hasText && (firstText.align || 'left') === 'left' },
          { label: T('Ortaya', 'Centre'), act: 'textAlign', arg: 'center', dis: !hasText, on: hasText && firstText.align === 'center' },
          { label: T('Sağa', 'Right'), act: 'textAlign', arg: 'right', dis: !hasText, on: hasText && firstText.align === 'right' },
          '-',
          { label: T('Üste', 'Top'), act: 'textAlign', arg: 'top', dis: !hasText, on: hasText && (firstText.valign || 'top') === 'top' },
          { label: T('Dikeyde ortaya', 'Middle'), act: 'textAlign', arg: 'middle', dis: !hasText, on: hasText && firstText.valign === 'middle' },
          { label: T('Alta', 'Bottom'), act: 'textAlign', arg: 'bottom', dis: !hasText, on: hasText && firstText.valign === 'bottom' }
        ] },
        { label: T('Eşit aralıkla dağıt', 'Distribute'), sub: [
          { label: T('Yatayda', 'Horizontally'), act: 'dist', arg: 'h', dis: sel.length < 3 || !edit },
          { label: T('Dikeyde', 'Vertically'), act: 'dist', arg: 'v', dis: sel.length < 3 || !edit }
        ] },
        { label: T('Aynı boyuta getir', 'Same size'), sub: [
          { label: T('Genişlik', 'Width'), act: 'same', arg: 'w', dis: !many },
          { label: T('Yükseklik', 'Height'), act: 'same', arg: 'h', dis: !many }
        ] },
        { label: T('Sayfada ortala', 'Centre on the page'), sub: [
          { label: T('Yatayda', 'Horizontally'), act: 'centerPage', arg: 'h', dis: !some },
          { label: T('Dikeyde', 'Vertically'), act: 'centerPage', arg: 'v', dis: !some }
        ] },
        '-',
        { label: T('En öne getir', 'Bring to front'), act: 'order', arg: 'front', dis: !some },
        { label: T('Bir öne getir', 'Bring forward'), act: 'order', arg: 'up', dis: !some },
        { label: T('Bir arkaya gönder', 'Send backward'), act: 'order', arg: 'down', dis: !some },
        { label: T('En arkaya gönder', 'Send to back'), act: 'order', arg: 'back', dis: !some },
        '-',
        { label: T('Kilitle / kilidi aç', 'Lock / unlock'), act: 'lock', dis: !some }
      ] },
      { id: 'tools', label: T('Araçlar', 'Tools'), items: [
        { label: T('Logo / font yükle...', 'Upload logo / font...'), act: 'uploadAsset', dis: !edit },
        { label: T('Logo ve font deposu...', 'Asset store (logos, fonts)...'), act: 'assets' },
        '-',
        { label: T('Önizleme verisi...', 'Preview data...'), act: 'tabIface' },
        { label: T('Uyarılar...', 'Warnings...'), act: 'warnings' },
        { label: T('ABAP çağrı kodu...', 'ABAP call code...'), act: 'abapCode' },
        { label: T('Oluşturulan form HTML\'i...', 'Generated form HTML...'), act: 'htmlSource' },
        '-',
        { label: T('Otomatik kaydet', 'Auto save'), act: 'autosave', on: S.autosave, dis: !edit }
      ] },
      { id: 'palettes', label: T('Paletler', 'Palettes'), items: Object.keys(defs).map(function (id) {
        return { label: defs[id].title, act: 'panel', arg: id, on: S.panels[id].open, icon: defs[id].icon };
      }).concat([
        '-',
        { label: T('Tüm paletleri göster', 'Show all palettes'), act: 'panelsAll' },
        { label: T('Tüm paletleri gizle', 'Hide all palettes'), act: 'panelsNone' },
        { label: T('Çalışma alanını sıfırla', 'Reset the workspace'), act: 'resetWorkspace' }
      ]) },
      { id: 'help', label: T('Yardım', 'Help'), items: [
        { label: T('Klavye kısayolları', 'Keyboard shortcuts'), act: 'shortcuts' },
        { label: T('Hızlı başlangıç', 'Quick start'), act: 'quickStart' },
        { label: T('ZPDF Studio hakkında', 'About ZPDF Studio'), act: 'about' }
      ] }
    ];
  },

  itemsHtml: function (items) {
    var self = this;
    return items.map(function (item) {
      if (item === '-') return '<div class="msep"></div>';
      if (item.sub) {
        return '<div class="mi has-sub"><span class="mchk"></span><span class="mlbl">' + esc(item.label) + '</span><span class="mkey">›</span><div class="submenu">' + self.itemsHtml(item.sub) + '</div></div>';
      }
      return '<div class="mi' + (item.dis ? ' dis' : '') + '" data-act="' + (item.act || '') + '"' + (item.arg !== undefined ? ' data-arg="' + esc(item.arg) + '"' : '') + '>' +
        '<span class="mchk">' + (item.on ? '✓' : item.icon ? icon(item.icon) : '') + '</span><span class="mlbl">' + esc(item.label) + '</span><span class="mkey">' + esc(item.key || '') + '</span></div>';
    }).join('');
  },

  render: function () {
    var bar = document.getElementById('menubar');
    var self = this;
    setHtml(bar, '<span class="brand">ZPDF <b>Studio</b></span>' + this.defs().map(function (menu) {
      return '<div class="menu' + (self.openId === menu.id ? ' open' : '') + '" data-menu="' + menu.id + '"><span class="mtitle">' + esc(menu.label) + '</span>' +
        (self.openId === menu.id ? '<div class="dropdown">' + self.itemsHtml(menu.items) + '</div>' : '') + '</div>';
    }).join('') + '<span class="spacer"></span><span class="formid" id="formBadge"></span>');
    App.renderBadge();
  },

  close: function () {
    if (this.openId) { this.openId = null; this.render(); }
    if (this.popupNode) { this.popupNode.remove(); this.popupNode = null; }
  },

  popup: function (items, x, y) {
    this.close();
    var node = document.createElement('div');
    node.className = 'dropdown ctx';
    node.innerHTML = this.itemsHtml(items);
    document.body.appendChild(node);
    var box = node.getBoundingClientRect();
    node.style.left = clamp(x, 2, window.innerWidth - box.width - 4) + 'px';
    node.style.top = clamp(y, 2, window.innerHeight - box.height - 4) + 'px';
    this.popupNode = node;
    node.addEventListener('mousedown', function (ev) { ev.stopPropagation(); });
    node.addEventListener('click', function (ev) {
      var item = ev.target.closest('.mi[data-act]');
      if (!item || item.classList.contains('dis') || !item.dataset.act) return;
      Menus.close();
      App.run(item.dataset.act, item.dataset.arg);
    });
  },

  context: function (x, y) {
    var all = this.defs();
    var edit = all[1].items;
    var layout = all[5].items;
    this.popup([edit[3], edit[4], edit[5], edit[6], edit[7], '-', layout[6], layout[9], layout[11], '-', layout[0], layout[1], layout[4]], x, y);
  },

  init: function () {
    var self = this;
    var bar = document.getElementById('menubar');
    bar.addEventListener('mousedown', function (ev) { ev.stopPropagation(); });
    bar.addEventListener('click', function (ev) {
      var item = ev.target.closest('.mi[data-act]');
      if (item) {
        if (item.classList.contains('dis') || !item.dataset.act) return;
        self.close();
        App.run(item.dataset.act, item.dataset.arg);
        return;
      }
      var menu = ev.target.closest('.menu');
      if (!menu || ev.target.closest('.dropdown')) return;
      self.openId = self.openId === menu.dataset.menu ? null : menu.dataset.menu;
      self.render();
    });
    bar.addEventListener('mouseover', function (ev) {
      var menu = ev.target.closest('.menu');
      if (menu && self.openId && self.openId !== menu.dataset.menu) {
        self.openId = menu.dataset.menu;
        self.render();
      }
    });
    document.addEventListener('mousedown', function () { self.close(); });

    document.addEventListener('keydown', function (ev) {
      var tag = ev.target.tagName;
      var typing = tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT';
      var ctrl = ev.ctrlKey || ev.metaKey;
      var key = ev.key.toLowerCase();
      if (ev.key === 'Escape') {
        if (self.openId || self.popupNode) { self.close(); return; }
        if (Picker.node) { Picker.close(); return; }
        if (Dialog.node) { Dialog.close(); return; }
        if (!typing) App.select([]);
        return;
      }
      if (ctrl && key === 's') { ev.preventDefault(); App.run('save'); return; }
      if (ctrl && key === 'p') { ev.preventDefault(); App.run('preview'); return; }
      // Ctrl + / - / 0 would zoom the whole designer in the browser: they zoom the page instead,
      // wherever the focus is.
      var zoomKey = { '+': 'zoomIn', '=': 'zoomIn', add: 'zoomIn', '-': 'zoomOut', subtract: 'zoomOut', '0': 'zoom100' }[key];
      if (ctrl && zoomKey) { ev.preventDefault(); App.run(zoomKey); return; }
      if (typing || Dialog.node) return;
      if (!ctrl && !ev.altKey && S.tab === 'layout' && (key === '+' || key === '-' || key === 'add' || key === 'subtract')) {
        ev.preventDefault();
        App.run(key === '+' || key === 'add' ? 'zoomIn' : 'zoomOut');
        return;
      }
      if (ctrl) {
        var map = { z: 'undo', y: 'redo', c: 'copy', x: 'cut', v: 'paste', d: 'duplicate', a: 'selectAll' };
        if (key === 'z' && ev.shiftKey) { ev.preventDefault(); App.run('redo'); return; }
        if (map[key]) { ev.preventDefault(); App.run(map[key]); }
        return;
      }
      if (S.tab !== 'layout') return;
      if (ev.key === 'Delete' || ev.key === 'Backspace') { ev.preventDefault(); App.run('delete'); return; }
      var step = ev.shiftKey ? 5 : ev.altKey ? 0.1 : (num(S.doc.grid) || 1);
      var move = { ArrowLeft: [-step, 0], ArrowRight: [step, 0], ArrowUp: [0, -step], ArrowDown: [0, step] }[ev.key];
      if (move) { ev.preventDefault(); App.nudge(move[0], move[1]); }
    });
  }
};
