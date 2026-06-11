# Feature Specification: Comptes liste Flutter (alignement DESIGN.md v5)

**Issue**: KKS-250 | **Parent**: KKS-242  
**Feature Branch**: `develop`  
**Created**: 2026-05-21  
**Status**: Draft  
**Priority**: High (2pts)  
**Labels**: Feature

---

## Contexte

Source de vérité Angular : `app/src/app/features/settings/components/accounts/accounts.html` + `accounts.scss`.

Écran Flutter actuel : `account_list_screen.dart` (216L) + `account_list_tile.dart` (173L) + `account_list_skeleton.dart`.

Delta Angular vs Flutter :
- `AccountListTile` : icône 40px → 32px, sous-titre `bankName · type` manquant, solde rouge si négatif manquant, badges style divergent (fill → outline), actions inline manquantes (PopupMenuButton actuel)
- `AccountListScreen` : conteneur carte (`surface` + `radius-xl` + `border-bottom` entre items) absent, section header "{N} comptes" + bouton "+" circulaire manquants, skeleton 5 → 3 items, états empty/error utilisent des `Column` custom au lieu de `EmptyStateWidget`
- Confirmation delete : `AlertDialog` (Flutter) → bloc confirm inline (Angular)

Hors scope : `CurrencyList`, `ExchangeRateManager`, import CSV (non implémenté en Flutter).

---

## User Scenarios & Testing

### User Story 1 — Alignement AccountListTile (P1)

L'utilisateur ouvre l'écran Comptes et voit chaque ligne avec l'icône 32px, le nom + badges sur la première ligne, le sous-titre `bankName · type`, le solde colorisé (rouge si négatif), et les boutons d'action (trash / star / edit) sur une ligne séparée en dessous — identique à Angular.

**Why this priority** : Cœur visuel de l'écran. Chaque `account-row` diverge de l'Angular sur 5 points visuels. Impact direct sur la lisibilité (solde rouge si négatif) et l'ergonomie (actions visibles vs menu caché 3-points).

**Independent Test** : Ouvrir l'écran Comptes avec des données → vérifier qu'une ligne affiche : icône 32px, nom (`sizeSm`/medium/`onSurfaceVariant`) + badge Défaut si applicable, sous-titre (`bankName · type`, `sizeXs`/`onSurfaceVariant`), solde (`sizeSm`/semiBold), 3 boutons (trash/star/edit) en-dessous sur une ligne pleine largeur.

**Acceptance Scenarios** :

1. **Given** l'écran affiche un compte actif non-défaut, **When** l'écran s'affiche, **Then** : icône 32px, nom sans badge, sous-titre `bankName · type` (ou uniquement type si pas de bankName), solde en `onSurfaceVariant`, boutons trash + star + edit alignés sous le contenu.
2. **Given** un compte est le compte par défaut (`isDefault = true`), **When** la ligne s'affiche, **Then** le badge "Défaut" (outline `borderDefault`, `text-tertiary`) apparaît à droite du nom. Le bouton star **n'est pas** affiché (compte déjà défaut).
3. **Given** un compte est inactif (`actif = false`), **When** la ligne s'affiche, **Then** opacité 0.5, badge "Inactif" (même style outline que Défaut). Le bouton star **n'est pas** affiché.
4. **Given** un compte a un solde négatif, **When** la ligne s'affiche, **Then** le solde s'affiche en `expenseColor` (rouge). Sinon `onSurfaceVariant`.
5. **Given** un compte n'a pas de `bankName`, **When** la ligne s'affiche, **Then** le sous-titre affiche uniquement le type, sans ` · ` ni chaîne vide.

---

### User Story 2 — Section header et états (P2)

L'utilisateur voit le nombre de comptes avec un bouton "+" circulaire dans un en-tête de section scrollable au-dessus de la liste. Les états empty et error utilisent `EmptyStateWidget` (KKS-238) plutôt que des colonnes personnalisées.

**Why this priority** : La section header est visible dès le chargement et contextualise la liste (pattern Angular `accounts-section__header`). `EmptyStateWidget` uniforme les états avec les autres écrans (KKS-240).

**Independent Test** : Ouvrir l'écran Comptes → vérifier l'en-tête "{N} comptes" (sizeXs, semiBold, uppercase, letterSpacing) + bouton "+" circulaire. Forcer un état vide → vérifier `EmptyStateWidget` avec icône Bank.

**Acceptance Scenarios** :

1. **Given** des comptes sont chargés, **When** l'écran s'affiche, **Then** au-dessus de la liste : label "{N} comptes" (`sizeXs`, `semiBold`, uppercase, `letterSpacing 0.5px`, `onSurfaceVariant`) + bouton "+" circulaire (28px, `outlineVariant` border) à droite.
2. **Given** aucun compte n'existe, **When** l'état empty est actif, **Then** `EmptyStateWidget` s'affiche : icône Bank, message "Aucun compte", CTA "Créer un compte" → navigation vers le formulaire création.
3. **Given** le chargement échoue, **When** l'état error est actif, **Then** `EmptyStateWidget` s'affiche : icône Warning, message "Erreur de chargement", CTA "Réessayer" → relance `loadItems()`.
4. **Given** le skeleton est actif, **When** le chargement est en cours, **Then** le skeleton affiche **3 items** (actuellement 5). Structure inchangée : cercle + 2 lignes + valeur droite.

