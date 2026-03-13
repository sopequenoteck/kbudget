# Implementation Plan: Banques sur les comptes — Angular

**Branch**: `082-angular-bank-accounts` | **Date**: 2026-03-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/082-angular-bank-accounts/spec.md`

## Summary

Intégrer l'association bancaire dans le frontend Angular : service `BankService` (signal-based, cache), sélecteur de banque groupé par région avec recherche dans le formulaire compte, composant `AccountBankIcon` réutilisable pour la résolution logo banque/custom/emoji, et mise à jour de l'affichage partout où un compte est visible.

## Technical Context

**Language/Version**: TypeScript 5.9
**Primary Dependencies**: Angular 21, Angular Reactive Forms, @ng-icons/phosphor-icons
**Storage**: N/A (server-only, données fraîches depuis l'API)
**Testing**: Vitest (Angular test runner)
**Target Platform**: PWA mobile-first (Chrome, Safari iOS)
**Project Type**: Web application (frontend Angular)
**Performance Goals**: Affichage instantané du sélecteur (<100ms après cache), logos SVG dimensionnés 24×24/32×32
**Constraints**: Logos SVG servis par le backend (`/api/bank-logos/{code}.svg`), pas d'assets locaux
**Scale/Scope**: 29 banques prédéfinies, ~6 écrans impactés

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Consomme `GET /api/banks` (public) + champs bank enrichis sur `AccountResponse`/`AccountRequest` existants |
| II. Sécurité par défaut | PASS | `GET /banks` est public (registre statique). Les comptes restent protégés par JWT + filtrage user |
| III. Simplicité & YAGNI | PASS | Pas de nouveau pattern — suit les conventions existantes (signal-based services, SelectPicker). `BankSelectComponent` spécialisé car le groupement par région et le pinning "Autre" dépassent les capacités du `SelectPicker` générique |
| IV. Mobile-First UX | PASS | Sélecteur avec recherche pour accès rapide. Masquage conditionnel réduit la charge cognitive |
| V. Testabilité | PASS | Tests unitaires sur BankService, BankSelectComponent, AccountBankIcon, AccountForm enrichi |
| VI. Observabilité | N/A | Feature frontend pure, pas de logging backend nécessaire |
| VII. Self-Hosted Ready | PASS | Logos servis depuis le backend, aucune dépendance externe |

## Project Structure

### Documentation (this feature)

```text
specs/082-angular-bank-accounts/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   ├── models/
│   │   ├── account.model.ts        # UPDATE: +7 champs bank sur Account, +3 sur AccountRequest
│   │   └── bank.model.ts           # NEW: BankResponse interface
│   └── services/
│       └── bank.ts                 # NEW: BankService (signal-based, cache)
├── shared/components/
│   ├── account-bank-icon/          # NEW: composant résolution logo
│   │   ├── account-bank-icon.ts
│   │   ├── account-bank-icon.html
│   │   └── account-bank-icon.scss
│   ├── bank-select/                # NEW: sélecteur banque groupé
│   │   ├── bank-select.ts
│   │   ├── bank-select.html
│   │   └── bank-select.scss
│   └── account-form/
│       ├── account-form.ts         # UPDATE: section banque + masquage conditionnel
│       ├── account-form.html       # UPDATE: template enrichi
│       └── account-form.scss       # UPDATE: styles section banque
├── features/settings/components/
│   └── accounts/
│       ├── accounts.ts             # UPDATE: utiliser AccountBankIcon
│       └── accounts.html           # UPDATE: logo banque dans la liste
```

**Structure Decision**: Feature frontend Angular pure. Nouveaux fichiers dans `core/models/`, `core/services/`, et `shared/components/`. Modifications ciblées sur les composants existants d'affichage de compte.

## Design Decisions

### DD-001: BankSelectComponent dédié vs réutilisation de SelectPicker

**Décision** : Créer un `BankSelectComponent` dédié.

**Rationale** : Le `SelectPicker` existant supporte une liste plate avec icônes. Le sélecteur de banque nécessite un groupement par région (France/Afrique de l'Ouest/International), le pinning de l'option "Autre" en bas de liste même pendant le filtrage, et l'affichage de logos SVG (images) plutôt que d'emojis. Ces 3 comportements spécifiques ne s'intègrent pas proprement dans le `SelectPicker` sans le complexifier inutilement.

**Alternatives rejetées** : Étendre `SelectPicker` avec des groupes — ajouterait de la complexité à un composant déjà utilisé dans 6+ endroits.

### DD-002: Cache des banques

**Décision** : Signal `banks` dans `BankService`, chargé une seule fois au premier accès (lazy loading).

**Rationale** : La liste des banques est statique (registre backend). Un seul `GET /api/banks` puis cache signal est suffisant. Pas besoin de refresh trigger car les banques ne changent pas pendant une session.

### DD-003: Résolution logo dans AccountBankIcon

**Décision** : Logique de résolution en 3 niveaux dans le composant :
1. `bankCode ≠ OTHER` → `<img src="bankLogoUrl">` (SVG du backend)
2. `bankCode = OTHER` + `bankCustomLogo` → `<img src="bankCustomLogo">` (data URI)
3. `bankCode = OTHER` + pas de logo custom → `<span>{{ account.icone }}</span>` (emoji)

**Rationale** : Centralise la logique de résolution dans un seul composant réutilisable. Pas besoin d'injecter `BankService` dans le composant — toutes les infos nécessaires sont déjà sur `AccountResponse` (champs résolus par le backend).

### DD-004: Upload logo custom pour "Autre"

**Décision** : Réutiliser le pattern de compression d'image du `ProductForm` (canvas, maxWidth=512, quality=0.8, JPEG data URI).

**Rationale** : Pattern déjà éprouvé dans le shop module (068). Taille réduite pour les logos (512px max vs 1024px pour les produits) car un logo n'a pas besoin de haute résolution.

### DD-005: Formulaire compte — placement et masquage

**Décision** : Section banque en haut du formulaire (avant le type). Quand `bankCode ≠ OTHER` : masquer les sections icône/couleur. La couleur de prévisualisation du compte utilise `bankBrandColor`.

**Rationale** : La banque est le contexte principal d'un compte. En la plaçant en premier, l'utilisateur fait le choix structurant immédiatement, et le formulaire s'adapte en conséquence.

## Implementation Phases

### Phase A — Fondations (modèle + service)

1. Créer `bank.model.ts` avec `BankResponse` interface
2. Mettre à jour `account.model.ts` : ajouter les 7 champs bank sur `Account`, les 3 sur `AccountRequest`
3. Créer `BankService` (signal-based, lazy loading, cache)

### Phase B — Composants UI

4. Créer `AccountBankIcon` (résolution logo 3 niveaux)
5. Créer `BankSelectComponent` (dropdown groupé, recherche, pin "Autre")
6. Enrichir `AccountForm` (section banque, masquage conditionnel icône/couleur, upload logo custom)

### Phase C — Intégration affichage

7. Mettre à jour la liste des comptes (paramètres) pour utiliser `AccountBankIcon`
8. Mettre à jour les sélecteurs de compte dans les formulaires (transactions, dettes, transfert, abonnements) pour afficher le logo banque

### Phase D — Tests

9. Tests unitaires : BankService, BankSelectComponent, AccountBankIcon, AccountForm enrichi
