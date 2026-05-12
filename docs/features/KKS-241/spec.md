# Feature Specification: Refonte 3 formulaires XL Flutter (bottom sheet 4-rows)

**Issue** : `KKS-241`
**Feature Branch** : `feature/flutter-formulaires-xl-v5`
**Created** : 2026-05-10
**Status** : Draft
**Priorité** : High (P2)
**Labels** : Feature
**Parent** : KKS-236

---

## Contexte

Les 3 formulaires XL de saisie (`TransactionForm`, `SubscriptionForm`, `DebtForm`) utilisent
actuellement un pattern ancien : champs `AppFormField` empilés verticalement, sélection de date
via `showDatePicker()` Material (dialog external), sélection de catégorie via `CategoryPicker`
(second bottom sheet imbriqué). Ce pattern est visuellement incohérent avec la charte DESIGN.md v5
et créé une expérience à 2 niveaux de bottom sheet pour la catégorie.

Cette feature migre les 3 formulaires vers le squelette composable `BottomSheet4RowsWidget`
(KKS-239) en consommant également `InlineDatePicker` et `CategorySelectExpand` (KKS-238) pour
une expérience entièrement inline. `TransactionForm` intègre également la récurrence (portée
depuis Angular). Aucune modification de la couche data/notifier.

---

## User Scenarios & Testing

### User Story 1 — Migration TransactionForm (Priorité : P1)

L'utilisateur ouvre le formulaire de saisie d'une transaction (dépense ou revenu) depuis le
bouton FAB (+). Il saisit le montant et le libellé directement dans le bottom sheet, sélectionne
la date via le picker inline qui se déploie en zone expand, et choisit la catégorie inline sans
ouvrir un second bottom sheet.

**Why this priority** : La transaction est l'action de saisie la plus fréquente dans l'app
(constitution IV — saisie en 2-3 interactions). C'est le formulaire avec le plus d'utilisateurs
actifs et le plus grand impact sur la perception UX quotidienne.

**Independent Test** : Peut être entièrement testé en isolation — ouvrir le TransactionForm,
saisir montant + libellé, toggler le type (dépense/revenu), sélectionner date inline et catégorie
inline, valider. La valeur est immédiatement démontrable sans que SubscriptionForm ou DebtForm
soient migrés.

**Acceptance Scenarios** :

1. **Given** l'utilisateur ouvre un nouveau TransactionForm, **When** il saisit un montant et un libellé, **Then** le montant est en hero (Row 2 gauche) et le libellé en Row 2 droite via `LibelleAutocompleteField`.
2. **Given** l'utilisateur tape la pill "date" en Row 3, **When** la zone expand s'ouvre, **Then** `InlineDatePicker` est affiché et `showDatePicker()` Material n'est pas déclenché.
3. **Given** l'utilisateur tape la pill "catégorie" en Row 3, **When** la zone expand s'ouvre, **Then** `CategorySelectExpand` s'affiche inline sans ouvrir de second bottom sheet.
4. **Given** `CategorySelectExpand` est en mode création de catégorie, **When** l'état `onCreatingChanged(true)` est déclenché, **Then** `footerEnabled = false` sur `BottomSheet4RowsWidget`.
5. **Given** le formulaire est en mode édition, **When** il est ouvert, **Then** une pill "Supprimer" est présente dans `footerLeading` (Row 4 gauche) et affiche un `ConfirmDialog` avant suppression.
6. **Given** l'utilisateur appuie sur le bouton retour Android avec la zone expand ouverte, **When** `onExpandClose` est déclenché, **Then** la zone expand se ferme sans fermer le bottom sheet.
7. **Given** l'utilisateur tape l'icône `phosphorNoteBlank` dans `iconButtons` Row 3, **When** la zone expand s'ouvre, **Then** un textarea de note s'affiche ; si une note a une valeur, elle est prévisualisée en `notePreview` entre Row 2 et Row 3.
8. **Given** l'utilisateur tape l'icône `phosphorRepeat` dans `iconButtons` Row 3 (mode création uniquement), **When** la zone expand s'ouvre, **Then** un toggle "Transaction récurrente" est affiché ; si activé, un sélecteur de fréquence (`hebdomadaire` / `mensuel` / `annuel`) et un `InlineDatePicker` de prochaine occurrence sont disponibles.

