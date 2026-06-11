# Documentation : Comptes liste Flutter (alignement DESIGN.md v5)

**Issue** : KKS-250 | **Parent** : KKS-242 | **Date** : 2026-05-21  
**Branche** : `develop` | **Statut** : Done

---

## Résumé

KKS-250 aligne l'écran Comptes Flutter sur la source de vérité Angular (`accounts.html` / `accounts.scss`). Cinq divergences visuelles sont corrigées sur `AccountListTile` (icône, sous-titre, solde, badges, actions) et deux lacunes structurelles sur `AccountListScreen` (carte conteneur, section header). La confirmation de suppression passe d'un `AlertDialog` bloquant à un bloc inline dans la ligne. Aucune logique métier, aucun notifier, aucun repository modifié.

---

## Guide utilisateur

### Écran Comptes — ce qui change

#### Chaque ligne de compte (`AccountListTile`)

| Élément | Avant | Après |
|---------|-------|-------|
| Icône banque | Cercle 60px (`size × 1.5`) | Cercle 32px (diamètre exact) |
| Nom du compte | `sizeMd` / `onSurface` | `sizeSm` / `onSurfaceVariant` |
| Sous-titre | Type seul (`Courant`) | `BankName · Type` si banque renseignée |
| Solde | Toujours `onSurface` | Rouge (`expenseColor`) si négatif |
| Badges Défaut / Inactif | Fond coloré (`primary` / `error`) | Contour neutre (`outlineVariant`, 10px) |
| Actions | Menu 3-points caché | Boutons inline : 🗑️ étoile ✏️ |

#### Confirmation de suppression

Cliquer sur 🗑️ affiche un bloc inline dans la ligne du compte (pas de popup) :

```
┌─────────────────────────────────────┐
│ Supprimer ce compte ?               │
│ [message d'erreur si échec API]     │
│   [ Annuler ]   [ Supprimer ]       │
└─────────────────────────────────────┘
```

- **Annuler** → ferme le bloc, la liste reprend son état normal
- **Supprimer** → supprime le compte ; en cas d'erreur API, le message s'affiche dans le bloc
- Un seul bloc actif à la fois : cliquer 🗑️ sur un autre compte ferme le bloc en cours

#### Structure de l'écran (`AccountListScreen`)

| Élément | Avant | Après |
|---------|-------|-------|
| Bouton "+" | AppBar (coin haut droit) | Section header (inline dans le scroll) |
| Liste | `SliverList` sans conteneur | Carte `surface` / `radius-xl` avec Dividers |
| Section header | Absent | "{N} COMPTES" + bouton ⊕ circulaire 28px |
| État vide | `Column` custom | `EmptyStateWidget` (icône Bank) |
| État erreur | `Column` custom | `EmptyStateWidget` (icône Warning) |
| Skeleton | 5 items | 3 items, cercle 32px |

---

## Changements techniques

### Fichiers modifiés

| Fichier | Type | Description |
|---------|------|-------------|
| `flutter/lib/src/common_widgets/account_bank_icon.dart` | Correction | `size` = diamètre conteneur (suppression `×1.5`). SVG `size×⅔`, emoji `size×0.55`. Fallback `iconCircleBg` (AppThemeExtension) au lieu de `Colors.grey`. |
| `flutter/lib/src/features/accounts/presentation/widgets/account_list_tile.dart` | Refonte | Layout Column 3 lignes. Paramètres US3 ajoutés. `_Badge` outline. `_ActionButton` 32px. `_ConfirmDeleteBlock` inline. Suppression `PopupMenuButton`. |
| `flutter/lib/src/features/accounts/presentation/screens/account_list_screen.dart` | Refonte | `SliverToBoxAdapter` + carte. Section header. `EmptyStateWidget`. State `_confirmDeleteId`/`_deleteError`. Suppression AlertDialog et AppBar.actions. |
| `flutter/lib/src/features/accounts/presentation/widgets/account_list_skeleton.dart` | Mineure | 5 → 3 items. Cercle `space10` → `space8`. |

### API `AccountListTile` — nouveaux paramètres

```dart
AccountListTile({
  required Account account,
  VoidCallback? onTap,
  VoidCallback? onSetDefault,
  VoidCallback? onEdit,                  // nouveau (remplace navigation depuis popup)
  bool isConfirmingDelete = false,       // nouveau
  String? deleteError,                   // nouveau
  VoidCallback? onRequestDelete,         // nouveau (remplace onDelete)
  VoidCallback? onConfirmDelete,         // nouveau
  VoidCallback? onCancelDelete,          // nouveau
})
```

> `onDelete` est supprimé. Si du code utilise ce paramètre, le remplacer par `onRequestDelete`.

### Widgets privés ajoutés

| Widget | Fichier | Rôle |
|--------|---------|------|
| `_Badge` | `account_list_tile.dart` | Badge outline (Défaut, Inactif) |
| `_ActionButton` | `account_list_tile.dart` | Bouton icône inline 32px |
| `_ConfirmDeleteBlock` | `account_list_tile.dart` | Bloc confirmation suppression inline |
| `_AddButton` | `account_list_screen.dart` | Bouton ⊕ circulaire 28px section header |

### Tokens utilisés

| Token | Valeur | Usage |
|-------|--------|-------|
| `AppSpacing.space8` | 32px | Icône banque, actions |
| `AppSpacing.space7` | 28px | Bouton ⊕ section header |
| `AppTypography.size2Xs` | 10px | Badges |
| `AppTypography.sizeSm` | 14px | Nom, solde |
| `AppRadius.xl` | 16px | Carte liste |
| `AppRadius.round` | 999px | Badges |
| `AppRadius.lg` | 12px | Bloc confirm delete |
| `AppThemeExtension.expenseColor` | Rouge | Solde négatif, bouton trash |
| `AppThemeExtension.iconCircleBg` | — | Fond icône fallback |
| `AppTypography.labelLetterSpacingForSize12` | 0.6 | Section header |

---

## Tests et validation

### Tests automatisés

| Fichier test | Tests | Résultat |
|-------------|-------|---------|
| `account_list_tile_test.dart` | 9 (6 adaptés + 2 nouveaux pour `_ConfirmDeleteBlock`) | ✅ PASS |
| `account_list_screen_test.dart` | 6 (adaptés : icône `+`, état error, retry) | ✅ PASS |
| `account_bank_icon_test.dart` | Existants — non modifiés | ✅ PASS |
| **Total feature** | **54** | ✅ **PASS** |

### Validation manuelle requise (T-052 → T-054)

- **US1** : Ouvrir l'écran Comptes → vérifier icône 32px, sous-titre `bankName · type`, solde rouge si négatif, badges outline, 3 boutons inline
- **US2** : Vérifier section header "{N} COMPTES" + bouton ⊕, carte `surface/radius-xl`, Dividers, `EmptyStateWidget` sur état vide, skeleton 3 items
- **US3** : Cliquer 🗑️ → vérifier bloc confirm inline (pas de dialog), Annuler → ferme, Confirmer → compte supprimé

---

## Hors scope

- Import CSV (`triggerImport` Angular) — non implémenté en Flutter
- Écrans `CurrencyList`, `ExchangeRateManager`
- Pluralisation dynamique de "{N} comptes" (alignement intentionnel avec Angular)

---

## Dépendances

Aucune nouvelle dépendance ajoutée. Utilise uniquement des packages et tokens déjà présents dans le projet.
