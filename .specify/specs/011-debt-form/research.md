# Research: Formulaire Debt (modal)

**Feature**: 011-debt-form | **Date**: 2026-02-11

## R1 — Toggle segmente pour le sens de la dette

**Decision**: Toggle segmente custom (2 boutons cote a cote) avec labels "Emprunt" / "Pret", mappant respectivement les valeurs enum `DebtType.JE_DOIS` et `DebtType.ON_ME_DOIT`.

**Rationale**: Pattern identique au toggle DEPENSE/RECETTE du `TransactionForm` et MENSUEL/ANNUEL du `SubscriptionForm`. Les labels "Emprunt"/"Pret" sont plus clairs que "Je dois"/"On me doit" (choix valide par clarification spec).

**Alternatives considered**:
- Labels "Je dois" / "On me doit" : plus explicites mais plus longs, moins adaptes au mobile
- Select/dropdown : moins ergonomique pour 2 options, rompt le pattern existant

## R2 — Gestion du mode creation/edition

**Decision**: Input `debt: Debt | null` via `input<Debt | null>(null)`. `null` = creation, objet = edition. Un `effect()` pre-remplit le formulaire en mode edition.

**Rationale**: Pattern identique a `TransactionForm.transaction` et `SubscriptionForm.subscription`. Coherence totale du codebase.

**Alternatives considered**:
- Deux composants separes (create/edit) : duplication, non YAGNI
- Service de state global : over-engineering pour un formulaire modal

## R3 — Champ date natif HTML5

**Decision**: `<input type="date">` natif avec format `YYYY-MM-DD`, valeur par defaut `new Date().toISOString().split('T')[0]`.

**Rationale**: Pattern identique aux autres formulaires. Pas de librairie de date picker externe (YAGNI). Le format ISO est compatible avec le backend Spring Boot.

**Alternatives considered**:
- Date picker tiers (ng-bootstrap, material) : dependance inutile, non self-hosted ready
- Input texte avec masque : moins ergonomique sur mobile

## R4 — Case a cocher "Rembourse"

**Decision**: Checkbox native avec `formControlName="rembourse"`, valeur par defaut `false`. Pas de wrapping dans `FormField` car les checkboxes ont un layout different (label inline).

**Rationale**: Pattern standard HTML. La checkbox est un champ simple sans validation complexe.

**Alternatives considered**:
- Toggle switch : plus esthetique mais non present dans le design system actuel
- Select oui/non : sur-ingenierie pour un boolean

## R5 — Champ categorie (optionnel)

**Decision**: Le modele `Debt` possede un champ `category: Category | null` et `DebtRequest` a un `categoryId?: string`. Le formulaire DOIT inclure un select de categories optionnel, charge via `toSignal(categoryService.getAll())`, avec une option "Aucune categorie" par defaut.

**Rationale**: Le modele de donnees supporte les categories sur les dettes (contrairement a l'hypothese initiale de la spec). Pour coherence avec Transaction et Subscription forms, ce champ est inclus.

**Alternatives considered**:
- Omettre le champ categorie : incoherent avec le modele de donnees existant
- Champ texte libre : non conforme au pattern existant

## R6 — Validation frontend

**Decision**: Validators Angular (`Validators.required`, `Validators.min(0.01)`, `Validators.maxLength(255)`) sur les champs requis. Les messages d'erreur s'affichent via `FormField.showError` apres interaction (touched) ou tentative de soumission.

**Rationale**: Pattern identique a TransactionForm. Le backend reste la source de verite pour la validation (Bean Validation).

**Alternatives considered**:
- Validation custom async (verifier le montant cote serveur) : over-engineering, latence inutile
