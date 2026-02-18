# Feature Specification: Flutter Setup & Architecture

**Feature Branch**: `031-flutter-setup`
**Created**: 2026-02-18
**Status**: Draft
**Input**: User description: "V3 Phase 1 — Flutter Setup & Architecture : Initialisation du projet Flutter et mise en place de l'architecture fondamentale."

## Clarifications

### Session 2026-02-18

- Q: En mode local (pas de login), faut-il une protection d'acces a l'app ? → A: Verrouillage biometrique/PIN optionnel au lancement, configurable par l'utilisateur.
- Q: En mode serveur, l'utilisateur peut-il creer un compte depuis l'app ou uniquement se connecter ? → A: Inscription par invitation uniquement. L'admin envoie un lien d'inscription par email a l'adresse du futur utilisateur. Le lien a une duree de validite definie. L'utilisateur clique sur le lien, est redirige vers l'app et complete son inscription.
- Q: Quelle approche de gestion d'etat pour l'app Flutter ? → A: Riverpod (gestion d'etat + DI, type, testable).
- Q: Quelle base de donnees locale pour le mode offline ? → A: Drift (SQL type, migrations versionnees, relationnel, multi-plateforme).
- Q: Les donnees locales doivent-elles etre chiffrees au repos ? → A: Non, on s'appuie sur le chiffrement natif de l'OS + verrouillage app (biometrie/PIN).
- Q: Quelle strategie de localisation pour l'app ? → A: Francais uniquement, mais infrastructure i18n en place (fichiers ARB) pour extensibilite future.
- Q: Quelle strategie de crash reporting / observabilite ? → A: Firebase Crashlytics (gratuit, natif Flutter, iOS + Android). Web: erreurs capturees cote serveur.
- Q: Ou placer le projet Flutter dans le monorepo ? → A: Nouveau dossier `flutter/` a la racine (coexistence avec `app/` Angular pendant la transition). Nom neutre car Flutter couvre mobile et web.
- Q: Quelles versions minimales des plateformes cibles ? → A: iOS 15+ / Android API 24 (7.0). Bon compromis couverture (appareils au Togo) et acces aux API modernes.
- Q: Quel package de navigation/routing ? → A: `go_router` (officiel Flutter, declaratif, deep links natifs, bon support Riverpod).
- Q: Quel client HTTP pour la couche API (mode serveur) ? → A: `dio` (intercepteurs pour JWT refresh transparent, logging, cancel tokens).
- Q: Quel stockage securise pour les donnees sensibles (tokens JWT, PIN hashe) ? → A: `flutter_secure_storage` (Keychain iOS, EncryptedSharedPreferences Android, localStorage web).
- Q: Les 4 sections de navigation doivent-elles etre des ecrans fonctionnels complets ou des shells architecturaux ? → A: Shells architecturaux (ecrans placeholder avec donnees mockees prouvant routing, layout et theme). Les ecrans CRUD complets seront developpes dans des features dediees ulterieures.
- Q: Quelle strategie d'identifiants pour les entites en mode local (base Drift) ? → A: UUID v4 generes cote client (compatibles avec le schema serveur existant, prets pour une future sync).
- Q: Quelle strategie de deploiement pour le build Flutter Web ? → A: Sous-domaine dedie (`flutter.budget.kksdev.fr`). Isolation totale, deploiement independant de l'Angular existant, migration progressive par bascule DNS.
- Q: Quel format d'URI pour les deep links d'invitation ? → A: Universal Links (iOS) / App Links (Android) sur le domaine existant (`budget.kksdev.fr/invite/xxx`). Ouverture directe dans l'app, fallback web si non installee.
- Q: A quel seuil de largeur la navigation bascule de barre en bas vers sidebar ? → A: 768px (breakpoint tablette standard Material Design medium).
- Q: Quelle strategie de test pour le projet Flutter en Phase 1 ? → A: Unit tests + widget tests + integration tests (flux complet onboarding → navigation). Couverture complete des 3 niveaux de test.
- Q: Comment gerer les environnements (dev/prod) dans le projet Flutter ? → A: `--dart-define` / `--dart-define-from-file` (fichiers .env par environnement, pas de flavor natif). Leger et suffisant pour 2 environnements.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Choix du mode de donnees au premier lancement (Priority: P1)

Au premier lancement de l'application, l'utilisateur est accueilli par un ecran d'onboarding qui lui propose de choisir comment ses donnees seront stockees. Deux options sont presentees :

- **Mode local** : les donnees restent sur l'appareil, aucun compte ni serveur requis. Ideal pour un usage simple et prive. L'utilisateur peut activer un verrouillage biometrique ou PIN pour proteger l'acces a l'app.
- **Mode serveur** : l'utilisateur se connecte a un serveur K-Budget (auto-heberge). Les donnees sont stockees sur le serveur via l'API existante. Necessite une URL de serveur et des identifiants. L'inscription se fait uniquement par invitation (lien envoye par l'admin).

