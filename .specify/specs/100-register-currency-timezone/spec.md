# Feature Specification: Devise et fuseau horaire a l'inscription

**Feature Branch**: `100-register-currency-timezone`
**Created**: 2026-03-21
**Status**: Draft
**Input**: Ajouter la devise et le fuseau horaire au flux d'inscription pour initialiser correctement le compte par defaut et les preferences utilisateur.

## Clarifications

### Session 2026-03-21

- Q: Les utilisateurs existants (deja inscrits avec EUR par defaut) sont-ils concernes par cette feature ? → A: Hors scope -- les utilisateurs existants changent leur devise manuellement via les parametres existants.
- Q: Ou placer le selecteur de devise dans le formulaire d'inscription ? → A: Apres le champ "Nom", avant "Email".
- Q: Que devient le selecteur de timezone dans les parametres de notifications ? → A: Il reste en place tel quel (inchange). L'utilisateur peut toujours modifier son timezone manuellement apres l'inscription.
- Q: Que fait-on du selecteur "Devise par defaut" fantome dans le profil (backend ignore la valeur) ? → A: Supprimer le selecteur du profil et ajouter un lien vers "Devises & Taux" a la place.

## User Scenarios & Testing

### User Story 1 - Choix de la devise a l'inscription (Priority: P1)

Un nouvel utilisateur s'inscrit sur K-Budget. Lors de la creation de son compte, il choisit sa devise principale parmi les devises disponibles (EUR, XOF, USD, GBP, CHF, CAD, MAD). Le compte bancaire par defaut ("Compte Principal") et les preferences utilisateur sont automatiquement initialises avec cette devise.

**Why this priority**: C'est le coeur de la feature. Un utilisateur au Togo qui s'inscrit se retrouve aujourd'hui avec un compte en EUR et doit reconfigurer manuellement sa devise dans les parametres, ses comptes et ses preferences. Ce parcours est casse pour tout utilisateur non-EUR.

**Independent Test**: Creer un compte avec la devise XOF et verifier que le Compte Principal est en XOF et que la devise principale dans les preferences est XOF.

**Acceptance Scenarios**:

1. **Given** un visiteur sur la page d'inscription, **When** il remplit le formulaire et selectionne XOF comme devise, **Then** son compte est cree, son Compte Principal est en XOF, et ses preferences ont `currencies = [XOF]`.
2. **Given** un visiteur sur la page d'inscription, **When** il remplit le formulaire sans choisir de devise (champ non modifie), **Then** son compte est cree avec le Compte Principal en EUR et les preferences en EUR (comportement retrocompatible).
3. **Given** un visiteur sur la page d'inscription, **When** il selectionne une devise puis soumet le formulaire, **Then** le selecteur de devise affiche le symbole et le nom de la devise choisie.

---

### User Story 2 - Detection automatique du fuseau horaire (Priority: P2)

Lors de l'inscription, le fuseau horaire de l'utilisateur est detecte automatiquement par le client (navigateur ou application mobile) et envoye silencieusement au serveur. Aucun champ de formulaire n'est affiche pour le fuseau horaire. Les preferences utilisateur sont initialisees avec ce fuseau horaire.

**Why this priority**: Le fuseau horaire impacte l'affichage des dates et les notifications planifiees (rappels de dettes, recurrences). Un utilisateur en Africa/Lome avec le defaut Europe/Paris recoit des notifications decalees d'1h. L'impact est moindre que la devise mais ameliore la precision des le premier jour.

**Independent Test**: S'inscrire depuis un navigateur configure en Africa/Lome et verifier que les preferences ont timezone = "Africa/Lome" sans aucune action manuelle de l'utilisateur.

**Acceptance Scenarios**:

1. **Given** un visiteur dont le navigateur/device est configure en "Africa/Lome", **When** il s'inscrit, **Then** ses preferences sont creees avec `timezone = "Africa/Lome"`.
2. **Given** un visiteur dont la detection de timezone echoue (navigateur ancien ou API indisponible), **When** il s'inscrit, **Then** ses preferences sont creees avec `timezone = "Europe/Paris"` (fallback).
3. **Given** un visiteur inscrit avec un timezone detecte, **When** il consulte ses parametres apres inscription, **Then** il voit le fuseau horaire correct sans avoir eu a le configurer.

---

### User Story 3 - Retrocompatibilite de l'inscription (Priority: P1)

