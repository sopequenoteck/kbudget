package fr.kksdev.budget.api.model;

import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.Frequency;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "budgets",
       uniqueConstraints = @UniqueConstraint(columnNames = {"category_id", "user_id"}))
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Budget {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal montant;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 3)
    @Builder.Default
    private Currency currency = Currency.EUR;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Frequency frequence;

    @Column(name = "seuil_notification", nullable = false)
    @Builder.Default
    private Integer seuilNotification = 80;

    @Column(nullable = false)
    @Builder.Default
    private Boolean actif = true;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
}
