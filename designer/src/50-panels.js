/* ZPDF Studio Designer 2 - palettes: Hierarchy, Data View, Object Library, Object (properties and
 * data binding). Every palette can be collapsed, closed and reopened from the "Palettes" menu. */

function panelDefs() {
  return {
    hier: { dock: 'left', title: T('Hiyerarşi', 'Hierarchy'), icon: 'struct' },
    data: { dock: 'left', title: T('Veri Görünümü', 'Data View'), icon: 'iface' },
    lib: { dock: 'right', title: T('Nesne Kitaplığı', 'Object Library'), icon: 'rect' },
    obj: { dock: 'right', title: T('Nesne', 'Object'), icon: 'form' }
  };
}

// ---------------------------------------------------------------------------------------------
// Path picker: the only way to bind an object - a searchable list of the interface fields
// ---------------------------------------------------------------------------------------------

var Picker = {
  node: null,

  close: function () {
    if (this.node) { this.node.remove(); this.node = null; }
  },

  /**
   * @param options { kind: 'scalar' | 'table' | 'row', table: path of the table for 'row' }
   * @param done    function (path, node)
   */
  open: function (anchor, options, done) {
    this.close();
    var items = options.kind === 'table' ? tableNodes(S.doc) : options.kind === 'row' ? rowFields(S.doc, options.table) : scalarPaths(S.doc);
    var box = document.createElement('div');
    box.className = 'picker';
    var empty = !S.doc.iface.length;
    box.innerHTML = '<input type="text" class="pk-q" placeholder="' + esc(empty ? T('Alan adı yazın, Enter', 'Type a field name, Enter') : T('Ara...', 'Search...')) + '">' +
      '<div class="pk-list"></div>' +
      (empty ? '<div class="pk-hint">' + esc(T('Arayüz tanımlı değil. Alanları listeden seçebilmek için Arayüz sekmesinde parametre ekleyin.', 'No interface defined. Add parameters on the Interface tab to pick fields from a list.')) +
        ' <a href="#" data-goto="iface">' + esc(T('Arayüz sekmesi', 'Interface tab')) + '</a></div>' : '');
    document.body.appendChild(box);
    this.node = box;
    var r = anchor.getBoundingClientRect();
    var width = Math.max(r.width, 300);
    box.style.width = width + 'px';
    box.style.left = clamp(r.left, 4, window.innerWidth - width - 4) + 'px';
    var below = window.innerHeight - r.bottom;
    if (below < 260 && r.top > below) box.style.bottom = (window.innerHeight - r.top + 2) + 'px';
    else box.style.top = (r.bottom + 2) + 'px';

    var list = box.querySelector('.pk-list');
    var input = box.querySelector('.pk-q');
    function draw() {
      var q = input.value.trim().toUpperCase();
      var shown = items.filter(function (it) {
        return !q || it.path.toUpperCase().indexOf(q) >= 0 || String(it.node.d || '').toUpperCase().indexOf(q) >= 0;
      }).slice(0, 400);
      list.innerHTML = shown.map(function (it) {
        return '<div class="pk-item" data-path="' + esc(it.path) + '">' + icon(it.node.k === 'T' ? 'table' : 'elem') + '<b>' + esc(it.path) + '</b><span>' + esc(it.node.d || '') + '</span></div>';
      }).join('') || (empty ? '' : '<div class="pk-hint">' + esc(options.kind === 'row' && !options.table
        ? T('Önce tabloyu bir arayüz tablosuna bağlayın.', 'Bind the table to an interface table first.')
        : T('Eşleşen alan yok.', 'No matching field.')) + '</div>');
    }
    draw();
    input.addEventListener('input', draw);
    input.addEventListener('keydown', function (ev) {
      ev.stopPropagation();
      if (ev.key === 'Escape') Picker.close();
      if (ev.key === 'Enter') {
        var first = list.querySelector('.pk-item');
        if (first) first.click();
        else if (empty && isPath(input.value.trim())) { Picker.close(); done(input.value.trim().toUpperCase(), null); }
      }
    });
    box.addEventListener('mousedown', function (ev) { ev.stopPropagation(); });
    box.addEventListener('click', function (ev) {
      var go = ev.target.closest('[data-goto]');
      if (go) { ev.preventDefault(); Picker.close(); App.showTab(go.dataset.goto); return; }
      var item = ev.target.closest('.pk-item');
      if (!item) return;
      var path = item.dataset.path;
      var hit = items.filter(function (it) { return it.path === path; })[0];
      Picker.close();
      done(path, hit ? hit.node : null);
    });
    input.focus();
  }
};

// ---------------------------------------------------------------------------------------------
// Property descriptions
// ---------------------------------------------------------------------------------------------

function fontOptions() {
  var list = [['', T('(Form varsayılanı)', '(Form default)')], ['Arial', 'Arial / Helvetica'], ['Times New Roman', 'Times New Roman'], ['Courier New', 'Courier New']];
  App.fontFamilies().forEach(function (f) { list.push([f, f + ' (TTF)']); });
  return list;
}

var ALIGN_OPTS = function () { return [['left', T('Sol', 'Left')], ['center', T('Orta', 'Center')], ['right', T('Sağ', 'Right')]]; };
var VALIGN_OPTS = function () { return [['top', T('Üst', 'Top')], ['middle', T('Orta', 'Middle')], ['bottom', T('Alt', 'Bottom')]]; };

