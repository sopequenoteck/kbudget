// Tests de scripts/k-design-update.mjs (KKS-595). Usage : node --test scripts/k-design-update.test.mjs
// Le workflow de synchro de k-design les rejoue avant d'appeler le script.

import { strict as assert } from "node:assert";
import { spawnSync } from "node:child_process";
import { cpSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { after, describe, it } from "node:test";
import { fileURLToPath } from "node:url";

import { changelogWithEntry, updateRepository } from "./k-design-update.mjs";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const LINE = "- Design tokens updated to k-design v0.4.1.";
const folders = [];
after(() => folders.forEach((f) => rmSync(f, { recursive: true, force: true })));

const head = "# Changelog\n\nIntro.\n\n";
const release = "## [6.13.1] - 2026-10-24\n\n### Fixed\n\n- Old.\n";

describe("changelogWithEntry", () => {
  it("ajoute la puce a la fin du bloc Changed de [Unreleased]", () => {
    const changelog = `${head}## [Unreleased]\n\n### Added\n\n- A.\n\n### Changed\n\n- B.\n  suite.\n\n### Fixed\n\n- C.\n\n${release}`;
    assert.equal(
      changelogWithEntry(changelog, LINE, "f"),
      `${head}## [Unreleased]\n\n### Added\n\n- A.\n\n### Changed\n\n- B.\n  suite.\n${LINE}\n\n### Fixed\n\n- C.\n\n${release}`,
    );
  });

  it("cree le bloc Changed avant Fixed quand il manque", () => {
    const changelog = `${head}## [Unreleased]\n\n### Added\n\n- A.\n\n### Fixed\n\n- C.\n\n${release}`;
    assert.equal(
      changelogWithEntry(changelog, LINE, "f"),
      `${head}## [Unreleased]\n\n### Added\n\n- A.\n\n### Changed\n\n${LINE}\n\n### Fixed\n\n- C.\n\n${release}`,
    );
  });

  it("cree le bloc Changed en fin de [Unreleased] quand rien ne le suit", () => {
    const changelog = `${head}## [Unreleased]\n\n### Added\n\n- A.\n\n${release}`;
    assert.equal(
      changelogWithEntry(changelog, LINE, "f"),
      `${head}## [Unreleased]\n\n### Added\n\n- A.\n\n### Changed\n\n${LINE}\n\n${release}`,
    );
  });

  it("cree [Unreleased] quand il manque", () => {
    assert.equal(
      changelogWithEntry(`${head}${release}`, LINE, "f"),
      `${head}## [Unreleased]\n\n### Changed\n\n${LINE}\n\n${release}`,
    );
  });

  it("ajoute la puce quand Changed est le dernier bloc d'un journal sans version publiee", () => {
    const changelog = `${head}## [Unreleased]\n\n### Changed\n\n- B.\n`;
    assert.throws(() => changelogWithEntry("# Changelog\n", LINE, "f"), /f : aucune entree/);
    assert.equal(changelogWithEntry(changelog, LINE, "f"), `${head}## [Unreleased]\n\n### Changed\n\n- B.\n${LINE}\n\n`);
  });
});

describe("updateRepository sur une copie des vrais journaux", () => {
  const copy = () => {
    const root = mkdtempSync(join(tmpdir(), "kbudget-k-design-"));
    folders.push(root);
    for (const name of ["CHANGELOG.md", "CHANGELOG.fr.md"]) cpSync(join(ROOT, name), join(root, name));
    return root;
  };

  it("ajoute la puce anglaise et la puce francaise, une seule fois chacune", () => {
    const root = copy();
    updateRepository(root, "0.4.1");
    const en = readFileSync(join(root, "CHANGELOG.md"), "utf8");
    const fr = readFileSync(join(root, "CHANGELOG.fr.md"), "utf8");
    assert.equal(en.split("Design tokens updated to k-design v0.4.1.").length, 2);
    assert.equal(fr.split("Tokens de design mis à jour vers k-design v0.4.1.").length, 2);
    for (const text of [en, fr]) {
      const unreleased = text.slice(text.indexOf("## [Unreleased]"), text.search(/^## \[\d/m));
      assert.match(unreleased, /k-design v0\.4\.1\./);
    }
  });

  it("n'ecrit rien quand un journal est inexploitable", () => {
    const root = copy();
    writeFileSync(join(root, "CHANGELOG.fr.md"), "# Changelog\n");
    const before = readFileSync(join(root, "CHANGELOG.md"), "utf8");
    assert.throws(() => updateRepository(root, "0.4.1"), /CHANGELOG\.fr\.md : aucune entree/);
    assert.equal(readFileSync(join(root, "CHANGELOG.md"), "utf8"), before);
  });

  it("refuse une version invalide", () => {
    assert.throws(() => updateRepository(copy(), "v0.4.1"), /version de k-design invalide/);
  });
});

describe("ligne de commande", () => {
  it("signale un mauvais usage avec exit 1", () => {
    const run = spawnSync(process.execPath, [join(ROOT, "scripts", "k-design-update.mjs")], { encoding: "utf8" });
    assert.equal(run.status, 1);
    assert.match(run.stderr, /usage/);
  });
});
