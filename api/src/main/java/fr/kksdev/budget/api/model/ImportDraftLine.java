package fr.kksdev.budget.api.model;

import fr.kksdev.budget.api.enums.CategorySource;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.ImportSkipReason;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.converter.UuidListConverter;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "import_draft_lines")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"draft", "category"})
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ImportDraftLine {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @EqualsAndHashCode.Include
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "draft_id", nullable = false)
    private ImportDraft draft;

    @Column(nullable = false)
    private Integer lineNumber;

    @Column(name = "raw_label", nullable = false, length = 500)
    private String rawLabel;

    @Column(name = "clean_label", nullable = false, length = 500)
    private String cleanLabel;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal amount;

    @Column(nullable = false)
    private LocalDate date;

    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false, length = 20)
    private TransactionType transactionType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private ImportLineStatus status = ImportLineStatus.READY;

    @Column(name = "status_message", length = 500)
    private String statusMessage;

    @Enumerated(EnumType.STRING)
    @Column(name = "skip_reason", length = 30)
    private ImportSkipReason skipReason;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    /** Origine de la categorie (KKS-383), nulle tant que la ligne n'en a pas. */
    @Enumerated(EnumType.STRING)
    @Column(name = "category_source", length = 20)
    private CategorySource categorySource;

    @Column(name = "duplicate_transaction_id")
    private UUID duplicateTransactionId;

    /** Date d'achat lue dans le libelle brut d'un paiement carte (KKS-385), nulle sinon. {@code date} reste la date comptable. */
    @Column(name = "purchase_date")
    private LocalDate purchaseDate;

    /** Transaction existante a laquelle la ligne est rapprochee : aucune transaction n'est creee a la confirmation (KKS-385). */
    @Column(name = "matched_transaction_id")
    private UUID matchedTransactionId;

    /** Transactions candidates quand le rapprochement est ambigu (statut DUPLICATE), vide sinon (KKS-385). */
    @Convert(converter = UuidListConverter.class)
    @Column(name = "match_candidate_ids")
    @Builder.Default
    private List<UUID> matchCandidateIds = List.of();

    /** Abonnement auquel la transaction creee sera rattachee (KKS-385). */
    @Column(name = "subscription_id")
    private UUID subscriptionId;

    @CreationTimestamp
    @Column(nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    /** Date de la transaction que la ligne cree : la date d'achat quand elle est connue, sinon la date comptable. */
    public LocalDate transactionDate() {
        return purchaseDate != null ? purchaseDate : date;
    }
}
