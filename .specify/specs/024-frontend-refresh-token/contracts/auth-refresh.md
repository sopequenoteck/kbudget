# API Contracts: Auth Refresh & Logout

**Feature**: 024-frontend-refresh-token
**Date**: 2026-02-13
**Note**: Ces endpoints existent déjà côté backend. Ce document décrit le contrat tel que le frontend doit le consommer.

## POST /api/auth/refresh

Renouvelle l'access token et le refresh token via rotation.

**Request**:
```json
{
  "refreshToken": "string (non-vide, opaque)"
}
```

**Response 200** (succès):
```json
{
  "token": "string (nouveau JWT access token)",
  "refreshToken": "string (nouveau refresh token — rotation)",
  "email": "string",
  "name": "string"
}
```

**Response 401** (refresh token invalide, expiré ou révoqué):
```json
{
  "message": "string (ex: Token expiré, Token révoqué)"
}
```

**Comportement frontend**:
- Sur 200 : stocker les nouveaux `token` et `refreshToken` dans localStorage, rejouer la requête originale
- Sur 401 : déconnexion immédiate, nettoyage localStorage, redirect `/auth`
- Sur erreur réseau (status 0) : propager l'erreur, ne pas déconnecter (le refresh token reste potentiellement valide)

---

## POST /api/auth/logout

Révoque le refresh token côté serveur.

**Request**:
```json
{
  "refreshToken": "string (non-vide, opaque)"
}
```

**Response 204** (succès, pas de body)

**Response 400/401** (token déjà révoqué ou invalide)

**Comportement frontend**:
- Appel fire-and-forget : le nettoyage localStorage et la redirection se font indépendamment de la réponse
- L'échec de l'appel API ne doit pas bloquer la déconnexion locale

---

## POST /api/auth/login (existant, modification du contrat de réponse)

**Response 200** (contrat inchangé côté backend, modification de la consommation frontend):
```json
{
  "token": "string (JWT access token)",
  "refreshToken": "string (refresh token — NOUVEAU champ consommé)",
  "email": "string",
  "name": "string"
}
```

**Changement frontend** : stocker `refreshToken` en plus de `token` dans localStorage.

---

## POST /api/auth/register (existant, même modification)

Même contrat de réponse et même changement frontend que `/auth/login`.
