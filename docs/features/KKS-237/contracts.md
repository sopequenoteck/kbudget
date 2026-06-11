# Contrats techniques — KKS-237 : Refonte tokens design Flutter (palette propriétaire v5)

> Date : 2026-05-03
> Issue : [KKS-237](https://linear.app/kksdev/issue/KKS-237/phase-1-etape-1-refonte-tokens-design-flutter-palette-proprietaire)
> Plan : [plan.md](./plan.md)

> **Note** : cette feature ne touche pas d'API REST ni de composants UI nouveaux. Les contrats documentés ici sont les **signatures publiques Dart** des classes de tokens et du thème Flutter. Les sections "API Endpoints", "Contrats composants UI" et "Contrats services" sont sans objet.

---

## Interfaces & Types — Classes Dart publiques

### `AppColors` (couche primitive + sémantique)

> Réf : FR-001, FR-002, FR-003, FR-004, FR-005, FR-009, FR-010, FR-011, FR-012b/c/d

```dart
final class AppColors {
  AppColors._(); // Constructeur privé — instanciation interdite

  // ===== Palette gris propriétaire =====
  static const Color gray50  = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE5E5E5);
  static const Color gray300 = Color(0xFFD4D4D4);
  static const Color gray400 = Color(0xFFA3A3A3);
  static const Color gray500 = Color(0xFF737373);
  static const Color gray600 = Color(0xFF525252);
  static const Color gray700 = Color(0xFF1E1E1E);
  static const Color gray800 = Color(0xFF141414);
  static const Color gray900 = Color(0xFF0A0A0A);

  // ===== Palettes amber / violet / indigo / feedback Tailwind =====
  // (inchangées — conservation conforme `_primitives.scss`)
  static const Color amber50  = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  // ... (amber200..amber900)
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);

  static const Color violet400 = Color(0xFFA78BFA);
  static const Color violet500 = Color(0xFF8B5CF6);

  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo600 = Color(0xFF4F46E5);
  // ... (autres indigo conservés)

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // ===== Sémantique dark — business (mises à jour) =====
  /// Income color for dark theme. Custom value — was #4ADE80 (green-400 Tailwind).
  /// Source: app/src/styles/themes/_dark.scss `--color-income: #6dc990`.
  static const Color incomeDark        = Color(0xFF6DC990);
  /// Expense color for dark theme. Custom value — was #F87171.
  static const Color expenseDark       = Color(0xFFD97777);
  /// Subscription color for dark theme. Custom value — was #A78BFA.
  static const Color subscriptionDark  = Color(0xFF9580D9);
  static const Color debtOweDark       = Color(0xFFD97777); // alias expenseDark
  static const Color debtOwedDark      = Color(0xFF6DC990); // alias incomeDark

  // ===== Sémantique dark — primary =====
  /// Primary amber semantic value for dark theme. Not derived from amber-* palette.
  /// Source: app/src/styles/themes/_dark.scss `--color-primary: #e0a820`.
  static const Color primaryAmberDark      = Color(0xFFE0A820);
  static const Color primaryAmberHoverDark = Color(0xFFC9952A);

  // ===== Sémantique dark — feedback =====
  static const Color textWarningDark = Color(0xFFD4AD3C);
  static const Color textInfoDark    = Color(0xFF7AACDB);

  // ===== Sémantique dark — interactifs =====
  static const Color primarySubtleDark   = Color(0x1AE0A820); // rgba(224,168,32,0.10)
  static const Color primaryMutedDark    = Color(0x26E0A820); // rgba(224,168,32,0.15)
  static const Color primaryBorderDark   = Color(0x40E0A820); // rgba(224,168,32,0.25)
  static const Color hoverBgDark         = gray700;
  static const Color hoverSubtleDark     = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)
  static const Color highlightSubtleDark = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const Color overlayLightDark    = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
  static const Color focusRingDark       = Color(0x80FBBF24); // rgba(amber-400, 0.5)
  static const Color iconCircleBgDark    = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)

  // ===== Sémantique light — business (existantes, inchangées) =====
  static const Color incomeLight       = Color(0xFF16A34A);
  static const Color expenseLight      = Color(0xFFDC2626);
  static const Color subscriptionLight = Color(0xFF8B5CF6);
  static const Color debtOweLight      = Color(0xFFDC2626);
  static const Color debtOwedLight     = Color(0xFF16A34A);

  // ===== Sémantique light — feedback =====
  static const Color textWarningLight = Color(0xFFCA8A04);
  static const Color textInfoLight    = Color(0xFF2563EB);

  // ===== Sémantique light — interactifs =====
  static const Color primarySubtleLight   = Color(0x1AD97706); // rgba(amber-600, 0.10)
  static const Color primaryMutedLight    = Color(0x26D97706);
  static const Color primaryBorderLight   = Color(0x40D97706);
  static const Color hoverBgLight         = gray100;
  static const Color hoverSubtleLight     = Color(0x0A000000); // rgba(0,0,0,0.04)
  static const Color highlightSubtleLight = Color(0x0F000000); // rgba(0,0,0,0.06)
  static const Color overlayLightLight    = Color(0x1A000000); // rgba(0,0,0,0.10)
  static const Color focusRingLight       = Color(0x80F59E0B); // rgba(amber-500, 0.5)
  static const Color iconCircleBgLight    = Color(0x0A000000);
}
```

**Invariants** :
- Aucune valeur Tailwind gray Tailwind résiduelle (FR-005, SC-001).
- Toutes les valeurs hex correspondent exactement à `_primitives.scss` (primitives) et `_dark.scss` / `_light.scss` (sémantiques).
- `static const` partout — instances immuables, utilisables dans `const` widgets.
- Constructeur privé `_()` — pas d'instanciation possible.

---

### `AppTypography`

> Réf : FR-013, FR-014, FR-015

```dart
final class AppTypography {
  AppTypography._();

