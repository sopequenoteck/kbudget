package fr.kksdev.budget.api.service;

import java.util.List;
import java.util.Map;
import java.util.Optional;

public class ImportProfileRegistry {

    public record ImportProfileConfig(
            String bankCode,
            String name,
            String separator,
            String dateFormat,
            String dateColumn,
            String amountColumn,
            String debitColumn,
            String creditColumn,
            String labelColumn,
            String encoding,
            String decimalSeparator,
            int skipHeaderLines,
            List<String> cleanupPatterns
    ) {}

    private static final Map<String, ImportProfileConfig> PROFILES = Map.ofEntries(
            entry("SG", new ImportProfileConfig(
                    "SG",
                    "Société Générale",
                    ";",
                    "dd/MM/yyyy",
                    "Date de l'opération",
                    "Montant de l'opération",
                    null,
                    null,
                    "Détail de l'écriture",
                    "ISO-8859-1",
                    ",",
                    1,
                    List.of(
                            "CARTE\\s+\\w+\\d{4}\\s+\\d{2}/\\d{2}\\s+",
                            "CARTE\\s+\\w+\\d{4}\\s+TRANSF\\s+\\d{2}/\\d{2}\\s+",
                            "UEP\\*"
                    )
            ))
    );

    private static final List<ImportProfileConfig> ALL_PROFILES = List.copyOf(PROFILES.values());

    private ImportProfileRegistry() {}

    private static Map.Entry<String, ImportProfileConfig> entry(String key, ImportProfileConfig profile) {
        return Map.entry(key, profile);
    }

    public static Optional<ImportProfileConfig> findByBankCode(String bankCode) {
        if (bankCode == null) {
            return Optional.empty();
        }
        return Optional.ofNullable(PROFILES.get(bankCode.toUpperCase()));
    }

    public static List<ImportProfileConfig> getAll() {
        return ALL_PROFILES;
    }
}
