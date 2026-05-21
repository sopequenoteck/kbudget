# Implementation Plan: Comptes liste Flutter (alignement DESIGN.md v5)

**Issue**: KKS-250 | **Branch**: `develop` | **Date**: 2026-05-21  
**Spec**: [spec.md](spec.md) | **Clarify**: [clarify-log.md](clarify-log.md)

---

## Summary

Alignement de `AccountListScreen` et `AccountListTile` Flutter sur le rendu Angular (source de vérité visuelle). Quatre modifications concrètes : (1) correction sémantique de `AccountBankIcon` (size = diamètre conteneur) ; (2) refonte `AccountListTile` — icône 32px, sous-titre `bankName · type`, solde colorisé, badges outline, actions inline ; (3) refonte `AccountListScreen` — carte `surface/radius-xl`, section header "{N} comptes", `EmptyStateWidget`, AppBar nettoyée ; (4) delete confirm inline (US3 P3). Aucun nouveau composant, aucune logique métier modifiée.

---

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27  
**Primary Dependencies**: flutter_riverpod, phosphor_flutter, AppSpacing, AppTypography, AppColors, AppRadius, AppThemeExtension (tokens v5)  
**Storage**: N/A — aucun schéma Drift modifié  
**Testing**: flutter_test (tests existants sur `AccountListTile` et `AccountListScreen` — mise à jour si nécessaire)  
**Target Platform**: iOS + Android (Trajectoire B — Standalone Commercial)  
**Project Type**: Mobile app  
**Performance Goals**: N/A — refonte purement visuelle  
**Constraints**: `AccountBankIcon` dans `common_widgets` — seul caller : `account_list_tile.dart` (modification safe)

---

## Constitution Check

| Principe | Applicable | Statut | Notes |
|----------|-----------|--------|-------|
| I — API-First / Local-First | Non | ✅ N/A | Aucun endpoint modifié, aucun schéma Drift touché |
| II — Sécurité | Non | ✅ N/A | Pas de routes, pas de secrets |
| III — Simplicité & YAGNI | Oui | ✅ PASS | Refactoring minimal — suppression PopupMenuButton et AlertDialog = simplification nette |
| IV — Mobile-First UX | Oui | ✅ PASS | Alignement Angular améliore la fidélité visuelle et l'ergonomie (actions visibles) |
| V — Testabilité | Oui | ✅ PASS | Nouveaux params `AccountListTile` tous optionnels — tests existants non cassés |
| VI — Observabilité | Oui | ✅ PASS | Aucun `print()` introduit |
| VII — Two Trajectories | Non | ✅ N/A | Trajectoire B uniquement, pas d'impact sync |

**Résultat : PASS — aucune gate violée.**

---

## Architecture — Fichiers impactés

### Modifications (M)

| Fichier | Nature | FR couverts |
|---------|--------|-------------|
| `flutter/lib/src/common_widgets/account_bank_icon.dart` | Sémantique `size` = diamètre conteneur | FR-001 (prérequis) |
| `flutter/lib/src/features/accounts/presentation/widgets/account_list_tile.dart` | Refonte layout + styles + actions inline + confirm delete | FR-001 → FR-006, FR-012 → FR-014 |
| `flutter/lib/src/features/accounts/presentation/widgets/account_list_skeleton.dart` | 5 → 3 items, circle space10 → space8 | FR-011 |
| `flutter/lib/src/features/accounts/presentation/screens/account_list_screen.dart` | Carte SliverToBoxAdapter, section header, EmptyStateWidget, AppBar nettoyée, confirmDeleteId state | FR-007 → FR-011, FR-012 → FR-014 |

### Tests à mettre à jour (si nécessaire)

| Fichier | Vérification |
|---------|-------------|
| `flutter/test/src/features/accounts/presentation/widgets/account_list_tile_test.dart` | Adapter si `PopupMenuButton` est testé (supprimé) — sinon params optionnels non cassants |
| `flutter/test/src/features/accounts/presentation/screens/account_list_screen_test.dart` | Adapter si `EmptyStateWidget` ou section header sont testés |

### Aucun fichier à créer

---

## Approche détaillée par composant

### 1. `AccountBankIcon` — Correction sémantique (prérequis US1)

**FR couverts** : FR-001 (prérequis)

