# Feature Specification: Alignement Settings Angular sur Flutter

**Feature Branch**: `098-angular-settings-alignment`
**Created**: 2026-03-20
**Status**: Draft
**Input**: Aligner la page Settings Angular sur le modele Flutter : hub avec 3 groupes (General, Gestion, Autre), couleurs d'icones variees par item, reordonnement des sections, ajout "Securite" placeholder, retrait "Budget" du hub. Enrichir la page "A propos" avec statut serveur, stats dynamiques et contact.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Hub Settings groupe et colore (Priority: P1)

L'utilisateur ouvre la page Parametres et voit les sections organisees en 3 groupes distincts avec des headers visuels ("General", "Gestion", "Autre"), chaque section ayant une couleur d'icone propre. L'ordre des sections correspond a celui de l'app Flutter. Le placeholder "Budget" a disparu (accessible via la navigation principale). Un nouveau placeholder "Securite" est visible dans le groupe "Autre".

**Why this priority**: Le hub est le point d'entree unique vers tous les reglages. Son organisation impacte directement la navigation et la coherence cross-plateforme.

**Independent Test**: Peut etre teste en ouvrant /settings et en verifiant visuellement les 3 groupes, l'ordre des items, les couleurs d'icones et les placeholders.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur /settings, **When** la page se charge, **Then** les sections sont affichees en 3 groupes avec headers "General", "Gestion", "Autre"
2. **Given** l'utilisateur est sur /settings, **When** il regarde les icones, **Then** chaque section a une couleur d'icone distincte (bleu, vert, violet, amber, teal, orange, amber, indigo, rouge, gris)
3. **Given** l'utilisateur est sur /settings, **When** il cherche "Budget", **Then** la section Budget n'apparait plus dans le hub
4. **Given** l'utilisateur est sur /settings, **When** il regarde le groupe "Autre", **Then** il voit "Securite" comme placeholder avec badge "A venir" et "A propos" actif
5. **Given** l'utilisateur est sur /settings, **When** il compare l'ordre avec Flutter, **Then** l'ordre est identique : Profil, Fonctionnalites & Navigation, Apparence, Notifications / Comptes, Categories, Devises & Taux, Donnees / Securite, A propos

---

### User Story 2 - Page A propos enrichie (Priority: P2)

L'utilisateur ouvre la page "A propos" et voit 3 cards : une card "Application" avec le nom, la version, un indicateur de statut serveur (en ligne/hors ligne) et le badge environnement (Production/Dev), une card "Mes donnees" avec une grille 2x2 montrant le nombre de transactions, comptes, abonnements et dettes, et une card "Contact" avec le nom de l'auteur et un lien email.

**Why this priority**: Enrichit une page existante basique (3 lignes statiques) pour offrir des informations utiles sans creer de nouvelles pages.

**Independent Test**: Peut etre teste en ouvrant /settings/about et en verifiant que les 3 cards affichent les bonnes informations dynamiques.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur /settings/about, **When** la page se charge, **Then** il voit 3 cards : Application, Mes donnees, Contact
2. **Given** le serveur est accessible, **When** l'utilisateur regarde la card Application, **Then** il voit le nom "K-Budget", la version courante, un pill vert "En ligne" et un badge "Production" ou "Dev"
3. **Given** le serveur n'est pas accessible, **When** l'utilisateur regarde la card Application, **Then** le pill affiche "Hors ligne" en rouge
4. **Given** l'utilisateur a des donnees existantes, **When** il regarde la card "Mes donnees", **Then** il voit 4 compteurs avec les vrais nombres de transactions, comptes, abonnements et dettes
5. **Given** l'utilisateur regarde la card Contact, **When** il clique sur le contact, **Then** un mailto s'ouvre vers l'adresse de l'auteur

---

### Edge Cases

