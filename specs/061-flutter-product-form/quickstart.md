# Quickstart: Formulaire Produit (creation/edition)

## Prerequis

- Flutter >= 3.27 installe
- API backend demarree (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Module shop active dans les preferences utilisateur (Feature.shop)

## Demarrage rapide

```bash
# 1. Installer les nouvelles dependances
cd flutter && flutter pub get

# 2. Regenerer le code (si modifications Freezed/JSON)
cd flutter && dart run build_runner build --delete-conflicting-outputs

# 3. Lancer l'app
cd flutter && flutter run
```

## Fichiers cles

| Fichier | Role |
|---------|------|
| `flutter/lib/src/features/shop/presentation/widgets/product_form.dart` | Widget formulaire principal |
| `flutter/lib/src/features/shop/presentation/product_list_screen.dart` | Ecran liste (ouvre le formulaire) |
| `flutter/lib/src/utils/decimal_input_formatter.dart` | Formatter 2 decimales |
| `flutter/lib/src/domain/enums/modal_type.dart` | ModalType.product |
| `flutter/lib/src/routing/app_router.dart` | Case ProductForm dans _buildModalChild |

## Tester manuellement

1. Naviguer vers le module Boutique (onglet Shop)
2. **Creation**: Appuyer sur "Creer un produit" (etat vide) ou le bouton d'ajout
3. Remplir: nom, prix achat, prix vente, stock initial
4. Verifier la marge temps reel
5. Optionnel: ajouter photo (camera ou galerie)
6. Enregistrer → produit apparait dans la liste
7. **Edition**: Taper sur un produit → formulaire pre-rempli, stock masque
8. Modifier un prix → marge se met a jour
9. Enregistrer → modifications refletees dans la liste

## Tester automatiquement

```bash
cd flutter && flutter test test/src/features/shop/presentation/widgets/product_form_test.dart
```
