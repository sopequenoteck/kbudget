# Review Log — KKS-253

---

## Itération 1 — 2026-05-22 | review-spec | PASS

**Agent** : devflow-review  
**Verdict** : PASS  
**Constats** : 0 BLOQUANT · 5 WARNING · 4 INFO

### Warnings (non bloquants)

| ID | Localisation | Description |
|----|-------------|-------------|
| W-001 | `spec.md` NFR-006 | Non quantifié — nombre de tests et scenarios négatifs non spécifiés |
| W-002 | `spec.md` Assumptions A-001/A-002 | Colonne "Impact si fausse" vide (`—`) après résolution — ajouter "N/A (résolu CL-XXX)" |
| W-003 | `spec.md` FR-004 | Contient du code Dart littéral — niveau implémentation, pas spec. Reformuler en comportement observable |
| W-004 | `spec.md` SC-004/SC-005 | Uniquement manuels — partiellement vérifiable par widget test |
| W-005 | `spec.md` US-002 Independent Test | Subjectif — pas de vérification que les tokens (pas valeurs hardcodées) sont bien utilisés |

### Infos

| ID | Description |
|----|-------------|
| I-001 | FR-009 contient des valeurs numériques exactes (`thickness: 0.5`) — niveau plan, pas spec |
| I-002 | Section P3 à renommer "Hors scope / Différées" pour éviter confusion avec P3 planifié |
| I-003 | Clarify-log résumé : "3/11" mais 4 catégories listées — incohérence de comptage mineure |
| I-004 | NFR-003/004/005 sont des contraintes de périmètre, pas des NFR au sens strict |

### Justification PASS

Spec bien structurée, complète et cohérente. Les 5 CL résolus correctement répercutés. Les 3 questions ouvertes fermées. US P1 avec Given/When/Then exploitables et SC testables. Les warnings W-001 à W-005 sont des faiblesses de forme à adresser lors de la rédaction du plan et des tasks. Le point le plus matériel est W-003 (FR-004 avec code Dart) : à reformuler dans plan.md si le pattern évolue.

---

## Itération 2 — 2026-05-22 | review-tasks | PASS

**Agent** : devflow-review  
**Verdict** : PASS  
**Constats** : 0 BLOQUANT · 5 WARNING

### Warnings (non bloquants)

| ID | Localisation | Description |
|----|-------------|-------------|
| W-001 | `tasks.md` Phase 2 / Résumé | Marqueur [P] sur T-011 présent dans le résumé mais absent dans le texte de la phase ; T-012 aussi parallélisable (non marqué) ; incohérence tableau Parallel Opportunities vs texte |
| W-002 | `tasks.md` T-051→T-054 | SC-004 et SC-005 (vérification manuelle) non mentionnés dans les tâches de test — risque d'oubli lors de la review d'implémentation |
| W-003 | `tasks.md` graphe ASCII | Dépendance T-021 → T-032 présente dans la table US Dependencies mais absente du graphe ASCII — légère incohérence de représentation |
| W-004 | `tasks.md` T-034 | `_openDeleteAccount` absent de la liste des actions effaçant `_errorMessage` — cas limite sur FR-016 ("chaque action") |
| W-005 | `tasks.md` section titre | "Phase 5 — Dépendances & Ordre d'exécution" est un titre trompeur : décrit le graphe global inter-phases, pas uniquement la Phase 5 |

### Justification PASS

Couverture FR complète (16/16), NFR complète (6/6), SC quasi-complète (SC-001→SC-011 tous adressés). Les 3 décisions techniques (RES-001, RES-002, RES-003) et les 4 risques (R-001→R-004) sont reflétés dans des tâches concrètes. Ordonnancement correct, granularité homogène (23 tâches, chacune < ½ journée). Les 5 warnings sont des incohérences de présentation ou un cas limite FR-016 — aucun oubli fonctionnel bloquant.

---

## Itération 3 — 2026-05-22 | review-impl | PASS

**Agent** : devflow-review  
**Verdict** : PASS  
**Constats** : 0 BLOQUANT · 4 WARNING · 2 INFO

### Warnings (non bloquants)

| ID | Localisation | Description |
|----|-------------|-------------|
| W-001 | `profile_settings_screen.dart` lignes ~117,124 | `_ExportRow` utilise `ext(context).primarySubtle` comme `iconBg` au lieu de `ext.secondaryColor.withAlpha(30)` prévu dans le plan — déviation mineure, token valide |
| W-002 | `profile_settings_screen_test.dart` lignes ~336-360 | SC-008 : test vérifie la présence du widget CSV mais pas que son `onTap` est `null` — comportement correct dans le code, couverture incomplète |
| W-003 | `profile_settings_screen.dart` ligne ~196 | `color: Colors.green` hardcodé sur le bouton check (save) — viole NFR-002, remplacer par `colorScheme.primary` ou `ext(context).incomeColor` |
| W-004 | `profile_settings_screen.dart` ligne ~327 | `_openDeleteAccount` ne remet pas `_errorMessage` à null en début d'action — FR-016 exige "chaque action" |

### Justification PASS

16/16 FRs implémentés, 6/6 NFRs respectés, infrastructure de test robuste (4 mocks variés, SC-001→SC-009 tous couverts). `mounted` vérifié après chaque `await`, bloc `finally` sur les exports (R-003 mitigé), `AppRadius.xl` utilisé partout (R-002 non matérialisé), `_CurrencySelector`/`_hasChanged`/`_isSaving` totalement absents (FR-011). Les 4 warnings sont des corrections de polish applicables dans le commit suivant sans bloquer la livraison.
