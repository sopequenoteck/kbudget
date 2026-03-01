# Research: Formulaire Produit (creation/edition)

**Feature Branch**: `061-flutter-product-form`
**Date**: 2026-03-01

## R1 — Pattern de formulaire existant

**Decision**: Suivre le pattern `TransactionForm` (ConsumerStatefulWidget + callbacks).

**Rationale**: C'est le pattern standard pour les formulaires en bottom sheet dans ce projet. Tous les formulaires modaux (transaction, subscription, debt, transfer) utilisent le meme squelette :
- `ConsumerStatefulWidget` avec controllers et validation locale
- Callbacks `onSaved`, `onDeleted`, `onCancelled` passes par le parent
- `_showErrors` boolean declenchant l'affichage des erreurs apres premier submit
- `_isSubmitting` pour le loading state et prevention double-submit
- `_initialized` guard pour le pre-remplissage en mode edit
- Bouton FilledButton avec CircularProgressIndicator pendant la sauvegarde

**Alternatives considered**:
- Form widget Flutter natif (GlobalKey\<FormState\>) — non utilise dans les formulaires existants, introduirait un pattern different.

## R2 — Integration au systeme ModalNotifier

**Decision**: Etendre `ModalType` avec `product`, integrer dans `app_router.dart`.

**Rationale**: Le systeme ModalNotifier gere 6 types de modals. Il fournit :
- Gestion create/edit mode via `ModalMode`
- Titres automatiques via `modalCreateTitles` / `modalEditTitles`
- Toggle optionnel (null pour product — pas de sous-type)
- Cycle de vie uniforme (open/close observes par _ShellScaffold)
- Passage de l'entite en edit mode via `state.entity`

**Fichiers concernes**:
- `flutter/lib/src/domain/enums/modal_type.dart` — ajouter `product` + titres
- `flutter/lib/src/routing/app_router.dart` — ajouter case dans `_buildModalChild()`

**Alternatives considered**:
- Appel direct `AppModal.show()` — fonctionnel mais cree un second pattern de gestion modale.

## R3 — Selecteur photo (image_picker)

**Decision**: Utiliser le package `image_picker` (camera + galerie). Copier le fichier selectionne dans le repertoire documents de l'app via `path_provider` pour persistance.

**Rationale**:
- `image_picker` est le package standard Flutter pour la selection photo (camera/galerie).
- `path_provider` fournit `getApplicationDocumentsDirectory()` pour un stockage persistant.
- Le fichier original (cache temporaire) est copie dans `<docs>/products/` avec un nom unique (UUID).
- Le chemin final est stocke dans `product.imageUrl` et envoye a l'API.

**Workflow image**:
1. Utilisateur tap sur la zone image → ActionSheet (Camera / Galerie / Supprimer)
2. `ImagePicker().pickImage(source: ...)` → fichier temporaire XFile
3. Copie dans `<docs>/products/<uuid>.<ext>`
4. setState `_localImagePath = chemin copie`
5. A la sauvegarde, `imageUrl = _localImagePath`
6. En remplacement: supprimer ancien fichier via `File(oldPath).delete()`

**Alternatives considered**:
- `file_picker` — plus generique mais ne supporte pas la camera directement.
- Upload serveur — rejete par spec ("pas d'upload serveur").

## R4 — Formatter decimal (2 decimales max)

**Decision**: Creer `DecimalTextInputFormatter` dans `utils/decimal_input_formatter.dart`.

**Rationale**: FR-009 exige que la saisie des prix soit limitee a 2 decimales. Le projet n'a pas de formatter existant pour cela. Le `FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]'))` utilise dans `AccountFormScreen` autorise un nombre illimite de decimales.

**Implementation**:
- Etend `TextInputFormatter`
- `formatEditUpdate()` verifie le texte apres modification
- Regex : `^\d*[.,]?\d{0,N}$` (N = nombre de decimales configurable, defaut 2)
- Remplace la virgule par un point pour coherence de parsing
- Rejette la saisie si le pattern ne match pas (conserve l'ancien texte)

**Alternatives considered**:
- Validation a posteriori (au submit) — n'empeche pas l'utilisateur de saisir 3+ decimales, mauvaise UX.

## R5 — Gestion create vs edit mode

**Decision**: Parametrer via `Product? product` — null = creation, non-null = edition.

**Rationale**: Pattern identique a `TransactionForm` (`Transaction? transaction`), `SubscriptionForm` (`Subscription? subscription`), `DebtForm` (`Debt? debt`).

**Differences entre modes**:
| Aspect | Creation | Edition |
|--------|----------|---------|
| Champ stock initial | Visible, obligatoire (>= 0) | Masque (absent) |
| Pre-remplissage | Aucun | Tous les champs depuis product |
| Image | Zone vide / placeholder | Image existante affichee |
| Bouton supprimer | Non | Non (suppression depuis la liste) |
| Titre modal | "Nouveau produit" | "Modifier le produit" |

## R6 — Affichage image dans la liste (post-formulaire)

**Decision**: Mettre a jour `ProductListScreen` pour afficher `product.imageUrl` (image locale) quand disponible, fallback sur `product.icone ?? '📦'`.

**Rationale**: Apres ce feature, les produits auront `imageUrl` renseigne (chemin local). La liste doit afficher cette image au lieu du placeholder emoji.

**Implementation**: Le widget `ListItem` prend `icon: String` (emoji). Pour afficher une image, soit :
- Option A : Modifier `ListItem` pour supporter un widget `leading` (breaking change)
- Option B : Utiliser un `Stack` ou wrapper autour de `ListItem`
- Option C : Construire un widget produit-specific au lieu de `ListItem`

**Decision finale**: Petite modification dans `ProductListScreen` uniquement — remplacer le `ListItem` par un widget inline qui affiche soit l'image (ClipRRect + Image.file) soit le fallback emoji. Pas de modification de `ListItem` (utilise partout ailleurs).

## R7 — Dependances pubspec.yaml

**Decision**: Ajouter `image_picker` et `path_provider`.

**Versions cibles**: Dernieres stables compatibles Flutter >= 3.27.
- `image_picker: ^0.8.9` (ou latest)
- `path_provider: ^2.1.0` (ou latest)

**Impact**: Aucun conflit avec les dependances existantes. `path_provider` est une dependance courante sans overlap.
