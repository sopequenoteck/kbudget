# Tasks — KKS-253 : Profil / Mon compte Flutter (alignement DESIGN.md v5)

**Date** : 2026-05-22 | **Spec** : [spec.md](./spec.md) | **Plan** : [plan.md](./plan.md)
**Fichier cible** : `flutter/lib/src/features/user_profile/presentation/screens/profile_settings_screen.dart`
**Tests** : `flutter/test/src/features/user_profile/profile_settings_screen_test.dart`

---

## Phase 1 — Setup

**Objectif** : Vérifier les prérequis et préparer le terrain avant tout changement.

- [x] [T-001] Vérifier l'existence de `AppRadius.xl` dans `flutter/lib/src/constants/app_radius.dart` — si absent, noter le fallback `BorderRadius.circular(16)` à utiliser dans `_SettingsSection` — Réf : R-002
- [x] [T-002] Supprimer le code obsolète de `profile_settings_screen.dart` : classe `_CurrencySelector` (entière), variables `_selectedCurrency`, `_hasChanged`, `_isSaving`, méthode `_save()`, `actions:` dans l'`AppBar`, import `Currency` si devenu inutile — Réf : FR-011

**Checkpoint** : Le screen compile sans `_CurrencySelector`. Les tests existants peuvent casser temporairement (attendu).

---

## Phase 2 — Fondations

**Objectif** : Infrastructure partagée dont dépendent toutes les US. Aucune US ne peut commencer avant cette phase.

**⚠️ CRITIQUE** : T-010, T-011, T-012, T-013 doivent être complétés avant Phase 3.

- [x] [T-010] Créer `_SettingsSection({required String label, required List<Widget> children})` dans `profile_settings_screen.dart` : label uppercase `textTheme.labelSmall` + `onSurfaceVariant` + `fontWeight.w600`, `SizedBox(8)`, `ClipRRect(borderRadius: AppRadius.xl ou fallback)` + `Container(color: colorScheme.surfaceContainerHighest)` + `Column` avec `Divider(height:0, thickness:0.5, color: outlineVariant)` entre chaque child (absent après le dernier) — Réf : FR-005, FR-006, FR-007, FR-009
- [x] [T-011] Créer `_SettingsRow({PhosphorIconData? icon, Color? iconBg, required String title, String? description, Widget? trailing, VoidCallback? onTap, bool enabled = true})` dans `profile_settings_screen.dart` : icône circulaire 36 px (`Container(36×36, shape:circle, color:iconBg)`) si `icon` fourni, title + description, trailing = chevron `caretRight` par défaut si `onTap != null` et pas de `trailing` custom, `InkWell(onTap: enabled ? onTap : null, borderRadius: AppRadius.md)`, padding `EdgeInsets.symmetric(horizontal: space4, vertical: space3)` — Réf : FR-008
- [x] [T-012] Migrer `_ProfileSettingsScreenState` vers le pattern `ConsumerStatefulWidget` avec les nouvelles variables d'état : `bool _isEditingName = false`, `bool _isSavingName = false`, `late TextEditingController _nameController`, `bool _isExportingJson = false`, `bool _isExportingCsv = false`, `String? _errorMessage` + `initState()` → `_nameController = TextEditingController()` + `dispose()` → `_nameController.dispose()` — Réf : RES-002
- [x] [T-013] Restructurer `Scaffold.body` : `Column([if (_errorMessage != null) _errorBannerPlaceholder, Expanded(child: ListView(...))])` et créer le squelette des 4 `_SettingsSection` (Identité, Sécurité, Données, Zone de danger) avec des `_SettingsRow` provisoires (titres en dur) + `AvatarPicker` centré au-dessus de la section Identité — Réf : FR-005

**Checkpoint** : Le screen affiche 4 sections avec containers arrondis. `flutter analyze` sans erreur.

---

## Phase 3 — US P1 : Structure sections + Inline name edit

**Objectif** : Livrer les deux US critiques. US-002 pose la structure complète ; US-001 ajoute l'édition inline du nom.

### US-002 — Structure settings-section

**But** : 4 sections visuelles conformes DESIGN.md v5 avec icônes circulaires, chevrons, séparateurs.
**Test indépendant** : Vérifier visuellement les 4 sections — containers arrondis, icônes colorées, chevrons présents.

