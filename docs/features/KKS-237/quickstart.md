# Quickstart — KKS-237 : Refonte tokens design Flutter (palette propriétaire v5)

> Date : 2026-05-03
> Issue : [KKS-237](https://linear.app/kksdev/issue/KKS-237/phase-1-etape-1-refonte-tokens-design-flutter-palette-proprietaire)

---

## Pré-requis

- [x] Constitution lue (`.specify/memory/constitution.md` v3.0.0)
- [x] Spec validée (`spec.md` — review-spec PASS)
- [x] Clarify complétée (`clarify-log.md` — 5 résolutions)
- [x] Research complétée (`research.md` — 8 décisions techniques)
- [x] Plan approuvé (`plan.md` — Constitution Check ✅)
- [ ] Tasks générées (`tasks.md` — à venir via `/devflow.tasks`)
- [ ] Branche `feature/flutter-tokens-refonte-v5` créée et checkée out
- [ ] Source de vérité Angular ouverte dans l'éditeur :
  - `app/src/styles/tokens/_primitives.scss`
  - `app/src/styles/themes/_dark.scss`
  - `app/src/styles/themes/_light.scss`

---

## Phase 1 — Setup

```bash
# Depuis la racine du repo
cd /Users/kellysossoe/Code/Apps/budget

# Créer la branche feature
git checkout develop
git pull
git checkout -b feature/flutter-tokens-refonte-v5

# Vérifier l'état Flutter
cd flutter
flutter pub get
flutter analyze   # baseline propre attendue
flutter test      # baseline 100% attendue
```

**Vérification** : `flutter analyze` retourne 0 erreur, `flutter test` passe à 100%. Si non, corriger avant de commencer (ne pas mélanger les corrections de baseline avec la refonte tokens).

---

## Phase 2 — Fondations

### Fichiers à modifier (récap plan.md)

| Fichier | Action | Composant |
|---------|--------|-----------|
| `flutter/lib/src/constants/app_colors.dart` | Refonte | Composant 1 (AppColors) |
| `flutter/lib/src/constants/app_typography.dart` | Étendre | Composant 2 (AppTypography) |
| `flutter/lib/src/constants/app_shadows.dart` | Refonte + étendre | Composant 3 (AppShadows) |
| `flutter/lib/src/theme/app_theme_extension.dart` | Étendre | Composant 4 (AppThemeExtension) |
| `flutter/lib/src/theme/app_theme.dart` | Refonte ciblée | Composant 5 (AppTheme) |
| `flutter/lib/src/features/dashboard/presentation/widgets/patrimoine_card.dart` | `@Deprecated` | Composant 6 |
| `docs/design-tokens.md` | Avertissement entête | Composant 7 |
| `flutter/test/theme/app_theme_extension_test.dart` | Créer/étendre | Tests |

### Étapes (ordre recommandé — cf. research.md §"Ordre d'implémentation")

1. **Refonte `AppColors`** — palette gris propriétaire (10 nuances) + valeurs sémantiques dark mises à jour (5 valeurs) + ajout des constantes sémantiques dark (~12 nouvelles) + ajout des constantes sémantiques light (~10 nouvelles).
2. **Étendre `AppTypography`** — 2 nouvelles tailles (`size2Xs`, `sizeHero`) + convention letter-spacing hybride (4 constantes).
3. **Refonte `AppShadows`** — `md`/`lg` double-layer + `coloredPrimaryDark`/`coloredPrimaryLight` + helper `coloredPrimary(Brightness)` + `@Deprecated` sur `colored()`.
4. **Étendre `AppThemeExtension`** — 10 nouvelles propriétés + `lerp()`/`copyWith()` étendus + tests unitaires.
5. **Refonte `AppTheme.dark`** — audit ligne par ligne, remplacement `AppColors.amber*` par `primaryAmberDark` selon RES-005.
6. **Refonte `AppTheme.light`** — alignement sur `_light.scss` (primary `amber-600` confirmé).
7. **Annotation `@Deprecated`** sur `PatrimoineCard`.
8. **Audit grep gradient** : `grep -rn "LinearGradient" flutter/lib/src/features/`.
9. **Audit informatif hardcodes Tailwind** (SC-011) : `grep -E '#(F59E0B|D97706|FBBF24|FCD34D|4ADE80|F87171|8B5CF6|A78BFA|111827|1F2937|374151|4B5563|6B7280|9CA3AF|D1D5DB|E5E7EB|F3F4F6|F9FAFB)' flutter/lib/src/features/` — résultat à consigner dans la PR.
10. **Avertissement obsolète `docs/design-tokens.md`** — insertion en entête.
11. **Adaptation des tests** existants validant des hex précis.

**Vérification** : après chaque étape, lancer `flutter analyze` (warnings `@Deprecated` autorisés sur `AppShadows.colored` et `PatrimoineCard`).

---

## Phase 3 — Implémentation User Stories

### US-001 — Aligner les primitives Flutter sur la palette gris propriétaire (P1)

1. Ouvrir `flutter/lib/src/constants/app_colors.dart`.
2. Remplacer les valeurs `gray50` → `gray900` par la palette propriétaire conforme à `_primitives.scss`.
3. Vérifier qu'aucune autre constante (e.g. `incomeDark`, `amber500`) n'utilise les anciennes valeurs Tailwind gray.

**Test** : `grep -E '#(111827|1F2937|374151|4B5563|6B7280|9CA3AF|D1D5DB|E5E7EB|F3F4F6|F9FAFB)' flutter/lib/src/constants/` retourne 0 ligne.

### US-002 — Conserver les primitives amber/violet/feedback Tailwind (P1)

1. Vérifier que `AppColors.amber500 = #f59e0b`, `amber400 = #fbbf24`, `amber600 = #d97706` restent inchangés.
2. Vérifier `violet500 = #8b5cf6`, `violet400 = #a78bfa`.
3. Vérifier feedback : `success = #22c55e`, `error = #ef4444`, `warning = #eab308`, `info = #3b82f6`.

**Test** : aucune modification sur ces constantes — diff git ne montre aucun changement sur ces lignes.

### US-003 — Définir la couche semantique dark (P1)

1. Ajouter dans `AppColors` la section commentée "Semantic dark values" avec :
   - `primaryAmberDark = Color(0xFFE0A820)`
   - `incomeDark = Color(0xFF6DC990)` (mise à jour valeur)
   - `expenseDark = Color(0xFFD97777)` (mise à jour valeur)
   - `subscriptionDark = Color(0xFF9580D9)` (mise à jour valeur)
   - `debtOweDark`, `debtOwedDark` (alias)
   - `textWarningDark = Color(0xFFD4AD3C)`
   - `textInfoDark = Color(0xFF7AACDB)`
2. Ajouter les constantes interactives dark (`primarySubtleDark`, `hoverBgDark`, etc.)
3. Mettre à jour `AppTheme.dark.colorScheme.primary = AppColors.primaryAmberDark`.
4. Étendre `AppThemeExtension` avec les nouvelles propriétés (`textWarning`, `textInfo`, `primarySubtle`, etc.).
5. Mettre à jour `AppThemeExtension.dark` pour pointer vers les nouvelles constantes.

**Test** : sur un widget arbitraire en dark, `Theme.of(context).colorScheme.primary == Color(0xFFE0A820)`. `Theme.of(context).extension<AppThemeExtension>()!.incomeColor == Color(0xFF6DC990)`.

### US-004 — Tokens manquants (P2)

1. Ajouter `AppTypography.size2Xs = 10.0` et `AppTypography.sizeHero = 36.0`.
2. Ajouter `AppTypography.labelLetterSpacingFactor = 0.05` et les 3 constantes pré-calculées.
3. Tous les nouveaux tokens documentés via `///`.

**Test** : `flutter analyze` propre. Constantes accessibles depuis un widget de test.

### US-005 — AppShadows aligné (P2)

1. Refondre `AppShadows.md` en double-layer (2 `BoxShadow` au lieu d'1).
2. Refondre `AppShadows.lg` en double-layer.
3. Ajouter `coloredPrimaryDark` et `coloredPrimaryLight` const.
4. Ajouter helper `coloredPrimary(Brightness)`.
5. Marquer `colored(Color, {alpha})` `@Deprecated`.

**Test** : `AppShadows.md.length == 2`. `AppShadows.coloredPrimary(Brightness.dark).first.color == Color(0x66000000)`.

### US-006 — AppTheme et anti-patterns (P2)

1. Audit `app_theme.dart` ligne par ligne — remplacer `AppColors.amber*` selon RES-005.
2. Annoter `PatrimoineCard` `@Deprecated('Gradient décoratif interdit en dark v5 — refonte hero flat dans KKS-240. Token Angular équivalent neutralisé : --hero-gradient: none.')`.
3. Audit grep `LinearGradient` pour autres widgets à marquer.

**Test** : `flutter analyze` retourne des warnings `@Deprecated` ciblés sur `PatrimoineCard` (et autres si trouvés). Aucune erreur. `Theme.of(context).colorScheme.surface == Color(0xFF141414)` en dark.

### US-007 — `docs/design-tokens.md` obsolète (P3)

1. Insérer l'avertissement obsolète en entête (cf. plan.md §"Composant 7").
2. Aucune modification du contenu existant.

**Test** : ouvrir `docs/design-tokens.md` — l'avertissement obsolète est visible immédiatement après le titre.

---

## Phase 4 — Polish

1. Adapter les tests Flutter existants qui validaient des valeurs hex précises (`incomeDark == 0xFF4ADE80` → `incomeDark == 0xFF6DC990`).
2. Compléter `app_theme_extension_test.dart` avec :
   - Test que `AppThemeExtension.dark.incomeColor == AppColors.incomeDark`.
   - Test que `AppThemeExtension.lerp(t=0)` retourne `this` pour chaque propriété.
   - Test que `AppThemeExtension.lerp(t=1)` retourne `other` pour chaque propriété.
3. Lancer la batterie complète :
   ```bash
   cd flutter
   flutter analyze
   flutter test
   ```
4. Test visuel manuel sur device/simulateur :
   - Lancer l'app en dark theme.
   - Vérifier que la primary apparaît en `#e0a820` (plus doux, moins saturé qu'avant).
   - Vérifier que les surfaces sont plus sombres (`#141414` au lieu de `#1F2937`).
   - Vérifier que `PatrimoineCard` continue de fonctionner (gradient toujours présent jusqu'à KKS-240) avec warning IDE `@Deprecated`.
5. Test visuel light theme : vérifier que la primary reste `#d97706` (amber-600) — comportement inchangé.
6. Audit informatif hardcodes Tailwind (SC-011) :
   ```bash
   grep -rE '#(F59E0B|D97706|FBBF24|FCD34D|4ADE80|F87171|8B5CF6|A78BFA|111827|1F2937|374151|4B5563|6B7280|9CA3AF|D1D5DB|E5E7EB|F3F4F6|F9FAFB)' flutter/lib/src/features/ | tee /tmp/hardcodes-tailwind-audit.txt
   wc -l /tmp/hardcodes-tailwind-audit.txt
   ```
   Consigner le comptage dans la description de PR.
7. Pre-commit review : lancer agent `pre-commit-review` sur les fichiers staged. Lancer `frontend-design-review` car fichiers frontend touchés.
8. Commit avec message descriptif référençant KKS-237.

---

## Commandes utiles

| Action | Commande |
|--------|----------|
| Lancer les tests | `cd flutter && flutter test` |
| Vérifier le lint | `cd flutter && flutter analyze` |
| Build dev | `cd flutter && flutter run` |
| Code generation (si applicable) | `cd flutter && dart run build_runner build --delete-conflicting-outputs` |
| Tests d'un fichier précis | `cd flutter && flutter test test/theme/app_theme_extension_test.dart` |
| Audit hardcodes Tailwind | Cf. Phase 4 étape 6 |
| Audit gradient anti-pattern | `grep -rn "LinearGradient" flutter/lib/src/features/` |
| Audit consommateurs `AppColors.amber*` | `grep -rn "AppColors\.amber" flutter/lib/src/` |

---

## Checklist finale

- [ ] Tous les tests Flutter passent (`flutter test` 100%)
- [ ] Pas d'erreur `flutter analyze` (warnings `@Deprecated` autorisés et attendus)
- [ ] Audit grep palette Tailwind gray (FR-005, SC-001) : 0 résultat dans `flutter/lib/src/constants/`
- [ ] Audit grep palette propriétaire (SC-002) : ≥ 10 résultats dans `app_colors.dart`
- [ ] `Theme.of(context).colorScheme.primary == Color(0xFFE0A820)` en dark (SC-005)
- [ ] `Theme.of(context).extension<AppThemeExtension>()!.incomeColor == Color(0xFF6DC990)` en dark (SC-006)
- [ ] `AppShadows.coloredPrimary(Brightness.dark).first.color == Color(0x66000000)` (SC-007)
- [ ] ≥ 12 nouveaux tokens documentés via `///` (SC-008)
- [ ] `PatrimoineCard` annoté `@Deprecated` (SC-009)
- [ ] `docs/design-tokens.md` porte l'avertissement obsolète (SC-010)
- [ ] Audit hardcodes Tailwind exécuté et consigné dans la PR (SC-011)
- [ ] Pre-commit review et frontend-design-review PASS
- [ ] Tests visuels dark + light validés sur device/simulateur
- [ ] Review-impl PASS via `/devflow.review-impl`
- [ ] Documentation à jour (mise à jour `docs.md` via `/devflow.docs`)