function propGroups(el) {
  var g = [];
  var mmStep = { step: 0.5, unit: 'mm' };
  g.push({
    id: 'gen', label: T('Genel', 'General'), fields: [
      { k: 'name', label: T('Ad', 'Name'), type: 'text' },
      { k: '_type', label: T('Tür', 'Type'), type: 'info', value: typeLabel(el) },
      { k: 'locked', label: T('Kilitli (taşınamaz)', 'Locked (cannot be moved)'), type: 'check' }
    ]
  });
  if (el.type === 'text' && !el.bind) {
    g.push({ id: 'content', label: T('İçerik', 'Content'), fields: [
      { k: 'text', label: T('Metin', 'Text'), type: 'area', hint: T('{ALAN} veya {ALAN | biçim} yazarak metnin içine veri alanı ekleyebilirsiniz. {currentPage} / {totalPages}: sayfa numarası.', 'Type {FIELD} or {FIELD | format} to insert a data field into the text. {currentPage} / {totalPages}: page numbers.') }
    ] });
  }
  if (el.type === 'barcode') {
    g.push({ id: 'code', label: T('Barkod', 'Barcode'), fields: [
      { k: 'code', label: T('Barkod türü', 'Barcode type'), type: 'select', opts: Object.keys(BARCODES).map(function (c) { return [c, T(BARCODES[c].tr, BARCODES[c].en)]; }) },
      { k: 'text', label: T('Sabit değer', 'Fixed value'), type: 'text', hint: T('Veri alanı bağlıysa kullanılmaz.', 'Not used when a data field is bound.') },
      { k: 'hr', label: T('Değeri barkodun altına yaz', 'Print human readable text'), type: 'check', hide: BARCODES[el.code] && BARCODES[el.code].two },
      { k: 'ecc', label: T('Hata düzeltme düzeyi', 'Error correction'), type: 'select', opts: [['L', 'L (%7)'], ['M', 'M (%15)'], ['Q', 'Q (%25)'], ['H', 'H (%30)']], hide: el.code !== 'qr' }
    ] });
  }
  g.push({
    id: 'pos', label: T('Konum ve Boyut', 'Position and Size'), fields: [
      Object.assign({ k: 'x', label: 'X', type: 'num', half: true }, mmStep),
      Object.assign({ k: 'y', label: 'Y', type: 'num', half: true }, mmStep),
      Object.assign({ k: 'w', label: T('Genişlik', 'Width'), type: 'num', half: true, min: 0.1 }, mmStep),
      Object.assign({ k: 'h', label: T('Yükseklik', 'Height'), type: 'num', half: true, min: 0.1 }, mmStep),
      { k: 'rot', label: T('Döndürme', 'Rotation'), type: 'num', half: true, step: 5, unit: '°', hide: el.type === 'table' },
      { k: 'op', label: T('Opaklık', 'Opacity'), type: 'num', half: true, step: 0.05, min: 0, max: 1, hide: el.type === 'table' }
    ]
  });
  if (el.type === 'text') {
    g.push({ id: 'font', label: T('Yazı Tipi', 'Font'), fields: [
      { k: 'font', label: T('Yazı tipi', 'Font'), type: 'select', opts: fontOptions() },
      { k: 'size', label: T('Boyut', 'Size'), type: 'num', half: true, step: 1, min: 4, max: 200, unit: 'pt' },
      { k: 'color', label: T('Renk', 'Colour'), type: 'color', half: true },
      { k: 'bold', label: T('Kalın', 'Bold'), type: 'check', third: true },
      { k: 'italic', label: T('İtalik', 'Italic'), type: 'check', third: true },
      { k: 'underline', label: T('Altı çizili', 'Underline'), type: 'check', third: true }
    ] });
    g.push({ id: 'para', label: T('Paragraf', 'Paragraph'), fields: [
      { k: 'align', label: T('Yatay hizalama', 'Horizontal alignment'), type: 'seg', opts: ALIGN_OPTS() },
      { k: 'valign', label: T('Dikey hizalama', 'Vertical alignment'), type: 'seg', opts: VALIGN_OPTS() },
      { k: 'wrap', label: T('Metni satırlara böl', 'Wrap lines'), type: 'check', half: true },
      { k: 'pad', label: T('İç boşluk', 'Padding'), type: 'num', half: true, step: 0.5, min: 0, unit: 'mm' }
    ] });
    g.push({ id: 'look', label: T('Arka Plan ve Kenarlık', 'Background and Border'), fields: [
      { k: 'bg', label: T('Arka plan', 'Background'), type: 'color', none: true, half: true },
      { k: 'bc', label: T('Kenarlık rengi', 'Border colour'), type: 'color', half: true },
      { k: 'bw', label: T('Kenarlık kalınlığı', 'Border width'), type: 'num', half: true, step: 0.1, min: 0, unit: 'mm' }
    ] });
  }
  if (el.type === 'rect' || el.type === 'ellipse') {
    g.push({ id: 'look', label: T('Dolgu ve Kenarlık', 'Fill and Border'), fields: [
      { k: 'fill', label: T('Dolgu', 'Fill'), type: 'color', none: true, half: true },
      { k: 'bc', label: T('Kenarlık rengi', 'Border colour'), type: 'color', half: true },
      { k: 'bw', label: T('Kenarlık kalınlığı', 'Border width'), type: 'num', half: true, step: 0.1, min: 0, unit: 'mm' }
    ] });
  }
  if (el.type === 'line' || el.type === 'checkbox') {
    g.push({ id: 'look', label: T('Görünüm', 'Appearance'), fields: [{ k: 'color', label: T('Renk', 'Colour'), type: 'color', half: true }] });
  }
  if (el.type === 'barcode') {
    g.push({ id: 'look', label: T('Görünüm', 'Appearance'), fields: [
      { k: 'color', label: T('Çubuk rengi', 'Bar colour'), type: 'color', half: true },
      { k: 'bg', label: T('Arka plan', 'Background'), type: 'color', none: true, half: true }
    ] });
  }
  if (el.type === 'image') {
    g.push({ id: 'img', label: T('Resim', 'Image'), fields: [
      { k: 'fit', label: T('Sığdırma', 'Fit'), type: 'select', opts: [['contain', T('Oranı koru', 'Keep ratio')], ['fill', T('Kutuyu doldur', 'Fill the box')]] }
    ] });
  }
  if (el.type === 'table') {
    g.push({ id: 'thead', label: T('Başlık Satırı', 'Header Row'), fields: [
      { k: 'showHead', label: T('Başlık satırını yazdır (her sayfada tekrarlanır)', 'Print the header row (repeated on every page)'), type: 'check' },
      { k: 'hbg', label: T('Arka plan', 'Background'), type: 'color', none: true, half: true },
      { k: 'hfg', label: T('Yazı rengi', 'Text colour'), type: 'color', half: true },
      { k: 'hsize', label: T('Yazı boyutu', 'Font size'), type: 'num', half: true, step: 1, min: 4, unit: 'pt' },
      { k: 'hbold', label: T('Kalın', 'Bold'), type: 'check', half: true }
    ] });
    g.push({ id: 'tbody', label: T('Veri Satırları', 'Data Rows'), fields: [
      { k: 'font', label: T('Yazı tipi', 'Font'), type: 'select', opts: fontOptions() },
      { k: 'bsize', label: T('Yazı boyutu', 'Font size'), type: 'num', half: true, step: 1, min: 4, unit: 'pt' },
      { k: 'bfg', label: T('Yazı rengi', 'Text colour'), type: 'color', half: true },
      { k: 'bbg', label: T('Arka plan', 'Background'), type: 'color', none: true, half: true },
      { k: 'zebra', label: T('Alternatif satır rengi', 'Zebra row colour'), type: 'color', none: true, half: true },
      { k: 'bc', label: T('Çizgi rengi', 'Line colour'), type: 'color', half: true },
      { k: 'bw', label: T('Çizgi kalınlığı', 'Line width'), type: 'num', half: true, step: 0.1, min: 0, unit: 'mm' },
      { k: 'pad', label: T('Hücre iç boşluğu', 'Cell padding'), type: 'num', half: true, step: 0.5, min: 0, unit: 'mm' }
    ] });
  }
  if (el.type !== 'table') {
    g.push({ id: 'print', label: T('Yazdırma Kuralı (Ana Sayfa)', 'Print Rule (Master Page)'), fields: [
      { k: 'printOn', label: T('Hangi sayfalarda yazdırılır', 'Where it is printed'), type: 'select', opts: PRINT_RULES.map(function (r) { return [r[0], T(r[1], r[2])]; }),
        hint: T('"Gövde" dışındaki seçenekler nesneyi ana sayfa nesnesi yapar: tablo birden fazla sayfaya taşsa bile nesne, seçilen sayfalarda aynı yerde yazdırılır.', 'Any option other than "Body" makes this a master page object: it is printed at the same place on the chosen pages even when a table runs over several pages.') }
    ] });
  }
  return g;
}