Ce choix est fait une seule fois. L'utilisateur peut le modifier ulterieurement depuis les parametres.

**Why this priority**: Sans ce choix fondamental, l'application ne peut pas fonctionner. C'est le point d'entree de toute l'experience utilisateur et la decision architecturale qui conditionne tout le reste.

**Independent Test**: Peut etre teste en lancant l'app pour la premiere fois et en verifiant que le choix est propose, que chaque mode est selectionnable, et que le choix est persiste.

**Acceptance Scenarios**:

1. **Given** l'application est lancee pour la premiere fois, **When** l'ecran d'onboarding s'affiche, **Then** les deux modes (local et serveur) sont presentes avec une description claire de chacun.
2. **Given** l'utilisateur choisit le mode local, **When** il confirme son choix, **Then** l'application demarre avec un stockage local sur l'appareil, sans demande de connexion.
3. **Given** l'utilisateur choisit le mode serveur, **When** il saisit l'URL du serveur, **Then** l'application verifie la connectivite avec le serveur avant de continuer.
4. **Given** l'utilisateur a choisi le mode serveur et le serveur est joignable, **When** il saisit ses identifiants, **Then** il est authentifie et accede a l'application.
5. **Given** l'utilisateur a deja fait son choix lors d'un lancement precedent, **When** il relance l'application, **Then** l'onboarding est saute et le mode precedemment choisi est utilise.
6. **Given** l'utilisateur a choisi le mode local, **When** il configure un verrouillage biometrique/PIN, **Then** a chaque ouverture de l'app il doit s'authentifier via biometrie ou PIN avant d'acceder a ses donnees.
7. **Given** un utilisateur recoit un lien d'invitation par email, **When** il clique sur le lien, **Then** l'application s'ouvre sur l'ecran d'inscription avec l'URL du serveur pre-remplie.

---

### User Story 2 - Navigation et structure de l'application (Priority: P1)

L'utilisateur accede aux differentes sections de l'application via une barre de navigation en bas de l'ecran (mobile) ou une sidebar (ecrans larges). Les sections principales sont : Accueil (dashboard), Transactions, Abonnements, Dettes. Un bouton d'action flottant (+) est accessible depuis toutes les sections pour creer rapidement une nouvelle entree. En Phase 1, ces sections sont des shells architecturaux (ecrans placeholder avec donnees mockees) prouvant le routing, le layout et le theming. Les ecrans CRUD complets seront developpes dans des features dediees ulterieures.

**Why this priority**: La navigation est le squelette de l'application. Sans elle, aucun ecran fonctionnel ne peut etre atteint ni teste.

**Independent Test**: Peut etre teste en verifiant que chaque onglet de navigation mene a l'ecran correspondant et que le bouton flottant est visible et fonctionnel.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est authentifie ou en mode local, **When** l'application se charge, **Then** la barre de navigation affiche les 4 sections (Accueil, Transactions, Abonnements, Dettes).
2. **Given** l'utilisateur est sur un ecran quelconque, **When** il tape sur un onglet de navigation, **Then** il est redirige vers la section correspondante.
3. **Given** l'utilisateur est sur un ecran de liste, **When** il tape sur le bouton flottant (+), **Then** un menu rapide propose la creation d'une transaction, d'un abonnement ou d'une dette.
4. **Given** l'utilisateur est sur un ecran large (tablette, web), **When** l'application s'affiche, **Then** la navigation est presentee sous forme de sidebar laterale plutot qu'une barre en bas.

