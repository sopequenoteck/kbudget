# Feature Specification: Settings Hub Flutter

**Feature Branch**: `034-flutter-settings-hub`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "Flutter: Settings hub refonte — Refonte page settings en grille de sections navigables: Profil, Apparence, Comptes, Catégories, (Sécurité, Données, À propos = placeholders). Ref: settings.html Angular. KKS-110"
**Linear**: KKS-110

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navigation vers une section de réglages active (Priority: P1)

En tant qu'utilisateur, j'accède à la page Réglages et je vois une liste verticale d'items groupés par section. J'appuie sur un item actif (Profil, Apparence, Comptes ou Catégories) et je suis redirigé vers la sous-page correspondante.

**Why this priority**: C'est la fonctionnalité centrale du hub — permettre la navigation vers les sous-pages de configuration. Sans cela, aucune section n'est accessible.

**Independent Test**: Peut être testé en affichant le hub et en vérifiant que chaque carte active navigue vers la bonne route.

**Acceptance Scenarios**:

1. **Given** la page Réglages affichée, **When** l'utilisateur la visualise, **Then** il voit 7 items en liste verticale avec icône, titre et description pour chaque section
2. **Given** la page Réglages affichée, **When** l'utilisateur appuie sur la carte "Comptes", **Then** il est redirigé vers la sous-page Comptes (`/settings/accounts`)
3. **Given** la page Réglages affichée, **When** l'utilisateur appuie sur la carte "Catégories", **Then** il est redirigé vers la sous-page Catégories (`/settings/categories`)
4. **Given** la page Réglages affichée, **When** l'utilisateur appuie sur la carte "Profil", **Then** il est redirigé vers la sous-page Profil (`/settings/profile`)
5. **Given** la page Réglages affichée, **When** l'utilisateur appuie sur la carte "Apparence", **Then** il est redirigé vers la sous-page Apparence (`/settings/appearance`)

---

### User Story 2 - Identification visuelle des sections placeholders (Priority: P2)

En tant qu'utilisateur, je distingue clairement les sections actives des sections à venir grâce à un badge "À venir" et un style visuel atténué sur les cartes placeholders. Appuyer dessus n'a aucun effet.

**Why this priority**: Informe l'utilisateur sur les fonctionnalités futures sans créer de frustration. Secondaire car ne bloque pas l'usage des sections actives.

**Independent Test**: Peut être testé en vérifiant que les cartes placeholders affichent le badge, ont un style distinct et ne déclenchent aucune navigation.

**Acceptance Scenarios**:

1. **Given** la page Réglages affichée, **When** l'utilisateur regarde les items "Sécurité" et "À propos", **Then** chaque item affiche un badge "À venir" et le style est visuellement atténué (opacité réduite)
2. **Given** un item placeholder affiché, **When** l'utilisateur appuie dessus, **Then** rien ne se passe (pas de navigation, pas de feedback tactile)

---

### User Story 3 - Cohérence visuelle et thème (Priority: P2)

En tant qu'utilisateur, la page Réglages s'affiche correctement en thème clair et sombre, avec des icônes dans des cercles colorés et une mise en page responsive.

**Why this priority**: L'application supporte déjà les deux thèmes. Le hub doit être visuellement cohérent avec le reste de l'application.

**Independent Test**: Peut être testé en basculant entre les thèmes et en vérifiant le rendu visuel des cartes.

**Acceptance Scenarios**:

1. **Given** le thème sombre activé, **When** la page Réglages est affichée, **Then** les cartes utilisent les couleurs de surface du thème sombre (fond, bordures, texte) sans couleur incohérente
2. **Given** la page Réglages affichée, **When** l'utilisateur fait défiler la page, **Then** la liste scrolle sans erreur de rendu et chaque item conserve son layout complet (icône, titre, description, chevron/badge)

---

### User Story 4 - Accessibilité de la page Réglages (Priority: P3)

En tant qu'utilisateur utilisant un lecteur d'écran, chaque carte de réglage est annoncée correctement avec son titre, sa description et son état (active ou à venir).

**Why this priority**: L'accessibilité est importante mais secondaire par rapport au rendu et à la navigation.

**Independent Test**: Peut être testé en vérifiant la sémantique des cartes via les tests de widget.

**Acceptance Scenarios**:

1. **Given** un lecteur d'écran actif, **When** une carte active est focalisée, **Then** le titre et la description sont annoncés, avec la sémantique "bouton"
2. **Given** un lecteur d'écran actif, **When** une carte placeholder est focalisée, **Then** le titre, la description et le statut "À venir" sont annoncés, sans sémantique "bouton"

---

### User Story 5 - Changement de source de données (Priority: P1)

En tant qu'utilisateur, j'accède à la sous-page Données et je peux basculer entre le mode local (SQLite) et le mode serveur (API REST). Un dialog de confirmation m'avertit avant le changement et l'app redémarre pour appliquer la nouvelle source.

