# Tasks: Système de Catégories

**Input**: Design documents from `/specs/018-category-system/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/category-api.yaml

**Tests**: Inclus en Phase 8 (constitution V — Testabilité).

**Organization**: Tasks groupées par user story. Chaque story est implémentable et testable indépendamment après la phase Foundational.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut tourner en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1–US5)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Foundational — Backend (Blocking Prerequisites)

**Purpose**: Migration DB, champ `isSystem`, gardes de protection, seeding. DOIT être complet avant toute user story.

- [x] T001 Créer la migration Flyway `api/src/main/resources/db/migration/V5__add_is_system_and_seed.sql` — (1) tronquer les noms > 30 chars (`UPDATE categories SET nom = LEFT(nom, 30) WHERE LENGTH(nom) > 30`), (2) réduire `nom` à `VARCHAR(30)`, (3) ajouter colonne `is_system BOOLEAN DEFAULT FALSE NOT NULL`, (4) remplacer contrainte `uq_categories_nom_user` par index `UNIQUE (LOWER(nom), user_id)`, (5) insérer catégories système "Abonnement" (🔄, #6366f1) et "Dette" (💰, #ef4444) pour chaque utilisateur existant, (6) backfill : attribuer la catégorie système aux abonnements/dettes existants sans catégorie (`UPDATE subscriptions SET category_id = (SELECT id FROM categories WHERE nom = 'Abonnement' AND is_system = true AND user_id = subscriptions.user_id) WHERE category_id IS NULL`, idem pour debts avec "Dette")
- [x] T002 [P] Ajouter le champ `isSystem` (Boolean, default false) à l'entité JPA `api/src/main/java/fr/kksdev/budget/api/model/Category.java` — column `is_system`, mapper vers le champ DB
- [x] T003 [P] Ajouter le champ `isSystem` (boolean) au DTO `api/src/main/java/fr/kksdev/budget/api/dto/response/CategoryResponse.java` et mettre à jour le mapping `toResponse()` dans CategoryService
- [x] T004 [P] Mettre à jour la validation dans `api/src/main/java/fr/kksdev/budget/api/dto/request/CategoryRequest.java` — changer `@Size(max = 255)` en `@Size(max = 30)` sur le champ `nom`
- [x] T005 [P] Ajouter les queries au repository `api/src/main/java/fr/kksdev/budget/api/repository/CategoryRepository.java` — `findByNomIgnoreCaseAndUserId(String nom, UUID userId)`, `findByUserIdAndIsSystemTrue(UUID userId)`, `existsByNomIgnoreCaseAndUserId(String nom, UUID userId)`, `existsByNomIgnoreCaseAndUserIdAndIdNot(String nom, UUID userId, UUID id)`
- [x] T006 Mettre à jour `api/src/main/java/fr/kksdev/budget/api/service/CategoryService.java` — (1) gardes isSystem sur `update()` et `delete()` (lever `IllegalArgumentException` si `isSystem`, logger WARN tentative — `IllegalArgumentException` est mappé → 400 par le `GlobalExceptionHandler` existant), (2) remplacer les checks d'unicité par des versions case-insensitive, (3) ajouter méthode `seedSystemCategories(User user)` créant les 2 catégories système (logger INFO seeding), (4) ajouter méthode `findSystemCategoryByNom(String nom, UUID userId)` pour résoudre la catégorie par défaut. Logging : INFO sur create/update/delete réussis, WARN sur tentative modification/suppression catégorie système, ERROR sur échec seeding (constitution VI — Observabilité)
- [x] T007 Mettre à jour `api/src/main/java/fr/kksdev/budget/api/service/AuthService.java` — appeler `categoryService.seedSystemCategories(user)` après `userRepository.save(user)` dans la méthode `register()`
- [x] T008 [P] Créer la constante de palette de couleurs dans `api/src/main/java/fr/kksdev/budget/api/config/CategoryConstants.java` — liste de 12 couleurs hex prédéfinies (`#ef4444`, `#f97316`, `#f59e0b`, `#84cc16`, `#22c55e`, `#14b8a6`, `#06b6d4`, `#3b82f6`, `#6366f1`, `#8b5cf6`, `#ec4899`, `#78716c`), méthode `randomColor()`

