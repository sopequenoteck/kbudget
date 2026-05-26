# Plan — KKS-255 : Comptes formulaire Flutter (alignement DESIGN.md v5)

**Branche** : `sopequenotech/kks-255-kks-2428-comptes-formulaire-flutter-alignement-designmd-v5`
**Date** : 2026-05-26
**Spec** : [spec.md](./spec.md) | **Research** : [research.md](./research.md)

---

## Résumé de l'approche

Ticket d'alignement visuel/structurel pur — aucun changement de logique métier ni de couche data. Deux fichiers Flutter modifiés :

1. **`account_preview_card.dart`** — extension API avec `AccountType? accountType` + layout Column pour afficher le label de type sous le nom (RES-001).
2. **`account_form_screen.dart`** — réordonnancement des sections, ajout de 4 `_SectionHeader`, masquage du `SelectPicker` devise en édition, migration `ConfirmDialogCustom`, remplacement `_ReadOnlyField`.

Un fichier de test existant étendu avec ≥ 5 nouveaux tests couvrant les nouveaux comportements.

---

## Constitution Check

| Principe | Vérification | Résultat |
|----------|-------------|---------|
| I — API-First / Local-First | Aucun endpoint, aucune couche data impactée — modifications UI pures | ✅ PASS |
| II — Sécurité par défaut | Aucune donnée sensible, pas de route non protégée | ✅ PASS |
| III — Simplicité & YAGNI | Solution minimale : 2 fichiers modifiés, aucune abstraction nouvelle partagée. `_ReadOnlyField` supprimé (1 callsite). `_SectionHeader` privé au fichier | ✅ PASS |
| IV — Mobile-First UX | Alignement source de vérité Angular = cohérence cross-platform | ✅ PASS |
| V — Testabilité | `AccountPreviewCard` reste `StatelessWidget` testable. Tests existants conservés + ≥ 5 nouveaux | ✅ PASS |
| VI — Observabilité | Aucun changement log | ✅ PASS |
| VII — Two Distribution Trajectories | Modification UI locale uniquement | ✅ PASS |

**Aucune dérogation requise.**

---

## Contexte technique

- **Stack** : Flutter/Dart, Riverpod, go_router, `AppTypography` / `AppSpacing` / `AppRadius` / `AppColors` (tokens v5)
- **Dépendances impactées** : `ConfirmDialogCustom` (déjà disponible), `AccountPreviewCard` (widget partagé — 1 seul callsite), `AppLocalizations` (clés `accountTypeCourant/Epargne/Especes` disponibles)
- **Dépendances nouvelles** : aucune
- **Tests** : `flutter_test` + `mockito` (pattern existant dans `account_form_screen_test.dart`)

---

## Architecture — Fichiers impactés

| Opération | Fichier | Raison |
|-----------|---------|--------|
| **M** | `flutter/lib/src/features/accounts/presentation/widgets/account_preview_card.dart` | Ajout `AccountType? accountType` + Column layout avec type label (FR-006, FR-007) |
| **M** | `flutter/lib/src/features/accounts/presentation/screens/account_form_screen.dart` | Réordonnancement sections, 4 headers, masquage devise, ConfirmDialog, _ReadOnlyField (FR-001 à FR-012) |
| **M** | `flutter/test/src/features/accounts/presentation/screens/account_form_screen_test.dart` | ≥ 5 nouveaux tests pour SC-001 à SC-009 (NFR-006) |

Aucun fichier créé. Aucun fichier supprimé (hors suppression de la classe privée `_ReadOnlyField` dans `account_form_screen.dart`).

---

## Approche détaillée par composant

### Composant 1 — `AccountPreviewCard` (FR-006, FR-007, FR-008)

**Fichier** : `flutter/lib/src/features/accounts/presentation/widgets/account_preview_card.dart`

**Changement** : Ajout du paramètre `AccountType? accountType` (optionnel, `null` = pas de label affiché). Le `Expanded(Text name)` existant devient un `Expanded(Column([Text name, if accountType != null Text typeLabel]))`.

