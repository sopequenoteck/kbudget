# Feature Specification: Formulaire Virement

**Feature Branch**: `050-flutter-transfer-form`
**Created**: 2026-02-23
**Status**: Draft
**Input**: User description: "Flutter: Formulaire Virement. Modal de virement entre comptes. Champs: compte source, compte destination, montant, date. Crée 2 transactions liées par transferId."
**Linear**: KKS-109
**Bloqué par**: KKS-94 (Système Modal), KKS-95 (Widget FormField), KKS-96 (Widget SelectPicker), KKS-115 (Notifiers CRUD)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Effectuer un virement entre comptes (Priority: P1)

L'utilisateur souhaite transférer de l'argent d'un compte à un autre. Il ouvre le formulaire de virement depuis le menu d'actions rapides (FAB), sélectionne le compte source, le compte destination, saisit le montant, et valide. Le système crée automatiquement deux transactions liées (une dépense sur le compte source, une recette sur le compte destination).

**Why this priority**: C'est la fonctionnalité principale et la raison d'être de cet écran. Sans le formulaire de saisie, aucun virement ne peut être réalisé.

**Independent Test**: Peut être testé en ouvrant le formulaire via le FAB, en remplissant les 3 champs obligatoires (source, destination, montant), en validant, et en vérifiant que les deux transactions apparaissent dans la liste des transactions.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a au moins 2 comptes actifs, **When** il tape sur le FAB puis choisit "Virement", **Then** le formulaire de virement s'ouvre en modal avec les champs compte source, compte destination, montant et note
2. **Given** le formulaire est ouvert, **When** l'utilisateur sélectionne un compte source, un compte destination différent, saisit un montant valide et valide, **Then** le virement est envoyé au serveur, la modal se ferme, et la liste des transactions est rafraîchie
3. **Given** le virement est en cours d'envoi, **When** le serveur traite la requête, **Then** un indicateur de chargement s'affiche sur le bouton de validation et les champs sont désactivés
4. **Given** le virement a été créé avec succès, **When** la modal se ferme, **Then** les deux transactions (dépense + recette) sont visibles dans la liste des transactions avec le même identifiant de virement

---

### User Story 2 - Validation du formulaire (Priority: P2)

Le système empêche l'utilisateur de soumettre un virement invalide. Les erreurs sont affichées de manière claire et contextuelle pour guider l'utilisateur vers une correction.

**Why this priority**: La validation protège l'intégrité des données et évite les erreurs utilisateur. Sans elle, des virements incohérents pourraient être créés.

**Independent Test**: Peut être testé en tentant de soumettre le formulaire avec des données invalides (champs vides, même compte, montant à 0) et en vérifiant que les messages d'erreur appropriés s'affichent.

**Acceptance Scenarios**:

1. **Given** le formulaire est vide, **When** l'utilisateur tente de valider, **Then** les erreurs de validation s'affichent sur les champs obligatoires (compte source, compte destination, montant)
2. **Given** l'utilisateur a sélectionné le même compte source et destination, **When** il tente de valider, **Then** un message d'erreur indique que les comptes doivent être différents
3. **Given** l'utilisateur saisit un montant inférieur ou égal à 0, **When** il tente de valider, **Then** un message d'erreur indique que le montant doit être supérieur à 0
4. **Given** la requête serveur échoue, **When** l'erreur est reçue, **Then** un message d'erreur s'affiche dans le formulaire et les champs restent remplis pour permettre une nouvelle tentative

---

### User Story 3 - Accès conditionnel au formulaire (Priority: P3)

Le formulaire de virement n'est accessible que si l'utilisateur dispose d'au moins 2 comptes actifs. Si cette condition n'est pas remplie, l'option de virement n'est pas disponible ou un message informatif est affiché.

**Why this priority**: C'est une condition préalable qui concerne un cas limite. La majorité des utilisateurs auront au moins 2 comptes.

