// Smoke test of dist/designer.html in headless Chrome: real mouse and keyboard input.
import puppeteer from 'puppeteer-core';
import { readFileSync, writeFileSync } from 'node:fs';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { join } from 'node:path';

const dist = fileURLToPath(new URL('../dist/designer.html', import.meta.url));
const out = process.argv[2] || '.';
const results = [];
let failed = 0;
function check(name, cond, extra) {
  results.push((cond ? '  ok  ' : 'FAIL  ') + name + (extra && !cond ? '  -> ' + extra : ''));
  if (!cond) failed++;
}

const browser = await puppeteer.launch({ executablePath: process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true, args: ['--no-sandbox'] });
const page = await browser.newPage();
await page.setViewport({ width: 1600, height: 900 });
const errors = [];
page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
page.on('console', (m) => { if (m.type() === 'error') errors.push('console: ' + m.text()); });
await page.evaluateOnNewDocument(() => { try { localStorage.clear(); } catch (e) {} });
await page.goto(pathToFileURL(dist).href);
await page.waitForSelector('#menubar .menu');
const st = () => page.evaluate(() => { const s = window.ZPDF.state(); return { tab: s.tab, sel: s.sel, dirty: s.dirty, n: s.doc.pages[0].els.length, iface: s.doc.iface.length, zoom: s.zoom, els: s.doc.pages[0].els }; });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---- start
let s = await st();
check('starts on the layout tab with an empty form', s.tab === 'layout' && s.n === 0);
check('menu bar has 9 menus', (await page.$$eval('#menubar .menu', (n) => n.length)) === 9);
check('four palettes are shown', (await page.$$eval('.panel', (n) => n.length)) === 4);
check('library groups: 4, barcodes collapsed by default', (await page.$$eval('#pb_lib .acc', (n) => n.length)) === 4 && (await page.$$eval('#pb_lib .acc.closed', (n) => n.length)) === 3);
await page.screenshot({ path: join(out, '01-empty.png') });

// ---- interface
await page.click('.mtab[data-tab="iface"]');
await page.type('#ifName', 'INPUT');
await page.type('#ifType', 'zpdf_s_input');
await page.click('[data-act="ifaceAdd"]');
await sleep(200);
s = await st();
check('interface parameter added through DDIC_RESOLVE', s.iface === 1 && s.dirty === true);
check('context tree lists the fields', (await page.$$eval('#ifaceTab .ctx .trow', (n) => n.length)) >= 14);
check('ABAP call code uses render_form', (await page.$eval('#abapCode', (n) => n.textContent)).includes("( name = 'INPUT' value = REF #( ls_input ) ) )"));
await page.screenshot({ path: join(out, '02-interface.png') });

// ---- parameter name rules: required, never defaulted, unique, at most 16 characters
const tryAdd = async (name, type) => {
  await page.$eval('#ifName', (n, v) => { n.value = v; }, name);
  await page.$eval('#ifType', (n, v) => { n.value = v; }, type);
  await page.click('[data-act="ifaceAdd"]');
  await sleep(150);
  return page.evaluate(() => ({ n: window.ZPDF.state().doc.iface.length, toast: document.getElementById('toast').textContent, err: document.getElementById('toast').className === 'error', focus: document.activeElement && document.activeElement.id }));
};
let pr = await tryAdd('', 'T001');
check('a parameter without a name is refused (no name is derived from the type)', pr.n === 1 && pr.err && pr.focus === 'ifName', JSON.stringify(pr));
pr = await tryAdd('INPUT', 'T001');
check('a parameter name cannot be repeated in a form', pr.n === 1 && pr.err && pr.toast.includes('INPUT'), JSON.stringify(pr));
pr = await tryAdd('A234567890123456X', 'T001');
check('the name field accepts at most 16 characters', (await page.$eval('#ifName', (n) => n.maxLength)) === 16 && pr.n === 1 && pr.err, JSON.stringify(pr));
pr = await tryAdd('IS_COMPANY_CODE1', 'T001');
check('a name of exactly 16 characters is accepted', pr.n === 2 && !pr.err, JSON.stringify(pr));
await page.evaluate(() => { const s = window.ZPDF.state(); s.doc.iface.pop(); window.ZPDF.App.commit(); });
// DDIC search dialog
await page.click('[data-act="ddicSearch"]');
await page.$eval('#ddQ', (n) => { n.value = 'T0'; });
await page.click('#ddGo');
await sleep(150);
check('DDIC search lists T001', (await page.$$eval('#ddList .pk-item', (n) => n.map((x) => x.dataset.name))).includes('T001'));
await page.keyboard.press('Escape');

