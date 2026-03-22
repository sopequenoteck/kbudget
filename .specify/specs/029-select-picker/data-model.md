# Data Model: SelectPicker generique

**Feature**: 029-select-picker | **Date**: 2026-02-17

> Note : cette feature est purement frontend. Ce document decrit les interfaces TypeScript et l'API du composant (pas de modele de donnees backend).

## Interfaces

### SelectPickerItem

Representation generique d'un element selectionnable. Transformee par le formulaire parent a partir des entites metier (Account, Category, etc.).

```
SelectPickerItem {
  id: string              # Identifiant unique (obligatoire)
  label: string           # Texte principal affiche (obligatoire)
  icon: string | null     # Emoji ou icone (optionnel, affiche avant le label)
  secondaryText: string | null  # Texte secondaire (optionnel, ex: solde du compte)
  color: string | null    # Couleur associee (optionnel, ex: couleur du compte)
}
```

**Regles de validation** :
- `id` ne peut pas etre vide
- `label` ne peut pas etre vide
- `icon`, `secondaryText`, `color` sont optionnels (null par defaut)

**Transformations depuis les entites existantes** :

| Entite source | id | label | icon | secondaryText | color |
|---------------|-----|-------|------|---------------|-------|
| Account | account.id | account.nom | account.icone | `{solde} €` (formate) | account.couleur |
| Category | category.id | category.nom | category.icone | null | null |

## API du composant SelectPicker

### Inputs

| Input | Type | Defaut | Description |
|-------|------|--------|-------------|
| items | SelectPickerItem[] | [] | Liste des elements selectionnables |
| placeholder | string | 'Selectionner...' | Texte affiche quand aucun element n'est selectionne |
| searchable | boolean | null | Force l'activation (true) ou desactivation (false) de la recherche. Si null, le seuil s'applique |
| searchThreshold | number | 5 | Nombre d'items a partir duquel la recherche s'active automatiquement (si searchable est null) |
| searchPlaceholder | string | 'Rechercher...' | Placeholder du champ de recherche |
| clearable | boolean | true | Affiche le bouton pour vider la selection |
| emptyMessage | string | 'Aucun element disponible' | Message affiche quand la liste est vide |
| disabled | boolean | false | Desactive le composant (via setDisabledState de ControlValueAccessor) |

### Outputs

| Output | Type | Description |
|--------|------|-------------|
| opened | void | Emis quand le dropdown s'ouvre |
| closed | void | Emis quand le dropdown se ferme |

### ControlValueAccessor

| Methode | Comportement |
|---------|-------------|
| writeValue(id: string) | Selectionne l'item correspondant a l'id |
| registerOnChange(fn) | Stocke le callback appele a chaque selection/desselection |
| registerOnTouched(fn) | Stocke le callback appele au premier blur |
| setDisabledState(disabled) | Met a jour le signal `disabled` interne |

**Valeur emise** : `string` (l'id de l'item selectionne) ou `''` (selection videe)

## Etats du composant

```
                    ┌──────────┐
                    │  CLOSED  │ (etat initial)
                    └────┬─────┘
                         │ click / Enter / Space
                         ▼
                ┌────────────────┐
                │    OPEN        │
                │  (dropdown     │
                │   visible)     │
                └───┬───┬───┬───┘
                    │   │   │
         select     │   │   │ Escape / click outside
         item       │   │   │
                    │   │   ▼
                    │   │ ┌──────────┐
                    │   │ │  CLOSED  │
                    │   │ └──────────┘
                    │   │
                    │   │ saisie texte (si searchable)
                    │   ▼
                ┌────────────────┐
                │  SEARCHING     │
                │  (filtre actif)│
                └───┬────────┬──┘
                    │        │
         select     │        │ Escape / clear
                    ▼        ▼
              ┌──────────┐ ┌──────────┐
              │  CLOSED  │ │  OPEN    │
              │(selected)│ │(no filter│
              └──────────┘ └──────────┘
```

**Etats supplementaires** :
- `DISABLED` : overlay grise, aucune interaction possible
- `BOTTOM_SHEET` : sur mobile (<768px), le dropdown est remplace par un overlay ancre en bas

## Rendu responsive

### Desktop (>=768px)

```
┌─────────────────────────────┐
│ 🏦 Compte courant     ×    │  ← Chip selectionne (ou placeholder)
└─────────────────────────────┘
┌─────────────────────────────┐
│ 🔍 Rechercher...            │  ← Champ recherche (si actif)
├─────────────────────────────┤
│ 🏦 Compte courant   150 €  │  ← Item (icon + label + secondaryText)
│ 💰 Livret A        2000 €  │
│ 💵 Especes           50 €  │
└─────────────────────────────┘
   ↑ position: absolute, ancre sous le champ
```

### Mobile (<768px)

```
┌─────────────────────────────────────┐
│          (overlay sombre)           │
│                                     │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Selectionner un compte          │ │  ← Titre
│ │ 🔍 Rechercher...                │ │  ← Champ recherche (si actif)
│ ├─────────────────────────────────┤ │
│ │ 🏦 Compte courant       150 €  │ │
│ │ 💰 Livret A            2000 €  │ │
│ │ 💵 Especes               50 €  │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
   ↑ position: fixed, ancre en bas (bottom-sheet)
```

## Impact sur les composants existants

### CategoryPicker (refactore en wrapper)

**Avant** : composant autonome (184 lignes) avec toute la logique de selection + recherche + creation inline
**Apres** : thin wrapper qui :
- Transforme `Category[]` en `SelectPickerItem[]`
- Passe `searchable=true` au SelectPicker
- Ecoute un output `noMatch` (ou verifie l'absence de match) pour afficher le bouton "Creer"
- Conserve la modal de creation et le service `CategoryService`

### AccountPicker (supprime)

**Avant** : composant presentationnel (30 lignes) avec chips horizontaux
**Apres** : supprime. Les formulaires parents utilisent directement `<app-select-picker>` en transformant `Account[]` en `SelectPickerItem[]`.

### TransferForm (modifie)

**Avant** : 2 `<select>` natifs avec `formControlName`
**Apres** : 2 `<app-select-picker>` avec `formControlName`, meme validation `differentAccountsValidator`
