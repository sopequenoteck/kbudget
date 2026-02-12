# Quickstart: 016-modal-service

**Date**: 2026-02-12

## Prérequis

- Node.js installé
- Backend API lancé (`cd api && mvn spring-boot:run`)
- Données existantes (au moins 1 transaction, 1 abonnement, 1 dette)

## Lancer l'application

```bash
cd app && ng serve
```

Ouvrir `http://localhost:4200` dans un navigateur.

## Tester l'édition (P1)

1. Se connecter
2. Naviguer vers **Transactions**
3. Taper sur une transaction existante dans la liste
4. Vérifier : la modale s'ouvre avec le titre "Modifier la transaction"
5. Vérifier : le formulaire est pré-rempli avec les données de la transaction
6. Modifier le montant
7. Cliquer "Modifier"
8. Vérifier : la modale se ferme et la liste affiche le nouveau montant
9. Répéter pour **Abonnements** et **Dettes**

## Tester la suppression (P2)

1. Ouvrir une transaction existante (tap sur l'élément)
2. Vérifier : un bouton "Supprimer" est visible en bas du formulaire
3. Cliquer "Supprimer"
4. Vérifier : une zone de confirmation apparaît ("Confirmer" / "Annuler")
5. Cliquer "Annuler" → vérifier que rien ne change
6. Re-cliquer "Supprimer" puis "Confirmer"
7. Vérifier : la modale se ferme et la transaction a disparu de la liste
8. Répéter pour **Abonnements** et **Dettes**

## Tester la création (non-régression)

1. Cliquer le bouton FAB (+) sur n'importe quel écran
2. Choisir "Transaction" dans le speed dial
3. Vérifier : la modale s'ouvre avec le titre "Nouvelle transaction"
4. Vérifier : le formulaire est vide
5. Vérifier : le bouton "Supprimer" n'est PAS visible
6. Remplir et sauvegarder → vérifier que la transaction apparaît dans la liste

## Tester la fermeture à la navigation (P3)

1. Ouvrir une modale (édition ou création)
2. Naviguer vers un autre écran via le menu latéral
3. Vérifier : la modale se ferme automatiquement

## Lancer les tests unitaires

```bash
cd app && npx vitest run
```
