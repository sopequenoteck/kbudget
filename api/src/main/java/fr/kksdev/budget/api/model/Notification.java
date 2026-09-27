package fr.kksdev.budget.api.model;

import fr.kksdev.budget.api.enums.EntityType;
import fr.kksdev.budget.api.enums.NotificationType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(name = "notifications")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"user"})
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @EqualsAndHashCode.Include
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private NotificationType type;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    @Enumerated(EnumType.STRING)
    private EntityType entityType;

    private UUID entityId;

    @Builder.Default
    @Column(nullable = false)
    private boolean read = false;

    private LocalDateTime readAt;

    /**
     * Valeurs brutes que le client compose dans sa langue (KKS-397) : nulle
     * pour les notifications existantes et pour {@code title}/{@code message},
     * qui restent des defauts anglais fixes par le serveur.
     */
    @JdbcTypeCode(SqlTypes.JSON)
    private Map<String, String> params;

    @CreationTimestamp
    @Column(nullable = false)
    private LocalDateTime createdAt;
}
