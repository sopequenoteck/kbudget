package fr.kksdev.budget.api.dto;

import fr.kksdev.budget.api.enums.DebtType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.time.LocalDate;

public record DebtRequest(
        @NotBlank String personne,
        @NotNull @Positive BigDecimal montant,
        @NotNull DebtType sens,
        @NotNull LocalDate date,
        Boolean rembourse
) {}
