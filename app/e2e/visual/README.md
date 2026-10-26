# Captures de référence

Écrans clés de K·Budget web, dans les deux thèmes, comparés pixel à pixel à `baseline/` (KKS-587). Ils prouvent qu'un changement de styles ne bouge rien à l'écran, ou montrent exactement ce qui bouge.

| Fichier | Rôle |
|---|---|
| `screens.spec.ts` | connexion, dashboard, transactions, bottom sheet d'une transaction, confirmation de suppression (non validée), réglages ; thèmes `dark` et `light` |
| `playwright.config.ts` | mobile 390 × 844, `fr-FR`, `Europe/Paris`, diff nul exigé (`maxDiffPixels: 0`, `threshold: 0`) |
| `seed.sql` | base de dev au 25 octobre 2026 (`pg_dump` après les migrations et `db/dev/R__dev_seed.sql`, jetons de session exclus) |
| `baseline/` | 12 captures de référence, produites par la CI (voir « En CI ») |
| `package.json` | paquet séparé de `app/` avec `@playwright/test` : déclaré dans `app/package.json`, Playwright activerait chez Sonar une règle sur tous les tests unitaires |

Les données de `R__dev_seed.sql` sont datées par rapport au jour de création de la base. `seed.sql` fige ce jour, et le test fige l'horloge du navigateur au même jour (`NOW` dans `screens.spec.ts`) : les captures restent comparables quel que soit le jour où on les rejoue.

## Rejouer

```bash
# 1. Base : PostgreSQL 15+, base vide restaurée depuis le dump
createdb budget_db
psql -d budget_db -f app/e2e/visual/seed.sql

# 2. API en profil dev contre cette base. SPRING_FLYWAY_LOCATIONS est requis :
#    le dump porte l'historique des migrations de db/dev, que Flyway doit retrouver.
cd api && mvn -q -DskipTests package
SPRING_PROFILES_ACTIVE=dev \
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/budget_db \
SPRING_DATASOURCE_USERNAME=<utilisateur> SPRING_DATASOURCE_PASSWORD=<mot de passe> \
APP_JWT_SECRET="$(openssl rand -base64 48)" \
SPRING_FLYWAY_LOCATIONS=classpath:db/migration,classpath:db/dev \
java -jar target/api-*.jar

# 3. Front
cd app && npm ci && npm start

# 4. Captures
cd app/e2e/visual && npm ci
npm test              # compare à baseline/
npm run update        # remplace baseline/
```

Compte : `dev@local.test` / `dev123` (jeu de données de dev). `KB_BASE_URL` change l'adresse du front (défaut `http://localhost:4200`).

## En CI

Le workflow `.github/workflows/visual.yml` rejoue les captures à chaque PR qui touche `app/` ou `api/src/main/`, avec la même pile (PostgreSQL restauré depuis `seed.sql`, API en profil dev, `ng serve`), dans l'image officielle `mcr.microsoft.com/playwright:v1.63.0-noble`. En cas d'écart, le job *Captures APP* échoue et l'artefact `captures-ecart` contient les captures obtenues et les diffs.

**Les références sont produites dans cette image, par la CI**, pour un rendu identique d'une exécution à l'autre (même Chromium, mêmes polices, y compris les emoji des catégories). Pour les régénérer après un changement visuel validé : onglet Actions, workflow *Captures - écrans de référence*, « Run workflow » sur la branche de la PR. Le workflow commite les nouvelles références sur cette branche (commit dédié de `github-actions[bot]`), ce qui relance toute la CI de la PR.

Prérequis : le secret de dépôt `VISUAL_PUSH_TOKEN`, un jeton GitHub à grain fin limité au dépôt, permission *Contents : read and write*. Un commit poussé avec le jeton par défaut ne relancerait aucun workflow.

## Rejouer localement les références de la CI

Rejouées hors de l'image (poste, autre conteneur), les captures diffèrent de quelques pixels sans qu'aucun style ait changé : polices emoji, version de Chromium. Pour comparer à l'identique, lancer les captures dans la même image :

```bash
docker run --rm --network host -v "$PWD":/work -w /work/app/e2e/visual \
  mcr.microsoft.com/playwright:v1.63.0-noble sh -c "npm ci && npx playwright test"
```

Sans Docker, produire ses propres références avant et après un changement, sur la même machine, et les comparer (`npm run update` puis `npm test`) sans les commiter.
