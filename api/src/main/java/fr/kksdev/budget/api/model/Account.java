package fr.kksdev.budget.api.model;

import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Currency;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "accounts")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"user"})
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Account {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @EqualsAndHashCode.Include
    private UUID id;

    @Column(nullable = false, length = 50)
    private String nom;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AccountType type;

    @Column(name = "solde_initial", nullable = false)
    private BigDecimal soldeInitial;

    @Column(nullable = false, length = 10)
    private String icone;

    @Column(nullable = false, length = 7)
    private String couleur;

    @Column(name = "is_default", nullable = false)
    @Builder.Default
    private Boolean isDefault = false;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 3)
    @Builder.Default
    private Currency currency = Currency.EUR;

    @Column(nullable = false)
    @Builder.Default
    private Boolean actif = true;

    @Column(name = "bank_code", nullable = false, length = 20)
    @Builder.Default
    private String bankCode = "OTHER";

    @Column(name = "bank_custom_name", length = 100)
    private String bankCustomName;

    @Column(name = "bank_custom_logo", columnDefinition = "TEXT")
    private String bankCustomLogo;

    /**
     * Profil du dernier releve importe sur ce compte (KKS-384) : {@code REGISTRY:<bankCode>}
     * ou {@code CUSTOM:<id du profil>}. Avec {@link #statementAccountSuffix}, il sert a
     * reconnaitre le compte au prochain releve. Nulle tant qu'aucun releve exploitable n'a ete importe.
     */
    @Column(name = "statement_profile_key", length = 64)
    private String statementProfileKey;

    /** 4 derniers chiffres du numero de compte lu dans l'en-tete du releve (KKS-384), jamais le numero complet. */
    @Column(name = "statement_account_suffix", length = 4)
    private String statementAccountSuffix;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
}
