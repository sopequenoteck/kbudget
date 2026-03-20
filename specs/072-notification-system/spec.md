# Feature Specification: Notification System

**Feature Branch**: `072-notification-system`
**Created**: 2026-03-06
**Status**: Draft
**Input**: KKS-158 — Systeme de notifications — push local, WebSocket, panneau in-app
**Linear**: [KKS-158](https://linear.app/kksdev/issue/KKS-158)

## User Scenarios & Testing

### User Story 1 - Recevoir une alerte quand un budget est proche du plafond (Priority: P1)

En tant qu'utilisateur, lorsque je saisis une depense qui fait depasser un seuil (ex. 80%) ou le plafond (100%) d'un budget categorie, je recois immediatement une notification m'avertissant de la situation.

**Why this priority**: C'est le premier consommateur du systeme de notifications. L'alerte budget est la raison d'etre principale de la feature — elle permet d'eviter les depassements involontaires. Note : cette story est bloquee par KKS-157 (budgets par categorie) mais l'infrastructure notifications peut etre developpee en parallele.

**Independent Test**: Creer un budget de 100 EUR, saisir une depense de 85 EUR, verifier qu'une notification de seuil apparait. Saisir 20 EUR de plus, verifier qu'une notification de depassement apparait.

**Acceptance Scenarios**:

1. **Given** un budget Alimentation de 500 EUR avec seuil a 80%, **When** je saisis une depense qui porte le total a 410 EUR (82%), **Then** je recois une notification "Budget Alimentation a 82% — 90 EUR restants"
2. **Given** un budget Alimentation de 500 EUR, **When** je saisis une depense qui porte le total a 520 EUR, **Then** je recois une notification "Budget Alimentation depasse (104%)"
3. **Given** un budget sans seuil configure, **When** je saisis une depense qui depasse 100%, **Then** je recois uniquement la notification de depassement

---

### User Story 2 - Consulter et gerer les notifications dans un panneau in-app (Priority: P1)

En tant qu'utilisateur, je vois une icone cloche avec un badge indiquant le nombre de notifications non lues. En tapant dessus, un drawer lateral (slide-in depuis la droite) s'ouvre en overlay sur la page courante et affiche mes notifications groupees par jour. Je peux marquer une notification comme lue, toutes les marquer comme lues, supprimer une notification par swipe, ou vider tout l'historique.

**Why this priority**: Le panneau est le point d'acces central a toutes les notifications. Sans lui, les notifications n'ont pas d'interface de consultation.

**Independent Test**: Generer 3 notifications, verifier que le badge affiche "3", ouvrir le panneau, verifier le groupement par jour, marquer une notification comme lue, verifier que le badge passe a "2".

**Acceptance Scenarios**:

1. **Given** 5 notifications non lues, **When** j'ouvre l'application, **Then** le badge de la cloche affiche "5"
2. **Given** le panneau de notifications ouvert, **When** je lis les notifications, **Then** elles sont groupees par jour (Aujourd'hui, Hier, dates anterieures)
3. **Given** une notification non lue, **When** je tape dessus, **Then** elle est marquee comme lue et je suis redirige vers l'entite concernee (budget, abonnement, dette)
4. **Given** plusieurs notifications non lues, **When** je tape "Tout marquer comme lu", **Then** toutes les notifications sont marquees comme lues et le badge disparait
5. **Given** une notification dans le panneau, **When** je swipe pour la supprimer, **Then** elle est retiree definitivement du panneau
6. **Given** un historique de notifications, **When** je tape "Vider tout l'historique", **Then** toutes les notifications sont supprimees definitivement

---

### User Story 3 - Recevoir des rappels d'abonnements et de dettes (Priority: P2)

En tant qu'utilisateur, je recois la veille (J-1) une notification me rappelant qu'un abonnement arrive a echeance ou qu'une dette approche de sa date de reglement.

**Why this priority**: Ces rappels sont essentiels pour la gestion financiere quotidienne, mais moins critiques que les alertes budget car ils n'empechent pas de depense en temps reel.

**Independent Test**: Creer un abonnement avec date d'echeance demain, attendre l'execution du job quotidien, verifier qu'une notification de rappel est generee.

**Acceptance Scenarios**:

1. **Given** un abonnement Netflix actif avec prochaine echeance le 7 mars, **When** le job quotidien s'execute le 6 mars, **Then** je recois "Abonnement Netflix — echeance demain"
2. **Given** une dette envers Paul avec date de reglement le 10 mars, **When** le job quotidien s'execute le 9 mars, **Then** je recois "Dette Paul — echeance demain"
3. **Given** un abonnement inactif, **When** le job quotidien s'execute, **Then** aucune notification n'est generee

---

### User Story 4 - Recevoir les notifications en temps reel (Priority: P2)

En tant qu'utilisateur avec l'application ouverte, je recois les notifications instantanement via STOMP WebSocket sans avoir besoin de rafraichir. Quand l'application Flutter est fermee ou en arriere-plan, les notifications arrivent via push locale native. L'application Angular ne recoit les notifications qu'avec l'onglet actif (pas de Web Push).

**Why this priority**: Le temps reel ameliore significativement l'experience mais n'est pas bloquant — le polling ou la consultation manuelle du panneau fonctionnent aussi.

**Independent Test**: Ouvrir l'application sur deux canaux (Flutter + Angular), declencher le job quotidien (endpoint dev POST /notifications/trigger-daily-job) avec un abonnement echeant demain, verifier que la notification apparait sur les deux en moins de 2 secondes.

**Acceptance Scenarios**:

1. **Given** l'application Flutter ouverte avec connexion WebSocket active, **When** une notification est generee cote serveur, **Then** elle apparait dans le panneau en moins de 2 secondes
2. **Given** l'application Flutter en arriere-plan, **When** une notification est generee, **Then** une notification push locale apparait sur l'appareil
3. **Given** l'application Angular ouverte (onglet actif) avec connexion STOMP WebSocket active, **When** une notification est generee, **Then** elle apparait dans le panneau en moins de 2 secondes (pas de push navigateur quand l'onglet est ferme)

---

### User Story 5 - Configurer les preferences de notification (Priority: P3)

En tant qu'utilisateur, je peux choisir quels types de notifications je souhaite recevoir dans les parametres de l'application.

**Why this priority**: La personnalisation est un confort qui peut etre ajoute apres le systeme de base.

**Independent Test**: Desactiver les rappels d'abonnements dans les preferences, verifier qu'aucune notification d'abonnement n'est generee le lendemain.

**Acceptance Scenarios**:

1. **Given** les preferences de notification ouvertes, **When** je desactive "Rappels d'abonnements", **Then** les notifications de type abonnement ne sont plus generees
2. **Given** tous les types desactives, **When** des evenements se produisent, **Then** aucune notification n'est generee
3. **Given** un type reactive, **When** l'evenement correspondant se produit, **Then** la notification est generee normalement

---

### Edge Cases

- Que se passe-t-il si plusieurs transactions sont creees rapidement et declenchent le meme seuil ? Le systeme notifie a chaque franchissement a la hausse. Si le seuil est deja depasse (sans retour sous le seuil entre-temps), pas de re-notification.
- Que se passe-t-il si la connexion WebSocket est perdue ? Le client doit se reconnecter automatiquement et recuperer les notifications manquees via l'API REST.
- Que se passe-t-il lors de la transition background → foreground ? Le client deduplique par ID unique de notification : si une push locale a deja affiche une notification, le WebSocket ne l'ajoute pas une seconde fois au panneau.
- Que se passe-t-il si l'utilisateur n'a aucun budget configure ? Aucune notification de type budget n'est generee (pas d'erreur).
- Que se passe-t-il si une notification reference une entite supprimee ? La notification reste visible mais la navigation vers l'entite affiche un message "Element introuvable".
- Que se passe-t-il si une notification reference un entityType dont la feature n'est pas encore disponible (ex: BUDGET avant KKS-157) ? La notification reste visible mais le lien de navigation est desactive. Un message "Fonctionnalite non disponible" est affiche si l'utilisateur tente de naviguer.
- Comment gerer l'accumulation de notifications ? Les notifications de plus de 90 jours sont automatiquement purgees.