// ---- layout: data view
await page.click('.mtab[data-tab="layout"]');
await sleep(100);
check('data view shows the interface tree', (await page.$$eval('#pb_data .trow', (n) => n.length)) >= 10);
// double click a field: inserts a bound text
const row = await page.$('#pb_data .trow[data-key="INPUT.GONDEREN_BANKA"]');
await row.click({ count: 2 });
await sleep(150);
s = await st();
check('double click on a data field inserts a bound text', s.n === 1 && s.els[0].bind === 'INPUT.GONDEREN_BANKA' && s.sel.length === 1);

// drag it with the mouse
const box = await (await page.$('.el[data-id="' + s.els[0].id + '"]')).boundingBox();
const before = { x: s.els[0].x, y: s.els[0].y };
await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
await page.mouse.down();
await page.mouse.move(box.x + box.width / 2 + 120, box.y + box.height / 2 + 80, { steps: 8 });
await page.mouse.up();
s = await st();
check('mouse drag moves the object', s.els[0].x > before.x + 5 && s.els[0].y > before.y + 5, JSON.stringify([before, s.els[0].x, s.els[0].y]));

// resize with the south-east handle
const h = await (await page.$('.handle.h-se')).boundingBox();
const w0 = s.els[0].w;
await page.mouse.move(h.x + 4, h.y + 4);
await page.mouse.down();
await page.mouse.move(h.x + 64, h.y + 24, { steps: 5 });
await page.mouse.up();
s = await st();
check('handle drag resizes the object', s.els[0].w > w0 + 3);

// keyboard: nudge, undo, redo
const x1 = s.els[0].x;
await page.keyboard.press('ArrowRight');
s = await st();
check('arrow key nudges by the grid step', Math.abs(s.els[0].x - (x1 + 1)) < 0.01);
await page.keyboard.down('Control'); await page.keyboard.press('z'); await page.keyboard.up('Control');
s = await st();
check('Ctrl+Z undoes', Math.abs(s.els[0].x - x1) < 0.01);

// library: click adds; barcode group opens
await page.click('#pb_lib .acch[data-acc="lib_codes"]');
await page.click('#pb_lib [data-lib="bc_qr"]');
await sleep(150);
await page.keyboard.press('Escape');
await page.click('#pb_lib [data-lib="text"]');
await sleep(100);
s = await st();
check('library click adds QR and text', s.n === 3 && s.els[1].code === 'qr' && s.els[2].type === 'text');

// drop a table node through the same code path as HTML5 drop
await page.evaluate(() => window.ZPDF.App.dropped({ kind: 'table', path: 'INPUT.ITEMS', table: '' }, 12, 120));
await sleep(100);
s = await st();
const tbl = s.els.find((e) => e.type === 'table');
check('table node creates a bound table with its columns', !!tbl && tbl.bind === 'INPUT.ITEMS' && tbl.cols.length === 5 && tbl.cols[2].fmt === '#.##0,00');