**Pattern** (RES-001) :
```dart
// Paramètre ajouté :
final AccountType? accountType;

// Méthode privée de conversion (pattern account_list_tile.dart:38-43) :
String _typeLabel(AppLocalizations l10n) => switch (accountType!) {
  AccountType.courant  => l10n.accountTypeCourant.toUpperCase(),
  AccountType.epargne  => l10n.accountTypeEpargne.toUpperCase(),
  AccountType.especes  => l10n.accountTypeEspeces.toUpperCase(),
};

// Dans build() — remplacement du Expanded :
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name ?? l10n.accountFormPreviewPlaceholder, ...),
      if (accountType != null)
        Text(
          _typeLabel(l10n),
          style: TextStyle(
            fontSize: AppTypography.sizeXs,
            fontWeight: AppTypography.semiBold,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
    ],
  ),
),
```

**Callsite à mettre à jour** : `account_form_screen.dart:407` → ajouter `accountType: _selectedType`.

**FR couverts** : FR-006, FR-007, FR-008
**NFR** : NFR-004 (`StatelessWidget` conservé)

---

### Composant 2 — `_SectionHeader` widget privé (FR-002, FR-003, FR-004, FR-005)

**Fichier** : `account_form_screen.dart` (classe privée en bas de fichier)

**Ajout** (RES-002) :
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

**Appels dans le body** (4 headers avec `SizedBox(height: AppSpacing.space2)` entre header et premier widget de la section) :
- `_SectionHeader(l10n.accountFormSectionType)` — avant `AccountTypeSelector`
- `_SectionHeader(l10n.accountFormSectionBank)` — avant `BankSelectPicker`
- `_SectionHeader(l10n.accountFormSectionPersonnalisation)` — avant emoji/color/logo (dans le bloc `if OTHER`)
- `_SectionHeader(l10n.accountFormSectionDetails)` — avant le champ nom

> Note : si les clés l10n `accountFormSectionType` etc. n'existent pas, utiliser les chaînes hardcodées `'TYPE DE COMPTE'`, `'BANQUE'`, `'PERSONNALISATION'`, `'DÉTAILS'`. **À vérifier avant implémentation** (cf. risque R-001).

**FR couverts** : FR-002, FR-003, FR-004, FR-005
**NFR** : NFR-005 (`letterSpacing: 0.8`, `semiBold`, `sizeXs`, `onSurfaceVariant`)

---

### Composant 3 — Réordonnancement des sections (FR-001)

**Fichier** : `account_form_screen.dart` — corps du `ListView` (`body:`)

**Ordre actuel** (lignes 406-638) :
1. Preview card (407)
2. `BankSelectPicker` (416)
3. `AccountTypeSelector` (424)
4. Personnalisation `if OTHER` (432)
5. Nom (491)
6. Devise (511)
7. Solde (532)
8. Active switch + Delete (589)

**Ordre cible** :
1. Preview card (avec `accountType: _selectedType`)
2. `_SectionHeader` Type + `AccountTypeSelector`
3. `_SectionHeader` Banque + `BankSelectPicker`
4. `if OTHER`: `_SectionHeader` Personnalisation + emoji/color/logo
5. `_SectionHeader` Détails
6. Nom
7. `if (!_isEditMode)` Devise ← **changement : caché en édition, pas désactivé**
8. Solde (initial si création / current+new si édition)
9. Active switch + Delete (inchangés)

**FR couverts** : FR-001

---

### Composant 4 — Masquage devise en édition (FR-009)

**Changement** : `account_form_screen.dart` ligne 511-528

Avant :
```dart
SelectPicker(
  ...
  enabled: !_isEditMode,
),
```

Après :
```dart
if (!_isEditMode)
  SelectPicker(
    ...
    // enabled: true (défaut)
  ),
```

**FR couverts** : FR-009

---

### Composant 5 — Migration `ConfirmDialogCustom` (FR-010)

**Changement** : `account_form_screen.dart` méthode `_onDelete()` (ligne 344)

Avant :
```dart
final confirmed = await showDeleteConfirmDialog(
  context: context,
  title: l10n.accountDeleteConfirmTitle,
  message: l10n.accountDeleteConfirmMessage,
);
```

Après (RES-003) :
```dart
final confirmed = await ConfirmDialogCustom.show(
  context: context,
  title: l10n.accountDeleteConfirmTitle,
  message: l10n.accountDeleteConfirmMessage,
  confirmLabel: l10n.delete,
  variant: ConfirmVariant.danger,
);
```

