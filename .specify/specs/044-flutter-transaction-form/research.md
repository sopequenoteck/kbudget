# Research: Flutter — Formulaire Transaction

**Feature**: `044-flutter-transaction-form` | **Date**: 2026-02-23

## R1: Gestion du state du formulaire

**Decision**: `ConsumerStatefulWidget` avec `TextEditingController` + variables d'état locales. Pas de Notifier séparé pour le formulaire.

**Rationale**: Le formulaire est un widget éphémère (vit le temps du modal). Son état (texte des champs, sélections) n'a pas besoin d'être partagé ni persisté. Les `TextEditingController` sont le pattern standard Flutter pour les champs texte. Les sélections (accountId, categoryId, date, type) sont des variables `State`. La soumission appelle directement le `TransactionNotifier` existant via callback.

**Alternatives considered**:
- **FormNotifier (Riverpod Notifier séparé)** : Over-engineering pour un formulaire simple. Ajoute de la complexité sans bénéfice (pas de state partagé, pas de side-effects complexes). Rejeté per principe III (Simplicité & YAGNI).
- **Flutter Form + GlobalKey\<FormState\>** : Viable mais les widgets communs (SelectPicker, CategoryPicker) n'utilisent pas FormField de manière homogène. Préférer la validation manuelle avec `showErrors` flag.

## R2: Intégration modal + toggle type

**Decision**: Le toggle type est géré par le parent (`TransactionsScreen`) via un `ValueNotifier<TransactionType>` local. Il est passé comme `headerActions` à `AppModal.show()`. Le formulaire reçoit le type courant via callback.

**Rationale**: Pattern identique à l'Angular (type géré par le parent/shell, pas par le form). `AppModal.show()` accepte un `headerActions` widget — `AppToggle` y est placé naturellement. Le parent gère le state du type car il survit aux interactions dans le modal.

**Alternatives considered**:
- **Type géré dans le formulaire** : Impliquerait de remonter le toggle dans le header via un pattern complexe. Le modal ne donne pas accès au header depuis le child. Rejeté pour raison technique.
- **Provider global pour le type** : Over-engineering. Le type n'est pertinent que pendant la durée de vie du modal. Rejeté.

## R3: Validation des champs

**Decision**: Validation on-submit avec flag `showErrors`. Chaque champ a une méthode de validation retournant `String?` (null = valide). Le flag `showErrors` est activé au premier submit pour afficher les erreurs.

**Rationale**: Pattern simple et prévisible. L'utilisateur n'est pas interrompu pendant la saisie. Les erreurs apparaissent au moment de la soumission, aligné avec FR-012. Les widgets `AppFormField` supportent `showError` + `errorMessage` nativement.

**Validators**:
- `libelle` : non vide, max 255 caractères
- `montant` : non vide, parsable en double, > 0
- `date` : non null (toujours pré-remplie, donc toujours valide)
- `accountId` : non null
- `categoryId` : non null
- `note` : optionnel, max 500 caractères

**Alternatives considered**:
- **Validation on-blur** : Meilleure UX mais plus complexe (FocusNode sur chaque champ). Peut être ajouté en itération future. Non requis par la spec (FR-012 = "lors de la soumission").

## R4: Sélecteur de date

**Decision**: Utiliser `showDatePicker` natif Flutter, déclenché par un tap sur un `AppFormField` non-éditable affichant la date formatée.

**Rationale**: Pattern standard Flutter. Le date picker natif est adapté mobile (Material Design). La date est formatée via `intl` (déjà dans les dépendances). Pas besoin de widget custom.

**Format d'affichage**: `dd/MM/yyyy` (convention française, ex: "23/02/2026")

**Alternatives considered**:
- **Package flutter_datetime_picker** : Dépendance externe inutile. Le date picker natif suffit. Rejeté per principe III.
- **TextField avec parsing manuel** : Mauvaise UX mobile (saisie de date au clavier). Rejeté per principe IV.

## R5: Gestion du chargement pendant la soumission

**Decision**: Flag `isSubmitting` dans le state du widget. Pendant la soumission : bouton désactivé + indicateur de chargement. En cas d'erreur : message affiché via SnackBar, formulaire reste ouvert (FR-015).

**Rationale**: Empêche la double soumission. Feedback visuel standard. Le formulaire conserve les données en cas d'erreur réseau.

**Alternatives considered**:
- **Pas de loading state** : Risque de double soumission. Rejeté.

## R6: Pré-remplissage du compte par défaut

**Decision**: En mode création, charger les comptes via `ref.read(accountNotifierProvider)`. Si un compte a `isDefault == true`, le pré-sélectionner. Sinon, laisser le champ vide.

**Rationale**: Aligné avec FR-007. Le `AccountNotifier` est déjà chargé (l'utilisateur vient de la liste de transactions qui l'utilise probablement déjà). Pas de requête supplémentaire.

## R7: Localisation (i18n)

**Decision**: Ajouter les clés i18n dans `app_fr.arb` pour les labels du formulaire, les messages de validation et les boutons d'action.

**Rationale**: Le projet utilise déjà `intl` avec des fichiers ARB. Suivre le pattern existant.

**Clés nécessaires** (estimées):
- `transactionFormTitle` / `transactionFormEditTitle`
- `transactionFormLabelField` / `transactionFormAmountField` / `transactionFormDateField` / `transactionFormNoteField`
- `transactionFormAccountPicker` / `transactionFormCategoryPicker`
- `transactionFormSaveButton` / `transactionFormUpdateButton` / `transactionFormDeleteButton`
- `transactionFormDeleteConfirmTitle` / `transactionFormDeleteConfirmMessage`
- Validation: `validationRequired` / `validationAmountPositive` / `validationMaxLength`
