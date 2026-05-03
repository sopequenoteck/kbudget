# Implementation Plan: Formulaire Virement

**Branch**: `050-flutter-transfer-form` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/050-flutter-transfer-form/spec.md`

## Summary

Implémenter le formulaire de virement entre comptes dans le module Flutter. Le formulaire s'ouvre en modal depuis le FAB, permet de sélectionner un compte source et destination, saisir un montant et une note optionnelle, puis soumet via POST `/accounts/transfer`. Le backend crée atomiquement 2 transactions liées. Le FAB masque l'option "Virement" si < 2 comptes actifs.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, freezed, json_serializable, go_router, dio
**Storage**: Serveur uniquement (opération atomique, pas de stockage local)
**Testing**: flutter_test + ProviderContainer avec overrides
**Target Platform**: iOS & Android (mobile-first)
**Project Type**: Mobile app (module Flutter du monorepo)
**Performance Goals**: Feedback < 3s après validation (SC-002)
**Constraints**: Dépend de KKS-94, KKS-95, KKS-96, KKS-115. Création uniquement, pas d'édition.
**Scale/Scope**: 1 formulaire modal, DTOs, méthode transfer sur data source, intégration FAB + router

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | ✅ PASS | Backend déjà implémenté (POST `/accounts/transfer`). DTOs Flutter séparent API de domaine. |
| II. Sécurité par défaut | ✅ PASS | JWT via `authenticatedDioProvider` + `JwtInterceptor`. Validation côté backend (comptes de l'user authentifié). |
| III. Simplicité & YAGNI | ✅ PASS | Pas de repository abstract (server-only, 1 seule méthode). Formulaire simple dans features/transactions/. |
| IV. Mobile-First UX | ✅ PASS | Virement en 4 interactions max (FAB → menu → form → valider). FAB accessible. |
| V. Testabilité | ✅ PASS | Formulaire testable via ProviderScope + mock. Validation testable unitairement. |
| VI. Observabilité | ✅ N/A | Feature frontend uniquement. Le backend logge déjà le POST /accounts/transfer. |
| VII. Self-Hosted Ready | ✅ PASS | Aucune dépendance externe ajoutée. Consomme l'API existante. |

## Project Structure

### Documentation (this feature)

```text
specs/050-flutter-transfer-form/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api-contract.md
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── common_widgets/
│   └── fab_menu.dart                        # MODIFY — masquer "Virement" si < 2 comptes actifs
├── data/remote/
│   ├── data_sources/
│   │   └── account_remote_data_source.dart  # MODIFY — ajouter méthode transfer()
│   └── dtos/
│       └── transfer_dtos.dart               # NEW — TransferRequest, TransferResponse, TransactionRef
├── localization/
│   ├── app_fr.arb                             # MODIFY — ajouter chaînes i18n du formulaire de virement
│   └── app_en.arb                             # MODIFY — ajouter chaînes i18n du formulaire de virement
├── features/
│   └── transactions/
│       └── presentation/
│           └── widgets/
│               └── transfer_form.dart       # NEW — formulaire de virement
├── routing/
│   └── app_router.dart                      # MODIFY — ajouter case ModalType.transfer dans _buildModalChild
```

**Structure Decision** : Le formulaire vit dans `features/transactions/presentation/widgets/` car le virement est une opération sur les transactions existantes, pas un domaine séparé. Les DTOs de transfert ont leur propre fichier (`transfer_dtos.dart`) car leur shape est distincte des DTOs de transaction. La méthode `transfer()` est ajoutée à `AccountRemoteDataSource` (cohérent avec l'endpoint `/accounts/transfer` du backend).

**Provider Decision** : Pas de repository abstract ni de provider dédié. Le `transfer()` est appelé directement depuis le consumer (`_TransferFormConsumer`) via `accountRemoteDataSource.transfer()`. YAGNI — une seule méthode, server-only, pas de variante locale.

## Complexity Tracking

> Aucune violation de la constitution détectée. Pas de complexité additionnelle requise.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
