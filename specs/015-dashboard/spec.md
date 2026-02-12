# Feature Specification: Écran Dashboard

**Feature Branch**: `015-dashboard`
**Created**: 2026-02-12
**Status**: Draft
**Input**: Issue KKS-57 — Écran Dashboard (bilan + résumés)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter le bilan mensuel (Priority: P1)

L'utilisateur ouvre le tableau de bord et voit immédiatement un résumé financier du mois en cours : total des recettes, total des dépenses et solde net. Il peut naviguer vers d'autres mois pour comparer ses finances.

**Why this priority**: Le bilan mensuel est la raison principale de l'existence du dashboard. C'est l'information que l'utilisateur consulte en priorité pour évaluer sa santé financière.

**Independent Test**: Peut être testé en vérifiant que les 3 cartes financières (Recettes, Dépenses, Solde) affichent les bons totaux pour le mois sélectionné et que la navigation entre mois fonctionne.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a des transactions en février 2026, **When** il ouvre le dashboard, **Then** il voit 3 cartes : Recettes (vert), Dépenses (rouge) et Solde avec les montants du mois en cours
2. **Given** l'utilisateur est sur le dashboard de février 2026, **When** il navigue au mois précédent, **Then** les cartes affichent les montants de janvier 2026
3. **Given** l'utilisateur n'a aucune transaction pour un mois donné, **When** il consulte ce mois, **Then** les 3 cartes affichent 0,00 EUR

---

### User Story 2 - Aperçu des dernières transactions (Priority: P2)

L'utilisateur voit les 5 dernières transactions sur le dashboard avec un accès rapide vers la liste complète.

**Why this priority**: Les transactions récentes donnent un aperçu immédiat de l'activité financière. C'est l'information la plus consultée après le bilan.

**Independent Test**: Peut être testé en vérifiant que les 5 transactions les plus récentes apparaissent sous forme de liste, avec un lien fonctionnel vers la page complète.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 10 transactions, **When** il consulte le dashboard, **Then** il voit les 5 plus récentes avec libellé, montant et date relative
2. **Given** l'utilisateur a 2 transactions, **When** il consulte le dashboard, **Then** il voit 2 éléments (pas de remplissage artificiel)
3. **Given** l'utilisateur clique sur "Voir tout", **When** la navigation s'effectue, **Then** il arrive sur la page des transactions
4. **Given** l'utilisateur clique sur une transaction dans l'aperçu, **When** la modale s'ouvre, **Then** il peut modifier la transaction directement depuis le dashboard

---

### User Story 3 - Aperçu des abonnements actifs (Priority: P3)

L'utilisateur voit ses 3 premiers abonnements actifs avec le coût mensuel total et un accès vers la liste complète.

**Why this priority**: Les abonnements représentent des charges récurrentes. Un rappel sur le dashboard aide à garder le contrôle des dépenses fixes.

**Independent Test**: Peut être testé en vérifiant l'affichage des 3 abonnements actifs, le calcul du total mensuel et la navigation vers la liste complète.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 5 abonnements actifs, **When** il consulte le dashboard, **Then** il voit les 3 premiers avec nom, montant et un total mensuel
2. **Given** l'utilisateur a un abonnement annuel de 120 EUR, **When** le total mensuel est calculé, **Then** il est converti en 10,00 EUR/mois
3. **Given** l'utilisateur n'a aucun abonnement actif, **When** il consulte le dashboard, **Then** la section abonnements affiche un état vide
4. **Given** l'utilisateur clique sur un abonnement dans l'aperçu, **When** la modale s'ouvre, **Then** il peut modifier l'abonnement directement depuis le dashboard

---

### User Story 4 - Aperçu des dettes en cours (Priority: P3)

L'utilisateur voit ses 3 premières dettes non remboursées avec un résumé des montants (je dois / on me doit) et un accès vers la liste complète.

**Why this priority**: Même priorité que les abonnements — les dettes en cours nécessitent un suivi régulier mais sont moins consultées que le bilan et les transactions.

**Independent Test**: Peut être testé en vérifiant l'affichage des 3 dettes en cours, les totaux par sens et la navigation vers la liste complète.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 5 dettes en cours, **When** il consulte le dashboard, **Then** il voit les 3 premières avec personne, montant et sens
2. **Given** l'utilisateur a des dettes dans les deux sens, **When** il consulte le résumé, **Then** il voit le total "Je dois" et le total "On me doit" séparément
3. **Given** l'utilisateur n'a aucune dette en cours, **When** il consulte le dashboard, **Then** la section dettes affiche un état vide
4. **Given** l'utilisateur clique sur une dette dans l'aperçu, **When** la modale s'ouvre, **Then** il peut modifier la dette directement depuis le dashboard