// property panel: change font size of the text through the input
await page.evaluate(() => { const s = window.ZPDF.state(); window.ZPDF.App.select([s.doc.pages[0].els[2].id]); });
await page.click('#pb_obj [data-otab="props"]');
await sleep(50);
check('property groups are collapsible accordions', (await page.$$eval('#pb_obj .acc', (n) => n.length)) >= 6);
const sizeInput = await page.$('#pb_obj [data-k="size"]');
await sizeInput.click({ count: 3 });
await page.keyboard.type('18');
await page.keyboard.press('Tab');
await sleep(80);
s = await st();
check('typing a font size updates the object', s.els[2].size === 18);
await page.click('#pb_obj .acch[data-acc="props_pos"]');
check('a property group collapses', (await page.$$eval('#pb_obj .acc.closed', (n) => n.length)) === 1);

// binding tab: picker
await page.click('#pb_obj [data-otab="bind"]');
await page.click('#pb_obj [data-pick="bind"]');
await page.type('.picker .pk-q', 'IBAN');
await sleep(50);
const items = await page.$$eval('.picker .pk-item', (n) => n.map((x) => x.dataset.path));
check('binding picker offers only interface fields', items.length === 1 && items[0] === 'INPUT.GONDEREN_IBAN', JSON.stringify(items));
await page.click('.picker .pk-item');
await sleep(80);
s = await st();
check('picker binds the object', s.els[2].bind === 'INPUT.GONDEREN_IBAN');
await page.screenshot({ path: join(out, '03-layout.png') });

// menus
await page.click('.menu[data-menu="palettes"] .mtitle');
await page.screenshot({ path: join(out, '04-menu-palettes.png') });
await page.click('.menu[data-menu="palettes"] .mi[data-arg="hier"]');
check('Palettes menu hides a palette', (await page.$$eval('.panel', (n) => n.length)) === 3);
await page.click('.menu[data-menu="palettes"] .mtitle');
await page.click('.menu[data-menu="palettes"] .mi[data-act="panelsAll"]');
check('Palettes menu shows all again', (await page.$$eval('.panel', (n) => n.length)) === 4);
await page.click('.panel[data-panel="lib"] [data-pact="collapse"]');
check('a palette collapses to its header', (await page.$$eval('.panel.collapsed', (n) => n.length)) === 1);
await page.click('.panel[data-panel="lib"] [data-pact="collapse"]');
await sleep(500); // the toolbar is drawn again shortly after a change
await page.click('.menu[data-menu="insert"] .mtitle');
await page.hover('.menu[data-menu="insert"] .mi.has-sub:nth-child(4)');
await page.screenshot({ path: join(out, '05-menu-insert.png') });
await page.keyboard.press('Escape');

// warnings and save
const conv = await page.evaluate(() => { const r = window.ZPDF.App.converted(); return { warnings: r.warnings, html: r.html.replace(/<!--zpdf-studio:[^>]*-->/, '') }; });
check('conversion has only the expected warning (QR without value)', conv.warnings.length === 1, JSON.stringify(conv.warnings));
check('engine HTML has the each loop and the interface comment', conv.html.includes('{{#each INPUT.ITEMS}}') && conv.html.includes('<!--zpdf-iface:INPUT=ZPDF_S_INPUT-->'));
await page.keyboard.down('Control'); await page.keyboard.press('s'); await page.keyboard.up('Control');
await sleep(200);
s = await st();
check('Ctrl+S saves and clears the dirty flag', s.dirty === false);
await page.click('.mtab[data-tab="form"]');
await page.screenshot({ path: join(out, '06-form.png') });