**Checkpoint**: Backend complet — `mvn clean compile` doit passer. Les endpoints existants fonctionnent avec le nouveau champ `isSystem`.

---

## Phase 2: Foundational — Frontend (Blocking Prerequisites)

**Purpose**: Mise à jour des modèles et constantes frontend.

- [x] T009 [P] Mettre à jour le modèle `app/src/app/core/models/category.model.ts` — ajouter `isSystem: boolean` à l'interface `Category`
- [x] T010 [P] Créer les constantes frontend dans `app/src/app/core/constants/category.constants.ts` — palette de 12 couleurs hex (identique backend), liste de ~35 emojis budget prédéfinis groupés par thème, fonction `randomColor()`

**Checkpoint**: Foundation frontend prête — modèles et constantes disponibles pour les composants.

---

## Phase 3: User Story 1 — Sélectionner une catégorie existante (Priority: P1) 🎯 MVP

**Goal**: L'utilisateur peut sélectionner une catégorie existante via un autocomplete avec filtrage en temps réel dans les formulaires de saisie.

**Independent Test**: Créer une transaction avec une catégorie existante via le picker autocomplete. Vérifier que le filtrage fonctionne et que la catégorie est bien associée à la transaction.

### Implementation

- [x] T011 [US1] Créer le composant `CategoryPicker` (ControlValueAccessor) dans `app/src/app/shared/components/category-picker/` — le composant injecte `CategoryService` et charge les catégories via `getAll()` (convertir en signal via `toSignal()`). Input texte avec dropdown filtré, affiche emoji + nom pour chaque catégorie, sélection émet le categoryId, affiche la catégorie sélectionnée (emoji + nom), état vide "Aucune catégorie", filtrage case-insensitive via `computed()`, support clavier (ArrowUp/Down, Enter, Escape), fermeture au clic extérieur
- [x] T012 [US1] Remplacer le `<select>` par `<app-category-picker>` dans `app/src/app/features/transactions/components/transaction-form/transaction-form.html` et `transaction-form.ts` — supprimer le `toSignal(categoryService.getAll())` local (le picker le gère), brancher via `formControlName="categoryId"`
- [x] T013 [P] [US1] Remplacer le `<select>` par `<app-category-picker>` dans `app/src/app/features/subscriptions/components/subscription-form/subscription-form.html` et `subscription-form.ts`
- [x] T014 [P] [US1] Remplacer le `<select>` par `<app-category-picker>` dans `app/src/app/features/debts/components/debt-form/debt-form.html` et `debt-form.ts`

**Checkpoint**: Le picker autocomplete fonctionne dans les 3 formulaires. Sélection d'une catégorie existante = 2 interactions (taper + cliquer).

---

## Phase 4: User Story 2 — Créer une catégorie à la volée (Priority: P1)

**Goal**: L'utilisateur peut créer une nouvelle catégorie directement depuis le picker, sans quitter le formulaire de saisie. Modal avec nom pré-rempli, grille d'emojis, couleur aléatoire.

**Independent Test**: Taper un nom inexistant dans le picker → cliquer "Créer X" → choisir un emoji → valider → la catégorie est créée et sélectionnée automatiquement.

### Implementation

- [x] T015 [P] [US2] Créer le composant `EmojiGrid` dans `app/src/app/shared/components/emoji-grid/` — grille 6 colonnes de ~35 emojis budget prédéfinis (depuis `category.constants.ts`), input `selected` (emoji courant), output `emojiSelected` (string), style bouton avec état actif, support clavier
- [x] T016 [US2] Créer le composant `CategoryForm` dans `app/src/app/shared/components/category-form/` — formulaire avec champ nom (max 30, pré-rempli via input), EmojiGrid pour sélection icône, palette de couleurs : 12 pastilles rondes cliquables (depuis `CATEGORY_COLORS` de `category.constants.ts`) avec couleur aléatoire pré-sélectionnée en mode création, boutons Créer/Annuler, appel `CategoryService.create()` au submit, outputs `saved(Category)` et `cancelled()`
- [x] T017 [US2] Ajouter le flux de création inline au `CategoryPicker` dans `app/src/app/shared/components/category-picker/` — bouton "Créer {searchTerm}" visible quand la recherche ne matche aucune catégorie exacte (comparaison case-insensitive), ouvre le `CategoryForm` en modal (via le composant `<app-modal>` directement, pas via ModalService — le picker gère son propre état modal en interne), après création réussie: rafraîchir la liste via `CategoryService.refreshTrigger`, auto-sélectionner la nouvelle catégorie

