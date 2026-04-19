# Review Log — KKS-232

> Journal des reviews de la feature KKS-232

---

## Review spec — 2026-04-19 (itération 1)

**Mode** : review-spec
**Verdict** : **BLOQUANT**
**Artefacts analysés** : `spec.md`, `clarify-log.md`
**Constitution** : v2.1.2

### Grille

| Passe | Résultat |
|-------|----------|
| 1 — Complétude | OK (toutes sections, 10 US P1, FR-001→024, SC-001→012, Key Entities, 6 Assumptions) |
| 2 — Clarté | OK (G/W/T, Why + Independent Test sur chaque US, aucun `[NEEDS CLARIFICATION]`) |
| 3 — Testabilité | AVERTISSEMENT (SC méthode précisée ; orphelins partiels) |
| 4 — Cohérence | BLOQUANT (US-005 non couverte par un SC) + 2 incohérences mineures |
| 5 — Clarification | OK (5 points résolus reflétés dans spec.md) |

### Constats

**BLOQUANT**
- **B-001** — US-005 (réactivation) n'a aucun SC validant le retour d'accès. Ajouter `SC-013 — Après réactivation, le user peut se connecter et ses requêtes ne renvoient plus 401 | Test d'intégration auto | US-005`.

**WARNING**
- **W-001** — FR-004 contient "liste paginée" : résidu incohérent avec CL-002 (pas de pagination). Remplacer "paginée" → "complète".
- **W-002** — FR-009 (`GET /api/auth/invitations/:token`) est attribué uniquement à US-002 mais SC-005 l'utilise pour valider US-003. Ajouter US-003 dans la colonne.
- **W-003** — NFR-008 : "lecture à chaque check" non bornée. Préciser "lecture depuis `Environment` Spring, pas d'I/O externe".
- **W-004** — FR-001 (migration Flyway `Invitation`) ne mentionne pas explicitement `token UNIQUE NOT NULL + INDEX(token)`. Amender la description.
- **W-005** — SC-006 "Test E2E frontend" sans préciser le scope (Angular ? Flutter ? les deux ?). Préciser "Test E2E Angular + manuel Flutter".
- **W-006** — Assumption A-003 "factorisable ou déjà extrait" : à transformer en constat technique en phase `/devflow.plan` après vérif du code existant.

**INFO**
- **I-001** — Hors scope "Bootstrap premier admin sur DB vide" : utile d'ouvrir un ticket Linear de suivi pour l'adoption par d'autres self-hosters.
- **I-002** — NFR-006 sans référence explicite aux cas limites (token expiré / utilisé / révoqué / double-use). Les SC les couvrent mais NFR-006 devrait y faire référence.
- **I-003** — Dans `InvitationResponse`, la projection `invitedByUserId → invitedByEmail` implique un lookup. À noter dans la description du DTO.

### Conformité constitution v2.1.2

| Principe | Statut |
|----------|--------|
| I — API-First | OK |
| II — Sécurité par défaut | OK |
| III — YAGNI | OK |
| IV — Mobile-First UX | OK |
| V — Testabilité | AVERTISSEMENT (B-001) |
| VI — Observabilité | OK |
| VII — Self-Hosted Ready | OK |

### Actions requises avant passage à la phase plan

1. **[BLOQUANT]** Ajouter SC-013 pour couvrir US-005.
2. Corriger "paginée" → "complète" dans FR-004 (W-001).
3. Ajouter US-003 dans la colonne User Story de FR-009 (W-002).
4. Amender FR-001 pour mentionner `UNIQUE NOT NULL + INDEX(token)` (W-004).
5. Préciser NFR-008 (W-003) et SC-006 (W-005) si souhaité.

**Prochaine étape** : corriger la spec puis relancer `/devflow.review-spec KKS-232`.

---

## Review spec — 2026-04-19 (itération 2)

