# Data Model: Sync TextScale via API

**Branch**: `094-sync-text-scale-api` | **Date**: 2026-03-15

## Entité modifiée : UserPreference

### Nouveau champ

| Champ | Type | Default | Nullable | Contrainte |
|-------|------|---------|----------|-----------|
| `textScale` | TextScale (enum: SMALL, MEDIUM, LARGE) | MEDIUM | Oui (en base) | Valeur applicative par défaut MEDIUM |

### Enum TextScale

| Valeur | Signification | Facteur CSS |
|--------|--------------|-------------|
| SMALL | Texte réduit | 0.85x |
| MEDIUM | Texte normal (défaut) | 1.0x |
| LARGE | Texte agrandi | 1.3x |

### Migration SQL (V21)

```sql
ALTER TABLE user_preferences ADD COLUMN text_scale VARCHAR(20) DEFAULT 'MEDIUM';
```

### Impact DTOs

| DTO | Champ ajouté | Nullable |
|-----|-------------|----------|
| `UserPreferenceRequest` | `TextScale textScale` | Oui (partial update) |
| `UserPreferenceResponse` | `TextScale textScale` | Non (toujours renvoyé) |
