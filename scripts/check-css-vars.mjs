#!/usr/bin/env node
// Variables CSS inconnues (KKS-590). Aucune dependance. Usage : node scripts/check-css-vars.mjs
//
// Echoue si app/src emploie une variable que personne ne declare :
//   - var(--k-…) ou '--k-…' absent de app/src/styles/k/k-tokens.css (copie de k-design, D14) ;
//   - var(--…) sans prefixe k- et sans declaration `--…:` dans app/src (styles/_app-tokens.scss,
//     ou variable locale d'un composant).
// Echoue aussi si app/src redeclare un `--k-…` : ces valeurs ne vivent que dans k-design.

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const SRC = join(ROOT, 'app', 'src');
const K_DIR = join(SRC, 'styles', 'k');
const K_TOKENS = join(K_DIR, 'k-tokens.css');

const walk = (dir) =>
  readdirSync(dir).flatMap((name) => {
    const p = join(dir, name);
    if (p === K_DIR) return [];
    if (statSync(p).isDirectory()) return walk(p);
    return /\.(scss|css|ts|html)$/.test(name) && !name.endsWith('.spec.ts') ? [p] : [];
  });

const DECL = /(?<![\w-])(--[a-z0-9-]+)\s*:/g;
const USE = /var\(\s*(--[a-z0-9-]+)/g;
const K_LITERAL = /['"`](--k-[a-z0-9-]+)['"`]/g;

const kTokens = new Set([...readFileSync(K_TOKENS, 'utf8').matchAll(DECL)].map((m) => m[1]));
const files = walk(SRC).map((p) => ({ p, s: readFileSync(p, 'utf8') }));

const local = new Set();
const errors = [];
const line = (s, i) => s.slice(0, i).split('\n').length;

for (const { p, s } of files) {
  for (const m of s.matchAll(DECL)) {
    if (m[1].startsWith('--k-')) errors.push(`${relative(ROOT, p)}:${line(s, m.index)}  ${m[1]} redeclare : les --k-* ne vivent que dans k-design`);
    else local.add(m[1]);
  }
}

for (const { p, s } of files) {
  for (const re of [USE, K_LITERAL]) {
    for (const m of s.matchAll(re)) {
      const name = m[1];
      const known = name.startsWith('--k-') ? kTokens.has(name) : local.has(name);
      if (!known) errors.push(`${relative(ROOT, p)}:${line(s, m.index)}  ${name} inconnue`);
    }
  }
}

if (errors.length) {
  console.error(errors.map((e) => `✖ ${e}`).join('\n'));
  console.error(`\n${errors.length} variable(s) inconnue(s) ou redeclaree(s). Tokens k-design : app/src/styles/k/k-tokens.css ; tokens locaux : app/src/styles/_app-tokens.scss.`);
  process.exit(1);
}
console.log(`✔ ${files.length} fichiers, ${kTokens.size} tokens k-design, ${local.size} variables locales : aucune variable inconnue`);