// English
await page.click('.mtab[data-tab="layout"]');
await page.evaluate(() => window.ZPDF.App.run('lang', 'EN'));
check('language switch to English', (await page.$eval('.menu[data-menu="file"] .mtitle', (n) => n.textContent)) === 'File');
await page.evaluate(() => window.ZPDF.App.run('toggle', 'sample'));
await page.screenshot({ path: join(out, '07-english-sample.png') });
// ---- zoom: fixed steps through 100 %, the tools never shrink
await page.evaluate(() => window.ZPDF.Canvas.setZoom(1.38));
await page.click('.tb[data-act="zoomOut"]');
check('zoom out from 138 % lands on 125 %', (await st()).zoom === 1.25);
await page.click('.tb[data-act="zoomOut"]');
await page.click('.tb[data-act="zoomOut"]');
check('two more steps reach exactly 100 %', (await st()).zoom === 1);
await page.click('.tb[data-act="zoomIn"]');
check('zoom in from 100 % goes to 110 %', (await st()).zoom === 1.1);
await page.click('.tb.zoomv');
check('a click on the percentage returns to 100 %', (await st()).zoom === 1);
const wheel = await page.evaluate(() => {
  const paper = document.getElementById('paper');
  const r = paper.getBoundingClientRect();
  const fire = (target, init) => { const ev = new WheelEvent('wheel', Object.assign({ bubbles: true, cancelable: true, clientX: r.left + 50, clientY: r.top + 50 }, init)); target.dispatchEvent(ev); return ev.defaultPrevented; };
  const out = {};
  out.altPrevented = fire(paper, { altKey: true, deltaY: -100 });
  out.afterAlt = window.ZPDF.state().zoom;
  out.ctrlPrevented = fire(paper, { ctrlKey: true, deltaY: 100 });
  out.afterCtrl = window.ZPDF.state().zoom;
  out.toolsPrevented = fire(document.getElementById('menubar'), { ctrlKey: true, deltaY: 100 });
  out.afterTools = window.ZPDF.state().zoom;
  out.plain = fire(paper, { deltaY: 100 });
  return out;
});
check('Alt + wheel over the page zooms the page', wheel.altPrevented && wheel.afterAlt === 1.1, JSON.stringify(wheel));
check('Ctrl + wheel over the page zooms the page as well', wheel.ctrlPrevented && wheel.afterCtrl === 1, JSON.stringify(wheel));
check('Ctrl + wheel over the tools is swallowed (no browser zoom) and does not zoom the page', wheel.toolsPrevented && wheel.afterTools === 1 && wheel.plain === false, JSON.stringify(wheel));
await page.click('#pb_obj');
const keys = await page.evaluate(() => {
  const fire = (key, init) => { const ev = new KeyboardEvent('keydown', Object.assign({ key, bubbles: true, cancelable: true }, init)); (document.activeElement || document.body).dispatchEvent(ev); return ev.defaultPrevented; };
  const input = document.querySelector('#ifName') || document.querySelector('input[type="text"]');
  const out = {};
  out.minus = fire('-', { ctrlKey: true });
  out.afterMinus = window.ZPDF.state().zoom;
  out.zero = fire('0', { ctrlKey: true });
  out.afterZero = window.ZPDF.state().zoom;
  return out;
});
check('Ctrl + minus and Ctrl + 0 zoom the page instead of the browser', keys.minus && keys.afterMinus === 0.9 && keys.zero && keys.afterZero === 1, JSON.stringify(keys));
// ---- theme: switch in the toolbar, remembered for the user
check('the designer starts in the light theme', (await page.evaluate(() => document.documentElement.getAttribute('data-theme'))) === null);
await page.click('.theme [data-arg="dark"]');
const dark = await page.evaluate(() => ({ attr: document.documentElement.getAttribute('data-theme'), panel: getComputedStyle(document.getElementById('toolbar')).backgroundColor, paper: getComputedStyle(document.getElementById('paper')).backgroundColor, on: document.querySelector('.theme [data-arg="dark"]').className, stored: localStorage.getItem('zpdf-studio2:prefs') }));
check('the moon button switches to the dark theme; the paper stays white', dark.attr === 'dark' && dark.panel === 'rgb(34, 40, 48)' && dark.paper === 'rgb(255, 255, 255)' && dark.on === 'on', JSON.stringify(dark));
check('the choice is stored for the user', JSON.parse(dark.stored).theme === 'dark', dark.stored);
await page.screenshot({ path: join(out, '10-dark.png') });
await page.click('.theme [data-arg="light"]');
check('the sun button returns to the light theme', (await page.evaluate(() => document.documentElement.getAttribute('data-theme'))) === null);
// ---- small window: the tools keep their size, the window scrolls
await page.setViewport({ width: 760, height: 420 });
await sleep(150);
const small = await page.evaluate(() => ({ panels: Array.prototype.map.call(document.querySelectorAll('.panel'), (p) => Math.round(p.getBoundingClientRect().width)), lib: document.querySelectorAll('#pb_lib .libitem').length, sw: document.documentElement.scrollWidth, sh: document.documentElement.scrollHeight, tb: Math.round(document.getElementById('toolbar').getBoundingClientRect().width), paper: Math.round(document.getElementById('canvasArea').getBoundingClientRect().width) }));
check('in a small window nothing is squeezed away: the designer keeps 1120 x 620 and scrolls', small.panels.length === 4 && small.panels.every((w) => w >= 200) && small.sw >= 1120 && small.sh >= 620 && small.tb >= 1120 && small.paper >= 300, JSON.stringify(small));
await page.setViewport({ width: 1600, height: 900 });
await sleep(100);
check('no script errors (browser mode)', errors.length === 0, errors.join(' | '));

