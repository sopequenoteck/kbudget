# Implementation Plan: Banques sur les comptes — Flutter

**Branch**: `083-flutter-bank-accounts` | **Date**: 2026-03-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/083-flutter-bank-accounts/spec.md`

## Summary

Intégrer l'association bancaire aux comptes dans l'app Flutter, alignée avec l'implémentation Angular (KKS-082). Cela comprend : un modèle Bank (Freezed) + repository remote, un widget `BankSelectPicker` (bottom sheet groupée par pays avec recherche), un widget `AccountBankIcon` (résolution logo SVG/custom/emoji), l'enrichissement du modèle Account + DTOs + Drift avec les champs bank, et la mise à jour de tous les écrans affichant des comptes (dashboard, listes, sélecteurs, formulaire).

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, json_serializable, dio, flutter_svg (nouveau), image_picker, shimmer, phosphor_flutter
**Storage**: SQLite/Drift (table Accounts enrichie +3 colonnes) + API REST/Dio (GET /api/banks, GET/POST/PUT /api/accounts)
**Testing**: flutter_test + Mockito
**Target Platform**: iOS, Android
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Rendu SVG 60fps, chargement banques < 500ms
**Constraints**: Assets SVG embarqués pour rendu offline des logos
**Scale/Scope**: 29 banques, ~10 fichiers à modifier, ~9 fichiers à créer, ~5 écrans impactés

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Le backend KKS-081 est terminé. Les banques sont consommées depuis `GET /api/banks`. Les comptes enrichis passent par les DTOs existants. |
| II. Sécurité par défaut | PASS | `GET /banks` est public (données statiques). Les comptes restent protégés par JWT. Pas de secret exposé. |
| III. Simplicité & YAGNI | PASS | Architecture simple : FutureProvider pour les banques, pas de pattern complexe. BankSelectPicker dédié plutôt qu'enrichissement du SelectPicker générique. |
| IV. Mobile-First UX | PASS | Bottom sheet native pour le sélecteur, recherche temps réel, masquage conditionnel fluide. Association banque en 2-3 interactions. |
| V. Testabilité | PASS | Widget tests prévus pour AccountBankIcon et BankSelectPicker. Repository mockable via interface abstraite. |
| VI. Observabilité | N/A | Feature frontend, pas de logging serveur ajouté. |
| VII. Self-Hosted Ready | PASS | Pas de dépendance cloud. Assets SVG embarqués localement. |

**Constitution Check post-design** : PASS — aucune violation détectée.

## Project Structure

### Documentation (this feature)

```text
specs/083-flutter-bank-accounts/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: research decisions
├── data-model.md        # Phase 1: data model changes
├── quickstart.md        # Phase 1: build & test guide
├── contracts/
│   └── api-consumed.md  # Phase 1: API contracts consumed
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/
├── assets/
│   └── banks/                          # 29 logos SVG (nouveau)
│       ├── sg.svg
│       ├── bnp.svg
│       └── ...
├── lib/src/
│   ├── common_widgets/
│   │   ├── account_bank_icon.dart      # Widget résolution logo (nouveau)
│   │   ├── bank_select_picker.dart     # Sélecteur banque bottom sheet (nouveau)
│   │   └── select_picker.dart          # +imageUrl sur SelectPickerItem (modifié)
│   ├── data/
│   │   ├── local/
│   │   │   ├── database.dart           # +3 colonnes Accounts + migration (modifié)
│   │   │   └── mappers.dart            # +3 champs accountFromDb/accountToDb (modifié)
│   │   └── remote/
│   │       ├── data_sources/
│   │       │   └── bank_remote_data_source.dart  # Dio GET /api/banks (nouveau)
│   │       └── dtos/
│   │           ├── account_dtos.dart    # +champs bank request/response (modifié)
│   │           └── bank_dtos.dart       # BankResponse DTO (nouveau)
│   ├── domain/
│   │   ├── models/
│   │   │   └── account.dart            # +7 champs bank Freezed (modifié)
│   │   └── repositories/
│   │       └── bank_repository.dart    # Interface abstraite (nouveau)
│   ├── features/
│   │   └── accounts/
│   │       ├── application/
│   │       │   └── bank_provider.dart  # banksProvider FutureProvider (nouveau)
│   │       ├── data/
│   │       │   ├── account_repository_remote.dart  # +champs bank mappers (modifié)
│   │       │   └── bank_repository_remote.dart      # Implémentation remote (nouveau)
│   │       └── presentation/
│   │           ├── screens/
│   │           │   └── account_form_screen.dart  # +sélecteur banque + masquage (modifié)
│   │           └── widgets/
│   │               ├── account_list_tile.dart     # +AccountBankIcon (modifié)
│   │               └── account_preview_card.dart  # +logo banque preview (modifié)
│   └── features/
│       └── dashboard/
│           └── presentation/
│               └── widgets/
│                   └── hero_account_section.dart  # +AccountBankIcon (modifié)
├── pubspec.yaml                        # +flutter_svg, +assets/banks/ (modifié)
└── test/
    └── src/features/accounts/
        ├── account_bank_icon_test.dart  # Tests widget (nouveau)
        └── bank_select_picker_test.dart # Tests widget (nouveau)
```

**Structure Decision**: Feature Flutter uniquement, pas de modification backend. Les fichiers suivent la structure existante du monorepo (`flutter/lib/src/`). Les nouveaux fichiers bank sont placés dans le domaine `accounts` car les banques sont une sous-entité des comptes dans le contexte de cette app.

## Complexity Tracking

Aucune violation de la constitution — tableau non requis.
