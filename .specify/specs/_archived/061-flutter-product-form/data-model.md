# Data Model: Formulaire Produit (creation/edition)

**Feature Branch**: `061-flutter-product-form`
**Date**: 2026-03-01

## Entites existantes (aucune modification)

### Product (Flutter — Freezed)

**Fichier**: `flutter/lib/src/domain/models/product.dart`

| Champ | Type | Obligatoire | Utilise dans le formulaire |
|-------|------|-------------|---------------------------|
| id | String | oui (UUID) | Non (genere par l'API) |
| nom | String | oui | Oui — texte, max 100 |
| description | String? | non | Oui — multiline, max 500 |
| icone | String? | non | Non — remplace par image (clarification spec) |
| imageUrl | String? | non | Oui — chemin fichier local (image_picker) |
| prixAchat | double | oui | Oui — decimal, > 0, max 2 decimales |
| prixVente | double | oui | Oui — decimal, > 0, max 2 decimales |
| stock | int | oui | Creation seulement — entier, >= 0 |
| totalVendu | int | oui (default 0) | Non (gere serveur) |
| actif | bool | oui (default true) | Non (gere hors formulaire) |
| createdAt | DateTime? | non | Non (gere serveur) |
| updatedAt | DateTime? | non | Non (gere serveur) |

### ProductRequest (Flutter — Freezed DTO)

**Fichier**: `flutter/lib/src/data/remote/dtos/product_dtos.dart`

Utilise pour la creation. Champs envoyes a l'API :
- `nom`, `description`, `icone`, `imageUrl`, `prixAchat`, `prixVente`, `stock`

### ProductUpdateRequest (Flutter — Freezed DTO)

Utilise pour la mise a jour. Champs envoyes a l'API :
- `nom`, `description`, `icone`, `imageUrl`, `prixAchat`, `prixVente`, `stock`, `actif`

**Note**: En mode edition, le formulaire ne modifie pas `stock` ni `actif`. Le notifier envoie les valeurs existantes du produit pour ces champs.

## Regles de validation (formulaire cote client)

| Champ | Regle | Message d'erreur |
|-------|-------|-----------------|
| nom | Non vide, max 100 caracteres | "Le nom est obligatoire" / "100 caracteres maximum" |
| description | Max 500 caracteres (optionnel) | "500 caracteres maximum" |
| prixAchat | > 0, max 2 decimales | "Le prix d'achat doit etre superieur a 0" |
| prixVente | > 0, max 2 decimales | "Le prix de vente doit etre superieur a 0" |
| stock (creation) | >= 0, entier | "Le stock doit etre superieur ou egal a 0" |

## Calcul derive (affichage pur)

| Derive | Formule | Affichage |
|--------|---------|-----------|
| Marge | `prixVente - prixAchat` | Formate avec `AmountFormatter.format()`, couleur verte si >= 0, rouge si < 0 |

La marge est un calcul d'affichage dans le formulaire. Elle n'est pas persistee ni envoyee a l'API.

## Fichiers locaux (images)

| Aspect | Detail |
|--------|--------|
| Repertoire | `<getApplicationDocumentsDirectory()>/products/` |
| Nommage | `<uuid>.<extension>` (ex: `a1b2c3.jpg`) |
| Source | `image_picker` — camera ou galerie |
| Suppression | Automatique a la suppression/remplacement d'image |
| Lien avec Product | `product.imageUrl` = chemin absolu local |

## Relations et flux

```
ProductListScreen
  │
  ├─ [Creer] → ModalNotifier.open(ModalType.product)
  │               → AppModal.show → ProductForm(product: null)
  │                   → _onSubmit() → onSaved callback
  │                       → ProductNotifier.create(product)
  │                           → ProductRepositoryRemote.create()
  │                               → POST /products (ProductRequest)
  │
  └─ [Editer] → ModalNotifier.open(ModalType.product, entity: product)
                  → AppModal.show → ProductForm(product: existingProduct)
                      → _onSubmit() → onSaved callback
                          → ProductNotifier.update(product)
                              → ProductRepositoryRemote.update()
                                  → PUT /products/{id} (ProductUpdateRequest)
```
