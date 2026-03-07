package fr.kksdev.budget.api.model;

import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.model.converter.CurrencyListConverter;
import fr.kksdev.budget.api.model.converter.FeatureListConverter;
import fr.kksdev.budget.api.model.converter.NotificationTypeListConverter;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "user_preferences")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserPreference {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Convert(converter = FeatureListConverter.class)
    @Column(name = "enabled_features", nullable = false)
    @Builder.Default
    private List<Feature> enabledFeatures = List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP);

    @Convert(converter = FeatureListConverter.class)
    @Column(name = "nav_order", nullable = false)
    @Builder.Default
    private List<Feature> navOrder = List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP);

    @Column(name = "shop_account_id")
    private UUID shopAccountId;

    @Column(name = "include_shop_in_balance", nullable = false)
    @Builder.Default
    private Boolean includeShopInBalance = false;

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

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
