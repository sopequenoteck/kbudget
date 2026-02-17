# Research: Comptes bancaires — Frontend

**Branch**: `027-bank-accounts-frontend` | **Date**: 2026-02-16

## Contexte

Cette feature est purement frontend. L'API backend est deja implementee et testee (feature 026-bank-accounts). Le frontend Angular existant suit des patterns bien etablis. Aucun "NEEDS CLARIFICATION" technique n'a ete identifie.

## Decisions

### D1 — Pattern du AccountService

**Decision** : Repliquer le pattern exact de `TransactionService` / `SubscriptionService` / `DebtService`.

**Rationale** : Tous les services existants suivent le meme pattern (inject ApiService, methodes CRUD retournant Observable, signal `refreshTrigger`). Aucune raison de devier.

**Alternatives considerees** :
- Signal-based service (store pattern) : Rejete, trop complexe pour le scope, violerait YAGNI.
- NgRx / state management : Rejete, sur-ingenierie pour une app single-user.

### D2 — Composant AccountPicker (selecteur de compte)

**Decision** : Creer un composant partage `AccountPicker` sur le meme modele que `CategoryPicker`.

**Rationale** : Le selecteur de compte est utilise dans 3 contextes (transaction-form, subscription-form, transfer-form). Un composant partage evite la duplication.

**Alternatives considerees** :
- Select HTML natif : Rejete, ne permet pas d'afficher icone + couleur + solde.
- Inline dans chaque formulaire : Rejete, duplication de code dans 3 endroits.

### D3 — Placement des comptes dans Settings (pas en navigation principale)

**Decision** : Les comptes sont une sous-page de Settings, pas un onglet de navigation principal.

**Rationale** : Decision utilisateur (clarification session). Les comptes sont configures une fois puis utilises via le dashboard et les formulaires. Pas d'acces frequent necessaire.

### D4 — Section comptes en haut du dashboard

**Decision** : Nouvelle section au-dessus des KPI mensuels existants.

**Rationale** : Decision utilisateur (clarification session). Le solde patrimonial global est l'information la plus importante a voir en premier.

### D5 — Formulaire de virement via ModalService

**Decision** : Ajouter un type `transfer` au `ModalService` existant pour gerer le formulaire de virement.

**Rationale** : Le systeme de modals centralise est deja en place pour transaction/subscription/debt/category. Ajouter `transfer` suit le meme pattern.

**Alternatives considerees** :
- Page dediee `/transfers` : Rejete, le virement est une action ponctuelle, pas une liste a consulter.
- Formulaire inline sur la page comptes : Rejete, le FAB (+) doit pouvoir ouvrir le virement depuis n'importe ou.

### D6 — Gestion des entites existantes sans compte

**Decision** : Les transactions/abonnements sans `accountId` s'affichent normalement. Le champ compte est vide dans les listes et peut etre assigne lors de l'edition.

**Rationale** : Decision utilisateur (clarification session). Approche non-intrusive, pas de wizard de migration force.

### D7 — Modele Transaction enrichi

**Decision** : Ajouter `account: AccountSummary | null` et `transferId: string | null` a l'interface `Transaction`. Ajouter `accountId?: string` a `TransactionRequest`.

**Rationale** : Reflete les DTOs backend existants. Le champ `account` utilise `AccountSummary` (id, nom, icone, couleur) plutot que l'objet complet pour les references.
