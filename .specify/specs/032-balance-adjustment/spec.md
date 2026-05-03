# Feature Specification: Ajustement de solde de compte bancaire

**Feature Branch**: `032-balance-adjustment`
**Created**: 2026-02-19
**Status**: Draft
**Input**: Permettre à l'utilisateur de corriger le solde d'un compte bancaire en créant automatiquement une transaction d'ajustement.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ajuster le solde d'un compte (Priority: P1)

L'utilisateur ouvre le formulaire d'édition d'un compte bancaire. Il voit le solde actuel calculé du compte. Il saisit un nouveau solde souhaité. Le système calcule la différence et crée automatiquement une transaction de type "Ajustement" pour combler l'écart. Le solde du compte reflète immédiatement la correction.

**Why this priority**: C'est le cœur de la feature — sans cette capacité, rien d'autre n'a de sens. C'est le cas d'usage principal : l'utilisateur constate que son solde dans l'app ne correspond pas à son solde bancaire réel et veut le corriger.

**Independent Test**: Peut être testé en modifiant le solde d'un compte existant et en vérifiant que le nouveau solde est correct après soumission.

**Acceptance Scenarios**:

1. **Given** un compte "Compte Principal" avec un solde actuel de 500 EUR, **When** l'utilisateur saisit un nouveau solde de 750 EUR et valide, **Then** une transaction d'ajustement de +250 EUR est créée et le solde affiché passe à 750 EUR.
2. **Given** un compte "Compte Principal" avec un solde actuel de 500 EUR, **When** l'utilisateur saisit un nouveau solde de 300 EUR et valide, **Then** une transaction d'ajustement de -200 EUR est créée et le solde affiché passe à 300 EUR.
3. **Given** un compte avec un solde actuel de 500 EUR, **When** l'utilisateur saisit un nouveau solde de 500 EUR (identique) et valide, **Then** aucune transaction d'ajustement n'est créée et le formulaire se ferme normalement.

---

### User Story 2 - Consulter l'historique des ajustements (Priority: P2)

L'utilisateur consulte la liste des transactions d'un compte. Les transactions d'ajustement apparaissent dans l'historique au même titre que les autres transactions, avec un libellé clair et une catégorie "Ajustement" permettant de les identifier facilement.

**Why this priority**: La traçabilité est essentielle pour comprendre l'évolution du solde. Sans elle, l'utilisateur ne peut pas retracer pourquoi son solde a changé.

**Independent Test**: Après avoir créé un ajustement, vérifier qu'il apparaît dans la liste des transactions avec la catégorie "Ajustement" et un libellé explicatif.

**Acceptance Scenarios**:

1. **Given** un ajustement de +250 EUR a été créé sur un compte, **When** l'utilisateur consulte l'historique des transactions de ce compte, **Then** la transaction d'ajustement apparaît avec le libellé "Ajustement de solde", la catégorie "Ajustement", et le montant +250 EUR.
2. **Given** plusieurs ajustements ont été créés sur un compte, **When** l'utilisateur consulte l'historique, **Then** chaque ajustement est visible, daté du jour de sa création, et trié chronologiquement avec les autres transactions.

---

### User Story 3 - Ajuster le solde du compte par défaut initial (Priority: P3)

Un nouvel utilisateur vient de s'inscrire. Son compte par défaut "Compte Principal" a un solde initial de 0 EUR. Il souhaite renseigner son solde réel actuel. Il édite le compte et saisit son vrai solde. Le système crée une transaction d'ajustement pour mettre à jour le solde.

**Why this priority**: C'est un cas d'usage courant lors de l'onboarding d'un utilisateur, mais c'est un sous-cas de la User Story 1.

**Independent Test**: Créer un compte avec un solde initial de 0, ajuster à 1500 EUR, vérifier que le solde final est 1500 EUR.

**Acceptance Scenarios**:

1. **Given** un compte par défaut avec un solde de 0 EUR (aucune transaction), **When** l'utilisateur saisit un nouveau solde de 1500 EUR, **Then** une transaction d'ajustement de +1500 EUR est créée et le solde du compte passe à 1500 EUR.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur saisit un montant négatif comme nouveau solde ? Le système doit l'accepter (un solde négatif est un découvert valide) et créer la transaction d'ajustement correspondante.
- Que se passe-t-il si la catégorie système "Ajustement" n'existe pas encore pour cet utilisateur ? Le système doit la créer automatiquement avant de créer la transaction.
- Que se passe-t-il si l'utilisateur tente d'ajuster le solde d'un compte inactif ? L'opération doit être refusée.
- Que se passe-t-il si le nouveau solde saisi est identique au solde actuel ? Aucune transaction ne doit être créée.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre à l'utilisateur de saisir un nouveau solde souhaité lors de l'édition d'un compte bancaire.
- **FR-002**: Le système DOIT calculer automatiquement la différence entre le solde actuel du compte et le nouveau solde souhaité. Le solde actuel est calculé selon la formule : `solde_initial + Σ recettes - Σ dépenses + Σ ajustements` (montants signés pour les ajustements).
- **FR-003**: Le système DOIT créer une transaction de type `AJUSTEMENT` dont le montant correspond à la différence signée (nouveau_solde - solde_actuel). Un montant positif indique un ajustement à la hausse, un montant négatif un ajustement à la baisse. Pas de notion recette/dépense pour ce type.
- **FR-004**: La transaction d'ajustement DOIT être associée à une catégorie système "Ajustement", créée automatiquement si elle n'existe pas pour l'utilisateur.
- **FR-005**: Le système NE DOIT PAS créer de transaction si le nouveau solde est identique au solde actuel.
- **FR-006**: Le système DOIT refuser l'ajustement sur un compte inactif.
- **FR-007**: Le type de transaction "Ajustement" DOIT être ajouté au domaine en complément des types existants (Dépense, Recette).
- **FR-008**: Les transactions d'ajustement DOIVENT apparaître dans l'historique des transactions du compte, avec un libellé "Ajustement de solde" et la date du jour de création.
- **FR-009**: Le formulaire d'édition de compte DOIT afficher le solde actuel calculé du compte et permettre sa modification.
- **FR-010**: L'ajustement DOIT être atomique — le calcul du solde actuel et la création de la transaction doivent être traités comme une seule opération pour éviter les incohérences.
- **FR-011**: L'ajustement de solde DOIT être exposé via un endpoint REST dédié `POST /api/accounts/{id}/adjust-balance` avec un body `{ "newBalance": <montant> }`. Ce endpoint est distinct de la mise à jour des propriétés du compte (`PUT /api/accounts/{id}`).
- **FR-012**: Les transactions de type `AJUSTEMENT` NE DOIVENT PAS être modifiables ni supprimables. L'API DOIT retourner une erreur 403 sur les tentatives de modification ou suppression. Le frontend DOIT masquer les boutons d'édition et de suppression pour ces transactions.
- **FR-013**: Le résumé mensuel DOIT exclure les transactions d'ajustement du total des recettes et du total des dépenses. Les ajustements DOIVENT être inclus dans le calcul du solde mensuel (recettes - dépenses + ajustements).
- **FR-014**: Les transactions de type `AJUSTEMENT` NE DOIVENT PAS être créables via l'endpoint standard `POST /api/transactions`. Seul le workflow `POST /api/accounts/{id}/adjust-balance` peut créer ce type. L'API DOIT retourner une erreur 400 sur toute tentative de création directe.

### Key Entities

- **Transaction (type Ajustement)** : Nouvelle variante du type de transaction. Montant signé = nouveau_solde - solde_actuel (positif = hausse, négatif = baisse). Pas de notion recette/dépense. Associée à la catégorie système "Ajustement". Libellé automatique "Ajustement de solde". Rattachée au compte concerné.
- **Catégorie système "Ajustement"** : Catégorie marquée comme système (non modifiable/supprimable par l'utilisateur). Créée de manière lazy lors du premier ajustement de solde pour chaque utilisateur (pas de migration Flyway). Icône et couleur par défaut prédéfinies.
- **TransactionType** : Enum étendu avec la valeur `AJUSTEMENT` en plus de `DEPENSE` et `RECETTE`. Le montant est signé (+/-) pour les transactions AJUSTEMENT, contrairement à DEPENSE/RECETTE où le type détermine la direction.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut ajuster le solde d'un compte en moins de 3 interactions (ouvrir l'édition, saisir le nouveau solde, valider).
- **SC-002**: Après un ajustement, le solde affiché du compte correspond exactement au montant saisi par l'utilisateur.
- **SC-003**: 100% des ajustements de solde sont traçables dans l'historique des transactions avec la catégorie "Ajustement".
- **SC-004**: L'ajustement fonctionne pour tous les types de comptes (courant, épargne, espèces) et toutes les devises supportées.

## Assumptions

- Le solde négatif est un état valide pour un compte (découvert autorisé).
- La catégorie système "Ajustement" utilise icône "⚖️" (U+2696 balance) et couleur "#6b7280" (gray-500, neutre).
- Les transactions d'ajustement ne sont pas modifiables ni supprimables (protégé côté API avec erreur 403, et boutons masqués côté frontend).
- Le libellé "Ajustement de solde" est fixe et non personnalisable par l'utilisateur.
- Le frontend cible est Angular uniquement (app/ existante), pas Flutter.

## Clarifications

### Session 2026-02-19

- Q: TransactionType — nouveau AJUSTEMENT vs utiliser DEPENSE/RECETTE avec catégorie ? → A: Nouveau `TransactionType.AJUSTEMENT` avec montant signé (+/-), pas de notion recette/dépense.
- Q: API — endpoint dédié vs intégré au PUT accounts ? → A: Endpoint dédié `POST /accounts/{id}/adjust-balance` avec body `{ "newBalance": <montant> }`.
- Q: Immutabilité — comment empêcher la modification/suppression des ajustements ? → A: Protection API (403 sur edit/delete) + masquage des boutons côté frontend.
- Q: Catégorie système "Ajustement" — migration Flyway ou création lazy ? → A: Création lazy lors du premier ajustement de solde pour chaque user (pas de migration Flyway).
- Q: Calcul du solde — comment intégrer AJUSTEMENT dans la formule ? → A: Montant signé additionné directement : `solde_initial + recettes - dépenses + ajustements`.
- Q: Frontend cible — Angular ou Flutter ? → A: Angular uniquement (app/ existante).
