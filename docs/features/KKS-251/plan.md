# Implementation Plan: Récurrences liste Flutter (alignement DESIGN.md v5)

**Issue**: KKS-251 | **Branch**: `develop` | **Date**: 2026-05-21  
**Spec**: [spec.md](spec.md) | **Clarify**: [clarify-log.md](clarify-log.md) | **Research**: [research.md](research.md)

---

## Summary

Refonte de `RecurringListScreen`, `RecurringListItem` et `RecurringListSkeleton` pour alignement sur DESIGN.md v5 / Angular (source de vérité). Trois livrables principaux : (1) `RecurringListItem` redesigné — icône cercle 36px, sous-titre `fréquence · date_relative`, montant coloré, interface réduite à `onTap` avec suppression de `Dismissible`/`_StatusBadge`/`_SwipeBackground` ; (2) écran restructuré en `CustomScrollView` avec groupes visuels par statut + carte monthly summary ; (3) action sheet redessinée (résumé + 3 boutons stylisés, sans `AlertDialog`). Deux ajouts utilitaires : `validateAll()` dans le notifier et `formatCompact()` dans `RelativeDateFormatter`. Aucune modification des couches data/domain.

---

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27  
**Primary Dependencies**: flutter_riverpod, phosphor_flutter `^2.1.0`, shimmer `^3.0.0`, intl, AppTypography, AppSpacing, AppRadius, AppThemeExtension (tokens v5)  
**Storage**: N/A — aucun schéma Drift modifié, aucun endpoint REST modifié  
**Testing**: flutter_test + Mockito (tests existants à adapter + nouveaux tests)  
**Target Platform**: iOS + Android (Trajectoire B — Standalone Commercial)  
**Project Type**: Mobile app — refonte visuelle + UX  
**Performance Goals**: N/A — écran avec < 30 items typiquement  
**Constraints**: `ListState<T>` Freezed générique ne doit pas être modifié (breaking change interdit)

---

## Constitution Check

| Principe | Applicable | Statut | Notes |
|----------|-----------|--------|-------|
| I — API-First / Local-First | Non | ✅ N/A | Aucun endpoint REST ni schéma Drift modifié |
| II — Sécurité | Non | ✅ N/A | Pas de routes, pas de secrets, pas de données utilisateur cross-user |
| III — Simplicité & YAGNI | Oui | ✅ PASS | Simplification nette : `Dismissible`, `AlertDialog`, `_StatusBadge`, `_SwipeBackground` supprimés. `validateAll()` (~10L) et `formatCompact()` (~15L) — minimal |
| IV — Mobile-First UX | Oui | ✅ PASS | Tap > LongPress (plus découvrable). Action sheet accessible directement. "Tout payé" réduit le nombre d'interactions |
| V — Testabilité | Oui | ✅ PASS | NFR-004 : tests existants adaptés + nouveaux tests `_StatusGroupHeader`, `_MonthlySummaryCard`, `validateAll` |
| VI — Observabilité | Oui | ✅ PASS | Aucun `print()` introduit |
| VII — Two Trajectories | Non | ✅ N/A | Trajectoire B uniquement — pas d'impact API REST ni sync |

**Résultat : PASS — aucune gate violée.**

---

## Architecture — Fichiers impactés

### Modifications (M)

| Fichier | Nature | FR/NFR couverts |
|---------|--------|----------------|
| `flutter/lib/src/features/recurring/presentation/recurring_list_screen.dart` | Refonte complète — CustomScrollView, groupes, monthly summary, action sheet | FR-002, FR-003 (via onTap), FR-006 → FR-015, NFR-005, NFR-006 |
| `flutter/lib/src/features/recurring/presentation/widgets/recurring_list_item.dart` | Interface `{onTap}`, icône cercle 36px, sous-titre, montant coloré, suppression Dismissible/_StatusBadge/_SwipeBackground | FR-001 → FR-005 |
| `flutter/lib/src/features/recurring/presentation/widgets/recurring_list_skeleton.dart` | 6 → 5 items, icône carré → cercle 36px, suppression badge-round côté droit | FR-016 |
| `flutter/lib/src/features/recurring/application/recurring_list_notifier.dart` | Ajout `validateAll(List<String> ids)` | NFR-001, NFR-006 |
| `flutter/lib/src/utils/relative_date_formatter.dart` | Ajout `formatCompact(DateTime)` | NFR-002, FR-003, FR-011 |
| `flutter/lib/src/localization/app_fr.arb` | 3 mises à jour valeurs + 4 nouvelles clés | FR-006, FR-009, FR-011, NFR-001 |
| `flutter/lib/src/localization/app_localizations_fr.dart` | Régénéré via `flutter gen-l10n` | — |
| `flutter/lib/src/localization/app_localizations.dart` | Régénéré via `flutter gen-l10n` | — |
| `flutter/test/src/features/recurring/presentation/recurring_list_screen_test.dart` | Adaptation tests existants + nouveaux | NFR-004 |
| `flutter/test/src/features/recurring/application/recurring_list_notifier_test.dart` | Ajout tests `validateAll` | NFR-004 |

