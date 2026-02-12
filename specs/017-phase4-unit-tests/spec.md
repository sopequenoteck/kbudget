# Feature Specification: Tests unitaires services Phase 4

**Feature Branch**: `017-phase4-unit-tests`
**Created**: 2026-02-12
**Status**: Draft
**Input**: User description: "KKS-59 Tests unitaires services Phase 4"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tests TransactionService (Priority: P1)

En tant que développeur, je veux des tests unitaires couvrant toutes les opérations du service de transactions (CRUD + résumé mensuel + signal de rafraîchissement) afin de garantir la fiabilité des opérations financières les plus critiques de l'application.

**Why this priority**: Les transactions sont le coeur fonctionnel de l'application budget. Toute régression sur le CRUD ou le calcul du résumé mensuel impacte directement l'utilisateur final.

**Independent Test**: Peut être vérifié indépendamment en exécutant la suite de tests du service Transaction et en validant que chaque opération (lecture, création, mise à jour, suppression, résumé) est couverte.

**Acceptance Scenarios**:

1. **Given** le service est instancié avec un mock de la couche réseau, **When** on appelle la récupération de toutes les transactions, **Then** le service retourne la liste de transactions via l'endpoint attendu
2. **Given** le service est instancié, **When** on appelle la récupération d'une transaction par identifiant, **Then** le service interroge l'endpoint avec l'identifiant correct et retourne la transaction
3. **Given** le service est instancié, **When** on crée une transaction, **Then** l'endpoint de création est appelé avec les bonnes données et le signal de rafraîchissement est incrémenté
4. **Given** le service est instancié, **When** on met à jour une transaction, **Then** l'endpoint de mise à jour est appelé et le signal de rafraîchissement est incrémenté
5. **Given** le service est instancié, **When** on supprime une transaction, **Then** l'endpoint de suppression est appelé et le signal de rafraîchissement est incrémenté
6. **Given** le service est instancié, **When** on demande le résumé mensuel sans paramètres, **Then** l'endpoint de résumé est appelé sans filtre
7. **Given** le service est instancié, **When** on demande le résumé mensuel avec un mois et une année, **Then** l'endpoint de résumé est appelé avec les paramètres de filtre correspondants
8. **Given** le service est instancié, **When** on effectue plusieurs opérations de mutation successives, **Then** le signal de rafraîchissement est incrémenté à chaque fois (compteur cumulatif)

---

### User Story 2 - Tests SubscriptionService (Priority: P2)

En tant que développeur, je veux des tests unitaires couvrant toutes les opérations du service d'abonnements (CRUD + filtre actif/inactif + signal de rafraîchissement) afin de prévenir les régressions sur la gestion des dépenses récurrentes.

**Why this priority**: Les abonnements sont la deuxième feature la plus utilisée. Le filtre actif/inactif est une logique métier spécifique qui nécessite une couverture dédiée.

**Independent Test**: Peut être vérifié indépendamment en exécutant la suite de tests du service Subscription.

**Acceptance Scenarios**:

1. **Given** le service est instancié avec un mock, **When** on récupère tous les abonnements sans filtre, **Then** l'endpoint est appelé sans paramètre de filtre
2. **Given** le service est instancié, **When** on récupère les abonnements avec le filtre actif à vrai, **Then** l'endpoint est appelé avec le paramètre de filtre actif
3. **Given** le service est instancié, **When** on récupère les abonnements avec le filtre actif à faux, **Then** l'endpoint est appelé avec le paramètre correspondant
4. **Given** le service est instancié, **When** on appelle la récupération d'un abonnement par identifiant, **Then** le service interroge l'endpoint avec l'identifiant correct et retourne l'abonnement
5. **Given** le service est instancié, **When** on crée un abonnement, **Then** l'endpoint de création est appelé et le signal de rafraîchissement est incrémenté
6. **Given** le service est instancié, **When** on met à jour un abonnement, **Then** l'endpoint de mise à jour est appelé et le signal de rafraîchissement est incrémenté
7. **Given** le service est instancié, **When** on supprime un abonnement, **Then** l'endpoint de suppression est appelé et le signal de rafraîchissement est incrémenté
8. **Given** le service est instancié, **When** on effectue plusieurs mutations successives, **Then** le signal de rafraîchissement est incrémenté de manière cumulative

---

### User Story 3 - Tests DebtService (Priority: P3)

En tant que développeur, je veux des tests unitaires couvrant toutes les opérations du service de dettes (CRUD + filtre remboursé + signal de rafraîchissement) afin de valider la gestion des créances et emprunts.

**Why this priority**: Les dettes suivent le même pattern CRUD que les autres services. Le filtre remboursé/non-remboursé est une logique métier importante à couvrir.

