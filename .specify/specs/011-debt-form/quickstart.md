# Quickstart: Formulaire Debt (modal)

**Feature**: 011-debt-form | **Date**: 2026-02-11

## Prerequis

- Node.js installe
- Dependances installees (`cd app && npm install`)
- Backend Spring Boot en cours d'execution (`cd api && mvn spring-boot:run`)

## Demarrage

```bash
cd app && ng serve
```

Ouvrir `http://localhost:4200`, se connecter, puis cliquer sur le bouton flottant (+) et selectionner "Dette".

## Fichiers cles

| Fichier | Role |
|---------|------|
| `app/src/app/features/debts/components/debt-form/debt-form.ts` | Composant formulaire (a creer) |
| `app/src/app/features/debts/components/debt-form/debt-form.html` | Template (a creer) |
| `app/src/app/features/debts/components/debt-form/debt-form.scss` | Styles (a creer) |
| `app/src/app/shared/components/shell/shell.ts` | Integration dans le shell (a modifier) |
| `app/src/app/shared/components/shell/shell.html` | Remplacement placeholder (a modifier) |
| `app/src/app/core/models/debt.model.ts` | Modeles Debt, DebtRequest, DebtType (existant) |

## Tests

```bash
cd app && npx vitest run --reporter=verbose
```

## Verification

1. Ouvrir la modal via (+) > "Dette"
2. Verifier les valeurs par defaut : date = aujourd'hui, sens = Emprunt, rembourse = decoche
3. Soumettre sans remplir → messages d'erreur sur personne, montant
4. Remplir et soumettre → la dette apparait dans la liste
5. Cliquer sur une dette existante → formulaire pre-rempli en mode edition