**Problème** : `size` = paramètre d'icône interne, conteneur = `size × 1.5`. Résultat : `size: 40` → conteneur 60px. Cible : conteneur 32px (`AppSpacing.space8`).

**Avant** :
```dart
Container(
  width: size * 1.5, height: size * 1.5,  // conteneur dérivé
  child: ...
)
_resolveIcon():
  Text(fontSize: size * 0.8)          // emoji
  SvgPicture(width: size, height: size) // svg
```

**Après** (`size` = diamètre du conteneur) :
```dart
Container(
  width: size, height: size,  // conteneur direct
  child: ...
)
_resolveIcon():
  Text(fontSize: size * 0.55)               // emoji (= 0.8/1.5 de l'ancienne formule)
  SvgPicture(width: size * 2/3, height: size * 2/3)  // svg (= 1/1.5 de l'ancienne formule)
```

**Caller** : `account_list_tile.dart` → passe de `size: AppSpacing.space10` à `size: AppSpacing.space8`.  
**Skeleton** : `_SkeletonItem` → cercle `AppSpacing.space10` → `AppSpacing.space8`.

---

### 2. `AccountListTile` — Refonte layout et styles

**FR couverts** : FR-001 → FR-006, NFR-001

#### 2.1 Import à ajouter

```dart
import 'package:k_budget/src/theme/app_theme_extension.dart';
```

#### 2.2 Nouveaux paramètres (US3 — optionnels)

```dart
class AccountListTile extends ConsumerWidget {
  const AccountListTile({
    super.key,
    required this.account,
    this.onTap,
    this.onSetDefault,
    // US3 — delete confirm inline
    this.isConfirmingDelete = false,
    this.deleteError,
    this.onRequestDelete,
    this.onConfirmDelete,
    this.onCancelDelete,
    this.onEdit,
  });

  final bool isConfirmingDelete;
  final String? deleteError;
  final VoidCallback? onRequestDelete;
  final VoidCallback? onConfirmDelete;
  final VoidCallback? onCancelDelete;
  final VoidCallback? onEdit;
}
```

#### 2.3 Layout principal (build)

```dart
final colors = Theme.of(context).extension<AppThemeExtension>()!;
final colorScheme = Theme.of(context).colorScheme;
final l10n = AppLocalizations.of(context)!;

final formattedBalance = AmountFormatter.format(account.solde, currency: account.currency);
final balanceColor = account.solde < 0 ? colors.expenseColor : colorScheme.onSurfaceVariant;

final content = Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.space4,
    vertical: AppSpacing.space3,
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      // Ligne 1 : icône + contenu + solde
      Row(
        spacing: AppSpacing.space3,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AccountBankIcon(account: account, size: AppSpacing.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(account.nom,
                        style: TextStyle(
                          fontSize: AppTypography.sizeSm,
                          fontWeight: AppTypography.medium,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (account.isDefault) ...[
                      const SizedBox(width: AppSpacing.space2),
                      _Badge(label: l10n.accountBadgeDefault, colorScheme: colorScheme),
                    ],
                    if (!account.actif) ...[
                      const SizedBox(width: AppSpacing.space2),
                      _Badge(label: l10n.accountBadgeInactive, colorScheme: colorScheme),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  _subtitle(l10n),
                  style: TextStyle(
                    fontSize: AppTypography.sizeXs,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formattedBalance,
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.semiBold,
              color: balanceColor,
            ),
          ),
        ],
      ),
      // Ligne 2 : actions inline
      const SizedBox(height: AppSpacing.space1),
      Row(
        children: [
          _ActionButton(
            icon: PhosphorIconsRegular.trash,
            color: colors.expenseColor,
            onTap: onRequestDelete,
          ),
          const Spacer(),
          if (!account.isDefault && account.actif)
            _ActionButton(icon: PhosphorIconsRegular.star, onTap: onSetDefault),
          _ActionButton(
            icon: PhosphorIconsRegular.pencilSimple,
            onTap: onEdit ?? onTap,
          ),
        ],
      ),
      // Ligne 3 : confirm delete (US3)
      if (isConfirmingDelete) ...[
        const SizedBox(height: AppSpacing.space2),
        _ConfirmDeleteBlock(
          error: deleteError,
          onConfirm: onConfirmDelete,
          onCancel: onCancelDelete,
          colors: colors,
          colorScheme: colorScheme,
        ),
      ],
    ],
  ),
);

return Opacity(
  opacity: account.actif ? 1.0 : 0.5,
  child: onTap != null
      ? InkWell(onTap: onTap, child: content)
      : content,
);
```

