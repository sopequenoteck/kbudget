package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Bank;
import fr.kksdev.budget.api.service.BankRegistry;

import java.util.UUID;

public record AccountSummary(
        UUID id,
        String nom,
        String icone,
        String couleur,
        String currency,
        String bankLogoUrl,
        String bankCustomLogo
) {
    public static AccountSummary from(Account account) {
        if (account == null) {
            return null;
        }
        String logoUrl = BankRegistry.findByCode(account.getBankCode())
                .map(Bank::logoUrl)
                .orElse(null);

        return new AccountSummary(
                account.getId(),
                account.getNom(),
                account.getIcone(),
                account.getCouleur(),
                account.getCurrency().name(),
                logoUrl,
                account.getBankCustomLogo()
        );
    }
}
