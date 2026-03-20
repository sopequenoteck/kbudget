package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record SubscriptionPaymentResponse(
        UUID id,
        BigDecimal montant,
        LocalDate date,
        String subscriptionName,
        String accountName
) {}