function bindGroups(el) {
  var g = [];
  var node = el.bind ? findNode(S.doc, el.bind, '') : null;
  var info = node ? (node.d ? node.d + ' · ' : '') + T('Tip', 'Type') + ' ' + (node.k === 'T' ? T('tablo', 'table') : node.t + (node.l ? '(' + node.l + (node.dec ? ',' + node.dec : '') + ')' : '')) : '';
  if (el.type === 'text' || el.type === 'checkbox' || el.type === 'barcode' || el.type === 'image') {
    var fields = [];
    if (el.type === 'image') {
      fields.push({ k: 'asset', label: T('Depodaki logo / resim', 'Logo / image from the store'), type: 'select', opts: [['', T('(yok)', '(none)')]].concat(App.images().map(function (a) { return [a.id, a.id + (a.description ? ' – ' + a.description : '')]; })), hint: T('Araçlar > Logo/Font yükle ile masaüstünden eklenir; formla birlikte taşınır.', 'Added from the desktop with Tools > Upload logo/font; transported with the form.') });
    }
    fields.push({ k: 'bind', label: el.type === 'image' ? T('veya veri alanı (base64 / asset:AD)', 'or data field (base64 / asset:NAME)') : T('Veri alanı (arayüzden)', 'Data field (from the interface)'), type: 'path', kind: 'scalar', info: info });
    if (el.type === 'text') {
      var grp = formatGroup(node ? node.t : 'C');
      fields.push({ k: 'fmt', label: T('Biçim', 'Format'), type: 'fmt', presets: node ? FORMAT_PRESETS[grp] : FORMAT_PRESETS.D.concat(FORMAT_PRESETS.N, FORMAT_PRESETS.C), hide: !el.bind,
        hint: T('Tarih: DD.MM.YYYY, D MMMM YYYY · Sayı: #.##0,00 · Yazıyla: WORDS:TRY · Metin: UPPER, ALPHA. Boş bırakılırsa kullanıcının SAP ayarı kullanılır.', 'Date: DD.MM.YYYY, D MMMM YYYY · Number: #.##0,00 · In words: WORDS:TRY · Text: UPPER, ALPHA. Empty = the user\'s SAP setting.') });
    }
    g.push({ id: 'bind', label: T('Veri Bağlama', 'Data Binding'), fields: fields });
  }
  if (el.type === 'table') {
    g.push({ id: 'bind', label: T('Veri Bağlama', 'Data Binding'), fields: [
      { k: 'bind', label: T('Arayüz tablosu', 'Interface table'), type: 'path', kind: 'table', info: info },
      { k: '_gen', type: 'button', label: T('Sütunları tablodan oluştur', 'Generate the columns from the table'), act: 'colsFromTable', hide: !el.bind }
    ] });
    g.push({ id: 'cols', label: T('Sütunlar', 'Columns') + ' (' + (el.cols || []).length + ')', cols: true });
  }
  var negate = String(el.printIf || '').charAt(0) === '!';
  g.push({ id: 'cond', label: T('Koşul', 'Condition'), fields: [
    { k: 'printIfPath', label: T('Yalnızca bu alan doluysa yazdır', 'Print only when this field is filled'), type: 'path', kind: 'scalar', value: String(el.printIf || '').replace(/^!/, '') },
    { k: 'printIfNot', label: T('Tersi: alan boşsa yazdır', 'Invert: print when the field is empty'), type: 'check', value: negate, hide: !el.printIf }
  ] });
  return g;
}

