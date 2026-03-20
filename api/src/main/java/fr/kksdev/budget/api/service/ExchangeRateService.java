package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.ExchangeRateRequest;
import fr.kksdev.budget.api.dto.response.ExchangeRateResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.model.ExchangeRate;
import fr.kksdev.budget.api.repository.ExchangeRateRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ExchangeRateService {

    private final ExchangeRateRepository exchangeRateRepository;
    private final UserRepository userRepository;

    public List<ExchangeRateResponse> getAll(UUID userId) {
        return exchangeRateRepository.findAllByUserId(userId).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public ExchangeRateResponse upsert(ExchangeRateRequest request, UUID userId) {
        if (request.baseCurrency() == request.targetCurrency()) {
            throw new IllegalArgumentException("Les devises de base et cible doivent être différentes");
        }
        if (request.rate().compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Le taux doit être strictement positif");
        }

        ExchangeRate rate = exchangeRateRepository
                .findByUserIdAndBaseCurrencyAndTargetCurrency(userId, request.baseCurrency(), request.targetCurrency())
                .map(existing -> {
                    existing.setRate(request.rate());
                    log.info("Taux mis à jour: {}/{} = {} pour userId={}",
                            request.baseCurrency(), request.targetCurrency(), request.rate(), userId);
                    return existing;
                })
                .orElseGet(() -> {
                    log.info("Taux créé: {}/{} = {} pour userId={}",
                            request.baseCurrency(), request.targetCurrency(), request.rate(), userId);
                    return ExchangeRate.builder()
                            .user(userRepository.getReferenceById(userId))
                            .baseCurrency(request.baseCurrency())
                            .targetCurrency(request.targetCurrency())
                            .rate(request.rate())
                            .build();
                });

        rate = exchangeRateRepository.save(rate);
        return toResponse(rate);
    }

    @Transactional
    public void delete(UUID userId, Currency baseCurrency, Currency targetCurrency) {
        ExchangeRate rate = exchangeRateRepository
                .findByUserIdAndBaseCurrencyAndTargetCurrency(userId, baseCurrency, targetCurrency)
                .orElseThrow(() -> new EntityNotFoundException("Taux non trouvé"));
        exchangeRateRepository.delete(rate);
        log.info("Taux supprimé: {}/{} pour userId={}", baseCurrency, targetCurrency, userId);
    }

    @Transactional
    public void rebaseRates(UUID userId, Currency oldBaseCurrency, Currency newBaseCurrency) {
        List<ExchangeRate> rates = exchangeRateRepository.findAllByUserId(userId);

        BigDecimal pivotRate = findPivotRate(rates, oldBaseCurrency, newBaseCurrency);
        if (pivotRate == null) {
            log.warn("Taux pivot manquant {} → {} — rebase ignoré pour userId={}", oldBaseCurrency, newBaseCurrency, userId);
            return;
        }

        for (ExchangeRate rate : rates) {
            if (rate.getBaseCurrency() != oldBaseCurrency) continue;

            if (rate.getTargetCurrency() == newBaseCurrency) {
                BigDecimal inverted = BigDecimal.ONE.divide(rate.getRate(), 6, RoundingMode.HALF_UP);
                rate.setBaseCurrency(newBaseCurrency);
                rate.setTargetCurrency(oldBaseCurrency);
                rate.setRate(inverted);
            } else {
                BigDecimal crossRate = rate.getRate().divide(pivotRate, 6, RoundingMode.HALF_UP);
                rate.setBaseCurrency(newBaseCurrency);
                rate.setRate(crossRate);
            }
            exchangeRateRepository.save(rate);
            log.info("Taux rebasé: {}/{} = {} pour userId={}", rate.getBaseCurrency(), rate.getTargetCurrency(), rate.getRate(), userId);
        }
    }

    public Optional<BigDecimal> getRate(UUID userId, Currency from, Currency to) {
        if (from == to) return Optional.of(BigDecimal.ONE);
        Optional<BigDecimal> rate = exchangeRateRepository.findByUserIdAndBaseCurrencyAndTargetCurrency(userId, from, to)
                .map(ExchangeRate::getRate);
        if (rate.isPresent()) return rate;
        Optional<BigDecimal> inverse = exchangeRateRepository.findByUserIdAndBaseCurrencyAndTargetCurrency(userId, to, from)
                .map(ExchangeRate::getRate);
        if (inverse.isPresent()) {
            return Optional.of(BigDecimal.ONE.divide(inverse.get(), 6, RoundingMode.HALF_UP));
        }
        return Optional.empty();
    }

    private BigDecimal findPivotRate(List<ExchangeRate> rates, Currency from, Currency to) {
        for (ExchangeRate r : rates) {
            if (r.getBaseCurrency() == from && r.getTargetCurrency() == to) return r.getRate();
        }
        for (ExchangeRate r : rates) {
            if (r.getBaseCurrency() == to && r.getTargetCurrency() == from) {
                return BigDecimal.ONE.divide(r.getRate(), 6, RoundingMode.HALF_UP);
            }
        }
        return null;
    }

    private ExchangeRateResponse toResponse(ExchangeRate rate) {
        return new ExchangeRateResponse(
                rate.getId(),
                rate.getBaseCurrency().name(),
                rate.getTargetCurrency().name(),
                rate.getRate(),
                rate.getUpdatedAt()
        );
    }
}