---

### User Story 2 — Migration SubscriptionForm (Priorité : P2)

L'utilisateur crée ou édite un abonnement depuis la liste des abonnements. Il saisit le nom et le
montant dans Row 2, sélectionne la fréquence via le toggle en Row 1, et configure date de début
et catégorie via les pills meta inline.

**Why this priority** : Les abonnements sont saisis moins fréquemment que les transactions mais
représentent un flux régulier. La migration améliore la cohérence visuelle. P2 car moins critique
que le flux transactionnel journalier.

**Independent Test** : Ouvrir SubscriptionForm, saisir nom + montant, toggler la fréquence (Row 1
trailing), sélectionner date et catégorie via pills, toggler l'état actif/inactif, valider.
Peut être testé indépendamment de TransactionForm et DebtForm.

**Acceptance Scenarios** :

1. **Given** l'utilisateur ouvre SubscriptionForm, **When** il consulte Row 1, **Then** le toggle de fréquence 3 boutons (`Hebdo` / `Mensuel` / `Annuel`) est affiché dans `topTrailing`, reflétant les 3 valeurs de l'enum `Frequency`.
2. **Given** l'utilisateur tape la pill "date de début" en Row 3, **When** la zone expand s'ouvre, **Then** `InlineDatePicker` est affiché inline.
3. **Given** l'utilisateur tape la pill "catégorie" en Row 3, **When** la zone expand s'ouvre, **Then** `CategorySelectExpand` s'affiche inline.
4. **Given** le formulaire est en mode édition, **When** l'utilisateur tape l'icône `phosphorToggleRight/Left` dans `iconButtons` Row 3, **Then** l'état `isActif` bascule (icône absente en mode création).
5. **Given** aucun compte n'est sélectionné, **When** l'utilisateur consulte Row 3, **Then** une pill "Devise" est disponible et ouvre un sélecteur de devise en zone expand (`currency` libre si pas de compte lié).
6. **Given** le formulaire est en mode édition, **When** il est ouvert, **Then** une pill "Supprimer" est présente dans `footerLeading`.

---

### User Story 3 — Migration DebtForm (Priorité : P3)