// ---------------------------------------------------------------------------------------------
// Rendering of the field descriptions
// ---------------------------------------------------------------------------------------------

function fieldHtml(f, el) {
  if (f.hide) return '';
  var value = f.value !== undefined ? f.value : el[f.k];
  var cls = 'fld' + (f.half ? ' half' : '') + (f.third ? ' third' : '');
  var fk = 'data-fk="k:' + f.k + '" data-k="' + f.k + '" data-t="' + f.type + '"';
  var ro = App.canEdit() ? '' : ' disabled';
  var hint = f.hint ? '<div class="hint">' + esc(f.hint) + '</div>' : '';
  switch (f.type) {
    case 'info':
      return '<div class="' + cls + '"><label>' + esc(f.label) + '</label><div class="info">' + esc(value) + '</div></div>';
    case 'check':
      return '<div class="' + cls + ' chk"><label><input type="checkbox" ' + fk + (value ? ' checked' : '') + ro + '> ' + esc(f.label) + '</label>' + hint + '</div>';
    case 'num':
      return '<div class="' + cls + '"><label>' + esc(f.label) + (f.unit ? ' <i>' + f.unit + '</i>' : '') + '</label><input type="number" ' + fk + ' value="' + esc(value === undefined ? '' : value) + '" step="' + (f.step || 1) + '"' +
        (f.min !== undefined ? ' min="' + f.min + '"' : '') + (f.max !== undefined ? ' max="' + f.max + '"' : '') + ro + '>' + hint + '</div>';
    case 'area':
      return '<div class="' + cls + '"><label>' + esc(f.label) + '</label><textarea rows="4" ' + fk + ro + '>' + esc(value || '') + '</textarea>' + hint + '</div>';
    case 'select':
      return '<div class="' + cls + '"><label>' + esc(f.label) + '</label><select ' + fk + ro + '>' + f.opts.map(function (o) {
        return '<option value="' + esc(o[0]) + '"' + (String(value === undefined ? '' : value) === String(o[0]) ? ' selected' : '') + '>' + esc(o[1]) + '</option>';
      }).join('') + '</select>' + hint + '</div>';
    case 'seg':
      return '<div class="' + cls + '"><label>' + esc(f.label) + '</label><div class="seg">' + f.opts.map(function (o) {
        return '<button type="button" data-seg="' + f.k + '" data-v="' + esc(o[0]) + '" class="' + (value === o[0] ? 'on' : '') + '"' + ro + '>' + esc(o[1]) + '</button>';
      }).join('') + '</div></div>';
    case 'color': {
      var hex = /^#[0-9a-fA-F]{6}$/.test(value || '') ? value : '#ffffff';
      return '<div class="' + cls + '"><label>' + esc(f.label) + '</label><div class="clr"><input type="color" data-k="' + f.k + '" data-t="color" value="' + hex + '"' + ro + '>' +
        '<input type="text" ' + fk + ' value="' + esc(value || '') + '" placeholder="' + (f.none ? esc(T('yok', 'none')) : '#000000') + '"' + ro + '>' +
        (f.none ? '<button type="button" class="mini" data-clear="' + f.k + '" title="' + esc(T('Renk yok (saydam)', 'No colour (transparent)')) + '"' + ro + '>' + icon('close') + '</button>' : '') + '</div></div>';
    }
    case 'path':
      return '<div class="' + cls + '"><label>' + esc(f.label) + '</label><div class="pathbox' + (value ? ' bound' : '') + '">' +
        '<button type="button" class="pathbtn" data-pick="' + f.k + '" data-kind="' + f.kind + '"' + ro + '>' + icon('link') + '<span>' + esc(value || T('Alan seçin...', 'Choose a field...')) + '</span></button>' +
        (value ? '<button type="button" class="mini" data-clear="' + f.k + '" title="' + esc(T('Bağlamayı kaldır', 'Remove the binding')) + '"' + ro + '>' + icon('close') + '</button>' : '') + '</div>' +
        (f.info ? '<div class="hint">' + esc(f.info) + '</div>' : '') + '</div>';
    case 'fmt':
      return '<div class="' + cls + '"><label>' + esc(f.label) + '</label><input type="text" ' + fk + ' list="fmtlist" value="' + esc(value || '') + '"' + ro + '>' +
        '<datalist id="fmtlist">' + (f.presets || []).map(function (p) { return '<option value="' + esc(p) + '">'; }).join('') + '</datalist>' + hint + '</div>';
    case 'button':
      return '<div class="' + cls + '"><button type="button" class="btn" data-act="' + f.act + '"' + ro + '>' + esc(f.label) + '</button></div>';
    default:
      return '<div class="' + cls + '"><label>' + esc(f.label) + '</label><input type="text" ' + fk + ' value="' + esc(value || '') + '"' + ro + '>' + hint + '</div>';
  }
}

