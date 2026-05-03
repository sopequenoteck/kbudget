# Feature Specification: Formulaire Abonnement (Flutter)

**Feature Branch**: `045-flutter-subscription-form`
**Created**: 2026-02-23
**Status**: Draft
**Input**: User description: "KKS-106 — Modal avec toggle Mensuel/Annuel. Champs: nom, montant, date début, compte, catégorie, actif. Mode création et édition + suppression."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Créer un abonnement (Priority: P1)

L'utilisateur souhaite enregistrer un nouvel abonnement récurrent (Netflix, loyer, assurance, etc.) pour suivre ses charges fixes mensuelles ou annuelles. Depuis l'écran liste des abonnements, il ouvre un formulaire modal, remplit les informations (nom, montant, fréquence, date de début), et sauvegarde. L'abonnement apparaît immédiatement dans la liste.

**Why this priority** : C'est la fonctionnalité fondamentale — sans création, aucune autre interaction n'est possible. Permet à l'utilisateur de commencer à gérer ses charges récurrentes dès la première utilisation.

**Independent Test** : Peut être testé en ouvrant le formulaire, remplissant les champs obligatoires et vérifiant que l'abonnement apparaît dans la liste après sauvegarde.

**Acceptance Scenarios** :

1. **Given** l'utilisateur est sur l'écran abonnements, **When** il appuie sur le bouton d'ajout et remplit nom="Netflix", montant=15.99, fréquence=Mensuel, date=01/03/2026, **Then** l'abonnement est créé et visible dans la liste
2. **Given** le formulaire est ouvert en mode création, **When** l'utilisateur tente de sauvegarder sans remplir le nom, **Then** un message d'erreur de validation s'affiche sous le champ nom
3. **Given** le formulaire est ouvert en mode création, **When** l'utilisateur saisit un montant négatif ou zéro, **Then** un message d'erreur de validation s'affiche sous le champ montant
4. **Given** le formulaire est ouvert, **When** l'utilisateur ne sélectionne pas de catégorie, **Then** le système utilise la catégorie par défaut "Abonnement"

---

### User Story 2 - Modifier un abonnement existant (Priority: P2)

L'utilisateur souhaite corriger ou mettre à jour les informations d'un abonnement existant (changement de prix, de fréquence, de compte associé). Il sélectionne l'abonnement dans la liste, le formulaire s'ouvre pré-rempli avec les données actuelles, il effectue ses modifications et sauvegarde.

**Why this priority** : Les informations d'abonnement changent régulièrement (augmentation de prix, changement de compte bancaire). L'édition est essentielle pour maintenir des données exactes.

**Independent Test** : Peut être testé en créant un abonnement, puis en l'ouvrant en édition, modifiant le montant, et vérifiant que la modification est persistée.

**Acceptance Scenarios** :

1. **Given** un abonnement "Spotify" existe à 9.99€/mois, **When** l'utilisateur l'ouvre en édition et change le montant à 11.99€, **Then** le montant est mis à jour dans la liste
2. **Given** un abonnement est ouvert en édition, **When** l'utilisateur change la fréquence de Mensuel à Annuel, **Then** la fréquence est mise à jour après sauvegarde
3. **Given** un abonnement est ouvert en édition, **When** l'utilisateur modifie le compte associé, **Then** le nouveau compte est associé à l'abonnement

---

### User Story 3 - Supprimer un abonnement (Priority: P3)

L'utilisateur souhaite supprimer un abonnement qu'il n'a plus (résiliation d'un service). Depuis le formulaire en mode édition, il accède à l'option de suppression, confirme son choix, et l'abonnement disparaît de la liste.

**Why this priority** : Fonction de maintenance nécessaire mais moins fréquente que la création/édition. Un abonnement peut aussi être désactivé via le toggle "actif" au lieu d'être supprimé.

**Independent Test** : Peut être testé en créant un abonnement, puis en le supprimant via le formulaire d'édition et vérifiant sa disparition de la liste.

**Acceptance Scenarios** :

1. **Given** un abonnement "Canal+" existe, **When** l'utilisateur ouvre le formulaire d'édition et appuie sur supprimer, **Then** une confirmation est demandée avant suppression
2. **Given** la confirmation de suppression est affichée, **When** l'utilisateur confirme, **Then** l'abonnement est supprimé de la liste
3. **Given** la confirmation de suppression est affichée, **When** l'utilisateur annule, **Then** l'abonnement reste inchangé et le formulaire reste ouvert

---

### User Story 4 - Basculer la fréquence via un toggle visuel (Priority: P2)

L'utilisateur doit pouvoir choisir rapidement entre un abonnement mensuel et annuel via un toggle visuel intuitif (deux options côte à côte). Ce toggle remplace un menu déroulant classique pour offrir une saisie plus rapide et explicite.

**Why this priority** : La fréquence est un champ obligatoire critique qui distingue les abonnements mensuels des annuels. Un toggle visuel rend le choix immédiat et sans ambiguïté.

**Independent Test** : Peut être testé en vérifiant que le toggle affiche les deux options, que la sélection est visuelle et que la valeur est correctement transmise à la sauvegarde.

