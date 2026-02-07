package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.TransactionType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public record TransactionRequest(
        @NotNull @Positive BigDecimal montant,
        @NotBlank @Size(max = 255) String libelle,
        @NotNull TransactionType type,
        @NotNull LocalDate date,
        @Size(max = 255) String categorie,
        @Size(max = 500) String note
) {}
