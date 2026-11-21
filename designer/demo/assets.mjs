// Draws the demo images (logo, seal, signature, stamp, event banner) with headless Chrome.
//   set ZPDF_MODULES=<folder with node_modules/puppeteer-core>   then   node demo/assets.mjs
// Output: demo/assets/*.png|jpg  (kept in the project; the pack builder only reads them).
import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(join(process.env.ZPDF_MODULES || here, 'x.js'));
const puppeteer = require('puppeteer-core');
const out = join(here, 'assets');
mkdirSync(out, { recursive: true });

const font = "font-family='Segoe UI, Arial, sans-serif'";

const logo = `<svg xmlns='http://www.w3.org/2000/svg' width='360' height='108' viewBox='0 0 360 108'>
  <defs><linearGradient id='g' x1='0' y1='0' x2='1' y2='1'><stop offset='0' stop-color='#14b8a6'/><stop offset='1' stop-color='#0f2a43'/></linearGradient></defs>
  <polygon points='54,8 94,31 94,77 54,100 14,77 14,31' fill='url(#g)'/>
  <polygon points='54,22 82,38 82,70 54,86 26,70 26,38' fill='none' stroke='#ffffff' stroke-width='3' opacity='.55'/>
  <path d='M38 72 V36 L70 72 V36' fill='none' stroke='#ffffff' stroke-width='8' stroke-linejoin='round' stroke-linecap='round'/>
  <text x='112' y='62' ${font} font-size='50' font-weight='800' fill='#0f2a43' letter-spacing='3'>NOVA</text>
  <text x='114' y='88' ${font} font-size='17' font-weight='600' fill='#0f766e' letter-spacing='9'>ENDÜSTRİ</text>
  <rect x='262' y='24' width='84' height='5' rx='2.5' fill='#f59e0b'/>
</svg>`;

function sealSvg() {
  let scallops = '';
  for (let i = 0; i < 28; i++) {
    const a = i / 28 * Math.PI * 2;
    scallops += `<circle cx='${(120 + Math.cos(a) * 96).toFixed(1)}' cy='${(120 + Math.sin(a) * 96).toFixed(1)}' r='14' fill='#c9a227'/>`;
  }
  let rays = '';
  for (let i = 0; i < 48; i++) {
    const a = i / 48 * Math.PI * 2;
    rays += `<line x1='${(120 + Math.cos(a) * 60).toFixed(1)}' y1='${(120 + Math.sin(a) * 60).toFixed(1)}' x2='${(120 + Math.cos(a) * 74).toFixed(1)}' y2='${(120 + Math.sin(a) * 74).toFixed(1)}' stroke='#fff7d6' stroke-width='1.6'/>`;
  }
  const star = [];
  for (let i = 0; i < 10; i++) {
    const a = -Math.PI / 2 + i * Math.PI / 5;
    const r = i % 2 ? 15 : 36;
    star.push((120 + Math.cos(a) * r).toFixed(1) + ',' + (114 + Math.sin(a) * r).toFixed(1));
  }
  return `<svg xmlns='http://www.w3.org/2000/svg' width='240' height='240' viewBox='0 0 240 240'>
  <defs><radialGradient id='s' cx='.38' cy='.32' r='.8'><stop offset='0' stop-color='#fde68a'/><stop offset='.55' stop-color='#d4a72c'/><stop offset='1' stop-color='#8a6a12'/></radialGradient></defs>
  ${scallops}
  <circle cx='120' cy='120' r='98' fill='url(#s)'/>
  <circle cx='120' cy='120' r='84' fill='none' stroke='#fff7d6' stroke-width='2.5'/>
  <circle cx='120' cy='120' r='78' fill='none' stroke='#8a6a12' stroke-width='1'/>
  ${rays}
  <polygon points='${star.join(' ')}' fill='#fff7d6' stroke='#8a6a12' stroke-width='1.2'/>
  <text x='120' y='176' text-anchor='middle' ${font} font-size='17' font-weight='800' fill='#5b4508' letter-spacing='3'>AKADEMİ</text>
</svg>`;
}

const sign = `<svg xmlns='http://www.w3.org/2000/svg' width='300' height='100' viewBox='0 0 300 100'>
  <path d='M18 70 C 30 20, 46 14, 44 46 C 42 78, 30 86, 40 58 C 52 26, 70 30, 66 56 C 63 76, 78 70, 86 52 C 92 38, 102 40, 98 58 C 96 70, 110 66, 118 48 C 126 30, 138 40, 132 60 C 128 74, 150 66, 160 44 C 166 30, 150 24, 150 44 C 150 68, 180 70, 200 50 C 214 36, 230 34, 262 40'
        fill='none' stroke='#1e3a8a' stroke-width='3.4' stroke-linecap='round' stroke-linejoin='round'/>
  <path d='M30 86 C 90 74, 190 72, 284 82' fill='none' stroke='#1e3a8a' stroke-width='2.2' stroke-linecap='round'/>
  <circle cx='276' cy='38' r='2.6' fill='#1e3a8a'/>
</svg>`;

