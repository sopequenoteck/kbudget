package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.DebtType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record DebtResponse(
        UUID id,
        String personne,
        BigDecimal montant,
        DebtType sens,
        LocalDate date,
        Boolean rembourse
) {}
