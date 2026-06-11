# Tasks — KKS-255 : Comptes formulaire Flutter (alignement DESIGN.md v5)

**Date** : 2026-05-26
**Spec** : [spec.md](./spec.md) | **Plan** : [plan.md](./plan.md)

---

## Phase 1 — Setup

**Objectif** : Vérifier les prérequis et établir une baseline avant modification.

- [x] [T-001] Vérifier l'existence des clés l10n `accountFormSection*` dans `app_localizations.dart` — les sections headers utiliseront des chaînes hardcodées (`'TYPE DE COMPTE'`, `'BANQUE'`, `'PERSONNALISATION'`, `'DÉTAILS'`) — Réf: R-001
- [x] [T-002] Lancer `flutter analyze` baseline dans `flutter/` — noter le nombre d'infos/warnings pré-existants pour distinguer les régressions introduites — Réf: NFR-002

**Checkpoint** : Baseline établie, choix hardcodé pour les section headers confirmé.

---

## Phase 2 — Fondations

**Objectif** : Ajouter le widget privé `_SectionHeader` qui bloque toutes les tâches de section headers.

⚠️ Aucune tâche Phase 3 ne peut commencer avant T-010.

- [x] [T-010] [US-002] Ajouter la classe privée `_SectionHeader extends StatelessWidget` en bas de `flutter/lib/src/features/accounts/presentation/screens/account_form_screen.dart` (`sizeXs`, `semiBold`, `onSurfaceVariant`, `letterSpacing: 0.8`) — Réf: FR-002, FR-003, FR-004, FR-005

**Checkpoint** : `_SectionHeader` disponible → T-021 débloqué.

---

## Phase 3 — User Stories

### US-001 — Réordonnancement des sections (P1)

**Objectif** : Déplacer `AccountTypeSelector` avant `BankSelectPicker` dans le body.

- [x] [T-020] [US-001] Réordonner le body ListView de `account_form_screen.dart` : Preview → Type → Banque → Personnalisation (si OTHER) → Détails (conserver la logique inchangée, déplacer uniquement les blocs widget) — Réf: FR-001

**Checkpoint** : Ordre visuel conforme Angular — vérifiable manuellement (SC-001).

---

### US-002 — Section headers visuels (P1)

**Objectif** : Insérer les 4 appels `_SectionHeader` dans le body réordonné.

Dépend de T-010 et T-020.

- [x] [T-021] [US-002] Insérer dans le body réordonné : `_SectionHeader('TYPE DE COMPTE')` avant `AccountTypeSelector`, `_SectionHeader('BANQUE')` avant `BankSelectPicker`, `_SectionHeader('PERSONNALISATION')` dans le bloc `if OTHER`, `_SectionHeader('DÉTAILS')` avant le champ nom — avec `SizedBox(height: AppSpacing.space2)` entre chaque header et son premier widget — Réf: FR-002, FR-003, FR-004, FR-005

**Checkpoint** : 4 headers présents, uppercase, couleur `onSurfaceVariant` — vérifiable manuellement (SC-002).

---

### US-003 — Label de type dans la preview (P2)

**Objectif** : Afficher le type ("COURANT", "ÉPARGNE", "ESPÈCES") sous le nom dans `AccountPreviewCard`.

T-030 est parallélisable avec T-020/T-021 (fichier distinct). T-031 dépend de T-030.

- [x] [T-030] [P] [US-003] Modifier `flutter/lib/src/features/accounts/presentation/widgets/account_preview_card.dart` : ajouter `final AccountType? accountType`, méthode privée `_typeLabel(AppLocalizations l10n)` (switch exhaustif → `.toUpperCase()`), transformer `Expanded(Text name)` en `Expanded(Column([Text name, if (accountType != null) Text typeLabel]))` — Réf: FR-006, FR-007
- [x] [T-031] [US-003] Mettre à jour le callsite `account_form_screen.dart:407` : ajouter `accountType: _selectedType` au constructeur `AccountPreviewCard(...)` — Réf: FR-008

