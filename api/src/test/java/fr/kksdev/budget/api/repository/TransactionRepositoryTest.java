package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.jdbc.Sql;

import jakarta.persistence.EntityManager;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
@Sql(scripts = "/h2-unaccent.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_CLASS)
class TransactionRepositoryTest {

    @Autowired
    private TransactionRepository transactionRepository;

    @Autowired
    private AccountRepository accountRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EntityManager entityManager;

    private User user1;
    private User user2;

    @BeforeEach
    void setUp() {
        user1 = userRepository.save(User.builder()
                .email("user1@test.com")
                .password("encoded")
                .name("User 1")
                .build());

        user2 = userRepository.save(User.builder()
                .email("user2@test.com")
                .password("encoded")
                .name("User 2")
                .build());

        Account account1 = accountRepository.save(Account.builder()
                .nom("Compte Principal")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦").couleur("#3b82f6")
                .isDefault(true).actif(true)
                .user(user1)
                .build());

        Account account2 = accountRepository.save(Account.builder()
                .nom("Compte Principal")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦").couleur("#3b82f6")
                .isDefault(true).actif(true)
                .user(user2)
                .build());

        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("100.00"))
                .libelle("Salaire")
                .type(TransactionType.RECETTE)
                .date(LocalDate.of(2026, 1, 1))
                .account(account1)
                .user(user1)
                .build());

        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("50.00"))
                .libelle("Courses")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 1, 15))
                .account(account1)
                .user(user1)
                .build());

        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("200.00"))
                .libelle("Loyer")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 1, 10))
                .account(account2)
                .user(user2)
                .build());

        entityManager.flush();
        entityManager.clear();
    }

    @Test
    void should_find_by_userId_ordered_by_date_desc() {
        List<Transaction> transactions = transactionRepository.findByUserIdAndIsRecurringFalseOrderByDateDesc(user1.getId());

        assertThat(transactions).hasSize(2);
        assertThat(transactions.get(0).getLibelle()).isEqualTo("Courses");
        assertThat(transactions.get(1).getLibelle()).isEqualTo("Salaire");
    }

    @Test
    void should_isolate_transactions_by_user() {
        List<Transaction> user1Transactions = transactionRepository.findByUserIdAndIsRecurringFalseOrderByDateDesc(user1.getId());
        List<Transaction> user2Transactions = transactionRepository.findByUserIdAndIsRecurringFalseOrderByDateDesc(user2.getId());

        assertThat(user1Transactions).hasSize(2);
        assertThat(user2Transactions).hasSize(1);
        assertThat(user2Transactions.getFirst().getLibelle()).isEqualTo("Loyer");
    }

    @Test
    void should_find_by_userId_and_date_between() {
        List<Transaction> transactions = transactionRepository.findByUserIdAndIsRecurringFalseAndDateBetweenOrderByDateDesc(
                user1.getId(),
                LocalDate.of(2026, 1, 10),
                LocalDate.of(2026, 1, 31));

        assertThat(transactions).hasSize(1);
        assertThat(transactions.getFirst().getLibelle()).isEqualTo("Courses");
    }

    // --- T-022 : libellés distincts par user ---

    @Test
    void should_return_distinct_libelles_for_user() {
        // user1 a déjà "Salaire" et "Courses" en setUp, on ajoute un doublon "Courses"
        Account account1 = accountRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user1.getId()))
                .findFirst().orElseThrow();

        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("30.00"))
                .libelle("Courses")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 2, 1))
                .account(account1)
                .user(user1)
                .build());
        entityManager.flush();
        entityManager.clear();

        List<String> libelles = transactionRepository.findLibelleSuggestions(user1.getId(), null, 50);

        assertThat(libelles).containsOnlyOnce("Courses");
    }

    // --- T-023 : tri par fréquence décroissante ---

    @Test
    void should_order_by_frequency_desc() {
        Account account1 = accountRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user1.getId()))
                .findFirst().orElseThrow();

        // Ajouter 9 "Carrefour" supplémentaires (total 10) et 1 "Monoprix" supplémentaire (total 2)
        for (int i = 0; i < 9; i++) {
            transactionRepository.save(Transaction.builder()
                    .montant(new BigDecimal("25.00"))
                    .libelle("Carrefour")
                    .type(TransactionType.DEPENSE)
                    .date(LocalDate.of(2026, 1, i + 1))
                    .account(account1)
                    .user(user1)
                    .build());
        }
        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("15.00"))
                .libelle("Monoprix")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 1, 20))
                .account(account1)
                .user(user1)
                .build());
        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("15.00"))
                .libelle("Monoprix")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 1, 21))
                .account(account1)
                .user(user1)
                .build());
        entityManager.flush();
        entityManager.clear();

        List<String> libelles = transactionRepository.findLibelleSuggestions(user1.getId(), null, 50);

        assertThat(libelles).contains("Carrefour", "Monoprix");
        assertThat(libelles.indexOf("Carrefour")).isLessThan(libelles.indexOf("Monoprix"));
    }

    // --- T-024 : tie-break par date la plus récente ---

    @Test
    void should_tiebreak_by_last_date_desc() {
        Account account1 = accountRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user1.getId()))
                .findFirst().orElseThrow();

        // "Ancien" : 1 occurrence, date ancienne
        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("10.00"))
                .libelle("Ancien")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2025, 6, 1))
                .account(account1)
                .user(user1)
                .build());
        // "Recent" : 1 occurrence, date récente
        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("10.00"))
                .libelle("Recent")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 3, 1))
                .account(account1)
                .user(user1)
                .build());
        entityManager.flush();
        entityManager.clear();

        List<String> libelles = transactionRepository.findLibelleSuggestions(user1.getId(), null, 50);

        assertThat(libelles).contains("Recent", "Ancien");
        assertThat(libelles.indexOf("Recent")).isLessThan(libelles.indexOf("Ancien"));
    }

    // --- T-050 : filtre contains case-insensitive ---

    @Test
    void should_filter_contains_case_insensitive() {
        Account account1 = accountRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user1.getId()))
                .findFirst().orElseThrow();

        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("45.00"))
                .libelle("Carrefour Market")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 2, 1))
                .account(account1)
                .user(user1)
                .build());
        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("30.00"))
                .libelle("Monoprix")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 2, 2))
                .account(account1)
                .user(user1)
                .build());
        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("10.00"))
                .libelle("Carte bleue")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 2, 3))
                .account(account1)
                .user(user1)
                .build());
        entityManager.flush();
        entityManager.clear();

        // Filtre en minuscule : matche au milieu du libellé
        List<String> resultatMinuscule = transactionRepository.findLibelleSuggestions(user1.getId(), "market", 20);
        assertThat(resultatMinuscule).containsExactly("Carrefour Market");

        // Filtre en majuscule : même résultat
        List<String> resultatMajuscule = transactionRepository.findLibelleSuggestions(user1.getId(), "MARKET", 20);
        assertThat(resultatMajuscule).containsExactly("Carrefour Market");

        // Filtre casse mixte : même résultat
        List<String> resultatMixte = transactionRepository.findLibelleSuggestions(user1.getId(), "Market", 20);
        assertThat(resultatMixte).containsExactly("Carrefour Market");
    }

    // --- T-051 : filtre accent-insensitive ---

    @Test
    void should_filter_accent_insensitive() {
        Account account1 = accountRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user1.getId()))
                .findFirst().orElseThrow();

        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("5.00"))
                .libelle("Café du coin")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 2, 1))
                .account(account1)
                .user(user1)
                .build());
        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("20.00"))
                .libelle("L'épicerie")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 2, 2))
                .account(account1)
                .user(user1)
                .build());
        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("15.00"))
                .libelle("Boulangerie")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 2, 3))
                .account(account1)
                .user(user1)
                .build());
        entityManager.flush();
        entityManager.clear();

        // "cafe" sans accent doit matcher "Café du coin"
        List<String> resultatCafe = transactionRepository.findLibelleSuggestions(user1.getId(), "cafe", 20);
        assertThat(resultatCafe).containsExactly("Café du coin");

        // "epicerie" sans accent doit matcher "L'épicerie"
        List<String> resultatEpicerie = transactionRepository.findLibelleSuggestions(user1.getId(), "epicerie", 20);
        assertThat(resultatEpicerie).containsExactly("L'épicerie");
    }

    // --- T-026 : scaling sous-linéaire de findLibelleSuggestions ---
    //
    // Intention : détecter une régression algorithmique (N+1, scan quadratique,
    // index manquant) indépendamment de la vitesse absolue du hardware.
    // Approche : mesurer T(1k) puis T(10k) après warm-up JIT.
    // Une requête saine (GROUP BY + LIMIT) doit scaler de façon
    // sous-linéaire ou au pire linéaire : ratio T(10k)/T(1k) < 20.
    // Un N+1 ou une boucle quadratique ferait exploser ce ratio.

    @Test
    void should_scale_sublinearly_on_large_transaction_volume() {
        Account account1 = accountRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user1.getId()))
                .findFirst().orElseThrow();

        // -- Seed 1 000 transactions (volume petit) --
        List<Transaction> smallBatch = new java.util.ArrayList<>(1000);
        for (int i = 0; i < 1000; i++) {
            smallBatch.add(Transaction.builder()
                    .montant(new BigDecimal("10.00"))
                    .libelle("Libelle_" + (i % 50))
                    .type(TransactionType.DEPENSE)
                    .date(LocalDate.of(2026, Month.JANUARY, 1).plusDays(i % 365))
                    .account(account1)
                    .user(user1)
                    .build());
        }
        transactionRepository.saveAll(smallBatch);
        entityManager.flush();
        entityManager.clear();

        // Warm-up : exécution ignorée pour chauffer le JIT et le cache du plan SQL
        transactionRepository.findLibelleSuggestions(user1.getId(), null, 20);
        entityManager.clear();

        long startSmall = System.nanoTime();
        List<String> libellesSmall = transactionRepository.findLibelleSuggestions(user1.getId(), null, 20);
        long durationSmallMs = Math.max(1L, (System.nanoTime() - startSmall) / 1_000_000);

        // -- Seed 9 000 transactions supplémentaires (total 10 000) --
        List<Transaction> largeBatch = new java.util.ArrayList<>(9000);
        for (int i = 1000; i < 10000; i++) {
            largeBatch.add(Transaction.builder()
                    .montant(new BigDecimal("10.00"))
                    .libelle("Libelle_" + (i % 200))
                    .type(TransactionType.DEPENSE)
                    .date(LocalDate.of(2026, Month.JANUARY, 1).plusDays(i % 365))
                    .account(account1)
                    .user(user1)
                    .build());
        }
        transactionRepository.saveAll(largeBatch);
        entityManager.flush();
        entityManager.clear();

        // Warm-up sur le volume large
        transactionRepository.findLibelleSuggestions(user1.getId(), null, 20);
        entityManager.clear();

        long startLarge = System.nanoTime();
        List<String> libellesLarge = transactionRepository.findLibelleSuggestions(user1.getId(), null, 20);
        long durationLargeMs = Math.max(1L, (System.nanoTime() - startLarge) / 1_000_000);

        assertThat(libellesSmall).isNotEmpty();
        assertThat(libellesLarge).isNotEmpty();

        // Le ratio T(10k) / T(1k) doit rester < 20 :
        // - une requête SQL saine (GROUP BY + LIMIT, plan fixe) est ~1-5x
        // - un N+1 ou scan quadratique serait ~100-1000x
        // Seuil 20x laisse une marge confortable face aux variations de scheduling
        // du runner GitHub Actions tout en détectant toute régression réelle.
        double ratio = (double) durationLargeMs / durationSmallMs;
        assertThat(ratio)
                .as("Ratio T(10k)/T(1k) = %.1f — dépasse 20x, régression algorithmique probable "
                        + "(N+1, scan quadratique ou index manquant). "
                        + "T(1k)=%dms, T(10k)=%dms",
                        ratio, durationSmallMs, durationLargeMs)
                .isLessThan(20.0);
    }
}
