# Review Log — KKS-255 : Comptes formulaire Flutter (alignement DESIGN.md v5)

---

## Itération 1 — review-spec — 2026-05-25

**Verdict : PASS**
**Agent** : devflow-review
**Artefacts analysés** : spec.md, clarify-log.md

### Constats

#### WARNING

| ID | Description | Recommandation |
|----|-------------|----------------|
| W-001 | Ordre des champs dans la section "Détails" non spécifié dans FR-001 — A-004 le mentionne comme assumption sans FR associé | Préciser dans FR-001 l'ordre exact : nom → (devise si création) → solde |
| W-002 | NFR-006 : seuil de 5 tests non justifié — risque de sous-couverture si tests triviaux | Reformuler "≥ 1 test par US modifiée (US-001 à US-006)" ou ≥ 6 tests |
| W-003 | SC-001 et SC-002 : méthodes de vérification uniquement manuelles pour des contraintes d'ordre structurel testables en widget test | Ajouter "Manuel + widget test" à SC-001 et SC-002 |
| W-004 | NFR-005 référence "pattern KKS-252" (listes) mais les formulaires ont un pattern différent — tokens pour `_SectionHeader` non consolidés dans les NFR | Préciser dans NFR-005 les tokens exacts : `sizeXs`, `semiBold`, `onSurfaceVariant`, `letterSpacing: 0.8` |

#### INFO

| ID | Description |
|----|-------------|
| I-001 | `clarify-log.md` présent et complet (CL-001 à CL-005) — conformité devflow OK |
| I-002 | FR-007 utilise `l10n.accountTypeXxx` comme placeholder — pattern concret disponible dans `account_list_tile.dart` (switch AccountType → clés l10n) |
| I-003 | "Active switch" et bouton "Supprimer" non explicitement exclus du scope dans la spec |
| I-004 | NFR-004 (`AccountPreviewCard` reste `StatelessWidget`) gagnerait à préciser "label de type passé en paramètre par le parent" |

### Justification PASS

Spec complète et immédiatement actionnable : 6 US avec Given/When/Then, 12 FR sans gap, 9 SC mesurables, 3 questions ouvertes toutes résolues, 4 Assumptions confirmées par le codebase. Aucun `[NEEDS CLARIFICATION]` restant. 0 constat BLOQUANT.

---

## Itération 2 — review-tasks — 2026-05-26

**Verdict : PASS**
**Agent** : devflow-review
**Artefacts analysés** : spec.md, plan.md, tasks.md

### Constats

#### WARNING

| ID | Description | Recommandation |
|----|-------------|----------------|
| W-001 | Dépendance T-020 → T-010 surdéclarée (zones disjointes du fichier) — incohérence entre texte narratif et graphe Phase 5 pour T-032/T-033/T-034 | Clarifier la justification de chaque dépendance ; marquer T-032/T-033/T-034 comme [P] avec note "sérialiser pour conflits git" |
| W-002 | T-031 dépend de T-020 sans justification dans le graphe Phase 5 | Ajouter note : "T-031 → T-020 (ligne 407 impactée par réordonnancement)" |
| W-003 | SC-004 (preview update en temps réel) sans couverture test automatique dans T-050 | Ajouter `should_updateTypeLabel_when_typeChangedInPreview` ou documenter validation manuelle uniquement |
| W-004 | T-002 (baseline analyze) non coché alors que T-001 est coché — état partiel avant implémentation | Cocher T-002 dès la baseline capturée |
| W-005 | `_SectionHeader` appelée avec strings déjà majuscules dans T-021, mais `build()` fait aussi `.toUpperCase()` — double uppercase redondant | Clarifier : soit strings hardcodées en minuscule, soit supprimer `.toUpperCase()` dans `build()` |

#### INFO

| ID | Description |
|----|-------------|
| I-001 | NFR-001 (non-régression) couvert implicitement par T-052 — non explicité dans le mapping NFR |
| I-002 | Risque R-002 (réordonnancement casse tests existants) non adressé dans T-020 — ajouter note de relecture |
| I-003 | T-033 omet `icon: PhosphorIconsRegular.trash` — requis par US-005 AC-001 / SC-006 |
| I-004 | `phosphor_flutter` déjà importé dans `account_form_screen.dart` — pas d'import supplémentaire requis pour l'icône |

### Justification PASS

12/12 FR couverts, mapping FR → Tâches complet. NFR-002 (T-051) et NFR-006 (T-050/T-052) adressés. Graphe Phase 5 cohérent avec la réalité du code (2 fichiers prod distincts pour les groupes parallèles). 5 WARNING = imprécisions de documentation sans impact bloquant sur l'implémentation.

---

## Itération 3 — review-impl — 2026-05-26

**Verdict : PASS**
**Agent** : devflow-review
**Artefacts analysés** : spec.md, plan.md, tasks.md, account_form_screen.dart, account_preview_card.dart, account_form_screen_test.dart

### Grille d'évaluation

| Passe | Statut |
|-------|--------|
| Conformité spec → code (FR-001 à FR-012) | ✅ PASS |
| NFR respectés (NFR-001 à NFR-006) | ✅ PASS |
| Qualité code | ⚠️ 1 SizedBox inutile |
| Non-régression (8 tests + callsites) | ✅ PASS |
| Complétude tâches (13/13) | ✅ PASS |

### Constats

#### WARNING

| ID | Description | Recommandation |
|----|-------------|----------------|
| W-001 | `SizedBox(height: AppSpacing.space0)` dans la branche `else` du bloc `if (_selectedBankCode == 'OTHER')` (ligne 498) — no-op, code superflu | Remplacer par `const SizedBox.shrink()` ou restructurer le `if` |

#### INFO

| ID | Description |
|----|-------------|
| I-001 | Chaînes hardcodées ("TYPE DE COMPTE", etc.) confirmées — clés l10n absentes de `app_fr.arb` (décision R-001 correcte) |
| I-002 | `should_hideCurrencyPicker_when_editMode` : `findsNothing` sur `SelectPicker` légèrement fragile si d'autres pickers ajoutés en édition |
| I-003 | `should_useConfirmDialogCustom_when_deletePressed` : ne valide pas `ConfirmVariant.danger` ni icône trash — couverture suffisante pour NFR-006 |

### Justification PASS

12/12 FR implémentés conformément à la spec. 6 NFR respectés : tokens v5, `StatelessWidget`, `flutter analyze` sans erreur nouvelle, 14 tests PASS (6 nouveaux). `_ReadOnlyField` supprimé, import `confirm_delete_dialog.dart` retiré, fichier conservé (4 callsites actifs). Aucune régression fonctionnelle. W-001 = code superflu inoffensif.
