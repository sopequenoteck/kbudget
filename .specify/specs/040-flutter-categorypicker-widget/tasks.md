# Tasks: Flutter — Widget CategoryPicker

**Input**: Design documents from `/specs/040-flutter-categorypicker-widget/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Inclus (SC-003 : 100% des scénarios d'acceptation couverts par des tests automatisés).

**Organization**: Tâches groupées par user story. Chaque story est indépendamment testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut tourner en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: US1 à US7 (correspond aux user stories de spec.md)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Foundational (Prérequis bloquant)

**Purpose**: Étendre SelectPicker avec le paramètre `emptyActionBuilder` pour permettre au CategoryPicker d'injecter le bouton "+ Créer" dans l'état vide du modal.

- [X] T001 Ajouter le paramètre `Widget Function(String searchTerm)? emptyActionBuilder` à SelectPicker : champ, constructeur, et condition dans `_buildItemsList` pour appeler le builder quand `filteredItems.isEmpty` au lieu d'afficher `emptyMessage` dans `flutter/lib/src/common_widgets/select_picker.dart`
- [X] T002 Ajouter les tests pour `emptyActionBuilder` dans le groupe existant du fichier `flutter/test/src/common_widgets/select_picker_test.dart` : (1) quand fourni et liste vide, le builder est rendu ; (2) quand non fourni, `emptyMessage` est affiché (backward-compat) ; (3) le `searchTerm` est correctement passé au builder

**Checkpoint**: SelectPicker supporte `emptyActionBuilder`. Tous les tests existants passent. Backward-compatible.

---

## Phase 2: US1+US2 — Sélection & Recherche (Priority: P1) 🎯 MVP

**Goal**: L'utilisateur peut ouvrir le CategoryPicker, voir les catégories avec emoji+couleur, en sélectionner une, et filtrer par recherche.

**Independent Test**: Fournir une liste de 10 catégories avec icônes et couleurs, sélectionner une catégorie, vérifier que le trigger affiche l'emoji et le nom, puis chercher un terme et vérifier le filtrage.

### Implementation

- [X] T003 [US1] Créer le widget `CategoryPicker` dans `flutter/lib/src/common_widgets/category_picker.dart` : fonction privée `_parseHexColor` (String hex → Color), mapping `Category` → `SelectPickerItem` (id, nom→label, icone→icon, couleur→color via parse hex), `StatelessWidget` qui compose `SelectPicker` avec les paramètres : `categories` (List\<Category\>), `selectedId`, `onChanged`, `label`, `placeholder` (défaut 'Sélectionner...'), `clearable`, `searchThreshold` (défaut 5), `enabled`, `onSearchChanged`, `onCreateRequested`, `validator`, `onSaved`, `autovalidateMode`. Quand `onCreateRequested` est fourni, passer un `emptyActionBuilder` qui construit le bouton "+ Créer « [terme] »" (style : icône add + texte primary color, centré, Semantics button:true). Le `emptyMessage` doit être 'Aucune catégorie'.

### Tests

- [X] T004 [US1] Écrire les tests widget pour la sélection dans `flutter/test/src/common_widgets/category_picker_test.dart` : helper `pumpCategoryPicker` (MaterialApp + AppTheme + Form), données de test (5 catégories avec id/nom/icone/couleur variés). Tests : (1) smoke — rendu avec label et placeholder ; (2) tap ouvre le modal avec toutes les catégories ; (3) tap sur une catégorie ferme le modal et appelle onChanged avec l'id ; (4) trigger affiche emoji + nom de la catégorie sélectionnée ; (5) changement de sélection met à jour le trigger ; (6) re-sélection de la même catégorie déjà choisie ferme le modal sans déclencher onChanged ; (7) catégorie sélectionnée est visuellement marquée (surlignée) dans le modal
- [X] T005 [US2] Écrire les tests widget pour la recherche dans `flutter/test/src/common_widgets/category_picker_test.dart` : (1) recherche visible si categories.length >= searchThreshold ; (2) recherche masquée si categories.length < searchThreshold ; (3) saisie filtre les catégories par nom (insensible à la casse) ; (4) terme sans résultat affiche 'Aucune catégorie' ; (5) saisie dans le champ de recherche appelle `onSearchChanged` avec le terme saisi

**Checkpoint**: CategoryPicker fonctionnel avec sélection et recherche. MVP utilisable dans un formulaire.

---

## Phase 3: US3 — Affichage riche (Priority: P2)

**Goal**: Chaque catégorie affiche son emoji et sa pastille de couleur pour identification rapide.

**Independent Test**: Fournir des catégories avec couleurs variées et vérifier que les pastilles circulaires sont rendues.

### Tests

- [X] T006 [P] [US3] Écrire les tests widget pour l'affichage riche dans `flutter/test/src/common_widgets/category_picker_test.dart` : (1) emoji affiché à gauche de chaque catégorie dans le modal ; (2) pastille circulaire colorée affichée (conversion hex → Color correcte) ; (3) catégorie sans couleur définie → pas de pastille circulaire affichée ; (4) trigger avec sélection affiche emoji + nom

**Checkpoint**: Affichage visuel complet avec emoji + couleur validé.

---

## Phase 4: US4+US5 — Effacement & Validation (Priority: P2)

**Goal**: Support du mode clearable et intégration avec la validation de formulaire.

**Independent Test**: Sélectionner une catégorie puis l'effacer. Soumettre un formulaire sans sélection avec validator required et vérifier le message d'erreur.

### Tests

- [X] T007 [P] [US4] Écrire les tests widget pour le mode clearable dans `flutter/test/src/common_widgets/category_picker_test.dart` : (1) bouton × visible quand clearable=true et catégorie sélectionnée ; (2) bouton × masqué quand rien n'est sélectionné ; (3) tap sur × remet la sélection à null et appelle onChanged(null)
- [X] T008 [P] [US5] Écrire les tests widget pour la validation dans `flutter/test/src/common_widgets/category_picker_test.dart` : (1) message d'erreur affiché quand validator échoue après submit ; (2) message d'erreur disparaît après sélection ; (3) auto-reset quand catégorie sélectionnée retirée de la liste (appelle onChanged(null))

**Checkpoint**: Effacement et validation fonctionnels. Widget intégrable dans un formulaire avec validation.

---

## Phase 5: US6 — Création de catégorie inline (Priority: P2)

**Goal**: Bouton "+ Créer « [terme] »" apparaît quand la recherche ne retourne aucun résultat et un callback est fourni.

**Independent Test**: Taper un terme sans correspondance et vérifier que le bouton apparaît. Taper un terme avec résultat partiel et vérifier que le bouton n'apparaît pas.

### Tests

- [X] T009 [P] [US6] Écrire les tests widget pour le bouton "+ Créer" dans `flutter/test/src/common_widgets/category_picker_test.dart` : (1) bouton affiché quand onCreateRequested fourni ET liste filtrée vide ; (2) tap sur bouton appelle onCreateRequested avec le terme et ferme le modal ; (3) bouton NON affiché quand des résultats partiels existent ; (4) bouton NON affiché quand onCreateRequested est null (message 'Aucune catégorie' affiché à la place)

**Checkpoint**: Bouton "+ Créer" fonctionnel. Le parent peut ouvrir un formulaire de création.

---

## Phase 6: US7 — Accessibilité (Priority: P3)

**Goal**: Labels sémantiques pour les technologies d'assistance.

**Independent Test**: Vérifier les Semantics nodes du widget avec les outils Flutter.

### Tests

- [X] T010 [P] [US7] Écrire les tests widget pour l'accessibilité dans `flutter/test/src/common_widgets/category_picker_test.dart` : (1) trigger a Semantics button:true avec label = nom catégorie ou placeholder ; (2) bouton "+ Créer" a Semantics button:true avec label descriptif

**Checkpoint**: Widget accessible avec sémantique complète.

---

## Phase 7: Polish & Edge Cases

**Purpose**: Tests edge cases cross-story et validation finale.

- [X] T011 [P] Écrire les tests edge cases dans `flutter/test/src/common_widgets/category_picker_test.dart` : (1) état désactivé (opacity réduite, tap ne fait rien) ; (2) thème sombre (rendu sans erreur) ; (3) liste vide (message 'Aucune catégorie') ; (4) nom de catégorie très long (truncation avec ellipsis)
- [X] T012 Lancer les tests Flutter et vérifier que tous passent : `cd flutter && flutter test test/src/common_widgets/category_picker_test.dart && flutter test test/src/common_widgets/select_picker_test.dart`

**Checkpoint**: Tous les tests passent. Widget prêt pour intégration dans les formulaires.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: Pas de dépendance — peut commencer immédiatement
- **Phase 2 (US1+US2)**: Dépend de Phase 1 (T001) — le widget utilise `emptyActionBuilder`
- **Phase 3 (US3)**: Tests uniquement — peut commencer après T003
- **Phase 4 (US4+US5)**: Tests uniquement — peut commencer après T003
- **Phase 5 (US6)**: Tests uniquement — peut commencer après T003
- **Phase 6 (US7)**: Tests uniquement — peut commencer après T003
- **Phase 7 (Polish)**: Dépend de toutes les phases précédentes

### User Story Dependencies

```
Phase 1 (T001, T002)
    │
    ▼
