# Quickstart: Formulaire Virement

**Feature**: 050-flutter-transfer-form | **Date**: 2026-02-23

## Prérequis

- Flutter >= 3.27 installé
- Backend API lancé (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Compte utilisateur créé avec au moins 2 comptes actifs
- KKS-94 (Système Modal) mergé
- KKS-95 (Widget FormField) mergé
- KKS-96 (SelectPicker) mergé
- KKS-115 (Notifiers CRUD) mergé

## Lancer le projet

```bash
cd flutter
flutter run
```

## Tester la feature

1. Se connecter avec un compte existant
2. Vérifier que 2+ comptes actifs existent (sinon en créer)
3. Taper sur le FAB (+)
4. Choisir "Virement" dans le menu
5. Sélectionner un compte source
6. Sélectionner un compte destination (différent)
7. Saisir un montant (ex: 50.00)
8. Optionnel : ajouter une note
9. Taper "Valider"
10. Vérifier que la modal se ferme
11. Vérifier dans la liste des transactions : 2 nouvelles transactions (1 dépense + 1 recette)

## Cas de test validation

- Tenter de valider sans remplir les champs → erreurs affichées
- Sélectionner le même compte source et destination → erreur "comptes différents"
- Saisir un montant de 0 → erreur "montant supérieur à 0"
- Couper le réseau et valider → erreur réseau affichée

## Cas de test FAB conditionnel

- Avec 1 seul compte actif : le FAB ne doit pas proposer "Virement"
- Avec 2+ comptes actifs : le FAB propose "Virement"

## Code generation (si modification des DTOs)

```bash
cd flutter
dart run build_runner build --delete-conflicting-outputs
```
