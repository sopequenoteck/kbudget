# Tasks: Sync TextScale via API

**Input**: Design documents from `/specs/094-sync-text-scale-api/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/preferences-api.md

**Tests**: Tests backend requis (pattern existant). Tests frontend existants doivent passer.

**Organization**: Tasks groupées par user story. Backend puis frontend.

## Format: `[ID] [P?] [Story] Description`

## Path Conventions

- **Backend**: `api/src/main/java/fr/kksdev/budget/api/`
- **Migrations**: `api/src/main/resources/db/migration/`
- **Frontend**: `app/src/app/core/`
- **Appearance**: `app/src/app/features/settings/components/appearance/`

---

## Phase 1: Foundational — Backend (enum + entité + migration)

**Purpose**: Créer l'enum, enrichir l'entité, migrer la base. Bloque toutes les user stories.

- [x] T001 [P] Créer l'enum `TextScale` dans `api/src/main/java/fr/kksdev/budget/api/enums/TextScale.java` — Enum Java avec 3 valeurs : `SMALL`, `MEDIUM`, `LARGE`. Pas de champ ni de méthode supplémentaire.
- [x] T002 [P] Créer la migration Flyway `V21__add_text_scale.sql` dans `api/src/main/resources/db/migration/` — Contenu : `ALTER TABLE user_preferences ADD COLUMN text_scale VARCHAR(20) DEFAULT 'MEDIUM';`
- [x] T003 Ajouter le champ `textScale` à l'entité `UserPreference` dans `api/src/main/java/fr/kksdev/budget/api/model/UserPreference.java` — Ajouter le champ `@Builder.Default @Enumerated(EnumType.STRING) @Column(name = "text_scale", length = 20) private TextScale textScale = TextScale.MEDIUM;`. Importer `TextScale` et `EnumType`.

**Checkpoint**: Enum + entité + migration prêts. La base accepte le champ.

---

## Phase 2: User Story 1 — Persistance serveur (Priority: P1) 🎯 MVP

**Goal**: GET/PUT /users/me/preferences incluent textScale. Le frontend sync via l'API.

**Independent Test**: `curl GET /api/users/me/preferences` retourne `textScale: "MEDIUM"`. `curl PUT` avec `textScale: "LARGE"` persiste la valeur.

### Backend

- [x] T004 [P] [US1] Ajouter `TextScale textScale` au DTO `UserPreferenceRequest` dans `api/src/main/java/fr/kksdev/budget/api/dto/request/UserPreferenceRequest.java` — Champ nullable (pas de `@NotNull`). Importer TextScale.
- [x] T005 [P] [US1] Ajouter `TextScale textScale` au DTO `UserPreferenceResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/response/UserPreferenceResponse.java` — Champ non-nullable (toujours renvoyé). Importer TextScale.
- [x] T006 [US1] Mettre à jour `PreferenceService.updatePreferences()` dans `api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java` — Ajouter le merge du champ textScale (même pattern que timezone) : `if (request.textScale() != null) { preference.setTextScale(request.textScale()); }`. Mettre à jour `toResponse()` pour inclure `preference.getTextScale()`.

### Frontend

- [x] T007 [US1] Ajouter `textScale` aux interfaces TypeScript dans `app/src/app/core/models/preference.model.ts` — Ajouter `textScale?: string` à `UserPreference` et `textScale?: string | null` à `UserPreferenceRequest`.
- [x] T008 [US1] Enrichir le `PreferenceService` Angular dans `app/src/app/core/services/preference.ts` — Ajouter signal `textScale = signal<string>('MEDIUM')`. Dans `loadPreferences()`, hydrater le signal : `this.textScale.set(data.textScale ?? 'MEDIUM')`. Ajouter méthode `updateTextScale(scale: string)` qui met à jour le signal + appelle `this.update({ ...current, textScale: scale })` (fire-and-forget, même pattern que updateTimezone).
- [x] T009 [US1] Modifier le `TextScaleService` dans `app/src/app/core/services/text-scale.ts` — Injecter `PreferenceService`. Ajouter un `effect()` qui écoute `preferenceService.textScale()` et met à jour `currentTextScale` + localStorage (cache). Conserver le `restoreTextScale()` depuis localStorage au constructeur pour le démarrage rapide. Modifier `setTextScale()` pour aussi appeler `preferenceService.updateTextScale()`.
- [x] T010 [US1] Mettre à jour le composant Appearance dans `app/src/app/features/settings/components/appearance/appearance.ts` — Vérifier que `setTextScale()` passe par le `TextScaleService` qui à son tour appelle `PreferenceService.updateTextScale()`. Aucun changement de template requis.

**Checkpoint**: GET retourne textScale. PUT persiste. Frontend sync via API. localStorage = cache rapide.

---

## Phase 3: User Story 2 — Défaut utilisateurs existants (Priority: P2)

**Goal**: Les utilisateurs existants ont automatiquement MEDIUM sans action.

**Independent Test**: Requêter un utilisateur existant dont les préférences existent déjà → textScale = MEDIUM.

### Implementation

- [ ] T011 [US2] Vérifier que la migration V21 applique le défaut correctement — Exécuter `cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev` et vérifier dans la base : `SELECT text_scale FROM user_preferences;` → toutes les lignes ont 'MEDIUM'. Si le profil dev utilise `create-drop`, vérifier que l'entité génère bien la colonne avec le défaut.

**Checkpoint**: Utilisateurs existants ont MEDIUM. Pas de données cassées.

---

## Phase 4: Polish & Cross-Cutting Concerns

- [x] T012 Exécuter les tests backend via `cd api && mvn test` — Vérifier que tous les tests passent (le nouveau champ nullable ne doit pas casser les tests existants du PreferenceController/Service).
- [x] T013 Exécuter les tests frontend via `cd app && npx vitest run` — Vérifier que les 379 tests passent sans modification.
- [ ] T014 Test d'intégration manuel — Suivre le `specs/094-sync-text-scale-api/quickstart.md` : GET → textScale présent, PUT → textScale persisté, reconnexion → textScale restauré.
- [ ] T015 Validation cross-device — Changer la taille sur un navigateur, se connecter sur un autre → taille synchronisée.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)** : Pas de dépendances. T001 + T002 parallélisables. T003 dépend de T001 (enum).
- **Phase 2 (US1)** : Dépend de Phase 1. Backend (T004-T006) puis Frontend (T007-T010) séquentiels.
- **Phase 3 (US2)** : Dépend de Phase 1 (migration). Vérification seulement.
- **Phase 4 (Polish)** : Dépend de toutes les phases.

### Parallel Opportunities

- T001 + T002 : parallélisables (fichiers différents)
- T004 + T005 : parallélisables (DTOs différents)

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 : Enum + Entité + Migration
2. Phase 2 backend : DTOs + Service
3. Phase 2 frontend : PreferenceService + TextScaleService bridge
4. **STOP et VALIDER** : GET/PUT fonctionnels

### Incremental Delivery

1. Backend (T001-T006) → API prête
2. Frontend (T007-T010) → Sync active
3. Vérification (T011-T015) → Validation complète

---

## Notes

- Pattern identique à `timezone` dans PreferenceService (partial update, nullable, défaut applicatif)
- Le `localStorage` est conservé comme cache de démarrage rapide (pas de flash)
- La source de vérité est le serveur (API), le localStorage est un cache
- Flutter N'EST PAS impacté (FR-009)
- Déléguer l'implémentation backend à l'agent `spring-boot-dev` et les tests à `test-qa`
