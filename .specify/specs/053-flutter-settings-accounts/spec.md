# Feature Specification: Flutter Settings — Gestion Comptes

**Feature Branch**: `053-flutter-settings-accounts`
**Created**: 2026-02-23
**Status**: Draft
**Input**: User description: "Sous-page Settings: liste des comptes + CRUD. Formulaire: nom, type (Courant/Épargne/Espèces), icône, couleur, solde initial. Ajustement de solde."
**Linear**: KKS-113

## Clarifications

### Session 2026-02-23

- Q: Comment déclencher "Définir par défaut" et "Supprimer" depuis la liste sur mobile ? → A: Tap sur l'item = navigation vers formulaire d'édition. Menu popup trailing (⋮) sur chaque item pour "Définir par défaut" et "Supprimer" (adaptation du pattern Angular qui utilise 3 boutons d'action par item).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter la liste des comptes (Priority: P1)

L'utilisateur accède à la sous-page "Comptes" depuis les paramètres pour visualiser tous ses comptes bancaires. Chaque compte affiche son icône emoji, son nom, son type, son solde actuel formaté avec la devise, et des badges visuels indiquant s'il est par défaut ou inactif. Les comptes inactifs sont visuellement atténués.

**Why this priority**: C'est la porte d'entrée de la feature — sans liste, aucune autre action n'est possible. Délivre immédiatement de la valeur en donnant une vue d'ensemble des comptes.

**Independent Test**: Naviguer vers Settings > Comptes et vérifier que tous les comptes s'affichent avec les bonnes informations. Couvre le chargement, les états vide/erreur, et le skeleton loading.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 3 comptes (dont 1 inactif), **When** il ouvre la page Comptes, **Then** les 3 comptes s'affichent avec icône, nom, type, solde et devise, le compte par défaut porte un badge "Défaut", le compte inactif porte un badge "Inactif" et est visuellement atténué
2. **Given** l'utilisateur n'a aucun compte, **When** il ouvre la page Comptes, **Then** un état vide s'affiche avec un message d'incitation à créer un premier compte
3. **Given** le chargement est en cours, **When** l'utilisateur arrive sur la page, **Then** un skeleton loading animé s'affiche
4. **Given** une erreur réseau survient, **When** le chargement échoue, **Then** un message d'erreur s'affiche avec un bouton "Réessayer"

---

### User Story 2 - Créer un nouveau compte (Priority: P1)

L'utilisateur crée un nouveau compte via un formulaire accessible depuis la liste. Le formulaire comprend : sélection du type (Courant/Épargne/Espèces) avec icône et couleur par défaut selon le type, personnalisation de l'icône emoji et de la couleur, saisie du nom, du solde initial et de la devise. Un aperçu en temps réel du compte est visible en haut du formulaire.

**Why this priority**: Fonctionnalité fondamentale — un utilisateur doit pouvoir ajouter des comptes pour gérer son budget. Sans création, la liste reste vide.

**Independent Test**: Ouvrir le formulaire de création, remplir tous les champs, valider, et vérifier que le compte apparaît dans la liste.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la liste des comptes, **When** il appuie sur le bouton d'ajout, **Then** le formulaire de création s'ouvre avec les champs type, icône, couleur, nom, solde initial et devise
2. **Given** l'utilisateur sélectionne un type de compte, **When** il choisit "Épargne", **Then** l'icône et la couleur se pré-remplissent avec les valeurs par défaut du type (🐷, vert)
3. **Given** le formulaire est rempli correctement, **When** l'utilisateur valide, **Then** le compte est créé et l'utilisateur revient à la liste mise à jour
4. **Given** le nom est vide ou dépasse 50 caractères, **When** l'utilisateur tente de valider, **Then** un message d'erreur de validation s'affiche sous le champ
5. **Given** un compte actif porte déjà le même nom, **When** l'utilisateur tente de créer, **Then** une erreur de doublon s'affiche

---

### User Story 3 - Modifier un compte existant (Priority: P2)

L'utilisateur modifie un compte existant. Le formulaire d'édition reprend les mêmes champs que la création, sauf que le type et la devise ne sont plus modifiables. Le solde initial est affiché en lecture seule. L'utilisateur peut modifier le nom, l'icône, la couleur et l'état actif/inactif (sauf pour le compte par défaut qui ne peut pas être désactivé).

**Why this priority**: Permet de corriger les informations d'un compte après création. Important mais secondaire par rapport à la création et la consultation.

**Independent Test**: Ouvrir un compte existant en édition, modifier le nom et l'icône, sauvegarder, et vérifier les changements dans la liste.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la liste, **When** il tape sur un compte, **Then** il navigue vers le formulaire d'édition pré-rempli avec les valeurs actuelles
2. **Given** le formulaire d'édition est ouvert, **When** le type est affiché, **Then** il est en lecture seule (non modifiable)
3. **Given** le compte est le compte par défaut, **When** l'utilisateur tente de le désactiver, **Then** la case actif est désactivée avec un message explicatif
4. **Given** les modifications sont valides, **When** l'utilisateur sauvegarde, **Then** le compte est mis à jour et la liste est rafraîchie

---

### User Story 4 - Ajuster le solde d'un compte (Priority: P2)

En mode édition, l'utilisateur peut ajuster le solde de son compte. Le solde actuel est affiché en lecture seule. Un champ "Nouveau solde" permet de saisir la valeur souhaitée. L'ajustement crée automatiquement une transaction d'ajustement côté serveur.

**Why this priority**: Fonctionnalité essentielle pour corriger les écarts entre le solde réel et le solde calculé, mais ne bloque pas l'utilisation basique de l'application.

**Independent Test**: Ouvrir un compte en édition, saisir un nouveau solde différent de l'actuel, sauvegarder, et vérifier que le solde a changé.

**Acceptance Scenarios**:

1. **Given** un compte a un solde actuel de 500 €, **When** l'utilisateur ouvre le formulaire d'édition, **Then** le solde actuel "500,00 €" est affiché en lecture seule
2. **Given** l'utilisateur saisit 600 comme nouveau solde, **When** il sauvegarde, **Then** un ajustement de +100 est créé et le solde passe à 600 €
3. **Given** l'utilisateur saisit le même solde que l'actuel, **When** il sauvegarde, **Then** aucun ajustement n'est créé

---

### User Story 5 - Supprimer un compte (Priority: P3)

L'utilisateur peut supprimer un compte depuis le menu popup (⋮) de la liste ou depuis le formulaire d'édition. Une confirmation est demandée avant suppression. Certains comptes ne peuvent pas être supprimés (compte par défaut, compte avec des transactions ou abonnements liés).

**Why this priority**: Fonctionnalité de nettoyage, utilisée rarement. La plupart des utilisateurs préféreront désactiver un compte plutôt que le supprimer.

**Independent Test**: Supprimer un compte sans transactions liées et vérifier sa disparition de la liste.

**Acceptance Scenarios**:

1. **Given** l'utilisateur veut supprimer un compte sans transactions, **When** il confirme la suppression, **Then** le compte est supprimé et disparaît de la liste
2. **Given** le compte est le compte par défaut, **When** l'utilisateur tente de le supprimer, **Then** une erreur s'affiche expliquant que le compte par défaut ne peut pas être supprimé
3. **Given** le compte a des transactions liées, **When** l'utilisateur tente de le supprimer, **Then** une erreur s'affiche indiquant que le compte ne peut pas être supprimé
4. **Given** l'utilisateur appuie sur supprimer, **When** la confirmation apparaît, **Then** il peut annuler ou confirmer la suppression

---

### User Story 6 - Définir un compte par défaut (Priority: P3)

L'utilisateur peut marquer un compte actif comme compte par défaut via le menu popup (⋮) de chaque item dans la liste. Ce compte sera pré-sélectionné dans les formulaires de transaction et d'abonnement. Un seul compte peut être par défaut à la fois. L'action n'est visible que pour les comptes actifs non-défaut.

**Why this priority**: Améliore le confort d'utilisation mais n'est pas bloquant. Le premier compte créé est automatiquement par défaut.

**Independent Test**: Depuis la liste, définir un compte non-défaut comme défaut et vérifier que l'ancien perd son badge.

**Acceptance Scenarios**:

1. **Given** un compte actif non-défaut, **When** l'utilisateur ouvre le menu popup (⋮) et choisit "Définir par défaut", **Then** ce compte reçoit le badge "Défaut" et l'ancien compte le perd
2. **Given** un compte inactif, **When** l'utilisateur ouvre le menu popup (⋮), **Then** l'option "Définir par défaut" n'est pas disponible

---

### Edge Cases

- Que se passe-t-il si le réseau coupe pendant la sauvegarde ? → Un message d'erreur s'affiche, le formulaire reste ouvert avec les données saisies.
- Que se passe-t-il si l'utilisateur tente de créer un compte avec un nom identique (casse différente) à un compte actif existant ? → Erreur de doublon renvoyée par l'API.
- Que se passe-t-il si un autre appareil modifie un compte pendant l'édition ? → Le dernier enregistrement l'emporte (last-write-wins).
- Que se passe-t-il si l'utilisateur saisit un solde initial négatif ? → Accepté (un découvert est un cas légitime).
- Que se passe-t-il si la palette de couleurs ne contient pas la couleur actuelle du compte ? → La couleur actuelle est affichée comme sélectionnée dans le formulaire.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher la liste de tous les comptes de l'utilisateur (actifs et inactifs) avec icône, nom, type, solde formaté et devise
- **FR-002**: Le système DOIT permettre la création d'un compte avec les champs : nom (requis, 1-50 car.), type (requis), icône emoji, couleur hex, solde initial (défaut 0), devise
- **FR-003**: Le système DOIT pré-remplir l'icône et la couleur avec les valeurs par défaut du type sélectionné (Courant: 🏦/#3b82f6, Épargne: 🐷/#22c55e, Espèces: 💵/#f59e0b)
- **FR-004**: Le système DOIT permettre la modification du nom, de l'icône, de la couleur et du statut actif/inactif d'un compte existant
- **FR-005**: Le système DOIT empêcher la modification du type et de la devise d'un compte existant
- **FR-006**: Le système DOIT afficher le solde actuel en lecture seule en mode édition et permettre la saisie d'un nouveau solde pour ajustement
- **FR-007**: Le système DOIT empêcher la désactivation du compte par défaut avec un message explicatif
- **FR-008**: Le système DOIT permettre la suppression d'un compte via le menu popup (⋮) de la liste ou le formulaire d'édition, avec confirmation préalable
- **FR-009**: Le système DOIT empêcher la suppression du compte par défaut et des comptes ayant des transactions ou abonnements liés, avec un message d'erreur approprié
- **FR-010**: Le système DOIT permettre de définir un compte actif comme compte par défaut via le menu popup (⋮) de chaque item dans la liste
- **FR-017**: Chaque item de la liste DOIT afficher un menu popup (⋮) regroupant les actions contextuelles : "Définir par défaut" (si actif et non-défaut), "Supprimer"
- **FR-011**: Le système DOIT afficher un skeleton loading pendant le chargement initial de la liste
- **FR-012**: Le système DOIT afficher un état vide lorsque l'utilisateur n'a aucun compte
- **FR-013**: Le système DOIT afficher un état d'erreur avec option de réessai en cas d'échec réseau
- **FR-014**: Le système DOIT afficher un aperçu en temps réel du compte dans le formulaire (icône, nom, couleur)
- **FR-015**: Le système DOIT proposer une palette de 12 couleurs prédéfinies pour la personnalisation du compte : #3b82f6 (blue), #10b981 (green), #f59e0b (amber), #ef4444 (red), #f97316 (orange), #84cc16 (lime), #22c55e (green-light), #06b6d4 (cyan), #6366f1 (indigo), #8b5cf6 (purple), #ec4899 (pink), #6b7280 (gray). Si la couleur actuelle du compte n'est pas dans la palette, elle est affichée comme sélectionnée en position supplémentaire
- **FR-016**: Le système DOIT afficher des badges visuels "Défaut" et "Inactif" sur les comptes concernés dans la liste

### Key Entities

- **Compte (Account)**: Représente un compte bancaire de l'utilisateur. Attributs : identifiant unique, nom (1-50 car.), type (Courant/Épargne/Espèces), solde initial, solde courant (calculé), icône emoji, couleur hexadécimale, indicateur par défaut, indicateur actif, devise. Un seul compte par défaut par utilisateur.
- **Ajustement de solde**: Opération qui crée une transaction d'ajustement pour corriger le solde calculé d'un compte. Le montant est la différence entre le nouveau solde souhaité et le solde actuel.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut créer un nouveau compte en moins de 30 secondes (formulaire simple, pré-remplissage des défauts)
- **SC-002**: L'utilisateur peut ajuster le solde d'un compte en 2 interactions (ouvrir le compte, saisir le nouveau solde)
- **SC-003**: La liste des comptes s'affiche en moins de 2 secondes après navigation
- **SC-004**: Toutes les opérations CRUD (création, modification, suppression) se reflètent immédiatement dans la liste sans rechargement manuel
- **SC-005**: Les messages d'erreur sont suffisamment explicites pour que l'utilisateur comprenne pourquoi une action est refusée (suppression, désactivation)
- **SC-006**: Le formulaire conserve les données saisies en cas d'erreur réseau, permettant une nouvelle tentative sans resaisie

## Assumptions

- L'application fonctionne en mode serveur uniquement (API REST) pour la gestion des comptes — les données doivent toujours être fraîches
- La devise par défaut de l'utilisateur est utilisée si aucune devise n'est spécifiée à la création
- La palette de couleurs prédéfinies contient 12 couleurs couvrant les cas d'usage courants
- Le formulaire de compte est affiché en plein écran (navigation push) et non en modal, conformément au pattern mobile Flutter
- Les transferts inter-comptes ne font pas partie de cette feature (déjà couverts par KKS-109)
