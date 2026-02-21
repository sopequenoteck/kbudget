# Data Model: Widget ListItem (Flutter)

**Feature**: 033-flutter-listitem-widget | **Date**: 2026-02-21

## Entity: ListItem

Widget Flutter `StatelessWidget` sans logique métier. Reçoit des données pré-formatées.

### Paramètres (constructor)

| Paramètre | Type | Requis | Default | Description |
|-----------|------|--------|---------|-------------|
| `key` | `Key?` | Non | `null` | Clé Flutter standard |
| `icon` | `String` | Oui | — | Emoji affiché dans le cercle gauche |
| `title` | `String` | Oui | — | Texte principal (tronqué si trop long) |
| `value` | `String` | Oui | — | Montant formaté aligné à droite |
| `subtitle` | `String?` | Non | `null` | Texte secondaire sous le titre |
| `rightSubtitle` | `String?` | Non | `null` | Texte secondaire sous la valeur |
| `valueColor` | `Color?` | Non | `null` | Couleur du texte de la valeur (défaut : onSurface du thème) |
| `iconBackgroundColor` | `Color?` | Non | `null` | Couleur de fond du cercle icône (défaut : `AppColors.amber100`) |
| `onPressed` | `VoidCallback?` | Non | `null` | Callback au tap. Si null : widget non-interactif |

### Constructeur skeleton

| Paramètre | Type | Requis | Default | Description |
|-----------|------|--------|---------|-------------|
| `key` | `Key?` | Non | `null` | Clé Flutter standard |

`ListItem.skeleton()` : constructeur nommé `const`. Initialise les champs requis avec des valeurs vides (`icon = ''`, `title = ''`, `value = ''`) et positionne `_isSkeleton = true`. Le `build()` branche sur `_isSkeleton` pour afficher des placeholders shimmer animés au lieu du contenu réel.

### Champ interne

| Champ | Type | Description |
|-------|------|-------------|
| `_isSkeleton` | `bool` | `false` pour le constructeur principal, `true` pour `.skeleton()`. Détermine le rendu dans `build()`. |

### Validation Rules

- `icon` : non-vide (assertion debug)
- `title` : non-vide (assertion debug)
- `value` : non-vide (assertion debug)
- Pas de validation runtime — le widget fait confiance aux données fournies par le parent (conformément au principe YAGNI)

### Relations avec les tokens existants

```
ListItem
├── uses → AppSpacing (space1, space3, space4, space10)
├── uses → AppTypography (sizeSm, sizeMd, sizeLg, medium, semiBold)
├── uses → AppColors (amber100 comme défaut iconBackgroundColor)
├── uses → AppRadius (round pour cercle icône)
├── uses → Theme.colorScheme (onSurface, onSurfaceVariant)
└── uses → shimmer (package, pour skeleton uniquement)
```

### Usage Pattern (par les écrans consommateurs)

```dart
// Transaction
ListItem(
  icon: transaction.category?.icone ?? '📝',
  title: transaction.libelle,
  subtitle: transaction.category?.nom,
  value: AmountFormatter.format(transaction.montant, type: transaction.type.name),
  valueColor: AmountFormatter.amountColor(transaction.type.name, colors),
  rightSubtitle: RelativeDateFormatter.format(transaction.date),
  onPressed: () => onTransactionTap(transaction),
)

// Abonnement
ListItem(
  icon: subscription.category?.icone ?? '🔄',
  title: subscription.nom,
  subtitle: subscription.frequence == Frequency.mensuel ? 'Mensuel' : 'Annuel',
  value: AmountFormatter.format(subscription.montant),
  onPressed: () => onSubscriptionTap(subscription),
)

// Dette
ListItem(
  icon: debt.type == DebtType.emprunt ? '📥' : '📤',
  title: debt.personne,
  subtitle: debt.type == DebtType.emprunt ? 'Emprunt' : 'Prêt',
  value: AmountFormatter.format(debt.montant),
  valueColor: AmountFormatter.amountColor(debt.type.name, colors),
  rightSubtitle: RelativeDateFormatter.format(debt.date),
  onPressed: () => onDebtTap(debt),
)

// Skeleton (état de chargement)
ListItem.skeleton()
```

### Pas de migration / pas de contrat API

Ce widget est un composant frontend pur. Aucune migration de base de données, aucun endpoint API, aucun contrat REST n'est nécessaire.