  // ===== Tailles existantes (inchangées) =====
  static const double sizeXs   = 12.0;
  static const double sizeSm   = 14.0;
  static const double sizeMd   = 16.0;  // base
  static const double sizeLg   = 18.0;
  static const double sizeXl   = 20.0;
  static const double size2xl  = 24.0;
  static const double size3xl  = 30.0;

  // ===== Nouvelles tailles =====
  /// Extra-extra-small font size — for uppercase labels.
  /// Source: `_primitives.scss` `--font-size-2xs: 0.625rem`.
  static const double size2Xs = 10.0;

  /// Hero font size — for patrimony amount on dashboard.
  /// Source: `_dark.scss` `--font-size-hero: 2.25rem`.
  static const double sizeHero = 36.0;

  // ===== Poids (inchangés) =====
  static const FontWeight regular  = FontWeight.w400;
  static const FontWeight medium   = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold     = FontWeight.w700;

  // ===== Letter-spacing pour labels uppercase =====
  /// Multiplicative factor for uppercase label letter-spacing (CSS `letter-spacing: 0.05em` equivalent).
  /// Usage: `Text(label, style: TextStyle(fontSize: size, letterSpacing: size * AppTypography.labelLetterSpacingFactor))`.
  static const double labelLetterSpacingFactor = 0.05;

  /// Pre-computed for `size2Xs` (10px).
  static const double labelLetterSpacingForSize10 = 0.5;
  /// Pre-computed for `sizeXs` (12px).
  static const double labelLetterSpacingForSize12 = 0.6;
  /// Pre-computed for `sizeSm` (14px).
  static const double labelLetterSpacingForSize14 = 0.7;
}
```

**Invariants** :
- Toutes valeurs `static const`.
- Le facteur dynamique × taille = letter-spacing absolu en logical pixels.

---

### `AppShadows`

> Réf : FR-016, FR-017, FR-018, FR-019

```dart
final class AppShadows {
  AppShadows._();

