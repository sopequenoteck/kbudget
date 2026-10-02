# Budget API — Exemples de requetes

Exemples de payloads (request/response) pour chaque endpoint. Toutes les routes (sauf auth) necessitent un header `Authorization: Bearer <token>`.

## Versionnement des chemins

Les endpoints metier sont servis sous `/api/v1` (KKS-313). Une seule version est
servie a la fois : le projet ne fera jamais coexister `/v1` et `/v2` sur une meme
instance. Le prefixe existe pour que les clients puissent detecter une
incompatibilite, pas pour maintenir deux contrats en parallele.

Ne sont **pas** versionnes, et gardent leur chemin sous `/api` :

| Chemin | Raison |
|--------|--------|
| `/api/actuator/health` | Endpoint Spring Boot, hors du contrat applicatif |
| `/api/bank-logos/*.svg` | Ressources statiques |
| `/api/ws` | Handshake WebSocket |
| `/api/v3/api-docs`, `/api/swagger-ui.html` | Documentation OpenAPI (profil `dev`, cf. KKS-311) |

## Decouverte du serveur `GET /api/meta` (public, non versionne)

Permet a un client de verifier qu'il peut fonctionner avec ce serveur avant
d'aller plus loin (KKS-314). **Public et jamais versionne** : c'est lui qui sert
a detecter les cassures, il ne doit donc jamais casser. Aucun champ ne sera
retire ni renomme, y compris lors d'un changement de version majeure.

Response :

```json
{
  "serverVersion": "6.1.0",
  "apiVersion": "v1",
  "minClientVersion": "6.0.0",
  "capabilities": ["SUBSCRIPTIONS", "DEBTS", "BUDGETS"]
}
```

| Champ | Signification |
|-------|---------------|
| `serverVersion` | Version du serveur, derivee du build Maven |
| `apiVersion` | Version d'API servie, sans le slash |
| `minClientVersion` | Version de client la plus ancienne acceptee |
| `capabilities` | Fonctionnalites connues du serveur, a croiser avec les preferences utilisateur |

Les clients l'appellent au demarrage et se placent dans l'un de ces etats :

| Situation | Comportement attendu |
|-----------|----------------------|
| Reponse 200, versions compatibles | Fonctionnement normal |
| `clientVersion` < `minClientVersion` | Inviter a mettre l'application a jour |
| `serverVersion` < minimum exige par le client | Inviter a mettre le serveur a jour |
| **404** | Serveur anterieur a KKS-314, donc trop ancien |
| **Aucune reponse** (timeout, DNS, connexion refusee) | **Hors ligne — jamais une incompatibilite.** Le cache prend le relais |

La derniere ligne est la distinction a ne pas perdre : confondre un serveur
injoignable avec un serveur incompatible afficherait « mettez votre serveur a
jour » a un utilisateur simplement coupe du reseau.

## Authentification

### Inscription publique

**Route supprimee** depuis KKS-232 (conformite constitution principe VII). L'onboarding se fait via invitation admin — voir `POST /api/v1/auth/accept-invite` ci-dessous.

### Valider un token d'invitation `GET /api/v1/auth/invitations/{token}` (public)

Request : aucun body. Exemple : `GET /api/v1/auth/invitations/8b3f7c2a-...`

Response `200` :

```json
{
  "email": "nouveau@example.com"
}
```

Response `404` : token invalide, expire, utilise ou revoque (indifferencie).

### Accepter une invitation `POST /api/v1/auth/accept-invite` (public)

Request :

```json
{
  "token": "8b3f7c2a-4d5e-...",
  "password": "motDePasse12",
  "displayName": "Kelly",
  "currency": "XOF",
  "timezone": "Africa/Lome",
  "defaultAccountName": "Main account"
}
```

> `defaultAccountName` (optionnel, 50 caracteres au plus, KKS-396) : nom du
> compte cree pour le nouvel utilisateur, fourni par le client dans sa langue.
> Absent, vide ou blanc : `Main account`.

> `email` n'est **pas** dans le body — l'email vient de l'invitation (verrouille cote serveur).

> `password` doit faire **au moins 12 caracteres** (KKS-351), comme sur
> `/auth/first-login-reset` et `/user/password`. Ce parcours en exigeait 8
> auparavant : un client plus ancien qui valide 8 caracteres recevra une
> `400 VALIDATION_ERROR`. Source de verite : `PasswordPolicy` cote API, dont
> les clients derivent leur propre constante.

Response `201` :

```json
{
  "token": "eyJhbGciOi...",
  "refreshToken": "a1b2c3d4e5f6...",
  "email": "nouveau@example.com",
  "name": "Kelly",
  "mustResetCredentials": false
}
```

Response `404` : token invalide/expire/utilise/revoque.

### Connexion `POST /api/v1/auth/login`

Request :

```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```

Response `200` :

```json
{
  "token": "eyJhbGciOi...",
  "refreshToken": "a1b2c3d4e5f6...",
  "email": "user@example.com",
  "name": "Kelly",
  "mustResetCredentials": false
}
```

> Le champ `mustResetCredentials` est `true` uniquement pour le compte admin bootstrappé (KKS-233) tant qu'il n'a pas complete son premier reset. Dans ce cas le JWT emis porte un claim `mustResetCredentials` et le filtre `PasswordResetRequiredFilter` bloque tous les endpoints sauf `POST /api/v1/auth/first-login-reset` et `POST /api/v1/auth/logout` avec `403 PASSWORD_RESET_REQUIRED`.

### Premier reset des credentials `POST /api/v1/auth/first-login-reset` (KKS-233)

Endpoint utilise uniquement lors du premier demarrage d'une instance vierge, pour permettre a l'admin seed (cree par le `BootstrapSeedRunner` avec un mot de passe aleatoire affiche dans les logs) de definir ses credentials definitifs.

Request (Authorization: Bearer avec JWT portant le claim `mustResetCredentials: true`) :

```json
{
  "email": "kelly@exemple.com",
  "password": "NouveauMotDePasseFort123",
  "displayName": "Kelly"
}
```

Response `200` — nouveau JWT sans le claim, flag `password_reset_required` remis a `false` en DB :

```json
{
  "token": "eyJhbGciOi...",
  "refreshToken": "a1b2c3d4e5f6...",
  "email": "kelly@exemple.com",
  "name": "Kelly",
  "mustResetCredentials": false
}
```

Response `400 PASSWORD_UNCHANGED` : le nouveau mot de passe est identique a celui actuellement en base.

Response `403 PASSWORD_RESET_NOT_REQUIRED` : le user authentifie a deja `password_reset_required = false` (reset deja effectue ou user ordinaire). Neutralise egalement les anciens JWT encore porteurs du claim apres que le reset ait ete fait par une autre session.

Response `409 EMAIL_ALREADY_EXISTS` : l'email cible est deja utilise par un autre user.

### Renouvellement `POST /api/v1/auth/refresh`

Request :

```json
{
  "refreshToken": "a1b2c3d4e5f6..."
}
```

Response `200` :

```json
{
  "token": "eyJhbGciOi...(nouveau)...",
  "refreshToken": "f6e5d4c3b2a1...(nouveau)...",
  "email": "user@example.com",
  "name": "Kelly"
}
```

### Deconnexion `POST /api/v1/auth/logout`

Request :

```json
{
  "refreshToken": "a1b2c3d4e5f6..."
}
```

Response `200` : (corps vide)

## Administration

> Endpoints proteges par `AdminAuthorizationFilter`. Requiert un JWT dont l'email figure dans `ADMIN_EMAILS` (env var). Sinon 403 Forbidden.

### Creer une invitation `POST /api/v1/admin/invitations`

Request :

```json
{
  "email": "nouveau@example.com"
}
```

Response `201` :

```json
{
  "token": "8b3f7c2a-4d5e-...",
  "expiresAt": "2026-04-26T14:30:00Z"
}
```

Le front compose le lien : `${origin}/auth/accept-invite/${token}` (TTL 7 jours). L'admin transmet le lien hors bande (Signal, SMS).

### Lister les invitations `GET /api/v1/admin/invitations`

Response `200` : tri `createdAt DESC`, statut derive. Le champ `token` est expose uniquement pour les invitations `ACTIVE` (null pour EXPIRED/USED/REVOKED).

```json
[
  {
    "id": 42,
    "email": "new@example.com",
    "invitedByEmail": "admin@example.com",
    "status": "ACTIVE",
    "token": "8b3f7c2a-4d5e-...",
    "createdAt": "2026-04-19T12:00:00Z",
    "expiresAt": "2026-04-26T12:00:00Z",
    "usedAt": null,
    "revokedAt": null
  }
]
```

### Revoquer une invitation `DELETE /api/v1/admin/invitations/{id}`

Response `204` No Content. Positionne `revokedAt = now`. Le `GET /api/v1/auth/invitations/{token}` retourne ensuite 404.

### Lister les users `GET /api/v1/admin/users`

Response `200` :

```json
[
  {
    "id": "9fc3-...-uuid",
    "email": "user@example.com",
    "displayName": "Alice",
    "createdAt": "2026-02-01T10:30:00",
    "disabledAt": null,
    "isAdmin": false
  }
]
```

### Desactiver un user `PATCH /api/v1/admin/users/{id}/disable`

Response `204` No Content. Positionne `disabledAt = now`. Le user ne peut plus s'authentifier (401 sur requetes authentifiees via `JwtFilter`).

Erreur `409` si l'user cible est le dernier admin actif :

```json
{
  "error": "LAST_ADMIN_CANNOT_BE_DISABLED",
  "message": "Impossible de desactiver le dernier admin actif."
}
```

