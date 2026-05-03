# Clarify Log — KKS-235 : Page Mon compte (profil, sécurité, données, suppression) + fix bouton déconnexion

> Date : 2026-04-30
> Issue : KKS-235
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md US-2 §scénario 2 + NFR-002 + NFR-006 | Spécifications avatar : limite de taille, formats acceptés, dimension cible du redimensionnement | 11 Sécurité | H | H | CRITIQUE | JPG + PNG uniquement, max 2 MB upload, redim serveur 256x256 (sortie JPEG ~85% qualité), validation MIME via magic numbers | Auto |
| CL-002 | spec.md US-5 §scénario 1 + Edge Case "Admin se supprime lui-même" | Pattern de confirmation pour la suppression de compte : MDP seul ou MDP + saisie email (pattern GitHub) ? | 3 UX/Interaction | H | M | HAUT | MDP seul + checkbox "Je comprends que cette action est définitive". Bottom-sheet sur mobile. Pattern GitHub jugé sur-dimensionné pour 16 users self-hosted | Auto |
| CL-003 | spec.md US-4 §scénario 1 | Export JSON : structure du payload (groupé/flat) et stratégie de versionning du schéma | 1 Scope fonctionnel | M | H | HAUT | Structure groupée par entité avec metadata top-level (`schemaVersion`, `exportedAt`, `user`, `accounts`, etc.). Versionning via clé `schemaVersion` SemVer (initial "1.0.0") | Auto |
| CL-004 | spec.md Edge Cases "Utilisateur change son MDP puis ferme l'app" | Stratégie de révocation des sessions au changement de MDP : invalidation totale, attente expiration, ou hybride ? | 11 Sécurité | H | M | HAUT | Révocation immédiate de tous les RefreshToken du user + émission nouveau JWT pour le device courant + JWT autres devices expire naturellement (TTL ≤ 15 min). Pas de blocklist | Auto |
| CL-005 | spec.md FR-017 (CSV Type) | Format de la colonne `Type` dans l'export CSV : valeur brute de l'enum `TransactionType` ou traduction française ? Encodage du fichier ? | 8 Terminologie | B | M | BAS | Traduction française : "Revenu" pour `RECETTE`, "Dépense" pour `DEPENSE`, "Ajustement" pour `AJUSTEMENT`. Encodage UTF-8 avec BOM pour compatibilité Excel | Auto |

---

## Résolutions détaillées

### CL-001 — Spécifications avatar (taille, formats, redimensionnement)

- **Catégorie** : 11 Sécurité (volet validation MIME) + 4 Non-fonctionnel (volet performance)
- **Score** : CRITIQUE (Impact H × Incertitude H)
- **Contexte** : La spec initiale posait 3 sous-questions imbriquées sur l'upload avatar (taille / formats / redim) sans trancher. Impact direct sur la sécurité (validation MIME), la performance (poids transmis) et l'UX (qualité rendu).
- **Analyse** :
  - **Formats** : JPG et PNG couvrent 100% des cas d'usage avatar. WebP serait une optimisation prématurée (constitution principe III YAGNI) et complique le côté serveur (tous les browsers ne supportent pas l'export WebP nativement, librairies de redim hétérogènes).
  - **Limite de taille** : 2 MB couvre les photos prises sur smartphone moderne (la plupart sont 1-3 MB en JPG natif). 5 MB serait excessif sachant que l'image cible finale fait < 50 KB après redim. Coût bande passante minimisé pour 16 users self-hosted.
  - **Dimension cible** : 256x256 = compromis entre qualité (suffisant pour mobile retina ET desktop) et poids (~30-50 KB en JPEG 85%). Comparables marché : Slack 192px, Discord 128px, GitHub 460px, Linear 256px.
  - **Validation MIME** : extension seule = trivialement contournable (renommer `.exe` en `.jpg`). Magic numbers obligatoires côté serveur pour rejeter les fichiers maquillés.
- **Décision** :
  - Formats acceptés : `image/jpeg`, `image/png` uniquement.
  - Limite upload : 2 MB.
  - Redim serveur : 256x256 pixels, sortie JPEG qualité ~85%.
  - Validation MIME : magic numbers (pas extension).
- **Impact sur spec.md** :
  - US-2 scénario 2 : marqueur `[NEEDS CLARIFICATION]` retiré, formulation précisée.
  - NFR-002 : précise les formats `image/jpeg` + `image/png`, magic numbers, taille 2 MB.
  - NFR-006 : précise dimension 256x256 + sortie JPEG 85%.

---

### CL-002 — Pattern de confirmation suppression de compte

