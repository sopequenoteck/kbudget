package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.service.ImportProfileRegistry.ImportProfileConfig;
import org.yaml.snakeyaml.LoaderOptions;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.SafeConstructor;

import java.io.Reader;
import java.nio.charset.Charset;
import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.Month;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * Reads and validates an import profile file (KKS-440). Every problem is raised
 * as an {@link IllegalArgumentException} naming the offending key, so that the
 * registry can log it and ignore the file.
 */
final class ImportProfileFileParser {

    static final int SUPPORTED_FORMAT_VERSION = 1;

    private static final String SIGNATURE = "signature";
    private static final String STATEMENT_HEADER = "statementHeader";
    private static final String PURCHASE_DATE = "purchaseDate";

    private ImportProfileFileParser() {}

    static ImportProfileConfig parse(Reader reader) {
        Object root = new Yaml(new SafeConstructor(new LoaderOptions())).load(reader);
        if (!(root instanceof Map<?, ?> map)) {
            throw new IllegalArgumentException("The file must contain a mapping");
        }
        return toConfig(map);
    }

    private static ImportProfileConfig toConfig(Map<?, ?> file) {
        checkFormatVersion(file.get("formatVersion"));

        String dateFormat = readableDateFormat(requiredString(file, "dateFormat"));

        String amountColumn = optionalString(file, "amountColumn");
        String debitColumn = optionalString(file, "debitColumn");
        String creditColumn = optionalString(file, "creditColumn");
        if (amountColumn == null && (debitColumn == null || creditColumn == null)) {
            throw new IllegalArgumentException(
                    "A profile needs amountColumn, or both debitColumn and creditColumn");
        }

        return new ImportProfileConfig(
                requiredString(file, "bankCode").toUpperCase(Locale.ROOT),
                requiredString(file, "name"),
                singleCharacter(file, "separator"),
                dateFormat,
                requiredString(file, "dateColumn"),
                amountColumn,
                debitColumn,
                creditColumn,
                requiredString(file, "labelColumn"),
                supportedEncoding(requiredString(file, "encoding")),
                singleCharacter(file, "decimalSeparator"),
                skipHeaderLines(file.get("skipHeaderLines")),
                cleanupPatterns(file.get("cleanupPatterns")),
                signatureColumns(file.get(SIGNATURE)),
                statementHeader(file.get(STATEMENT_HEADER)),
                purchaseDate(file.get(PURCHASE_DATE)));
    }

    private static void checkFormatVersion(Object version) {
        if (version == null) {
            throw required("formatVersion");
        }
        if (!Integer.valueOf(SUPPORTED_FORMAT_VERSION).equals(version)) {
            throw new IllegalArgumentException("Unsupported formatVersion: " + version);
        }
    }

    /** The format must be able to read a full date, as the import reads each operation date with it. */
    private static String readableDateFormat(String pattern) {
        if (!readsFullDate(DateTimeFormatter.ofPattern(pattern))) {
            throw new IllegalArgumentException("dateFormat must read a full date (day, month and year): " + pattern);
        }
        return pattern;
    }

    private static boolean readsFullDate(DateTimeFormatter formatter) {
        LocalDate sample = LocalDate.of(2000, Month.JANUARY, 31);
        try {
            return sample.equals(LocalDate.parse(sample.format(formatter), formatter));
        } catch (DateTimeException e) {
            return false;
        }
    }

    private static String supportedEncoding(String encoding) {
        if (!Charset.isSupported(encoding)) {
            throw new IllegalArgumentException("Unsupported encoding: " + encoding);
        }
        return encoding;
    }

    private static int skipHeaderLines(Object value) {
        if (value == null) {
            return 0;
        }
        if (value instanceof Integer count && count >= 0) {
            return count;
        }
        throw new IllegalArgumentException("skipHeaderLines must be a non-negative integer");
    }

    private static List<String> cleanupPatterns(Object value) {
        if (value == null) {
            return List.of();
        }
        return stringList(value, "cleanupPatterns").stream()
                .map(Pattern::compile)
                .map(Pattern::pattern)
                .toList();
    }

    private static List<String> signatureColumns(Object value) {
        if (!(value instanceof Map<?, ?> signature)) {
            throw required(SIGNATURE);
        }
        List<String> columns = stringList(signature.get("headerColumns"), SIGNATURE + ".headerColumns");
        if (columns.isEmpty()) {
            throw new IllegalArgumentException(SIGNATURE + ".headerColumns must not be empty");
        }
        return columns;
    }

    private static StatementHeaderSpec statementHeader(Object value) {
        if (value == null) {
            return null;
        }
        if (!(value instanceof Map<?, ?> section)) {
            throw new IllegalArgumentException(STATEMENT_HEADER + " must be a mapping");
        }
        return StatementHeaderSpec.of(
                integer(section, "line"),
                rawString(section, "separator"),
                optionalInteger(section, "accountNumberField"),
                optionalInteger(section, "balanceField"),
                optionalInteger(section, "balanceDateField"),
                optionalString(section, "balanceDateFormat"),
                rawString(section, "decimalSeparator"));
    }

    private static PurchaseDateSpec purchaseDate(Object value) {
        if (value == null) {
            return null;
        }
        if (!(value instanceof Map<?, ?> section)) {
            throw new IllegalArgumentException(PURCHASE_DATE + " must be a mapping");
        }
        return PurchaseDateSpec.of(optionalString(section, "pattern"), optionalString(section, "format"));
    }

    private static String requiredString(Map<?, ?> map, String key) {
        String value = optionalString(map, key);
        if (value == null) {
            throw required(key);
        }
        return value;
    }

    /** A blank value counts as absent. */
    private static String optionalString(Map<?, ?> map, String key) {
        String value = rawString(map, key);
        return value == null || value.isBlank() ? null : value;
    }

    /** Unlike {@link #optionalString}, keeps a blank value: a tab or a space is a valid separator. */
    private static String rawString(Map<?, ?> map, String key) {
        Object value = map.get(key);
        if (value == null) {
            return null;
        }
        if (value instanceof String text) {
            return text;
        }
        throw new IllegalArgumentException(key + " must be a quoted string");
    }

    private static String singleCharacter(Map<?, ?> map, String key) {
        String value = rawString(map, key);
        if (value == null || value.length() != 1) {
            throw new IllegalArgumentException(key + " must be a single character");
        }
        return value;
    }

    private static Integer optionalInteger(Map<?, ?> map, String key) {
        Object value = map.get(key);
        if (value == null) {
            return null;
        }
        if (value instanceof Integer number) {
            return number;
        }
        throw new IllegalArgumentException(key + " must be an integer");
    }

    private static int integer(Map<?, ?> map, String key) {
        Integer value = optionalInteger(map, key);
        if (value == null) {
            throw required(key);
        }
        return value;
    }

    private static IllegalArgumentException required(String key) {
        return new IllegalArgumentException(key + " is required");
    }

    private static List<String> stringList(Object value, String key) {
        if (!(value instanceof List<?> items)) {
            throw new IllegalArgumentException(key + " must be a list");
        }
        return items.stream().map(item -> {
            if (item instanceof String text && !text.isBlank()) {
                return text;
            }
            throw new IllegalArgumentException(key + " must only hold non-blank strings");
        }).toList();
    }
}