  // ===== sm (inchangé) =====
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  // ===== md (REFONTE — double-layer) =====
  /// Source: `_primitives.scss` `$shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)`.
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 6, spreadRadius: -1, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, spreadRadius: -2, offset: Offset(0, 2)),
  ];

  // ===== lg (REFONTE — double-layer) =====
  /// Source: `_primitives.scss` `$shadow-lg`.
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 15, spreadRadius: -3, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 6,  spreadRadius: -4, offset: Offset(0, 4)),
  ];

  // ===== coloredPrimary — brightness-aware =====
  /// Colored shadow for dark theme — neutral black (cf. `_dark.scss` `--shadow-colored-primary: rgb(0 0 0 / 0.4)`).
  static const List<BoxShadow> coloredPrimaryDark = [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, spreadRadius: -4, offset: Offset(0, 8)),
  ];

  /// Colored shadow for light theme — amber glow (cf. `_primitives.scss` `$shadow-colored-primary: rgb(245 158 11 / 0.4)`).
  static const List<BoxShadow> coloredPrimaryLight = [
    BoxShadow(color: Color(0x66F59E0B), blurRadius: 24, spreadRadius: -4, offset: Offset(0, 8)),
  ];

  /// Returns the brightness-appropriate primary colored shadow.
  /// Use `Theme.of(context).brightness` as argument when needing it dynamically.
  static List<BoxShadow> coloredPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? coloredPrimaryDark : coloredPrimaryLight;

  // ===== DEPRECATED API =====
  @Deprecated(
    'Utiliser AppShadows.coloredPrimary(brightness) ou les constantes '
    'coloredPrimaryDark/Light. Cette API sera supprimée en KKS-240+.',
  )
  static List<BoxShadow> colored(Color color, {int alpha = 102}) => [
    BoxShadow(
      color: color.withAlpha(alpha),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];
}
```

**Invariants** :
- `sm`, `md`, `lg`, `coloredPrimaryDark`, `coloredPrimaryLight` sont `const List<BoxShadow>` — utilisables dans `const BoxDecoration`.
- `coloredPrimary(Brightness)` retourne une référence à la constante existante (pas d'allocation).
- L'ancienne API `colored()` reste fonctionnelle et marquée `@Deprecated`.

---

### `AppThemeExtension extends ThemeExtension<AppThemeExtension>`

> Réf : FR-009, FR-010, FR-011, FR-012b/c/d, FR-022

```dart
final class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    // ===== Existantes (conservées — pas de breaking change) =====
    required this.incomeColor,
    required this.expenseColor,
    required this.debtOweColor,
    required this.debtOwedColor,
    required this.subscriptionColor,
    required this.secondaryColor,
    // ===== Nouvelles — feedback =====
    required this.textWarning,
    required this.textInfo,
    // ===== Nouvelles — interactifs =====
    required this.primarySubtle,
    required this.primaryMuted,
    required this.primaryBorder,
    required this.hoverSubtle,
    required this.highlightSubtle,
    required this.overlayLight,
    required this.focusRing,
    required this.iconCircleBg,
  });

  // Existantes (compatibilité 14+ widgets consommateurs)
  final Color incomeColor;
  final Color expenseColor;
  final Color debtOweColor;
  final Color debtOwedColor;
  final Color subscriptionColor;
  final Color secondaryColor;

  // Nouvelles
  final Color textWarning;
  final Color textInfo;
  final Color primarySubtle;
  final Color primaryMuted;
  final Color primaryBorder;
  final Color hoverSubtle;
  final Color highlightSubtle;
  final Color overlayLight;
  final Color focusRing;
  final Color iconCircleBg;

  // ===== Instances statiques =====
  static const AppThemeExtension light = AppThemeExtension(
    incomeColor: AppColors.incomeLight,
    expenseColor: AppColors.expenseLight,
    debtOweColor: AppColors.debtOweLight,
    debtOwedColor: AppColors.debtOwedLight,
    subscriptionColor: AppColors.subscriptionLight,
    secondaryColor: AppColors.indigo600,
    textWarning: AppColors.textWarningLight,
    textInfo: AppColors.textInfoLight,
    primarySubtle: AppColors.primarySubtleLight,
    primaryMuted: AppColors.primaryMutedLight,
    primaryBorder: AppColors.primaryBorderLight,
    hoverSubtle: AppColors.hoverSubtleLight,
    highlightSubtle: AppColors.highlightSubtleLight,
    overlayLight: AppColors.overlayLightLight,
    focusRing: AppColors.focusRingLight,
    iconCircleBg: AppColors.iconCircleBgLight,
  );

  static const AppThemeExtension dark = AppThemeExtension(
    incomeColor: AppColors.incomeDark,
    expenseColor: AppColors.expenseDark,
    debtOweColor: AppColors.debtOweDark,
    debtOwedColor: AppColors.debtOwedDark,
    subscriptionColor: AppColors.subscriptionDark,
    secondaryColor: AppColors.indigo400,
    textWarning: AppColors.textWarningDark,
    textInfo: AppColors.textInfoDark,
    primarySubtle: AppColors.primarySubtleDark,
    primaryMuted: AppColors.primaryMutedDark,
    primaryBorder: AppColors.primaryBorderDark,
    hoverSubtle: AppColors.hoverSubtleDark,
    highlightSubtle: AppColors.highlightSubtleDark,
    overlayLight: AppColors.overlayLightDark,
    focusRing: AppColors.focusRingDark,
    iconCircleBg: AppColors.iconCircleBgDark,
  );

  // ===== Méthodes ThemeExtension =====
  @override
  AppThemeExtension copyWith({
    Color? incomeColor, Color? expenseColor, Color? debtOweColor,
    Color? debtOwedColor, Color? subscriptionColor, Color? secondaryColor,
    Color? textWarning, Color? textInfo,
    Color? primarySubtle, Color? primaryMuted, Color? primaryBorder,
    Color? hoverSubtle, Color? highlightSubtle, Color? overlayLight,
    Color? focusRing, Color? iconCircleBg,
  }) => AppThemeExtension(
    incomeColor: incomeColor ?? this.incomeColor,
    // ... (16 propriétés)
  );

  @override
  AppThemeExtension lerp(covariant AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      incomeColor: Color.lerp(incomeColor, other.incomeColor, t)!,
      // ... (16 propriétés via Color.lerp)
    );
  }
}
```

**Invariants** :
- **Compatibilité backward** : les 6 propriétés existantes (`incomeColor`, `expenseColor`, `debtOweColor`, `debtOwedColor`, `subscriptionColor`, `secondaryColor`) sont conservées avec leurs noms et types. Les 14+ widgets consommateurs ne cassent pas.
- Toutes les propriétés sont `final Color` — immuabilité.
- `copyWith()` accepte des `Color?` optionnels pour chaque propriété.
- `lerp()` retourne `this` si `other` est null ou d'un autre type.
- `Color.lerp()` natif gère correctement l'interpolation alpha (RES-004).

---

### `AppTheme`

> Réf : FR-006, FR-007, FR-008, FR-012a, FR-020

```dart
final class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.amber600,                    // #d97706
      onPrimary: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      surfaceContainerHighest: AppColors.gray100,     // #f5f5f5
      // ... autres champs colorScheme
    ),
    extensions: const <ThemeExtension<dynamic>>[
      AppThemeExtension.light,
    ],
    // ... selectedItemColor, FAB.backgroundColor, focused border, etc.
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryAmberDark,            // #e0a820 (NEW — était amber400)
      onPrimary: AppColors.gray900,                   // #0a0a0a
      surface: AppColors.gray800,                     // #141414 (NEW — était gray-800 Tailwind)
      surfaceContainerHighest: AppColors.gray700,     // #1e1e1e
      surfaceContainer: AppColors.gray800,
      background: AppColors.gray900,                  // #0a0a0a
      // ... autres champs colorScheme
    ),
    extensions: const <ThemeExtension<dynamic>>[
      AppThemeExtension.dark,
    ],
    // ... selectedItemColor: primaryAmberDark, FAB.backgroundColor: primaryAmberDark, etc.
  );
}
```

**Invariants** :
- `useMaterial3: true` activé sur les deux thèmes.
- `AppThemeExtension` injectée via `extensions:` dans chaque thème.
- Les 14+ usages `AppColors.amber*` dans le `app_theme.dart` actuel sont audités ligne par ligne (RES-005) :
  - Usage **primary semantic** (boutons, FAB, selectedItem, focused border) → migré vers `primaryAmberDark` en dark / conservé `amber600` en light.
  - Usage **palette structurelle** (`primaryContainer`, `onPrimaryContainer`) → conservé si pertinent ou migré selon contexte.

---

### `PatrimoineCard` (annotation `@Deprecated`)

> Réf : FR-021

```dart
@Deprecated(
  'Gradient décoratif interdit en dark v5 — refonte hero flat dans KKS-240. '
  'Token Angular équivalent neutralisé : --hero-gradient: none.',
)
class PatrimoineCard extends ConsumerWidget {
  const PatrimoineCard({super.key, /* ... */});

