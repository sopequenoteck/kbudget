# Implementation Plan: Fix checkboxes non fonctionnelles

**Branch**: `020-fix-checkbox-forms` | **Date**: 2026-02-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/020-fix-checkbox-forms/spec.md`

## Summary

Les checkboxes des formulaires SubscriptionForm ("actif") et DebtForm ("remboursé") sont non fonctionnelles. La cause racine est identifiée : les styles globaux `_forms.scss` ciblent `input` sans exclure `input[type="checkbox"]`, appliquant `appearance: none`, `width: 100%` et des styles de champ texte qui rendent la checkbox invisible et inutilisable.

Le correctif consiste à exclure les checkboxes du sélecteur global `input` dans `_forms.scss`, puis nettoyer les styles dupliqués dans les composants.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0, SCSS
**Primary Dependencies**: `@angular/forms` (ReactiveFormsModule)
**Storage**: N/A (pas de changement de persistance)
**Testing**: Vitest 4.x (tests unitaires frontend existants)
**Target Platform**: PWA mobile-first (navigateurs modernes)
**Project Type**: Web application (frontend uniquement pour ce fix)
**Performance Goals**: N/A (bug fix CSS, pas d'impact performance)
**Constraints**: Pas de régression visuelle sur les autres champs input/textarea/select
**Scale/Scope**: 2 fichiers SCSS impactés, 2 formulaires vérifiés

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Status | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Pas de changement backend |
| II. Sécurité par défaut | N/A | Pas de changement sécurité |
| III. Simplicité & YAGNI | PASS | Correction minimale, pas d'abstraction ajoutée |
| IV. Mobile-First UX | PASS | Restaure les checkboxes fonctionnelles sur mobile |
| V. Testabilité | PASS | Vérifiable manuellement (clic checkbox → état soumis) |
| VI. Observabilité | N/A | Pas de changement logging |
| VII. Self-Hosted Ready | N/A | Pas de dépendance ajoutée |

Aucune violation. Gate PASS.

## Project Structure

### Documentation (this feature)

```text
specs/020-fix-checkbox-forms/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/
├── styles/
│   └── _forms.scss                          # FIX: exclure checkbox du sélecteur input
└── app/features/
    ├── subscriptions/components/
    │   └── subscription-form/
    │       └── subscription-form.scss       # CLEANUP: supprimer styles checkbox dupliqués
    └── debts/components/
        └── debt-form/
            └── debt-form.scss               # CLEANUP: supprimer styles checkbox dupliqués
```

**Structure Decision**: Modification de fichiers existants uniquement. Aucun fichier créé.

## Phase 0: Research

### Résolution

Aucun NEEDS CLARIFICATION dans le Technical Context. La cause racine est confirmée par analyse directe du code source.

**Décision** : Modifier le sélecteur `input` dans `_forms.scss` pour exclure `input[type="checkbox"]` et `input[type="radio"]` (prévention future).

**Rationale** : Le sélecteur CSS `:not()` est supporté par tous les navigateurs cibles (>99% support). C'est la correction la plus simple et la plus maintenable — un seul point de modification qui protège aussi les futurs `input[type="radio"]`.

**Alternatives considérées** :
- Ajouter des overrides dans chaque composant → Rejeté (duplication, fragile, ne protège pas les futurs formulaires)
- Créer une classe `.text-input` et la cibler à la place de `input` → Rejeté (nécessite de modifier tous les templates existants, sur-ingénierie)

## Phase 1: Design

### Data Model

N/A — Pas de changement de modèle de données. Les champs `actif` (Subscription) et `rembourse` (Debt) sont des booléens existants qui fonctionnent correctement côté logique.

### Contracts

N/A — Pas de changement d'API. Les DTOs et endpoints existants transmettent déjà correctement les valeurs booléennes.

### Approach détaillé

#### Étape 1 : Corriger `_forms.scss` (global)

Modifier le sélecteur `input, textarea, select` (ligne 5-7) pour exclure les checkboxes et radios :

```scss
input:not([type='checkbox']):not([type='radio']),
textarea,
select {
  // ... styles existants inchangés
}
```

Cela restaure le rendu natif des checkboxes (`appearance` par défaut, taille intrinsèque).

#### Étape 2 : Ajouter un style global checkbox dans `_forms.scss`

Ajouter un bloc dédié pour les checkboxes afin de centraliser le style (actuellement dupliqué dans chaque composant) :

```scss
input[type='checkbox'],
input[type='radio'] {
  width: auto;
  accent-color: var(--color-primary);
  cursor: pointer;
}
```

#### Étape 3 : Nettoyer les styles dupliqués dans les composants

Supprimer les blocs `input[type='checkbox']` dans :
- `subscription-form.scss` (les styles sont maintenant globaux)
- `debt-form.scss` (idem)

Conserver les classes `.checkbox-field` dans les composants (layout flex spécifique au composant).

### Quickstart

```bash
# 1. Vérifier le build frontend
cd app && ng build

# 2. Lancer le dev server
cd app && ng serve

# 3. Ouvrir http://localhost:4200
# 4. Naviguer vers Abonnements → créer un abonnement → vérifier la checkbox "actif"
# 5. Naviguer vers Dettes → créer une dette → vérifier la checkbox "remboursé"
# 6. Vérifier que les champs texte/select n'ont pas de régression visuelle
```

## Complexity Tracking

Aucune violation de constitution — tableau non requis.
