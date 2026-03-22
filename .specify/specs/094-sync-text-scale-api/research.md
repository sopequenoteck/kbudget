# Research: Sync TextScale via API

**Branch**: `094-sync-text-scale-api` | **Date**: 2026-03-15

## R1 — Stockage enum en base : VARCHAR vs ordinal

**Decision**: Stocker en VARCHAR via `@Enumerated(EnumType.STRING)`.

**Rationale**: Le projet utilise déjà ce pattern pour tous les enums (Feature, Currency, NotificationType, Frequency, etc.). VARCHAR est lisible en base et résistant aux réordonnancements de l'enum.

**Alternatives rejected**:
- `EnumType.ORDINAL` : fragile, un ajout d'enum casse les données existantes
- Converter custom : over-engineering pour un enum de 3 valeurs

## R2 — Pattern de sync frontend : signal bridge

**Decision**: Le `PreferenceService` possède le signal `textScale`. Le `TextScaleService` s'y abonne via `effect()` et applique le CSS.

**Rationale**: Évite un couplage bidirectionnel. Le PreferenceService est la source de vérité (API). Le TextScaleService est un consommateur qui traduit la valeur en effet CSS. Le localStorage sert de cache de démarrage rapide.

**Flow de démarrage**:
1. `TextScaleService` construit → lit localStorage → applique CSS immédiatement
2. `PreferenceService.loadPreferences()` (appelé par le shell au login) → GET API → met à jour signal
3. `TextScaleService.effect()` détecte le changement de signal → met à jour CSS + localStorage

**Avantage** : pas de flash de taille incorrecte au démarrage (localStorage donne la valeur instantanément).

## R3 — Migration : NOT NULL vs nullable

**Decision**: Colonne nullable avec DEFAULT 'MEDIUM'.

**Rationale**: Tous les autres champs ajoutés après V9 (currencies, timezone, enabledNotificationTypes) sont nullable avec un défaut géré côté applicatif. Garder la cohérence. Le `@Builder.Default` dans l'entité Java assure la valeur MEDIUM si null en base.