Phase 2 (T003) ─── implémentation complète du widget
    │
    ├──▶ T004, T005 (US1+US2 tests)
    ├──▶ T006 [P] (US3 tests)
    ├──▶ T007 [P] (US4 tests)
    ├──▶ T008 [P] (US5 tests)
    ├──▶ T009 (US6 tests)
    └──▶ T010 [P] (US7 tests)
         │
         ▼
    Phase 7 (T011, T012) ─── edge cases + validation finale
```

### Parallel Opportunities

Après T003, les groupes de tests suivants peuvent tourner en parallèle :
- T006 [US3] + T007 [US4] + T008 [US5] + T009 [US6] + T010 [US7] (groupes de tests indépendants, pas de dépendances)

---

## Parallel Example: Tests après T003

```bash
# Tous ces tests portent sur le même fichier mais des groupes de tests indépendants.
# En pratique, ils sont écrits séquentiellement dans le même fichier mais peuvent
# être développés et validés dans n'importe quel ordre.

T006 [US3]: Tests affichage riche (emoji + couleur)
T007 [US4]: Tests clearable
T008 [US5]: Tests validation
T009 [US6]: Tests bouton "+ Créer"
T010 [US7]: Tests accessibilité
```

---

## Implementation Strategy

### MVP First (US1+US2 uniquement)

1. Phase 1 : Ajouter `emptyActionBuilder` à SelectPicker (T001, T002)
2. Phase 2 : Créer CategoryPicker + tests sélection et recherche (T003, T004, T005)
3. **STOP et VALIDER** : Le widget est fonctionnel pour la sélection de catégorie
4. Intégrable dans les formulaires transaction/abonnement/dette

### Incremental Delivery

1. MVP (T001–T005) → Sélection + Recherche fonctionnelles
2. +T006 → Validation de l'affichage riche
3. +T007, T008 → Clear + validation formulaire
4. +T009 → Bouton "+ Créer"
5. +T010, T011, T012 → Accessibilité + edge cases + validation finale

---

## Notes

- T003 crée le widget complet (~80 lignes) avec tous les paramètres dès le départ. Les phases suivantes ajoutent des tests par user story.
- Le widget est un StatelessWidget wrapper — pas d'état interne. SelectPicker (FormField) gère l'état.
- Pas de nouvelle dépendance à installer. Seul import additionnel : `Category` depuis `domain/models/`.
- Commit recommandé après chaque phase complétée.
