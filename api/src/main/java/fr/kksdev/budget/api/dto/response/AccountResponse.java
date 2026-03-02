package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.AccountType;

import java.math.BigDecimal;
import java.util.UUID;

public record AccountResponse(
        UUID id,
        String nom,
        AccountType type,
        BigDecimal soldeInitial,
        BigDecimal solde,
        String icone,
        String couleur,
        boolean isDefault,
        boolean actif,
        String currency,
        boolean isShopAccount
) {}
