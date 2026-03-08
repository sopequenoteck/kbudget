package fr.kksdev.budget.api.model;

import fr.kksdev.budget.api.enums.Currency;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "budget_snapshots",
       uniqueConstraints = @UniqueConstraint(columnNames = {"mois", "category_id", "user_id"}))
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"category", "user"})
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BudgetSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @EqualsAndHashCode.Include
    private UUID id;

    @Column(name = "montant_budget", nullable = false, precision = 12, scale = 2)
    private BigDecimal montantBudget;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private Currency currency;

    @Column(name = "taux_change", precision = 20, scale = 6)
    private BigDecimal tauxChange;

    @Column(name = "montant_depense", nullable = false, precision = 12, scale = 2)
    private BigDecimal montantDepense;

    @Column(nullable = false, length = 7)
    private String mois;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
}
