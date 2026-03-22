# Quickstart: Comptes bancaires — Frontend

**Branch**: `027-bank-accounts-frontend` | **Date**: 2026-02-16

## Prerequis

- Backend API lance avec le profil dev (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- PostgreSQL disponible avec les migrations Flyway appliquees (V7 pour accounts)
- Node.js installe, dependances frontend installees (`cd app && npm install`)

## Demarrage

```bash
# 1. Se placer sur la branche
git checkout 027-bank-accounts-frontend

# 2. Lancer le backend (terminal 1)
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 3. Lancer le frontend (terminal 2)
cd app && ng serve
# → http://localhost:4200
```

## Ordre d'implementation recommande

1. **Modeles** : `account.model.ts` + modifications `transaction.model.ts` / `subscription.model.ts`
2. **Service** : `AccountService` (CRUD + transfer + default)
3. **Composant partage** : `AccountPicker` (selecteur reutilisable)
4. **Page Settings > Comptes** : liste + formulaire creation/edition/suppression
5. **Dashboard** : section comptes en haut (solde total + individuels)
6. **Transaction form** : integration AccountPicker (obligatoire, pre-selection defaut)
7. **Subscription form** : integration AccountPicker (optionnel)
8. **ModalService** : ajout type `transfer`
9. **Transfer form** : formulaire de virement entre comptes

## Verification rapide

```bash
# Tests unitaires
cd app && ng test

# Build production
cd app && ng build --configuration production

# Lint
cd app && ng lint
```

## Points d'attention

- Le `soldeInitial` est en lecture seule apres creation (ne pas inclure dans le formulaire d'edition)
- Les comptes inactifs ne doivent jamais apparaitre dans les selecteurs (AccountPicker, transfer form)
- Le compte par defaut doit etre pre-selectionne dans tous les formulaires (transaction, subscription)
- Les transactions/abonnements sans compte (legacy) s'affichent normalement avec un champ compte vide
- Le `refreshTrigger` du AccountService doit declencher un rafraichissement sur le dashboard
