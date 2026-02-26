# Research: Formulaire Virement

**Feature**: 050-flutter-transfer-form | **Date**: 2026-02-23

## Résumé

Aucun NEEDS CLARIFICATION identifié dans le Technical Context. Le backend est déjà implémenté (POST /accounts/transfer). Le système de modal supporte déjà `ModalType.transfer`. La recherche porte sur les patterns existants et les pièces manquantes.

## Décisions

### 1. Pas de feature module séparé pour le virement

**Decision**: Le formulaire de virement vit dans `features/transactions/` (pas de nouveau feature module `features/transfer/`).

**Rationale**: Un virement est une opération sur les transactions et comptes existants — ce n'est pas un domaine métier distinct. Il utilise le `TransactionNotifier` pour le refresh et le `AccountRepository` pour les données. Créer un feature module séparé serait du sur-découpage.

**Alternatives considered**:
- Feature module `features/transfer/` → Overhead inutile pour un formulaire sans state propre. Le virement n'a pas de liste, pas de détail, pas de CRUD propre. C'est une action ponctuelle.

### 2. Pas de TransferRepository dédié

**Decision**: La méthode `transfer()` est ajoutée à `AccountRemoteDataSource` et exposée via un provider direct (pas de repository abstract).

**Rationale**: Le backend expose l'endpoint sous `/accounts/transfer` (AccountController). Le virement n'a pas de mode local (Drift) — c'est une opération server-only (créer 2 transactions atomiquement). Un repository abstract avec interface serait du YAGNI pur.

**Alternatives considered**:
- `TransferRepository` abstract + `TransferRepositoryRemote` → Pattern repository complet pour une seule méthode sans variante locale. Surdimensionné.
- Ajouter à `TransactionRepository` → Le endpoint est sur `/accounts/`, pas `/transactions/`. Sémantiquement incorrect.

### 3. DTOs dans le fichier existant vs nouveau fichier

**Decision**: Créer `data/remote/dtos/transfer_dtos.dart` (nouveau fichier) pour `TransferRequest` et `TransferResponse`.

**Rationale**: Suit le pattern du projet (un fichier DTO par domaine). Les DTOs de transfert sont distincts des DTOs de transaction. `TransferResponse` contient des `TransactionRef` imbriqués (pas le même shape que `TransactionResponse`).

### 4. Gestion du refresh après virement

**Decision**: Après un virement réussi, rafraîchir le `TransactionListNotifier` (via `.refresh()`), comme le fait le shell Angular avec `refreshTrigger`.

**Rationale**: Le virement crée 2 transactions. La liste des transactions doit être mise à jour. Le pattern est déjà utilisé dans `_TransactionFormConsumer` dans `app_router.dart`.

### 5. Masquage conditionnel du FAB "Virement"

**Decision**: Le FAB filtre l'item "Virement" quand le nombre de comptes actifs est < 2. Le FAB watch le `accountNotifier` pour accéder à la liste des comptes.

**Rationale**: Cohérent avec le comportement Angular (bouton masqué si < 2 comptes). Empêche l'ouverture d'un formulaire inutilisable.

**Alternatives considered**:
- Toujours afficher et montrer un message dans le formulaire → Moins élégant, l'Angular masque le bouton.
- Message dans le formulaire en plus du masquage → Belt-and-suspenders, pas nécessaire si le FAB est déjà conditionnel.

### 6. Pas de mode édition pour le virement

**Decision**: Le formulaire de virement est en mode création uniquement. Pas d'édition ni de suppression de virement.

**Rationale**: Le backend ne fournit pas d'endpoint PUT/DELETE pour les virements. L'Angular ne supporte pas l'édition non plus. Un virement est une opération atomique irréversible (les transactions individuelles peuvent être supprimées séparément si nécessaire).
