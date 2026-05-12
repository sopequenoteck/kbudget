# Clarify Log — KKS-241 : Refonte 3 formulaires XL Flutter (bottom sheet 4-rows)

> Date : 2026-05-11
> Issue : KKS-241
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md §Contexte + A-003 | AppModal possède son propre header (handle + titre + fermer) — incompatible avec Row 1 de BottomSheet4RowsWidget | UX/Interaction | H | H | CRITIQUE | Bypass AppModal ; appel direct showModalBottomSheet dans app_router.dart | Auto |
| CL-002 | spec.md §FR-012 + FR-013 | RecurringTransaction existe en Flutter mais FR-012 interdisait tout appel couche application | Scope fonctionnel | H | H | CRITIQUE | FR-012 amendé : pas de NOUVEAU notifier — appel recurringListNotifierProvider existant autorisé | Auto |
| CL-003 | spec.md §US3 sc.4 | Pill "échéance" absente si non définie : mécanisme d'ajout non spécifié | UX/Interaction | M | H | HAUT | Pill toujours visible (état vide grisé) — confirmé par l'utilisateur | Interactif |
| CL-004 | spec.md §FR-015 | Input time reminder Flutter : pas d'équivalent `<input type="time">` natif inline | UX/Interaction | M | M | MOYEN | showTimePicker() Material acceptable pour ce champ secondaire | Auto |
| CL-005 | spec.md §US2 sc.1 | Toggle fréquence 2 boutons (Angular) vs 3 valeurs enum Frequency Flutter | UX/Interaction | M | M | MOYEN | Toggle 3 boutons (Hebdo / Mensuel / Annuel) dans topTrailing | Auto |

---

## Résolutions détaillées

### CL-001 — Conflit AppModal ↔ BottomSheet4RowsWidget

- **Catégorie** : UX/Interaction
- **Score** : CRITIQUE
- **Contexte** : Les 3 formulaires sont actuellement passés comme `child` de `AppModal.show()` via `app_router.dart._showModal`. `AppModal._ModalContent` ajoute son propre drag handle, son propre titre (`state.type.title(state.mode)`), ses `headerActions` (le toggle type/fréquence/debtType actuel) et un bouton fermer (×). `BottomSheet4RowsWidget` a également sa Row 1 : handle + titre + `topTrailing`. Les deux shells superposés produiraient un double header.
- **Analyse** : `app_router.dart` ligne 566 : `AppModal.show(context, title: ..., headerActions: ...)` → `_showBottomSheet` → `showModalBottomSheet(isScrollControlled: true, useSafeArea: true, builder: (_) => _ModalContent(...))`. La `_ModalContent` wrap le `child` dans un `SingleChildScrollView` avec `maxHeight: 0.9 * screenHeight`. Ces configurations sont reproductibles sans AppModal.
- **Décision** : `app_router.dart._showModal` est modifié pour les types `transaction`, `subscription`, `debt` (et `transfer` si concerné) : appel direct à `showModalBottomSheet` avec `isScrollControlled: true`, `useSafeArea: true`, le formulaire comme builder root. `AppModal` reste utilisé pour les autres modals non migrés (budget, etc.). La modification de `app_router.dart` est dans le périmètre (couche routing, pas data).
- **Impact sur spec.md** : FR-012 mis à jour — "couche routing (`app_router.dart`) peut être modifiée" ; A-003 marquée validée avec note sur la reproduction des paramètres.

---

### CL-002 — Récurrence TransactionForm et périmètre FR-012

- **Catégorie** : Scope fonctionnel
- **Score** : CRITIQUE
- **Contexte** : FR-012 (version initiale) interdisait "toute modification de la couche data, des notifiers, ni des repositories". FR-013 impose de porter la récurrence depuis Angular, ce qui requiert d'appeler `recurringListNotifierProvider.create()` à la validation de `TransactionForm`. Contradiction directe.
- **Analyse** : `RecurringTransaction`, `recurringListNotifierProvider`, `RecurringTransactionRepositoryRemote` et `RecurringTransactionRemoteDataSource` existent tous en Flutter (`flutter/lib/src/features/recurring/`). Le modèle `RecurringTransaction` a `montant`, `libelle`, `type`, `frequency`, `nextOccurrence`, `recurringActive`. Appeler un notifier existant n'est pas "créer ou modifier la couche data" — c'est consommer une infrastructure déjà en place.
- **Décision** : FR-012 amendé : "aucun NOUVEAU notifier, repository ou service créé". L'appel au `recurringListNotifierProvider` existant est explicitement autorisé depuis `TransactionForm`. FR-013 précisé : "à la validation, si `isRecurring = true`, appeler `recurringListNotifierProvider.create()` en plus de la création de transaction."
- **Impact sur spec.md** : FR-012 et FR-013 mis à jour.

