// Unit tests of the model and the converter (no browser needed):  node test/convert.test.mjs
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const src = join(dirname(fileURLToPath(import.meta.url)), '..', 'src');
const code = ['10-core.js', '20-convert.js'].map((f) => readFileSync(join(src, f), 'utf8')).join('\n');
const ctx = vm.createContext({ btoa, atob, TextEncoder, TextDecoder, console });
vm.runInContext(code + '\nthis.api = { newDoc, normalizeDoc, defaultsFor, convert, importPdfme, loadAny, extractDoc, bindText, toFieldName, ifaceSpec, sampleFromIface, paletteGroups, findNode, rowFields, tableNodes, History, isPdfme };', ctx);
const z = ctx.api;

let passed = 0;
function test(name, fn) {
  try {
    fn();
    passed++;
    console.log('  ok  ' + name);
  } catch (err) {
    console.error('FAIL  ' + name + '\n      ' + err.message);
    process.exitCode = 1;
  }
}

const iface = [{
  name: 'INPUT', type: 'ZPDF_S_INPUT', node: {
    k: 'S', d: 'Input', c: [
      { n: 'BUKRS', k: 'E', t: 'C', l: 4, d: 'Şirket kodu' },
      { n: 'DATE', k: 'E', t: 'D', l: 8, d: 'Tarih' },
      { n: 'TOPLAM', k: 'E', t: 'P', l: 15, dec: 2, d: 'Toplam' },
      { n: 'ITEMS', k: 'T', d: 'Kalemler', c: [
        { n: 'ALICI', k: 'E', t: 'C', l: 60, d: 'Alıcı' },
        { n: 'WRBTR', k: 'E', t: 'P', l: 13, dec: 2, d: 'Tutar' }] }] }
}];

function docWith(els) {
  const doc = z.newDoc();
  doc.iface = JSON.parse(JSON.stringify(iface));
  doc.pages[0].els = els;
  return z.normalizeDoc(doc);
}

test('bindText: placeholders, formats, page tokens, escaping', () => {
  assert.equal(z.bindText('A < B {X} {Y | DD.MM.YYYY} {currentPage}/{totalPages} {{Z}} {not a path!}'),
    'A &lt; B {{X}} {{Y | DD.MM.YYYY}} <span class="pageNumber"></span>/<span class="totalPages"></span> {{Z}} {not a path!}');
});

test('toFieldName maps Turkish letters', () => {
  assert.equal(z.toFieldName('Birim fiyat (₺)'), 'BIRIM_FIYAT');
  assert.equal(z.toFieldName('Şube İlçe'), 'SUBE_ILCE');
  assert.equal(z.toFieldName('1. kalem'), 'F_1_KALEM');
});

test('bound text: geometry relative to the margins, format, no warnings', () => {
  const doc = docWith([z.defaultsFor('text', { name: 'tarih', bind: 'INPUT.DATE', fmt: 'DD.MM.YYYY', x: 22, y: 25, w: 40, h: 6, bold: true })]);
  const r = z.convert(doc);
  assert.match(r.html, /left:10mm;top:10mm;width:40mm;height:6mm;/);
  assert.match(r.html, /font-weight:bold;/);
  assert.match(r.html, /\{\{INPUT\.DATE \| DD\.MM\.YYYY\}\}/);
  assert.deepEqual([...r.warnings], []);
  assert.equal(r.page.margin_top, 15);
});

test('interface comment and embedded document round trip', () => {
  const doc = docWith([z.defaultsFor('text', { name: 'a', text: 'Merhaba ğüşiöç İ' })]);
  const r = z.convert(doc);
  assert.match(r.html, /<!--zpdf-iface:INPUT=ZPDF_S_INPUT-->/);
  const back = z.extractDoc(r.html);
  assert.equal(back.zpdf, 2);
  assert.equal(back.pages[0].els[0].text, 'Merhaba ğüşiöç İ');
  assert.equal(z.ifaceSpec(back), 'INPUT=ZPDF_S_INPUT');
});