---

### User Story 3 - Coherence visuelle avec l'application existante (Priority: P2)

L'application Flutter reprend l'identite visuelle de K-Budget : palette de couleurs Amber (primaire), palette Gray (neutres), police Inter, themes clair et sombre, tokens de design (espacement, bordures, ombres, typographie). L'utilisateur qui utilisait la version web retrouve une experience visuelle familiere.

**Why this priority**: La coherence visuelle assure une transition fluide pour les utilisateurs existants. Moins critique que la navigation mais essentiel pour la qualite percue.

**Independent Test**: Peut etre teste en comparant visuellement l'application Flutter avec la version Angular sur les memes ecrans, en verifiant les tokens de couleurs, espacement et typographie.

**Acceptance Scenarios**:

1. **Given** l'application est lancee en theme clair, **When** l'utilisateur regarde l'interface, **Then** les couleurs, polices et espacements correspondent au design system existant (Amber primaire, Gray neutres, Inter).
2. **Given** l'application est lancee en theme sombre, **When** l'utilisateur regarde l'interface, **Then** le theme sombre utilise les memes tokens semantiques que la version web (contrastes adaptes pour le mode sombre).
3. **Given** l'utilisateur change le theme dans les parametres, **When** le theme est applique, **Then** toute l'interface bascule instantanement sans rechargement.

---

### User Story 4 - Fonctionnement hors-ligne en mode local (Priority: P2)

En mode local, l'application fonctionne entierement sans connexion internet. Toutes les donnees sont stockees sur l'appareil. L'utilisateur peut creer, consulter, modifier et supprimer ses donnees financieres sans aucune dependance reseau.

**Why this priority**: Le mode local est un des deux piliers de l'architecture donnees. Il doit fonctionner parfaitement offline, surtout pour les utilisateurs au Togo ou la connectivite peut etre intermittente.

**Independent Test**: Peut etre teste en activant le mode avion et en verifiant que toutes les operations CRUD fonctionnent.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est en mode local et sans connexion internet, **When** il cree une transaction, **Then** la transaction est enregistree localement et visible immediatement.
2. **Given** l'utilisateur est en mode local, **When** il consulte ses donnees, **Then** toutes les donnees sont lues depuis le stockage local sans tentative de requete reseau.
3. **Given** l'utilisateur est en mode local, **When** il supprime ou modifie une entree, **Then** la modification est persistee localement immediatement.

---

### User Story 5 - Connexion au serveur existant (Priority: P2)

En mode serveur, l'application se connecte au backend Spring Boot existant via l'API REST. L'authentification utilise le mecanisme JWT existant (access token + refresh token). L'inscription de nouveaux utilisateurs se fait uniquement par invitation : l'admin envoie un lien par email, le destinataire clique et complete son inscription dans l'app. Le lien a une duree de validite definie.

**Why this priority**: Le mode serveur permet aux utilisateurs actuels (6+ proches) de continuer a utiliser leur instance existante avec la nouvelle application.

