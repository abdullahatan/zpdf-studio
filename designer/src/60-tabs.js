/* ZPDF Studio Designer 2 - dialogs and the two form level tabs: Form Properties and Interface. */

var Dialog = {
  node: null,

  close: function () {
    if (this.node) { this.node.remove(); this.node = null; }
  },

  /**
   * @param buttons [{ label, primary, run: function (box) }] - run returns false to keep the dialog open
   */
  open: function (title, bodyHtml, buttons, options) {
    this.close();
    options = options || {};
    var back = document.createElement('div');
    back.className = 'dlgback';
    back.innerHTML = '<div class="dlg' + (options.wide ? ' wide' : '') + '"><header><span>' + esc(title) + '</span><button type="button" class="mini" data-x="1">' + icon('close') + '</button></header>' +
      '<div class="dlgbody">' + bodyHtml + '</div><footer>' + (buttons || []).map(function (b, i) {
        return '<button type="button" class="btn' + (b.primary ? ' primary' : '') + '" data-b="' + i + '">' + esc(b.label) + '</button>';
      }).join('') + '</footer></div>';
    document.body.appendChild(back);
    this.node = back;
    var self = this;
    back.addEventListener('mousedown', function (ev) { ev.stopPropagation(); });
    back.addEventListener('click', function (ev) {
      if (ev.target.closest('[data-x]')) { self.close(); return; }
      var b = ev.target.closest('[data-b]');
      if (!b) return;
      var def = buttons[Number(b.dataset.b)];
      if (!def.run || def.run(back) !== false) self.close();
    });
    back.addEventListener('keydown', function (ev) {
      ev.stopPropagation();
      if (ev.key === 'Escape') self.close();
      if (ev.key === 'Enter' && ev.target.tagName === 'INPUT') {
        var primary = back.querySelector('.btn.primary');
        if (primary) primary.click();
      }
    });
    var first = back.querySelector('input,textarea,select');
    if (first) first.focus();
    return back;
  },

  info: function (title, html) {
    return this.open(title, html, [{ label: T('Kapat', 'Close'), primary: true }]);
  },

  confirm: function (title, text, yesLabel, onYes) {
    return this.open(title, '<p>' + esc(text) + '</p>', [
      { label: yesLabel, primary: true, run: function () { onYes(); } },
      { label: T('Vazgeç', 'Cancel') }
    ]);
  },

  prompt: function (title, label, value, onOk) {
    return this.open(title, '<div class="fld"><label>' + esc(label) + '</label><input type="text" id="dlgValue" value="' + esc(value || '') + '"></div>', [
      { label: T('Tamam', 'OK'), primary: true, run: function (box) { return onOk(box.querySelector('#dlgValue').value.trim()); } },
      { label: T('Vazgeç', 'Cancel') }
    ]);
  }
};

function abapCallCode() {
  var form = S.form || 'ZFORM';
  var lines = [];
  var params = S.doc.iface;
  if (!params.length) {
    return '" ' + T('Arayüz tanımlı değil: veriyi tek bir yapı olarak verin.', 'No interface defined: pass the data as one structure.') + '\n' +
      'DATA(lv_pdf) = zcl_pdf_studio_api=>render_pdf(\n  iv_form_id = \'' + form + '\'\n  is_data    = ls_data ).\n';
  }
  var vars = params.map(function (p) {
    var kind = p.node ? p.node.k : 'S';
    return { name: p.name, v: (kind === 'T' ? 'lt_' : kind === 'E' ? 'lv_' : 'ls_') + p.name.toLowerCase(), type: String(p.type).toLowerCase() };
  });
  vars.forEach(function (v) { lines.push('DATA ' + v.v + ' TYPE ' + v.type + '.'); });
  lines.push('');
  lines.push('" ... ' + T('verileri doldurun', 'fill the data') + ' ...');
  lines.push('');
  lines.push('DATA(lv_pdf) = zcl_pdf_studio_api=>render_form(');
  lines.push("  iv_form_id = '" + form + "'");
  lines.push('  it_params  = VALUE #(');
  vars.forEach(function (v, i) {
    lines.push("    ( name = '" + v.name + "' value = REF #( " + v.v + ' ) )' + (i === vars.length - 1 ? ' ) ).' : ''));
  });
  lines.push('');
  lines.push('zcl_pdf_studio_api=>download_pdf(');
  lines.push('  iv_pdf_xstring = lv_pdf');
  lines.push("  iv_filename    = '" + form.toLowerCase() + ".pdf' ).");
  return lines.join('\n');
}