// ---- SAP mode: boot data, captured posts, frame replies, reload
const savedHtml = await page.evaluate(() => window.ZPDF.App.converted().html);
const b64 = (t) => Buffer.from(t, 'utf8').toString('base64');
const boot = {
  runtime: 'sap', lang: 'TR', form: 'ZPDF_TEST', viewOnly: false, user: 'DEMO_USER', version: '0003', description: 'Test formu',
  doc64: b64(JSON.stringify(await page.evaluate(() => window.ZPDF.state().doc))), sample64: '', ui64: '', dirty: false, autosave: true, assets: [],
  message: { type: 'S', text: 'Hoş geldiniz' }, reply: null
};
const sapFile = join(out, 'designer-sap.html');
writeFileSync(sapFile, readFileSync(dist, 'utf8').replace('__ZPDF_BOOT__', () => JSON.stringify(boot).replace(/</g, '\\u003c')));
const sap = await browser.newPage();
await sap.setViewport({ width: 1500, height: 850 });
const sapErrors = [];
sap.on('pageerror', (e) => sapErrors.push(e.message));
await sap.evaluateOnNewDocument(() => {
  window.__posts = [];
  HTMLFormElement.prototype.submit = function () { window.__posts.push({ action: this.getAttribute('action'), payload: this.querySelector('textarea').value }); };
});
await sap.goto(pathToFileURL(sapFile).href);
await sap.waitForSelector('#menubar .menu');
const decode = (payload) => Object.fromEntries(Buffer.from(payload, 'base64').toString('utf8').split('\n').map((l) => { const p = l.split('\t'); return [p[1], Buffer.from(p[2] || '', 'base64').toString('utf8')]; }));
let ss = await sap.evaluate(() => { const s = window.ZPDF.state(); return { form: s.form, version: s.version, n: s.doc.pages[0].els.length, dirty: s.dirty, badge: document.getElementById('formBadge').textContent, toast: document.getElementById('toast').textContent }; });
check('SAP boot: form, version, stored design, message', ss.form === 'ZPDF_TEST' && ss.version === '0003' && ss.n === 4 && ss.dirty === false && ss.toast === 'Hoş geldiniz', JSON.stringify(ss));

// a change schedules a SYNC; leaving the window sends it at once
await sap.evaluate(() => { const s = window.ZPDF.state(); window.ZPDF.App.select([s.doc.pages[0].els[0].id]); });
await sap.keyboard.press('ArrowDown');
await sap.evaluate(() => window.dispatchEvent(new Event('blur')));
let posts = await sap.evaluate(() => window.__posts);
check('a change is synchronised to ABAP when the window loses focus', posts.length === 1 && posts[0].action === 'sapevent:SYNC');
const sync = decode(posts[0].payload);
check('SYNC carries html, page, sample, ui, dirty and autosave', sync.html.startsWith('<!--zpdf-studio:') && sync.page_size === 'A4' && sync.dirty === 'X' && sync.autosave === 'X' && JSON.parse(sync.ui).tab === 'layout' && sync.iface === 'INPUT=ZPDF_S_INPUT' && !!JSON.parse(sync.sample).INPUT);