- [x] [T-020] [US-002] Implémenter la section **Identité** : `AvatarPicker(currentAvatarUrl: null, ...)` centré + `_SettingsSection(label:'Identité', children:[nameRow placeholder, emailRow])` où `emailRow` = `_SettingsRow(title: user.email, description: 'Géré par l\'administrateur')` sans icône ni trailing — Réf : FR-005, FR-008
- [x] [T-021] [P] [US-002] Implémenter les sections **Sécurité**, **Données** et **Zone de danger** : Sécurité → `_SettingsRow(icon: lock, iconBg: ext.primarySubtle, title:'Changer le mot de passe', onTap: _openChangePassword)` ; Données → rows JSON + CSV standard (sans spinner, branché en T-032) ; Danger → row Logout neutre + row Delete account (`title` en rouge `colorScheme.error`, sans icône) — Réf : FR-005, FR-008, FR-010

**Checkpoint** : SC-004, SC-005 vérifiables manuellement. Structure complète visible.

### US-001 — Inline name edit

**But** : Édition du nom directement dans l'écran sans navigation.
**Test indépendant** : Tap pencil → input inline visible, Enter/save → nom mis à jour.

- [x] [T-022] [US-001] Implémenter `_buildNameRow(User user)` en mode **lecture** : `_SettingsRow(title: user.name ?? 'Non renseigné', trailing: IconButton(PhosphorIconsRegular.pencil, onPressed: () => setState(() { _nameController.text = user.name ?? ''; _isEditingName = true; })))` — Réf : FR-001
- [x] [T-023] [US-001] Compléter `_buildNameRow()` avec le mode **édition** : si `_isEditingName` → `Padding(horizontal:space4, vertical:space3, child: Row([Expanded(TextField(controller:_nameController, autofocus:true, onSubmitted:(_)=>_saveName())), if (_isSavingName) SizedBox(20, CircularProgressIndicator) else IconButton(check, _saveName) + IconButton(x, cancel)]))` — Réf : FR-002, FR-003 (RES-003 : pas de gestion Escape)
- [x] [T-024] [US-001] Implémenter `_saveName()` : `setState(_errorMessage=null, _isSavingName=true)` → validation `name.trim().isNotEmpty && name.length <= 100` → `(await ref.read(userProfileRepositoryProvider.future)).updateName(name.trim())` → `ref.read(userProfileNotifierProvider.notifier).loadProfile()` → `setState(_isEditingName=false, _isSavingName=false)` ; en `catch` → `setState(_isSavingName=false, _errorMessage='Impossible de mettre à jour le nom')` — Réf : FR-004

**Checkpoint** : SC-001, SC-002, SC-003 testables. Édition inline fonctionnelle end-to-end.

---

## Phase 4 — US P2 : Export spinners + Error banner

**Objectif** : Livrer les US importantes. US-003 et US-004 sont indépendantes et parallélisables.

### US-003 — Spinners individuels + désactivation croisée

**But** : Feedback visuel pendant l'export, protection contre les doubles clics.
**Test indépendant** : Mocker un export lent, vérifier spinner + désactivation croisée.

- [x] [T-030] [US-003] Créer `_ExportRow({required PhosphorIconData icon, required Color iconBg, required String title, required bool isLoading, required bool enabled, required VoidCallback onTap})` : `description: isLoading ? 'Téléchargement en cours…' : null`, trailing = `SizedBox(20×20, child: CircularProgressIndicator(strokeWidth:2))` si `isLoading`, sinon `PhosphorIcon(caretRight)` — Réf : FR-012, FR-013
- [x] [T-031] [US-003] Refactorer `_exportJson()` et `_exportCsv()` : `setState(_errorMessage=null, _isExportingJson=true)` + `try { await repo.exportJson(); } catch (e) { setState(_errorMessage='Erreur lors de l\'export JSON'); } finally { setState(_isExportingJson=false); }` — supprimer `ScaffoldMessenger` — Réf : FR-012, FR-013, R-003
- [x] [T-032] [US-003] Brancher `_ExportRow` dans la section Données : `_ExportRow(icon:database, isLoading:_isExportingJson, enabled:!_isExportingJson && !_isExportingCsv, onTap:_exportJson)` + idem CSV — Réf : FR-014

**Checkpoint** : SC-007, SC-008 testables.

### US-004 — Error banner global

**But** : Bandeau d'erreur persistant sous le header pour toutes les actions échouées.
**Test indépendant** : Simuler une erreur réseau, vérifier bandeau rouge et persistance.

