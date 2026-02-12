# Feature Specification: Réorganisation complète du Dashboard

**Feature Branch**: `021-dashboard-redesign`
**Created**: 2026-02-12
**Status**: Draft
**Input**: User description: "KKS-70 — Réorganisation complète du dashboard. Regrouper tous les KPIs en haut (2 rangées), supprimer les résumés texte brut des sections, listes pures en dessous. Composant mini-card réutilisable avec barre colorée. Cohérence visuelle totale."

## Clarifications

### Session 2026-02-12

- Q: Le rang 2 des KPI (abos, dettes) doit-il suivre le sélecteur de mois ? → A: Non, rang 2 statique (état courant). Seul le rang 1 (recettes/dépenses/solde) suit le mois sélectionné.
- Q: Les mini-cards du rang 2 sont-elles cliquables ? → A: Oui, chaque mini-card navigue vers la page dédiée correspondante (/subscriptions, /debts).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Vue d'ensemble financière instantanée (Priority: P1)

L'utilisateur ouvre le dashboard et voit immédiatement tous ses indicateurs financiers clés regroupés en haut de l'écran, organisés en 2 rangées :
- **Rang 1** (cards principales) : Recettes, Dépenses, Solde du mois en cours — piloté par le sélecteur de mois
- **Rang 2** (mini-cards compactes) : Total abonnements/mois, Total "Je dois", Total "On me doit" — état courant, indépendant du mois sélectionné

En un seul coup d'oeil, sans scroller, l'utilisateur comprend sa situation financière globale.

**Why this priority**: C'est le coeur de la feature — la raison principale de la réorganisation. Sans cette zone KPI unifiée, le dashboard reste morcelé.

**Independent Test**: Peut être testé en vérifiant que les 6 indicateurs sont visibles au-dessus de la ligne de flottaison sur mobile (375px) et desktop.

**Acceptance Scenarios**:

1. **Given** le dashboard est chargé avec des données, **When** l'utilisateur arrive sur la page, **Then** il voit les 6 KPI regroupés en haut (3 cards principales + 3 mini-cards)
2. **Given** le dashboard est chargé, **When** l'utilisateur regarde le rang 2, **Then** chaque mini-card a une barre colorée en haut identifiant sa catégorie (bleu abos, rouge "je dois", vert "on me doit")
3. **Given** l'utilisateur change de mois via le sélecteur, **When** les données sont rechargées, **Then** seuls les KPI du rang 1 (recettes, dépenses, solde) se mettent à jour ; le rang 2 reste inchangé
4. **Given** le dashboard est chargé, **When** l'utilisateur clique sur une mini-card du rang 2, **Then** il est redirigé vers la page dédiée correspondante (/subscriptions ou /debts)

---

### User Story 2 - Listes de détail épurées (Priority: P2)

Sous la zone KPI, l'utilisateur parcourt 3 sections de listes pures (sans résumé texte dupliqué) :
- Dernières transactions
- Abonnements actifs
- Dettes en cours

Chaque section affiche uniquement un titre, un lien "Voir tout", et la liste des items. Les résumés texte brut ("Total mensuel : X €", "Je dois : X €") sont supprimés car l'information est déjà dans les KPI en haut.

**Why this priority**: Complète la réorganisation en supprimant la duplication d'information et en clarifiant la hiérarchie visuelle.

**Independent Test**: Peut être testé en vérifiant l'absence de texte de résumé dans les sections liste et que chaque section affiche correctement ses items.

**Acceptance Scenarios**:

1. **Given** le dashboard est chargé, **When** l'utilisateur regarde la section abonnements, **Then** il ne voit pas de texte "Total mensuel : X €" — juste le titre, le lien, et la liste
2. **Given** le dashboard est chargé, **When** l'utilisateur regarde la section dettes, **Then** il ne voit pas de texte "Je dois : X € / On me doit : X €" — juste le titre, le lien, et la liste
3. **Given** le dashboard a des dettes, **When** l'utilisateur regarde un item dette dans la liste, **Then** le montant est affiché en positif avec un label contextuel ("Emprunt" ou "Prêt") au lieu d'un signe négatif

---

### User Story 3 - Cohérence visuelle du composant mini-card (Priority: P3)

Le dashboard utilise un composant visuel mini-card unifié pour le rang 2 des KPI. Ce composant est cohérent avec le style des cards principales du rang 1 (même arrondis, même ombres, même typographie) tout en étant plus compact. Chaque mini-card comporte une barre colorée de 3px en haut pour l'identification visuelle rapide.

