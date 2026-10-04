package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.CsvPreviewResponse;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.ImportReadError;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.ImportDraftLine;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.math.BigDecimal;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class CsvParsingService {

    /** Length of the {@code read_error_value} column. */
    private static final int READ_ERROR_VALUE_MAX = 500;

    private final LabelCleaningService labelCleaningService;
    private final CategorySuggestionService categorySuggestionService;

    public List<ImportDraftLine> parse(InputStream inputStream, ImportProfileRegistry.ImportProfileConfig profile, UUID userId) {
        List<ImportDraftLine> lines = new ArrayList<>();

        Charset charset = Charset.forName(profile.encoding());
        DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern(profile.dateFormat());

        CSVFormat format = columnHeaderFormat(profile.separator().charAt(0));

        try (BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(inputStream, charset))) {
            skipBankHeader(bufferedReader, profile.skipHeaderLines());

            CSVParser parser = new CSVParser(bufferedReader, format);
            int lineNumber = 1;
            for (CSVRecord record : parser) {
                ImportDraftLine line = parseLine(record, lineNumber, profile, dateFormatter);
                lines.add(line);
                lineNumber++;
            }
            parser.close();
        } catch (IOException e) {
            log.error("Erreur lecture CSV: {}", e.getMessage());
            throw new IllegalArgumentException("Unable to read the CSV file: " + e.getMessage());
        }

        // Pre-fill categories: user rules, then the user's own history (KKS-383)
        categorySuggestionService.suggest(lines, userId);

        return lines;
    }

    private ImportDraftLine parseLine(CSVRecord record, int lineNumber,
                                      ImportProfileRegistry.ImportProfileConfig profile,
                                      DateTimeFormatter dateFormatter) {
        // Raw cells read so far, kept for the read error of the line (KKS-441)
        String rawDate = null;
        String rawAmountCell = null;
        try {
            // Parse date
            rawDate = record.get(profile.dateColumn());
            LocalDate date = LocalDate.parse(rawDate.trim(), dateFormatter);

            // Parse amount and determine type
            BigDecimal amount;
            TransactionType type;

            if (profile.amountColumn() != null) {
                // Single column strategy
                String rawAmount = record.get(profile.amountColumn()).trim();
                rawAmountCell = rawAmount;
                rawAmount = rawAmount.replace(profile.decimalSeparator(), ".");
                // Remove any thousand separators (space or non-breaking space)
                rawAmount = rawAmount.replaceAll("[\\s\u00A0]", "");
                BigDecimal parsed = new BigDecimal(rawAmount);
                if (parsed.compareTo(BigDecimal.ZERO) < 0) {
                    type = TransactionType.DEPENSE;
                } else {
                    type = TransactionType.RECETTE;
                }
                amount = parsed.abs();
            } else {
                // Debit/Credit columns strategy
                String rawDebit = record.get(profile.debitColumn()).trim();
                String rawCredit = record.get(profile.creditColumn()).trim();
                rawAmountCell = rawDebit.isEmpty() ? rawCredit : rawDebit;

                rawDebit = rawDebit.replace(profile.decimalSeparator(), ".")
                        .replaceAll("[\\s\u00A0]", "");
                rawCredit = rawCredit.replace(profile.decimalSeparator(), ".")
                        .replaceAll("[\\s\u00A0]", "");

                if (!rawDebit.isEmpty()) {
                    amount = new BigDecimal(rawDebit).abs();
                    type = TransactionType.DEPENSE;
                } else if (!rawCredit.isEmpty()) {
                    amount = new BigDecimal(rawCredit).abs();
                    type = TransactionType.RECETTE;
                } else {
                    throw new IllegalArgumentException("No amount found in the debit/credit columns");
                }
            }

            // Parse label
            String rawLabel = record.get(profile.labelColumn()).trim();
            String cleanLabel = labelCleaningService.clean(rawLabel, profile.cleanupPatterns());

            return ImportDraftLine.builder()
                    .lineNumber(lineNumber)
                    .rawLabel(rawLabel)
                    .cleanLabel(cleanLabel)
                    .amount(amount)
                    .date(date)
                    .purchaseDate(purchaseDateOf(profile, rawLabel, date))
                    .transactionType(type)
                    .status(ImportLineStatus.READY)
                    .build();

        } catch (DateTimeParseException e) {
            return unreadableLine(record, lineNumber, profile, ImportReadError.INVALID_DATE, rawDate,
                    "Invalid date: " + e.getMessage());
        } catch (NumberFormatException e) {
            return unreadableLine(record, lineNumber, profile, ImportReadError.INVALID_AMOUNT, rawAmountCell,
                    "Invalid amount: " + e.getMessage());
        } catch (Exception e) {
            return unreadableLine(record, lineNumber, profile, ImportReadError.UNREADABLE_LINE, null,
                    "Unreadable line: " + e.getMessage());
        }
    }

    /** A line that could not be read: it goes to review with its error code, the faulty raw value and an English message (KKS-441). */
    private ImportDraftLine unreadableLine(CSVRecord csvRecord, int lineNumber,
                                           ImportProfileRegistry.ImportProfileConfig profile,
                                           ImportReadError readError, String rawValue, String message) {
        String rawLabel = safeGet(csvRecord, profile.labelColumn());
        return ImportDraftLine.builder()
                .lineNumber(lineNumber)
                .rawLabel(rawLabel)
                .cleanLabel(rawLabel)
                .amount(BigDecimal.ZERO)
                .date(LocalDate.now())
                .transactionType(TransactionType.DEPENSE)
                .status(ImportLineStatus.NEEDS_REVIEW)
                .statusMessage(message)
                .readError(readError)
                .readErrorValue(truncate(rawValue))
                .build();
    }

    private static String truncate(String value) {
        return value != null && value.length() > READ_ERROR_VALUE_MAX ? value.substring(0, READ_ERROR_VALUE_MAX) : value;
    }

    /** Purchase date carried by the raw label when the profile declares one (KKS-385), {@code null} otherwise. */
    private static LocalDate purchaseDateOf(ImportProfileRegistry.ImportProfileConfig profile, String rawLabel,
                                            LocalDate bookingDate) {
        PurchaseDateSpec spec = profile.purchaseDate();
        return spec == null ? null : spec.extract(rawLabel, bookingDate).orElse(null);
    }

    /**
     * Column names found on the column header line of the file, read the way
     * {@link #parse} reads it: bank header lines skipped, then the first
     * non-empty record. Empty when the file cannot be read with this profile.
     */
    public List<String> readHeaderColumns(byte[] content, ImportProfileRegistry.ImportProfileConfig profile) {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                new ByteArrayInputStream(content), Charset.forName(profile.encoding())))) {
            skipBankHeader(reader, profile.skipHeaderLines());
            try (CSVParser parser = new CSVParser(reader, columnHeaderFormat(profile.separator().charAt(0)))) {
                return List.copyOf(parser.getHeaderNames());
            }
        } catch (IOException | RuntimeException e) {
            log.debug("File not readable with import profile '{}': {}", profile.name(), e.getMessage());
            return List.of();
        }
    }

    /**
     * Raw lines skipped before the column header, read with the encoding of the profile
     * (KKS-384). Fewer lines when the file is shorter; empty when it cannot be read.
     */
    public List<String> readSkippedLines(byte[] content, ImportProfileRegistry.ImportProfileConfig profile) {
        List<String> skipped = new ArrayList<>();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                new ByteArrayInputStream(content), Charset.forName(profile.encoding())))) {
            for (int i = 0; i < profile.skipHeaderLines(); i++) {
                String line = reader.readLine();
                if (line == null) {
                    break;
                }
                skipped.add(line);
            }
        } catch (IOException | RuntimeException e) {
            log.debug("Header lines not readable with import profile '{}': {}", profile.name(), e.getMessage());
            return List.of();
        }
        return skipped;
    }

    private static CSVFormat columnHeaderFormat(char delimiter) {
        return CSVFormat.Builder.create()
                .setDelimiter(delimiter)
                .setHeader()
                .setSkipHeaderRecord(true)
                .setIgnoreEmptyLines(true)
                .setTrim(true)
                .build();
    }

    /** Skips the bank info header lines (e.g. SG has 1 line before the column headers). */
    private static void skipBankHeader(BufferedReader reader, int lines) throws IOException {
        for (int i = 0; i < lines; i++) {
            String skippedLine = reader.readLine();
            if (skippedLine == null) {
                return;
            }
        }
    }

    public CsvPreviewResponse preview(InputStream inputStream, String separator, String encoding, int skipHeaderLines) throws IOException {
        byte[] fileBytes = inputStream.readAllBytes();

        String detectedEncoding = detectEncoding(fileBytes);
        Charset charset = Charset.forName(detectedEncoding);

        // Read all lines as raw strings first for separator detection and counting
        List<String> allRawLines = new ArrayList<>();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                new java.io.ByteArrayInputStream(fileBytes), charset))) {
            String line;
            while ((line = reader.readLine()) != null) {
                allRawLines.add(line);
            }
        }

        List<String> nonBlankLines = allRawLines.stream().filter(l -> !l.isBlank()).toList();

        if (nonBlankLines.isEmpty()) {
            return new CsvPreviewResponse(List.of(), List.of(), separator != null ? separator : ";", detectedEncoding, 0, 0);
        }

        // Auto-detect separator from the line with the most separators (likely the header row)
        String detectedSeparator = (separator != null && !separator.isBlank())
                ? separator
                : detectSeparator(nonBlankLines.size() > 1 ? nonBlankLines.get(1) : nonBlankLines.get(0));

        // Auto-detect skipHeaderLines if not explicitly set
        int effectiveSkip = skipHeaderLines;
        if (effectiveSkip == 0 && nonBlankLines.size() >= 3) {
            char sep = detectedSeparator.charAt(0);
            // Count columns for each of the first few lines
            long majorityColCount = nonBlankLines.stream()
                    .skip(1).limit(5)
                    .mapToLong(l -> l.chars().filter(c -> c == sep).count() + 1)
                    .sorted().skip(2).findFirst()
                    .orElse(0);
            // Skip leading lines with a different column count
            for (int i = 0; i < Math.min(5, nonBlankLines.size() - 1); i++) {
                long colCount = nonBlankLines.get(i).chars().filter(c -> c == sep).count() + 1;
                if (colCount != majorityColCount) {
                    effectiveSkip = i + 1;
                } else {
                    break;
                }
            }
            if (effectiveSkip > 0) {
                log.info("Auto-détection skipHeaderLines={} (lignes d'info bancaire détectées)", effectiveSkip);
            }
        }

        // Skip header lines
        List<String> dataLines = allRawLines.stream()
                .skip(effectiveSkip)
                .filter(l -> !l.isBlank())
                .toList();

        if (dataLines.isEmpty()) {
            return new CsvPreviewResponse(List.of(), List.of(), detectedSeparator, detectedEncoding, effectiveSkip, 0);
        }

        // Rebuild input from skipped lines for CSVParser
        String dataContent = String.join("\n", dataLines);
        CSVFormat format = CSVFormat.Builder.create()
                .setDelimiter(detectedSeparator.charAt(0))
                .setHeader()
                .setSkipHeaderRecord(true)
                .setIgnoreEmptyLines(true)
                .setTrim(true)
                .build();

        List<String> headers = new ArrayList<>();
        List<List<String>> previewRows = new ArrayList<>();
        int totalRows = 0;

        try (CSVParser parser = CSVParser.parse(dataContent, format)) {
            headers.addAll(parser.getHeaderNames());
            for (CSVRecord record : parser) {
                totalRows++;
                if (previewRows.size() < 5) {
                    List<String> row = new ArrayList<>();
                    for (String header : headers) {
                        try {
                            row.add(record.get(header));
                        } catch (Exception e) {
                            row.add("");
                        }
                    }
                    previewRows.add(row);
                }
            }
        }

        return new CsvPreviewResponse(headers, previewRows, detectedSeparator, detectedEncoding, effectiveSkip, totalRows);
    }

    private String detectSeparator(String firstLine) {
        long semicolons = firstLine.chars().filter(c -> c == ';').count();
        long commas = firstLine.chars().filter(c -> c == ',').count();
        long tabs = firstLine.chars().filter(c -> c == '\t').count();
        if (semicolons >= commas && semicolons >= tabs) {
            return ";";
        } else if (commas >= tabs) {
            return ",";
        } else {
            return "\t";
        }
    }

    public String detectEncoding(byte[] fileBytes) {
        if (fileBytes.length >= 3
                && fileBytes[0] == (byte) 0xEF
                && fileBytes[1] == (byte) 0xBB
                && fileBytes[2] == (byte) 0xBF) {
            return "UTF-8";
        }

        try {
            CharsetDecoder decoder = StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT);
            decoder.decode(java.nio.ByteBuffer.wrap(fileBytes));
            return "UTF-8";
        } catch (Exception e) {
            return "ISO-8859-1";
        }
    }

    private String safeGet(CSVRecord record, String columnName) {
        try {
            if (columnName != null) {
                return record.get(columnName);
            }
        } catch (Exception ignored) {
        }
        return "";
    }
}
