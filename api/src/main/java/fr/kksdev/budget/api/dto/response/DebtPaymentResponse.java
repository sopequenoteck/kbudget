package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record DebtPaymentResponse(
        UUID id,
        BigDecimal amount,
        LocalDate date,
        String accountName
) {}
