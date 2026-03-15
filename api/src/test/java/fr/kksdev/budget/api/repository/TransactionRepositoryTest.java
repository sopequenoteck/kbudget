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
}
