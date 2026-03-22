# Tasks: Notification System

**Input**: Design documents from `/specs/072-notification-system/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/notification-api.md, quickstart.md

**Tests**: Inclus (constitution Principe V — Testabilite). Tests d'integration backend, tests unitaires services, widget tests Flutter.

**Organization**: Tasks groupees par user story. US1 (alertes budget) est bloquee par KKS-157 — seule l'infrastructure (hooks) est implementee. US2 (panneau) est le MVP visible.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Enums, migration Flyway, entite Notification, enrichissement UserPreference

- [x] T001 [P] Creer l'enum `NotificationType` (BUDGET_THRESHOLD, BUDGET_EXCEEDED, SUBSCRIPTION_DUE, DEBT_DUE) dans `api/src/main/java/fr/kksdev/budget/api/enums/NotificationType.java`
- [x] T002 [P] Creer l'enum `EntityType` (BUDGET, SUBSCRIPTION, DEBT) dans `api/src/main/java/fr/kksdev/budget/api/enums/EntityType.java`
- [x] T003 [P] Creer la migration Flyway `api/src/main/resources/db/migration/V15__add_notifications.sql` — table `notifications` (id, user_id, type, title, message, entity_type, entity_id, read, read_at, created_at + CHECK constraint + 3 index) + ALTER `user_preferences` (enabled_notification_types VARCHAR(255), timezone VARCHAR(50) DEFAULT 'Europe/Paris')
- [x] T004 Creer l'entite JPA `Notification` dans `api/src/main/java/fr/kksdev/budget/api/model/Notification.java` — UUID, @ManyToOne User, @Enumerated NotificationType + EntityType, title, message, entityId, read (default false), readAt, @CreationTimestamp createdAt. Annotations Lombok @Data @Builder @NoArgsConstructor @AllArgsConstructor (depends on T001, T002)
- [x] T005 Creer le converter `NotificationTypeListConverter` dans `api/src/main/java/fr/kksdev/budget/api/model/converter/NotificationTypeListConverter.java` — meme pattern que `FeatureListConverter` existant dans le meme package
- [x] T006 Enrichir l'entite `UserPreference` dans `api/src/main/java/fr/kksdev/budget/api/model/UserPreference.java` — ajouter champ `enabledNotificationTypes` (List\<NotificationType\> avec @Convert NotificationTypeListConverter) + `timezone` (String, default "Europe/Paris") (depends on T005)
- [x] T007 [P] Creer le DTO `NotificationResponse` (record) dans `api/src/main/java/fr/kksdev/budget/api/dto/NotificationResponse.java` — id, type, title, message, entityType, entityId, read, readAt, createdAt
- [x] T008 [P] Enrichir les DTOs `UserPreferenceRequest` et `UserPreferenceResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/` — ajouter enabledNotificationTypes (List\<NotificationType\>) + timezone (String)

**Checkpoint**: Enums, entite, migration et DTOs prets. Le schema de base est en place.

---

## Phase 2: Foundational (Backend CRUD + REST)

**Purpose**: NotificationRepository, NotificationService (CRUD), NotificationController (REST endpoints), enrichissement PreferenceService

**CRITICAL**: Toutes les user stories dependent de cette phase.

- [x] T009 Creer le repository `NotificationRepository` dans `api/src/main/java/fr/kksdev/budget/api/repository/NotificationRepository.java` — extends JpaRepository\<Notification, UUID\>. Methodes custom : `Page<Notification> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable)`, `Page<Notification> findByUserIdAndReadOrderByCreatedAtDesc(UUID userId, boolean read, Pageable pageable)`, `long countByUserIdAndRead(UUID userId, boolean read)`, `List<Notification> findByUserIdAndRead(UUID userId, boolean read)`, `void deleteByUserIdAndCreatedAtBefore(UUID userId, LocalDateTime before)`
- [x] T010 Creer le service `NotificationService` dans `api/src/main/java/fr/kksdev/budget/api/service/NotificationService.java` — methodes : `createNotification(UUID userId, NotificationType type, String title, String message, EntityType entityType, UUID entityId)`, `getNotifications(UUID userId, Pageable pageable, Boolean unread)`, `getUnreadCount(UUID userId)`, `markAsRead(UUID userId, UUID notificationId)`, `markAllAsRead(UUID userId)`, `deleteNotification(UUID userId, UUID notificationId)`, `deleteAllNotifications(UUID userId)`, `purgeOldNotifications(UUID userId)`. Logs INFO sur creation/lecture/suppression. Verification ownership (userId match) (depends on T009)
- [x] T011 Creer le controller `NotificationController` dans `api/src/main/java/fr/kksdev/budget/api/controller/NotificationController.java` — @RestController @RequestMapping("/notifications"). Endpoints selon contracts/notification-api.md : GET / (pagine, ?unread), GET /unread-count, PUT /{id}/read, PUT /read-all, DELETE /{id}, DELETE /. Injecte NotificationService. Principal userId extrait du JWT (depends on T010)
- [x] T012 Enrichir `PreferenceService` dans `api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java` — mapper enabledNotificationTypes + timezone dans getPreferences() et updatePreferences(). Ajouter methode `isNotificationTypeEnabled(UUID userId, NotificationType type)` et `getUserTimezone(UUID userId)`. Defaut : tous les types actifs si null (depends on T006, T008)
- [x] T013 Ajouter `/ws` aux routes permises dans `api/src/main/java/fr/kksdev/budget/api/config/SecurityConfig.java` — authorizeHttpRequests: requestMatchers("/ws/**").permitAll() (l'auth se fait via STOMP ChannelInterceptor, pas via servlet filter)

**Checkpoint**: API REST notifications fonctionnelle. On peut creer, lister, marquer lu, supprimer des notifications via curl.

---

## Phase 3: User Story 2 - Panneau notifications in-app (Priority: P1) — MVP

**Goal**: Icone cloche avec badge, drawer lateral (slide-in droite), groupement par jour, mark read, swipe delete, vider historique.

**Independent Test**: Creer manuellement 3 notifications via API, ouvrir l'app, verifier badge "3", ouvrir drawer, verifier groupement, marquer lu, verifier badge "2".

### Backend (deja couvert par Phase 2)

Aucune tache supplementaire — le CRUD REST couvre les besoins du panneau.

### Angular

- [x] T014 [P] [US2] Creer le modele TypeScript `NotificationModel` + `NotificationType` + `EntityType` dans `app/src/app/core/models/notification.model.ts` — interface NotificationModel (id, type, title, message, entityType, entityId, read, readAt, createdAt), type NotificationType, type EntityType, interface NotificationPage (content, page, size, totalElements, totalPages)
- [x] T015 [US2] Creer le service `NotificationService` (signal-based) dans `app/src/app/core/services/notification.ts` — signals: notifications, unreadCount, isLoading, hasMore, currentPage. Methodes: loadNotifications(), loadMore(), loadUnreadCount(), markAsRead(id), markAllAsRead(), deleteNotification(id), deleteAll(). Appels REST vers /notifications et /notifications/unread-count. Polling periodique du unreadCount (30s) (depends on T014)
- [x] T016 [US2] Creer le composant `NotificationBadge` (standalone, OnPush) dans `app/src/app/shared/components/notification-badge/` — icone cloche Phosphor (ph-bell), badge compteur (unreadCount signal du NotificationService), click event output (depends on T015)
- [x] T017 [US2] Creer le composant `NotificationPanel` (standalone, OnPush) dans `app/src/app/shared/components/notification-panel/` — drawer lateral slide-in depuis la droite (overlay, backdrop). Groupement par jour (Aujourd'hui, Hier, dates). Liste des notifications avec icone type, titre, message, heure. Actions: tap → markAsRead + navigation entite (si entityType=BUDGET et feature non disponible, afficher "Fonctionnalite non disponible" — pas de lien cliquable), swipe gauche → delete, bouton "Tout marquer lu", bouton "Vider historique" (avec confirmation dialog avant suppression — action destructive irreversible). Pagination infinite scroll (loadMore) (depends on T015)
- [x] T018 [US2] Integrer NotificationBadge + NotificationPanel dans le Shell dans `app/src/app/shared/components/shell/shell.ts` — ajouter badge cloche dans l'AppBar (a cote du user menu), toggle ouverture/fermeture du panel. Charger unreadCount au init (depends on T016, T017)

### Flutter

- [x] T019 [P] [US2] Creer les enums Flutter `NotificationType` et `EntityType` dans `flutter/lib/src/domain/enums/notification_type.dart` et `flutter/lib/src/domain/enums/entity_type.dart`
- [x] T020 [P] [US2] Creer le modele Freezed `NotificationModel` dans `flutter/lib/src/domain/models/notification.dart` — id, type, title, message, entityType?, entityId?, read, readAt?, createdAt. Avec fromJson/toJson. Puis `dart run build_runner build --delete-conflicting-outputs`
- [x] T021 [P] [US2] Creer l'interface `NotificationRepository` dans `flutter/lib/src/domain/repositories/notification_repository.dart` — getNotifications(page, size, unreadOnly?), getUnreadCount(), markAsRead(id), markAllAsRead(), deleteNotification(id), deleteAll()
- [x] T022 [US2] Creer la data source `NotificationRemoteDataSource` dans `flutter/lib/src/data/remote/notification_remote_data_source.dart` — appels Dio vers /notifications, /notifications/unread-count, /notifications/{id}/read, /notifications/read-all, /notifications/{id}, /notifications (depends on T020)
- [x] T023 [US2] Creer l'implementation `NotificationRepositoryRemote` dans `flutter/lib/src/features/notifications/data/notification_repository_remote.dart` (depends on T021, T022)
- [x] T024 [US2] Creer le `NotificationNotifier` (Riverpod Notifier\<ListState\<NotificationModel\>\>) dans `flutter/lib/src/features/notifications/application/notification_notifier.dart` — loadItems(), markAsRead(), markAllAsRead(), delete(), deleteAll(), loadMore(). Provider `notificationNotifierProvider` + `unreadCountProvider` (FutureProvider) (depends on T023)
- [x] T025 [US2] Creer le widget `NotificationBadge` dans `flutter/lib/src/features/notifications/presentation/notification_badge.dart` — ConsumerWidget, icone cloche PhosphorIcons.bell, badge compteur (unreadCountProvider), onTap callback (depends on T024)
- [x] T026 [US2] Creer le widget `NotificationPanel` (drawer lateral) dans `flutter/lib/src/features/notifications/presentation/notification_panel.dart` — ConsumerStatefulWidget. Drawer via Scaffold.endDrawer (idiomatique Flutter). Groupement par jour. Liste avec Dismissible (swipe delete). Tap → markAsRead + navigation (context.push basee sur entityType/entityId ; si entityType=BUDGET et feature non disponible, afficher SnackBar "Fonctionnalite non disponible"). Boutons "Tout lu" + "Vider" (avec confirmation dialog avant suppression — action destructive irreversible). Pagination via loadMore() (depends on T024)
- [x] T027 [US2] Integrer NotificationBadge + NotificationPanel dans `flutter/lib/src/common_widgets/adaptive_scaffold.dart` — ajouter badge cloche dans l'AppBar (actions), ouvrir le panel en drawer de droite (endDrawer ou overlay). Charger unreadCount au init (depends on T025, T026)

**Checkpoint**: Panneau notifications fonctionnel sur Angular et Flutter. Badge visible, drawer ouvre, notifications groupees par jour, mark read/delete/vider operationnels via API REST.

---

## Phase 4: User Story 3 - Rappels abonnements et dettes J-1 (Priority: P2)

**Goal**: Job quotidien qui genere des notifications J-1 pour les abonnements actifs et dettes non remboursees.

**Independent Test**: Creer un abonnement avec echeance demain, forcer l'execution du job, verifier qu'une notification "echeance demain" apparait dans le panneau.

- [x] T028 [US3] Ajouter `@EnableScheduling` dans `api/src/main/java/fr/kksdev/budget/api/config/` — soit dans une classe @Configuration existante, soit creer `SchedulingConfig.java`
- [x] T029 [US3] Creer le service `NotificationScheduler` dans `api/src/main/java/fr/kksdev/budget/api/service/NotificationScheduler.java` — @Scheduled(cron = "0 0 6 * * *") job quotidien (6h00 heure serveur — app self-hosted mono-user, le serveur DOIT etre configure dans le fuseau horaire de l'utilisateur). Pour chaque user: recuperer timezone (PreferenceService.getUserTimezone), calculer "demain" dans ce timezone. Parcourir les abonnements actifs dont la prochaine echeance = demain (calculee via dateDebut + frequence). Parcourir les dettes non remboursees dont date = demain. Creer une notification pour chaque (NotificationService.createNotification). Verifier les preferences (isNotificationTypeEnabled) avant de creer. Appeler NotificationService.purgeOldNotifications() pour purger les > 90 jours (pas de logique de purge dupliquee dans le scheduler). Logs INFO pour chaque notification generee (depends on T010, T012)
- [x] T030 [US3] Ajouter methode utilitaire `getNextDueDate(Subscription subscription)` dans `NotificationScheduler` ou dans un helper — calcul de la prochaine echeance basee sur dateDebut + frequence (MENSUEL/ANNUEL). Algorithme: depuis dateDebut, incrementer par frequence jusqu'a obtenir une date >= aujourd'hui (depends on T029)
- [x] T031 [US3] Ajouter endpoint dev-only `POST /notifications/trigger-daily-job` dans `NotificationController` — @Profile("dev") uniquement, permet de declencher manuellement le job pour les tests. Appelle NotificationScheduler.runDailyJob() (depends on T029)

**Checkpoint**: Le job quotidien genere des notifications J-1 pour abonnements et dettes. Les notifications apparaissent dans le panneau (Phase 3).

---

## Phase 5: User Story 4 - Notifications temps reel STOMP WebSocket (Priority: P2)

**Goal**: Transmission instantanee des notifications via STOMP over WebSocket. Reconnexion automatique.

**Independent Test**: Ouvrir l'app Flutter + Angular, creer un abonnement avec echeance demain, declencher le job, verifier que les notifications apparaissent en < 2s sans refresh.

### Backend

- [x] T032 [P] [US4] Ajouter la dependance `spring-boot-starter-websocket` dans `api/pom.xml`
- [x] T033 [US4] Creer `WebSocketConfig` dans `api/src/main/java/fr/kksdev/budget/api/config/WebSocketConfig.java` — @EnableWebSocketMessageBroker, registerStompEndpoints("/ws" allowedOriginPatterns "*"), configureMessageBroker(enableSimpleBroker "/queue" "/topic", setApplicationDestinationPrefixes "/app", setUserDestinationPrefix "/user"), configureClientInboundChannel (ajouter StompAuthInterceptor) (depends on T032)
- [x] T034 [US4] Creer `StompAuthInterceptor` dans `api/src/main/java/fr/kksdev/budget/api/config/StompAuthInterceptor.java` — implements ChannelInterceptor. preSend(): intercepter STOMP CONNECT, extraire header "Authorization", valider JWT via JwtUtil, extraire email, charger User, set `new UsernamePasswordAuthenticationToken(user.getId(), null, List.of())` dans le accessor — IMPORTANT: le principal DOIT etre `user.getId()` (UUID) pour etre coherent avec `JwtFilter` et permettre a `SimpMessagingTemplate.convertAndSendToUser()` de router correctement. Si token invalide, throw MessagingException (le client STOMP recevra un ERROR frame et devra retenter la connexion) (depends on T033)
- [x] T035 [US4] Enrichir `NotificationService.createNotification()` dans `api/src/main/java/fr/kksdev/budget/api/service/NotificationService.java` — apres persistance, envoyer la notification via SimpMessagingTemplate.convertAndSendToUser(userId, "/queue/notifications", notificationResponse). Injecter SimpMessagingTemplate (depends on T033)

### Angular

- [x] T036 [US4] Installer `@stomp/stompjs` via `cd app && npm install @stomp/stompjs`
- [x] T037 [US4] Creer le service `StompService` dans `app/src/app/core/services/stomp.ts` — signal-based. Methodes: connect(token), disconnect(), subscribe(destination, callback), isConnected signal. Config: brokerURL ws://{host}/api/ws, connectHeaders Authorization Bearer, reconnectDelay 5000, heartbeat 10s. A la reconnexion: appeler NotificationService.loadUnreadCount() pour recuperer les manquees (depends on T036)
- [x] T038 [US4] Integrer StompService dans NotificationService dans `app/src/app/core/services/notification.ts` — au login/init: connecter STOMP, subscribe /user/queue/notifications. A la reception: prepend notification dans le signal notifications avec deduplication par ID (FR-015 — eviter doublons entre REST recovery et STOMP), incrementer unreadCount. Au logout: disconnect STOMP. Remplacer le polling 30s par STOMP (garder polling comme fallback si STOMP non connecte) (depends on T037)

### Flutter

- [x] T039 [US4] Ajouter dependance `stomp_dart_client` dans `flutter/pubspec.yaml` via `cd flutter && flutter pub add stomp_dart_client`
- [x] T040 [US4] Creer le service `StompService` dans `flutter/lib/src/services/stomp_service.dart` — Riverpod provider. Methodes: connect(token, baseUrl), disconnect(), onNotification(callback). StompClient config: connectHeaders Authorization Bearer, reconnectDelay backoff exponentiel (1s, 2s, 4s, max 30s). Subscribe /user/queue/notifications. A la reconnexion: callback pour recuperer les manquees via REST (depends on T039)
- [x] T041 [US4] Integrer StompService dans NotificationNotifier dans `flutter/lib/src/features/notifications/application/notification_notifier.dart` — au init: connecter STOMP avec le token JWT. A la reception: prepend notification dans state.items, rafraichir unreadCount. Au logout: disconnect. Deduplication par ID (FR-015) (depends on T040)

**Checkpoint**: Notifications temps reel fonctionnelles. Une notification creee cote serveur apparait en < 2s sur les clients connectes.

---

## Phase 6: User Story 1 - Alertes budget seuil/depassement (Priority: P1) — BLOQUEE par KKS-157

**Goal**: Infrastructure pour declencher des notifications quand un budget est franchi. L'implementation effective depend de KKS-157 (budgets par categorie).

**Independent Test**: Ne peut etre teste qu'apres KKS-157. L'infrastructure (hook dans TransactionService) est prete a etre activee.

- [x] T042 [US1] Preparer le hook dans `NotificationService` dans `api/src/main/java/fr/kksdev/budget/api/service/NotificationService.java` — ajouter methode `checkBudgetThresholds(UUID userId, UUID categoryId, BigDecimal previousTotal, BigDecimal newTotal, BigDecimal budgetLimit, BigDecimal thresholdPercent)`. Le parametre `previousTotal` est le total AVANT la transaction (fourni par le futur BudgetService qui connait le solde courant). Logique: si previousTotal < seuil et newTotal >= seuil → creer BUDGET_THRESHOLD. Si previousTotal < budgetLimit et newTotal >= budgetLimit → creer BUDGET_EXCEEDED. Verifier preferences utilisateur. Methode prete a etre appelee depuis le futur BudgetService (KKS-157)
- [x] T043 [US1] Documenter le point d'integration dans `specs/072-notification-system/quickstart.md` — ajouter section "Integration KKS-157" expliquant ou appeler `checkBudgetThresholds()` dans le futur TransactionService apres creation/modification d'une transaction

**Checkpoint**: Hook pret pour KKS-157. L'infrastructure est en place, il suffit d'appeler `checkBudgetThresholds()` depuis le service budget futur.

---

## Phase 7: User Story 5 - Preferences de notification (Priority: P3)

**Goal**: Ecran de parametres permettant d'activer/desactiver chaque type de notification + configurer le timezone.

**Independent Test**: Desactiver "Rappels d'abonnements" dans les preferences, declencher le job, verifier qu'aucune notification d'abonnement n'est generee.

### Angular

- [x] T044 [P] [US5] Creer le composant `NotificationSettings` (standalone, OnPush) dans `app/src/app/features/settings/notification-settings/` — liste des NotificationType avec toggle (switch) pour chaque, selecteur timezone (input text ou select avec suggestions courantes). Utilise PreferenceService.update() pour sauvegarder. Afficher le nom lisible de chaque type (Alertes budget, Rappels abonnements, Rappels dettes)
- [x] T045 [US5] Ajouter la route `/settings/notifications` dans le routing settings Angular et lien dans la page Settings existante (depends on T044)

### Flutter

- [x] T046 [P] [US5] Creer le widget `NotificationSettingsScreen` dans `flutter/lib/src/features/notifications/presentation/notification_settings_screen.dart` — ConsumerWidget. Liste des NotificationType avec SwitchListTile pour chaque. Selecteur timezone. Sauvegarde via PreferenceRemoteDataSource ou notifier dedie. Affichage noms lisibles
- [x] T047 [US5] Ajouter la route `/settings/notifications` dans `flutter/lib/src/routing/app_router.dart` et lien dans l'ecran Settings existant (depends on T046)
- [x] T048 [US5] Enrichir `PreferenceRemoteDataSource` dans `flutter/lib/src/data/remote/preference_remote_data_source.dart` — ajouter enabledNotificationTypes + timezone dans les methodes getPreferences/updatePreferences (depends on T046)

**Checkpoint**: L'utilisateur peut configurer ses preferences de notification. Les types desactives ne generent plus de notifications.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Push locale Flutter, reconnexion robuste, nettoyage

- [x] T049 [P] Ajouter dependance `flutter_local_notifications` dans `flutter/pubspec.yaml` via `cd flutter && flutter pub add flutter_local_notifications`
- [x] T050 Creer le service `LocalNotificationService` dans `flutter/lib/src/services/local_notification_service.dart` — initialisation du plugin (Android NotificationChannel, iOS permissions), methode `showNotification(title, body, payload)`. Appele par StompService quand l'app est en background (AppLifecycleState.paused) (depends on T049)
- [x] T051 Integrer `LocalNotificationService` dans `StompService` dans `flutter/lib/src/services/stomp_service.dart` — detecter l'etat de l'app (WidgetsBindingObserver ou AppLifecycleState provider). Si background: afficher push locale. Si foreground: laisser le panneau gerer. Deduplication par ID (depends on T050, T041)
- [x] T052 [P] Ajouter configuration CORS WebSocket dans `api/src/main/java/fr/kksdev/budget/api/config/WebSocketConfig.java` — setAllowedOriginPatterns depuis la config CORS existante (env var CORS_ALLOWED_ORIGINS) plutot que "*" en prod
- [x] T053 [P] Ajouter logging structure dans `NotificationScheduler` — log.info au debut/fin du job avec nombre de notifications generees, log.error sur exceptions
- [x] T054 Validation quickstart.md — suivre le guide `specs/072-notification-system/quickstart.md` pour verifier que le flux complet fonctionne end-to-end

---

## Phase 9: Tests (Constitution Principe V — Testabilite)

**Purpose**: Tests d'integration backend, tests unitaires services, widget tests Flutter. Nommage : `should_[resultat]_when_[condition]`.

### Backend — Tests d'integration

- [x] T055 [P] Creer les tests d'integration `NotificationControllerTest` dans `api/src/test/java/fr/kksdev/budget/api/controller/NotificationControllerTest.java` — @SpringBootTest @AutoConfigureMockMvc. Tests : should_return_paginated_notifications_when_authenticated, should_return_unread_count_when_has_unread, should_mark_as_read_when_valid_id, should_mark_all_as_read_when_has_unread, should_delete_notification_when_valid_id, should_delete_all_notifications_when_authenticated, should_return_403_when_accessing_other_user_notification, should_return_404_when_notification_not_found (depends on T011)

### Backend — Tests unitaires

- [x] T056 [P] Creer les tests unitaires `NotificationServiceTest` dans `api/src/test/java/fr/kksdev/budget/api/service/NotificationServiceTest.java` — @ExtendWith(MockitoExtension.class). Mock NotificationRepository. Tests : should_create_notification_when_valid_params, should_return_paginated_notifications_when_user_has_notifications, should_mark_as_read_when_notification_exists, should_throw_when_marking_other_user_notification, should_delete_notification_when_owned, should_purge_old_notifications_when_older_than_90_days (depends on T010)
- [x] T057 [P] Creer les tests unitaires `NotificationSchedulerTest` dans `api/src/test/java/fr/kksdev/budget/api/service/NotificationSchedulerTest.java` — @ExtendWith(MockitoExtension.class). Mock SubscriptionRepository, DebtRepository, NotificationService, PreferenceService. Tests : should_create_subscription_notification_when_due_tomorrow, should_create_debt_notification_when_due_tomorrow, should_not_create_notification_when_type_disabled, should_not_create_notification_when_subscription_inactive, should_calculate_next_due_date_when_monthly, should_calculate_next_due_date_when_yearly, should_purge_old_notifications_when_job_runs (depends on T029, T030)

### Flutter — Widget tests

- [x] T058 [P] Creer les widget tests `NotificationBadgeTest` dans `flutter/test/src/features/notifications/presentation/notification_badge_test.dart` — ProviderScope + overrides. Tests : should_display_count_when_has_unread, should_hide_badge_when_zero_unread, should_trigger_callback_when_tapped (depends on T025)
- [x] T059 [P] Creer les widget tests `NotificationPanelTest` dans `flutter/test/src/features/notifications/presentation/notification_panel_test.dart` — ProviderScope + MaterialApp.router + AppTheme.light. Tests : should_display_grouped_notifications_when_loaded, should_mark_as_read_when_tapped, should_delete_when_swiped, should_show_empty_state_when_no_notifications (depends on T026)

### Angular — Tests unitaires

- [x] T060 [P] Creer les tests unitaires `NotificationService` dans `app/src/app/core/services/notification.spec.ts` — Vitest + HttpClientTestingModule. Tests : should_load_notifications_when_called, should_return_unread_count_when_has_unread, should_mark_as_read_when_valid_id, should_mark_all_as_read_when_called, should_delete_notification_when_valid_id, should_delete_all_when_called (depends on T015)
- [x] T061 [P] Creer les tests unitaires `StompService` dans `app/src/app/core/services/stomp.spec.ts` — Vitest. Tests : should_connect_when_token_provided, should_reconnect_when_disconnected, should_call_callback_when_message_received (depends on T037)

### Flutter — Tests unitaires notifier

- [x] T062 [P] Creer les tests unitaires `NotificationNotifierTest` dans `flutter/test/src/features/notifications/application/notification_notifier_test.dart` — ProviderContainer + overrides mock repository. Tests : should_load_notifications_when_init, should_mark_as_read_when_called, should_mark_all_as_read_when_called, should_delete_notification_when_called, should_load_more_when_has_more (depends on T024)

**Checkpoint**: Tous les tests passent. Constitution Principe V satisfait.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — BLOCKS all user stories
- **US2 Panel (Phase 3)**: Depends on Phase 2 — MVP visible
- **US3 Rappels (Phase 4)**: Depends on Phase 2 — premier producteur de notifications
- **US4 WebSocket (Phase 5)**: Depends on Phase 2 — enrichit la livraison
- **US1 Budget (Phase 6)**: Depends on Phase 2 — infrastructure hook (bloquee par KKS-157)
- **US5 Preferences (Phase 7)**: Depends on Phase 2 + Phase 4 (les preferences doivent etre verifiees par le scheduler)
- **Polish (Phase 8)**: Depends on Phase 5 (StompService necessaire pour push locale)
- **Tests (Phase 9)**: Depends on Phase 2 (backend tests), Phase 3 (Flutter widget tests), Phase 4 (scheduler tests). Peut demarrer des que les phases correspondantes sont terminees

### User Story Dependencies

- **US2 (P1 — Panel)**: Phase 2 uniquement. Independant des autres stories. **MVP**
- **US3 (P2 — Rappels)**: Phase 2 uniquement. Independant. Produit les premieres notifications reelles
- **US4 (P2 — WebSocket)**: Phase 2 uniquement. Independant. Enrichit US2 et US3
- **US1 (P1 — Budget)**: Phase 2. Bloque par KKS-157 externe
- **US5 (P3 — Preferences)**: Phase 2. Interagit avec US3 (scheduler verifie preferences) et US4 (types filtres)

### Within Each User Story

- Backend avant frontend
- Models/enums avant services
- Services avant controllers/widgets
- Core implementation avant integration

### Parallel Opportunities

**Phase 1** : T001, T002, T003 en parallele. T007, T008 en parallele.
**Phase 3 (US2)** : Angular (T014-T018) et Flutter (T019-T027) en parallele total. Au sein de Flutter: T019, T020, T021 en parallele.
**Phase 4 et 5** : US3 (rappels) et US4 (WebSocket) peuvent etre faites en parallele car ils ne partagent pas de fichiers (sauf NotificationService.createNotification enrichi par T035).
**Phase 7 (US5)** : Angular (T044-T045) et Flutter (T046-T048) en parallele.
**Phase 9 (Tests)** : T055, T056, T057, T058, T059, T060, T061, T062 tous en parallele (fichiers independants).

---

## Parallel Example: User Story 2 (Panel)

```bash
# Backend deja couvert par Phase 2