- Que se passe-t-il si le health check echoue au chargement ? Le pill affiche "Hors ligne" en rouge, pas d'erreur bloquante.
- Que se passe-t-il si un service de comptage echoue ? Le compteur affiche un tiret comme fallback.
- Que se passe-t-il si l'utilisateur clique sur "Securite" (placeholder) ? Navigation vers la page Placeholder generique affichant "A venir" (meme comportement que l'ancien placeholder Budget).
- Que se passe-t-il en dark mode ? Les couleurs d'icones, les pills et les badges s'adaptent au theme sombre via les tokens existants.

## Requirements *(mandatory)*

### Functional Requirements

**Hub Settings**
- **FR-001**: Le hub DOIT afficher les sections regroupees en 3 categories avec headers visuels : "General", "Gestion", "Autre"
- **FR-002**: Chaque section DOIT avoir une couleur d'icone propre, alignee sur Flutter : Profil (bleu), Fonctionnalites & Navigation (vert), Apparence (violet), Notifications (amber), Comptes (teal), Categories (orange), Devises (amber), Donnees (indigo), Securite (rouge), A propos (gris)
- **FR-003**: L'ordre des sections DOIT correspondre a celui de Flutter : General (Profil, Fonctionnalites & Navigation, Apparence, Notifications) > Gestion (Comptes, Categories, Devises & Taux, Donnees) > Autre (Securite, A propos)
- **FR-004**: La section "Budget" DOIT etre retiree du hub (accessible uniquement via la navigation principale)
- **FR-005**: La section "Securite" DOIT etre ajoutee comme placeholder dans le groupe "Autre" avec badge "A venir" et route vers la page Placeholder generique (meme pattern que l'ancien Budget)
- **FR-006**: La section "A propos" DOIT rester active (navigable) dans le groupe "Autre"
- **FR-007**: L'interface DOIT etre compatible dark mode et light mode via les tokens existants

**Page A propos**
- **FR-008**: La page DOIT afficher 3 cards empilees verticalement : Application, Mes donnees, Contact
- **FR-009**: La card Application DOIT afficher le nom de l'app, la version, un indicateur de statut serveur (pill "En ligne" vert ou "Hors ligne" rouge) et un badge environnement
- **FR-010**: L'indicateur de statut serveur DOIT utiliser le service de health check existant
- **FR-011**: La card "Mes donnees" DOIT afficher une grille 2x2 avec les compteurs dynamiques : nombre de transactions, comptes, abonnements, dettes
- **FR-012**: Les compteurs DOIVENT etre recuperes depuis les services existants
- **FR-013**: La card Contact DOIT afficher le nom de l'auteur et un lien email cliquable (mailto)
- **FR-014**: En cas d'echec du health check, le pill DOIT afficher "Hors ligne" sans bloquer le reste de la page
- **FR-015**: En cas d'echec d'un compteur, la valeur DOIT afficher un fallback

### Key Entities

- **SettingsGroup**: Groupement des sections (General, Gestion, Autre) — nouveau concept cote Angular, existe deja cote Flutter
- **SettingsSection**: Structure existante enrichie avec une couleur d'icone et un groupe d'appartenance

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Le hub Settings Angular affiche les memes 3 groupes, le meme ordre et les memes couleurs d'icones que le hub Flutter
- **SC-002**: La page "A propos" affiche les 3 cards avec les donnees correctes en moins de 2 secondes
- **SC-003**: Le statut serveur se met a jour correctement (en ligne/hors ligne) au chargement de la page
- **SC-004**: Les 4 compteurs affichent les vraies donnees de l'utilisateur
- **SC-005**: Tous les tests unitaires existants continuent de passer apres les modifications
- **SC-006**: L'affichage est coherent en dark mode et en light mode

## Assumptions

- Le service HealthService existant (DataSettings) est reutilise pour le statut serveur de la page A propos
- Les services CRUD existants (TransactionService, AccountService, SubscriptionService, DebtService) exposent un moyen de recuperer le nombre total d'elements
- L'environnement (dev/prod) est determinable cote frontend
- La route /settings/budget est supprimee des routes Angular
- La section "Securite" utilise une route vers le composant Placeholder existant (meme pattern que l'ancien Budget)
