# Quickstart: Dashboard Finance

**Feature**: 090-finance-dashboard

## Prerequis

- Node.js + Angular CLI (frontend Angular)
- Flutter SDK >= 3.27 (frontend Flutter)
- Backend API en cours d'execution (profil dev)

## Lancer le backend

```bash
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

## Tester Angular

```bash
cd app && ng serve
# Ouvrir http://localhost:4200 → dashboard
```

Fichiers a modifier :
- `app/src/app/features/dashboard/dashboard.ts` — composant principal
- `app/src/app/features/dashboard/dashboard.html` — template
- `app/src/app/features/dashboard/dashboard.scss` — styles
- `app/src/app/features/dashboard/components/` — sous-composants

## Tester Flutter

```bash
cd flutter && flutter run
# Le dashboard s'affiche par defaut
```

Fichiers a modifier :
- `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart` — ecran principal
- `flutter/lib/src/features/dashboard/presentation/` — sections (HeroAccountSection, MonthlySummarySection, etc.)
- `flutter/lib/src/features/dashboard/application/dashboard_notifier.dart` — logique metier
- `flutter/lib/src/features/dashboard/application/dashboard_state.dart` — state Freezed

## Tests

```bash
cd app && ng test    # Tests Angular
cd flutter && flutter test test/src/features/dashboard/  # Tests Flutter
```

## Points de verification rapide

1. Le patrimoine total affiche la variation nette du mois (montant + %)
2. Les cartes revenus/depenses affichent la comparaison vs mois precedent
3. La section budgets affiche max 4 items tries par urgence
4. Les contre-valeurs apparaissent quand une devise secondaire est selectionnee
5. Le changement de devise dans le selecteur met a jour toutes les contre-valeurs
6. Le dashboard se rafraichit automatiquement toutes les 60s
7. Les etats vides affichent des messages d'incitation