### Reactiver un user `PATCH /api/v1/admin/users/{id}/enable`

Response `204` No Content. Remet `disabledAt = null`. Le user peut a nouveau se connecter.

## Transactions

### Creer `POST /api/v1/transactions`

Request :

```json
{
  "montant": 42.50,
  "libelle": "Courses Carrefour",
  "type": "DEPENSE",
  "date": "2026-02-07",
  "categoryId": "c1d2e3f4-a5b6-7890-cdef-123456789abc",
  "note": null,
  "accountId": "f1a2b3c4-d5e6-7890-abcd-ef1234567890"
}
```

Response `200` :

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "montant": 42.50,
  "libelle": "Courses Carrefour",
  "type": "DEPENSE",
  "date": "2026-02-07",
  "category": {
    "id": "c1d2e3f4-a5b6-7890-cdef-123456789abc",
    "nom": "Alimentation",
    "icone": "🛒",
    "couleur": "#4CAF50",
    "isSystem": false,
    "systemKey": null
  },
  "note": null,
  "account": {
    "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
    "nom": "Compte Principal",
    "icone": "🏦",
    "couleur": "#3b82f6"
  },
  "transferId": null
}
```

### Lister `GET /api/v1/transactions?month=2&year=2026`

Parametres optionnels : `month` et `year` pour filtrer par mois.

Response `200` :

```json
[
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "montant": 42.50,
    "libelle": "Courses Carrefour",
    "type": "DEPENSE",
    "date": "2026-02-07",
    "category": { "id": "uuid", "nom": "Alimentation", "icone": "🛒", "couleur": "#4CAF50", "isSystem": false, "systemKey": null },
    "note": null,
    "account": { "id": "uuid", "nom": "Compte Principal", "icone": "🏦", "couleur": "#3b82f6" },
    "transferId": null,
    "debtId": null
  }
]
```

### Consulter `GET /api/v1/transactions/{id}`

Response `200` : meme format qu'un element de la liste.

### Modifier `PUT /api/v1/transactions/{id}`

Request : meme format que la creation.

Response `200` : la transaction mise a jour.

### Supprimer `DELETE /api/v1/transactions/{id}`

Response `204` (corps vide).

### Bilan mensuel `GET /api/v1/transactions/summary?month=2&year=2026`

Response `200` :

```json
{
  "month": 2,
  "year": 2026,
  "totalRecettes": 2500.00,
  "totalDepenses": 1200.50,
  "solde": 1299.50
}
```

### Libelles autocomplete `GET /api/v1/transactions/libelles?q=car&limit=20`

Retourne les libelles distincts de l'utilisateur authentifie, tries par frequence decroissante puis par date de derniere utilisation decroissante. Filtre `q` optionnel `contains` case-insensitive et accent-insensible. `limit` optionnel clampe a `[1, 50]` (defaut `20`).

Response `200` :

```json
["Carrefour", "Carrefour Market", "Carte bleue"]
```

Exemples :
- `GET /api/v1/transactions/libelles` → tous les libelles tries par frequence
- `GET /api/v1/transactions/libelles?q=cafe` → "Cafe du coin" (accent-insensible)
- `GET /api/v1/transactions/libelles?q=market&limit=5` → max 5 libelles contenant "market"

Erreur `401` si JWT absent ou invalide.

## Abonnements

### Creer `POST /api/v1/subscriptions`

Request :

```json
{
  "nom": "Netflix",
  "montant": 13.49,
  "frequence": "MENSUEL",
  "dateDebut": "2026-01-15",
  "actif": true,
  "accountId": "f1a2b3c4-d5e6-7890-abcd-ef1234567890"
}
```

Response `200` :

```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "nom": "Netflix",
  "montant": 13.49,
  "frequence": "MENSUEL",
  "dateDebut": "2026-01-15",
  "actif": true,
  "category": null,
  "account": {
    "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
    "nom": "Compte Principal",
    "icone": "🏦",
    "couleur": "#3b82f6"
  }
}
```

### Modifier `PUT /api/v1/subscriptions/{id}`

Request :

```json
{
  "nom": "Netflix",
  "montant": 15.99,
  "frequence": "MENSUEL",
  "dateDebut": "2026-01-15",
  "actif": true,
  "accountId": "f1a2b3c4-d5e6-7890-abcd-ef1234567890"
}
```

Response `200` :

```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "nom": "Netflix",
  "montant": 15.99,
  "frequence": "MENSUEL",
  "dateDebut": "2026-01-15",
  "actif": true,
  "category": null,
  "account": {
    "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
    "nom": "Compte Principal",
    "icone": "🏦",
    "couleur": "#3b82f6"
  }
}
```

### Lister `GET /api/v1/subscriptions?actif=true`

Response `200` :

```json
[
  {
    "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "nom": "Netflix",
    "montant": 15.99,
    "frequence": "MENSUEL",
    "dateDebut": "2026-01-15",
    "actif": true,
    "category": null,
    "account": {
      "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
      "nom": "Compte Principal",
      "icone": "🏦",
      "couleur": "#3b82f6"
    }
  },
  {
    "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
    "nom": "Spotify",
    "montant": 10.99,
    "frequence": "MENSUEL",
    "dateDebut": "2025-06-01",
    "actif": true,
    "category": null,
    "account": null
  }
]
```

### Consulter `GET /api/v1/subscriptions/{id}`

Response `200` : meme format qu'un element de la liste.

### Supprimer `DELETE /api/v1/subscriptions/{id}`

Response `204` (corps vide).

### Payer `POST /api/v1/subscriptions/{id}/pay`

Response `201` :

```json
{
  "id": "uuid-transaction",
  "montant": 15.99,
  "date": "2026-03-30",
  "subscriptionName": "Netflix",
  "accountName": "Compte Principal"
}
```

**Idempotent (KKS-385)** : si une transaction liee a l'abonnement existe deja dans
la periode courante, `pay` la renvoie telle quelle (meme `id`, sa propre `date`) et
ne cree rien. La periode est celle de la `frequence` qui contient aujourd'hui,
comptee depuis `dateDebut` (un mois a partir du 5, du 5 au 4 inclus). Une
transaction importee d'un releve et rattachee a l'abonnement compte comme un
paiement. Un double clic ne cree donc plus de doublon.

### Historique paiements `GET /api/v1/subscriptions/{id}/payments`

Response `200` :

```json
[
  {
    "id": "uuid-transaction",
    "montant": 15.99,
    "date": "2026-03-01",
    "subscriptionName": "Netflix",
    "accountName": "Compte Principal"
  }
]
```

### Cumul paiements `GET /api/v1/subscriptions/{id}/payments/total`

Response `200` :

```json
{
  "total": 191.88
}
```

## Dettes

### Creer `POST /api/v1/debts`

Request :

```json
{
  "personne": "Thomas",
  "montant": 50.00,
  "sens": "EMPRUNT",
  "date": "2026-02-01",
  "rembourse": false,
  "currency": "EUR",
  "accountId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "includeInBalance": true,
  "reminderDate": "2026-03-01",
  "reminderTime": "09:00"
}
```

Response `200` :

```json
{
  "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
  "personne": "Thomas",
  "montant": 50.00,
  "sens": "EMPRUNT",
  "date": "2026-02-01",
  "dueDate": null,
  "currency": "EUR",
  "rembourse": false,
  "montantRestant": 50.00,
  "category": null,
  "account": { "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890", "nom": "Compte Courant" },
  "includeInBalance": true,
  "reminderDate": "2026-03-01",
  "reminderTime": "09:00"
}
```

### Modifier `PUT /api/v1/debts/{id}`

Request :

```json
{
  "personne": "Thomas",
  "montant": 50.00,
  "sens": "EMPRUNT",
  "date": "2026-02-01",
  "rembourse": true,
  "currency": "EUR",
  "accountId": null,
  "includeInBalance": false,
  "reminderDate": null,
  "reminderTime": null
}
```

Response `200` :

```json
{
  "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
  "personne": "Thomas",
  "montant": 50.00,
  "sens": "EMPRUNT",
  "date": "2026-02-01",
  "dueDate": null,
  "currency": "EUR",
  "rembourse": true,
  "montantRestant": 0.00,
  "category": null,
  "account": null,
  "includeInBalance": false,
  "reminderDate": null,
  "reminderTime": null
}
```

### Lister `GET /api/v1/debts?rembourse=false`

Response `200` :

```json
[
  {
    "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
    "personne": "Thomas",
    "montant": 50.00,
    "sens": "EMPRUNT",
    "date": "2026-02-01",
    "dueDate": null,
    "currency": "EUR",
    "rembourse": false,
    "montantRestant": 30.00,
    "category": null,
    "account": { "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890", "nom": "Compte Courant" },
    "includeInBalance": true,
    "reminderDate": "2026-03-01",
    "reminderTime": "09:00"
  }
]
```

### Rembourser `POST /api/v1/debts/{id}/repay`

Request :

```json
{
  "accountId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "amount": 20.00,
  "libelle": "Repayment - Awa"
}
```

> `libelle` (optionnel, 255 caracteres au plus, KKS-396) : libelle de la
> transaction creee, fourni par le client dans sa langue. Defaut :
> `Repayment - <personne>`.

> `amount` optionnel — si omis, rembourse le montant restant (solde complet).

Response `200` : la dette mise a jour (meme format que ci-dessus, `montantRestant` recalcule, `rembourse: true` si solde).

### Historique paiements `GET /api/v1/debts/{id}/payments`

Response `200` :

```json
[
  {
    "id": "f1a2b3c4-d5e6-7890-abcd-123456789012",
    "amount": 20.00,
    "date": "2026-02-15",
    "accountName": "Compte Courant"
  }
]
```

### Reporter le rappel `POST /api/v1/debts/{id}/snooze`

Request :

```json
{
  "reminderDate": "2026-04-01",
  "reminderTime": "10:00"
}
```

Response `200` : la dette mise a jour avec les nouveaux `reminderDate` et `reminderTime`.

### Consulter `GET /api/v1/debts/{id}`

Response `200` : meme format qu'un element de la liste.

### Supprimer `DELETE /api/v1/debts/{id}`

Response `204` (corps vide).

### Solde total `GET /api/v1/accounts/total-balance`

Response `200` :

```json
{
  "balances": [
    { "currency": "EUR", "amount": 3450.00 },
    { "currency": "XOF", "amount": 150000.00 }
  ]
}
```

> Agregation des soldes de tous les comptes actifs + dettes avec `includeInBalance=true`, par devise.

## Comptes

### Creer `POST /api/v1/accounts`

Request :

```json
{
  "nom": "Livret A",
  "type": "EPARGNE",
  "soldeInitial": 1500.00,
  "icone": "🐷",
  "couleur": "#22c55e",
  "actif": true,
  "bankCode": "OTHER"
}
```

Response `201` :

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-000000000001",
  "nom": "Livret A",
  "type": "EPARGNE",
  "soldeInitial": 1500.00,
  "solde": 1500.00,
  "icone": "🐷",
  "couleur": "#22c55e",
  "isDefault": false,
  "actif": true,
  "currency": "EUR",
  "bankCode": "OTHER",
  "bankName": "Autre",
  "bankCountry": null,
  "bankBrandColor": "#6b7280",
  "bankLogoUrl": "/api/bank-logos/other.svg",
  "bankCustomName": null,
  "bankCustomLogo": null
}
```