#### 2.4 `_subtitle()` — sous-titre bankName · type

```dart
String _subtitle(AppLocalizations l10n) {
  final type = _typeLabel(l10n);
  if (account.bankName != null && account.bankName!.isNotEmpty) {
    return '${account.bankName} · $type';
  }
  return type;
}
```

#### 2.5 `_Badge` — style outline Angular

```dart
class _Badge extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;

  const _Badge({required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.size2Xs,
          fontWeight: AppTypography.medium,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
```

#### 2.6 `_ActionButton` — bouton action 32px

```dart
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppSpacing.space8,
      height: AppSpacing.space8,
      child: IconButton(
        icon: PhosphorIcon(icon, size: 16),
        color: color ?? colorScheme.onSurfaceVariant,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}
```

#### 2.7 `_ConfirmDeleteBlock` — bloc confirm inline (US3)

```dart
class _ConfirmDeleteBlock extends StatelessWidget {
  final String? error;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final AppThemeExtension colors;
  final ColorScheme colorScheme;

  const _ConfirmDeleteBlock({...});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Supprimer ce compte ?',
            style: TextStyle(fontSize: AppTypography.sizeSm, color: colorScheme.onSurfaceVariant)),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(error!, style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.medium,
              color: colors.expenseColor,
            )),
          ],
          const SizedBox(height: AppSpacing.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: AppSpacing.space2,
            children: [
              OutlinedButton(onPressed: onCancel, child: const Text('Annuler')),
              FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(backgroundColor: colors.expenseColor),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### 2.8 Suppression

- `PopupMenuButton` → supprimé
- `onDelete` callback → supprimé (remplacé par `onRequestDelete`)

---

### 3. `AccountListSkeleton` — 3 items, circle 32px

**FR couverts** : FR-011

```dart
// Avant
List.generate(5, (_) => _SkeletonItem(baseColor: baseColor))

// Après
List.generate(3, (_) => _SkeletonItem(baseColor: baseColor))
```

```dart
// Dans _SkeletonItem : cercle
// Avant : width: AppSpacing.space10, height: AppSpacing.space10
// Après :
width: AppSpacing.space8,
height: AppSpacing.space8,
```

---

### 4. `AccountListScreen` — Structure et états

**FR couverts** : FR-007 → FR-014

#### 4.1 Suppression AppBar `actions`

```dart
// Avant
appBar: AppBar(
  title: Text(l10n.accountsTitle),
  actions: [
    IconButton(
      icon: PhosphorIcon(PhosphorIconsBold.plus, size: 24),
      onPressed: () => context.push(...new),
    ),
  ],
),

// Après
appBar: AppBar(title: Text(l10n.accountsTitle)),
```

#### 4.2 State pour US3 (delete confirm inline)

```dart
class _AccountListScreenState extends ConsumerState<AccountListScreen> {
  String? _confirmDeleteId;
  String? _deleteError;

  // ... initState inchangé

  void _requestDelete(String accountId) {
    setState(() {
      _confirmDeleteId = accountId;
      _deleteError = null;
    });
  }

  void _cancelDelete() {
    setState(() {
      _confirmDeleteId = null;
      _deleteError = null;
    });
  }

