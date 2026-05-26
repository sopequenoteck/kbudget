# Spec — KKS-255 : Comptes formulaire Flutter (alignement DESIGN.md v5)

> Date : 2026-05-24
> Issue : KKS-255
> Priorité : High (P2)
> Labels : Feature

---

## Contexte

Le formulaire de compte Flutter (`account_form_screen.dart`, 745L) est fonctionnellement complet — la logique de création, d'édition, de suppression, du logo, de l'auto-fill couleur et de la proposition de taux est en place. L'objectif de ce ticket est un **alignement visuel et structurel** sur le composant Angular `account-form` (`/shared/components/account-form/`) qui fait office de source de vérité DESIGN.md v5.

**Source de vérité Angular** : `app/src/app/shared/components/account-form/account-form.{ts,html,scss}`

**Décisions techniques prises en amont** (non sujettes à clarification) :
- Le formulaire Flutter reste un **écran plein page** (Scaffold + AppBar) — pas de migration en bottom-sheet. Cette différence d'enveloppe est intentionnelle et hors scope.
- Le logo upload Flutter (bottom-sheet caméra/galerie) est une adaptation mobile légitime — pas de regression vers `input[type=file]`.
- La proposition de taux Flutter (AlertDialog + AppModal) est fonctionnellement équivalente à l'overlay inline Angular — hors scope d'alignement.
- `ConfirmDialogCustom` est la norme projet pour les confirmations — le `showDeleteConfirmDialog` utilisé dans ce screen est à remplacer.

---

## User Stories

### US-001 — Réordonner les sections du formulaire (P1)

En tant qu'utilisateur, je veux que les sections du formulaire de compte apparaissent dans le même ordre que sur Angular, afin d'avoir une expérience cohérente entre les plateformes.

**Why this priority** : L'ordre actuel (Preview → Banque → Type → Personnalisation → Détails) contredit la source de vérité Angular (Preview → Type → Banque → Personnalisation → Détails). C'est le seul écart structurel visible dès le premier rendu — il est immédiatement perceptible.

**Independent Test** : Ouvrir le formulaire de création → vérifier que les type-cards apparaissent avant le sélecteur de banque.

**Acceptance Scenarios** :

1. **Given** l'utilisateur ouvre le formulaire de création de compte, **When** l'écran se charge, **Then** il voit dans l'ordre : (1) Preview card, (2) section Type de compte, (3) section Banque, (4) section Personnalisation (si OTHER), (5) section Détails.
2. **Given** l'utilisateur ouvre le formulaire d'édition, **When** l'écran se charge, **Then** le même ordre est respecté, avec les type-cards désactivées.

---

### US-002 — Ajouter les section headers visuels (P1)

En tant qu'utilisateur, je veux que chaque groupe de champs soit clairement identifié par un titre de section, afin de comprendre la structure du formulaire d'un coup d'œil.

**Why this priority** : Angular utilise des `fieldset > legend` avec un style uppercase + secondary color pour structurer visuellement le formulaire. Sans ces headers, les sections se fondent les unes dans les autres. C'est un pattern défini dans DESIGN.md v5.

**Independent Test** : Vérifier que les labels "Type de compte", "Banque", "Personnalisation", "Détails" sont présents et stylistiquement cohérents avec les tokens v5 (uppercase xs semibold text-secondary).

**Acceptance Scenarios** :

1. **Given** l'utilisateur est sur le formulaire de création, **When** il fait défiler, **Then** il voit les labels de section : "Type de compte" (avant les cards), "Banque" (avant le sélecteur), "Personnalisation" (si OTHER, avant emoji/couleur), "Détails" (avant le champ nom).
2. **Given** les section headers sont affichés, **When** le design est inspecté, **Then** les tokens appliqués sont : `fontSize: AppTypography.sizeXs`, `fontWeight: AppTypography.semiBold`, `color: colorScheme.onSurfaceVariant`, `letterSpacing: 0.8` (uppercase implicite via styling, pas de transformation CSS forcée).

---

### US-003 — Ajouter le label de type dans la preview card (P2)

En tant qu'utilisateur, je veux voir le type de compte ("COURANT", "ÉPARGNE", "ESPÈCES") sous le nom dans la preview card, afin de voir en temps réel l'aperçu complet du compte tel qu'il apparaîtra dans la liste.

**Why this priority** : Angular affiche `typeLabels[selectedType()]` sous le nom dans la preview. La preview Flutter actuelle n'affiche que le nom/emoji. Écart UX mesurable mais non bloquant.