**Why this priority**: Le choix de la source de données est fondamental pour le fonctionnement de l'app. L'utilisateur doit pouvoir choisir entre le mode hors-ligne et le mode connecté.

**Independent Test**: Peut être testé en vérifiant le dialog de confirmation, le changement de mode et le redémarrage.

**Acceptance Scenarios**:

1. **Given** la sous-page Données affichée, **When** l'utilisateur la visualise, **Then** il voit la source active actuelle (local ou serveur) clairement indiquée et un champ URL serveur (pré-rempli ou vide)
2. **Given** la sous-page Données avec mode "local" actif et URL serveur renseignée, **When** l'utilisateur sélectionne "serveur", **Then** un dialog de confirmation s'affiche expliquant les conséquences du changement
3. **Given** le dialog de confirmation affiché pour un switch vers serveur, **When** l'utilisateur confirme, **Then** un test de connectivité est effectué sur l'URL configurée, et si le serveur répond, la source est changée et l'app redémarre
4. **Given** le dialog de confirmation affiché, **When** l'utilisateur annule, **Then** rien ne change et il reste sur la sous-page Données
5. **Given** la sous-page Données avec URL serveur vide, **When** l'utilisateur tente de basculer vers "serveur", **Then** le switch est bloqué et le champ URL est mis en erreur avec un message de validation
6. **Given** le dialog de confirmation confirmé pour un switch vers serveur, **When** le test de connectivité échoue (serveur injoignable, timeout 10s), **Then** le switch est annulé, un message d'erreur "Serveur injoignable" est affiché et l'utilisateur reste sur la sous-page Données

---

### Edge Cases

