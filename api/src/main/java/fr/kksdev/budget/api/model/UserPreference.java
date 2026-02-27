package fr.kksdev.budget.api.model;

import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.model.converter.FeatureListConverter;
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

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