**Independent Test**: Peut etre teste en pointant l'application vers un serveur K-Budget existant et en verifiant que login, lecture et ecriture de donnees fonctionnent.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est en mode serveur, **When** il se connecte avec ses identifiants, **Then** il recoit un access token et un refresh token, et accede a ses donnees.
2. **Given** l'access token a expire, **When** l'utilisateur effectue une action, **Then** le refresh token est utilise automatiquement pour renouveler la session sans intervention utilisateur.
3. **Given** le serveur est temporairement injoignable, **When** l'utilisateur tente une action, **Then** un message clair indique le probleme de connexion.
4. **Given** l'utilisateur se deconnecte, **When** il confirme, **Then** les tokens sont supprimes et l'ecran de connexion est affiche.
5. **Given** l'admin envoie une invitation a une adresse email, **When** le destinataire clique sur le lien dans l'email, **Then** l'app s'ouvre sur un ecran d'inscription avec le serveur pre-configure.
6. **Given** un lien d'invitation a expire, **When** le destinataire clique dessus, **Then** un message indique que l'invitation n'est plus valide et invite a contacter l'admin.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur choisit le mode serveur mais que le serveur est injoignable au premier lancement ? L'application affiche un message d'erreur avec la possibilite de reessayer ou de revenir au choix du mode.
- Que se passe-t-il si l'utilisateur en mode serveur perd sa connexion en cours d'utilisation ? Les actions en cours echouent avec un message explicite. Pas de file d'attente offline (hors scope Phase 1).
- Que se passe-t-il si l'utilisateur change de mode (local vers serveur ou inversement) ? Les donnees du mode precedent ne sont pas migrees automatiquement. L'utilisateur est averti de cette consequence avant confirmation.
- Que se passe-t-il sur un appareil avec tres peu d'espace de stockage en mode local ? L'application s'appuie sur les mecanismes natifs du systeme pour gerer l'espace. Pas de gestion specifique en Phase 1.
- Que se passe-t-il si le serveur utilise une version d'API incompatible ? L'application verifie la version de l'API au premier contact et avertit l'utilisateur en cas d'incompatibilite.
- Que se passe-t-il si l'utilisateur en mode local oublie son PIN ? L'app propose une reinitialisation qui efface les donnees locales (seul moyen sans serveur de recuperation). L'utilisateur est averti avant confirmation.
- Que se passe-t-il si le lien d'invitation est ouvert sur un appareil sans l'app installee ? Le lien redirige vers la page de telechargement de l'app (App Store / Play Store / web).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: L'application DOIT proposer un ecran d'onboarding au premier lancement permettant de choisir entre le mode local et le mode serveur.
- **FR-002**: Le choix du mode de donnees DOIT etre persiste sur l'appareil et reutilise aux lancements suivants.
- **FR-003**: En mode local, l'application DOIT stocker toutes les donnees financieres localement sur l'appareil, sans aucune requete reseau.
- **FR-004**: En mode serveur, l'application DOIT communiquer avec le backend Spring Boot existant via son API REST.
- **FR-005**: En mode serveur, l'application DOIT gerer l'authentification JWT (access token + refresh token) conformement au mecanisme existant.
- **FR-006**: L'application DOIT offrir une navigation principale vers 4 sections : Accueil, Transactions, Abonnements, Dettes.
- **FR-007**: La navigation DOIT s'adapter au format de l'ecran : barre en bas sur mobile (< 768px), sidebar laterale sur ecrans larges (>= 768px).
- **FR-008**: Un bouton d'action flottant (+) DOIT etre visible sur toutes les sections de liste et proposer la creation rapide d'une transaction, d'un abonnement ou d'une dette.
- **FR-009**: L'application DOIT supporter deux themes visuels (clair et sombre) utilisant les tokens de design existants de K-Budget.
- **FR-010**: L'application DOIT fonctionner sur trois plateformes : iOS, Android et Web.
- **FR-011**: L'utilisateur DOIT pouvoir modifier son choix de mode de donnees depuis les parametres, avec un avertissement que les donnees ne seront pas migrees.
- **FR-012**: En mode serveur, l'application DOIT gerer proprement la perte de connexion avec un message explicite a l'utilisateur.
- **FR-013**: L'application DOIT verifier la connectivite avec le serveur lors de la configuration du mode serveur, avant de permettre la connexion.
- **FR-014**: L'acces aux donnees DOIT etre abstrait derriere une couche commune, de sorte que les ecrans fonctionnels ne dependent pas du mode de stockage choisi.
- **FR-015**: En mode local, l'application DOIT proposer un verrouillage optionnel par biometrie (empreinte, Face ID) ou code PIN au lancement.
- **FR-016**: En mode serveur, l'inscription de nouveaux utilisateurs DOIT se faire uniquement via un lien d'invitation envoye par email par l'admin, avec une duree de validite de 7 jours (configurable cote backend).
- **FR-017**: L'application DOIT gerer les liens d'invitation via Universal Links (iOS) / App Links (Android) sur le domaine `budget.kksdev.fr/invite/{token}` : ouvrir l'ecran d'inscription avec le serveur pre-configure lorsqu'un lien valide est clique.
- **FR-018**: *(Hors-scope Phase 1)* Si le lien d'invitation (`budget.kksdev.fr/invite/{token}`) est ouvert sur un appareil sans l'app, le fallback web DEVRAIT rediriger l'utilisateur vers la page de telechargement appropriee (App Store, Play Store ou version web Flutter). En Phase 1, le lien ouvre la version web Flutter (`flutter.budget.kksdev.fr`) comme fallback naturel.