**Independent Test** : Ouvrir le formulaire → vérifier que "COURANT" est visible dans la preview. Changer le type → vérifier que la preview se met à jour en temps réel.

**Acceptance Scenarios** :

1. **Given** l'utilisateur est sur le formulaire de création avec le type "Courant" sélectionné, **When** la preview card est rendue, **Then** elle affiche sous le nom (ou placeholder) le label du type en uppercase : "COURANT".
2. **Given** l'utilisateur change le type vers "Épargne", **When** la sélection change, **Then** la preview se met à jour immédiatement avec "ÉPARGNE".
3. **Given** l'utilisateur est en mode édition, **When** la preview est rendue, **Then** le label de type affiché correspond au type du compte édité (non modifiable).

---

### US-004 — Masquer le sélecteur de devise en mode édition (P2)

En tant qu'utilisateur en mode édition, je ne veux pas voir le sélecteur de devise (il est non modifiable), afin que le formulaire soit épuré et n'affiche que les champs actionnables.

**Why this priority** : Angular masque complètement le champ devise (`@if (!isEditMode())`) en édition. Flutter le rend visible mais désactivé (`enabled: !_isEditMode`). UX différente — le champ désactivé encombre l'écran sans apporter de valeur.

**Independent Test** : Ouvrir le formulaire en mode édition → vérifier que le `SelectPicker` devise est absent du DOM/widget tree.

**Acceptance Scenarios** :

1. **Given** l'utilisateur ouvre le formulaire en mode édition (via tap sur un compte existant), **When** l'écran se charge, **Then** le sélecteur de devise n'est pas visible dans le formulaire.
2. **Given** l'utilisateur est en mode création, **When** l'écran se charge, **Then** le sélecteur de devise est visible et interactif.

---

### US-005 — Remplacer `showDeleteConfirmDialog` par `ConfirmDialogCustom` (P2)

En tant que développeur, je veux que la confirmation de suppression de compte utilise `ConfirmDialogCustom.show()` au lieu de `showDeleteConfirmDialog`, afin de respecter la norme de confirmation du projet et garantir la cohérence visuelle.

**Why this priority** : `ConfirmDialogCustom` est le composant standard depuis KKS-252. `showDeleteConfirmDialog` est un utilitaire legacy que tous les formulaires révisés abandonnent. C'est une dette technique légère mais mesurable.

**Independent Test** : En mode édition, taper "Supprimer le compte" → vérifier que le dialog affiché est de type `ConfirmDialogCustom` (avec icône Phosphor + variant danger).

**Acceptance Scenarios** :

1. **Given** l'utilisateur est en mode édition et tape le bouton de suppression, **When** le dialog s'affiche, **Then** c'est `ConfirmDialogCustom.show()` qui est appelé avec `icon: PhosphorIconsRegular.trash`, `variant: ConfirmVariant.danger`, titre et message appropriés.
2. **Given** l'utilisateur annule dans le dialog, **When** il tape "Annuler" ou ferme le dialog, **Then** le compte n'est pas supprimé et l'écran reste ouvert.
3. **Given** l'utilisateur confirme dans le dialog, **When** il tape le bouton de confirmation danger, **Then** `accountNotifier.delete()` est appelé et l'écran se ferme.

---

### US-006 — Aligner le styling du solde actuel en mode édition (P2)

En tant qu'utilisateur en mode édition, je veux voir le solde actuel dans un bloc visuellement distinct (background + layout horizontal), aligné sur le pattern Angular `.account-form__balance-info`, afin que l'information soit clairement présentée.

**Why this priority** : `_ReadOnlyField` actuel affiche label + valeur en colonne sans background distinctif. Angular utilise un bloc `display: flex; justify-content: space-between; background: var(--hover-bg); border-radius: var(--radius-lg)` — pattern plus lisible.

**Independent Test** : En mode édition, vérifier que le solde actuel est dans un `Container` avec `surfaceContainerHighest` en background, layout Row (label à gauche, valeur à droite).

**Acceptance Scenarios** :

1. **Given** l'utilisateur est en mode édition, **When** il voit la section solde, **Then** le solde actuel est affiché dans un bloc Row avec label à gauche et valeur formatée à droite, sur un fond `colorScheme.surfaceContainerHighest` avec `borderRadius: AppRadius.lg`.
2. **Given** le solde est affiché, **When** le design est inspecté, **Then** la valeur est formatée avec `AmountFormatter.format()` (devise incluse) — identique à ce qui est déjà fait.

