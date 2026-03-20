package fr.kksdev.budget.api.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "import_profiles")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"user"})
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ImportProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @EqualsAndHashCode.Include
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 5)
    @Builder.Default
    private String separator = ",";

    @Column(name = "date_format", nullable = false, length = 20)
    @Builder.Default
    private String dateFormat = "dd/MM/yyyy";

    @Column(name = "date_column", nullable = false, length = 50)
    private String dateColumn;

    @Column(name = "amount_column", length = 50)
    private String amountColumn;

    @Column(name = "debit_column", length = 50)
    private String debitColumn;

    @Column(name = "credit_column", length = 50)
    private String creditColumn;

    @Column(name = "label_column", nullable = false, length = 50)
    private String labelColumn;

    @Column(nullable = false, length = 20)
    @Builder.Default
    private String encoding = "UTF-8";

    @Column(name = "decimal_separator", nullable = false, length = 1)
    @Builder.Default
    private String decimalSeparator = ".";

    @Column(name = "skip_header_lines", nullable = false)
    @Builder.Default
    private Integer skipHeaderLines = 0;

    @CreationTimestamp
    @Column(nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
}
