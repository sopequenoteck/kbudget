# Research: Formulaire Dette Flutter

**Feature**: `047-flutter-debt-form` | **Date**: 2026-02-23

## Résumé

Aucun NEEDS CLARIFICATION dans le Technical Context ni dans la spec. La feature repose entièrement sur des patterns et infrastructures existants. La recherche se concentre sur la documentation des patterns à reproduire.

## Décisions

### D1 — Pattern du widget formulaire

**Décision**: Reproduire exactement le pattern `SubscriptionForm` (ConsumerStatefulWidget)

**Rationale**: Le formulaire dette est structurellement le plus proche du formulaire abonnement (champs similaires, pas de champ complexe type transfert). Les deux utilisent un toggle dans le header de la modale et des champs texte + sélecteurs.

**Alternatives considérées**:
- Pattern `TransactionForm` : plus complexe (gestion des comptes source/destination pour transferts), surdimensionné pour le cas dette.
- `ConsumerWidget` stateless : insuffisant car le formulaire nécessite des `TextEditingController` et un état interne (`_showErrors`, `_isSubmitting`).

### D2 — Champs du formulaire

**Décision**: 4 champs + 1 switch (mode édition uniquement)

| Champ | Type | Obligatoire | Source |
| ----- | ---- | ----------- | ------ |
| Personne | TextEditingController | Oui | Saisie libre |
| Montant | TextEditingController (numérique) | Oui | Saisie libre |
| Date | DateTime + DatePicker | Oui (défaut: aujourd'hui) | Sélecteur natif |
| Catégorie | CategoryPicker | Non | Liste existante |
| Remboursé | Switch | N/A (édition only) | Toggle on/off |

**Rationale**: Aligné avec le modèle `Debt` Freezed et le DTO backend `DebtRequest`. Le champ `sens` (emprunt/prêt) est contrôlé par le toggle dans le header de la modale, pas dans le formulaire lui-même.

### D3 — Intégration modale

**Décision**: Ajouter le cas `ModalType.debt` dans `_buildModalChild()` de `app_router.dart`, suivant le pattern `_DebtFormConsumer` (ConsumerWidget inline).

**Rationale**: Les formulaires transaction et abonnement suivent ce pattern exact. Le `_DebtFormConsumer` lit `modalNotifierProvider` pour obtenir le `subType` (DebtType) et l'entité à éditer, puis passe ces données au `DebtForm`.

**Alternatives considérées**:
- Widget séparé dans un fichier dédié : incohérent avec les patterns existants (`_TransactionFormConsumer` et `_SubscriptionFormConsumer` sont des classes privées inline dans `app_router.dart`).

### D4 — Localisation

**Décision**: Ajouter les clés i18n dans `app_fr.arb` pour les labels, placeholders, erreurs de validation et messages de confirmation.

**Rationale**: Cohérent avec les clés existantes pour transaction et subscription. Les clés suivront le pattern `debtXxx` (ex: `debtPerson`, `debtAmount`, `debtDeleteConfirm`).

### D5 — Tests

**Décision**: Tests unitaires du notifier (CRUD) + widget tests du formulaire.

**Rationale**: Suit le pattern des tests existants pour TransactionForm et SubscriptionForm. Les tests notifier utilisent `ProviderContainer` avec mock du repository. Les widget tests vérifient le rendu, la validation et les callbacks.
