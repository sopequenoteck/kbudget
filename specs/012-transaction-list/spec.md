# Feature Specification: Écran Transactions (liste + filtres)

**Feature Branch**: `012-transaction-list`
**Created**: 2026-02-11
**Status**: Draft
**Input**: User description: "KKS-54 — Écran Transactions (liste + filtres)"
**Linear**: KKS-54

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter ses transactions du mois (Priority: P1)

L'utilisateur ouvre l'écran Transactions et voit immédiatement la liste de ses transactions du mois en cours, avec un résumé financier (recettes, dépenses, solde).

**Why this priority**: C'est la fonctionnalité principale — sans affichage des transactions, l'écran n'a aucune valeur.

**Independent Test**: Peut être testé en naviguant vers l'écran Transactions et en vérifiant que les transactions du mois courant s'affichent avec le résumé mensuel.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est connecté et a des transactions ce mois-ci, **When** il ouvre l'écran Transactions, **Then** il voit la liste des transactions du mois en cours triées par date décroissante, avec le résumé mensuel (recettes, dépenses, solde).
2. **Given** l'utilisateur est connecté et n'a aucune transaction ce mois-ci, **When** il ouvre l'écran Transactions, **Then** il voit un message "Aucune transaction" et le résumé affiche 0 pour chaque montant.
3. **Given** les transactions sont en cours de chargement, **When** l'écran s'affiche, **Then** un indicateur de chargement est visible à la place de la liste.

---

### User Story 2 - Filtrer par mois et année (Priority: P2)

L'utilisateur peut naviguer entre les mois pour consulter ses transactions passées ou futures. Le résumé mensuel se met à jour en conséquence.

**Why this priority**: Permet d'avoir une vision historique, essentielle pour le suivi budgétaire.

**Independent Test**: Peut être testé en changeant le mois/année et en vérifiant que la liste et le résumé se mettent à jour.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur le mois de janvier 2026, **When** il sélectionne février 2026, **Then** la liste affiche uniquement les transactions de février 2026 et le résumé se met à jour.
2. **Given** l'utilisateur change de mois, **When** le nouveau mois n'a aucune transaction, **Then** le message "Aucune transaction" s'affiche et le résumé affiche 0.
3. **Given** l'utilisateur est sur janvier 2026, **When** il recule d'un mois, **Then** décembre 2025 est sélectionné.

---

### User Story 3 - Filtrer par type de transaction (Priority: P2)

L'utilisateur peut filtrer la liste pour n'afficher que les dépenses, que les recettes, ou toutes les transactions.

**Why this priority**: Permet une analyse ciblée des entrées et sorties d'argent.

**Independent Test**: Peut être testé en sélectionnant un filtre type et en vérifiant que seules les transactions correspondantes sont affichées.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a des dépenses et des recettes, **When** il sélectionne le filtre "Dépenses", **Then** seules les transactions de type dépense sont affichées.
2. **Given** l'utilisateur a des dépenses et des recettes, **When** il sélectionne le filtre "Recettes", **Then** seules les transactions de type recette sont affichées.
3. **Given** le filtre "Dépenses" est actif, **When** l'utilisateur sélectionne "Tous", **Then** toutes les transactions du mois sont affichées.
4. **Given** le filtre "Recettes" est actif et aucune recette n'existe ce mois, **When** l'utilisateur applique le filtre, **Then** le message "Aucune transaction" s'affiche.

---

### User Story 4 - Gestion des erreurs réseau (Priority: P3)

En cas d'erreur lors du chargement des transactions, l'utilisateur voit un message d'erreur avec la possibilité de réessayer.

**Why this priority**: Gestion des cas dégradés pour une bonne expérience utilisateur.

**Independent Test**: Peut être testé en simulant une erreur réseau et en vérifiant l'affichage du message d'erreur et le fonctionnement du bouton réessayer.

**Acceptance Scenarios**:

1. **Given** le chargement des transactions échoue, **When** l'écran tente d'afficher les données, **Then** un message d'erreur s'affiche avec un bouton "Réessayer".
2. **Given** un message d'erreur est affiché, **When** l'utilisateur clique sur "Réessayer", **Then** le chargement est relancé.

---

### Edge Cases

