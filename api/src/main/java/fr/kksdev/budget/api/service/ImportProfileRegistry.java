package fr.kksdev.budget.api.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/**
 * Bank profiles shipped with the application, loaded at startup from
 * {@code classpath*:import-profiles/*.yaml} (KKS-440).
 *
 * <p>A file that cannot be read or that fails validation is logged and ignored:
 * it never prevents the application from starting.
 */
@Slf4j
@Component
public class ImportProfileRegistry {

    static final String DEFAULT_LOCATION = "classpath*:import-profiles/*.yaml";

    /**
     * @param signatureColumns   header columns that identify the file format; for a custom
     *                           profile, its mapped columns
     * @param statementHeader    bank header of the statement, or {@code null}
     * @param purchaseDate       purchase date carried by the label, or {@code null}
     */
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
            List<String> cleanupPatterns,
            List<String> signatureColumns,
            StatementHeaderSpec statementHeader,
            PurchaseDateSpec purchaseDate
    ) {}

    private final Map<String, ImportProfileConfig> profiles;

    @Autowired
    public ImportProfileRegistry() {
        this(DEFAULT_LOCATION);
    }

    ImportProfileRegistry(String locationPattern) {
        this(locationPattern, new PathMatchingResourcePatternResolver());
    }

    ImportProfileRegistry(String locationPattern, ResourcePatternResolver resolver) {
        this.profiles = load(locationPattern, resolver);
        log.info("Import profiles loaded: {}", profiles.keySet());
    }

    public Optional<ImportProfileConfig> findByBankCode(String bankCode) {
        if (bankCode == null) {
            return Optional.empty();
        }
        return Optional.ofNullable(profiles.get(bankCode.toUpperCase(Locale.ROOT)));
    }

    public List<ImportProfileConfig> getAll() {
        return List.copyOf(profiles.values());
    }

    private static Map<String, ImportProfileConfig> load(String locationPattern, ResourcePatternResolver resolver) {
        Map<String, ImportProfileConfig> loaded = new LinkedHashMap<>();
        Resource[] resources;
        try {
            resources = resolver.getResources(locationPattern);
        } catch (IOException e) {
            log.warn("Import profiles could not be listed from '{}': {}", locationPattern, e.getMessage());
            return loaded;
        }
        // Sorted, so that which profile is kept on a duplicate bank code does not depend on the classpath order.
        Arrays.sort(resources, Comparator.comparing(Resource::getDescription));
        for (Resource resource : resources) {
            try (Reader reader = new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8)) {
                ImportProfileConfig config = ImportProfileFileParser.parse(reader);
                if (loaded.putIfAbsent(config.bankCode(), config) != null) {
                    log.warn("Import profile file ignored: {} (bank code {} already loaded)",
                            resource.getDescription(), config.bankCode());
                }
            } catch (IOException | RuntimeException e) {
                log.warn("Import profile file ignored: {} ({})", resource.getDescription(), e.getMessage());
            }
        }
        return loaded;
    }
}