**Checkpoint**: Création à la volée fonctionnelle dans tous les formulaires. Flux complet en <10 secondes.

---

## Phase 5: User Story 3 — Afficher les catégories dans les listes (Priority: P2)

**Goal**: Les listes de transactions, abonnements et dettes affichent l'emoji de la catégorie de chaque item pour une identification visuelle rapide.

**Independent Test**: Consulter la liste des transactions → chaque transaction catégorisée affiche l'emoji à côté du libellé.

### Implementation

- [x] T018 [P] [US3] Mettre à jour la liste des transactions dans `app/src/app/features/transactions/transactions.ts` et `transactions.html` — passer `item.category?.icone ?? '📋'` comme `icon` au composant `ListItem` pour chaque transaction (fallback '📋' car `ListItem.icon` est `input.required<string>()`, ne peut pas être undefined)
- [x] T019 [P] [US3] Mettre à jour la liste des abonnements dans `app/src/app/features/subscriptions/subscriptions.ts` et `subscriptions.html` — passer `item.category?.icone ?? '🔄'` comme `icon` au composant `ListItem` (fallback emoji système "Abonnement")
- [x] T020 [P] [US3] Mettre à jour la liste des dettes dans `app/src/app/features/debts/debts.ts` et `debts.html` — passer `item.category?.icone ?? '💰'` comme `icon` au composant `ListItem` (fallback emoji système "Dette")
- [x] T021 [US3] Mettre à jour le dashboard dans `app/src/app/features/dashboard/dashboard.ts` et `dashboard.html` — afficher l'emoji de catégorie dans les sections "transactions récentes", "abonnements actifs" et "dettes actives"

**Checkpoint**: Toutes les listes affichent l'emoji de catégorie. Items sans catégorie : pas d'emoji (espace vide ou icône par défaut).

---

## Phase 6: User Story 4 — Catégories système par défaut (Priority: P2)

**Goal**: Les abonnements et dettes créés sans catégorie explicite reçoivent automatiquement leur catégorie système respective ("Abonnement" / "Dette").

**Independent Test**: `POST /api/subscriptions` sans `categoryId` → la réponse contient `category: { nom: "Abonnement", icone: "🔄", isSystem: true }`.

### Implementation

- [x] T022 [US4] Mettre à jour `api/src/main/java/fr/kksdev/budget/api/service/SubscriptionService.java` — dans la méthode `create()`, si `categoryId` est null, résoudre la catégorie système "Abonnement" via `categoryService.findSystemCategoryByNom("Abonnement", userId)` et l'attribuer automatiquement
- [x] T023 [P] [US4] Mettre à jour `api/src/main/java/fr/kksdev/budget/api/service/DebtService.java` — dans la méthode `create()`, si `categoryId` est null, résoudre la catégorie système "Dette" via `categoryService.findSystemCategoryByNom("Dette", userId)` et l'attribuer automatiquement

**Checkpoint**: 100% des abonnements/dettes sans catégorie explicite reçoivent leur catégorie système. Vérifiable via API.

---

## Phase 7: User Story 5 — Gérer ses catégories dans Paramètres (Priority: P3)

**Goal**: L'utilisateur peut consulter, modifier et supprimer ses catégories depuis une section dédiée dans l'écran Paramètres.

**Independent Test**: Naviguer vers /settings → voir la liste des catégories → modifier le nom/emoji d'une catégorie → vérifier que le changement se reflète.

### Implementation

