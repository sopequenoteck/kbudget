# Data Model — KKS-238 : Phase 1 / Étape 2 — Composants shared Flutter

> Date : 2026-05-07
> Issue : [KKS-238](https://linear.app/kksdev/issue/KKS-238/phase-1-etape-2-composants-shared-flutter-8-widgets)
> Spec : [spec.md](./spec.md)
> Plan : [plan.md](./plan.md)

---

## Note

**Aucune nouvelle entité de domaine** dans cette feature. Les composants livrés sont 100% UI / présentation. Ce fichier documente uniquement les types **non-domaine** (UI / widgets) introduits, pour traçabilité.

Les entités de domaine consommées (existantes, inchangées) :
- `Category` (`flutter/lib/src/domain/models/category.dart`) — `id: String`, `nom: String`, `icone: String`, `couleur: String`, `isSystem: bool`, `updatedAt: DateTime?`. Consommée par `CategorySelectExpand` et `CategoryFormWidget`.

---

## Types UI introduits

### `ConfirmVariant` (enum local)

Fichier : `flutter/lib/src/common_widgets/confirm_dialog_custom.dart`
Portée : interne au composant `ConfirmDialogCustom`.

| Valeur | Couleur bouton confirmer | Icône bouton confirmer |
|--------|--------------------------|------------------------|
| `primary` | `colorScheme.primary` (amber) | `PhosphorIcons.check()` |
| `danger` | `colorScheme.error` (rouge) | `PhosphorIcons.trash()` |

**Note nommage** : `default` est un mot-clé Dart réservé. La valeur par défaut s'appelle `primary` (et non `default`).

**Invariants** :
- `ConfirmVariant.primary` est la valeur par défaut du paramètre `variant` de `ConfirmDialogCustom.show()`.
- L'enum n'est pas exposé publiquement par d'autres composants.

### `_CalendarDay` (model interne)

Fichier : `flutter/lib/src/common_widgets/inline_date_picker.dart`
Portée : **privée** au fichier `inline_date_picker.dart` (préfixe `_`).

| Champ | Type | Description |
|-------|------|-------------|
| `date` | `DateTime` | Date complète |
| `dayNumber` | `int` | Numéro du jour (1-31) |
| `isCurrentMonth` | `bool` | Le jour appartient au mois affiché ? |
| `isToday` | `bool` | C'est aujourd'hui ? |
| `isSelected` | `bool` | Le jour est la sélection courante ? |
| `isOriginal` | `bool` | Le jour est la valeur originale (mode édition) ? Masqué quand `isSelected` |
| `isDisabled` | `bool` | Désactivé via `minDate` / `maxDate` ou hors-mois |
| `isoDate` | `String` | Format ISO `'YYYY-MM-DD'` |

**Invariants** :
- `isOriginal == true && isSelected == true` est impossible (la sélection prime sur l'original).
- `isCurrentMonth == false` implique `isDisabled == true` (les jours hors-mois ne sont jamais tappables).
- `isoDate` est cohérent avec `date` (calculé via helper `_toIsoDate`).

### `_SelectMode` (enum local)

Fichier : `flutter/lib/src/common_widgets/category_select_expand.dart`
Portée : privée au composant `CategorySelectExpand`.

| Valeur | Description |
|--------|-------------|
| `list` | Mode par défaut : champ recherche + listbox + bouton créer |
| `create` | Mode création : header `[← Retour] [✓ Créer]` + embed `CategoryFormWidget` |

**Invariants** :
- Au `dispose()`, le mode est forcé à `list` (équivalent `ngOnDestroy` Angular).
- La recherche (`_searchController.text`) est conservée au retour `create → list`.

---

## Widgets introduits (référence — pas du domaine)

| Widget | Fichier | Type Flutter | État Riverpod |
|--------|---------|--------------|---------------|
| `SectionHeaderSticky` | `common_widgets/section_header_sticky.dart` | `StatelessWidget` | Aucun |
| `_SectionHeaderDelegate` | (privé) | `SliverPersistentHeaderDelegate` | Aucun |
| `ListGroup` | `common_widgets/list_group.dart` | `StatelessWidget` | Aucun |
| `EmptyStateWidget` | `common_widgets/empty_state_widget.dart` | `StatelessWidget` | Aucun |
| `VariationBadge` | `common_widgets/variation_badge.dart` | `StatelessWidget` | Aucun |
| `PageHeader` | `common_widgets/page_header.dart` | `StatelessWidget` | Aucun |
| `ConfirmDialogCustom` | `common_widgets/confirm_dialog_custom.dart` | méthode statique + `_ConfirmDialogContent` privé | Aucun |
| `InlineDatePicker` | `common_widgets/inline_date_picker.dart` | `StatefulWidget` | Aucun |
| `_CalendarHeader`, `_CalendarGrid`, `_DayCell` | (privés) | `StatelessWidget` | Aucun |
| `CategorySelectExpand` | `common_widgets/category_select_expand.dart` | `StatefulWidget` | Aucun (parent gère) |
| `CategoryFormWidget` | `features/categories/presentation/widgets/category_form_widget.dart` | `ConsumerStatefulWidget` | Lit `categoryNotifierProvider` (pour `create()` / `update()`) |
| `CategoryFormWidgetState` | (publique) | `ConsumerState<CategoryFormWidget>` | — |

---

## Relations

```
CategorySelectExpand --embed (mode 'create')--> CategoryFormWidget
                    --consomme--> Category[] (input)
                    --émet--> Category (onCreated, output après save)

CategoryFormWidget --reads--> categoryNotifierProvider
                  --calls--> categoryNotifier.create() / update()
                  --émet--> Category (onSaved)

CategoryFormScreen --wraps--> CategoryFormWidget
                  (Scaffold + AppBar)
```

| Relation | Type | Cardinalité | Contrainte |
|----------|------|-------------|------------|
| `CategorySelectExpand → CategoryFormWidget` | Embed (mode `'create'`) | 1:1 | `GlobalKey<CategoryFormWidgetState>` partagée |
| `CategoryFormWidget → Category` | Lecture / création / mise à jour via Riverpod | N:1 | Via `categoryNotifierProvider` |
| `CategoryFormScreen → CategoryFormWidget` | Wrapper Scaffold | 1:1 | `GlobalKey<CategoryFormWidgetState>` pour invoquer `submit()` depuis l'AppBar |

---

## Contraintes globales

| # | Contrainte | Type | Composants concernés |
|---|-----------|------|---------------------|
| DC-001 | Aucune valeur hex / `Color(0xFF...)` directe — tokens uniquement (`colorScheme.*` ou `AppThemeExtension`) | Code style | Tous les 8 composants + `CategoryFormWidget` |
| DC-002 | Aucune dépendance package externe nouvelle | Dépendances | Tous (NFR-005) |
| DC-003 | `Category.id` est toujours typé `String` (jamais `int`) | Typing | `CategorySelectExpand`, `CategoryFormWidget` |
| DC-004 | Format date `String` ISO `'YYYY-MM-DD'` en E/S de `InlineDatePicker` (jamais `DateTime` exposé) | API | `InlineDatePicker` |
| DC-005 | `ConfirmDialogCustom.show()` retourne `Future<bool?>` (pas `Future<bool>`) — `null` au scrim dismiss | API | `ConfirmDialogCustom` |
| DC-006 | Aucun `print()` — `developer.log` ou logging contrôlé uniquement (Constitution VI / NFR-008) | Code style | Tous |

---

## Migrations

**Aucune migration de base de données**. Cette feature est 100% UI.

Le schéma Drift et les migrations existantes ne sont pas impactés.

---

## Index

**Aucun index nouveau ou modifié**. Cette feature n'introduit pas d'opération de requête.
