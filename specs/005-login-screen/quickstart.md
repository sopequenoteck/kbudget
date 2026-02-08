# Quickstart: 005-login-screen

## Prérequis

- Node.js installé
- Dépendances installées : `cd app && npm install`

## Lancer

```bash
cd app && npx ng serve
```

Accéder à `http://localhost:4200/auth` pour voir l'écran de login.

## Vérifier

```bash
cd app && npx ng build        # Compilation SCSS + TS
cd app && npx ng lint          # Lint
cd app && npx vitest run       # Tests existants
```

## Tester manuellement

1. Aller sur `http://localhost:4200` → redirigé vers `/auth` (non authentifié)
2. Soumettre le formulaire vide → erreurs de validation affichées
3. Saisir un email invalide → message d'erreur inline
4. Saisir un mot de passe < 6 car → message d'erreur inline
5. Se connecter avec des identifiants valides → redirigé vers `/dashboard` avec header
6. **Mobile (< 768px)** : cliquer sur le bouton hamburger → sidebar s'ouvre en overlay avec backdrop
7. Cliquer sur une section dans la sidebar → redirigé, sidebar se ferme
8. Cliquer sur le backdrop → sidebar se ferme
9. **Desktop (>= 768px)** : la sidebar est toujours visible à côté du contenu, pas de bouton hamburger
10. Cliquer sur "Déconnexion" dans la sidebar → redirigé vers `/auth`
11. Accéder directement à `/transactions` sans être connecté → redirigé vers `/auth?returnUrl=/transactions`
12. Se connecter → redirigé vers `/transactions`
13. Dans DevTools, changer la classe de `<html>` de `theme-light` à `theme-dark` → les couleurs s'adaptent