---

### Edge Cases

- Que se passe-t-il si une section échoue au chargement (erreur réseau) ? Les autres sections restent fonctionnelles et affichent leurs données normalement
- Que se passe-t-il si toutes les sections échouent ? L'utilisateur voit un message d'erreur pour chaque section avec possibilité de réessayer
- Que se passe-t-il au premier usage (aucune donnée) ? Le dashboard affiche le bilan à zéro et des états vides pour chaque section
- Que se passe-t-il si l'utilisateur navigue vers un mois futur ? Le sélecteur fonctionne sans restriction et affiche des valeurs à zéro

## Clarifications

### Session 2026-02-12

- Q: Que se passe-t-il quand l'utilisateur clique sur un item individuel dans un aperçu du dashboard ? → A: Le clic ouvre la modale d'édition, comme sur les écrans de liste (cohérence UX, économie d'actions)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher un sélecteur de mois permettant de naviguer mois par mois (précédent/suivant)
- **FR-002**: Le système DOIT afficher 3 cartes de bilan pour le mois sélectionné : Recettes (stylisé en vert), Dépenses (stylisé en rouge) et Solde
- **FR-003**: Le système DOIT afficher la section "Dernières transactions" avec un maximum de 5 éléments triés par date décroissante
- **FR-004**: Le système DOIT afficher la section "Abonnements actifs" avec un maximum de 3 éléments et le total mensuel (abonnements annuels convertis en mensuel)
- **FR-005**: Le système DOIT afficher la section "Dettes en cours" avec un maximum de 3 éléments non remboursés et un résumé des totaux par sens (je dois / on me doit)
- **FR-006**: Chaque section de résumé DOIT inclure un lien "Voir tout" qui navigue vers la page dédiée (/transactions, /subscriptions, /debts)
- **FR-007**: Chaque section DOIT gérer son chargement indépendamment (l'échec d'une section n'impacte pas les autres)
- **FR-008**: Les montants DOIVENT être formatés en euros avec signe contextuel (+ pour recettes/créances, - pour dépenses/dettes)
- **FR-009**: Les dates DOIVENT être affichées en format relatif (Aujourd'hui, Hier, il y a X jours, etc.)
- **FR-010**: Chaque section DOIT afficher un état de chargement pendant le fetch des données
- **FR-011**: Chaque section DOIT afficher un état vide explicite quand aucune donnée n'existe
- **FR-012**: Le dashboard DOIT s'initialiser sur le mois en cours à l'ouverture
- **FR-013**: Le clic sur un item individuel dans un aperçu DOIT ouvrir la modale d'édition de l'entité correspondante (cohérent avec les écrans de liste)

### Key Entities

- **Bilan mensuel (MonthlySummary)** : Agrégation des recettes et dépenses pour un mois donné, avec calcul du solde. Attributs : mois, année, total recettes, total dépenses, solde
- **Transaction** : Opération financière ponctuelle (recette ou dépense) avec libellé, montant, date, catégorie
- **Abonnement (Subscription)** : Charge récurrente avec nom, montant, fréquence (mensuel/annuel), statut actif/inactif
- **Dette (Debt)** : Montant dû ou à recevoir avec personne concernée, montant, sens (je dois/on me doit), statut de remboursement

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter son bilan mensuel en moins de 2 secondes après ouverture du dashboard
- **SC-002**: L'utilisateur peut naviguer vers n'importe quel mois en un seul clic (précédent ou suivant)
- **SC-003**: L'utilisateur peut accéder à la liste complète de chaque entité en un seul clic depuis le dashboard
- **SC-004**: En cas d'erreur sur une section, les autres sections restent fonctionnelles et affichent leurs données
- **SC-005**: L'utilisateur identifie visuellement les recettes (vert), dépenses (rouge), dettes dues et créances grâce au code couleur

## Assumptions

- Le mois en cours est le mois par défaut à l'ouverture du dashboard
- Les transactions affichées dans l'aperçu ne sont pas filtrées par mois — ce sont les 5 plus récentes toutes périodes confondues
- Les abonnements affichés sont triés par nom alphabétique (cohérent avec l'écran abonnements)
- Les dettes affichées sont triées par date décroissante (cohérent avec l'écran dettes)
- Le total mensuel des abonnements inclut la conversion annuel vers mensuel (montant/12)
- Le sélecteur de mois n'a pas de borne (l'utilisateur peut naviguer librement)

## Dependencies

- **KKS-50** : TransactionService avec méthode getSummary() pour le bilan mensuel
- **KKS-48** : SubscriptionService pour les abonnements actifs
- **KKS-49** : DebtService pour les dettes en cours
- Composants partagés : ListItem, AmountPipe, RelativeDatePipe
