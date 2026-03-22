# Quickstart: Service d'authentification frontend

**Feature**: 002-auth-service
**Date**: 2026-02-07

## Prérequis

1. Backend Spring Boot lancé sur `http://localhost:8080` :
   ```bash
   cd api && mvn spring-boot:run
   ```

2. Un utilisateur de test créé via l'API :
   ```bash
   curl -X POST http://localhost:8080/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"name": "Test User", "email": "test@test.com", "password": "password123"}'
   ```

## Lancer le frontend

```bash
cd app && npm start
```

Le serveur de développement démarre sur `http://localhost:4200` avec le proxy API configuré.

## Fichiers créés par cette feature

```
app/src/app/core/
├── models/
│   ├── auth.model.ts       # LoginRequest, RegisterRequest, AuthResponse
│   └── user.model.ts       # UserInfo
└── services/
    └── auth.ts             # AuthService
```

## Utilisation du AuthService

### Injection

```typescript
private readonly auth = inject(AuthService);
```

### Connexion

```typescript
this.auth.login({ email: 'test@test.com', password: 'password123' });
```

### Inscription

```typescript
this.auth.register({ name: 'New User', email: 'new@test.com', password: 'password123' });
```

### Vérifier l'état

```typescript
// Dans un template
@if (auth.isAuthenticated()) {
  <p>Bienvenue {{ auth.currentUser()?.name }}</p>
}
```

### Déconnexion

```typescript
this.auth.logout();
```

## Vérification rapide

1. Ouvrir la console du navigateur sur `http://localhost:4200`
2. Vérifier que `localStorage.getItem('budget_token')` est `null` (pas connecté)
3. Se connecter via le composant ou la console
4. Vérifier que `localStorage.getItem('budget_token')` contient un JWT
5. Recharger la page — la session doit être restaurée
6. Se déconnecter — le token doit être supprimé et la redirection vers `/auth` effectuée

## Tests

```bash
cd app && ng test
```

Les tests du AuthService vérifient :
- Login/Register appellent les bons endpoints
- Le token est stocké/supprimé correctement
- L'état réactif (signals) se met à jour
- L'expiration du token est détectée
- Les erreurs sont mappées en messages lisibles
