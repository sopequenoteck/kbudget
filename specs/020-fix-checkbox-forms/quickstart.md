# Quickstart: Fix checkboxes non fonctionnelles

## Prérequis

- Node.js installé
- Dépendances frontend installées (`cd app && npm install`)

## Vérification

```bash
# 1. Build frontend (vérifier absence d'erreurs SCSS)
cd app && ng build

# 2. Lancer le dev server
cd app && ng serve

# 3. Ouvrir http://localhost:4200

# 4. Se connecter

# 5. Test checkbox Abonnement
#    - Naviguer vers Abonnements
#    - Cliquer (+) → formulaire création
#    - Vérifier que la checkbox "Abonnement actif" est visible et cochée par défaut
#    - Cliquer dessus → doit se décocher visuellement
#    - Soumettre → vérifier actif = false

# 6. Test checkbox Dette
#    - Naviguer vers Dettes
#    - Cliquer (+) → formulaire création
#    - Vérifier que la checkbox "Remboursé" est visible et décochée par défaut
#    - Cliquer dessus → doit se cocher visuellement
#    - Soumettre → vérifier rembourse = true

# 7. Test régression
#    - Vérifier que les champs texte (montant, libellé, etc.) n'ont pas changé d'apparence
#    - Vérifier que les select (type, fréquence) n'ont pas changé d'apparence
```

## Fichiers modifiés

| Fichier | Modification |
|---------|-------------|
| `app/src/styles/_forms.scss` | Exclusion checkbox/radio du sélecteur global + style dédié |
| `app/src/app/features/subscriptions/components/subscription-form/subscription-form.scss` | Suppression styles checkbox dupliqués |
| `app/src/app/features/debts/components/debt-form/debt-form.scss` | Suppression styles checkbox dupliqués |
