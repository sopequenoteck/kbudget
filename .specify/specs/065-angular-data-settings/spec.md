# Feature Specification: Gestion donnees Angular (Data Settings)

**Feature Branch**: `065-angular-data-settings`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "KKS-151 — Ajouter un ecran Data Settings dans le module Settings Angular. Afficher les informations de connexion au serveur. Actions de maintenance (purge cache, reload donnees)."
**Linear**: KKS-151

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter les informations de connexion serveur (Priority: P1)

L'utilisateur accede a l'ecran "Donnees" depuis le hub Settings pour visualiser l'etat de sa connexion au serveur API. Il voit immediatement l'URL du serveur utilisee et le statut de connectivite (en ligne / hors ligne). Cela lui permet de diagnostiquer rapidement un probleme de connexion.

**Why this priority**: C'est la fonctionnalite principale de l'ecran. Sans elle, l'ecran n'a aucune utilite. L'utilisateur a besoin de savoir si son application communique correctement avec le serveur.

**Independent Test**: Peut etre teste en accedant a `/settings/data` et en verifiant que l'URL serveur et le statut de connexion sont affiches correctement.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est authentifie, **When** il accede a l'ecran Donnees, **Then** il voit l'URL du serveur API actuellement utilisee et un indicateur de statut de connexion (en ligne/hors ligne)
2. **Given** le serveur est accessible, **When** l'ecran verifie la connectivite, **Then** un indicateur visuel "En ligne" est affiche avec un badge vert
3. **Given** le serveur est inaccessible, **When** l'ecran verifie la connectivite, **Then** un indicateur visuel "Hors ligne" est affiche avec un badge rouge et un message explicatif

---

### User Story 2 - Tester manuellement la connectivite serveur (Priority: P2)

L'utilisateur souhaite verifier a la demande si le serveur est joignable, par exemple apres avoir resolu un probleme reseau. Il clique sur un bouton de test qui effectue un ping et met a jour le statut affiche.

**Why this priority**: Complete la consultation passive (P1) par une action de diagnostic active. Utile pour le depannage sans quitter l'application.

**Independent Test**: Peut etre teste en cliquant sur le bouton "Tester la connexion" et en verifiant que le statut se met a jour.

**Acceptance Scenarios**:

1. **Given** l'ecran Donnees est affiche, **When** l'utilisateur clique sur "Tester la connexion", **Then** un indicateur de chargement s'affiche pendant le test puis le statut est mis a jour
2. **Given** le serveur est accessible, **When** le test est lance, **Then** le statut passe a "En ligne" avec la duree de reponse affichee (ex: "120 ms")
3. **Given** le serveur est inaccessible, **When** le test est lance, **Then** le statut passe a "Hors ligne" avec un message d'erreur (ex: "Serveur injoignable", "Delai depasse")

---

### User Story 3 - Recharger les donnees depuis le serveur (Priority: P3)

L'utilisateur souhaite forcer un rechargement complet des donnees affichees dans l'application (transactions, comptes, categories, etc.), par exemple apres une modification directe en base de donnees ou pour resoudre un affichage incoherent.

**Why this priority**: Action de maintenance utile mais rare. La plupart du temps, les donnees sont automatiquement a jour via les appels API.

**Independent Test**: Peut etre teste en cliquant sur "Recharger les donnees" et en verifiant que les listes de l'application sont rafraichies.

**Acceptance Scenarios**:

1. **Given** l'ecran Donnees est affiche, **When** l'utilisateur clique sur "Recharger les donnees", **Then** une confirmation est demandee avant de proceder
2. **Given** l'utilisateur confirme le rechargement, **When** l'action est executee, **Then** la page se recharge automatiquement, reinitialisant toutes les donnees en memoire

---

### Edge Cases

- Que se passe-t-il si le test de connectivite expire (timeout) ? Le statut affiche "Hors ligne" avec le message "Delai de reponse depasse (10s)".
- Que se passe-t-il si l'utilisateur lance plusieurs tests de connectivite rapidement ? Les tests precedents sont annules, seul le dernier fait foi.
- Que se passe-t-il si le rechargement des donnees est lance alors que le serveur est hors ligne ? La page se recharge normalement, puis les ecrans affichent les messages d'erreur standards de chaque service (donnees indisponibles).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT afficher l'URL du serveur API actuellement configuree (lecture seule)
- **FR-002**: Le systeme DOIT effectuer un test de connectivite automatique au chargement de l'ecran via l'endpoint de sante du serveur
- **FR-003**: Le systeme DOIT afficher un indicateur visuel de statut de connexion (en ligne avec badge vert / hors ligne avec badge rouge)
- **FR-004**: Le systeme DOIT permettre a l'utilisateur de lancer un test de connectivite manuel via un bouton dedie
- **FR-005**: Le systeme DOIT afficher le temps de reponse du serveur lors d'un test reussi
- **FR-006**: Le systeme DOIT afficher un message d'erreur explicatif lors d'un test echoue (injoignable, timeout, erreur serveur)
- **FR-007**: Le systeme DOIT permettre a l'utilisateur de forcer un rechargement complet des donnees de l'application
- **FR-008**: Le systeme DOIT demander une confirmation avant de proceder au rechargement des donnees
- **FR-009**: Le systeme DOIT afficher un indicateur de chargement pendant le test de connectivite
- **FR-010**: L'ecran DOIT etre accessible via la route `/settings/data` et integre dans le hub Settings existant

### Key Entities

- **Server Status**: Represente l'etat de connexion au serveur API — statut (en ligne/hors ligne), temps de reponse, message d'erreur eventuel, horodatage du dernier test
- **Server Info**: Informations de configuration du serveur — URL de l'API, environnement (production/development)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut visualiser le statut de connexion serveur en moins de 3 secondes apres l'ouverture de l'ecran
- **SC-002**: Le test de connectivite manuel retourne un resultat (succes ou erreur) en moins de 15 secondes
- **SC-003**: Le rechargement complet des donnees se termine en moins de 10 secondes pour un volume standard (< 1000 transactions)
- **SC-004**: 100% des scenarios d'erreur (serveur inaccessible, timeout, erreur reseau) affichent un message comprehensible a l'utilisateur

## Assumptions

- Angular est **server-only** : il n'y a pas de mode local/hors-ligne a gerer. L'URL du serveur est determinee par la configuration de l'application (environment), pas saisie par l'utilisateur.
- L'endpoint de sante du serveur (`/actuator/health`) est accessible sans authentification et retourne un statut HTTP 200 quand le serveur est operationnel.
- Le rechargement des donnees consiste a invalider les caches en memoire (signaux/services) et forcer un re-fetch depuis l'API lors de la prochaine navigation. Il ne s'agit pas d'un telechargement en masse.
- Le placeholder existant a la route `/settings/data` sera remplace par le composant reel.
- L'ecran suit les memes conventions visuelles et techniques que les autres ecrans Settings (standalone, OnPush, signals-first, inject()).
