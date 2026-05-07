# Spec — KKS-238 : Phase 1 / Étape 2 — Composants shared Flutter (8 widgets)

> Date : 2026-05-03
> Issue : [KKS-238](https://linear.app/kksdev/issue/KKS-238/phase-1-etape-2-composants-shared-flutter-8-widgets)
> Issue parent : [KKS-236](https://linear.app/kksdev/issue/KKS-236/phase-1-refonte-design-flutter-v5)
> Feature Branch : `feature/flutter-shared-components-v5`
> Priorité : High (P2 Linear)
> Estimation : 5 points (~40h, M+)
> Labels : Feature
> Statut : Draft

---

## Contexte

KKS-237 a aligné les **tokens design** Flutter sur la palette propriétaire Angular v5 (`AppColors`, `AppTypography`, `AppShadows`, `AppThemeExtension` étendu à 16 propriétés). Les écrans Flutter consomment maintenant les bons tokens, mais ils n'ont **pas encore les composants shared** qui matérialisent les patterns visuels Angular v5 (`DESIGN.md` § Patterns). Étape 2 = créer ces composants en amont des refontes d'écrans (Étape 4 listes, Étape 5 formulaires).

### Inventaire des 8 composants à créer

| # | Composant Flutter | Source Angular | Pattern DESIGN.md | Bloque |
|---|-------------------|----------------|-------------------|--------|
| 1 | `SectionHeaderSticky` | `.section-header.stuck` (`_list-patterns.scss`) | "Section header (sticky)" | Étape 4 (écrans listes) |
| 2 | `ListGroup` | `.list-group` (`_list-patterns.scss`) | "Liste groupee" | Étape 4 (écrans listes) |
| 3 | `EmptyStateWidget` | `<app-empty-state>` | "Empty state" | Étape 4 (états vides listes) |
| 4 | `VariationBadge` | "Variation Badges" (DESIGN.md) | Pill +montant | Étape 4 (résumés mensuels) |
| 5 | `PageHeader` | `.page-header` (`_list-patterns.scss`) | "Page header (sous-pages)" | Étape 4 (sous-pages) |
| 6 | `ConfirmDialogCustom` | `<app-confirm-dialog>` + `ConfirmService` | "Confirm dialog" | Étape 4 + Étape 5 (12 sites d'appel actuels) |
| 7 | `InlineDatePicker` | `<app-inline-date-picker>` | "Bottom sheet expand" | Étape 5 (formulaires bottom sheets) |
| 8 | `CategorySelectExpand` | `<app-category-select>` (KKS-231) | "Category Select (inline expand)" | Étape 5 (formulaires bottom sheets) |

### Décisions structurantes (Phase 0, sparring 2026-05-03)

- **Périmètre limité aux composants shared** : aucun écran refait. Les sites d'appel actuels restent inchangés sauf si la suppression de l'ancien composant est triviale (ex : `SegmentedFilter` — décidé en sparring : à supprimer dans cette étape, deux usages seulement, à remplacer par groupement + sections dans Étape 4).
- **Suppression `SegmentedFilter`** : 2 sites consommateurs (`debt_list_screen.dart`, `subscription_list_screen.dart`) — à décommissionner ici (suppression du fichier + retrait des imports + simplification temporaire des 2 écrans concernés ; refonte propre dans Étape 4).
- **Constitution v3.0.0 — Trajectoire B (Flutter standalone commercial)** : tous les composants doivent fonctionner offline (pas de dépendance réseau).
- **Pas de Material Date Picker / showDialog Material par défaut** : `InlineDatePicker` et `ConfirmDialogCustom` remplacent ces patterns Material, conformément à DESIGN.md (anti-patterns : `<input type="date">` natif, second sheet empilé).
- **Lib-first** : tous les composants vont dans `flutter/lib/src/common_widgets/` (convention existante). Aucun déplacement vers un futur package séparé dans cette étape.

### Ne fait PAS partie du périmètre

- Refonte d'écrans (Étape 4-7).
- Refactoring des sites d'appel actuels de `showDialog` (12 fichiers) : ils continueront à utiliser `showDialog` Material dans cette étape, et seront migrés progressivement dans Étape 4-5 quand les écrans sont refaits.
- BottomSheet à 4 lignes (Étape 3 — KKS-239 séparée).
- Onboarding (Étape 8).
- Tokens additionnels : tous les tokens nécessaires (`AppThemeExtension` avec 16 props, `AppShadows`, `AppColors`, `AppTypography`) ont été livrés dans KKS-237.

### Audit comparatif Angular effectué

Audit complet des 8 composants Angular sources réalisé le 2026-05-07 avant gel de la spec, suite à la découverte que la décision initiale CL-002 (`CalendarDatePicker` Material) était fondée sur des hypothèses non vérifiées. Sources consultées :

- `app/src/app/shared/components/inline-date-picker/` — pattern visuel + concept `originalValue` (pour US-001)
- `app/src/app/shared/components/category-select/` — embed `<app-category-form>`, ControlValueAccessor (pour US-002)
- `app/src/styles/_list-patterns.scss` — `.section-header.stuck`, `.list-group`, `.page-header` (pour US-003 / US-004 / US-005)
- `app/src/app/shared/components/empty-state/` — paramètres `message`/`hint`, CTA text-link (pour US-006)
- `app/src/app/shared/components/confirm-dialog/` + `app/src/app/core/services/confirm.service.ts` — overlay global piloté par service signal-based (pour US-007)
- `app/src/app/features/dashboard/dashboard.scss` + `dashboard.html` — `.variation-badge` texte coloré conditionnel (pour US-008)
- `app/src/app/features/debts/debts.ts` — pattern `IntersectionObserver` + sentinel pour le sticky (pour US-003)
- `app/src/app/core/models/category.model.ts` — typing `Category.id: string` (pour FR-004)

Écarts détectés et corrigés directement dans cette spec : InlineDatePicker custom (non Material), `originalValue` ajouté, CategorySelectExpand composite stateful (non dumb), extraction `CategoryFormWidget` (FR-019), VariationBadge texte (pas pill) avec masquage conditionnel, EmptyState `message`/`hint` (pas `title`/`subtitle`), CTA text-link (pas bouton plein), PageHeader titre flex-end + icône métier optionnelle + pas de trailing, typing `Category.id: String`.

---

## User Stories

### P1 — Critiques (bloquantes Étape 4 et Étape 5)

#### US-001 — InlineDatePicker (sélecteur de date inline pour bottom sheets)

En tant qu'utilisateur saisissant une transaction / abonnement / dette dans un bottom sheet, je veux choisir une date via un calendrier intégré au sheet (pas un second dialog Material), afin que la saisie reste à un seul niveau de surface modale (DESIGN.md principe #4).

- **Why this priority** : Bloquant Étape 5 (refonte formulaires bottom sheets). Sans `InlineDatePicker`, tous les formulaires continueraient à appeler `showDatePicker()` Material, ce qui empile un second dialog au-dessus du bottom sheet — violation directe de DESIGN.md anti-pattern « `<input type="date">` natif » et du principe « un seul niveau de surface modale ».
- **Given** un bottom sheet de transaction ouvert avec un champ date pill, **when** l'utilisateur tape sur la pill, **then** le picker se déploie inline dans le sheet (zone `bsheet__expand`), pas en overlay.
- **Independent Test** : créer un widget test `InlineDatePicker` dans un `Scaffold` minimal, vérifier que la sélection d'un jour émet `onChanged(String iso)` et que la navigation mois précédent / suivant fonctionne. Pas de dépendance bottom sheet.

> **Décision technique (clarify CL-002 — révisée après audit Angular `<app-inline-date-picker>`)** : **réimplémentation custom Flutter**. Le composant Angular est 100% custom (~400 lignes : 196 TS + 49 HTML + 156 SCSS) et ne peut **pas** être reproduit avec `CalendarDatePicker` Material 3 ni `DatePickerThemeData` (cellules cercle vs carré Material, headers `L M M J V S D` 1 lettre, label mois cliquable = goToToday vs popup année Material, et **concept `originalValue`** — cellule mise en valeur discrètement pour visualiser l'écart entre date initiale et nouvelle sélection en mode édition — inexistant en Material).
>
> **Pattern visuel à reproduire** (cf. `app/src/app/shared/components/inline-date-picker/`) :
> - Header : `[‹ 28×28 rond] [Mai 2026 cliquable → goToToday] [› 28×28 rond]`
> - Grille 7 colonnes, gap 2px, headers de jours `L M M J V S D` (28px height, `text-tertiary` xs)
> - Cellules jours 36×36 **cercle complet** (`radius-round`), tap → `selectDay()`
> - Jour sélectionné : cercle plein `colorScheme.primary` + texte inverse semibold
> - Aujourd'hui : cercle outline 1px `border-default`, fond transparent
> - Original (mode édition) : cellule en `hover-subtle` discret pour visualiser l'écart
> - Hors-mois : `opacity 0.3`, non-tappable
> - Disabled (min/max) : `opacity 0.3`, non-tappable
>
> **Format date** : `String` ISO (`'2026-05-07'`) — cohérence cross-stack avec Angular et évite les dérives timezone. Conversion vers `DateTime` Dart à la charge des consommateurs.
> **Lundi-first** hardcodé.

#### US-002 — CategorySelectExpand (sélecteur catégorie inline)

En tant qu'utilisateur choisissant une catégorie dans un formulaire transaction / abonnement / dette, je veux la sélectionner inline (pas via un second sheet ni un overlay), avec recherche insensible à la casse / accents et création inline si la catégorie n'existe pas, afin de finaliser la saisie en ≤ 30s (Constitution Principe IV — Mobile-First UX).

- **Why this priority** : Bloquant Étape 5. Le pattern Angular `<app-category-select>` (KKS-231) a explicitement remplacé l'ancien `app-category-picker` qui empilait un second sheet — Flutter doit suivre. Sans ce composant, les formulaires Flutter resteront sur l'ancien `category_picker.dart` qui ouvre un second screen.
- **Given** un bottom sheet transaction avec section `expandedSection = 'category'` activée, **when** l'utilisateur tape « cour », **then** la liste filtre les catégories matchant (ex : « Courses ») et propose `+ Créer « cour »` si aucune ne match.
- **Independent Test** : injecter une liste statique de catégories dans un `CategorySelectExpand` rendu dans un `Scaffold`, taper un terme dans le champ recherche, vérifier le filtrage et l'émission de `onSelected(categoryId)` au tap d'une option matching. Le tap sur `+ Créer « terme »` bascule en mode `'create'` (vérifier l'apparition du `CategoryFormWidget` embedded), pas l'émission directe de `onCreated` — cette dernière intervient uniquement après validation du sous-formulaire.

> **Décision technique (clarify CL-003 — révisée après audit Angular `<app-category-select>`)** : **composite stateful avec embed `CategoryFormWidget`** en mode création (Option A — alignée Angular). Le composant Angular n'est **pas** dumb : il importe et embed `<app-category-form>` complet en mode création.
>
> **Architecture Flutter** :
> - `CategorySelectExpand` est un `StatefulWidget` à 2 modes : `'list'` / `'create'`
> - Mode `'list'` : champ recherche + listbox + bouton `+ Créer « terme »` quand pas de match exact
> - Mode `'create'` : header `[← Retour] [✓ Créer]` + embed `CategoryFormWidget`
> - Inputs : `categories: List<Category>`, `selectedId: String?`, `searchPlaceholder: String?`
> - Outputs : `onSelected: ValueChanged<String>` (id Category), `onCreated: ValueChanged<Category>` (objet complet retourné par `CategoryFormWidget` après save), `onCreatingChanged: ValueChanged<bool>?` (notifie le parent du basculement de mode pour désactiver le footer du sheet)
> - Recherche conservée au retour mode création (cohérence Angular)
> - Reset au `dispose()` : retour mode `'list'` (cohérence `ngOnDestroy` Angular)
>
> **Dépendance interne** : nécessite l'extraction d'un `CategoryFormWidget` réutilisable depuis `flutter/lib/src/features/categories/presentation/screens/category_form_screen.dart` (actuellement c'est un Scaffold complet, pas un widget embeddable). **Cette extraction fait partie du périmètre de KKS-238** (cf. FR-019 nouveau).

#### US-003 — SectionHeaderSticky (en-tête sticky avec fond dynamique au scroll)

En tant qu'utilisateur scrollant une liste (transactions, abonnements, dettes), je veux que l'en-tête de section reste visible en haut (sticky) avec un fond `surface-raised` qui apparaît dès que le header se colle, afin de garder le contexte de section + accéder aux actions (compteur, filtre).

- **Why this priority** : Bloquant Étape 4 (refonte écrans listes — pattern central). Le pattern Angular `.section-header.stuck` (`_list-patterns.scss`) repose sur un `IntersectionObserver` qui détecte le « stuck ». Le pattern le plus complexe des 8 — à prototyper en premier.
- **Given** une liste scrollable contenant un `SectionHeaderSticky` placé après un hero, **when** l'utilisateur scrolle vers le bas et que le header atteint le top, **then** son fond passe de transparent à `surface-raised` (gray-700 dark / gray-100 light) avec une transition douce.
- **Independent Test** : `widget test` qui place `SectionHeaderSticky` dans un `CustomScrollView`, simule un scroll programmatique via `tester.drag()`, et vérifie que le fond du header devient `surfaceContainerHighest` quand `shrinkOffset > 0`.

> **Décision technique (clarify CL-001)** : `SliverPersistentHeader` avec `pinned: true`. Le delegate expose `(BuildContext context, double shrinkOffset, bool overlapsContent)`. Bascule `Colors.transparent` → `colorScheme.surfaceContainerHighest` quand `shrinkOffset > 0`, animée via `AnimatedContainer` (300 ms).

#### US-004 — ListGroup (conteneur arrondi avec dividers internes)

En tant que développeur Flutter implémentant un écran liste, je veux un `ListGroup` qui regroupe les rows dans un conteneur arrondi `surface-default` avec dividers internes, afin de remplacer le pattern actuel de `Container` individuels avec `Border.all` (DESIGN.md anti-pattern « Cards individuelles par item »).

- **Why this priority** : Bloquant Étape 4. Sans ce composant, les écrans listes Flutter continueront à empiler des `Container` chacun avec leur propre bordure → coût visuel et structurel à corriger après-coup.
- **Given** un `ListGroup` avec 5 enfants `ListItem`, **when** il est rendu, **then** un conteneur unique arrondi `radius-xl` `surface-default` englobe les 5 items, séparés par un divider 1px `border-default` (sans bordure sur le dernier).
- **Independent Test** : widget test rendant `ListGroup(children: [...])`, vérifier la présence d'un seul `Container` parent avec `borderRadius` `AppRadius.xl` et que `children.length - 1` dividers sont insérés.

### P2 — Importantes (utilisé partout, non bloquant)

#### US-005 — PageHeader (header sous-pages avec flèche retour)

En tant qu'utilisateur naviguant vers une sous-page (ex : Mon compte, Catégories, Détail transaction), je veux un header standardisé avec une flèche retour ronde 36px à gauche et le titre aligné à droite, afin que toutes les sous-pages partagent la même chrome.

- **Why this priority** : Important pour homogénéiser, non bloquant strict (les sous-pages actuelles utilisent `AppBar` Material qui fonctionne — la migration peut se faire écran par écran en Étape 4-7).
- **Given** une sous-page rendant `PageHeader(title: 'Mon compte', onBack: () => context.pop())`, **when** elle est affichée, **then** la flèche est ronde 36px à gauche, l'espace flexible la sépare du titre, et le titre apparaît **à droite** (flex-end) avec la typographie page header (`size-lg` bold).
- **Independent Test** : widget test rendant `PageHeader` dans `MaterialApp`, taper la flèche, vérifier que le callback `onBack` est appelé.

> **Décision technique (audit Angular `.page-header`)** : Layout `[← back 36×36 rond] ............ [icon 32×32 rond optionnel] [titre]`. **Titre aligné `flex-end` (à droite)** — c'est l'inverse du pattern AppBar Material classique. Pas de `trailing` actions à droite (suit strictement Angular). Une icône métier optionnelle 32×32 ronde avec `icon-circle-bg` peut être placée juste avant le titre (utile sur les écrans détail).

#### US-006 — EmptyStateWidget (état vide unifié)

En tant qu'utilisateur arrivant sur un écran liste vide (catégories, comptes, abonnements, dettes, etc.), je veux un état vide visuel cohérent (icône Phosphor 48px @ 50% opacity + message + hint optionnel + CTA text-link optionnel), afin de comprendre l'écran et l'action à entreprendre.

- **Why this priority** : Important — actuellement, ~6 écrans rendent leur propre `Column(children: [Icon, Text])` ad hoc, avec des tailles d'icône et des espacements inconsistants. Pas bloquant car les écrans actuels fonctionnent.
- **Given** un écran liste vide, **when** il rend `EmptyStateWidget(icon: PhosphorIcons.folder, message: 'Aucune transaction', hint: 'Tapez + pour ajouter', ctaLabel: '+ Créer', onCtaTap: ...)`, **then** l'icône est centrée 48px à 50% opacity, message + hint + CTA suivent verticalement.
- **Independent Test** : widget test rendant `EmptyStateWidget` avec et sans CTA, vérifier la présence des bons `Text` widgets et le tap sur le CTA.

> **Décision technique (audit Angular `<app-empty-state>`)** : API alignée Angular — paramètres `icon` (optionnel), `message` (requis), `hint` (optionnel — texte secondaire xs / `text-tertiary`), `ctaLabel` (optionnel) → `onCtaTap`. **Le CTA est un text-link amber** (`color-primary`, souligné au hover), pas un bouton plein. Layout `Column` centré, `padding: AppSpacing.s10 / s4`, `gap: AppSpacing.s2`.

#### US-007 — ConfirmDialogCustom (dialog confirmation avec icône métier)

En tant qu'utilisateur supprimant une entité (transaction, catégorie, compte, etc.), je veux un dialog de confirmation avec icône métier + titre concret (nom + montant) + variante danger, afin de comprendre exactement ce que je supprime avant de valider.

- **Why this priority** : Important — actuellement 12 sites utilisent `AlertDialog` Material générique (« Supprimer ? OK / Annuler »). Sans variante visuelle, les utilisateurs peuvent confirmer trop vite. Pas bloquant car fonctionnel actuellement.
- **Given** une suppression de transaction, **when** `ConfirmDialogCustom.show(context, icon: ..., title: 'Supprimer Courses 42 €', message: 'Cette action est irréversible.', variant: ConfirmVariant.danger)` est invoqué, **then** un dialog centré apparaît avec icône métier en haut, titre concret, message, et boutons pills `Annuler` / `Supprimer` rouge.
- **Independent Test** : widget test invoquant `ConfirmDialogCustom.show()`, taper `Confirmer`, vérifier que le `Future<bool>` retourne `true`. Taper `Annuler`, vérifier `false`.

#### US-008 — VariationBadge (texte coloré +montant ce mois)

En tant qu'utilisateur consultant un résumé mensuel (dashboard, détail catégorie, détail compte), je veux voir un texte coloré compact avec le delta vs mois précédent (`+150,00 € ce mois (+12,5%)` en vert ou `-8,00 € ce mois (-3,2%)` en rouge), afin de comprendre la tendance d'un coup d'œil.

- **Why this priority** : Important — pattern défini dans DESIGN.md (« Variation Badges »), utilisé sur dashboard et résumés. Pas bloquant car composant mineur visuel.
- **Given** un résumé de catégorie `current = 120 €` et `previous = 100 €`, **when** `VariationBadge(delta: 20, currency: '€', percentage: 20.0, suffix: 'ce mois')` est rendu, **then** le texte affiche `+20,00 € ce mois (+20,0%)` avec couleur `text-success`.
- **Independent Test** : widget test rendant `VariationBadge` avec delta positif, négatif, zéro avec/sans pourcentage ; vérifier le signe, la couleur appliquée, et le masquage si `delta == 0 && percentage == null`.

> **Décision technique (audit Angular `.variation-badge`)** : **Pas un pill, juste un texte coloré** — `inline-flex`, gap 1, font xs medium, **pas de fond, pas de padding** au-delà de la taille de texte. 3 états : `positive` (`textSuccess`), `negative` (`textError`), `neutral` (`textSecondary` — pas tertiary). Format Angular exact : `{signe}{montant formaté} {suffix} ({signe}{pct,1 décimal}%)`.
>
> **CL-005 résolu** : le badge est **masqué** si `delta == 0 && percentage == null` (logique Angular `@if (convertedNet() !== 0 || convertedVariationPct() !== null)`). Si l'un des deux est non-nul, on affiche en couleur appropriée.

---

## Requirements fonctionnels

### Composants

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-001 | `InlineDatePicker` est une **réimplémentation custom Flutter** (clarify CL-002 révisée — pas de `CalendarDatePicker` Material). Accepte `value: String` ISO (`'2026-05-07'`), `onChanged: ValueChanged<String>`, `originalValue: String?` (pour mode édition), `minDate: String?`, `maxDate: String?`. Lundi-first hardcodé | P1 | US-001 |
| FR-002 | `InlineDatePicker` ne déclenche aucun overlay / dialog / route (pas de `showDatePicker`, pas de `Navigator.push`) — rend uniquement le calendrier inline avec header `[‹] [Mai 2026 cliquable] [›]` + grille 7 colonnes | P1 | US-001 |
| FR-003 | Cellules jour 36×36 cercle complet (`AppRadius.round`). Sélection : fond `colorScheme.primary` + texte inverse semibold. Aujourd'hui : outline 1px `border-default`. Original (mode édition) : fond `hoverSubtle` discret. Hors-mois & disabled : `opacity 0.3`, non-tappable. Tap label mois → `goToToday()` (revient au mois courant) | P1 | US-001 |
| FR-004 | `CategorySelectExpand` est un `StatefulWidget` composite (clarify CL-003 révisée — Option A). Accepte `categories: List<Category>`, `selectedId: String?`, `searchPlaceholder: String?`. Outputs : `onSelected: ValueChanged<String>` (id), `onCreated: ValueChanged<Category>` (objet complet retourné par le sous-form), `onCreatingChanged: ValueChanged<bool>?` | P1 | US-002 |
| FR-005 | `CategorySelectExpand` filtre la liste avec recherche insensible à la casse / accents (helper `normalizeForSearch` — NFD + suppression diacritiques) — affichage de la liste complète quand la recherche est vide. Bouton `+ Créer` apparaît quand la recherche n'a aucun match exact | P1 | US-002 |
| FR-006 | `CategorySelectExpand` a 2 modes internes : `'list'` (recherche + listbox + bouton créer) et `'create'` (header `[← Retour] [✓ Créer]` + embed `CategoryFormWidget`). Recherche conservée au retour mode création. Reset à `dispose()` (retour mode `'list'`) | P1 | US-002 |
| FR-007 | `SectionHeaderSticky` est implémenté via `SliverPersistentHeader(pinned: true)` (clarify CL-001). Accepte `title: String`, `count: int?`, `actions: List<Widget>?`, et bascule visuellement (fond `surfaceContainerHighest`) dès que `shrinkOffset > 0` | P1 | US-003 |
| FR-008 | `ListGroup` accepte `children: List<Widget>` et insère un divider 1px (`AppColors.border` ou équivalent thème) entre chaque enfant — pas de divider après le dernier | P1 | US-004 |
| FR-009 | `ListGroup` rend un conteneur unique avec `borderRadius: AppRadius.xl`, `color: surfaceContainer`, sans `Border.all` interne | P1 | US-004 |
| FR-010 | `PageHeader` accepte `title: String`, `onBack: VoidCallback?`, `icon: Widget?` (icône métier optionnelle 32×32 ronde avec fond `iconCircleBg`). **Pas de `trailing` actions** (suit strictement Angular). Flèche retour ronde 36px (`AppRadius.round`, icône `arrow_left` Phosphor 20px) à gauche, espace flexible, titre `flex-end` (à droite) avec icône optionnelle juste avant | P2 | US-005 |
| FR-011 | `EmptyStateWidget` accepte `icon: IconData?` (optionnel), `message: String` (requis), `hint: String?` (optionnel), `ctaLabel: String?`, `onCtaTap: VoidCallback?`. Icône 48px Phosphor `text-tertiary` `opacity 0.5`. Layout `Column` centré, `padding: AppSpacing.s10 / s4`, `gap: AppSpacing.s2`. **Le CTA est un text-link amber** (pas un bouton plein) avec souligné au hover | P2 | US-006 |
| FR-012 | `ConfirmDialogCustom.show()` est une **méthode statique uniquement** (clarify CL-004 — justifiée par l'idiomatique Flutter `showDialog`, équivalent natif de l'overlay global Angular) retournant `Future<bool>` ; accepte `context: BuildContext`, `icon: IconData?` (20px en header), `title: String`, `message: String?`, `confirmLabel: String = 'Confirmer'`, `cancelLabel: String = 'Annuler'`, `variant: ConfirmVariant { default, danger }` | P2 | US-007 |
| FR-013 | `ConfirmDialogCustom` utilise `showDialog` Material en interne mais avec un `child` custom (pas `AlertDialog`) — boutons en pills compacts conformes DESIGN.md. Icône **X** (Phosphor 14px) sur le bouton Annuler. Icône **Check** (variant `default`) ou **Trash** (variant `danger`) 14px sur le bouton Confirmer. Escape → `false`, click outside → `false`, click bouton → `true` / `false` | P2 | US-007 |
| FR-014 | `VariationBadge` est un **texte coloré** (pas un pill — pas de fond, pas de border-radius). Accepte `delta: num`, `currency: String?`, `percentage: num?`, `suffix: String?` (par défaut `'ce mois'`). Format : `{signe}{montant formaté} {suffix} ({signe}{pct,1 décimal}%)`. Couleurs : `textSuccess` si `delta > 0`, `textError` si `delta < 0`, `textSecondary` si `delta == 0`. **Masqué (rend `SizedBox.shrink()`)** si `delta == 0 && percentage == null` (CL-005 résolu) | P2 | US-008 |

### Décommissionnement / cleanup

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-015 | Supprimer `flutter/lib/src/common_widgets/segmented_filter.dart` et ses tests | P1 | (cleanup transversal) |
| FR-016 | Retirer les imports `SegmentedFilter` de `debt_list_screen.dart` et `subscription_list_screen.dart` ; remplacer temporairement par un `Wrap` de `FilterChip` Material 3 standard avec un commentaire `// TODO KKS-240 : remplacer par groupement + sections (DESIGN.md anti-pattern segmented control)` (clarify CL-006). Refonte propre en Étape 4 | P1 | (cleanup transversal) |
| FR-019 | Extraire un `CategoryFormWidget` réutilisable depuis `flutter/lib/src/features/categories/presentation/screens/category_form_screen.dart` (qui est actuellement un `Scaffold` complet). Le `CategoryFormScreen` existant reste un wrapper navigable autour du nouveau `CategoryFormWidget`. Le widget extrait expose `submit()` (équivalent du `categoryForm()?.submit()` Angular) et émet `onSaved(Category)` / `onCancelled()`. Cette extraction est un prérequis à FR-006 (embed mode `'create'` de `CategorySelectExpand`) | P1 | US-002 (dépendance interne) |

### Tokens et thème

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-017 | Tous les composants consomment exclusivement `Theme.of(context).colorScheme.*` et `Theme.of(context).extension<AppThemeExtension>()` — aucune valeur hex / `Color(0xFF...)` hardcodée dans les widgets | P1 | (transversal — Constitution Article 1 lib-first) |
| FR-018 | Tous les composants supportent dark + light theme via `AppThemeExtension` — un widget test par composant valide les deux thèmes | P1 | (transversal) |

---

## Requirements non-fonctionnels

| ID | Description | Catégorie |
|----|-------------|-----------|
| NFR-001 | Chaque composant doit avoir un widget test couvrant : rendu nominal, état vide / null, interaction principale (tap / change), thème dark + light | Testabilité (Constitution Principe V) |
| NFR-002 | Les composants doivent fonctionner sans appel réseau ni dépendance Drift / Dio (pure UI) — facilite tests unitaires et conforme local-first | Architecture (Trajectoire B) |
| NFR-003 | `InlineDatePicker`, `CategorySelectExpand`, `SectionHeaderSticky` doivent rendre 60 fps sur Android profil release low-end (Pixel 3a équivalent) — pas de rebuild complet de la liste à chaque scroll | Performance |
| NFR-004 | Tous les composants sont `StatelessWidget` ou `ConsumerWidget` par défaut. `StatefulWidget` autorisé pour état local UI strict — confirmé pour `CategorySelectExpand` (recherche + mode liste/création), `InlineDatePicker` (mois affiché), `SectionHeaderSticky` (animation transition). Pas de `Notifier` interne (composants dumb) | Architecture Riverpod-first |
| NFR-005 | Aucune dépendance package externe nouvelle. Réutiliser `phosphor_flutter` (icônes), `intl` (format dates / nombres) déjà présents | Dépendances (YAGNI) |
| NFR-006 | Documentation `///` triple-slash sur chaque classe publique + chaque paramètre public, avec exemple d'usage minimal | Maintenabilité |
| NFR-007 | Les composants `ConfirmDialogCustom` et `InlineDatePicker` doivent supporter le bouton retour Android (back button) → fermeture du dialog / picker | UX Mobile-First |

---

## Contraintes et dépendances

- **Contraintes techniques** :
  - Constitution v3.0.0 — Trajectoire B : composants 100% local, pas de dépendance réseau, pas de service Spring requis.
  - DESIGN.md `_list-patterns.scss` et `_bottom-sheet.scss` sont la référence visuelle (pas de divergence sans justification).
  - `AppThemeExtension` (16 propriétés post-KKS-237) — tout token manquant à retokeniser ici via extension du `AppThemeExtension`, pas de hardcode.
  - Flutter SDK ≥ 3.6, Material 3.
- **Dépendances externes** : aucune nouvelle (réutiliser `phosphor_flutter`, `intl`, `flutter_riverpod`).
- **Dépendances internes** :
  - KKS-237 mergé (palette + tokens) — ✅ Done.
  - `flutter/lib/src/common_widgets/` existant (16 widgets) — point d'extension.
  - `domain/entities/category.dart` (entité Category) consommée par `CategorySelectExpand`.
- **Dépendances bloquées par cette feature** :
  - KKS-239 (Étape 3 — BottomSheet 4 rows) consomme `InlineDatePicker` + `CategorySelectExpand`.
  - KKS-240+ (Étape 4 écrans listes) consomme `ListGroup`, `SectionHeaderSticky`, `EmptyStateWidget`, `VariationBadge`, `PageHeader`.
  - KKS-241+ (Étape 5 formulaires XL) consomme `ConfirmDialogCustom`.

---

## Questions ouvertes

| # | Question | Statut | Réponse |
|---|----------|--------|---------|
| Q1 | Pattern Flutter pour `SectionHeaderSticky` : `SliverPersistentHeader` ou `NotificationListener<ScrollNotification>` ? | Résolu (CL-001) | `SliverPersistentHeader(pinned: true)`, bascule du fond via `shrinkOffset > 0` animée par `AnimatedContainer` 300 ms |
| Q2 | `InlineDatePicker` : réutiliser `CalendarDatePicker` Material ou réimplémenter custom ? | Résolu (CL-002 — révisé après audit Angular) | **Réimplémentation custom** (~300-400 lignes Dart). `CalendarDatePicker` Material ne permet pas de reproduire les cellules cercle, le tap label = goToToday, ni le concept `originalValue` |
| Q3 | `CategorySelectExpand` : dumb component vs intégration Riverpod ? | Résolu (CL-003 — révisé après audit Angular) | **Composite stateful avec embed `CategoryFormWidget`** (Option A — alignée Angular). Nécessite extraction de `CategoryFormWidget` depuis `category_form_screen.dart` (FR-019) |
| Q4 | `ConfirmDialogCustom` : service Riverpod ou méthode statique uniquement ? | Résolu (CL-004 — justification corrigée) | Méthode statique `Future<bool>` uniquement. Justification : Flutter a `showDialog` natif comme **équivalent idiomatique de l'overlay global Angular** — pas un choix YAGNI mais un choix d'idiome plateforme |
| Q5 | `VariationBadge` à zéro : afficher ou masquer ? | Résolu (CL-005 — résolu après audit Angular) | **Masqué** si `delta == 0 && percentage == null`. Sinon affiché en couleur appropriée (positive / negative / neutral). Logique alignée sur le `@if` Angular |
| Q6 | `SegmentedFilter` supprimé : remplacement temporaire ? | Résolu (CL-006) | `FilterChip` Material 3 standard avec TODO référence Étape 4 (KKS-240) |
| Q7 | `Category.id` typing Flutter : `int` ou `String` ? | Résolu (vérification code) | **`String`** — confirmé dans `flutter/lib/src/domain/models/category.dart:9` (cohérent avec Angular `interface Category { id: string }`) |

---

## Success Criteria

| ID | Description | Méthode de vérification | User Story |
|----|-------------|------------------------|------------|
| SC-001 | `InlineDatePicker` rend un calendrier avec mois courant, navigation mois ±, et tap sur jour émet `onChanged` avec la `String` ISO correcte (ex : `'2026-05-07'`) — cohérent avec FR-001 | Widget test automatisé | US-001 |
| SC-002 | `InlineDatePicker` n'invoque jamais `showDatePicker` ni `Navigator.push` (vérifié par lecture du code source) | Code review + test | US-001 |
| SC-003 | `CategorySelectExpand` filtre 50 catégories avec recherche « cou » et retourne uniquement celles matchant insensible à la casse / accents | Widget test avec liste mock | US-002 |
| SC-004 | `CategorySelectExpand` propose `+ Créer « cour »` quand aucune catégorie ne match ; le tap sur ce bouton **bascule en mode `'create'`** (émet `onCreatingChanged(true)`) et embed `CategoryFormWidget` avec le terme pré-rempli. `onCreated(Category)` est émis uniquement après validation du sous-formulaire (cf. FR-006) | Widget test | US-002 |
| SC-005 | `SectionHeaderSticky` change de couleur de fond (transparent → `surfaceContainerHighest`) lorsqu'il atteint `shrinkOffset > 0` | Widget test avec scroll programmatique | US-003 |
| SC-006 | `ListGroup` insère exactement `n - 1` dividers pour `n` enfants, avec un seul `BorderRadius` parent | Widget test | US-004 |
| SC-007 | `PageHeader` rend la flèche ronde 36px et déclenche `onBack` au tap | Widget test | US-005 |
| SC-008 | `EmptyStateWidget` rend correctement avec et sans CTA optionnel | Widget test | US-006 |
| SC-009 | `ConfirmDialogCustom.show()` retourne `true` au tap `Confirmer`, `false` au tap `Annuler`, et `false` au tap hors-dialog (barrier dismiss) | Widget test async | US-007 |
| SC-010 | `ConfirmDialogCustom` variant `danger` affiche le bouton Confirmer en `expenseColor`, variant `default` en `primary` (amber) | Widget test golden ou explicite | US-007 |
| SC-011 | `VariationBadge` affiche `+20 €` vert pour delta positif, `-15 €` rouge pour négatif, `0 €` neutre pour zéro | Widget test avec 3 cas | US-008 |
| SC-012 | Aucune valeur hex `Color(0xFF...)` ni `withValues(alpha: ...)` directe dans les 8 fichiers composants — uniquement tokens (`Theme.of(context)` ou `AppThemeExtension`) | Grep automatique sur les 8 fichiers | Transversal FR-017 |
| SC-013 | Suppression effective de `segmented_filter.dart` + tests + retrait des 2 imports dans `debt_list_screen.dart` et `subscription_list_screen.dart` | Vérification git diff + grep | FR-015 / FR-016 |
| SC-014 | Tous les composants ont un widget test passant en dark ET en light (24 tests minimum, 3 par composant × 2 thèmes × 4 cas en moyenne) | `flutter test` exit 0 | NFR-001 |

---

## Key Entities

| Entité | Description | Relations principales |
|--------|-------------|----------------------|
| `Category` (existante) | Catégorie de transaction (`id: String`, `nom: String`, `icone: String`, `couleur: String`, `isSystem: bool`, `updatedAt: DateTime?`). Consommée par `CategorySelectExpand`. | `flutter/lib/src/domain/models/category.dart` — déjà présente. **Typing `id: String`** (cohérent Angular) |
| `ConfirmVariant` (nouveau enum) | `default` \| `danger` — pilote la couleur du bouton de confirmation et l'icône (Check vs Trash) | Local au fichier `confirm_dialog_custom.dart` |
| `CategoryFormWidget` (nouveau widget extrait) | Sous-widget réutilisable extrait de `category_form_screen.dart`. Expose `submit()` + émet `onSaved(Category)` / `onCancelled()`. Consommé par `CategorySelectExpand` en mode `'create'` et par `CategoryFormScreen` (wrapper navigable). | Cf. FR-019 |
| Aucune entité de domaine nouvelle | Tous les composants restent UI / présentation | — |

---

## Assumptions

| # | Hypothèse | Impact si fausse | Validation prévue |
|---|-----------|-----------------|-------------------|
| A-001 | `AppThemeExtension` (16 props post-KKS-237) suffit pour tous les besoins de tokens des 8 composants | Si insuffisant : extension supplémentaire dans cette étape (low risk car tokens déjà tous mappés depuis `_dark.scss` / `_light.scss`) | Audit token-par-token en research / plan |
| A-002 | Aucun composant n'a besoin de package externe nouveau (`table_calendar`, `flutter_form_builder`, etc.) | Si besoin : décision research, refus par défaut (NFR-005 — YAGNI) | Recherche en phase research |
| A-003 | Les 8 composants peuvent être livrés indépendamment les uns des autres, **excepté `CategorySelectExpand` qui dépend de FR-019 (extraction `CategoryFormWidget`)**. Ordre d'implémentation suggéré : FR-019 → US-002 ; les 7 autres sont parallélisables | Si dépendance révélée en plan : ordre contraint, livraison par lot | Audit en plan |
| A-004 | La suppression de `SegmentedFilter` (2 sites d'appel) ne casse pas les tests existants des 2 écrans | Si tests cassent : adapter les tests dans cette étape (in-scope cleanup) | Lancer `flutter test` après suppression |
| A-005 | `phosphor_flutter` couvre toutes les icônes nécessaires (notamment `arrow_left`, `folder`, `calendar`, `tag`, `trash`) | Si icône manquante : utiliser un fallback Material temporaire | Audit research |
| A-006 | Le pattern `SliverPersistentHeader` Flutter natif (avec `shrinkOffset`) suffit à reproduire l'effet « stuck » d'Angular sans `IntersectionObserver` | Si limitations visuelles : fallback `NotificationListener<ScrollNotification>` (plus coûteux mais flexible) | Prototype POC en research US-003 |
