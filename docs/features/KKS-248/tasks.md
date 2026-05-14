# Tasks: Catégories formulaire Flutter (alignement DESIGN.md v5)

**Issue**: KKS-248 | **Date**: 2026-05-14  
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

---

## Phase 1 — Setup (Vérifications préliminaires)

**Objectif** : Confirmer le périmètre réel avant de modifier quoi que ce soit.

- [x] T-001 Grep `CategoryPreviewCard` dans tout le codebase Flutter — confirmer usage unique dans `category_form_widget.dart` : `grep -rn "CategoryPreviewCard" flutter/lib/`
- [x] T-002 [P] Lire `category_form_widget_test.dart` — confirmer aucune assertion sur `CategoryPreviewCard` ou `CategoryPreviewCard` dans les finders

**Checkpoint** : Périmètre confirmé, aucune surprise. Modifications peuvent commencer.

---

## Phase 2 — Fondations (Audit tokens avant modification)

**Objectif** : Identifier toutes les valeurs hardcodées avant de toucher au code.

- [x] T-011 Auditer `category_form_widget.dart` — grep valeurs hardcodées : `grep -n '[0-9]\+\.0\b\|fontSize:\|width:\|height:\|padding:\|margin:' flutter/lib/src/features/categories/presentation/widgets/category_form_widget.dart`
- [x] T-012 [P] Auditer `emoji_input.dart` — même grep sur `flutter/lib/src/common_widgets/emoji_input.dart` — Réf: FR-008
- [x] T-013 [P] Auditer `category_form_screen.dart` — même grep sur `flutter/lib/src/features/categories/presentation/screens/category_form_screen.dart` — Réf: FR-008

**Checkpoint** : Liste exhaustive des valeurs hardcodées connue. Aucune modification non planifiée.

---

## Phase 3 — User Stories (Implémentation)

### US1 — Saisie du nom avec validation (P1)

**Goal** : Le champ nom fonctionne avec validation inline, tokens v5, sans `CategoryPreviewCard`.

- [x] T-021 [US1] Supprimer import `category_preview_card.dart` et usage `CategoryPreviewCard(...)` + `SizedBox` spacer associé dans `flutter/lib/src/features/categories/presentation/widgets/category_form_widget.dart` — Réf: FR-009
- [x] T-022 [US1] Corriger valeurs hardcodées identifiées en T-011 dans `category_form_widget.dart` (remplacer par tokens `AppSpacing`, `AppTypography`, `AppColors`) — Réf: FR-008

**Checkpoint US1** : Formulaire s'affiche sans `CategoryPreviewCard`, champ nom avec validation inline, aucune valeur hardcodée.

---

### US2 — Sélection de l'emoji avec validation (P2)

**Goal** : `EmojiInput` aligné tokens v5, validation bloquante si vide.

- [x] T-031 [US2] Corriger valeurs hardcodées identifiées en T-012 dans `emoji_input.dart` si présentes — Réf: FR-003, FR-008
- [x] T-032 [P] [US2] Corriger valeurs hardcodées identifiées en T-013 dans `category_form_screen.dart` si présentes — Réf: FR-008

**Checkpoint US2** : `EmojiInput` et `CategoryFormScreen` sans valeurs hardcodées.

---

### US3 — Sélection de la couleur avec défaut aléatoire (P3)

**Goal** : `ColorPalettePicker` avec token `AppSpacing.space9` à la place de `36`.

- [x] T-041 [US3] Remplacer `width: 36, height: 36` par `AppSpacing.space9` dans `flutter/lib/src/common_widgets/color_palette_picker.dart` — Réf: FR-004, FR-008

**Checkpoint US3** : `ColorPalettePicker` sans valeur hardcodée, rendu identique.

---

## Phase 4 — Polish

**Objectif** : Vérification globale, tests, sort du fichier orphelin.