- [x] [T-033] [P] [US-004] Implémenter le widget error banner inline : `Container(width:double.infinity, color:colorScheme.errorContainer, padding:EdgeInsets.symmetric(horizontal:space4, vertical:space3), child: Row([PhosphorIcon(warning, color:error, size:16), SizedBox(space2), Expanded(Text(_errorMessage!, style:bodySmall+onErrorContainer))]))` — brancher dans `Scaffold.body` via `if (_errorMessage != null)` — Réf : FR-015
- [x] [T-034] [US-004] Ajouter `setState(() => _errorMessage = null)` en **début** de chaque action (`_saveName`, `_exportJson`, `_exportCsv`, `_logout`, `_openChangePassword`) pour effacement automatique — Réf : FR-016

**Checkpoint** : SC-009 testable. Bandeau apparaît et disparaît correctement.

---

## Phase 5 — Polish & Tests

**Objectif** : Couverture des SC, adaptation des tests existants, validation statique.

- [x] [T-050] Adapter les 7 tests existants dans `profile_settings_screen_test.dart` : ajouter override `userProfileRepositoryProvider` (mock `_MockUserProfileRepository`), supprimer toute référence à `_CurrencySelector` / `_hasChanged`, adapter les finders aux nouvelles labels de section si changés, vérifier `find.text('Géré par l\'administrateur')` toujours présent — Réf : NFR-003
- [x] [T-051] [P] Ajouter tests **SC-001** et **SC-003** : `should_showInlineTextField_when_pencilTapped` (find pencil → tap → `find.byType(TextField)` visible) + `should_closeEditMode_when_cancelTapped` (tap pencil → tap cancel → TextField absent) — Réf : NFR-006, SC-001, SC-003
- [x] [T-052] [P] Ajouter tests **SC-002** et **SC-006** : `should_callUpdateName_when_saveTapped` (mock `updateName` → tap save → vérifié appelé, `_isEditingName=false`) + `should_hideCurrencySelector_when_rendered` (`find.byType(_CurrencySelector)` → `findsNothing`, AppBar sans bouton save) — Réf : NFR-006, SC-002, SC-006
- [x] [T-053] [P] Ajouter tests **SC-007** et **SC-008** : `should_showSpinner_when_exportJsonStarted` (mock export lent → tap JSON → `find.byType(CircularProgressIndicator)`) + `should_disableCsvRow_when_exportingJson` (pendant export JSON → CSV row `onTap = null`) — Réf : NFR-006, SC-007, SC-008
- [x] [T-054] [P] Ajouter test **SC-009** : `should_showErrorBanner_when_actionFails` (mock `updateName` throw → tap save → `find.byType(Container)` avec `errorContainer` color) — Réf : NFR-006, SC-009
- [x] [T-055] Valider : `flutter analyze lib/src/features/user_profile/` → **No issues found** + `flutter test test/src/features/user_profile/` → **tous PASS** — Réf : SC-010, SC-011
- [x] [T-056] [P] Adapter `ProfileSettingsSkeleton` : remplacer les 3 `_fieldPlaceholder()` par 4 blocs skeleton représentant les sections (label 80 px + container arrondi avec 1-2 rows placeholder) — Réf : NFR-005

---

## Mapping Requirements → Tâches

| FR | Description | Tâche(s) |
|----|-------------|----------|
| FR-001 | Inline name edit : row Nom avec trigger pencil | T-022 |
| FR-002 | Inline name edit : input pré-rempli + save + cancel | T-023 |
| FR-003 | Enter save, trim + non vide + max 100 chars | T-023 |
| FR-004 | Sauvegarde via `userProfileRepositoryProvider.updateName` + `loadProfile` | T-024 |
| FR-005 | Structure 4 sections | T-013, T-020, T-021 |
| FR-006 | Label uppercase gris (`text-tertiary`, `font-weight-semibold`) | T-010 |
| FR-007 | Container section fond `surface-default`, `border-radius-xl` | T-010 |
| FR-008 | Rows icônes circulaires 36px, title/description, chevron | T-011, T-020, T-021 |
| FR-009 | Séparateurs entre rows (absent après dernier) | T-010 |
| FR-010 | Danger : Logout neutre, Delete rouge sans icône | T-021 |
| FR-011 | Supprimer `_CurrencySelector`, `_hasChanged`, bouton AppBar save | T-002 |
| FR-012 | Export JSON : spinner individuel `_isExportingJson` + sous-titre | T-030, T-031 |
| FR-013 | Export CSV : spinner individuel `_isExportingCsv` + sous-titre | T-030, T-031 |
| FR-014 | Désactivation croisée exports | T-032 |
| FR-015 | Error banner rouge inline sous le header | T-033 |
| FR-016 | Error banner effacé au début de chaque nouvelle action | T-034 |