- [x] T024 [US5] Créer les routes settings dans `app/src/app/features/settings/settings.routes.ts` — route par défaut affichant la page paramètres
- [x] T025 [US5] Créer la page Settings dans `app/src/app/features/settings/` (settings.ts, settings.html, settings.scss) — section "Catégories" listant toutes les catégories (emoji, nom, couleur, badge "Système" si isSystem), bouton modifier sur les catégories personnalisées (ouvre CategoryForm en modal via ModalService — ajouter `'category'` au `ModalType`), bouton supprimer (avec confirmation "Cette catégorie sera dissociée de tous les items liés (transactions, abonnements, dettes)" — pas de comptage d'items, simplification YAGNI), catégories système en lecture seule (pas de bouton modifier/supprimer)
- [x] T025b [US5] Mettre à jour `app/src/app/core/services/modal.service.ts` — ajouter `'category'` au type `ModalType`, ajouter titres dans `CREATE_TITLES` ("Nouvelle catégorie") et `EDIT_TITLES` ("Modifier la catégorie")
    > Note: ID T025b car inséré après rédaction initiale. Renumérotation différée pour éviter les cascades.
- [x] T026 [US5] Adapter le composant `CategoryForm` (`app/src/app/shared/components/category-form/`) pour supporter le mode édition — input optionnel `category` (Category existante), pré-remplir nom + emoji + couleur, champ nom modifiable, EmojiGrid avec emoji courant sélectionné, palette de couleurs : 12 pastilles rondes cliquables (depuis `CATEGORY_COLORS` de `category.constants.ts`) avec bordure active sur la couleur sélectionnée (inline dans le template, pas de composant séparé — 12 items = trop simple pour un composant), appel `CategoryService.update()` au lieu de `create()` en mode édition
- [x] T027 [US5] Ajouter le lien "Paramètres" à la navigation Shell dans `app/src/app/shared/components/shell/shell.html` et `shell.ts` — icône ⚙️, route `/settings`, positionné avant Déconnexion
- [x] T028 [US5] Ajouter la route `/settings` dans `app/src/app/app.routes.ts` — lazy-loaded vers `settings.routes.ts`, protégée par `authGuard` (enfant de Shell)

**Checkpoint**: Page Paramètres fonctionnelle. CRUD complet sur les catégories personnalisées. Catégories système protégées (lecture seule).

---

## Phase 8: Tests (Constitution V — Testabilité)

**Purpose**: Tests unitaires et d'intégration couvrant les nouvelles fonctionnalités. Pattern AAA, nommage `should_[résultat]_when_[condition]`.

### Backend

- [x] T029 [P] Tests unitaires `CategoryService` dans `api/src/test/java/.../service/CategoryServiceTest.java` — (1) `should_throw_when_deleteSystemCategory` (garde isSystem), (2) `should_throw_when_updateSystemCategory`, (3) `should_seedSystemCategories_when_newUser` (vérifie 2 catégories créées), (4) `should_rejectDuplicate_when_caseInsensitiveName` (unicité), (5) `should_findSystemCategory_when_nomAndUserExist`
- [x] T030 [P] Tests unitaires `SubscriptionService` — `should_assignSystemCategory_when_noCategoryProvided`
- [x] T031 [P] Tests unitaires `DebtService` — `should_assignSystemCategory_when_noCategoryProvided`
- [x] T031b [P] Tests d'intégration endpoints catégories dans `api/src/test/java/.../controller/CategoryControllerTest.java` (constitution V — Testabilité) — (1) `should_returnAllCategories_when_authenticated` (GET 200, inclut isSystem), (2) `should_createCategory_when_validRequest` (POST 201), (3) `should_return400_when_duplicateName` (POST 400 case-insensitive), (4) `should_return400_when_deleteSystemCategory` (DELETE 400), (5) `should_return400_when_updateSystemCategory` (PUT 400), (6) `should_return404_when_categoryNotFound` (GET/PUT/DELETE 404), (7) `should_return401_when_noToken` (GET 401). Utiliser `@SpringBootTest` + `MockMvc` + base H2 ou Testcontainers.

### Frontend

- [x] T032 [P] Tests composant `CategoryPicker` dans `app/src/app/shared/components/category-picker/category-picker.spec.ts` — (1) affiche les catégories filtrées, (2) sélection émet le categoryId, (3) bouton "Créer" visible quand aucun match exact, (4) état vide sans catégories
- [x] T032b [P] Tests composant `CategoryForm` dans `app/src/app/shared/components/category-form/category-form.spec.ts` — (1) mode création : nom pré-rempli, couleur aléatoire pré-sélectionnée, emoji sélectionnable, (2) mode édition : champs pré-remplis avec catégorie existante, appel `update()` au submit, (3) validation : rejet nom vide et nom > 30 chars, (4) catégorie système : champs non modifiables si `isSystem`

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Validation, build, cohérence.

- [x] T033 [P] Vérifier le build backend et les tests — `cd api && mvn clean compile && mvn test`
- [x] T034 [P] Vérifier le build frontend et le lint — `cd app && ng build && ng lint`
- [x] T035 Valider les scénarios du quickstart.md — exécuter les 12 points de validation manuellement

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational Backend)**: Aucune dépendance — démarrer immédiatement
- **Phase 2 (Foundational Frontend)**: Aucune dépendance — parallélisable avec Phase 1
- **Phase 3 (US1)**: Dépend de Phase 1 + Phase 2
- **Phase 4 (US2)**: Dépend de Phase 3 (US1) — le picker existe, on ajoute la création
- **Phase 5 (US3)**: Dépend de Phase 1 + Phase 2 — parallélisable avec US1/US2
- **Phase 6 (US4)**: Dépend de Phase 1 uniquement (backend only) — parallélisable avec US1/US2/US3
- **Phase 7 (US5)**: Dépend de Phase 4 (US2, pour le CategoryForm) — ou Phase 1+2 si on construit la page Paramètres avant le form
- **Phase 8 (Tests)**: Dépend de Phase 1-7 (code implémenté)
- **Phase 9 (Polish)**: Dépend de toutes les phases précédentes