**Independent Test**: Peut être vérifié indépendamment en exécutant la suite de tests du service Debt.

**Acceptance Scenarios**:

1. **Given** le service est instancié avec un mock, **When** on récupère toutes les dettes sans filtre, **Then** l'endpoint est appelé sans paramètre de filtre
2. **Given** le service est instancié, **When** on récupère les dettes avec le filtre remboursé à vrai, **Then** l'endpoint est appelé avec le paramètre de filtre correspondant
3. **Given** le service est instancié, **When** on récupère les dettes avec le filtre remboursé à faux, **Then** l'endpoint est appelé avec le paramètre correspondant
4. **Given** le service est instancié, **When** on appelle la récupération d'une dette par identifiant, **Then** le service interroge l'endpoint avec l'identifiant correct et retourne la dette
5. **Given** le service est instancié, **When** on crée une dette, **Then** l'endpoint de création est appelé et le signal de rafraîchissement est incrémenté
6. **Given** le service est instancié, **When** on met à jour une dette, **Then** l'endpoint de mise à jour est appelé et le signal de rafraîchissement est incrémenté
7. **Given** le service est instancié, **When** on supprime une dette, **Then** l'endpoint de suppression est appelé et le signal de rafraîchissement est incrémenté
8. **Given** le service est instancié, **When** on effectue plusieurs mutations successives, **Then** le signal de rafraîchissement est incrémenté de manière cumulative

---

### Edge Cases

- Que se passe-t-il lorsque le signal de rafraîchissement est incrémenté plusieurs fois rapidement (opérations successives) ? → **Couvert** par le test `successive_mutations` dans chaque service
- Comment le service se comporte-t-il si l'identifiant fourni pour une opération unitaire est vide ou invalide ? → **Hors scope frontend** : les services sont des passthrough vers l'API, aucune validation d'input côté frontend. La validation est gérée par le backend (Bean Validation)
- Que retourne le résumé mensuel lorsqu'on fournit un mois hors limites (ex. mois 0 ou 13) ? → **Hors scope frontend** : le service construit le query string sans validation, le backend rejette les valeurs invalides
- Que se passe-t-il lorsque le filtre optionnel (actif, remboursé) n'est pas fourni vs fourni explicitement ? → **Couvert** par les tests de filtre (3 variantes : true/false/undefined)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Chaque service (Transaction, Subscription, Debt) DOIT avoir une suite de tests unitaires couvrant toutes ses méthodes publiques
- **FR-002**: Les tests DOIVENT vérifier que chaque opération de mutation (création, mise à jour, suppression) incrémente le signal de rafraîchissement
- **FR-003**: Les tests DOIVENT vérifier que les endpoints réseau corrects sont appelés avec les bons paramètres pour chaque opération
- **FR-004**: Les tests du service Transaction DOIVENT couvrir la méthode de résumé mensuel, avec et sans paramètres de filtre (mois/année)
- **FR-005**: Les tests du service Subscription DOIVENT couvrir le paramètre de filtre optionnel (actif : vrai, faux, non fourni)
- **FR-006**: Les tests du service Debt DOIVENT couvrir le paramètre de filtre optionnel (remboursé : vrai, faux, non fourni)
- **FR-007**: Les tests DOIVENT utiliser des mocks pour isoler la couche réseau (pas d'appels HTTP réels)
- **FR-008**: Les tests DOIVENT respecter le nommage `should_[résultat]_when_[condition]`
- **FR-009**: Tous les tests existants (pipes, services, composants) DOIVENT continuer à passer après l'ajout des nouveaux tests
- **FR-010**: Le projet DOIT compiler sans erreur et le linter ne DOIT pas signaler de warning

## Assumptions

- Les pipes AmountPipe et RelativeDatePipe ont déjà une couverture de tests complète (12 et 11 tests respectivement) et ne nécessitent pas de tests supplémentaires
- Les services suivent un pattern CRUD identique avec ApiService comme unique dépendance réseau
- Le signal `refreshTrigger` est un compteur incrémenté via `update()` après chaque opération de mutation
- Le runner de tests est Vitest (pas Jest) avec la configuration Angular 21 existante

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des méthodes publiques des 3 services sont couvertes par au moins un test
- **SC-002**: Chaque service dispose d'au minimum 6 tests unitaires (1 par méthode CRUD + tests spécifiques au service)
- **SC-003**: Tous les tests (existants + nouveaux) passent avec succès à l'exécution de la suite complète
- **SC-004**: Aucune erreur de compilation ni warning de linter après l'ajout des tests
- **SC-005**: Le signal de rafraîchissement est vérifié dans chaque test de mutation (création, mise à jour, suppression)
