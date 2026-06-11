# Research — KKS-238 : Phase 1 / Étape 2 — Composants shared Flutter (8 widgets)

> Date : 2026-05-07
> Issue : [KKS-238](https://linear.app/kksdev/issue/KKS-238/phase-1-etape-2-composants-shared-flutter-8-widgets)
> Spec : [spec.md](./spec.md)

---

## Note méthodologique

Cette phase research arrive après un **clarify étendu par audit comparatif Angular** (cf. `clarify-log.md` § Note méthodologique). Beaucoup de décisions de design ont été prises dans ce cadre. Le présent research se concentre sur les **inconnues techniques d'implémentation Flutter restantes** : structure interne des widgets, communication entre widgets composites, choix d'API Flutter parmi des alternatives natives, traitement des constats reportés du review-spec.

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Architecture widget | Structure interne `SectionHeaderSticky` — delegate `SliverPersistentHeaderDelegate` (extends ou subclass anonymous) ? Comment exposer `minExtent`/`maxExtent` ? Comment animer la bascule de fond ? | **Haute** |
| RES-002 | Architecture widget | `InlineDatePicker` — modèle interne (`CalendarDay` private), structure des sub-widgets, format date entrée/sortie | **Haute** |
| RES-003 | Communication inter-widget | `CategorySelectExpand` ↔ `CategoryFormWidget` embarqué : comment déclencher `submit()` depuis le bouton header parent ? GlobalKey vs ValueNotifier vs callback ? | **Haute** |
| RES-004 | Refactor | Stratégie d'extraction `CategoryFormWidget` depuis `CategoryFormScreen` actuel : préservation comportement, signature API, tests | **Haute** |
| RES-005 | API Flutter | `ConfirmDialogCustom` via `showDialog` Material : barrierDismissible, animation, focus, type de bouton (pills) | Moyenne |
| RES-006 | Formatage | `VariationBadge` — format des montants et pourcentages (intl, locale, séparateurs) | Moyenne |
| RES-007 | Style Flutter | `EmptyStateWidget` CTA text-link (souligné au hover) — `TextButton` stylé vs `InkWell + Text` | Basse |
| RES-008 | API design | `PageHeader.icon` typing — `Widget?` libre vs wrapper ronde 32×32 imposé | Moyenne |
| RES-009 | Style Flutter | `ListGroup` dividers — `Divider` Material vs `Container` 1px custom ; couleur via `dividerColor` ou `AppThemeExtension` | Basse |
| RES-010 | Helper | `normalizeForSearch` (NFD + diacritiques) — package existant ou nouveau helper | Basse |
| RES-011 | Décommissionnement | Remplacement `SegmentedFilter` (2 sites) — `ChoiceChip` vs `FilterChip` vs `SegmentedButton` | Moyenne |
| RES-012 | Tests | Pattern de tests dark + light — duplication par thème vs paramétrage | Basse |
| RES-013 | Mapping cross-stack | Mapping `surfaceContainer` Flutter ↔ `--surface-default` Angular (INFO-01 review-spec) | Basse |
| RES-014 | Méthodologie | Méthode de vérification NFR-003 « 60 fps Pixel 3a » (WARNING-02 review-spec) | Moyenne |

---

## Décisions techniques

### RES-001 — Pattern `SectionHeaderSticky` via `SliverPersistentHeader`

- **Contexte** : CL-001 a tranché l'utilisation de `SliverPersistentHeader(pinned: true)`. Restent les détails d'implémentation : structure du delegate, animation de la bascule de fond, exposition des extents.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `SliverPersistentHeaderDelegate` subclass dédié `_SectionHeaderDelegate` | Idiomatique Flutter, `shouldRebuild` contrôlable, code testable séparément | Une class supplémentaire | **9/10** |
| B — `SliverPersistentHeaderDelegate` anonymous via package `flutter/cupertino` ou helper | Concis | Pas standard, moins lisible, `shouldRebuild` toujours `true` (rebuild inutiles) | 4/10 |
| C — `SliverAppBar(pinned: true)` avec `flexibleSpace` | Animation built-in | Trop opiniâtré (titre + actions Material), divergence DESIGN.md, override coûteux | 3/10 |

- **Décision** : **Option A** — subclass `_SectionHeaderDelegate extends SliverPersistentHeaderDelegate`.
- **Rationale** :
  - `minExtent == maxExtent` (header fixe en hauteur, pas d'expand/collapse) — simplifie l'animation à une bascule de couleur.
  - `shouldRebuild(_SectionHeaderDelegate oldDelegate)` retourne `oldDelegate.title != title || oldDelegate.count != count || oldDelegate.actions != actions` → optimisation rebuild.
  - Animation de fond via `AnimatedContainer(duration: AppDurations.medium)` dans le `build(context, shrinkOffset, overlapsContent)` du delegate, basé sur `shrinkOffset > 0` (équivalent du `.stuck` Angular).
  - Hauteur fixe : `static const double _kHeight = 48.0` (équivalent au padding Angular `space-2 + size-base + space-2 = 32px`, arrondi à 48 pour confort tactile).
- **Alternatives rejetées** :
  - Option B : moins d'optimisation, comportement par défaut `shouldRebuild=true` sur chaque scroll = waste perf.
  - Option C : `SliverAppBar` est conçu pour des AppBars Material avec leading/title/actions. Override pour produire DESIGN.md = couvre le widget de hacks.
- **Impact sur le plan** :
  - Créer `flutter/lib/src/common_widgets/section_header_sticky.dart` avec :
    - Public widget `SectionHeaderSticky` exposant `title`, `count?`, `actions?`
    - Private `_SectionHeaderDelegate extends SliverPersistentHeaderDelegate`
  - Test : utiliser `tester.scrollUntilVisible()` ou `tester.drag(find.byType(CustomScrollView), Offset(0, -300))` pour faire tomber le header au top, puis vérifier la couleur via `tester.widget<AnimatedContainer>().decoration`.

---

### RES-002 — Architecture interne `InlineDatePicker`

- **Contexte** : CL-002 a tranché la réimplémentation custom. Restent les choix de structure interne (model `CalendarDay`, sub-widgets, format date).
- **Options évaluées** :

| Option | Modèle interne | Sub-widgets | Format I/O |
|--------|---------------|-------------|------------|
| A — Direct, pas de model | Calculs inline dans `build()` | Tout en un seul widget `_buildXxx()` | `String` ISO direct |
| B — Model `CalendarDay` + sub-widgets privés | Model `_CalendarDay` (private record) | `_CalendarHeader`, `_CalendarGrid`, `_DayCell` | `String` ISO en sortie, `DateTime` interne pour mois/année |
| C — Package externe `table_calendar` | N/A | Widget de la lib | `DateTime` natif |

- **Décision** : **Option B** — Model privé + sub-widgets décomposés.
- **Rationale** :
  - Reproduit fidèlement la structure Angular (interface `CalendarDay`, sous-blocs `idp__header`, `idp__grid`, `idp__day`).
  - Testabilité : `_DayCell` peut être testé isolément (état sélectionné / aujourd'hui / original / disabled / hors-mois).
  - Model `CalendarDay` :
    ```dart
    class _CalendarDay {
      final DateTime date;
      final int dayNumber;
      final bool isCurrentMonth;
      final bool isToday;
      final bool isSelected;
      final bool isOriginal;
      final bool isDisabled;
      final String isoDate;
      // ...
    }
    ```
  - Format I/O : `String` ISO en entrée/sortie (cohérent FR-001), `DateTime` interne pour navigation `_currentMonth` / `_currentYear` (équivalent signals Angular). Helpers privés `_toIsoDate(DateTime)` et `_isoToDate(String)`.
- **Alternatives rejetées** :
  - Option A : code monolithique → tests difficiles, refactor coûteux.
  - Option C (`table_calendar`) : viole NFR-005 (pas de package externe nouveau) et pattern visuel impose des hacks.
- **Impact sur le plan** :
  - Fichier `flutter/lib/src/common_widgets/inline_date_picker.dart` (~250 lignes Dart).
  - Sub-widgets privés dans le même fichier : `_CalendarHeader`, `_CalendarGrid`, `_DayCell` (Stateless).
  - Helpers `_toIsoDate`, `_isoToDate`, `_normalizeStartOffset` privés au fichier.
  - Tests : 5 widget tests (rendu mois courant, navigation, sélection, originalValue mode édition, min/max disabled).

---

### RES-003 — Communication `CategorySelectExpand` ↔ `CategoryFormWidget`

- **Contexte** : Le pattern Angular utilise `viewChild('formRef')` + `categoryForm()?.submit()`. Comment reproduire cette communication parent → enfant en Flutter ?
- **Options évaluées** :

| Option | Mécanisme | Avantages | Inconvénients |
|--------|-----------|-----------|---------------|
| A — `GlobalKey<CategoryFormWidgetState>` | `key.currentState?.submit()` depuis le bouton header | Idiomatique Flutter pour ce cas, simple | `GlobalKey` déconseillé en général (rebuild non gérés) — mais cas légitime ici |
| B — `ValueNotifier<bool> triggerSubmit` injecté | Le bouton header `triggerSubmit.value = true`, le form écoute via `addListener` | Découplé, testable | Verbeux, état asynchrone |
| C — `submitController: SubmitController` (custom controller pattern, comme `TextEditingController`) | API publique élégante | Sur-ingénierie pour 1 méthode | Pour 1 callback ça vaut pas le coût |
| D — Bouton submit interne au sous-widget, pas de bouton header parent | Plus simple | Diverge du pattern Angular qui a le bouton dans le header parent (ergonomie : footer du sheet désactivé pendant création) | |

- **Décision** : **Option A** — `GlobalKey<CategoryFormWidgetState>`.
- **Rationale** :
  - `GlobalKey` est le mécanisme officiel Flutter pour atteindre l'état d'un sous-widget depuis un parent (cf. doc Flutter : « To use a GlobalKey to access the state of a widget »).
  - L'inconvénient principal des `GlobalKey` (rebuild non gérés quand le widget change de position dans l'arbre) ne s'applique pas ici : le `CategoryFormWidget` est créé/détruit avec le mode `'create'` et n'est jamais déplacé.
  - Le `GlobalKey` est créé une seule fois en `initState` du `_CategorySelectExpandState` et passé au `CategoryFormWidget` lorsqu'il est instancié.
  - Pattern : `_formKey.currentState?.submit()` depuis le `onPressed` du bouton header `[✓ Créer]`.
- **Alternatives rejetées** :
  - Option B : ajout d'un `ValueNotifier` pour 1 commande binaire = sur-ingénierie.
  - Option C : custom controller pattern = trop pour 1 méthode.
  - Option D : casse l'ergonomie Angular (footer parent inactif pendant création).
- **Impact sur le plan** :
  - `_CategorySelectExpandState` détient `_formKey = GlobalKey<CategoryFormWidgetState>()`.
  - `CategoryFormWidget` doit exposer `State` publique avec méthode `submit()` accessible (`State<CategoryFormWidget>` est private par défaut → faire un type alias ou exposer un mixin).
  - Préférer le pattern : `class CategoryFormWidgetState extends State<CategoryFormWidget>` (state class publique), avec méthode publique `Future<void> submit()`.

---

### RES-004 — Stratégie d'extraction `CategoryFormWidget`

- **Contexte** : `CategoryFormScreen` actuel (`category_form_screen.dart`, 218 lignes) est un `ConsumerStatefulWidget` avec Scaffold + AppBar. À transformer pour permettre l'embed sans Scaffold.
- **Options évaluées** :

| Option | Stratégie | Avantages | Inconvénients |
|--------|-----------|-----------|---------------|
| A — Refactor in-place | `CategoryFormScreen` extrait son corps dans un nouveau `CategoryFormWidget` ; `CategoryFormScreen` devient un wrapper Scaffold autour | Préserve les tests existants, refactor minimal | Demande discipline pour ne pas casser les usages actuels |
| B — Réécriture complète | Créer `CategoryFormWidget` from scratch en s'inspirant de `CategoryFormScreen`, garder l'ancien temporairement | Liberté totale | Duplication temporaire, risque de divergence |
| C — `CategoryFormWidget` reçoit `Scaffold` en option via `wrapInScaffold: bool` | Un seul widget pour les 2 cas | Anti-pattern : un widget devrait avoir une responsabilité claire | |

- **Décision** : **Option A** — refactor in-place.
- **Rationale** :
  - Le refactor est mécanique : extraire le `body` du Scaffold dans un `CategoryFormWidget` `ConsumerStatefulWidget`, garder Scaffold + AppBar dans `CategoryFormScreen`.
  - `CategoryFormScreen` reste navigable via `context.go('/categories/new')` pour le cas standalone (création depuis liste catégories).
  - `CategoryFormWidget` est utilisable embedded sans Scaffold (cas `CategorySelectExpand`).
- **Signature** `CategoryFormWidget` :
  ```dart
  class CategoryFormWidget extends ConsumerStatefulWidget {
    final Category? category;       // null = create, non-null = edit
    final String? initialName;      // pré-remplissage du champ nom (depuis recherche CategorySelectExpand)
    final ValueChanged<Category>? onSaved;     // émis après save réussi
    final VoidCallback? onCancelled;           // émis au cancel
    final bool showHeader;          // défaut true ; false en mode embedded (pas d'AppBar dans le widget)
  }
  ```
- **Méthode publique** `Future<void> submit()` exposée par `CategoryFormWidgetState` (publique, pas privée).
  - Valide les champs (nom + emoji) — affiche les erreurs inline si invalide, **ne lève pas d'exception**.
  - Si valide : appelle `categoryNotifierProvider.notifier.create()` ou `.update()`, attend le retour, émet `onSaved(category)`.
  - Si erreur réseau / serveur : reste sur le widget, affiche un `SnackBar` d'erreur (cohérent avec le comportement actuel `CategoryFormScreen`).
- **Comportement clé (réponse INFO-02 review-spec)** :
  - `submit()` est silencieux en cas d'erreur de validation (affiche les erreurs inline via le state interne `_showErrors`).
  - `onSaved` est émis **uniquement** en cas de succès complet (POST/PUT réussi).
  - Erreurs réseau → `SnackBar`, pas de propagation au parent (cohérent Angular `category-form` qui gère ses propres erreurs).
- **Alternatives rejetées** :
  - Option B : duplication risque divergence.
  - Option C : viole SRP, anti-pattern Flutter.
- **Impact sur le plan** :
  - 1 nouveau fichier : `flutter/lib/src/features/categories/presentation/widgets/category_form_widget.dart`
  - 1 fichier existant modifié : `flutter/lib/src/features/categories/presentation/screens/category_form_screen.dart` (devient un wrapper Scaffold de ~30 lignes).
  - Tests : déplacer/adapter les tests existants de `CategoryFormScreen` vers `CategoryFormWidget` (les tests étaient probablement sur `CategoryFormScreen`, vérifier en plan).

---

### RES-005 — `ConfirmDialogCustom` via `showDialog` natif

- **Contexte** : CL-004 a tranché la méthode statique `Future<bool>` via `showDialog`. Restent les détails : barrierDismissible, animation, type de bouton.
- **Décision** :
  - `showDialog<bool>(context: context, barrierDismissible: true, builder: (ctx) => Dialog(child: _ConfirmDialogContent(...)))`.
  - `barrierDismissible: true` → tap sur le scrim ferme avec `null`, mais on **ne convertit jamais `null` en `false`** dans le `Future<bool>` retourné — on assume que les sites d'appel font `final result = await ConfirmDialogCustom.show(...) ?? false`. Plus sûr et cohérent Material.
  - **Correction** : retourner `Future<bool?>` plutôt que `Future<bool>` (signature plus précise, idiomatique Flutter, évite la conversion silencieuse `null → false`).
  - Boutons en pills compacts via :
    - Bouton Annuler : `OutlinedButton.icon(icon: Icon(PhosphorIcons.x(), size: 14), label: Text(cancelLabel), style: OutlinedButton.styleFrom(...))`
    - Bouton Confirmer : `FilledButton.icon(icon: Icon(... selon variant), ...)` avec `backgroundColor: colorScheme.primary` (default) ou `colorScheme.error` (danger).
  - Animation : par défaut Material (fade + scale léger). Pas de custom transition.
- **Impact sur le plan** : signature publique :
  ```dart
  static Future<bool?> show({
    required BuildContext context,
    IconData? icon,
    required String title,
    String? message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    ConfirmVariant variant = ConfirmVariant.default_,
  });
  ```
  Note : `default` est un mot réservé Dart → utiliser `default_` ou renommer (`primary`, `normal`).

---

### RES-006 — `VariationBadge` formatage avec `intl`

- **Contexte** : Le format Angular est `{signe}{montant amount-pipe} {suffix} ({signe}{pct number:1.1-1}%)`. Comment formater côté Flutter ?
- **Décision** :
  - Utiliser `package:intl/intl.dart` (déjà présent dans `pubspec.yaml`).
  - `NumberFormat.currency(locale: 'fr_FR', symbol: currency ?? '€', decimalDigits: 2)` pour le montant.
  - `NumberFormat.decimalPattern('fr_FR').simpleCurrencySymbol` non — trop opaque. Plutôt :
    - Montant : `NumberFormat.currency(locale: 'fr_FR', symbol: currency ?? '€', decimalDigits: 2).format(delta.abs())` puis préfixer manuellement le signe : `delta > 0 ? '+' : '-'`.
    - Pourcentage : `NumberFormat.decimalPercentPattern(locale: 'fr_FR', decimalDigits: 1).format(percentage / 100)` — produit `12,5 %` ou via formatage explicite `'${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%'`.
  - Format final : `'$signe$montantFormatte $suffix ($pctSigne$pctValeur%)'`.
- **Justification** : intl est déjà utilisé pour le formatage monétaire ailleurs dans l'app (cf. `recent_transactions_section.dart` et autres). Cohérence patterns existants.
- **Impact sur le plan** : pas de nouvelle dépendance. Helper privé `_formatVariation(num delta, String? currency, num? percentage, String suffix)` qui retourne `String`.

---

### RES-007 — `EmptyStateWidget` CTA text-link

- **Contexte** : Le CTA Angular est un `<button>` stylé en text-link (`color: primary`, souligné au hover, fond transparent). Equivalent Flutter ?
- **Décision** :
  - `TextButton` Material avec `style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, foregroundColor: colorScheme.primary)`.
  - Souligné géré via `Text(label, style: TextStyle(decoration: TextDecoration.underline))` au tap (Flutter n'a pas de `:hover` mobile — souligné permanent acceptable).
  - Alternative : `InkWell + Text` avec `onTap` manuel — plus de boilerplate, pas de bénéfice net.
- **Justification** : `TextButton` est l'idiome Flutter pour les boutons de type lien. Le souligné permanent au lieu du hover-only n'est pas un anti-pattern sur mobile (pas de notion de hover).
- **Impact sur le plan** : pas de complication. Style `TextButton.styleFrom` à factoriser ? Pas pour 1 usage.

---

### RES-008 — `PageHeader.icon` typing

- **Contexte** : Le pattern Angular utilise `<ng-icon>` avec wrapper `.page-header__icon` (32×32 cercle `icon-circle-bg`). Côté Flutter, faut-il imposer le wrapper ou laisser le caller fournir un `Widget` libre ?
- **Options évaluées** :

| Option | Type | Avantages | Inconvénients |
|--------|------|-----------|---------------|
| A — `IconData? icon` (icône Phosphor) | `IconData?` | API simple, wrapping uniforme garanti par le composant | Limité aux icônes Phosphor, pas d'image / emoji |
| B — `Widget? icon` (libre) | `Widget?` | Flexible : icon, emoji, image | Le caller doit savoir construire le wrapper rond 32×32 |
| C — `Widget? icon` mais wrapping interne 32×32 | `Widget?` + wrap interne | Flexible + uniforme | Nécessite que le child soit centré et de la bonne taille |

- **Décision** : **Option C** — `Widget? icon` avec wrapping interne 32×32 cercle `iconCircleBg`.
- **Rationale** :
  - Couvre tous les cas (icône Phosphor, emoji string, image custom).
  - Le wrapping est imposé par le composant → garantie visuelle DESIGN.md.
  - Le caller passe juste l'enfant (ex : `Icon(PhosphorIcons.coin())` ou `Text('💰')`), le wrapper s'occupe du cercle + fond.
- **Impact sur le plan** : `PageHeader` rend interne `Container(width: 32, height: 32, decoration: BoxDecoration(color: themeExt.iconCircleBg, shape: BoxShape.circle), child: Center(child: icon!))` quand `icon != null`.

---

### RES-009 — `ListGroup` dividers internes

- **Contexte** : Angular utilise `border-bottom: 1px solid var(--border-default)` sur chaque `.list-row:not(:last-child)`. Côté Flutter ?
- **Décision** :
  - Utiliser le widget Material `Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant)`.
  - **Justification du token** : `colorScheme.outlineVariant` Material 3 = équivalent semantique de `--border-default` Angular (couleur subtile pour séparateurs).
  - Implémentation : itérer `children` et insérer `Divider` entre chaque paire — pas après le dernier. Helper privé `_intersperse<T>(List<T> items, T separator) -> List<T>`.
- **Alternative rejetée** : `Container(height: 1, color: ...)` — fonctionne mais perd la sémantique Material `Divider` (a11y, comportement par défaut).
- **Impact sur le plan** : utiliser `colorScheme.outlineVariant` cohérent dans tous les composants qui ont besoin de dividers (cf. RES-013 pour le mapping global).

---

### RES-010 — Helper `normalizeForSearch`

- **Contexte** : Recherche insensible à la casse + accents nécessaire pour `CategorySelectExpand`. Helper existant ?
- **Audit codebase** :
  - Package `diacritic: ^0.1.6` est déjà déclaré dans `flutter/pubspec.yaml:62`.
  - Utilisé dans `transaction_repository_local.dart:71` :
    ```dart
    String _normalize(String s) => removeDiacritics(s.toLowerCase());
    ```
- **Décision** :
  - **Réutiliser le helper existant**, mais le **rendre public et partagé** dans un fichier `flutter/lib/src/utils/string_utils.dart` exposant `String normalizeForSearch(String input)`.
  - Migrer `transaction_repository_local.dart` pour utiliser ce helper public (refactor secondaire de cohérence — facultatif, à intégrer dans cette feature ou différé).
- **Justification** :
  - Évite la duplication.
  - Cohérence avec le helper `normalize()` Angular (`app/src/app/shared/utils/string.utils.ts`).
  - Pas de nouvelle dépendance (`diacritic` déjà présent).
- **Impact sur le plan** : 1 nouveau fichier `string_utils.dart` (10-15 lignes). Refactor optionnel `transaction_repository_local.dart`.

---

### RES-011 — Remplacement temporaire `SegmentedFilter`

- **Contexte** : CL-006 a tranché « `FilterChip` Material 3 ». Audit complémentaire : quelle option Material 3 est la plus adaptée à un filtre **mono-sélection** (le pattern actuel `SegmentedFilter` est mono) ?
- **Options évaluées** :

| Option | Sémantique | Adapté ? |
|--------|------------|----------|
| `FilterChip` | Multi-sélection (cocher/décocher des chips indépendamment) | ❌ Sémantique fausse |
| `ChoiceChip` | Mono-sélection dans un groupe | ✅ Sémantique correcte |
| `SegmentedButton` | Segmented control mono-sélection | ❌ C'est exactement ce que DESIGN.md interdit |

- **Décision** : **`ChoiceChip`** (correction de CL-006 qui mentionnait `FilterChip` par erreur).
- **Rationale** :
  - `ChoiceChip` Material 3 = sémantique mono-sélection.
  - `FilterChip` impliquerait que plusieurs chips peuvent être actifs simultanément, ce qui n'est pas le comportement actuel de `SegmentedFilter`.
  - `SegmentedButton` serait paradoxal : on supprime un segmented control pour le remplacer par un autre.
- **Impact sur le plan** : mise à jour de FR-016 dans la spec (remplacer « FilterChip » par « ChoiceChip »). Commentaire `// TODO KKS-240` reste identique. **À documenter dans le plan comme correction explicite de CL-006**.

---

### RES-012 — Stratégie de tests dark + light

- **Contexte** : NFR-001 exige des tests couvrant rendu dark + light. Comment structurer ?
- **Options évaluées** :

| Option | Stratégie | Verbosité | Maintenabilité |
|--------|-----------|-----------|----------------|
| A — 2 tests séparés par cas | `should_render_correctly_when_dark_theme` + `should_render_correctly_when_light_theme` | Élevée (×2 tests) | OK mais duplication |
| B — Test paramétré via helper `forEachTheme` | `forEachTheme((theme) { testWidgets('...', ...) })` | Faible | Centralisé, ajout d'un thème = 1 ligne |
| C — Test golden multi-thème | `pumpWidgetWithTheme` + screenshot comparison | Couvre le pixel-perfect | Goldens fragiles, CI lourd |

- **Décision** : **Option B** — helper `forEachTheme` (ou similaire) dans un fichier `test/helpers/theme_test_helpers.dart`.
- **Rationale** :
  - Réduit la duplication (24 → 12 tests visuellement, mais chacun exécuté ×2 thèmes via paramétrage).
  - Ajout d'un thème (ex : high-contrast en future feature) = changement local au helper.
  - Golden tests trop fragiles à ce stade — réservés à une feature dédiée si besoin.
- **Impact sur le plan** :
  - Créer `flutter/test/helpers/theme_test_helpers.dart` exposant `void forEachTheme(void Function(ThemeData theme, String themeName) body)`.
  - Adapter le pattern de tests des composants pour utiliser ce helper.

---

### RES-013 — Mapping `surfaceContainer` Flutter ↔ `--surface-default` Angular (réponse INFO-01)

- **Contexte** : INFO-01 review-spec a relevé que le mapping entre tokens Flutter `colorScheme.surfaceContainer` et Angular `--surface-default` n'est pas documenté.
- **Audit `AppTheme` (post-KKS-237)** :
  - Lecture `flutter/lib/src/theme/app_theme.dart` : `colorScheme.surfaceContainerHighest = gray-700` (dark) / `gray-100` (light) → équivalent `--surface-raised` Angular.
  - `colorScheme.surfaceContainer = gray-800` (dark) / `#fff` (light) → équivalent `--surface-default` Angular.
  - `colorScheme.surface = gray-900` (dark) / `#f0f0f0` (light) → équivalent `--bg-primary` Angular.
- **Décision** : **Documenter ce mapping** dans le plan (section « Tokens » du plan), pas dans la spec (qui doit rester sur les exigences fonctionnelles).
- **Mapping confirmé** :

| Angular token | Flutter equivalent | Niveau |
|---------------|-------------------|--------|
| `--bg-primary` | `colorScheme.surface` | Fond page |
| `--surface-default` | `colorScheme.surfaceContainer` | Cards, conteneurs (= `ListGroup`, dialogs) |
| `--surface-raised` | `colorScheme.surfaceContainerHighest` | Header, sticky, FAB (= `SectionHeaderSticky.stuck`) |
| `--border-default` | `colorScheme.outlineVariant` | Dividers, borders subtiles |
| `--text-primary` | `colorScheme.onSurface` | Texte principal |
| `--text-secondary` | `colorScheme.onSurfaceVariant` | Texte secondaire |
| `--text-tertiary` | (à confirmer — `colorScheme.outline` ou `AppThemeExtension`) | Labels, hints |

- **Impact sur le plan** : section « Tokens » à inclure dans `plan.md` ; auditer les composants pour cohérence avec ce mapping.

---

### RES-014 — Méthode de vérification NFR-003 (réponse WARNING-02)

- **Contexte** : WARNING-02 review-spec a relevé que NFR-003 (« 60 fps Pixel 3a ») n'a pas de méthode de vérification.
- **Décision** :
  - **Méthode 1 (manuelle, documentée)** : Profile mode `flutter run --profile` sur émulateur Pixel 3a + DevTools Timeline. Mesurer `frameTime` lors d'un scroll continu sur un écran consommant `SectionHeaderSticky` + `ListGroup` × 50 items. Critère : `frameTime < 16.67ms` (60 fps) sur 95 % des frames.
  - **Méthode 2 (automatique, optionnelle)** : test d'intégration `flutter test integration_test/perf_test.dart` avec `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` + `binding.watchPerformance(...)`. Génère un fichier JSON avec les frame times. Mais : nécessite un appareil Android réel ou un émulateur configuré, pas réalisable en CI sans coût significatif.
- **Plan d'action** :
  - **Phase 1 (cette feature)** : méthode 1 manuelle, validée à la review-impl par un screencast + screenshot DevTools. Pas de test automatisé.
  - **Phase 2 (future feature dédiée)** : si la perf devient critique (signalée par utilisateur en commercialisation Play Store / App Store), créer un ticket de mise en place de tests perf automatisés.
- **Impact sur le plan** :
  - Mentionner la méthode de vérification dans le plan (« Vérification perf manuelle au review-impl »).
  - Ne pas bloquer la livraison sur un test perf automatisé pour cette feature.

---

## Patterns existants identifiés

Le codebase Flutter a plusieurs patterns réutilisables identifiés pendant l'audit :

| Pattern | Fichier | Réutilisation prévue |
|---------|---------|---------------------|
| Helper `_normalize(s)` (lowercase + diacritics) | `transaction_repository_local.dart:71` | Promu en helper public `normalizeForSearch` (RES-010) |
| Pattern `ConsumerStatefulWidget` avec form local + `Notifier.create/.update()` | `category_form_screen.dart` | Modèle pour `CategoryFormWidget` extrait (RES-004) |
| `AlertDialog` Material standard | `category_form_screen.dart:130` | À migrer vers `ConfirmDialogCustom` futur (hors scope cette étape) |
| Skeleton pulse via package `shimmer` | `category_list_skeleton.dart` | Pattern pour `EmptyStateWidget` mode loading ? Non — `EmptyStateWidget` est rendu après chargement, pas pendant |
| `ConsumerWidget` + `ref.watch` lecture state | tout le codebase | Pas applicable aux composants shared (purs UI sans Riverpod) |

---

## Dépendances techniques

| Dépendance | Version | Usage prévu | Risque |
|------------|---------|-------------|--------|
| `flutter` (SDK) | ≥ 3.6 | Material 3, Slivers, `showDialog`, `AnimatedContainer` | Aucun — déjà en place |
| `flutter_riverpod` | déjà présent | `CategoryFormWidget` (lecture `categoryNotifierProvider`) | Aucun |
| `phosphor_flutter` | déjà présent | Icônes (back arrow, X, Check, Trash, calendar nav, etc.) | Aucun |
| `intl` | déjà présent | `VariationBadge` formatage monétaire et pourcentage | Aucun |
| `diacritic` | déjà présent (^0.1.6) | Helper `normalizeForSearch` (RES-010) | Aucun |
| **Aucune nouvelle dépendance** | — | — | Conforme NFR-005 |

---

## Réponses aux INFO et WARNING reportés du review-spec

| Constat | Disposition | Référence research |
|---------|-------------|-------------------|
| WARNING-02 | Méthode de vérification NFR-003 documentée (manuelle phase 1, automatique différé) | RES-014 |
| WARNING-03 | FR-015/FR-016 sans US — accepté en cleanup transversal, à confirmer en review-tasks | (hors research, pas de décision technique) |
| WARNING-04 | SC-012 portée 8 → 9 fichiers (inclure `CategoryFormWidget`) | À corriger au plan |
| WARNING-06 | Animation 300ms `SectionHeaderSticky` non testée widget — mention dans plan | RES-001 (hauteur fixe + AnimatedContainer) |
| INFO-01 | Mapping `surfaceContainer` Flutter ↔ Angular | RES-013 |
| INFO-02 | Contrat `submit()` de `CategoryFormWidget` | RES-004 (« Comportement clé ») |
| INFO-03 | NFR-007 back button Android — `InlineDatePicker` inline pas concerné | À corriger au plan (NFR-007 ne concerne que `ConfirmDialogCustom`) |
| INFO-04 | Parallélisme FR-004/FR-005 vs FR-019 | RES-004 (extraction first → CategorySelectExpand) ; A-003 cohérent |
| INFO-05 | Constitution VI `print()` interdit | À ajouter en NFR-008 au plan ; convention globale `pre-commit-review` la couvre déjà |

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Inconnues identifiées | 14 |
| Décisions prises | 14 (RES-001 à RES-014) |
| Nouvelles dépendances | **0** (conforme NFR-005) |
| Patterns réutilisés | 4 (`_normalize`, `ConsumerStatefulWidget` form, intl, AppThemeExtension KKS-237) |
| Composants visiblement bloquants pour le plan | 0 — toutes les inconnues techniques résolues |
| Constats review-spec adressés | 6/8 dans le research (2 sont à corriger directement au plan : WARNING-04, INFO-03) |
