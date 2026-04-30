# Review Log — KKS-235

> Journal des reviews de la feature KKS-235

---

## Review #1 — `review-spec` — 2026-04-30

**Verdict** : PASS
**Itération** : 1
**Agent** : `devflow-review`
**Fichiers analysés** : `spec.md`, `clarify-log.md`, `.specify/memory/constitution.md`

### Métriques

| Métrique | Valeur |
|----------|--------|
| User Stories | 5 (3 P1, 1 P2, 1 P3) |
| Functional Requirements | 25 (FR-001 à FR-025) |
| Non-Functional Requirements | 9 (NFR-001 à NFR-009) |
| Success Criteria | 14 (SC-001 à SC-014) |
| Key Entities | 4 |
| Assumptions | 7 |
| Edge Cases | 8 |
| Migrations DB | 4 (MIG-001 à MIG-004) |
| Questions clarify-log | 5/5 résolues |
| Marqueurs `[NEEDS CLARIFICATION]` restants | 0 |
| Constats BLOQUANT | 0 |
| Constats WARNING | 5 |
| Constats INFO | 5 |

### Constats BLOQUANT

Aucun.

### Constats WARNING (non bloquants, à considérer avant /devflow.plan)

- **W-001** — MIG-003 / MIG-004 : migrations FK hors périmètre, risque de régression sur tests budgets existants. Recommandation : ajouter une assumption documentant l'état actuel des FK et l'impact sur les tests existants.
- **W-002** — FR-024 / FR-025 : comportement "nouveau JWT device courant" absent des Success Criteria. Recommandation : ajouter SC-015 vérifiant que le device courant reste authentifié avec un nouveau JWT après change-password.
- **W-003** — NFR-004 / SC-008 : limite de performance export JSON non couverte (SC-008 ne couvre que le CSV). Recommandation : ajouter SC-016 sur la performance de l'export JSON complet.
- **W-004** — Edge Case "Admin se supprime lui-même" : FR-021 couvre "dernier admin actif" mais le scénario "admin non-seul peut se supprimer" n'est pas couvert dans US-5. Recommandation : ajouter scénario US-5 ou SC dédié.
- **W-005** — SC-004 : métrique de performance avatar "200 ms" potentiellement non tenable sur self-hosted modeste car mélange upload + traitement + service. Recommandation : séparer en deux SC distincts (upload/redim vs service).

### Constats INFO (suggestions de précision)

- **I-001** — FR-003 / FR-007 : étendue exacte du DTO `PUT /users/me` non documentée. Recommandation : préciser que le DTO est limité au champ `name`.
- **I-002** — FR-005 : stratégie de cache HTTP avatar non spécifiée (ETag, Cache-Control, Last-Modified). Recommandation : préciser la stratégie pour parité Angular ↔ Flutter.
- **I-003** — NFR-008 : nom de property Spring pour le chemin de stockage avatar non défini. Recommandation : nommer la property (ex: `app.storage.avatar.path`).
- **I-004** — FR-016 : entité `invitations` absente de la liste des entités à exporter. Recommandation : décider inclusion vs exclusion explicite.
- **I-005** — Parité Flutter : mode offline pour la page Mon compte non clarifié vs constitution principe IV. Recommandation : assumption explicite "page Mon compte = server-only" avec justification.

### Synthèse

La spec KKS-235 est **complète, cohérente et conforme aux 7 principes constitutionnels**. Les 3 US P1 sont indépendamment testables, les 25 FR couvrent exhaustivement les fonctionnalités, les 14 SC sont mesurables avec méthode de vérification. Les 5 questions ouvertes du clarify-log sont toutes résolues et retranscrites.

Les 5 WARNING ne bloquent pas l'avancement mais signalent des angles morts de couverture test et un risque de régression à anticiper. Les 5 INFO sont des précisions utiles pour faciliter l'implémentation. Tous peuvent être traités soit dans une itération `/devflow.review-spec` complémentaire, soit absorbés en phase `/devflow.plan` ou `/devflow.tasks`.

**Décision** : passage en phase `/devflow.research` autorisé.

---

## Review #2 — `review-tasks` — 2026-04-30

**Verdict** : PASS
**Itération** : 1
**Agent** : `devflow-review`
**Fichiers analysés** : `spec.md`, `plan.md`, `contracts.md`, `data-model.md`, `tasks.md`, `.specify/memory/constitution.md`

### Métriques

