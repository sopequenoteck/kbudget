package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.model.ExchangeRate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ExchangeRateRepository extends JpaRepository<ExchangeRate, UUID> {

    List<ExchangeRate> findAllByUserId(UUID userId);

    Optional<ExchangeRate> findByUserIdAndBaseCurrencyAndTargetCurrency(UUID userId, Currency baseCurrency, Currency targetCurrency);
}