L'utilisateur crée ou édite une dette (emprunt ou prêt). Il saisit le montant en hero, le nom de
la personne en Row 2, configure les métadonnées (date, catégorie, compte, date d'échéance) via les
pills meta.

**Why this priority** : Les dettes sont les entrées les moins fréquentes. La migration est
nécessaire pour la cohérence visuelle globale mais ne débloque pas de flux critique.

**Independent Test** : Ouvrir DebtForm pour un prêt, saisir montant + personne, sélectionner
catégorie et compte via pills inline, valider. Testable sans que TransactionForm ou SubscriptionForm
soient migrés.

**Acceptance Scenarios** :

1. **Given** l'utilisateur ouvre DebtForm, **When** il consulte Row 1, **Then** le toggle type (`PRET` / `EMPRUNT`) est affiché dans `topTrailing` avec coloration montant dynamique (vert prêt / rouge emprunt).
2. **Given** l'utilisateur tape la pill "date" en Row 3, **When** la zone expand s'ouvre, **Then** `InlineDatePicker` est affiché inline.
3. **Given** l'utilisateur tape la pill "catégorie" en Row 3, **When** la zone expand s'ouvre, **Then** `CategorySelectExpand` s'affiche inline.
4. **Given** l'utilisateur ouvre DebtForm, **When** il consulte Row 3, **Then** la pill "Échéance" est toujours présente dans `metaPills` avec une icône calendrier grisée si aucune date n'est définie, et la date formatée si une `dueDate` existe. Tap → `InlineDatePicker` en zone expand.
5. **Given** l'utilisateur tape l'icône `phosphorBell` dans `iconButtons` Row 3, **When** la zone expand s'ouvre, **Then** `InlineDatePicker` + `input time` sont affichés pour `reminderDate` / `reminderTime`.
6. **Given** aucun compte n'est sélectionné, **When** l'utilisateur consulte Row 3, **Then** une pill "Devise" ouvre un sélecteur de devise en zone expand (`currency` libre si pas de compte lié). Le champ `includeInBalance` est supprimé de cette version.
7. **Given** le formulaire est en mode édition, **When** il est ouvert, **Then** `footerLeading` contient une pill "Supprimer" (danger) ET une pill "Remboursé / Non remboursé" (status) côte à côte.

---

### User Story 4 — Adaptation des tests existants (Priorité : P2)

Les tests widget existants pour les 3 formulaires sont adaptés au nouveau pattern
`BottomSheet4RowsWidget`. Le test `subscription_form_test.dart` existe. TransactionForm et
DebtForm n'ont pas de test widget à ce jour — en créer.

**Why this priority** : Les tests garantissent que la migration ne régresse pas sur les cas
nominaux et de validation. P2 car bloquant pour la merge.

**Independent Test** : `flutter test test/src/features/` doit passer à 100% après migration
de chaque formulaire.

**Acceptance Scenarios** :

1. **Given** les tests de `subscription_form_test.dart`, **When** la migration est terminée, **Then** les cas métier testés (création, édition, validation) sont conservés et passent ; les assertions structurelles liées à l'ancien pattern (`AppFormField`, `FilledButton`) sont mises à jour pour cibler les nouveaux widgets (`BottomSheet4RowsWidget`, pills, `Key('bsheet_submit')`).
2. **Given** `TransactionForm` migré, **When** les tests widget sont exécutés, **Then** les cas nominaux (création, édition, validation libellé vide, validation montant négatif) sont couverts.
3. **Given** `DebtForm` migré, **When** les tests widget sont exécutés, **Then** les cas nominaux (création, édition, delete confirm) sont couverts.

---

### Edge Cases

- Que se passe-t-il si aucun compte actif n'existe quand TransactionForm est ouvert ? → Afficher un message d'information dans la pill "compte" (comportement actuel à conserver).
- Que se passe-t-il si aucune catégorie n'existe quand la zone expand catégorie s'ouvre ? → `CategorySelectExpand` doit proposer la création directement.
- Que se passe-t-il si le clavier est ouvert et que l'utilisateur tape une pill meta ? → Le clavier DOIT se fermer avant l'ouverture de la zone expand (géré via `FocusScope.unfocus()`).
- Que se passe-t-il si l'utilisateur appuie sur le bouton retour Android sans zone expand ouverte ? → Le bottom sheet se ferme normalement (`canPop: true`).
- Que se passe-t-il si la dette est déjà remboursée à l'ouverture du formulaire ? → La pill "Remboursé" dans `footerLeading` est pré-activée (style `BSheetSubmitVariant.status` checked).
- Que se passe-t-il si la transaction est créée avec succès mais que `recurringListNotifier.create()` échoue ? → Afficher un `SnackBar` d'erreur spécifique à la récurrence sans annuler la transaction (la création de transaction est définitive ; la récurrence est un effet secondaire non-transactionnel).

---

## Requirements

### Functional Requirements

- **FR-001** : Les 3 formulaires (`TransactionForm`, `SubscriptionForm`, `DebtForm`) DOIVENT utiliser `BottomSheet4RowsWidget` comme squelette visuel unique.
- **FR-002** : La sélection de date DOIT utiliser `InlineDatePicker` dans la zone expand — `showDatePicker()` Material DOIT être supprimé.
- **FR-003** : La sélection de catégorie DOIT utiliser `CategorySelectExpand` dans la zone expand — `CategoryPicker` (second bottom sheet) DOIT être supprimé.
- **FR-004** : Les pills meta (Row 3) DOIVENT être scrollables horizontalement et afficher les valeurs sélectionnées (ex : "12/05/2026", "Alimentation", "LCL").
- **FR-005** : En mode édition, une pill "Supprimer" (danger) DOIT être présente dans `footerLeading` et déclencher un `ConfirmDialog` avant suppression. Pour `DebtForm` uniquement, une pill "Remboursé / Non remboursé" (status) DOIT être présente à côté.
- **FR-006** : Quand `CategorySelectExpand` passe en mode création (`onCreatingChanged(true)`), `footerEnabled` DOIT être `false` sur `BottomSheet4RowsWidget`.
- **FR-007** : Le toggle de type/fréquence/debtType DOIT être positionné dans le slot `topTrailing` de Row 1.
- **FR-008** : Le bouton retour Android avec zone expand ouverte DOIT fermer la zone expand via `PopScope` + `onExpandClose` sans fermer le bottom sheet.
- **FR-009** : `TransactionForm` DOIT conserver `LibelleAutocompleteField` dans le slot `libelleField` de Row 2.
- **FR-010** : `SubscriptionForm` DOIT exposer le toggle actif/inactif via une icône `phosphorToggleRight/Left` dans `iconButtons` Row 3, visible en mode édition uniquement.
- **FR-011** : Les tests widget DOIVENT couvrir les 3 formulaires après migration, nommage `should_[résultat]_when_[condition]`.
- **FR-012** : Aucun nouveau notifier, repository ou service créé de zéro. Modifications autorisées dans le périmètre : (a) couche présentation (widgets des 3 formulaires), (b) couche routing (`app_router.dart` — bypass AppModal), (c) ajout de la méthode `create()` aux fichiers existants : `RecurringListNotifier`, `RecurringTransactionRepository` (interface), `RecurringTransactionRepositoryRemote` (implémentation). Les 3 formulaires bypassent `AppModal` : `app_router.dart._showModal` est mis à jour pour appeler `showModalBottomSheet` directement (avec `isScrollControlled: true`, `useSafeArea: true`, gestion keyboard via `MediaQuery.viewInsetsOf`).
- **FR-013** : `TransactionForm` DOIT porter la fonctionnalité de récurrence : icône `phosphorRepeat` dans `iconButtons` Row 3 (mode création uniquement) → expand toggle + sélecteur fréquence (`hebdomadaire` / `mensuel` / `annuel`) + `InlineDatePicker` prochaine occurrence. À la validation, si `isRecurring = true`, appeler `recurringListNotifierProvider.create()` en plus de la création de transaction. La méthode `create()` est ajoutée à `RecurringListNotifier` et `RecurringTransactionRepository`/`RecurringTransactionRepositoryRemote` dans le cadre de cette feature.
- **FR-014** : `DebtForm` DOIT exposer `dueDate` comme pill "échéance" dans `metaPills` Row 3, ouvrant `InlineDatePicker` en zone expand.
- **FR-015** : `DebtForm` DOIT exposer `reminderDate` / `reminderTime` via icône `phosphorBell` dans `iconButtons` Row 3 → expand `InlineDatePicker` pour la date + `showTimePicker()` Material déclenché après sélection de date pour l'heure.
- **FR-016** : `SubscriptionForm` et `DebtForm` DOIVENT exposer une pill "Devise" en Row 3 ouvrant un sélecteur de devise en expand, visible uniquement quand aucun compte n'est sélectionné.
- **FR-017** : Le champ `includeInBalance` est supprimé de l'UI de `DebtForm` uniquement — le champ reste dans le modèle `Debt` (pas de migration Drift). La valeur est calculée silencieusement à la soumission : `includeInBalance = accountId != null` (logique déjà présente dans le code actuel). Aucune modification du modèle ni du schéma Drift.

### Non-Functional Requirements

- **NFR-001** : La saisie d'une transaction DOIT rester possible en ≤ 3 interactions (constitution IV — Mobile-First UX).
- **NFR-002** : Aucun appel réseau ni modification de la couche data (constitution III — YAGNI).
- **NFR-003** : Les widgets refactorisés DOIVENT utiliser `ConsumerStatefulWidget` + `ChangeDetectionStrategy` (pas de `setState` global inutile).
- **NFR-004** : Pas de `showDatePicker()` ni de `CategoryPicker` dans les 3 formulaires après migration.
- **NFR-005** : La zone expand DOIT s'animer via `AnimatedSize` (déjà géré par `BottomSheet4RowsWidget`).

### Key Entities

- **Transaction** : `id`, `montant`, `libelle`, `type` (dépense/revenu), `date`, `note?`, `categoryId?`, `accountId?`
- **Subscription** : `id`, `nom`, `montant`, `frequence`, `dateDebut`, `categoryId?`, `accountId?`, `isActif`
- **Debt** : `id`, `personne`, `montant`, `debtType` (prêt/emprunt), `date`, `categoryId?`, `accountId?`, `rembourse`, `currency?`, `reminderDate?`, `reminderTime?`, `dueDate?`, `includeInBalance` (calculé : `accountId != null`, non exposé UI)
- **BottomSheet4RowsWidget** : slots `title`, `topTrailing`, `amountField`, `libelleField`, `metaPills`, `expandedContent`, `footerLeading`, `onSubmit`
- **InlineDatePicker** : widget shared `common_widgets/inline_date_picker.dart`
- **CategorySelectExpand** : widget shared `common_widgets/category_select_expand.dart`, expose `onCreatingChanged`

---

## Success Criteria

### Measurable Outcomes

- **SC-001** : L'utilisateur peut saisir une transaction dépense (montant + libellé + valider) en ≤ 3 taps sans que le clavier masque le bouton Valider.
- **SC-002** : La sélection de catégorie dans les 3 formulaires ne déclenche plus l'ouverture d'un second bottom sheet.
- **SC-003** : La sélection de date ne déclenche plus de dialog Material — uniquement l'expand inline.
- **SC-004** : `flutter test test/src/features/` passe à 100% après migration des 3 formulaires.
- **SC-005** : Le footer est visuellement désactivé (Opacity 0.4) quand `CategorySelectExpand` est en mode création.
- **SC-006** : En mode édition, la pill "Supprimer" est présente dans Row 4 gauche pour les 3 formulaires ; `DebtForm` affiche également la pill "Remboursé / Non remboursé" dans le même footer.
- **SC-007** : Les seuls fichiers hors couche présentation modifiés sont : `app_router.dart` (routing), `RecurringListNotifier` (ajout `create()`), `RecurringTransactionRepository` (ajout `create()`), `RecurringTransactionRepositoryRemote` (implémentation `create()`). Aucun autre fichier `data/` ou `application/` n'est modifié.
- **SC-008** : `TransactionForm` en mode création expose l'icône récurrence dans `iconButtons` Row 3 ; en mode édition cette icône est absente.
- **SC-009** : Le champ `includeInBalance` est absent de `DebtForm` après migration.

---

## Assumptions

- **A-001** : `InlineDatePicker` et `CategorySelectExpand` (KKS-238) sont disponibles et fonctionnels dans `common_widgets/`. **Impact si faux** : la migration est bloquée — vérifier leur présence avant de commencer.
- **A-002** : `BottomSheet4RowsWidget` (KKS-239) est disponible et stable dans `common_widgets/`. **Impact si faux** : idem.
- **A-003** : ~~Validée~~ — Les 3 formulaires sont actuellement wrappés par `AppModal._showBottomSheet` qui passe `isScrollControlled: true` + `MediaQuery.viewInsetsOf` dans `_ModalContent`. Après migration, ces paramètres sont reproduits dans l'appel direct à `showModalBottomSheet` dans `app_router.dart`.
- **A-004** : `LibelleAutocompleteField` (TransactionForm) est compatible avec le slot `libelleField` de `BottomSheet4RowsWidget` (il s'agit d'un widget pur sans dépendance sur la structure parente). **Impact si faux** : refactoring supplémentaire du field nécessaire.
- **A-005** : La suppression via `ConfirmDialog` dans le footer gauche est identique pour les 3 formulaires — `ConfirmDialog` est déjà disponible dans `common_widgets/`. **Impact si faux** : créer ou adapter le dialog.