var Tabs = {
  // ----- Form Properties ---------------------------------------------------------------------

  form: function () {
    var host = document.getElementById('formTab');
    if (!host) return;
    var d = S.doc;
    var ro = App.canEdit() ? '' : ' disabled';
    function opt(list, value) {
      return list.map(function (o) { return '<option value="' + esc(o[0]) + '"' + (String(value) === String(o[0]) ? ' selected' : '') + '>' + esc(o[1]) + '</option>'; }).join('');
    }
    function n(key, label, value, extra) {
      return '<div class="fld half"><label>' + esc(label) + '</label><input type="number" data-dk="' + key + '" value="' + esc(value) + '" ' + (extra || 'min="0" max="100" step="1"') + ro + '></div>';
    }
    host.innerHTML = '<div class="cards">' +
      '<div class="card"><h3>' + icon('form') + esc(T('Form', 'Form')) + '</h3>' +
      '<div class="fld"><label>' + esc(T('Form adı', 'Form name')) + '</label><div class="info">' + esc(S.form || '-') + '</div></div>' +
      '<div class="fld"><label>' + esc(T('Açıklama', 'Description')) + '</label><input type="text" data-dk="description" maxlength="80" value="' + esc(d.description || '') + '"' + ro + '></div>' +
      '<div class="fld half"><label>' + esc(T('Etkin sürüm', 'Active version')) + '</label><div class="info">' + esc(S.version || T('(yeni form)', '(new form)')) + '</div></div>' +
      '<div class="fld half"><label>' + esc(T('Durum', 'Status')) + '</label><div class="info">' + esc(S.viewOnly ? T('Salt okunur', 'Display only') : S.dirty ? T('Kaydedilmemiş değişiklik var', 'Unsaved changes') : T('Kaydedildi', 'Saved')) + '</div></div>' +
      '<div class="btnrow"><button type="button" class="btn" data-act="versions">' + esc(T('Sürümler...', 'Versions...')) + '</button>' +
      '<button type="button" class="btn" data-act="abapCode">' + esc(T('ABAP çağrı kodu...', 'ABAP call code...')) + '</button></div></div>' +

      '<div class="card"><h3>' + icon('page') + esc(T('Sayfa', 'Page')) + '</h3>' +
      '<div class="fld half"><label>' + esc(T('Kağıt boyutu', 'Paper size')) + '</label><select data-dk="page.size"' + ro + '>' + opt([['A4', 'A4 (210 × 297)'], ['A3', 'A3 (297 × 420)'], ['A5', 'A5 (148 × 210)'], ['LETTER', 'Letter'], ['LEGAL', 'Legal']], d.page.size) + '</select></div>' +
      '<div class="fld half"><label>' + esc(T('Yön', 'Orientation')) + '</label><select data-dk="page.orientation"' + ro + '>' + opt([['P', T('Dikey', 'Portrait')], ['L', T('Yatay', 'Landscape')]], d.page.orientation) + '</select></div>' +
      '<h4>' + esc(T('Kenar boşlukları (mm)', 'Margins (mm)')) + '</h4>' +
      n('page.mt', T('Üst', 'Top'), d.page.mt) + n('page.mb', T('Alt', 'Bottom'), d.page.mb) + n('page.ml', T('Sol', 'Left'), d.page.ml) + n('page.mr', T('Sağ', 'Right'), d.page.mr) +
      '<div class="hint">' + esc(T('Tablolar alt kenar boşluğuna ulaşınca yeni sayfada devam eder; başlık satırı her sayfada tekrarlanır.', 'Tables continue on a new page when they reach the bottom margin; the header row is repeated on every page.')) + '</div></div>' +

      '<div class="card"><h3>' + icon('text') + esc(T('Varsayılanlar', 'Defaults')) + '</h3>' +
      '<div class="fld half"><label>' + esc(T('Yazı tipi', 'Font')) + '</label><select data-dk="font.family"' + ro + '>' + opt(fontOptions().slice(1), d.font.family) + '</select></div>' +
      n('font.size', T('Yazı boyutu (pt)', 'Font size (pt)'), d.font.size, 'min="4" max="72" step="1"') +
      n('grid', T('Izgara aralığı (mm)', 'Grid step (mm)'), d.grid, 'min="0.1" max="20" step="0.1"') +
      '<div class="hint">' + esc(T('Yeni metin nesneleri bu yazı tipini ve boyutu kullanır. Türkçe karakterler standart yazı tiplerinde de doğru yazdırılır.', 'New text objects use this font and size. Turkish characters print correctly in the standard fonts as well.')) + '</div></div>' +
      '</div>';
  },

  // ----- Interface ---------------------------------------------------------------------------

  iface: function () {
    var host = document.getElementById('ifaceTab');
    if (!host) return;
    var ro = App.canEdit() ? '' : ' disabled';
    var used = Panels.usedPaths();
    var rows = S.doc.iface.map(function (p, i) {
      var kind = p.node ? p.node.k : '?';
      var count = Object.keys(used).filter(function (path) { return path === p.name || path.indexOf(p.name + '.') === 0 || path.indexOf(p.name + '>') === 0; }).length;
      return '<tr><td>' + icon(kind === 'T' ? 'table' : kind === 'S' ? 'struct' : 'elem') + ' <b>' + esc(p.name) + '</b></td><td><code>' + esc(p.type) + '</code></td>' +
        '<td>' + esc(kind === 'T' ? T('Tablo', 'Table') : kind === 'S' ? T('Yapı', 'Structure') : kind === 'E' ? T('Alan', 'Field') : '?') + '</td>' +
        '<td>' + esc(p.node && p.node.d ? p.node.d : '') + '</td><td class="r">' + count + '</td>' +
        '<td class="acts"><button type="button" class="mini" data-pa="refresh" data-i="' + i + '" title="' + esc(T('Tipi DDIC\'ten yeniden oku', 'Read the type from the DDIC again')) + '"' + ro + '>' + icon('refresh') + '</button>' +
        '<button type="button" class="mini" data-pa="rename" data-i="' + i + '" title="' + esc(T('Yeniden adlandır (bağlamalar güncellenir)', 'Rename (bindings are updated)')) + '"' + ro + '>' + icon('text') + '</button>' +
        '<button type="button" class="mini" data-pa="del" data-i="' + i + '" title="' + esc(T('Parametreyi sil', 'Delete the parameter')) + '"' + ro + '>' + icon('trash') + '</button></td></tr>';
    }).join('');

    function tree(node, name, depth) {
      var out = '<div class="trow" style="padding-left:' + (6 + depth * 16) + 'px">' + icon(node.k === 'T' ? 'table' : node.k === 'S' ? 'struct' : 'elem') +
        '<span class="nm">' + esc(name) + '</span><span class="ty">' + esc(node.k === 'E' ? node.t + (node.l ? '(' + node.l + (node.dec ? ',' + node.dec : '') + ')' : '') : '') + '</span><span class="ds">' + esc(node.d || '') + '</span></div>';
      (node.c || []).forEach(function (child) { out += tree(child, child.n, depth + 1); });
      return out;
    }
    var context = S.doc.iface.map(function (p) { return p.node ? tree(p.node, p.name, 0) : ''; }).join('');
    var result = App.converted();
    var sampleText = S.doc.sample && S.doc.sample.trim() ? S.doc.sample : JSON.stringify(result ? result.sample : {}, null, 2);

    host.innerHTML = '<div class="ifgrid"><div class="ifleft">' +
      '<div class="card"><h3>' + icon('iface') + esc(T('Arayüz parametreleri', 'Interface parameters')) + '</h3>' +
      '<p class="hint">' + esc(T('Formun dışarıdan aldığı veriler. Her parametre bir DDIC yapısı, tablo tipi, tablo/görünüm veya veri öğesidir (SFP arayüzündeki Import parametreleri gibi). Düzen sekmesinde nesneler yalnızca bu alanlara bağlanır.', 'The data the form receives. Every parameter is a DDIC structure, table type, table/view or data element (like the Import parameters of an SFP interface). On the Layout tab objects are bound to these fields only.')) + '</p>' +
      '<table class="grid"><thead><tr><th>' + esc(T('Parametre', 'Parameter')) + '</th><th>' + esc(T('DDIC tipi', 'DDIC type')) + '</th><th>' + esc(T('Tür', 'Kind')) + '</th><th>' + esc(T('Açıklama', 'Description')) + '</th><th class="r">' + esc(T('Kullanım', 'Used')) + '</th><th></th></tr></thead>' +
      '<tbody>' + (rows || '<tr><td colspan="6" class="none">' + esc(T('Henüz parametre yok.', 'No parameters yet.')) + '</td></tr>') + '</tbody></table>' +
      '<div class="addrow"><div class="fld"><label>' + esc(T('Parametre adı', 'Parameter name')) + ' <b class="req">*</b> <i>' + esc(T('en fazla 16', 'max. 16')) + '</i></label><input type="text" id="ifName" maxlength="16" placeholder="' + esc(T('zorunlu', 'required')) + '" value="' + esc(S.ifDraft ? S.ifDraft.name : '') + '"' + ro + '></div>' +
      '<div class="fld grow"><label>' + esc(T('DDIC tipi (yapı / tablo tipi / tablo / veri öğesi)', 'DDIC type (structure / table type / table / data element)')) + '</label><div class="withbtn"><input type="text" id="ifType" maxlength="30" placeholder="' + esc(T('ör. ZPDF_S_INPUT', 'e.g. ZPDF_S_INPUT')) + '" value="' + esc(S.ifDraft ? S.ifDraft.type : '') + '"' + ro + '>' +
      '<button type="button" class="btn" data-act="ddicSearch"' + ro + '>' + icon('search') + ' ' + esc(T('Ara...', 'Search...')) + '</button></div></div>' +
      '<button type="button" class="btn primary" data-act="ifaceAdd"' + ro + '>' + icon('plus') + ' ' + esc(T('Ekle', 'Add')) + '</button></div></div>' +

      '<div class="card"><h3>' + icon('form') + esc(T('ABAP çağrısı', 'ABAP call')) + '</h3><pre class="code" id="abapCode">' + esc(abapCallCode()) + '</pre>' +
      '<div class="btnrow"><button type="button" class="btn" data-act="copyAbap">' + esc(T('Panoya kopyala', 'Copy to clipboard')) + '</button></div></div>' +

      '<div class="card"><h3>' + icon('table') + esc(T('Önizleme verisi (JSON)', 'Preview data (JSON)')) + '</h3>' +
      '<p class="hint">' + esc(T('Önizleme bu veriyle oluşturulur; veri formla birlikte saklanır. Tarihler YYYYMMDD biçiminde, sayılar ondalık nokta ile yazılır.', 'Preview prints with this data; it is stored with the form. Dates are YYYYMMDD, numbers use a decimal point.')) + '</p>' +
      '<textarea id="sampleText" spellcheck="false"' + ro + '>' + esc(sampleText) + '</textarea>' +
      '<div class="btnrow"><button type="button" class="btn primary" data-act="sampleApply"' + ro + '>' + esc(T('Uygula', 'Apply')) + '</button>' +
      '<button type="button" class="btn" data-act="sampleReset"' + ro + '>' + esc(T('Arayüzden yeniden oluştur', 'Generate again from the interface')) + '</button></div></div></div>' +

      '<div class="ifright"><div class="card full"><h3>' + icon('struct') + esc(T('Bağlam (alan ağacı)', 'Context (field tree)')) + '</h3><div class="tree ctx">' +
      (context || '<div class="empty">' + esc(T('Parametre ekleyince alanlar burada görünür.', 'The fields appear here once a parameter is added.')) + '</div>') + '</div></div></div></div>';
  },

  /** A parameter name is the user's decision: required, unique in the form, at most 16 characters. */
  paramNameError: function (name, except) {
    if (!name) return T('Parametre adı zorunludur.', 'The parameter name is required.');
    if (name.length > 16) return T('Parametre adı en fazla 16 karakter olabilir.', 'The parameter name may have at most 16 characters.');
    if (!/^[A-Z][A-Z0-9_]*$/.test(name)) return T('Parametre adı harfle başlamalı; yalnızca A-Z, 0-9 ve _ içerebilir.', 'The parameter name must start with a letter and contain only A-Z, 0-9 and _.');
    if (S.doc.iface.some(function (p) { return p.name === name && p !== except; })) return T('"' + name + '" adında bir parametre zaten var; bir formda parametre adı tekrarlanamaz.', 'A parameter named "' + name + '" already exists; a parameter name cannot be repeated in a form.');
    return '';
  },

  addParam: function () {
    var nameInput = document.getElementById('ifName');
    var typeInput = document.getElementById('ifType');
    var name = nameInput.value.trim().toUpperCase();
    var type = typeInput.value.trim().toUpperCase();
    var problem = this.paramNameError(name, null);
    if (problem) {
      nameInput.focus();
      return App.toast(problem, true);
    }
    if (!type) {
      typeInput.focus();
      return App.toast(T('DDIC tipini yazın veya "Ara" ile seçin.', 'Type the DDIC type or pick it with "Search".'), true);
    }
    App.status(T('Tip okunuyor: ', 'Reading type: ') + type);
    S.pendingParam = { name: name, type: type, mode: 'add' };
    S.ifDraft = null;
    Bridge.send('DDIC_RESOLVE', { lines: [['type', type]].concat(App.stateLines()) });
  },

  /** Answer of DDIC_RESOLVE: the field tree of the type that addParam / refresh asked for. */
  paramResolved: function (answer) {
    var p = S.pendingParam;
    S.pendingParam = null;
    if (!p) return;
    if (!answer.ok || !answer.data) return App.toast(answer.message || T('Tip okunamadı: ', 'The type could not be read: ') + p.type, true);
    var existing = S.doc.iface.filter(function (o) { return o.name === p.name; })[0];
    if (p.mode === 'refresh') {
      if (!existing) return;
      existing.node = answer.data;
      App.commit();
      return App.toast(p.name + ': ' + T('alanlar DDIC\'ten yenilendi.', 'fields refreshed from the DDIC.'));
    }
    if (existing) return;
    S.doc.iface.push({ name: p.name, type: p.type, node: answer.data });
    App.commit();
    App.toast(p.name + ' (' + p.type + ') ' + T('arayüze eklendi.', 'added to the interface.'));
  },

  paramAction: function (action, index) {
    var p = S.doc.iface[index];
    if (!p) return;
    if (action === 'refresh') {
      S.pendingParam = { name: p.name, type: p.type, mode: 'refresh' };
      Bridge.send('DDIC_RESOLVE', { lines: [['type', p.type]].concat(App.stateLines()) });
    } else if (action === 'del') {
      Dialog.confirm(T('Parametreyi sil', 'Delete the parameter'), T('"' + p.name + '" arayüzden silinsin mi? Bu parametreye bağlı nesnelerin bağlantısı uyarı olarak işaretlenir.', 'Delete "' + p.name + '" from the interface? Objects bound to it are flagged with a warning.'), T('Sil', 'Delete'), function () {
        S.doc.iface.splice(index, 1);
        App.commit();
      });
    } else if (action === 'rename') {
      Dialog.prompt(T('Parametreyi yeniden adlandır', 'Rename the parameter'), T('Yeni ad', 'New name'), p.name, function (value) {
        var next = value.toUpperCase();
        if (next === p.name) return true;
        var problem = Tabs.paramNameError(next, p);
        if (problem) { App.toast(problem, true); return false; }
        var old = p.name;
        var swap = function (path) {
          if (!path) return path;
          var neg = path.charAt(0) === '!' ? '!' : '';
          var bare = path.replace(/^!/, '');
          return bare === old || bare.indexOf(old + '.') === 0 ? neg + next + bare.slice(old.length) : path;
        };
        allElements(S.doc).forEach(function (el) {
          if (el.bind) el.bind = swap(el.bind);
          if (el.printIf) el.printIf = swap(el.printIf);
          if (el.type === 'text' && el.text) {
            el.text = el.text.replace(/\{([^{}|]+)(\|[^{}]*)?\}/g, function (all, key, rest) { return '{' + swap(key.trim()) + (rest || '') + '}'; });
          }
        });
        p.name = next;
        App.commit();
        return true;
      });
    }
  },

  /**
   * Search dialog for DDIC types. Opened empty, or again with the answer of a search
   * (the search itself runs in ABAP, which shows the page again with the result).
   * @param search { q, kinds, pkg, max } - what was searched for
   */
  ddicSearch: function (search, answer) {
    if (!document.getElementById('ifType')) App.showTab('iface');
    var typeInput = document.getElementById('ifType');
    var crit = search && typeof search === 'object' ? search : { q: typeInput.value || '', kinds: 'SDVTE', pkg: '', max: 100 };
    var kindDefs = [
      ['S', T('Yapı', 'Structure')], ['D', T('Veritabanı tablosu', 'Database table')], ['V', T('Görünüm', 'View')],
      ['T', T('Tablo tipi', 'Table type')], ['E', T('Veri öğesi', 'Data element')]
    ];
    var kindLabel = {};
    kindDefs.forEach(function (k) { kindLabel[k[0]] = k[1]; });
    var box = Dialog.open(T('DDIC tipi ara', 'Search DDIC type'),
      '<div class="ddform"><div class="fld grow"><label>' + esc(T('Ad (* joker)', 'Name (* wildcard)')) + '</label><input type="text" id="ddQ" maxlength="30" placeholder="ZPDF*" value="' + esc(crit.q || '') + '"></div>' +
      '<div class="fld"><label>' + esc(T('Paket (* joker)', 'Package (* wildcard)')) + '</label><input type="text" id="ddPkg" maxlength="30" placeholder="ZPDF*" value="' + esc(crit.pkg || '') + '"></div>' +
      '<div class="fld small"><label>' + esc(T('En fazla satır', 'Maximum rows')) + '</label><select id="ddMax">' + [50, 100, 200, 500].map(function (n) {
        return '<option value="' + n + '"' + (Number(crit.max) === n ? ' selected' : '') + '>' + n + '</option>';
      }).join('') + '</select></div>' +
      '<button type="button" class="btn primary" id="ddGo">' + icon('search') + ' ' + esc(T('Ara', 'Search')) + '</button></div>' +
      '<div class="ddkinds"><span>' + esc(T('Nesne tipi:', 'Object type:')) + '</span>' + kindDefs.map(function (k) {
        return '<label><input type="checkbox" data-kind="' + k[0] + '"' + (String(crit.kinds || '').indexOf(k[0]) >= 0 ? ' checked' : '') + '> ' + esc(k[1]) + '</label>';
      }).join('') + '<a href="#" id="ddAll">' + esc(T('tümü', 'all')) + '</a></div>' +
      '<div class="ddlist" id="ddList"><div class="empty">' + esc(T('Ad, paket veya ikisiyle arayın; örn. Z veya Z* tüm Z nesnelerini listeler. Joker yazmazsanız ad ve paket baştan eşleşir; adın içinde geçenler için *METİN* yazın (daha yavaştır). Sonuç sayısını "En fazla satır" sınırlar.', 'Search by name, package or both; e.g. Z or Z* lists all Z objects. Without a wildcard name and package match from their start; write *TEXT* for names that contain the text (slower). "Maximum rows" limits the result.')) + '</div></div>' +
      '<div class="hint" id="ddInfo"></div>',
      [{ label: T('Kapat', 'Close') }], { wide: true });
    var list = box.querySelector('#ddList');
    var info = box.querySelector('#ddInfo');

    function criteria() {
      var kinds = '';
      Array.prototype.forEach.call(box.querySelectorAll('[data-kind]'), function (c) { if (c.checked) kinds += c.dataset.kind; });
      return {
        q: box.querySelector('#ddQ').value.trim().toUpperCase(), kinds: kinds,
        pkg: box.querySelector('#ddPkg').value.trim().toUpperCase(), max: Number(box.querySelector('#ddMax').value) || 100
      };
    }
    function go() {
      var c = criteria();
      // No minimum length (Z* is a valid search): the row limit bounds the result.
      // No object type chosen means every object type.
      if (!c.kinds) {
        c.kinds = 'SDVTE';
        Array.prototype.forEach.call(box.querySelectorAll('[data-kind]'), function (k) { k.checked = true; });
      }
      list.innerHTML = '<div class="empty">' + esc(T('Aranıyor...', 'Searching...')) + '</div>';
      info.textContent = '';
      // The answer opens this dialog again with the results (see App.onHostEvent).
      S.pendingSearch = c;
      S.ifDraft = { name: document.getElementById('ifName').value, type: document.getElementById('ifType').value };
      Bridge.send('DDIC_SEARCH', { lines: [['q', c.q], ['kinds', c.kinds], ['pkg', c.pkg], ['max', c.max]].concat(App.stateLines()) });
    }
    function show(result) {
      var rows = result.data || [];
      if (!result.ok) { list.innerHTML = '<div class="empty">' + esc(result.message) + '</div>'; return; }
      if (!rows.length) { list.innerHTML = '<div class="empty">' + esc(T('Sonuç yok.', 'No results.')) + '</div>'; return; }
      list.innerHTML = '<table class="grid ddgrid"><thead><tr><th>' + esc(T('Ad', 'Name')) + '</th><th>' + esc(T('Tip', 'Type')) + '</th><th>' + esc(T('Açıklama', 'Description')) + '</th><th>' + esc(T('Paket', 'Package')) + '</th></tr></thead><tbody>' +
        rows.map(function (r) {
          var type = r.type || r.kind;
          return '<tr class="pk-item" data-name="' + esc(r.name) + '"><td>' + icon(r.kind === 'T' ? 'table' : r.kind === 'S' ? 'struct' : 'elem') + ' <b>' + esc(r.name) + '</b></td><td>' +
            esc(kindLabel[type] || type) + '</td><td>' + esc(r.descr || '') + '</td><td>' + esc(r.package || '') + '</td></tr>';
        }).join('') + '</tbody></table>';
      info.textContent = rows.length + ' ' + T('sonuç', 'results') + (rows.length >= Number(crit.max || 100)
        ? ' - ' + T('satır sınırına ulaşıldı; aramayı daraltın veya sınırı artırın', 'the row limit was reached; narrow the search or raise the limit') : '') +
        '. ' + T('Seçmek için satıra tıklayın.', 'Click a row to choose it.');
    }
    if (answer) show(answer);

    box.querySelector('#ddGo').addEventListener('click', go);
    box.querySelector('#ddAll').addEventListener('click', function (ev) {
      ev.preventDefault();
      Array.prototype.forEach.call(box.querySelectorAll('[data-kind]'), function (c) { c.checked = true; });
    });
    Array.prototype.forEach.call(box.querySelectorAll('#ddQ,#ddPkg'), function (input) {
      input.addEventListener('keydown', function (ev) { if (ev.key === 'Enter') { ev.stopPropagation(); ev.preventDefault(); go(); } });
    });
    list.addEventListener('click', function (ev) {
      var item = ev.target.closest('.pk-item');
      if (!item) return;
      Dialog.close();
      S.pendingSearch = null;
      S.ifDraft = null;
      document.getElementById('ifType').value = item.dataset.name;
      // The name stays the user's decision: it is only focused when it is still empty.
      var name = document.getElementById('ifName');
      (name.value.trim() ? document.getElementById('ifType') : name).focus();
    });
  },

  applySample: function (reset) {
    if (reset) {
      S.doc.sample = '';
      App.commit();
      return App.toast(T('Önizleme verisi arayüzden oluşturuldu.', 'The preview data was generated from the interface.'));
    }
    var text = document.getElementById('sampleText').value;
    try {
      if (text.trim()) JSON.parse(text);
    } catch (err) {
      return App.toast(T('JSON geçersiz: ', 'Invalid JSON: ') + err.message, true);
    }
    S.doc.sample = text;
    App.commit();
    App.toast(T('Önizleme verisi güncellendi.', 'The preview data was updated.'));
  },

  init: function () {
    var self = this;
    document.getElementById('formTab').addEventListener('change', function (ev) {
      var key = ev.target.dataset.dk;
      if (!key || !App.canEdit()) return;
      var value = ev.target.type === 'number' ? num(ev.target.value, 0) : ev.target.value;
      var parts = key.split('.');
      if (parts.length === 2) S.doc[parts[0]][parts[1]] = value; else S.doc[key] = value;
      App.commit();
    });
    document.getElementById('formTab').addEventListener('click', function (ev) {
      var act = ev.target.closest('[data-act]');
      if (act) App.run(act.dataset.act);
    });
    var iface = document.getElementById('ifaceTab');
    iface.addEventListener('click', function (ev) {
      var act = ev.target.closest('[data-act]');
      if (act) { App.run(act.dataset.act); return; }
      var pa = ev.target.closest('[data-pa]');
      if (pa && App.canEdit()) self.paramAction(pa.dataset.pa, Number(pa.dataset.i));
    });
    iface.addEventListener('keydown', function (ev) {
      if (ev.key === 'Enter' && (ev.target.id === 'ifName' || ev.target.id === 'ifType')) { ev.preventDefault(); self.addParam(); }
    });
  }
};