**Why this priority**: Assure la cohérence du design system. Moins critique fonctionnellement mais important pour la qualité perçue.

**Independent Test**: Peut être testé en comparant visuellement les mini-cards entre elles et avec les cards du rang 1, et en vérifiant le rendu en thème clair et sombre.

**Acceptance Scenarios**:

1. **Given** le dashboard en thème sombre, **When** l'utilisateur regarde les mini-cards, **Then** les couleurs de barre sont distinctes : bleu (abos), rouge (je dois), vert (on me doit)
2. **Given** le dashboard en thème clair, **When** l'utilisateur regarde les mini-cards, **Then** les mêmes distinctions de couleur sont visibles et lisibles
3. **Given** le dashboard sur un écran 375px, **When** l'utilisateur regarde les mini-cards, **Then** elles s'affichent en ligne (3 côte à côte) sans débordement ni troncature

---

### Edge Cases

- Que se passe-t-il quand l'utilisateur n'a aucune donnée (nouveau compte) ? Les KPI affichent 0 € pour chaque indicateur, les listes affichent "Aucun(e) [entité]"
- Que se passe-t-il quand un seul type de données existe (ex: transactions mais pas de dettes ni d'abonnements) ? Les KPI abos/dettes affichent 0 €, les listes concernées affichent leur état vide
- Que se passe-t-il pendant le chargement ? Les cards KPI affichent un état de chargement (spinner), les listes affichent leur spinner existant
- Que se passe-t-il en cas d'erreur réseau ? Le dashboard affiche les états d'erreur existants avec bouton "Réessayer" pour chaque section

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le dashboard DOIT afficher tous les indicateurs financiers regroupés en haut de la page, avant les listes de détail
- **FR-002**: Le rang 1 des KPI DOIT afficher 3 cards principales : Recettes, Dépenses, Solde — avec les mêmes données et couleurs qu'actuellement, pilotées par le sélecteur de mois
- **FR-003**: Le rang 2 des KPI DOIT afficher 3 mini-cards compactes : Total abonnements mensuels (bleu), Total "Je dois" (rouge), Total "On me doit" (vert) — état courant, indépendant du mois sélectionné
- **FR-004**: Chaque mini-card du rang 2 DOIT avoir une barre colorée de 3px en haut pour l'identification visuelle
- **FR-005**: Les sections listes (transactions, abonnements, dettes) NE DOIVENT PLUS afficher de résumé texte (plus de "Total mensuel", plus de "Je dois / On me doit")
- **FR-006**: Les listes DOIVENT conserver leur fonctionnement actuel (items cliquables, navigation vers détail, états vide/chargement/erreur)
- **FR-007**: Les items de dette dans la liste DOIVENT afficher le montant en positif avec un label contextuel ("Emprunt" ou "Prêt") au lieu d'un signe négatif
- **FR-008**: Un séparateur visuel DOIT séparer la zone KPI des listes de détail
- **FR-009**: Le dashboard DOIT fonctionner correctement en thème clair et sombre
- **FR-010**: Chaque mini-card du rang 2 DOIT être cliquable et naviguer vers la page dédiée correspondante (abos → /subscriptions, "je dois" et "on me doit" → /debts)

### Assumptions

- Les données des abonnements et dettes sont déjà disponibles via les services existants (SubscriptionService, DebtService) — aucune modification backend nécessaire
- Le sélecteur de mois pilote uniquement le rang 1 (recettes/dépenses/solde) ; le rang 2 (abos, dettes) reflète l'état courant indépendamment du mois sélectionné
- Les couleurs de barre des mini-cards correspondent aux tokens sémantiques existants du design system
- Le composant mini-card est interne au dashboard (pas un composant shared réutilisable hors du dashboard en v1)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur voit ses 6 indicateurs financiers clés sans scroller sur un écran mobile 375px de hauteur standard
- **SC-002**: Aucune information de résumé n'est dupliquée — chaque donnée apparaît une seule fois (dans les KPI ou dans la liste, pas les deux)
- **SC-003**: Le dashboard conserve tous les comportements existants (navigation mois, clic items, états vide/chargement/erreur)
- **SC-004**: Le rendu est visuellement cohérent en thème clair et sombre (couleurs distinctes, lisibilité correcte)
- **SC-005**: Le temps de chargement perçu du dashboard ne régresse pas par rapport à l'état actuel
