# Data Model: Service d'authentification frontend

**Feature**: 002-auth-service
**Date**: 2026-02-07

## Entités TypeScript

### LoginRequest

Données envoyées pour la connexion.

| Champ    | Type   | Requis | Validation           |
|----------|--------|--------|----------------------|
| email    | string | oui    | Format email valide  |
| password | string | oui    | Non vide             |

### RegisterRequest

Données envoyées pour l'inscription.

| Champ    | Type   | Requis | Validation                   |
|----------|--------|--------|------------------------------|
| name     | string? | non    | Max 100 caractères (optionnel, omis → backend retourne `""`) |
| email    | string | oui    | Format email valide          |
| password | string | oui    | Min 6 caractères, non vide   |

### AuthResponse

Réponse du serveur après authentification réussie.

| Champ | Type   | Description                    |
|-------|--------|--------------------------------|
| token | string | Token JWT pour les requêtes    |
| email | string | Email de l'utilisateur         |
| name  | string | Nom de l'utilisateur           |

### UserInfo

Informations de l'utilisateur connecté (état local).

| Champ | Type   | Description                    |
|-------|--------|--------------------------------|
| email | string | Email de l'utilisateur         |
| name  | string | Nom de l'utilisateur           |

## Relations et flux de données

```text
LoginRequest / RegisterRequest
        │
        ▼  POST /api/auth/login  ou  /api/auth/register
        │
   AuthResponse { token, name, email }
        │
        ├──► localStorage["budget_token"] = token
        ├──► localStorage["budget_user"] = JSON.stringify({ name, email })
        │
        ▼
   signal<UserInfo | null>  ──► computed: isAuthenticated (boolean)
```

## Stockage local

| Clé            | Type   | Contenu                                | Cycle de vie                    |
|----------------|--------|----------------------------------------|---------------------------------|
| `budget_token` | string | Token JWT brut                         | Créé au login/register, supprimé au logout ou expiration |
| `budget_user`  | string | JSON `{ name: string, email: string }` | Créé au login/register, supprimé au logout |

## État réactif (Signals)

| Signal           | Type                  | Description                                      |
|------------------|-----------------------|--------------------------------------------------|
| `currentUser`    | `Signal<UserInfo \| null>` | Utilisateur connecté ou null                |
| `isAuthenticated`| `Signal<boolean>`     | Computed: `currentUser() !== null`                |

## Transitions d'état

```text
[Non connecté] ──login/register──► [Connecté]
     ▲                                  │
     │                                  │
     └──── logout / token expiré ◄──────┘
```

| Transition       | Déclencheur                  | Actions                                              |
|------------------|------------------------------|------------------------------------------------------|
| → Connecté       | Login ou Register réussi     | Stocker token + user, mettre à jour signal            |
| → Non connecté   | Logout                       | Supprimer token + user, reset signal, rediriger /auth |
| → Non connecté   | Token expiré détecté         | Supprimer token + user, reset signal                  |
| → Connecté       | Démarrage app (token valide) | Lire storage, vérifier expiration, restaurer signal   |
| → Non connecté   | Démarrage app (token invalide/absent) | Nettoyer storage si nécessaire              |