## Requirements

### Functional Requirements

- **FR-001**: Le systeme DOIT creer une notification quand une transaction fait franchir un seuil de budget (configurable, defaut 80%)
- **FR-002**: Le systeme DOIT creer une notification quand une transaction fait depasser le plafond d'un budget (100%)
- **FR-003**: Le systeme DOIT envoyer un rappel J-1 pour les abonnements actifs arrivant a echeance
- **FR-004**: Le systeme DOIT envoyer un rappel J-1 pour les dettes avec date de reglement approchant
- **FR-005**: Le systeme DOIT afficher les notifications dans un drawer lateral (slide-in droite, overlay) avec groupement par jour
- **FR-006**: Le systeme DOIT afficher un badge avec le nombre de notifications non lues
- **FR-007**: Le systeme DOIT permettre de marquer une notification comme lue individuellement ou toutes en lot
- **FR-016**: Le systeme DOIT permettre la suppression individuelle d'une notification (swipe)
- **FR-017**: Le systeme DOIT permettre de vider tout l'historique de notifications en une action
- **FR-008**: Le systeme DOIT transmettre les nouvelles notifications en temps reel via STOMP over WebSocket aux clients connectes, authentifies par JWT dans le header STOMP CONNECT (valide par ChannelInterceptor)
- **FR-009**: Le systeme DOIT declencher des notifications push locales sur mobile quand l'application est en arriere-plan
- **FR-010**: Le systeme DOIT permettre a l'utilisateur de configurer quels types de notifications il souhaite recevoir
- **FR-011**: Le systeme DOIT persister l'historique des notifications et le rendre consultable
- **FR-012**: Le systeme DOIT purger automatiquement les notifications de plus de 90 jours
- **FR-013**: Le systeme DOIT notifier a chaque franchissement de seuil a la hausse ; si le seuil est deja depasse sans retour sous le seuil entre-temps, pas de re-notification
- **FR-014**: Le systeme DOIT permettre la navigation depuis une notification vers l'entite concernee
- **FR-015**: Le client DOIT dedupliquer les notifications par identifiant unique pour eviter les doublons entre push locale et WebSocket

