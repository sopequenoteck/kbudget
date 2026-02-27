# Quickstart: Système de Feature Toggles — Backend

**Branch**: `055-backend-feature-toggles`

## Prérequis

- Java 21
- Maven
- PostgreSQL 15+ en cours d'exécution
- Profil `dev` configuré

## Séquence de build

```bash
# 1. Se placer dans le module API
cd api

# 2. Compiler (inclut la migration Flyway V9 au démarrage)
mvn clean compile

# 3. Lancer en mode dev
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 4. Vérifier l'endpoint
curl -H "Authorization: Bearer <token>" http://localhost:8080/api/users/me/preferences
```

## Tests

```bash
cd api

# Tous les tests
mvn test

# Tests du controller préférences uniquement
mvn test -Dtest=PreferenceControllerTest

# Tests du service préférences uniquement
mvn test -Dtest=PreferenceServiceTest
```

## Fichiers créés/modifiés

### Nouveaux fichiers

| Fichier | Description |
|---------|-------------|
| `enums/Feature.java` | Enum des fonctionnalités optionnelles |
| `model/UserPreference.java` | Entité JPA |
| `model/converter/FeatureListConverter.java` | Converter JPA List\<Feature\> ↔ String |
| `dto/request/UserPreferenceRequest.java` | DTO requête PUT |
| `dto/response/UserPreferenceResponse.java` | DTO réponse GET/PUT |
| `repository/UserPreferenceRepository.java` | Repository JPA |
| `service/PreferenceService.java` | Logique métier |
| `controller/PreferenceController.java` | Endpoints REST |
| `V9__add_user_preferences.sql` | Migration Flyway |
| `PreferenceControllerTest.java` | Tests d'intégration |
| `PreferenceServiceTest.java` | Tests unitaires |

### Fichiers non modifiés

Aucun fichier existant n'est modifié. Cette feature est entièrement additive.

## Vérification rapide

```bash
# GET — doit retourner les valeurs par défaut
curl -s -H "Authorization: Bearer <token>" \
  http://localhost:8080/api/users/me/preferences | jq

# PUT — désactiver les dettes
curl -s -X PUT -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"enabledFeatures": ["SUBSCRIPTIONS", "SHOP"]}' \
  http://localhost:8080/api/users/me/preferences | jq

# PUT — réordonner
curl -s -X PUT -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"], "navOrder": ["SHOP", "DEBTS", "SUBSCRIPTIONS"]}' \
  http://localhost:8080/api/users/me/preferences | jq
```
