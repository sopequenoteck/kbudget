# Research — KKS-241 : Refonte 3 formulaires XL Flutter (bottom sheet 4-rows)

> Date : 2026-05-11
> Issue : KKS-241
> Spec : [spec.md](./spec.md)

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Data layer | `RecurringTransaction.create()` : DTO Flutter + data source + repository + notifier à créer | Haute |
| RES-002 | Architecture | Gestion de l'état `expandedSection` dans les formulaires migrés | Haute |
| RES-003 | UI | Sélecteur de devise dans la zone expand : widget à utiliser | Moyenne |
| RES-004 | UI | Toggle type/fréquence/debtType dans `topTrailing` Row 1 : nouveau composant ou Material ? | Moyenne |
| RES-005 | UI | Dialog de confirmation suppression : `showDeleteConfirmDialog` vs `ConfirmDialog` | Basse |
| RES-006 | Architecture | Bypass `AppModal` dans `app_router.dart` : structure de l'appel direct à `showModalBottomSheet` | Haute |

---

## Décisions techniques

### RES-001 — RecurringTransaction `create()` : couche data Flutter

- **Contexte** : FR-013 impose d'appeler `recurringListNotifierProvider.create()` depuis `TransactionForm` quand `isRecurring = true`. Côté Spring, l'endpoint `POST /transactions/recurring` existe avec son `RecurringTransactionRequest`. Côté Flutter, ni le data source (`RecurringTransactionRemoteDataSource`), ni le repository (`RecurringTransactionRepository`), ni le notifier (`RecurringListNotifier`) n'exposent de méthode `create()`. Un DTO de request Flutter (`RecurringTransactionCreateRequest`) est aussi absent.
- **Analyse du codebase** :
  - Endpoint : `POST /api/transactions/recurring` — payload Angular : `{montant, libelle, type, frequency, nextOccurrence, categoryId?, accountId?, note?}`
  - Modèle `RecurringTransaction` Flutter : `montant`, `libelle`, `type`, `frequency`, `nextOccurrence`, `recurringActive` (pas de `categoryId`/`accountId` — présents seulement dans la response via `categoryName`/`accountName`)
  - `RecurringTransactionResponse` Flutter existe avec mapper `toDomain()`
  - Pattern établi : data source → repository interface → repository impl → notifier

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Freezed `RecurringTransactionCreateRequest` + ajout dans la chaîne complète | Conforme au pattern existant, typé, testable | 4 fichiers à modifier | ★★★★★ |
| B — Appel Dio direct depuis TransactionForm | Moins de code | Bypass pattern repository, non testable, viole la convention Riverpod | ★ |
| C — Réutiliser le DTO response comme request | 0 nouveau fichier | Couplage response/request, champs superflus | ★★ |

- **Décision** : Option A — créer `RecurringTransactionCreateRequest` (Freezed) et propager `create()` dans les 4 couches.
- **Rationale** : Constitution III (YAGNI) ne s'oppose pas à respecter le pattern — ajouter une méthode à une chaîne existante est minimal. La testabilité (constitution V) et la lisibilité imposent le bon pattern.
- **Alternatives rejetées** : B viole les conventions Riverpod du projet. C crée un couplage structurel invisible.
- **Impact sur le plan** :
  1. Créer `RecurringTransactionCreateRequest` (Freezed, `build_runner`) dans `data/remote/dtos/`
  2. Ajouter `Future<RecurringTransaction> create(RecurringTransactionCreateRequest req)` à `RecurringTransactionRemoteDataSource`
  3. Ajouter `Future<RecurringTransaction> create(RecurringTransactionCreateRequest req)` à `RecurringTransactionRepository` (interface)
  4. Implémenter dans `RecurringTransactionRepositoryRemote`
  5. Ajouter `Future<void> create(RecurringTransactionCreateRequest req)` à `RecurringListNotifier` (suit le pattern `validate`/`skip`/`deactivate`)
  - Payload request : `{montant, libelle, type (enum → string), frequency (enum → string), nextOccurrence (ISO date), categoryId?, accountId?, note?}`

---

### RES-002 — Gestion de l'état `expandedSection`

