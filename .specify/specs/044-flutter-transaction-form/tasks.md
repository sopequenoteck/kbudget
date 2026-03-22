# Tasks: Flutter — Formulaire Transaction

**Input**: Design documents from `/specs/044-flutter-transaction-form/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Non demandés explicitement — pas de tâches de test générées.

**Organization**: Tasks groupées par user story pour livraison incrémentale.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (i18n)

**Purpose**: Ajouter les clés de localisation nécessaires au formulaire avant l'implémentation des widgets.

- [X] T001 Ajouter les clés i18n pour le formulaire transaction dans `flutter/lib/src/localization/app_fr.arb` — labels des champs (transactionFormLabelField, transactionFormAmountField, transactionFormDateField, transactionFormNoteField, transactionFormAccountPicker, transactionFormCategoryPicker), titres du modal (transactionFormTitle "Nouvelle transaction", transactionFormEditTitle "Modifier la transaction"), boutons d'action (transactionFormSaveButton "Enregistrer", transactionFormUpdateButton "Modifier", transactionFormDeleteButton "Supprimer"), dialog de confirmation suppression (transactionFormDeleteConfirmTitle, transactionFormDeleteConfirmMessage), messages de validation (validationRequired "Champ requis", validationAmountPositive "Le montant doit être positif", validationMaxLength "Maximum {max} caractères"), messages d'état vide (transactionFormNoAccounts "Créez un compte dans les paramètres", transactionFormNoCategories "Créez une catégorie d'abord"). Suivre le pattern existant des clés ARB du projet.

---

## Phase 3: User Story 1 — Créer une transaction (Priority: P1) MVP

**Goal**: L'utilisateur peut créer une transaction complète (Dépense/Recette) via un formulaire dans un modal ouvert depuis le FAB (+).

**Independent Test**: Ouvrir le formulaire via FAB, remplir tous les champs obligatoires, valider. La transaction apparaît dans la liste.

### Implementation for User Story 1

- [X] T002 [US1] Créer le widget TransactionForm (ConsumerStatefulWidget) dans `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` — Paramètres du widget : `Transaction? transaction` (null = mode création), `TransactionType type`, `ValueChanged<Transaction> onSaved`, `ValueChanged<String>? onDeleted`, `VoidCallback onCancelled`. State interne : TextEditingController pour libellé/montant/note, variables DateTime selectedDate (default: DateTime.now()), String? selectedAccountId (default: compte avec isDefault=true via ref.read(accountNotifierProvider)), String? selectedCategoryId, bool showErrors (false), bool isSubmitting (false). Layout : Column scrollable avec AppFormField+TextField pour libellé (InputDecoration.collapsed, max 255 chars), AppFormField+TextField pour montant (keyboardType: TextInputType.numberWithOptions(decimal: true), InputDecoration.collapsed), AppFormField+GestureDetector pour date (affiche date formatée dd/MM/yyyy via intl DateFormat, tap ouvre showDatePicker natif), SelectPicker pour compte (items depuis ref.watch(accountNotifierProvider).items filtrés actif, convertis en SelectPickerItem avec id/label=nom/icon=icone/color=parseHexColor(couleur)/secondaryText=solde formaté), CategoryPicker pour catégorie (categories depuis ref.watch(categoryNotifierProvider).items), AppFormField+TextField pour note (maxLines: 3, optionnel, max 500 chars). Bouton d'action en bas : ElevatedButton "Enregistrer" (i18n). Si aucun compte disponible : afficher message info (i18n transactionFormNoAccounts) à la place du SelectPicker. Idem pour catégories vides.

- [X] T003 [US1] Implémenter la validation et la soumission dans `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` — Méthodes de validation : _validateLibelle() retourne String? (null si valide, "Champ requis" si vide, "Maximum 255 caractères" si > 255), _validateMontant() (non vide, double.tryParse != null, > 0), _validateAccount() (non null), _validateCategory() (non null), _validateNote() (max 500 si non vide). Chaque AppFormField/SelectPicker/CategoryPicker reçoit showError: showErrors && _validateX() != null et errorMessage: _validateX() ?? ''. Méthode _onSubmit() : active showErrors=true, vérifie tous les validators, si un échoue → setState() et return. Si valide → setState isSubmitting=true, construit Transaction(id: pour création 'pending-${DateTime.now().millisecondsSinceEpoch}', montant: double.parse(montantController.text), libelle: libelleController.text.trim(), type: widget.type, date: selectedDate, note: noteController.text.trim().isEmpty ? null : noteController.text.trim(), categoryId: selectedCategoryId, accountId: selectedAccountId), appelle widget.onSaved(tx) dans try/catch. En cas d'erreur : setState isSubmitting=false, affiche SnackBar avec message d'erreur (FR-015). Bouton désactivé quand isSubmitting (CircularProgressIndicator à la place du texte).

- [X] T004 [US1] Brancher l'ouverture du modal de création dans `flutter/lib/src/features/transactions/presentation/transactions_screen.dart` — Ajouter une méthode _openTransactionForm({Transaction? transaction}) qui : crée un ValueNotifier<TransactionType> initialisé à transaction?.type ?? TransactionType.depense, appelle AppModal.show(context, title: transaction == null ? i18n.transactionFormTitle : i18n.transactionFormEditTitle, headerActions: ValueListenableBuilder<TransactionType>(valueListenable: typeNotifier, builder: (_, type, __) => AppToggle(labels: [i18n.depense, i18n.recette], selectedIndex: type == TransactionType.depense ? 0 : 1, onChanged: (i) => typeNotifier.value = i == 0 ? TransactionType.depense : TransactionType.recette)), child: ValueListenableBuilder<TransactionType>(valueListenable: typeNotifier, builder: (_, type, __) => TransactionForm(transaction: transaction, type: type, onSaved: (tx) async { if (transaction == null) await ref.read(transactionNotifierProvider.notifier).create(tx) else await ref.read(transactionNotifierProvider.notifier).update(tx); Navigator.of(context).pop(); }, onCancelled: () => Navigator.of(context).pop())), onClose: () => Navigator.of(context).pop()). Modifier le FAB existant pour appeler _openTransactionForm() sans paramètre (mode création).

**Checkpoint**: US1 complète — l'utilisateur peut créer une transaction via le FAB (+) avec toggle Dépense/Recette, tous les champs, validation on-submit et gestion d'erreur réseau.

---

## Phase 4: User Story 2 — Modifier une transaction existante (Priority: P2)

**Goal**: L'utilisateur peut modifier une transaction existante en appuyant dessus dans la liste. Le modal s'ouvre pré-rempli en mode édition.

**Independent Test**: Appuyer sur une transaction existante, modifier le montant, valider. La modification est persistée.

### Implementation for User Story 2

- [X] T005 [US2] Ajouter le mode édition au TransactionForm dans `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` — Dans initState(), si widget.transaction != null : libelleController.text = widget.transaction!.libelle, montantController.text = widget.transaction!.montant.toString(), noteController.text = widget.transaction!.note ?? '', selectedDate = widget.transaction!.date, selectedAccountId = widget.transaction!.accountId, selectedCategoryId = widget.transaction!.categoryId. Computed isEditMode = widget.transaction != null. Changer le texte du bouton d'action : isEditMode ? i18n.transactionFormUpdateButton : i18n.transactionFormSaveButton. Dans _onSubmit() pour le mode édition : construire le Transaction avec id = widget.transaction!.id (conserver l'id existant au lieu de générer un nouveau).

- [X] T006 [US2] Brancher l'ouverture du modal d'édition depuis la liste dans `flutter/lib/src/features/transactions/presentation/transactions_screen.dart` — Localiser le handler de tap sur les items de la liste (TransactionListItem ou équivalent). Au tap sur un item, appeler _openTransactionForm(transaction: transaction) avec l'objet Transaction. Vérifier que le type ajustement est exclu (si transaction.type == TransactionType.ajustement → ne pas ouvrir le formulaire, pattern Angular existant).

**Checkpoint**: US1 + US2 complètes — création et édition de transactions fonctionnelles.

---

## Phase 5: User Story 3 — Supprimer une transaction (Priority: P3)

**Goal**: L'utilisateur peut supprimer une transaction depuis le mode édition via un bouton avec confirmation.

**Independent Test**: Ouvrir une transaction en édition, appuyer sur supprimer, confirmer. La transaction disparaît de la liste.

### Implementation for User Story 3

- [X] T007 [US3] Ajouter le bouton supprimer et le dialog de confirmation dans `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` — En mode édition (isEditMode), afficher un TextButton.icon avec icône Icons.delete et texte i18n.transactionFormDeleteButton, style rouge (colorScheme.error). Positionné avant le bouton d'action principal (ou en bas séparé avec Divider). Au tap : afficher showDialog avec AlertDialog (titre: i18n.transactionFormDeleteConfirmTitle, contenu: i18n.transactionFormDeleteConfirmMessage, actions: TextButton "Annuler" → Navigator.pop(context, false) et TextButton "Supprimer" style rouge → Navigator.pop(context, true)). Si confirmé : appeler widget.onDeleted!(widget.transaction!.id). En mode création : ne PAS afficher le bouton supprimer (FR-010, acceptance scenario 4).

- [X] T008 [US3] Brancher le callback onDeleted dans `flutter/lib/src/features/transactions/presentation/transactions_screen.dart` — Dans _openTransactionForm(), ajouter le paramètre onDeleted au TransactionForm : onDeleted: (id) async { await ref.read(transactionNotifierProvider.notifier).delete(id); Navigator.of(context).pop(); }. Ce callback n'est passé que quand transaction != null (mode édition).

**Checkpoint**: US1 + US2 + US3 complètes — toutes les user stories fonctionnelles.

---

## Phase 6: Polish & Validation

**Purpose**: Vérification finale de qualité et cohérence.

- [X] T009 Exécuter `flutter analyze` dans `flutter/` et corriger tout warning ou erreur introduit par les nouveaux fichiers
- [X] T010 Valider les scénarios du quickstart.md — tester manuellement : création (FAB → form → submit), édition (tap item → form pré-rempli → modify → submit), suppression (edit → delete → confirm), validation (submit vide → erreurs inline), edge cases (toggle type, date future)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — peut démarrer immédiatement
- **US1 (Phase 3)**: Dépend de Phase 1 (i18n keys nécessaires)
- **US2 (Phase 4)**: Dépend de US1 (le widget TransactionForm doit exister)
- **US3 (Phase 5)**: Dépend de US2 (le mode édition doit exister pour ajouter le delete)
- **Polish (Phase 6)**: Dépend de toutes les user stories

### User Story Dependencies

- **US1 (P1)**: Dépend de T001 (i18n). Crée le widget + le branche au FAB.
- **US2 (P2)**: Dépend de US1 (étend le widget existant avec le mode édition).
- **US3 (P3)**: Dépend de US2 (ajoute le delete au mode édition).

### Within Each User Story

```
US1: T002 → T003 → T004 (séquentiels — même fichier pour T002/T003, T004 dépend du widget)
US2: T005 → T006 (séquentiels — T006 dépend du mode édition)
US3: T007 → T008 (séquentiels — T008 branche le callback créé en T007)
```

### Parallel Opportunities

- T001 (i18n) peut être fait en parallèle d'une lecture préparatoire du code existant
- T005 et T006 touchent des fichiers différents mais T006 a besoin du mode édition de T005
- Les user stories sont séquentielles (US1 → US2 → US3) car elles étendent le même widget

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. T001 : Setup i18n keys
2. T002 + T003 : Créer le widget TransactionForm complet avec validation
3. T004 : Brancher le FAB → modal
4. **STOP and VALIDATE** : Tester la création de transaction de bout en bout

### Incremental Delivery

1. Phase 1 (T001) → i18n prêt
2. Phase 3 (T002–T004) → Création fonctionne → **MVP livrable**
3. Phase 4 (T005–T006) → Édition fonctionne
4. Phase 5 (T007–T008) → Suppression fonctionne
5. Phase 6 (T009–T010) → Qualité validée

---

## Notes

- Aucun nouveau modèle Freezed requis — utilisation du Transaction existant
- Aucun nouveau provider Riverpod — utilisation de transactionNotifierProvider, accountNotifierProvider, categoryNotifierProvider existants
- Les widgets communs (AppModal, AppToggle, AppFormField, SelectPicker, CategoryPicker) sont tous disponibles (KKS-94 à KKS-97)
- Commit recommandé après chaque phase (ou chaque user story)