// save: the request carries the state; ABAP answers by showing the page again
await sap.evaluate(() => window.ZPDF.App.run('save'));
posts = await sap.evaluate(() => window.__posts);
const save = decode(posts[1].payload);
check('SAVE is posted with a request id and the state', posts[1].action === 'sapevent:SAVE' && Number(save.req) > 0 && save.html.length > 100);
check('a busy veil covers the page while SAP works', await sap.evaluate(() => document.getElementById('busy').className === ''));
const stash = await sap.evaluate(() => window.name);
check('the undo history is stashed in window.name', stash.startsWith('ZPDF2') && JSON.parse(stash.slice(5)).stack.length >= 2);

// the new display: boot data with the state the page sent, dirty = false, and the answer
const boot2 = Object.assign({}, boot, {
  doc64: Buffer.from(save.html.slice('<!--zpdf-studio:'.length, save.html.indexOf('-->')), 'utf8').toString('utf8'),
  ui64: b64(save.ui), dirty: false, version: '0004', message: null,
  reply: { id: Number(save.req), ok: true, kind: 'save', message: 'ZPDF_TEST kaydedildi, sürüm 0004.', data64: b64(JSON.stringify({ version: '0004' })) }
});
writeFileSync(sapFile, readFileSync(dist, 'utf8').replace('__ZPDF_BOOT__', () => JSON.stringify(boot2).replace(/</g, '\u003c')));
await sap.goto(pathToFileURL(sapFile).href);
await sap.waitForSelector('#menubar .menu');
ss = await sap.evaluate(() => { const s = window.ZPDF.state(); return { version: s.version, dirty: s.dirty, toast: document.getElementById('toast').textContent, undo: s.history.canUndo(), n: s.doc.pages[0].els.length, busy: document.getElementById('busy').className, sel: s.sel.length }; });
check('after the new display the form is saved, the design and the selection are back', ss.version === '0004' && ss.dirty === false && ss.toast.includes('0004') && ss.n === 4 && ss.busy === 'hidden' && ss.sel === 1, JSON.stringify(ss));
check('the undo history survived the new display', ss.undo === true);