### Aucun fichier à créer

---

## Approche détaillée par composant

### 1. `RelativeDateFormatter.formatCompact()` — NFR-002

**FR couverts** : NFR-002, FR-003, FR-011

Ajout de la méthode statique `formatCompact(DateTime value, {DateTime? now})` dans la classe existante. Réimplémentation indépendante (6 cas, ~15 lignes) — pas de délégation à `format()` (casing incompatible, cf. IT-001 research.md).

```dart
static String formatCompact(DateTime value, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final targetDate = DateTime(value.year, value.month, value.day);
  final diffDays = todayDate.difference(targetDate).inDays;

  if (diffDays == 0) return "aujourd'hui";
  if (diffDays == 1) return 'hier';
  if (diffDays == -1) return 'demain';
  if (diffDays >= 2 && diffDays <= 7) return 'il y a ${diffDays} j.';
  if (diffDays < -1 && diffDays >= -30) return 'dans ${-diffDays} j.';
  return DateFormat('dd MMM', 'fr').format(value);
}
```

> Passé > 7j → fallback `DateFormat('dd MMM', 'fr')` (dates très en retard affichées comme date courte). Import `intl` déjà présent dans le fichier.

---

### 2. `RecurringListNotifier.validateAll()` — NFR-001, NFR-006

**FR couverts** : NFR-001, NFR-006, FR-009

Ajout dans la classe existante — appels séquentiels à `validate(id)` dans un `try/catch` global (arrêt au premier échec, aligne sur Angular). L'id fictif `'__all__'` est ajouté à `mutatingIds` pour désactiver le bouton "Tout payé" pendant l'opération.

```dart
Future<void> validateAll(List<String> ids) async {
  if (ids.isEmpty) return;
  state = state.copyWith(
    mutatingIds: {...state.mutatingIds, '__all__'},
    error: null,
  );
  try {
    for (final id in ids) {
      await validate(id);
    }
  } on Exception {
    // validate() met déjà l'erreur dans state.error — pas de redondance
  } finally {
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds}..remove('__all__'),
    );
  }
}
```

> Note : `validate(id)` gère déjà `mutatingIds` par id. `'__all__'` s'ajoute *en parallèle* pour identifier l'opération globale. `finally` garantit le nettoyage même en cas d'exception.

---

### 3. `RecurringListItem` — US1

**FR couverts** : FR-001 → FR-005

#### 3.1 Suppressions

- `Dismissible` + ses `background`/`secondaryBackground`/`confirmDismiss` (FR-002, FR-004)
- `GestureDetector.onLongPress` → remplacé par `InkWell.onTap` sur la ligne entière (FR-002)
- `_StatusBadge` (FR-005)
- `_SwipeBackground` (FR-004, FR-005)
- `_showActionsSheet()` (NFR-005 — migré dans `RecurringListScreen`)
- Paramètres `onValidate`, `onSkip`, `onDeactivate` → remplacés par `onTap: VoidCallback` (NFR-005)
- Import `AppColors` si devenu inutile

#### 3.2 Nouvelle interface

```dart
class RecurringListItem extends StatelessWidget {
  const RecurringListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  final RecurringTransaction item;
  final VoidCallback onTap;
```

> `ConsumerWidget` → `StatelessWidget` (plus d'accès direct au provider, `mutatingIds` géré dans l'action sheet screen-level).

#### 3.3 `_CategoryIcon` — cercle 36px (FR-001)