### Key Entities

- **Notification**: Represente un evenement notifie a l'utilisateur. Attributs : id (UUID), type (NotificationType), titre, message, entityType (enum: BUDGET, SUBSCRIPTION, DEBT) + entityId (UUID) pour la reference generique vers l'entite source (sans FK — le cas "entite supprimee" est gere), read (boolean), createdAt, readAt (nullable). Appartient a un utilisateur (FK → User).
- **NotificationType**: Enumeration des types de notifications : `BUDGET_THRESHOLD`, `BUDGET_EXCEEDED`, `SUBSCRIPTION_DUE`, `DEBT_DUE`. Sert a la fois pour le typage des notifications et pour les preferences utilisateur. Note : un type pour les transactions recurrentes (KKS-159) sera ajoute ulterieurement.
- **UserPreference (enrichi)**: Nouveaux champs `enabledNotificationTypes` (List\<NotificationType\>, meme pattern que `enabledFeatures`) + `timezone` (String, defaut "Europe/Paris"). Les preferences de notification sont stockees directement sur cette entite existante. Le timezone est utilise par le job quotidien de rappels.

## Success Criteria

### Measurable Outcomes

- **SC-001**: L'utilisateur est notifie d'un depassement de budget en moins de 3 secondes apres la saisie de la transaction (app ouverte)
- **SC-002**: Les rappels d'abonnements et de dettes sont generes chaque jour avant 8h00 du matin dans le fuseau horaire configure par l'utilisateur (champ `timezone` de `UserPreference`, defaut `Europe/Paris`)
- **SC-003**: L'utilisateur peut consulter ses notifications et identifier les urgences en moins de 10 secondes
- **SC-004**: Le panneau de notifications charge et affiche les 20 dernieres notifications en moins de 1 seconde
- **SC-005**: La reconnexion WebSocket apres perte de connexion se fait automatiquement en moins de 5 secondes
- **SC-006**: 100% des notifications generees sont delivrees (aucune perte entre creation et affichage)
- **SC-007**: Zero dependance externe requise pour le fonctionnement du systeme de notifications