### Lister `GET /api/v1/accounts`

Response `200` :

```json
[
  {
    "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
    "nom": "Compte Principal",
    "type": "COURANT",
    "soldeInitial": 0.00,
    "solde": 1299.50,
    "icone": "🏦",
    "couleur": "#3b82f6",
    "isDefault": true,
    "actif": true,
    "currency": "EUR",
    "bankCode": "OTHER",
    "bankName": "Autre",
    "bankCountry": null,
    "bankBrandColor": "#6b7280",
    "bankLogoUrl": "/api/bank-logos/other.svg",
    "bankCustomName": null,
    "bankCustomLogo": null,
    "statementAccountSuffix": "1596"
  },
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-000000000001",
    "nom": "Livret A",
    "type": "EPARGNE",
    "soldeInitial": 1500.00,
    "solde": 1500.00,
    "icone": "🐷",
    "couleur": "#22c55e",
    "isDefault": false,
    "actif": true,
    "currency": "EUR",
    "bankCode": "OTHER",
    "bankName": "Autre",
    "bankCountry": null,
    "bankBrandColor": "#6b7280",
    "bankLogoUrl": "/api/bank-logos/other.svg",
    "bankCustomName": null,
    "bankCustomLogo": null,
    "statementAccountSuffix": null
  }
]
```

`statementAccountSuffix` (KKS-384) : 4 derniers chiffres du numero de compte lu dans
le dernier releve importe sur ce compte, pour afficher « …1596 ». `null` tant qu'aucun
releve exploitable n'a ete importe. Le numero complet n'est jamais stocke.

### Virement `POST /api/v1/accounts/transfer`

Request :

```json
{
  "fromAccountId": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
  "toAccountId": "a1b2c3d4-e5f6-7890-abcd-000000000001",
  "montant": 200.00,
  "note": "Epargne mensuelle",
  "libelleDebit": "Transfer to Livret A",
  "libelleCredit": "Transfer from Compte Principal"
}
```

> `libelleDebit` / `libelleCredit` (optionnels, 255 caracteres au plus,
> KKS-396) : libelles des transactions de debit (compte source) et de credit
> (compte destination), fournis par le client dans sa langue. Defauts :
> `Transfer to <compte destination>` / `Transfer from <compte source>`.

Response `201` :

```json
{
  "transferId": "e5f6a7b8-c9d0-1234-efab-345678901234",
  "debitTransaction": {
    "id": "11111111-1111-1111-1111-111111111111",
    "montant": 200.00,
    "libelle": "Transfer to Livret A",
    "type": "DEPENSE",
    "date": "2026-02-15",
    "accountId": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
    "accountNom": "Compte Principal"
  },
  "creditTransaction": {
    "id": "22222222-2222-2222-2222-222222222222",
    "montant": 200.00,
    "libelle": "Transfer from Compte Principal",
    "type": "RECETTE",
    "date": "2026-02-15",
    "accountId": "a1b2c3d4-e5f6-7890-abcd-000000000001",
    "accountNom": "Livret A"
  }
}
```

### Consulter `GET /api/v1/accounts/{id}`

Response `200` : meme format qu'un element de la liste.

### Modifier `PUT /api/v1/accounts/{id}`

Request : meme format que la creation.

Response `200` : le compte mis a jour.

### Supprimer `DELETE /api/v1/accounts/{id}`

Response `204` (corps vide).

### Ajuster le solde `POST /api/v1/accounts/{id}/adjust-balance`

Request :

```json
{
  "newBalance": 1500.00,
  "libelle": "Balance adjustment"
}
```

> `libelle` (optionnel, 255 caracteres au plus, KKS-396) : libelle de la
> transaction d'ajustement, fourni par le client dans sa langue. Defaut :
> `Balance adjustment`.

Response `200` : le compte mis a jour avec le nouveau solde.

### Definir par defaut `PUT /api/v1/accounts/{id}/default`

Response `200` :

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-000000000001",
  "nom": "Livret A",
  "type": "EPARGNE",
  "soldeInitial": 1500.00,
  "solde": 1700.00,
  "icone": "🐷",
  "couleur": "#22c55e",
  "isDefault": true,
  "actif": true,
  "currency": "EUR",
  "bankCode": "OTHER",
  "bankName": "Autre",
  "bankCountry": null,
  "bankBrandColor": "#6b7280",
  "bankLogoUrl": "/api/bank-logos/other.svg",
  "bankCustomName": null,
  "bankCustomLogo": null
}
```

## Categories

### Creer `POST /api/v1/categories`

Request :

```json
{
  "nom": "Alimentation",
  "icone": "🛒",
  "couleur": "#4CAF50"
}
```

Response `200` :

```json
{
  "id": "c1d2e3f4-a5b6-7890-cdef-123456789abc",
  "nom": "Alimentation",
  "icone": "🛒",
  "couleur": "#4CAF50",
  "isSystem": false,
  "systemKey": null
}
```

### Consulter `GET /api/v1/categories/{id}`

Response `200` : meme format qu'un element de la liste.

### Modifier `PUT /api/v1/categories/{id}`

Request : meme format que la creation.

Response `200` : la categorie mise a jour.

### Supprimer `DELETE /api/v1/categories/{id}`

Response `204` (corps vide). Erreur `409` si categorie systeme.

### Lister `GET /api/v1/categories`

Response `200` :

```json
[
  {
    "id": "c1d2e3f4-a5b6-7890-cdef-123456789abc",
    "nom": "Alimentation",
    "icone": "🛒",
    "couleur": "#4CAF50",
    "isSystem": false,
    "systemKey": null
  },
  {
    "id": "d2e3f4a5-b6c7-8901-defa-234567890bcd",
    "nom": "Abonnement",
    "icone": "🔄",
    "couleur": "#6366f1",
    "isSystem": true,
    "systemKey": "SUBSCRIPTION"
  }
]
```

## Taux de conversion

### Lister `GET /api/v1/exchange-rates`

Response `200` :

```json
[
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "baseCurrency": "EUR",
    "targetCurrency": "XOF",
    "rate": 655.957000,
    "updatedAt": "2026-03-06T10:00:00"
  }
]
```

### Creer ou mettre a jour `PUT /api/v1/exchange-rates`

Request (upsert — cree ou met a jour le taux pour la paire) :

```json
{
  "baseCurrency": "EUR",
  "targetCurrency": "XOF",
  "rate": 655.957
}
```

Response `200` :

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "baseCurrency": "EUR",
  "targetCurrency": "XOF",
  "rate": 655.957000,
  "updatedAt": "2026-03-06T10:00:00"
}
```

### Supprimer `DELETE /api/v1/exchange-rates/{baseCurrency}/{targetCurrency}`

Response `204` (corps vide).

## Preferences utilisateur

### Consulter `GET /api/v1/users/me/preferences`

Response `200` (valeurs par defaut) :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "BUDGETS"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS", "BUDGETS"],
  "currencies": ["EUR"]
}
```

### Mettre a jour `PUT /api/v1/users/me/preferences`

Request (desactiver les dettes, navOrder auto-gere) :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "BUDGETS"]
}
```

Response `200` :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "BUDGETS"],
  "navOrder": ["SUBSCRIPTIONS", "BUDGETS"],
  "currencies": ["EUR"]
}
```

Request (reordonner avec navOrder explicite + changer devise principale) :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "BUDGETS"],
  "navOrder": ["BUDGETS", "DEBTS", "SUBSCRIPTIONS"],
  "currencies": ["XOF", "EUR"]
}
```

