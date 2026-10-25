package fr.kksdev.budget.api.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/**
 * Bank profiles loaded at startup: first those shipped with the application, from
 * {@code classpath*:import-profiles/*.yaml} (KKS-440), then the {@code *.yaml} files of the
 * external directory {@code app.import-profiles.external-dir}, sorted by name (KKS-329).
 * On a duplicate bank code, the first profile loaded is kept: an external file never
 * replaces a bundled profile.
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
     * @param contributor        who provided the profile (name or nickname), or {@code null}
     * @param validatedOn        date of the last statement the profile was checked on, or {@code null}
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
            PurchaseDateSpec purchaseDate,
            String contributor,
            LocalDate validatedOn
    ) {

        /** Profile without contribution metadata. */
        public ImportProfileConfig(
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
        ) {
            this(bankCode, name, separator, dateFormat, dateColumn, amountColumn, debitColumn, creditColumn,
                    labelColumn, encoding, decimalSeparator, skipHeaderLines, cleanupPatterns, signatureColumns,
                    statementHeader, purchaseDate, null, null);
        }
    }

    private final Map<String, ImportProfileConfig> profiles;

    public ImportProfileRegistry() {
        this(DEFAULT_LOCATION);
    }

    ImportProfileRegistry(String locationPattern) {
        this(locationPattern, new PathMatchingResourcePatternResolver());
    }

    /** Spring constructor; {@code DEFAULT_LOCATION} holds no placeholder, so it is injected as is. */
    @Autowired
    ImportProfileRegistry(@Value(DEFAULT_LOCATION) String locationPattern,
                          @Value("${app.import-profiles.external-dir:}") String externalDir) {
        this(locationPattern, new PathMatchingResourcePatternResolver(), externalDir);
    }

    ImportProfileRegistry(String locationPattern, ResourcePatternResolver resolver) {
        this(locationPattern, resolver, null);
    }

    private ImportProfileRegistry(String locationPattern, ResourcePatternResolver resolver, String externalDir) {
        Map<String, ImportProfileConfig> loaded = new LinkedHashMap<>();
        load(locationPattern, resolver, loaded);
        if (externalDir != null && !externalDir.isBlank()) {
            loadExternal(externalDir.strip(), loaded);
        }
        this.profiles = loaded;
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

    private static void load(String locationPattern, ResourcePatternResolver resolver,
                             Map<String, ImportProfileConfig> loaded) {
        Resource[] resources;
        try {
            resources = resolver.getResources(locationPattern);
        } catch (IOException e) {
            log.warn("Import profiles could not be listed from '{}': {}", locationPattern, e.getMessage());
            return;
        }
        // Sorted, so that which profile is kept on a duplicate bank code does not depend on the classpath order.
        Arrays.sort(resources, Comparator.comparing(Resource::getDescription));
        for (Resource resource : resources) {
            try (Reader reader = new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8)) {
                register(ImportProfileFileParser.parse(reader), resource.getDescription(), loaded);
            } catch (IOException | RuntimeException e) {
                log.warn("Import profile file ignored: {} ({})", resource.getDescription(), e.getMessage());
            }
        }
    }

    /** Read with java.nio rather than a resource pattern, so that the path is never read as a pattern. */
    private static void loadExternal(String directory, Map<String, ImportProfileConfig> loaded) {
        List<Path> files = new ArrayList<>();
        try (DirectoryStream<Path> stream = Files.newDirectoryStream(Path.of(directory), "*.yaml")) {
            stream.forEach(files::add);
        } catch (IOException | RuntimeException e) {
            log.info("External import profiles directory not read: {} ({})", directory, e.getMessage());
            return;
        }
        files.sort(Comparator.comparing(file -> file.getFileName().toString()));
        for (Path file : files) {
            try (Reader reader = Files.newBufferedReader(file, StandardCharsets.UTF_8)) {
                register(ImportProfileFileParser.parse(reader), file.toString(), loaded);
            } catch (IOException | RuntimeException e) {
                log.warn("Import profile file ignored: {} ({})", file, e.getMessage());
            }
        }
    }

    private static void register(ImportProfileConfig config, String source, Map<String, ImportProfileConfig> loaded) {
        if (loaded.putIfAbsent(config.bankCode(), config) != null) {
            log.warn("Import profile file ignored: {} (bank code {} already loaded)", source, config.bankCode());
        }
    }
}