- **Contexte** : Les formulaires migrés doivent gérer quel slot est déployé dans la zone expand de `BottomSheet4RowsWidget` (date, catégorie, compte, note, récurrence, reminder, devise, échéance). L'état est local au formulaire, non partagé.
- **Analyse du codebase** :
  - Angular utilise un `signal<ExpandableSection | null>` local dans le composant
  - L'exemple de `BottomSheet4RowsWidget` (docstring) utilise `ValueNotifier<String?>` dans le parent
  - Les formulaires actuels Flutter utilisent `ConsumerStatefulWidget` avec `setState`
  - Constitution : Riverpod signals pour la state globale ; `setState` pour la state locale UI est acceptable

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `setState` dans `ConsumerStatefulWidget` | Pattern déjà en place, minimal, 0 overhead | Non observable depuis l'extérieur (pas d'impact ici) | ★★★★★ |
| B — `ValueNotifier<String?>` | Légèrement plus performant (rebuild ciblé) | Complexité supplémentaire pour un état trivial | ★★★ |
| C — Provider Riverpod local (`StateProvider`) | Observable, testable | Overkill pour un état purement UI temporaire | ★★ |

- **Décision** : Option A — `setState` dans `ConsumerStatefulWidget`, champ `String? _expandedSection`.
- **Rationale** : Constitution III (YAGNI). L'état est local, éphémère (disparaît à la fermeture du bottom sheet), et non partagé. `setState` est le bon outil. Le rebuildest borné au widget du formulaire.
- **Impact sur le plan** : Chaque formulaire déclare `String? _expandedSection` dans son state. Un helper `_toggleSection(String key)` bascule l'expand (ferme si déjà ouvert, ouvre sinon). Pattern identique pour les 3 formulaires.

---

### RES-003 — Sélecteur de devise dans la zone expand

- **Contexte** : FR-016 impose une pill "Devise" dans Row 3 de `SubscriptionForm` et `DebtForm`, visible quand aucun compte n'est sélectionné. Le tap ouvre un sélecteur de devise en zone expand.
- **Analyse du codebase** :
  - `SelectPicker` (`common_widgets/select_picker.dart`) : `FormField<String?>` avec `items: List<SelectPickerItem>`, `label`, `placeholder`, `clearable`, `searchable`
  - `Currency` enum Flutter : 7 valeurs avec `symbol` et `displayName`
  - `DebtForm` actuel utilise déjà `SelectPicker` avec des items d'accounts — le pattern est établi
  - `SelectPickerItem` : `{id, label, icon?, color?, secondaryText?, imageUrl?}`

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `SelectPicker` avec `Currency.values` mappés en `SelectPickerItem` | Réutilise un widget existant, 0 nouvelle dépendance | `SelectPicker` est un `FormField` — nécessite un wrapping hors Form si utilisé seul | ★★★★★ |
| B — `DropdownButton` Material | Natif Flutter | Visuellement incohérent avec le design system | ★ |
| C — Nouveau widget `CurrencySelectExpand` | Contrôle total | Création inutile d'un composant spécialisé | ★★ |

- **Décision** : Option A — `SelectPicker` avec items générés depuis `Currency.values`. Mapping : `SelectPickerItem(id: c.name, label: '${c.displayName} (${c.symbol})')`.
- **Rationale** : Constitution III (YAGNI) et principe Lib-first. `SelectPicker` est déjà utilisé pour les comptes dans `DebtForm` — la réutilisation est directe.
- **Impact sur le plan** : Générer la liste `currencyItems` dans le state du formulaire une seule fois. La sélection met à jour `_forcedCurrency`. Quand un compte est sélectionné (`_selectedAccountId != null`), la pill "Devise" est masquée et `_forcedCurrency` est réinitialisé.

---

### RES-004 — Toggle type/fréquence/debtType dans `topTrailing`