**Independent Test**: Peut être testé en configurant un utilisateur avec 0 ou 1 compte actif et en vérifiant que l'option "Virement" est masquée ou qu'un message explicatif s'affiche.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a moins de 2 comptes actifs, **When** il ouvre le FAB, **Then** l'option "Virement" n'est pas proposée dans le menu d'actions rapides
2. **Given** l'utilisateur a exactement 2 comptes actifs, **When** il ouvre le formulaire de virement, **Then** les deux comptes sont disponibles dans les sélecteurs

---

### Edge Cases

- Que se passe-t-il si l'utilisateur perd sa connexion pendant l'envoi du virement ? Un message d'erreur réseau s'affiche, le formulaire reste rempli pour permettre un nouvel essai
- Que se passe-t-il si un compte est désactivé entre l'ouverture du formulaire et la validation ? L'erreur serveur est affichée dans le formulaire
- Que se passe-t-il si le token JWT expire pendant la saisie ? Le mécanisme de refresh token existant s'applique automatiquement
- Que se passe-t-il si l'utilisateur ferme la modal pendant l'envoi ? La requête en cours ne doit pas provoquer d'erreur visible

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT présenter un formulaire de virement accessible depuis le menu d'actions rapides (FAB) avec l'option "Virement"
- **FR-002**: Le formulaire DOIT afficher les champs suivants : compte source (sélecteur), compte destination (sélecteur), montant (numérique), note (texte libre, optionnel)
- **FR-003**: Les sélecteurs de compte DOIVENT afficher uniquement les comptes actifs, avec leur icône, nom, solde actuel et devise
- **FR-004**: Le système DOIT empêcher la sélection du même compte comme source et destination, avec un message d'erreur explicite
- **FR-005**: Le montant DOIT être strictement supérieur à 0 (minimum 0.01)
- **FR-006**: La note DOIT être limitée à 500 caractères maximum
- **FR-007**: Le système DOIT envoyer le virement au serveur et créer deux transactions liées (dépense sur le compte source, recette sur le compte destination) partageant un identifiant de virement commun
- **FR-008**: Le système DOIT afficher un indicateur de chargement pendant l'envoi et désactiver les interactions avec le formulaire
- **FR-009**: Le système DOIT fermer la modal et rafraîchir la liste des transactions après un virement réussi
- **FR-010**: Le système DOIT afficher un message d'erreur dans le formulaire en cas d'échec serveur, en conservant les données saisies
- **FR-011**: L'option "Virement" dans le FAB DOIT être masquée si l'utilisateur a moins de 2 comptes actifs
- **FR-012**: Les erreurs de validation DOIVENT s'afficher uniquement après une tentative de soumission (pas au premier affichage)

### Key Entities

- **Virement** : Opération de transfert d'argent entre deux comptes. Produit deux transactions liées. Attributs : compte source, compte destination, montant, note optionnelle. La date est celle du jour de la création.
- **Transaction (existante)** : Représente un mouvement financier. Un virement crée deux transactions : une dépense (compte source) et une recette (compte destination), reliées par un identifiant de virement partagé.
- **Compte (existant)** : Représente un compte bancaire. Seuls les comptes actifs sont proposés dans les sélecteurs. Affiche son icône, nom, solde et devise.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut effectuer un virement en 4 interactions maximum (ouvrir FAB → choisir "Virement" → remplir le formulaire → valider)
- **SC-002**: Le feedback visuel (succès ou erreur) est affiché dans les 3 secondes suivant la validation
- **SC-003**: Les erreurs de validation sont toutes visibles sans défilement sur un écran mobile standard
- **SC-004**: 100% des virements réussis produisent exactement 2 transactions liées visibles dans la liste

## Assumptions

- L'endpoint backend POST /accounts/transfer est déjà implémenté et fonctionnel
- Le système de modal (KKS-94) et le widget SelectPicker (KKS-96) sont disponibles
- Le FAB menu existant supporte déjà le type "transfer" (ModalType.transfer est défini)
- La date du virement est automatiquement la date du jour (pas de sélecteur de date — le backend utilise la date courante)
- Le formulaire est en mode création uniquement (pas d'édition de virement existant)
- Seule la devise du compte source est utilisée pour le montant (pas de conversion de devises)
- Le refresh de la liste des transactions après virement est géré par le mécanisme existant (`transactionListNotifierProvider.notifier.refresh()`)