# Angular et Flutter en parallele total:
# Agent Angular:
Task T014: "Creer modele TypeScript NotificationModel"
Task T015: "Creer NotificationService signal-based" (after T014)
Task T016: "Creer NotificationBadge component" (after T015)
Task T017: "Creer NotificationPanel drawer" (after T015)
Task T018: "Integrer dans Shell" (after T016, T017)

# Agent Flutter (en parallele de Angular):
Task T019: "Creer enums Flutter"
Task T020: "Creer modele Freezed" (parallel with T019)
Task T021: "Creer interface repository" (parallel with T019, T020)
Task T022: "Creer remote data source" (after T020)
Task T023: "Creer repository implementation" (after T021, T022)
Task T024: "Creer NotificationNotifier" (after T023)
Task T025: "Creer NotificationBadge widget" (after T024)
Task T026: "Creer NotificationPanel drawer" (after T024)
Task T027: "Integrer dans AdaptiveScaffold" (after T025, T026)
```

---

## Implementation Strategy

### MVP First (US2 — Panel)

1. Complete Phase 1: Setup (enums, migration, entite)
2. Complete Phase 2: Foundational (CRUD REST)
3. Complete Phase 3: US2 Panel (Angular + Flutter)
4. **STOP and VALIDATE**: Creer des notifications via curl, verifier le panneau
5. Deploy/demo si OK

### Incremental Delivery

1. Setup + Foundational → API REST operationnelle
2. US2 Panel → Interface visible (MVP!)
3. US3 Rappels → Premieres notifications automatiques
4. US4 WebSocket → Temps reel
5. US1 Budget → Hooks prets (attente KKS-157)
6. US5 Preferences → Personnalisation
7. Polish → Push locale Flutter, CORS prod, validation E2E
8. Tests → Integration backend, unitaires services/scheduler, widget tests Flutter

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US1 (alertes budget) est partiellement bloquee par KKS-157 — seule l'infrastructure est implementee
- Commit apres chaque task ou groupe logique
- Penser a `/sync-doc` apres les commits
