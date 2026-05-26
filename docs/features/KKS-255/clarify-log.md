# Clarify Log — KKS-255 : Comptes formulaire Flutter (alignement DESIGN.md v5)

> Date : 2026-05-24
> Issue : KKS-255
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md Q1 / A-001 | `AccountPreviewCard` — nombre de callsites dans le codebase (optionnalité du paramètre `accountType`) | Contraintes | H | H | CRITIQUE | `AccountType? accountType` optionnel — 1 seul callsite confirmé | Auto |
| CL-002 | spec.md Q3 / A-002 | `showDeleteConfirmDialog` — autres callsites (impacte la décision de supprimer ou non le fichier utilitaire) | Scope fonctionnel | H | H | CRITIQUE | 4 callsites actifs — fichier conservé, import seul retiré de `account_form_screen.dart` | Auto |
| CL-003 | spec.md Q2 | Label de type dans la preview : localisé (`l10n.accountTypeXxx`) ou hardcodé ("COURANT") — Angular uppercase via CSS | UX/Interaction | M | M | MOYEN | `l10n.accountTypeXxx.toUpperCase()` — localisé + uppercase Flutter | Auto |
| CL-004 | spec.md A-003 | Section headers : widget commun ou `Text` inline — pattern exact à utiliser dans le formulaire | Scope fonctionnel | B | M | BAS | `Text` inline, letterSpacing: 0.8 — pattern identique à `budget_detail_screen.dart:370` | Auto |
| CL-005 | spec.md US-002 | `letterSpacing` exact pour les section headers (spec indique 0.8, à confirmer par le codebase) | Terminologie | B | B | BAS | `letterSpacing: 0.8` confirmé — `budget_detail_screen.dart:370` utilise cette valeur pour labels uppercase xs | Auto |

---

## Résolutions détaillées

### CL-001 — Callsites `AccountPreviewCard` (Q1 / A-001)

- **Catégorie** : Contraintes
- **Score** : CRITIQUE
- **Contexte** : La spec (FR-006) prévoit d'étendre `AccountPreviewCard` avec un paramètre `accountType`. Si le widget est utilisé en dehors de `account_form_screen.dart`, le paramètre doit être optionnel pour ne pas casser les callsites existants.
- **Analyse** : `grep -rn "AccountPreviewCard" flutter/lib/` → 2 occurrences : la définition (`account_preview_card.dart:9`) et 1 seul callsite (`account_form_screen.dart:407`). Aucun autre usage.
- **Décision** : Paramètre `AccountType? accountType` optionnel (valeur par défaut `null` = pas de label type affiché). L'optionnalité est préférable même avec 1 seul callsite, pour respecter la convention de compatibilité ascendante des widgets partagés.
- **Impact sur spec.md** : Q1 fermée ("Résolu"), A-001 validation confirmée.

---

### CL-002 — Callsites `showDeleteConfirmDialog` (Q3 / A-002)

- **Catégorie** : Scope fonctionnel
- **Score** : CRITIQUE
- **Contexte** : FR-010 remplace `showDeleteConfirmDialog` par `ConfirmDialogCustom.show()` dans `account_form_screen.dart`. La question est de savoir si le fichier `confirm_delete_dialog.dart` peut être supprimé ou doit être conservé.
- **Analyse** : `grep -rn "showDeleteConfirmDialog" flutter/lib/` → 5 occurrences totales : `account_form_screen.dart:344` (à migrer) + 4 callsites actifs dans d'autres formulaires : `debt_form.dart:184`, `subscription_form.dart:180`, `transaction_form.dart:208`, `budget_form.dart:140`. Le fichier utilitaire est donc encore largement utilisé.
- **Décision** : `confirm_delete_dialog.dart` est **conservé** — seul l'import est retiré de `account_form_screen.dart`. Les autres formulaires (`debt_form`, `subscription_form`, `transaction_form`, `budget_form`) conservent leur usage actuel — hors scope KKS-255.
- **Impact sur spec.md** : Q3 fermée ("Résolu"), A-002 validation confirmée. FR-010 précisé : "retirer l'import de `confirm_delete_dialog.dart` dans `account_form_screen.dart` uniquement".