**Checkpoint** : Preview affiche "COURANT" par défaut, se met à jour au tap sur une type-card (SC-003, SC-004).

---

### US-004 — Devise masquée en édition (P2)

**Objectif** : Le `SelectPicker` devise n'est pas rendu en mode édition.

Parallélisable avec T-030 (même fichier que T-020/T-021 mais modification indépendante). À faire après T-020.

- [x] [T-032] [US-004] Dans `account_form_screen.dart` : remplacer `SelectPicker(..., enabled: !_isEditMode)` par `if (!_isEditMode) SelectPicker(...)` (retirer le paramètre `enabled`) — Réf: FR-009

**Checkpoint** : En mode édition, le `SelectPicker` devise est absent (SC-005).

---

### US-005 — Migration `ConfirmDialogCustom` (P2)

**Objectif** : Remplacer `showDeleteConfirmDialog` par `ConfirmDialogCustom.show()` dans `_onDelete()`.

- [x] [T-033] [US-005] Dans `account_form_screen.dart` : (1) retirer l'import `confirm_delete_dialog.dart`, (2) ajouter l'import `confirm_dialog_custom.dart`, (3) remplacer l'appel `showDeleteConfirmDialog(...)` par `ConfirmDialogCustom.show(context: context, icon: PhosphorIconsRegular.trash, title: ..., message: ..., confirmLabel: l10n.delete, variant: ConfirmVariant.danger)` dans `_onDelete()` (`phosphor_flutter` déjà importé) — Réf: FR-010

**Checkpoint** : Le dialog de suppression affiche le style danger (icône trash, bouton rouge) (SC-006).

---

### US-006 — Styling solde actuel en édition (P2)

**Objectif** : Remplacer `_ReadOnlyField` par un Container Row `surfaceContainerHighest`.

- [x] [T-034] [US-006] Dans `account_form_screen.dart` : (1) remplacer le callsite `_ReadOnlyField(...)` (ligne ~557) par un `Container(decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: ...), child: Row(mainAxisAlignment: spaceBetween, [Text label, Text valeur formatée]))`, (2) supprimer la classe privée `_ReadOnlyField` (lignes ~713-743) — Réf: FR-011, FR-012

**Checkpoint** : Solde actuel affiché dans un fond distinct, label à gauche, montant à droite (SC-007).

---

**Checkpoint Phase 3** : Toutes les US implémentées — vérification manuelle SC-001 à SC-007 possible.

---

## Phase 4 — Polish

**Objectif** : Tests automatisés + validation statique.

- [x] [T-050] [P] Écrire ≥ 5 nouveaux tests widget dans `flutter/test/src/features/accounts/presentation/screens/account_form_screen_test.dart` (conserver les 8 tests existants) :
  - `should_showTypeSectionBeforeBank_when_createMode` (SC-001)
  - `should_showSectionHeaders_when_createMode` (SC-002)
  - `should_showTypeLabel_when_defaultTypeInPreview` (SC-003)
  - `should_hideCurrencyPicker_when_editMode` (SC-005)
  - `should_useConfirmDialogCustom_when_deletePressed` (SC-006)
  - `should_showCurrentBalanceBlock_when_editMode` (SC-007)
  — Réf: NFR-006
- [x] [T-051] Lancer `flutter analyze flutter/` → vérifier 0 erreur nouvelle par rapport à la baseline T-002 — Réf: NFR-002, SC-008
- [x] [T-052] Lancer `flutter test flutter/test/src/features/accounts/` → vérifier ≥ 13 PASS (8 existants + ≥ 5 nouveaux), 0 FAIL — Réf: NFR-006, SC-009

**Checkpoint** : `flutter analyze` propre + tous les tests PASS → prêt pour review-impl.

---

## Phase 5 — Dependencies & Execution Order

### Graphe de dépendances

