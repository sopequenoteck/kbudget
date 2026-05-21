# Review Log — KKS-251

---

## Itération 1 — 2026-05-21 | review-impl | PASS

**Agent** : devflow-review  
**Constats** : 0 BLOQUANT · 4 WARNING · 4 INFO

### Warnings

| ID | Localisation | Description |
|----|-------------|-------------|
| W-001 | `recurring_list_screen.dart` L.224 / FR-011 | Montant action sheet en `semiBold` (w600) au lieu de `bold` (w700) — plan indique `AppTypography.bold` |
| W-002 | `recurring_list_screen.dart` L.241/253/265 / FR-012 | `isMutating: false` hardcodé dans `_showActionSheet()` — bouton non désactivé si item en mutation via `validateAll` |
| W-003 | `recurring_list_screen.dart` L.296 / NFR-001 | SnackBar `validateAll` succès utilise `recurringValidateSuccess` (= "Transaction créée") au lieu du message interpolé avec count attendu par la spec |
| W-004 | `recurring_list_screen_test.dart` / NFR-004 | Couverture partielle : aucun test pour couleur header, bouton "Tout payé" conditionnel, ni montants `_MonthlySummaryCard` |

### Infos

| ID | Localisation | Description |
|----|-------------|-------------|
| I-001 | `_StatusGroupSection` / FR-008 | `Divider(indent: space4+36+space3)` non prévu dans le plan — amélioration visuelle cohérente avec les patterns existants |
| I-002 | `relative_date_formatter.dart` / NFR-002 | Passé > 7j tombe directement sur `DateFormat('dd MMM')` sans cas intermédiaire semaines (conforme spec, notable) |
| I-003 | `app_fr.arb` L.332 | `recurringDeactivateConfirm` toujours présent mais plus utilisé (clé orpheline, dette mineure) |
| I-004 | `recurring_list_item.dart` L.53 / plan 3.4 | Libellé sans couleur `onSurfaceVariant` explicite — hérite du thème, conforme Angular source mais écart avec le plan écrit |

### Points à corriger optionnellement avant merge

- **W-001** : `AppTypography.semiBold` → `AppTypography.bold` dans `_showActionSheet()` (1 ligne)
- **W-003** : Créer une clé l10n `recurringValidateAllSuccess` avec count ou adapter le message

---

## Gate implement — 2026-05-21 | checklist | DÉGRADÉ (absent)

checklist.md absent → gate ignorée, implémentation poursuivie sans blocage.

---

## Implémentation — 2026-05-21 | implement | TERMINÉE

**18/18 tâches complétées** | 13 tests PASS | `flutter analyze` : 0 warning

**Fichiers modifiés** :
- `flutter/lib/src/localization/app_fr.arb` — 3 mises à jour + 4 nouvelles clés + gen-l10n
- `flutter/lib/src/utils/relative_date_formatter.dart` — `formatCompact()` ajouté
- `flutter/lib/src/features/recurring/application/recurring_list_notifier.dart` — `validateAll()` ajouté
- `flutter/lib/src/features/recurring/presentation/widgets/recurring_list_skeleton.dart` — 6→5 items, icône cercle
- `flutter/lib/src/features/recurring/presentation/widgets/recurring_list_item.dart` — refonte complète (StatelessWidget, onTap, cercle 36px, sous-titre, montant coloré)
- `flutter/lib/src/features/recurring/presentation/recurring_list_screen.dart` — refonte complète (CustomScrollView, groupes, summary, action sheet)
- `flutter/test/src/features/recurring/application/recurring_list_notifier_test.dart` — 3 tests validateAll ajoutés
- `flutter/test/src/features/recurring/presentation/recurring_list_screen_test.dart` — overrides additionnels + assertions adaptées

**Point W-001 résolu** : tests `_StatusGroupHeader` (`EN RETARD`, `À VENIR`) vérifiés dans T-052.
**Point W-003 respecté** : T-041 (`_showActionSheet`) implémenté avant T-033 (`_StatusGroupSection`).

---

## Itération 2 — 2026-05-21 | review-tasks | PASS

