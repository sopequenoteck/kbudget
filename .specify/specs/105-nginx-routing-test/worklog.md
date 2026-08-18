# Worklog — DEMO-004

<!-- devflow:worklog:start -->

## Objectif

Ajouter dans l’application frontend un test automatisé de non-régression pour app/nginx.conf. Le test doit vérifier que les requêtes /api/, notamment /api/bank-logos/*.svg, restent prioritaires sur la regex générique des assets SVG grâce à location ^~ /api/, que le proxy_pass vers le conteneur API est conservé, et qu’une régression de cette configuration fait échouer le test. Ne pas modifier le comportement applicatif ni nécessiter un serveur de production.

## Évaluation

- Profil recommandé : `standard`
- Profil sélectionné : `standard`
- Signaux : `{"ambiguity": "medium", "contractChange": false, "dataOrSecurity": false, "risk": "low", "scope": "local"}`
- Raison : certaines precisions peuvent etre necessaires

## Progression

- Statut : `active`
- Activité courante : `implement`
- Activités terminées : `assess`, `prepare`

## Modifications

- Implémentation non terminée.

## Vérifications

- Vérification non exécutée.

## Risques restants

- Aucun risque déclaré.

## Résumé

Implémentation en attente.

<!-- devflow:worklog:end -->


## Notes manuelles

_Ajoutez ici vos observations._
