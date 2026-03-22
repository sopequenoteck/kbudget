# Quickstart: Virement entre comptes Angular

**Feature**: 066-angular-transfer-form

## Prérequis

- Node.js installé
- Backend Spring Boot lancé (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Au moins 2 comptes actifs créés dans l'application

## Lancer le frontend

```bash
cd app && ng serve
```

Accéder à `http://localhost:4200`.

## Tester le virement

1. Ouvrir l'application dans le navigateur
2. Cliquer sur le bouton flottant (+) en bas à droite
3. L'option "Virement" (↔️) apparaît si 2+ comptes actifs
4. Sélectionner un compte source
5. Sélectionner un compte destination (différent)
6. Saisir un montant > 0
7. Optionnellement, ajouter une note
8. Cliquer "Effectuer le virement"
9. Vérifier que 2 transactions liées apparaissent dans la liste

## Lancer les tests

```bash
cd app && npx vitest run --reporter=verbose src/app/shared/components/transfer-form/transfer-form.spec.ts
```

## Fichiers clés

| Fichier | Rôle |
|---------|------|
| `app/src/app/shared/components/transfer-form/transfer-form.ts` | Composant formulaire |
| `app/src/app/shared/components/transfer-form/transfer-form.html` | Template |
| `app/src/app/shared/components/transfer-form/transfer-form.scss` | Styles |
| `app/src/app/shared/components/transfer-form/transfer-form.spec.ts` | Tests |
| `app/src/app/core/models/account.model.ts` | Interfaces TransferRequest/Response |
| `app/src/app/core/services/account.ts` | AccountService.transfer() |
| `app/src/app/shared/components/fab/fab.ts` | Action FAB conditionnelle |
| `app/src/app/shared/components/shell/shell.ts` | Orchestration modale |
