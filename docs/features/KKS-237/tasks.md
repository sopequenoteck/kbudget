# Tasks — KKS-237 : Refonte tokens design Flutter (palette propriétaire v5)

> Date : 2026-05-03
> Issue : [KKS-237](https://linear.app/kksdev/issue/KKS-237/phase-1-etape-1-refonte-tokens-design-flutter-palette-proprietaire)
> Spec : [spec.md](./spec.md)
> Plan : [plan.md](./plan.md)

---

## Phase 1 : Setup

- [ ] [T-001] [P1] Créer la branche `feature/flutter-tokens-refonte-v5` depuis `develop` — Réf: setup
- [ ] [T-002] [P1] Vérifier baseline propre : `cd flutter && flutter analyze && flutter test` (zéro erreur, 100% tests passent) — Réf: setup
- [ ] [T-003] [P1] Ouvrir les SCSS Angular comme source de vérité (`app/src/styles/tokens/_primitives.scss`, `app/src/styles/themes/_dark.scss`, `app/src/styles/themes/_light.scss`) — Réf: setup

**Checkpoint** : Branche feature créée, `flutter analyze` propre, `flutter test` à 100%, SCSS Angular accessibles côté éditeur.

---

## Phase 2 : Fondations (bloquantes)

Modifications de la couche primitive `AppColors` qui débloquent toutes les tâches suivantes.

- [ ] [T-010] [P1] [US1] Refonte palette gris propriétaire dans `AppColors.gray50` → `gray900` (10 nuances : `#fafafa, #f5f5f5, #e5e5e5, #d4d4d4, #a3a3a3, #737373, #525252, #1e1e1e, #141414, #0a0a0a`) — Réf: FR-001, FR-005
- [ ] [T-011] [P] [P1] [US2] Vérification que les primitives `AppColors.amber*`, `violet400/500`, `success/warning/error/info` restent inchangées (Tailwind conformément à `_primitives.scss`) — Réf: FR-002, FR-003, FR-004
- [ ] [T-012] [P1] [US3] Mise à jour des valeurs sémantiques dark business existantes : `incomeDark = #6DC990`, `expenseDark = #D97777`, `subscriptionDark = #9580D9`, `debtOweDark = #D97777`, `debtOwedDark = #6DC990` — Réf: FR-009

**Checkpoint** : Palette gris propriétaire en place. Les tests unitaires existants validant `incomeDark = #4ADE80` etc. cassent — c'est attendu, à corriger en Phase 4. `flutter analyze` reste propre. `grep -E '#(111827|1F2937|374151|4B5563|6B7280|9CA3AF|D1D5DB|E5E7EB|F3F4F6|F9FAFB)' flutter/lib/src/constants/` retourne 0 ligne (SC-001).

---

## Phase 3 : User Stories (par priorité)

### P1 — Critiques

#### Couche sémantique dark — primary, feedback, interactifs

- [ ] [T-020] [P1] [US3] Ajout dans `AppColors` section "Semantic dark values — primary" : `primaryAmberDark = Color(0xFFE0A820)`, `primaryAmberHoverDark = Color(0xFFC9952A)` avec docstrings — Réf: FR-009, FR-022
- [ ] [T-021] [P] [P1] [US3] Ajout dans `AppColors` section "Semantic dark values — feedback" : `textWarningDark = Color(0xFFD4AD3C)`, `textInfoDark = Color(0xFF7AACDB)` avec docstrings — Réf: FR-010, FR-022
- [ ] [T-022] [P] [P1] [US3] Ajout dans `AppColors` section "Semantic dark values — interactifs" (9 constantes) : `primarySubtleDark = Color(0x1AE0A820)`, `primaryMutedDark = Color(0x26E0A820)`, `primaryBorderDark = Color(0x40E0A820)`, `hoverBgDark = gray700`, `hoverSubtleDark = Color(0x0AFFFFFF)`, `highlightSubtleDark = Color(0x1AFFFFFF)`, `overlayLightDark = Color(0x26FFFFFF)`, `focusRingDark = Color(0x80FBBF24)`, `iconCircleBgDark = Color(0x0FFFFFFF)` — Réf: FR-011, FR-022

#### Couche sémantique light — feedback, interactifs

- [ ] [T-023] [P] [P1] [US3] Ajout dans `AppColors` section "Semantic light values — feedback" : `textWarningLight = Color(0xFFCA8A04)`, `textInfoLight = Color(0xFF2563EB)` avec docstrings — Réf: FR-012c, FR-022
- [ ] [T-024] [P] [P1] [US3] Ajout dans `AppColors` section "Semantic light values — interactifs" (9 constantes) : `primarySubtleLight = Color(0x1AD97706)`, `primaryMutedLight = Color(0x26D97706)`, `primaryBorderLight = Color(0x40D97706)`, `hoverBgLight = gray100`, `hoverSubtleLight = Color(0x0A000000)`, `highlightSubtleLight = Color(0x0F000000)`, `overlayLightLight = Color(0x1A000000)`, `focusRingLight = Color(0x80F59E0B)`, `iconCircleBgLight = Color(0x0A000000)` — Réf: FR-012d, FR-022

### P2 — Importantes

#### AppTypography

- [ ] [T-030] [P2] [US4] Ajout `AppTypography.size2Xs = 10.0` et `AppTypography.sizeHero = 36.0` avec docstrings — Réf: FR-013, FR-014, FR-022
- [ ] [T-031] [P] [P2] [US4] Ajout convention letter-spacing labels uppercase : `labelLetterSpacingFactor = 0.05`, `labelLetterSpacingForSize10 = 0.5`, `labelLetterSpacingForSize12 = 0.6`, `labelLetterSpacingForSize14 = 0.7` avec docstrings — Réf: FR-015, FR-022

#### AppShadows

- [ ] [T-032] [P2] [US5] Refonte `AppShadows.md` en double-layer (`[BoxShadow(blur=6, spread=-1, offset=(0,4), 0x1A000000), BoxShadow(blur=4, spread=-2, offset=(0,2), 0x1A000000)]`) — Réf: FR-016
- [ ] [T-033] [P] [P2] [US5] Refonte `AppShadows.lg` en double-layer (`[BoxShadow(blur=15, spread=-3, offset=(0,10), 0x1A000000), BoxShadow(blur=6, spread=-4, offset=(0,4), 0x1A000000)]`) — Réf: FR-017
- [ ] [T-034] [P] [P2] [US5] Ajout `AppShadows.coloredPrimaryDark = [BoxShadow(blur=24, spread=-4, offset=(0,8), 0x66000000)]` et `coloredPrimaryLight = [BoxShadow(blur=24, spread=-4, offset=(0,8), 0x66F59E0B)]` const — Réf: FR-018
- [ ] [T-035] [P2] [US5] Ajout helper `static List<BoxShadow> coloredPrimary(Brightness brightness) => brightness == Brightness.dark ? coloredPrimaryDark : coloredPrimaryLight;` — Réf: FR-018
- [ ] [T-036] [P2] [US5] Marquage `@Deprecated('Utiliser AppShadows.coloredPrimary(brightness) ou les constantes coloredPrimaryDark/Light. Cette API sera supprimée en KKS-240+.')` sur `AppShadows.colored(Color, {alpha})` — Réf: FR-019

#### AppThemeExtension

- [ ] [T-037] [P2] [US3] [US4] Étendre la classe `AppThemeExtension` avec 10 nouvelles propriétés `final Color` (`textWarning`, `textInfo`, `primarySubtle`, `primaryMuted`, `primaryBorder`, `hoverSubtle`, `highlightSubtle`, `overlayLight`, `focusRing`, `iconCircleBg`) + paramètres `required` du constructeur — Réf: FR-009, FR-010, FR-011
- [ ] [T-038] [P2] [US3] Mettre à jour `AppThemeExtension.dark` (instance const) pour pointer vers les nouvelles constantes `AppColors.{name}Dark` (16 propriétés au total) — Réf: FR-009, FR-010, FR-011
- [ ] [T-039] [P2] [US3] Mettre à jour `AppThemeExtension.light` (instance const) pour pointer vers les nouvelles constantes `AppColors.{name}Light` (16 propriétés au total) — Réf: FR-012b, FR-012c, FR-012d
- [ ] [T-040] [P2] [US3] Étendre les méthodes `copyWith()` et `lerp()` pour les 10 nouvelles propriétés (mécanique via `Color.lerp()`) — Réf: FR-009, FR-010, FR-011

#### AppTheme

- [ ] [T-041] [P2] [US6] Refonte `AppTheme.dark` : `colorScheme.primary = AppColors.primaryAmberDark` (`#E0A820`), `colorScheme.onPrimary = gray900`, `colorScheme.surface = gray800` (`#141414`), `colorScheme.surfaceContainerHighest = gray700`, `colorScheme.background = gray900`. Vérifier `useMaterial3: true`. — Réf: FR-006, FR-007, FR-008, FR-020
- [ ] [T-042] [P2] [US6] Refonte `AppTheme.light` : `colorScheme.primary = AppColors.amber600` (`#D97706`, conservé conforme `_light.scss`), `colorScheme.surface = #FFFFFF`, `colorScheme.surfaceContainerHighest = gray100`. Vérifier `useMaterial3: true`. **Séquentiel après T-041** (même fichier `app_theme.dart`). — Réf: FR-012a, FR-020
- [ ] [T-043] [P2] [US6] Audit ligne par ligne des 14+ usages `AppColors.amber*` dans `app_theme.dart` (selectedItemColor, FAB.backgroundColor, focused border, etc.) — reclasser chaque usage : sémantique primary → `primaryAmberDark` (dark) / `amber600` (light) ; palette structurelle → conservé. — Réf: FR-020

#### Anti-patterns

- [ ] [T-044] [P] [P2] [US6] Annotation `@Deprecated('Gradient décoratif interdit en dark v5 — refonte hero flat dans KKS-240. Token Angular équivalent neutralisé : --hero-gradient: none.')` sur la classe `PatrimoineCard` (`flutter/lib/src/features/dashboard/presentation/widgets/patrimoine_card.dart`) — Réf: FR-021
- [ ] [T-045] [P] [P2] [US6] Audit `grep -rn "LinearGradient" flutter/lib/src/features/` pour détecter d'autres widgets gradient à marquer `@Deprecated`. Marquer ceux trouvés. — Réf: FR-021

### P3 — Nice to have

- [ ] [T-050] [P] [P3] [US7] Insertion en entête de `docs/design-tokens.md` du bloc d'avertissement `> ⚠️ OBSOLÈTE — ...` avec redirection vers les sources de vérité actuelles (`_primitives.scss`, `_dark.scss`, `_light.scss`, `DESIGN.md`, Flutter `constants/` et `theme/`). Aucune modification du contenu existant. — Réf: FR-023

**Checkpoint Phase 3** : Tous les tokens nouveaux exposés. `flutter analyze` retourne uniquement des warnings `@Deprecated` ciblés (`AppShadows.colored`, `PatrimoineCard`, autres widgets gradient si trouvés). Les tests unitaires des widgets ne cassent pas (l'API `AppThemeExtension` reste backward compatible). Les tests sur les valeurs hex précises dans `app_colors.dart` cassent — à corriger en Phase 4.

---

## Phase 4 : Polish

- [ ] [T-060] [P2] Adapter les tests Flutter qui validaient des valeurs hex précises (`incomeDark == 0xFF4ADE80` → `incomeDark == 0xFF6DC990`, etc.). Préférence : référencer les tokens (`AppColors.incomeDark`) au lieu des valeurs hex pour future-proof — Réf: NFR-002
- [ ] [T-061] [P] [P2] Créer (ou étendre) `flutter/test/theme/app_theme_extension_test.dart` avec : (a) **test explicite SC-006** que `AppThemeExtension.dark.incomeColor == AppColors.incomeDark == Color(0xFF6DC990)` et symétrique pour light ; (b) test que chaque propriété dark/light pointe vers la bonne constante `AppColors.*Dark/*Light` (16 propriétés × 2 thèmes) ; (c) test `lerp(t=0)` retourne `this` ; (d) test `lerp(t=1)` retourne `other` ; (e) test `copyWith()` modifie uniquement la propriété passée — Réf: NFR-002, SC-006
- [ ] [T-062] [P] [P3] Audit informatif hardcodes Tailwind hors `AppColors` : `grep -rE '#(F59E0B|D97706|FBBF24|FCD34D|4ADE80|F87171|8B5CF6|A78BFA|111827|1F2937|374151|4B5563|6B7280|9CA3AF|D1D5DB|E5E7EB|F3F4F6|F9FAFB)' flutter/lib/src/features/` — consigner le comptage dans la description de PR (informatif, non bloquant) — Réf: SC-011
- [ ] [T-063] [P2] Test visuel manuel **dark theme** sur device/simulateur : (a) `colorScheme.primary` apparaît en `#e0a820` (plus doux que avant) ; (b) surfaces apparaissent en `#141414`/`#0a0a0a` (plus sombres que `#1F2937`/`#111827`) ; (c) `PatrimoineCard` continue d'afficher son gradient (warning IDE attendu) — Réf: SC-005
- [ ] [T-064] [P] [P2] Test visuel manuel **light theme** : `colorScheme.primary` reste `#d97706` (amber-600 inchangé), surfaces blanches/gray100 — Réf: FR-012a
- [ ] [T-065] [P2] Lancement final de la batterie : `cd flutter && flutter analyze && flutter test` — résultat : 0 erreur, warnings `@Deprecated` attendus, 100% tests passent — Réf: NFR-001, NFR-002, SC-003, SC-004
- [ ] [T-066] [P] [P2] Vérifications grep finales : (a) `grep -E '#(111827|1F2937|374151|4B5563|6B7280|9CA3AF|D1D5DB|E5E7EB|F3F4F6|F9FAFB)' flutter/lib/src/constants/` = 0 ligne ; (b) `grep -E '#(0a0a0a|141414|1e1e1e|525252|737373|a3a3a3|d4d4d4|e5e5e5|f5f5f5|fafafa)' flutter/lib/src/constants/app_colors.dart` ≥ 10 lignes — Réf: SC-001, SC-002
- [ ] [T-067] [P2] Pre-commit review : lancer agent `pre-commit-review` sur fichiers staged + `frontend-design-review` (frontend Flutter touché). CRITIQUE détecté → corriger avant commit. — Réf: NFR-005, gouvernance projet
- [ ] [T-068] [P3] Commit avec message descriptif référençant `KKS-237` et incluant le résumé du SC-011 dans la description PR — Réf: gouvernance projet

**Checkpoint Phase 4** : Tous les SC vérifiés (SC-001 à SC-011). `flutter analyze` propre (warnings `@Deprecated` autorisés). `flutter test` 100%. Pre-commit review et frontend-design-review PASS. PR prête à push pour `/devflow.review-impl`.

---

## Phase 5 : Dependencies & Execution Order

### Graphe de dépendances

```
Phase 1 (séquentiel) :
  T-001 → T-002 → T-003

Phase 2 (séquentiel sur AppColors) :
  T-003 → T-010 → T-012
              ↓
          T-011 [P avec T-010]

Phase 3 P1 (parallélisations larges) :
  T-012 → T-020
            ↓
       T-021 [P], T-022 [P], T-023 [P], T-024 [P]   (sections AppColors différentes)

Phase 3 P2 :
  T-020-T-024 → T-037 (étendre AppThemeExtension)
                  ↓
              T-038 → T-039 → T-040   (séquentiel : même fichier)
                                ↓
  T-020 + T-040 → T-041 (AppTheme.dark)
                    ↓
                T-042 [P avec T-041 — fichier différent? NON, même fichier]
                    ↓
                T-043 (audit ligne par ligne)

  T-030 → T-031 [P]   (AppTypography — même fichier mais zones différentes)
  T-032 → T-033 [P] → T-034 [P] → T-035 → T-036   (AppShadows séquentiel : même fichier)

  T-044 [P avec T-045]   (PatrimoineCard + audit grep autres widgets)

Phase 3 P3 :
  T-050 [P avec presque tout]   (docs/design-tokens.md — fichier indépendant)

Phase 4 :
  Phase 3 → T-060 [P avec T-061] → T-062 [P]
                                       ↓
                                   T-063 → T-064 [P]
                                              ↓
                                          T-065 → T-066 [P] → T-067 → T-068
```

### US Dependencies

| User Story | Tâches | Dépend de |
|------------|--------|-----------|
| **US1** (Primitives gris propriétaire) | T-010 | T-001, T-002, T-003 |
| **US2** (Primitives amber/violet/feedback conservées) | T-011 | T-003 |
| **US3** (Couche sémantique dark) | T-012, T-020, T-021, T-022, T-023, T-024, T-037, T-038, T-039, T-040 | T-010 |
| **US4** (Tokens manquants) | T-030, T-031, T-037 | T-003 (AppTypography) ; T-020-T-024 (pour T-037) |
| **US5** (AppShadows aligné) | T-032, T-033, T-034, T-035, T-036 | T-003 |
| **US6** (AppTheme et anti-patterns) | T-041, T-042, T-043, T-044, T-045 | T-020-T-024, T-040 |
| **US7** (docs/design-tokens.md obsolète) | T-050 | aucune (indépendant) |

### Parallel Opportunities

| Groupe | Tâches parallélisables | Condition |
|--------|----------------------|-----------|
| **G1** | T-010, T-011 | T-003 complété — modifs sur fichiers/sections différents |
| **G2** | T-021, T-022, T-023, T-024 | T-020 complété — sections différentes d'`AppColors` |
| **G3** | T-030, T-031 | aucune — sections différentes d'`AppTypography` |
| **G4** | T-033, T-034 | T-032 complété — sections distinctes du même fichier `app_shadows.dart` ; risque conflit faible mais réel — préférer séquentiel en mode mono-thread |
| **G5** | T-044, T-045 | T-003 complété — fichiers différents |
| **G6** | T-050 | aucune — fichier `docs/design-tokens.md` indépendant, parallélisable avec toute la Phase 3 |
| **G7** | T-060, T-061 | Phase 3 complétée — tests sur fichiers différents |
| **G8** | T-062, T-063, T-064 | T-061 complété — actions indépendantes |
| **G9** | T-065, T-066 | Phase 3 complétée — checks indépendants |

**Note importante** : T-041 (AppTheme.dark) et T-042 (AppTheme.light) modifient tous deux `app_theme.dart`. **À traiter en séquentiel strict** (T-041 → T-042) malgré la similarité de scope, pour éviter tout conflit.

---

## Implementation Strategy

### MVP First

**MVP** (livrer au plus vite la valeur "tokens alignés Angular v5") : T-001 → T-002 → T-003 → T-010 → T-012 → T-020 → T-037 → T-038 → T-041. Avec ces 9 tâches, le dark theme apparaît avec les bonnes valeurs (primary `#e0a820`, surfaces `#141414`, business tokens custom). C'est le cœur de la feature.

- **MVP** : T-001, T-002, T-003, T-010, T-012, T-020, T-037, T-038, T-041 (9 tâches)
- **Itération 2** (couche sémantique complète + light) : T-011, T-021, T-022, T-023, T-024, T-039, T-040, T-042, T-043
- **Itération 3** (typo + ombres + anti-patterns + doc) : T-030, T-031, T-032-T-036, T-044, T-045, T-050
- **Itération 4** (polish) : T-060 → T-068

### Incremental Delivery

| Livraison | Tâches | Valeur délivrée |
|-----------|--------|----------------|
| **L1 — Fondations** | T-001 → T-012 | Branche prête, palette gris propriétaire en place, valeurs sémantiques dark business mises à jour. Première vérification SC-001. |
| **L2 — Sémantique dark complète** | T-020, T-021, T-022, T-037 partiellement, T-038, T-041 | Dark theme cohérent v5 : primary `#e0a820`, surfaces sombres, business tokens custom (incomeDark = #6DC990 etc.). Cœur visuel de la feature. |
| **L3 — Sémantique light + tokens manquants** | T-023, T-024, T-030, T-031, T-039, T-040, T-042, T-043 | Light theme aligné, AppTypography étendu, AppThemeExtension complet. |
| **L4 — Ombres + anti-patterns** | T-032 → T-036, T-044, T-045 | AppShadows aligné double-layer + brightness-aware. Widgets gradient marqués `@Deprecated`. |
| **L5 — Documentation** | T-050 | `docs/design-tokens.md` marqué obsolète. |
| **L6 — Polish** | T-060 → T-068 | Tests adaptés et étendus, audits SC-001/002/011, tests visuels, pre-commit review. |

---

## Mapping Requirements → Tâches

| Requirement | Tâches |
|-------------|--------|
| FR-001 (palette gris propriétaire) | T-010 |
| FR-002 (primitives amber Tailwind) | T-011 |
| FR-003 (primitives violet Tailwind) | T-011 |
| FR-004 (primitives feedback Tailwind) | T-011 |
| FR-005 (aucune valeur Tailwind gray résiduelle) | T-010, T-066 |
| FR-006 (`AppTheme.dark.colorScheme.primary = #e0a820`) | T-041 |
| FR-007 (`AppTheme.dark.colorScheme.onPrimary = gray900`) | T-041 |
| FR-008 (`AppTheme.dark.colorScheme.surface = gray800`, etc.) | T-041 |
| FR-009 (business tokens dark via AppThemeExtension étendu) | T-012, T-020, T-037, T-038 |
| FR-010 (feedback dark `textWarning`, `textInfo`) | T-021, T-037, T-038 |
| FR-011 (interactifs dark) | T-022, T-037, T-038 |
| FR-012a (AppTheme.light primary amber-600) | T-042 |
| FR-012b (business tokens light) | T-039 |
| FR-012c (feedback light) | T-023, T-039 |
| FR-012d (interactifs light) | T-024, T-039 |
| FR-013 (`AppTypography.size2Xs`) | T-030 |
| FR-014 (`AppTypography.sizeHero`) | T-030 |
| FR-015 (letter-spacing convention hybride) | T-031 |
| FR-016 (`AppShadows.md` double-layer) | T-032 |
| FR-017 (`AppShadows.lg` double-layer) | T-033 |
| FR-018 (`AppShadows.coloredPrimary*`) | T-034, T-035 |
| FR-019 (`@Deprecated` sur `AppShadows.colored()`) | T-036 |
| FR-020 (AppTheme refonte) | T-041, T-042, T-043 |
| FR-021 (`@Deprecated` sur PatrimoineCard) | T-044, T-045 |
| FR-022 (docstrings sur nouveaux tokens) | T-020, T-021, T-022, T-023, T-024, T-030, T-031 |
| FR-023 (`docs/design-tokens.md` obsolète) | T-050 |
| NFR-001 (compile sans erreur) | T-065 |
| NFR-002 (tests Flutter passent) | T-060, T-061, T-065 |
| NFR-003 (performances inchangées) | implicite (refonte tokens, pas de logique runtime nouvelle) |
| NFR-004 (pubspec.yaml inchangé) | aucune dépendance ajoutée — vérifié par audit visuel diff git |
| NFR-005 (Constitution v3.0.0 respectée) | T-067 |
| SC-001 (audit grep Tailwind gray = 0) | T-066 |
| SC-002 (audit grep palette propriétaire ≥ 10) | T-066 |
| SC-003 (`flutter analyze` 0 erreur) | T-065 |
| SC-004 (`flutter test` 100%) | T-065 |
| SC-005 (`primary == #E0A820` dark) | T-063 |
| SC-006 (`incomeColor == #6DC990` dark via extension) | T-061 (test unitaire), T-063 (test visuel) |
| SC-007 (`coloredPrimary(dark).first.color == 0x66000000`) | T-061 |
| SC-008 (≥ 12 nouveaux tokens documentés) | T-020, T-021, T-022, T-023, T-024, T-030, T-031 (cumulé) |
| SC-009 (PatrimoineCard `@Deprecated`) | T-044 |
| SC-010 (`docs/design-tokens.md` avertissement obsolète) | T-050 |
| SC-011 (audit informatif hardcodes Tailwind) | T-062 |

---

## Résumé

| Phase | Total | P1 | P2 | P3 | Parallélisables |
|-------|-------|----|----|----|-----------------|
| Setup | 3 | 3 | 0 | 0 | 0 |
| Fondations | 3 | 3 | 0 | 0 | 1 (T-011) |
| User Stories P1 | 5 | 5 | 0 | 0 | 4 (T-021, T-022, T-023, T-024) |
| User Stories P2 | 16 | 0 | 16 | 0 | 4 (T-031, T-033, T-034, T-044, T-045) |
| User Stories P3 | 1 | 0 | 0 | 1 | 1 (T-050) |
| Polish | 9 | 0 | 7 | 2 | 4 (T-061, T-062, T-064, T-066) |
| **Total** | **37** | **11** | **23** | **3** | **14** |

**Estimation effort cumulée** : ~16h (cohérent avec Linear KKS-237 estimate = 3 points). Avec parallélisation, possible de descendre à ~10-12h en focus complet.
