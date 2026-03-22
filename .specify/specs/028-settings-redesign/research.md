# Research: Refonte page Settings (8 sections)

**Date**: 2026-02-16 | **Branch**: `028-settings-redesign`

## R1 — Mécanisme d'application du thème CSS

**Decision** : Appliquer la classe `theme-light` ou `theme-dark` sur l'élément `<html>` via `document.documentElement.classList`.

**Rationale** :
- Les thèmes SCSS existants sont déjà définis via les sélecteurs `.theme-light` (`:root, .theme-light`) et `.theme-dark`.
- Le thème light est le défaut via `:root` — si aucune classe n'est présente, le light s'applique.
- L'élément `<html>` porte actuellement `class="theme-dark"` en dur dans `index.html`.
- Utiliser `classList.remove/add` sur `document.documentElement` est la méthode la plus directe et performante (<1ms).

**Alternatives considered** :
- `data-theme` attribute → Nécessiterait de refactorer les sélecteurs SCSS existants. Rejeté.
- CSS `@media (prefers-color-scheme)` uniquement → Ne permet pas le choix manuel de l'utilisateur. Rejeté.
- Classe sur `<body>` → Fonctionne mais `<html>` est plus standard et déjà utilisé. Rejeté.

## R2 — Persistance du thème en localStorage

**Decision** : Clé `budget_theme` dans localStorage. Valeurs possibles : `'light'`, `'dark'`, `'auto'`. Défaut : `'light'` (fallback si clé absente ou localStorage indisponible).

**Rationale** :
- Le projet utilise déjà le préfixe `budget_` pour les clés localStorage (`budget_token`, `budget_refresh_token`, `budget_user`).
- Le pattern `try/catch` avec `isDevMode()` est établi dans `AuthService` pour gérer l'indisponibilité du localStorage.
- Le type `Theme = 'light' | 'dark' | 'auto'` est suffisant — pas besoin d'un enum Angular.

**Alternatives considered** :
- sessionStorage → Ne persiste pas entre sessions. Rejeté (FR-008 exige persistance).
- IndexedDB → Over-engineering pour une seule valeur. Rejeté.
- Cookie → Inutile côté serveur. Rejeté.

## R3 — Gestion du mode "Automatique" (prefers-color-scheme)

**Decision** : Utiliser `window.matchMedia('(prefers-color-scheme: dark)')` avec un listener `change` pour réagir aux changements du système en temps réel.

**Rationale** :
- Le mode "auto" doit suivre les préférences système (FR-009).
- `matchMedia` est supporté par tous les navigateurs modernes ciblés.
- Le listener `change` permet de basculer le thème instantanément si l'OS change de mode pendant que l'app est ouverte.

**Alternatives considered** :
- Vérifier uniquement au démarrage → Ne réagit pas aux changements système en cours de session. Rejeté.
- Media query CSS pure → Ne permet pas de savoir quel mode est effectif côté JS. Rejeté.

## R4 — Architecture du ThemeService

**Decision** : Service Angular `providedIn: 'root'` avec signals. Initialisé dans le constructor. Applique le thème via effet sur `document.documentElement`.

**Rationale** :
- Pattern identique à `AuthService` (service singleton, signals pour l'état réactif, restauration au démarrage).
- `signal()` pour `currentTheme`, `computed()` pour `effectiveTheme` (résolution auto → light/dark).
- `effect()` pour appliquer la classe CSS à chaque changement.
- Le service doit être injecté dans `app.component.ts` ou `shell.ts` pour garantir son initialisation au démarrage.

**Alternatives considered** :
- ThemeService dans le module Settings → Ne s'applique pas globalement. Rejeté.
- Directive sur `<html>` → Moins direct et plus complexe. Rejeté.

## R5 — Extraction des catégories depuis settings.ts

**Decision** : Déplacer le code de gestion des catégories de `settings.ts` vers un nouveau composant `settings/components/categories/categories.ts`. Le composant hub (`settings.ts`) ne contiendra plus que la grille des 8 cartes de navigation.

**Rationale** :
- Actuellement, `settings.ts` contient toute la logique catégories (signal, computed, loadCategories, CRUD) + le lien vers accounts.
- Le composant `Accounts` est déjà un composant séparé sous `settings/components/accounts/` — suivre le même pattern.
- Les styles catégories dans `settings.scss` (`.category-group`, `.category-list`, `.btn-icon`, `.btn-danger`) seront déplacés vers `categories.scss`.

**Alternatives considered** :
- Garder les catégories inline et wrapper le tout → Crée un composant hybride incohérent. Rejeté.
- Créer un service intermédiaire → Over-engineering, le CategoryService existe déjà. Rejeté.

## R6 — Routing des sections

**Decision** : Routes enfant sous `settings/` avec lazy loading pour chaque section.

```
{ path: '', component: Settings }            // Hub (grille 8 cartes)
{ path: 'accounts', loadComponent: ... }     // Existant
{ path: 'categories', loadComponent: ... }   // Nouveau
{ path: 'appearance', loadComponent: ... }   // Nouveau
{ path: 'profile', loadComponent: ... }      // Nouveau
{ path: 'about', loadComponent: ... }        // Nouveau
{ path: 'budget', loadComponent: ... }       // Placeholder
{ path: 'notifications', loadComponent: ... }// Placeholder
{ path: 'data', loadComponent: ... }         // Placeholder
```

**Rationale** :
- Le pattern est déjà établi : `settings.routes.ts` utilise `loadComponent` pour accounts.
- Le lazy loading par section garantit que seul le code de la section visitée est chargé.
- Les URLs sont en anglais (cohérent avec `accounts` existant, et les routes du projet : `dashboard`, `transactions`, `subscriptions`, `debts`).
- Le composant `Placeholder` est partagé entre Budget, Notifications et Données via un `input()` pour le titre de la section.

**Alternatives considered** :
- URLs en français (`/settings/comptes-bancaires`) → Incohérent avec les routes existantes en anglais. Rejeté.
- Routes non-lazy (import direct) → Contraire aux bonnes pratiques Angular pour le code splitting. Rejeté.
- Un composant par placeholder → Duplication. Un seul composant avec `input()` suffit. Rejeté.

## R7 — Source des données profil

**Decision** : Utiliser `AuthService.currentUser()` (signal existant, type `UserInfo { name, email }`).

**Rationale** :
- `AuthService.currentUser()` est un signal alimenté au login (`saveAuth`) et restauré au démarrage (`restoreSession`).
- Contient `{ name: string, email: string }` — exactement ce que FR-010 demande.
- Aucun endpoint API supplémentaire nécessaire.
- Le composant Profile injecte simplement `AuthService` et lit le signal.

**Alternatives considered** :
- Créer un endpoint `/users/me` → Backend work non nécessaire, données déjà disponibles côté frontend. Rejeté.
- Décoder le JWT → Fragile et les données ne sont pas garanties dans le payload. Rejeté.

## R8 — Composant Placeholder partagé

**Decision** : Un seul composant `Placeholder` lisant le titre et l'icône depuis `ActivatedRoute.snapshot.data` (passés via la config de route `data: { title, icon }`).

**Rationale** :
- 3 sections (Budget, Notifications, Données) affichent le même template : titre + icône + message "Fonctionnalité à venir".
- Passer le titre via `route.data` suffit pour différencier chaque usage.
- Chaque route passe `data: { title, icon }` dans la config, le composant lit via `ActivatedRoute.snapshot.data`.

**Alternatives considered** :
- 3 composants distincts → Duplication pour un template identique. Rejeté.
- Template ng-content → Over-engineering pour un texte statique. Rejeté.
