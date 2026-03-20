package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.model.Account;

import java.util.UUID;

public record AccountSummary(
        UUID id,
        String nom,
        String icone,
        String couleur,
        String currency
) {
    public static AccountSummary from(Account account) {
        if (account == null) {
            return null;
        }
        return new AccountSummary(
                account.getId(),
                account.getNom(),
                account.getIcone(),
                account.getCouleur(),
                account.getCurrency().name()
        );
    }
}
