// Screenshots for the README: the designer in English with the demo forms.
//   set ZPDF_MODULES=<folder with node_modules/puppeteer-core>
//   node demo/screens.mjs <output folder>
import { readFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';
import vm from 'node:vm';
import { forms, ASSETS } from './forms.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');
const out = process.argv[2] || join(here, 'out', 'screens');
mkdirSync(out, { recursive: true });
const require = createRequire(join(process.env.ZPDF_MODULES || here, 'x.js'));
const puppeteer = require('puppeteer-core');

const code = ['10-core.js', '20-convert.js'].map((f) => readFileSync(join(root, 'src', f), 'utf8')).join('\n');
const ctx = vm.createContext({ btoa, atob, TextEncoder, TextDecoder, console });
vm.runInContext(code + '\nthis.api = { newDoc, normalizeDoc, defaultsFor, convert };', ctx);
const docs = Object.fromEntries(forms(ctx.api).map((f) => [f.id, f.doc]));
const assets = ASSETS.map((a) => ({ id: a.id, kind: 'IMAGE', mime: a.mime, description: a.description, data: readFileSync(join(here, 'assets', a.file)).toString('base64') }));

const browser = await puppeteer.launch({ executablePath: process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true, args: ['--no-sandbox'] });
const page = await browser.newPage();
const errors = [];
page.on('pageerror', (e) => errors.push(e.message));
await page.setViewport({ width: 1600, height: 900, deviceScaleFactor: 1 });
await page.evaluateOnNewDocument(() => { try { localStorage.clear(); } catch (e) {} });
await page.goto(pathToFileURL(join(root, 'dist', 'designer.html')).href);
await page.waitForSelector('#menubar .menu');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Loads a demo document in English, with the store images and options. */
async function show(id, opts) {
  await page.evaluate((doc, assets, opts) => {
    const A = window.ZPDF.App;
    const st = window.ZPDF.state();
    window.ZPDF.Menus.close();
    st.assets = assets;
    st.form = opts.form || '';
    st.version = opts.version || '';
    A.run('lang', 'EN');
    A.loadDoc(doc);
    st.view.sample = !!opts.sample;
    st.view.grid = opts.grid !== false;
    if (opts.theme) { st.theme = opts.theme; A.applyTheme(); }
    Object.keys(st.panels).forEach((k) => { st.panels[k].open = opts.panels !== false; st.panels[k].collapsed = false; });
    A.showTab(opts.tab || 'layout');
    A.refresh();
    if (opts.select) st.sel = [st.doc.pages[0].els.filter((e) => e.name === opts.select)[0].id];
    A.select(st.sel);
  }, docs[id], assets, opts);
  await sleep(150);
  await page.evaluate((zoom) => { if (zoom === 'page') window.ZPDF.Canvas.fit('page'); else window.ZPDF.Canvas.setZoom(zoom); }, opts.zoom || 'page');
  await sleep(350);
}

// 1. the designer: purchase order, light theme, preview data on, a table selected
await show('ZPDF_DEMO_ORDER', { form: 'ZPDF_DEMO_ORDER', version: '0001', sample: true, select: 'kalemler' });
await page.screenshot({ path: join(out, 'designer-light.png') });

// 2. dark theme: event ticket at 100 %
await show('ZPDF_DEMO_TICKET', { form: 'ZPDF_DEMO_TICKET', version: '0001', sample: true, theme: 'dark', zoom: 1, select: 'kupon_qr' });
await page.screenshot({ path: join(out, 'designer-dark.png') });

// 3. interface tab: three parameters of three kinds
await show('ZPDF_DEMO_ORDER', { form: 'ZPDF_DEMO_ORDER', version: '0001', theme: 'light', tab: 'iface' });
await page.screenshot({ path: join(out, 'interface.png') });

// 4. the Layout menu with Align text
await show('ZPDF_DEMO_CERT', { form: 'ZPDF_DEMO_CERT', version: '0001', sample: true, select: 'ad_soyad' });
await page.click('#menubar .menu[data-menu="layout"] .mtitle');
await sleep(100);
const sub = await page.evaluateHandle(() => Array.prototype.filter.call(document.querySelectorAll('#menubar .dropdown > .mi.has-sub'), (n) => n.querySelector('.mlbl').textContent === 'Align text')[0]);
await sub.asElement().hover();
await sleep(200);
await page.screenshot({ path: join(out, 'menu-align.png') });
await page.evaluate(() => window.ZPDF.Menus.close());

if (errors.length) console.log('PAGE ERRORS: ' + errors.join(' | '));
await browser.close();
console.log('screenshots in ' + out);
