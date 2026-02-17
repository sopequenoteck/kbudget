# Quickstart: Refonte page Settings (8 sections)

**Branch**: `028-settings-redesign`

## Prérequis

- Node.js installé
- Angular CLI (`ng`) disponible
- Le backend API doit tourner pour les sections Comptes et Catégories

## Démarrage rapide

```bash
# 1. Se placer sur la branche feature
git checkout 028-settings-redesign

# 2. Installer les dépendances frontend
cd app && npm install

# 3. Lancer le dev server
ng serve
# → http://localhost:4200

# 4. (Optionnel) Lancer le backend pour les données
cd ../api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

## Vérification manuelle

1. Se connecter à l'application
2. Ouvrir le menu utilisateur (avatar en haut à droite)
3. Cliquer sur "Paramètres"
4. Vérifier : 8 cartes de section affichées en liste verticale
5. Cliquer sur chaque section :
   - **Comptes bancaires** → liste des comptes (CRUD fonctionnel)
   - **Catégories** → catégories système + personnalisées (CRUD fonctionnel)
   - **Apparence** → segmented control (Clair/Sombre/Automatique) → thème change immédiatement
   - **Profil** → nom + email en lecture seule
   - **À propos** → nom app, version, auteur
   - **Budget/Notifications/Données** → placeholder "Fonctionnalité à venir"
6. Vérifier les URLs directes : naviguer vers `/settings/appearance` dans la barre d'adresse
7. Vérifier la persistance du thème : changer le thème, rafraîchir la page

## Tests

```bash
cd app && ng test
```

## Fichiers clés

| Fichier | Rôle |
|---------|------|
| `app/src/app/core/services/theme.ts` | ThemeService (bascule thème, localStorage) |
| `app/src/app/features/settings/settings.ts` | Hub Settings (grille 8 cartes) |
| `app/src/app/features/settings/settings.routes.ts` | Routing des 8 sections |
| `app/src/app/features/settings/components/categories/` | Section catégories (extraite) |
| `app/src/app/features/settings/components/appearance/` | Section apparence (thème) |
| `app/src/app/features/settings/components/profile/` | Section profil (lecture seule) |
| `app/src/app/features/settings/components/about/` | Section à propos |
| `app/src/app/features/settings/components/placeholder/` | Composant partagé (Budget, Notifications, Données) |
