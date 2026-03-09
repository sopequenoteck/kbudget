# Quickstart — 076-budget-category-tracking

## Prérequis

- Branches KKS-073, KKS-074, KKS-075 mergées dans main
- Java 21, Maven, PostgreSQL 15+ (backend)
- Node.js 20+, Angular CLI (frontend)
- Flutter >= 3.27, Dart >= 3.6 (mobile)

## Ordre d'implémentation

```
1. Backend — Enums + DTOs + Queries          (indépendant)
2. Backend — BudgetService "Autre"           (dépend de 1)
3. Backend — Notifications seuil             (dépend de 1)
4. Backend — Tests                           (dépend de 2, 3)
5. Angular — Modèles + "Autre" + toggle      (dépend de 2)
6. Flutter — Modèles + "Autre" remote        (dépend de 2)
7. Flutter — "Autre" local + snapshots lazy   (indépendant)
8. Flutter — Multi-devises local             (indépendant)
9. Tests frontends                           (dépend de 5, 6, 7, 8)
```

## Vérification rapide

```bash
# Backend
cd api && mvn test -Dtest="BudgetServiceTest,BudgetControllerTest"

# Flutter
cd flutter && flutter test test/src/features/budgets/

# Angular
cd app && ng test --include='**/budgets/**'
```

## Points d'attention

- Ne pas créer de migration Flyway : le schéma est déjà complet (V17)
- Les enums `NotificationType` et `EntityType` sont des enums Java avec stockage VARCHAR — pas de migration Flyway nécessaire, juste ajouter les valeurs dans le code Java
- En Flutter local, la table `exchange_rates` peut être vide → fallback taux 1.0
- Les notifications utilisent le `NotificationService` existant qui envoie via STOMP + persiste en BDD