```dart
class _CategoryIcon extends StatelessWidget {
  // Avant : width: 40, borderRadius: AppRadius.md (carré)
  // Après :
  Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
      color: _parseColorWithAlpha(color) ??
          Theme.of(context).extension<AppThemeExtension>()!.iconCircleBg,
      shape: BoxShape.circle,  // ou borderRadius: BorderRadius.circular(AppRadius.round)
    ),
    alignment: Alignment.center,
    child: Text(icon ?? '🔄', style: const TextStyle(fontSize: 18)),
  )
```

Couleur fond : `_parseColorWithAlpha(hex)` → couleur catégorie avec alpha `0x26` (si hex disponible), sinon `AppThemeExtension.iconCircleBg`.

```dart
Color? _parseColorWithAlpha(String? hex) {
  if (hex == null) return null;
  final clean = hex.replaceFirst('#', '');
  final value = int.tryParse(clean, radix: 16);
  if (value == null) return null;
  return Color((0x26 << 24) | (value & 0xFFFFFF));
}
```

#### 3.4 Sous-titre `fréquence · date_relative` (FR-003)

```dart
Text(
  '${_frequencyLabel(l10n)} · ${RelativeDateFormatter.formatCompact(item.nextOccurrence)}',
  style: TextStyle(
    fontSize: AppTypography.sizeXs,
    color: colorScheme.onSurfaceVariant,
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)
```

#### 3.5 Montant coloré (FR-004)

```dart
final themeExt = Theme.of(context).extension<AppThemeExtension>()!;
final amountColor = item.type == TransactionType.depense
    ? themeExt.expenseColor
    : themeExt.incomeColor;

Text(
  AmountFormatter.format(item.montant, currency: item.accountCurrency ?? Currency.eur),
  style: TextStyle(
    fontSize: AppTypography.sizeSm,
    fontWeight: AppTypography.semiBold,
    color: amountColor,
  ),
)
```

