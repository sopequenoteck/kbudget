# Data Model: Flutter — Widget CategoryPicker

**Feature**: 040-flutter-categorypicker-widget
**Date**: 2026-02-22

## Modèles existants réutilisés

### Category (domain model — Freezed, déjà existant)

**Fichier** : `flutter/lib/src/domain/models/category.dart`

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `id` | `String` | Oui | Identifiant unique (UUID) |
| `nom` | `String` | Oui | Nom de la catégorie |
| `icone` | `String` | Oui | Icône emoji (chaîne Unicode, ex: "🍔") |
| `couleur` | `String` | Oui | Couleur hex (ex: "#ef4444") |
| `isSystem` | `bool` | Non (défaut: false) | Catégorie système vs utilisateur |
| `updatedAt` | `DateTime?` | Non | Date de dernière mise à jour |

### SelectPickerItem (UI model — déjà existant)

**Fichier** : `flutter/lib/src/common_widgets/select_picker.dart`

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `id` | `String` | Oui | Identifiant unique (non vide) |
| `label` | `String` | Oui | Texte affiché (non vide) |
| `icon` | `String?` | Non | Icône emoji |
| `color` | `Color?` | Non | Couleur de la pastille circulaire |
| `secondaryText` | `String?` | Non | Texte secondaire (non utilisé pour les catégories) |

## Mapping Category → SelectPickerItem

```
Category.id        → SelectPickerItem.id
Category.nom       → SelectPickerItem.label
Category.icone     → SelectPickerItem.icon
Category.couleur   → SelectPickerItem.color (conversion hex String → Color)
(non utilisé)      → SelectPickerItem.secondaryText = null
```

### Conversion couleur hex → Color

Fonction utilitaire pour parser une couleur hex (`"#ef4444"` ou `"ef4444"`) en `Color` Flutter :
- Supprime le préfixe `#` si présent
- Ajoute `FF` pour l'opacité si la chaîne fait 6 caractères
- Parse en `int` base 16, construit `Color(value)`

## Aucun nouveau modèle requis

Le CategoryPicker ne nécessite pas de nouveau type. Il réutilise :
- `Category` du domain pour l'entrée (liste fournie par le parent)
- `SelectPickerItem` pour l'affichage (conversion interne)

## Relations

```
Parent (formulaire)
  │
  ├── fournit List<Category>
  │
  └── CategoryPicker (StatelessWidget)
        │
        ├── convertit Category[] → SelectPickerItem[]
        │
        └── SelectPicker (FormField<String?>)
              │
              ├── affiche les items dans AppModal
              └── emptyActionBuilder → bouton "+ Créer"
```
