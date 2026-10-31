// K Design v0.7.1 — copié par scripts/build.mjs depuis pwa/. Ne pas éditer.
// Contrôle du socle PWA d'une app K : version d'Angular, coquille index.html, manifeste, ngsw-config, nginx.
// Aucune dépendance. Usage, depuis la racine de l'app : node <chemin>/k-pwa-check.mjs
//
// Lit la section « pwa » du k-design.json de l'app (chemins relatifs à la racine de l'app) :
//
//   "pwa": { "packageJson": "…", "index": "…", "manifest": "…", "ngswConfig": "…", "nginx": ["…", …] }
//
// et ecosystem.json, placé à côté de ce script. Tous les écarts sont listés (fichier + règle) ; code 1 s'il y en a.
// Une configuration inutilisable (section absente, fichier introuvable, liste nginx vide, aucun paquet Angular) sort aussi en 1.

import { readFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const APP = process.cwd();
const FRAGMENT = 'k-pwa-sw.conf';
const LOCATIONS = ['/index.html', '/ngsw-worker.js', '/ngsw.json', '/manifest.webmanifest', '/safety-worker.js'];
const fail = (msg) => { console.error(`✖ ${msg}`); process.exit(1); };
const gaps = [];
const gap = (file, msg) => gaps.push(`${file} : ${msg}`);

const read = (rel, what) => {
  const p = resolve(APP, rel);
  if (!existsSync(p)) fail(`fichier introuvable (${what}) : ${rel}`);
  return readFileSync(p, 'utf8');
};
const readJson = (rel, what) => {
  let v;
  try { v = JSON.parse(read(rel, what)); } catch (e) { if (e instanceof SyntaxError) fail(`${rel} : JSON illisible (${e.message})`); throw e; }
  if (v === null || typeof v !== 'object' || Array.isArray(v)) fail(`${rel} : objet JSON attendu`);
  return v;
};

// ---------- configuration ----------
const here = dirname(fileURLToPath(import.meta.url));
const ecoPath = join(here, 'ecosystem.json');
if (!existsSync(ecoPath)) fail(`ecosystem.json introuvable à côté du script : ${ecoPath}`);
let MINOR;
try { MINOR = JSON.parse(readFileSync(ecoPath, 'utf8')).angular; } catch (e) { fail(`ecosystem.json illisible : ${e.message}`); }
if (!/^\d+\.\d+$/.test(MINOR ?? '')) fail(`ecosystem.json : « angular » doit être une version mineure (ex. 22.2), reçu ${JSON.stringify(MINOR)}`);

if (!existsSync(join(APP, 'k-design.json'))) fail('k-design.json absent à la racine de l\'app (lancer le script depuis cette racine)');
const cfg = readJson('k-design.json', 'manifeste k-design').pwa;
if (!cfg || typeof cfg !== 'object') fail('k-design.json : section « pwa » absente');
for (const k of ['packageJson', 'index', 'manifest', 'ngswConfig']) if (typeof cfg[k] !== 'string' || !cfg[k]) fail(`k-design.json : pwa.${k} manquant`);
if (!Array.isArray(cfg.nginx) || !cfg.nginx.length || cfg.nginx.some((f) => typeof f !== 'string' || !f)) fail('k-design.json : pwa.nginx doit être une liste non vide de fichiers');

// ---------- Angular ----------
const pkg = readJson(cfg.packageJson, 'pwa.packageJson');
const deps = { ...pkg.dependencies, ...pkg.devDependencies };
const angular = Object.entries(deps).filter(([n]) => /^@angular(-devkit)?\//.test(n));
if (!angular.length) fail(`${cfg.packageJson} : aucun paquet @angular/* ni @angular-devkit/*`);
const range = new RegExp(`^~${MINOR.replace('.', '\\.')}\\.\\d+`);
for (const [n, v] of angular) if (!range.test(v)) gap(cfg.packageJson, `${n} ${v} : plage attendue ~${MINOR}.x`);

// ---------- coquille index.html ----------
const html = read(cfg.index, 'pwa.index');
const tags = (name) => [...html.matchAll(new RegExp(`<${name}\\b[^>]*>`, 'gi'))].map((m) => Object.fromEntries([...m[0].matchAll(/([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')/g)].map((a) => [a[1].toLowerCase(), a[2] ?? a[3]])));
const metas = tags('meta');
const links = tags('link');
const viewport = metas.find((m) => m.name?.toLowerCase() === 'viewport');
if (!viewport) gap(cfg.index, 'balise meta viewport absente');
else if (!/viewport-fit\s*=\s*cover/.test(viewport.content ?? '')) gap(cfg.index, 'meta viewport sans viewport-fit=cover');
if (!metas.some((m) => m.name?.toLowerCase() === 'theme-color')) gap(cfg.index, 'meta theme-color absente');
if (!links.some((l) => l.rel?.toLowerCase().split(/\s+/).includes('manifest'))) gap(cfg.index, 'link rel="manifest" absent');
if (!links.some((l) => l.rel?.toLowerCase().split(/\s+/).includes('apple-touch-icon'))) gap(cfg.index, 'link rel="apple-touch-icon" absent');

// ---------- manifeste ----------
const man = readJson(cfg.manifest, 'pwa.manifest');
for (const k of ['id', 'start_url', 'scope']) if (typeof man[k] !== 'string' || !man[k]) gap(cfg.manifest, `« ${k} » absent`);
if (man.display !== 'standalone') gap(cfg.manifest, `« display » doit valoir standalone (reçu ${JSON.stringify(man.display)})`);
const icons = Array.isArray(man.icons) ? man.icons : [];
for (const s of ['192x192', '512x512']) if (!icons.some((i) => String(i.sizes ?? '').split(/\s+/).includes(s))) gap(cfg.manifest, `aucune icône ${s}`);
if (!icons.some((i) => String(i.purpose ?? '').split(/\s+/).includes('maskable'))) gap(cfg.manifest, 'aucune icône maskable');

// ---------- ngsw-config ----------
const ngsw = readJson(cfg.ngswConfig, 'pwa.ngswConfig');
for (const [i, g] of (ngsw.assetGroups ?? []).entries()) {
  const files = g.resources?.files ?? [];
  if (files.includes('/*.js') && !files.includes('!/safety-worker.js')) gap(cfg.ngswConfig, `groupe « ${g.name ?? i} » inclut /*.js sans exclure !/safety-worker.js`);
}

// ---------- nginx ----------
for (const f of cfg.nginx) {
  const conf = read(f, 'pwa.nginx').replace(/#.*$/gm, '');
  if (!new RegExp(`^\\s*include\\s+[^;]*${FRAGMENT.replace('.', '\\.')}\\s*;`, 'm').test(conf)) gap(f, `aucun include de ${FRAGMENT}`);
  for (const loc of LOCATIONS) if (new RegExp(`location\\s*=\\s*${loc.replace(/\./g, '\\.')}\\s*\\{`).test(conf)) gap(f, `redéclare « location = ${loc} » (déjà dans ${FRAGMENT})`);
}

// ---------- résultat ----------
if (gaps.length) {
  for (const g of gaps) console.error(`✖ ${g}`);
  console.error(`${gaps.length} écart(s) au socle PWA (Angular ${MINOR})`);
  process.exit(1);
}
console.log(`✔ socle PWA conforme (Angular ${MINOR}, ${cfg.nginx.length} fichier(s) nginx)`);
