# Research — KKS-255 : Comptes formulaire Flutter (alignement DESIGN.md v5)

> Date : 2026-05-26
> Issue : KKS-255
> Spec : [spec.md](./spec.md)

---

## Synthèse

**Aucune inconnue technique bloquante.** KKS-255 est un ticket d'alignement visuel/structurel pur — toutes les briques (widgets, tokens, patterns, APIs) sont disponibles dans le codebase existant. Les 4 points documentés ci-dessous confirment les patterns à appliquer pour chaque FR non trivial.

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Widget API | Extension `AccountPreviewCard` : comment afficher le label de type (structure du widget, layout) | Moyenne |
| RES-002 | UI | `_SectionHeader` privé : tokens exacts et pattern de référence dans le codebase | Basse |
| RES-003 | API migration | `ConfirmDialogCustom.show()` : signature exacte vs `showDeleteConfirmDialog` | Basse |
| RES-004 | UI | Remplacement `_ReadOnlyField` : layout Row + fond `surfaceContainerHighest` — pattern de référence | Basse |

---

## Décisions techniques

### RES-001 — Extension `AccountPreviewCard` : layout avec label de type

- **Contexte** : FR-006/FR-007 ajoutent `AccountType? accountType` à `AccountPreviewCard`. Le widget actuel (`account_preview_card.dart`) affiche un `Row` avec [logo/emoji | `Expanded(Text name)`]. Il faut insérer le label de type sans casser le layout existant.
- **Analyse du codebase** :
  - Pattern type label : `account_list_tile.dart:38-43` — switch exhaustif sur `AccountType` → `l10n.accountTypeCourant`, `l10n.accountTypeEpargne`, `l10n.accountTypeEspeces`.
  - Contrainte NFR-004 : `AccountPreviewCard` reste `StatelessWidget` — le label est reçu via `AccountType? accountType`, transformé localement en string via le même switch.
  - Angular affiche le type sous le nom dans la preview card (layout colonne nom/type). Flutter doit reproduire ce layout.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `Expanded(Column([Text name, Text typeLabel]))` | Layout identique Angular, cohérent | Minime réorganisation du `Row` parent | ★★★★★ |
| B — `Text typeLabel` après le `Row` (en dessous de la carte) | Zéro modification du `Row` interne | Non conforme Angular (type sous le nom, pas sous la carte) | ★★ |
| C — Paramètre `typeLabel` (String?) au lieu de `AccountType?` | Découple le widget de l'enum | Moins typé, oblige le parent à faire la conversion | ★★★ |

- **Décision** : Option A — `Expanded` contient un `Column` avec `Text name` (md/medium) puis `if (accountType != null) Text typeLabel` (xs/semiBold/onSurfaceVariant/letterSpacing:0.8). Paramètre `AccountType? accountType` (enum, conforme constitution III YAGNI — pas de duplication de la logique de label).
- **Rationale** : Pattern le plus lisible, le plus typé, le plus proche de la source de vérité Angular. Le switch sur `AccountType` est déjà présent dans `account_list_tile.dart` — réplication minimale.
- **Impact sur le plan** : modifier uniquement `account_preview_card.dart` (ajout paramètre + Column interne) + callsite `account_form_screen.dart:407` (passer `_selectedType`).

---

### RES-002 — `_SectionHeader` : tokens exacts

- **Contexte** : FR-002 à FR-005 ajoutent 4 section headers dans `account_form_screen.dart`. CL-004 décide un widget privé `_SectionHeader` avec `Text` inline — la question est les tokens exacts et le pattern de référence.
- **Analyse du codebase** :
  - `budget_detail_screen.dart:363-372` : labels uppercase xs, `fontWeight: AppTypography.medium`, `letterSpacing: 0.8`, `color: colorScheme.onSurfaceVariant`. Ces labels sont des métadonnées de hero (DÉPENSÉ), pas des section headers de formulaire.
  - `budget_detail_screen.dart:675-684` : sticky header labels — `sizeXs`, `fontWeight: AppTypography.semiBold`, `letterSpacing: 0.5`, `onSurfaceVariant`.
  - La spec (US-002 scenario 2) et CL-004 définissent explicitement : `sizeXs` + `semiBold` + `onSurfaceVariant` + `letterSpacing: 0.8`.
  - Les heroes utilisent `medium` (poids inférieur), les section headers de formulaire utilisent `semiBold` (plus structurant) — distinction intentionnelle.
- **Décision** : Widget privé `_SectionHeader` dans `account_form_screen.dart` :
  ```dart
  class _SectionHeader extends StatelessWidget {
    const _SectionHeader(this.label);
    final String label;

    @override
    Widget build(BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;
      return Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: AppTypography.sizeXs,
          fontWeight: AppTypography.semiBold,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      );
    }
  }
  ```
