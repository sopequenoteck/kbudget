# Feature Specification: Configuration de la navigation — Flutter

**Feature Branch**: `059-flutter-settings-bottom-nav`
**Created**: 2026-02-28
**Status**: Draft
**Input**: User description: "KKS-121 — Flutter: Settings — Configuration Bottom Nav"
**Linear**: [KKS-121](https://linear.app/kksdev/issue/KKS-121/flutter-settings-configuration-bottom-nav)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Réordonner les onglets de navigation par drag & drop (Priority: P1)

En tant qu'utilisateur, je veux pouvoir réordonner les onglets optionnels de la barre de navigation par glisser-déposer depuis les paramètres, afin de personnaliser l'ordre d'affichage selon mes préférences d'usage.

**Why this priority**: C'est la fonctionnalité cœur de cette feature — sans le drag & drop, la page n'a pas de raison d'exister. Le réordonnancement est la seule action utilisateur de cette page.

**Independent Test**: Peut être testé en ouvrant la page de configuration de la navigation, en glissant une fonctionnalité activée vers une autre position, et en vérifiant que l'ordre change visuellement dans la liste et dans la preview.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la page Features & Navigation des paramètres, **When** il consulte la section "Navigation", **Then** il voit les éléments du noyau fixe (Dashboard, Transactions) affichés en haut en grisé et non déplaçables, suivis des fonctionnalités activées avec une poignée de drag.
2. **Given** les fonctionnalités Abonnements, Dettes et Boutique sont activées dans cet ordre, **When** l'utilisateur glisse "Boutique" au-dessus de "Abonnements", **Then** le nouvel ordre devient Boutique, Abonnements, Dettes.
3. **Given** seules Abonnements et Dettes sont activées, **When** l'utilisateur glisse "Dettes" au-dessus de "Abonnements", **Then** le nouvel ordre devient Dettes, Abonnements.
4. **Given** une seule fonctionnalité optionnelle est activée, **When** l'utilisateur consulte la section Navigation, **Then** l'élément est affiché avec sa poignée de drag mais ne peut être réordonné (il n'y a qu'un seul élément).

---

### User Story 2 - Visualiser la preview du Bottom Nav résultant (Priority: P1)

En tant qu'utilisateur, je veux voir une preview de la barre de navigation résultante en bas de la page, afin de comprendre immédiatement l'impact de mon réordonnancement sur l'interface.

**Why this priority**: Le feedback visuel immédiat est essentiel pour que l'utilisateur comprenne l'effet de ses actions. Sans preview, il doit quitter les paramètres pour vérifier le résultat.

**Independent Test**: Peut être testé en réordonnant des fonctionnalités et en vérifiant que la preview en bas de page reflète l'ordre exact, incluant les icônes et libellés de chaque onglet.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la section Navigation, **When** la page se charge, **Then** une preview de la barre de navigation est affichée en bas de page avec les onglets dans l'ordre actuel (noyau fixe + fonctionnalités activées ordonnées).
2. **Given** l'utilisateur réordonne une fonctionnalité, **When** le drag & drop est terminé, **Then** la preview se met à jour instantanément pour refléter le nouvel ordre.
3. **Given** les fonctionnalités activées sont Boutique puis Abonnements, **When** l'utilisateur consulte la preview, **Then** la preview affiche : Dashboard, Transactions, Boutique, Abonnements (noyau fixe en premier, puis fonctionnalités dans l'ordre personnalisé).

---

### User Story 3 - Persistance automatique de l'ordre (Priority: P2)

En tant qu'utilisateur, je veux que l'ordre de navigation soit sauvegardé automatiquement à chaque modification, afin de retrouver ma configuration sans action de sauvegarde explicite.

**Why this priority**: La persistance garantit que l'effort de personnalisation n'est pas perdu. La sauvegarde automatique est attendue pour ce type d'interaction (pas de bouton "Enregistrer").

**Independent Test**: Peut être testé en réordonnant les onglets, en quittant la page, puis en y revenant pour vérifier que l'ordre est conservé. En fermant et rouvrant l'application, l'ordre doit être restauré.

**Acceptance Scenarios**:

1. **Given** l'utilisateur réordonne les fonctionnalités, **When** le drag & drop est terminé, **Then** le nouvel ordre est sauvegardé automatiquement (localement et sur le serveur si en mode serveur).
2. **Given** l'utilisateur a personnalisé l'ordre, **When** il quitte la page et y revient, **Then** l'ordre personnalisé est affiché.
3. **Given** l'utilisateur a personnalisé l'ordre, **When** il ferme et rouvre l'application, **Then** l'ordre personnalisé est restauré depuis la persistance locale.
4. **Given** l'utilisateur est en mode serveur, **When** il réordonne les fonctionnalités, **Then** le nouvel ordre est synchronisé avec le serveur pour être disponible sur d'autres appareils.

---

### User Story 4 - Impact immédiat sur la vraie barre de navigation (Priority: P2)

En tant qu'utilisateur, je veux que la barre de navigation de l'application reflète immédiatement le nouvel ordre, afin que la personnalisation soit effective sans redémarrage.

**Why this priority**: Le feedback réel (pas seulement la preview) valide que la personnalisation fonctionne. Sans cela, l'utilisateur doute de l'efficacité de ses modifications.

