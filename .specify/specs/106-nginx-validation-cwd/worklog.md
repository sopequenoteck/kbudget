# Worklog — DEMO-005

<!-- devflow:worklog:start -->

## Objectif

Ajouter dans l’application frontend un test automatisé de non-régression pour app/nginx.conf. Le test doit vérifier que les requêtes /api/, notamment /api/bank-logos/*.svg, restent prioritaires sur la regex générique des assets SVG grâce à location ^~ /api/, que le proxy_pass vers le conteneur API est conservé, et qu’une régression de cette configuration fait échouer le test. Ne pas modifier le comportement applicatif ni nécessiter un serveur de production.

## Évaluation

- Profil recommandé : `standard`
- Profil sélectionné : `standard`
- Signaux : `{"ambiguity": "medium", "contractChange": false, "dataOrSecurity": false, "risk": "low", "scope": "local"}`
- Raison : certaines precisions peuvent etre necessaires

## Progression

- Statut : `completed`
- Activité courante : `done`
- Activités terminées : `assess`, `prepare`, `implement`, `verify`, `done`

## Modifications

- Ajout d’un test Vitest statique de non-régression pour app/nginx.conf. Il vérifie la priorité de location ^~ /api/ face à la regex SVG générique, le routage de /api/bank-logos/demo.svg, le proxy_pass vers http://api:8080/api/, et confirme que la suppression de ^~ ou l’altération du proxy provoque un échec. Aucun comportement applicatif ni serveur de production n’est requis.
- `app/src/nginx.conf.spec.ts`

## Vérifications

- `targeted-check` : **passed**
- `diff-inspection` : **passed**
  - `npm test --prefix app` → code `0`
- `targeted-check` : **passed**
  - `npm run build --prefix app` → code `0`
  - `npm test -- src/nginx.conf.spec.ts` → code `0`
  - `npm test -- src/nginx.conf.spec.ts -t rejette les régressions` → code `0`
  - `npm test` → code `0`
  - `git diff --check` → code `0`
  - `git diff -- app/src/nginx.conf.spec.ts app/nginx.conf app/package.json app/vitest.config.ts app/tsconfig.spec.json` → code `0`

## Risques restants

- Le type-check global des tests reste en échec sur de nombreuses erreurs préexistantes dans les fixtures et guards sans rapport avec ce changement; le nouveau fichier n’ajoute plus d’erreur TypeScript.
- Les répertoires .specify/specs/105-nginx-routing-test/ et .specify/specs/106-nginx-validation-cwd/ étaient déjà non suivis et ont été préservés.

## Résumé

Workflow terminé avec toutes les preuves requises.

<!-- devflow:worklog:end -->






## Notes manuelles

_Ajoutez ici vos observations._
