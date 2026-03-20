# Quickstart: 097-angular-emoji-picker

**Date**: 2026-03-20

## Prérequis

- Node.js (version du projet)
- Angular CLI (`ng`)
- Dépendances du projet installées (`cd app && npm install`)

## Installation des nouvelles dépendances

```bash
cd app && npm install emoji-mart @emoji-mart/data
```

## Développement

```bash
cd app && ng serve
```

Ouvrir `http://localhost:4200`, naviguer vers :
- Paramètres > Catégories > Créer/Éditer une catégorie → champ emoji
- Paramètres > Comptes > Créer/Éditer un compte → champ emoji

## Tests

```bash
cd app && ng test
```

## Vérification manuelle

1. Ouvrir le formulaire catégorie
2. Cliquer sur la box emoji → le picker s'ouvre
3. Naviguer les catégories (labels en français)
4. Rechercher "soleil" → emojis correspondants affichés
5. Cliquer sur un emoji → picker se ferme, emoji affiché dans la box
6. Rouvrir → section "Récents" en premier
7. Basculer en dark mode → picker s'adapte
8. Cliquer à l'extérieur → picker se ferme sans changement
9. Appuyer Escape → picker se ferme sans changement
10. Vérifier le même comportement dans le formulaire compte
