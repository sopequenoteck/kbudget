package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.DebtType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public record DebtRequest(
        @NotBlank @Size(max = 255) String personne,
        @NotNull @Positive BigDecimal montant,
        @NotNull DebtType sens,
        @NotNull LocalDate date,
        Boolean rembourse
) {}
