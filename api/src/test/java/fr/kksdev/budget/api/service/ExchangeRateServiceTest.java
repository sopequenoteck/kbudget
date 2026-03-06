package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.ExchangeRateRequest;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.model.ExchangeRate;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.ExchangeRateRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ExchangeRateServiceTest {

    @Mock
    private ExchangeRateRepository exchangeRateRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private ExchangeRateService exchangeRateService;

    private final UUID userId = UUID.randomUUID();

    private ExchangeRate buildRate(Currency base, Currency target, String rate) {
        return ExchangeRate.builder()
                .id(UUID.randomUUID())
                .user(User.builder().id(userId).build())
                .baseCurrency(base)
                .targetCurrency(target)
                .rate(new BigDecimal(rate))
                .build();
    }

    @Test
    void should_invertAllRates_when_rebase() {
        var rate = buildRate(Currency.EUR, Currency.XOF, "2.000000");
        when(exchangeRateRepository.findAllByUserId(userId)).thenReturn(List.of(rate));
        when(exchangeRateRepository.save(any(ExchangeRate.class))).thenAnswer(invocation -> invocation.getArgument(0));

        exchangeRateService.rebaseRates(userId, Currency.XOF);

        assertThat(rate.getBaseCurrency()).isEqualTo(Currency.XOF);
        assertThat(rate.getTargetCurrency()).isEqualTo(Currency.EUR);
        assertThat(rate.getRate()).isEqualByComparingTo("0.500000");
        verify(exchangeRateRepository).save(rate);
    }

    @Test
    void should_preservePrecision_when_invertHighRate() {
        var rate = buildRate(Currency.EUR, Currency.XOF, "655.957000");
        when(exchangeRateRepository.findAllByUserId(userId)).thenReturn(List.of(rate));
        when(exchangeRateRepository.save(any(ExchangeRate.class))).thenAnswer(invocation -> invocation.getArgument(0));

        exchangeRateService.rebaseRates(userId, Currency.XOF);

        // 1 / 655.957 = 0.001524 (HALF_UP, 6 decimal places)
        assertThat(rate.getRate()).isEqualByComparingTo("0.001524");
    }

    @Test
    void should_rejectNegativeRate() {
        var request = new ExchangeRateRequest(Currency.EUR, Currency.XOF, new BigDecimal("-1.000000"));

        assertThatThrownBy(() -> exchangeRateService.upsert(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Le taux doit être strictement positif");
    }

    @Test
    void should_rejectZeroRate() {
        var request = new ExchangeRateRequest(Currency.EUR, Currency.XOF, BigDecimal.ZERO);

        assertThatThrownBy(() -> exchangeRateService.upsert(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Le taux doit être strictement positif");
    }

    @Test
    void should_upsertExistingPair() {
        var existing = buildRate(Currency.EUR, Currency.XOF, "655.957000");
        var request = new ExchangeRateRequest(Currency.EUR, Currency.XOF, new BigDecimal("660.000000"));

        when(exchangeRateRepository.findByUserIdAndBaseCurrencyAndTargetCurrency(userId, Currency.EUR, Currency.XOF))
                .thenReturn(Optional.of(existing));
        when(exchangeRateRepository.save(any(ExchangeRate.class))).thenAnswer(invocation -> invocation.getArgument(0));

        var response = exchangeRateService.upsert(request, userId);

        assertThat(response.baseCurrency()).isEqualTo("EUR");
        assertThat(response.targetCurrency()).isEqualTo("XOF");
        assertThat(response.rate()).isEqualByComparingTo("660.000000");
        // No new entity created — save called once on the existing object
        verify(exchangeRateRepository).save(existing);
        verify(userRepository, never()).getReferenceById(any());
    }
}
