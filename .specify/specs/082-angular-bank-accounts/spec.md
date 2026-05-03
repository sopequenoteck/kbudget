# Feature Specification: Banques sur les comptes — Angular

**Feature Branch**: `082-angular-bank-accounts`
**Created**: 2026-03-13
**Status**: Draft
**Input**: KKS-198 — Banques sur les comptes Angular : sélecteur banque, affichage logo, assets SVG
**Parent Issue**: KKS-164

## Contexte

Le backend (KKS-081) fournit déjà un registre de 29 banques prédéfinies avec logos SVG, un endpoint public `GET /api/banks`, et des champs enrichis sur les comptes (`bankCode`, `bankName`, `bankBrandColor`, `bankLogoUrl`, `bankCustomName`, `bankCustomLogo`). Cette feature intègre côté Angular le sélecteur de banque dans le formulaire compte, l'affichage du logo banque partout où un compte apparaît, et la résolution visuelle (logo banque / logo custom / emoji fallback).

## Prérequis

- Backend KKS-081 terminé : endpoint `GET /api/banks`, champs bank sur `AccountResponse`/`AccountRequest`, logos SVG servis depuis `/api/bank-logos/`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Associer une banque à un compte (Priority: P1)

L'utilisateur crée ou modifie un compte et choisit une banque dans un sélecteur dédié. Le sélecteur présente les banques groupées par région (France, Afrique de l'Ouest, International), chacune avec son logo et sa couleur. Si l'utilisateur choisit une banque connue, l'icône et la couleur du compte sont automatiquement dérivées de la banque (ces champs disparaissent du formulaire). S'il choisit "Autre", il peut saisir un nom personnalisé et optionnellement uploader un logo.

**Why this priority**: Fonctionnalité centrale — sans le sélecteur, aucune banque ne peut être associée aux comptes.

**Independent Test**: Ouvrir le formulaire de création de compte, sélectionner une banque connue (ex: Société Générale), vérifier que l'icône et la couleur sont masquées, soumettre, et vérifier que le compte est créé avec le bon `bankCode`.

**Acceptance Scenarios**:

1. **Given** le formulaire de création de compte est ouvert, **When** l'utilisateur ouvre le sélecteur de banque, **Then** la liste affiche les 29 banques groupées par région (France, Afrique de l'Ouest, International) avec l'option "Autre" en dernier.
2. **Given** le sélecteur de banque est ouvert, **When** l'utilisateur tape "soc" dans le champ de recherche, **Then** seules les banques dont le nom contient "soc" sont affichées (ex: Société Générale).
3. **Given** l'utilisateur a sélectionné "Société Générale", **When** le formulaire se met à jour, **Then** les champs icône et couleur sont masqués, et la prévisualisation du compte affiche le logo SG avec la couleur brand.
4. **Given** l'utilisateur a sélectionné "Autre", **When** le formulaire se met à jour, **Then** les champs icône, couleur, nom de banque personnalisé et logo personnalisé sont affichés.
5. **Given** un compte existant avec `bankCode = "SG"`, **When** l'utilisateur ouvre le formulaire d'édition, **Then** le sélecteur affiche "Société Générale" comme banque sélectionnée.

---

### User Story 2 - Voir le logo banque sur les comptes (Priority: P2)

Partout où un compte est affiché dans l'application (paramètres comptes, sélecteurs de compte dans les formulaires, dashboard), l'utilisateur voit le logo de la banque associée au lieu de l'emoji générique. Pour les banques connues, c'est le logo SVG officiel. Pour "Autre" avec logo custom, c'est le logo uploadé. Pour "Autre" sans logo, c'est l'emoji existant (comportement actuel inchangé).

**Why this priority**: L'identité visuelle des banques améliore la reconnaissance rapide des comptes, mais la feature est utilisable sans (les comptes fonctionnent déjà avec des emojis).

**Independent Test**: Créer un compte avec banque SG, naviguer vers les paramètres comptes, vérifier que le logo SG apparaît à côté du nom du compte.

**Acceptance Scenarios**:

1. **Given** un compte avec `bankCode = "BNP"`, **When** l'utilisateur consulte la liste des comptes (paramètres), **Then** le logo BNP (SVG) est affiché à côté du nom du compte.
2. **Given** un compte avec `bankCode = "OTHER"` et un `bankCustomLogo` (base64 data URI), **When** l'utilisateur consulte la liste des comptes, **Then** le logo custom est affiché.
3. **Given** un compte avec `bankCode = "OTHER"` sans logo custom, **When** l'utilisateur consulte la liste des comptes, **Then** l'emoji du compte est affiché (comportement actuel).
4. **Given** un compte avec banque connue, **When** l'utilisateur ouvre un sélecteur de compte (formulaire transaction, formulaire dette, formulaire transfert), **Then** le logo banque est visible dans le sélecteur.

