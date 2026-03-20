package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.model.Bank;

import java.util.List;
import java.util.Map;
import java.util.Optional;

public class BankRegistry {

    private static final Map<String, Bank> BANKS = Map.ofEntries(
            // France
            entry("SG", new Bank("SG", "Société Générale", "FR", "#e2001a", "/api/bank-logos/sg.svg")),
            entry("BNP", new Bank("BNP", "BNP Paribas", "FR", "#00915a", "/api/bank-logos/bnp.svg")),
            entry("CA", new Bank("CA", "Crédit Agricole", "FR", "#006f4e", "/api/bank-logos/ca.svg")),
            entry("LCL", new Bank("LCL", "LCL", "FR", "#0046a8", "/api/bank-logos/lcl.svg")),
            entry("CM", new Bank("CM", "Crédit Mutuel", "FR", "#005fa3", "/api/bank-logos/cm.svg")),
            entry("CE", new Bank("CE", "Caisse d'Épargne", "FR", "#cf0544", "/api/bank-logos/ce.svg")),
            entry("LBP", new Bank("LBP", "La Banque Postale", "FR", "#003d7c", "/api/bank-logos/lbp.svg")),
            entry("BP", new Bank("BP", "Banque Populaire", "FR", "#0055a4", "/api/bank-logos/bp.svg")),
            entry("BOURSO", new Bank("BOURSO", "Boursorama", "FR", "#ff6600", "/api/bank-logos/bourso.svg")),
            entry("FORTUNEO", new Bank("FORTUNEO", "Fortuneo", "FR", "#58595b", "/api/bank-logos/fortuneo.svg")),
            entry("HELLO", new Bank("HELLO", "Hello Bank", "FR", "#3a3a3a", "/api/bank-logos/hello.svg")),
            entry("N26", new Bank("N26", "N26", "FR", "#36a18b", "/api/bank-logos/n26.svg")),
            entry("REVOLUT", new Bank("REVOLUT", "Revolut", "FR", "#0075eb", "/api/bank-logos/revolut.svg")),
            entry("HSBC_FR", new Bank("HSBC_FR", "HSBC France", "FR", "#db0011", "/api/bank-logos/hsbc_fr.svg")),
            entry("BIA", new Bank("BIA", "BIA", "FR", "#003366", "/api/bank-logos/bia.svg")),
            // Togo/UEMOA
            entry("ECOBANK", new Bank("ECOBANK", "Ecobank", "TG", "#0033a0", "/api/bank-logos/ecobank.svg")),
            entry("BOA", new Bank("BOA", "Bank of Africa", "TG", "#e30613", "/api/bank-logos/boa.svg")),
            entry("ORABANK", new Bank("ORABANK", "Orabank", "TG", "#00a651", "/api/bank-logos/orabank.svg")),
            entry("CORIS", new Bank("CORIS", "Coris Bank", "TG", "#f7941d", "/api/bank-logos/coris.svg")),
            entry("BSIC", new Bank("BSIC", "BSIC", "TG", "#004a9f", "/api/bank-logos/bsic.svg")),
            entry("UTB", new Bank("UTB", "UTB", "TG", "#1a3c6e", "/api/bank-logos/utb.svg")),
            entry("SUNU", new Bank("SUNU", "SUNU Bank", "TG", "#0072bc", "/api/bank-logos/sunu.svg")),
            entry("BDT", new Bank("BDT", "Banque de Développement du Togo", "TG", "#006633", "/api/bank-logos/bdt.svg")),
            entry("NSIA", new Bank("NSIA", "NSIA Banque", "TG", "#003399", "/api/bank-logos/nsia.svg")),
            entry("BTCI", new Bank("BTCI", "BTCI", "TG", "#cc0033", "/api/bank-logos/btci.svg")),
            entry("SGTO", new Bank("SGTO", "Société Générale Togo", "TG", "#e2001a", "/api/bank-logos/sgto.svg")),
            entry("UBA", new Bank("UBA", "United Bank for Africa", "TG", "#d32011", "/api/bank-logos/uba.svg")),
            // International
            entry("WISE", new Bank("WISE", "Wise", null, "#9fe870", "/api/bank-logos/wise.svg")),
            // Special
            entry("OTHER", new Bank("OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg"))
    );

    private static final List<Bank> ALL_BANKS = List.copyOf(BANKS.values());

    private BankRegistry() {}

    private static Map.Entry<String, Bank> entry(String key, Bank bank) {
        return Map.entry(key, bank);
    }

    public static Optional<Bank> findByCode(String code) {
        if (code == null) {
            return Optional.empty();
        }
        return Optional.ofNullable(BANKS.get(code.toUpperCase()));
    }

    public static List<Bank> getAll() {
        return ALL_BANKS;
    }
}