function columnsHtml(el) {
  var ro = App.canEdit() ? '' : ' disabled';
  var html = '';
  (el.cols || []).forEach(function (c, i) {
    var fk = function (p) { return 'data-fk="col:' + i + ':' + p + '" data-col="' + i + '" data-cp="' + p + '"'; };
    html += '<div class="colcard"><div class="colhead"><b>' + (i + 1) + '</b>' +
      '<input type="text" ' + fk('title') + ' value="' + esc(c.title || '') + '" placeholder="' + esc(T('Başlık', 'Heading')) + '"' + ro + '>' +
      '<button type="button" class="mini" data-colact="up" data-col="' + i + '" title="' + esc(T('Sola taşı', 'Move left')) + '"' + ro + '>' + icon('up') + '</button>' +
      '<button type="button" class="mini" data-colact="down" data-col="' + i + '" title="' + esc(T('Sağa taşı', 'Move right')) + '"' + ro + '>' + icon('dn') + '</button>' +
      '<button type="button" class="mini" data-colact="del" data-col="' + i + '" title="' + esc(T('Sütunu sil', 'Delete the column')) + '"' + ro + '>' + icon('trash') + '</button></div>' +
      '<div class="pathbox' + (c.field ? ' bound' : '') + '"><button type="button" class="pathbtn" data-pickcol="' + i + '"' + ro + '>' + icon('link') + '<span>' + esc(c.field || T('Satır alanı seçin...', 'Choose a row field...')) + '</span></button></div>' +
      '<div class="colrow"><label>' + esc(T('Genişlik', 'Width')) + ' %<input type="number" ' + fk('w') + ' value="' + esc(c.w) + '" min="1" step="1"' + ro + '></label>' +
      '<label>' + esc(T('Hizalama', 'Align')) + '<select ' + fk('align') + ro + '>' + ALIGN_OPTS().map(function (o) { return '<option value="' + o[0] + '"' + (c.align === o[0] ? ' selected' : '') + '>' + esc(o[1]) + '</option>'; }).join('') + '</select></label>' +
      '<label>' + esc(T('Biçim', 'Format')) + '<input type="text" ' + fk('fmt') + ' list="fmtall" value="' + esc(c.fmt || '') + '"' + ro + '></label></div></div>';
  });
  html += '<datalist id="fmtall">' + FORMAT_PRESETS.D.concat(FORMAT_PRESETS.N, FORMAT_PRESETS.C).map(function (p) { return '<option value="' + esc(p) + '">'; }).join('') + '</datalist>';
  html += '<button type="button" class="btn" data-colact="add"' + ro + '>' + icon('plus') + ' ' + esc(T('Sütun ekle', 'Add a column')) + '</button>';
  return html;
}

function groupsHtml(groups, el, prefix) {
  return groups.map(function (g) {
    var key = prefix + g.id;
    var closed = !!S.acc[key];
    var body = g.cols ? columnsHtml(el) : g.fields.map(function (f) { return fieldHtml(f, el); }).join('');
    if (!body) return '';
    return '<div class="acc' + (closed ? ' closed' : '') + '"><div class="acch" data-acc="' + key + '">' + icon(closed ? 'right' : 'down') + '<span>' + esc(g.label) + '</span></div>' +
      '<div class="accb">' + body + '</div></div>';
  }).join('');
}

// ---------------------------------------------------------------------------------------------
// Panels
// ---------------------------------------------------------------------------------------------

