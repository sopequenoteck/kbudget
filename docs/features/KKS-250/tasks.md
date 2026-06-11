# Tasks: Comptes liste Flutter (alignement DESIGN.md v5)

**Issue**: KKS-250 | **Date**: 2026-05-21  
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

---

## Phase 1 — Setup (Vérifications préliminaires)

**Objectif** : Confirmer le périmètre et les tokens avant toute modification.

- [x] T-001 Grep `AccountBankIcon` dans tout `flutter/lib` pour confirmer l'unique caller : `grep -rn "AccountBankIcon" flutter/lib --include="*.dart" | grep -v "account_bank_icon.dart"`
- [x] T-002 [P] Vérifier les tokens dans les constantes : `AppRadius.xl = 16`, `AppSpacing.space7 = 28`, `AppSpacing.space8 = 32`, `AppTypography.size2Xs = 10`
- [x] T-003 [P] Inspecter `account_list_tile_test.dart` pour identifier si `PopupMenuButton` est testé — grep : `grep -n "PopupMenu\|onDelete\|setDefault" flutter/test/src/features/accounts/presentation/widgets/account_list_tile_test.dart`

**Checkpoint** : Seul caller `account_list_tile.dart` confirmé, tokens vérifiés, impact tests connu. Modifications peuvent commencer.

---

## Phase 2 — Fondations (Prérequis bloquant)

**Objectif** : Corriger `AccountBankIcon` avant tout usage dans le tile — ce fix est prérequis à tous les T-02X.

- [x] T-011 Modifier `flutter/lib/src/common_widgets/account_bank_icon.dart` — changer la formule : `Container(width: size, height: size)` (au lieu de `size * 1.5`), icône SVG → `size * 2/3`, emoji → `size * 0.55` — Réf: FR-001

**Checkpoint** : `AccountBankIcon(size: 32)` produit un cercle de 32px. US1 peut commencer.

---

## Phase 3 — User Stories (Implémentation)

### US1 — Refonte AccountListTile (P1)

**Goal** : `AccountListTile` fidèle à Angular — icône 32px, layout Row + Column, sous-titre `bankName · type`, solde colorisé, badges outline, actions inline (trash/star/edit), supprimer PopupMenuButton.

- [x] T-021 [US1] Refonte layout `AccountListTile` dans `flutter/lib/src/features/accounts/presentation/widgets/account_list_tile.dart` : `Column(Row(icon+Column(nom+badges+subtitle)+balance) + Row(actions))`, icon `size: AppSpacing.space8`, sous-titre `_subtitle()` = `bankName · type`, importer `app_theme_extension.dart` — Réf: FR-001, FR-002, FR-003
- [x] T-022 [US1] Implémenter styles dans `account_list_tile.dart` : nom `sizeSm`/`medium`/`onSurfaceVariant`, solde `sizeSm`/`semiBold`/`expenseColor` si `solde < 0`, `_Badge` outline (`Border.all(outlineVariant)`, `size2Xs`, `AppRadius.round`, padding `horizontal: 6, vertical: 1`) — Réf: FR-004, FR-005
- [x] T-023 [US1] Implémenter actions inline dans `account_list_tile.dart` : `_ActionButton` (SizedBox 32px, IconButton padding zero, phosphor size 16), Row(trash `expenseColor` + Spacer + star si `!isDefault && actif` + edit), supprimer `PopupMenuButton` et `onDelete` — Réf: FR-006

**Checkpoint US1** : `AccountListTile` affiche icône 32px, badge outline, solde rouge si négatif, 3 boutons inline. Aucun `PopupMenuButton`.

---

### US2 — AccountListScreen structure et états (P2)

**Goal** : `AccountListScreen` fidèle à Angular — carte `surface/radius-xl`, section header "{N} comptes", `EmptyStateWidget`, AppBar nettoyée, skeleton 3 items.

