package fr.kksdev.budget.api.dto;

import fr.kksdev.budget.api.enums.TransactionType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record TransactionResponse(
        UUID id,
        BigDecimal montant,
        String libelle,
        TransactionType type,
        LocalDate date,
        String categorie,
        String note
) {}
