# Review Log — KKS-237

> Trace des reviews cross-artefacts effectuées sur cette feature.

---

## Review Spec — 2026-05-03 (itération 1)

**Verdict : PASS (avec 5 WARNING non bloquants)**

### Synthèse

La spec est bien structurée, complète et cohérente sur ses propres bases. La phase de clarification a correctement résolu les 5 points NC. La principale détection est de **5 écarts WARNING** (dont 4 sur des valeurs ou tokens non documentés) qui n'empêchent pas le passage à research.

### Cohérence interne spec.md
- ✅ 7 US avec priorités cohérentes, "Why this priority", "Independent Test", "Acceptance Scenarios"
- ✅ 23 FR + 5 NFR + 11 SC + 7 Assumptions, tous traçables
- ✅ Aucun marqueur `[NEEDS CLARIFICATION]` résiduel
- ⚠️ W-03 : pas de tableau formel Requirements→US (mapping inférable mais non explicite)

### Cohérence cross-artefact (spec ↔ clarify-log)
- ✅ Les 5 CL résolus sont répercutés dans spec.md
- ✅ Section Open Questions remplacée par pointeur vers clarify-log.md
- ⚠️ W-05 : "SC-010 reformulé" cité dans le résumé clarify-log mais non tracé dans spec.md (mineur)

### Cohérence avec la constitution v3.0.0
- ✅ Principe I (Local-First) : NFR-004 garantit absence de dépendance réseau
- ✅ Principe IV (Mobile-First UX) : tokens cohérents avec usage mobile
- ✅ Principe V (Testabilité) : SC-003/SC-004 couvrent flutter analyze + flutter test
- ✅ Principe VII (Trajectoire B) : NFR-005 cite la constitution v3.0.0

### Cohérence avec la source de vérité Angular (SCSS)

Vérification valeur par valeur de la spec contre `_primitives.scss`, `_dark.scss`, `_light.scss` :

| Catégorie | Conforme | Écart |
|---|---|---|
| Palette gris primitive (10 nuances) | 10/10 | — |
| Primitives amber/violet/feedback | 9/9 | — |
| Tokens semantiques dark (color-primary, text-*, color-*, shadow neutralisée, font-size-2xs, font-size-hero) | 13/13 | — |
| Tokens interactifs dark (primary-subtle/muted/border, hover, highlight, overlay, focus, icon-circle) | 9/9 | — |

⚠️ **W-01** : FR-018 mentionne `0x59` (0.35) comme alternative pour l'ombre colored light, alors que `_primitives.scss` impose `0.4` (= `0x66`). Ambiguïté à trancher au profit de `0x66`.
⚠️ **W-02** : `textWarning = #ca8a04` et `textInfo = #2563eb` (light, conformes `_light.scss`) ne sont pas documentés dans FR-010/FR-012. À ajouter pour que l'`AppThemeExtension` light soit complet.
⚠️ **W-04** : `hoverBg = gray-100 en light` mentionné en US4 SC4 mais pas listé dans FR-011 ni FR-012 comme valeur de tokens light interactifs.

### Cohérence avec la codebase Flutter
- ✅ `AppThemeExtension` existant correctement décrit (6 propriétés, 14+ widgets consommateurs)
- ✅ Fichiers cibles vérifiés existants (`flutter/lib/src/constants/app_*.dart`, `flutter/lib/src/theme/app_theme*.dart`)
- ✅ Diagnostic correct : `incomeDark/expenseDark/subscriptionDark` actuels sont les anciennes valeurs Tailwind à remplacer
- ✅ `AppTheme.dark` utilise actuellement `primary: AppColors.amber400` (= `#FBBF24`) au lieu du custom `#e0a820` cible — diagnostic correct

### Périmètre
- ✅ Strictement limité aux fichiers de tokens et au thème
- ✅ Hors-périmètre explicite et exhaustif (KKS-238/239/240+ cités)
- ✅ Tokens "à valeur nulle en dark" (`--hero-gradient: none`, `--glass-bg`, etc.) explicitement exclus avec justification

### Constats BLOQUANT
Aucun.

### Constats WARNING (non bloquants)

| ID | Description |
|---|---|
| W-01 | FR-018 : mention `0x59` (0.35) ambiguë pour ombre colored light, contredit `_primitives.scss` (`0.4` = `0x66`). Trancher au profit de `0x66`. |
| W-02 | FR-010/FR-012 : valeurs light de `textWarning` (`#ca8a04`) et `textInfo` (`#2563eb`) non documentées. À ajouter. |
| W-03 | Tableau formel Requirements→US absent. Mineur, mais facilite la review-tasks future. |
| W-04 | `hoverBg = gray-100 en light` non listé explicitement dans FR-011/FR-012. |
| W-05 | "SC-010 reformulé" mentionné dans le résumé clarify-log mais pas tracé dans spec.md. |

### Recommandations pour /devflow.research

1. **Stratégie de migration `AppColors`** : trancher si les constantes sémantiques dark (`incomeDark`, `expenseDark`, `subscriptionDark`) doivent être supprimées de `AppColors` ou conservées avec valeurs mises à jour. Grep préliminaire sur `flutter/lib/src/features/` pour détecter les consommateurs directs.
2. **Pattern `AppShadows.coloredPrimary(context)`** : `AppShadows` est statique. Introduire un helper `BuildContext`-aware rompt le pattern `const`. Documenter : méthode statique prenant context, ou deux constantes `coloredPrimaryDark/Light`, ou les deux.
3. **Extension `lerp()` du `AppThemeExtension`** : ajout de ~10 nouveaux tokens nécessite extension de `lerp()` et `copyWith()`. Vérifier l'interpolation des tokens alpha (`primarySubtle = rgba(..., 0.10)`) entre dark et light.