#### 3.6 Layout final

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final colorScheme = Theme.of(context).colorScheme;
  final themeExt = Theme.of(context).extension<AppThemeExtension>()!;

  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          _CategoryIcon(icon: item.categoryIcon, color: item.categoryColor),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.libelle,
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    fontWeight: AppTypography.medium,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${_frequencyLabel(l10n)} · '
                  '${RelativeDateFormatter.formatCompact(item.nextOccurrence)}',
                  style: TextStyle(
                    fontSize: AppTypography.sizeXs,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            AmountFormatter.format(
                item.montant, currency: item.accountCurrency ?? Currency.eur),
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.semiBold,
              color: item.type == TransactionType.depense
                  ? themeExt.expenseColor
                  : themeExt.incomeColor,
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

### 4. `RecurringListSkeleton` — FR-016

**FR couverts** : FR-016

Deux modifications :

1. `itemCount: 6` → `itemCount: 5`
2. Dans `_RecurringSkeletonItem` :
   - Icône : `width: 40, borderRadius: AppRadius.md` → `width: 36, height: 36, shape: BoxShape.circle`
   - Côté droit : supprimer le placeholder badge-round (60px `AppRadius.round`) + `SizedBox(height: space2)`. Conserver uniquement le placeholder montant : `height: 12, width: 80, borderRadius: AppRadius.sm`.

```dart
// Avant (côté droit) :
Column(children: [
  Container(height: 20, width: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.round))),
  SizedBox(height: AppSpacing.space2),
  Container(height: 12, width: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.sm))),
])

// Après :
Container(
  height: 12, width: 80,
  decoration: BoxDecoration(
    color: baseColor,
    borderRadius: BorderRadius.circular(AppRadius.sm),
  ),
)
```

---

### 5. L10n — IT-003

**FR couverts** : FR-006, FR-009, FR-011, NFR-001

#### 5.1 Mises à jour `app_fr.arb`

```json
"recurringValidate": "Marquer comme payée",
"recurringSkip": "Passer cette occurrence",
"recurringDeactivate": "Désactiver la récurrence",
```

#### 5.2 Nouvelles clés `app_fr.arb`

```json
"recurringValidateAll": "Tout payé",
"recurringNextOccurrence": "Prochaine : {date}",
"@recurringNextOccurrence": {
  "placeholders": { "date": { "type": "String" } }
},
"recurringMonthlySummaryTitle": "BILAN MENSUEL",
"recurringChargesCount": "{count} CHARGES",
"@recurringChargesCount": {
  "placeholders": { "count": { "type": "int" } }
}
```

#### 5.3 Régénération

```bash
cd flutter && flutter gen-l10n
```

---

### 6. `RecurringListScreen` — US1 + US2 + US3

**FR couverts** : FR-002, FR-006 → FR-015

C'est le composant le plus impacté. Refonte complète en 4 sections.

#### 6.1 Imports ajoutés

```dart
import 'package:k_budget/src/common_widgets/empty_state_widget.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/currency_converter.dart';
import 'package:k_budget/src/utils/relative_date_formatter.dart';
```

#### 6.2 `build()` — lecture des providers

```dart
@override
Widget build(BuildContext context) {
  final state = ref.watch(recurringListNotifierProvider);
  final exchangeRateState = ref.watch(exchangeRateListProvider);
  final dashboardState = ref.watch(dashboardNotifierProvider);
  final l10n = AppLocalizations.of(context)!;
  final colorScheme = Theme.of(context).colorScheme;
  final themeExt = Theme.of(context).extension<AppThemeExtension>()!;

  final primaryCurrency = dashboardState.currencies.isNotEmpty
      ? dashboardState.currencies.first
      : null;

  return Scaffold(
    appBar: AppBar(title: Text(l10n.recurringTitle)),
    body: _buildBody(context, state, l10n, colorScheme, themeExt,
        exchangeRates: exchangeRateState.items,
        primaryCurrency: primaryCurrency),
  );
}
```

#### 6.3 `_buildBody()` — états loading/error/empty/data

```dart
Widget _buildBody(...) {
  // Loading
  if (state.isLoading && state.items.isEmpty) {
    return const RecurringListSkeleton();
  }

  // Error (FR-015)
  if (state.error != null && state.items.isEmpty) {
    return EmptyStateWidget(
      icon: PhosphorIconsRegular.warning,
      message: l10n.errorGeneric,
      ctaLabel: l10n.retry,
      onCtaTap: () => ref.read(recurringListNotifierProvider.notifier).loadItems(),
    );
  }

  // Empty (FR-014)
  if (state.items.isEmpty) {
    return EmptyStateWidget(
      icon: PhosphorIconsRegular.repeat,
      message: l10n.recurringEmpty,
    );
  }

  // Data
  return RefreshIndicator(
    onRefresh: () => ref.read(recurringListNotifierProvider.notifier).loadItems(),
    child: CustomScrollView(
      slivers: [
        ..._buildContent(state, l10n, colorScheme, themeExt,
            exchangeRates: exchangeRates, primaryCurrency: primaryCurrency),
      ],
    ),
  );
}
```

#### 6.4 `_buildContent()` — monthly summary + groupes (FR-010, FR-006 → FR-009)

```dart
List<Widget> _buildContent(
  ListState<RecurringTransaction> state,
  AppLocalizations l10n,
  ColorScheme colorScheme,
  AppThemeExtension themeExt, {
  List<ExchangeRate> exchangeRates = const [],
  Currency? primaryCurrency,
}) {
  // Groupes par statut (items déjà triés par le notifier)
  final overdue = state.items.where((i) => i.status == RecurringStatus.overdue).toList();
  final today  = state.items.where((i) => i.status == RecurringStatus.today).toList();
  final upcoming = state.items.where((i) => i.status == RecurringStatus.upcoming).toList();

  return [
    // Monthly summary card (FR-010)
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, 0),
        child: _MonthlySummaryCard(
          items: state.items,
          exchangeRates: exchangeRates,
          primaryCurrency: primaryCurrency,
          colorScheme: colorScheme,
          themeExt: themeExt,
          l10n: l10n,
        ),
      ),
    ),

    // Groupe EN RETARD (FR-006, FR-007, FR-008, FR-009)
    if (overdue.isNotEmpty)
      SliverToBoxAdapter(
        child: _StatusGroupSection(
          label: l10n.recurringOverdue.toUpperCase(),
          labelColor: themeExt.expenseColor,
          items: overdue,
          colorScheme: colorScheme,
          showValidateAll: true,
          isValidatingAll: state.mutatingIds.contains('__all__'),
          onValidateAll: () {
            final ids = overdue.map((i) => i.id).toList();
            _handleValidateAll(context, ids, l10n);
          },
          onItemTap: (item) => _showActionSheet(context, item, l10n, themeExt),
        ),
      ),

    // Groupe AUJOURD'HUI (FR-006, FR-007, FR-008)
    if (today.isNotEmpty)
      SliverToBoxAdapter(
        child: _StatusGroupSection(
          label: l10n.recurringToday.toUpperCase(),
          labelColor: colorScheme.primary,
          items: today,
          colorScheme: colorScheme,
          onItemTap: (item) => _showActionSheet(context, item, l10n, themeExt),
        ),
      ),

    // Groupe À VENIR (FR-006, FR-007, FR-008)
    if (upcoming.isNotEmpty)
      SliverToBoxAdapter(
        child: _StatusGroupSection(
          label: l10n.recurringUpcoming.toUpperCase(),
          labelColor: colorScheme.onSurfaceVariant,
          items: upcoming,
          colorScheme: colorScheme,
          onItemTap: (item) => _showActionSheet(context, item, l10n, themeExt),
        ),
      ),

    const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space12 * 2)),
  ];
}
```

#### 6.5 `_StatusGroupSection` — widget privé (FR-006 → FR-009)

```dart
class _StatusGroupSection extends StatelessWidget {
  const _StatusGroupSection({
    required this.label,
    required this.labelColor,
    required this.items,
    required this.colorScheme,
    this.showValidateAll = false,
    this.isValidatingAll = false,
    this.onValidateAll,
    required this.onItemTap,
  });

  final String label;
  final Color labelColor;
  final List<RecurringTransaction> items;
  final ColorScheme colorScheme;
  final bool showValidateAll;
  final bool isValidatingAll;
  final VoidCallback? onValidateAll;
  final void Function(RecurringTransaction) onItemTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header de groupe (FR-006, FR-007)
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  fontWeight: AppTypography.semiBold,
                  color: labelColor,
                  letterSpacing: AppTypography.labelLetterSpacingForSize12,
                ),
              ),
              const Spacer(),
              // Bouton "Tout payé" uniquement sur EN RETARD (FR-009)
              if (showValidateAll)
                SizedBox(
                  height: 28,
                  child: FilledButton(
                    onPressed: isValidatingAll ? null : onValidateAll,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
                      minimumSize: Size.zero,
                      shape: StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: AppTypography.sizeXs,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    child: isValidatingAll
                        ? const SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5))
                        : Text(l10n.recurringValidateAll),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          // Carte groupe (FR-008)
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  RecurringListItem(
                    item: items[i],
                    onTap: () => onItemTap(items[i]),
                  ),
                  if (i < items.length - 1)
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outlineVariant),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 6.6 `_MonthlySummaryCard` — widget privé (FR-010)

Calcul : pour chaque item, normaliser le montant en mensuel (`hebdo × 4.33`, `annuel ÷ 12`), convertir en `primaryCurrency` via `CurrencyConverter` (fallback nominal si taux absent). Net = recettes - dépenses. `totalExpenses` = somme des dépenses. `expenseCount` = count des dépenses.

```dart
class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.items,
    required this.exchangeRates,
    required this.primaryCurrency,
    required this.colorScheme,
    required this.themeExt,
    required this.l10n,
  });

  // ...fields...

  double _toMonthly(RecurringTransaction item) {
    return switch (item.frequency) {
      Frequency.hebdomadaire => item.montant * 4.33,
      Frequency.mensuel      => item.montant,
      Frequency.annuel       => item.montant / 12,
    };
  }

  double _toPrimary(double monthly, Currency? fromCurrency) {
    if (primaryCurrency == null || fromCurrency == null) return monthly;
    if (fromCurrency == primaryCurrency) return monthly;
    return CurrencyConverter.convert(
          amount: monthly,
          fromCurrency: fromCurrency,
          toCurrency: primaryCurrency!,
          rates: exchangeRates,
        ) ??
        monthly; // fallback valeur nominale
  }

  @override
  Widget build(BuildContext context) {
    double net = 0;
    double totalExpenses = 0;
    int expenseCount = 0;

    for (final item in items) {
      final monthly = _toMonthly(item);
      final converted = _toPrimary(monthly, item.accountCurrency);
      if (item.type == TransactionType.depense) {
        totalExpenses += converted;
        expenseCount++;
        net -= converted;
      } else {
        net += converted;
      }
    }

    final displayCurrency = primaryCurrency ?? Currency.eur;
    final netFormatted = AmountFormatter.format(net.abs(), currency: displayCurrency);
    final expensesFormatted = AmountFormatter.format(totalExpenses, currency: displayCurrency);
    final netColor = net >= 0 ? themeExt.incomeColor : themeExt.expenseColor;
    final netSign = net >= 0 ? '+' : '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Colonne gauche : bilan net
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.recurringMonthlySummaryTitle,
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: AppTypography.labelLetterSpacingForSize12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$netSign$netFormatted',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  fontWeight: AppTypography.semiBold,
                  color: netColor,
                ),
              ),
            ],
          ),
          // Colonne droite : charges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.recurringChargesCount(expenseCount),
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: AppTypography.labelLetterSpacingForSize12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '~$expensesFormatted/mois',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  fontWeight: AppTypography.semiBold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### 6.7 `_showActionSheet()` — action sheet redessinée (US3, FR-011 → FR-013)

