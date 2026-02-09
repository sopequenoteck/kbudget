package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.SubscriptionRequest;
import fr.kksdev.budget.api.dto.response.SubscriptionResponse;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SubscriptionServiceTest {

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @InjectMocks
    private SubscriptionService subscriptionService;

    private final UUID userId = UUID.randomUUID();
    private final UUID subscriptionId = UUID.randomUUID();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").build();
    }

    private Subscription buildSubscription(User user) {
        return Subscription.builder()
                .id(subscriptionId)
                .nom("Netflix")
                .montant(new BigDecimal("13.99"))
                .frequence(Frequency.MENSUEL)
                .dateDebut(LocalDate.of(2026, 1, 1))
                .actif(true)
                .category(null)
                .user(user)
                .build();
    }

    @Test
    void should_create_subscription_when_valid_request() {
        var user = buildUser();
        var request = new SubscriptionRequest("Netflix", new BigDecimal("13.99"),
                Frequency.MENSUEL, LocalDate.of(2026, 1, 1), null, null);
        var saved = buildSubscription(user);

        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(subscriptionRepository.save(any(Subscription.class))).thenReturn(saved);

        SubscriptionResponse response = subscriptionService.create(request, userId);

        assertThat(response.id()).isEqualTo(subscriptionId);
        assertThat(response.nom()).isEqualTo("Netflix");
        assertThat(response.actif()).isTrue();
        assertThat(response.category()).isNull();
        verify(subscriptionRepository).save(any(Subscription.class));
    }

    @Test
    void should_return_all_subscriptions_when_user_has_subscriptions() {
        var user = buildUser();
        when(subscriptionRepository.findByUserIdOrderByNomAsc(userId))
                .thenReturn(List.of(buildSubscription(user)));

        List<SubscriptionResponse> result = subscriptionService.getAllByUser(userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().nom()).isEqualTo("Netflix");
    }

    @Test
    void should_return_only_active_subscriptions() {
        var user = buildUser();
        when(subscriptionRepository.findByUserIdAndActifTrueOrderByNomAsc(userId))
                .thenReturn(List.of(buildSubscription(user)));

        List<SubscriptionResponse> result = subscriptionService.getActiveByUser(userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().actif()).isTrue();
    }

    @Test
    void should_return_subscription_when_found_and_owned() {
        var user = buildUser();
        when(subscriptionRepository.findById(subscriptionId))
                .thenReturn(Optional.of(buildSubscription(user)));

        SubscriptionResponse response = subscriptionService.getById(subscriptionId, userId);

        assertThat(response.id()).isEqualTo(subscriptionId);
    }

    @Test
    void should_throw_when_subscription_not_found() {
        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> subscriptionService.getById(subscriptionId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Abonnement non trouvé");
    }

    @Test
    void should_throw_when_subscription_belongs_to_other_user() {
        var otherUser = User.builder().id(UUID.randomUUID()).email("other@mail.com").build();
        when(subscriptionRepository.findById(subscriptionId))
                .thenReturn(Optional.of(buildSubscription(otherUser)));

        assertThatThrownBy(() -> subscriptionService.getById(subscriptionId, userId))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    void should_update_subscription_when_valid() {
        var user = buildUser();
        var existing = buildSubscription(user);
        var request = new SubscriptionRequest("Spotify", new BigDecimal("9.99"),
                Frequency.MENSUEL, LocalDate.of(2026, 2, 1), false, null);

        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.of(existing));
        when(subscriptionRepository.save(any(Subscription.class))).thenReturn(existing);

        SubscriptionResponse response = subscriptionService.update(subscriptionId, request, userId);

        assertThat(response).isNotNull();
        verify(subscriptionRepository).save(existing);
    }

    @Test
    void should_delete_subscription_when_found_and_owned() {
        var user = buildUser();
        var subscription = buildSubscription(user);

        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.of(subscription));

        subscriptionService.delete(subscriptionId, userId);

        verify(subscriptionRepository).delete(subscription);
    }
}
