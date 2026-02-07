package fr.kksdev.budget.api.dto;

import fr.kksdev.budget.api.enums.TransactionType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.time.LocalDate;

public record TransactionRequest(
        @NotNull @Positive BigDecimal montant,
        @NotBlank String libelle,
        @NotNull TransactionType type,
        @NotNull LocalDate date,
        String categorie,
        String note
) {}