- **Catégorie** : 3 UX/Interaction
- **Score** : HAUT (Impact H × Incertitude M)
- **Contexte** : Question issue du sparring. Deux patterns courants : (a) MDP seul, (b) MDP + saisie email exact (pattern GitHub). Le choix impacte la friction utilisateur et la prévention de clic accidentel.
- **Analyse** :
  - **Contexte projet** : self-hosted, ~16 users avertis, action rare (probablement < 1 fois par user dans toute la durée de vie de l'instance).
  - **Soft-delete** : la suppression est techniquement réversible côté admin (le row reste en DB). La friction n'a pas besoin d'être maximale — un admin peut restaurer un compte soft-deleted en cas d'accident.
  - **Pattern GitHub** : justifié pour des instances publiques avec millions d'utilisateurs novices. Sur-dimensionné ici (constitution principe III YAGNI).
  - **MDP seul** : suffit pour empêcher un clic accidentel (l'utilisateur doit retaper son mot de passe). Une checkbox de confirmation explicite ajoute un cran de friction sans alourdir.
- **Décision** :
  - Modale de confirmation avec 2 éléments : (1) saisie du mot de passe actuel, (2) checkbox cochée explicitement "Je comprends que cette action est définitive".
  - Bouton "Supprimer mon compte" désactivé tant que checkbox non cochée ET MDP non saisi.
  - Pattern bottom-sheet sur Flutter (mobile-first).
- **Impact sur spec.md** :
  - US-5 scénario 1 : marqueur `[NEEDS CLARIFICATION]` retiré, formulation précisée.

---

### CL-003 — Structure et versionning de l'export JSON

- **Catégorie** : 1 Scope fonctionnel
- **Score** : HAUT (Impact M × Incertitude H)
- **Contexte** : L'export JSON doit contenir toutes les entités du user. Deux structures possibles : (a) groupée par entité (`{accounts: [...], transactions: [...]}`), (b) flat (`[{type: "account", ...}, {type: "transaction", ...}]`). Stratégie de versionning à fixer pour permettre des évolutions futures du schéma sans casser les outils tiers.
- **Analyse** :
  - **Structure groupée** : meilleure lisibilité humaine (un utilisateur peut ouvrir le JSON et naviguer par section). Plus naturelle pour des langages de requête (jq par exemple). Standards marché : Notion export, Linear export, Toggl export.
  - **Structure flat** : plus facile à parser en streaming pour très gros datasets, mais surdimensionné pour 16 users avec quelques milliers de transactions max. Pas de gain mesurable.
  - **Versionning** : la clé `schemaVersion` au top-level du JSON est le pattern standard (npm `package.json`, OpenAPI spec, etc.). Permet aux outils tiers de détecter le format et d'adapter le parsing. Préférable à un en-tête HTTP qui se perd lors du téléchargement de fichier.
  - **SemVer** : MAJOR = breaking change structurel, MINOR = ajout d'entité, PATCH = correction non-structurelle. Pattern compris universellement.
- **Décision** :
  - Structure : groupée par entité avec metadata top-level.
  - Champs top-level : `schemaVersion` (string SemVer), `exportedAt` (ISO-8601), puis chaque entité comme clé (`user`, `preferences`, `accounts`, `categories`, `transactions`, `budgets`, `budgetSnapshots`, `subscriptions`, `debts`, `categoryRules`, `importProfiles`, `importHistory`).
  - Version initiale : `"1.0.0"`.
- **Impact sur spec.md** :
  - US-4 scénario 1 : marqueur `[NEEDS CLARIFICATION]` retiré, formulation précisée.
  - FR-017a ajouté : structure JSON détaillée avec exemple inline.

---

### CL-004 — Stratégie de révocation des sessions au changement de mot de passe

- **Catégorie** : 11 Sécurité
- **Score** : HAUT (Impact H × Incertitude M)
- **Contexte** : Edge case "Utilisateur change son MDP puis ferme l'app sans recharger" laissait la question ouverte. Trois stratégies : (a) blocklist JWT en mémoire, (b) rotation du secret JWT, (c) révocation des refresh tokens uniquement.
- **Analyse** :
  - **Architecture actuelle** : JWT stateless, refresh tokens persistés en DB (table `RefreshToken` avec `ON DELETE CASCADE` sur user). Précédent KKS-233 a tranché pour pattern (c) sur le first-login-reset (claim JWT + double-check DB).
  - **Option (a) blocklist en mémoire** : coûteux (état serveur partagé, perd le bénéfice stateless), surdimensionné pour 16 users.
  - **Option (b) rotation du secret JWT** : déconnecterait TOUS les utilisateurs, pas seulement celui qui a changé son MDP. Inacceptable.
  - **Option (c) révocation refresh tokens** : cohérent avec stateless JWT. Le JWT actuel reste valide jusqu'à expiration courte (15 min max), mais impossible de renouveler la session sans le refresh token révoqué. Acceptable car fenêtre courte.
  - **Continuité UX device courant** : il faut que l'utilisateur qui change son MDP ne soit pas immédiatement déconnecté de l'application qu'il utilise. L'endpoint doit donc émettre un nouveau couple JWT + refresh token dans la réponse pour le device courant.
- **Décision** :
  - Au changement de MDP : `RefreshToken` du user purgés (cascade DB).
  - Réponse de `POST /users/me/password` : nouveau JWT + nouveau refresh token pour le device courant.
  - JWT existants sur les autres devices : restent valides jusqu'à expiration naturelle (≤ 15 min). Pas de blocklist.
  - Documentation claire dans la spec : trade-off explicite (fenêtre de 15 min de session valide sur autres devices acceptée).
- **Impact sur spec.md** :
  - Edge case "Utilisateur change son MDP" : résolution documentée.
  - FR-023, FR-024, FR-025 ajoutés (révocation refresh tokens, nouveau JWT device courant, comportement autres devices).

---

### CL-005 — Format de la colonne `Type` dans l'export CSV

- **Catégorie** : 8 Terminologie
- **Score** : BAS (Impact B × Incertitude M)
- **Contexte** : FR-017 listait les entêtes CSV mais ne précisait pas si `type` exposait la valeur brute de l'enum (REVENUE / EXPENSE / TRANSFER) ou une version traduite. Question d'encodage du fichier également ouverte (UTF-8 / UTF-8 BOM / Latin-1 ?).
- **Analyse** :
  - **Cible utilisateur** : francophone (l'app est en français). Exposer `REVENUE` au lieu de `Revenu` casse l'expérience pour un user qui ouvrirait le fichier dans Excel/LibreOffice/Google Sheets.
  - **Encodage Excel** : UTF-8 sans BOM est mal interprété par Excel sur Windows (caractères accentués cassés). UTF-8 avec BOM est l'encodage canonique pour les CSV destinés à Excel. LibreOffice et Google Sheets gèrent les deux.
- **Décision** :
  - Entêtes CSV en français : `Date`, `Libellé`, `Montant`, `Devise`, `Compte`, `Catégorie`, `Type`.
  - Colonne `Type` : valeurs traduites — `Revenu` pour `RECETTE`, `Dépense` pour `DEPENSE`, `Ajustement` pour `AJUSTEMENT`. **Note** : l'enum `TransactionType` du domaine ne contient pas de valeur `TRANSFERT` (clarification post-implémentation, l'audit research-impl a relevé cette divergence).
  - Encodage : UTF-8 avec BOM (`﻿` en début de fichier).
- **Impact sur spec.md** :
  - FR-017 : précise traduction française des valeurs Type + encodage UTF-8 BOM.

---

## Points différés

> Aucun point différé pour cette session. Les 5 points identifiés ont tous été résolus.

| # | Point identifié | Catégorie | Score | Raison du report |
|---|-----------------|-----------|-------|------------------|
| (vide) | — | — | — | — |

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 5 |
| Catégories couvertes | 4/11 (1 Scope, 3 UX, 8 Terminologie, 11 Sécurité) |
| Résolus automatiquement | 5/5 |
| Résolus interactivement | 0/5 |
| Différés | 0 |
| Modifications spec.md | US-2, US-4, US-5, NFR-002, NFR-006, FR-017 (précisé), FR-017a (ajouté), FR-023/024/025 (ajoutés), Edge case "JWT après MDP", section Questions ouvertes (toutes résolues) |
| Marqueurs `[NEEDS CLARIFICATION]` restants dans spec.md | 0 |

---

## Notes méthodologiques

- **Source des résolutions automatiques** : sparring effectué en amont (4 audits parallèles : isolation données, bootstrap admin, endpoints existants, frontend Settings) + standards marché (Slack, Discord, GitHub, Linear, Notion, Excel) + précédent KKS-233 (CL-002 sur stratégie JWT) + constitution projet (principe III YAGNI, principe VII Self-Hosted Ready).
- **Aucune résolution interactive nécessaire** : le sparring préalable avait déjà tranché la majorité des décisions UX/produit, et les standards techniques sont suffisamment clairs sur les autres points.
- **Conformité constitutionnelle** : toutes les décisions respectent les 7 principes (notamment principe II sur isolation user, principe III sur YAGNI, principe VII sur self-hosted).
