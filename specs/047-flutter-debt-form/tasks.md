# Tasks: Formulaire Dette Flutter

**Input**: Design documents from `/specs/047-flutter-debt-form/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

**Tests**: Non demandés dans la spec — non inclus.

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story concernée (US1, US2, US3, US4)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Setup (Infrastructure partagée)

**Purpose**: Ajouter les clés de localisation nécessaires à toutes les user stories

- [X] T001 Ajouter les clés i18n du formulaire dette (labels, placeholders, validation, confirmation) dans `flutter/lib/src/localization/app_fr.arb`
- [X] T002 Regénérer les fichiers de localisation via `flutter gen-l10n`

---

## Phase 2: User Story 1 - Créer une dette (Priority: P1) — MVP

**Goal**: L'utilisateur peut ouvrir la modale dette via le FAB (+), remplir les champs (personne, montant, date, catégorie optionnelle) avec le toggle Emprunt/Prêt, et sauvegarder une nouvelle dette.

**Independent Test**: Ouvrir la modale via FAB → remplir personne, montant → Enregistrer → vérifier que la dette apparaît dans la liste.

### Implementation for User Story 1

- [X] T003 [US1] Créer le widget DebtForm (ConsumerStatefulWidget) avec mode création : champs personne + montant côte à côte (Row flex:3/flex:2), date picker (défaut aujourd'hui), CategoryPicker optionnel, validation des champs obligatoires, boutons Annuler + Enregistrer, callback `onSaved` dans `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart`
- [X] T004 [US1] Créer la classe `_DebtFormConsumer` (ConsumerWidget) et ajouter le cas `ModalType.debt` dans `_buildModalChild()` pour connecter le formulaire au système de modale (lecture du subType DebtType et de l'entité depuis modalNotifierProvider) dans `flutter/lib/src/routing/app_router.dart`

**Checkpoint**: La création de dette fonctionne via la modale. Le toggle Emprunt/Prêt est fonctionnel dans le header.

---

## Phase 3: User Story 2 + User Story 4 - Modifier + Marquer remboursé (Priority: P2)

**Goal**: L'utilisateur peut ouvrir une dette existante en mode édition (champs pré-remplis), modifier les champs et sauvegarder. Il peut aussi basculer l'état de remboursement via un switch.

**Independent Test**: Taper sur une dette dans la liste → vérifier les champs pré-remplis → modifier le montant → sauvegarder → vérifier la mise à jour. Activer le switch Remboursé → sauvegarder → vérifier l'état.

### Implementation for User Story 2 + 4

- [X] T005 [US2] Ajouter le mode édition au DebtForm : pré-remplissage des champs depuis l'entité Debt existante via `_initFromEntity()`, changement du libellé du bouton de "Enregistrer" à "Modifier" (le toggle Emprunt/Prêt est positionné par le consumer via `modalNotifierProvider.subType`, initialisé par l'appelant lors de `open()`) dans `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart`
- [X] T006 [US4] Ajouter le switch "Remboursé" visible uniquement en mode édition, positionné après le CategoryPicker, avec état initial depuis `debt.rembourse`, inclus dans le payload de sauvegarde dans `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart`

**Checkpoint**: L'édition de dette et le marquage remboursé fonctionnent. Tous les champs sont correctement pré-remplis.

---

## Phase 4: User Story 3 - Supprimer une dette (Priority: P3)

**Goal**: L'utilisateur peut supprimer une dette depuis la modale d'édition, avec confirmation avant suppression définitive.

**Independent Test**: Ouvrir une dette en édition → appuyer sur l'icône de suppression → confirmer → vérifier la disparition de la liste.

### Implementation for User Story 3

- [X] T007 [US3] Ajouter le bouton de suppression (IconButton avec icône delete) visible uniquement en mode édition, positionné à gauche dans la barre de boutons, avec AlertDialog de confirmation avant appel du callback `onDeleted` dans `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart`

**Checkpoint**: La suppression de dette fonctionne avec confirmation. Toutes les user stories sont opérationnelles.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et cohérence

- [X] T008 Exécuter le scénario de validation quickstart.md sur device/simulateur (création, édition, remboursement, suppression)
- [X] T009 Vérifier la cohérence visuelle du formulaire dette avec les formulaires transaction et abonnement existants

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — démarrage immédiat
- **US1 (Phase 2)**: Dépend de Phase 1 (clés i18n) — BLOQUE les phases suivantes
- **US2 + US4 (Phase 3)**: Dépend de Phase 2 (formulaire créé)
- **US3 (Phase 4)**: Dépend de Phase 2 (formulaire créé) — logiquement indépendant de Phase 3 mais séquentiel (même fichier `debt_form.dart`)
- **Polish (Phase 5)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Dépend du Setup — aucune dépendance inter-story
- **US2 + US4 (P2)**: Dépend de US1 (le formulaire doit exister pour ajouter le mode édition)
- **US3 (P3)**: Dépend de US1 (le formulaire doit exister pour ajouter la suppression)

### Within Each User Story

- i18n avant widget (les clés sont référencées dans le formulaire)
- Widget avant intégration router (T003 avant T004)
- Mode création avant mode édition (T003-T004 avant T005-T006)

### Parallel Opportunities

- T003 et T004 sont séquentiels (T004 importe DebtForm de T003)
- T005 et T006 sont séquentiels (même fichier)
- Phase 3 et Phase 4 sont logiquement indépendantes mais séquentielles (T005, T006, T007 modifient tous `debt_form.dart`)

---

## Execution Order: Phase 2 → Phase 3 → Phase 4

```bash
# Séquentiel — toutes les tâches modifient debt_form.dart
# Étape 1 : Phase 2 (création)
Task: "T003 [US1] Créer le widget DebtForm"
Task: "T004 [US1] Intégrer dans app_router.dart"

# Étape 2 : Phase 3 (édition + remboursé)
Task: "T005 [US2] Ajouter le mode édition au DebtForm"
Task: "T006 [US4] Ajouter le switch Remboursé"

# Étape 3 : Phase 4 (suppression)
Task: "T007 [US3] Ajouter le bouton de suppression avec confirmation"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (i18n)
2. Compléter Phase 2: US1 — Créer une dette
3. **STOP et VALIDER**: Tester la création de dette via la modale
4. Livrable : formulaire dette fonctionnel en mode création

### Incremental Delivery

1. Setup + US1 → Création de dette fonctionnelle (MVP)
2. Ajouter US2 + US4 → Édition + remboursement
3. Ajouter US3 → Suppression avec confirmation
4. Polish → Validation finale
5. Chaque incrément ajoute de la valeur sans casser les précédents

---

## Notes

- Toutes les tâches modifient uniquement 3 fichiers : `debt_form.dart` (nouveau), `app_router.dart` (modifié), `app_fr.arb` (modifié)
- Le modèle de données, le notifier, le repository et le DAO sont déjà implémentés — aucune tâche data layer
- Le pattern à suivre est `SubscriptionForm` (ConsumerStatefulWidget avec les mêmes conventions)
- Le toggle Emprunt/Prêt est géré par le header de la modale (déjà configuré dans `ModalType.debt`), pas par le formulaire
- Commiter après chaque phase complète
