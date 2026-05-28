# Tasks — KKS-243 : Phase 1 / Étape 7 — Refonte 3 écrans S Flutter

> Date : 2026-05-27
> Issue : KKS-243
> Spec : [spec.md](./spec.md)
> Plan : [plan.md](./plan.md)

---

## Phase 1 : Setup

- [x] [T-001] [P1] Baseline — `flutter analyze` sur les 4 fichiers cibles + grep des patterns non-conformes (`surfaceContainerHighest`, `AlertDialog`, `AppBar(`, `OutlinedButton`, `titleSmall`, `FontWeight\.w`) pour mesurer l'état initial — Réf: NFR-001

**Checkpoint** : sortie baseline documentée (nombre d'occurrences par pattern). `flutter analyze` sans erreur préexistante dans les fichiers cibles.

---

## Phase 2 : Fondations (bloquantes)

- [x] [T-010] [P1] Vérifier les signatures API des widgets communs disponibles : `PageHeader(title, onBack, icon)`, `EmptyStateWidget(icon, message, ctaLabel, onCtaTap)`, `ConfirmDialogCustom.show(context, icon, title, message, confirmLabel, variant)` — s'assurer que les imports `page_header.dart`, `empty_state_widget.dart`, `confirm_dialog_custom.dart` et `app_typography.dart` sont accessibles — Réf: FR-010, FR-002, FR-005, FR-008

**Checkpoint** : les 4 fichiers de widgets communs existent et leurs signatures correspondent au plan. Aucun `build_runner` requis (aucun modèle Freezed touché — NFR-003).

---

## Phase 3 : User Stories (par priorité)

### P1 — Critiques

#### US1 — Catégories (category_list_tile.dart + category_list_screen.dart)

- [x] [T-021] [P] [P1] [US1] CategoryListTile — remplacer `colorScheme.surfaceContainerHighest` (fond icône fallback) par `themeExt?.iconCircleBg ?? colorScheme.surface` ; importer `AppThemeExtension` si absent — Réf: FR-001
- [x] [T-022] [P] [P1] [US1] CategoryListScreen — remplacer `appBar: AppBar(...)` par `PageHeader(title: 'Catégories', onBack: () => context.pop(), icon: PhosphorIcon(PhosphorIconsRegular.tag, size: 16))` encapsulé dans `SafeArea > Column > Padding(horizontal: AppSpacing.space4)` + `Expanded > RefreshIndicator > CustomScrollView` — conserver le FAB — Réf: FR-010
- [x] [T-023] [P1] [US1] CategoryListScreen — remplacer les 2 états ad hoc (`SliverFillRemaining` avec Column+Icon+Text+bouton) par `EmptyStateWidget` : état vide `(icon: tag, message: l10n.categoriesEmpty)`, état erreur `(icon: warning, message: l10n.categoryErrorLoad, ctaLabel: Réessayer, onCtaTap: refresh)` — Réf: FR-002

#### US2 — Settings données (data_settings_screen.dart)

- [x] [T-024] [P] [P1] [US2] DataSettingsScreen — retirer `appBar: AppBar(title: Text('Données'))` ; ajouter `PageHeader(title: 'Données', onBack: () => context.pop(), icon: PhosphorIcon(PhosphorIconsRegular.database, size: 16))` en premier enfant du `ListView` dans `SafeArea` — Réf: FR-010
- [x] [T-025] [P] [P1] [US2] DataSettingsScreen — remplacer les 2 labels `theme.textTheme.titleSmall?.copyWith(color: ..., fontWeight: FontWeight.w600)` ('Source de données', 'URL du serveur') par style uppercase : `TextStyle(fontSize: AppTypography.sizeXs, fontWeight: AppTypography.medium, letterSpacing: AppTypography.labelLetterSpacingForSize12, color: colorScheme.onSurfaceVariant)` + passer les textes en majuscules — Réf: FR-003, FR-004
- [x] [T-026] [P] [P1] [US2] DataSettingsScreen — remplacer `showDialog<bool>(...AlertDialog...)` dans `_onModeChanged` par `await ConfirmDialogCustom.show(context: context, icon: PhosphorIconsRegular.swapHorizontal, title: 'Changer de source ?', message: '...', confirmLabel: 'Confirmer', variant: ConfirmVariant.primary) ?? false` — Réf: FR-005

#### US3 — Devises & Taux (currency_settings_screen.dart)

- [x] [T-027] [P] [P1] [US3] CurrencySettingsScreen — retirer `appBar: AppBar(title: Text('Devises & Taux'))` ; ajouter `PageHeader(title: 'Devises & Taux', onBack: () => context.pop(), icon: PhosphorIcon(PhosphorIconsRegular.bank, size: 16))` en premier item du `ListView` dans `SafeArea` — Réf: FR-010
- [x] [T-028] [P1] [US3] CurrencySettingsScreen — remplacer les 3 labels `theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary)` ('Mes devises', 'Taux de conversion', 'Calculateur') par style uppercase identique à T-025 (sizeXs / medium / labelLetterSpacingForSize12 / onSurfaceVariant) + passer en majuscules — Réf: FR-007
- [x] [T-029] [P1] [US3] CurrencySettingsScreen — créer widget privé `_AddButton` (GestureDetector + Container 28×28 circle + `Border.all(colorScheme.outline)` + `PhosphorIcon(plus, 16, onSurfaceVariant)`) ; restructurer les headers "Mes devises" et "Taux de conversion" en `Row(mainAxisAlignment: spaceBetween, [Text label, _AddButton])` ; retirer les `OutlinedButton.icon` en pied de section — Réf: FR-011
- [x] [T-030] [P1] [US3] CurrencySettingsScreen — rewrite `_RateTile` : remplacer `Card(color: surfaceContainerHighest)` par `Padding` + `Row` simple (`Expanded` texte paire devises, texte valeur tabularFigures, IconButton edit, IconButton delete:error) ; wrapper la liste taux dans `Container(decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.xl)))` + `Column` avec `Divider(height: 1, color: colorScheme.outline)` entre items — Réf: FR-006
- [x] [T-031] [P1] [US3] CurrencySettingsScreen — remplacer les 2 `AlertDialog` natifs par `ConfirmDialogCustom.show` : suppression taux `(icon: trash, title: 'BASE → TARGET', message: 'Ce taux sera définitivement supprimé.', confirmLabel: 'Supprimer', variant: danger)` ; retrait devise `(icon: warning, title: 'Retirer CURRENCY ?', message: contextuel hasAccounts, confirmLabel: 'Retirer', variant: danger)` — Réf: FR-008

**Checkpoint** : 11 FR couverts. `flutter analyze` sans warning. Navigation fonctionnelle depuis le hub vers les 3 écrans.

---

## Phase 4 : Polish

- [x] [T-050] [P1] `flutter analyze` sur l'ensemble du projet — zéro warning dans les 4 fichiers modifiés — Réf: SC-001, NFR-001
- [x] [T-051] [P1] Grep contrats de conformité — vérifier zéro occurrence de `surfaceContainerHighest`, `theme.textTheme.titleSmall`, `AlertDialog`, `Card(`, `OutlinedButton`, `AppBar(`, `FontWeight\.w[0-9]` dans les 4 fichiers modifiés — Réf: SC-002, SC-003, SC-004, SC-007, SC-008
- [x] [T-052] [P1] Vérifier SC-005 — `EmptyStateWidget` présent pour les états vide ET erreur dans `category_list_screen.dart` (grep `EmptyStateWidget`, confirmer 2 occurrences)
- [ ] [T-053] [P1] Parcours utilisateur manuel sur les 3 écrans : navigation, chargement, CRUD (créer/modifier/supprimer catégorie, changer mode données, ajouter/supprimer taux, retirer devise), `ConfirmDialogCustom` sur chaque action destructive — Réf: SC-006, NFR-002

**Checkpoint** : SC-001 à SC-008 tous verts. Aucune régression fonctionnelle détectée.

---

## Phase 5 : Dependencies & Execution Order

### Graphe de dépendances

```
T-001 → T-010 → T-021 [P] ─────────────────────────────→ T-023
                 T-022 [P] → T-023
                 T-024 [P] → T-025 [P] → T-026 [P]
                 T-027 [P] → T-028 → T-029 → T-030 → T-031
                 └─────────────────────────────────────────────→ T-050 → T-051 → T-052 → T-053
```

**Règle** : les groupes US1/US2/US3 sont indépendants (fichiers différents) et peuvent être exécutés en parallèle. Au sein de chaque groupe, l'ordre est contraint (même fichier).

### US Dependencies

| User Story | Tâches | Dépend de |
|------------|--------|-----------|
| US1 — Catégories | T-021, T-022, T-023 | T-010 |
| US2 — Données | T-024, T-025, T-026 | T-010 |
| US3 — Devises | T-027, T-028, T-029, T-030, T-031 | T-010 |
| Polish | T-050, T-051, T-052, T-053 | T-023 + T-026 + T-031 |

### Parallel Opportunities

| Groupe | Tâches parallélisables | Condition |
|--------|----------------------|-----------|
| G1 — Entrées | T-021, T-024, T-027 | T-010 complété |
| G2 — Suites | T-022, T-025, T-028 | T-021, T-024, T-027 respectivement |
| G3 — Fin écrans | T-023, T-026, T-029 | Tâches G2 respectivement |
| G4 — Currency suite | T-030, T-031 | T-029 complété (même fichier) |

---

## Implementation Strategy

### MVP First

- **MVP** (1 fichier, livraison immédiate) : T-001 + T-010 + T-021 + T-022 + T-023 — `CategoryListTile` + `CategoryListScreen` conformes, l'écran le plus fréquemment visité
- **Itération 2** : T-024 + T-025 + T-026 — `DataSettingsScreen` conforme
- **Itération 3** : T-027 → T-031 — `CurrencySettingsScreen` conforme (le plus complexe)
- **Polish** : T-050 → T-053 — Validation finale

### Incremental Delivery

| Livraison | Tâches | Valeur délivrée |
|-----------|--------|----------------|
| L1 — Catégories | T-001, T-010, T-021, T-022, T-023 | Écran catégories conforme v5 : PageHeader + EmptyStateWidget + token iconCircleBg |
| L2 — Données | T-024, T-025, T-026 | DataSettings conforme : PageHeader + labels uppercase + ConfirmDialogCustom |
| L3 — Devises | T-027, T-028, T-029, T-030, T-031 | CurrencySettings conforme : PageHeader + labels + liste sans Card + boutons + ConfirmDialogCustom |
| L4 — Polish | T-050, T-051, T-052, T-053 | Validation complète — 8 SC verts, prêt review-impl |

---

## Mapping Requirements → Tâches

| Requirement | Description | Tâches |
|-------------|-------------|--------|
| FR-001 | CategoryListTile — tokens iconCircleBg | T-021 |
| FR-002 | CategoryListScreen — EmptyStateWidget (vide + erreur) | T-023 |
| FR-003 | DataSettingsScreen — labels AppTypography | T-025 |
| FR-004 | DataSettingsScreen — FontWeight.w600 → AppTypography.semiBold | T-025 |
| FR-005 | DataSettingsScreen — AlertDialog → ConfirmDialogCustom | T-026 |
| FR-006 | CurrencySettingsScreen — Card → liste surface-default+border | T-030 |
| FR-007 | CurrencySettingsScreen — labels AppTypography | T-028 |
| FR-008 | CurrencySettingsScreen — AlertDialog ×2 → ConfirmDialogCustom | T-031 |
| FR-009 | RateCalculator — conservé sans modification | (hors scope — aucune tâche) |
| FR-010 | PageHeader dans les 3 écrans | T-022, T-024, T-027 |
| FR-011 | OutlinedButton → bouton + circulaire 28px | T-029 |

---

## Résumé

| Phase | Total | P1 | P2 | P3 | Parallélisables |
|-------|-------|----|----|----|-----------------|
| Setup | 1 | 1 | 0 | 0 | 0 |
| Fondations | 1 | 1 | 0 | 0 | 0 |
| User Stories P1 | 11 | 11 | 0 | 0 | 7 |
| Polish | 4 | 4 | 0 | 0 | 0 |
| **Total** | **17** | **17** | **0** | **0** | **7** |
