# Processus de release

La version vit dans **quatre** fichiers, tous a incrementer ensemble :

| Fichier | Format |
|---------|--------|
| `VERSION` | `6.1.0` |
| `api/pom.xml` | `<version>` du projet, pas celle du parent Spring Boot |
| `app/package.json` | champ `version`. Le changer avec `npm version X.Y.Z --no-git-tag-version` depuis `app/` : la commande met aussi a jour les deux champs de version de `app/package-lock.json`, controles avec les autres |
| `flutter/pubspec.yaml` | `6.1.0+2` — le `+N` suit le rythme des depots sur les stores, pas celui des releases |

Le workflow `version-check` compare les quatre, plus le lock, sur toute PR vers
`main` et nomme le fichier fautif. Avant KKS-314, `flutter/pubspec.yaml` etait fige a `1.0.0+1`
et hors du controle : l'incoherence n'apparaissait qu'apres publication, dans le
champ `serverVersion` de `/api/meta`.

`docker-compose.yml` fixe aussi les deux tags d'image (`k-budget-api:X.Y.Z`,
`k-budget-app:X.Y.Z`) : a incrementer dans le meme commit de release.
`version-check` ne les controle pas.

Le reste du processus :

1. Mettre a jour **`CHANGELOG.md` (anglais) et `CHANGELOG.fr.md` (francais)**, a
   parite — bloc `Unreleased` promu, liens de comparaison. `CHANGELOG.md` est
   en anglais depuis la 6.10.0 ; `CHANGELOG.fr.md` garde tout l'historique
   francais
2. Commit sur `develop`, puis PR `develop` -> `main` (le push direct sur `main`
   est bloque)
4. **Ne jamais pousser le tag** : la CI le cree au merge, apres le gate de tests
   et la publication des images. Un tag `vX.Y.Z` implique donc qu'une image
   `:X.Y.Z` existe
5. Apres le tag, la CI cree la GitHub Release `vX.Y.Z` (job `github-release`)
   avec pour notes le bloc de la version du `CHANGELOG.md` anglais
   (`.github/scripts/release-notes.sh`), sans fichier joint. `version-check`
   refuse une PR vers `main` sans bloc de version dans les deux changelogs

## Branches

- Release : branche `chore/release-X.Y.Z` -> PR vers `develop`, puis PR `develop` -> `main`
- Correctif urgent : branche `fix/` depuis `main` -> PR vers `main`, puis PR de synchro `main` -> `develop`
