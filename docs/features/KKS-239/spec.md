# Spec — KKS-239 : Phase 1 / Étape 3 — BottomSheet4RowsWidget composable

> Date : 2026-05-08
> Issue : [KKS-239](https://linear.app/kksdev/issue/KKS-239/phase-1-etape-3-bottomsheet4rowswidget-composable)
> Issue parent : [KKS-236](https://linear.app/kksdev/issue/KKS-236/phase-1-refonte-design-flutter-v5)
> Feature Branch : `feature/bottom-sheet-4-rows-widget`
> Priorité : High (P2 Linear)
> Estimation : 3 points (~16h, S+/M)
> Labels : Feature
> Statut : Draft

---

## Contexte

KKS-237 a aligné les **tokens design** Flutter sur la palette propriétaire Angular v5, et KKS-238 a livré les **8 composants shared** (dont `InlineDatePicker` et `CategorySelectExpand`) qui matérialisent les patterns visuels Angular v5. L'Étape 3 — objet de cette spec — consiste à créer le **squelette structurel commun** des 3 grands formulaires bottom sheet (`Transaction`, `Subscription`, `Debt`) sous la forme d'un **widget composable** `BottomSheet4RowsWidget` aligné sur le pattern Angular `_bottom-sheet.scss` (`.bsheet`).

L'app Flutter actuelle utilise pour chaque formulaire un layout ad-hoc (`TransactionForm` dans `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` — 441 lignes) avec un mélange de `AppFormField`, `CategoryPicker`, `SelectPicker`, et un `showDatePicker` Material qui empile un second dialog. La refonte v5 impose le pattern **4 rows** (handle+titre / montant hero / pills meta / footer actions) avec sections inline `bsheet__expand` (jamais de second sheet ni dialog Material). Cette étape ne refait **pas** les 3 formulaires (Étape 5 — KKS-241+) ; elle livre uniquement le **squelette composable**.

### Périmètre

| # | Bloc | Description Angular (`_bottom-sheet.scss`) |
|---|------|---------------------------------------------|
| Row 1 | `bsheet__top` | Handle 36×4 centré + titre `bsheet__top-title` (icône + texte secondaire bold) + slot trailing **universel** `topTrailing` — utilisé par les 3 formulaires pour leur `bsheet__type-toggle` (Tx : Dépense/Recette · Sub : Mensuel/Annuel · Debt : Emprunt/Prêt) |
| Row 2 | `bsheet__main-row` | Montant hero (font-size 30px bold, `bsheet__amount`) + libellé optionnel (`bsheet__libelle`, flex 1, text-align right, border-bottom) — utilisé par les 3 formulaires (Tx : autocomplete optionnel · Sub : "Nom" requis · Debt : "Personne" requis) |
| Note preview | `bsheet__note-preview` | Slot optionnel inséré **entre Row 2 et Row 3** — preview italique 2 lignes ellipsées de la note. Utilisé par Transaction quand le champ note est non vide. |
| Row 3 | `bsheet__meta-row` | Icones gauche (`bsheet__icons` — note, recurring, actif, reminder…) + pills scrollables (`bsheet__meta-pills` — date, catégorie, compte, récurrence…) |
| Row 4 | `bsheet__bottom-row` | Footer pinned : zone gauche (`bsheet__bottom-left` — **liste** de pills : annuler en création, ou danger + status en édition selon le formulaire) + zone droite (Valider — `bsheet__action-pill --primary`) |
| Expand | `bsheet__expand` | Zone de déploiement inline (date picker, catégorie, note, récurrence, currency…) sous Row 3 — affiche le composant correspondant à `expandedSection`. Le déclencheur **n'est pas nécessairement** une pill de Row 3 (ex : currency picker Sub/Debt déclenché ailleurs dans l'UI — section "expand orpheline"). |

### Décisions structurantes (issue Linear + parent KKS-236)

- **Pattern composable, pas générique inflexible** : chaque formulaire (Transaction, Subscription, Debt) a des champs, sections et pills différents. Le widget doit donc exposer une **API par slots/builders** (pas un constructeur monolithique avec des dizaines de paramètres).
- **Constitution v3.0.0 — Trajectoire B (Flutter standalone commercial)** : composant 100% UI, pas de `Notifier`, pas d'appel réseau ni Drift. Pure composition.
- **Réutilisation systématique des composants shared KKS-238** : `InlineDatePicker` et `CategorySelectExpand` sont **embeddés dans la zone expand**, jamais dupliqués. Aucun `showDatePicker` Material résiduel autorisé dans le squelette.
- **Lib-first** : le widget va dans `flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart` (convention KKS-238). Aucun déplacement vers un package séparé.
- **Pas de gestion d'état métier** : l'expansion d'une section (`expandedSection`), le contrôle du montant, du libellé, des sélections appartiennent au formulaire parent. Le widget ne contient **aucun** `Notifier` ni controller métier.
- **Fail-loud sur les états dégradés** : `loading` désactive le bouton Valider et affiche un `CircularProgressIndicator` 16px à sa place. `errorMessage` rend un bandeau `bsheet__error` au-dessus de Row 1 (font-size sm, `colorScheme.error`).

### Hors périmètre

- Refonte effective des 3 formulaires (Transaction / Subscription / Debt) — Étape 5 (KKS-241+).
- Refonte des écrans listes consommateurs des bottom sheets (Étape 4 — KKS-240).
- Création de **nouveaux** composants shared (handle, pill, action button) : ils sont rendus en SCSS Angular comme blocs CSS, mais en Flutter il s'agit ici de **petits widgets privés du fichier** (`_BSheetHandle`, `_BSheetPill`, `_BSheetActionPill`) — non exposés publiquement ; aucune extraction vers `common_widgets/` séparée tant qu'un autre site d'appel n'émerge (Constitution YAGNI).
- Animations transitionnelles sophistiquées de la zone `bsheet__expand` (au-delà d'un simple `AnimatedSize`/`AnimatedSwitcher` natif Flutter).
- Migration des sites d'appel actuels (`TransactionForm`, etc.) — uniquement un **exemple de consommation de référence** dans la documentation `///` du widget pour valider l'API.

### Audit comparatif Angular effectué

Audit du pattern source réalisé le 2026-05-08 avant gel de la spec. Sources consultées :

- `app/src/styles/_bottom-sheet.scss` — référence structurelle complète (415 lignes, 4 rows + expand + variantes)
- `app/src/app/features/transactions/components/transaction-form/transaction-form.html` — exemple de consommation Angular (handle, titre, type-toggle, amount, libellé, pills, expand)
- `app/src/app/features/subscriptions/components/subscription-form/subscription-form.html` et `app/src/app/features/debts/components/debt-form/debt-form.html` — variantes (différentes pills, footer avec action danger pour debt)
- `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` — état Flutter actuel (à refactoriser en Étape 5 mais utilisé ici pour valider que l'API du widget couvre tous les besoins)
- `flutter/lib/src/common_widgets/inline_date_picker.dart` et `flutter/lib/src/common_widgets/category_select_expand.dart` (KKS-238) — composants à intégrer dans la zone expand

Écarts détectés et arbitrés directement dans cette spec (audit code Angular ré-effectué 2026-05-09) :

- **`bsheet__type-toggle` (Row 1 trailing) — universel** : utilisé par les **3 formulaires** (Tx : Recette/Dépense, Sub : Mensuel/Annuel, Debt : Emprunt/Prêt). Exposé via slot `topTrailing: Widget?` agnostique — le squelette n'impose ni structure ni libellés ; chaque formulaire passe son propre widget.
- **`bsheet__libelle` (Row 2) — universel** : les 3 formulaires l'utilisent (Tx : `<app-autocomplete>` optionnel ; Sub : `<input>` "Nom" requis maxlength 255 ; Debt : `<input>` "Personne" requis maxlength 255). Le slot `libelleField: Widget?` accepte indifféremment un input direct ou un wrapper qui contient un input (le SCSS source cible déjà `input.bsheet__libelle, .bsheet__libelle input`).
- **`bsheet__note-preview`** : slot optionnel `notePreview: Widget?` inséré **entre Row 2 et Row 3** (utilisé aujourd'hui uniquement par Transaction). Pas une expand, pas une pill.
- **`bsheet__bottom-left` — liste de pills** : Debt en édition affiche **simultanément** `--danger` (trash) **et** `--status` (Remboursé/Non remboursé). Le slot `footerLeading` est donc typé `List<Widget>?` (pas `Widget?` singulier) — sinon Debt ne tient pas dans le squelette en Étape 5.
- **Expand orpheline** : la zone `bsheet__expand` peut afficher une section **sans pill correspondante dans Row 3** (ex : currency picker Sub/Debt déclenché par la logique du formulaire — `showCurrencyPicker()` — pas par un tap utilisateur sur Row 3). Le squelette ne valide aucune correspondance pill ↔ expand : il rend simplement `expandedContent` quand non null.

---

## User Scenarios & Testing

### User Story 1 — Squelette 4 rows visuellement aligné DESIGN.md (Priority: P1)

En tant que **développeur Flutter** implémentant un formulaire bottom sheet (Transaction / Subscription / Debt) en Étape 5, je veux **un squelette 4 rows déjà conforme `DESIGN.md` v5** (handle, titre, montant hero, pills, footer), afin que mon formulaire métier **n'ait plus à s'occuper du chrome visuel** — uniquement de ses champs et de sa logique.

- **Why this priority** : Bloquant Étape 5 (3 formulaires XL refactorisés). Sans ce squelette, chaque formulaire dupliquerait ~120 lignes de chrome (handle, structure flex, padding, border-top footer, gestion zone expand) — divergence garantie au fil du temps. C'est le P1 absolu de cette feature.
- **Acceptance Scenarios** :
  1. **Given** un appel `BottomSheet4RowsWidget(title: 'Nouvelle transaction', amountField: ..., metaPills: [...], onSubmit: ..., onCancel: ...)`, **when** le widget est rendu dans un `showModalBottomSheet`, **then** la structure visuelle exhibe : Row 1 (handle 36×4 centré + titre secondaire bold), Row 2 (montant hero 30px bold à gauche), Row 3 (pills à droite, scrollables horizontalement), Row 4 (footer pinned avec border-top + boutons pills Annuler / Valider).
  2. **Given** le widget rendu en mode dark **et** light, **when** on observe les couleurs, **then** tous les éléments consomment exclusivement les tokens (`colorScheme`, `AppThemeExtension`) — aucun hex hardcodé.
- **Independent Test** : widget test rendant `BottomSheet4RowsWidget` avec slots minimaux (titre + amount + 1 pill + actions par défaut) dans un `Scaffold`. Vérifier la présence des 4 zones structurelles via `find.byKey(const Key('bsheet_top'))`, `find.byKey(const Key('bsheet_main_row'))`, `find.byKey(const Key('bsheet_meta_row'))`, `find.byKey(const Key('bsheet_bottom_row'))`. Test idempotent, pas de dépendance externe.

---

### User Story 2 — API composable par slots/builders (Priority: P1)

En tant que **développeur Flutter**, je veux **une API à slots typés** (`amountField`, `libelleField?`, `metaPills`, `iconButtons?`, `footerLeading?`, `expandedContent?`), afin que **chaque formulaire (Transaction / Subscription / Debt) injecte ses propres champs** sans avoir à étendre le widget ni à passer 30 paramètres scalaires.

- **Why this priority** : Bloquant Étape 5. Les 3 formulaires partagent le squelette mais divergent sur les champs (Transaction = toggle type, montant, libellé autocomplete, pills date/catégorie/compte ; Subscription = montant, libellé "Nom" requis, pills date/catégorie/compte/récurrence ; Debt = montant, libellé "Personne" requis, pills date/catégorie/compte). Une API slots est le seul moyen propre de couvrir les 3 sans duplication ni paramètres mort-nés.
- **Acceptance Scenarios** :
  1. **Given** une consommation `BottomSheet4RowsWidget(title: ..., amountField: MonAmountInput(), libelleField: MonLibelleInput(), metaPills: [pillDate, pillCategory, pillAccount], onSubmit: ..., onCancel: ...)`, **when** le widget est rendu, **then** les widgets passés en slots apparaissent aux emplacements documentés sans modification (le widget les wrappe dans la zone visuelle correspondante mais ne touche pas à leur arbre).
  2. **Given** une consommation `BottomSheet4RowsWidget(title: ..., amountField: ..., metaPills: [...], onSubmit: ..., onCancel: ...)` **sans** `libelleField`, **when** le widget est rendu, **then** Row 2 affiche uniquement le bloc montant (le slot libellé est rendu `SizedBox.shrink()` et l'espacement `bsheet__main-row` reste cohérent).
  3. **Given** une consommation avec `footerLeading: [BSheetActionPill.danger(label: 'Supprimer', icon: PhosphorIcons.trash, onTap: ...)]`, **when** rendue, **then** Row 4 affiche le bouton danger à gauche et le bouton Valider à droite, alignés via `MainAxisAlignment.spaceBetween`. **Cas Debt edit** : `footerLeading: [danger, status]` rend les **deux** pills cote-à-cote dans `bsheet__bottom-left`.
- **Independent Test** : widget test paramétrique ; rend 3 variantes d'API (Transaction-like, Subscription-like, Debt-like avec footerLeading) avec des `Container`s typés-clés en slots ; vérifier la présence des bonnes clés aux bons emplacements dans l'arbre via `find.descendant`.

---

### User Story 3 — Zone expand inline pour InlineDatePicker / CategorySelectExpand (Priority: P1)

En tant qu'**utilisateur** ouvrant un formulaire bottom sheet, je veux **les sections (date, catégorie, note, récurrence) qui se déploient inline sous Row 3** (jamais en second sheet ni dialog Material), afin que la saisie reste à un seul niveau de surface modale (DESIGN.md principe « un seul niveau de surface modale »).

- **Why this priority** : Bloquant Étape 5 et lien direct avec les composants shared KKS-238. Sans cette zone expand pilotée par un slot `expandedContent`, les formulaires repartiraient sur `showDatePicker`/`showModalBottomSheet` empilés. La zone expand est le **point d'intégration** des composants livrés par KKS-238.
- **Acceptance Scenarios** :
  1. **Given** un formulaire dont l'état parent gère `expandedSection: String?` initialement `null`, **when** l'utilisateur tape la pill `Date`, **then** le parent passe `expandedSection: 'date'` et `expandedContent: InlineDatePicker(...)` au widget, qui rend ce contenu dans la zone `bsheet__expand` entre Row 3 et Row 4 avec une animation `AnimatedSize` (`AppDurations.normal` = 200 ms, `AppDurations.easeOut`).
  2. **Given** une zone expand contenant `CategorySelectExpand`, **when** l'utilisateur entre en mode création (callback `onCreatingChanged(true)` du composant KKS-238), **then** le formulaire parent peut **désactiver le footer** via le paramètre `footerEnabled: bool` du widget — le widget ne pilote pas cette logique mais expose le levier.
  3. **Given** `expandedContent: null`, **when** rendu, **then** la zone expand est entièrement absente de l'arbre (pas d'`AnimatedSize` à hauteur 0 inutile — `if (expandedContent != null) ... else SizedBox.shrink()`).
- **Independent Test** : widget test enchaînant 2 builds — premier avec `expandedContent: null`, second avec `expandedContent: Container(key: ValueKey('expand-test'))` ; vérifier que le `ValueKey` apparaît dans l'arbre uniquement au second build et que le passage déclenche bien `AnimatedSize`.

---

### User Story 4 — États loading & error visibles dans le squelette (Priority: P2)

En tant qu'**utilisateur** validant un formulaire, je veux **un retour visuel immédiat** (spinner sur le bouton Valider en `loading`, bandeau d'erreur en haut du sheet en `errorMessage`), afin de **comprendre** ce qui se passe sans deviner.

- **Why this priority** : Important non bloquant. Sans cette gestion centralisée, chaque formulaire devra réimplémenter sa propre logique de spinner / bandeau d'erreur, avec des positionnements et des animations divergents. Pas P1 car les 3 formulaires *pourraient* théoriquement gérer eux-mêmes (mais convergence garantie en P2).
- **Acceptance Scenarios** :
  1. **Given** `loading: true`, **when** rendu, **then** le bouton Valider est désactivé visuellement (`opacity 0.4`, `cursor: not-allowed`) et son contenu remplacé par un `CircularProgressIndicator` 16×16 ; le bouton Annuler reste actif.
  2. **Given** `errorMessage: 'Le montant est requis.'`, **when** rendu, **then** un bandeau apparaît au-dessus de Row 1 avec font-size sm, fond `colorScheme.errorContainer` (équivalent `bg-error`), texte `colorScheme.error`, padding `s2 / s3`, `borderRadius: AppRadius.lg`.
  3. **Given** `loading: true` **et** `errorMessage` non null, **when** rendu, **then** les deux états coexistent (bandeau erreur visible + spinner sur Valider) — il n'y a pas de masquage mutuel (ex : une dernière soumission a échoué et l'utilisateur retente : on doit voir l'erreur précédente jusqu'à ce qu'elle soit explicitement effacée par le parent).
- **Independent Test** : widget tests trois cas (`loading: false, errorMessage: null` — état nominal ; `loading: true, errorMessage: null` — spinner visible ; `loading: false, errorMessage: 'X'` — bandeau visible). Vérifier la présence/absence du `CircularProgressIndicator` et du widget bandeau via clé.

---

### User Story 5 — Footer actions configurable (Annuler / Valider / leading list optionnelle) (Priority: P2)

En tant que **développeur Flutter** réutilisant le squelette, je veux **un footer pré-câblé** avec Annuler/Valider et un emplacement gauche optionnel **pour une liste** de pills (typiquement « Supprimer » seul en édition Tx/Sub, ou « Supprimer + Remboursé » en édition Debt), afin de couvrir les 3 formulaires sans réécrire la zone Row 4.

- **Why this priority** : Important non bloquant. C'est essentiellement un raffinement de l'US-002 (slots) : on **typifie** le slot footer pour empêcher les divergences (label Annuler tronqué, bouton Valider sans état danger, ordre Valider/Annuler inversé). Pas P1 car techniquement couvert par US-002.
- **Acceptance Scenarios** :
  1. **Given** un appel `BottomSheet4RowsWidget(..., onCancel: cb1, onSubmit: cb2, submitLabel: 'Créer')` **sans** `footerLeading`, **when** rendu, **then** Row 4 expose deux pills : Annuler (`--cancel`, gauche dans `bsheet__bottom-left`) et Créer (`--primary`, à droite). Le label par défaut de submit est `'Valider'` (override possible).
  2. **Given** `footerLeading: [BSheetActionPill.danger(label: 'Supprimer', icon: PhosphorIcons.trash, onTap: ...), BSheetActionPill.status(label: 'Remboursé', done: true, onTap: ...)]`, **when** rendu, **then** la zone `bsheet__bottom-left` contient **les deux** pills cote-à-cote, et l'espace flexible les sépare du bouton Valider à droite. Le bouton Annuler par défaut **n'est pas rendu** (le parent a pris la responsabilité complète de la zone gauche en passant `footerLeading`).
  3. **Given** un tap sur `Valider` alors que le formulaire est `loading: true`, **when** l'utilisateur tape, **then** le callback `onSubmit` n'est **pas** invoqué (le widget consomme et ignore le tap pour empêcher les double-soumissions).
- **Independent Test** : widget test invoquant tap sur `find.byKey(const Key('bsheet_submit'))` avec `loading: true` puis `loading: false` — vérifier que le callback `onSubmit` est invoqué seulement au second cas. Vérifier aussi le tap sur `find.byKey(const Key('bsheet_cancel'))` invoque `onCancel` dans tous les cas.

---

### Edge Cases

- **Clavier visible** (champs de saisie sur mobile réel) : le `bsheet__bottom-row` (Row 4) doit rester accessible — utiliser `MediaQuery.of(context).viewInsets.bottom` pour ajouter un padding bottom dynamique. À valider en plan car peut nécessiter `resizeToAvoidBottomInset: true` dans le `Scaffold` parent et un wrap `SafeArea(bottom: true)`.
- **Sheet très court** (Debt sans libellé, sans note) : le contenu peut être plus court que la hauteur min des bottom sheets Material — le widget ne doit pas forcer une hauteur min ; il rend ce qu'on lui donne et `showModalBottomSheet(isScrollControlled: true, ...)` côté appelant gère le sizing.
- **Sheet très long** (Subscription avec récurrence + note + 5 pills + expand `CategorySelectExpand` en mode création) : la zone scrollable doit englober Row 1 → Row 3 + expand, et Row 4 doit rester pinned en bas (footer fixe). Pattern : `Column { ScrollView { Row1, Row2, Row3, Expand }, Row4 }`.
- **`metaPills: []`** (aucun pill — cas hypothétique) : si `metaPills` est vide ET `iconButtons` est null, Row 3 est `SizedBox.shrink()` — entièrement absente de l'arbre. Symétrique au pattern FR-003 (expand). Le widget ne rend pas de hauteur minimale vide.
- **Tap dans la zone expand pendant `loading: true`** : interactions laissées libres — alignement Angular (aucun formulaire Angular ne gèle l'expand pendant la soumission). Le parent peut surcouvrir via `IgnorePointer(ignoring: loading, child: expandedContent)` si son cas métier l'exige. Le widget n'impose aucune contrainte.
- **Bouton retour Android** alors que la zone expand est ouverte : doit-il fermer l'expand (cohérent UX ascending) ou fermer le sheet ? Le widget ne gère **pas** la navigation système (c'est au parent), mais doit exposer un callback `onExpandClose: VoidCallback?` que le parent pourra brancher sur `WillPopScope`/`PopScope`.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Composable structure

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-001 | `BottomSheet4RowsWidget` est un `StatelessWidget` (`flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart`) — toute logique d'état (montant, libellé, sélections, `expandedSection`) appartient au formulaire parent. | P1 | US-001, US-002 |
| FR-002 | Le widget rend exactement 4 rows alignées sur `_bottom-sheet.scss` : Row 1 `bsheet__top` (handle + titre + slot trailing universel `topTrailing`), Row 2 `bsheet__main-row` (slot `amountField` + slot `libelleField?`), slot intermédiaire `notePreview?` (rendu entre Row 2 et Row 3 dans un conteneur `bsheet__note-preview`), Row 3 `bsheet__meta-row` (slot `iconButtons?` + `metaPills`), Row 4 `bsheet__bottom-row` (slot `footerLeading?: List<Widget>` + bouton Valider à droite — quand `footerLeading` est null, le widget rend un bouton Annuler par défaut dans la zone gauche via `onCancel`). | P1 | US-001 |
| FR-003 | Une zone `bsheet__expand` est insérée entre Row 3 et Row 4 **uniquement si** `expandedContent != null` ; elle est animée via `AnimatedSize` (durée `AppDurations.normal` = 200 ms, `AppDurations.easeOut` — aligné sur l'animation Angular `expandCollapse` : 200 ms easeOut à l'ouverture / 150 ms easeIn à la fermeture). Si `expandedContent == null`, la zone est `SizedBox.shrink()` (pas d'`AnimatedSize` à hauteur 0). | P1 | US-003 |
| FR-004 | Le widget expose les keys structurelles publiques (utilisables en tests) : `Key('bsheet_top')`, `Key('bsheet_main_row')`, `Key('bsheet_meta_row')`, `Key('bsheet_expand')`, `Key('bsheet_bottom_row')`, `Key('bsheet_submit')`, `Key('bsheet_cancel')`, `Key('bsheet_error_banner')`. | P1 | US-001, NFR-001 |

#### API publique (slots & paramètres)

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-005 | API publique du constructeur (paramètres nommés) : `title: String` (requis), `titleIcon: IconData?`, `topTrailing: Widget?` (slot Row 1 — **universel**, type-toggle Tx/Sub/Debt ou widget arbitraire), `amountField: Widget` (requis — slot Row 2), `libelleField: Widget?` (slot Row 2 — accepte input direct ou wrapper `<input>`), `notePreview: Widget?` (slot inter-Row entre Row 2 et Row 3), `iconButtons: List<Widget>?` (slot Row 3 gauche), `metaPills: List<Widget>` (slot Row 3 droite — peut être vide cf. CL-001), `expandedContent: Widget?` (peut être affiché **sans pill correspondante** dans Row 3 — cf. "expand orpheline"), `footerLeading: List<Widget>?` (slot Row 4 gauche — **liste** de pills pour couvrir Debt edit qui en affiche 2, danger + status), `onCancel: VoidCallback?` (rendu en pill cancel par défaut dans `footerLeading` quand `footerLeading == null` ; ignoré si `footerLeading` non null — le parent prend alors la responsabilité complète de la zone gauche, y compris le bouton Annuler), `onSubmit: VoidCallback` (requis), `cancelLabel: String = 'Annuler'`, `submitLabel: String = 'Valider'`, `loading: bool = false`, `errorMessage: String?`, `submitVariant: BSheetSubmitVariant { primary, danger } = primary`, `footerEnabled: bool = true`, `onExpandClose: VoidCallback?` (callback optionnel que le parent branche sur un `PopScope` pour intercepter le bouton retour Android quand l'expand est ouvert — le widget n'intercepte pas lui-même la navigation système). | P1 | US-002 |
| FR-006 | `submitVariant: BSheetSubmitVariant.danger` rend le bouton Valider en `colorScheme.error` au lieu de `colorScheme.primary` (utilisé pour confirmer une suppression dans un futur usage hypothétique — couvre le cas de cohérence avec `ConfirmDialogCustom` ; expose le levier sans l'utiliser dans cette étape). | P2 | US-002 |
| FR-007 | `footerEnabled: false` désactive visuellement (opacité 0.4) **les deux boutons** Annuler et Valider et bloque leurs callbacks (utilisé quand `CategorySelectExpand` est en mode `'create'` — cf. KKS-238 callback `onCreatingChanged`). | P2 | US-003, US-005 |

#### Comportements (loading / error / submit)

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-008 | `loading: true` désactive le bouton Valider et remplace son label par un `CircularProgressIndicator` 16×16 (couleur `colorScheme.primary` ou `onPrimary` selon le contraste) ; le bouton Annuler reste actif. Tap sur Valider en `loading: true` est ignoré (callback non invoqué). | P2 | US-004, US-005 |
| FR-009 | `errorMessage` non null rend un bandeau au-dessus de Row 1 avec : font-size `AppTypography.bodySmall` ou équivalent sm, couleur de texte `colorScheme.error`, fond `colorScheme.errorContainer` (token à ajouter explicitement dans les deux `ColorScheme` de `app_theme.dart` light + dark, aligné sur `--bg-error` Angular — la valeur Material 3 auto-générée n'est pas utilisable), padding `AppSpacing.s2` vertical / `AppSpacing.s3` horizontal, `borderRadius: AppRadius.lg`. Clé `Key('bsheet_error_banner')`. L'ajout de `errorContainer` dans `app_theme.dart` est un prérequis de cette feature (à lister dans le plan). | P2 | US-004 |
| FR-010 | `errorMessage` et `loading` peuvent coexister : pas de masquage mutuel (cf. US-004 scénario 3). | P2 | US-004 |

#### Composition & embedding

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-011 | Le widget **n'instancie ni `InlineDatePicker` ni `CategorySelectExpand` en interne** : il les rend uniquement quand le parent les passe via `expandedContent`. Cela évite tout couplage du squelette à la liste des composants embarqués (DESIGN.md) et permet d'ajouter une nouvelle section sans modifier le squelette. | P1 | US-003 |
| FR-012 | Documentation `///` du widget : commentaire de classe avec **au moins un exemple complet** d'usage (Transaction-like) montrant comment passer les slots et brancher les callbacks `expandedSection` côté parent. | P2 | NFR-006 |

#### Sous-widgets privés (file-scoped)

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-013 | Sous-widgets privés au fichier (pas exportés) : `_BSheetHandle` (handle 36×4 centré), `_BSheetActionPill` (pill action — variantes `primary`, `cancel`, `danger`, `status`, `loading`, alignées sur les modificateurs `bsheet__action-pill --*` du SCSS Angular), `_BSheetErrorBanner`. Aucun de ces widgets n'est extrait vers `common_widgets/` séparé (Constitution YAGNI — pas de second site d'appel). | P2 | US-002 |
| FR-014 | Pas de structure imposée pour le `bsheet__type-toggle` dans le squelette : le slot `topTrailing` couvre le besoin **universel** des 3 formulaires (Tx Recette/Dépense, Sub Mensuel/Annuel, Debt Emprunt/Prêt) en restant agnostique du contenu — chaque formulaire passe son propre widget toggle. | P1 | US-002 |

#### Tokens & thème

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-015 | Le widget consomme exclusivement les tokens via `Theme.of(context).colorScheme.*`, `AppThemeExtension`, et les constantes `flutter/lib/src/constants/` (`AppSpacing`, `AppTypography`, `AppRadius`, `AppShadows`, `AppDurations`). Aucune valeur hex / `Color(0xFF...)` hardcodée. | P1 | NFR-002, transversal |
| FR-016 | Le widget supporte dark + light theme : un widget test par scénario clé (au moins 5) valide les deux thèmes. | P1 | NFR-001 |

---

### Key Entities

| Entité | Description | Relations |
|--------|-------------|-----------|
| `BottomSheet4RowsWidget` (nouveau) | Widget composable squelette des bottom sheets XL (Transaction, Subscription, Debt) | `flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart` |
| `BSheetSubmitVariant` (nouvel enum) | `primary` \| `danger` — pilote la couleur du bouton Valider | Local au fichier |
| `_BSheetHandle`, `_BSheetActionPill`, `_BSheetErrorBanner` (sous-widgets privés) | Petits sous-widgets file-scoped de présentation | Local au fichier (pas extraits) |
| Aucune entité métier | Le widget est 100% UI / présentation | — |

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

| ID | Description | Méthode de vérification | User Story |
|----|-------------|-------------------------|------------|
| SC-001 | `BottomSheet4RowsWidget` rend les 4 rows attendues avec slots minimaux (titre + amount + 1 pill + actions par défaut) — keys `bsheet_top`, `bsheet_main_row`, `bsheet_meta_row`, `bsheet_bottom_row` toutes présentes dans l'arbre. | Widget test automatisé | US-001 |
| SC-002 | Les widgets passés en slots (`amountField`, `libelleField`, `metaPills`, `iconButtons`, `expandedContent`, `footerLeading`, `topTrailing`) apparaissent inchangés dans l'arbre de rendu (vérifié par `ValueKey` dans les widgets injectés). | Widget test paramétrique sur 3 variantes (Transaction-like, Subscription-like, Debt-like) | US-002 |
| SC-003 | Le passage de `expandedContent: null` → `expandedContent: Widget` déclenche bien un `AnimatedSize` (`AppDurations.normal` = 200 ms) et la clé du contenu apparaît dans l'arbre uniquement au second build. | Widget test enchaînant 2 builds + `tester.pump(AppDurations.normal)` | US-003 |
| SC-004 | `loading: true` désactive le bouton Valider (opacité 0.4) et substitue son label par un `CircularProgressIndicator` 16×16. Tap sur Valider en `loading: true` n'invoque pas `onSubmit`. | Widget test avec spy sur callback | US-004, US-005 |
| SC-005 | `errorMessage: 'X'` rend un bandeau d'erreur de clé `bsheet_error_banner` avec couleur de texte `colorScheme.error` et fond `colorScheme.errorContainer` (vérifié via `tester.widget<Container>` et lecture `decoration.color` — la valeur attendue est celle déclarée dans le `ColorScheme` projet après ajout du prérequis FR-009, pas la valeur Material par défaut). | Widget test avec inspection des couleurs résolues du thème actif | US-004 |
| SC-006 | `loading: true` ET `errorMessage` non null : les deux états sont visibles simultanément (bandeau + spinner). | Widget test combinatoire | US-004 |
| SC-007 | `footerLeading: BSheetActionPill.danger(...)` apparaît à gauche de Row 4 et `MainAxisAlignment.spaceBetween` sépare correctement leading et trailing. | Widget test inspection layout (`Row` direction & alignment) | US-005 |
| SC-008 | `footerEnabled: false` désactive visuellement (opacité 0.4) les deux boutons et bloque les callbacks `onCancel` ET `onSubmit`. | Widget test avec spy sur callbacks | US-003, US-005, FR-007 |
| SC-009 | Aucune valeur hex `Color(0xFF...)`, `withValues(alpha: ...)` direct, ni magic number d'espacement / radius non-tokenisé dans le fichier `bottom_sheet_4_rows_widget.dart`. | Grep automatique sur le fichier (`grep -nE "Color\\(0x|#[0-9a-fA-F]{6,8}"`) — exit 0 attendu | FR-015 |
| SC-010 | Tous les widget tests passent en dark ET en light theme — au moins 5 scénarios × 2 thèmes = 10 tests minimum. | `flutter test test/src/common_widgets/bottom_sheet_4_rows_widget_test.dart` exit 0 | NFR-001 |
| SC-011 | Documentation `///` du widget contient un exemple complet d'usage Transaction-like (montrant `topTrailing: typeToggle`, `amountField`, `libelleField`, `metaPills`, `expandedContent` piloté par un `expandedSection: ValueNotifier<String?>` côté parent). | Lecture humaine + `dart doc` sur le fichier (pas `dart analyze --fatal-infos` — trop strict sur les règles globales du projet) | NFR-006 |
| SC-012 | Le widget rend correctement (sans overflow, sans assertion) sur 3 hauteurs simulées : 320px (sheet court Debt-like), 600px (sheet moyen Transaction-like), 900px (sheet long Subscription-like avec expand). | Widget tests avec `tester.binding.window.physicalSizeTestValue` | Edge cases |
| SC-013 | Le slot `notePreview` est rendu dans un conteneur `Key('bsheet_note_preview')` **entre Row 2 et Row 3** quand non null, et entièrement absent de l'arbre quand null. | Widget test paramétrique (notePreview null vs Container clé) | US-001, FR-002 |
| SC-014 | `footerLeading: List<Widget>?` rend correctement les 3 cas Angular observés : (a) `null` → seul le bouton Annuler par défaut s'affiche à gauche ; (b) `[supprimer]` → seul Supprimer à gauche, Annuler **non rendu** ; (c) `[supprimer, status]` (Debt edit) → les 2 pills cote-à-cote à gauche, Annuler **non rendu**. | Widget test paramétrique 3 cas | US-002, US-005 |

---

## Non-Functional Requirements

| ID | Description | Catégorie |
|----|-------------|-----------|
| NFR-001 | Couverture de tests : minimum 5 widget tests scénarisés (rendu nominal, slot vide, expand, loading, error) × 2 thèmes = 10 tests. Suite `flutter test test/src/common_widgets/bottom_sheet_4_rows_widget_test.dart` doit passer. | Testabilité (Constitution Principe V) |
| NFR-002 | Le widget fonctionne sans appel réseau, sans Drift, sans Dio, sans `Notifier`. Pure UI / composition. | Architecture (Trajectoire B, Riverpod-first — composant dumb) |
| NFR-003 | Performance : le passage `expandedContent: null` → non-null (et inverse) doit fluidifier en 60 fps sur Android low-end (Pixel 3a). Pas de `setState` cascadant ni rebuild de la liste `metaPills` au tap d'une pill (le rebuild n'affecte que la zone expand côté parent). | Performance (Constitution Mobile-First) |
| NFR-004 | Pas de package externe nouveau. Réutiliser `phosphor_flutter` (icônes), `flutter_riverpod` (déjà présent — non utilisé en interne mais le widget peut être consommé dans un `ConsumerWidget` parent), composants shared KKS-238. | Dépendances (YAGNI) |
| NFR-005 | Documentation `///` triple-slash sur la classe publique + chaque paramètre public + l'enum `BSheetSubmitVariant`, avec un exemple complet d'usage Transaction-like dans la doc de classe. | Maintenabilité |
| NFR-006 | Le widget supporte le bouton retour Android via le callback `onExpandClose: VoidCallback?` (déclaré dans FR-005) — le parent le branche sur un `PopScope` (Flutter 3.12+). Le widget lui-même n'intercepte pas la navigation système. | UX Mobile-First |
| NFR-007 | Le clavier visible (saisie sur mobile réel) ne masque pas Row 4 : la documentation `///` mentionne explicitement la responsabilité du parent (`showModalBottomSheet(isScrollControlled: true, ...)` + `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))`). Le widget lui-même ne fait pas cette gestion (séparation des responsabilités). | UX Mobile-First |

---

## Constraints & Dependencies

- **Contraintes techniques** :
  - Constitution v3.0.0 — Trajectoire B : composant 100% local, pas de dépendance réseau, pas de service Spring requis.
  - DESIGN.md `_bottom-sheet.scss` est la référence visuelle (4 rows, expand, footer). Pas de divergence sans justification documentée.
  - `AppThemeExtension` (16 props post-KKS-237) — tout token manquant à retokeniser via extension du `AppThemeExtension`, pas de hardcode.
  - Flutter SDK ≥ 3.6, Material 3.

- **Dépendances externes** : aucune nouvelle.

- **Dépendances internes** :
  - KKS-237 mergé (palette + tokens) — ✅ Done.
  - KKS-238 mergé (8 composants shared dont `InlineDatePicker` et `CategorySelectExpand`) — ✅ Done (eae5bc6 sur main, branche actuelle dérivée).
  - `flutter/lib/src/common_widgets/` existant — point d'extension.

- **Dépendances bloquées par cette feature** :
  - KKS-241+ (Étape 5 — 3 formulaires XL refactorisés via `BottomSheet4RowsWidget`) consomment ce widget directement.

---

## Open Questions

| # | Question | Statut | Réponse cible |
|---|----------|--------|----------------|
| Q1 | Comportement Row 3 si `metaPills` ET `iconButtons` sont vides : Row 3 disparaît du DOM ou rend une hauteur 0 ? *(cf. edge case 4)* | Résolu ✓ | Row 3 est `SizedBox.shrink()` — entièrement absente de l'arbre si `metaPills.isEmpty && iconButtons == null`. Symétrique au pattern FR-003 (expand). (CL-001) |
| Q2 | Comportement de la zone expand quand `loading: true` : interactions gelées ou laissées libres ? *(cf. edge case 5)* | Résolu ✓ | Interactions laissées libres — alignement Angular. Le parent surcouvre via `IgnorePointer` si besoin. Le widget n'impose aucune contrainte. (CL-004) |
| Q3 | `BSheetSubmitVariant.danger` : couleur exacte — texte/bordure et fond ? | Résolu ✓ | Texte `ext.expenseColor`, bordure `ext.expenseColor`, fond `Colors.transparent`. Audit SCSS `_bottom-sheet.scss` §`.bsheet__action-pill--danger` : `color: var(--color-expense)`. Pas `colorScheme.error`. (CL-005) |
| Q4 | Convention de rendu `Annuler` vs `footerLeading` : omis ou rendu en plus si `footerLeading != null` ? | Résolu ✓ | Option (a) — `onCancel` ignoré quand `footerLeading != null`. Le parent inclut son bouton Annuler dans `footerLeading` s'il le veut. Déjà documenté dans FR-005 + SC-014. (CL-002) |
| Q5 | `notePreview` : prévoir `bsheet__amount--md/--sm` pour réduire le montant si `notePreview` consomme verticale ? | Résolu ✓ | Non (YAGNI). Aucun des 3 formulaires n'utilise ces modificateurs. `bsheet__amount` reste à 30px partout. (CL-006, différé — évidence YAGNI) |

---

## Assumptions

| # | Hypothèse | Impact si fausse | Validation prévue |
|---|-----------|------------------|-------------------|
| A-001 | `AppThemeExtension` (16 props post-KKS-237) suffit pour tous les besoins du squelette (notamment `errorContainer` équivalent `--bg-error` et `iconCircleBg` pour le pill icon). | Si insuffisant : ajouter le ou les tokens manquants à `AppThemeExtension` dans cette étape (low risk car alignement direct sur `_bottom-sheet.scss`). | Audit token-par-token en research / plan. |
| A-002 | Aucun composant n'a besoin de package externe nouveau. | Si besoin : décision research, refus par défaut (NFR-004 — YAGNI). | Recherche en phase research. |
| A-003 | Une API à slots typés (Widget?, List<Widget>?) suffit pour les 3 formulaires (Transaction, Subscription, Debt) sans imposer un builder pattern (`Widget Function(BuildContext)`). | Si un slot doit accéder au context du widget squelette (ex: position dans le sheet pour scroll-to-error) : passer en builder pattern pour ce slot uniquement, sans casser l'API globale. | **Validée (2026-05-10)** — `BottomSheet4RowsWidget` n'expose aucun `InheritedWidget` propre. Les slots construits par le parent accèdent à leur propre context via leur `build()`. `Widget?` est suffisant. (CL-003) |
| A-004 | `AnimatedSize` natif Flutter suffit pour l'animation de la zone expand (fluide à 60 fps sur Android low-end). | Si performance dégradée (`InlineDatePicker` 36×6 cellules + animation fold) : fallback `AnimatedCrossFade` ou suppression de l'animation. | POC en research US-003. |
| A-005 | Les keys structurelles (`bsheet_top`, etc.) sont **publiques** dans le fichier (constantes au top) — pas de risque de duplication entre tests, formulaire parent, et widget interne. | Si collision : préfixer par `_BSheet4RowsKeys.top` namespace de classe. | Vérification en plan. |

---

## Marqueurs `[NEEDS CLARIFICATION]`

Tous les marqueurs ont été résolus lors de `/devflow.clarify` (session 2026-05-10). Voir [`clarify-log.md`](./clarify-log.md) pour les détails.

1. **Row 3 vide** → `SizedBox.shrink()` si `metaPills.isEmpty && iconButtons == null`. (CL-001)
2. **Loading + zone expand** → interactions laissées libres, pas de gel. (CL-004)
3. **`BSheetSubmitVariant.danger`** → texte/bordure `ext.expenseColor`, fond `Colors.transparent`. (CL-005)