### User Story Dependencies

```
Phase 1+2 (Foundational)
    ├── US1 (P1: Sélection autocomplete)
    │     └── US2 (P1: Création à la volée)
    │           └── US5 (P3: Gestion Paramètres — réutilise CategoryForm)
    ├── US3 (P2: Affichage emoji — parallèle avec US1)
    └── US4 (P2: Catégorie par défaut — parallèle avec US1, backend only)
```

### Within Each User Story

- Models/constantes avant composants
- Composants shared avant intégration dans les features
- Backend avant frontend quand il y a dépendance API

### Parallel Opportunities

- **Phase 1**: T002/T003/T004/T005/T008 en parallèle (fichiers différents)
- **Phase 2**: T009/T010 en parallèle
- **Phase 3**: T013/T014 en parallèle (après T012)
- **Phase 5**: T018/T019/T020 tous en parallèle
- **Phase 6**: T022/T023 en parallèle
- **Phase 8**: T029/T030/T031/T031b/T032/T032b tous en parallèle (fichiers de test indépendants)
- **Phase 9**: T033/T034 en parallèle
- **Cross-phase**: US3 et US4 parallélisables avec US1/US2

---

## Parallel Example: Foundational Phase

```bash
# T002, T003, T004, T005, T008 en parallèle (fichiers backend différents):
T002: Category.java (isSystem field)
T003: CategoryResponse.java (isSystem field)
T004: CategoryRequest.java (@Size max 30)
T005: CategoryRepository.java (new queries)
T008: CategoryConstants.java (palette)

# Puis séquentiellement:
T006: CategoryService.java (dépend de T002, T005)
T007: AuthService.java (dépend de T006)
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Foundational Backend
2. Complete Phase 2: Foundational Frontend
3. Complete Phase 3: US1 (Autocomplete sélection)
4. **STOP and VALIDATE**: Le picker fonctionne dans les 3 formulaires
5. Commit et vérification

### Incremental Delivery

1. Phase 1+2 → Foundation prête
2. + US1 → Sélection catégorie (MVP!)
3. + US2 → Création à la volée (flux complet P1)
4. + US3 + US4 → Affichage + défauts système (P2)
5. + US5 → Page Paramètres (P3)
6. Tests → Tests unitaires backend + frontend (constitution V)
7. Polish → Build, lint, validation

---

## Notes

- Les tâches [P] sont parallélisables (fichiers différents, pas de conflits)
- Chaque checkpoint est un point de validation indépendant
- Commit recommandé après chaque phase complète
- Le CategoryPicker est le composant central — bien le concevoir en Phase 3 facilite tout le reste
- La page Paramètres (US5) réutilise le CategoryForm de US2 — d'où la dépendance
