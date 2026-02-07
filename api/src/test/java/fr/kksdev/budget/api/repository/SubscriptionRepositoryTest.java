package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.model.Subscription;
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
class SubscriptionRepositoryTest {

    @Autowired
    private SubscriptionRepository subscriptionRepository;

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

        subscriptionRepository.save(Subscription.builder()
                .nom("Spotify")
                .montant(new BigDecimal("9.99"))
                .frequence(Frequency.MENSUEL)
                .dateDebut(LocalDate.of(2025, 1, 1))
                .actif(true)
                .user(user)
                .build());

        subscriptionRepository.save(Subscription.builder()
                .nom("Netflix")
                .montant(new BigDecimal("13.49"))
                .frequence(Frequency.MENSUEL)
                .dateDebut(LocalDate.of(2025, 6, 1))
                .actif(false)
                .user(user)
                .build());

        subscriptionRepository.save(Subscription.builder()
                .nom("Amazon Prime")
                .montant(new BigDecimal("69.90"))
                .frequence(Frequency.ANNUEL)
                .dateDebut(LocalDate.of(2025, 3, 1))
                .actif(true)
                .user(user)
                .build());

        entityManager.flush();
        entityManager.clear();
    }

    @Test
    void should_find_all_by_userId_ordered_by_name() {
        List<Subscription> subs = subscriptionRepository.findByUserIdOrderByNomAsc(user.getId());

        assertThat(subs).hasSize(3);
        assertThat(subs.get(0).getNom()).isEqualTo("Amazon Prime");
        assertThat(subs.get(1).getNom()).isEqualTo("Netflix");
        assertThat(subs.get(2).getNom()).isEqualTo("Spotify");
    }

    @Test
    void should_find_only_active_by_userId() {
        List<Subscription> activeSubs = subscriptionRepository.findByUserIdAndActifTrueOrderByNomAsc(user.getId());

        assertThat(activeSubs).hasSize(2);
        assertThat(activeSubs).extracting(Subscription::getNom)
                .containsExactly("Amazon Prime", "Spotify");
    }
}
