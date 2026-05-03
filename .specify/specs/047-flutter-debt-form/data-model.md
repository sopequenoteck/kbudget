# Data Model: Formulaire Dette Flutter

**Feature**: `047-flutter-debt-form` | **Date**: 2026-02-23

## Entités

### Debt (existante — aucune modification)

```
Debt
├── id: String (UUID)
├── personne: String (obligatoire, max 255 car.)
├── montant: double (obligatoire, positif)
├── sens: DebtType (emprunt | pret)
├── date: DateTime (obligatoire)
├── currency: Currency (défaut: EUR)
├── rembourse: bool (défaut: false)
├── categoryId: String? (FK → Category, optionnel)
└── updatedAt: DateTime?
```

### Category (existante — aucune modification)

```
Category
├── id: String (UUID)
├── nom: String
├── icone: String (emoji)
├── couleur: String (hex color)
├── isSystem: bool
└── updatedAt: DateTime?
```

### DebtType (enum existant — aucune modification)

```
DebtType
├── emprunt
└── pret
```

## Relations

```
Debt ──(0..1)──> Category (via categoryId, optionnel)
Debt ──(1)──> DebtType (via sens, obligatoire)
```

## Transitions d'état

```
[Création] → Non remboursée (rembourse = false)
                │
                ├── [Édition] → Modifiée (champs mis à jour)
                │
                ├── [Marquer remboursée] → Remboursée (rembourse = true)
                │       │
                │       └── [Annuler remboursement] → Non remboursée
                │
                └── [Suppression] → Supprimée (définitif)
```

## Règles de validation

| Champ | Règle | Message d'erreur |
| ----- | ----- | ---------------- |
| personne | Non vide, non blank | "Le nom est obligatoire" |
| montant | Non vide, parsable en double, > 0 | "Le montant doit être positif" |
| date | Non null | "La date est obligatoire" |
| sens | Fourni par le toggle modal | Pas de validation formulaire |
| categoryId | Optionnel | Pas de validation |

## Impact sur le modèle existant

**Aucune modification du modèle de données.** Le modèle Debt (Freezed), la table Drift, les DTOs remote, le DAO et les mappers sont tous déjà implémentés et complets. Ce feature ne fait qu'ajouter l'interface utilisateur (widget formulaire).
