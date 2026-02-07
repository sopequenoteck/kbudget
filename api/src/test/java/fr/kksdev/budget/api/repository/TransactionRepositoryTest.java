package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import jakarta.persistence.EntityManager;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
class TransactionRepositoryTest {

    @Autowired
    private TransactionRepository transactionRepository;

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

        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("100.00"))
                .libelle("Salaire")
                .type(TransactionType.RECETTE)
                .date(LocalDate.of(2026, 1, 1))
                .user(user1)
                .build());

        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("50.00"))
                .libelle("Courses")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 1, 15))
                .user(user1)
                .build());

        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("200.00"))
                .libelle("Loyer")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 1, 10))
                .user(user2)
                .build());

        entityManager.flush();
        entityManager.clear();
    }

    @Test
    void should_find_by_userId_ordered_by_date_desc() {
        List<Transaction> transactions = transactionRepository.findByUserIdOrderByDateDesc(user1.getId());

        assertThat(transactions).hasSize(2);
        assertThat(transactions.get(0).getLibelle()).isEqualTo("Courses");
        assertThat(transactions.get(1).getLibelle()).isEqualTo("Salaire");
    }

    @Test
    void should_isolate_transactions_by_user() {
        List<Transaction> user1Transactions = transactionRepository.findByUserIdOrderByDateDesc(user1.getId());
        List<Transaction> user2Transactions = transactionRepository.findByUserIdOrderByDateDesc(user2.getId());

        assertThat(user1Transactions).hasSize(2);
        assertThat(user2Transactions).hasSize(1);
        assertThat(user2Transactions.get(0).getLibelle()).isEqualTo("Loyer");
    }

    @Test
    void should_find_by_userId_and_date_between() {
        List<Transaction> transactions = transactionRepository.findByUserIdAndDateBetweenOrderByDateDesc(
                user1.getId(),
                LocalDate.of(2026, 1, 10),
                LocalDate.of(2026, 1, 31));

        assertThat(transactions).hasSize(1);
        assertThat(transactions.get(0).getLibelle()).isEqualTo("Courses");
    }
}
