# Implementation Plan: Sync TextScale via API

**Branch**: `094-sync-text-scale-api` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/094-sync-text-scale-api/spec.md`

## Summary

Ajouter le champ `textScale` (enum SMALL/MEDIUM/LARGE) à l'entité UserPreference, aux DTOs, au service backend, et à la migration Flyway V21. Côté Angular, le PreferenceService charge/sauve la valeur via l'API et le TextScaleService l'applique comme CSS. Pattern identique à `timezone`.

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (frontend)
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Angular 21
**Storage**: PostgreSQL 15+ (Flyway V21)
**Testing**: JUnit 5 + Mockito (backend), Vitest (frontend)
**Target Platform**: API REST + PWA
**Project Type**: Web application full-stack
**Performance Goals**: < 200ms pour GET/PUT preferences
**Constraints**: Migration non-destructive, rétro-compatible
**Scale/Scope**: 1 enum + 1 champ entité + 2 DTOs + 1 service + 1 migration (backend), 2 services modifiés + 1 modèle (frontend)

## Constitution Check

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Champ ajouté à l'API REST existante (GET/PUT /users/me/preferences) |
| II. Sécurité | PASS | Endpoint protégé JWT, filtrage par user authentifié (existant) |
| III. Simplicité/YAGNI | PASS | 1 champ simple dans une entité existante, pattern identique à timezone |
| IV. Mobile-First | PASS | Frontend Angular utilise l'API pour sync |
| V. Testabilité | PASS | Tests d'intégration backend + tests unitaires service |
| VI. Observabilité | PASS | Actions loguées au niveau INFO (existant dans PreferenceService) |
| VII. Self-Hosted | PASS | PostgreSQL uniquement |

**GATE RESULT**: PASS

## Project Structure

### Documentation

```text
specs/094-sync-text-scale-api/
├── plan.md
├── spec.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code

```text
api/src/main/java/fr/kksdev/budget/api/
├── enums/
│   └── TextScale.java                    # NOUVEAU — enum SMALL, MEDIUM, LARGE
├── model/
│   └── UserPreference.java               # MODIFIÉ — +textScale field
├── dto/
│   ├── request/UserPreferenceRequest.java # MODIFIÉ — +textScale field
│   └── response/UserPreferenceResponse.java # MODIFIÉ — +textScale field
├── service/
│   └── PreferenceService.java            # MODIFIÉ — merge textScale + toResponse
└── resources/db/migration/
    └── V21__add_text_scale.sql           # NOUVEAU — ALTER TABLE

app/src/app/
├── core/
│   ├── models/preference.model.ts        # MODIFIÉ — +textScale
│   ├── services/preference.ts            # MODIFIÉ — +signal textScale, +updateTextScale()
│   └── services/text-scale.ts            # MODIFIÉ — lire depuis PreferenceService au lieu de localStorage
└── features/settings/components/appearance/
    └── appearance.ts                     # MODIFIÉ — utiliser PreferenceService pour sync
```

### Fichiers modifiés (inventaire)

| Fichier | Changement | FR |
|---------|-----------|-----|
| `enums/TextScale.java` | NOUVEAU — enum | FR-001 |
| `model/UserPreference.java` | +champ `textScale` (TextScale, default MEDIUM) | FR-001, FR-002 |
| `dto/request/UserPreferenceRequest.java` | +champ `TextScale textScale` (nullable) | FR-004 |
| `dto/response/UserPreferenceResponse.java` | +champ `TextScale textScale` | FR-003 |
| `service/PreferenceService.java` | Merger textScale dans updatePreferences() + toResponse() | FR-004 |
| `V21__add_text_scale.sql` | `ALTER TABLE user_preferences ADD COLUMN text_scale VARCHAR(20) DEFAULT 'MEDIUM'` | FR-008 |
| `preference.model.ts` | +`textScale?: string` aux interfaces | FR-003 |
| `preference.ts` | +signal, +loadPreferences(), +updateTextScale() | FR-005, FR-006 |
| `text-scale.ts` | Lire depuis PreferenceService, garder localStorage comme cache | FR-006, FR-007 |

## Design Decisions

### D1 — Enum TextScale (backend)

Enum Java simple dans `api/enums/` avec 3 valeurs : `SMALL`, `MEDIUM`, `LARGE`. Stocké en VARCHAR dans la base (pas de converter custom — JPA utilise `@Enumerated(EnumType.STRING)` par défaut sur les enums).

### D2 — Champ UserPreference

```java
@Builder.Default
@Enumerated(EnumType.STRING)
@Column(name = "text_scale", length = 20)
private TextScale textScale = TextScale.MEDIUM;
```

Pattern identique à `timezone` : champ simple avec valeur par défaut.

### D3 — DTO nullable (partial update)

Dans `UserPreferenceRequest`, le champ est `TextScale textScale` (nullable). Si null dans la requête PUT, la valeur actuelle est conservée (même logique que timezone dans `updatePreferences()`).

### D4 — Frontend : PreferenceService + TextScaleService

Le `PreferenceService` gère la communication API (signal `textScale`, méthode `updateTextScale()`). Le `TextScaleService` s'abonne au signal du `PreferenceService` et applique le CSS. Le `localStorage` est conservé comme cache de démarrage rapide (évite un flash de taille incorrecte avant le chargement API).

Flow :
1. App démarre → TextScaleService lit localStorage → applique immédiatement
2. PreferenceService.loadPreferences() → GET API → met à jour signal textScale
3. TextScaleService.effect() → détecte changement → met à jour CSS + localStorage
4. User change taille → PreferenceService.updateTextScale() → PUT API (fire-and-forget) + update signal
5. TextScaleService.effect() → applique CSS + cache localStorage

### D5 — Migration V21

```sql
ALTER TABLE user_preferences ADD COLUMN text_scale VARCHAR(20) DEFAULT 'MEDIUM';
```

Non-destructive. Les lignes existantes reçoivent MEDIUM. Pas de NOT NULL pour rester cohérent avec le pattern nullable des autres champs (timezone).

## Complexity Tracking

> Aucune violation — section vide.
