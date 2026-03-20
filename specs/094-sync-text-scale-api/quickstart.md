# Quickstart: Sync TextScale via API

**Branch**: `094-sync-text-scale-api`

## Backend

```bash
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

Vérifier la migration V21 : `SELECT text_scale FROM user_preferences LIMIT 5;` → toutes les lignes ont `MEDIUM`.

## Frontend

```bash
cd app && npx ng serve
```

## Vérification

1. GET `/api/users/me/preferences` → réponse contient `"textScale": "MEDIUM"`
2. PUT `/api/users/me/preferences` avec `{ "enabledFeatures": [...], "textScale": "LARGE" }` → réponse contient `"textScale": "LARGE"`
3. GET à nouveau → `"textScale": "LARGE"` persisté
4. Ouvrir `http://localhost:4200/settings/appearance` → changer taille → vérifier dans un autre onglet que la valeur est sync
5. Se déconnecter/reconnecter → taille restaurée depuis le serveur

## Tests

```bash
cd api && mvn test
cd app && npx vitest run
```