| NFR | Description | Tâche(s) |
|-----|-------------|----------|
| NFR-001 | Aucune modification data/domain | — (contrainte) |
| NFR-002 | Tokens `AppThemeExtension` + `colorScheme` M3 | T-010, T-011, T-030, T-033 |
| NFR-003 | Widgets conservés (ChangePasswordSheet, DeleteAccountSheet) | T-021 (branché), T-050 |
| NFR-004 | `AvatarPicker` conservé | T-020 |
| NFR-005 | `ProfileSettingsSkeleton` adapté | T-056 |
| NFR-006 | Tests widget SC-001→SC-009 | T-050→T-054 |

---

## Phase 5 — Dépendances & Ordre d'exécution

### Graphe de dépendances

```
T-001 ──────────────────────────────────────────┐
T-002 ──────────────────────────────────────────┤
                                                 ▼
T-010 ──┐                                   Phase 2
T-011 ──┤ → T-013 ──┐
T-012 ──┘            │
                     ▼
              T-020 ──────────────┐
              T-021 ──────────────┤ → Phase 3 complète
              T-022 ──┐           │
              T-023 ──┤ → T-024 ──┘
                     │
              T-030 ──┐
              T-031 ──┤ → T-032 ──┐
              T-033 ──┘            │ → Phase 4 complète
              T-034 ───────────────┘
                                   │
              T-050 ───────────────┤
              T-051 ──┐            │
              T-052 ──┤ → T-055 ──┘
              T-053 ──┤
              T-054 ──┘
              T-056 (indépendant)
```

### Table US Dependencies

| User Story | Tâches | Dépend de |
|------------|--------|-----------|
| US-002 (P1) | T-020, T-021 | T-010, T-011, T-013 (Phase 2) |
| US-001 (P1) | T-022, T-023, T-024 | T-011, T-012, T-013 (Phase 2) |
| US-003 (P2) | T-030, T-031, T-032 | T-011 (Phase 2), T-021 (section Données squelette) |
| US-004 (P2) | T-033, T-034 | T-012, T-013 (Phase 2) |
| Tests | T-050→T-055 | Phase 3 + Phase 4 complètes |

### Parallel Opportunities

| Groupe | Tâches parallélisables | Condition |
|--------|------------------------|-----------|
| Phase 2 init | T-010 + T-011 | Aucune (widgets indépendants, même fichier) |
| Phase 3 US-001 + US-002 sections | T-021 + T-022 | Après T-013 |
| Phase 4 US-003 + US-004 | T-030 + T-033 | Après Phase 3 US-002 |
| Phase 5 tests | T-051 + T-052 + T-053 + T-054 | Après T-050 adapté |
| Phase 5 skeleton | T-056 | Indépendant (autre fichier) |

---

## Implementation Strategy

### MVP First (US-001 + US-002 uniquement)

1. Phase 1 : Setup (T-001, T-002)
2. Phase 2 : Fondations (T-010→T-013)
3. Phase 3 : US-002 (T-020, T-021) + US-001 (T-022→T-024)
4. **STOP et VALIDER** : vérifier manuellement SC-001→SC-006
5. Committer le MVP — les exports restent fonctionnels sans spinners (comportement existant)

### Incremental Delivery

1. Setup + Fondations → screen restructuré avec sections (valeur : conformité visuelle immédiate)
2. US-001 → édition nom inline (valeur : delta fonctionnel Angular ↔ Flutter comblé)
3. US-003 → spinners exports (valeur : protection UX double-clic)
4. US-004 → error banner (valeur : feedback erreur persistant)
5. Tests + validation → SC-010, SC-011 PASS

---

## Résumé

| Phase | Tâches | Dont [P] | Priorité |
|-------|--------|----------|---------|
| Phase 1 — Setup | 2 | 0 | — |
| Phase 2 — Fondations | 4 | 1 (T-011) | — |
| Phase 3 — US P1 | 5 | 1 (T-021) | P1 |
| Phase 4 — US P2 | 5 | 2 (T-030, T-033) | P2 |
| Phase 5 — Polish/Tests | 7 | 5 (T-051→T-054, T-056) | — |
| **Total** | **23** | **9** | |

**Couverture FRs** : 16/16 ✅ | **Couverture NFRs** : 6/6 ✅
