# Quickstart: 078-angular-debt-enhancements

## Prérequis

- Node.js (version compatible Angular 21)
- Backend API démarré avec profil dev (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Base PostgreSQL avec données de test (dettes, comptes, notifications)

## Démarrage

```bash
cd app && ng serve
# → http://localhost:4200
```

## Vérification des endpoints backend

```bash
# Créer une dette avec compte + rappel
curl -X POST http://localhost:8080/api/debts \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"personne":"Jean","montant":500,"sens":"EMPRUNT","date":"2026-01-15","accountId":"<account-uuid>","includeInBalance":true,"reminderDate":"2026-03-20","reminderTime":"09:00"}'

# Rembourser partiellement
curl -X POST http://localhost:8080/api/debts/<debt-id>/repay \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"accountId":"<account-uuid>","amount":200}'

# Consulter les paiements
curl http://localhost:8080/api/debts/<debt-id>/payments \
  -H "Authorization: Bearer <token>"

# Reporter un rappel
curl -X POST http://localhost:8080/api/debts/<debt-id>/snooze \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"reminderDate":"2026-03-25","reminderTime":"10:00"}'
```

## Fichiers clés à modifier/créer

| Fichier | Action | Description |
|---------|--------|-------------|
| `app/src/app/core/models/debt.model.ts` | UPDATE | +8 champs, +3 interfaces |
| `app/src/app/core/services/debt.ts` | UPDATE | +repay(), +getPayments(), +snooze() |
| `app/src/app/features/debts/components/debt-form/debt-form.ts` | UPDATE | +champs compte, rappel, patrimoine |
| `app/src/app/features/debts/debts.ts` | UPDATE | Tap → navigation détail |
| `app/src/app/features/debts/debts.routes.ts` | UPDATE | +route :id |
| `app/src/app/features/debts/components/debt-detail/` | NEW | Écran détail complet |
| `app/src/app/features/debts/components/repay-dialog/` | NEW | Dialog remboursement |
| `app/src/app/features/debts/components/snooze-dialog/` | NEW | Dialog report rappel |
| `app/src/app/shared/components/toast/` | NEW | Service + composant toast |
| `app/src/app/shared/components/notification-panel/notification-panel.ts` | UPDATE | +actions dette |
| `app/src/app/shared/components/shell/shell.ts` | UPDATE | +toast integration |

## Tests

```bash
cd app && ng test
```
