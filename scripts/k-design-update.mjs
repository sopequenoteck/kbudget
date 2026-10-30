#!/usr/bin/env node
// Journal d'une mise a jour de k-design (KKS-595). Aucune dependance.
// Usage : node scripts/k-design-update.mjs <version de k-design>
//
// Lance par le workflow de k-design juste apres son scripts/sync.mjs, qui a copie les nouvelles
// sorties (app/src/styles/k/, flutter/lib/src/theme/k_tokens.dart) et ecrit la version dans
// k-design.json. La PR vise develop : pas de version ici, elle se monte a la release
// (docs/release.md). Le script ajoute une puce au bloc « ### Changed » de [Unreleased], dans
// CHANGELOG.md (anglais) et CHANGELOG.fr.md (francais), a parite. Il n'ecrit rien tant que les deux
// journaux n'ont pas ete verifies.

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const VERSION = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;
// Ordre de Keep a Changelog : un « ### Changed » absent se place avant la premiere section suivante.
const AFTER_CHANGED = ["Deprecated", "Removed", "Fixed", "Security"];

export const ENTRIES = {
  "CHANGELOG.md": (version) => `- Design tokens updated to k-design v${version}.`,
  "CHANGELOG.fr.md": (version) => `- Tokens de design mis à jour vers k-design v${version}.`,
};

/** Ajoute `line` a la fin du bloc « ### Changed » de [Unreleased], en creant ce qui manque. */
export function changelogWithEntry(changelog, line, name) {
  const firstRelease = changelog.search(/^## \[/m);
  if (firstRelease === -1) throw new Error(`${name} : aucune entree « ## [...] »`);
  let unreleased = changelog.search(/^## \[Unreleased\][ \t]*$/m);
  if (unreleased === -1) {
    changelog = `${changelog.slice(0, firstRelease)}## [Unreleased]\n\n${changelog.slice(firstRelease)}`;
    unreleased = firstRelease;
  }
  const bodyStart = changelog.indexOf("\n", unreleased) + 1;
  const next = changelog.slice(bodyStart).search(/^## \[/m);
  const bodyEnd = next === -1 ? changelog.length : bodyStart + next;
  let body = changelog.slice(bodyStart, bodyEnd);

  const changed = body.search(/^### Changed[ \t]*$/m);
  if (changed === -1) {
    const after = AFTER_CHANGED.map((s) => body.search(new RegExp(`^### ${s}[ \\t]*$`, "m"))).filter((i) => i !== -1);
    const at = after.length ? Math.min(...after) : body.length;
    const before = body.slice(0, at).replace(/\s*$/, "");
    const head = before ? `${before}\n\n` : "\n";
    body = `${head}### Changed\n\n${line}\n\n${body.slice(at)}`;
  } else {
    const sectionStart = body.indexOf("\n", changed) + 1;
    const following = body.slice(sectionStart).search(/^### /m);
    const sectionEnd = following === -1 ? body.length : sectionStart + following;
    const section = body.slice(sectionStart, sectionEnd).replace(/\s*$/, "");
    body = `${body.slice(0, sectionStart)}${section}\n${line}\n\n${body.slice(sectionEnd)}`;
  }
  body = body.replace(/\n{3,}$/, "\n\n");
  return changelog.slice(0, bodyStart) + body + changelog.slice(bodyEnd);
}

/** Calcule les deux journaux, puis les ecrit. */
export function updateRepository(root, version) {
  if (!VERSION.test(version)) throw new Error(`version de k-design invalide « ${version} » : format attendu X.Y.Z`);
  const writes = Object.entries(ENTRIES).map(([name, entry]) => {
    let text;
    try {
      text = readFileSync(join(root, name), "utf8");
    } catch {
      throw new Error(`${name} : fichier illisible ou absent`);
    }
    return [name, changelogWithEntry(text, entry(version), name)];
  });
  for (const [name, text] of writes) writeFileSync(join(root, name), text);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    if (process.argv.length !== 3) throw new Error("usage : node scripts/k-design-update.mjs <version de k-design>");
    updateRepository(ROOT, process.argv[2]);
    console.log(`✔ CHANGELOG.md et CHANGELOG.fr.md : k-design v${process.argv[2]}`);
  } catch (error) {
    console.error(`✖ ${error.message}`);
    process.exit(1);
  }
}
