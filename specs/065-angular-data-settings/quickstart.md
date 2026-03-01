# Quickstart: 065-angular-data-settings

**Date**: 2026-03-01

## Prerequis

- Node.js installe
- Backend Spring Boot lance (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- L'endpoint `/actuator/health` accessible sur `http://localhost:8080/actuator/health`

## Demarrage rapide

```bash
# 1. Se positionner sur la branche
git checkout 065-angular-data-settings

# 2. Installer les dependances (si necessaire)
cd app && npm install

# 3. Lancer le serveur de dev
ng serve
# → http://localhost:4200

# 4. Acceder a l'ecran
# Se connecter → Menu utilisateur → Parametres → Donnees
# Ou directement : http://localhost:4200/settings/data
```

## Verification

1. **Statut serveur** : Le badge doit afficher "En ligne" avec un temps de reponse si le backend est lance
2. **Test manuel** : Cliquer sur "Tester la connexion" — le badge se met a jour
3. **Mode hors ligne** : Arreter le backend, tester — le badge passe a "Hors ligne" avec un message d'erreur
4. **Rechargement** : Cliquer sur "Recharger les donnees" — confirmation demandee, puis la page se recharge

## Fichiers cles

| Fichier | Role |
|---------|------|
| `app/src/app/core/services/health.ts` | Service de health check (ping + latence) |
| `app/src/app/features/settings/components/data-settings/data-settings.ts` | Composant principal |
| `app/src/app/features/settings/components/data-settings/data-settings.html` | Template |
| `app/src/app/features/settings/components/data-settings/data-settings.scss` | Styles |
| `app/src/app/features/settings/settings.ts` | Hub settings (card data → active) |
| `app/src/app/features/settings/settings.routes.ts` | Route data → DataSettings |

## Tests

```bash
cd app && ng test
```
