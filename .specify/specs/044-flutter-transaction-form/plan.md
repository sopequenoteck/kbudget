# Implementation Plan: Flutter — Formulaire Transaction

**Branch**: `044-flutter-transaction-form` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/044-flutter-transaction-form/spec.md`

## Summary

Implémentation du formulaire de transaction Flutter dans un modal (AppModal) avec toggle Dépense/Recette dans le header. Le formulaire supporte la création, l'édition et la suppression de transactions. Il s'appuie sur les widgets communs existants (AppFormField, SelectPicker, CategoryPicker, AppToggle) et le CRUD notifier Riverpod existant (TransactionNotifier).

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, freezed, go_router, intl
**Storage**: Drift (SQLite local) / Dio (API REST) via strategy pattern `dataModeProvider`
**Testing**: flutter_test + mockito
**Target Platform**: iOS, Android (mobile-first)
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Ouverture du formulaire < 100ms, soumission perçue instantanée
**Constraints**: Offline-capable (local-first via Drift), single-user
**Scale/Scope**: 1 écran (formulaire dans modal), ~3 fichiers à créer, ~2 fichiers à modifier

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Endpoints CRUD transactions déjà existants. Aucun nouveau endpoint requis. |
| II. Sécurité par défaut | PASS | JWT géré par Dio interceptors. Données filtrées par user authentifié côté API. |
| III. Simplicité & YAGNI | PASS | Form = ConsumerStatefulWidget simple avec controllers. Pas d'abstraction prématurée (pas de FormNotifier séparé). |
| IV. Mobile-First UX | PASS | Objectif principal : saisie rapide en 2-3 interactions. FAB (+) existant. Modal optimisé mobile. |
| V. Testabilité | PASS | Widget tests sur le formulaire. Tests unitaires sur la logique de validation. |
| VI. Observabilité | N/A | Feature Flutter frontend uniquement — pas de logging backend. |
| VII. Self-Hosted Ready | N/A | Aucun changement d'infrastructure. |

**Résultat** : Tous les gates passent. Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/044-flutter-transaction-form/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/features/transactions/
├── application/
│   ├── transaction_notifier.dart           # Existant — CRUD
│   ├── transaction_list_notifier.dart       # Existant — état liste
│   └── transaction_list_state.dart          # Existant — filtres
└── presentation/
    ├── transactions_screen.dart              # Existant — MODIFIER (ouverture modal)
    ├── widgets/
    │   ├── transaction_list_item.dart        # Existant
    │   └── transaction_form.dart             # NOUVEAU — contenu du formulaire

flutter/lib/src/localization/
└── app_fr.arb                               # Existant — MODIFIER (labels du formulaire)

flutter/test/src/features/transactions/
└── presentation/
    └── widgets/
        └── transaction_form_test.dart        # NOUVEAU — si tests demandés
```

**Structure Decision** : Feature Flutter uniquement. Le formulaire est un widget `ConsumerStatefulWidget` placé comme `child` dans `AppModal.show()`. Le toggle type est passé en `headerActions` du modal. Aucun nouveau fichier d'application (notifier/state) — le `TransactionNotifier` existant couvre le CRUD.

### Architecture du formulaire

```text
TransactionsScreen (existant)
  │
  ├── FAB (+) tap → AppModal.show(
  │     title: i18n.newTransaction,
  │     headerActions: AppToggle(labels: ['Dépense', 'Recette']),
  │     child: TransactionForm(onSaved: ..., onCancelled: ...)
  │   )
  │
  └── ListItem tap → AppModal.show(
        title: i18n.editTransaction,
        headerActions: AppToggle(labels: ['Dépense', 'Recette']),
        child: TransactionForm(transaction: tx, onSaved: ..., onDeleted: ..., onCancelled: ...)
      )

TransactionForm (nouveau ConsumerStatefulWidget)
  ├── AppFormField + TextField  → libellé
  ├── AppFormField + TextField  → montant (numeric keyboard)
  ├── AppFormField + DatePicker → date
  ├── SelectPicker              → compte (accountNotifierProvider)
  ├── CategoryPicker            → catégorie (categoryNotifierProvider)
  ├── AppFormField + TextField  → note (multiligne, optionnel)
  ├── Bouton "Enregistrer" / "Modifier"
  └── Bouton "Supprimer" (mode édition uniquement)
```

### Flux de données

```text
1. Création:
   FAB tap → AppModal ouvert → TransactionForm (vide, defaults)
   → User remplit → Valide → onSaved(Transaction) callback
   → Parent appelle transactionNotifier.create(tx)
   → Modal ferme → Liste rafraîchie

2. Édition:
   ListItem tap → AppModal ouvert → TransactionForm (pré-rempli)
   → User modifie → Valide → onSaved(Transaction) callback
   → Parent appelle transactionNotifier.update(tx)
   → Modal ferme → Liste rafraîchie

3. Suppression:
   Mode édition → Bouton supprimer → Dialog confirmation
   → Confirme → onDeleted(id) callback
   → Parent appelle transactionNotifier.delete(id)
   → Modal ferme → Transaction disparaît
```

## Complexity Tracking

> Aucune violation de constitution à justifier.
