# Data Model: 097-angular-emoji-picker

**Date**: 2026-03-20

## Entities

Cette feature ne modifie aucune entité backend. Pas de migration, pas de DTO, pas de endpoint.

### EmojiInput (composant Angular)

| Propriété | Type | Direction | Description |
|-----------|------|-----------|-------------|
| `value` | `string` | Input | Emoji actuellement sélectionné (caractère Unicode) |
| `valueChange` | `EventEmitter<string>` | Output | Événement émis à la sélection d'un emoji |

**State interne** :
- `isOpen: signal<boolean>` — état ouvert/fermé du popover picker
- Thème détecté depuis la classe DOM (`.theme-dark`)

### Données persistées (navigateur)

- **Emojis récents** : gérés automatiquement par emoji-mart dans `localStorage` (clé interne au package). Pas de gestion manuelle nécessaire.

## Relations

```
AccountForm ──uses──> EmojiInput ──opens──> emoji-mart picker
CategoryForm ──uses──> EmojiInput ──opens──> emoji-mart picker
```

Aucune relation avec le backend. Feature 100% frontend.