```
T-001 (setup/vérif l10n)        ─── aucune dépendance
T-002 (baseline analyze)         ─── aucune dépendance

T-010 (_SectionHeader widget)    ─── T-001, T-002
T-020 (réordonner sections)      ─── T-010
T-030 (AccountPreviewCard ext.)  ─── T-001, T-002 [parallèle avec T-010/T-020]

T-021 (insérer headers)          ─── T-010, T-020
T-031 (callsite accountType)     ─── T-030, T-020
T-032 (masquer devise édition)   ─── T-020
T-033 (ConfirmDialogCustom)      ─── T-020
T-034 (_ReadOnlyField replace)   ─── T-020

T-050 (écrire tests)             ─── T-021, T-031, T-032, T-033, T-034
T-051 (flutter analyze)          ─── T-050
T-052 (flutter test)             ─── T-050
```

### Table US Dependencies

| User Story | Tâches | Dépend de |
|------------|--------|-----------|
| US-001 (réordonnancement) | T-020 | T-010 |
| US-002 (section headers) | T-010, T-021 | T-010 → T-020 |
| US-003 (label type preview) | T-030, T-031 | T-030 → T-020 |
| US-004 (devise masquée) | T-032 | T-020 |
| US-005 (ConfirmDialogCustom) | T-033 | T-020 |
| US-006 (solde actuel styling) | T-034 | T-020 |

### Parallel Opportunities

| Groupe | Condition | Tâches |
|--------|-----------|--------|
| Setup | Immédiat | T-001, T-002 |
| Fondation + Preview | Après T-001/T-002 | T-010, T-030 (fichiers distincts) |
| P2 account_form | Après T-020 | T-032, T-033, T-034 (sections indépendantes du même fichier — à sérialiser pour éviter conflits) |
| Polish | Après T-021, T-031, T-032, T-033, T-034 | T-050, T-051 en parallèle sur T-052 (T-051 avant T-052 recommandé) |

---

## Implementation Strategy

### MVP First (US-001 + US-002 uniquement)

1. T-001, T-002 — setup
2. T-010, T-020, T-021 — réordonnancement + headers P1
3. **STOP** : vérifier SC-001 et SC-002 manuellement
4. Valeur délivrée : structure formulaire conforme Angular

### Incremental Delivery

1. T-001 → T-002 → T-010 → T-020 → T-021 : US-001 + US-002 (structure)
2. T-030 → T-031 : US-003 (preview live type label)
3. T-032 : US-004 (devise cachée en édition)
4. T-033 : US-005 (dialog suppression standard projet)
5. T-034 : US-006 (solde actuel styling)
6. T-050 → T-051 → T-052 : polish + validation

---

## Mapping Requirements → Tâches

| FR | Description courte | Tâche(s) |
|----|-------------------|----------|
| FR-001 | Réordonnancement sections | T-020 |
| FR-002 | Header "Type de compte" | T-010, T-021 |
| FR-003 | Header "Banque" | T-010, T-021 |
| FR-004 | Header "Personnalisation" | T-010, T-021 |
| FR-005 | Header "Détails" | T-010, T-021 |
| FR-006 | `AccountPreviewCard.accountType` paramètre | T-030 |
| FR-007 | Label type via `l10n.accountTypeXxx.toUpperCase()` | T-030 |
| FR-008 | Preview mise à jour temps réel | T-031 |
| FR-009 | Devise masquée en édition | T-032 |
| FR-010 | `ConfirmDialogCustom.show()` | T-033 |
| FR-011 | `_ReadOnlyField` → Container Row | T-034 |
| FR-012 | `AmountFormatter.format()` conservé | T-034 |

---

## Résumé

| Phase | Tâches | Dont parallélisables |
|-------|--------|----------------------|
| Phase 1 — Setup | 2 | 2 |
| Phase 2 — Fondations | 1 | 0 |
| Phase 3 — US P1 | 2 | 0 |
| Phase 3 — US P2 | 5 | 1 (T-030) |
| Phase 4 — Polish | 3 | 2 (T-050, T-051) |
| **Total** | **13** | **5** |