- Que se passe-t-il quand l'utilisateur change de mois pendant un chargement en cours ? Le chargement précédent est annulé et un nouveau est lancé.
- Comment le système gère-t-il un très grand nombre de transactions (100+) sur un mois ? La liste affiche toutes les transactions sans pagination (single-user, volume limité).
- Que se passe-t-il si le résumé mensuel et la liste retournent des erreurs différentes ? L'état d'erreur global s'applique — un seul message d'erreur avec retry.
- Que se passe-t-il si une transaction n'a pas de catégorie (category: null) ? Afficher une icône par défaut et aucun sous-titre de catégorie.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher la liste des transactions du mois courant par défaut à l'ouverture de l'écran.
- **FR-002**: Le système DOIT afficher un résumé mensuel avec trois montants : total recettes, total dépenses, et solde.
- **FR-003**: Le système DOIT permettre la navigation entre les mois via des flèches prev/next avec le label "Mois Année" affiché au centre.
- **FR-004**: Le système DOIT permettre le filtrage par type de transaction : tous, dépenses, recettes.
- **FR-005**: Le système DOIT trier les transactions par date décroissante (plus récentes en premier).
- **FR-006**: Le système DOIT afficher pour chaque transaction : l'icône de la catégorie, le libellé, le nom de la catégorie en sous-titre, le montant formaté (coloré selon le type), et la date relative.
- **FR-007**: Le système DOIT afficher un indicateur de chargement pendant le chargement des données.
- **FR-008**: Le système DOIT afficher un état vide avec le message "Aucune transaction" quand aucune transaction ne correspond aux filtres.
- **FR-009**: Le système DOIT afficher un message d'erreur avec un bouton "Réessayer" en cas d'échec du chargement.
- **FR-010**: Le système DOIT appliquer le filtrage par type côté client (sans appel API supplémentaire).
- **FR-011**: Le système DOIT mettre à jour le résumé mensuel quand l'utilisateur change de mois/année.
- **FR-012**: Les montants des recettes DOIVENT être affichés en vert et les dépenses en rouge.

### Key Entities

- **Transaction**: Opération financière avec montant, libellé, type (dépense/recette), date, catégorie optionnelle, et note optionnelle.
- **MonthlySummary**: Agrégation mensuelle avec total recettes, total dépenses, et solde calculé.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter ses transactions du mois courant en moins de 2 secondes après ouverture de l'écran.
- **SC-002**: L'utilisateur peut changer de mois et voir la liste mise à jour en moins de 2 secondes.
- **SC-003**: Le filtrage par type (dépenses/recettes/tous) est instantané (moins de 100ms) car côté client.
- **SC-004**: L'utilisateur peut identifier visuellement le type de chaque transaction (couleur du montant : vert pour recette, rouge pour dépense) sans lire le détail.
- **SC-005**: En cas d'erreur, l'utilisateur peut relancer le chargement en un seul clic.
- **SC-006**: Le résumé mensuel reflète correctement les totaux des transactions affichées pour le mois sélectionné.

## Clarifications

### Session 2026-02-11

- Q: Quel pattern de navigation entre les mois ? → A: Flèches prev/next avec label "Mois Année" au centre (navigation pas à pas).
- Q: Afficher la catégorie dans la liste ? Quelle est la source de l'icône ? → A: Oui, afficher le nom de la catégorie en sous-titre. L'icône de chaque transaction provient de la catégorie (champ `icone`), pas du type recette/dépense. La distinction de type se fait par la couleur du montant (vert/rouge).

## Assumptions

- L'API ne supporte pas le filtrage par date côté serveur — le filtrage mois/année se fait côté client après récupération de toutes les transactions.
- Le volume de transactions par utilisateur est limité (application single-user, pas de pagination nécessaire).
- Les composants ListItem, AmountPipe et RelativeDatePipe sont déjà implémentés et disponibles (KKS-48, KKS-49).
- Le service TransactionService avec les méthodes getAll() et getSummary() est déjà implémenté (KKS-50).
- Le mois par défaut à l'ouverture est le mois calendaire en cours.

## Dependencies

- **KKS-48**: AmountPipe et RelativeDatePipe (implémentés)
- **KKS-49**: Composant ListItem (implémenté)
- **KKS-50**: Services CRUD frontend dont TransactionService (implémenté)
