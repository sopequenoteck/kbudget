# Review Log — KKS-239 : BottomSheet4RowsWidget composable

---

## Itération 1 — 2026-05-10 — review-tasks

**Verdict : PASS**

16/16 FR couverts. 14/14 SC couverts. 7/7 composants plan couverts. 5/5 contrats couverts. 0 cycle. 0 constat BLOQUANT.

### Warnings (W-XXX)

**W-001 : FR-009 mappé T-010+T-023+T-030 — câblage dans T-024 omis du mapping**
L'instanciation conditionnelle `if (errorMessage != null) _BSheetErrorBanner(...)` dans le widget principal est logiquement dans T-024 (assembly des 4 rows), mais T-024 n'est pas listé dans le mapping FR-009. Risque : implémenteur pourrait omettre le câblage dans T-024 et attendre T-030. Impact mineur si le plan est lu en complément.

**W-002 : Graphe Phase 5 — sur-contrainte T-021 + condition G1 incorrecte pour T-023**
T-021 est placé sous T-010 dans le graphe alors que sa seule dépendance réelle est T-001. La condition G1 dit "T-001 complété" pour T-023 alors que T-023 dépend de T-010 (`colorScheme.errorContainer`). Un implémenteur suivant strictement G1 pourrait démarrer T-023 avant T-010.

### Informations (I-XXX)

**I-001 : NFR-003 (60fps AnimatedSize) — aucune tâche de validation performance dédiée**
Risque documenté en CX-001/R2 du plan et différé à Étape 5 (CL-008). Observation sans action requise.

**I-002 : T-050 et T-051 sans tag [USX]**
Format incohérent avec les tâches Phase 3 — couverture multi-US rend le tag difficile. Non bloquant.

**I-003 : NFR-002, NFR-003, NFR-004 absents du tableau "Mapping Requirements → Tâches"**
Contraintes architecturales couvertes implicitement (T-024 pour NFR-002, T-001 pour NFR-004). Non bloquant.

---

## Itération 2 — 2026-05-10 — review-spec

**Verdict : PASS**

B-001 résolu : `AppDurations.normal` (200 ms) confirmé existant. FR-003, SC-003, US-003 alignés.
B-002 résolu : `colorScheme.errorContainer` documenté comme prérequis dans FR-009 + SC-005.
W-001 résolu : "FR-005bis" fantôme retiré de FR-002.
I-002/I-004/I-005 résolus : SC-011 corrigé, `onExpandClose` dans FR-005, US-002 libellé Debt corrigé.

Constats résiduels non bloquants :
- W-002 : état pressed `BSheetSubmitVariant.danger` non spécifié → à arbitrer en plan
- I-003 : NFR-003 (60fps) orphelin de SC → validation par POC en research
- I-007 : durée fermeture expand 150ms sans constante dédiée → valeur inline acceptable, à arbitrer en plan

---

## Itération 1 — 2026-05-10 — review-spec

**Verdict : BLOQUANT**

### Constats BLOQUANTS

**B-001 — `AppDurations.medium` inexistant (FR-003, SC-003)**

`AppDurations` n'expose que `fast` (120 ms), `normal` (200 ms), `slow` (400 ms). La constante `medium` est absente du fichier `flutter/lib/src/constants/app_durations.dart`. FR-003 et SC-003 la référencent pour la durée de l'`AnimatedSize` (300 ms). Le code ne compilerait pas tel quel.

**Correction** : dans FR-003 et SC-003, soit remplacer `AppDurations.medium` par `AppDurations.normal` (200 ms) ou `AppDurations.slow` (400 ms) et ajuster la valeur numérique, soit documenter explicitement l'ajout de `AppDurations.medium = const Duration(milliseconds: 300)` dans `app_durations.dart` comme prérequis de cette feature.

---

**B-002 — `colorScheme.errorContainer` non déclaré dans le projet (FR-009, SC-005)**

`app_theme.dart` ne déclare que `error` dans son `ColorScheme` (pas `errorContainer`). La valeur utilisée à runtime serait la valeur Material 3 par défaut (rose pâle), non un token projet. L'équivalence affirmée dans FR-009 (`colorScheme.errorContainer` ≡ `--bg-error`) est non validée. SC-005 testerait une couleur incorrecte visuellement.

**Correction** : arbitrer et documenter dans spec.md le token exact pour le fond du bandeau d'erreur. Options : (a) ajouter `errorContainer` explicitement dans les deux `ColorScheme` de `app_theme.dart` ; (b) utiliser un token `AppThemeExtension` existant ou à créer ; (c) accepter la valeur Material par défaut et le documenter. Ce choix doit figurer dans la spec avant la phase research.

---

### Constats WARNINGS

**W-001 — "FR-005bis" fantôme dans FR-002 (FR-002, FR-005, SC-014)**

FR-002 parenthèse de fin cite "cf. FR-005bis" qui n'existe pas dans le tableau des FR. Cela crée une contradiction apparente avec SC-014 cas (a) qui dit que le squelette rend Annuler automatiquement quand `footerLeading == null`. L'intention est correcte dans SC-014 ; la mention "FR-005bis" dans FR-002 est à supprimer.

**W-002 — État pressed (hover Angular → pressed Flutter) non spécifié pour `BSheetSubmitVariant.danger`**

CL-005 mentionne "fond `colorScheme.errorContainer` au hover" — terminologie Angular. Sur mobile Flutter il n'y a pas de hover, uniquement `pressed`. L'état pressed n'est pas spécifié. Non bloquant pour la spec, mais génèrera une question en phase plan.

---

### Constats INFO

**I-001** — Lié à B-001 : 300 ms ne correspond à aucune constante `AppDurations` (120 / 200 / 400 ms).
**I-002** — SC-011 : `dart analyze --fatal-infos` trop strict comme critère de vérification de la doc. Reformuler en "lecture humaine + `dart doc`".
**I-003** — NFR-003 (60 fps Pixel 3a) : orphelin de tout SC. Documenter que la validation se fera par POC en phase research.
**I-004** — `onExpandClose: VoidCallback?` déclaré en NFR-006 mais absent de FR-005 (API publique). À déplacer dans FR-005.
**I-005** — US-002 §Why this priority dit "Debt = pas de libellé" alors que §Périmètre et FR-005 précisent que Debt a bien un libellé "Personne". Incohérence mineure à corriger dans US-002.

---

### Corrections appliquées — 2026-05-10

1. **B-001 résolu** — `AppDurations.normal` (200 ms) choisi, aligné sur `expandCollapse` Angular (200ms easeOut enter / 150ms easeIn leave). Corrigé dans FR-003, SC-003, US-003 scenario 1.
2. **B-002 résolu** — `colorScheme.errorContainer` maintenu mais documenté comme prérequis (à ajouter dans `app_theme.dart` light + dark, aligné sur `--bg-error`). Corrigé dans FR-009, SC-005.
3. **W-001 résolu** — "FR-005bis" fantôme retiré de FR-002. Sémantique Annuler par défaut clarifiée.
4. **I-002 résolu** — SC-011 : `dart analyze --fatal-infos` remplacé par `dart doc`.
5. **I-004 résolu** — `onExpandClose: VoidCallback?` ajouté dans FR-005. NFR-006 mis à jour pour pointer vers FR-005.
6. **I-005 résolu** — US-002 §Why : "Debt = pas de libellé" corrigé en "Debt = libellé Personne requis".
