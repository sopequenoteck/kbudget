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
  "message": "Transaction not found"
}
```

`error` est un identifiant machine stable : c'est le **seul** champ sur lequel un
client doit brancher quoi que ce soit, sa logique comme son affichage.

**`message` est un champ de diagnostic** (KKS-324). Il est destine aux journaux
et au debogage, jamais a l'ecran. Il est redige en anglais technique, sa
formulation n'est couverte par aucune garantie de compatibilite, et il peut
changer sans preavis. Tout client derive donc le texte qu'il presente a
l'utilisateur du code porte par `error`, via son propre catalogue de libelles —
c'est ce que font le client Angular (`ApiErrorService`) et le client Flutter
(`errorLabel`). Un code absent du catalogue tombe sur un libelle generique : la
politique de compatibilite interdit de retirer un champ de reponse, pas
d'ajouter un code.

`message` n'est pas non plus un identifiant : deux erreurs distinctes peuvent
partager le meme texte, et le meme code peut porter des textes differents selon
l'appel.

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

**Le code derive du nom de l'annotation qui a echoue, il n'est ecrit nulle part.** Remplacer `@Size` par une autre contrainte de longueur change donc la valeur servie, sans qu'aucune signature ni aucun DTO expose ne bouge. Ce lien est verrouille par `ValidationErrorCodeContractTest`, qui part des DTOs et du validateur reels. Dans le cas ou la contrainte n'est pas identifiable, le code retombe sur `INVALID_VALUE`.

## Matrice des erreurs gerees

| Categorie | HTTP | `error` | `message` servi (diagnostic) |
|---|---:|---|---|
| Argument ou etat invalide | 400 | `BAD_REQUEST` | Message metier, avec fallback public |
| Validation Bean Validation | 400 | `VALIDATION_ERROR` | Message agrege et `details` structures par champ |
| Corps JSON illisible | 400 | `MALFORMED_REQUEST` | `Invalid request` |
| Format d'image | 400 | `INVALID_IMAGE_FORMAT` | Message specialise existant |
| Format d'export | 400 | `INVALID_EXPORT_FORMAT` | Message specialise existant |
| Mot de passe inchange | 400 | `PASSWORD_UNCHANGED` | Message specialise existant |
| Confirmation manquante | 400 | `CONFIRMATION_REQUIRED` | Message specialise existant |
| Mot de passe incorrect | 401 | `PASSWORD_INCORRECT` | Message specialise existant |
| Authentification absente ou invalide | 401 | `UNAUTHENTICATED` | `Authentication required` |
| Refresh token expire | 401 | `TOKEN_EXPIRED` | Message specialise existant |
| Refresh token revoque | 401 | `TOKEN_REVOKED` | Message specialise existant |
| Reutilisation de refresh token | 401 | `TOKEN_REUSE_DETECTED` | Message specialise existant |
| Refresh token invalide | 401 | `TOKEN_INVALID` | Message specialise existant |
| Acces refuse | 403 | `ACCESS_DENIED` | `Access denied` ou message du handler |
| Reset obligatoire avant acces | 403 | `PASSWORD_RESET_REQUIRED` | Message public specialise |
| Fonctionnalite desactivee | 403 | `FEATURE_DISABLED` | Message metier, avec fallback public |
| Reset non requis | 403 | `PASSWORD_RESET_NOT_REQUIRED` | Message specialise existant |
| Suppression du dernier admin | 403 | `LAST_ADMIN_DELETION_FORBIDDEN` | Message specialise existant |
| Ressource absente | 404 | `NOT_FOUND` | Message metier, avec fallback public |
| Route inconnue | 404 | `NOT_FOUND` | `Resource not found` |
| Avatar absent | 404 | `AVATAR_NOT_FOUND` | Message specialise existant |
| Conflit metier generique | 409 | `CONFLICT` | Message metier, avec fallback public |
| Desactivation du dernier admin | 409 | `LAST_ADMIN_CANNOT_BE_DISABLED` | `The last active administrator cannot be disabled.` |
| Email deja utilise | 409 | `EMAIL_ALREADY_EXISTS` | `This email is already used by another user.` |
| Fichier trop volumineux | 413 | `FILE_TOO_LARGE` | Message specialise existant |
| Profil CSV absent | 422 | `CSV_PROFILE_NOT_FOUND` | Message metier, avec fallback public |
| Trop de tentatives d'authentification | 429 | `TOO_MANY_REQUESTS` | `Too many attempts. Please try again shortly.` |
| Erreur inattendue | 500 | `INTERNAL_ERROR` | `An internal error occurred` |

Les erreurs 500 sont journalisees avec leur trace complete cote serveur. Le corps public ne reprend jamais le message, la cause, le type ou la trace de l'exception.

## Limitation de debit (KKS-310)

Les endpoints d'authentification sont limites par IP. Sans cela, `/auth/login`
offre du bruteforce sans cout et `/auth/invitations/{token}` permet d'enumerer
des jetons d'invitation — acceptable derriere un reseau prive, plus du tout des
lors que des instances sont exposees sur Internet.

| Endpoint | Limite |
|----------|--------|
| `POST /api/v1/auth/login` | Oui |
| `POST /api/v1/auth/refresh` | Oui |
| `POST /api/v1/auth/accept-invite` | Oui |
| `GET /api/v1/auth/invitations/{token}` | Oui |
| `POST /api/v1/auth/logout`, `/auth/first-login-reset` | Non — exigent deja un JWT valide |
| Tout le reste, dont `/api/actuator/health` | Non |

Au-dela du quota, la reponse suit le contrat unifie :

```json
HTTP 429
{ "error": "TOO_MANY_REQUESTS", "message": "Too many attempts. Please try again shortly." }
```

**La limitation porte sur l'IP, jamais sur le compte.** Verrouiller un compte
apres des echecs repetes ouvrirait un deni de service cible : il suffirait de
connaitre l'email de quelqu'un pour l'empecher de se connecter.

### Configuration

| Variable | Defaut | Role |
|----------|--------|------|
| `RATE_LIMIT_CAPACITY` | `5` | Tentatives autorisees par fenetre et par IP |
| `RATE_LIMIT_WINDOW_SECONDS` | `60` | Duree de la fenetre |
| `TRUSTED_PROXIES` | Plages privees | Prefixes d'IP dont l'en-tete `X-Forwarded-For` est cru |

Un self-hoster derriere un VPN voudra desserrer, une instance exposee voudra
serrer.

### Derriere un reverse proxy

Sans proxy, l'IP retenue est l'adresse TCP de l'appelant.

Avec un proxy, toutes les requetes portent l'adresse du proxy : la limite
s'appliquerait globalement a tous les utilisateurs. L'API lit donc
`X-Forwarded-For` — **mais seulement si la requete provient d'une IP listee dans
`TRUSTED_PROXIES`**.

Cette condition n'est pas un detail. `X-Forwarded-For` est un en-tete fourni par
le client : n'importe qui peut l'envoyer. Cru sans condition, il suffirait d'y
mettre une valeur differente a chaque requete pour obtenir un quota neuf et
contourner la limitation entierement.

Le defaut couvre le deploiement fourni par le projet — Caddy et le container
nginx joignent l'API depuis le reseau Docker ou le LAN. Une instance derriere un
proxy situe sur un autre reseau doit ajouter son adresse :

```bash
TRUSTED_PROXIES=10.,192.168.,203.0.113.5
```

Les proxies fournis transmettent `X-Forwarded-For`, mais **pas de la meme
facon selon leur position** :

| Fichier | Position | Comportement |
|---------|----------|--------------|
| `deploy/Caddyfile` | Bordure | **Ecrase** l'en-tete (`header_up X-Forwarded-For {remote_host}`) |
| `deploy/nginx.conf` | Bordure | **Ecrase** l'en-tete (`$remote_addr`) |
| `app/nginx.conf` | Interne, derriere Caddy | **Enrichit** la chaine (`$proxy_add_x_forwarded_for`) |

La distinction est essentielle. Un proxy de bordure recoit directement les
clients : s'il enrichit au lieu d'ecraser, une valeur envoyee par le client
reste en premier maillon — celui que l'API retient. Un proxy interne, lui, doit
enrichir : ecraser remplacerait l'IP reelle du client par celle du proxy amont.

Si `app/nginx.conf` devait etre expose directement sur Internet, sans proxy
devant, il faudrait le passer a `$remote_addr`.

## Securite HTTP

Les erreurs emises avant les controleurs utilisent le meme contrat grace a un writer partage. Une requete protegee sans authentification retourne `UNAUTHENTICATED`; un refus d'autorisation retourne `ACCESS_DENIED`; le filtre de premier login retourne `PASSWORD_RESET_REQUIRED`.

L'intercepteur Angular tente un refresh uniquement apres un 401. Un 403 represente une authentification valide mais insuffisamment autorisee et est propage sans refresh.

Les erreurs STOMP/WebSocket ne sont pas des reponses HTTP JSON et restent hors de ce contrat.
