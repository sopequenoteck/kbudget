# Research: Service d'authentification frontend

**Feature**: 002-auth-service
**Date**: 2026-02-07

## R1 — Décodage JWT sans librairie externe

**Decision**: Utiliser `atob()` natif pour décoder le payload JWT (base64url → JSON).

**Rationale**: Le JWT est composé de 3 parties séparées par des points (`header.payload.signature`). Seul le payload (2e partie) nous intéresse pour lire le champ `exp`. `atob()` est supporté par tous les navigateurs modernes. Pas besoin de librairie comme `jwt-decode` pour un cas aussi simple.

**Alternatives considered**:
- `jwt-decode` (npm) : librairie légère mais dépendance supplémentaire inutile pour lire un seul champ
- Appel serveur pour valider le token : overhead réseau inutile, le backend valide déjà à chaque requête via JwtFilter

**Implementation notes**:
- JWT base64url utilise `-` et `_` au lieu de `+` et `/`. Il faut remplacer avant `atob()`.
- Le champ `exp` est en secondes epoch (pas millisecondes). Comparer avec `Date.now() / 1000`.
- Entourer le décodage d'un try/catch : un token corrompu ne doit pas crasher l'app.

## R2 — Signals vs BehaviorSubject pour l'état auth

**Decision**: Utiliser `signal()` et `computed()` Angular pour l'état d'authentification.

**Rationale**: Convention projet signals-first (CLAUDE.md). Les signals sont synchrones, plus simples que RxJS pour du state management local, et s'intègrent nativement avec le change detection OnPush d'Angular.

**Alternatives considered**:
- `BehaviorSubject` (RxJS) : fonctionnel mais contrevient à la convention signals-first du projet
- NgRx Store : sur-ingénierie pour un state aussi simple (single-user, 1 service)
- Service avec getter : pas réactif, ne déclenche pas le change detection OnPush

**Implementation notes**:
- `signal<UserInfo | null>(null)` pour l'état utilisateur
- `computed(() => this.currentUser() !== null)` pour `isAuthenticated`
- Mise à jour synchrone du signal après stockage du token

## R3 — Stockage du token (localStorage vs sessionStorage)

**Decision**: localStorage avec la clé `budget_token` (spécifié dans l'issue KKS-25).

**Rationale**: localStorage persiste après fermeture du navigateur, permettant la restauration de session (FR-009). sessionStorage limiterait la session à l'onglet courant, ce qui est une mauvaise UX pour une app mobile-first.

**Alternatives considered**:
- `sessionStorage` : session perdue à la fermeture du navigateur, mauvaise UX
- Cookie HttpOnly : plus sécurisé (XSS) mais le backend est déjà stateless JWT, et nécessiterait des changements côté serveur
- IndexedDB : plus complexe, aucun avantage pour stocker une simple string

**Implementation notes**:
- Vérifier la disponibilité de localStorage (try/catch) pour gérer le mode navigation privée
- Une seule clé `budget_token` : simple à nettoyer au logout

## R4 — Gestion des erreurs backend

**Decision**: Mapper les erreurs HTTP du backend en messages utilisateur lisibles côté service.

**Rationale**: Le backend retourne des messages en français ("Email déjà utilisé", "Email ou mot de passe incorrect") dans le body de la réponse 400. Le service doit extraire ces messages et les propager aux composants UI.

**Alternatives considered**:
- Laisser les composants gérer les erreurs HTTP brutes : code dupliqué dans chaque composant
- Intercepteur global d'erreurs : trop générique pour les erreurs métier auth, plus adapté pour les 401/500

**Implementation notes**:
- Erreur 400 : extraire le message du body de réponse
- Erreur 0 (réseau) : message "Impossible de contacter le serveur"
- Erreur 500 : message générique "Une erreur est survenue"
- Propager via `throwError()` RxJS ou via le signal d'erreur

## R5 — Restauration de session au démarrage

**Decision**: Vérifier le token en localStorage au constructeur du service (appelé au bootstrap de l'app).

**Rationale**: Le service est `providedIn: 'root'`, donc instancié au démarrage. Vérifier le token à l'initialisation permet de restaurer l'état auth sans action utilisateur (FR-009).

**Alternatives considered**:
- `APP_INITIALIZER` : plus explicite mais ajoute de la complexité pour un simple check synchrone
- Lazy check au premier accès : l'état serait "non connecté" brièvement puis "connecté", causant un flash

**Implementation notes**:
- Lire le token depuis localStorage
- Décoder et vérifier l'expiration
- Si valide : mettre à jour le signal avec les infos user (extraites du token ou stockées séparément)
- Si expiré/invalide : supprimer le token, laisser l'état "non connecté"

## R6 — Informations utilisateur (nom, email)

**Decision**: Stocker les infos utilisateur (nom, email) dans un signal séparé, alimenté par la réponse AuthResponse (pas par le décodage du token JWT).

**Rationale**: Le token JWT backend ne contient que l'email comme `subject`. Le nom est uniquement dans la réponse AuthResponse. Pour restaurer le nom au rechargement, on le stocke en localStorage avec le token.

**Alternatives considered**:
- Décoder le nom depuis le JWT : le backend ne l'inclut pas dans le payload JWT (seul `sub` = email)
- Appeler un endpoint `/me` au démarrage : overhead réseau, endpoint inexistant
- Ne stocker que le token : perte du nom au rechargement

**Implementation notes**:
- Stocker `{ token, name, email }` sérialisé en JSON sous `budget_token`, ou stocker le nom/email dans une clé séparée (`budget_user`)
- Option retenue : stocker le token dans `budget_token` et les infos user dans `budget_user` (JSON `{ name, email }`) pour une séparation claire