- [ ] T-051 Ouvrir `CategorySelectExpand` en mode création → vérifier rendu visuel du `CategoryFormWidget` embedded (pas d'espace vide, layout cohérent sans `CategoryPreviewCard`) — Réf: NFR-002
- [x] T-052 [P] Lancer `flutter test flutter/test/src/features/categories/` — 44/44 tests passent — Réf: SC-006
- [x] T-053 Supprimer `category_preview_card.dart` + `category_preview_card_test.dart` — code mort, aucun usage, YAGNI (principe III constitution).

**Checkpoint Final** : Tous les tests passent. Aucune régression. `CategoryPreviewCard` traitée.

---

## Phase 5 — Dépendances & Ordre d'exécution

### Graphe de dépendances

```
T-001 ──┐
T-002 ──┤── Checkpoint Phase 1
        │
T-011 ──┤
T-012 ──┤── Checkpoint Phase 2
T-013 ──┘
        │
T-021 ←─┘ (dépend T-001, T-011)
T-022   (dépend T-011, T-021)
        │
T-031 ←─┘ (dépend T-012)
T-032   (dépend T-013) [parallèle avec T-031]
        │
T-041 ←─┘ (indépendant, dépend Phase 2)
        │
T-051   (dépend T-021, T-022)
T-052   (dépend toute Phase 3) [parallèle avec T-051]
T-053   (dépend T-021)
```

### Table US Dependencies

| User Story | Tâches | Dépend de |
|-----------|--------|-----------|
| US1 — Nom | T-021, T-022 | T-001, T-011 (Phase 1 + 2) |
| US2 — Emoji | T-031, T-032 | T-012, T-013 (Phase 2) |
| US3 — Couleur | T-041 | Phase 2 complète |

### Parallel Opportunities

| Groupe | Condition |
|--------|-----------|
| T-002, T-012, T-013 | Dès Phase 1 lancée — fichiers distincts |
| T-031, T-032 | Après Phase 2 — fichiers distincts |
| T-051, T-052 | Après Phase 3 complète |

---

## Requirements → Tâches

| Requirement | Tâches |
|-------------|--------|
| FR-001 (erreur nom inline) | T-011, T-022 |
| FR-002 (max 30 chars) | T-011, T-022 |
| FR-003 (emoji bloquant si vide) | T-031 |
| FR-004 (color swatches token) | T-041 |
| FR-005 (couleur aléatoire création) | T-041 |
| FR-006 (pré-remplissage édition) | T-022 |
| FR-007 (erreurs après soumission) | T-011, T-022 |
| FR-008 (tokens v5, zéro hardcode) | T-011, T-012, T-013, T-022, T-031, T-032, T-041 |
| FR-009 (retirer CategoryPreviewCard) | T-001, T-021 |
| NFR-001 (erreurs réseau → SnackBar) | T-022 (vérification, logique déjà en place) |
| NFR-002 (mode embedded CategorySelectExpand) | T-051 |
| NFR-003 (pas d'extraction common_widgets) | Contrainte implicite sur toutes les tâches |

---

## Tableau résumé

| Phase | Tâches | Parallélisables |
|-------|--------|----------------|
| Phase 1 — Setup | 2 | 1 (T-002) |
| Phase 2 — Fondations | 3 | 2 (T-012, T-013) |
| Phase 3 — US P1 | 2 | 0 |
| Phase 3 — US P2 | 2 | 1 (T-032) |
| Phase 3 — US P3 | 1 | 0 |
| Phase 4 — Polish | 3 | 1 (T-052) |
| **Total** | **13** | **5** |

---

## Implementation Strategy

### MVP First (US1 uniquement)

1. Phase 1 : T-001, T-002
2. Phase 2 : T-011
3. US1 : T-021, T-022
4. **STOP** : Vérifier le formulaire visuellement, tester

### Incremental Delivery

1. Setup + Audit → périmètre confirmé
2. US1 (nom) → `CategoryPreviewCard` retirée, tokens nom OK
3. US2 (emoji) → `EmojiInput` aligné
4. US3 (couleur) → `ColorPalettePicker` token
5. Polish → tests, embedded, orphelin traité