| Métrique | Valeur |
|----------|--------|
| Total tâches | 77 |
| Phase 1 (Setup) | 8 |
| Phase 2 (Fondations) | 10 |
| Phase 3 P1 (3 US) | 30 |
| Phase 3 P2 (1 US) | 9 |
| Phase 3 P3 (1 US) | 9 |
| Phase 4 (Polish) | 11 |
| Tâches parallélisables `[P]` | 36/77 (47%) |
| FR couverts | 25/25 (100%) |
| NFR couverts | 9/9 (100%) |
| Endpoints contracts couverts | 8/8 (100%) |
| Contrats services couverts | 8/8 (100%) |
| US avec couverture complète (backend + tests + Angular + Flutter) | 5/5 |
| Items review-spec absorbés | 10/10 |
| Constats BLOQUANT | 0 |
| Constats WARNING | 5 |
| Constats INFO | 5 |

### Constats BLOQUANT

Aucun.

### Constats WARNING (non bloquants, corrections cosmétiques recommandées)

- **W-001** — Granularité dense T-043 (`UserPasswordService.changePassword`) et T-060 (`UserDeletionService.softDelete`) : chacune agrège 6-7 opérations distinctes (BCrypt verify, persist, revoke tokens, génération JWT, logs, etc.). Risque de dépassement 1 journée. Recommandation : découper internement en sous-étapes (stub + impl + test unitaire) sans créer de nouvelles tâches formelles.
- **W-002** — Dépendance T-023 → T-022 documentée dans le tableau US Dependencies mais omise dans le graphe macro de Phase 3.
- **W-003** — Auto-référence dans le graphe : `T-058 (dépend T-053, T-058 perf check)` doit être `T-058 (dépend T-053, T-054)`. Coquille à corriger.
- **W-004** — Couverture Flutter US-001 : T-024 ajoute uniquement le row Déconnexion, la navigation Settings hub → page profil Flutter est absorbée implicitement par T-040 (extension `ProfileSettingsScreen`) sans tâche dédiée. Acceptable mais à signaler à l'agent Flutter.
- **W-005** — NFR-007 (logs ERROR) : mapping pointe sur les services (T-030, T-043, T-052, T-060). Préciser à l'agent backend que les `log.error()` doivent aussi être placés dans les handlers d'exception du `UserController` pour couvrir les codes 4xx/5xx générés au niveau controller.

### Constats INFO

- **I-001** — Trou dans la numérotation : T-009 manquant entre T-008 (Phase 1) et T-010 (Phase 2). Cosmétique.
- **I-002** — T-056 / T-057 : dépendances frontend inter-endpoints incomplètes dans le graphe (T-056 dépend aussi de T-054 implicitement, T-057 dépend aussi de T-053).
- **I-003** — T-068 (mode offline Flutter) en Phase 4 sans dépendance documentée vers la couche présentation Flutter de Phase 3 (implicite via ordre Phase 3 → Phase 4).
- **I-004** — T-034 référence SC-004 alors que T-075 le sépare en SC-015 / SC-016. Référence orpheline si SC-004 reste dans la spec sans mise à jour explicite.
- **I-005** — Modèles TypeScript Angular (`change-password-request.model.ts`, `update-profile-request.model.ts`) n'ont pas de tâche dédiée — implicitement absorbés dans T-027 et T-047. À signaler à l'agent `angular-dev`.

### Synthèse

L'ensemble des 25 FR, 9 NFR, 8 endpoints, 8 contrats de services et 4 migrations sont couverts par au moins une tâche. L'ordonnancement respecte strictement Phase 1 → Phase 2 → Phase 3 (P1 → P2 → P3) → Phase 4. Les dépendances inter-tâches sont cohérentes sans cycle détecté. Les 10 items review-spec sont tous absorbés avec tâches dédiées vérifiables. Le principe V de la constitution (tests d'intégration sur chaque endpoint + tests unitaires sur chaque service) est pleinement respecté.

Les 5 WARNING et 5 INFO sont des corrections **cosmétiques** (coquille de référence, manques mineurs dans le graphe, navigation implicite Flutter, granularité dense de 2 services) qui ne bloquent pas l'implémentation. Elles peuvent être absorbées par les agents d'implémentation lors du développement réel.

**Décision** : passage en phase `/devflow.implement` autorisé.

---

## Gate `/devflow.implement` — 2026-04-30

**Verdict** : MODE DÉGRADÉ (continue)
**Motif** : `checklist.md` absent (la commande `/devflow.checklist` n'a pas été exécutée). Conformément aux contraintes du command, mode dégradé activé : la gate est ignorée avec avertissement.

**Scan technologique** :
- ✅ Stacks détectées : Java/Spring Boot (`api/pom.xml`), Angular/TS (`app/package.json`, `app/tsconfig.json`, `app/angular.json`), Flutter (`flutter/pubspec.yaml`)
- ✅ `.gitignore` présent à la racine, suffisant pour les 3 stacks (vérification visuelle non bloquante)
- ✅ Branche `feature/KKS-235` active
- ✅ Pas de changement non-commité hormis le dossier `docs/features/KKS-235/` (artefacts devflow normaux)

**Décision** : démarrage de l'implémentation phase par phase autorisé.

---
