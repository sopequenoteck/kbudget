package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.*;

import java.math.BigDecimal;

public record ProductUpdateRequest(
        @NotBlank @Size(max = 100) String nom,
        @Size(max = 500) String description,
        String icone,
        @Size(max = 500) String imageUrl,
        @NotNull @Positive @Digits(integer = 10, fraction = 2) BigDecimal prixAchat,
        @NotNull @Positive @Digits(integer = 10, fraction = 2) BigDecimal prixVente,
        @NotNull @Min(0) Integer stock,
        @NotNull Boolean actif
) {}
