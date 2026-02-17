package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Currency;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record AccountRequest(
        @NotBlank @Size(min = 1, max = 50) String nom,
        @NotNull AccountType type,
        BigDecimal soldeInitial,
        String icone,
        @Pattern(regexp = "^#[0-9a-fA-F]{6}$", message = "Couleur invalide (format hex attendu)") String couleur,
        Boolean actif,
        Currency currency
) {}
