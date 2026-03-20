# Feature Specification: Banques sur les comptes — Flutter

**Feature Branch**: `083-flutter-bank-accounts`
**Created**: 2026-03-13
**Status**: Draft
**Input**: KKS-199 — Banques sur les comptes Flutter : sélecteur banque, affichage logo, assets SVG
**Parent Issue**: KKS-164
**Aligned with**: 082-angular-bank-accounts (KKS-198)

## Contexte

Le backend (KKS-081) fournit un registre de 29 banques prédéfinies avec logos SVG, un endpoint public `GET /api/banks`, et des champs enrichis sur les comptes (`bankCode`, `bankName`, `bankBrandColor`, `bankLogoUrl`, `bankCustomName`, `bankCustomLogo`). L'application Angular (KKS-082) a déjà implémenté cette feature avec un BankService signal-based, un BankSelect CVA, un AccountBankIcon et un formulaire enrichi.

Cette feature aligne l'application Flutter sur le même comportement : sélecteur de banque dans le formulaire compte, affichage du logo banque partout où un compte apparaît, et résolution visuelle identique (logo banque SVG / logo custom / emoji fallback).

## Prérequis

- Backend KKS-081 terminé : endpoint `GET /api/banks`, champs bank sur `AccountResponse`/`AccountRequest`, logos SVG servis depuis `/api/bank-logos/`
- Assets SVG des 29 banques embarqués dans `flutter/assets/banks/` (contrairement à Angular qui charge depuis le serveur, Flutter embarque les assets localement pour le rendu `flutter_svg`)

## User Scenarios & Testing

### User Story 1 - Associer une banque à un compte (Priority: P1)

L'utilisateur crée ou modifie un compte et choisit une banque dans un sélecteur dédié présenté en bottom sheet. Le sélecteur affiche les banques groupées par région (France, Afrique de l'Ouest, International), chacune avec son logo SVG et sa couleur brand. Si l'utilisateur choisit une banque connue, l'icône et la couleur du compte sont automatiquement dérivées de la banque (ces champs disparaissent du formulaire). S'il choisit "Autre", il peut saisir un nom personnalisé et optionnellement uploader un logo.

**Why this priority**: Fonctionnalité centrale — sans le sélecteur, aucune banque ne peut être associée aux comptes.

**Independent Test**: Ouvrir le formulaire de création de compte, sélectionner une banque connue (ex: Société Générale), vérifier que l'icône et la couleur sont masquées, soumettre, et vérifier que le compte est créé avec le bon `bankCode`.

**Acceptance Scenarios**:

1. **Given** le formulaire de création de compte est ouvert, **When** l'utilisateur tape sur le sélecteur de banque, **Then** une bottom sheet (AppModal) affiche les 29 banques groupées par région (France, Afrique de l'Ouest, International) avec l'option "Autre" en dernier.
2. **Given** le sélecteur de banque est ouvert, **When** l'utilisateur tape "soc" dans le champ de recherche, **Then** seules les banques dont le nom contient "soc" sont affichées (ex: Société Générale).
3. **Given** l'utilisateur a sélectionné "Société Générale", **When** le formulaire se met à jour, **Then** les champs icône et couleur sont masqués, et la prévisualisation du compte affiche le logo SG avec la couleur brand.
4. **Given** l'utilisateur a sélectionné "Autre", **When** le formulaire se met à jour, **Then** les champs icône, couleur, nom de banque personnalisé et logo personnalisé sont affichés.
5. **Given** un compte existant avec `bankCode = "SG"`, **When** l'utilisateur ouvre le formulaire d'édition, **Then** le sélecteur affiche "Société Générale" comme banque sélectionnée.

---

### User Story 2 - Voir le logo banque sur les comptes (Priority: P2)

Partout où un compte est affiché dans l'application Flutter (dashboard, paramètres comptes, sélecteurs de compte dans les formulaires transaction/dette/abonnement/transfert), l'utilisateur voit le logo de la banque associée au lieu de l'emoji générique. Pour les banques connues, c'est le logo SVG embarqué localement. Pour "Autre" avec logo custom, c'est le logo uploadé (base64 data URI décodé en Image.memory). Pour "Autre" sans logo, c'est l'emoji existant (comportement actuel inchangé).

**Why this priority**: L'identité visuelle des banques améliore la reconnaissance rapide des comptes, mais la feature est utilisable sans (les comptes fonctionnent déjà avec des emojis).

**Independent Test**: Créer un compte avec banque BNP, naviguer vers les paramètres comptes, vérifier que le logo BNP apparaît à côté du nom du compte.

**Acceptance Scenarios**:

1. **Given** un compte avec `bankCode = "BNP"`, **When** l'utilisateur consulte la liste des comptes (paramètres), **Then** le logo BNP (SVG local) est affiché à côté du nom du compte.
2. **Given** un compte avec `bankCode = "OTHER"` et un `bankCustomLogo` (base64 data URI), **When** l'utilisateur consulte la liste des comptes, **Then** le logo custom est affiché via Image.memory.
3. **Given** un compte avec `bankCode = "OTHER"` sans logo custom, **When** l'utilisateur consulte la liste des comptes, **Then** l'emoji du compte est affiché (comportement actuel).
4. **Given** un compte avec banque connue, **When** l'utilisateur ouvre un sélecteur de compte (formulaire transaction, dette, abonnement, transfert), **Then** le logo banque est visible dans le sélecteur.
5. **Given** un compte avec banque connue, **When** l'utilisateur consulte le dashboard (hero account section), **Then** le logo banque remplace l'emoji dans la carte du compte par défaut et dans les lignes des autres comptes.

---

### User Story 3 - Recherche et filtrage dans le sélecteur (Priority: P3)

Le sélecteur de banque permet de trouver rapidement une banque parmi les 29 options via un champ de recherche textuel en haut de la bottom sheet. La recherche filtre en temps réel sur le nom de la banque, insensible à la casse.

**Why this priority**: Amélioration d'ergonomie — les 29 banques sont déjà groupées par région, le filtrage n'est qu'un confort additionnel.

**Independent Test**: Ouvrir le sélecteur, taper "eco", vérifier que seul "Ecobank" apparaît.

**Acceptance Scenarios**:

1. **Given** le sélecteur de banque est ouvert avec toutes les banques visibles, **When** l'utilisateur tape "rev", **Then** seule "Revolut" est affichée.
2. **Given** le sélecteur affiche des résultats filtrés, **When** l'utilisateur efface le champ de recherche, **Then** toutes les banques réapparaissent groupées par région.
3. **Given** l'utilisateur tape un texte qui ne correspond à aucune banque, **When** le filtre est appliqué, **Then** un message "Aucune banque trouvée" est affiché, et l'option "Autre" reste toujours visible.

---

### Edge Cases

- Que se passe-t-il si l'endpoint `GET /api/banks` est indisponible ? → Le sélecteur affiche un message d'erreur et propose uniquement l'option "Autre" en fallback.
- Que se passe-t-il si un compte existant a un `bankCode` inconnu (supprimé du registre) ? → Afficher le code brut et traiter comme "Autre".
- Que se passe-t-il si l'asset SVG d'une banque est absent du bundle Flutter ? → Afficher un placeholder générique (icône banque Phosphor par défaut).
- Comment se comporte le formulaire quand l'utilisateur passe de banque connue à "Autre" puis revient ? → Les champs icône/couleur se masquent/affichent dynamiquement, les valeurs custom précédemment saisies sont conservées tant que le formulaire est ouvert.
- Que se passe-t-il si `bankCustomLogo` est un base64 invalide ? → Afficher l'emoji du compte en fallback.
- Que se passe-t-il en mode local (Drift) ? → Les champs bank sont stockés en SQLite. Les assets SVG sont embarqués dans l'app (pas besoin de réseau pour l'affichage des logos). La table Drift `accounts` reçoit 3 nouvelles colonnes nullable.

## Requirements

### Functional Requirements

