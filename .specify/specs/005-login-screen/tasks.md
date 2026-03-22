# Tasks: Écran de login et fondations UI

**Input**: Design documents from `/specs/005-login-screen/`
**Prerequisites**: plan.md (required), spec.md (required), research.md

**Tests**: Non demandés dans la spec. Pas de tests unitaires spécifiques (hors scope du plan).

**Organization**: Tâches groupées par user story. Les US1 et US3 (validation) sont fusionnées car elles concernent le même formulaire.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Aucun setup requis. Le projet Angular existe, les dépendances sont installées, les design tokens/themes sont en place.

- [x] T001 Vérifier que `cd app && npx ng build` compile sans erreur avant de commencer

**Checkpoint**: Projet prêt pour l'implémentation.

---

## Phase 2: Foundational (Styles globaux + composant shared)

**Purpose**: Styles globaux pour formulaires et boutons + composant FormField réutilisable. DOIT être complété avant toute user story.

- [x] T002 [P] Créer `app/src/styles/_forms.scss` — styles globaux pour `input`, `textarea`, `select` : reset apparence, full width, padding `--space-3`, border `--border-default`, radius `--radius-md`, bg `--bg-secondary`, text `--text-primary`, focus avec `--color-primary` + `--focus-ring`, placeholder `--text-tertiary`, transition `--duration-fast`
- [x] T003 [P] Créer `app/src/styles/_buttons.scss` — styles globaux boutons : `button` base (padding, radius, font-weight, cursor, transition), `.btn-primary` (bg `--color-primary`, text `--color-primary-contrast`, hover `--color-primary-hover`), `.btn-outline` (border `--border-default`, bg transparent, hover `--hover-bg`), `:disabled` (opacity 0.6, cursor not-allowed), `.btn-block` (width 100%)
- [x] T004 Modifier `app/src/styles/_index.scss` — ajouter `@use 'forms'` et `@use 'buttons'` après la ligne `@use 'base'` (dépend de T002, T003)
- [x] T005 [P] Créer le composant `FormField` dans `app/src/app/shared/components/form-field/` (3 fichiers : form-field.ts, form-field.html, form-field.scss) — standalone, OnPush, inputs signal : `label = input.required<string>()`, `fieldId = input.required<string>()`, `errorMessage = input<string>('')`, `showError = input(false)`. Template : `<div class="form-field"><label [for]="fieldId()">{{ label() }}</label><ng-content /><span class="form-error" @if (showError())>{{ errorMessage() }}</span></div>`. Styles : spacing label/input/erreur, label `--font-size-sm --text-secondary`, erreur `--text-error --font-size-xs`

**Checkpoint**: Styles globaux appliqués, FormField importable. `ng build` passe.

---

## Phase 3: US1 + US3 — Connexion et validation du formulaire (Priority: P1)

**Goal**: L'utilisateur peut se connecter avec email/mot de passe. Validation inline sur les champs. Messages d'erreur globaux en cas d'échec. État de chargement sur le bouton.

**Independent Test**: Accéder à `/auth`, soumettre le formulaire vide (erreurs visibles), saisir un email invalide (message inline), saisir un mot de passe < 6 car (message inline), se connecter avec des identifiants valides (redirection vers `/dashboard`).

### Implementation

- [x] T006 Modifier `app/src/app/features/auth/auth.ts` — imports : `ReactiveFormsModule`, `FormField`. inject : `AuthService`, `Router`, `ActivatedRoute`, `FormBuilder`. Créer `loginForm` avec FormBuilder : email (Validators.required, Validators.email), password (Validators.required, Validators.minLength(6)). Signals : `loading = signal(false)`, `errorMessage = signal('')`. Méthode `onSubmit()` : si form invalide → `markAllAsTouched()` + return, sinon `loading.set(true)` → `authService.login()` → succès : navigate vers `returnUrl` (queryParam) ou `/` → erreur : `errorMessage.set(err.message)`, `loading.set(false)`
- [x] T007 Modifier `app/src/app/features/auth/auth.html` — template login : `.auth-page > .auth-card > .auth-header` (h1 "Budget", p "Connectez-vous à votre compte"), `@if (errorMessage())` bloc erreur global, `<form [formGroup]="loginForm" (ngSubmit)="onSubmit()">` avec 2 `<app-form-field>` (email + password) contenant des `<input>` natifs avec formControlName, autocomplete, placeholder. Bouton submit `.btn-primary .btn-block` avec `[disabled]="loading()"` et texte conditionnel `@if (loading()) { Connexion... } @else { Se connecter }` (dépend de T006)
- [x] T008 Modifier `app/src/app/features/auth/auth.scss` — styles mobile-first : `.auth-page` (min-height 100dvh, flex center, `--bg-primary`), `.auth-card` (max-width 400px, width 100%, padding `--space-6`, `--surface-default`, `--radius-xl`, `--shadow-md`, margin `--space-4`), `.auth-header` (centré, h1 `--color-primary --font-size-3xl`, p `--text-secondary`), `.auth-error` (`--bg-error`, `--text-error`, padding, radius), `form` (flex column, gap `--space-4`) (dépend de T007)

**Checkpoint**: Login fonctionnel avec validation. `ng build` passe. Test manuel : soumission vide montre erreurs, connexion réussie redirige.

---

## Phase 4: US2 — Navigation dans l'application authentifiée (Priority: P2)

**Goal**: Layout shell avec header + sidebar responsive (overlay sur mobile < 768px, fixe sur desktop >= 768px) + 4 sections de navigation + déconnexion. Le bas de l'écran reste libre pour le futur FAB.

