# Captures de référence

Écrans clés de K·Budget web, dans les deux thèmes, comparés pixel à pixel à `baseline/` (KKS-587). Ils prouvent qu'un changement de styles ne bouge rien à l'écran, ou montrent exactement ce qui bouge.

| Fichier | Rôle |
|---|---|
| `screens.spec.ts` | connexion, dashboard, transactions, bottom sheet d'une transaction, confirmation de suppression (non validée), réglages ; thèmes `dark` et `light` |
| `playwright.config.ts` | mobile 390 × 844, `fr-FR`, `Europe/Paris`, diff nul exigé (`maxDiffPixels: 0`, `threshold: 0`) |
| `seed.sql` | base de dev au 25 octobre 2026 (`pg_dump` après les migrations et `db/dev/R__dev_seed.sql`, jetons de session exclus) |
| `baseline/` | 12 captures de référence |
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

## Limite

Une capture dépend du moteur de rendu et des polices installées. Les références ont été produites sous Linux, avec le Chromium de `@playwright/test` 1.63.0 et la police Inter installée sur la machine (K·Budget web ne l'embarque pas encore). Rejouées ailleurs, elles peuvent différer sans qu'aucun style ait changé : produire alors des références sur la même machine, avant et après le changement.
