package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.BankResponse;
import fr.kksdev.budget.api.model.Account;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class BankServiceTest {

    private final BankService bankService = new BankService();

    @Test
    void should_returnAllBanks_when_getAllBanks() {
        List<BankResponse> banks = bankService.getAllBanks();

        assertThat(banks).hasSize(29);
    }

    @Test
    void should_sortFrenchBanksFirst_when_getAllBanks() {
        List<BankResponse> banks = bankService.getAllBanks();

        assertThat(banks.get(0).country()).isEqualTo("FR");
        assertThat(banks.get(1).country()).isEqualTo("FR");
        assertThat(banks.get(2).country()).isEqualTo("FR");
    }

    @Test
    void should_sortTogoBanksAfterFrench_when_getAllBanks() {
        List<BankResponse> banks = bankService.getAllBanks();

        long frCount = banks.stream().filter(b -> "FR".equals(b.country())).count();
        long tgCount = banks.stream().filter(b -> "TG".equals(b.country())).count();

        assertThat(frCount).isGreaterThan(0);
        assertThat(tgCount).isGreaterThan(0);

        int lastFrIndex = -1;
        int firstTgIndex = Integer.MAX_VALUE;
        for (int i = 0; i < banks.size(); i++) {
            if ("FR".equals(banks.get(i).country())) lastFrIndex = i;
            if ("TG".equals(banks.get(i).country()) && i < firstTgIndex) firstTgIndex = i;
        }

        assertThat(lastFrIndex).isLessThan(firstTgIndex);
    }

    @Test
    void should_putOtherLast_when_getAllBanks() {
        List<BankResponse> banks = bankService.getAllBanks();

        BankResponse last = banks.get(banks.size() - 1);
        assertThat(last.code()).isEqualTo("OTHER");
    }

    @Test
    void should_sortAlphabeticallyWithinCountry_when_getAllBanks() {
        List<BankResponse> banks = bankService.getAllBanks();

        List<String> frNames = banks.stream()
                .filter(b -> "FR".equals(b.country()))
                .map(BankResponse::name)
                .toList();

        for (int i = 0; i < frNames.size() - 1; i++) {
            assertThat(frNames.get(i).compareTo(frNames.get(i + 1))).isLessThanOrEqualTo(0);
        }
    }

    @Test
    void should_resolveKnownBank_when_validBankCode() {
        Account account = Account.builder().bankCode("SG").build();

        BankService.BankResolvedInfo info = bankService.resolveBank(account);

        assertThat(info.bankCode()).isEqualTo("SG");
        assertThat(info.bankName()).isEqualTo("Société Générale");
        assertThat(info.bankBrandColor()).isEqualTo("#e2001a");
        assertThat(info.bankCustomName()).isNull();
        assertThat(info.bankCustomLogo()).isNull();
    }

    @Test
    void should_resolveOtherWithCustomFields_when_otherBankCode() {
        Account account = Account.builder()
                .bankCode("OTHER")
                .bankCustomName("Ma Banque")
                .bankCustomLogo("data:image/png;base64,abc")
                .build();

        BankService.BankResolvedInfo info = bankService.resolveBank(account);

        assertThat(info.bankCode()).isEqualTo("OTHER");
        assertThat(info.bankCustomName()).isEqualTo("Ma Banque");
        assertThat(info.bankCustomLogo()).isEqualTo("data:image/png;base64,abc");
    }

    @Test
    void should_ignoreCustomFields_when_knownBankCode() {
        Account account = Account.builder()
                .bankCode("SG")
                .bankCustomName("Should be ignored")
                .bankCustomLogo("ignored")
                .build();

        BankService.BankResolvedInfo info = bankService.resolveBank(account);

        assertThat(info.bankCode()).isEqualTo("SG");
        assertThat(info.bankCustomName()).isNull();
        assertThat(info.bankCustomLogo()).isNull();
    }
}