- [x] T-031 [US2] Refonte zone data dans `flutter/lib/src/features/accounts/presentation/screens/account_list_screen.dart` : remplacer `SliverList.builder` par `SliverToBoxAdapter(Padding(Column(section-header + Container(surface/radius-xl/clip, Column(items + Dividers)))))`, brancher `AccountListTile` avec nouveaux callbacks (`onSetDefault`, `onEdit`) — Réf: FR-007
- [x] T-032 [US2] Ajouter section header dans `account_list_screen.dart` : `Row(Text('{N} comptes', sizeXs/semiBold/uppercase/letterSpacing0.5) + _AddButton(28px, outlineVariant, +, navigate /new))`, supprimer `AppBar.actions` (IconButton +) — Réf: FR-008
- [x] T-033 [US2] Remplacer états empty et error dans `account_list_screen.dart` : `SliverFillRemaining(EmptyStateWidget(icon: bank, message: 'Aucun compte', ctaLabel: 'Créer un compte'))` et `SliverFillRemaining(EmptyStateWidget(icon: warning, message: 'Erreur de chargement', ctaLabel: 'Réessayer'))` — Réf: FR-009, FR-010
- [x] T-034 [P] [US2] Modifier `flutter/lib/src/features/accounts/presentation/widgets/account_list_skeleton.dart` : `List.generate(3, ...)` (était 5), cercle `AppSpacing.space8` (était `space10`) — Réf: FR-011

**Checkpoint US2** : L'écran affiche la section header, la carte surface, l'EmptyStateWidget, le skeleton 3 items. AppBar sans bouton +.

---

### US3 — Delete confirm inline (P3)

**Goal** : Bouton trash → bloc confirm inline dans la ligne, pas d'AlertDialog. State `confirmDeleteId`/`deleteError` dans `_AccountListScreenState`.

- [x] T-041 [US3] Étendre `AccountListTile` dans `account_list_tile.dart` — ajouter params optionnels : `isConfirmingDelete = false`, `deleteError`, `onRequestDelete`, `onConfirmDelete`, `onCancelDelete`, `onEdit`. Ajouter widget `_ConfirmDeleteBlock` (Container `surfaceContainerHighest`/`AppRadius.lg`, texte + erreur optionnelle + OutlinedButton Annuler + FilledButton Supprimer `expenseColor`) — Réf: FR-013, FR-014, NFR-001
- [x] T-042 [US3] Implémenter state dans `account_list_screen.dart` : champs `_confirmDeleteId`, `_deleteError` dans `_AccountListScreenState`, méthodes `_requestDelete(id)`, `_cancelDelete()`, `_confirmDelete()` (appelle `accountNotifier.delete()`, catch erreur → `_deleteError`), supprimer `_onDelete(account)` (AlertDialog), brancher les nouveaux params sur `AccountListTile` — Réf: FR-012, FR-014

**Checkpoint US3** : Clic trash → bloc confirm inline visible. Annuler → ferme. Confirmer → suppression + fermeture. Erreur API → affichée dans le bloc.

---

## Phase 4 — Polish

**Objectif** : Tests et inspection visuelle avant merge.

