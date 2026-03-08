package fr.kksdev.budget.api.model;

import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.DebtType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "debts")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"category", "user"})
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Debt {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @EqualsAndHashCode.Include
    private UUID id;

    @Column(nullable = false)
    private String personne;

    @Column(nullable = false)
    private BigDecimal montant;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DebtType sens;

    @Column(nullable = false)
    private LocalDate date;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    @Builder.Default
    private Currency currency = Currency.EUR;

    @Column(nullable = false)
    private Boolean rembourse = false;

    @Column(name = "due_date")
    private LocalDate dueDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
}
