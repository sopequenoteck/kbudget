package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.enums.DebtType;
import fr.kksdev.budget.api.model.Debt;
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
class DebtRepositoryTest {

    @Autowired
    private DebtRepository debtRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EntityManager entityManager;

    private User user;

    @BeforeEach
    void setUp() {
        user = userRepository.save(User.builder()
                .email("user@test.com")
                .password("encoded")
                .name("User")
                .build());

        debtRepository.save(Debt.builder()
                .personne("Alice")
                .montant(new BigDecimal("50.00"))
                .sens(DebtType.JE_DOIS)
                .date(LocalDate.of(2026, 1, 5))
                .rembourse(false)
                .user(user)
                .build());

        debtRepository.save(Debt.builder()
                .personne("Bob")
                .montant(new BigDecimal("30.00"))
                .sens(DebtType.ON_ME_DOIT)
                .date(LocalDate.of(2026, 1, 15))
                .rembourse(true)
                .user(user)
                .build());

        debtRepository.save(Debt.builder()
                .personne("Charlie")
                .montant(new BigDecimal("100.00"))
                .sens(DebtType.JE_DOIS)
                .date(LocalDate.of(2026, 1, 10))
                .rembourse(false)
                .user(user)
                .build());

        entityManager.flush();
        entityManager.clear();
    }

    @Test
    void should_find_all_by_userId_ordered_by_date_desc() {
        List<Debt> debts = debtRepository.findByUserIdOrderByDateDesc(user.getId());

        assertThat(debts).hasSize(3);
        assertThat(debts.get(0).getPersonne()).isEqualTo("Bob");
        assertThat(debts.get(1).getPersonne()).isEqualTo("Charlie");
        assertThat(debts.get(2).getPersonne()).isEqualTo("Alice");
    }

    @Test
    void should_find_only_unpaid_by_userId() {
        List<Debt> unpaid = debtRepository.findByUserIdAndRembourseFalseOrderByDateDesc(user.getId());

        assertThat(unpaid).hasSize(2);
        assertThat(unpaid).extracting(Debt::getPersonne)
                .containsExactly("Charlie", "Alice");
    }
}