**Acceptance Scenarios** :

1. **Given** le formulaire est ouvert en mode création, **When** il s'affiche, **Then** le toggle fréquence est visible avec les options "Mensuel" et "Annuel", et "Mensuel" est sélectionné par défaut
2. **Given** le formulaire est ouvert, **When** l'utilisateur appuie sur "Annuel", **Then** l'option bascule visuellement vers "Annuel"

---

### Edge Cases

- Que se passe-t-il si l'utilisateur saisit un nom dépassant 255 caractères ? Le système affiche une erreur de validation sous le champ.
- Que se passe-t-il si le compte associé est désactivé après la création de l'abonnement ? L'abonnement reste valide, le compte désactivé n'apparaît plus dans le sélecteur en édition (sauf s'il est déjà associé).
- Que se passe-t-il si la sauvegarde échoue (erreur réseau, serveur indisponible) ? Un message d'erreur s'affiche et le formulaire reste ouvert avec les données saisies.
- Que se passe-t-il si l'utilisateur ferme le formulaire sans sauvegarder ? Les données saisies sont perdues sans confirmation (comportement aligné avec le formulaire de transaction existant).
- Que se passe-t-il si aucun compte n'est configuré ? Le champ compte reste vide (optionnel), l'abonnement peut être créé sans compte associé.
- Que se passe-t-il si aucune catégorie n'existe ? Le champ catégorie reste vide et le backend attribue la catégorie système "Abonnement".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** : Le système DOIT afficher un formulaire modal pour la création d'un abonnement, accessible depuis l'écran liste des abonnements
- **FR-002** : Le formulaire DOIT contenir les champs suivants : nom (texte, obligatoire), montant (numérique, obligatoire), fréquence (toggle Mensuel/Annuel, obligatoire), date de début (sélecteur de date, obligatoire), compte (sélecteur optionnel), catégorie (sélecteur optionnel), statut actif (interrupteur)
- **FR-003** : Le système DOIT valider les saisies après la première tentative de soumission, puis en temps réel : nom non vide (max 255 caractères), montant strictement positif, date de début renseignée
- **FR-004** : Le formulaire DOIT supporter le mode édition avec pré-remplissage de tous les champs à partir des données existantes de l'abonnement
- **FR-005** : En mode édition, le système DOIT offrir une option de suppression avec demande de confirmation
- **FR-006** : Le toggle de fréquence DOIT présenter deux options visuelles côte à côte : "Mensuel" et "Annuel", avec "Mensuel" comme valeur par défaut en création
- **FR-007** : Le sélecteur de compte DOIT afficher uniquement les comptes actifs, avec leur nom, icône et solde actuel
- **FR-008** : Le sélecteur de catégorie DOIT afficher les catégories disponibles avec leur icône et couleur
- **FR-009** : Après une sauvegarde réussie (création ou modification), le formulaire DOIT se fermer et la liste des abonnements DOIT être mise à jour immédiatement
- **FR-010** : En cas d'erreur lors de la sauvegarde, le système DOIT afficher un message d'erreur et conserver les données saisies dans le formulaire
- **FR-011** : Le statut "actif" DOIT être activé par défaut en mode création
- **FR-012** : Le formulaire DOIT s'adapter au format de l'appareil (bottom sheet sur mobile, dialogue sur tablette)

### Key Entities

- **Abonnement** : Charge récurrente avec un nom, un montant, une fréquence (mensuel ou annuel), une date de début, un statut actif/inactif. Peut être associé à un compte bancaire et une catégorie de dépense.
- **Compte** : Compte bancaire de l'utilisateur (courant, épargne, espèces) auquel l'abonnement peut être rattaché. Seuls les comptes actifs sont proposés dans le formulaire.
- **Catégorie** : Catégorie de classement de la dépense (ex: Loisirs, Transport). Si non spécifiée, le système attribue automatiquement la catégorie "Abonnement".

## Assumptions

- Le formulaire suit le même pattern UX que le formulaire de transaction existant (modal adaptative, validation à la soumission, disposition des boutons)
- La devise par défaut est l'euro (EUR), héritée du compte sélectionné ou par défaut
- L'application fonctionne en mode single-user, pas de gestion de permissions spécifique
- Les widgets communs existants (AppFormField, SelectPicker, CategoryPicker, AppToggle, AppModal) sont réutilisés tel quel
- L'abonnement dépend des modules existants : système modal (KKS-94), widgets FormField (KKS-95), notifiers CRUD (KKS-115), CategoryPicker (KKS-97), SelectPicker (KKS-96)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** : L'utilisateur peut créer un abonnement complet (tous les champs) en moins de 30 secondes
- **SC-002** : 100% des validations de champs affichent un retour visuel immédiat (avant soumission au serveur)
- **SC-003** : Le formulaire en mode édition affiche correctement toutes les données existantes de l'abonnement sélectionné
- **SC-004** : La suppression d'un abonnement nécessite une confirmation explicite avant exécution
- **SC-005** : En cas d'erreur réseau, les données saisies sont conservées et l'utilisateur peut réessayer sans ressaisie