  Future<void> _confirmDelete() async {
    final id = _confirmDeleteId;
    if (id == null) return;
    try {
      await ref.read(accountNotifierProvider.notifier).delete(id);
      setState(() {
        _confirmDeleteId = null;
        _deleteError = null;
      });
    } on Exception catch (e) {
      setState(() {
        _deleteError = e.toString();
      });
    }
  }
}
```

#### 4.3 États empty et error — EmptyStateWidget

```dart
// Avant : custom Column avec PhosphorIcon + Text + FilledButton.icon
// Après :
SliverFillRemaining(
  hasScrollBody: false,
  child: EmptyStateWidget(
    icon: PhosphorIconsRegular.bank,          // ou .warning pour error
    message: 'Aucun compte',                  // ou 'Erreur de chargement'
    ctaLabel: 'Créer un compte',              // ou 'Réessayer'
    onCtaTap: () => context.push(... /new),   // ou () => _refresh()
  ),
)
```

#### 4.4 Zone data — Carte + Section header

```dart
// Remplace SliverList.builder par deux SliverToBoxAdapter :
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Row(
          children: [
            Text(
              '${state.items.length} comptes'.toUpperCase(),
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            _AddButton(onTap: () => context.push(... /new)),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        // Carte conteneur
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(state.items.length, (i) {
              final account = state.items[i];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AccountListTile(
                    account: account,
                    onTap: () => context.push(
                      '${RouteNames.settings}/${RouteNames.settingsAccounts}/${account.id}',
                      extra: account,
                    ),
                    onSetDefault: () => ref.read(accountNotifierProvider.notifier).setDefault(account.id),
                    onEdit: () => context.push(
                      '${RouteNames.settings}/${RouteNames.settingsAccounts}/${account.id}',
                      extra: account,
                    ),
                    onRequestDelete: () => _requestDelete(account.id),
                    onConfirmDelete: _confirmDelete,
                    onCancelDelete: _cancelDelete,
                    isConfirmingDelete: _confirmDeleteId == account.id,
                    deleteError: _confirmDeleteId == account.id ? _deleteError : null,
                  ),
                  if (i < state.items.length - 1)
                    Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.space12 * 2),
      ],
    ),
  ),
)
```

#### 4.5 `_AddButton` — bouton "+" circulaire 28px

```dart
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppSpacing.space7,
      height: AppSpacing.space7,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: PhosphorIcon(PhosphorIconsRegular.plus, size: 16, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
```

#### 4.6 Suppression

- `_onDelete(account)` (méthode AlertDialog) → supprimée (remplacée par `_requestDelete`, `_confirmDelete`, `_cancelDelete`)

---

## Risques & Mitigations

| Risque | Probabilité | Impact | Mitigation |
|--------|------------|--------|------------|
| `AccountBankIcon` size change → régression visuelle | Faible | Mineur | Seul caller vérifié par grep (`account_list_tile.dart`). Inspection visuelle suffisante |
| `SliverToBoxAdapter(Column)` → jank sur très longues listes | Très faible | Mineur | Accounts < 20 typiquement. `CustomScrollView` gère le scroll externe |
| Tests `account_list_tile_test.dart` testent `PopupMenuButton` | Moyen | Mineur | À vérifier — si oui, remplacer par test des boutons d'action inline |
| `_ConfirmDeleteBlock` error display → exception `.toString()` trop verbeux | Faible | Mineur | Catcher le message HTTP spécifiquement (pattern Angular : `err?.error?.message`) |
| `onTap` et `onEdit` identiques → duplication de navigation | Faible | Mineur | Acceptable — `onTap` pour swipe/row tap, `onEdit` pour bouton explicite. DRY possible dans screen |

---

## Hors scope

- Modification de `budget_list_screen.dart`, `account_detail_screen.dart`
- Import CSV (non implémenté en Flutter — CL-007 confirmé)
- `CurrencyList` et `ExchangeRateManager` sections
- Pluralisation de "{N} comptes" (alignement intentionnel Angular — CL-005)
- Badge padding token `space-1-5` (6px hardcodé acceptable — CL-006)
- Modification logique métier (notifier, repository, calculs)

---

## Complexity Tracking

Aucune violation de gate.

| Éventuel | Justification |
|----------|--------------|
| `AccountBankIcon` modifié en `common_widgets` | Seul caller (`account_list_tile.dart`) — modification safe. Sémantique `size = conteneur` plus intuitive |
| `SliverToBoxAdapter(Column)` au lieu de `SliverList.builder` | Nécessaire pour clipper la liste dans un `Container(borderRadius)`. Non-lazy acceptable pour < 20 items |
| Lift-state `confirmDeleteId`/`deleteError` vers `AccountListScreen` | Pattern Angular exact — signal au niveau composant. `ConsumerStatefulWidget` déjà en place |
| 4 widgets privés ajoutés (`_Badge`, `_ActionButton`, `_ConfirmDeleteBlock`, `_AddButton`) | Extraction minimale pour éviter nesting excessif — tous privés, aucun export |
