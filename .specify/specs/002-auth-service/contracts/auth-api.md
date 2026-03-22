# API Contracts: Authentification

**Feature**: 002-auth-service
**Date**: 2026-02-07
**Note**: Ces contrats décrivent les endpoints backend **existants** que le AuthService frontend va consommer. Aucun nouveau endpoint à créer.

## POST /api/auth/login

Connexion d'un utilisateur existant.

### Request

```
POST /api/auth/login
Content-Type: application/json
```

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

| Champ    | Type   | Requis | Contraintes         |
|----------|--------|--------|---------------------|
| email    | string | oui    | Format email valide |
| password | string | oui    | Non vide            |

### Responses

**200 OK** — Authentification réussie

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**400 Bad Request** — Identifiants invalides

```json
{
  "timestamp": "2026-02-07T10:30:00",
  "status": 400,
  "message": "Email ou mot de passe incorrect"
}
```

---

## POST /api/auth/register

Inscription d'un nouvel utilisateur.

### Request

```
POST /api/auth/register
Content-Type: application/json
```

```json
{
  "name": "John Doe",
  "email": "user@example.com",
  "password": "password123"
}
```

| Champ    | Type   | Requis | Contraintes                  |
|----------|--------|--------|------------------------------|
| name     | string | non    | Max 100 caractères           |
| email    | string | oui    | Format email valide          |
| password | string | oui    | Min 6 caractères, non vide   |

### Responses

**201 Created** — Inscription réussie (si `name` omis dans la requête, le backend retourne `"name": ""` — chaîne vide, jamais null)

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**400 Bad Request** — Email déjà utilisé

```json
{
  "timestamp": "2026-02-07T10:30:00",
  "status": 400,
  "message": "Email déjà utilisé"
}
```

**400 Bad Request** — Validation échouée (Bean Validation)

```json
{
  "timestamp": "2026-02-07T10:30:00",
  "status": 400,
  "message": "email: must be a well-formed email address; password: size must be between 6 and 2147483647"
}
```

---

## JWT Token Structure

Le token retourné est un JWT standard (RFC 7519).

### Header (décodé)

```json
{
  "alg": "HS256"
}
```

### Payload (décodé)

```json
{
  "sub": "user@example.com",
  "iat": 1738886400,
  "exp": 1738972800
}
```

| Champ | Description                              |
|-------|------------------------------------------|
| sub   | Email de l'utilisateur (subject)         |
| iat   | Timestamp de création (seconds epoch)    |
| exp   | Timestamp d'expiration (seconds epoch)   |

### Usage

```
Authorization: Bearer <token>
```

Le token doit être envoyé dans le header `Authorization` de toutes les requêtes vers les routes protégées. Cette responsabilité sera implémentée dans KKS-26 (intercepteur HTTP).