---

### User Story 3 - Recherche et filtrage dans le sélecteur (Priority: P3)

Le sélecteur de banque permet de trouver rapidement une banque parmi les 29 options via un champ de recherche textuel. La recherche filtre en temps réel sur le nom de la banque.

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
- Que se passe-t-il si le logo SVG d'une banque ne charge pas ? → Afficher un placeholder générique (icône banque par défaut).
- Comment se comporte le formulaire quand l'utilisateur passe de banque connue à "Autre" puis revient ? → Les champs icône/couleur se masquent/affichent dynamiquement, les valeurs custom précédemment saisies sont conservées tant que le formulaire est ouvert.
- Que se passe-t-il si `bankCustomLogo` est un base64 invalide ? → Afficher l'emoji du compte en fallback.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT fournir un service de récupération de la liste des banques disponibles, avec mise en cache locale pour éviter les appels réseau répétés.
- **FR-002**: Le système DOIT afficher un sélecteur de banque dans le formulaire de création et d'édition de compte, placé en haut du formulaire.
- **FR-003**: Le sélecteur de banque DOIT grouper les banques par région (France, Afrique de l'Ouest, International) avec "Autre" en dernière position.
- **FR-004**: Le sélecteur de banque DOIT proposer un champ de recherche textuel filtrant les banques par nom.
- **FR-005**: Lorsqu'une banque connue (≠ OTHER) est sélectionnée, le formulaire DOIT masquer les champs icône et couleur (ces valeurs sont dérivées de la banque).
- **FR-006**: Lorsque "Autre" est sélectionné, le formulaire DOIT afficher les champs icône, couleur, nom personnalisé et logo personnalisé (image compressée en JPEG data URI via canvas, maxWidth=512).
- **FR-007**: Le système DOIT fournir un composant réutilisable de résolution d'affichage de compte qui affiche le logo banque (SVG) pour les banques connues, le logo custom (data URI) pour "Autre" avec logo uploadé, ou l'emoji pour "Autre" sans logo.
- **FR-008**: Le composant de résolution d'affichage DOIT être utilisé partout où un compte est affiché dans l'application (paramètres, sélecteurs de formulaire, listes).
- **FR-009**: Le modèle de données Angular DOIT être mis à jour pour inclure les 7 champs banque sur la réponse compte (`bankCode`, `bankName`, `bankCountry`, `bankBrandColor`, `bankLogoUrl`, `bankCustomName`, `bankCustomLogo`) et les 3 champs sur la requête (`bankCode`, `bankCustomName`, `bankCustomLogo`).
- **FR-010**: Les logos banque DOIVENT être dimensionnés de manière cohérente : 24×24 dans les sélecteurs et listes, 32×32 dans les formulaires et écrans de détail.
- **FR-011**: L'option "Autre" DOIT toujours rester visible même lors du filtrage par recherche.

### Key Entities

- **Bank** : Banque prédéfinie avec code unique, nom, pays (ou null pour international), couleur de marque et URL du logo SVG. 29 banques dans le registre.
- **Account (enrichi)** : Compte enrichi avec association bancaire — code banque, nom résolu, pays, couleur brand, URL logo. Pour les banques custom ("Autre") : nom personnalisé et logo personnalisé en base64.

## Assumptions

- Les logos SVG sont servis par le backend depuis `/api/bank-logos/{code}.svg` et n'ont pas besoin d'être embarqués dans les assets Angular (contrairement à ce que l'issue Linear suggère). L'URL est fournie dans `bankLogoUrl` de `AccountResponse` et `BankResponse`.
- Le formulaire de compte existant gère déjà l'emoji picker et le color picker — la logique de masquage conditionnel vient s'ajouter sans réécriture majeure.
- La liste des banques est stable (rarement mise à jour) — un seul appel au démarrage avec cache signal est suffisant.
- Le `bankCode` par défaut pour les comptes existants sans banque est "OTHER" (migration backend V19).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut associer une banque à un compte en moins de 3 interactions (ouvrir sélecteur → choisir banque → valider).
- **SC-002**: 100% des comptes affichent la bonne représentation visuelle (logo banque / logo custom / emoji fallback) dans tous les écrans de l'application.
- **SC-003**: Le sélecteur de banque permet de trouver n'importe quelle banque en moins de 5 secondes grâce au groupement et au filtre de recherche.
- **SC-004**: Le passage entre banque connue et "Autre" dans le formulaire est fluide : les champs se masquent/affichent instantanément sans rechargement.
- **SC-005**: Les tests unitaires couvrent les composants clés (sélecteur de banque, composant de résolution logo, formulaire enrichi).
