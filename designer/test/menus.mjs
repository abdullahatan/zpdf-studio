// End-to-end test of every menu item of dist/designer.html in headless Chrome.
// Every item is opened and clicked with the real mouse; the effect is checked on the state,
// on the page (DOM) and, inside the SAP harness, on the request posted to ABAP.
// Usage: node menus.mjs <output folder>   (prints one line per check, writes menus-report.json)
import puppeteer from 'puppeteer-core';
import { readFileSync, writeFileSync } from 'node:fs';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { join } from 'node:path';

const dist = fileURLToPath(new URL('../dist/designer.html', import.meta.url));
const out = process.argv[2] || '.';
const rows = [];
let failed = 0;
function check(menu, item, what, cond, extra) {
  rows.push({ menu, item, what, ok: !!cond, extra: cond ? '' : String(extra === undefined ? '' : extra) });
  if (!cond) failed++;
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const near = (a, b, tol) => Math.abs(a - b) <= (tol === undefined ? 0.011 : tol);

const browser = await puppeteer.launch({ executablePath: process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true, args: ['--no-sandbox'] });
const page = await browser.newPage();
await page.setViewport({ width: 1600, height: 900 });
const errors = [];
page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
page.on('console', (m) => { if (m.type() === 'error') errors.push('console: ' + m.text()); });
await page.evaluateOnNewDocument(() => {
  try { if (!sessionStorage.getItem('kept')) { localStorage.clear(); sessionStorage.setItem('kept', '1'); } } catch (e) {}
  // a download is recorded instead of written to disk
  window.__downloads = [];
  HTMLAnchorElement.prototype.click = function () { if (this.download) window.__downloads.push({ name: this.download, href: this.href }); };
});
await page.goto(pathToFileURL(dist).href);
await page.waitForSelector('#menubar .menu');

// ---------------------------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------------------------
const covered = new Set();

/** Opens a menu of the menu bar with the mouse. */
async function openMenu(p, id) {
  await p.evaluate(() => window.ZPDF.Menus.close());
  await p.click('#menubar .menu[data-menu="' + id + '"] .mtitle');
  await p.waitForSelector('#menubar .menu[data-menu="' + id + '"] .dropdown');
}

/** Finds an item by its labels below a root (menu bar dropdown or context menu); hovers the submenu. */
async function findItem(p, rootSelector, labels) {
  let scope = await p.$(rootSelector);
  if (!scope) return { state: 'no-menu' };
  for (let i = 0; i < labels.length; i++) {
    const handle = await p.evaluateHandle((node, label) => {
      const kids = Array.prototype.filter.call(node.children, (k) => k.classList.contains('mi'));
      return kids.filter((k) => { const l = k.querySelector(':scope > .mlbl'); return l && l.textContent === label; })[0] || null;
    }, scope, labels[i]);
    const el = handle.asElement();
    if (!el) return { state: 'missing', at: labels[i] };
    if (i < labels.length - 1) {
      await el.hover();
      await sleep(40);
      scope = await el.$(':scope > .submenu');
      if (!scope) return { state: 'no-submenu', at: labels[i] };
      const shown = await scope.evaluate((n) => getComputedStyle(n).display !== 'none' && n.getBoundingClientRect().width > 0);
      if (!shown) return { state: 'submenu-hidden', at: labels[i] };
    } else {
      const info = await el.evaluate((n) => ({ dis: n.classList.contains('dis'), act: n.dataset.act || '', arg: n.dataset.arg, on: n.querySelector('.mchk').textContent === '✓' }));
      return Object.assign({ state: info.dis ? 'disabled' : 'ok', el }, info);
    }
  }
  return { state: 'missing' };
}

/** Clicks a menu item: pick(page, 'layout', 'Nesneleri hizala', 'Sola'). Returns 'ok' or why not. */
async function pick(p, menu, ...labels) {
  await openMenu(p, menu);
  const it = await findItem(p, '#menubar .menu[data-menu="' + menu + '"] .dropdown', labels);
  if (it.state !== 'ok') { await p.evaluate(() => window.ZPDF.Menus.close()); return it.state + (it.at ? ' (' + it.at + ')' : ''); }
  covered.add(menu + '|' + it.act + '|' + (it.arg === undefined ? '' : it.arg));
  await it.el.click();
  await sleep(60);
  return 'ok';
}

/** State of a menu item without clicking it: 'ok', 'disabled', 'missing' ... plus the check mark. */
async function peek(p, menu, ...labels) {
  await openMenu(p, menu);
  const it = await findItem(p, '#menubar .menu[data-menu="' + menu + '"] .dropdown', labels);
  await p.evaluate(() => window.ZPDF.Menus.close());
  return { state: it.state, on: !!it.on };
}

const state = (p) => p.evaluate(() => {
  const s = window.ZPDF.state();
  return JSON.parse(JSON.stringify({ tab: s.tab, sel: s.sel, dirty: s.dirty, zoom: s.zoom, view: s.view, panels: s.panels, theme: s.theme, autosave: s.autosave, version: s.version,
    pageIndex: s.pageIndex, pages: s.doc.pages.length, els: s.doc.pages[s.pageIndex].els, page: s.doc.page, clip: s.clip.length, assets: s.assets.map((a) => ({ id: a.id, kind: a.kind, family: a.family })),
    iface: s.doc.iface.map((x) => x.name), undo: s.history.canUndo(), redo: s.history.canRedo() }));
});
const dialog = (p) => p.evaluate(() => {
  const d = document.querySelector('.dlgback .dlg');
  return d ? { title: d.querySelector('header span').textContent, text: d.querySelector('.dlgbody').innerText, buttons: Array.prototype.map.call(d.querySelectorAll('footer .btn'), (b) => b.textContent) } : null;
});
const dialogButton = async (p, label) => {
  const h = await p.evaluateHandle((label) => Array.prototype.filter.call(document.querySelectorAll('.dlgback .dlg footer .btn'), (b) => b.textContent === label)[0] || null, label);
  if (!h.asElement()) return false;
  await h.asElement().click();
  await sleep(60);
  return true;
};
const toast = (p) => p.evaluate(() => { const t = document.getElementById('toast'); return { text: t.textContent, error: t.className === 'error', shown: t.className !== 'hidden' }; });
const escape = async (p) => { await p.keyboard.press('Escape'); await sleep(30); };
/** Sets up the page through the test hook (preparation only, never the action under test). */
const setup = (p, fn, arg) => p.evaluate(fn, arg);
const selectByClick = async (p, ids) => {
  await p.evaluate(() => window.ZPDF.App.select([]));
  for (let i = 0; i < ids.length; i++) {
    if (i) await p.keyboard.down('Shift');
    const box = await (await p.$('.el[data-id="' + ids[i] + '"]')).boundingBox();
    await p.mouse.click(box.x + 3, box.y + 3);
    if (i) await p.keyboard.up('Shift');
  }
  await sleep(40);
};

// ---------------------------------------------------------------------------------------------
// preparation: an interface, so that data fields and tables can be bound
// ---------------------------------------------------------------------------------------------
await page.click('.mtab[data-tab="iface"]');
await page.type('#ifName', 'INPUT');
await page.type('#ifType', 'ZPDF_S_INPUT');
await page.click('[data-act="ifaceAdd"]');
await sleep(200);
await page.click('.mtab[data-tab="layout"]');
await sleep(80);
let s = await state(page);
check('Hazırlık', 'Arayüz', 'INPUT = ZPDF_S_INPUT parametresi eklendi', s.iface.join() === 'INPUT');

// ---------------------------------------------------------------------------------------------
// EKLE (Insert): every object of the library, stored logos, new design page
// ---------------------------------------------------------------------------------------------
const groups = await page.evaluate(() => window.ZPDF.paletteGroups().map((g) => ({ label: g.label, items: g.items.map((i) => ({ id: i.id, label: i.label, type: i.type, code: i.props.code || '', fmt: i.props.fmt || '', printOn: i.props.printOn || '' })) })));
let count = 0;
for (const g of groups) {
  for (const item of g.items) {
    const before = (await state(page)).els.length;
    const r = await pick(page, 'insert', g.label, item.label);
    await sleep(120); // objects that need a field open the field picker
    const pickerOpen = await page.evaluate(() => !!document.querySelector('.picker'));
    if (pickerOpen) await escape(page);
    s = await state(page);
    const el = s.els[s.els.length - 1] || {};
    const onPage = await page.evaluate((id) => { const n = document.querySelector('.el[data-id="' + id + '"]'); return !!n && n.getBoundingClientRect().width > 0; }, el.id);
    const ok = r === 'ok' && s.els.length === before + 1 && el.type === item.type && (!item.code || el.code === item.code) && (!item.fmt || el.fmt === item.fmt) && (!item.printOn || el.printOn === item.printOn) && s.sel.length === 1 && s.sel[0] === el.id && onPage && s.tab === 'layout';
    check('Ekle', g.label + ' > ' + item.label, 'nesne sayfaya eklenir ve seçilir' + (['field', 'date', 'amount', 'words', 'table'].includes(item.id) ? '; alan seçici açılır' : ''),
      ok && (['field', 'date', 'amount', 'words', 'table'].includes(item.id) ? pickerOpen : true), JSON.stringify({ r, n: s.els.length, before, type: el.type, code: el.code, pickerOpen }));
    count++;
  }
}
check('Ekle', '(tümü)', count + ' kitaplık nesnesinin tamamı eklendi', (await state(page)).els.length === count);
await page.screenshot({ path: join(out, 'm01-insert-all.png') });
let logoState = await peek(page, 'insert', 'Kayıtlı logolar', '(depoda logo yok)');
check('Ekle', 'Kayıtlı logolar', 'depo boşken "(depoda logo yok)" gösterilir ve seçilemez', logoState.state === 'disabled', logoState.state);
let r = await pick(page, 'insert', 'Yeni tasarım sayfası');
s = await state(page);
check('Ekle', 'Yeni tasarım sayfası', 'ikinci tasarım sayfası açılır ve gösterilir', r === 'ok' && s.pages === 2 && s.pageIndex === 1 && s.els.length === 0 && (await page.$eval('#pageNav span', (n) => n.textContent)) === 'Sayfa 2 / 2', JSON.stringify({ r, pages: s.pages, idx: s.pageIndex }));
// back to one page (page navigation of the canvas)
await page.click('#pageNav [data-act="pageDel"]');
await dialogButton(page, 'Sil');
s = await state(page);
check('Ekle', 'Sayfa gezgini: sayfayı sil (−)', 'onaydan sonra tasarım sayfası silinir', s.pages === 1 && s.els.length === count, JSON.stringify({ pages: s.pages, n: s.els.length }));

// ---------------------------------------------------------------------------------------------
// DÜZENLE (Edit)
// ---------------------------------------------------------------------------------------------
await setup(page, () => window.ZPDF.App.select([]));
let dis = [await peek(page, 'edit', 'Kes'), await peek(page, 'edit', 'Kopyala'), await peek(page, 'edit', 'Çoğalt'), await peek(page, 'edit', 'Sil')].map((x) => x.state).join();
check('Düzenle', 'Kes / Kopyala / Çoğalt / Sil', 'seçim yokken pasif', dis === 'disabled,disabled,disabled,disabled', dis);
r = await pick(page, 'edit', 'Tümünü seç');
s = await state(page);
check('Düzenle', 'Tümünü seç', 'sayfadaki tüm nesneler seçilir', r === 'ok' && s.sel.length === count, r + ' ' + s.sel.length);
r = await pick(page, 'edit', 'Sil');
s = await state(page);
check('Düzenle', 'Sil', 'seçili nesneler silinir', r === 'ok' && s.els.length === 0 && s.sel.length === 0, r + ' ' + s.els.length);
r = await pick(page, 'edit', 'Geri al');
s = await state(page);
check('Düzenle', 'Geri al', 'silinen nesneler geri gelir', r === 'ok' && s.els.length === count && s.redo, r + ' ' + s.els.length);
r = await pick(page, 'edit', 'Yinele');
s = await state(page);
check('Düzenle', 'Yinele', 'geri alınan silme yeniden uygulanır', r === 'ok' && s.els.length === 0, r + ' ' + s.els.length);
await pick(page, 'insert', 'Standart', 'Metin');
s = await state(page);
const first = s.els[0];
r = await pick(page, 'edit', 'Kopyala');
s = await state(page);
check('Düzenle', 'Kopyala', 'seçili nesne panoya alınır, sayfa değişmez', r === 'ok' && s.clip === 1 && s.els.length === 1, r + ' ' + s.clip);
r = await pick(page, 'edit', 'Yapıştır');
s = await state(page);
check('Düzenle', 'Yapıştır', 'kopya 4 mm kaydırılarak eklenir ve seçilir', r === 'ok' && s.els.length === 2 && near(s.els[1].x, first.x + 4) && near(s.els[1].y, first.y + 4) && s.sel[0] === s.els[1].id && s.els[1].name !== first.name, JSON.stringify(s.els.map((e) => [e.x, e.y, e.name])));
r = await pick(page, 'edit', 'Çoğalt');
s = await state(page);
check('Düzenle', 'Çoğalt', 'seçili nesnenin kopyası eklenir', r === 'ok' && s.els.length === 3, r + ' ' + s.els.length);
r = await pick(page, 'edit', 'Kes');
s = await state(page);
check('Düzenle', 'Kes', 'nesne sayfadan kalkar, panoda kalır', r === 'ok' && s.els.length === 2 && s.clip === 1, r + ' ' + s.els.length);
r = await pick(page, 'edit', 'Yapıştır');
s = await state(page);
check('Düzenle', 'Yapıştır (kesilen)', 'kesilen nesne yeniden eklenir', r === 'ok' && s.els.length === 3, r + ' ' + s.els.length);
// shortcuts of the Edit menu
await page.keyboard.down('Control'); await page.keyboard.press('KeyZ'); await page.keyboard.up('Control');
s = await state(page);
check('Düzenle', 'Ctrl+Z', 'kısayol geri alır', s.els.length === 2, s.els.length);
await page.keyboard.down('Control'); await page.keyboard.press('KeyY'); await page.keyboard.up('Control');
s = await state(page);
check('Düzenle', 'Ctrl+Y', 'kısayol yineler', s.els.length === 3, s.els.length);
await page.keyboard.down('Control'); await page.keyboard.press('KeyA'); await page.keyboard.up('Control');
await page.keyboard.down('Control'); await page.keyboard.press('KeyD'); await page.keyboard.up('Control');
s = await state(page);
check('Düzenle', 'Ctrl+A, Ctrl+D', 'tümünü seçer ve çoğaltır', s.els.length === 6 && s.sel.length === 3, s.els.length + '/' + s.sel.length);
await page.keyboard.press('Delete');
s = await state(page);
check('Düzenle', 'Del', 'seçili nesneleri siler', s.els.length === 3, s.els.length);
// on another tab the page commands are not offered
await page.click('.mtab[data-tab="form"]');
await setup(page, () => { const st = window.ZPDF.state(); st.sel = [st.doc.pages[0].els[0].id]; });
dis = [await peek(page, 'edit', 'Sil'), await peek(page, 'edit', 'Yapıştır'), await peek(page, 'edit', 'Tümünü seç'), await peek(page, 'layout', 'Kilitle / kilidi aç')].map((x) => x.state).join();
await page.keyboard.down('Control'); await page.keyboard.press('KeyD'); await page.keyboard.up('Control');
s = await state(page);
check('Düzenle', 'Sayfa komutları', 'Form Özellikleri / Arayüz sekmesinde pasif; kısayolları da çalışmaz', dis === 'disabled,disabled,disabled,disabled' && s.els.length === 3, dis + ' ' + s.els.length);
await page.click('.mtab[data-tab="layout"]');

// ---------------------------------------------------------------------------------------------
// GÖRÜNÜM (View)
// ---------------------------------------------------------------------------------------------
const shownTab = () => page.evaluate(() => ['form', 'iface', 'layout'].filter((t) => document.getElementById(t + 'Tab').style.display !== 'none').join());
r = await pick(page, 'view', 'Form Özellikleri');
check('Görünüm', 'Form Özellikleri', 'Form Özellikleri sekmesi açılır', r === 'ok' && (await shownTab()) === 'form' && (await peek(page, 'view', 'Form Özellikleri')).on, r + ' ' + await shownTab());
r = await pick(page, 'view', 'Arayüz');
check('Görünüm', 'Arayüz', 'Arayüz sekmesi açılır', r === 'ok' && (await shownTab()) === 'iface', r + ' ' + await shownTab());
r = await pick(page, 'view', 'Düzen');
check('Görünüm', 'Düzen', 'Düzen sekmesi açılır', r === 'ok' && (await shownTab()) === 'layout', r + ' ' + await shownTab());
const paperBox = () => page.evaluate(() => { const b = document.getElementById('paper').getBoundingClientRect(); const sc = document.getElementById('scroller'); return { w: b.width, h: b.height, sw: sc.clientWidth, sh: sc.clientHeight }; });
const w100 = (await paperBox()).w;
r = await pick(page, 'view', 'Yakınlaştır');
s = await state(page);
check('Görünüm', 'Yakınlaştır', '%100 → %110; kâğıt büyür', r === 'ok' && s.zoom === 1.1 && near((await paperBox()).w, w100 * 1.1, 1) && (await page.$eval('.tb.zoomv', (n) => n.textContent)) === '110%', r + ' ' + s.zoom);
await pick(page, 'view', 'Uzaklaştır');
r = await pick(page, 'view', 'Uzaklaştır');
s = await state(page);
check('Görünüm', 'Uzaklaştır', '%110 → %100 → %90', r === 'ok' && s.zoom === 0.9, r + ' ' + s.zoom);
r = await pick(page, 'view', 'Gerçek boyut (%100)');
s = await state(page);
check('Görünüm', 'Gerçek boyut (%100)', 'yakınlaştırma %100 olur', r === 'ok' && s.zoom === 1 && near((await paperBox()).w, w100, 1), r + ' ' + s.zoom);
r = await pick(page, 'view', 'Sayfayı sığdır');
let pb = await paperBox();
check('Görünüm', 'Sayfayı sığdır', 'sayfanın tamamı çalışma alanına sığar', r === 'ok' && pb.h <= pb.sh && pb.w <= pb.sw && pb.h > pb.sh - 80, JSON.stringify(pb));
r = await pick(page, 'view', 'Genişliğe sığdır');
pb = await paperBox();
check('Görünüm', 'Genişliğe sığdır', 'sayfa genişliği çalışma alanını doldurur', r === 'ok' && near(pb.w, pb.sw - 60, 18), JSON.stringify(pb));
await pick(page, 'view', 'Gerçek boyut (%100)');
// + / - keys and Ctrl+0
await page.mouse.click(5, 895);
await page.keyboard.press('+');
s = await state(page);
const plusZoom = s.zoom;
await page.keyboard.press('-');
await page.keyboard.press('-');
s = await state(page);
const minusZoom = s.zoom;
await page.keyboard.down('Control'); await page.keyboard.press('Digit0'); await page.keyboard.up('Control');
s = await state(page);
check('Görünüm', '+ / − / Ctrl+0', 'klavyeyle kademeli yakınlaştırma ve %100', plusZoom === 1.1 && minusZoom === 0.9 && s.zoom === 1, [plusZoom, minusZoom, s.zoom].join());

const gridOn = () => page.$eval('#paper', (n) => n.style.backgroundImage !== 'none');
r = await pick(page, 'view', 'Izgara');
check('Görünüm', 'Izgara', 'ızgara noktaları gizlenir; işaret kalkar', r === 'ok' && !(await gridOn()) && !(await peek(page, 'view', 'Izgara')).on, r);
r = await pick(page, 'view', 'Izgara');
check('Görünüm', 'Izgara (tekrar)', 'ızgara yeniden gösterilir', r === 'ok' && (await gridOn()) && (await peek(page, 'view', 'Izgara')).on, r);
const rulerInk = () => page.$eval('#rulerH', (cv) => { const d = cv.getContext('2d').getImageData(0, 0, cv.width, cv.height).data; let n = 0; for (let i = 3; i < d.length; i += 4) if (d[i]) n++; return n; });
const inkOn = await rulerInk();
r = await pick(page, 'view', 'Cetveller');
const inkOff = await rulerInk();
check('Görünüm', 'Cetveller', 'cetvel çizgileri gizlenir', r === 'ok' && inkOn > 50 && inkOff === 0, inkOn + ' / ' + inkOff);
r = await pick(page, 'view', 'Cetveller');
check('Görünüm', 'Cetveller (tekrar)', 'cetveller yeniden çizilir', r === 'ok' && (await rulerInk()) > 50);
r = await pick(page, 'view', 'Kenar boşlukları');
check('Görünüm', 'Kenar boşlukları', 'kenar boşluğu kılavuzu gizlenir', r === 'ok' && (await page.$$eval('#paper .margins', (n) => n.length)) === 0, r);
r = await pick(page, 'view', 'Kenar boşlukları');
check('Görünüm', 'Kenar boşlukları (tekrar)', 'kılavuz yeniden gösterilir', r === 'ok' && (await page.$$eval('#paper .margins', (n) => n.length)) === 1, r);

// snapping is checked by dragging with the mouse
async function resetTwo() {
  return setup(page, () => {
    const st = window.ZPDF.state();
    const els = st.doc.pages[0].els;
    els.length = 2;
    Object.assign(els[0], { x: 30, y: 100, w: 50, h: 6, locked: false });
    Object.assign(els[1], { x: 47.3, y: 130, w: 50, h: 6, locked: false });
    st.sel = [];
    window.ZPDF.App.commit();
    return els.map((e) => e.id);
  });
}
async function dragBy(id, dxPx, dyPx) {
  const box = await (await page.$('.el[data-id="' + id + '"]')).boundingBox();
  const x = box.x + 6, y = box.y + box.height / 2;
  await page.mouse.move(x, y);
  await page.mouse.down();
  await page.mouse.move(x + dxPx / 2, y + dyPx / 2, { steps: 3 });
  await page.mouse.move(x + dxPx, y + dyPx, { steps: 3 });
  await page.mouse.up();
  await sleep(50);
}
const pxPerMm = 96 / 25.4;
let ids = await resetTwo();
// both snaps on (default): the grid decides
await pick(page, 'view', 'Nesnelere yasla'); // off
await dragBy(ids[1], 10, 0);
s = await state(page);
const snappedX = s.els[1].x;
r = await pick(page, 'view', 'Izgaraya yasla'); // off
ids = await resetTwo();
await dragBy(ids[1], 10, 0);
s = await state(page);
check('Görünüm', 'Izgaraya yasla', 'açıkken sürüklenen nesne ızgara adımına (1 mm) oturur; kapalıyken serbest konumda kalır',
  r === 'ok' && Number.isInteger(snappedX) && !Number.isInteger(s.els[1].x) && near(s.els[1].x, 47.3 + 10 / pxPerMm, 0.05), snappedX + ' / ' + s.els[1].x);
r = await pick(page, 'view', 'Nesnelere yasla'); // on again (grid still off)
ids = await resetTwo();
await dragBy(ids[1], (30 - 47.3) * pxPerMm + 2, 0);
s = await state(page);
const objSnapX = s.els[1].x;
await pick(page, 'view', 'Nesnelere yasla'); // off
ids = await resetTwo();
await dragBy(ids[1], (30 - 47.3) * pxPerMm + 2, 0);
s = await state(page);
check('Görünüm', 'Nesnelere yasla', 'açıkken nesne, yakınındaki nesnenin kenarına oturur (4 piksel içinde); kapalıyken oturmaz',
  r === 'ok' && near(objSnapX, 30, 0.001) && !near(s.els[1].x, 30, 0.1), objSnapX + ' / ' + s.els[1].x);
await pick(page, 'view', 'Izgaraya yasla');
await pick(page, 'view', 'Nesnelere yasla');
s = await state(page);
check('Görünüm', 'Izgaraya / Nesnelere yasla (tekrar)', 'ikisi de yeniden açılır', s.view.snapGrid && s.view.snapObj);

// preview data on the page
await setup(page, () => { const st = window.ZPDF.state(); const e = st.doc.pages[0].els[0]; e.bind = 'INPUT.GONDEREN_BANKA'; e.text = ''; window.ZPDF.App.commit(); });
const fieldText = () => page.evaluate(() => { const st = window.ZPDF.state(); return document.querySelector('.el[data-id="' + st.doc.pages[0].els[0].id + '"]').textContent; });
const tagText = await fieldText();
r = await pick(page, 'view', 'Önizleme verisini sayfada göster');
const sampleText = await fieldText();
check('Görünüm', 'Önizleme verisini sayfada göster', 'bağlı alanlar {ALAN} yerine önizleme verisinin değerini gösterir', r === 'ok' && tagText === '{INPUT.GONDEREN_BANKA}' && sampleText.length > 0 && sampleText.indexOf('{') < 0, tagText + ' / ' + sampleText);
await pick(page, 'view', 'Önizleme verisini sayfada göster');
check('Görünüm', 'Önizleme verisini sayfada göster (tekrar)', 'alan adları yeniden gösterilir', (await fieldText()) === '{INPUT.GONDEREN_BANKA}');
r = await pick(page, 'view', 'Tema', 'Koyu');
check('Görünüm', 'Tema > Koyu', 'koyu tema uygulanır, kullanıcı ayarı olarak saklanır; kâğıt beyaz kalır',
  r === 'ok' && (await page.evaluate(() => document.documentElement.getAttribute('data-theme') === 'dark' && JSON.parse(localStorage.getItem('zpdf-studio2:prefs')).theme === 'dark' && getComputedStyle(document.getElementById('paper')).backgroundColor === 'rgb(255, 255, 255)')), r);
r = await pick(page, 'view', 'Tema', 'Açık');
check('Görünüm', 'Tema > Açık', 'açık temaya dönülür', r === 'ok' && (await page.evaluate(() => document.documentElement.getAttribute('data-theme') === null)), r);

// ---------------------------------------------------------------------------------------------
// TABLO (Table)
// ---------------------------------------------------------------------------------------------
await setup(page, () => { const st = window.ZPDF.state(); st.doc.pages[0].els.length = 0; st.sel = []; window.ZPDF.App.commit(); });
dis = [await peek(page, 'table', 'Sütun ekle'), await peek(page, 'table', 'Son sütunu sil'), await peek(page, 'table', 'Sütunları eşit genişlikte yap'), await peek(page, 'table', 'Başlık satırı')].map((x) => x.state).join();
check('Tablo', 'Sütun komutları', 'tablo seçili değilken pasif', dis === 'disabled,disabled,disabled,disabled', dis);
r = await pick(page, 'table', 'Tablo ekle');
await sleep(150);
let picker = await page.$$eval('.picker .pk-item', (n) => n.map((x) => x.dataset.path));
check('Tablo', 'Tablo ekle', 'tablo sayfa genişliğinde eklenir; arayüz tabloları seçime sunulur', r === 'ok' && picker.join() === 'INPUT.ITEMS', r + ' ' + picker.join());
await page.click('.picker .pk-item[data-path="INPUT.ITEMS"]');
await sleep(80);
s = await state(page);
let tbl = s.els[0];
check('Tablo', 'Tablo ekle > arayüz tablosu seç', 'tablo INPUT.ITEMS tablosuna bağlanır; sütunlar satır alanlarından oluşur',
  tbl.bind === 'INPUT.ITEMS' && tbl.cols.length === 5 && tbl.cols[0].field === 'ALICI' && near(tbl.x, s.page.ml) && near(tbl.w, 210 - s.page.ml - s.page.mr), JSON.stringify({ bind: tbl.bind, cols: tbl.cols.map((c) => c.field) }));
r = await pick(page, 'table', 'Sütun ekle');
s = await state(page);
check('Tablo', 'Sütun ekle', 'tabloya bir sütun eklenir', r === 'ok' && s.els[0].cols.length === 6, r + ' ' + s.els[0].cols.length);
await pick(page, 'table', 'Son sütunu sil');
r = await pick(page, 'table', 'Son sütunu sil');
s = await state(page);
check('Tablo', 'Son sütunu sil', 'son sütun silinir', r === 'ok' && s.els[0].cols.length === 4 && s.els[0].cols[3].field === 'WAERS', r + ' ' + s.els[0].cols.map((c) => c.field).join());
r = await pick(page, 'table', 'Sütunları arayüz tablosundan oluştur');
s = await state(page);
check('Tablo', 'Sütunları arayüz tablosundan oluştur', 'sütunlar bağlı tablonun alanlarından yeniden oluşur', r === 'ok' && s.els[0].cols.map((c) => c.field).join() === 'ALICI,ALICI_IBAN,WRBTR,WAERS,ACIKLAMA', r + ' ' + s.els[0].cols.map((c) => c.field).join());
await setup(page, () => { const st = window.ZPDF.state(); const c = st.doc.pages[0].els[0].cols; c[0].w = 50; c[1].w = 10; window.ZPDF.App.commit(); });
r = await pick(page, 'table', 'Sütunları eşit genişlikte yap');
s = await state(page);
check('Tablo', 'Sütunları eşit genişlikte yap', 'tüm sütunlar %20 olur', r === 'ok' && s.els[0].cols.every((c) => c.w === 20), r + ' ' + s.els[0].cols.map((c) => c.w).join());
const tableRows = () => page.$$eval('#paper .el-table table tr', (n) => n.length);
const htmlOf = () => page.evaluate(() => window.ZPDF.App.converted().html);
const rowsBefore = await tableRows();
const theadBefore = (await htmlOf()).includes('<thead');
r = await pick(page, 'table', 'Başlık satırı');
s = await state(page);
check('Tablo', 'Başlık satırı', 'başlık satırı tasarımdan ve üretilen formdan kalkar', r === 'ok' && s.els[0].showHead === false && (await tableRows()) === rowsBefore - 1 && theadBefore && !(await htmlOf()).includes('<thead') && !(await peek(page, 'table', 'Başlık satırı')).on, r + ' ' + rowsBefore + '>' + await tableRows());
r = await pick(page, 'table', 'Başlık satırı');
check('Tablo', 'Başlık satırı (tekrar)', 'başlık satırı geri gelir', r === 'ok' && (await tableRows()) === rowsBefore && (await htmlOf()).includes('<thead') && (await peek(page, 'table', 'Başlık satırı')).on, r);
// a table without a binding cannot generate columns
await setup(page, () => { const st = window.ZPDF.state(); st.doc.pages[0].els[0].bind = ''; window.ZPDF.App.commit(); });
check('Tablo', 'Sütunları arayüz tablosundan oluştur', 'tablo bağlı değilken pasif', (await peek(page, 'table', 'Sütunları arayüz tablosundan oluştur')).state === 'disabled');
await page.screenshot({ path: join(out, 'm02-table.png') });

// ---------------------------------------------------------------------------------------------
// DÜZEN (Layout)
// ---------------------------------------------------------------------------------------------
async function three() {
  return setup(page, () => {
    const st = window.ZPDF.state();
    const A = window.ZPDF.App;
    st.doc.pages[0].els.length = 0;
    st.sel = [];
    const mk = (name, x, y, w, h, extra) => { A.addFromLibrary('text'); const e = st.doc.pages[0].els[st.doc.pages[0].els.length - 1]; Object.assign(e, { name, text: name, x, y, w, h, align: 'left', valign: 'top' }, extra || {}); return e.id; };
    const ids = [mk('A', 20, 30, 50, 6), mk('B', 60, 50, 30, 10), mk('C', 120, 90, 40, 8)];
    st.sel = [];
    A.commit();
    return ids;
  });
}
const pos = async () => (await state(page)).els.map((e) => ({ n: e.name, x: e.x, y: e.y, w: e.w, h: e.h }));
const byName = async () => Object.fromEntries((await pos()).map((e) => [e.n, e]));

ids = await three();
dis = [await peek(page, 'layout', 'Nesneleri hizala', 'Sola'), await peek(page, 'layout', 'Metni hizala', 'Sola'), await peek(page, 'layout', 'Sayfada ortala', 'Yatayda'), await peek(page, 'layout', 'En öne getir')].map((x) => x.state).join();
check('Düzen', 'Hizalama / sıra komutları', 'seçim yokken pasif', dis === 'disabled,disabled,disabled,disabled', dis);

const alignCases = [
  ['Sola', (e) => near(e.A.x, 20) && near(e.B.x, 20) && near(e.C.x, 20), 'sol kenarlar en soldaki nesneye (20 mm) hizalanır'],
  ['Yatayda ortala', (e) => near(e.A.x + 25, 90) && near(e.B.x + 15, 90) && near(e.C.x + 20, 90), 'yatay merkezler seçimin ortasına (90 mm) hizalanır'],
  ['Sağa', (e) => near(e.A.x + 50, 160) && near(e.B.x + 30, 160) && near(e.C.x + 40, 160), 'sağ kenarlar en sağdaki nesneye (160 mm) hizalanır'],
  ['Üste', (e) => near(e.A.y, 30) && near(e.B.y, 30) && near(e.C.y, 30), 'üst kenarlar en üstteki nesneye (30 mm) hizalanır'],
  ['Dikeyde ortala', (e) => near(e.A.y + 3, 64) && near(e.B.y + 5, 64) && near(e.C.y + 4, 64), 'dikey merkezler seçimin ortasına (64 mm) hizalanır'],
  ['Alta', (e) => near(e.A.y + 6, 98) && near(e.B.y + 10, 98) && near(e.C.y + 8, 98), 'alt kenarlar en alttaki nesneye (98 mm) hizalanır']
];
for (const [label, test, what] of alignCases) {
  ids = await three();
  await selectByClick(page, ids);
  r = await pick(page, 'layout', 'Nesneleri hizala', label);
  const e = await byName();
  check('Düzen', 'Nesneleri hizala > ' + label + ' (3 nesne)', what, r === 'ok' && test(e), r + ' ' + JSON.stringify(e));
}
const pg = (await state(page)).page;
const W = 210, H = 297;
const singleCases = [
  ['Sola', (e) => near(e.B.x, pg.ml) && near(e.B.y, 50), 'tek nesne sol kenar boşluğuna yaslanır'],
  ['Yatayda ortala', (e) => near(e.B.x + 15, (pg.ml + W - pg.mr) / 2), 'tek nesne yazdırılabilir alanın yatay ortasına gelir'],
  ['Sağa', (e) => near(e.B.x + 30, W - pg.mr), 'tek nesne sağ kenar boşluğuna yaslanır'],
  ['Üste', (e) => near(e.B.y, pg.mt) && near(e.B.x, 60), 'tek nesne üst kenar boşluğuna yaslanır'],
  ['Dikeyde ortala', (e) => near(e.B.y + 5, (pg.mt + H - pg.mb) / 2), 'tek nesne yazdırılabilir alanın dikey ortasına gelir'],
  ['Alta', (e) => near(e.B.y + 10, H - pg.mb), 'tek nesne alt kenar boşluğuna yaslanır']
];
for (const [label, test, what] of singleCases) {
  ids = await three();
  await selectByClick(page, [ids[1]]);
  r = await pick(page, 'layout', 'Nesneleri hizala', label);
  const e = await byName();
  check('Düzen', 'Nesneleri hizala > ' + label + ' (tek nesne)', what, r === 'ok' && test(e) && near(e.A.x, 20) && near(e.C.x, 120), r + ' ' + JSON.stringify(e.B));
}

// text alignment inside the box: state, canvas and the generated form
ids = await three();
await setup(page, (id) => { const st = window.ZPDF.state(); const e = st.doc.pages[0].els.filter((x) => x.id === id)[0]; e.bind = 'INPUT.TOPLAM'; e.text = ''; window.ZPDF.App.commit(); }, ids[1]);
await selectByClick(page, ids);
const textCss = (id) => page.evaluate((id) => { const t = document.querySelector('.el[data-id="' + id + '"] .t'); return { align: t.style.textAlign, v: t.style.justifyContent }; }, id);
const textCases = [['Ortaya', 'align', 'center', 'center'], ['Sağa', 'align', 'right', 'right'], ['Sola', 'align', 'left', 'left'], ['Dikeyde ortaya', 'valign', 'middle', 'center'], ['Alta', 'valign', 'bottom', 'flex-end'], ['Üste', 'valign', 'top', 'flex-start']];
for (const [label, prop, value, css] of textCases) {
  const xy = JSON.stringify((await pos()).map((e) => [e.x, e.y]));
  r = await pick(page, 'layout', 'Metni hizala', label);
  s = await state(page);
  const cssNow = await Promise.all(ids.map((id) => textCss(id)));
  const html = await htmlOf();
  const inHtml = prop === 'align' ? (html.match(new RegExp('text-align:' + value, 'g')) || []).length >= 3 : value === 'top' ? !html.includes('vertical-align:') : (html.match(new RegExp('vertical-align:' + value, 'g')) || []).length >= 3;
  const mark = (await peek(page, 'layout', 'Metni hizala', label)).on;
  check('Düzen', 'Metni hizala > ' + label, 'metin ve veri alanının yazısı kutusunun içinde hizalanır (tasarım + üretilen form); nesne yer değiştirmez; menüde işaretlenir',
    r === 'ok' && s.els.every((e) => e[prop] === value) && cssNow.every((c) => (prop === 'align' ? c.align : c.v) === css) && inHtml && mark && JSON.stringify(s.els.map((e) => [e.x, e.y])) === xy,
    r + ' ' + JSON.stringify({ st: s.els.map((e) => e[prop]), cssNow, inHtml, mark }));
}
// mixed selection: only the texts are changed
await setup(page, () => { window.ZPDF.App.addFromLibrary('rect'); });
s = await state(page);
const rectId = s.els[s.els.length - 1].id;
await selectByClick(page, [rectId]);
check('Düzen', 'Metni hizala', 'seçimde metin nesnesi yokken pasif', (await peek(page, 'layout', 'Metni hizala', 'Ortaya')).state === 'disabled');

ids = await three();
await selectByClick(page, ids.slice(0, 2));
check('Düzen', 'Eşit aralıkla dağıt', 'üçten az nesne seçiliyken pasif', (await peek(page, 'layout', 'Eşit aralıkla dağıt', 'Yatayda')).state === 'disabled');
await selectByClick(page, ids);
r = await pick(page, 'layout', 'Eşit aralıkla dağıt', 'Yatayda');
let e3 = await byName();
check('Düzen', 'Eşit aralıkla dağıt > Yatayda', 'ilk ve son nesne yerinde kalır; aradaki boşluklar eşitlenir (10 mm)', r === 'ok' && near(e3.A.x, 20) && near(e3.B.x, 80) && near(e3.C.x, 120), r + ' ' + JSON.stringify(e3));
ids = await three();
await selectByClick(page, ids);
r = await pick(page, 'layout', 'Eşit aralıkla dağıt', 'Dikeyde');
e3 = await byName();
check('Düzen', 'Eşit aralıkla dağıt > Dikeyde', 'dikey boşluklar eşitlenir (22 mm)', r === 'ok' && near(e3.A.y, 30) && near(e3.B.y, 58) && near(e3.C.y, 90), r + ' ' + JSON.stringify(e3));

ids = await three();
await selectByClick(page, [ids[0]]);
check('Düzen', 'Aynı boyuta getir', 'tek nesne seçiliyken pasif', (await peek(page, 'layout', 'Aynı boyuta getir', 'Genişlik')).state === 'disabled');
await selectByClick(page, [ids[1], ids[0], ids[2]]); // B is selected first
r = await pick(page, 'layout', 'Aynı boyuta getir', 'Genişlik');
e3 = await byName();
check('Düzen', 'Aynı boyuta getir > Genişlik', 'tüm nesneler ilk seçilen nesnenin (B, 30 mm) genişliğini alır', r === 'ok' && e3.A.w === 30 && e3.B.w === 30 && e3.C.w === 30 && e3.A.h === 6, r + ' ' + JSON.stringify(e3));
r = await pick(page, 'layout', 'Aynı boyuta getir', 'Yükseklik');
e3 = await byName();
check('Düzen', 'Aynı boyuta getir > Yükseklik', 'tüm nesneler ilk seçilen nesnenin (B, 10 mm) yüksekliğini alır', r === 'ok' && e3.A.h === 10 && e3.B.h === 10 && e3.C.h === 10, r + ' ' + JSON.stringify(e3));

ids = await three();
await selectByClick(page, [ids[0]]);
r = await pick(page, 'layout', 'Sayfada ortala', 'Yatayda');
e3 = await byName();
check('Düzen', 'Sayfada ortala > Yatayda', 'nesne kâğıdın yatay ortasına gelir (kenar boşluklarına bakmadan)', r === 'ok' && near(e3.A.x, (W - 50) / 2) && near(e3.A.y, 30), r + ' ' + JSON.stringify(e3.A));
r = await pick(page, 'layout', 'Sayfada ortala', 'Dikeyde');
e3 = await byName();
check('Düzen', 'Sayfada ortala > Dikeyde', 'nesne kâğıdın dikey ortasına gelir', r === 'ok' && near(e3.A.y, (H - 6) / 2), r + ' ' + JSON.stringify(e3.A));

const order = async () => (await state(page)).els.map((e) => e.name).join('');
const domOrder = () => page.$$eval('#paper .el .ti', (n) => n.map((x) => x.textContent).join(''));
ids = await three();
await selectByClick(page, [ids[0]]);
r = await pick(page, 'layout', 'En öne getir');
check('Düzen', 'En öne getir', 'nesne en üste çizilir (ABC → BCA)', r === 'ok' && (await order()) === 'BCA' && (await domOrder()) === 'BCA', r + ' ' + await order());
ids = await three();
await selectByClick(page, [ids[0]]);
r = await pick(page, 'layout', 'Bir öne getir');
check('Düzen', 'Bir öne getir', 'nesne bir sıra öne gelir (ABC → BAC)', r === 'ok' && (await order()) === 'BAC', r + ' ' + await order());
ids = await three();
await selectByClick(page, [ids[2]]);
r = await pick(page, 'layout', 'Bir arkaya gönder');
check('Düzen', 'Bir arkaya gönder', 'nesne bir sıra arkaya gider (ABC → ACB)', r === 'ok' && (await order()) === 'ACB', r + ' ' + await order());
ids = await three();
await selectByClick(page, [ids[2]]);
r = await pick(page, 'layout', 'En arkaya gönder');
check('Düzen', 'En arkaya gönder', 'nesne en alta çizilir (ABC → CAB)', r === 'ok' && (await order()) === 'CAB' && (await domOrder()) === 'CAB', r + ' ' + await order());

ids = await three();
await selectByClick(page, [ids[0]]);
r = await pick(page, 'layout', 'Kilitle / kilidi aç');
s = await state(page);
const lockedState = s.els[0].locked;
await dragBy(ids[0], 60, 40);
await selectByClick(page, [ids[0]]);
await page.keyboard.press('Delete');
await pick(page, 'layout', 'Nesneleri hizala', 'Sağa');
s = await state(page);
check('Düzen', 'Kilitle / kilidi aç', 'kilitli nesne sürüklenemez, silinemez, hizalanamaz', r === 'ok' && lockedState === true && s.els.length === 3 && near(s.els[0].x, 20) && near(s.els[0].y, 30) && (await page.$$eval('#paper .el.is-locked', (n) => n.length)) === 1, JSON.stringify(s.els[0]));
await selectByClick(page, [ids[0]]);
r = await pick(page, 'layout', 'Kilitle / kilidi aç');
await dragBy(ids[0], 38, 0);
s = await state(page);
check('Düzen', 'Kilitle / kilidi aç (tekrar)', 'kilit kalkar; nesne yeniden taşınabilir', r === 'ok' && s.els[0].locked === false && s.els[0].x > 25, JSON.stringify(s.els[0]));

// context menu of the page (right click)
ids = await three();
const cbox = await (await page.$('.el[data-id="' + ids[1] + '"]')).boundingBox();
await page.mouse.click(cbox.x + 4, cbox.y + 4, { button: 'right' });
await sleep(60);
const ctxLabels = await page.$$eval('.dropdown.ctx > .mi > .mlbl', (n) => n.map((x) => x.textContent));
check('Sağ tık menüsü', '(içerik)', 'nesneye sağ tıklayınca nesne seçilir ve kısa menü açılır', ctxLabels.join('|') === 'Kes|Kopyala|Yapıştır|Çoğalt|Sil|En öne getir|En arkaya gönder|Kilitle / kilidi aç|Nesneleri hizala|Metni hizala|Sayfada ortala' && (await state(page)).sel[0] === ids[1], ctxLabels.join('|'));
let it = await findItem(page, '.dropdown.ctx', ['Metni hizala', 'Sağa']);
if (it.state === 'ok') await it.el.click();
await sleep(60);
s = await state(page);
check('Sağ tık menüsü', 'Metni hizala > Sağa', 'alt menü açılır ve komut uygulanır', it.state === 'ok' && s.els[1].align === 'right' && !(await page.$('.dropdown.ctx')), it.state + ' ' + s.els[1].align);
await page.mouse.click(cbox.x + 4, cbox.y + 4, { button: 'right' });
await sleep(60);
it = await findItem(page, '.dropdown.ctx', ['Çoğalt']);
if (it.state === 'ok') await it.el.click();
await sleep(60);
check('Sağ tık menüsü', 'Çoğalt', 'nesnenin kopyası eklenir', it.state === 'ok' && (await state(page)).els.length === 4, it.state);
await page.screenshot({ path: join(out, 'm03-layout.png') });

// ---------------------------------------------------------------------------------------------
// ARAÇLAR (Tools)
// ---------------------------------------------------------------------------------------------
const png = join(out, 'zpdf_logo.png');
writeFileSync(png, Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAQAAAACCAYAAAB/qH1jAAAAEklEQVR4nGP8z8Dwn4EIwDiqEAC6DAP9Wb0aPQAAAABJRU5ErkJggg==', 'base64'));
await openMenu(page, 'tools');
it = await findItem(page, '#menubar .menu[data-menu="tools"] .dropdown', ['Logo / font yükle...']);
covered.add('tools|uploadAsset|');
let [chooser] = await Promise.all([page.waitForFileChooser({ timeout: 5000 }).catch(() => null), it.el.click()]);
check('Araçlar', 'Logo / font yükle...', 'dosya seçme penceresi açılır (PNG, JPEG, TTF)', !!chooser);
if (chooser) {
  await chooser.accept([png]);
  await sleep(300);
  let d = await dialog(page);
  const idValue = d ? await page.$eval('#asId', (n) => n.value) : '';
  check('Araçlar', 'Logo / font yükle... > dosya', '"Logo yükle" penceresi dosya adından bir depo adı önerir', !!d && d.title === 'Logo yükle' && idValue === 'ZPDF_LOGO', JSON.stringify(d) + idValue);
  await dialogButton(page, 'Yükle');
  s = await state(page);
  check('Araçlar', 'Logo / font yükle... > Yükle', 'logo depoya eklenir', s.assets.length === 1 && s.assets[0].id === 'ZPDF_LOGO' && s.assets[0].kind === 'IMAGE' && (await toast(page)).text.includes('ZPDF_LOGO'), JSON.stringify(s.assets));
}
// an unsupported file is refused
const txt = join(out, 'not-a-logo.png');
writeFileSync(txt, 'this is not an image');
await openMenu(page, 'tools');
it = await findItem(page, '#menubar .menu[data-menu="tools"] .dropdown', ['Logo / font yükle...']);
[chooser] = await Promise.all([page.waitForFileChooser({ timeout: 5000 }).catch(() => null), it.el.click()]);
if (chooser) { await chooser.accept([txt]); await sleep(300); }
let t = await toast(page);
check('Araçlar', 'Logo / font yükle... > geçersiz dosya', 'PNG/JPEG/TTF olmayan dosya hata mesajıyla reddedilir', t.error && t.text.includes('Desteklenmeyen dosya') && (await state(page)).assets.length === 1, JSON.stringify(t));
// a TrueType font
const ttf = 'C:/Windows/Fonts/arial.ttf';
await openMenu(page, 'tools');
it = await findItem(page, '#menubar .menu[data-menu="tools"] .dropdown', ['Logo / font yükle...']);
[chooser] = await Promise.all([page.waitForFileChooser({ timeout: 5000 }).catch(() => null), it.el.click()]);
if (chooser) {
  await chooser.accept([ttf]);
  await page.waitForSelector('#asFamily', { timeout: 8000 }).catch(() => null);
  const d = await dialog(page);
  const fam = d ? await page.$eval('#asFamily', (n) => n.value).catch(() => '') : '';
  await dialogButton(page, 'Yükle');
  s = await state(page);
  const face = await page.evaluate(() => (document.getElementById('assetFonts') || {}).textContent || '');
  check('Araçlar', 'Logo / font yükle... > TTF', 'font ailesi sorulur; font depoya eklenir ve tasarımcıda kullanılabilir olur', !!d && d.title === 'Font yükle' && fam === 'arial' && s.assets.some((a) => a.kind === 'FONT' && a.family === 'arial') && face.includes("font-family:'arial'"), JSON.stringify({ d: d && d.title, fam, assets: s.assets }));
}
r = await pick(page, 'tools', 'Logo ve font deposu...');
let d = await dialog(page);
check('Araçlar', 'Logo ve font deposu...', 'depodaki logo ve fontlar listelenir', r === 'ok' && !!d && d.title === 'Logo ve font deposu' && d.text.includes('ZPDF_LOGO') && d.text.includes('ARIAL'), JSON.stringify(d));
const thumbs = await page.evaluate(() => Array.prototype.map.call(document.querySelectorAll('.dlg .thumb'), (n) => n.tagName === 'IMG' ? (n.complete && n.naturalWidth > 0 ? 'img' : 'broken') : n.style.fontFamily));
check('Araçlar', 'Logo ve font deposu... > önizleme', 'her logo küçük resimle, her font kendi yazı tipinde örnek metinle gösterilir', thumbs.join() === "img,\"arial\"" || thumbs.join() === "img,arial", thumbs.join());
const nBefore = (await state(page)).els.length;
await page.click('.dlg [data-logo="ZPDF_LOGO"]');
await sleep(250);
s = await state(page);
check('Araçlar', 'Logo ve font deposu... > Sayfaya ekle', 'logo, en-boy oranı korunarak resim nesnesi olarak eklenir', s.els.length === nBefore + 1 && s.els[s.els.length - 1].type === 'image' && s.els[s.els.length - 1].asset === 'ZPDF_LOGO' && near(s.els[s.els.length - 1].w / s.els[s.els.length - 1].h, 2, 0.2) && !(await dialog(page)), JSON.stringify(s.els[s.els.length - 1]));
r = await pick(page, 'insert', 'Kayıtlı logolar', 'ZPDF_LOGO');
await sleep(250);
s = await state(page);
check('Ekle', 'Kayıtlı logolar > ZPDF_LOGO', 'depodaki logo sayfaya eklenir', r === 'ok' && s.els.length === nBefore + 2 && s.els[s.els.length - 1].asset === 'ZPDF_LOGO' && (await page.$$eval('#paper .el-image img', (n) => n.length)) === 2, r + ' ' + s.els.length);

r = await pick(page, 'tools', 'Önizleme verisi...');
check('Araçlar', 'Önizleme verisi...', 'Arayüz sekmesi açılır (önizleme verisi burada düzenlenir)', r === 'ok' && (await shownTab()) === 'iface' && (await page.$$eval('#ifaceTab textarea', (n) => n.length)) >= 1, r + ' ' + await shownTab());
await page.click('.mtab[data-tab="layout"]');
await setup(page, () => { window.ZPDF.App.addFromLibrary('table'); });
await sleep(150);
await escape(page);
r = await pick(page, 'tools', 'Uyarılar...');
d = await dialog(page);
check('Araçlar', 'Uyarılar...', 'çıktıyı etkileyecek uyarılar listelenir (ör. bağlanmamış tablo)', r === 'ok' && !!d && d.title === 'Uyarılar' && d.text.includes('tablo bir arayüz tablosuna bağlanmadı'), JSON.stringify(d));
await dialogButton(page, 'Kapat');
r = await pick(page, 'tools', 'ABAP çağrı kodu...');
d = await dialog(page);
check('Araçlar', 'ABAP çağrı kodu...', 'formu çağıran ABAP kodu gösterilir (render_form, arayüz parametreleriyle)', r === 'ok' && !!d && d.title === 'ABAP çağrı kodu' && d.text.includes('render_form') && d.text.includes("name = 'INPUT'") && d.text.includes('zpdf_s_input'.toUpperCase().toLowerCase()), JSON.stringify(d).slice(0, 600));
await dialogButton(page, 'Panoya kopyala');
t = await toast(page);
check('Araçlar', 'ABAP çağrı kodu... > Panoya kopyala', 'kod panoya kopyalanır; pencere açık kalır', t.text === 'Panoya kopyalandı.' && !t.error && !!(await dialog(page)), JSON.stringify(t));
await dialogButton(page, 'Kapat');
r = await pick(page, 'tools', "Oluşturulan form HTML'i...");
d = await dialog(page);
const srcText = d ? await page.$eval('.dlg textarea', (n) => n.value) : '';
check('Araçlar', "Oluşturulan form HTML'i...", "motorun kullanacağı form HTML'i salt okunur gösterilir", r === 'ok' && !!d && d.title === "Oluşturulan form HTML'i" && srcText.includes('<section>') && srcText.includes('<img src="asset:ZPDF_LOGO"') && (await page.$eval('.dlg textarea', (n) => n.readOnly)), (d && d.title) + ' ' + srcText.slice(0, 200));
await dialogButton(page, 'Kapat');
r = await pick(page, 'tools', 'Otomatik kaydet');
s = await state(page);
check('Araçlar', 'Otomatik kaydet', 'otomatik kaydet kapanır; araç çubuğundaki kutu ve menü işareti de değişir', r === 'ok' && s.autosave === false && !(await page.$eval('#autosave', (n) => n.checked)) && !(await peek(page, 'tools', 'Otomatik kaydet')).on, r + ' ' + s.autosave);
r = await pick(page, 'tools', 'Otomatik kaydet');
s = await state(page);
check('Araçlar', 'Otomatik kaydet (tekrar)', 'otomatik kaydet yeniden açılır', r === 'ok' && s.autosave === true && (await page.$eval('#autosave', (n) => n.checked)), r + ' ' + s.autosave);

// ---------------------------------------------------------------------------------------------
// PALETLER (Palettes)
// ---------------------------------------------------------------------------------------------
const panels = () => page.$$eval('.panel', (n) => n.map((x) => x.dataset.panel).sort().join());
const panelDefs = await page.evaluate(() => { const st = window.ZPDF.state(); return Object.keys(st.panels); });
const titles = await page.evaluate(() => window.ZPDF.Menus.defs().filter((m) => m.id === 'palettes')[0].items.filter((i) => i.act === 'panel').map((i) => ({ id: i.arg, label: i.label })));
check('Paletler', '(içerik)', 'dört palet listelenir', titles.length === 4 && panelDefs.length === 4, JSON.stringify(titles));
for (const p of titles) {
  r = await pick(page, 'palettes', p.label);
  const gone = !(await panels()).split(',').includes(p.id) && !(await peek(page, 'palettes', p.label)).on;
  const r2 = await pick(page, 'palettes', p.label);
  const back = (await panels()).split(',').includes(p.id) && (await peek(page, 'palettes', p.label)).on;
  check('Paletler', p.label, 'palet gizlenir; yeniden seçilince geri gelir', r === 'ok' && r2 === 'ok' && gone && back, [r, r2, gone, back].join());
}
r = await pick(page, 'palettes', 'Tüm paletleri gizle');
check('Paletler', 'Tüm paletleri gizle', 'tüm paletler kapanır; sayfa tam genişliği kullanır', r === 'ok' && (await panels()) === '', r + ' ' + await panels());
r = await pick(page, 'palettes', 'Tüm paletleri göster');
check('Paletler', 'Tüm paletleri göster', 'dört palet de açılır', r === 'ok' && (await panels()).split(',').length === 4, r + ' ' + await panels());
// a palette header: collapse and close
await page.click('.panel[data-panel="lib"] [data-pact="collapse"]');
const collapsed = await page.$eval('.panel[data-panel="lib"]', (n) => n.classList.contains('collapsed'));
await page.click('.panel[data-panel="lib"] [data-pact="collapse"]');
check('Paletler', 'Palet başlığı: daralt / genişlet', 'palet başlığındaki düğme paleti daraltır ve genişletir', collapsed && !(await page.$eval('.panel[data-panel="lib"]', (n) => n.classList.contains('collapsed'))));
await pick(page, 'view', 'Izgara');
await pick(page, 'view', 'Yakınlaştır');
await pick(page, 'palettes', titles[0].label);
r = await pick(page, 'palettes', 'Çalışma alanını sıfırla');
s = await state(page);
check('Paletler', 'Çalışma alanını sıfırla', 'paletler, görünüm seçenekleri ve yakınlaştırma varsayılana döner (tasarım değişmez)', r === 'ok' && (await panels()).split(',').length === 4 && s.view.grid === true && s.zoom === 1 && s.els.length === nBefore + 3, r + ' ' + JSON.stringify([s.view, s.zoom, s.els.length]));

// ---------------------------------------------------------------------------------------------
// YARDIM (Help)
// ---------------------------------------------------------------------------------------------
for (const [label, must] of [['Klavye kısayolları', 'Ctrl+S'], ['Hızlı başlangıç', 'Arayüz sekmesinde'], ['ZPDF Studio hakkında', 'ZPDF Studio']]) {
  r = await pick(page, 'help', label);
  d = await dialog(page);
  const closed = await dialogButton(page, 'Kapat');
  check('Yardım', label, 'bilgi penceresi açılır ve Kapat ile kapanır', r === 'ok' && !!d && d.title === label && d.text.includes(must) && closed && !(await dialog(page)), JSON.stringify(d).slice(0, 300));
}

// ---------------------------------------------------------------------------------------------
// DOSYA (File) - browser stand-in; the SAP requests are checked in the SAP harness below
// ---------------------------------------------------------------------------------------------
dis = [await peek(page, 'file', 'Transport talebine ekle...'), await peek(page, 'file', "Sayfayı SAP'den yeniden yükle"), await peek(page, 'file', 'Çıkış')].map((x) => x.state).join();
check('Dosya', 'Transport / Yeniden yükle / Çıkış', 'SAP dışında (tarayıcıda) pasif', dis === 'disabled,disabled,disabled', dis);
r = await pick(page, 'file', 'Tasarımı JSON olarak dışa aktar');
const dl = await page.evaluate(async () => { const x = window.__downloads[window.__downloads.length - 1]; return x ? { name: x.name, text: await (await fetch(x.href)).text() } : null; });
let exported = null;
try { exported = JSON.parse(dl.text); } catch (err) { exported = null; }
check('Dosya', 'Tasarımı JSON olarak dışa aktar', 'tasarım .json dosyası olarak indirilir (tarayıcı modu)', r === 'ok' && !!exported && exported.pages[0].els.length === nBefore + 3 && /\.json$/.test(dl.name), dl && dl.name);
r = await pick(page, 'file', 'JSON içe aktar...');
d = await dialog(page);
await page.$eval('#dlgJson', (n) => { n.value = '{ bozuk json'; });
await dialogButton(page, 'İçe aktar');
t = await toast(page);
check('Dosya', 'JSON içe aktar... > geçersiz metin', 'hata mesajı verilir; pencere açık kalır, tasarım değişmez', r === 'ok' && !!d && d.title === 'JSON içe aktar' && t.error && t.text.includes('JSON okunamadı') && !!(await dialog(page)) && (await state(page)).els.length === nBefore + 3, JSON.stringify(t));
const smaller = JSON.parse(JSON.stringify(exported));
smaller.pages[0].els = smaller.pages[0].els.slice(0, 2);
await page.$eval('#dlgJson', (n, v) => { n.value = v; }, JSON.stringify(smaller));
await dialogButton(page, 'İçe aktar');
s = await state(page);
check('Dosya', 'JSON içe aktar... > İçe aktar', 'yapıştırılan tasarım mevcut tasarımın yerini alır', s.els.length === 2 && !(await dialog(page)) && (await toast(page)).text === 'Tasarım içe aktarıldı.', s.els.length);
await pick(page, 'edit', 'Geri al');
s = await state(page);
check('Dosya', 'JSON içe aktar... > Geri al', 'içe aktarma geri alınabilir', s.els.length === nBefore + 3, s.els.length);
r = await pick(page, 'file', 'Kaydet');
await sleep(120);
s = await state(page);
check('Dosya', 'Kaydet', 'form kaydedilir; "değişti" işareti kalkar, sürüm atanır', r === 'ok' && s.dirty === false && s.version === '0001' && !(await toast(page)).error, r + ' ' + JSON.stringify([s.dirty, s.version]));
const pagesBefore = (await browser.pages()).length;
r = await pick(page, 'file', 'PDF önizle');
await sleep(400);
const pagesAfter = await browser.pages();
check('Dosya', 'PDF önizle', 'önizleme isteği gönderilir (tarayıcı modunda motor HTML\'i yeni pencerede açılır)', r === 'ok' && pagesAfter.length === pagesBefore + 1, r + ' ' + pagesAfter.length);
if (pagesAfter.length > pagesBefore) await pagesAfter[pagesAfter.length - 1].close();
await page.bringToFront();
r = await pick(page, 'file', 'Sürümler...');
await sleep(120);
d = await dialog(page);
check('Dosya', 'Sürümler...', 'sürüm listesi açılır; etkin sürüm işaretlidir', r === 'ok' && !!d && d.title === 'Sürümler' && d.text.includes('0001') && d.text.includes('etkin'), JSON.stringify(d));
await dialogButton(page, 'Kapat');
// shortcuts of the File menu
await setup(page, () => { window.ZPDF.App.addFromLibrary('line'); });
await page.keyboard.down('Control'); await page.keyboard.press('KeyS'); await page.keyboard.up('Control');
await sleep(120);
check('Dosya', 'Ctrl+S', 'kısayol kaydeder', (await state(page)).dirty === false);

// toolbar: the three main buttons
const tbLabels = await page.$$eval('#toolbar .tb span', (n) => n.map((x) => x.textContent));
await page.click('.tb[data-act="warnings"]');
d = await dialog(page);
check('Araç çubuğu', 'Kaydet | Önizle | Uyarılar', 'üç ana düğme vardır; Uyarılar penceresi açılır', tbLabels.join('|') === 'Kaydet|Önizle|Uyarılar' && !!d && d.title === 'Uyarılar', tbLabels.join('|'));
await dialogButton(page, 'Kapat');
check('Genel', 'Betik hataları (tarayıcı modu)', 'hiçbir menü öğesi betik hatası üretmedi', errors.length === 0, errors.join(' | '));

// every item of the menu bar was clicked?
const leaves = await page.evaluate(() => {
  const out = [];
  const walk = (menu, items, path) => items.forEach((i) => {
    if (i === '-') return;
    if (i.sub) return walk(menu, i.sub, path.concat(i.label));
    if (i.act) out.push({ key: menu + '|' + i.act + '|' + (i.arg === undefined ? '' : i.arg), label: path.concat(i.label).join(' > ') });
  });
  window.ZPDF.Menus.defs().forEach((m) => walk(m.id, m.items, [m.label]));
  return out;
});
const sapOnly = ['file|transport|', 'file|reload|', 'file|exit|'];
const untested = leaves.filter((l) => !covered.has(l.key) && !sapOnly.includes(l.key));
check('Genel', 'Kapsam (tarayıcı modu)', leaves.length + ' menü öğesinin SAP\'ye özel 3\'ü dışında hepsi tıklandı', untested.length === 0, untested.map((u) => u.label).join(' ; '));

// ---------------------------------------------------------------------------------------------
// SAP harness: the page runs with SAP boot data; the requests to ABAP are captured
// ---------------------------------------------------------------------------------------------
const b64 = (text) => Buffer.from(text, 'utf8').toString('base64');
const docJson = JSON.stringify(await page.evaluate(() => window.ZPDF.state().doc));
const asset = await page.evaluate(() => window.ZPDF.state().assets.filter((a) => a.kind === 'IMAGE')[0]);
const baseBoot = { runtime: 'sap', lang: 'TR', form: 'ZPDF_DEMO', viewOnly: false, user: 'TESTER', version: '0003', description: 'Test formu', doc64: b64(docJson), sample64: '', ui64: '', dirty: false, autosave: true, assets: [asset], message: null, reply: null };
const sapFile = join(out, 'menus-sap.html');
const sap = await browser.newPage();
await sap.setViewport({ width: 1600, height: 900 });
const sapErrors = [];
sap.on('pageerror', (e) => sapErrors.push(e.message));
await sap.evaluateOnNewDocument(() => {
  window.__posts = [];
  HTMLFormElement.prototype.submit = function () { window.__posts.push({ action: this.getAttribute('action'), payload: this.querySelector('textarea').value }); };
});
async function boot(over) {
  const data = Object.assign({}, baseBoot, over || {});
  writeFileSync(sapFile, readFileSync(dist, 'utf8').replace('__ZPDF_BOOT__', () => JSON.stringify(data).replace(/</g, '\\u003c')));
  await sap.goto(pathToFileURL(sapFile).href);
  await sap.waitForSelector('#menubar .menu');
}
const decode = (payload) => Object.fromEntries(Buffer.from(payload, 'base64').toString('utf8').split('\n').map((l) => { const p = l.split('\t'); return [p[1], Buffer.from(p[2] || '', 'base64').toString('utf8')]; }));
const lastPost = async () => { const posts = await sap.evaluate(() => window.__posts); const p = posts[posts.length - 1]; return p ? { action: p.action, n: posts.length, args: decode(p.payload) } : { action: '', n: 0, args: {} }; };
const veil = () => sap.evaluate(() => document.getElementById('busy').className === '');
const unveil = () => sap.evaluate(() => window.ZPDF.App.busy(false));

await boot();
r = await pick(sap, 'file', 'Kaydet');
let post = await lastPost();
check('Dosya (SAP)', 'Kaydet', 'SAVE isteği tasarımın tamamıyla ABAP\'a gönderilir; SAP yanıtlayana kadar "SAP işlem yapıyor..." perdesi görünür',
  r === 'ok' && post.action === 'sapevent:SAVE' && post.args.html.startsWith('<!--zpdf-studio:') && post.args.iface === 'INPUT=ZPDF_S_INPUT' && post.args.page_size === 'A4' && (await veil()) && (await sap.$eval('#busy span', (n) => n.textContent)) === 'SAP işlem yapıyor...', r + ' ' + post.action);
// the answer of ABAP = the page is shown again with the reply in the boot data
await boot({ ui64: b64(post.args.ui), version: '0004', reply: { id: Number(post.args.req), ok: true, kind: 'save', message: 'ZPDF_DEMO kaydedildi, sürüm 0004.', data64: b64(JSON.stringify({ version: '0004' })) } });
let ss = await state(sap);
check('Dosya (SAP)', 'Kaydet > SAP yanıtı', 'sayfa yeniden gösterildiğinde tasarım yerindedir; sürüm 0004, mesaj gösterilir', ss.els.length === nBefore + 4 && ss.version === '0004' && ss.dirty === false && (await toast(sap)).text.includes('0004') && !(await veil()), JSON.stringify([ss.els.length, ss.version, ss.dirty]));
r = await pick(sap, 'file', 'PDF önizle');
post = await lastPost();
check('Dosya (SAP)', 'PDF önizle', 'PREVIEW isteği form HTML\'i, kenar boşlukları ve önizleme verisiyle gönderilir; sayfa kullanılabilir kalır',
  r === 'ok' && post.action === 'sapevent:PREVIEW' && post.args.html.length > 100 && post.args.margin_left === String(ss.page.ml) && post.args.margin_right === String(ss.page.mr) && post.args.margin_top === String(ss.page.mt) && post.args.margin_bottom === String(ss.page.mb) && !!JSON.parse(post.args.sample).INPUT && !(await veil()),
  r + ' ' + post.action + ' ' + JSON.stringify([post.args.margin_left, post.args.margin_right, post.args.margin_top, post.args.margin_bottom]));
r = await pick(sap, 'file', 'Transport talebine ekle...');
post = await lastPost();
check('Dosya (SAP)', 'Transport talebine ekle... (kaydedilmiş form)', 'TRANSPORT isteği doğrudan gönderilir', r === 'ok' && post.action === 'sapevent:TRANSPORT' && post.args.save === '' && post.args.html.length > 100 && (await veil()), r + ' ' + post.action);
await unveil();
await setup(sap, () => { window.ZPDF.App.addFromLibrary('rect'); });
r = await pick(sap, 'file', 'Transport talebine ekle...');
d = await dialog(sap);
await dialogButton(sap, 'Kaydet ve devam et');
post = await lastPost();
check('Dosya (SAP)', 'Transport talebine ekle... (değişmiş form)', 'önce kaydetme onayı istenir; onaydan sonra TRANSPORT isteği save=X ile gider', r === 'ok' && !!d && d.title === 'Transport' && post.action === 'sapevent:TRANSPORT' && post.args.save === 'X', r + ' ' + JSON.stringify(d) + post.action);
await unveil();
r = await pick(sap, 'file', 'Sürümler...');
post = await lastPost();
check('Dosya (SAP)', 'Sürümler...', 'VERSIONS isteği gönderilir', r === 'ok' && post.action === 'sapevent:VERSIONS' && (await veil()), r + ' ' + post.action);
await boot({ ui64: b64(post.args.ui), reply: { id: Number(post.args.req), ok: true, kind: 'versions', message: '', data64: b64(JSON.stringify([{ version: '0004', active: true, user: 'TESTER', at: '20261121093000' }, { version: '0003', active: false, user: 'TESTER', at: '20261120101500' }])) } });
d = await dialog(sap);
check('Dosya (SAP)', 'Sürümler... > SAP yanıtı', 'sürümler tarih ve kullanıcıyla listelenir; eski sürümde "Bu sürüme dön" düğmesi vardır', !!d && d.title === 'Sürümler' && d.text.includes('21.11.2026 09:30') && d.text.includes('etkin') && (await sap.$$eval('.dlg [data-ver]', (n) => n.map((x) => x.dataset.ver).join())) === '0003', JSON.stringify(d));
await sap.click('.dlg [data-ver="0003"]');
await sleep(60);
d = await dialog(sap);
await dialogButton(sap, 'Etkinleştir');
post = await lastPost();
check('Dosya (SAP)', 'Sürümler... > Bu sürüme dön', 'onaydan sonra ACTIVATE_VERSION isteği sürüm numarasıyla gönderilir', !!d && d.title === 'Sürüme dön' && post.action === 'sapevent:ACTIVATE_VERSION' && post.args.version === '0003', JSON.stringify(d) + post.action);
await unveil();
r = await pick(sap, 'file', 'Tasarımı JSON olarak dışa aktar');
d = await dialog(sap);
const jsonText = d ? await sap.$eval('#dlgJson', (n) => n.value) : '';
let parsed = null;
try { parsed = JSON.parse(jsonText); } catch (err) { parsed = null; }
check('Dosya (SAP)', 'Tasarımı JSON olarak dışa aktar', 'SAP içinde tasarım JSON\'u kopyalanabilir bir pencerede gösterilir', r === 'ok' && !!d && d.title === 'Tasarım (JSON)' && !!parsed && Array.isArray(parsed.pages), d && d.title);
await dialogButton(sap, 'Kapat');
r = await pick(sap, 'file', "Sayfayı SAP'den yeniden yükle");
post = await lastPost();
check('Dosya (SAP)', "Sayfayı SAP'den yeniden yükle", 'RELOAD isteği güncel tasarımla gönderilir (ABAP sayfayı aynı durumla yeniden gösterir)', r === 'ok' && post.action === 'sapevent:RELOAD' && post.args.html.length > 100, r + ' ' + post.action);
await unveil();
await setup(sap, () => { window.ZPDF.App.addFromLibrary('line'); });
r = await pick(sap, 'file', 'Çıkış');
post = await lastPost();
check('Dosya (SAP)', 'Çıkış', 'EXIT isteği güncel tasarım ve "değişti" bilgisiyle gönderilir (kaydetme uyarısını ABAP gösterir)', r === 'ok' && post.action === 'sapevent:EXIT' && post.args.dirty === 'X' && post.args.html.length > 100, r + ' ' + post.action + ' ' + post.args.dirty);
r = await pick(sap, 'tools', 'Otomatik kaydet');
post = await lastPost();
check('Araçlar (SAP)', 'Otomatik kaydet', 'seçim SYNC isteğiyle hemen ABAP\'a bildirilir (autosave boş = kapalı)', r === 'ok' && post.action === 'sapevent:SYNC' && post.args.autosave === '', r + ' ' + post.action + ' [' + post.args.autosave + ']');
await pick(sap, 'tools', 'Otomatik kaydet');
r = await pick(sap, 'view', 'Tema', 'Koyu');
post = await lastPost();
check('Görünüm (SAP)', 'Tema > Koyu', 'tema PREFS isteğiyle kullanıcı ayarı olarak ABAP\'a gönderilir; dil ayarı gönderilmez', r === 'ok' && post.action === 'sapevent:PREFS' && post.args.prefs === '{"theme":"dark"}', r + ' ' + post.action + ' ' + post.args.prefs);
await pick(sap, 'view', 'Tema', 'Açık');
await openMenu(sap, 'tools');
it = await findItem(sap, '#menubar .menu[data-menu="tools"] .dropdown', ['Logo / font yükle...']);
[chooser] = await Promise.all([sap.waitForFileChooser({ timeout: 5000 }).catch(() => null), it.el.click()]);
if (chooser) { await chooser.accept([png]); await sleep(300); await sap.$eval('#asId', (n) => { n.value = 'ZPDF_LOGO2'; }); await dialogButton(sap, 'Yükle'); }
post = await lastPost();
check('Araçlar (SAP)', 'Logo / font yükle...', 'UPLOAD_ASSET isteği dosya içeriği, depo adı ve güncel tasarımla gönderilir', !!chooser && post.action === 'sapevent:UPLOAD_ASSET' && post.args.asset_id === 'ZPDF_LOGO2' && post.args.content.startsWith('iVBOR') && post.args.html.length > 100, post.action + ' ' + post.args.asset_id);
await unveil();
check('Araçlar (SAP)', 'Dil', 'Araçlar menüsünde dil seçimi yoktur (dil SAP oturum dilinden gelir)', (await peek(sap, 'tools', 'Dil')).state === 'missing');

// ---- language: Turkish for a Turkish logon, English for every other logon language
const menuTitles = () => sap.$$eval('#menubar .mtitle', (n) => n.map((x) => x.textContent).join('|'));
const TR = 'Dosya|Düzenle|Görünüm|Ekle|Tablo|Düzen|Araçlar|Paletler|Yardım';
const EN = 'File|Edit|View|Insert|Table|Layout|Tools|Palettes|Help';
await boot({ lang: 'TR', prefs64: b64(JSON.stringify({ theme: 'light', lang: 'EN' })) });
check('Dil', 'Oturum dili TR', 'arayüz Türkçe açılır (eski "dil" kullanıcı ayarı dikkate alınmaz)', (await menuTitles()) === TR && (await sap.evaluate(() => document.documentElement.lang)) === 'tr', await menuTitles());
for (const lang of ['EN', 'DE', 'FR', 'RU', '']) {
  await boot({ lang, prefs64: b64(JSON.stringify({ theme: 'light', lang: 'TR' })) });
  check('Dil', 'Oturum dili ' + (lang || '(boş)'), 'arayüz İngilizce açılır', (await menuTitles()) === EN && (await sap.evaluate(() => document.documentElement.lang)) === 'en', await menuTitles());
}
// English session: no Turkish text may be left anywhere in the designer itself
await boot({ lang: 'DE', doc64: '', assets: [] });
const turkish = /[çğışöüÇĞİŞÖÜ]/;
const leftovers = [];
const scan = async (where) => {
  const texts = await sap.evaluate(() => {
    const out = [];
    document.querySelectorAll('#menubar, #toolbar, #maintabs, #work, #statusbar, .dlgback, #toast, .picker').forEach((root) => {
      if (root.offsetParent === null && root.id !== 'toast') return;
      out.push(root.innerText);
      root.querySelectorAll('[title], [placeholder]').forEach((n) => { if (n.offsetParent !== null) out.push((n.getAttribute('title') || '') + ' ' + (n.getAttribute('placeholder') || '')); });
      root.querySelectorAll('option').forEach((n) => out.push(n.textContent));
    });
    return out;
  });
  texts.join('\n').split('\n').forEach((line) => { if (turkish.test(line)) leftovers.push(where + ': ' + line.trim().slice(0, 90)); });
};
const allLabels = await sap.evaluate(() => { const out = []; const walk = (items) => items.forEach((i) => { if (i === '-') return; out.push(i.label); if (i.sub) walk(i.sub); }); window.ZPDF.Menus.defs().forEach((m) => { out.push(m.label); walk(m.items); }); return out; });
allLabels.forEach((l) => { if (turkish.test(l)) leftovers.push('menu: ' + l); });
await scan('layout (empty)');
for (const tab of ['form', 'iface']) { await sap.click('.mtab[data-tab="' + tab + '"]'); await sleep(60); await scan(tab + ' tab'); }
await sap.click('[data-act="ddicSearch"]'); await sleep(60); await scan('ddic search'); await escape(sap);
await sap.click('.mtab[data-tab="layout"]');
for (const id of ['text', 'field', 'table', 'image', 'checkbox', 'pageno', 'line', 'rect', 'bc_' + groups[3].items[0].code, 'bc_' + groups[3].items[groups[3].items.length - 1].code]) {
  await setup(sap, (id) => { window.ZPDF.App.addFromLibrary(id); }, id);
  await sleep(120);
  await scan('picker/' + id);
  await escape(sap);
  await setup(sap, () => { const st = window.ZPDF.state(); const A = window.ZPDF.App; st.sel = [st.doc.pages[0].els[st.doc.pages[0].els.length - 1].id]; A.showObjectTab('props'); A.refresh(); });
  await scan('properties/' + id);
  await setup(sap, () => { window.ZPDF.App.showObjectTab('bind'); });
  await scan('binding/' + id);
}
for (const act of ['shortcuts', 'quickStart', 'about', 'warnings', 'abapCode', 'htmlSource', 'assets', 'importJson', 'exportJson']) {
  await setup(sap, (act) => { window.ZPDF.App.run(act); }, act);
  await sleep(40);
  await scan('dialog/' + act);
  await escape(sap);
}
await sap.mouse.click(700, 500, { button: 'right' }); await sleep(40); await scan('context menu'); await escape(sap);
check('Dil', 'İngilizce oturumda Türkçe kalıntı', 'menüler, araç çubuğu, sekmeler, paletler, özellikler ve pencerelerde Türkçe metin kalmaz', leftovers.length === 0, [...new Set(leftovers)].slice(0, 25).join(' ;; '));
await sap.screenshot({ path: join(out, 'm04-english.png') });

// display mode
await boot({ viewOnly: true });
dis = [await peek(sap, 'file', 'Kaydet'), await peek(sap, 'file', 'Transport talebine ekle...'), await peek(sap, 'file', 'JSON içe aktar...'), await peek(sap, 'insert', 'Standart', 'Metin'), await peek(sap, 'insert', 'Yeni tasarım sayfası'), await peek(sap, 'table', 'Tablo ekle'), await peek(sap, 'tools', 'Logo / font yükle...'), await peek(sap, 'tools', 'Otomatik kaydet'), await peek(sap, 'edit', 'Geri al')].map((x) => x.state).join();
const viewOk = [await peek(sap, 'file', 'PDF önizle'), await peek(sap, 'file', 'Sürümler...'), await peek(sap, 'file', 'Tasarımı JSON olarak dışa aktar'), await peek(sap, 'tools', 'ABAP çağrı kodu...'), await peek(sap, 'view', 'Sayfayı sığdır')].map((x) => x.state).join();
check('Görüntüleme modu', 'Değiştiren komutlar', 'Görüntüle ile açılan formda kaydetme, ekleme, içe aktarma, yükleme pasif; önizleme, sürümler, dışa aktarma etkin', dis === Array(9).fill('disabled').join() && viewOk === Array(5).fill('ok').join(), dis + ' / ' + viewOk);
check('Genel', 'Betik hataları (SAP modu)', 'hiçbir menü öğesi betik hatası üretmedi', sapErrors.length === 0, sapErrors.join(' | '));
const untestedSap = sapOnly.filter((k) => !covered.has(k));
check('Genel', 'Kapsam (SAP modu)', 'SAP\'ye özel 3 menü öğesi de tıklandı', untestedSap.length === 0, untestedSap.join());

await browser.close();
let lastMenu = '';
for (const row of rows) {
  if (row.menu !== lastMenu) { console.log('\n== ' + row.menu); lastMenu = row.menu; }
  console.log((row.ok ? '  ok   ' : '  FAIL ') + row.item + '  —  ' + row.what + (row.ok ? '' : '\n         -> ' + row.extra));
}
writeFileSync(join(out, 'menus-report.json'), JSON.stringify({ at: new Date().toISOString(), total: rows.length, failed, leaves: leaves.length, rows }, null, 1));
console.log(failed ? `\n${failed} of ${rows.length} FAILED` : `\nall ${rows.length} checks passed (${leaves.length} menu items)`);
process.exitCode = failed ? 1 : 0;
