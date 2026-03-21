# Quickstart: 100-register-currency-timezone

## Pour tester rapidement

### Backend

```bash
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

Tester avec curl :

```bash
# Inscription avec devise XOF et timezone Africa/Lome
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test","currency":"XOF","timezone":"Africa/Lome"}'

# Verifier le compte cree
curl http://localhost:8080/api/accounts \
  -H "Authorization: Bearer <token>"
# → Le Compte Principal doit avoir currency: "XOF"

# Verifier les preferences
curl http://localhost:8080/api/users/me/preferences \
  -H "Authorization: Bearer <token>"
# → currencies: ["XOF"], timezone: "Africa/Lome"
```

### Retrocompatibilite

```bash
# Inscription sans les nouveaux champs (ancien client)
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"old@example.com","password":"test123","name":"Old"}'
# → Doit fonctionner, compte en EUR, timezone Europe/Paris
```

### Frontend Angular

```bash
cd app && ng serve
# Naviguer vers /register, verifier le selecteur de devise
```

### Flutter

```bash
cd flutter && flutter run
# Naviguer vers l'ecran d'inscription, verifier le selecteur de devise
```

## Tests

```bash
cd api && mvn test -Dtest=AuthServiceTest
cd api && mvn test -Dtest=AuthControllerTest
cd api && mvn test -Dtest=AccountServiceTest
```