**Mode** : review-spec
**Verdict** : **PASS**
**Artefacts analysés** : `spec.md` corrigé, `clarify-log.md`, `review-log.md` (historique)

### Vérification des corrections de l'itération 1

| # | Correction | Statut |
|---|-----------|--------|
| B-001 | SC-013 ajouté (réactivation user → retour accès) | Validé |
| W-001 | FR-004 : "paginée" → "liste complète" + tri + enum status | Validé |
| W-002 | FR-009 : User Story = `US-002, US-003` | Validé |
| W-003 | NFR-008 : `Environment.getProperty()`, pas d'I/O externe | Validé |
| W-004 | FR-001 : `UNIQUE NOT NULL + INDEX(token)` + FK | Validé |
| W-005 | SC-006 : scope Angular + Flutter précisé | Validé |
| I-002 | NFR-006 : cas limites listés | Validé |
| I-003 | `InvitationResponse` : projection via lookup `UserRepository` notée | Validé |

### Grille

| Passe | Résultat |
|-------|----------|
| 1 — Complétude | OK (10 US P1 + 3 P2, FR-001→024, SC-001→013, 5 Key Entities, 6 Assumptions) |
| 2 — Clarté | OK |
| 3 — Testabilité | OK |
| 4 — Cohérence | OK |
| 5 — Clarification | OK |

### Constats

- **BLOQUANT** : aucun
- **WARNING** : aucun
- **INFO** :
  - I-001 (bootstrap admin DB vide) reporté à ticket séparé — mention explicite dans spec
  - I-004 — formulation exacte du log WARN ajustable en phase implémentation
  - I-005 — W-006 (A-003 "factorisable") correctement différé à `/devflow.plan`

### Conformité constitution v2.1.2

Tous principes (I à VII) : **OK**.

### Verdict

**PASS** — B-001 levé, 5 WARNING corrigés, aucune régression. Spec prête pour `/devflow.research` puis `/devflow.plan`.

---

## Review tasks — 2026-04-19 (itération 1)

**Mode** : review-tasks
**Verdict** : **PASS**
**Artefacts analysés** : `spec.md`, `plan.md`, `contracts.md`, `tasks.md`, `data-model.md`

### Grille

| Passe | Statut |
|-------|--------|
| 1 — Couverture FR/US/SC (24/24, 13/13, 13/13) | PASS |
| 2 — Mapping Requirements → Tâches | PASS (WARNING mineur) |
| 3 — Ordonnancement / dépendances | PASS (WARNING) |
| 4 — Granularité (< 1 j par tâche) | PASS |
| 5 — Format / numérotation / tags [P] | PASS (WARNING) |
| 6 — Parallel Opportunities (10 groupes) | PASS (WARNING) |
| 7 — Cohérence plan ↔ tasks (13/13 composants) | PASS |
| 8 — Cohérence contracts ↔ tasks | PASS (WARNING DC-003) |
| 9 — MVP / Incremental delivery (4 livraisons) | PASS |

### Constats

**BLOQUANT** : aucun.

**WARNING** (7, tous non bloquants — imperfections de documentation) :
- **W-001** — Description du groupe G2 potentiellement trompeuse : T-012/T-014 figurent dans la liste [P] de Phase 2 alors qu'ils dépendent de T-010/T-011. Le graphe Phase 5 est correct mais la description peut induire en erreur.
- **W-002** — NFR-002 (logs INFO admin) : T-034 (revoke) et T-042 (disable/enable) couvrent les logs dans leur corps mais ne figurent pas dans le mapping NFR-002.
- **W-003** — US-009 pas de ligne explicite dans `US Dependencies` (mentionné en commentaire de US-004).
- **W-004** — DC-003 (mutuelle exclusivité `usedAt` / `revokedAt`) pas de test dédié explicite.
- **W-005** — Tableau Résumé : "+ plus" inexact sur P1 parallèles (12 exactement, pas "12 + plus").
- **W-006** — T-062 (service Angular) listé dans mapping FR-003 à FR-008 aux côtés de tâches backend — matrice mélangée.
- **W-007** — Ordre intra-US Flutter (T-081 → T-082 → T-083 → T-084) présent dans le graphe mais pas dans la table US Dependencies.

