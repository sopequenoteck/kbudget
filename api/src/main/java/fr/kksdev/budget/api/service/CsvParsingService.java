package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.CsvPreviewResponse;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.repository.ImportProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
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
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class CsvParsingService {

    private final LabelCleaningService labelCleaningService;
    private final CategoryRuleService categoryRuleService;
    private final ImportProfileRepository importProfileRepository;

    public List<ImportDraftLine> parse(InputStream inputStream, ImportProfileRegistry.ImportProfileConfig profile, UUID userId) {
        List<ImportDraftLine> lines = new ArrayList<>();

        Charset charset = Charset.forName(profile.encoding());
        DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern(profile.dateFormat());

        CSVFormat format = CSVFormat.Builder.create()
                .setDelimiter(profile.separator().charAt(0))
                .setHeader()
                .setSkipHeaderRecord(true)
                .setIgnoreEmptyLines(true)
                .setTrim(true)
                .build();

        try (BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(inputStream, charset))) {
            // Skip bank info header lines (e.g. SG has 1 line before column headers)
            for (int i = 0; i < profile.skipHeaderLines(); i++) {
                bufferedReader.readLine();
            }

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
            throw new IllegalArgumentException("Impossible de lire le fichier CSV: " + e.getMessage());
        }

        // Apply categorization rules to pre-fill categories
        categoryRuleService.applyRules(lines, userId);

        return lines;
    }

    private ImportDraftLine parseLine(CSVRecord record, int lineNumber,
                                      ImportProfileRegistry.ImportProfileConfig profile,
                                      DateTimeFormatter dateFormatter) {
        try {
            // Parse date
            String rawDate = record.get(profile.dateColumn());
            LocalDate date = LocalDate.parse(rawDate.trim(), dateFormatter);

            // Parse amount and determine type
            BigDecimal amount;
            TransactionType type;

            if (profile.amountColumn() != null) {
                // Single column strategy
                String rawAmount = record.get(profile.amountColumn()).trim();
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
                    throw new IllegalArgumentException("Aucun montant trouvé dans les colonnes débit/crédit");
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
                    .transactionType(type)
                    .status(ImportLineStatus.READY)
                    .build();

        } catch (DateTimeParseException e) {
            String rawLabel = safeGet(record, profile.labelColumn());
            return ImportDraftLine.builder()
                    .lineNumber(lineNumber)
                    .rawLabel(rawLabel)
                    .cleanLabel(rawLabel)
                    .amount(BigDecimal.ZERO)
                    .date(LocalDate.now())
                    .transactionType(TransactionType.DEPENSE)
                    .status(ImportLineStatus.NEEDS_REVIEW)
                    .statusMessage("Date invalide: " + e.getMessage())
                    .build();
        } catch (NumberFormatException e) {
            String rawLabel = safeGet(record, profile.labelColumn());
            return ImportDraftLine.builder()
                    .lineNumber(lineNumber)
                    .rawLabel(rawLabel)
                    .cleanLabel(rawLabel)
                    .amount(BigDecimal.ZERO)
                    .date(LocalDate.now())
                    .transactionType(TransactionType.DEPENSE)
                    .status(ImportLineStatus.NEEDS_REVIEW)
                    .statusMessage("Montant invalide: " + e.getMessage())
                    .build();
        } catch (Exception e) {
            String rawLabel = safeGet(record, profile.labelColumn());
            return ImportDraftLine.builder()
                    .lineNumber(lineNumber)
                    .rawLabel(rawLabel != null ? rawLabel : "")
                    .cleanLabel(rawLabel != null ? rawLabel : "")
                    .amount(BigDecimal.ZERO)
                    .date(LocalDate.now())
                    .transactionType(TransactionType.DEPENSE)
                    .status(ImportLineStatus.NEEDS_REVIEW)
                    .statusMessage("Erreur de parsing: " + e.getMessage())
                    .build();
        }
    }

    public Optional<ImportProfileRegistry.ImportProfileConfig> detectProfile(String bankCode) {
        return resolveProfile(bankCode, null);
    }

    public Optional<ImportProfileRegistry.ImportProfileConfig> resolveProfile(String bankCode, UUID userId) {
        // 1. Try registry first
        Optional<ImportProfileRegistry.ImportProfileConfig> registryProfile = ImportProfileRegistry.findByBankCode(bankCode);
        if (registryProfile.isPresent()) {
            return registryProfile;
        }

        // 2. Try custom profiles for user
        if (userId != null) {
            List<fr.kksdev.budget.api.model.ImportProfile> customProfiles =
                    importProfileRepository.findByUserIdOrderByNameAsc(userId);
            if (!customProfiles.isEmpty()) {
                fr.kksdev.budget.api.model.ImportProfile custom = customProfiles.get(0);
                return Optional.of(toConfig(custom));
            }
        }

        return Optional.empty();
    }

    public ImportProfileRegistry.ImportProfileConfig toConfig(fr.kksdev.budget.api.model.ImportProfile profile) {
        return new ImportProfileRegistry.ImportProfileConfig(
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
                List.of()
        );
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
