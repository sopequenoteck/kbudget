# Quickstart — KKS-230 Autocomplete libellé

**Date** : 2026-04-13
**Feature** : Autocomplete sur le champ libellé de saisie des transactions
**Branche** : `feature/KKS-230-autocomplete-libelle-transactions`

Guide de démarrage rapide pour développer et valider manuellement la feature.

## Pré-requis

- Java 21, Maven, Node 20+, Angular CLI, Flutter SDK à jour
- PostgreSQL local lancé (profil `dev`)
- Base seedée (`R__dev_seed` fournit un user dev + des transactions)

## 1. Checkout branche

```bash
git checkout -b feature/KKS-230-autocomplete-libelle-transactions
```

## 2. Backend — lancer et vérifier

```bash
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

Vérifier Flyway : la migration `V27__enable_unaccent_extension.sql` doit s'appliquer sans erreur au démarrage.

Vérifier l'extension :
```sql
SELECT extname FROM pg_extension WHERE extname = 'unaccent';
```
→ doit retourner 1 ligne.

## 3. Tester l'endpoint manuellement

**Authentification** — récupérer un JWT :
```bash
curl -s -X POST http://localhost:8080/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"dev@kksdev.fr","password":"dev"}' | jq -r .accessToken
```

**Appel endpoint** :
```bash
TOKEN="<collé depuis la commande précédente>"

# Tous les libellés (tri par fréquence)
curl -s "http://localhost:8080/api/transactions/libelles" \
  -H "Authorization: Bearer $TOKEN" | jq

# Filtre q (contains, case-insensitive, accent-insensible)
curl -s "http://localhost:8080/api/transactions/libelles?q=car&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq

# Accent-insensible
curl -s "http://localhost:8080/api/transactions/libelles?q=cafe" \
  -H "Authorization: Bearer $TOKEN" | jq
# → doit matcher "Café du coin", "Café Starbucks", etc.

# 401 attendu sans token
curl -i "http://localhost:8080/api/transactions/libelles"
```

**Swagger UI** : http://localhost:8080/api/swagger-ui.html → section `Transactions` → `GET /transactions/libelles` doit être documenté avec les paramètres `q` et `limit`.

## 4. Tests backend

```bash
cd api && mvn test -Dtest=TransactionRepositoryTest
cd api && mvn test -Dtest=TransactionServiceTest
cd api && mvn test -Dtest=TransactionControllerTest
```

**Points clés à vérifier** :
- Tri fréquence décroissante puis date décroissante en cas d'égalité
- Filtre `q` `contains` case-insensitive ET accent-insensible
- Clamp `limit` ∈ [1, 50]
- Isolation cross-user stricte (SC-004)
- 401 sans JWT

## 5. Frontend Angular

```bash
cd app && ng serve
```

1. Ouvrir http://localhost:4200
2. Se connecter avec le user dev
3. Aller dans l'écran transactions → cliquer sur le bouton flottant (+)
4. Cliquer dans le champ **libellé**
5. Taper 1 caractère → aucune suggestion (FR-015)
6. Taper 2 caractères → liste apparaît (max 5 résultats, FR-016)
7. Naviguer avec ↑↓, valider avec Enter → champ rempli
8. Rouvrir, taper un libellé **inédit** → valider le formulaire → transaction créée (FR-009)
9. Taper un accent : "cafe" doit matcher "Café" (FR-012)
10. Vérifier ARIA : inspecter le DOM, `role="combobox"` et `aria-expanded` présents (NFR-005)
11. Mobile : tester en vue responsive (< 768px) — au pouce, lisible (NFR-002)

```bash
cd app && ng test --watch=false
```

## 6. Frontend Flutter

```bash
cd flutter && flutter run
```

1. Se connecter avec le user dev
2. Naviguer vers l'écran transactions → bouton (+)
3. Champ libellé → taper 2 caractères → suggestions (max 5)
4. Sélectionner une suggestion → champ rempli
5. Saisir un libellé inédit → validation OK
6. Vérifier que le mode `dataModeProvider` = local fonctionne aussi (suggestions Drift avec normalisation Dart)

```bash
cd flutter && flutter test test/src/features/transactions/
```

## 7. Isolation cross-user (critique — SC-004)

1. Créer un second user via `POST /api/auth/register`
2. Se connecter avec ce user
3. Appeler `GET /api/transactions/libelles` → doit retourner uniquement ses libellés
4. Vérifier qu'aucun libellé du user dev n'apparaît

## 8. Performance (NFR-001)

Sur un seed de 10 000 transactions pour un user (à générer ponctuellement via script SQL ou test de perf) :

```bash
time curl -s "http://localhost:8080/api/transactions/libelles?q=mar" \
  -H "Authorization: Bearer $TOKEN" > /dev/null
```

Objectif : < 100ms. Si dépassé → appliquer plan de contingence index documenté dans `research.md` R4.

## 9. Checks qualité avant commit

```bash
cd api && mvn test
cd app && ng lint && ng test --watch=false
cd flutter && flutter analyze && flutter test
```

## 10. Documentation à mettre à jour avant PR

- [ ] `docs/api-examples.md` — exemple requête/réponse `GET /transactions/libelles`
- [ ] `docs/dette-technique.md` — note migration future `Merchant`
- [ ] `DESIGN.md` — documenter pattern autocomplete si absent

## Références

- Spec : [`spec.md`](spec.md)
- Research : [`research.md`](research.md)
- Plan : [`plan.md`](plan.md)
- Data model : [`data-model.md`](data-model.md)
- Linear : https://linear.app/kksdev/issue/KKS-230