  // Aucune modification du body — annotation seulement.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... gradient existant inchangé jusqu'à KKS-240
  }
}
```

**Invariants** :
- L'annotation `@Deprecated` est sur la **classe entière** (RES-007).
- Le widget reste fonctionnel — l'annotation ne change pas le comportement, juste l'avertissement IDE.
- Les usages existants compilent toujours avec un warning Dart.

---

## API Endpoints

> **Sans objet**. Cette feature ne touche aucune API REST. Mode standalone Flutter (Constitution Trajectoire B).

---

## Contrats composants UI

> **Sans objet**. Cette feature ne crée pas de nouveau composant UI. Elle modifie des classes utilitaires (tokens) et le thème, ainsi qu'un seul widget existant (`PatrimoineCard`) via annotation `@Deprecated` sans modification de comportement.

---

## Contrats services

> **Sans objet**. Cette feature ne touche aucun service applicatif (pas de Notifier, pas de Repository, pas de Use Case).

---

## Contrats de compatibilité backward

### Compatibilité `AppThemeExtension` avec les 14+ widgets consommateurs

Les widgets suivants consomment `Theme.of(context).extension<AppThemeExtension>()` et accèdent aux 6 propriétés existantes. **Ces accès DOIVENT continuer de fonctionner après la refonte** :

| Fichier | Propriétés consommées |
|---------|----------------------|
| `flutter/lib/src/features/dashboard/presentation/widgets/income_expense_cards.dart` | `incomeColor`, `expenseColor` |
| `flutter/lib/src/features/dashboard/presentation/widgets/recent_transactions_section.dart` | (à confirmer dans l'audit) |
| `flutter/lib/src/features/transactions/presentation/widgets/transaction_summary_card.dart` | `incomeColor`, `expenseColor` |
| `flutter/lib/src/features/transactions/presentation/widgets/transaction_day_group.dart` | `incomeColor`, `expenseColor` |
| `flutter/lib/src/features/debts/presentation/debt_list_screen.dart` | `debtOweColor`, `debtOwedColor` |
| `flutter/lib/src/features/debts/presentation/debt_detail_screen.dart` | idem |
| `flutter/lib/src/features/subscriptions/presentation/subscription_detail_screen.dart` | `subscriptionColor` |
| `flutter/lib/src/utils/amount_formatter.dart` | `incomeColor`, `expenseColor` |

**Garantie** : aucune des 6 propriétés existantes n'est renommée, supprimée ou changée de type. Les valeurs sont mises à jour (`incomeDark = #6dc990` au lieu de `#4ADE80`) — les widgets reçoivent les nouvelles valeurs automatiquement.

