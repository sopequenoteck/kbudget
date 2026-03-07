# Data Model: Notification System

**Branch**: `072-notification-system` | **Date**: 2026-03-06

## Nouvelles entites

### Notification

| Champ | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| id | UUID | non | gen_random_uuid() | PK |
| user_id | UUID | non | — | FK → users(id) ON DELETE CASCADE |
| type | VARCHAR(50) | non | — | NotificationType (BUDGET_THRESHOLD, BUDGET_EXCEEDED, SUBSCRIPTION_DUE, DEBT_DUE) |
| title | VARCHAR(255) | non | — | Titre court de la notification |
| message | TEXT | non | — | Message descriptif |
| entity_type | VARCHAR(50) | oui | — | EntityType (BUDGET, SUBSCRIPTION, DEBT) |
| entity_id | UUID | oui | — | ID de l'entite source (pas de FK) |
| read | BOOLEAN | non | false | Statut de lecture |
| read_at | TIMESTAMP | oui | — | Horodatage de lecture |
| created_at | TIMESTAMP | non | NOW() | Horodatage de creation |

**Index**:
- `idx_notifications_user_id` sur `user_id`
- `idx_notifications_user_created` sur `(user_id, created_at DESC)` — pour la pagination
- `idx_notifications_user_read` sur `(user_id, read)` — pour le comptage non lus

**Contraintes**:
- `entity_type` et `entity_id` sont tous les deux null ou tous les deux non null (CHECK constraint)

### Entite JPA

```java
@Entity
@Table(name = "notifications")
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class Notification {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private NotificationType type;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    @Enumerated(EnumType.STRING)
    @Column(length = 50)
    private EntityType entityType;

    private UUID entityId;

    @Column(nullable = false)
    @Builder.Default
    private Boolean read = false;

    private LocalDateTime readAt;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
```

## Enumerations

### NotificationType

```java
public enum NotificationType {
    BUDGET_THRESHOLD,    // FR-001: seuil budget franchi
    BUDGET_EXCEEDED,     // FR-002: plafond budget depasse
    SUBSCRIPTION_DUE,    // FR-003: rappel abonnement J-1
    DEBT_DUE             // FR-004: rappel dette J-1
}
```

### EntityType

```java
public enum EntityType {
    BUDGET,        // Futur KKS-157
    SUBSCRIPTION,
    DEBT
}
```

## Entites modifiees

### UserPreference (enrichissement)

Nouveaux champs a ajouter :

| Champ | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| enabled_notification_types | VARCHAR(255) | oui | — | Liste NotificationType serialisee (meme pattern que enabled_features) |
| timezone | VARCHAR(50) | oui | 'Europe/Paris' | Fuseau horaire utilisateur pour le job quotidien |

**Converter**: `NotificationTypeListConverter` (meme pattern que `FeatureListConverter`).

## Migration Flyway V15

```sql
-- Table notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    read BOOLEAN NOT NULL DEFAULT false,
    read_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_entity_ref CHECK (
        (entity_type IS NULL AND entity_id IS NULL) OR
        (entity_type IS NOT NULL AND entity_id IS NOT NULL)
    )
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, read);

-- Enrichissement user_preferences
ALTER TABLE user_preferences ADD COLUMN enabled_notification_types VARCHAR(255);
ALTER TABLE user_preferences ADD COLUMN timezone VARCHAR(50) DEFAULT 'Europe/Paris';
```

## Modeles Flutter (Freezed)

### NotificationModel

```dart
@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required NotificationType type,
    required String title,
    required String message,
    EntityType? entityType,
    String? entityId,
    @Default(false) bool read,
    DateTime? readAt,
    required DateTime createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
```

## Diagramme de relations

```
User (1) ──── (N) Notification
  │                    │
  │                    ├── type: NotificationType
  │                    ├── entityType: EntityType (nullable)
  │                    └── entityId: UUID (nullable, pas de FK)
  │
  └── (1) UserPreference
              ├── enabledNotificationTypes: List<NotificationType>
              └── timezone: String
```
