package fr.kksdev.budget.api.model;

import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.enums.ImportProfileSource;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "import_drafts")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"user", "account", "lines"})
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ImportDraft {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @EqualsAndHashCode.Include
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private ImportDraftStatus status = ImportDraftStatus.PENDING;

    @Column(length = 255)
    private String fileName;

    @Column(nullable = false)
    @Builder.Default
    private Integer totalLines = 0;

    @Column(nullable = false)
    @Builder.Default
    private Integer readyCount = 0;

    @Column(nullable = false)
    @Builder.Default
    private Integer reviewCount = 0;

    @Column(nullable = false)
    @Builder.Default
    private Integer duplicateCount = 0;

    @Column(nullable = false)
    @Builder.Default
    private Integer skippedCount = 0;

    /** Sous-ensemble de skippedCount : lignes ecartees d'office car deja importees (KKS-382). */
    @Column(name = "already_imported_count", nullable = false)
    @Builder.Default
    private Integer alreadyImportedCount = 0;

    /** Sous-ensemble de readyCount : lignes rapprochees d'une transaction existante, qui ne creeront rien (KKS-385). */
    @Column(name = "matched_count", nullable = false)
    @Builder.Default
    private Integer matchedCount = 0;

    @Column(name = "profile_id")
    private UUID profileId;

    @Enumerated(EnumType.STRING)
    @Column(name = "profile_source", length = 20)
    private ImportProfileSource profileSource;

    /** Cle du profil du releve, voir {@link Account#getStatementProfileKey()} (KKS-384). Nulle sans en-tete exploitable. */
    @Column(name = "statement_profile_key", length = 64)
    private String statementProfileKey;

    /** 4 derniers chiffres du numero de compte lu dans l'en-tete du releve (KKS-384). */
    @Column(name = "statement_account_suffix", length = 4)
    private String statementAccountSuffix;

    /** Solde du compte donne par la banque dans l'en-tete du releve (KKS-384). */
    @Column(name = "statement_balance", precision = 19, scale = 2)
    private BigDecimal statementBalance;

    /** Date a laquelle la banque donne ce solde (KKS-384). */
    @Column(name = "statement_balance_date")
    private LocalDate statementBalanceDate;

    @CreationTimestamp
    @Column(nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(nullable = false)
    private LocalDateTime expiresAt;

    @OneToMany(mappedBy = "draft", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<ImportDraftLine> lines = new ArrayList<>();
}