- Que se passe-t-il quand une sous-page n'est pas encore implémentée mais que la carte est marquée active ? La navigation fonctionne vers la route définie (page vide/stub acceptable).
- Que se passe-t-il en orientation paysage ? La liste reste verticale et s'adapte à la largeur disponible.
- Que se passe-t-il si le texte de description est très long ? Il est tronqué avec ellipsis sur 2 lignes maximum.
- Que se passe-t-il si l'utilisateur change de source et que le serveur est injoignable ? Le changement vers serveur nécessite une connexion active ; un message d'erreur est affiché si le serveur n'est pas accessible.
- Que se passe-t-il si l'utilisateur est déjà sur la source sélectionnée ? Le sélecteur reste sur la valeur actuelle sans déclencher de dialog.
- Que se passe-t-il avec les données lors du changement de source ? Chaque source (local/serveur) est indépendante. Pas de synchronisation ni migration. Le dialog de confirmation avertit clairement que les données de l'autre source ne seront pas visibles après le changement.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La page DOIT afficher une liste verticale de 7 items de navigation groupés par catégories avec titres de section : "Général" (Profil, Apparence), "Gestion" (Comptes, Catégories, Données), "Autre" (Sécurité, À propos)
- **FR-002**: Chaque item DOIT afficher une Material Icon dans un cercle coloré, un titre et une description courte
- **FR-003**: Les items actifs (Profil, Apparence, Comptes, Catégories, Données) DOIVENT naviguer vers leur sous-page respective au tap avec un feedback visuel (ripple/splash)
- **FR-004**: Les items placeholders (Sécurité, À propos) DOIVENT afficher un badge "À venir" et être visuellement atténués (opacité réduite). Ils NE DOIVENT PAS être interactifs
- **FR-005**: La page DOIT afficher un titre "Réglages" dans l'AppBar
- **FR-006**: La page DOIT utiliser uniquement les design tokens du thème (couleurs, espacements, typographie, rayons)
- **FR-007**: La page DOIT supporter les thèmes clair et sombre via les tokens existants
- **FR-008**: La page DOIT être accessible (sémantique pour lecteur d'écran sur chaque carte)
- **FR-009**: La page DOIT remplacer l'écran de réglages Flutter existant (pas de nouvel onglet de navigation)
- **FR-010**: La sous-page Données DOIT afficher la source active (local/serveur) et permettre de basculer via un sélecteur
- **FR-011**: Le changement de source DOIT déclencher un dialog de confirmation avant application. Le dialog DOIT mentionner que les sources sont indépendantes et que les données de la source quittée ne seront pas visibles
- **FR-012**: Après confirmation du changement de source, l'app DOIT redémarrer pour appliquer la nouvelle source
- **FR-013**: La sous-page Données DOIT afficher un champ de saisie pour l'URL du serveur API. Le champ est pré-rempli si une URL est déjà enregistrée, sinon vide. L'URL DOIT être persistée localement (flutter_secure_storage)
- **FR-014**: Le switch vers le mode serveur NE DOIT PAS être possible si le champ URL est vide. Le champ DOIT valider le format URL (schéma https:// requis, http:// accepté en mode dev)
- **FR-015**: Avant le switch vers le mode serveur, un test de connectivité (HEAD request, timeout 10s) DOIT être effectué sur l'URL configurée. En cas d'échec, le switch est annulé et un message d'erreur "Serveur injoignable" est affiché

### Sections du hub

**Général**

| Section     | Icône Material          | Couleur cercle | Description              | État        | Route                    |
|-------------|-------------------------|----------------|--------------------------|-------------|--------------------------|
| Profil      | `Icons.person`          | Blue           | Nom, email, devise       | Active      | `/settings/profile`      |
| Apparence   | `Icons.palette`         | Purple         | Thème, taille texte      | Active      | `/settings/appearance`   |

**Gestion**

| Section     | Icône Material          | Couleur cercle | Description              | État        | Route                    |
|-------------|-------------------------|----------------|--------------------------|-------------|--------------------------|
| Comptes     | `Icons.account_balance` | Teal           | Gérer les comptes        | Active      | `/settings/accounts`     |
| Catégories  | `Icons.label`           | Orange         | Gérer les catégories     | Active      | `/settings/categories`   |
| Données     | `Icons.storage`         | Indigo         | Source locale / serveur  | Active      | `/settings/data`         |

**Autre**

| Section     | Icône Material          | Couleur cercle | Description              | État        | Route                    |
|-------------|-------------------------|----------------|--------------------------|-------------|--------------------------|
| Sécurité    | `Icons.lock`            | Red            | Verrouillage, biométrie  | Placeholder | —                        |
| À propos    | `Icons.info`            | Grey           | Version, licences        | Placeholder | —                        |

### Key Entities

- **SettingsSection** : représente une entrée dans le hub (Material Icon, couleur du cercle, titre, description, groupe, état actif/placeholder, route optionnelle). Liste statique définie dans le code, pas de données persistées.
- **SettingsGroup** : regroupe des SettingsSection sous un titre commun (Général, Gestion, Autre).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Les 7 sections DEVRAIENT être visibles sur la page Réglages sans scroll en taille de texte par défaut sur un écran standard (>= 667px de hauteur)
- **SC-002**: La navigation vers chaque sous-page active fonctionne au premier tap (5 routes : Profil, Apparence, Comptes, Catégories, Données)
- **SC-003**: Le rendu visuel est cohérent en thème clair et sombre (via tokens, pas de couleur hardcodée)
- **SC-004**: 100% des tests unitaires passent, couvrant les cas nominaux et edge cases
- **SC-005**: Les items placeholders (Sécurité, À propos) ne déclenchent aucune navigation ni aucun feedback interactif

## Assumptions

- Les sous-pages (Profil, Apparence, Comptes, Catégories) sont développées dans des issues séparées (KKS-111, KKS-112, KKS-113, KKS-114). La sous-page Données (switch source local/serveur) fait partie de cette feature. Ce hub fournit la navigation vers toutes ces routes, même si certaines pages sont des stubs.
- Le hub remplace l'écran `settings_screen.dart` existant. La seule fonctionnalité présente (toggle thème) sera migrée vers la sous-page Apparence (KKS-112). Les fonctionnalités de déconnexion et profil sont déjà gérées par le menu utilisateur dans l'AdaptiveScaffold — rien d'autre à migrer.
- La page Réglages est accessible via le menu utilisateur existant dans l'AdaptiveScaffold (pas de nouvel onglet de navigation).
- La liste verticale est le layout unique sur tous les écrans (mobile, tablette, desktop).
- Les icônes sont des Material Icons (pas des emoji) pour un rendu cohérent cross-platform.

## Clarifications

### Session 2026-02-21

- Q: Layout grille 2 colonnes ou liste verticale ? → A: Liste verticale avec sections groupées (style actuel Flutter amélioré)
- Q: Section "Données" placeholder ou active ? → A: Active avec switch source de données local/serveur
- Q: Comportement du switch source de données ? → A: Switch avec dialog de confirmation avant changement + redémarrage de l'app
- Q: Regroupement visuel des sections dans la liste ? → A: Groupés par catégorie avec titres de section (Général, Gestion, Autre)
- Q: Icônes emoji ou Material Icons ? → A: Material Icons dans des cercles colorés (cohérent avec Flutter, rendu identique cross-platform)
- Q: Comment l'URL du serveur API est-elle fournie pour le mode serveur ? → A: Champ de saisie sur la sous-page Données, permet la saisie initiale et la modification ultérieure
- Q: Que se passe-t-il avec les données existantes lors du changement de source ? → A: Sources indépendantes — chaque mode conserve ses données, pas de synchronisation. Le dialog de confirmation prévient l'utilisateur
- Q: Autres fonctionnalités dans l'écran settings actuel à conserver ? → A: Non, seul le toggle thème existe (migre vers Apparence KKS-112). Déconnexion et profil déjà dans le menu utilisateur AdaptiveScaffold

## Dependencies

- **Design tokens Flutter** : `AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`, `AppThemeExtension` (existants)
- **Navigation** : `go_router` (existant) pour les routes `/settings/*`
- **KKS-111 à KKS-114** : Sous-pages qui seront développées séparément. Le hub navigue vers des routes qui peuvent pointer vers des pages stub.