Response `200` :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "BUDGETS"],
  "navOrder": ["BUDGETS", "DEBTS", "SUBSCRIPTIONS"],
  "currencies": ["XOF", "EUR"]
}
```

Request (choisir la langue de l'interface, code BCP 47 restreint) :

```json
{
  "language": "fr"
}
```

Un champ absent ou `null` laisse la preference inchangee : `PUT` ne sait donc
pas revenir au choix automatique. C'est le role de l'endpoint suivant.

### Revenir a la langue automatique `DELETE /api/v1/users/me/preferences/language`

Remet `language` a `null` : le client suit alors la langue du navigateur
(KKS-380). Aucun corps de requete.

Response `204` (sans corps). Un `GET` suivant renvoie `"language": null`.

## Budgets

### Creer `POST /api/v1/budgets`

Request :

```json
{
  "categoryId": "uuid-category",
  "montant": 400.00,
  "frequence": "MENSUEL",
  "currency": "EUR",
  "seuilNotification": 80
}
```

Response `200` :

```json
{
  "id": "uuid-budget",
  "montant": 400.00,
  "currency": "EUR",
  "frequence": "MENSUEL",
  "seuilNotification": 80,
  "actif": true,
  "category": {
    "id": "uuid-category",
    "nom": "Alimentation",
    "icone": "🛒",
    "couleur": "#f59e0b",
    "isSystem": false,
    "systemKey": null
  },
  "spent": 0.00,
  "updatedAt": "2026-03-08T10:00:00"
}
```

### Lister `GET /api/v1/budgets`

Response `200` :

```json
[
  {
    "id": "uuid-budget",
    "montant": 400.00,
    "currency": "EUR",
    "frequence": "MENSUEL",
    "seuilNotification": 80,
    "actif": true,
    "category": { "id": "uuid", "nom": "Alimentation", "icone": "🛒", "couleur": "#f59e0b", "isSystem": false, "systemKey": null },
    "spent": 320.50,
    "updatedAt": "2026-03-08T10:00:00"
  }
]
```

### Consulter `GET /api/v1/budgets/{id}`

Response `200` : meme format qu'un element de la liste.

### Modifier `PUT /api/v1/budgets/{id}`

Request : meme format que la creation (tous les champs optionnels sauf `categoryId`).

### Supprimer `DELETE /api/v1/budgets/{id}`

Response `204` (pas de corps).

### Vue mensuelle `GET /api/v1/budgets/overview`

Response `200` :

```json
{
  "month": "2026-03",
  "totalBudget": 1500.00,
  "totalSpent": 980.50,
  "percentage": 65.37,
  "currency": "EUR",
  "items": [
    {
      "budgetId": "uuid-budget",
      "categoryId": "uuid-category",
      "categoryNom": "Alimentation",
      "categorySystemKey": null,
      "categoryIcone": "🛒",
      "categoryCouleur": "#f59e0b",
      "montantBudget": 400.00,
      "montantBudgetNormalise": 400.00,
      "currency": "EUR",
      "montantDepense": 320.50,
      "percentage": 80.13,
      "frequence": "MENSUEL"
    }
  ],
  "unbudgetedItems": [
    {
      "categoryId": "uuid-category",
      "categoryNom": "Courses",
      "categorySystemKey": null,
      "categoryIcone": "🛍️",
      "categoryCouleur": "#6b7280",
      "montantDepense": 45.00,
      "currency": "EUR"
    }
  ],
  "unbudgetedTotal": 45.00
}
```

### Historique `GET /api/v1/budgets/history?month=2026-02`

Response `200` :

```json
{
  "month": "2026-02",
  "totalBudget": 1500.00,
  "totalSpent": 1200.00,
  "percentage": 80.00,
  "currency": "EUR",
  "items": [
    {
      "categoryId": "uuid-category",
      "categoryNom": "Alimentation",
      "categorySystemKey": null,
      "categoryIcone": "🛒",
      "categoryCouleur": "#f59e0b",
      "montantBudget": 400.00,
      "currency": "EUR",
      "tauxChange": null,
      "montantDepense": 380.00,
      "percentage": 95.00,
      "createdAt": "2026-03-01T00:00:00"
    }
  ],
  "unbudgetedItems": [
    {
      "categoryId": "uuid-category",
      "categoryNom": "Courses",
      "categorySystemKey": null,
      "categoryIcone": "🛍️",
      "categoryCouleur": "#6b7280",
      "montantDepense": 52.30,
      "currency": "EUR"
    }
  ],
  "unbudgetedTotal": 52.30
}
```

## Banques

### Lister `GET /api/v1/banks`

Endpoint public (pas de token requis). Retourne les 29 banques supportees, triees par pays (FR, TG, International) puis par nom.

Response `200` :

```json
[
  {
    "code": "BIA",
    "name": "BIA",
    "country": "FR",
    "brandColor": "#003366",
    "logoUrl": "/api/bank-logos/bia.svg"
  },
  {
    "code": "BNP",
    "name": "BNP Paribas",
    "country": "FR",
    "brandColor": "#00915a",
    "logoUrl": "/api/bank-logos/bnp.svg"
  },
  {
    "code": "ECOBANK",
    "name": "Ecobank",
    "country": "TG",
    "brandColor": "#0033a0",
    "logoUrl": "/api/bank-logos/ecobank.svg"
  },
  {
    "code": "OTHER",
    "name": "Autre",
    "country": null,
    "brandColor": "#6b7280",
    "logoUrl": "/api/bank-logos/other.svg"
  }
]
```

> 29 entrees au total. Extraits ci-dessus pour illustration.

## Transactions recurrentes

### Creer `POST /api/v1/transactions/recurring`

Request :

```json
{
  "montant": 950.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "categoryId": "uuid-category",
  "accountId": "uuid-account",
  "note": null
}
```

Response `201` :

```json
{
  "id": "uuid",
  "montant": 950.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "recurringActive": true,
  "category": { "id": "uuid", "nom": "Logement", "icone": "🏠", "couleur": "#ef4444", "isSystem": false, "systemKey": null },
  "account": { "id": "uuid", "nom": "Compte Principal", "icone": "🏦", "couleur": "#3b82f6" }
}
```

### Lister les actives `GET /api/v1/transactions/recurring`

Response `200` : liste de `RecurringTransactionResponse`.

### Valider une occurrence `POST /api/v1/transactions/recurring/{id}/validate`

Cree la transaction pour l'occurrence courante et avance `nextOccurrence`.

Response `201` : `TransactionResponse` (la transaction creee).

### Passer une occurrence `PATCH /api/v1/transactions/recurring/{id}/skip`

Avance `nextOccurrence` sans creer de transaction.

Response `200` : `RecurringTransactionResponse` mise a jour.

### Desactiver `PATCH /api/v1/transactions/recurring/{id}/deactivate`

Response `200` : `RecurringTransactionResponse` avec `recurringActive: false`.

## Notifications

### Lister `GET /api/v1/notifications?page=0&size=20&unread=true`

Parametres optionnels : `page` (defaut 0), `size` (defaut 20, max 100), `unread` (filtre optionnel).

Response `200` :

```json
{
  "content": [
    {
      "id": "uuid",
      "type": "SUBSCRIPTION_DUE",
      "title": "Subscription Netflix",
      "message": "Netflix is due tomorrow",
      "entityType": "SUBSCRIPTION",
      "entityId": "uuid-subscription",
      "read": false,
      "readAt": null,
      "createdAt": "2026-03-27T08:00:00",
      "params": { "name": "Netflix" }
    }
  ],
  "number": 0,
  "size": 20,
  "totalElements": 5,
  "totalPages": 1
}
```

> `params` (KKS-397) : parametres de la notification, a partir desquels le
> client construit titre et message dans sa langue. Valeurs en chaines :
> montants decimaux exacts, dates ISO, pourcentage entier, devise en code ISO.
>
> | Type | Cles |
> |------|------|
> | `SUBSCRIPTION_DUE` | `name` |
> | `DEBT_DUE` | `person` |
> | `DEBT_REMINDER` | `person`, `amount`, `currency` |
> | `BUDGET_THRESHOLD`, `BUDGET_EXCEEDED` | `category`, `categorySystemKey` (categorie systeme seulement), `percentage` |
> | `RECURRING_TRANSACTION_DUE` | `label`, `amount`, `currency` (absente sans compte), `dueDate` |
>
> `null` pour une notification anterieure : le client affiche alors `title` /
> `message`, desormais ecrits en anglais. Le meme objet est pousse par
> WebSocket.

### Compteur non lues `GET /api/v1/notifications/unread-count`

Response `200` :

```json
{
  "count": 3
}
```

### Marquer comme lue `PUT /api/v1/notifications/{id}/read`

Response `200` : `NotificationResponse` avec `read: true` et `readAt` renseigne.

### Tout marquer comme lu `PUT /api/v1/notifications/read-all`

Response `204` (corps vide).

### Supprimer `DELETE /api/v1/notifications/{id}`

Response `204` (corps vide).

### Tout supprimer `DELETE /api/v1/notifications`

Response `204` (corps vide).

## Profil utilisateur

### Consulter `GET /api/v1/users/me`

Response `200` :

```json
{
  "name": "Kelly",
  "email": "user@example.com",
  "isAdmin": true
}
```

Le flag `isAdmin` est derive cote serveur via `AdminEmailResolver.isAdminEmail(user.email)`. Utilise par le frontend pour afficher conditionnellement la section `Settings > Utilisateurs`.

## Mon compte (KKS-235)

> Endpoints proteges par JWT. Tous les endpoints operent sur le user authentifie (pas de path parameter `id`). Voir aussi [`api-errors.md`](api-errors.md) pour les codes d'erreur dedies (`INVALID_IMAGE_FORMAT`, `FILE_TOO_LARGE`, `AVATAR_NOT_FOUND`, `PASSWORD_INCORRECT`, `PASSWORD_UNCHANGED`, `CONFIRMATION_REQUIRED`, `LAST_ADMIN_DELETION_FORBIDDEN`, `INVALID_EXPORT_FORMAT`).

### Modifier le nom `PUT /api/v1/users/me`

Request (`UpdateProfileRequest`, header `Authorization: Bearer <token>`) :

```json
{
  "name": "Kelly K."
}
```

> Seul le champ `name` est modifiable. L'email est en lecture seule cote backend (changement via flow dedie hors KKS-235).

Response `200` :

```json
{
  "name": "Kelly K.",
  "email": "user@example.com",
  "isAdmin": true
}
```

Erreurs : `400` (validation Bean : `name` blank ou `> 100` chars).

### Uploader un avatar `POST /api/v1/users/me/avatar`

Request (multipart/form-data, header `Authorization: Bearer <token>`) :

| Champ | Type | Description |
|-------|------|-------------|
| `file` | File | Image JPG ou PNG (max 2 Mo) |

Response `200` (`AvatarMetadataResponse`) :

```json
{
  "url": "/api/v1/users/me/avatar",
  "etag": "9c1185a5",
  "uploadedAt": "2026-04-27T10:30:00Z"
}
```

Erreurs :
- `400 INVALID_IMAGE_FORMAT` — type MIME non supporte (autre que `image/jpeg` ou `image/png`)
- `413 FILE_TOO_LARGE` — fichier > 2 Mo

### Recuperer l'avatar `GET /api/v1/users/me/avatar`

Headers requis :
- `Authorization: Bearer <token>`
- `If-None-Match: <etag>` (optionnel — pour le cache HTTP)

Response `200` :
- `Content-Type: image/jpeg` ou `image/png`
- `ETag: <sha256-hex>` (calcule sur le binaire stocke)
- Body : binaire de l'image

Response `304 Not Modified` : si le header `If-None-Match` correspond a l'ETag courant. Pas de body.

Response `404 AVATAR_NOT_FOUND` : aucun avatar configure pour ce user.

### Supprimer l'avatar `DELETE /api/v1/users/me/avatar`

Header requis : `Authorization: Bearer <token>`.

Response `204` : avatar supprime cote disque + `users.avatar_path` remis a `null`.

Response `404 AVATAR_NOT_FOUND` : aucun avatar a supprimer.

### Changer de mot de passe `POST /api/v1/users/me/password`

Request (`ChangePasswordRequest`, header `Authorization: Bearer <token>`) :

```json
{
  "currentPassword": "MotDePasseActuel123",
  "newPassword": "NouveauMotDePasseFort456"
}
```

> Le `currentPassword` est verifie via `BCryptPasswordEncoder.matches`. Le `newPassword` doit faire au moins 12 caracteres et etre different de l'actuel. La rotation invalide tous les refresh tokens existants et en emet de nouveaux.

Response `200` (`AuthResponse` — meme format que `/api/v1/auth/login`) :

```json
{
  "token": "eyJhbGciOi...(nouveau)...",
  "refreshToken": "a1b2c3d4...(nouveau)...",
  "email": "user@example.com",
  "name": "Kelly",
  "mustResetCredentials": false
}
```

Erreurs :
- `400` — validation Bean (`newPassword` < 12 chars)
- `400 PASSWORD_UNCHANGED` — le nouveau password est identique a l'actuel
- `401 PASSWORD_INCORRECT` — le `currentPassword` ne correspond pas

### Exporter ses donnees JSON `GET /api/v1/users/me/export?format=json`

Header requis : `Authorization: Bearer <token>`.

Response `200` :
- `Content-Type: application/json; charset=utf-8`
- `Content-Disposition: attachment; filename="k-budget-export-2026-04-27.json"`
- Body (`UserExportResponse`) : backup complet des donnees du user.

```json
{
  "exportedAt": "2026-04-27T10:30:00",
  "user": {
    "email": "user@example.com",
    "name": "Kelly",
    "createdAt": "2026-02-01T10:30:00"
  },
  "preferences": { "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "BUDGETS"], "navOrder": ["..."], "currencies": ["EUR"] },
  "accounts": [ { "id": "uuid", "nom": "Compte Principal", "...": "..." } ],
  "categories": [ { "id": "uuid", "nom": "Alimentation", "...": "..." } ],
  "transactions": [ { "id": "uuid", "montant": 42.50, "...": "..." } ],
  "subscriptions": [ { "id": "uuid", "nom": "Netflix", "...": "..." } ],
  "debts": [ { "id": "uuid", "personne": "Thomas", "...": "..." } ],
  "budgets": [ { "id": "uuid", "montant": 400.00, "...": "..." } ],
  "exchangeRates": [ { "baseCurrency": "EUR", "targetCurrency": "XOF", "rate": 655.957 } ]
}
```

### Exporter ses transactions CSV `GET /api/v1/users/me/export?format=csv`

Header requis : `Authorization: Bearer <token>`.

Response `200` :
- `Content-Type: text/csv; charset=utf-8`
- `Content-Disposition: attachment; filename="k-budget-transactions-2026-04-27.csv"`
- Body : transactions du user uniquement (pas les abonnements/dettes/budgets), prefixees du **BOM UTF-8** (`EF BB BF`) pour ouverture correcte dans Excel.

Colonnes (format stable depuis KKS-396, en-tetes non traduits) :
`date,label,amount,currency,account,category,type`. `type` : `RECETTE`,
`DEPENSE`, `AJUSTEMENT` (codes du JSON). `category` : nom tel que stocke.

Exemple :

```
date,label,amount,currency,account,category,type
2026-04-15,Courses Carrefour,42.50,EUR,Compte Principal,Alimentation,DEPENSE
2026-04-10,Salaire,2500.00,EUR,Compte Principal,,RECETTE
```

Erreurs (sur les deux variantes export) : `400 INVALID_EXPORT_FORMAT` — parametre `format` absent ou autre que `json`/`csv`.

### Supprimer son compte `DELETE /api/v1/users/me`

Soft-delete : le compte est desactive (`disabled_at = now`), les budgets/snapshots/refresh_tokens sont supprimes en cascade en DB. Les transactions/comptes/abonnements/dettes sont conserves (anonymisation differee).

Request (`DeleteAccountRequest`, header `Authorization: Bearer <token>`) :

```json
{
  "password": "MotDePasseActuel123",
  "confirmation": "SUPPRIMER"
}
```

> Le `password` est verifie via BCrypt. Le `confirmation` doit valoir exactement la chaine `SUPPRIMER` (case-sensitive).

Response `204` (corps vide). Tous les refresh tokens du user sont revoques.

Erreurs :
- `400 CONFIRMATION_REQUIRED` — `confirmation` differente de `SUPPRIMER`
- `401 PASSWORD_INCORRECT` — mot de passe incorrect
- `403 LAST_ADMIN_DELETION_FORBIDDEN` — le user est le dernier admin actif

## Devises

### Lister `GET /api/v1/currencies`

Response `200` :

```json
[
  {
    "code": "EUR",
    "symbol": "€",
    "name": "Euro",
    "decimalPlaces": 2
  },
  {
    "code": "XOF",
    "symbol": "CFA",
    "name": "Franc CFA",
    "decimalPlaces": 0
  }
]
```

## Valeurs des enums

| Enum | Valeurs |
|------|---------|
| `TransactionType` | `DEPENSE`, `RECETTE` |
| `Frequency` | `HEBDOMADAIRE`, `MENSUEL`, `ANNUEL` |
| `DebtType` | `EMPRUNT`, `PRET` |
| `TokenStatus` | `ACTIVE`, `CONSUMED`, `REVOKED` |
| `AccountType` | `COURANT`, `EPARGNE`, `ESPECES` |
| `Feature` | `SUBSCRIPTIONS`, `DEBTS`, `BUDGETS` |
| `Currency` | `EUR`, `XOF`, `USD`, `GBP`, `CHF`, `CAD`, `MAD` |


## Import CSV

### Reconnaitre un fichier `POST /api/v1/imports/detect` (KKS-440)

Identifie le profil d'import d'un fichier, sans rien creer : ni brouillon, ni
profil. A appeler avant le choix du compte pour reconnaitre le format.

Request (multipart/form-data) :

| Champ | Type | Description |
|-------|------|-------------|
| `file` | File | Fichier CSV (max 5 Mo, memes limites que `/upload`) |

Response `200`, fichier reconnu :

```json
{
  "recognized": true,
  "profileSource": "REGISTRY",
  "bankCode": "SG",
  "profileName": "Société Générale",
  "accountSuffix": "1596",
  "suggestedAccountId": "36eace5f-..."
}
```

Response `200`, fichier non reconnu :

```json
{
  "recognized": false,
  "profileSource": null,
  "bankCode": null,
  "profileName": null,
  "accountSuffix": null,
  "suggestedAccountId": null
}
```

- `accountSuffix` (KKS-384) : 4 derniers chiffres du numero de compte lu dans l'en-tete
  bancaire du releve ; `null` quand le profil n'a pas d'en-tete (profil personnalise)
  ou que le numero est illisible ou a moins de 4 chiffres.
- `suggestedAccountId` (KKS-384) : l'unique compte **actif de l'utilisateur
  authentifie** deja importe avec le meme profil et le meme suffixe ; `null` s'il y
  en a zero ou plusieurs (ambigu : pas de preselection). Le choix du compte reste
  explicite au premier import et modifiable a chaque import ; a la confirmation, le
  compte choisi recoit l'association (profil + suffixe) et remplace la precedente.
  Cle de profil : `REGISTRY:<bankCode>` (profil embarque) ou `CUSTOM:<id>` (profil
  personnalise). Le numero complet n'est jamais stocke, ni en clair ni en empreinte.

- `profileSource` : `REGISTRY` (profil embarque) ou `CUSTOM` (profil personnalise
  de l'utilisateur authentifie). `bankCode` vaut `null` pour `CUSTOM`.
- Le fichier est reconnu quand toutes les colonnes de la signature du profil
  figurent sur la ligne d'en-tete de colonnes (apres `skipHeaderLines`, lue avec
  l'encodage et le separateur du profil ; espaces de bord ignores, casse
  respectee, comme a la lecture des lignes). Un profil personnalise a pour
  signature ses colonnes mappees. Profils
  embarques d'abord, puis profils personnalises de l'utilisateur seulement
  (le plus recemment modifie si plusieurs correspondent).
- `/imports/upload` suit le meme ordre, puis se replie sur le profil embarque
  du `bankCode` du compte ; `422` si rien ne correspond. Le brouillon porte alors
  `profileSource` = `CUSTOM` quand un profil personnalise a ete reconnu.

Erreur `400` : fichier absent, vide, trop gros ou qui n'est pas un CSV. Erreur `401` sans jeton.

### Upload CSV `POST /api/v1/imports/upload`

Request (multipart/form-data) :

| Champ | Type | Description |
|-------|------|-------------|
| `file` | File | Fichier CSV (max 5 Mo) |
| `accountId` | UUID | Compte cible |

Response `201` :

```json
{
  "id": "91afe691-...",
  "accountId": "36eace5f-...",
  "accountName": "Compte Principal",
  "status": "PENDING",
  "fileName": "releve_mars.csv",
  "totalLines": 160,
  "readyCount": 151,
  "reviewCount": 0,
  "duplicateCount": 2,
  "skippedCount": 7,
  "alreadyImportedCount": 7,
  "matchedCount": 3,
  "profileName": "Societe Generale",
  "profileSource": "REGISTRY",
  "createdAt": "2026-03-20T14:30:00",
  "expiresAt": "2026-03-27T14:30:00",
  "statementAccountSuffix": "1596",
  "statementBalance": 1842.37,
  "statementBalanceDate": "2026-10-01",
  "projectedBalance": 895.70,
  "proposedOpeningBalance": 946.67,
  "lines": [
    {
      "id": "uuid",
      "lineNumber": 1,
      "rawLabel": "CARTE X3855 16/03 UEP*SUPER U 101607535098170IOPD",
      "cleanLabel": "SUPER U",
      "amount": 17.32,
      "date": "2026-03-16",
      "transactionType": "DEPENSE",
      "status": "READY",
      "statusMessage": null,
      "categoryId": null,
      "categoryName": null,
      "categorySystemKey": null,
      "duplicateTransactionId": null,
      "suggestRule": false,
      "skipReason": null,
      "categorySource": null,
      "purchaseDate": "2026-03-14",
      "matchedTransactionId": "uuid-transaction-saisie",
      "matchCandidateIds": [],
      "subscriptionId": null,
      "matchedTransaction": {
        "id": "uuid-transaction-saisie",
        "date": "2026-03-14",
        "libelle": "Tabac",
        "montant": 17.32,
        "type": "DEPENSE"
      },
      "matchCandidates": []
    },
    {
      "id": "uuid",
      "lineNumber": 2,
      "rawLabel": "FRAIS BANCAIRES TEST",
      "cleanLabel": "FRAIS BANCAIRES TEST",
      "amount": 45.00,
      "date": "2026-03-03",
      "transactionType": "DEPENSE",
      "status": "SKIPPED",
      "statusMessage": null,
      "categoryId": null,
      "categoryName": null,
      "categorySystemKey": null,
      "duplicateTransactionId": "uuid-transaction-existante",
      "suggestRule": false,
      "skipReason": "ALREADY_IMPORTED",
      "categorySource": null,
      "purchaseDate": null,
      "matchedTransactionId": null,
      "matchCandidateIds": [],
      "subscriptionId": null,
      "matchedTransaction": null,
      "matchCandidates": []
    }
  ]
}
```

**Lignes deja importees (KKS-382)** : une ligne d'un releve precedent est ecartee
d'office — `status: "SKIPPED"`, `skipReason: "ALREADY_IMPORTED"`,
`duplicateTransactionId` pointant sur la transaction existante. Elle ne bloque pas
la confirmation et ne peut pas etre reactivee. `alreadyImportedCount` est un
sous-ensemble de `skippedCount`. Une ligne est reconnue :

- par son **empreinte** (date comptable, montant, sens, libelle brut), posee sur
  chaque transaction importee : la reconnaissance survit au renommage ou au
  changement de date de la transaction ;
- a defaut d'empreinte (import anterieur), par date, montant, sens et libelle
  nettoye identique. L'empreinte lui est alors posee a la confirmation.

Deux lignes identiques d'un meme releve sont deux operations : elles ne sont
ecartees que si la base en contient autant. Un libelle seulement proche
(Jaro-Winkler >= 0,85) donne toujours `DUPLICATE`, bloquant.

**Saisies manuelles rapprochees (KKS-385)** : une operation que l'utilisateur a
deja saisie a la main ne doit pas etre comptee deux fois. A l'upload, apres la
reconnaissance des lignes deja importees et avant le doublon probable, chaque
ligne `READY` est rapprochee des transactions du **meme utilisateur et du meme
compte**, sans empreinte (non importees), de meme sens et de meme montant, dans une
fenetre de dates. **Le libelle n'est pas un critere** : celui de l'utilisateur et
celui de la banque n'ont rien en commun. La date de reference de la ligne est la
date d'achat si elle est connue, sinon la date comptable :

| Transaction candidate | Fenetre |
|-----------------------|---------|
| liee a un abonnement | 8 jours de part et d'autre de la date de reference |
| sinon, date d'achat connue (paiement carte) | 2 jours de part et d'autre de la date d'achat |
| sinon (virement, prelevement) | de 5 jours avant a 1 jour apres la date comptable |

- `purchaseDate` : date d'achat lue dans le libelle brut quand le profil la
  declare (`CARTE X1596 21/08`), `null` sinon. `date` reste la date comptable (elle
  porte l'empreinte). A la confirmation, la transaction creee prend `purchaseDate`
  si elle est connue, sinon `date`.
- **Un candidat** : la ligne reste `READY` et porte `matchedTransactionId`. A la
  confirmation, **aucune transaction n'est creee** : la transaction existante est
  conservee telle quelle (date, libelle, categorie, liens a une dette ou un
  abonnement) et recoit l'empreinte de la ligne. Les lignes rapprochees sont comptees
  dans `matchedCount` (sous-ensemble de `readyCount`), hors `importedCount`.
- **Plusieurs candidats** : aucune decision automatique. La ligne devient
  `DUPLICATE` (bloquante) et `matchCandidateIds` liste les candidats, du plus ancien
  au plus recent. Une transaction ne sert qu'a une ligne : les lignes sont traitees
  dans l'ordre du fichier.
- **Aucun** : la ligne suit son chemin habituel.
- **Detail pour la revue (KKS-386)** : `matchedTransaction` (`id`, `date`, `libelle`,
  `montant`, `type`) decrit la transaction rapprochee, et `matchCandidates` les memes
  objets pour `matchCandidateIds`, dans le meme ordre. Ils sont lus en une seule
  requete pour tout le brouillon, parmi les transactions de l'utilisateur et du compte
  du brouillon : un identifiant qui n'est pas le sien, ou d'une transaction supprimee
  depuis, n'a pas de detail (`matchedTransaction` vaut `null`, le candidat est absent
  de `matchCandidates` ; `matchedTransactionId` et `matchCandidateIds` restent tels
  quels). Presents dans toutes les reponses qui portent une ligne.
- `subscriptionId` : une ligne `READY` non rapprochee, de sens `DEPENSE`, dont la
  cle commercant et le montant sont ceux d'**un seul** abonnement actif de
  l'utilisateur est rattachee a cet abonnement. Elle cree a la confirmation une
  transaction liee a l'abonnement, avec sa categorie si la ligne n'en a pas. Plusieurs
  abonnements de meme libelle (cinq abonnements d'un meme editeur) se distinguent par
  le montant ; s'il ne suffit pas, aucun lien. La cle d'un abonnement est apprise a la
  confirmation d'une ligne rapprochee d'un de ses paiements.

**Categorie pre-remplie (KKS-383)** : `categorySource` indique d'ou vient la
categorie — `RULE` (une regle), `HISTORY` (categorie majoritaire des transactions
passees de l'utilisateur chez le meme commercant, d'abord au meme montant, puis
tous montants), `USER` (choisie pendant la revue). `null` sans categorie.

Erreur `409` : brouillon actif existant pour ce compte.
Erreur `422` : format CSV non reconnu (utiliser `/imports/upload-with-mapping`).

**Profil retenu (KKS-440)** : le fichier est d'abord reconnu par ses colonnes
(voir `/imports/detect`), quel que soit le `bankCode` du compte ; ce dernier ne
sert plus que de repli. Un profil personnalise sauvegarde au mapping manuel est
donc reutilise au reimport.

**Solde du releve (KKS-384)** : la banque donne le solde reel dans l'en-tete du
releve. Ces cinq champs sont `null` pour un profil sans en-tete exploitable
(profil personnalise), et le comportement est alors strictement inchange.

- `statementAccountSuffix` : 4 derniers chiffres du numero de compte (jamais le
  numero complet) ; `statementBalance` et `statementBalanceDate` : solde donne par la
  banque et sa date. Une valeur illisible vaut `null`, jamais une erreur.
- `projectedBalance` : solde que l'application aura **a la date du solde** si le
  brouillon est confirme tel quel = `soldeInitial` du compte + transactions du compte
  datees jusqu'a cette date + lignes `READY` du brouillon datees jusqu'a cette date.
  Recalcule a chaque lecture (une ligne ignoree le fait varier). `null` sans solde ni
  date, et une fois le brouillon confirme.
- `proposedOpeningBalance` : **premier import du compte seulement** (aucun
  historique d'import pour ce compte) : le `soldeInitial` qui rend `projectedBalance`
  egal au solde bancaire. `null` aux imports suivants.

### Confirmer import `POST /api/v1/imports/drafts/{draftId}/confirm`

Corps **optionnel** : une confirmation sans corps fonctionne comme avant.

```json
{ "applyOpeningBalance": true }
```

| Champ | Type | Description |
|-------|------|-------------|
| `applyOpeningBalance` | boolean (optionnel, defaut `false`) | Si `true` **et** premier import du compte, le `soldeInitial` du compte est fixe a la valeur proposee, recalculee a la confirmation (le solde de l'application egale alors celui de la banque a la date du releve, sans ajustement manuel). Ignore sinon (import suivant, releve sans solde). |

Response `200` :

```json
{
  "importedCount": 151,
  "skippedCount": 9,
  "historyId": "uuid",
  "alreadyImportedCount": 7,
  "matchedCount": 3,
  "balanceCheck": {
    "bankBalance": 1842.37,
    "balanceDate": "2026-10-01",
    "computedBalance": 1238.07,
    "difference": -604.30,
    "suspects": [
      {
        "id": "uuid",
        "date": "2026-09-16",
        "libelle": "Pain",
        "montant": 4.30,
        "type": "DEPENSE"
      }
    ]
  }
}
```

**Controle de solde (KKS-384)** : `balanceCheck` vaut `null` quand le releve ne donne
pas de solde et sa date.

- `computedBalance` : solde reel de l'application a `balanceDate`, **apres** la
  creation des transactions (et apres `applyOpeningBalance` le cas echeant) ;
  `difference` = `computedBalance` − `bankBalance`, `0` quand les deux concordent.
- `suspects` : transactions du compte dont la date est dans la periode du releve (de
  la plus petite date de ses lignes a la plus tardive de ses lignes et de la date du
  solde, puisque le solde bancaire couvre toutes les operations jusqu'a cette date)
  et qui ne correspondent a
  **aucune** ligne du releve — ni creees par cet import, ni reconnues comme deja
  importees ou ecartees comme doublon (`duplicateTransactionId` d'une ligne
  `SKIPPED`). Les transactions de type `AJUSTEMENT` n'y figurent jamais (elles restent
  dans le solde). Triees par date puis libelle. Quand l'application contient des
  doublons de lignes bancaires, `difference` est egale a la somme signee de leurs
  montants et `suspects` les designe. Une transaction datee avant la periode du
  releve compte dans `difference` sans etre listee ; une transaction datee apres la
  date du solde n'est ni comptee ni listee.

`importedCount` ne compte que les transactions **creees** ; `matchedCount` (KKS-385)
compte les lignes rapprochees d'une transaction existante, qui n'ont rien cree. Une
transaction rapprochee n'est jamais un suspect.

Erreur `400` : lignes NEEDS_REVIEW ou DUPLICATE non resolues (dont les lignes aux
candidats multiples), ou transaction rapprochee supprimee ou importee depuis l'upload
(defaire le rapprochement de la ligne). Les lignes deja importees ne bloquent jamais.

Les actions groupees ignorent les lignes deja importees : un « tout
selectionner » ne les modifie pas et n'echoue pas sur elles.

### Mettre a jour une ligne `PUT /api/v1/imports/drafts/{draftId}/lines/{lineId}`

Request :

```json
{
  "categoryId": "uuid-categorie",
  "status": "READY"
}
```

Redemander le statut courant d'une ligne est sans effet : `READY` sur une ligne
deja `READY` n'est plus une erreur (KKS-383).

**Rapprochement (KKS-385)** : deux champs **optionnels** tranchent ou defont le
rapprochement d'une ligne `READY` ou `DUPLICATE` :

```json
{ "matchedTransactionId": "uuid-transaction" }
```

```json
{ "clearMatch": true }
```

- `matchedTransactionId` rapproche la ligne de cette transaction : elle doit etre
  celle de l'utilisateur, sur le compte du brouillon, sans empreinte, de meme sens
  et de meme montant que la ligne, et ne pas deja servir une autre ligne du brouillon.
  La fenetre de dates n'est pas controlee : l'utilisateur sait. La ligne devient
  `READY` rapprochee. `404` si la transaction n'est pas la sienne ou pas sur ce
  compte, `409` si une autre ligne la porte, `400` sinon.
- `clearMatch: true` defait le rapprochement (ou renonce aux candidats) : la ligne
  est `READY` sans rapprochement, une transaction sera creee. `400` si la ligne n'a
  ni rapprochement ni candidats, ou si les deux champs sont donnes.
- Passer une ligne rapprochee a `SKIPPED` defait aussi son rapprochement ; passer
  une ligne aux candidats multiples a `READY` vaut `clearMatch` (creer la transaction).

**Correction de categorie (KKS-383)** : quand `categoryId` change la categorie
d'une ligne, elle est propagee aux autres lignes du brouillon du meme commercant
et du meme sens qui n'ont pas de categorie ou seulement celle de l'historique
(`categorySource` passe a `USER`). Une regle `AUTO` est creee ou mise a jour
sur la cle commercant : elle s'appliquera aux releves suivants. La reponse ne
contient que la ligne modifiee — recharger le brouillon pour voir la propagation.

### Actions groupees `PUT /api/v1/imports/drafts/{draftId}/lines/batch`

Request :

```json
{
  "lineIds": ["uuid1", "uuid2", "uuid3"],
  "categoryId": "uuid-categorie",
  "status": "READY"
}
```

Une ligne aux candidats multiples (KKS-385) n'est pas touchee par `status: "READY"` :
creer une transaction a sa place est un choix explicite, ligne par ligne
(`PUT .../lines/{lineId}`). Passer des lignes rapprochees a `SKIPPED` defait leur
rapprochement.

### Regles de categorisation `POST /api/v1/imports/rules`

Request :

```json
{
  "pattern": "CARREFOUR",
  "categoryId": "uuid-categorie"
}
```

Response `201` :

```json
{
  "id": "uuid",
  "pattern": "CARREFOUR",
  "categoryId": "uuid-categorie",
  "categoryName": "Courses",
  "categorySystemKey": null,
  "categoryIcon": "shopping-cart",
  "createdAt": "2026-03-20T14:30:00",
  "origin": "MANUAL"
}
```

`origin` : `MANUAL` pour une regle saisie (le libelle contient le motif), `AUTO`
pour une regle creee par une correction pendant la revue (motif = cle commercant,
reconnue par mots entiers). Une correction ne modifie jamais une regle `MANUAL`.

### Lister les regles `GET /api/v1/imports/rules`

### Supprimer une regle `DELETE /api/v1/imports/rules/{ruleId}` — `204`

### Preview CSV `POST /api/v1/imports/preview`

Request (multipart/form-data) : `file` + optionnel `separator`, `encoding`, `skipHeaderLines`

Response `200` :

```json
{
  "headers": ["Date de l'operation", "Libelle", "Detail de l'ecriture", "Montant de l'operation", "Devise"],
  "rows": [["17/03/2026", "COTISATION MENSUEL", "COTISATION MENSUELLE SOBRIO", "-15,90", "EUR"]],
  "detectedSeparator": ";",
  "detectedEncoding": "ISO-8859-1",
  "totalRows": 160
}
```

### Upload avec mapping `POST /api/v1/imports/upload-with-mapping`

Request (multipart/form-data) : `file`, `accountId`, `mapping` (JSON string)

### Consulter un brouillon `GET /api/v1/imports/drafts/{draftId}`

Response `200` : meme format que la reponse de l'upload (avec toutes les lignes).

### Supprimer un brouillon `DELETE /api/v1/imports/drafts/{draftId}`

Response `204` (corps vide).

### Modifier une regle `PUT /api/v1/imports/rules/{ruleId}`

Request : meme format que la creation (`pattern`, `categoryId`).

Response `200` : la regle mise a jour.

### Lister brouillons `GET /api/v1/imports/drafts` — liste des brouillons PENDING

### Historique `GET /api/v1/imports/history?page=0&size=20` — imports finalises pagines

### Profils `GET /api/v1/imports/profiles` — profils pre-configures + personnalises

### Supprimer profil `DELETE /api/v1/imports/profiles/{profileId}` — `204`

## Rattrapage de l'historique (KKS-387)

> Endpoints proteges par JWT, sur le user authentifie uniquement. Un passage unique, declenche par l'utilisateur : les `GET` **proposent** et ne modifient rien, chaque `POST` applique **une** proposition validee. Une transaction d'un autre utilisateur est toujours `404 NOT_FOUND`, rien n'est modifie. Les ajustements de solde, les jambes de virement et les modeles recurrents ne sont jamais proposes ni fusionnes.

### Doublons probables `GET /api/v1/history-cleanup/duplicates`

Response `200` :

```json
{
  "importedDuplicates": [
    {
      "imported": {
        "id": "a1b2c3d4-0000-4000-8000-000000000001",
        "date": "2026-09-15",
        "libelle": "CARTE BOULANGERIE TEST",
        "montant": 3.20,
        "type": "DEPENSE",
        "category": null,
        "account": { "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890", "nom": "Compte courant", "icone": "🏦", "couleur": "#000000", "currency": "EUR", "bankLogoUrl": null, "bankCustomLogo": null },
        "imported": true,
        "debtId": null,
        "subscriptionId": null
      },
      "candidates": [
        {
          "id": "a1b2c3d4-0000-4000-8000-000000000002",
          "date": "2026-09-16",
          "libelle": "Pain",
          "montant": 3.20,
          "type": "DEPENSE",
          "category": { "id": "c0000000-0000-4000-8000-000000000001", "nom": "Courses", "icone": "🏷️", "couleur": "#111111", "isSystem": false, "systemKey": null },
          "account": { "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890", "nom": "Compte courant", "icone": "🏦", "couleur": "#000000", "currency": "EUR", "bankLogoUrl": null, "bankCustomLogo": null },
          "imported": false,
          "debtId": null,
          "subscriptionId": null
        }
      ]
    }
  ],
  "subscriptionDuplicates": [
    {
      "subscriptionId": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
      "subscriptionName": "Netflix",
      "periodStart": "2026-09-10",
      "periodEnd": "2026-10-09",
      "suggestedKeepTransactionId": "a1b2c3d4-0000-4000-8000-000000000003",
      "transactions": [ { "id": "a1b2c3d4-0000-4000-8000-000000000003", "...": "meme forme que ci-dessus" } ]
    }
  ]
}
```

- **Operation importee deja saisie** : une transaction importee d'un releve (`imported: true`) et une ou plusieurs transactions saisies a la main du meme compte, du meme sens et du meme montant, dont la date entre dans la fenetre du rapprochement de l'import (KKS-385) : 8 jours de part et d'autre pour un paiement d'abonnement, sinon de 5 jours avant a 2 jours apres la date de la transaction importee (une transaction importee ne retient pas si sa date est celle d'achat — 2 jours de part et d'autre — ou la date comptable — de 5 jours avant a 1 jour apres : les deux fenetres sont admises). Le libelle n'est pas un critere. Une transaction n'apparait que dans une proposition ; l'importee est identifiee par `imported.id`, et l'utilisateur choisit parmi `candidates` (la plus proche en date d'abord). Un candidat deja pris par une autre proposition n'est pas repete : une fois la premiere fusionnee, une nouvelle lecture montre la suite.
- **Paiements d'abonnement multiples** : transactions liees au meme abonnement dans la meme echeance (periode de sa frequence comptee depuis sa date de debut). `suggestedKeepTransactionId` est le paiement importe s'il y en a un, sinon le plus ancien. Une echeance qui compte deux paiements importes n'est pas proposee : ce sont deux operations de la banque.

### Fusionner une operation importee `POST /api/v1/history-cleanup/duplicates/merge`

Request :

```json
{
  "importedTransactionId": "a1b2c3d4-0000-4000-8000-000000000001",
  "keptTransactionId": "a1b2c3d4-0000-4000-8000-000000000002"
}
```

Response `200` : `{ "kept": <transaction telle qu'elle est apres fusion>, "removedIds": ["a1b2c3d4-0000-4000-8000-000000000001"] }`.

La transaction **saisie** est conservee (libelle, date, categorie, liens a une dette et a un abonnement) et recoit l'empreinte d'import de la transaction importee, qui est supprimee : un reimport du meme releve reconnait la ligne comme deja importee. Si la saisie n'avait pas d'abonnement et l'importee en avait un, la saisie prend ce lien. Les criteres sont reverifies a l'appel.

Erreurs : `404 NOT_FOUND` (transaction inconnue ou d'un autre utilisateur) ; `400 BAD_REQUEST` (deux fois la meme transaction) ; `400 VALIDATION_ERROR` (champ manquant) ; `409 CLEANUP_PROPOSAL_STALE` (la paire ne satisfait plus les criteres : transaction deja importee ou modifiee depuis, montant, sens, compte ou date hors fenetre, ajustement, virement ou modele recurrent) ; `409 CLEANUP_DEBT_LINK_MISSING` (la transaction a supprimer rembourse une dette que la conservee ne rembourse pas : le restant du est la somme des transactions de la dette). Une dette remboursee par les deux transactions est rouverte si la suppression la laisse sous son montant.

### Ne garder qu'un paiement d'abonnement `POST /api/v1/history-cleanup/subscription-duplicates/merge`

Request :

```json
{
  "keptTransactionId": "a1b2c3d4-0000-4000-8000-000000000003",
  "removedTransactionIds": ["a1b2c3d4-0000-4000-8000-000000000004", "a1b2c3d4-0000-4000-8000-000000000005"]
}
```

Response `200` : `{ "kept": <transaction>, "removedIds": [...] }`. Les transactions a supprimer doivent etre liees au meme abonnement et a la meme echeance que la conservee, et ne pas etre importees d'un releve (`409 CLEANUP_PROPOSAL_STALE` sinon). Memes erreurs que ci-dessus, `400 BAD_REQUEST` si la conservee figure aussi parmi les supprimees ; 50 transactions au plus.

### Transactions sans categorie `GET /api/v1/history-cleanup/uncategorized`

Response `200` :

```json
{
  "groups": [
    {
      "merchantKey": "BOULANGERIE TEST",
      "type": "DEPENSE",
      "amount": null,
      "count": 2,
      "totalAmount": 7.30,
      "suggestion": {
        "category": { "id": "c0000000-0000-4000-8000-000000000001", "nom": "Courses", "icone": "🏷️", "couleur": "#111111", "isSystem": false, "systemKey": null },
        "source": "HISTORY_AMOUNT"
      },
      "transactions": [ { "id": "a1b2c3d4-0000-4000-8000-000000000006", "...": "meme forme que ci-dessus" } ]
    }
  ]
}
```

Transactions sans categorie, hors ajustements et modeles recurrents, groupees par cle commercant (`MerchantKey`) et par sens. La categorie proposee est, dans l'ordre, celle de la premiere regle de l'utilisateur qui correspond au libelle (`RULE`), la categorie majoritaire de ses transactions passees chez le meme commercant **au meme montant** (`HISTORY_AMOUNT`), puis chez le meme commercant (`HISTORY_MERCHANT`). Un commercant dont les montants recoivent des propositions differentes (plusieurs abonnements sous un meme libelle) est **decoupe par montant** : `amount` est alors renseigne, et le client n'y demande pas de regle (`createRule: false`). Un libelle sans commercant reconnaissable donne la cle vide, sans proposition ni regle possible. `suggestion` vaut `null` sans proposition ; ces groupes sont listes apres les autres, les plus gros d'abord.

### Appliquer une categorie `POST /api/v1/history-cleanup/uncategorized/apply`

Request :

```json
{
  "categoryId": "c0000000-0000-4000-8000-000000000001",
  "transactionIds": ["a1b2c3d4-0000-4000-8000-000000000006", "a1b2c3d4-0000-4000-8000-000000000007"],
  "createRule": true
}
```

Response `200` : `{ "categorizedCount": 2, "skippedCount": 0 }`.

La categorie est celle de l'utilisateur, systeme ou non. Les transactions qui ont deja une categorie au moment de l'appel (ainsi que les ajustements et modeles recurrents) sont ignorees et comptees dans `skippedCount`. `createRule` est optionnel (`true` par defaut) : la categorie est retenue comme regle `AUTO` sur la cle commercant, creee ou reorientee ; une regle `MANUAL` n'est jamais modifiee. Aucune regle si les transactions couvrent plusieurs commercants ou si la cle est vide. `404 NOT_FOUND` si la categorie ou une transaction n'est pas a l'utilisateur (rien n'est modifie) ; `400 VALIDATION_ERROR` si `categoryId` manque ou si `transactionIds` est vide ou depasse 500 elements.

### Ajustements de solde `GET /api/v1/history-cleanup/adjustments`

Response `200` :

```json
{
  "accounts": [
    {
      "account": { "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890", "nom": "Compte courant", "icone": "🏦", "couleur": "#000000", "currency": "EUR", "bankLogoUrl": null, "bankCustomLogo": null },
      "bankBalance": 80.00,
      "bankBalanceDate": "2026-09-30",
      "computedBalance": 85.00,
      "adjustments": [
        { "id": "a1b2c3d4-0000-4000-8000-000000000008", "date": "2026-09-12", "libelle": "Balance adjustment", "montant": 5.00, "probablyUnnecessary": true }
      ]
    }
  ]
}
```

Lecture seule : aucune suppression ici (la suppression de transaction existante refuse les ajustements). `bankBalance` et `bankBalanceDate` sont ceux du dernier releve termine qui donne un solde bancaire (KKS-384), la date de solde la plus recente l'emportant ; `computedBalance` est le solde de l'application a cette date, ajustements compris. `probablyUnnecessary` : l'ajustement est date au plus tard a la date du solde bancaire et, sans lui, le solde calcule a cette date egalerait le solde bancaire au centime. Ces trois champs valent `null`, et `probablyUnnecessary` `false`, pour un compte sans solde bancaire connu.

## Voir aussi

- [`api-errors.md`](api-errors.md) — Contrat d'erreurs HTTP et format des reponses d'erreur
- **Swagger UI** : [http://localhost:8080/api/swagger-ui.html](http://localhost:8080/api/swagger-ui.html) — Documentation interactive, servie uniquement en profil `dev` ou avec `SWAGGER_ENABLED=true`
