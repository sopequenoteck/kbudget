#!/usr/bin/env node
// Selecteurs en double dans la feuille globale (KKS-590). Usage : node scripts/check-global-duplicates.mjs
//
// Stylelint ne compare les selecteurs qu'a l'interieur d'un fichier ; ici, app/src/styles.scss est
// compile avec Sass puis la regle no-duplicate-selectors s'applique a la feuille obtenue : un meme
// selecteur defini dans deux partials (comme .btn-outline dans _buttons et _list-patterns) echoue.
// Les styles des composants n'y figurent pas : encapsules, ils peuvent surcharger un selecteur global.
// Dependances : sass et stylelint, resolus depuis app/.

import { createRequire } from "node:module";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const require = createRequire(join(ROOT, "app", "package.json"));
const sass = require("sass");
const stylelint = require("stylelint");

const entry = join(ROOT, "app", "src", "styles.scss");
const { css } = sass.compile(entry, { style: "expanded" });
const { results } = await stylelint.lint({
  code: css,
  config: { rules: { "no-duplicate-selectors": true } },
});

const warnings = results.flatMap((r) => r.warnings);
if (warnings.length) {
  for (const w of warnings)
    console.error(`✖ ${w.text.replace(/ \(no-duplicate-selectors\)$/, "")}`);
  console.error(
    `\n${warnings.length} selecteur(s) defini(s) plusieurs fois dans la feuille globale compilee (lignes de la sortie Sass). Une seule definition par selecteur, dans le partial qui le porte.`,
  );
  process.exit(1);
}
console.log("✔ feuille globale : aucun selecteur en double");
