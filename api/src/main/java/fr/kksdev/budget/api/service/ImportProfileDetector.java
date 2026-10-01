package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.ImportProfileSource;
import fr.kksdev.budget.api.model.ImportProfile;
import fr.kksdev.budget.api.repository.ImportProfileRepository;
import fr.kksdev.budget.api.service.ImportProfileRegistry.ImportProfileConfig;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;

/**
 * Finds the import profile that fits an uploaded file (KKS-440), from the file
 * itself rather than from the bank of the account.
 *
 * <p>A file is recognized by a profile when every column of the profile
 * signature is on the column header line, read with the encoding, separator
 * and header lines of that profile. The signature of a bundled profile is
 * declared in its file; the one of a custom profile is its mapped columns.
 */
@Service
@RequiredArgsConstructor
public class ImportProfileDetector {

    /** @param customProfileId id of the matched custom profile, {@code null} for a bundled one */
    public record Detection(ImportProfileConfig config, ImportProfileSource source, UUID customProfileId) {}

    private final ImportProfileRegistry registry;
    private final ImportProfileRepository importProfileRepository;
    private final CsvParsingService csvParsingService;

    /**
     * Recognizes the file by signature only: bundled profiles first, then the
     * custom profiles of {@code userId}, most recently modified first. The
     * profiles of other users are never read.
     */
    public Optional<Detection> detect(byte[] content, UUID userId) {
        Optional<Detection> bundled = registry.getAll().stream()
                .filter(profile -> recognizes(content, profile))
                .findFirst()
                .map(profile -> new Detection(profile, ImportProfileSource.REGISTRY, null));
        if (bundled.isPresent()) {
            return bundled;
        }
        return importProfileRepository.findByUserIdOrderByUpdatedAtDescIdDesc(userId).stream()
                .map(custom -> new Detection(toConfig(custom), ImportProfileSource.CUSTOM, custom.getId()))
                .filter(detection -> recognizes(content, detection.config()))
                .findFirst();
    }

    /**
     * {@link #detect} first; failing that, the bundled profile of the bank of
     * the account, as before the signature existed.
     */
    public Optional<Detection> resolve(byte[] content, String bankCode, UUID userId) {
        Optional<Detection> detected = detect(content, userId);
        if (detected.isPresent()) {
            return detected;
        }
        return registry.findByBankCode(bankCode)
                .map(profile -> new Detection(profile, ImportProfileSource.REGISTRY, null));
    }

    private boolean recognizes(byte[] content, ImportProfileConfig profile) {
        if (profile.signatureColumns().isEmpty()) {
            return false;
        }
        Set<String> found = new HashSet<>();
        csvParsingService.readHeaderColumns(content, profile).forEach(column -> found.add(normalize(column)));
        return profile.signatureColumns().stream().map(ImportProfileDetector::normalize).allMatch(found::contains);
    }

    private static String normalize(String column) {
        return column.trim();
    }

    private static ImportProfileConfig toConfig(ImportProfile profile) {
        List<String> mappedColumns = Stream.of(profile.getDateColumn(), profile.getLabelColumn(),
                        profile.getAmountColumn(), profile.getDebitColumn(), profile.getCreditColumn())
                .filter(StringUtils::hasText)
                .toList();
        return new ImportProfileConfig(
                null,
                profile.getName(),
                profile.getSeparator(),
                profile.getDateFormat(),
                profile.getDateColumn(),
                profile.getAmountColumn(),
                profile.getDebitColumn(),
                profile.getCreditColumn(),
                profile.getLabelColumn(),
                profile.getEncoding(),
                profile.getDecimalSeparator(),
                profile.getSkipHeaderLines() != null ? profile.getSkipHeaderLines() : 0,
                List.of(),
                mappedColumns,
                null,
                null);
    }
}
