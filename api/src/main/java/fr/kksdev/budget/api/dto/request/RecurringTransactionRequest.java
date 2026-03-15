package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.TransactionType;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record RecurringTransactionRequest(
        @NotNull @Positive BigDecimal montant,
        @NotBlank @Size(max = 255) String libelle,
        @NotNull TransactionType type,
        @NotNull Frequency frequency,
        @NotNull @FutureOrPresent LocalDate nextOccurrence,
        UUID categoryId,
        UUID accountId,
        @Size(max = 500) String note
) {}