// DDIC search: request, new display with the results, the dialog opens again
await sap.click('.mtab[data-tab="iface"]');
await sap.type('#ifName', 'KALEM');
await sap.click('[data-act="ddicSearch"]');
await sap.$eval('#ddQ', (n) => { n.value = 'ZPDF*'; });
await sap.click('#ddGo');
posts = await sap.evaluate(() => window.__posts);
const search = decode(posts[posts.length - 1].payload);
check('DDIC_SEARCH is posted with the query and the state', posts[posts.length - 1].action === 'sapevent:DDIC_SEARCH' && search.q === 'ZPDF*' && search.html.length > 100 && JSON.parse(search.ui).pendingSearch.q === 'ZPDF*' && search.kinds === 'SDVTE' && search.max === '100');
const boot3 = Object.assign({}, boot2, { ui64: b64(search.ui), reply: { id: 9, ok: true, kind: 'ddic_search', message: '', data64: b64(JSON.stringify([{ name: 'ZPDF_TT_ITEMS', kind: 'T', descr: 'Kalemler' }])) } });
writeFileSync(sapFile, readFileSync(dist, 'utf8').replace('__ZPDF_BOOT__', () => JSON.stringify(boot3).replace(/</g, '\u003c')));
await sap.goto(pathToFileURL(sapFile).href);
await sap.waitForSelector('#ddList .pk-item');
check('the search dialog opens again with the results, the typed name is kept', (await sap.$eval('#ddList .pk-item', (n) => n.dataset.name)) === 'ZPDF_TT_ITEMS' && (await sap.$eval('#ifName', (n) => n.value)) === 'KALEM');
await sap.click('#ddList .pk-item');
check('picking a result fills the type', (await sap.$eval('#ifType', (n) => n.value)) === 'ZPDF_TT_ITEMS');
check('picking a result keeps the name the user typed', (await sap.$eval('#ifName', (n) => n.value)) === 'KALEM');
await sap.click('[data-act="ifaceAdd"]');
posts = await sap.evaluate(() => window.__posts);
const resolve = decode(posts[posts.length - 1].payload);
check('DDIC_RESOLVE is posted and remembers what it is for', posts[posts.length - 1].action === 'sapevent:DDIC_RESOLVE' && resolve.type === 'ZPDF_TT_ITEMS' && JSON.parse(resolve.ui).pendingParam.name === 'KALEM');
const boot4 = Object.assign({}, boot3, { ui64: b64(resolve.ui), reply: { id: 10, ok: true, kind: 'ddic_resolve', message: '', data64: b64(JSON.stringify({ k: 'T', d: 'Kalemler', c: [{ n: 'ALICI', k: 'E', t: 'C', l: 60, d: 'Alıcı' }] })) } });
writeFileSync(sapFile, readFileSync(dist, 'utf8').replace('__ZPDF_BOOT__', () => JSON.stringify(boot4).replace(/</g, '\u003c')));
await sap.goto(pathToFileURL(sapFile).href);
await sap.waitForSelector('#menubar .menu');
ss = await sap.evaluate(() => { const s = window.ZPDF.state(); return { iface: s.doc.iface.map((p) => p.name + '=' + p.type), tab: s.tab, dirty: s.dirty }; });
check('the resolved type is added to the interface after the new display', ss.iface.join(';') === 'INPUT=ZPDF_S_INPUT;KALEM=ZPDF_TT_ITEMS' && ss.tab === 'iface' && ss.dirty === true, JSON.stringify(ss));

// preview and sync do not veil the page (ABAP does not show the page again)
await sap.evaluate(() => window.ZPDF.App.run('preview'));
check('preview keeps the page usable', await sap.evaluate(() => document.getElementById('busy').className === 'hidden' && window.__posts[window.__posts.length - 1].action === 'sapevent:PREVIEW'));

