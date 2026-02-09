# Feature Specification: Créer AmountPipe et RelativeDatePipe

**Feature Branch**: `007-format-pipes`
**Created**: 2026-02-09
**Status**: Draft
**Input**: KKS-48 — Pipes réutilisables pour le formatage des montants et des dates relatives

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Affichage formaté des montants (Priority: P1)

L'utilisateur consulte une liste (transactions, abonnements, dettes) et voit chaque montant formaté avec le signe approprié et le symbole euro, selon les conventions françaises (espace insécable comme séparateur de milliers, virgule décimale).

**Why this priority**: Le formatage des montants est essentiel pour la lisibilité de toutes les données financières de l'application. Sans ce formatage, les montants bruts (ex: `2100.5`) sont illisibles et ambigus pour l'utilisateur.

**Independent Test**: Peut être testé en appliquant le pipe à un montant brut et en vérifiant le résultat formaté dans n'importe quel template.

**Acceptance Scenarios**:

1. **Given** un montant de 2100.00 de type RECETTE, **When** le pipe formate ce montant, **Then** l'affichage est `+2 100,00 €`
2. **Given** un montant de 9.99 de type DEPENSE, **When** le pipe formate ce montant, **Then** l'affichage est `-9,99 €`
3. **Given** un montant de 0, **When** le pipe formate ce montant, **Then** l'affichage est `0,00 €` (sans signe)
4. **Given** un montant null ou undefined, **When** le pipe tente de formater, **Then** l'affichage est une chaîne vide
5. **Given** un montant de 1500.50 sans type spécifié, **When** le pipe formate ce montant, **Then** l'affichage est `1 500,50 €` (sans signe, montant brut)

---

### User Story 2 - Affichage des dates relatives (Priority: P1)

L'utilisateur consulte une liste et voit les dates récentes exprimées en langage naturel relatif ("Aujourd'hui", "Hier", "il y a 3 jours") pour une meilleure compréhension temporelle, tandis que les dates plus anciennes sont affichées au format long français.

**Why this priority**: Les dates relatives améliorent significativement la compréhension du contexte temporel des opérations récentes, ce qui est critique pour le suivi budgétaire au quotidien.

**Independent Test**: Peut être testé en appliquant le pipe à différentes dates et en vérifiant le résultat textuel dans n'importe quel template.

**Acceptance Scenarios**:

1. **Given** la date du jour, **When** le pipe formate cette date, **Then** l'affichage est `Aujourd'hui`
2. **Given** la date d'hier, **When** le pipe formate cette date, **Then** l'affichage est `Hier`
3. **Given** une date d'il y a 3 jours, **When** le pipe formate cette date, **Then** l'affichage est `il y a 3 jours`
4. **Given** une date d'il y a 7 jours, **When** le pipe formate cette date, **Then** l'affichage est `il y a 7 jours`
5. **Given** une date d'il y a 14 jours, **When** le pipe formate cette date, **Then** l'affichage est `il y a 2 semaines`
6. **Given** une date d'il y a 45 jours (ex: 26 décembre 2025), **When** le pipe formate cette date, **Then** l'affichage est `26 décembre 2025`
7. **Given** une date null ou undefined, **When** le pipe tente de formater, **Then** l'affichage est une chaîne vide
8. **Given** une date future (demain), **When** le pipe formate cette date, **Then** l'affichage est `Demain`

---

### Edge Cases

- Que se passe-t-il avec un montant négatif fourni sans type ? Le pipe affiche le montant tel quel avec le signe négatif.
- Que se passe-t-il avec une chaîne de date invalide (ex: "abc") ? Le pipe retourne une chaîne vide.
- Que se passe-t-il avec un montant très grand (ex: 1 000 000) ? Le formatage gère correctement les séparateurs de milliers.
- Que se passe-t-il exactement à la frontière 7 jours / semaines ? À 8 jours, l'affichage bascule en semaines ("il y a 1 semaine").
- Que se passe-t-il exactement à la frontière 30 jours / date complète ? À 31 jours, l'affichage bascule en date complète.
- Que se passe-t-il avec les dates futures au-delà de demain ? Elles sont affichées au format long français (même règle que >30 jours passés).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT formater les montants en euros selon les conventions françaises (virgule décimale, espace séparateur de milliers, symbole €)
- **FR-002**: Le système DOIT préfixer les montants d'un signe `+` pour les recettes et `-` pour les dépenses lorsqu'un type de transaction est fourni
- **FR-003**: Le système DOIT afficher les montants sans signe lorsqu'aucun type n'est spécifié
- **FR-004**: Le système DOIT afficher un montant de 0 sans signe, formaté `0,00 €`
- **FR-005**: Le système DOIT retourner une chaîne vide pour les montants null ou undefined
- **FR-006**: Le système DOIT afficher "Aujourd'hui" pour les dates du jour courant
- **FR-007**: Le système DOIT afficher "Hier" pour les dates de la veille
- **FR-008**: Le système DOIT afficher "Demain" pour les dates du lendemain
- **FR-009**: Le système DOIT afficher "il y a X jours" pour les dates entre 2 et 7 jours dans le passé
- **FR-010**: Le système DOIT afficher "il y a X semaines" pour les dates entre 8 et 30 jours dans le passé
- **FR-011**: Le système DOIT afficher la date au format long français (ex: "15 janvier 2026") pour les dates de plus de 30 jours dans le passé
- **FR-012**: Le système DOIT retourner une chaîne vide pour les dates null, undefined ou invalides
- **FR-013**: Les deux pipes DOIVENT être réutilisables dans n'importe quel template de l'application
- **FR-014**: Le pipe de montant DOIT accepter un paramètre optionnel de type pour déterminer le signe (compatible avec les types métier : transaction DEPENSE/RECETTE, dette JE_DOIS/ON_ME_DOIT)

### Key Entities

- **Montant formaté** : Valeur numérique transformée en chaîne lisible avec devise, signe et formatage français. Consomme les champs `montant` et `type` des entités Transaction, Subscription et Debt.
- **Date relative** : Date ISO transformée en expression temporelle relative ou en date longue française. Consomme les champs `date` et `dateDebut` des entités Transaction, Subscription et Debt.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des montants affichés dans l'application utilisent le formatage français standardisé (virgule, espace, euro)
- **SC-002**: Les dates de moins de 7 jours sont immédiatement compréhensibles sans calcul mental (affichage relatif)
- **SC-003**: Les deux pipes gèrent gracieusement les valeurs null/undefined sans erreur ni affichage cassé
- **SC-004**: Le formatage est cohérent sur tous les écrans (transactions, abonnements, dettes, dashboard)
- **SC-005**: L'utilisateur distingue visuellement les revenus des dépenses grâce au signe +/-

## Assumptions

- La locale cible est exclusivement le français (fr-FR). Pas de support multi-langue nécessaire.
- Les montants sont toujours en euros (pas de multi-devise).
- Les dates sont fournies au format ISO string (YYYY-MM-DD) tel que retourné par l'API backend.
- Le calcul des dates relatives se base sur la date locale de l'utilisateur (pas UTC).
- Le pipe de montant sera utilisé conjointement avec les types métier existants (TransactionType, DebtType) mais aussi de manière autonome (ex: abonnements sans notion de signe).
- Les dates futures au-delà de "Demain" sont affichées au format long français.

## Scope

### Inclus
- Pipe de formatage de montant avec signe conditionnel
- Pipe de date relative avec dégradation vers format long
- Gestion des cas limites (null, undefined, 0, dates invalides)

### Exclus
- Formatage multi-devise
- Support multi-locale (i18n)
- Pipe de formatage de pourcentage
- Animations ou transitions sur le changement de valeur