**INFO** (4) :
- I-001 — T-003 marqué [P] avec T-002 : formulation légèrement contradictoire.
- I-002 — Cas "email déjà utilisé" dans `AcceptInviteService` non explicitement testé.
- I-003 — T-068 / T-080 (design check) marqués [P] mais dépendent de la création des composants.
- I-004 — NFR-005 (BCrypt) non référencé dans le mapping Requirements → Tâches.

### Verdict

**PASS** — Les 82 tâches couvrent intégralement 24 FR / 13 US / 13 SC / 9 endpoints / 9 services / 14 interfaces / 4 contrats composants. Pas de cycle dans le graphe, checkpoints cohérents, 4 livraisons incrémentales distinctes. Les WARNING sont des imperfections de documentation sans impact sur l'exécutabilité.

**Prochaine étape** : `/devflow.implement KKS-232`. Les WARNING peuvent être corrigés en parallèle ou en Phase 4 Polish.

---

## Review tasks — 2026-04-19 (itération 2)

**Mode** : review-tasks
**Verdict** : **PASS**
**Artefacts analysés** : `spec.md`, `plan.md`, `contracts.md`, `tasks.md` corrigé, `data-model.md`

### Vérification des corrections itération 1

| # | Correction | Statut |
|---|-----------|--------|
| W-001 | Graphe G2/G3/G4 reformulé, T-012/T-014 dans G3, T-017/T-019 dans G4 | Validé |
| W-002 | NFR-002 mapping : T-023, T-034, T-042, T-044, T-029 | Validé |
| W-003 | US-009 ligne propre dans US Dependencies | Validé |
| W-004 | DC-003 → T-032 (double-use/revoke), T-036 (revoke USED), NFR/SC mappe DC-001 à DC-006 | Validé |
| W-005 | Résumé : P1 para = 12, P2 para = 8, Total para = 33 après ajouts T-016 [P] et T-062 [P] | Validé |
| W-006 | Mapping scindé backend / frontend, T-062 en colonne frontend | Validé |
| W-007 | Ordre intra-US Angular (T-069→T-070→T-071/T-072) et Flutter (T-081→T-082→T-083→T-084) documenté | Validé |
| I-001 | T-002 et T-003 tous deux [P] | Validé |
| I-002 | T-033 enrichi avec cas email déjà utilisé | Validé |
| I-003 | T-068 / T-080 [P] retiré, dépendances T-065 / T-077 notées | Validé |
| I-004 | NFR-005 mappé à T-029 | Validé |
| Résiduels itération 2 | T-016 [P] et T-062 [P] ajoutés pour aligner tags avec graphe | Corrigés |

### Grille

| Passe | Résultat |
|-------|----------|
| 1 — Couverture (24 FR, 13 US, 13 SC) | OK |
| 2 — Mapping Requirements → Tâches | OK |
| 3 — Ordonnancement / dépendances | OK (pas de cycle) |
| 4 — Granularité | OK |
| 5 — Format / numérotation / tags [P] | OK |
| 6 — Parallel Opportunities (11 groupes) | OK |
| 7 — Cohérence plan ↔ tasks (13/13 composants) | OK |
| 8 — Cohérence contracts ↔ tasks (9 endpoints, 9 services, 14 interfaces) | OK |
| 9 — MVP / Incremental delivery (4 livraisons) | OK |

### Constats

- **BLOQUANT** : aucun
- **WARNING** : aucun (les 2 résiduels identifiés par l'agent ont été corrigés)
- **INFO** : aucun

### Verdict

**PASS** — 11 corrections validées + 2 ajustements résiduels appliqués. Aucun constat restant. Document prêt pour `/devflow.implement KKS-232`.

---
