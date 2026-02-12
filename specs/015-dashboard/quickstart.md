# Quickstart: Écran Dashboard

**Feature**: 015-dashboard | **Date**: 2026-02-12

## Prérequis

- Node.js installé
- Backend Spring Boot en cours d'exécution (`cd api && mvn spring-boot:run`)
- Données de test existantes (transactions, abonnements, dettes)

## Démarrage

```bash
cd app && ng serve
```

Naviguer vers `http://localhost:4200/dashboard`

## Fichiers à modifier

| Fichier | Action |
| ------- | ------ |
| `app/src/app/features/dashboard/dashboard.ts` | Implémenter le composant |
| `app/src/app/features/dashboard/dashboard.html` | Créer le template |
| `app/src/app/features/dashboard/dashboard.scss` | Créer les styles |
| `app/src/app/shared/components/shell/shell.ts` | Ajouter méthodes openEdit* |

## Vérification

1. Le dashboard affiche le bilan du mois en cours (3 cartes)
2. Le sélecteur de mois navigue correctement
3. Les 5 dernières transactions apparaissent
4. Les 3 abonnements actifs apparaissent avec total mensuel
5. Les 3 dettes en cours apparaissent avec résumé je dois/on me doit
6. "Voir tout" navigue vers la bonne page
7. Le clic sur un item ouvre la modale d'édition
8. Une section en erreur n'impacte pas les autres

## Tests

```bash
cd app && npx vitest run
```
