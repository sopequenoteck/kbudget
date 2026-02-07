# Budget API — Contrat d'erreurs

Reference pour le frontend Angular : format des reponses d'erreur, codes HTTP et regles de validation.

## Format standard

Toutes les erreurs gerees par le `GlobalExceptionHandler` retournent un JSON avec 3 champs, toujours presents :

| Champ | Type | Description |
|-------|------|-------------|
| `timestamp` | string | Date/heure ISO-8601 sans timezone (`2026-02-07T14:30:25.123`) |
| `status` | number | Code HTTP numerique |
| `message` | string | Description lisible de l'erreur |

```json
{
  "timestamp": "2026-02-07T14:30:25.123456789",
  "status": 400,
  "message": "Description de l'erreur"
}
```

> **Note** : ce n'est pas un DTO typé — c'est un `Map<String, Object>` construit dans `GlobalExceptionHandler.errorBody()`.

## Codes d'erreur

### 400 Bad Request

Deux sources distinctes.

#### Erreur de validation (MethodArgumentNotValidException)

Declenchee quand un DTO annote `@Valid` echoue la validation Bean Validation. Le message concatene toutes les erreurs de champs avec `;` comme separateur.

```json
{
  "timestamp": "2026-02-07T14:30:25.123456789",
  "status": 400,
  "message": "montant: must be positive; libelle: must not be blank"
}
```

Format du message : `champ: contrainte; champ: contrainte; ...`

#### Erreur de logique metier (IllegalArgumentException)

Declenchee explicitement dans les services. Messages connus :

- `"Email deja utilise"` — inscription avec un email existant
- `"Email ou mot de passe incorrect"` — echec de connexion

```json
{
  "timestamp": "2026-02-07T14:30:25.123456789",
  "status": 400,
  "message": "Email deja utilise"
}
```

### 403 Forbidden

Declenchee par **Spring Security** (pas par le `GlobalExceptionHandler`) quand :

- Le header `Authorization` est absent
- Le token JWT est invalide ou expire
- La route n'est pas dans la liste des routes publiques

**Le corps de la reponse ne suit PAS le format standard.** Spring Security retourne son propre format ou un corps vide. Le frontend doit detecter le code HTTP 403, pas parser le body.

Routes publiques (pas de JWT requis) :

- `/auth/**`
- `/error`
- `/v3/api-docs/**`, `/swagger-ui/**`, `/swagger-ui.html`

### 404 Not Found

Declenchee via `EntityNotFoundException` quand :

- La ressource demandee n'existe pas
- La ressource existe mais n'appartient pas a l'utilisateur authentifie (meme comportement pour ne pas reveler l'existence de ressources d'autres utilisateurs)

```json
{
  "timestamp": "2026-02-07T14:30:25.123456789",
  "status": 404,
  "message": "Transaction not found"
}
```

### 500 Internal Server Error

Declenchee par le handler generique `Exception`. Le message est toujours le meme — aucun detail technique n'est expose au client.

```json
{
  "timestamp": "2026-02-07T14:30:25.123456789",
  "status": 500,
  "message": "Une erreur interne est survenue"
}
```

## Regles de validation par endpoint

### POST /api/auth/register — `RegisterRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `email` | `@NotBlank`, `@Email` | oui |
| `password` | `@NotBlank`, `@Size(min=6)` | oui |
| `name` | `@Size(max=100)` | non |

### POST /api/auth/login — `LoginRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `email` | `@NotBlank`, `@Email` | oui |
| `password` | `@NotBlank` | oui |

### POST/PUT /api/transactions — `TransactionRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `montant` | `@NotNull`, `@Positive` | oui |
| `libelle` | `@NotBlank`, `@Size(max=255)` | oui |
| `type` | `@NotNull`, enum `TransactionType` (DEPENSE, RECETTE) | oui |
| `date` | `@NotNull`, `LocalDate` | oui |
| `categorie` | `@Size(max=255)` | non |
| `note` | `@Size(max=500)` | non |

### POST/PUT /api/subscriptions — `SubscriptionRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `nom` | `@NotBlank`, `@Size(max=255)` | oui |
| `montant` | `@NotNull`, `@Positive` | oui |
| `frequence` | `@NotNull`, enum `Frequency` (MENSUEL, ANNUEL) | oui |
| `dateDebut` | `@NotNull`, `LocalDate` | oui |
| `actif` | `Boolean` | non |

### POST/PUT /api/debts — `DebtRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `personne` | `@NotBlank`, `@Size(max=255)` | oui |
| `montant` | `@NotNull`, `@Positive` | oui |
| `sens` | `@NotNull`, enum `DebtType` (JE_DOIS, ON_ME_DOIT) | oui |
| `date` | `@NotNull`, `LocalDate` | oui |
| `rembourse` | `Boolean` | non |

## Guide d'integration frontend

### Intercepteur HTTP Angular

L'intercepteur doit traiter les erreurs selon le code HTTP, pas le body (qui n'est pas garanti pour le 403).

```typescript
// Logique recommandee dans un HttpInterceptor Angular

switch (error.status) {
  case 400:
    // Parser error.error.message pour afficher a l'utilisateur
    // Si le message contient ";" → erreurs de validation multiples
    // Sinon → erreur metier directe
    break;

  case 403:
    // Pas de body fiable — rediriger vers login
    // Supprimer le token stocke (expire ou invalide)
    break;

  case 404:
    // Afficher "Ressource introuvable" ou rediriger
    break;

  case 500:
    // Afficher message generique, ne pas exposer error.error.message
    // (il dit toujours "Une erreur interne est survenue")
    break;
}
```

### Interface TypeScript

```typescript
interface ApiError {
  timestamp: string;  // ISO-8601 sans timezone
  status: number;
  message: string;
}
```

### Distinction erreur de validation vs erreur metier (400)

Le message de validation contient des `;` et suit le pattern `champ: contrainte`. Un split sur `"; "` permet d'extraire les erreurs par champ :

```typescript
function parseValidationErrors(message: string): Map<string, string> {
  const errors = new Map<string, string>();
  message.split('; ').forEach(part => {
    const [field, ...rest] = part.split(': ');
    errors.set(field, rest.join(': '));
  });
  return errors;
}
```