**Independent Test**: Peut être testé en réordonnant les onglets dans les paramètres, puis en naviguant en arrière vers l'écran principal et en vérifiant que la barre de navigation reflète le nouvel ordre.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a réordonné les fonctionnalités (Boutique, Abonnements, Dettes), **When** il quitte les paramètres, **Then** la barre de navigation affiche : Dashboard, Transactions, Boutique, Abonnements, Dettes.
2. **Given** l'utilisateur n'a jamais personnalisé l'ordre, **When** il utilise l'application, **Then** la barre de navigation affiche l'ordre par défaut : Dashboard, Transactions, puis les fonctionnalités activées dans leur ordre standard.

---

### Edge Cases

- Que se passe-t-il si une fonctionnalité est désactivée après avoir été ordonnée ? Elle disparaît de la liste de réordonnancement et de la preview. Son rang est ignoré. Si elle est réactivée plus tard, elle reprend sa position dans l'ordre sauvegardé (si encore présente dans `navOrder`) ou est ajoutée en dernière position.
- Que se passe-t-il si aucune fonctionnalité optionnelle n'est activée ? La section Navigation affiche uniquement les éléments du noyau fixe (grisés) et un message indiquant qu'aucune fonctionnalité n'est disponible pour le réordonnancement. La preview affiche seulement Dashboard et Transactions.
- Que se passe-t-il si la synchronisation serveur échoue lors de la sauvegarde de l'ordre ? L'ordre est sauvegardé localement (comportement optimiste), un snackbar informe de l'échec, et la synchronisation est retentée au prochain chargement.
- Que se passe-t-il si `navOrder` contient des identifiants de fonctionnalités inconnues (ex : après downgrade) ? Les identifiants inconnus sont ignorés silencieusement. Seules les fonctionnalités reconnues et activées sont affichées.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher une section "Navigation" dans la page Features & Navigation des paramètres, en dessous de la section des feature toggles.
- **FR-002**: La section Navigation DOIT afficher les éléments du noyau fixe (Dashboard et Transactions) en haut de la liste, visuellement grisés et non déplaçables.
- **FR-003**: La section Navigation DOIT afficher les fonctionnalités activées sous le noyau fixe, chacune avec une icône, un libellé et une poignée de drag.
- **FR-004**: Les fonctionnalités activées DOIVENT être réordonnables par glisser-déposer (drag & drop).
- **FR-005**: Une preview visuelle de la barre de navigation résultante DOIT être affichée en bas de la section Navigation, reflétant l'ordre actuel (noyau fixe + fonctionnalités ordonnées).
- **FR-006**: La preview DOIT se mettre à jour immédiatement après chaque réordonnancement.
- **FR-007**: Le nouvel ordre DOIT être sauvegardé automatiquement à chaque réordonnancement, sans action utilisateur supplémentaire.
- **FR-008**: Le système DOIT persister l'ordre localement pour qu'il survive à la fermeture de l'application.
- **FR-009**: En mode serveur, le système DOIT synchroniser l'ordre avec le serveur via le point de gestion des préférences utilisateur.
- **FR-010**: La barre de navigation de l'application DOIT refléter immédiatement le nouvel ordre, sans nécessiter de rechargement.
- **FR-011**: Si aucune fonctionnalité optionnelle n'est activée, la section Navigation DOIT afficher un message explicatif indiquant qu'il n'y a rien à réordonner.
- **FR-012**: L'ordre par défaut (si jamais personnalisé) DOIT suivre l'ordre standard : Abonnements, Dettes, Boutique.

### Key Entities

- **Feature**: Fonctionnalité optionnelle de l'application. Trois valeurs : Abonnements (SUBSCRIPTIONS), Dettes (DEBTS), Boutique (SHOP). Chacune a un libellé, une icône et une position dans l'ordre de navigation.
- **UserPreference**: Préférences de personnalisation d'un utilisateur. Contient la liste ordonnée des fonctionnalités (`navOrder`) qui détermine l'ordre d'affichage dans la barre de navigation. Relation 1:1 avec l'utilisateur.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut réordonner les onglets optionnels par drag & drop en une seule interaction (glisser et relâcher).
- **SC-002**: La preview de la barre de navigation se met à jour en moins de 500 millisecondes après un réordonnancement.
- **SC-003**: L'ordre personnalisé est fidèlement restauré après fermeture et réouverture de l'application.
- **SC-004**: La barre de navigation de l'application reflète le nouvel ordre sans nécessiter de navigation supplémentaire ou de rechargement.
- **SC-005**: En mode serveur, l'ordre personnalisé est disponible sur un autre appareil après synchronisation.

## Assumptions

- La feature KKS-120 (Feature Toggles) est déjà implémentée et fournit le `featureConfigNotifierProvider`. Le champ `navOrder` sera ajouté au state par cette feature (KKS-121).
- Le backend expose déjà les endpoints de gestion des préférences (`GET/PUT /users/me/preferences`) incluant le champ `navOrder`.
- La section Navigation est intégrée dans la même page que les feature toggles (page "Features & Navigation"), pas dans une page séparée.
- Le noyau fixe est toujours composé de Dashboard (position 0) et Transactions (position 1). Cet ordre est défini dans le code et ne dépend pas de `navOrder`.
- `navOrder` est une liste ordonnée d'identifiants de features (enum `Feature`). Seules les features activées et présentes dans `navOrder` sont affichées dans la barre de navigation.
- Les fonctionnalités désactivées sont exclues de la liste de réordonnancement mais conservent leur position dans `navOrder` pour restauration future.
