package fr.kksdev.budget.api.dto;

import fr.kksdev.budget.api.enums.Frequency;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.time.LocalDate;

public record SubscriptionRequest(
        @NotBlank String nom,
        @NotNull @Positive BigDecimal montant,
        @NotNull Frequency frequence,
        @NotNull LocalDate dateDebut,
        Boolean actif
) {}
