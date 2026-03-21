# Contract: POST /api/auth/register

**Statut**: Route publique (pas de JWT requis)

## Request

```json
{
  "email": "user@example.com",
  "password": "secret123",
  "name": "Kelly",
  "currency": "XOF",
  "timezone": "Africa/Lome"
}
```

| Champ | Type | Obligatoire | Contraintes |
|-------|------|-------------|-------------|
| email | string | oui | Format email valide, unique |
| password | string | oui | Min 6 caracteres |
| name | string | non | Max 100 caracteres |
| currency | string | non | Valeur de l'enum Currency: EUR, XOF, USD, GBP, CHF, CAD, MAD. Defaut: EUR |
| timezone | string | non | Identifiant IANA valide (ex: "Europe/Paris", "Africa/Lome"). Defaut: "Europe/Paris" |

## Response 200

```json
{
  "token": "eyJhbG...",
  "refreshToken": "abc123...",
  "email": "user@example.com",
  "name": "Kelly"
}
```

Pas de changement sur la response. Les champs currency/timezone ne sont pas retournes (ils sont persistes dans Account et UserPreference, consultables via GET /api/accounts et GET /api/users/me/preferences).

## Response 400

```json
{
  "message": "Email deja utilise"
}
```

Ou si currency invalide (Jackson deserialisation failure) :

```json
{
  "message": "Invalid value 'BTC' for field 'currency'"
}
```

## Response 400 (timezone invalide)

Pas d'erreur — le serveur utilise silencieusement le fallback "Europe/Paris". Le timezone n'est pas choisi par l'utilisateur, il est detecte automatiquement.

## Retrocompatibilite

Les champs `currency` et `timezone` sont optionnels. Un payload existant `{ email, password, name }` continue de fonctionner avec les defauts EUR / Europe/Paris.