Les clients existants (anciennes versions de l'app mobile ou du frontend) qui n'envoient pas les nouveaux champs (devise, timezone) doivent continuer a fonctionner sans erreur. L'inscription se comporte comme avant : devise EUR, timezone Europe/Paris.

**Why this priority**: P1 car un breaking change sur l'inscription empecherait les utilisateurs de s'inscrire depuis des clients non mis a jour.

**Independent Test**: Envoyer une requete d'inscription avec uniquement email/password/name (sans currency ni timezone) et verifier que le compte est cree normalement avec les defauts EUR / Europe/Paris.

**Acceptance Scenarios**:

1. **Given** un client qui envoie `{ email, password, name }` sans champ `currency` ni `timezone`, **When** la requete d'inscription est traitee, **Then** le compte est cree avec Compte Principal en EUR et preferences `currencies=[EUR], timezone="Europe/Paris"`.
2. **Given** un client qui envoie `{ email, password, name, currency: "XOF" }` sans champ `timezone`, **When** la requete d'inscription est traitee, **Then** le compte est cree avec Compte Principal en XOF, preferences `currencies=[XOF], timezone="Europe/Paris"`.

---

### Edge Cases

- Que se passe-t-il si le client envoie une valeur de devise invalide (ex: "BTC") ? Le serveur rejette avec une erreur de validation.
- Que se passe-t-il si le client envoie un timezone invalide (ex: "Mars/Olympus") ? Le serveur ignore et utilise le fallback "Europe/Paris".
- Que se passe-t-il si le client envoie un timezone vide ou null ? Le serveur utilise le fallback "Europe/Paris".
- Le formulaire de connexion (login) n'est pas impacte -- aucun nouveau champ.
- Les utilisateurs deja inscrits avant cette feature ne sont pas concernes. Ils continuent de modifier leur devise et timezone manuellement dans les parametres existants.
- Le selecteur de timezone dans les parametres de notifications reste inchange. Il sert au calcul des rappels J-1 (abonnements, dettes, recurrences) et l'utilisateur peut toujours le modifier manuellement apres l'inscription.
- Le selecteur "Devise par defaut" dans le profil (web) est un champ fantome : le backend ignore la valeur envoyee (UserUpdateRequest n'a que `name`). Il est supprime et remplace par un lien vers "Devises & Taux".

## Requirements

### Functional Requirements

- **FR-001**: Le systeme DOIT accepter un champ optionnel `currency` dans la requete d'inscription, representant la devise principale choisie par l'utilisateur.
- **FR-002**: Le systeme DOIT accepter un champ optionnel `timezone` dans la requete d'inscription, representant le fuseau horaire detecte par le client.
- **FR-003**: Si `currency` est fourni et valide, le compte bancaire par defaut ("Compte Principal") DOIT etre cree avec cette devise.
- **FR-004**: Si `currency` est fourni et valide, les preferences utilisateur DOIVENT etre initialisees avec cette devise comme devise principale (`currencies = [devise choisie]`).
- **FR-005**: Si `currency` n'est pas fourni ou est null, le systeme DOIT utiliser EUR comme devise par defaut (retrocompatibilite).
- **FR-006**: Si `currency` contient une valeur invalide, le systeme DOIT rejeter la requete avec une erreur de validation.
- **FR-007**: Si `timezone` est fourni et valide (identifiant IANA reconnu), les preferences utilisateur DOIVENT etre initialisees avec ce fuseau horaire.
- **FR-008**: Si `timezone` n'est pas fourni, est null, est vide ou est invalide, le systeme DOIT utiliser "Europe/Paris" comme fuseau horaire par defaut.
- **FR-009**: Le formulaire d'inscription (web) DOIT afficher un selecteur de devise avec toutes les devises disponibles, pre-selectionne sur EUR, positionne apres le champ "Nom" et avant le champ "Email".
- **FR-010**: Le formulaire d'inscription (web) DOIT detecter le fuseau horaire du navigateur et l'inclure dans la requete sans champ visible.
- **FR-011**: Le formulaire d'inscription (mobile) DOIT afficher un selecteur de devise avec toutes les devises disponibles, pre-selectionne sur EUR, positionne apres le champ "Nom" et avant le champ "Email".
- **FR-012**: Le formulaire d'inscription (mobile) DOIT detecter le fuseau horaire du device et l'inclure dans la requete sans champ visible.
- **FR-013**: Les preferences utilisateur DOIVENT etre creees lors de l'inscription (et non a la premiere consultation lazy) avec les valeurs currency et timezone fournies.
- **FR-014**: Le selecteur "Devise par defaut" dans la page Profil (web) DOIT etre supprime et remplace par un lien de navigation vers la page "Devises & Taux" (seul point d'entree pour la gestion des devises).

### Key Entities

- **RegisterRequest** : Requete d'inscription enrichie avec `currency` (devise choisie, optionnel) et `timezone` (fuseau horaire detecte, optionnel).
- **Account (Compte Principal)** : Compte par defaut cree a l'inscription dont la devise est desormais determinee par le choix de l'utilisateur.
- **UserPreference** : Preferences utilisateur dont `currencies` et `timezone` sont initialises des l'inscription avec les valeurs fournies.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Un utilisateur non-EUR peut s'inscrire et avoir un environnement pret a l'emploi dans sa devise en 0 etape de configuration supplementaire (contre 3 etapes aujourd'hui).
- **SC-002**: 100% des inscriptions depuis des clients mis a jour transmettent automatiquement le fuseau horaire correct sans intervention de l'utilisateur.
- **SC-003**: 100% des inscriptions depuis des clients non mis a jour (sans les nouveaux champs) continuent de fonctionner sans erreur avec les defauts EUR / Europe/Paris.
- **SC-004**: Le formulaire d'inscription reste completable en moins de 60 secondes (ajout d'un seul champ visuel : la devise).

## Assumptions

- L'enum Currency existante (7 devises) couvre les besoins actuels. Aucune nouvelle devise n'est ajoutee dans cette feature.
- La validation du timezone cote serveur se fait via les identifiants IANA standard.
- La detection du timezone cote web utilise `Intl.DateTimeFormat().resolvedOptions().timeZone`.
- La detection du timezone cote mobile utilise l'API native du device.
- Le selecteur de devise dans le formulaire affiche le symbole et le nom complet (ex: "CFA - Franc CFA (BCEAO)").
- La creation de UserPreference a l'inscription remplace la creation lazy actuelle pour les nouveaux utilisateurs -- la methode lazy reste comme fallback pour les utilisateurs existants.
