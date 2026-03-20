package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.UserPreferenceRequest;
import fr.kksdev.budget.api.dto.response.UserPreferenceResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.model.UserPreference;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.UserPreferenceRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PreferenceServiceTest {

    @Mock
    private UserPreferenceRepository userPreferenceRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private ExchangeRateService exchangeRateService;

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    @InjectMocks
    private PreferenceService preferenceService;

    private final UUID userId = UUID.randomUUID();

    private UserPreference buildPreference(List<Feature> enabled, List<Feature> navOrder) {
        return buildPreference(enabled, navOrder, List.of(Currency.EUR));
    }

    private UserPreference buildPreference(List<Feature> enabled, List<Feature> navOrder, List<Currency> currencies) {
        return UserPreference.builder()
                .id(UUID.randomUUID())
                .user(User.builder().id(userId).build())
                .enabledFeatures(new ArrayList<>(enabled))
                .navOrder(new ArrayList<>(navOrder))
                .currencies(new ArrayList<>(currencies))
                .build();
    }

    // === US1: getPreferences ===

    @Test
    void should_returnDefaultPreferences_when_noPreferenceExists() {
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.empty());
        when(userRepository.getReferenceById(userId)).thenReturn(User.builder().id(userId).build());
        when(userPreferenceRepository.save(any(UserPreference.class))).thenAnswer(i -> i.getArgument(0));

        UserPreferenceResponse response = preferenceService.getPreferences(userId);

        assertThat(response.enabledFeatures()).containsExactly(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP);
        assertThat(response.navOrder()).containsExactly(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP);
        verify(userPreferenceRepository).save(any(UserPreference.class));
    }

    @Test
    void should_returnExistingPreferences_when_preferenceExists() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS, Feature.SHOP),
                List.of(Feature.SHOP, Feature.SUBSCRIPTIONS)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));

        UserPreferenceResponse response = preferenceService.getPreferences(userId);

        assertThat(response.enabledFeatures()).containsExactly(Feature.SUBSCRIPTIONS, Feature.SHOP);
        assertThat(response.navOrder()).containsExactly(Feature.SHOP, Feature.SUBSCRIPTIONS);
    }

    // === US2: updatePreferences — auto-management navOrder ===

    @Test
    void should_removeDisabledFeatureFromNavOrder_when_navOrderNotProvided() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP),
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));
        when(userPreferenceRepository.save(any(UserPreference.class))).thenAnswer(i -> i.getArgument(0));

        var request = new UserPreferenceRequest(List.of(Feature.SUBSCRIPTIONS, Feature.SHOP), null, null, null, null, null, null, null);
        UserPreferenceResponse response = preferenceService.updatePreferences(request, userId);

        assertThat(response.enabledFeatures()).containsExactly(Feature.SUBSCRIPTIONS, Feature.SHOP);
        assertThat(response.navOrder()).containsExactly(Feature.SUBSCRIPTIONS, Feature.SHOP);
    }

    @Test
    void should_appendReactivatedFeatureAtEnd_when_navOrderNotProvided() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Feature.SUBSCRIPTIONS)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));
        when(userPreferenceRepository.save(any(UserPreference.class))).thenAnswer(i -> i.getArgument(0));

        var request = new UserPreferenceRequest(List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS), null, null, null, null, null, null, null);
        UserPreferenceResponse response = preferenceService.updatePreferences(request, userId);

        assertThat(response.navOrder()).containsExactly(Feature.SUBSCRIPTIONS, Feature.DEBTS);
    }

    @Test
    void should_acceptEmptyEnabledFeatures_when_allFeaturesDisabled() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP),
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));
        when(userPreferenceRepository.save(any(UserPreference.class))).thenAnswer(i -> i.getArgument(0));

        var request = new UserPreferenceRequest(List.of(), null, null, null, null, null, null, null);
        UserPreferenceResponse response = preferenceService.updatePreferences(request, userId);

        assertThat(response.enabledFeatures()).isEmpty();
        assertThat(response.navOrder()).isEmpty();
    }

    @Test
    void should_preserveRemainingOrder_when_featureRemovedFromMiddle() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP),
                List.of(Feature.SHOP, Feature.DEBTS, Feature.SUBSCRIPTIONS)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));
        when(userPreferenceRepository.save(any(UserPreference.class))).thenAnswer(i -> i.getArgument(0));

        var request = new UserPreferenceRequest(List.of(Feature.SHOP, Feature.SUBSCRIPTIONS), null, null, null, null, null, null, null);
        UserPreferenceResponse response = preferenceService.updatePreferences(request, userId);

        assertThat(response.navOrder()).containsExactly(Feature.SHOP, Feature.SUBSCRIPTIONS);
    }

    // === US3: updatePreferences — explicit navOrder validation ===

    @Test
    void should_acceptValidNavOrder_when_matchesEnabledFeatures() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP),
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));
        when(userPreferenceRepository.save(any(UserPreference.class))).thenAnswer(i -> i.getArgument(0));

        var request = new UserPreferenceRequest(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP),
                List.of(Feature.SHOP, Feature.DEBTS, Feature.SUBSCRIPTIONS),
                null, null, null, null, null, null
        );
        UserPreferenceResponse response = preferenceService.updatePreferences(request, userId);

        assertThat(response.navOrder()).containsExactly(Feature.SHOP, Feature.DEBTS, Feature.SUBSCRIPTIONS);
    }

    @Test
    void should_throw_when_navOrderContainsDuplicates() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS),
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));

        var request = new UserPreferenceRequest(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS),
                List.of(Feature.SUBSCRIPTIONS, Feature.SUBSCRIPTIONS),
                null, null, null, null, null, null
        );

        assertThatThrownBy(() -> preferenceService.updatePreferences(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("L'ordre de navigation ne doit pas contenir de doublons");
    }

    @Test
    void should_throw_when_navOrderMissingEnabledFeature() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS),
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));

        var request = new UserPreferenceRequest(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS),
                List.of(Feature.SUBSCRIPTIONS),
                null, null, null, null, null, null
        );

        assertThatThrownBy(() -> preferenceService.updatePreferences(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("L'ordre de navigation doit contenir exactement les fonctionnalités activées");
    }

    @Test
    void should_throw_when_navOrderContainsDisabledFeature() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Feature.SUBSCRIPTIONS)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));

        var request = new UserPreferenceRequest(
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS),
                null, null, null, null, null, null
        );

        assertThatThrownBy(() -> preferenceService.updatePreferences(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("L'ordre de navigation doit contenir exactement les fonctionnalités activées");
    }

    @Test
    void should_preserveExplicitNavOrderOrder() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP),
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));
        when(userPreferenceRepository.save(any(UserPreference.class))).thenAnswer(i -> i.getArgument(0));

        var request = new UserPreferenceRequest(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP),
                List.of(Feature.DEBTS, Feature.SHOP, Feature.SUBSCRIPTIONS),
                null, null, null, null, null, null
        );
        UserPreferenceResponse response = preferenceService.updatePreferences(request, userId);

        assertThat(response.navOrder()).containsExactly(Feature.DEBTS, Feature.SHOP, Feature.SUBSCRIPTIONS);
    }

    // === US4: updatePreferences — currencies & rebaseRates ===

    @Test
    void should_rebaseRates_when_primaryCurrencyChanges() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Currency.EUR)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));
        when(userPreferenceRepository.save(any(UserPreference.class))).thenAnswer(i -> i.getArgument(0));

        var request = new UserPreferenceRequest(List.of(Feature.SUBSCRIPTIONS), null, null, null, List.of(Currency.XOF, Currency.EUR), null, null, null);
        preferenceService.updatePreferences(request, userId);

        verify(exchangeRateService).rebaseRates(userId, Currency.EUR, Currency.XOF);
        verify(messagingTemplate).convertAndSendToUser(
                eq(userId.toString()),
                eq("/queue/exchange-rates"),
                any()
        );
    }

    @Test
    void should_notRebaseRates_when_primaryCurrencyUnchanged() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Currency.EUR, Currency.XOF)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));
        when(userPreferenceRepository.save(any(UserPreference.class))).thenAnswer(i -> i.getArgument(0));

        var request = new UserPreferenceRequest(List.of(Feature.SUBSCRIPTIONS), null, null, null, List.of(Currency.EUR, Currency.XOF, Currency.USD), null, null, null);
        preferenceService.updatePreferences(request, userId);

        verify(exchangeRateService, never()).rebaseRates(any(), any(), any());
        verify(messagingTemplate, never()).convertAndSendToUser(any(), any(), any());
    }

    @Test
    void should_rollbackPreferences_when_rebaseFails() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Currency.EUR)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));
        doThrow(new RuntimeException("Rebase failed")).when(exchangeRateService).rebaseRates(any(), any(), any());

        var request = new UserPreferenceRequest(List.of(Feature.SUBSCRIPTIONS), null, null, null, List.of(Currency.XOF), null, null, null);

        assertThatThrownBy(() -> preferenceService.updatePreferences(request, userId))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Rebase failed");
    }

    @Test
    void should_throw_when_currenciesEmpty() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Feature.SUBSCRIPTIONS)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));

        var request = new UserPreferenceRequest(List.of(Feature.SUBSCRIPTIONS), null, null, null, List.of(), null, null, null);

        assertThatThrownBy(() -> preferenceService.updatePreferences(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Au moins une devise requise");
    }

    @Test
    void should_throw_when_timezone_is_invalid() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Feature.SUBSCRIPTIONS)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));

        var request = new UserPreferenceRequest(List.of(Feature.SUBSCRIPTIONS), null, null, null, null, null, "Invalid/Timezone", null);

        assertThatThrownBy(() -> preferenceService.updatePreferences(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Timezone invalide");
    }

    @Test
    void should_throw_when_currenciesContainsDuplicates() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Feature.SUBSCRIPTIONS)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));

        var request = new UserPreferenceRequest(List.of(Feature.SUBSCRIPTIONS), null, null, null, List.of(Currency.EUR, Currency.XOF, Currency.EUR), null, null, null);

        assertThatThrownBy(() -> preferenceService.updatePreferences(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("La liste de devises ne doit pas contenir de doublons");
    }

    @Test
    void should_updateCurrencies_when_validList() {
        var preference = buildPreference(
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Feature.SUBSCRIPTIONS),
                List.of(Currency.EUR)
        );
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.of(preference));
        when(userPreferenceRepository.save(any(UserPreference.class))).thenAnswer(i -> i.getArgument(0));

        var request = new UserPreferenceRequest(List.of(Feature.SUBSCRIPTIONS), null, null, null, List.of(Currency.EUR, Currency.XOF, Currency.USD), null, null, null);
        UserPreferenceResponse response = preferenceService.updatePreferences(request, userId);

        assertThat(response.currencies()).containsExactly(Currency.EUR, Currency.XOF, Currency.USD);
    }
}