- **Contexte** : Row 1 de `BottomSheet4RowsWidget` accepte un `Widget? topTrailing`. Les 3 formulaires ont besoin d'un toggle : 2 boutons (Dépense/Recette pour Transaction, Emprunt/Prêt pour Debt) ou 3 boutons (Hebdo/Mensuel/Annuel pour Subscription). Ce composant est utilisé dans 3 formulaires → candidat Lib-first.
- **Analyse du codebase** :
  - Angular : `<div class="bsheet__type-toggle">` avec des boutons `[class.active]` — composant inline HTML/CSS
  - Flutter : aucun widget équivalent dans `common_widgets/`
  - `ToggleButtons` Material : widget natif avec `isSelected: List<bool>` et `children: List<Widget>`
  - Design system (`AppColors`, tokens) : tokens `var(--color-primary)` côté Angular → `colorScheme.primary` côté Flutter

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `BSheetTypeToggle` custom dans `common_widgets/` | Cohérent design system, réutilisable, contrôle visuel total | 1 fichier à créer | ★★★★★ |
| B — `ToggleButtons` Material | Natif, 0 nouveau fichier | Look Material non aligné sur le design system, personnalisation lourde | ★★ |
| C — Composant inline privé dans chaque formulaire | Simple | Duplication identique dans 3 fichiers | ★★ |

- **Décision** : Option A — créer `BSheetTypeToggle` dans `common_widgets/`. API minimale : `labels: List<String>`, `selectedIndex: int`, `onChanged: ValueChanged<int>`.
- **Rationale** : Principe Lib-first — 3 usages identiques → composant partagé. Constitution III : le composant est minimal (≤ 50 lignes), pas d'abstraction prématurée.
- **Impact sur le plan** : Créer `common_widgets/bsheet_type_toggle.dart`. Style : boutons pill adjacents, actif = fond `colorScheme.primary` + texte `colorScheme.onPrimary`, inactif = bordure `colorScheme.outline` + texte `colorScheme.onSurfaceVariant`. Taille police `AppTypography.sizeSm`, padding `vertical: 4, horizontal: AppSpacing.space3`.

---

### RES-005 — Dialog de confirmation suppression

- **Contexte** : FR-005 mentionnait `ConfirmDialog` pour la suppression, mais le code actuel des 3 formulaires utilise `showDeleteConfirmDialog` (`utils/confirm_delete_dialog.dart`).
- **Analyse du codebase** :
  - `showDeleteConfirmDialog` : fonction async `Future<bool?>`, affiche un `AlertDialog` avec titre, message, boutons "Annuler"/"Supprimer". Utilisée dans les 3 formulaires actuels.
  - `ConfirmDialog` (`common_widgets/confirm_dialog_custom.dart`, KKS-238) : widget statefull plus élaboré avec slots.
  - Comportement identique attendu dans les formulaires migrés.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Conserver `showDeleteConfirmDialog` | 0 changement, comportement éprouvé, consistant entre formulaires | aucun | ★★★★★ |
| B — Migrer vers `ConfirmDialog` | Plus riche | Hors périmètre, migration inutile | ★★ |

- **Décision** : Option A — conserver `showDeleteConfirmDialog` dans les 3 formulaires migrés.
- **Rationale** : Constitution III (YAGNI). La spec FR-005 est corrigée en conséquence : "déclencher `showDeleteConfirmDialog`".
- **Impact sur le plan** : Aucun. Conserver l'appel existant depuis le callback de la pill "Supprimer".

---

### RES-006 — Bypass AppModal dans `app_router.dart`

- **Contexte** : `AppModal._ModalContent` ajoute son propre header (drag handle, titre, bouton ×, headerActions). `BottomSheet4RowsWidget` a sa propre Row 1 (drag handle, titre, topTrailing). Les deux shells sont incompatibles — les 3 formulaires migrés doivent bypasser `AppModal` et appeler `showModalBottomSheet` directement.
- **Analyse du codebase** :
  - `AppModal._showBottomSheet` : `showModalBottomSheet(isScrollControlled: true, useSafeArea: true, shape: RoundedRectangleBorder(top: xxl), builder: (_) => _ModalContent(...))`
  - `_ModalContent` gère : `Padding(bottom: viewInsetsOf.bottom)`, `maxHeight: 0.9 * screenHeight`, `SingleChildScrollView`
  - `BottomSheet4RowsWidget` gère déjà : `Flexible` + `SingleChildScrollView` interne. Le `Padding(bottom: viewInsets)` doit être posé par le builder du `showModalBottomSheet`
  - `_showModal` actuel construit le child via `_buildModalChild` puis passe à `AppModal.show`

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Méthode `_showFormBottomSheet` dédiée dans `app_router.dart` | Propre, 0 impact sur `AppModal`, `AppModal` reste pour les autres modals | 1 méthode de + dans le router | ★★★★★ |
| B — Modifier `AppModal` pour mode "bare" (sans header) | 1 seul point d'entrée | `AppModal` devient complexe, risque de régression | ★★ |
| C — Inliner l'appel `showModalBottomSheet` dans `_showModal` avec `if` sur le type | Pas de nouvelle méthode | `_showModal` devient difficile à lire | ★★ |

