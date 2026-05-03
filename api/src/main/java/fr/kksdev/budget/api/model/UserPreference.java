package fr.kksdev.budget.api.model;

import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.enums.TextScale;
import fr.kksdev.budget.api.model.converter.CurrencyListConverter;
import fr.kksdev.budget.api.model.converter.FeatureListConverter;
import fr.kksdev.budget.api.model.converter.NotificationTypeListConverter;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "user_preferences")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"user"})
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserPreference {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @EqualsAndHashCode.Include
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Convert(converter = FeatureListConverter.class)
    @Column(name = "enabled_features", nullable = false)
    @Builder.Default
    private List<Feature> enabledFeatures = List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS);

    @Convert(converter = FeatureListConverter.class)
    @Column(name = "nav_order", nullable = false)
    @Builder.Default
    private List<Feature> navOrder = List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS);

    @Convert(converter = CurrencyListConverter.class)
    @Column(name = "currencies", nullable = false, length = 100)
    @Builder.Default
    private List<Currency> currencies = List.of(Currency.EUR);

    @Convert(converter = NotificationTypeListConverter.class)
    @Column(name = "enabled_notification_types")
    private List<NotificationType> enabledNotificationTypes;

    @Column(name = "timezone")
    @Builder.Default
    private String timezone = "Europe/Paris";

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "text_scale", length = 20)
    private TextScale textScale = TextScale.MEDIUM;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