### Key Entities

- **AppConfig** : Configuration persistee de l'application. Contient le mode de donnees choisi (local ou serveur), l'URL du serveur (si mode serveur), le theme selectionne (clair/sombre), le verrouillage biometrique/PIN active (oui/non).
- **Invitation** : *(Backend-only, geree par l'API)* Lien d'inscription envoye par l'admin (mode serveur uniquement). Contient l'adresse email du destinataire, le token d'invitation, la date d'expiration, le statut (en attente/utilise/expire). Cote Flutter, seul le token est consomme via deep link pour pre-remplir l'ecran d'inscription.
- **Transaction** : Operation financiere (depense ou recette). Montant, libelle, type, date, categorie, compte, note. Port de l'entite existante.
- **Subscription** : Depense recurrente. Nom, montant, frequence (mensuel/annuel), date de debut, actif, categorie, compte, devise (Currency). Port de l'entite existante.
- **Debt** : Emprunt ou pret. Personne, montant, sens (emprunt/pret), date, rembourse, categorie, devise (Currency). Port de l'entite existante.
- **Category** : Categorie de classification. Nom, icone, couleur, systeme (oui/non). Port de l'entite existante.
- **Account** : Compte bancaire. Nom, type (courant/epargne/especes), solde initial, icone, couleur, defaut, actif, devise (Currency). Port de l'entite existante.
- **User** : Utilisateur (mode serveur uniquement). Email, nom, devise par defaut (Currency). Port de l'entite existante.
- **DataRepository** : Couche d'abstraction donnees. Interface commune que les deux modes (local et serveur) implementent. Expose les operations CRUD pour toutes les entites metier. Toutes les entites utilisent des UUID v4 comme identifiants (generes cote client en mode local, coherents avec le schema serveur existant).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'application se lance et affiche l'ecran d'onboarding en moins de 3 secondes sur un appareil milieu de gamme.
- **SC-002**: En mode local, toutes les operations de lecture et d'ecriture s'executent en moins de 200 millisecondes percues par l'utilisateur.
- **SC-003**: En mode serveur, l'application se connecte et affiche les donnees de l'utilisateur en moins de 5 secondes sur une connexion 3G.
- **SC-004**: L'application fonctionne de maniere identique sur iOS, Android et Web pour toutes les fonctionnalites de base (navigation, theme, onboarding).
- **SC-005**: L'application Flutter utilise les memes tokens de design que la version Angular : couleur primaire Amber (#f59e0b), police Inter, palette Gray, et les memes tokens d'espacement (grille 4px), bordures et ombres.
- **SC-006**: Le changement de theme (clair vers sombre et inversement) est instantane (moins de 100 millisecondes).
- **SC-007**: L'utilisateur peut completer l'onboarding et acceder a l'ecran principal en moins de 30 secondes (mode local) ou 60 secondes (mode serveur, hors temps de creation de compte).

## Assumptions

- Le backend Spring Boot existant necessitera des modifications mineures pour supporter le systeme d'invitation (nouveaux endpoints : creation d'invitation, validation de token, envoi d'email). Ces modifications backend seront traitees comme une tache distincte dans la planification.
- Les utilisateurs actuels (Togo et France) ont des appareils Android milieu de gamme ou des iPhones recents. Le support des appareils tres bas de gamme n'est pas un objectif de cette phase.
- La migration de donnees entre la version PWA et la version Flutter n'est pas dans le scope. Les utilisateurs en mode serveur retrouveront leurs donnees via le serveur existant.
- Le mode local ne propose pas de synchronisation entre appareils en Phase 1. C'est un stockage purement local.
- La police Inter est disponible et bundlee dans l'application (pas de dependance Google Fonts runtime).
- L'ecran Settings existant sera porte dans une phase ulterieure (V3 Phase 2). En Phase 1, seul le changement de theme, le verrouillage biometrique/PIN et le changement de mode de donnees sont accessibles dans les parametres.
- Les 4 sections de navigation (Accueil, Transactions, Abonnements, Dettes) sont des shells architecturaux en Phase 1 : ecrans placeholder avec donnees mockees demontrant le routing, le layout responsive et le theming. Les ecrans CRUD fonctionnels seront developpes dans des features dediees ulterieures.
- Le verrouillage biometrique/PIN utilise les capacites natives de l'appareil (Touch ID/Face ID sur iOS, BiometricPrompt sur Android). Sur le web, seul le PIN est disponible.
- Le projet Flutter est place dans le dossier `flutter/` a la racine du monorepo, aux cotes de `api/` et `app/`. Les deux frontends (Angular et Flutter) coexistent pendant la phase de transition. Le build Flutter Web est deploye sur un sous-domaine dedie (`flutter.budget.kksdev.fr`), isole de l'Angular existant (`budget.kksdev.fr`). La migration se fera par bascule DNS quand Flutter sera pret.
- Versions minimales des plateformes : iOS 15+, Android API 24 (7.0). Web : navigateurs evergreen (Chrome, Firefox, Safari, Edge dernières versions).
- La navigation utilise `go_router` (package officiel Flutter). Il fournit le routing declaratif, les deep links natifs (necessaires pour les invitations), les redirections (auth guards), et s'integre bien avec Riverpod.
- Le client HTTP utilise `dio`. Ses intercepteurs natifs permettent le refresh JWT transparent, le logging des requetes, et la gestion fine des timeouts et annulations.
- Les donnees sensibles (JWT tokens, PIN hashe, config de verrouillage) sont stockees via `flutter_secure_storage` (Keychain sur iOS, EncryptedSharedPreferences sur Android, localStorage sur web).
- La gestion d'etat utilise Riverpod (flutter_riverpod). Riverpod sert egalement de mecanisme d'injection de dependances pour l'abstraction DataRepository et les services.
- La base de donnees locale utilise Drift (anciennement Moor). Drift fournit un modele relationnel type avec migrations versionnees, coherent avec le schema PostgreSQL du backend. Supporte iOS, Android et Web (via sql.js).
- Pas de chiffrement applicatif des donnees locales. La protection repose sur le chiffrement natif de l'OS (iOS Data Protection, Android FBE) et le verrouillage biometrique/PIN de l'application.
- L'interface est en francais uniquement en Phase 1. L'infrastructure i18n (flutter_localizations, fichiers ARB) est mise en place des le debut pour permettre l'ajout de langues ulterieurement sans refactoring.
- Le crash reporting utilise Firebase Crashlytics pour iOS et Android. Sur le web, les erreurs sont capturees via les mecanismes existants cote serveur. Pas d'analytics utilisateur en Phase 1.
- La strategie de test couvre les 3 niveaux : unit tests (services, repositories, providers Riverpod), widget tests (ecrans cles : onboarding, navigation shell), et integration tests (flux complet onboarding vers navigation). La structure de test et les dependances (mockito, flutter_test, integration_test) sont mises en place des le setup initial.
- La gestion des environnements utilise `--dart-define` / `--dart-define-from-file` avec des fichiers de configuration par environnement (ex: `.env.dev`, `.env.prod`). Pas de flavors natifs (iOS schemes, Android productFlavors). Les variables d'environnement incluent au minimum : l'URL de l'API, la configuration Firebase (project ID, etc.), et le flag mode debug.