**Independent Test**: Après connexion, l'utilisateur voit le header avec son nom, peut ouvrir la sidebar sur mobile (hamburger), naviguer entre les sections, la section active est visuellement indiquée, déconnexion redirige vers `/auth`.

### Implementation

- [x] T009 Créer le composant `Shell` dans `app/src/app/shared/components/shell/` (3 fichiers : shell.ts, shell.html, shell.scss) — standalone, OnPush. inject : `AuthService`, `Router`. Signal : `sidebarOpen = signal(false)`. Méthodes : `toggleSidebar()`, `closeSidebar()`, `onNavClick()` (navigate + closeSidebar sur mobile), `onLogout()` (authService.logout()). Template : header fixe (h1 "Budget", span nom user, bouton hamburger visible uniquement < 768px), sidebar/nav (4 liens : Accueil /dashboard, Transactions /transactions, Abonnements /subscriptions, Dettes /debts + lien Déconnexion, routerLinkActive="active"), backdrop (visible si sidebarOpen && mobile), `<router-outlet>` pour le contenu. Styles : sidebar responsive (overlay + backdrop sur mobile, fixe sur desktop), header sticky, main avec padding adaptatif
- [x] T010 Modifier `app/src/app/app.routes.ts` — refactorer les routes : `/auth` → lazy load auth.routes (pas de shell), `/` → composant Shell avec `canActivate: [authGuard]` et children : redirect '' → 'dashboard', dashboard, transactions, subscriptions, debts (tous lazy-loaded). Wildcard `**` → redirect vers dashboard (dépend de T009)

**Checkpoint**: Shell fonctionnel avec sidebar responsive. Navigation entre sections. Déconnexion redirige vers `/auth`. `ng build` passe.

---

## Phase 5: US4 — Redirection après tentative d'accès non authentifié (Priority: P2)

**Goal**: Après connexion, l'utilisateur est redirigé vers la page qu'il avait initialement demandée.

**Independent Test**: Accéder à `/transactions` non connecté → redirigé vers `/auth?returnUrl=/transactions` → connexion → redirigé vers `/transactions`.

### Implementation

- [x] T011 [US4] Vérifier la gestion du `returnUrl` dans `app/src/app/features/auth/auth.ts` — confirmer que la méthode `onSubmit()` lit le queryParam `returnUrl` via `this.route.snapshot.queryParamMap.get('returnUrl')` et redirige vers cette URL après login réussi (ou vers `/` par défaut). Tester manuellement : accéder à `/transactions` non connecté → login → vérifier redirection vers `/transactions`. Si la logique est absente, l'implémenter dans T006

**Checkpoint**: Redirection returnUrl fonctionnelle. `ng build` passe.

---

## Phase 6: US5 — Support du thème sombre (Priority: P3)

**Goal**: Tous les éléments créés s'adaptent correctement au thème sombre via les tokens CSS existants.

**Independent Test**: Changer la classe de `<html>` de `theme-light` à `theme-dark` dans DevTools → tous les éléments (login, shell, form-field, boutons) sont lisibles et esthétiques.

### Implementation

- [x] T012 [US5] Vérifier le rendu thème sombre sur tous les fichiers créés/modifiés — parcourir `_forms.scss`, `_buttons.scss`, `form-field.scss`, `auth.scss`, `shell.scss`. S'assurer que TOUS les styles utilisent des tokens CSS (`var(--token)`) et jamais de couleurs hardcodées. Corriger si nécessaire. Vérifier visuellement avec `.theme-dark` sur `<html>`.

**Checkpoint**: Thème sombre correct partout. Aucun élément illisible.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et nettoyage

- [x] T013 Exécuter `cd app && npx ng build` — vérifier compilation sans erreur ni warning
- [x] T014 Exécuter `cd app && npx ng lint` — vérifier lint sans erreur
- [x] T015 Exécuter `cd app && npx vitest run` — vérifier que les tests existants passent toujours
- [x] T016 Valider quickstart.md — parcourir les 13 étapes du test manuel et confirmer que tout fonctionne

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — vérification initiale
- **Foundational (Phase 2)**: Dépend de Phase 1 — BLOQUE toutes les user stories
- **US1+US3 (Phase 3)**: Dépend de Phase 2 (utilise `_forms.scss`, `_buttons.scss`, `FormField`)
- **US2 (Phase 4)**: Dépend de Phase 2 — peut être fait en parallèle de Phase 3 (fichiers différents)
- **US4 (Phase 5)**: Dépend de Phase 3 (vérification dans auth.ts)
- **US5 (Phase 6)**: Dépend de Phases 3 et 4 (vérifie tous les fichiers créés)
- **Polish (Phase 7)**: Dépend de toutes les phases précédentes

### Parallel Opportunities

- T002 et T003 : fichiers SCSS différents → parallèle
- T005 : composant indépendant → parallèle avec T002/T003
- Phase 3 (US1+US3) et Phase 4 (US2) : fichiers différents (auth/* vs shell/* + routes) → peuvent être faits en parallèle après Phase 2

### Within Each User Story

- auth.ts avant auth.html (le template référence les propriétés du composant)
- auth.html avant auth.scss (les styles ciblent les classes du template)
- shell.ts/html/scss créés ensemble (T009), puis routes modifiées (T010)

---

## Notes

- Feature purement frontend — aucune modification backend
- Les tokens CSS existants (`--bg-primary`, `--color-primary`, etc.) sont utilisés partout
- AuthService, AuthGuard, AuthInterceptor sont déjà implémentés et ne sont PAS modifiés
- Pas de tests unitaires spécifiques (hors scope du plan)
- Pas de page d'inscription ni "Mot de passe oublié"
- Pas d'icônes dans la navigation (texte seul)