---

### CL-003 — Pill "échéance" DebtForm : comportement état vide

- **Catégorie** : UX/Interaction
- **Score** : HAUT
- **Contexte** : La spec indiquait "pill optionnelle, absente si non définie initialement — tap 'ajouter échéance'" sans préciser le mécanisme exact de premier ajout. L'absence de la pill pose la question de la découvrabilité.
- **Analyse** : Angular n'a pas de champ `dueDate` — pas de référence de pattern. Deux options envisagées : (a) pill toujours visible avec état vide grisé, (b) icône dans `iconButtons` comme la Bell. L'option (a) est plus cohérente avec les autres pills meta (date, catégorie, compte) qui sont toujours visibles même sans valeur.
- **Décision** : confirmée par l'utilisateur — pill "Échéance" toujours présente dans `metaPills` Row 3. État vide : icône calendrier grisée + label "Échéance". État rempli : date formatée. Tap → `InlineDatePicker` en zone expand. La pill peut inclure un × pour effacer la date si définie.
- **Impact sur spec.md** : US3 scenario 4 mis à jour.

---

### CL-004 — Reminder time : widget Flutter

- **Catégorie** : UX/Interaction
- **Score** : MOYEN
- **Contexte** : Angular utilise `<input type="time" class="bsheet__input--time input-naked">` — un champ texte inline. Flutter n'a pas d'équivalent natif inline sans bibliothèque tierce.
- **Analyse** : NFR-004 interdit `showDatePicker()` Material pour la sélection de date (remplacé par InlineDatePicker). Le reminder time est un champ secondaire rare — appliquer le même niveau d'exigence serait disproportionné. `showTimePicker()` Material est natif, accessible, et évite l'ajout d'une dépendance. Constitution III (YAGNI) favorise cette solution.
- **Décision** : `showTimePicker()` Material est utilisé pour la sélection de l'heure de rappel, déclenché après sélection de la date dans l'expand Bell. NFR-004 est précisé pour ne s'appliquer qu'aux dates (showDatePicker).
- **Impact sur spec.md** : FR-015 mis à jour.

---

### CL-005 — Toggle fréquence SubscriptionForm : 3 valeurs vs 2 boutons

- **Catégorie** : UX/Interaction
- **Score** : MOYEN
- **Contexte** : Angular expose 2 boutons dans `topTrailing` (Mensuel / Annuel). L'enum Flutter `Frequency` a 3 valeurs (`hebdomadaire`, `mensuel`, `annuel`). Un toggle 2 boutons ne couvre pas la fréquence hebdomadaire.
- **Analyse** : Les abonnements hebdomadaires existent dans les données Flutter existantes (le `recurringListNotifier` les gère). Un toggle tronqué bloquerait l'édition d'un abonnement existant à fréquence hebdomadaire. La constitution IV (saisie rapide) favorise une sélection directe dans Row 1 plutôt qu'un expand supplémentaire.
- **Décision** : Toggle 3 boutons compacts (`Hebdo` / `Mensuel` / `Annuel`) dans `topTrailing`. Visuellement plus large mais couvre toutes les valeurs sans expand. Si l'espace est contraint, les labels courts (`H` / `M` / `A`) sont utilisés.
- **Impact sur spec.md** : US2 scenario 1 mis à jour.

---

## Points différés

> Aucun point différé — les 5 points identifiés ont été résolus dans cette session.

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Raison du report |
|---|--------|-----------------|-----------|--------|-------------|-------|------------------|
| — | — | — | — | — | — | — | — |

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 5 |
| Catégories couvertes | 2/11 (UX/Interaction, Scope fonctionnel) |
| Résolus automatiquement | 4 (CL-001, CL-002, CL-004, CL-005) |
| Résolus interactivement | 1 (CL-003) |
| Différés | 0 |
| Modifications spec.md | 7 (FR-012, FR-013, FR-015, US2 sc.1, US3 sc.4, A-003, contexte) |