var Panels = {
  /** Rebuilds the docks (which palettes are shown, collapsed, how wide). */
  layout: function () {
    var defs = panelDefs();
    ['left', 'right'].forEach(function (side) {
      var dock = document.getElementById(side === 'left' ? 'dockLeft' : 'dockRight');
      var split = document.getElementById(side === 'left' ? 'splitLeft' : 'splitRight');
      var ids = Object.keys(defs).filter(function (id) { return defs[id].dock === side && S.panels[id].open; });
      dock.style.display = ids.length ? '' : 'none';
      split.style.display = ids.length ? '' : 'none';
      dock.style.width = S.dock[side] + 'px';
      dock.innerHTML = ids.map(function (id) {
        var collapsed = S.panels[id].collapsed;
        return '<section class="panel' + (collapsed ? ' collapsed' : '') + '" data-panel="' + id + '">' +
          '<header><button type="button" class="mini" data-pact="collapse" title="' + esc(collapsed ? T('Genişlet', 'Expand') : T('Daralt', 'Collapse')) + '">' + icon(collapsed ? 'right' : 'down') + '</button>' +
          icon(defs[id].icon, 'pic') + '<span>' + esc(defs[id].title) + '</span>' +
          '<button type="button" class="mini" data-pact="close" title="' + esc(T('Paleti gizle (Paletler menüsünden geri açılır)', 'Hide the palette (reopen it from the Palettes menu)')) + '">' + icon('close') + '</button></header>' +
          '<div class="pbody" id="pb_' + id + '"></div></section>';
      }).join('');
    });
    this.hier();
    this.data();
    this.lib();
    this.obj();
    Canvas.drawRulers();
  },

  body: function (id) {
    return document.getElementById('pb_' + id);
  },

  // ----- Hierarchy ---------------------------------------------------------------------------

  hier: function () {
    var body = this.body('hier');
    if (!body) return;
    function row(el) {
      var bound = el.bind || (el.type === 'text' && placeholdersOf(el.text).length);
      return '<div class="trow lvl2' + (S.sel.indexOf(el.id) >= 0 ? ' sel' : '') + '" data-id="' + el.id + '">' + icon(typeIcon(el)) +
        '<span class="nm">' + esc(el.name) + '</span>' + (bound ? '<i class="dot" title="' + esc(T('Veriye bağlı', 'Bound to data')) + '"></i>' : '') + (el.locked ? icon('lock', 'dim') : '') + '</div>';
    }
    var html = '<div class="trow lvl0">' + icon('form') + '<span class="nm">' + esc(S.form || T('Form', 'Form')) + '</span></div>';
    var master = [];
    S.doc.pages.forEach(function (page) { page.els.forEach(function (el) { if (el.printOn) master.push(el); }); });
    html += '<div class="trow lvl1 grp">' + icon('master') + '<span class="nm">' + esc(T('(Ana Sayfa Nesneleri)', '(Master Page Objects)')) + '</span><em>' + master.length + '</em></div>';
    html += master.map(row).join('');
    S.doc.pages.forEach(function (page, i) {
      var els = page.els.filter(function (el) { return !el.printOn; });
      html += '<div class="trow lvl1 grp' + (i === S.pageIndex ? ' cur' : '') + '" data-page="' + i + '">' + icon('page') + '<span class="nm">' + esc(page.name || T('Sayfa', 'Page') + ' ' + (i + 1)) + '</span><em>' + els.length + '</em></div>';
      // The last object is drawn on top, so it is listed first.
      html += els.slice().reverse().map(row).join('');
    });
    body.innerHTML = html;
  },

  // ----- Data View ---------------------------------------------------------------------------

  usedPaths: function () {
    var used = {};
    allElements(S.doc).forEach(function (el) {
      if (el.bind) used[el.bind] = true;
      if (el.type === 'text' && !el.bind) placeholdersOf(el.text).forEach(function (p) { used[p] = true; });
      if (el.printIf) used[String(el.printIf).replace(/^!/, '')] = true;
      if (el.type === 'table') (el.cols || []).forEach(function (c) { if (c.field) used[el.bind + '>' + c.field] = true; });
    });
    return used;
  },

  data: function () {
    var body = this.body('data');
    if (!body) return;
    if (!S.doc.iface.length) {
      body.innerHTML = '<div class="empty">' + esc(T('Arayüz tanımlı değil. Formun kullanacağı yapıları (DDIC yapısı, tablo tipi) Arayüz sekmesinde seçin; alanları buradan sayfaya sürükleyin.', 'No interface defined. Choose the structures of the form (DDIC structure, table type) on the Interface tab, then drag the fields from here onto the page.')) +
        '<br><button type="button" class="btn" data-act="tabIface">' + icon('iface') + ' ' + esc(T('Arayüzü tanımla', 'Define the interface')) + '</button></div>';
      return;
    }
    var used = this.usedPaths();
    var q = (S.dataQuery || '').toUpperCase();
    var html = '<div class="search">' + icon('search') + '<input type="text" id="dataQuery" data-fk="dq" placeholder="' + esc(T('Alan ara...', 'Search fields...')) + '" value="' + esc(S.dataQuery || '') + '"></div><div class="tree">';
    function visit(node, name, path, table, depth) {
      var isTable = node.k === 'T';
      var kids = node.c || [];
      var state = S.tree[(table ? table + '>' : '') + path];
      var open = q ? true : (state === undefined ? depth < 1 : state);
      var selfHit = !q || name.toUpperCase().indexOf(q) >= 0 || String(node.d || '').toUpperCase().indexOf(q) >= 0;
      var inner = '';
      var childTable = isTable ? path : table;
      kids.forEach(function (child) {
        inner += visit(child, child.n, isTable ? child.n : path + '.' + child.n, childTable, depth + 1);
      });
      if (q && !selfHit && !inner) return '';
      var key = (table ? table + '>' : '') + path;
      var isUsed = used[key] || (!table && used[path]);
      var drag = JSON.stringify({ kind: node.k === 'E' ? (table ? 'rowfield' : 'field') : isTable ? 'table' : 'struct', path: path, table: table || '' });
      var out = '<div class="trow' + (isUsed ? ' used' : '') + '" style="padding-left:' + (6 + depth * 14) + 'px" draggable="true" data-drag="' + esc(drag) + '" data-key="' + esc(key) + '" title="' + esc(path + (node.d ? ' – ' + node.d : '')) + '">' +
        (kids.length ? '<span class="tw" data-tw="' + esc(key) + '" data-open="' + (open ? 1 : 0) + '">' + icon(open ? 'down' : 'right') + '</span>' : '<span class="tw"></span>') +
        icon(isTable ? 'table' : node.k === 'S' ? 'struct' : 'elem') + '<span class="nm">' + esc(name) + '</span><span class="ds">' + esc(node.d || '') + '</span></div>';
      return out + (open ? inner : '');
    }
    S.doc.iface.forEach(function (param) {
      if (param.node) html += visit(param.node, param.name, param.name, '', 0);
      else html += '<div class="trow">' + icon('warn') + '<span class="nm">' + esc(param.name) + '</span><span class="ds">' + esc(T('tip çözümlenemedi', 'type not resolved')) + '</span></div>';
    });
    body.innerHTML = html + '</div><div class="hint pad">' + esc(T('Sayfaya sürükleyip bırakın. Çift tıklama: alanı seçili nesneye bağlar.', 'Drag: drop on the page. Double click: bind to the selected object.')) + '</div>';
  },

  // ----- Object Library ----------------------------------------------------------------------

  lib: function () {
    var body = this.body('lib');
    if (!body) return;
    body.innerHTML = paletteGroups().map(function (group) {
      var key = 'lib_' + group.id;
      var closed = !!S.acc[key];
      return '<div class="acc' + (closed ? ' closed' : '') + '"><div class="acch" data-acc="' + key + '">' + icon(closed ? 'right' : 'down') + '<span>' + esc(group.label) + '</span><em>' + group.items.length + '</em></div>' +
        '<div class="accb libgrid">' + group.items.map(function (item) {
          return '<div class="libitem" draggable="true" data-lib="' + item.id + '" data-drag="' + esc(JSON.stringify({ kind: 'lib', id: item.id })) + '" title="' + esc(item.label) + '">' + icon(item.icon) + '<span>' + esc(item.label) + '</span></div>';
        }).join('') + '</div></div>';
    }).join('');
  },

  // ----- Object: properties and data binding -------------------------------------------------

  obj: function () {
    var body = this.body('obj');
    if (!body) return;
    var active = document.activeElement;
    var focusKey = active && body.contains(active) ? active.getAttribute('data-fk') : null;
    var scroll = body.querySelector('.objscroll');
    var top = scroll ? scroll.scrollTop : 0;
    var sel = App.selected();
    var tabs = '<div class="otabs"><button type="button" data-otab="props" class="' + (S.objTab === 'props' ? 'on' : '') + '">' + esc(T('Özellikler', 'Properties')) + '</button>' +
      '<button type="button" data-otab="bind" class="' + (S.objTab === 'bind' ? 'on' : '') + '">' + icon('link') + ' ' + esc(T('Veri Bağlama', 'Data Binding')) + '</button></div>';
    var html;
    if (!sel.length) {
      html = '<div class="empty">' + esc(T('Nesne seçilmedi. Sayfada bir nesneye tıklayın veya Nesne Kitaplığı\'ndan bir nesne sürükleyin.', 'No object selected. Click an object on the page or drag one from the Object Library.')) + '</div>';
    } else if (sel.length > 1) {
      html = '<div class="multi">' + sel.length + ' ' + esc(T('nesne seçili. Değişiklikler hepsine uygulanır; nesneleri birbirine göre hizalamak için Düzen menüsünü kullanın.', 'objects selected. Changes apply to all of them; use the Layout menu to align.')) + '</div>' +
        groupsHtml(S.objTab === 'bind' ? [bindGroups(sel[0]).pop()] : propGroups(sel[0]).filter(function (g) { return g.id !== 'gen' && g.id !== 'content'; }), sel[0], S.objTab + '_');
    } else {
      html = groupsHtml(S.objTab === 'bind' ? bindGroups(sel[0]) : propGroups(sel[0]), sel[0], S.objTab + '_');
    }
    body.innerHTML = tabs + '<div class="objscroll">' + html + '</div>';
    body.querySelector('.objscroll').scrollTop = top;
    if (focusKey) {
      var again = body.querySelector('[data-fk="' + focusKey + '"]');
      if (again) {
        again.focus();
        if (again.select && again.type !== 'number' && again.tagName !== 'SELECT') { try { again.select(); } catch (err) { /* not selectable */ } }
      }
    }
  },

  // ----- Events ------------------------------------------------------------------------------

  /** Writes a property of the selected objects. Returns true when something changed. */
  setProp: function (key, value) {
    var changed = false;
    App.selected().forEach(function (el) {
      if (key === 'printIfPath') {
        var neg = String(el.printIf || '').charAt(0) === '!';
        var next = value ? (neg ? '!' : '') + value : '';
        if (el.printIf !== next) { el.printIf = next; changed = true; }
        return;
      }
      if (key === 'printIfNot') {
        var path = String(el.printIf || '').replace(/^!/, '');
        var nxt = path ? (value ? '!' : '') + path : '';
        if (el.printIf !== nxt) { el.printIf = nxt; changed = true; }
        return;
      }
      if (!(key in el)) return;
      if (key === 'name' && !String(value).trim()) return;
      if (el[key] !== value) { el[key] = value; changed = true; }
    });
    return changed;
  },

  readInput: function (input) {
    var type = input.dataset.t;
    if (type === 'check') return input.checked;
    if (type === 'num') {
      var v = num(input.value, 0);
      if (input.min !== '') v = Math.max(v, Number(input.min));
      if (input.max !== '') v = Math.min(v, Number(input.max));
      return round2(v);
    }
    return input.value;
  },

  init: function () {
    var self = this;
    var main = document.getElementById('layoutTab');

    main.addEventListener('click', function (ev) {
      var t = ev.target;
      var pact = t.closest('[data-pact]');
      if (pact) {
        var id = pact.closest('.panel').dataset.panel;
        if (pact.dataset.pact === 'close') S.panels[id].open = false;
        else S.panels[id].collapsed = !S.panels[id].collapsed;
        self.layout();
        App.uiChanged();
        return;
      }
      var acc = t.closest('[data-acc]');
      if (acc) {
        S.acc[acc.dataset.acc] = !S.acc[acc.dataset.acc];
        if (acc.closest('#pb_lib')) self.lib(); else self.obj();
        App.uiChanged();
        return;
      }
      var otab = t.closest('[data-otab]');
      if (otab) { App.showObjectTab(otab.dataset.otab); return; }
      var act = t.closest('[data-act]');
      if (act && act.closest('.panel')) { App.run(act.dataset.act); return; }

      // Hierarchy
      var hrow = t.closest('#pb_hier .trow');
      if (hrow) {
        if (hrow.dataset.page !== undefined) { App.gotoPage(Number(hrow.dataset.page)); return; }
        if (hrow.dataset.id) {
          var hid = hrow.dataset.id;
          if (ev.ctrlKey || ev.shiftKey) {
            var ids = S.sel.slice();
            var at = ids.indexOf(hid);
            if (at >= 0) ids.splice(at, 1); else ids.push(hid);
            App.select(ids);
          } else {
            App.select([hid], true);
          }
        }
        return;
      }
      // Data view: open / close a node
      var tw = t.closest('[data-tw]');
      if (tw) {
        S.tree[tw.dataset.tw] = tw.dataset.open !== '1';
        self.data();
        return;
      }
      // Library: click adds the object
      var lib = t.closest('[data-lib]');
      if (lib) { App.addFromLibrary(lib.dataset.lib); return; }

      // Object panel
      if (!App.canEdit()) return;
      var seg = t.closest('[data-seg]');
      if (seg) {
        if (self.setProp(seg.dataset.seg, seg.dataset.v)) App.commit();
        return;
      }
      var clear = t.closest('[data-clear]');
      if (clear) {
        var ck = clear.dataset.clear;
        if (ck === 'bind') App.bindSelection('');
        else if (self.setProp(ck, '')) App.commit();
        return;
      }
      var pick = t.closest('[data-pick]');
      if (pick) {
        var pk = pick.dataset.pick;
        Picker.open(pick, { kind: pick.dataset.kind }, function (path, node) {
          if (pk === 'bind') App.bindSelection(path, node);
          else if (self.setProp(pk, path)) App.commit();
        });
        return;
      }
      var pickCol = t.closest('[data-pickcol]');
      if (pickCol) {
        var tbl = App.selected()[0];
        var ci = Number(pickCol.dataset.pickcol);
        Picker.open(pickCol, { kind: 'row', table: tbl.bind }, function (path, node) {
          var col = tbl.cols[ci];
          col.field = path;
          if (node && (!col.title || /^(Sütun|Column) \d+$/.test(col.title))) col.title = node.d || path;
          if (node && !col.fmt) App.defaultFormat(col, node);
          App.commit();
        });
        return;
      }
      var colact = t.closest('[data-colact]');
      if (colact) { App.columnAction(colact.dataset.colact, Number(colact.dataset.col)); return; }
    });

    main.addEventListener('dblclick', function (ev) {
      var row = ev.target.closest('#pb_data .trow[data-drag]');
      if (row) { App.useDataNode(JSON.parse(row.dataset.drag)); return; }
      var hrow = ev.target.closest('#pb_hier .trow[data-id]');
      if (hrow) {
        S.objTab = 'props';
        S.acc.props_gen = false;
        self.obj();
        var name = document.querySelector('#pb_obj [data-k="name"]');
        if (name) { name.focus(); name.select(); }
      }
    });

    main.addEventListener('dragstart', function (ev) {
      var src = ev.target.closest('[data-drag]');
      if (!src || !App.canEdit()) return;
      ev.dataTransfer.setData('text/plain', 'zpdf:' + src.dataset.drag);
      ev.dataTransfer.effectAllowed = 'copy';
    });

    // Live preview while typing, one undo step when the field is left.
    main.addEventListener('input', function (ev) {
      var input = ev.target;
      if (input.id === 'dataQuery') {
        S.dataQuery = input.value;
        var pos = input.selectionStart;
        self.data();
        var again = document.getElementById('dataQuery');
        if (again) { again.focus(); again.setSelectionRange(pos, pos); }
        return;
      }
      if (!App.canEdit() || !input.closest('#pb_obj')) return;
      if (input.dataset.cp) {
        var tbl = App.selected()[0];
        var col = tbl && tbl.cols[Number(input.dataset.col)];
        if (col) { col[input.dataset.cp] = input.type === 'number' ? Math.max(1, num(input.value, 1)) : input.value; App.touch(); }
        return;
      }
      if (!input.dataset.k || input.dataset.t === 'check' || input.tagName === 'SELECT') return;
      if (input.type === 'number' && input.value === '') return;
      if (self.setProp(input.dataset.k, self.readInput(input))) App.touch();
    });

    main.addEventListener('change', function (ev) {
      var input = ev.target;
      if (!App.canEdit() || !input.closest('#pb_obj')) return;
      if (input.dataset.cp) { App.commit(); return; }
      if (!input.dataset.k) return;
      self.setProp(input.dataset.k, self.readInput(input));
      App.commit();
    });

    // Dock width: drag the splitter.
    ['Left', 'Right'].forEach(function (side) {
      var split = document.getElementById('split' + side);
      split.addEventListener('mousedown', function (ev) {
        ev.preventDefault();
        var key = side.toLowerCase();
        var startX = ev.clientX;
        var startW = S.dock[key];
        function move(e) {
          var delta = (e.clientX - startX) * (key === 'left' ? 1 : -1);
          S.dock[key] = clamp(startW + delta, 180, 560);
          document.getElementById('dock' + side).style.width = S.dock[key] + 'px';
          Canvas.drawRulers();
        }
        function up() {
          document.removeEventListener('mousemove', move);
          document.removeEventListener('mouseup', up);
          App.uiChanged();
        }
        document.addEventListener('mousemove', move);
        document.addEventListener('mouseup', up);
      });
    });

    document.addEventListener('mousedown', function (ev) {
      if (Picker.node && !Picker.node.contains(ev.target)) Picker.close();
    });
  }
};
