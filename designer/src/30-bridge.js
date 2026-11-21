/* ZPDF Studio Designer 2 - bridge between the page and ABAP (ZCL_PDF_STUDIO_UI).
 *
 * ABAP -> page: the JSON in <script id="zpdf-boot"> (form, language, stored document, sample
 *   data, UI state, assets, a message, and the answer to the request that caused this display).
 * page -> ABAP: a hidden form is POSTed to "sapevent:<ACTION>". Body: one field "payload" =
 *   base64( UTF-8 lines "META<TAB>name<TAB>base64(value)" ).
 *
 * There is exactly one way back: ABAP shows the whole page again. The Edge control of SAP GUI
 * ignores the frame of show_url and replaces the whole page, so an answer sent "into a hidden
 * frame" wipes the designer. Therefore every request carries the complete state of the page
 * (design, UI state), ABAP shows the page again from that state and puts its answer into the boot
 * data; App.onHostEvent handles it. Only SYNC, PREVIEW and EXIT have no new display.
 * The undo history travels in window.name across the display.
 */

var SINK = 'zpdf-sink';

function readBoot() {
  var node = document.getElementById('zpdf-boot');
  var raw = node ? node.textContent.trim() : '';
  if (!raw || raw.indexOf('__') === 0) return { runtime: 'browser' };
  try {
    return JSON.parse(raw);
  } catch (err) {
    return { runtime: 'browser', bootError: String(err) };
  }
}

var Bridge = {
  boot: { runtime: 'browser' },
  seq: 0,

  get isSap() { return this.boot.runtime === 'sap'; },

  encode: function (lines) {
    var text = lines.map(function (l) { return 'META\t' + l[0] + '\t' + toBase64(l[1] === undefined || l[1] === null ? '' : String(l[1])); }).join('\n');
    return toBase64(text);
  },

  post: function (action, lines) {
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = 'sapevent:' + action;
    form.target = SINK;
    form.style.display = 'none';
    var field = document.createElement('textarea');
    field.name = 'payload';
    field.value = this.encode(lines);
    form.appendChild(field);
    document.body.appendChild(form);
    form.submit();
    window.setTimeout(function () { form.remove(); }, 1500);
  },

  /**
   * Sends an action.
   * @param options { lines: [[name, value]], quiet: true when ABAP does not show the page again }
   * The answer arrives through App.onHostEvent: with the boot data of the next display inside
   * SAP, directly from the stand-in in the browser.
   */
  send: function (action, options) {
    options = options || {};
    var id = ++this.seq;
    var lines = [['req', String(id)]].concat(options.lines || []);
    if (!this.isSap) {
      Mock.handle(action, lines);
      return id;
    }
    if (!options.quiet) {
      App.stash();
      App.busy(true);
    }
    this.post(action, lines);
    return id;
  },

  /** Answer object of the boot data -> { ok, message, data, kind }. */
  decode: function (answer) {
    var data = null;
    if (answer && answer.data64) {
      try { data = JSON.parse(fromBase64(answer.data64)); } catch (err) { data = null; }
    }
    return { ok: !answer || answer.ok !== false, message: (answer && answer.message) || '', data: data, kind: (answer && answer.kind) || '' };
  }
};

// ---------------------------------------------------------------------------------------------
// Browser mode (development and tests): ABAP is replaced by a small local stand-in
// ---------------------------------------------------------------------------------------------