```dart
void _showActionSheet(
  BuildContext context,
  RecurringTransaction item,
  AppLocalizations l10n,
  AppThemeExtension themeExt,
) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final colorScheme = Theme.of(ctx).colorScheme;
      final amountColor = item.type == TransactionType.depense
          ? themeExt.expenseColor
          : themeExt.incomeColor;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Résumé récurrence (FR-011)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space4),
                child: Column(
                  children: [
                    Text(
                      _frequencyLabel(item.frequency, l10n).toUpperCase(),
                      style: TextStyle(
                        fontSize: AppTypography.sizeXs,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: AppTypography.labelLetterSpacingForSize12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      AmountFormatter.format(
                          item.montant, currency: item.accountCurrency ?? Currency.eur),
                      style: TextStyle(
                        fontSize: AppTypography.sizeXl,
                        fontWeight: AppTypography.bold,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      l10n.recurringNextOccurrence(
                          RelativeDateFormatter.formatCompact(item.nextOccurrence)),
                      style: TextStyle(
                        fontSize: AppTypography.sizeXs,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Bouton Marquer comme payée (FR-012)
              _ActionButton(
                label: l10n.recurringValidate,
                icon: PhosphorIconsRegular.check,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                isMutating: ref.read(recurringListNotifierProvider).mutatingIds.contains(item.id),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _handleValidate(context, item.id, l10n);
                },
              ),
              const SizedBox(height: AppSpacing.space2),

              // Bouton Passer cette occurrence (FR-012)
              _ActionButton(
                label: l10n.recurringSkip,
                icon: PhosphorIconsRegular.skipForward,
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurface,
                isMutating: ref.read(recurringListNotifierProvider).mutatingIds.contains(item.id),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _handleSkip(context, item.id, l10n);
                },
              ),
              const SizedBox(height: AppSpacing.space2),

              // Bouton Désactiver (FR-012, FR-013 — sans AlertDialog)
              _ActionButton(
                label: l10n.recurringDeactivate,
                icon: PhosphorIconsRegular.pause,
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: themeExt.expenseColor,
                isMutating: ref.read(recurringListNotifierProvider).mutatingIds.contains(item.id),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _handleDeactivate(context, item.id, l10n); // sans AlertDialog (FR-013)
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
```