- **Rationale** : Widget privé au fichier (pas d'extraction dans `common_widgets/`) — scope limité à ce formulaire, conforme à la décision CL-004. Tokens identiques à `budget_detail_screen` sticky header sauf letterSpacing (0.8 vs 0.5) — justifié par le contexte formulaire vs liste.

---

### RES-003 — Migration `showDeleteConfirmDialog` → `ConfirmDialogCustom.show()`

- **Contexte** : FR-010 remplace `showDeleteConfirmDialog` par `ConfirmDialogCustom.show()` dans `_onDelete()`. Les deux retournent `Future<bool?>` — la logique après l'appel (`if (confirmed != true || !mounted) return;`) est inchangée.
- **Analyse du codebase** :
  - Actuel (`account_form_screen.dart:344-348`) : `showDeleteConfirmDialog(context: context, title: l10n.accountDeleteConfirmTitle, message: l10n.accountDeleteConfirmMessage)`
  - `ConfirmDialogCustom.show()` signature : `{required BuildContext context, IconData? icon, required String title, String? message, String confirmLabel, String cancelLabel, ConfirmVariant variant}`
  - Pattern existant (KKS-252) : `ConfirmDialogCustom.show(context: context, title: ..., message: ..., confirmLabel: l10n.delete, variant: ConfirmVariant.danger)`
- **Décision** :
  ```dart
  final confirmed = await ConfirmDialogCustom.show(
    context: context,
    title: l10n.accountDeleteConfirmTitle,
    message: l10n.accountDeleteConfirmMessage,
    confirmLabel: l10n.delete,
    variant: ConfirmVariant.danger,
  );
  ```
- **Rationale** : Migration 1:1 — seuls les paramètres changent. Import `confirm_delete_dialog.dart` retiré (conformément à CL-002 : fichier conservé, uniquement l'import retiré dans ce screen). Import `confirm_dialog_custom.dart` ajouté (déjà disponible dans `common_widgets/`).

---

### RES-004 — Remplacement `_ReadOnlyField` : layout Row `surfaceContainerHighest`

- **Contexte** : FR-011 remplace `_ReadOnlyField` (Column label/valeur sans fond) par un bloc Row avec fond `surfaceContainerHighest` + `borderRadius: AppRadius.lg`, conforme au pattern Angular `.account-form__balance-info`.
- **Analyse du codebase** :
  - `budget_detail_screen.dart:715-717` : Container `surfaceContainerHighest` + `borderRadius: AppRadius.lg` pour les blocs méta. Pattern identique à la cible.
  - Pattern Row `label ↔ valeur` utilisé dans `budget_detail_screen.dart:790-800` (montant/reste en Row `mainAxisAlignment: spaceBetween`).
- **Décision** :
  ```dart
  Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.space4,
      vertical: AppSpacing.space3,
    ),
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l10n.accountFormCurrentBalance,
          style: TextStyle(fontSize: AppTypography.sizeSm, color: colorScheme.onSurfaceVariant)),
        Text(AmountFormatter.format(widget.account!.solde, currency: widget.account!.currency),
          style: TextStyle(fontSize: AppTypography.sizeSm, fontWeight: AppTypography.semiBold, color: colorScheme.onSurface)),
      ],
    ),
  )
  ```
- **Rationale** : Pattern `surfaceContainerHighest` + Row spaceBetween est établi dans le codebase. `_ReadOnlyField` supprimé (classe privée au fichier, 1 seul callsite à `account_form_screen.dart:557`).
- **Impact sur le plan** : supprimer `_ReadOnlyField` (lignes 713-743) + remplacer son callsite par le Container inline.

---

## Nouvelles dépendances

Aucune — `ConfirmDialogCustom`, `AccountPreviewCard`, `AppTypography`, `AppSpacing`, `AppRadius`, `AmountFormatter`, `AppLocalizations` sont tous déjà importés ou disponibles dans le projet.

---

## Constitution Check

| Principe | Vérification | Résultat |
|----------|-------------|---------|
| I — API-First / Local-First | Aucun nouvel endpoint — modifications UI pures | ✅ |
| II — Sécurité par défaut | Aucune donnée sensible exposée | ✅ |
| III — Simplicité & YAGNI | `_ReadOnlyField` supprimé, pas de nouvelle abstraction | ✅ |
| IV — Mobile-First UX | Alignement sur source de vérité Angular = amélioration UX | ✅ |
| V — Testabilité | `AccountPreviewCard` stateless → testable | ✅ |
| VI — Observabilité | Aucune modification des logs | ✅ |
| VII — Two Distribution Trajectories | Aucun impact infrastructure | ✅ |

Aucune dérogation requise.