- [x] T-051 Lancer `flutter test flutter/test/src/features/accounts/` — tous les tests passent, adapter si `PopupMenuButton` ou `AlertDialog` étaient testés — Réf: NFR-003
- [ ] T-052 [P] Inspection visuelle US1 : ouvrir l'écran Comptes → vérifier icône 32px, sous-titre `bankName · type`, solde rouge si négatif, badges outline neutrals, 3 boutons inline trash/star/edit — Réf: SC-001, SC-002, SC-003
- [ ] T-053 [P] Inspection visuelle US2 : vérifier section header "{N} comptes" + bouton + circulaire, card `surface/radius-xl`, Divider entre items, EmptyStateWidget sur état vide, skeleton 3 items — Réf: SC-004, SC-005, SC-006, SC-008
- [ ] T-054 [P] Inspection visuelle US3 : cliquer trash → bloc inline visible (pas d'AlertDialog), cliquer Annuler → ferme, confirmer suppression → compte retiré — Réf: SC-007

**Checkpoint Final** : Rendu visuel conforme Angular. Tous les tests passent. Aucune régression.

---

## Phase 5 — Dépendances & Ordre d'exécution

### Graphe de dépendances

```
T-001 ──┐
T-002 ──┤── Checkpoint Phase 1
T-003 ──┘
        │
T-011 ←─┘── Checkpoint Phase 2 (prérequis T-02X)
        │
T-021 ←─┘ (dépend T-011 — AccountBankIcon corrigé)
T-022   (dépend T-021 — même fichier, suite logique)
T-023   (dépend T-022 — même fichier, suite logique)
        │
T-031 ←─┘ (dépend T-023 — brancher AccountListTile dans screen)
T-032   (dépend T-031 — même fichier account_list_screen)
T-033   (dépend T-031 — même fichier account_list_screen)
T-034   (parallèle T-031 — fichier distinct account_list_skeleton)
        │
T-041   (dépend T-023 — étend AccountListTile)
T-042   (dépend T-041 — brancher depuis screen)
        │
T-051   (dépend toute Phase 3)
T-052 ── T-053 ── T-054   (parallèles entre eux — écrans/flows distincts)
```

### Table US Dependencies

| User Story | Tâches | Dépend de |
|-----------|--------|-----------|
| US1 — AccountListTile | T-021, T-022, T-023 | T-011 (Phase 2) |
| US2 — AccountListScreen | T-031, T-032, T-033, T-034 | T-023 (US1 complète) + T-003 (setup) |
| US3 — Delete confirm | T-041, T-042 | T-023 (US1) + T-031 (US2) |

### Parallel Opportunities

| Groupe | Condition |
|--------|-----------|
| T-001, T-002, T-003 | Phase 1 — fichiers/greps distincts |
| T-034 et T-031/T-032/T-033 | Après US1 — fichiers distincts (skeleton vs screen) |
| T-041 et T-031 | Non recommandé — T-031 brancher le tile nécessite l'API finale de T-041 |
| T-051, T-052, T-053, T-054 | Après Phase 3 complète |

---

## Requirements → Tâches

| Requirement | Tâches |
|-------------|--------|
| FR-001 (AccountBankIcon size = conteneur, icône space8) | T-011, T-021 |
| FR-002 (nom sizeSm/medium/onSurfaceVariant) | T-021 |
| FR-003 (sous-titre bankName · type) | T-021 |
| FR-004 (solde sizeSm + expenseColor si négatif) | T-022 |
| FR-005 (badges outline size2Xs, outlineVariant) | T-022 |
| FR-006 (actions inline trash/star/edit, suppr PopupMenu) | T-023 |
| FR-007 (carte surface/radius-xl + Divider) | T-031 |
| FR-008 (section header + AddButton + AppBar clean) | T-032 |
| FR-009 (empty state EmptyStateWidget) | T-033 |
| FR-010 (error state EmptyStateWidget) | T-033 |
| FR-011 (skeleton 3 items, space8) | T-034 |
| FR-012 (trash → confirm inline, no AlertDialog, state screen) | T-042 |
| FR-013 (bloc confirm affichage) | T-041 |
| FR-014 (error dans bloc confirm) | T-041, T-042 |
| NFR-001 (API AccountListTile étendue si US3) | T-041 |
| NFR-002 (pas de nouveau widget common_widgets) | Contrainte implicite sur toutes les tâches |
| NFR-003 (tests passent) | T-051 |
| NFR-004 (pas de logique métier modifiée) | Contrainte implicite sur toutes les tâches |

---

## Tableau résumé

| Phase | Tâches | Parallélisables |
|-------|--------|----------------|
| Phase 1 — Setup | 3 | 2 (T-002, T-003) |
| Phase 2 — Fondations | 1 | 0 |
| Phase 3 — US1 (P1) | 3 | 0 |
| Phase 3 — US2 (P2) | 4 | 1 (T-034) |
| Phase 3 — US3 (P3) | 2 | 0 |
| Phase 4 — Polish | 4 | 3 (T-052, T-053, T-054) |
| **Total** | **17** | **6** |

---

## Implementation Strategy

### MVP First (US1 uniquement)

1. Phase 1 : T-001, T-002, T-003
2. Phase 2 : T-011
3. US1 : T-021, T-022, T-023
4. **STOP** : Vérifier `AccountListTile` visuellement sur l'écran Comptes

### Incremental Delivery

1. Setup + Fondations → `AccountBankIcon` corrigé
2. US1 (`AccountListTile`) → icône 32px, actions inline, styles
3. US2 (`AccountListScreen`) → carte, section header, états, skeleton
4. US3 (delete confirm inline) → UX polish optionnel
5. Polish → tests, inspection visuelle, validation commits
