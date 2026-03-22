# Research: Écran de login et fondations UI

**Feature**: 005-login-screen | **Date**: 2026-02-08

## Décisions

### D1 : Styles globaux vs composants Angular pour inputs/boutons

**Decision**: Styles globaux SCSS (`_forms.scss`, `_buttons.scss`) pour les éléments natifs, pas de composants Angular wrapper pour `<input>` et `<button>`.

**Rationale**: Les inputs et boutons natifs HTML sont suffisants avec des styles globaux. Créer des composants `DsInput`/`DsButton` serait de la sur-ingénierie à ce stade — l'app n'a qu'un seul formulaire. Le composant `FormField` (label + ng-content + erreur) apporte la vraie valeur réutilisable sans dupliquer les éléments natifs.

**Alternatives considered**:
- Composants Angular `DsInput`/`DsButton` : rejeté car YAGNI, un seul formulaire pour l'instant
- Librairie UI externe (PrimeNG, Angular Material) : rejeté car trop lourd pour un projet single-user, dépendance externe inutile

### D2 : Layout shell — route wrapper vs directive structurelle

**Decision**: Composant `Shell` utilisé comme route layout via `component` sur la route parent, avec `children` pour les routes protégées.

**Rationale**: Pattern standard Angular. Le Shell contient le `<router-outlet>` et est instancié une seule fois. Le guard `canActivate` est placé sur la route parent, protégeant automatiquement toutes les routes enfants.

**Alternatives considered**:
- `@if` conditionnel dans `app.html` : rejeté car mélange la logique de layout avec le root component
- Route guard sur chaque route enfant individuellement : rejeté car duplication, le guard parent protège tous les enfants

### D3 : Navigation — sidebar responsive (révisé après clarification)

**Decision**: Sidebar responsive. Overlay avec backdrop sur mobile (< 768px), fixe toujours visible sur desktop (>= 768px). 4 sections texte + lien déconnexion. Se ferme après navigation sur mobile. Clic sur le backdrop ferme la sidebar.

**Rationale**: La sidebar libère le bas de l'écran pour le futur bouton flottant (+) imposé par la constitution (principe IV). Sur desktop, la sidebar fixe exploite l'espace horizontal disponible. Pattern utilisé par les apps finance/budget.

**Alternatives considered**:
- Bottom nav fixe : rejeté car conflit de position avec le futur FAB (+) en bas de l'écran
- Sidebar overlay partout (même desktop) : rejeté car sur desktop l'espace est disponible, mieux vaut la garder visible
- Top tabs : rejeté car moins accessible sur mobile (zone de pouce en bas)

### D4 : Formulaire — ReactiveFormsModule vs Template-driven

**Decision**: ReactiveFormsModule avec FormBuilder.

**Rationale**: Convention Angular moderne pour les formulaires complexes. Permet la validation programmatique, le contrôle de l'état des champs (touched, dirty, errors), et l'intégration avec les signals.

**Alternatives considered**:
- Template-driven forms : rejeté car moins de contrôle sur la validation et l'état

### D5 : Gestion du loading — signal vs BehaviorSubject

**Decision**: `signal(false)` pour l'état de chargement.

**Rationale**: Convention signals-first du projet. Plus simple qu'un BehaviorSubject, pas besoin de `subscribe()`.

**Alternatives considered**:
- BehaviorSubject + async pipe : rejeté car les signals sont le pattern du projet

## Technologies existantes réutilisées

| Composant | Chemin | Usage |
|-----------|--------|-------|
| AuthService | `app/src/app/core/services/auth.ts` | `login()`, `logout()`, `currentUser`, `isAuthenticated` |
| AuthGuard | `app/src/app/core/guards/auth.guard.ts` | Protection des routes, redirection avec `returnUrl` |
| AuthInterceptor | `app/src/app/core/interceptors/auth.interceptor.ts` | Injection JWT header, gestion 401 |
| LoginRequest | `app/src/app/core/models/auth.model.ts` | Interface `{ email, password }` |
| Design tokens | `app/src/styles/tokens/_tokens.scss` | CSS custom properties (couleurs, spacing, typo, radius, shadows) |
| Themes | `app/src/styles/themes/_light.scss`, `_dark.scss` | Tokens sémantiques clair/sombre |