### Compatibilité `AppColors.amber*` dans le code Flutter

Les primitives `AppColors.amber500`, `amber400`, `amber600`, `amber100`, `amber900` etc. **restent disponibles avec leurs valeurs Tailwind inchangées** (FR-002). Les widgets qui les consomment continuent de fonctionner.

Cependant, certains usages dans `app_theme.dart` sont reclassés sémantiquement (ex : `primary: AppColors.amber400` → `primary: AppColors.primaryAmberDark`). Cela ne casse pas l'API : l'ancienne constante existe toujours, simplement le thème pointe vers une nouvelle constante.

### Compatibilité `AppShadows.colored()`

L'ancienne API `AppShadows.colored(Color, {alpha})` est **conservée** mais marquée `@Deprecated`. Les usages existants (s'il y en a — à confirmer par audit) compilent avec un warning. Migration recommandée vers `AppShadows.coloredPrimary(brightness)` ou les constantes statiques.

---

## Résumé

| Type | Nombre |
|------|--------|
| Classes Dart documentées | 6 (`AppColors`, `AppTypography`, `AppShadows`, `AppThemeExtension`, `AppTheme`, `PatrimoineCard` annotation) |
| Constantes publiques nouvelles dans `AppColors` | ~22 (5 sémantiques dark mises à jour + 12 nouvelles dark + ~10 nouvelles light) |
| Constantes publiques nouvelles dans `AppTypography` | 5 (`size2Xs`, `sizeHero`, `labelLetterSpacingFactor`, 3 pré-calculées) |
| Constantes publiques nouvelles dans `AppShadows` | 3 (`coloredPrimaryDark`, `coloredPrimaryLight`, `coloredPrimary(Brightness)`) |
| Propriétés nouvelles dans `AppThemeExtension` | 10 (`textWarning`, `textInfo`, `primarySubtle`, `primaryMuted`, `primaryBorder`, `hoverSubtle`, `highlightSubtle`, `overlayLight`, `focusRing`, `iconCircleBg`) |
| API Deprecated | 1 (`AppShadows.colored(Color, {alpha})`) |
| Annotations `@Deprecated` widgets | 1 (`PatrimoineCard`) |
| API REST endpoints | 0 (sans objet) |
| Contrats UI nouveaux | 0 (sans objet) |
| Contrats services | 0 (sans objet) |
| FR couverts | 23 (tous les FR de la spec) |
| Compatibilité backward | Garantie sur les 6 propriétés `AppThemeExtension` existantes et toutes les primitives `AppColors.amber*` |
