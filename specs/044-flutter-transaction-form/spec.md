# Feature Specification: Flutter — Formulaire Transaction

**Feature Branch**: `044-flutter-transaction-form`
**Created**: 2026-02-23
**Status**: Draft
**Input**: User description: "KKS-104 — Modal avec toggle Dépense/Recette dans le header. Champs: libellé, montant, date, compte (SelectPicker), catégorie (CategoryPicker), note. Mode création et édition. Bouton supprimer en édition."
**Linear**: [KKS-104](https://linear.app/kksdev/issue/KKS-104/flutter-formulaire-transaction)

## Clarifications

### Session 2026-02-23

- Q: Les catégories doivent-elles être filtrées par type de transaction (Dépense/Recette) ? → A: Non — toutes les catégories sont affichées quel que soit le type. Le modèle Category est type-agnostique (pas de champ type). Aligné sur le comportement actuel de l'app Angular.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Créer une transaction (Priority: P1)

L'utilisateur appuie sur le bouton flottant (+) depuis l'écran des transactions. Un modal s'ouvre avec un toggle Dépense/Recette dans le header. L'utilisateur remplit le libellé, le montant, choisit la date, sélectionne un compte et une catégorie, puis ajoute optionnellement une note. Il valide et la transaction est créée.

**Why this priority**: C'est le flux principal — sans création de transaction, l'application n'a aucune utilité.

**Independent Test**: Peut être testé en ouvrant le formulaire, remplissant les champs obligatoires et validant. La transaction apparaît ensuite dans la liste.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran des transactions, **When** il appuie sur le FAB (+), **Then** le modal de formulaire s'ouvre avec le toggle Dépense sélectionné par défaut.
2. **Given** le formulaire est ouvert avec le type Dépense, **When** l'utilisateur remplit libellé, montant, date, compte et catégorie puis valide, **Then** la transaction est créée avec les valeurs saisies et le modal se ferme.
3. **Given** le formulaire est ouvert, **When** l'utilisateur bascule le toggle sur Recette, **Then** le type de transaction change visuellement et la valeur type est mise à jour.
4. **Given** le formulaire est ouvert, **When** l'utilisateur valide sans remplir les champs obligatoires (libellé, montant, compte, catégorie), **Then** des messages d'erreur s'affichent sur les champs manquants et la soumission est bloquée.

---

### User Story 2 — Modifier une transaction existante (Priority: P2)

L'utilisateur appuie sur une transaction existante dans la liste. Le modal s'ouvre en mode édition avec les valeurs actuelles pré-remplies. L'utilisateur modifie les champs souhaités et valide pour enregistrer les modifications.

**Why this priority**: L'édition est essentielle pour corriger les erreurs de saisie, mais secondaire par rapport à la création.

**Independent Test**: Peut être testé en sélectionnant une transaction existante, modifiant un champ (ex: montant), validant et vérifiant que la modification est persistée.

**Acceptance Scenarios**:

1. **Given** une transaction existe dans la liste, **When** l'utilisateur appuie dessus, **Then** le modal s'ouvre en mode édition avec tous les champs pré-remplis (libellé, montant, date, type, compte, catégorie, note).
2. **Given** le formulaire est ouvert en mode édition, **When** l'utilisateur modifie le montant et valide, **Then** la transaction est mise à jour avec le nouveau montant.
3. **Given** le formulaire est ouvert en mode édition, **When** l'utilisateur change le type de Dépense à Recette, **Then** le type est mis à jour. Les catégories affichées restent inchangées (catégories type-agnostiques).

---

### User Story 3 — Supprimer une transaction (Priority: P3)

En mode édition, un bouton de suppression est visible. L'utilisateur appuie dessus, confirme, et la transaction est supprimée.

**Why this priority**: La suppression est un flux secondaire utilisé moins fréquemment, mais nécessaire pour corriger les doublons ou erreurs.

**Independent Test**: Peut être testé en ouvrant une transaction en édition, appuyant sur supprimer, confirmant et vérifiant que la transaction disparaît de la liste.

**Acceptance Scenarios**:

1. **Given** le formulaire est ouvert en mode édition, **When** l'utilisateur appuie sur le bouton supprimer, **Then** une confirmation est demandée avant la suppression.
2. **Given** la confirmation de suppression est affichée, **When** l'utilisateur confirme, **Then** la transaction est supprimée et le modal se ferme.
3. **Given** la confirmation de suppression est affichée, **When** l'utilisateur annule, **Then** le modal reste ouvert et la transaction n'est pas supprimée.
4. **Given** le formulaire est ouvert en mode création, **Then** le bouton supprimer n'est pas visible.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur soumet un montant à 0 ? Le formulaire doit refuser un montant nul ou négatif.
- Que se passe-t-il si l'utilisateur n'a aucun compte créé ? Le champ compte ne peut pas être sélectionné ; un message indique qu'il faut d'abord créer un compte.
- Que se passe-t-il si l'utilisateur n'a aucune catégorie disponible ? Le champ catégorie ne peut pas être sélectionné ; un message invite à créer une catégorie.
- Que se passe-t-il si la connexion réseau est perdue pendant la soumission ? Un message d'erreur est affiché et le formulaire reste ouvert avec les données saisies intactes.
- Que se passe-t-il si l'utilisateur ferme le modal sans sauvegarder alors que des modifications ont été faites ? Le modal se ferme sans confirmation (application single-user, pas de perte critique).
- Que se passe-t-il si la date sélectionnée est dans le futur ? La date future est autorisée (transactions planifiées).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher un formulaire dans un modal avec un toggle Dépense/Recette dans le header.
- **FR-002**: Le toggle DOIT permettre de basculer entre les types Dépense et Recette, avec Dépense sélectionné par défaut en mode création.
- **FR-003**: Le formulaire DOIT contenir les champs suivants : libellé (texte), montant (numérique), date (sélecteur de date), compte (SelectPicker), catégorie (CategoryPicker), note (texte multiligne optionnel).
- **FR-004**: Les champs libellé, montant, date, compte et catégorie DOIVENT être obligatoires. Le champ note est optionnel.
- **FR-005**: Le montant DOIT être strictement positif (> 0).
- **FR-006**: La date DOIT être pré-remplie avec la date du jour en mode création.
- **FR-007**: Le compte par défaut de l'utilisateur DOIT être pré-sélectionné en mode création si un compte par défaut existe.
- **FR-008**: Toutes les catégories de l'utilisateur DOIVENT être affichées dans le CategoryPicker, quel que soit le type de transaction sélectionné.
- **FR-009**: En mode édition, tous les champs DOIVENT être pré-remplis avec les valeurs actuelles de la transaction.
- **FR-010**: En mode édition, un bouton de suppression DOIT être visible et accessible.
- **FR-011**: La suppression DOIT requérir une confirmation avant exécution.
- **FR-012**: Le formulaire DOIT afficher des messages de validation en ligne sur les champs invalides lors de la soumission.
- **FR-013**: Après une création ou modification réussie, le modal DOIT se fermer et la liste des transactions DOIT se rafraîchir.
- **FR-014**: Après une suppression réussie, le modal DOIT se fermer et la transaction DOIT disparaître de la liste.
- **FR-015**: En cas d'erreur réseau lors de la soumission, un message d'erreur DOIT être affiché et le formulaire DOIT rester ouvert avec les données intactes.

### Key Entities

- **Transaction**: Montant, libellé, type (Dépense/Recette), date, compte associé, catégorie associée, note optionnelle. Liée à un utilisateur.
- **Compte (Account)**: Nom, type, solde. Sélectionné via SelectPicker. Un compte peut être marqué comme défaut.
- **Catégorie (Category)**: Nom, icône, couleur. Sélectionnée via CategoryPicker. Toutes les catégories sont affichées quel que soit le type de transaction.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut créer une transaction complète (tous les champs obligatoires) en moins de 15 secondes.
- **SC-002**: L'utilisateur peut modifier une transaction existante en moins de 10 secondes.
- **SC-003**: L'utilisateur peut supprimer une transaction en 2 interactions (appuyer sur supprimer + confirmer).
- **SC-004**: 100% des erreurs de validation sont affichées en ligne sur les champs concernés avant soumission.
- **SC-005**: Le formulaire conserve les données saisies en cas d'erreur réseau lors de la soumission.

## Assumptions

- Les widgets SelectPicker (KKS-96), CategoryPicker (KKS-97), FormField (KKS-95) et le système de modal (KKS-94) sont déjà implémentés et disponibles.
- Les notifiers Riverpod CRUD pour les transactions (KKS-115) sont déjà implémentés.
- Le type Dépense est le type par défaut le plus courant pour les saisies rapides.
- Les dates futures sont autorisées pour permettre la planification de transactions.
- La fermeture du modal sans sauvegarde ne nécessite pas de confirmation (application single-user, risque de perte minime).
- Le montant est saisi en valeur absolue (toujours positif), le signe étant déterminé par le toggle Dépense/Recette.

## Dependencies

- **KKS-94**: Flutter: Système Modal / Bottom Sheet (bloquant)
- **KKS-95**: Flutter: Widget FormField (bloquant)
- **KKS-96**: Flutter: Widget SelectPicker (bloquant)
- **KKS-97**: Flutter: Widget CategoryPicker (bloquant)
- **KKS-115**: Flutter: Notifiers Riverpod CRUD (bloquant)
