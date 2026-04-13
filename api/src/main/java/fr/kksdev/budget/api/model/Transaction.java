package fr.kksdev.budget.api.model;

import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.TransactionType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "transactions")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"category", "account", "debt", "subscription", "user"})
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @EqualsAndHashCode.Include
    private UUID id;

    @Column(nullable = false)
    private BigDecimal montant;

    @Column(nullable = false)
    private String libelle;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TransactionType type;

    @Column(nullable = false)
    private LocalDate date;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    private String note;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    @Column(name = "transfer_id")
    private UUID transferId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "debt_id")
    private Debt debt;

    @Column(name = "is_recurring", nullable = false)
    @Builder.Default
    private Boolean isRecurring = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "frequency")
    private Frequency frequency;

    @Column(name = "next_occurrence")
    private LocalDate nextOccurrence;

    @Column(name = "recurring_active", nullable = false)
    @Builder.Default
    private Boolean recurringActive = true;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subscription_id")
    private Subscription subscription;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
}