---

## Requirements fonctionnels

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-001 | Réordonner les sections : Preview → Type → Banque → Personnalisation → Détails (si OTHER) | P1 | US-001 |
| FR-002 | Section header "Type de compte" affiché avant les type-cards | P1 | US-002 |
| FR-003 | Section header "Banque" affiché avant `BankSelectPicker` | P1 | US-002 |
| FR-004 | Section header "Personnalisation" affiché avant emoji/couleur/logo (si `_selectedBankCode == 'OTHER'`) | P1 | US-002 |
| FR-005 | Section header "Détails" affiché avant le champ nom | P1 | US-002 |
| FR-006 | `AccountPreviewCard` étend son API avec un paramètre `accountType` (ou `typeLabel`) | P2 | US-003 |
| FR-007 | Le label de type est affiché dans la preview via `l10n.accountTypeXxx.toUpperCase()` — uppercase xs semibold `onSurfaceVariant` | P2 | US-003 |
| FR-008 | Le label de type dans la preview se met à jour en temps réel lors du changement de type | P2 | US-003 |
| FR-009 | `SelectPicker` devise masqué (non rendu) en mode édition — `if (!_isEditMode)` au lieu de `enabled: false` | P2 | US-004 |
| FR-010 | Remplacement de `showDeleteConfirmDialog` par `ConfirmDialogCustom.show()` dans `_onDelete()` — retirer uniquement l'import de `confirm_delete_dialog.dart` dans `account_form_screen.dart` (fichier conservé — 4 callsites actifs ailleurs) | P2 | US-005 |
| FR-011 | `_ReadOnlyField` remplacé par un bloc Row (label ↔ valeur) sur fond `surfaceContainerHighest` + `borderRadius: AppRadius.lg` | P2 | US-006 |
| FR-012 | Le nouveau bloc solde actuel utilise `AmountFormatter.format()` pour la valeur (déjà fait, à conserver) | P2 | US-006 |

---

## Requirements non-fonctionnels

| ID | Description | Catégorie |
|----|-------------|-----------|
| NFR-001 | Aucune régression sur les fonctionnalités existantes (création, édition, suppression, logo, auto-fill couleur, taux) | Qualité |
| NFR-002 | `flutter analyze` → 0 erreur après toutes les modifications | Qualité |
| NFR-003 | Tokens v5 exclusivement : `AppTypography`, `AppSpacing`, `AppRadius`, `AppColors` — pas de valeurs hardcodées | Design |
| NFR-004 | `AccountPreviewCard` reste `StatelessWidget` — pas d'introduction de state | Architecture |
| NFR-005 | Section headers réutilisent le pattern des autres écrans KKS-252 (label uppercase xs semibold onSurfaceVariant) | Design |
| NFR-006 | ≥ 5 widget tests PASS après modification | Tests |

---

## Contraintes et dépendances

- **Contraintes techniques** :
  - `AccountPreviewCard` est un widget partagé — toute modification de son API doit être rétrocompatible ou tous les callsites mis à jour
  - `_ReadOnlyField` est une classe privée dans `account_form_screen.dart` — supprimable sans risque externe
  - `showDeleteConfirmDialog` est dans `lib/src/utils/confirm_delete_dialog.dart` — vérifier s'il a d'autres callsites avant suppression de l'import
- **Dépendances internes** :
  - `ConfirmDialogCustom` dans `lib/src/common_widgets/confirm_dialog_custom.dart` (disponible depuis KKS-252)
  - `AccountPreviewCard` dans `lib/src/features/accounts/presentation/widgets/account_preview_card.dart`
  - `AppTypography`, `AppSpacing`, `AppRadius` dans `lib/src/constants/`

---

## Questions ouvertes

