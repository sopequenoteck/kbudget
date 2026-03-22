# Quickstart: Refonte UX formulaire Transaction

**Branch**: `019-form-ux-refonte`

## Prerequis

- Node.js et Angular CLI installes
- Le projet `app/` compile sans erreur

## Demarrage rapide

```bash
cd app && ng serve
```

Ouvrir `http://localhost:4200`, se connecter, puis cliquer sur le FAB (+) > Transaction pour voir le formulaire.

## Verification

### Creation

1. Cliquer sur (+) > Transaction
2. Verifier : toggle Depense/Recette dans le header du modal
3. Verifier : champs en grille 2 colonnes (libelle + montant, categorie + date, note)
4. Remplir et soumettre

### Edition

1. Aller dans la liste des transactions
2. Cliquer sur une transaction existante
3. Verifier : toggle reflete le type existant
4. Verifier : bouton Supprimer a gauche de la barre d'actions

### Responsive

1. Ouvrir DevTools > Device Mode
2. Selectionner un viewport < 400px
3. Verifier : champs empiles en colonne unique

### Non-regression

1. Ouvrir le formulaire d'abonnement (FAB > Abonnement)
2. Verifier : pas de toggle dans le header, formulaire inchange
3. Repeter pour dette et categorie

## Fichiers modifies

| Fichier | Changement |
|---------|------------|
| `shared/components/modal/modal.html` | Slot `ng-content[modal-header-actions]` |
| `shared/components/modal/modal.scss` | Header layout avec gap |
| `shared/components/shell/shell.ts` | Signal `transactionType`, handler |
| `shared/components/shell/shell.html` | Toggle projete dans header |
| `shared/components/shell/shell.scss` | Styles `.type-toggle` compact |
| `features/transactions/.../transaction-form.ts` | `input(type)`, retrait type du FormGroup |
| `features/transactions/.../transaction-form.html` | Layout grille, actions fusionnees |
| `features/transactions/.../transaction-form.scss` | `.form-row` grid, retrait `.type-toggle` |
