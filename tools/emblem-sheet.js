// tools/emblem-sheet.js
// 声骸徽记对照表生成器：把 index.html 里的 16 枚内联 SVG 徽记渲染成一页网格，
// 便于并排检查造型辨识度与元素配色（改完徽记后跑一次，用浏览器打开即可）。
//
// 用法：
//   node tools/emblem-sheet.js
//   # 产物：dist-artifacts/emblem-sheet.html（已被 .gitignore 忽略）
//
// 注意：徽记是内联 SVG 而非图片资源，因此无法用普通图片查看器检查；
//       整页截图里的符印只有约 70px，细节看不清，故用本工具放大并排比。

const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const code = html.match(/<script>([\s\S]*?)<\/script>/)[1];

const elBlock = code.match(/var ELEMENTS = \{[\s\S]*?\n\};/)[0];
const ecBlock = code.match(/var ECHOES = \[[\s\S]*?\n\];/)[0];
const embBlock = code.match(/var EMBLEMS = \{[\s\S]*?\n\};/)[0];

const sandbox = {};
new Function('g', elBlock + '\n' + ecBlock + '\n' + embBlock +
  '\ng.ELEMENTS=ELEMENTS;g.ECHOES=ECHOES;g.EMBLEMS=EMBLEMS;')(sandbox);
const { ELEMENTS, ECHOES, EMBLEMS } = sandbox;

const missing = ECHOES.filter(e => !EMBLEMS[e.id]).map(e => e.id);
if (missing.length) {
  console.error('以下声骸缺少徽记，会在卡片上留空：' + missing.join(', '));
  process.exitCode = 1;
}

const tiles = ECHOES.map(e => {
  const el = ELEMENTS[e.element];
  const svg = '<svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2" ' +
    'stroke-linecap="round" stroke-linejoin="round">' + (EMBLEMS[e.id] || '') + '</svg>';
  return '<figure style="--el:var(' + el.v + ')"><div class="sig">' + svg + '</div>' +
    '<figcaption>' + e.id + ' · ' + e.name + '<em>' + el.label + ' · COST ' + e.cost + '</em></figcaption></figure>';
}).join('');

const css = [
  ':root{--elem-diffraction:#dcc178;--elem-aero:#5ad8cc;--elem-havoc:#b47ae0;',
  '--elem-glacio:#74a8e8;--elem-fusion:#e0767e;--elem-electro:#9b8ae0}',
  'body{margin:0;padding:16px;background:#0b1220;color:#b8c7d6;',
  'font:12px/1.4 "Microsoft YaHei",system-ui,sans-serif}',
  'main{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}',
  'figure{margin:0;display:grid;justify-items:center;gap:8px;padding:10px;',
  'border:1px solid rgba(120,180,200,.2);border-radius:16px;background:#111c2b}',
  '.sig{display:grid;place-items:center;width:132px;height:132px;border-radius:999px;',
  'background:radial-gradient(78% 92% at 50% 106%,var(--el),transparent 68%),#080d14;',
  'border:1px solid rgba(120,180,200,.18)}',
  '.sig svg{width:62%;height:62%;color:var(--el);filter:drop-shadow(0 0 10px var(--el))}',
  'figcaption{text-align:center;color:#eaf2f8;font-size:13px}',
  'figcaption em{display:block;font-style:normal;color:#7d92a6;font-size:11px;margin-top:2px}'
].join('');

const page = '<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">' +
  '<title>声骸徽记对照表</title><style>' + css + '</style></head><body><main>' +
  tiles + '</main></body></html>';

const outDir = path.join(root, 'dist-artifacts');
fs.mkdirSync(outDir, { recursive: true });
const outFile = path.join(outDir, 'emblem-sheet.html');
fs.writeFileSync(outFile, page, 'utf8');
console.log('已生成 ' + ECHOES.length + ' 枚徽记对照表：' + outFile);