**Import** : Retirer `import '...confirm_delete_dialog.dart'` + ajouter `import '...confirm_dialog_custom.dart'`.

**Scope** : Import uniquement dans `account_form_screen.dart` — `confirm_delete_dialog.dart` conservé (4 autres callsites actifs — CL-002).

**FR couverts** : FR-010

---

### Composant 6 — Remplacement `_ReadOnlyField` (FR-011, FR-012)

**Changement** : `account_form_screen.dart`

Supprimer la classe `_ReadOnlyField` (lignes 713-743). Remplacer son callsite (ligne 557) par :

```dart
// Solde actuel (RES-004)
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
      Text(
        l10n.accountFormCurrentBalance,
        style: TextStyle(
          fontSize: AppTypography.sizeSm,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      Text(
        AmountFormatter.format(
          widget.account!.solde,
          currency: widget.account!.currency,
        ),
        style: TextStyle(
          fontSize: AppTypography.sizeSm,
          fontWeight: AppTypography.semiBold,
          color: colorScheme.onSurface,
        ),
      ),
    ],
  ),
),
```

**FR couverts** : FR-011, FR-012

---

### Composant 7 — Tests (NFR-006, SC-001 à SC-009)

**Fichier** : `flutter/test/src/features/accounts/presentation/screens/account_form_screen_test.dart`

8 tests existants conservés. ≥ 5 nouveaux tests à ajouter :

| Test | SC | Description |
|------|----|-------------|
| `should_showTypeSectionBeforeBank_when_createMode` | SC-001 | `AccountTypeSelector` avant `BankSelectPicker` dans le widget tree |
| `should_showSectionHeaders_when_createMode` | SC-002 | Textes "TYPE DE COMPTE", "BANQUE", "DÉTAILS" présents |
| `should_showTypeLabel_when_typeSelectedInPreview` | SC-003 | Preview affiche "COURANT" par défaut |
| `should_hideCurrencyPicker_when_editMode` | SC-005 | `SelectPicker` absent en mode édition |
| `should_useConfirmDialogCustom_when_deletePressed` | SC-006 | `ConfirmDialogCustom` (Dialog) affiché au tap delete |
| `should_showCurrentBalanceBlock_when_editMode` | SC-007 | Container `surfaceContainerHighest` visible avec solde formaté |

---

## Risques et mitigations

| ID | Risque | Probabilité | Impact | Mitigation |
|----|--------|-------------|--------|------------|
| R-001 | Clés l10n `accountFormSectionType/Bank/Personnalisation/Details` absentes | Haute | Faible | Utiliser hardcoded `'TYPE DE COMPTE'`, `'BANQUE'`, etc. si absent — vérifier `app_localizations.dart` avant implémentation |
| R-002 | Réordonnancement casse un test existant (`should_prefillDefaults_when_typeSelected` ou `should_showEditMode_when_accountProvided`) | Moyenne | Faible | Relire les 8 tests existants avant modification — ajuster si nécessaire |
| R-003 | `_SectionHeader` strings toUpperCase échouent sur accents (ès → ÈS) | Basse | Faible | `.toUpperCase()` Flutter respecte Unicode — vérifier manuellement sur device "ÉPARGNE", "ESPÈCES" |

---

## Hors scope

- Migration formulaire plein-page → bottom-sheet (décision intentionnelle, spec contexte)
- Proposition de taux : overlay inline Angular vs AlertDialog Flutter — hors alignement
- Logo upload : bottom-sheet caméra/galerie Flutter — adaptation mobile légitime
- Modification des autres formulaires utilisant `showDeleteConfirmDialog` (`debt_form`, `subscription_form`, `transaction_form`, `budget_form`) — hors KKS-255
- Ajout de l10n keys manquantes (si absentes → hardcoded pour ce ticket)

---

## Complexity Tracking

Aucune complexité architecturale ajoutée. Complexité réduite : suppression de `_ReadOnlyField` (1 classe privée).

---

## Artefacts complémentaires

| Artefact | Statut |
|----------|--------|
| [research.md](./research.md) | ✅ Produit (4 RES décisions) |
| data-model.md | Non requis — aucune entité nouvelle ni modifiée |
| quickstart.md | Non requis — pas de setup ou configuration nécessaire |