---

### User Story 3 — Delete confirm inline (P3)

L'utilisateur clique sur le bouton trash → un bloc de confirmation apparaît inline dans la ligne (pas de dialog séparé), avec "Supprimer ce compte ?", un éventuel message d'erreur, et les boutons Annuler / Supprimer.

**Why this priority** : Amélioration UX notable (inline vs modal), mais non bloquante. US1 et US2 livrent de la valeur sans cette US.

**Independent Test** : Cliquer trash sur un compte → vérifier qu'un bloc inline apparaît dans la ligne (pas de popup/dialog). Annuler → bloc disparaît. Confirmer → compte supprimé.

**Acceptance Scenarios** :

1. **Given** l'utilisateur clique trash d'un compte, **When** l'action se déclenche, **Then** un bloc inline apparaît sous les actions dans la même ligne : "Supprimer ce compte ?" + bouton Annuler (outline) + bouton Supprimer (fond `expenseColor`). Aucun `AlertDialog`.
2. **Given** le bloc confirm est affiché, **When** l'utilisateur clique Annuler, **Then** le bloc disparaît et l'état est réinitialisé.
3. **Given** le bloc confirm est affiché, **When** la suppression échoue côté API, **Then** le message d'erreur s'affiche dans le bloc confirm (pas de SnackBar).
4. **Given** le bloc confirm est affiché pour le compte A, **When** l'utilisateur clique trash du compte B, **Then** le bloc du compte A se ferme et celui de B s'ouvre (un seul confirm à la fois).

---

### Edge Cases

- Que se passe-t-il si `bankName` est une chaîne vide (`""`) ? → Traiter comme null : afficher uniquement le type.
- Que se passe-t-il si la liste n'a qu'un seul compte ? → Le label affiche "1 comptes" — alignement intentionnel avec Angular (pas de pluriel dynamique, label affiché en uppercase).
- Que se passe-t-il si `account.actif = false && account.isDefault = true` ? → Badge Inactif visible, badge Défaut aussi (les deux peuvent coexister).
- Que se passe-t-il si le scroll est en cours pendant l'affichage du bloc confirm ? → Comportement standard Flutter (le bloc reste dans la liste scrollable).

---

## Requirements

### Functional Requirements

**AccountListTile — layout et style**

- **FR-001** : `AccountListTile` DOIT afficher `AccountBankIcon` avec un cercle de **32px de diamètre**. `AccountBankIcon` DOIT être modifié pour que `size` = diamètre du conteneur (`width: size, height: size` au lieu de `size × 1.5`) et que l'icône intérieure soit proportionnelle (`icone_size = size * 0.67` SVG / `size * 0.55` emoji). Passer ensuite `size: AppSpacing.space8` (32px). Le skeleton DOIT aussi passer de `AppSpacing.space10` à `AppSpacing.space8`. Un seul caller (`account_list_tile.dart`) — modification safe.
- **FR-002** : Le nom DOIT être en `AppTypography.sizeSm` / `medium` / `colorScheme.onSurfaceVariant` (actuellement `sizeMd` / `medium` / `onSurface`).
- **FR-003** : Le sous-titre DOIT afficher `${bankName} · ${type}` si `bankName` non null/vide, sinon uniquement le type — actuellement uniquement le type.
- **FR-004** : Le solde DOIT être en `AppTypography.sizeSm` (14px) / `semiBold` / `expenseColor` si `account.solde < 0`, `colorScheme.onSurfaceVariant` sinon — actuellement `sizeMd` (16px) + toujours `onSurface`.
- **FR-005** : Les badges "Défaut" et "Inactif" DOIVENT utiliser le style Angular : `Border.all(colorScheme.outlineVariant)`, `AppRadius.round`, `AppTypography.size2Xs` (10px), `colorScheme.onSurfaceVariant`, padding `EdgeInsets.symmetric(horizontal: 6, vertical: 1)` (pas de token `space-1-5` en Flutter) — actuellement fill colorisé en `primary`/`error`.
- **FR-006** : Les actions DOIVENT être une `Row` inline pleine largeur sous le contenu : bouton trash (`expenseColor`) à gauche + `Spacer` + bouton star (`onSurfaceVariant`, si `!isDefault && actif`) + bouton edit. Supprimer le `PopupMenuButton`.

**AccountListScreen — structure et conteneur**