const stamp = `<svg xmlns='http://www.w3.org/2000/svg' width='300' height='180' viewBox='0 0 300 180'>
  <g transform='rotate(-9 150 90)' fill='none' stroke='#b91c1c' opacity='.86'>
    <rect x='24' y='34' width='252' height='112' rx='14' stroke-width='6'/>
    <rect x='34' y='44' width='232' height='92' rx='8' stroke-width='2'/>
    <line x1='44' y1='72' x2='256' y2='72' stroke-width='2'/>
    <line x1='44' y1='118' x2='256' y2='118' stroke-width='2'/>
    <text x='150' y='65' text-anchor='middle' ${font} font-size='15' font-weight='700' fill='#b91c1c' stroke='none' letter-spacing='3'>NOVA ENDÜSTRİ A.Ş.</text>
    <text x='150' y='108' text-anchor='middle' ${font} font-size='34' font-weight='900' fill='#b91c1c' stroke='none' letter-spacing='4'>ONAYLANDI</text>
    <text x='150' y='133' text-anchor='middle' ${font} font-size='12' font-weight='700' fill='#b91c1c' stroke='none' letter-spacing='5'>MALİ İŞLER</text>
  </g>
</svg>`;

function bannerSvg() {
  const w = 1050, h = 390;
  let stars = '';
  let seed = 7;
  const rnd = () => { seed = (seed * 16807) % 2147483647; return seed / 2147483647; };
  for (let i = 0; i < 90; i++) stars += `<circle cx='${(rnd() * w).toFixed(0)}' cy='${(rnd() * 190).toFixed(0)}' r='${(rnd() * 1.6 + .4).toFixed(1)}' fill='#fff' opacity='${(rnd() * .7 + .2).toFixed(2)}'/>`;
  let beams = '';
  [[150, '#f472b6'], [330, '#60a5fa'], [520, '#fbbf24'], [710, '#34d399'], [900, '#a78bfa']].forEach(([x, c], i) => {
    const tilt = (i - 2) * 70;
    beams += `<polygon points='${x - 10},0 ${x + 10},0 ${x + 150 + tilt},${h} ${x - 150 + tilt},${h}' fill='${c}' opacity='.22'/>`;
  });
  let bars = '';
  for (let i = 0; i < 70; i++) {
    const bh = 20 + Math.abs(Math.sin(i * .55) * 60) + rnd() * 34;
    bars += `<rect x='${i * 15 + 3}' y='${(300 - bh).toFixed(0)}' width='9' height='${bh.toFixed(0)}' rx='3' fill='#fff' opacity='.16'/>`;
  }
  let crowd = `M0 ${h} L0 330`;
  for (let x = 0; x <= w; x += 30) crowd += ` Q ${x + 15} ${300 + rnd() * 22} ${x + 30} ${326 + rnd() * 14}`;
  crowd += ` L${w} ${h} Z`;
  return `<svg xmlns='http://www.w3.org/2000/svg' width='${w}' height='${h}' viewBox='0 0 ${w} ${h}'>
  <defs><linearGradient id='b' x1='0' y1='0' x2='1' y2='1'><stop offset='0' stop-color='#4c1d95'/><stop offset='.5' stop-color='#1e1b4b'/><stop offset='1' stop-color='#0f766e'/></linearGradient>
  <radialGradient id='glow' cx='.5' cy='1' r='.7'><stop offset='0' stop-color='#f59e0b' stop-opacity='.55'/><stop offset='1' stop-color='#f59e0b' stop-opacity='0'/></radialGradient></defs>
  <rect width='${w}' height='${h}' fill='url(#b)'/>
  ${stars}${beams}
  <rect width='${w}' height='${h}' fill='url(#glow)'/>
  ${bars}
  <path d='${crowd}' fill='#0b1020'/>
</svg>`;
}

const jobs = [
  { file: 'ZPDF_DEMO_LOGO.png', svg: logo, w: 360, h: 108, alpha: true },
  { file: 'ZPDF_DEMO_SEAL.png', svg: sealSvg(), w: 240, h: 240, alpha: true },
  { file: 'ZPDF_DEMO_SIGN.png', svg: sign, w: 300, h: 100, alpha: true },
  { file: 'ZPDF_DEMO_STAMP.png', svg: stamp, w: 300, h: 180, alpha: true },
  { file: 'ZPDF_DEMO_BANNER.jpg', svg: bannerSvg(), w: 1050, h: 390, alpha: false }
];

const browser = await puppeteer.launch({ executablePath: process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true, args: ['--no-sandbox'] });
const page = await browser.newPage();
for (const job of jobs) {
  await page.setViewport({ width: job.w, height: job.h, deviceScaleFactor: 1 });
  await page.setContent(`<!doctype html><html><body style="margin:0;background:${job.alpha ? 'transparent' : '#000'}">${job.svg}</body></html>`);
  const data = await page.screenshot(job.alpha
    ? { type: 'png', omitBackground: true, clip: { x: 0, y: 0, width: job.w, height: job.h } }
    : { type: 'jpeg', quality: 86, clip: { x: 0, y: 0, width: job.w, height: job.h } });
  writeFileSync(join(out, job.file), data);
  const buf = Buffer.from(data);
  const info = job.alpha ? `PNG depth ${buf[24]} colour type ${buf[25]} interlace ${buf[28]}` : 'JPEG';
  console.log(job.file, (buf.length / 1024).toFixed(1) + ' KB', info);
}
await browser.close();