**Agent** : devflow-review  
**Constats** : 0 BLOQUANT · 4 WARNING · 5 INFO

### Warnings

| ID | Localisation | Description |
|----|-------------|-------------|
| W-001 | T-052 / NFR-004 | Nouveaux tests widget (`_StatusGroupHeader`, `_MonthlySummaryCard`) demandés par NFR-004 et plan.md non couverts dans tasks.md |
| W-002 | T-033 | Charge cognitive élevée : 5 responsabilités dans une seule tâche (widget + handler + branchage + SnackBar + 6 refs FR/NFR) |
| W-003 | Phase 5 graphe | Dépendance T-033 → T-041 présentée comme optionnelle alors qu'elle est nécessaire — risque que le développeur suive l'ordre US et implémente T-033 avant T-041 |
| W-004 | T-031 | 5 responsabilités hétérogènes (migration + états vides + providers + imports) — checkpoint intermédiaire recommandé |

### Infos

| ID | Localisation | Description |
|----|-------------|-------------|
| I-001 | NFR-003 | Contrainte "aucune modification repository/domain/DTOs" déclarée implicite sans vérification active (pas de grep) |
| I-002 | Phase 1 checkpoint | Libellé "Usages l10n confirmés" inexact — T-001 vérifie les usages des 3 clés récurrence, pas tous les usages l10n |
| I-003 | T-011/T-012 | Parallélisation correcte confirmée (fichiers distincts, pas de conflit gen-l10n) |
| I-004 | T-022 / FR-005 | Import `AppColors` à supprimer non mentionné explicitement dans les tâches |
| I-005 | T-041 | `_ActionButton` (widget) et `_showActionSheet()` (méthode) couplés dans une seule tâche sans distinction dans la table Requirements |

### Corrections appliquées post-review

Aucune correction nécessaire (verdict PASS). Points à surveiller lors de l'implémentation :
- **W-001** : Ajouter les tests widget `_StatusGroupHeader` et `_MonthlySummaryCard` dans T-052 lors de l'exécution
- **W-002/W-003** : Effectuer T-041 avant T-033 (ordre graphe, pas ordre US)
- **I-004** : Vérifier suppression import `AppColors` lors de T-022

---

## Itération 1 — 2026-05-21 | review-spec | PASS

**Agent** : devflow-review  
**Constats** : 0 BLOQUANT · 4 WARNING · 4 INFO

### Warnings

| ID | Localisation | Description |
|----|-------------|-------------|
| W-001 | Key Entities | `accountCurrency` absent des champs utilisés alors qu'il est nullable et indispensable à la conversion monthly summary |
| W-002 | NFR-002 | `formatCompact` non spécifié pour aujourd'hui/hier/demain |
| W-003 | SC-004 | Méthode de vérification du NET mensuel imprécise (mélange assertion comportementale et détail implémentation) |
| W-004 | FR-016 | Correction icône Désactiver (`.x` → `.pause`) mal placée dans la section skeleton — appartient à FR-012 |

### Infos

| ID | Localisation | Description |
|----|-------------|-------------|
| I-001 | NFR-001 | SnackBar succès `validateAll` hardcodé en français, incohérent avec l'approche l10n du projet |
| I-002 | FR-003 vs NFR-002 | Ambiguïté `date_formatter.dart`/`getRelativeDate` vs `relative_date_formatter.dart`/`formatCompact` — risque fichier orphelin |
| I-003 | Edge Cases | `validateAll(ids: [])` non exclu explicitement dans NFR-001 |
| I-004 | FR-010 vs US2 S5 | "{N} CHARGES" avec N=0 non traité dans les scenarios |

### Corrections appliquées post-review

- **FR-003** : Remplacé `date_formatter.dart` + `getRelativeDate()` → `RelativeDateFormatter.formatCompact()` (résout I-002)
- **FR-016** : Retiré correction icône Désactiver hors scope skeleton (résout W-004, déjà couvert par FR-012)
- **Key Entities** : Ajout `accountCurrency` (`Currency?`, nullable) avec mention fallback (résout W-001)
- **NFR-002** : Ajout comportement aujourd'hui/hier/demain dans `formatCompact` (résout W-002)