- **Décision** : Option A — ajouter `_showFormBottomSheet(BuildContext context, WidgetBuilder builder)` dans `_RootLayoutState` (ou extract en helper).
- **Rationale** : Séparation de responsabilités. `AppModal` continue à gérer les modals non migrés (budget, transfer) sans modification. Le nouveau helper est minimal et auto-documenté.
- **Structure** :
```dart
void _showFormBottomSheet(BuildContext context, Widget child) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: child,
    ),
  );
}
```
- `_showModal` appelle `_showFormBottomSheet` pour les types `transaction`, `subscription`, `debt`. Pour les autres (`budget`, `transfer`) : `AppModal.show` inchangé.
- **Impact sur le plan** : Modifier `_showModal` dans `app_router.dart`. Les consumers `_TransactionFormConsumer`, `_SubscriptionFormConsumer`, `_DebtFormConsumer` wrappent chacun leur `BottomSheet4RowsWidget` dans un `PopScope`.

---

## Analyse du codebase

### Patterns existants identifiés

- **Pattern `ConsumerStatefulWidget` + `setState`** : utilisé dans les 3 formulaires actuels pour la state locale (dates, IDs sélectionnés, flags) — reconduit tel quel.
- **Pattern `_toggleSection(String key)`** : à créer, inspiré du `toggleSection()` Angular. Ferme la section si déjà ouverte, ouvre sinon.
- **Pattern `SelectPicker` + `SelectPickerItem`** : utilisé pour comptes, catégories, budgets — reconduit pour la devise.
- **Pattern keyboard insets** : `Padding(bottom: MediaQuery.viewInsetsOf(ctx).bottom)` dans le builder du `showModalBottomSheet` — déjà en place dans `AppModal`, à reproduire dans `_showFormBottomSheet`.
- **Pattern `showDeleteConfirmDialog`** : `Future<bool?> confirmed = await showDeleteConfirmDialog(context: ctx, ...)` — reconduit.
- **Pattern `RecurringListNotifier.validate(id)`** : modèle exact pour `create()` (mutatingIds, try/catch, refreshList).

### Dépendances techniques

| Dépendance | Version | Usage prévu | Risque |
|------------|---------|-------------|--------|
| `freezed` / `json_serializable` | existants | `RecurringTransactionCreateRequest` | Bas — `build_runner` à relancer |
| `phosphor_flutter` | existant | Icônes `phosphorRepeat`, `phosphorNoteBlank`, `phosphorBell`, `phosphorToggleRight` | Nul |
| `flutter_riverpod` | existant | Appel `recurringListNotifierProvider` depuis `TransactionForm` | Nul |
| `go_router` | existant | `PopScope` + navigation — aucun nouveau usage | Nul |

**Aucune nouvelle dépendance externe requise.**

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Inconnues identifiées | 6 |
| Décisions prises | 6 |
| Nouvelles dépendances | 0 |
| Nouveaux fichiers à créer | 3 (`RecurringTransactionCreateRequest`, `BSheetTypeToggle`, méthode `_showFormBottomSheet`) |
| Fichiers existants à modifier (hors formulaires) | 4 (`RecurringTransactionRemoteDataSource`, `RecurringTransactionRepository`, `RecurringTransactionRepositoryRemote`, `RecurringListNotifier`) |
| Patterns réutilisés | 5 |