| # | Question | Statut | Réponse |
|---|----------|--------|---------|
| Q1 | `AccountPreviewCard` est-il utilisé ailleurs dans le codebase ? Si oui, l'ajout de `accountType` doit être optionnel (`AccountType? accountType`) pour ne pas casser les callsites. | Résolu | 1 seul callsite (`account_form_screen.dart:407`). Paramètre `AccountType? accountType` optionnel par convention de compatibilité ascendante (CL-001). |
| Q2 | Le label de type dans la preview doit-il être localisé (`l10n.accountTypeCourant`) ou en dur ("COURANT") ? Angular utilise `typeLabels[selectedType()]` → "Courant" (non uppercase dans le JS, uppercase via CSS). | Résolu | `l10n.accountTypeXxx.toUpperCase()` — clés existantes + transformation Flutter pour simuler `text-transform: uppercase` Angular (CL-003). |
| Q3 | `showDeleteConfirmDialog` est-il encore utilisé dans d'autres écrans ? Si oui, le fichier `confirm_delete_dialog.dart` reste mais l'import est retiré de `account_form_screen.dart` uniquement. | Résolu | 4 callsites actifs (`debt_form`, `subscription_form`, `transaction_form`, `budget_form`). Fichier conservé — seul l'import dans `account_form_screen.dart` est retiré (CL-002). |

---

## Success Criteria

| ID | Description | Méthode de vérification | User Story |
|----|-------------|------------------------|------------|
| SC-001 | Les type-cards apparaissent avant le sélecteur de banque dans le formulaire de création | Manuel — scroll depuis le haut | US-001 |
| SC-002 | Les 4 section headers sont visibles ("Type de compte", "Banque", "Personnalisation", "Détails") | Manuel — inspection visuelle | US-002 |
| SC-003 | La preview card affiche le label de type ("COURANT") sous le nom | Manuel — vérification visuelle | US-003 |
| SC-004 | La preview se met à jour en temps réel lors du changement de type | Manuel — tap sur un type card | US-003 |
| SC-005 | Le sélecteur de devise est absent en mode édition | Manuel — ouvrir édition d'un compte | US-004 |
| SC-006 | Le dialog de suppression utilise `ConfirmDialogCustom` (icône trash, variant danger) | Manuel + widget test | US-005 |
| SC-007 | Le solde actuel (édition) s'affiche dans un bloc Row avec fond `surfaceContainerHighest` | Manuel — inspection visuelle | US-006 |
| SC-008 | `flutter analyze` → 0 erreur | Auto — `flutter analyze` | NFR-002 |
| SC-009 | `flutter test test/src/features/accounts/` → ≥ 5 tests PASS, 0 FAIL | Auto — `flutter test` | NFR-006 |

---

## Key Entities

| Entité | Description | Relations principales |
|--------|-------------|----------------------|
| `Account` | Modèle de compte : `nom`, `type`, `icone`, `couleur`, `currency`, `solde`, `actif`, `bankCode`, `bankCustomName`, `bankCustomLogo`, `isDefault` | Central — lu/écrit par `AccountFormScreen` |
| `AccountType` | Enum : `courant`, `epargne`, `especes` | Utilisé par `AccountTypeSelector`, `AccountPreviewCard` (après FR-006) |
| `AccountPreviewCard` | Widget de preview live avec border-left couleur | Partagé — callsites à vérifier avant modification |
| `ConfirmDialogCustom` | Dialog de confirmation standard projet | Remplace `showDeleteConfirmDialog` (FR-010) |

---

## Assumptions

| # | Hypothèse | Impact si fausse | Validation prévue |
|---|-----------|-----------------|-------------------|
| A-001 | `AccountPreviewCard` n'est utilisé que dans `account_form_screen.dart` — l'ajout de `AccountType? accountType` est sans risque callsite | Si d'autres callsites existent → paramètre optionnel obligatoire | **Confirmé** — 1 seul callsite (`account_form_screen.dart:407`). Paramètre optionnel par convention (CL-001). |
| A-002 | `showDeleteConfirmDialog` a d'autres callsites dans le codebase — l'import est retiré de `account_form_screen.dart` uniquement, pas de suppression du fichier utilitaire | Si aucun autre callsite → le fichier devient orphelin | **Confirmé** — 4 callsites actifs (`debt_form`, `subscription_form`, `transaction_form`, `budget_form`). Fichier conservé (CL-002). |
| A-003 | Les section headers sont des widgets `Text` inline (pas un widget commun `SectionHeader`) — pattern cohérent avec `SectionHeaderSticky` pour les listes, mais pour les formulaires un `Text` inline est suffisant | Si un `_SectionHeader` widget commun existe → l'utiliser | **Confirmé** — aucun `SectionHeader` formulaire dans `common_widgets/`. Pattern `Text` inline retenu (CL-004). |
| A-004 | L'ordre des champs dans la section "Détails" reste inchangé : nom → (devise si création) → solde | Si la spec évolue → les tests existants peuvent casser | Review des tests accounts existants |