var Mock = {
  key: 'zpdf-studio2:',
  types: {
    ZPDF_S_INPUT: {
      k: 'S', d: 'ZPDF Studio örnek giriş yapısı', c: [
        { n: 'BUKRS', k: 'E', t: 'C', l: 4, d: 'Şirket kodu' },
        { n: 'TALIMAT', k: 'E', t: 'C', l: 100, d: 'Talimat' },
        { n: 'DATE', k: 'E', t: 'D', l: 8, d: 'Tarih' },
        { n: 'GONDEREN_BANKA', k: 'E', t: 'C', l: 100, d: 'Gönderen banka' },
        { n: 'GONDEREN_SUBE', k: 'E', t: 'C', l: 100, d: 'Gönderen şube' },
        { n: 'GONDEREN_IBAN', k: 'E', t: 'C', l: 34, d: 'Gönderen IBAN' },
        { n: 'KUR', k: 'E', t: 'P', l: 9, dec: 5, d: 'Kur' },
        { n: 'TOPLAM', k: 'E', t: 'P', l: 15, dec: 2, d: 'Toplam tutar' },
        {
          n: 'ITEMS', k: 'T', d: 'Kalemler', c: [
            { n: 'ALICI', k: 'E', t: 'C', l: 60, d: 'Alıcı adı' },
            { n: 'ALICI_IBAN', k: 'E', t: 'C', l: 34, d: 'IBAN' },
            { n: 'WRBTR', k: 'E', t: 'P', l: 13, dec: 2, d: 'Tutar' },
            { n: 'WAERS', k: 'E', t: 'C', l: 5, d: 'Para birimi' },
            { n: 'ACIKLAMA', k: 'E', t: 'C', l: 50, d: 'Açıklama' }
          ]
        }
      ]
    },
    T001: {
      k: 'S', d: 'Şirket kodları', c: [
        { n: 'BUKRS', k: 'E', t: 'C', l: 4, d: 'Şirket kodu' },
        { n: 'BUTXT', k: 'E', t: 'C', l: 25, d: 'Şirket adı' },
        { n: 'ORT01', k: 'E', t: 'C', l: 25, d: 'Şehir' },
        { n: 'WAERS', k: 'E', t: 'C', l: 5, d: 'Para birimi' }
      ]
    },
    BUKRS: { k: 'E', t: 'C', l: 4, d: 'Şirket kodu' }
  },

  store: function (name, value) {
    try {
      if (value === undefined) return localStorage.getItem(this.key + name);
      localStorage.setItem(this.key + name, value);
    } catch (err) { /* storage can be unavailable */ }
    return null;
  },

  handle: function (action, lines) {
    var args = {};
    lines.forEach(function (l) { args[l[0]] = l[1]; });
    var kinds = { SAVE: 'save', PREVIEW: 'preview', DDIC_SEARCH: 'ddic_search', DDIC_RESOLVE: 'ddic_resolve', VERSIONS: 'versions' };
    var answer = { ok: true, message: '', data: null, kind: kinds[action] || '' };
    switch (action) {
      case 'SYNC':
        if (args.autosave === 'X') this.store('draft', args.html);
        return;
      case 'PREFS':
        this.store('prefs', args.prefs);
        return;
      case 'EXIT':
      case 'RELOAD':
        return;
      case 'SAVE':
        this.store('saved', args.html);
        this.store('sample', args.sample || '');
        answer.message = T('Tarayıcıda saklandı (SAP içinde ZPDF_STUDIO_FORM tablosuna kaydedilir).', 'Stored in the browser (inside SAP it is saved to table ZPDF_STUDIO_FORM).');
        answer.data = { version: '0001' };
        break;
      case 'PREVIEW': {
        var win = window.open('', '_blank');
        if (win) {
          var doc = extractDoc(args.html);
          var dims = pageDims(doc.page);
          win.document.write('<!doctype html><meta charset="utf-8"><title>ZPDF Studio HTML</title><body style="margin:0;background:#ddd">' +
            '<div style="position:relative;background:#fff;margin:20px auto;width:' + dims.w + 'mm;min-height:' + dims.h + 'mm;box-sizing:border-box;padding:' +
            doc.page.mt + 'mm ' + doc.page.mr + 'mm ' + doc.page.mb + 'mm ' + doc.page.ml + 'mm"><div style="position:relative">' + args.html + '</div></div></body>');
          win.document.close();
        }
        answer.message = T('Tarayıcı modu: motor HTML\'i yeni pencerede gösterildi.', 'Browser mode: the engine HTML is shown in a new window.');
        break;
      }
      case 'DDIC_SEARCH': {
        var q = String(args.q || '').toUpperCase().replace(/\*/g, '');
        var kinds = String(args.kinds || 'SDVTE');
        var pkg = String(args.pkg || '').toUpperCase().replace(/\*/g, '');
        var self = this;
        answer.data = Object.keys(this.types).filter(function (name) {
          var t = self.types[name];
          var type = t.k === 'S' ? (name === 'T001' ? 'D' : 'S') : t.k;
          return name.indexOf(q) >= 0 && kinds.indexOf(type) >= 0 && '$ZPDF_STUDIO'.indexOf(pkg) === 0;
        }).slice(0, Number(args.max) || 100).map(function (name) {
          var t = self.types[name];
          return { name: name, kind: t.k, type: t.k === 'S' ? (name === 'T001' ? 'D' : 'S') : t.k, descr: t.d, package: '$ZPDF_STUDIO' };
        });
        break;
      }
      case 'DDIC_RESOLVE': {
        var type = this.types[String(args.type || '').toUpperCase()];
        if (type) answer.data = clone(type);
        else { answer.ok = false; answer.message = T('Tip bulunamadı: ', 'Type not found: ') + args.type; }
        break;
      }
      case 'VERSIONS':
        answer.data = [{ version: '0001', active: true, user: 'DEMO', at: '20261120101500' }];
        break;
      case 'UPLOAD_ASSET':
        answer.message = args.asset_id + T(' tarayıcıda saklandı.', ' stored in the browser.');
        break;
      default:
        answer.ok = false;
        answer.message = T('Bu işlem yalnızca SAP içinde yapılabilir: ', 'This action is only available inside SAP: ') + action;
    }
    window.setTimeout(function () { App.onHostEvent(answer); }, 30);
  }
};