## Assumptions

- Le systeme de budgets par categorie (KKS-157) fournira les donnees de consommation par categorie ; son absence ne bloque pas le developpement de l'infrastructure notifications
- Le seuil d'alerte par defaut est 80% du budget, configurable par budget individuel
- Le job quotidien pour les rappels s'execute une fois par jour (frequence non configurable par l'utilisateur) dans le fuseau horaire de l'utilisateur (`UserPreference.timezone`)
- Le transport temps reel utilise STOMP over WebSocket (protocole STOMP au-dessus de la connexion WebSocket) ; les clients Angular et Flutter necessitent un client STOMP (ex: @stomp/stompjs, stomp_dart_client)
- Angular PWA : pas de Web Push API / Service Worker push. Notifications temps reel uniquement quand l'onglet est ouvert. Les notifications manquees sont recuperees via l'API REST au retour
- Les notifications push locales (mobile) utilisent les packages Dart natifs sans dependance Firebase
- La retention des notifications est de 90 jours, non configurable par l'utilisateur
- La pagination du panneau de notifications charge 20 elements par page
- La deduplication des notifications budget se fait par etat : le systeme compare l'etat avant/apres transaction pour detecter un franchissement a la hausse (pas de fenetre temporelle)

## Clarifications

### Session 2026-03-06

- Q: KKS-157 doit-il etre termine avant tout developpement de KKS-158 ? → A: Non. L'infrastructure notifications (entite, panneau, WebSocket, rappels abos/dettes) se developpe en parallele. Seules les alertes budget (FR-001, FR-002) sont bloquees par KKS-157.
- Q: Comment eviter les doublons entre push locale et WebSocket lors de la transition background/foreground ? → A: Deduplication cote client par ID unique de notification.
- Q: Fenetre de deduplication des notifications budget ? → A: Re-notification a chaque franchissement de seuil a la hausse apres un retour sous le seuil. Pas de deduplication temporelle.
- Q: L'utilisateur peut-il supprimer des notifications ? → A: Oui. Suppression individuelle (swipe) + bouton "Vider tout l'historique" + purge automatique 90 jours.
- Q: Format du panneau de notifications ? → A: Drawer lateral (slide-in depuis la droite, overlay sur la page courante).
- Q: Comment stocker les preferences de types de notifications actives ? → A: Nouveau champ `enabledNotificationTypes` (List\<NotificationType\>) sur l'entite `UserPreference` existante (meme pattern que `enabledFeatures`).
- Q: Comment modeliser la reference vers l'entite source dans une notification ? → A: Couple `entityType` (enum: BUDGET, SUBSCRIPTION, DEBT) + `entityId` (UUID) — reference generique sans FK. L'integrite referentielle n'est pas requise (cas "entite supprimee" gere par la spec).
- Q: Comment authentifier la connexion WebSocket ? → A: STOMP over WebSocket. JWT envoye dans le header STOMP `Authorization` du frame CONNECT, valide par un `ChannelInterceptor` cote serveur. Pas de token dans l'URL.
- Q: Fuseau horaire du job quotidien de rappels ? → A: Configurable par l'utilisateur via un champ `timezone` (String, defaut `Europe/Paris`) sur `UserPreference`.
- Q: Notifications push PWA Angular quand l'onglet est ferme ? → A: Non. Angular = notifications temps reel uniquement quand l'onglet est ouvert (STOMP WebSocket). Pas de Web Push API. Le push background est couvert par Flutter mobile (push locale native).
- Q: Le type `recurring_reminder` dans NotificationType est-il necessaire ? → A: Non. Retire de l'enum — KKS-159 (transactions recurrentes) ajoutera le type adequat avec ses propres FRs quand il sera specifie.

## Dependencies

- **KKS-157**: Budgets par categorie — bloque uniquement FR-001 et FR-002 (alertes budget seuil/depassement). L'infrastructure notifications, le panneau, le WebSocket et les rappels abos/dettes (FR-003 a FR-014) peuvent etre developpes en parallele.
- **KKS-155**: Refonte ecran par ecran — integration du panneau de notifications dans le nouveau design
