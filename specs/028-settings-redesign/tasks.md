# Tasks: Refonte page Settings (8 sections)

**Input**: Design documents from `/specs/028-settings-redesign/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md
**Linear**: [KKS-83](https://linear.app/kksdev/issue/KKS-83/refonte-page-settings-8-sections)

**Tests**: Non demandés dans la spec — aucune tâche de test générée.

**Organization**: Tâches groupées par user story. Chaque story est implémentable et testable indépendamment après la phase Foundational.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécutée en parallèle (fichiers différents, pas de dépendance)
- **[Story]**: User story associée (US1, US2, US3, US4, US5, US6, US7)
- Chaque tâche inclut les chemins de fichiers exacts

## Path Conventions

- **Frontend**: `app/src/app/` (Angular PWA)
- **Styles**: `app/src/styles/`
- **Index**: `app/src/index.html`

---

## Phase 1: Setup

**Purpose**: Préparer le terrain pour le ThemeService en retirant le thème hardcodé.

- [x] T001 Retirer la classe `theme-dark` hardcodée de `app/src/index.html` et laisser `<html lang="fr">` sans classe de thème (le ThemeService appliquera la classe dynamiquement au démarrage)

---

## Phase 2: Foundational (ThemeService)

**Purpose**: Créer le service de thème global. DOIT être terminé avant US4 (Apparence) mais aussi avant toute story car il gère l'affichage du thème au démarrage de l'app.

- [x] T002 Créer le ThemeService dans `app/src/app/core/services/theme.ts` — type `Theme = 'light' | 'dark' | 'auto'`, signal `currentTheme`, computed `effectiveTheme`, persistance localStorage clé `budget_theme`, listener `window.matchMedia('(prefers-color-scheme: dark)')`, méthode `setTheme()` appliquant `theme-light`/`theme-dark` sur `document.documentElement` (cf. research.md R1-R4)
- [x] T003 Injecter le ThemeService dans le Shell pour initialisation globale au démarrage dans `app/src/app/shared/components/shell/shell.ts` — ajouter `private readonly themeService = inject(ThemeService)` (l'injection suffit à déclencher le constructor qui restaure le thème)

**Checkpoint**: Le thème est appliqué dynamiquement au démarrage. La classe sur `<html>` change selon la préférence stockée ou le défaut light.

---

## Phase 3: User Story 1 — Navigation par sections (Priority: P1) — MVP

**Goal**: L'utilisateur accède à /settings et voit 8 cartes de section. Chaque carte navigue vers sa sous-page. Le bouton retour fonctionne.

**Independent Test**: Naviguer vers /settings → 8 cartes visibles avec icône, titre, description. Cliquer sur chaque carte → sous-page correspondante. Bouton retour → retour au hub.

### Implementation

- [x] T004 [US1] Réécrire le composant hub Settings dans `app/src/app/features/settings/settings.ts` — supprimer toute logique catégories (signals, computed, loadCategories, CRUD, imports CategoryService/ModalService), ajouter l'interface `SettingsSection { id, title, description, icon, route, status }` et la constante `SECTIONS` avec les 8 sections dans l'ordre FR-014, importer `RouterLink`
- [x] T005 [US1] Réécrire le template hub dans `app/src/app/features/settings/settings.html` — titre "Paramètres", boucle `@for` sur les SECTIONS rendant chaque carte (icône, titre, description, flèche, `routerLink` vers `section.route`), badge visuel "À venir" pour les sections avec `status === 'placeholder'`
- [x] T006 [US1] Réécrire les styles hub dans `app/src/app/features/settings/settings.scss` — supprimer tous les styles catégories (.category-group, .category-list, .btn-icon, .btn-danger), garder/adapter .settings-nav-link pour les cartes de section, ajouter style badge "À venir", layout colonne unique mobile-first
- [x] T007 [P] [US1] Créer le composant Placeholder dans `app/src/app/features/settings/components/placeholder/` (placeholder.ts + placeholder.html + placeholder.scss) — injecter `ActivatedRoute`, lire `route.snapshot.data['title']` et `route.snapshot.data['icon']`, template avec bouton retour (`routerLink="/settings"`), icône, titre, message "Fonctionnalité à venir dans une prochaine version"
- [x] T008 [US1] Mettre à jour le routing dans `app/src/app/features/settings/settings.routes.ts` — ajouter les 8 routes enfant avec lazy loading : `accounts` (existant), `categories`, `appearance`, `profile`, `about` (chacun avec `loadComponent`), `budget`/`notifications`/`data` (chacun avec `loadComponent` vers Placeholder + `data: { title, icon }`)

**Checkpoint**: Le hub affiche 8 cartes. Les sections Comptes et Catégories ne fonctionnent pas encore (catégories pas encore extraite). Les placeholders (Budget, Notifications, Données) affichent "À venir". Le deep linking fonctionne (/settings/budget charge directement le placeholder).

---

## Phase 4: User Story 2 + User Story 3 — Comptes bancaires et Catégories (Priority: P2)

### US2 — Section Comptes bancaires

**Goal**: La section Comptes reprend toutes les fonctionnalités existantes dans le nouveau cadre de navigation.

**Independent Test**: Settings > Comptes bancaires → liste des comptes. CRUD (ajout, modif, suppression, défaut) fonctionne comme avant.

- [x] T009 [P] [US2] Ajouter le bouton retour vers le hub dans le template accounts `app/src/app/features/settings/components/accounts/accounts.html` — ajouter en haut du template un lien `<a routerLink="/settings">` avec icône flèche retour et texte "Paramètres", importer `RouterLink` dans `accounts.ts`

### US3 — Section Catégories

**Goal**: Extraire la gestion des catégories de l'ancien settings.ts vers un composant dédié.

**Independent Test**: Settings > Catégories → catégories système et personnalisées visibles. CRUD catégories personnalisées fonctionne comme avant.

- [x] T010 [US3] Créer le composant Categories dans `app/src/app/features/settings/components/categories/categories.ts` — extraire toute la logique catégories de l'ancien settings.ts : inject CategoryService et ModalService, signals (categories, loading, error, confirmDeleteId), computed (systemCategories, userCategories), méthodes (loadCategories, editCategory, requestDelete, cancelDelete, confirmDelete), effect avec refreshTrigger
- [x] T011 [US3] Créer le template categories dans `app/src/app/features/settings/components/categories/categories.html` — bouton retour (`routerLink="/settings"`), extraire le template catégories de l'ancien settings.html (section catégories système, catégories utilisateur, états loading/error/empty, confirmation suppression)
- [x] T012 [P] [US3] Créer les styles categories dans `app/src/app/features/settings/components/categories/categories.scss` — extraire de l'ancien settings.scss : .category-group, .category-list (item, icon, name, color, badge, actions, confirm), .btn-icon, .btn-danger, .btn-outline--sm, états (.state-loading, .state-error, .state-empty)

**Checkpoint**: Les sections Comptes et Catégories fonctionnent de manière identique à avant la refonte, avec navigation retour vers le hub.

---

## Phase 5: User Story 4 + User Story 5 — Apparence et Profil (Priority: P3)

### US4 — Section Apparence

**Goal**: L'utilisateur peut choisir entre thème Clair, Sombre et Automatique via un segmented control. Le changement est immédiat et persisté.

**Independent Test**: Settings > Apparence → segmented control visible. Sélectionner "Sombre" → interface passe en dark immédiatement. Rafraîchir → thème conservé.

- [x] T013 [US4] Créer le composant Appearance dans `app/src/app/features/settings/components/appearance/` (appearance.ts + appearance.html + appearance.scss) — injecter ThemeService, lire `currentTheme` signal, template avec bouton retour, titre "Apparence", segmented control (3 boutons : Clair/Sombre/Automatique) avec état actif basé sur `currentTheme()`, appel `themeService.setTheme()` au clic, styles du segmented control utilisant les design tokens CSS existants

### US5 — Section Profil

**Goal**: L'utilisateur voit son nom et email en lecture seule. Pas de bouton de modification.

**Independent Test**: Settings > Profil → nom et email affichés. Aucun bouton modifier visible.

- [x] T014 [P] [US5] Créer le composant Profile dans `app/src/app/features/settings/components/profile/` (profile.ts + profile.html + profile.scss) — injecter AuthService, lire `currentUser()` signal, template avec bouton retour, titre "Profil", affichage nom et email en lecture seule (champs non éditables), gestion du cas `currentUser() === null` avec message d'erreur

**Checkpoint**: Le thème bascule instantanément via la section Apparence. Le profil affiche les données de l'utilisateur connecté.

---

## Phase 6: User Story 7 — Section À propos (Priority: P4)

**Goal**: Afficher les informations de base de l'application : nom, version, auteur.

**Independent Test**: Settings > À propos → nom de l'app, version et auteur visibles.

> **Note US6** : Les sections placeholder (Budget, Notifications, Données) sont déjà couvertes par T007 (composant Placeholder) et T008 (routes avec data). Aucune tâche supplémentaire pour US6.

- [x] T015 [US7] Créer le composant About dans `app/src/app/features/settings/components/about/` (about.ts + about.html + about.scss) — template avec bouton retour, titre "À propos", contenu hardcodé : nom de l'app ("Budget"), version (lire depuis `package.json` ou hardcoder "1.0.0"), auteur ("kksdev"), design simple avec les tokens CSS existants

**Checkpoint**: Toutes les 8 sections sont fonctionnelles (5 actives + 3 placeholders).

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Vérifications finales et nettoyage.

- [x] T016 Vérifier le deep linking pour les 8 sections — accéder directement à `/settings/accounts`, `/settings/categories`, `/settings/appearance`, `/settings/profile`, `/settings/about`, `/settings/budget`, `/settings/notifications`, `/settings/data` et confirmer que chaque section se charge correctement avec le bouton retour fonctionnel (FR-013)
- [x] T017 Vérifier que les sections placeholder affichent bien le bon titre (Budget, Notifications, Données) et que le message "À venir" est visible sur chacune
- [x] T018 Exécuter la validation quickstart.md — suivre les étapes de `specs/028-settings-redesign/quickstart.md` pour une vérification manuelle complète

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — peut démarrer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 (T001) — BLOQUE US4 (Apparence)
- **US1 (Phase 3)**: Dépend de Phase 1. Peut démarrer en parallèle de Phase 2.
- **US2+US3 (Phase 4)**: Dépend de US1 (Phase 3) — le hub et les routes doivent exister
- **US4+US5 (Phase 5)**: US4 dépend de Phase 2 (ThemeService) + Phase 3 (routes). US5 dépend uniquement de Phase 3.
- **US7 (Phase 6)**: Dépend de Phase 3 (routes)
- **Polish (Phase 7)**: Dépend de toutes les phases précédentes

### User Story Dependencies

```
Phase 1 (Setup)
    │
    ├──► Phase 2 (ThemeService) ──────────────────────┐
    │                                                   │
    └──► Phase 3 (US1 — Hub + Routes + Placeholder) ──┤
              │                                         │
              ├──► Phase 4 (US2 — Comptes)             │
              ├──► Phase 4 (US3 — Catégories)          │
              ├──► Phase 5 (US5 — Profil)              │
              ├──► Phase 6 (US7 — À propos)            │
              │                                         │
              └──► Phase 5 (US4 — Apparence) ◄─────────┘
                          │
                          ▼
                   Phase 7 (Polish)