---

### Corrections post-review-spec WARNING (2026-05-03 15:45)

| ID | Action |
|---|---|
| W-01 | FR-018 reformulé : retiré la mention `0x59` (0.35) ambiguë. Conservé uniquement `0x66` (0.4) avec citation explicite de `_primitives.scss` et `_dark.scss`. |
| W-02 | FR-012 décomposé en FR-012a/b/c/d. FR-012c ajoute `textWarning = #ca8a04` et `textInfo = #2563eb` en light, conformes `_light.scss`. |
| W-04 | FR-012d ajoute le bloc complet des tokens interactifs light : `hoverBg = #f5f5f5`, `hoverSubtle = rgba(0,0,0,0.04)`, `highlightSubtle = rgba(0,0,0,0.06)`, `overlayLight = rgba(0,0,0,0.10)`, `focusRing = rgba(245,158,11,0.5)`, `iconCircleBg = rgba(0,0,0,0.04)`, `primarySubtle/Muted/Border` light. |
| W-03 | Différé. Tableau Requirements→US à ajouter au moment de `/devflow.tasks` si nécessaire à la traçabilité. |
| W-05 | Différé. Cosmétique de traçabilité, n'impacte pas l'implémentation. |

US3 SC4 mis à jour pour expliciter les valeurs light dans le scénario d'acceptation.

**État final review-spec** : 3/5 WARNING corrigés (les 3 concrets). 2/5 différés (cosmétiques).

---

## Review Tasks — 2026-05-03 (itération 1)

**Verdict : PASS (avec 3 WARNING non bloquants)**

### Synthèse

Le `tasks.md` est de haute qualité : couverture exhaustive des 23 FR, 5 NFR, 11 SC ; alignement fidèle avec les 8 décisions research.md ; cohérence totale avec les 6 entités contracts.md ; ordonnancement et MVP clairs. Aucun bloquant. 3 WARNING mineurs corrigés post-review.

### Cohérence FR / NFR / SC
- ✅ 23 FR tous couverts par au moins une tâche
- ✅ 5 NFR couverts ou tracés "implicite" justifié (NFR-003, NFR-004)
- ✅ 11 SC couverts par tâches de validation
- ⚠️ W-02 (corrigé) : SC-006 mappé uniquement sur T-063 visuel — ajout T-061 unit test

### Cohérence User Stories
- ✅ 7 US toutes implémentées par tâches taggées `[USX]`
- ✅ Priorités `[P1]`/`[P2]`/`[P3]` cohérentes avec spec

### Ordonnancement et dépendances
- ✅ Chaîne critique T-003 → T-010 → T-012 → T-020 → T-037 → T-038 → T-041 cohérente
- ✅ Checkpoints mesurables entre phases
- ⚠️ Dépendance transitive T-010 → T-037 non explicite mais satisfaite

### Parallélisation
- ⚠️ W-01 (corrigé) : T-042 marqué `[P]` mais même fichier que T-041 — `[P]` retiré, séquentiel strict imposé
- ⚠️ G4 (T-033, T-034) : sections distinctes mais même fichier — note ajoutée pour préférer séquentiel mono-thread
- ✅ Groupes G1, G2, G3, G5-G9 corrects

### Granularité
- ✅ 37 tâches granularité homogène, aucune > 1 jour
- ✅ T-043 (audit ligne par ligne app_theme.dart) acceptable comme tâche la plus large (~3-4h)

### Cohérence research.md
- ✅ Les 8 décisions RES-001 à RES-008 toutes reflétées dans les tâches

### Cohérence contracts.md
- ✅ Toutes les signatures Dart documentées sont implémentées par des tâches
- ✅ Compatibilité backward 6 propriétés `AppThemeExtension` garantie par T-037/T-038/T-039

### Implementation Strategy
- ✅ MVP 9 tâches isolable et vérifiable
- ⚠️ W-03 (corrigé) : compte parallélisables P2 incorrect (5 vs 6 dans la liste) — corrigé à 4 (T-042 retiré)
- ⚠️ Description narrative MVP listait 7 tâches vs 9 dans la liste — corrigé

### Constats BLOQUANT
Aucun.

### Constats WARNING (corrigés)

| ID | Description | Action |
|---|---|---|
| W-01 | T-042 marqué `[P]` mais même fichier que T-041 | `[P]` retiré, mention "Séquentiel après T-041" ajoutée + note importante après tableau Parallel Opportunities |
| W-02 | SC-006 mapping incomplet (T-063 seulement) | T-061 enrichi avec test unitaire explicite SC-006 ; mapping table mis à jour |
| W-03 | Compte parallélisables P2 incorrect (5 vs 6) + MVP narratif (7) vs liste (9) | Corrigés : 4 parallélisables P2, MVP narratif aligné à 9 |

### Recommandations pour /devflow.implement

1. **Traiter T-041 → T-042 en séquentiel strict** (même fichier `app_theme.dart`).
2. **Respecter l'ordre research.md pour `AppColors`** : la tentation de faire T-020 à T-024 en un seul bloc est forte ; vérifier `flutter analyze` propre entre chaque section.
3. **G4 (T-033, T-034) en séquentiel** mono-thread pour éviter conflits sur `app_shadows.dart`.

---
