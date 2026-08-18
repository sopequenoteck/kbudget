# Budget API — Contrat d'erreurs

Cette page decrit le contrat public des erreurs HTTP JSON de l'API, y compris celles produites par Spring Security et les filtres servlet.

## Schema public

Le corps contient toujours deux chaines non vides, `error` et `message`. Le code HTTP est porte uniquement par la reponse HTTP. Une erreur `VALIDATION_ERROR` contient en plus une liste `details` structuree.

```ts
interface ApiError {
  error: string;
  message: string;
  details?: ValidationErrorDetail[];
}

interface ValidationErrorDetail {
  field: string;
  code: string;
  message: string;
}
```

```json
{
  "error": "NOT_FOUND",
  "message": "Transaction non trouvee"
}
```

`error` est un identifiant machine stable. `message` est destine a l'affichage et peut reprendre un message metier ou de validation. Un consommateur doit brancher sa logique sur `error`, jamais sur `message`.

### Validation des champs

Pour `VALIDATION_ERROR`, `details` permet d'associer chaque contrainte au champ concerne sans analyser la chaine `message` :

```json
{
  "error": "VALIDATION_ERROR",
  "message": "email: must not be blank; password: size must be between 12 and 100",
  "details": [
    {
      "field": "email",
      "code": "NOT_BLANK",
      "message": "must not be blank"
    },
    {
      "field": "password",
      "code": "SIZE",
      "message": "size must be between 12 and 100"
    }
  ]
}
```

Les codes de contrainte sont normalises en majuscules snake case (`NotNull` devient `NOT_NULL`). `details` est absent pour toutes les autres erreurs.

## Matrice des erreurs gerees

| Categorie | HTTP | `error` | Message public |
|---|---:|---|---|
| Argument ou etat invalide | 400 | `BAD_REQUEST` | Message metier, avec fallback public |
| Validation Bean Validation | 400 | `VALIDATION_ERROR` | Message agrege et `details` structures par champ |
| Corps JSON illisible | 400 | `MALFORMED_REQUEST` | `Requete invalide` |
| Format d'image | 400 | `INVALID_IMAGE_FORMAT` | Message specialise existant |
| Format d'export | 400 | `INVALID_EXPORT_FORMAT` | Message specialise existant |
| Mot de passe inchange | 400 | `PASSWORD_UNCHANGED` | Message specialise existant |
| Confirmation manquante | 400 | `CONFIRMATION_REQUIRED` | Message specialise existant |
| Mot de passe incorrect | 401 | `PASSWORD_INCORRECT` | Message specialise existant |
| Authentification absente ou invalide | 401 | `UNAUTHENTICATED` | `Authentification requise` |
| Refresh token expire | 401 | `TOKEN_EXPIRED` | Message specialise existant |
| Refresh token revoque | 401 | `TOKEN_REVOKED` | Message specialise existant |
| Reutilisation de refresh token | 401 | `TOKEN_REUSE_DETECTED` | Message specialise existant |
| Refresh token invalide | 401 | `TOKEN_INVALID` | Message specialise existant |
| Acces refuse | 403 | `ACCESS_DENIED` | `Accès refusé` ou message public du handler |
| Reset obligatoire avant acces | 403 | `PASSWORD_RESET_REQUIRED` | Message public specialise |
| Fonctionnalite desactivee | 403 | `FEATURE_DISABLED` | Message metier, avec fallback public |
| Reset non requis | 403 | `PASSWORD_RESET_NOT_REQUIRED` | Message specialise existant |
| Suppression du dernier admin | 403 | `LAST_ADMIN_DELETION_FORBIDDEN` | Message specialise existant |
| Ressource absente | 404 | `NOT_FOUND` | Message metier, avec fallback public |
| Avatar absent | 404 | `AVATAR_NOT_FOUND` | Message specialise existant |
| Conflit metier generique | 409 | `CONFLICT` | Message metier, avec fallback public |
| Desactivation du dernier admin | 409 | `LAST_ADMIN_CANNOT_BE_DISABLED` | `Impossible de désactiver le dernier admin actif.` |
| Email deja utilise | 409 | `EMAIL_ALREADY_EXISTS` | `Cet email est déjà utilisé par un autre utilisateur.` |
| Fichier trop volumineux | 413 | `FILE_TOO_LARGE` | Message specialise existant |
| Profil CSV absent | 422 | `CSV_PROFILE_NOT_FOUND` | Message metier, avec fallback public |
| Erreur inattendue | 500 | `INTERNAL_ERROR` | `Une erreur interne est survenue` |

Les erreurs 500 sont journalisees avec leur trace complete cote serveur. Le corps public ne reprend jamais le message, la cause, le type ou la trace de l'exception.

## Securite HTTP

Les erreurs emises avant les controleurs utilisent le meme contrat grace a un writer partage. Une requete protegee sans authentification retourne `UNAUTHENTICATED`; un refus d'autorisation retourne `ACCESS_DENIED`; le filtre de premier login retourne `PASSWORD_RESET_REQUIRED`.

L'intercepteur Angular tente un refresh uniquement apres un 401. Un 403 represente une authentification valide mais insuffisamment autorisee et est propage sans refresh.

Les erreurs STOMP/WebSocket ne sont pas des reponses HTTP JSON et restent hors de ce contrat.