```

### Within Each User Story

- Composant .ts avant .html (templateUrl référence)
- .html et .scss peuvent être créés en parallèle
- Routes après composants (T008 après T004, T005, T007)

### Parallel Opportunities

- **Phase 2 + Phase 3** : T002/T003 (ThemeService) en parallèle de T004/T005/T006 (hub) — fichiers différents
- **Phase 3** : T007 (Placeholder) en parallèle de T004/T005/T006 (hub) — répertoires différents
- **Phase 4** : T009 (back button accounts) en parallèle de T010/T011/T012 (categories) — composants différents
- **Phase 5** : T013 (appearance) en parallèle de T014 (profile) — composants différents
- **Phase 7** : T016 et T017 en parallèle (vérifications indépendantes)

---

## Parallel Example: Phase 3 (US1)

```bash
# Groupe 1 : Hub + Placeholder en parallèle
Task: T004 "Réécrire settings.ts comme hub"
Task: T007 "Créer composant Placeholder"      # [P] — répertoire différent

# Groupe 2 : Template et styles hub (après T004)
Task: T005 "Réécrire settings.html"
Task: T006 "Réécrire settings.scss"

# Groupe 3 : Routes (après T004, T005, T007)
Task: T008 "Mettre à jour settings.routes.ts"
```

## Parallel Example: Phase 4 (US2 + US3)

```bash
# Tous en parallèle — composants différents
Task: T009 "Back button accounts"     # [P]
Task: T010 "Créer categories.ts"
Task: T011 "Créer categories.html"
Task: T012 "Créer categories.scss"    # [P]
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Phase 1: Setup (T001) — 1 tâche
2. Phase 2: ThemeService (T002-T003) — 2 tâches
3. Phase 3: US1 Hub + Routes (T004-T008) — 5 tâches
4. **STOP et VALIDER** : 8 cartes affichées, navigation fonctionne, placeholders visibles
5. Commit et deploy possible

### Incremental Delivery

1. Setup + Foundational + US1 → Hub fonctionnel avec placeholders (MVP)
2. + US2 + US3 → Comptes et catégories migrés (fonctionnalités existantes restaurées)
3. + US4 + US5 → Apparence (thème) et Profil (nouvelles fonctionnalités)
4. + US7 → À propos (finition)
5. Polish → Vérifications finales

---

## Notes

- Feature **frontend-only** — aucune modification backend, aucune migration Flyway
- US6 (Placeholders) est couvert par US1 (T007 + T008) — pas de tâches dédiées
- Le composant Accounts existant n'a besoin que d'un bouton retour (T009)
- Les styles catégories sont extraits de settings.scss, pas créés from scratch
- Commit recommandé après chaque phase complétée
