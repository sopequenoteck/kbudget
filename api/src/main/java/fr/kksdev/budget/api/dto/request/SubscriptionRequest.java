package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.Frequency;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record SubscriptionRequest(
        @NotBlank @Size(max = 255) String nom,
        @NotNull @Positive BigDecimal montant,
        @NotNull Frequency frequence,
        @NotNull LocalDate dateDebut,
        Boolean actif,
        UUID categoryId
) {}
