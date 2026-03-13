package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.BankResponse;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Bank;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;

@Service
public class BankService {

    public List<BankResponse> getAllBanks() {
        return BankRegistry.getAll().stream()
                .sorted(Comparator
                        .comparingInt(this::countryGroup)
                        .thenComparing(b -> b.name()))
                .map(b -> new BankResponse(b.code(), b.name(), b.country(), b.brandColor(), b.logoUrl()))
                .toList();
    }

    public BankResolvedInfo resolveBank(Account account) {
        Bank bank = BankRegistry.findByCode(account.getBankCode())
                .orElse(BankRegistry.findByCode("OTHER").orElseThrow());

        if ("OTHER".equals(account.getBankCode())) {
            return new BankResolvedInfo(
                    bank.code(),
                    account.getBankCustomName() != null ? account.getBankCustomName() : bank.name(),
                    bank.country(),
                    bank.brandColor(),
                    bank.logoUrl(),
                    account.getBankCustomName(),
                    account.getBankCustomLogo()
            );
        }

        return new BankResolvedInfo(
                bank.code(), bank.name(), bank.country(), bank.brandColor(), bank.logoUrl(), null, null
        );
    }

    private int countryGroup(Bank bank) {
        if ("OTHER".equals(bank.code())) return 3;
        if ("FR".equals(bank.country())) return 0;
        if ("TG".equals(bank.country())) return 1;
        return 2;
    }

    public record BankResolvedInfo(
            String bankCode,
            String bankName,
            String bankCountry,
            String bankBrandColor,
            String bankLogoUrl,
            String bankCustomName,
            String bankCustomLogo
    ) {}
}