---

### CL-003 — Label de type dans la preview : localisation vs uppercase (Q2)

- **Catégorie** : UX/Interaction
- **Score** : MOYEN
- **Contexte** : Angular affiche `typeLabels[selectedType()]` → "Courant" (chaîne en title case dans le TS), avec `text-transform: uppercase` dans le CSS pour le rendu visuel. Flutter n'a pas de CSS — il faut décider entre hardcoder "COURANT" ou utiliser `l10n.accountTypeCourant.toUpperCase()`.
- **Analyse** : Les clés de localisation existent et sont déjà utilisées dans `AccountTypeSelector` (`l10n.accountTypeCourant` → "Courant", `l10n.accountTypeEpargne` → "Épargne", `l10n.accountTypeEspeces` → "Espèces"). Appeler `.toUpperCase()` sur ces chaînes reproduit fidèlement le comportement CSS `text-transform: uppercase` d'Angular tout en restant maintenable et potentiellement localisable.
- **Décision** : `l10n.accountTypeLabel(type).toUpperCase()` — utiliser les clés l10n existantes + `.toUpperCase()`. Plus précisément : `labels[type]!.toUpperCase()` en utilisant la même map que `AccountTypeSelector`.
- **Impact sur spec.md** : Q2 fermée ("Résolu"). FR-007 mis à jour : "label de type = `l10n.accountTypeXxx.toUpperCase()`".

---

### CL-004 — Section headers : widget commun ou `Text` inline

- **Catégorie** : Scope fonctionnel
- **Score** : BAS
- **Contexte** : A-003 posait la question de l'existence d'un widget commun `_SectionHeader` pour les formulaires. Si oui, l'utiliser — sinon, `Text` inline.
- **Analyse** : `ls flutter/lib/src/common_widgets/` → pas de widget `SectionHeader` pour les formulaires. `SectionHeaderSticky` existe mais est réservé aux listes (basé sur `SliverPersistentHeaderDelegate`). Les autres formulaires (ex: `BottomSheet4RowsWidget`) n'utilisent pas de section headers nommés. Le pattern `Text` inline avec les bons tokens est la bonne approche.
- **Décision** : Widget privé `_SectionHeader` local à `account_form_screen.dart` — `Text` avec `fontSize: AppTypography.sizeXs`, `fontWeight: AppTypography.semiBold`, `color: colorScheme.onSurfaceVariant`, `letterSpacing: 0.8`. Classe privée au fichier (pas d'extraction dans `common_widgets/`).
- **Impact sur spec.md** : A-003 validation confirmée. NFR-005 précisé.

---

### CL-005 — `letterSpacing` exact des section headers

- **Catégorie** : Terminologie
- **Score** : BAS
- **Contexte** : La spec US-002 mentionne `letterSpacing: 0.8` pour les section headers — valeur à confirmer par le codebase existant pour garantir la cohérence.
- **Analyse** : `budget_detail_screen.dart:370` → `letterSpacing: 0.8` pour le label "DÉPENSÉ" (uppercase xs semibold). `budget_list_screen.dart:637` → `AppTypography.labelLetterSpacingForSize12`. `budget_detail_screen.dart:681` → `letterSpacing: 0.5` pour le sticky header. Le pattern uppercase xs label utilise `0.8` — cohérent avec la spec.
- **Décision** : `letterSpacing: 0.8` confirmé pour les section headers du formulaire.
- **Impact sur spec.md** : Aucun — valeur déjà correcte dans la spec.

---

## Points différés

Aucun — les 5 points identifiés ont tous été résolus automatiquement dans cette session.

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 5 |
| Catégories couvertes | 4/11 (Contraintes, Scope fonctionnel, UX/Interaction, Terminologie) |
| Résolus automatiquement | 5 |
| Résolus interactivement | 0 |
| Différés | 0 |
| Modifications spec.md | 5 (Q1, Q2, Q3 fermées ; FR-007, FR-010 précisés) |