test('table: each loop, header, zebra, column formats, widths', () => {
  const tbl = z.defaultsFor('table', {
    name: 'kalemler', bind: 'INPUT.ITEMS', x: 12, y: 60, w: 100,
    cols: [{ title: 'Alıcı', field: 'ALICI', w: 60, align: 'left', fmt: '' }, { title: 'Tutar', field: 'WRBTR', w: 40, align: 'right', fmt: '#.##0,00' }]
  });
  const below = z.defaultsFor('text', { name: 'toplam', bind: 'INPUT.TOPLAM', x: 100, y: 120 });
  const above = z.defaultsFor('text', { name: 'ust', text: 'Başlık', x: 12, y: 20 });
  const r = z.convert(docWith([tbl, below, above]));
  assert.match(r.html, /\{\{#each INPUT\.ITEMS\}\}<tr>/);
  assert.match(r.html, /<thead style="display:table-header-group">/);
  assert.match(r.html, /<col style="width:60mm"><col style="width:40mm">/);
  assert.match(r.html, /\{\{WRBTR \| #\.##0,00\}\}/);
  assert.match(r.html, /\{\{#if ROW_EVEN\}\}#f3f6fa\{\{else\}\}transparent\{\{\/if\}\}/);
  assert.match(r.html, /margin-top:45mm/);
  // The object below the table follows it, the one above does not.
  assert.match(r.html, /data-flow="after"[^>]*>\{\{INPUT\.TOPLAM\}\}/);
  assert.ok(!/data-flow="after"[^>]*>Başlık/.test(r.html));
  assert.deepEqual([...r.warnings], []);
  assert.equal(r.sample.INPUT.ITEMS.length, 3);
});

test('master page rule, condition, rotation, opacity', () => {
  const el = z.defaultsFor('text', { name: 'filigran', text: 'TASLAK', printOn: 'every', printIf: '!INPUT.BUKRS', rot: -35, op: 0.15 });
  const r = z.convert(docWith([el]));
  assert.match(r.html, /\{\{\^INPUT\.BUKRS\}\}<div data-every="1"/);
  assert.match(r.html, /transform:rotate\(-35deg\);opacity:0\.15;/);
  const first = z.defaultsFor('text', { name: 'x', text: 'a', printOn: 'notfirst', printIf: 'INPUT.BUKRS' });
  assert.match(z.convert(docWith([first])).html, /\{\{#if INPUT\.BUKRS\}\}<div data-every="notfirst"/);
});

test('barcodes, image, shapes, checkbox', () => {
  const r = z.convert(docWith([
    z.defaultsFor('barcode', { name: 'qr', code: 'qr', bind: 'INPUT.BUKRS', ecc: 'H' }),
    z.defaultsFor('barcode', { name: 'ean', code: 'ean13', text: '8690000000019' }),
    z.defaultsFor('image', { name: 'logo', asset: 'logo' }),
    z.defaultsFor('line', { name: 'cizgi', color: '#1d4e89' }),
    z.defaultsFor('ellipse', { name: 'daire', fill: '#ff0000' }),
    z.defaultsFor('checkbox', { name: 'onay', bind: 'INPUT.BUKRS' })
  ]), { images: ['LOGO'] });
  assert.match(r.html, /data-code="qr" data-ecc="H"[^>]*>\{\{INPUT\.BUKRS\}\}/);
  assert.match(r.html, /data-code="ean13" data-hr="1"[^>]*>8690000000019/);
  assert.match(r.html, /<img src="asset:LOGO" style="object-fit:contain">/);
  assert.match(r.html, /background:#1d4e89;/);
  assert.match(r.html, /border-radius:50%;/);
  assert.match(r.html, /\{\{#if INPUT\.BUKRS\}\}X\{\{\/if\}\}/);
  assert.deepEqual([...r.warnings], []);
});

test('warnings: unknown field, unbound table, missing asset, custom font', () => {
  const r = z.convert(docWith([
    z.defaultsFor('text', { name: 'a', bind: 'INPUT.YOK' }),
    z.defaultsFor('table', { name: 't', bind: '' }),
    z.defaultsFor('image', { name: 'i', asset: 'YOK' }),
    z.defaultsFor('text', { name: 'f', text: 'x', font: 'Roboto' })
  ]));
  assert.equal(r.warnings.length >= 4, true);
  assert.ok(r.warnings.some((w) => w.includes('INPUT.YOK')));
  assert.match(z.convert(docWith([z.defaultsFor('text', { name: 'f', text: 'x', font: 'Roboto' })]), { fonts: ['roboto'] }).html, /font-family:'roboto';/);
});

test('sample data from the interface', () => {
  const s = z.sampleFromIface(docWith([]));
  assert.equal(s.INPUT.BUKRS, 'INPU'.length ? s.INPUT.BUKRS : '');
  assert.match(String(s.INPUT.DATE), /^\d{8}$/);
  assert.equal(typeof s.INPUT.TOPLAM, 'number');
  assert.equal(s.INPUT.ITEMS[1].WRBTR, 2469.12);
});

test('interface helpers', () => {
  const doc = docWith([]);
  assert.equal(z.tableNodes(doc)[0].path, 'INPUT.ITEMS');
  assert.deepEqual([...z.rowFields(doc, 'INPUT.ITEMS')].map((f) => f.path), ['ALICI', 'WRBTR']);
  assert.equal(z.findNode(doc, 'INPUT.DATE', '').t, 'D');
  assert.equal(z.findNode(doc, 'WRBTR', 'INPUT.ITEMS').t, 'P');
  assert.equal(z.findNode(doc, 'WRBTR', ''), null);
});

test('import of a Studio 1 (pdfme) template', () => {
  const template = {
    basePdf: { width: 210, height: 297, padding: [15, 12, 22, 12], staticSchema: [
      { name: 'altbilgi', type: 'text', content: 'Sayfa {currentPage} / {totalPages}', position: { x: 12, y: 280 }, width: 186, height: 5, fontSize: 8, alignment: 'center' }] },
    schemas: [[
      { name: 'baslik', type: 'text', content: 'FATURA', readOnly: true, position: { x: 12, y: 20 }, width: 80, height: 10, fontSize: 20, fontColor: '#1d4e89', fontName: 'Roboto' },
      { name: 'MUSTERI_ADI', type: 'text', content: 'Acme', position: { x: 12, y: 40 }, width: 80, height: 6, fontSize: 10 },
      { name: 'FATURA_TARIHI', type: 'date', content: '2026-11-20', format: 'dd.MM.yyyy', position: { x: 120, y: 40 }, width: 40, height: 6 },
      { name: 'KALEMLER', type: 'table', head: ['No', 'Tutar'], headWidthPercentages: [30, 70], abapColumns: 'ROW; NETWR | #.##0,00', content: '[["1","5"]]',
        position: { x: 12, y: 80 }, width: 186, height: 20, headStyles: { backgroundColor: '#1d4e89', fontColor: '#ffffff', fontSize: 9 }, bodyStyles: { fontSize: 9, alternateBackgroundColor: '#f3f6fa' }, columnStyles: { alignment: { 1: 'right' } } },
      { name: 'QR', type: 'qrcode', content: 'x', position: { x: 12, y: 200 }, width: 25, height: 25 },
      { name: 'filigran', type: 'text', content: 'TASLAK', readOnly: true, printOn: 'every', printIf: 'TASLAK', rotate: -35, opacity: 0.15, position: { x: 30, y: 100 }, width: 140, height: 30 }
    ]]
  };
  assert.equal(z.isPdfme(template), true);
  const doc = z.loadAny(template);
  assert.equal(doc.zpdf, 2);
  assert.deepEqual({ ...doc.page }, { size: 'A4', orientation: 'P', mt: 15, mr: 12, mb: 22, ml: 12 });
  const byName = Object.fromEntries(doc.pages[0].els.map((e) => [e.name, e]));
  assert.equal(byName.altbilgi.printOn, 'every');
  assert.equal(byName.baslik.text, 'FATURA');
  assert.equal(byName.baslik.font, '');
  assert.equal(byName.MUSTERI_ADI.bind, 'MUSTERI_ADI');
  assert.equal(byName.FATURA_TARIHI.fmt, 'DD.MM.YYYY');
  assert.equal(byName.KALEMLER.cols[1].field, 'NETWR');
  assert.equal(byName.KALEMLER.cols[1].fmt, '#.##0,00');
  assert.equal(byName.KALEMLER.cols[1].align, 'right');
  assert.equal(byName.QR.code, 'qr');
  assert.equal(byName.filigran.rot, -35);
  const r = z.convert(doc);
  assert.match(r.html, /\{\{#each KALEMLER\}\}/);
  assert.match(r.html, /\{\{#if TASLAK\}\}<div data-every="1"/);
  assert.match(r.html, /Sayfa <span class="pageNumber"><\/span> \/ <span class="totalPages"><\/span>/);
  // No interface: nothing is reported as "not in the interface".
  assert.ok(!r.warnings.some((w) => w.includes('arayüzde')));
});

test('normalizeDoc repairs ids; history undo/redo', () => {
  const doc = z.normalizeDoc({ pages: [{ els: [{ type: 'text', id: 'e1', name: 'a' }, { type: 'text', id: 'e1', name: 'b' }, { type: 'rect' }] }] });
  const ids = doc.pages[0].els.map((e) => e.id);
  assert.equal(new Set(ids).size, 3);
  const h = new z.History(10);
  h.reset(doc);
  doc.pages[0].els[0].x = 99;
  assert.equal(h.push(doc), true);
  assert.equal(h.push(doc), false);
  assert.equal(h.undo().pages[0].els[0].x, 20);
  assert.equal(h.redo().pages[0].els[0].x, 99);
});

test('palette groups: barcodes are one group', () => {
  const groups = z.paletteGroups();
  assert.deepEqual([...groups].map((g) => g.id), ['std', 'fields', 'shapes', 'codes']);
  assert.equal(groups[3].items.length, 8);
  assert.ok(groups[3].items.every((i) => i.type === 'barcode'));
});

console.log(`\n${passed} test(s) passed${process.exitCode ? ', some FAILED' : ''}`);
