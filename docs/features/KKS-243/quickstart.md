# Quickstart — KKS-243 : Phase 1 / Étape 7 — Refonte 3 écrans S Flutter

> Date : 2026-05-27
> Issue : KKS-243

---

## Pré-requis

- [x] Constitution lue (`.specify/memory/constitution.md`)
- [x] Spec validée (`spec.md` — review PASS)
- [x] Research complétée (implicite — clarify-log.md)
- [x] Plan approuvé (`plan.md`)
- [ ] Tasks générées (`tasks.md`)

## Phase 1 — Setup

```bash
cd flutter
flutter analyze     # Baseline avant modifications
```

**Vérification** : `flutter analyze` sans erreur sur les 4 fichiers cibles.

## Phase 2 — Fondations

Aucune dépendance externe à installer. Tous les widgets requis sont déjà disponibles :
- `PageHeader` — `lib/src/common_widgets/page_header.dart`
- `ConfirmDialogCustom` — `lib/src/common_widgets/confirm_dialog_custom.dart`
- `EmptyStateWidget` — `lib/src/common_widgets/empty_state_widget.dart`
- `AppTypography` — `lib/src/constants/app_typography.dart`
- `AppThemeExtension` — `lib/src/theme/app_theme_extension.dart`

### Fichiers à modifier

| Fichier | Type | FRs couverts |
|---------|------|-------------|
| `features/categories/presentation/widgets/category_list_tile.dart` | M | FR-001 |
| `features/categories/presentation/screens/category_list_screen.dart` | M | FR-002, FR-010 |
| `features/settings/presentation/data_settings_screen.dart` | M | FR-003, FR-004, FR-005, FR-010 |
| `features/exchange_rates/presentation/currency_settings_screen.dart` | M | FR-006, FR-007, FR-008, FR-010, FR-011 |

**Vérification** : lire chaque fichier, confirmer les patterns non-conformes (AppBar, AlertDialog, Card, colorScheme.surfaceContainerHighest, OutlinedButton.icon).

## Phase 3 — Implémentation User Stories

### US1 — Catégories (category_list_tile + category_list_screen)

**Fichier 1 : `category_list_tile.dart`**

1. Remplacer `colorScheme.surfaceContainerHighest` par `themeExt?.iconCircleBg ?? colorScheme.surface`
2. Importer `AppThemeExtension` si absent
3. Ajouter `final themeExt = Theme.of(context).extension<AppThemeExtension>();`

**Fichier 2 : `category_list_screen.dart`**

1. Retirer `appBar: AppBar(...)` du `Scaffold`
2. Wrapper le body dans `Column(children: [PageHeader(...), Expanded(...)])`
3. `PageHeader(title: 'Catégories', onBack: () => context.pop(), icon: PhosphorIcon(...))`
4. Remplacer l'état vide ad hoc par `EmptyStateWidget(icon: PhosphorIconsRegular.tag, message: ...)`
5. Remplacer l'état erreur ad hoc par `EmptyStateWidget(icon: PhosphorIconsRegular.warning, message: ..., ctaLabel: 'Réessayer', onCtaTap: () => ref.read(categoryNotifierProvider.notifier).refresh())`

**Test US1** :
```bash
# Flutter sur simulateur
# → Réglages → Catégories : vérifier PageHeader (back + titre + icône)
# → Supprimer toutes les catégories : vérifier EmptyStateWidget
# → Couper le réseau (mode serveur) : vérifier état erreur avec bouton Réessayer
```

---

### US2 — Settings données (data_settings_screen)

1. Retirer `appBar: AppBar(...)` du `Scaffold`
2. Ajouter `PageHeader(title: 'Source de données', onBack: () => context.pop())`
3. Remplacer `theme.textTheme.titleSmall?.copyWith(...)` par style manuel : `sizeXs / medium / labelLetterSpacingForSize12 / onSurfaceVariant`
4. Remplacer `FontWeight.w600` par `AppTypography.semiBold`
5. Remplacer `AlertDialog` par `ConfirmDialogCustom.show(...)` avec `await` + `?? false`