#### 6.8 `_ActionButton` — widget privé action sheet (FR-012)

```dart
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isMutating,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isMutating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isMutating ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
        ),
        icon: isMutating
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: foregroundColor))
            : PhosphorIcon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}
```

#### 6.9 Handlers d'actions (US3)

Reprendre les handlers `_handleValidate`, `_handleSkip` existants sans modification.  
`_handleDeactivate` : identique à l'existant mais **sans** appel à `_showDeactivateConfirm` (FR-013 — `AlertDialog` supprimé).  
`_showDeactivateConfirm` + son `AlertDialog` : supprimés.

#### 6.10 `_handleValidateAll()` (NFR-001)

```dart
Future<void> _handleValidateAll(
  BuildContext context,
  List<String> ids,
  AppLocalizations l10n,
) async {
  await ref.read(recurringListNotifierProvider.notifier).validateAll(ids);
  if (!context.mounted) return;
  final error = ref.read(recurringListNotifierProvider).error;
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.errorGeneric),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${ids.length} transaction${ids.length > 1 ? 's' : ''} '
          'validée${ids.length > 1 ? 's' : ''}',
        ),
      ),
    );
  }
}
```

---

### 7. Tests — NFR-004

#### 7.1 `recurring_list_notifier_test.dart` — ajouts

