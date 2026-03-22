# Research: Notification System

**Branch**: `072-notification-system` | **Date**: 2026-03-06

## R1: STOMP over WebSocket avec Spring Boot 4.x

**Decision**: Spring WebSocket avec STOMP intégré (`spring-boot-starter-websocket`)

**Rationale**: Spring Boot inclut nativement le support STOMP via `@EnableWebSocketMessageBroker`. Le simple broker en mémoire suffit pour une app mono-user (pas besoin de RabbitMQ/ActiveMQ). Le `SimpMessagingTemplate` permet d'envoyer des messages à des utilisateurs spécifiques via `/user/{userId}/queue/notifications`.

**Alternatives considered**:
- RabbitMQ comme broker STOMP → over-engineering pour mono-user (principe III)
- SSE (Server-Sent Events) → unidirectionnel seulement, pas de protocol standard pour auth
- Raw WebSocket sans STOMP → pas de routing topics, gestion manuelle des subscriptions

**Configuration**:
```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*");
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/queue", "/topic");
        registry.setApplicationDestinationPrefixes("/app");
        registry.setUserDestinationPrefix("/user");
    }
}
```

## R2: Authentification STOMP via ChannelInterceptor

**Decision**: `ChannelInterceptor` custom qui intercepte le frame STOMP CONNECT, extrait le JWT du header `Authorization`, et set l'authentification Spring Security.

**Rationale**: Le `JwtFilter` existant (servlet filter) ne s'applique pas aux WebSocket frames. Le `ChannelInterceptor` s'insere dans le pipeline STOMP et permet de valider le token avant la subscription.

**Implementation**:
```java
@Component
@RequiredArgsConstructor
public class StompAuthInterceptor implements ChannelInterceptor {
    private final JwtUtil jwtUtil;
    private final UserRepository userRepository;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            String token = accessor.getFirstNativeHeader("Authorization");
            // Valider JWT, extraire user, set Authentication
        }
        return message;
    }
}
```

## R3: Job quotidien Spring @Scheduled

**Decision**: `@Scheduled(cron = "0 0 6 * * *")` avec `@EnableScheduling`. Execution fixe a 6h UTC, les calculs J-1 utilisent le timezone de l'utilisateur.

**Rationale**: Spring `@Scheduled` est le mecanisme le plus simple pour un job cron (principe III). Pas besoin de Quartz pour un seul job mono-user. L'heure d'execution (6h UTC) est suffisamment tot pour couvrir les timezones Europe/Africa. Le calcul "demain" utilise `ZonedDateTime` avec le timezone de `UserPreference`.

**Alternatives considered**:
- Quartz Scheduler → complexite inutile pour un seul job simple
- Spring Batch → pour le traitement de masse, pas pertinent ici
- EventListener declenche par la creation de subscription → ne couvre pas le rappel J-1 quotidien

## R4: Push locale Flutter (sans Firebase)

**Decision**: Package `flutter_local_notifications` pour les push locales natives iOS/Android.

**Rationale**: Respect de SC-007 (zero dependance externe). Le package gere les canaux Android (NotificationChannel) et les permissions iOS nativement. Le STOMP client Flutter recoit la notification en background via un service Dart isolate, puis declenche la push locale.

**Alternatives considered**:
- Firebase Cloud Messaging (FCM) → dependance externe, viole SC-007 et principe VII
- `awesome_notifications` → plus de features mais plus lourd, pas necessaire

**Limitations**: Le push local ne fonctionne que si l'app Flutter tourne en background (service Dart). Si l'app est completement fermee (killed), pas de notification push — l'utilisateur les verra au prochain lancement via l'API REST. Acceptable pour une app mono-user.

## R5: Client STOMP Angular (@stomp/stompjs)

**Decision**: Package `@stomp/stompjs` (v7+) pour le client STOMP en Angular.

**Rationale**: Package le plus maintenu et documente pour STOMP en JavaScript. Compatible avec le simple broker Spring. Supporte la reconnexion automatique et les headers d'authentification sur CONNECT.

**Configuration**:
```typescript
const stompConfig: StompConfig = {
  brokerURL: `ws://${location.host}/api/ws`,
  connectHeaders: { Authorization: `Bearer ${token}` },
  reconnectDelay: 5000,
  heartbeatIncoming: 10000,
  heartbeatOutgoing: 10000,
};
```

## R6: Client STOMP Flutter (stomp_dart_client)

**Decision**: Package `stomp_dart_client` pour le client STOMP en Dart/Flutter.

**Rationale**: Package Dart natif compatible STOMP 1.2. Supporte les headers custom pour l'authentification. Reconnexion automatique configurable.

**Alternatives considered**:
- `web_socket_channel` + parsing STOMP manuel → reinventer la roue
- `stompx` → moins maintenu

## R7: Strategie de reconnexion WebSocket

**Decision**: Reconnexion automatique avec backoff exponentiel (1s, 2s, 4s, 8s, max 30s). A la reconnexion, le client appelle `GET /notifications?unread=true` pour recuperer les notifications manquees.

**Rationale**: Le backoff exponentiel evite de surcharger le serveur en cas de panne prolongee. La recuperation via REST garantit qu'aucune notification n'est perdue (SC-006).

## R8: Purge automatique des notifications

**Decision**: Job `@Scheduled` (meme classe que les rappels, execution quotidienne) qui execute `DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '90 days' AND user_id = :userId`.

**Rationale**: La purge dans le meme job quotidien simplifie l'architecture. 90 jours fixes (non configurable) selon la spec.
