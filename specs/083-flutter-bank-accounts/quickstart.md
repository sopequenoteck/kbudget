# Quickstart: 083-flutter-bank-accounts

## Prérequis

- Backend KKS-081 déployé (endpoint `GET /api/banks`, champs bank sur comptes)
- Flutter >= 3.27, Dart >= 3.6
- `flutter_svg` ajouté au pubspec.yaml

## Fichiers à créer

| Fichier | Description |
|---------|-------------|
| `flutter/lib/src/domain/models/bank.dart` | Modèle Bank (Freezed) |
| `flutter/lib/src/data/remote/dtos/bank_dtos.dart` | BankResponse DTO (Freezed) |
| `flutter/lib/src/data/remote/data_sources/bank_remote_data_source.dart` | DataSource Dio GET /api/banks |
| `flutter/lib/src/domain/repositories/bank_repository.dart` | Interface abstraite |
| `flutter/lib/src/features/accounts/data/bank_repository_remote.dart` | Implémentation remote |
| `flutter/lib/src/features/accounts/application/bank_provider.dart` | banksProvider (FutureProvider) |
| `flutter/lib/src/common_widgets/bank_select_picker.dart` | Sélecteur banque (bottom sheet groupée) |
| `flutter/lib/src/common_widgets/account_bank_icon.dart` | Widget résolution logo (SVG/custom/emoji) |
| `flutter/assets/banks/*.svg` | 29 logos SVG embarqués |

## Fichiers à modifier

| Fichier | Modification |
|---------|-------------|
| `flutter/pubspec.yaml` | Ajouter `flutter_svg`, déclarer assets `assets/banks/` |
| `flutter/lib/src/domain/models/account.dart` | Ajouter 7 champs bank au modèle Freezed |
| `flutter/lib/src/data/remote/dtos/account_dtos.dart` | Ajouter champs bank aux DTOs request/response |
| `flutter/lib/src/data/local/database.dart` | Ajouter 3 colonnes à la table Accounts, migration schema |
| `flutter/lib/src/data/local/mappers.dart` | Mapper les 3 champs bank (accountFromDb/accountToDb) |
| `flutter/lib/src/features/accounts/data/account_repository_remote.dart` | Mapper les champs bank dans _toDomain/_toRequest |
| `flutter/lib/src/features/accounts/presentation/screens/account_form_screen.dart` | Ajouter sélecteur banque + masquage conditionnel + upload logo custom |
| `flutter/lib/src/features/accounts/presentation/widgets/account_preview_card.dart` | Supporter affichage logo banque |
| `flutter/lib/src/features/accounts/presentation/widgets/account_list_tile.dart` | Remplacer emoji par AccountBankIcon |
| `flutter/lib/src/features/dashboard/presentation/widgets/hero_account_section.dart` | Remplacer emoji par AccountBankIcon (_HeroCard + _AccountRow) |
| `flutter/lib/src/common_widgets/select_picker.dart` | Ajouter champ `imageUrl` à SelectPickerItem + rendu |

## Séquence de build

```bash
# 1. Copier les assets SVG
cp api/src/main/resources/static/bank-logos/*.svg flutter/assets/banks/

# 2. Ajouter flutter_svg au pubspec
cd flutter && flutter pub add flutter_svg

# 3. Code generation (après modification des modèles Freezed)
cd flutter && dart run build_runner build --delete-conflicting-outputs

# 4. Vérifier l'analyse statique
cd flutter && flutter analyze

# 5. Tests
cd flutter && flutter test
```

## Vérification rapide

1. Lancer le backend : `cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`
2. Lancer l'app Flutter : `cd flutter && flutter run`
3. Naviguer vers Paramètres > Comptes > Nouveau compte
4. Vérifier que le sélecteur de banque apparaît en haut du formulaire
5. Sélectionner une banque connue (ex: SG) → icône/couleur masqués, logo SVG affiché
6. Sélectionner "Autre" → icône/couleur réapparaissent, champ nom custom visible
7. Sauvegarder → vérifier le logo dans la liste des comptes et le dashboard