```dart
test('should_validateAll_sequentially_and_clear_mutatingIds', () async { ... });
test('should_validateAll_stop_on_first_failure', () async { ... });
test('should_validateAll_add_and_remove_all_sentinel', () async { ... });
```

#### 7.2 `recurring_list_screen_test.dart` — adaptations

- Supprimer les vérifications sur les badges `_StatusBadge` ("En retard", "À venir")
- Remplacer par vérification des headers de groupe (text "EN RETARD", "AUJOURD'HUI", "À VENIR")
- Ajouter tests : `_StatusGroupHeader` couleur, `_MonthlySummaryCard` montants, bouton "Tout payé" présent sur overdue uniquement

> Setup `buildApp()` devra ajouter les overrides `exchangeRateListProvider` et `dashboardNotifierProvider`.

---

## Risques & Mitigations

| Risque | Probabilité | Impact | Mitigation |
|--------|------------|--------|------------|
| `recurringListNotifierProvider` watch dans `_showActionSheet` (via `ref.read`) — bottom sheet fermé avant l'action, `context` périmé | Faible | Moyen | Utiliser `ref.read()` (pas `watch`) dans le bottom sheet builder — pattern existant dans `subscription_list_screen` |
| Tests `recurring_list_screen_test.dart` nécessitent `exchangeRateListProvider` + `dashboardNotifierProvider` non mockés | Certain | Moyen | Ajouter les overrides dans `buildApp()` avec états vides (no rates, no currencies) |
| `validateAll` séquentiel : si l'API répond lentement sur 5+ items overdue, latence perceptible | Faible | Faible | Acceptable (ASS-002). UX : bouton désactivé + spinner pendant l'opération |
| `formatCompact()` : range passé > 7j non spécifié → fallback `DateFormat('dd MMM', 'fr')` | Très faible | Mineur | Cohérent avec le comportement Angular pour les dates lointaines |
| `l10n.recurringChargesCount(int)` nécessite une clé ICU avec paramètre `{count, plural}` ou simple `{count}` | Certain | Mineur | Utiliser simple placeholder `{count}` (pas de pluralisation ICU car "CHARGES" ne se flexionne pas selon le count — singulier/pluriel identique en contexte uppercase) |

---

## Hors scope

- Création de récurrences (formulaire KKS-241 — déjà implémenté)
- Conversion multi-devises côté notifier (calcul en screen uniquement, comme Angular)
- `print()` → `developer.log` migration (hors scope de cette feature)
- Modification de `RecurringTransactionRepository`, domain model, DTOs (NFR-003)
- Pagination / lazy loading (pas de pagination côté API pour les récurrences actives)
- Mode standalone Drift (Trajectoire B sans sync — les données viennent du remote uniquement pour l'instant)

---

## Complexity Tracking

Aucune gate constitutionnelle violée.

| Choix | Justification |
|-------|--------------|
| `CustomScrollView + SliverToBoxAdapter` au lieu de `ListView` | Structure hétérogène (monthly summary + headers + cartes) incompatible avec `ListView.builder` pur. Pattern existant dans `debt_list_screen` et `subscription_list_screen` |
| `_StatusGroupSection` + `_MonthlySummaryCard` + `_ActionButton` comme widgets privés | Extraction nécessaire pour éviter un nesting excessif dans `_buildContent`. Tous privés, aucun export |
| `dashboardNotifierProvider` ajouté comme dépendance screen | Seule source de `primaryCurrency` dans le codebase — pattern identique à `debt_list_screen` et `subscription_list_screen` |
| `_ActionButton` widget dupliqué dans `_showActionSheet` (distinct du `_ActionButton` de KKS-250) | Privé au screen, API différente (3 boutons pleine largeur avec spinner). Pas de confusion avec `_ActionButton` de `account_list_tile` (fichiers séparés) |