- **FR-007** : La liste des comptes DOIT être enveloppée dans un conteneur carte : `color: colorScheme.surface`, `borderRadius: AppRadius.xl`, `clipBehavior: Clip.antiAlias`. Chaque item DOIT afficher un `Divider` (1px, `colorScheme.outlineVariant`) sauf le dernier. Implémentation Flutter : remplacer `SliverList.builder` par `SliverToBoxAdapter(Container(surface/radius-xl/clip, Column(items)))` — les items ne sont plus lazy mais acceptable pour une liste de comptes (< 20 items). `CustomScrollView` + `RefreshIndicator` préservés.
- **FR-008** : Une section header DOIT être ajoutée dans la zone scrollable au-dessus de la liste : label "{N} comptes" (`sizeXs`, `semiBold`, uppercase, `letterSpacing: 0.5`) + bouton "+" circulaire (28px, border `outlineVariant`). Le bouton `+` de l'`AppBar` (`actions`) DOIT être supprimé — la section header le remplace (Angular `page-header` n'a pas de bouton `+`).
- **FR-009** : L'état empty DOIT utiliser `EmptyStateWidget` (icône `PhosphorIconsRegular.bank`, message "Aucun compte", `ctaLabel` "Créer un compte", `onCtaTap` → navigation formulaire création).
- **FR-010** : L'état error DOIT utiliser `EmptyStateWidget` (icône `PhosphorIconsRegular.warning`, message "Erreur de chargement", `ctaLabel` "Réessayer", `onCtaTap` → `loadItems()`).
- **FR-011** : Le skeleton DOIT afficher **3 items** (actuellement 5 dans `AccountListSkeleton`).

**Delete confirm inline**

- **FR-012** : Le bouton trash DOIT déclencher un bloc confirm inline (pas d'`AlertDialog`). L'état `confirmDeleteId` est géré au niveau `AccountListScreen` (lift-state).
- **FR-013** : Le bloc confirm DOIT afficher : texte "Supprimer ce compte ?", bouton "Annuler" (outline), bouton "Supprimer" (fond `expenseColor`, texte blanc).
- **FR-014** : Si la suppression échoue, l'erreur DOIT être affichée dans le bloc confirm (via `deleteError` state au niveau screen).

### Non-Functional Requirements

- **NFR-001** : Si US3 est implémentée, l'API de `AccountListTile` DOIT être étendue avec : `isConfirmingDelete` (bool), `deleteError` (String?), `onRequestDelete` (VoidCallback?), `onConfirmDelete` (VoidCallback?), `onCancelDelete` (VoidCallback?), `onEdit` (VoidCallback?) — pattern lift-state, tile reste `ConsumerWidget` (FR-012).
- **NFR-002** : Aucun nouveau widget extrait en `common_widgets` — périmètre limité aux fichiers existants.
- **NFR-003** : Les tests existants (`account_list_screen_test.dart`, `account_list_tile_test.dart`) DOIVENT passer ou être mis à jour si la signature change.
- **NFR-004** : Aucune logique métier (notifier, repository, data layer) modifiée.

### Key Entities

- **Account** : `id`, `nom`, `solde`, `currency`, `actif`, `isDefault`, `bankName`, `type`, `bankCode`, `bankBrandColor`, `couleur`, `bankCustomLogo`

---

## Success Criteria

### Measurable Outcomes

- **SC-001** : Un `AccountListTile` actif non-défaut affiche l'icône 32px, le nom/sous-titre, le solde, et 3 boutons inline — vérifiable visuellement.
- **SC-002** : Un solde négatif s'affiche en `expenseColor` — vérifiable visuellement.
- **SC-003** : Les badges "Défaut" et "Inactif" utilisent le style outline neutre (`outlineVariant`, `onSurfaceVariant`) — audit grep sur `_Badge`.
- **SC-004** : La section header "{N} comptes" + bouton "+" est visible au-dessus de la liste — vérifiable visuellement.
- **SC-005** : Les états empty et error utilisent `EmptyStateWidget` — audit grep dans `account_list_screen.dart`.
- **SC-006** : Le skeleton affiche 3 items — audit grep sur `List.generate(3`.
- **SC-007** : Le bouton trash déclenche un bloc confirm inline (pas d'`AlertDialog`) — vérifiable visuellement + grep sur `AlertDialog`.
- **SC-008** : La liste des comptes est enveloppée dans un conteneur `surface`/`radius-xl` visible — audit grep sur `AppRadius.xl` dans `account_list_screen.dart`.

---

## Assumptions

- **A-001** : L'import CSV n'existe pas en Flutter — le bouton `triggerImport` de l'Angular est hors scope. Impact si fausse : un 4ème bouton "upload" serait absent de la spec.
- **A-002** : L'état `confirmDeleteId` est géré au niveau `AccountListScreen` (pattern Angular avec signal `confirmDeleteId()`), pas dans le tile. Impact si fausse : le tile devrait être stateful, ce qui complique le pattern `ConsumerWidget`.
- **A-003** : `EmptyStateWidget` accepte les paramètres `message`, `ctaLabel`, `onCtaTap` — vérifié dans `common_widgets/empty_state_widget.dart`. Impact si fausse : l'API doit être adaptée (hors scope KKS-250).
