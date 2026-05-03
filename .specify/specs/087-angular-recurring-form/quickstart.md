# Quickstart: 087-angular-recurring-form

## Prérequis

- Node.js installé
- Backend Spring Boot lancé (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Base de données PostgreSQL avec migrations V20 appliquées

## Lancer le dev server

```bash
cd app && ng serve
```

## Tester les modifications

```bash
cd app && npx vitest run
```

## Vérifier la feature

1. Ouvrir http://localhost:4200
2. Se connecter
3. Aller sur Transactions → cliquer le FAB (+)
4. Dans le formulaire, activer le toggle "Récurrente"
5. Sélectionner une fréquence et une date de prochaine occurrence
6. Soumettre → vérifier le toast de confirmation
7. Naviguer vers /transactions/recurring → la récurrence doit apparaître

## Tester la conversion

1. Depuis la liste des transactions, cliquer l'icône "Rendre récurrente" sur une transaction
2. Vérifier que le formulaire s'ouvre pré-rempli avec le toggle récurrence activé
3. Soumettre → vérifier la création