**Test US2** :
```bash
# → Réglages → Données : vérifier PageHeader + labels uppercase
# → Changer de mode : vérifier que ConfirmDialogCustom apparaît (pas AlertDialog natif)
# → Annuler : vérifier que le mode ne change pas
```

---

### US3 — Devises & Taux (currency_settings_screen)

1. Retirer `appBar: AppBar(...)` du `Scaffold`
2. Ajouter `PageHeader(title: 'Devises & Taux', onBack: () => context.pop())`
3. Remplacer labels `theme.textTheme.titleSmall` par style uppercase (même pattern que US2)
4. Remplacer `Card(color: colorScheme.surfaceContainerHighest)` par `Container(decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.xl)))`
5. Ajouter `Divider(height: 1, color: colorScheme.outline)` entre les items de taux (sauf dernier)
6. Créer widget privé `_AddButton` (GestureDetector + Container 28px circle + PhosphorIcon.plus) pour les headers de section
7. Remplacer `OutlinedButton.icon` (×2) par `_AddButton`
8. Remplacer `AlertDialog` (×2 : suppression taux + retrait devise) par `ConfirmDialogCustom.show(...)`

**Test US3** :
```bash
# → Réglages → Comptes & Devises → Devises & Taux
# → Vérifier : PageHeader, labels uppercase, taux en liste (pas de cards)
# → Ajouter un taux : vérifier bouton + dans le header de section
# → Supprimer un taux : vérifier ConfirmDialogCustom.danger
# → Retirer une devise : vérifier ConfirmDialogCustom.danger
```

---

## Phase 4 — Polish

1. Vérifier `flutter analyze` sans warning :
   ```bash
   cd flutter && flutter analyze
   ```
2. Vérifier zéro token non-conforme dans les 4 fichiers :
   ```bash
   grep -n "surfaceContainerHighest\|titleSmall\|AlertDialog\|OutlinedButton\|FontWeight\.w[0-9]" \
     lib/src/features/categories/presentation/widgets/category_list_tile.dart \
     lib/src/features/categories/presentation/screens/category_list_screen.dart \
     lib/src/features/settings/presentation/data_settings_screen.dart \
     lib/src/features/exchange_rates/presentation/currency_settings_screen.dart
   ```
   → Résultat attendu : aucune occurrence.
3. Vérifier présence `PageHeader` et absence `AppBar(` :
   ```bash
   grep -n "AppBar(" \
     lib/src/features/categories/presentation/screens/category_list_screen.dart \
     lib/src/features/settings/presentation/data_settings_screen.dart \
     lib/src/features/exchange_rates/presentation/currency_settings_screen.dart
   ```
   → Résultat attendu : aucune occurrence.

## Commandes utiles

| Action | Commande |
|--------|----------|
| Analyse statique | `cd flutter && flutter analyze` |
| Tests widget | `cd flutter && flutter test test/src/features/` |
| Lancer l'app | `cd flutter && flutter run` |
| Build runner (si besoin) | `cd flutter && dart run build_runner build --delete-conflicting-outputs` |

## Checklist finale (Success Criteria spec.md)

- [ ] SC-001 : `flutter analyze` sans warning
- [ ] SC-002 : zéro `colorScheme.surfaceContainerHighest`, `colorScheme.onSurface`, `theme.textTheme.titleSmall` dans les fichiers modifiés
- [ ] SC-003 : zéro `AlertDialog` dans les 3 fichiers modifiés
- [ ] SC-004 : zéro `Card(` dans `currency_settings_screen.dart`
- [ ] SC-005 : `EmptyStateWidget` utilisé pour états vide ET erreur dans `CategoryListScreen`
- [ ] SC-006 : parcours utilisateur complet fonctionnel sur les 3 écrans
- [ ] SC-007 : `PageHeader` présent dans les 3 écrans, zéro `AppBar(`
- [ ] SC-008 : zéro `OutlinedButton` pour les actions "Ajouter" dans `currency_settings_screen.dart`