- **FR-001**: Le système DOIT fournir un modèle Bank (Freezed) avec code, nom, pays, couleur brand et URL logo, et un repository (interface + implémentation remote) pour récupérer la liste des banques depuis `GET /api/banks`.
- **FR-002**: Le système DOIT fournir un `banksProvider` (FutureProvider) qui charge la liste des banques une seule fois (données statiques, pas de re-fetch).
- **FR-003**: Le système DOIT afficher un sélecteur de banque (BankSelectPicker) dans le formulaire de création et d'édition de compte, placé en haut du formulaire, sous forme de bottom sheet (AppModal).
- **FR-004**: Le sélecteur de banque DOIT grouper les banques par région (France, Afrique de l'Ouest, International) avec "Autre" en dernière position, et chaque item DOIT afficher le logo SVG (SvgPicture.asset 24×24), le nom et un dot de couleur brand.
- **FR-005**: Le sélecteur de banque DOIT proposer un champ de recherche textuel filtrant les banques par nom (insensible à la casse).
- **FR-006**: Lorsqu'une banque connue (≠ OTHER) est sélectionnée, le formulaire DOIT masquer les champs icône et couleur (la couleur est auto-remplie par la couleur brand de la banque).
- **FR-007**: Lorsque "Autre" est sélectionné, le formulaire DOIT afficher les champs icône (EmojiInput), couleur (ColorPalettePicker), nom de banque personnalisé (AppFormField) et logo personnalisé (image compressée en JPEG data URI via image_picker, maxWidth=512, quality=80).
- **FR-008**: Le système DOIT fournir un widget réutilisable AccountBankIcon (StatelessWidget) qui résout l'affichage : logo SVG local (SvgPicture.asset) pour les banques connues, logo custom (Image.memory(base64Decode(...))) pour "Autre" avec logo uploadé, ou emoji (Text) pour "Autre" sans logo.
- **FR-009**: Le widget AccountBankIcon DOIT être utilisé partout où un compte est affiché : dashboard (hero account section), liste des comptes (paramètres), sélecteurs de compte (formulaires transaction, dette, abonnement, transfert).
- **FR-010**: Le modèle Account (Freezed) DOIT être enrichi avec les champs bank : `bankCode` (String, défaut "OTHER"), `bankName` (String?), `bankCountry` (String?), `bankBrandColor` (String?), `bankLogoUrl` (String?), `bankCustomName` (String?), `bankCustomLogo` (String?).
- **FR-011**: Les DTOs (AccountRequest/AccountResponse) DOIVENT être enrichis avec les champs bank correspondants.
- **FR-012**: La table Drift `accounts` DOIT être enrichie avec 3 colonnes nullable : `bankCode`, `bankCustomName`, `bankCustomLogo`.
- **FR-013**: Les logos SVG des 29 banques DOIVENT être embarqués dans `flutter/assets/banks/` et déclarés dans `pubspec.yaml`.
- **FR-014**: Le package `flutter_svg` DOIT être ajouté au `pubspec.yaml` pour le rendu des logos SVG.
- **FR-015**: Les logos banque DOIVENT être dimensionnés de manière cohérente : 24×24 dans les sélecteurs et listes, 32×32 dans les formulaires et écrans de détail.
- **FR-016**: L'option "Autre" DOIT toujours rester visible même lors du filtrage par recherche.
- **FR-017**: Le SelectPickerItem existant DOIT être étendu avec un champ `imageUrl` optionnel pour supporter l'affichage de logos dans les sélecteurs de compte enrichis.

### Key Entities

- **Bank** : Banque prédéfinie avec code unique, nom, pays (ou null pour international), couleur de marque et URL du logo SVG. 29 banques dans le registre. Modèle Freezed avec factory `fromJson`.
- **Account (enrichi)** : Compte enrichi avec association bancaire — code banque (défaut "OTHER"), nom résolu, pays, couleur brand, URL logo. Pour les banques custom ("Autre") : nom personnalisé et logo personnalisé en base64.

## Assumptions

- Les logos SVG sont embarqués localement dans `flutter/assets/banks/{code_lowercase}.svg` (contrairement à Angular qui les charge depuis le serveur). Cela garantit un rendu instantané sans réseau.
- Les mêmes 29 fichiers SVG que ceux servis par le backend (`static/bank-logos/`) sont copiés dans les assets Flutter.
- Le formulaire de compte existant gère déjà l'EmojiInput et le ColorPalettePicker — la logique de masquage conditionnel vient s'ajouter sans réécriture majeure.
- La liste des banques est stable (rarement mise à jour) — un FutureProvider chargé une fois est suffisant.
- Le `bankCode` par défaut pour les comptes existants sans banque est "OTHER" (migration backend V19).
- L'utilitaire `image_utils.dart` existant (utilisé pour les produits) est réutilisé pour la compression du logo custom.
- Le pattern BankSelectPicker suit le même design que les autres bottom sheets de l'app (AppModal, ConsumerWidget).
- Le AccountBankIcon suit la même cascade de résolution que l'Angular : SVG banque → logo custom → emoji fallback.

## Success Criteria

### Measurable Outcomes

- **SC-001**: L'utilisateur peut associer une banque à un compte en moins de 3 interactions (ouvrir sélecteur → choisir banque → valider).
- **SC-002**: 100% des comptes affichent la bonne représentation visuelle (logo banque / logo custom / emoji fallback) dans tous les écrans de l'application.
- **SC-003**: Le sélecteur de banque permet de trouver n'importe quelle banque en moins de 5 secondes grâce au groupement et au filtre de recherche.
- **SC-004**: Le passage entre banque connue et "Autre" dans le formulaire est fluide : les champs se masquent/affichent instantanément sans rechargement.
- **SC-005**: Les tests widget couvrent les composants clés (AccountBankIcon, BankSelectPicker).
- **SC-006**: Le comportement Flutter est visuellement et fonctionnellement aligné avec l'implémentation Angular (KKS-082) : même groupement, même résolution de logo, même logique de masquage dans le formulaire.
