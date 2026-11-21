// Builds dist/designer.html: one self-contained file (no dependencies, no bundler).
//   node build.mjs
import { readFileSync, writeFileSync, mkdirSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const src = join(root, 'src');
const files = readdirSync(src).filter((f) => /^\d\d-.*\.js$/.test(f)).sort();
const js = files.map((f) => `// ---- ${f} ----\n${readFileSync(join(src, f), 'utf8')}`).join('\n');
const css = readFileSync(join(src, 'style.css'), 'utf8');
const wrapped = `(function () {\n'use strict';\nif (window.ZPDF_UNSUPPORTED) return;\n${js}\n})();`;

// "</script" inside the code would end the script element.
if (/<\/script/i.test(wrapped)) throw new Error('The JavaScript contains "</script"; split the literal.');

const html = readFileSync(join(src, 'index.html'), 'utf8')
  .replace('/*CSS*/', () => css)
  .replace('/*JS*/', () => wrapped);

mkdirSync(join(root, 'dist'), { recursive: true });
writeFileSync(join(root, 'dist', 'designer.html'), html, 'utf8');
console.log(`dist/designer.html  ${(Buffer.byteLength(html) / 1024).toFixed(1)} KB  (${files.length} source files)`);
