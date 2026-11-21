// Builds the demo pack of ZPDF Studio: dist/zpdf-demo-pack.txt
//   node demo/build.mjs            (pack only)
//   set ZPDF_MODULES=<folder with node_modules/puppeteer-core>  ->  also screenshots in demo/out
//
// The pack is a text file that program ZPDF_STUDIO_DEMO imports ("Install demo forms"):
//   ZPDF-DEMO-PACK <TAB> 1
//   FORM  <TAB> form id <TAB> base64(description) <TAB> envelope
//   ASSET <TAB> asset id <TAB> base64(description) <TAB> file name <TAB> base64(content)
// The envelope of a form is what the designer sends when it saves: base64 of the lines
// "META <TAB> name <TAB> base64(value)" (html, page_size, orientation, margins, sample ...).
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';
import vm from 'node:vm';
import { forms, ASSETS } from './forms.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');
const src = join(root, 'src');
const code = ['10-core.js', '20-convert.js'].map((f) => readFileSync(join(src, f), 'utf8')).join('\n');
const ctx = vm.createContext({ btoa, atob, TextEncoder, TextDecoder, console });
vm.runInContext(code + '\nthis.api = { newDoc, normalizeDoc, defaultsFor, convert, extractDoc };', ctx);
const z = ctx.api;

const b64 = (text) => Buffer.from(String(text), 'utf8').toString('base64');
const lines = ['ZPDF-DEMO-PACK\t1'];
const summary = [];
let problems = 0;
mkdirSync(join(here, 'out'), { recursive: true });

const list = forms(z);
for (const form of list) {
  const result = z.convert(form.doc, { fonts: [], images: ASSETS.map((a) => a.id) });
  if (result.warnings.length) {
    problems += result.warnings.length;
    console.log(form.id + ' WARNINGS:\n  ' + [...result.warnings].join('\n  '));
  }
  // the form must open again exactly as it was built
  const back = z.extractDoc(result.html);
  if (JSON.stringify(back) !== JSON.stringify(form.doc)) { problems++; console.log(form.id + ': the embedded document differs'); }
  const state = [
    ['form_id', form.id], ['html', result.html], ['header', ''], ['footer', ''], ['css', ''],
    ['page_size', result.page.page_size], ['orientation', result.page.orientation],
    ['margin_top', result.page.margin_top], ['margin_right', result.page.margin_right],
    ['margin_bottom', result.page.margin_bottom], ['margin_left', result.page.margin_left],
    ['sample', form.doc.sample], ['description', form.description]
  ];
  const envelope = b64(state.map((l) => 'META\t' + l[0] + '\t' + b64(l[1])).join('\n'));
  lines.push(['FORM', form.id, b64(form.description), envelope].join('\t'));
  writeFileSync(join(here, 'out', form.id + '.json'), JSON.stringify(form.doc, null, 1));
  summary.push({ id: form.id, description: form.description, objects: form.doc.pages[0].els.length, fields: [...result.fields], html: result.html.length, page: result.page });
  console.log(form.id.padEnd(20), String(form.doc.pages[0].els.length).padStart(3) + ' objects', String(result.fields.length).padStart(3) + ' fields', (result.html.length / 1024).toFixed(1) + ' KB');
}
for (const asset of ASSETS) {
  const data = readFileSync(join(here, 'assets', asset.file));
  lines.push(['ASSET', asset.id, b64(asset.description), asset.file, data.toString('base64')].join('\t'));
}
if (problems) { console.error(problems + ' problem(s): pack not written'); process.exit(1); }
mkdirSync(join(root, 'dist'), { recursive: true });
const pack = lines.join('\n') + '\n';
writeFileSync(join(root, 'dist', 'zpdf-demo-pack.txt'), pack, 'utf8');
writeFileSync(join(here, 'out', 'summary.json'), JSON.stringify(summary, null, 1));
console.log('dist/zpdf-demo-pack.txt  ' + (Buffer.byteLength(pack) / 1024).toFixed(1) + ' KB  (' + list.length + ' forms, ' + ASSETS.length + ' images)');

// ---- screenshots: every form in the real designer, with its preview data
if (process.env.ZPDF_MODULES) {
  const require = createRequire(join(process.env.ZPDF_MODULES, 'x.js'));
  const puppeteer = require('puppeteer-core');
  const browser = await puppeteer.launch({ executablePath: process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  await page.setViewport({ width: 1700, height: 1250, deviceScaleFactor: 1 });
  await page.evaluateOnNewDocument(() => { try { localStorage.clear(); } catch (e) {} });
  await page.goto(pathToFileURL(join(root, 'dist', 'designer.html')).href);
  await page.waitForSelector('#menubar .menu');
  const assets = ASSETS.map((a) => ({ id: a.id, kind: 'IMAGE', mime: a.mime, description: a.description, data: readFileSync(join(here, 'assets', a.file)).toString('base64') }));
  for (const form of list) {
    const info = await page.evaluate((doc, assets) => {
      const A = window.ZPDF.App;
      const st = window.ZPDF.state();
      st.assets = assets;
      A.loadDoc(doc);
      st.view.sample = true;
      st.view.grid = false;
      Object.keys(st.panels).forEach((id) => { st.panels[id].open = false; });
      A.showTab('layout');
      window.ZPDF.Canvas.fit('page');
      A.refresh();
      return { warnings: A.converted().warnings, zoom: st.zoom };
    }, form.doc, assets);
    await new Promise((r) => setTimeout(r, 500));
    const paper = await page.$('#paper');
    await paper.screenshot({ path: join(here, 'out', form.id + '.png') });
    console.log('screenshot', form.id, 'zoom ' + Math.round(info.zoom * 100) + '%', info.warnings.length ? 'WARNINGS ' + info.warnings.join(' | ') : '');
  }
  if (errors.length) console.log('PAGE ERRORS: ' + errors.join(' | '));
  await browser.close();
}
