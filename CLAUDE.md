# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

App de gestion de budget. Self-hosted, multi-user (groupe restreint, ~16 comptes actifs, pas d'inscription publique). Isolation stricte des données par user (principe #2 de la constitution). Le suivi vit sur **Linear** (`KKS-*`). GitHub Issues n'est pas le tableau du projet mais **la porte d'entree des contributeurs externes**, qui n'ont pas acces a Linear : trois modeles dans `.github/ISSUE_TEMPLATE/`, et ce qui merite un ticket en recoit un cote Linear.

## Commandes

### Backend (api/)

```bash
cd api && mvn clean compile       # Build
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev  # Lancer (profil dev)
cd api && mvn test                # Tests
cd api && mvn test -Dtest=NomDuTest  # Test unique
cd api && mvn verify              # Tests + rapport couverture jacoco (target/site/jacoco/)
cd api && mvn clean install       # Build complet avec tests
```

> Le profil `prod` est le défaut. En dev, activer `dev` explicitement. Toutes les commandes Maven depuis `api/`.

> **Maven doit tourner sous Java 21**, la version de la CI. `java -version` peut
> afficher 21 pendant que Maven utilise un autre JDK — c'est `JAVA_HOME` qui
> decide, verifier avec `mvn -version`. Un JDK plus recent fait echouer
> l'instrumentation JaCoCo sur une erreur opaque ; le `maven-enforcer-plugin`
> intercepte le cas et affiche la marche a suivre.

### Frontend (app/)

```bash
cd app && ng serve                # Dev server (http://localhost:4200)
cd app && ng build                # Build
cd app && npm test                # Tests unitaires (vitest)
cd app && npm run test:coverage   # Tests + rapport de couverture (lcov)
cd app && ng build --configuration production  # Build prod
cd app && ng lint                 # ESLint
```

> Toutes les commandes Angular CLI depuis `app/`.

### Flutter (flutter/)

```bash
cd flutter && flutter test             # Tests unitaires + widget
cd flutter && flutter test test/src/features/  # Tests par feature
cd flutter && dart run build_runner build --delete-conflicting-outputs  # Code generation (Freezed, JSON, Mockito)
cd flutter && flutter run              # Lancer sur device/simulateur
cd flutter && flutter analyze          # Analyse statique
```

> Toutes les commandes Flutter/Dart depuis `flutter/`.

## Constitution du projet

[`.specify/memory/constitution.md`](.specify/memory/constitution.md) fait autorite sur toute autre documentation : la lire avant toute proposition ou implementation. Interdit permanent : ne jamais retirer ni renommer un champ de reponse de l'API — six regles et procedure de rupture assumee dans [`docs/api-compatibility.md`](docs/api-compatibility.md).

## Frontiere Angular / Flutter

Classement complet, motifs et ecarts connus : [`docs/architecture.md`](docs/architecture.md#frontiere-angular--flutter) (KKS-333). **Verifier l'etat d'une surface avant tout travail Flutter.**

| Etat | Regle | Surfaces |
|------|-------|----------|
| **Suivi** | Toute evolution cote Angular est portee sur Flutter | Transactions (recurrences, virement), budgets, abonnements, dettes, comptes, categories, tableau de bord, notifications, profil « Mon compte », reglages, connexion, invitation, reinitialisation a la premiere connexion, ecran d'incompatibilite |
| **Gele** | Fonctionne et reste maintenu (traductions, tests, corrections), aucune evolution fonctionnelle | Administration, devises et taux de change |
| **Jamais** | Angular seul, ne pas porter | Import de releve, mapping CSV, profils et reglages d'import, rattrapage de l'historique, regles de categorisation |
| **Propre a Flutter** | Sans equivalent web | Configuration du serveur, verrouillage PIN/biometrie, notification systeme a la reception |

- Une feature nait cote Angular. Sur une surface **Suivi**, son ticket prevoit le portage Flutter ; sur une surface **Gele** ou **Jamais**, il ne le prevoit pas
- Nouvelle surface : *va-t-elle continuer a bouger ?* Si oui et qu'elle est complexe, Angular seul. CRUD stable sur une entite : les deux
- Une fonction que Flutter aurait en avance se porte sur Angular, qui reste la surface fonctionnelle complete
- Un bug sur une surface gelee se corrige : le gel porte sur les evolutions, pas sur le fonctionnement

## Conventions par module

`api/CLAUDE.md` (backend), `app/CLAUDE.md` (Angular), `flutter/CLAUDE.md` (Flutter) : charges quand on travaille dans le dossier. Les lire avant de planifier un changement qui le touche.

## Branches

`feature/<nom>`, `fix/<nom>`, `chore/<nom>`, `hotfix/<nom>`. Un parcours Devflow nomme la sienne `<num>-kks-<id>-<slug>`.

## Documentation

| Document | Contenu |
|----------|---------|
| [`.specify/memory/constitution.md`](.specify/memory/constitution.md) | **Constitution du projet** (v4.2.0) — principes fondateurs. Fait autorite sur toute autre documentation |
| [`docs/architecture.md`](docs/architecture.md) | Structure du code, securite, profils Spring, decisions techniques, modele de donnees (18 entites) |
| [`docs/vision.md`](docs/vision.md) | Vision produit, modules fonctionnels |
| [`docs/api-examples.md`](docs/api-examples.md) | Exemples requetes/reponses par endpoint |
| [`docs/api-errors.md`](docs/api-errors.md) | Contrat erreurs HTTP |
| [`docs/api-compatibility.md`](docs/api-compatibility.md) | **Politique de compatibilite d'API** (KKS-315) — les six regles d'ecriture et la procedure de rupture assumee. A consulter avant toute modification de DTO, de migration Flyway ou de parsing client |
| [`docs/i18n.md`](docs/i18n.md) | **Convention i18n et glossaire EN/FR** (KKS-328) — structure des cles `domaine.contexte.element`, listes fermees des domaines et contextes, passage Transloco → ARB, ICU, glossaire. A consulter avant toute cle ou traduction |
| [`docs/deployment.md`](docs/deployment.md) | Deploiement Docker/bare-metal |
| [`docs/release.md`](docs/release.md) | Procedure de release : quatre fichiers de version, changelogs, branches, tag pose par la CI |
| [`DESIGN.md`](DESIGN.md) | Reference design : principes, couleurs, patterns, tokens |
| [`DESIGN-REFONTE.md`](DESIGN-REFONTE.md) | Changelog design : 20 sessions de decisions et justifications |
| [`docs/direction.md`](docs/direction.md) | **Direction produit (2026-08-26)** : ouverture open source, positionnement, decisions et alternatives ecartees |
| [`docs/roadmap-v2.md`](docs/roadmap-v2.md) | *(archive)* Roadmap V2 : bilan de livraison, decisions historiques. Ne decrit plus la trajectoire |
| [`docs/dette-technique.md`](docs/dette-technique.md) | Registre des dettes techniques identifiees |
| [`docs/pwa-install.md`](docs/pwa-install.md) | Guide d'installation PWA (Android/iOS) |
| [`docs/manual-test-plan.md`](docs/manual-test-plan.md) | Plan de tests manuels (Angular + Flutter) |
| **Swagger UI** | `http://localhost:8080/api/swagger-ui.html` — profil `dev` uniquement. Desactivee par defaut ailleurs, reactivable via `SWAGGER_ENABLED=true` (KKS-311) |

## Release

Procedure complete : [`docs/release.md`](docs/release.md), a suivre a chaque release. **Ne jamais pousser le tag** : la CI le cree au merge de la PR `develop` -> `main`.

## Zones sensibles (mode auto)

Regles lues par Claude et par le classifier du mode auto. Elles etaient auparavant dans `~/.claude/settings.json`.

- **Profil prod par defaut** : le profil Spring `prod` est actif sans option. Traiter `cd api && mvn clean install` visant `main` comme adjacent a un deploiement de production.
- **Fichiers proteges** : `deploy/Caddyfile` et `deploy/nginx.conf` (proxy d'entree, frontiere de confiance `TRUSTED_PROXIES` et rate limiting), `app/src/environments/environment.prod.ts`, `.env`. Ne pas les modifier sans demande explicite.
- **Donnees utilisateurs** : donnees financieres personnelles, multi-utilisateurs. Ne jamais croiser les frontieres entre utilisateurs ni exposer les donnees d'un utilisateur a un autre.
- **Secrets CI** : `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `SONAR_TOKEN` sont des noms de secrets GitHub. Ne jamais en ecrire ni en rechercher les valeurs.