// transport with unsaved changes asks first, then posts with save=X
await sap.evaluate(() => window.ZPDF.App.run('transport'));
check('transport asks to save first', (await sap.$$eval('.dlg', (n) => n.length)) === 1);
await sap.click('.dlg .btn.primary');
posts = await sap.evaluate(() => window.__posts);
const tr = posts[posts.length - 1];
check('TRANSPORT is posted with the full state', tr.action === 'sapevent:TRANSPORT' && decode(tr.payload).save === 'X' && decode(tr.payload).html.length > 100);
// search dialog: object types, package and row limit travel with the request
await sap.evaluate(() => window.ZPDF.App.busy(false)); // the veil of the transport request above
await sap.click('.mtab[data-tab="iface"]');
await sap.click('[data-act="ddicSearch"]');
await sap.$eval('#ddQ', (n) => { n.value = ''; });
await sap.$eval('#ddPkg', (n) => { n.value = 'zpdf*'; });
await sap.$eval('#ddMax', (n) => { n.value = '200'; });
await sap.click('.ddkinds [data-kind="S"]');
await sap.click('.ddkinds [data-kind="D"]');
await sap.click('.ddkinds [data-kind="V"]');
await sap.click('#ddGo');
posts = await sap.evaluate(() => window.__posts);
const filtered = decode(posts[posts.length - 1].payload);
check('the search carries object types, package and row limit', posts[posts.length - 1].action === 'sapevent:DDIC_SEARCH' && filtered.q === '' && filtered.kinds === 'TE' && filtered.pkg === 'ZPDF*' && filtered.max === '200', JSON.stringify([filtered.q, filtered.kinds, filtered.pkg, filtered.max]));
await sap.evaluate(() => window.ZPDF.App.busy(false));
await sap.keyboard.press('Escape');
// no minimum length for the name; no object type chosen means every type
await sap.click('[data-act="ddicSearch"]');
await sap.$eval('#ddQ', (n) => { n.value = 'z*'; });
await sap.$eval('#ddPkg', (n) => { n.value = ''; });
for (const k of ['S', 'D', 'V', 'T', 'E']) {
  if (await sap.$eval('.ddkinds [data-kind="' + k + '"]', (n) => n.checked)) await sap.click('.ddkinds [data-kind="' + k + '"]');
}
await sap.click('#ddGo');
posts = await sap.evaluate(() => window.__posts);
const zstar = decode(posts[posts.length - 1].payload);
check('Z* is searched without a minimum length, with every object type', posts[posts.length - 1].action === 'sapevent:DDIC_SEARCH' && zstar.q === 'Z*' && zstar.kinds === 'SDVTE' && zstar.pkg === '', JSON.stringify([zstar.q, zstar.kinds, zstar.pkg]));
await sap.evaluate(() => window.ZPDF.App.busy(false));
await sap.keyboard.press('Escape');
// theme inside SAP: the choice is posted to ABAP, and the boot data bring it back
await sap.click('.theme [data-arg="dark"]');
posts = await sap.evaluate(() => window.__posts);
const prefsPost = decode(posts[posts.length - 1].payload);
check('the theme is posted to ABAP as a user setting without a new display', posts[posts.length - 1].action === 'sapevent:PREFS' && JSON.parse(prefsPost.prefs).theme === 'dark' && await sap.evaluate(() => document.getElementById('busy').className === 'hidden'), prefsPost.prefs);
const boot5 = Object.assign({}, boot, { prefs64: b64(JSON.stringify({ theme: 'dark', lang: 'TR' })), reply: null, message: null });
writeFileSync(sapFile, readFileSync(dist, 'utf8').replace('<html lang="tr">', '<html lang="tr" data-theme="dark">').replace('__ZPDF_BOOT__', () => JSON.stringify(boot5).replace(/</g, '\\u003c')));
await sap.goto(pathToFileURL(sapFile).href);
await sap.waitForSelector('#menubar .menu');
check('a later session opens in the dark theme from the stored setting', await sap.evaluate(() => document.documentElement.getAttribute('data-theme') === 'dark' && window.ZPDF.state().theme === 'dark' && document.querySelector('.theme [data-arg="dark"]').className === 'on'));
check('no script errors (SAP mode)', sapErrors.length === 0, sapErrors.join(' | '));
await sap.screenshot({ path: join(out, '08-sap.png') });

// view only
boot.viewOnly = true;
writeFileSync(sapFile, readFileSync(dist, 'utf8').replace('__ZPDF_BOOT__', () => JSON.stringify(boot).replace(/</g, '\\u003c')));
await sap.goto(pathToFileURL(sapFile).href);
await sap.waitForSelector('#menubar .menu');
await sap.evaluate(() => { const s = window.ZPDF.state(); window.ZPDF.App.select([s.doc.pages[0].els[0].id]); });
await sap.keyboard.press('ArrowDown');
await sap.keyboard.press('Delete');
ss = await sap.evaluate(() => ({ n: window.ZPDF.state().doc.pages[0].els.length, posts: window.__posts.length, dis: document.querySelector('.tb[data-act="save"]').disabled }));
check('display mode: no changes, no posts, save disabled', ss.n === 4 && ss.posts === 0 && ss.dis === true, JSON.stringify(ss));

await browser.close();
console.log(results.join('\n'));
console.log(failed ? `\n${failed} FAILED` : `\nall ${results.length} checks passed`);
process.exitCode = failed ? 1 : 0;
