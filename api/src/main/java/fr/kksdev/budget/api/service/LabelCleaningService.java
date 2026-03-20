package fr.kksdev.budget.api.service;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class LabelCleaningService {

    // Structural extraction patterns (applied BEFORE regex removal)
    private static final Pattern PRELEVEMENT_PATTERN = Pattern.compile(
            "PRELEVEMENT EUROPEEN\\s+\\d+\\s+DE:\\s*(.+?)(?:\\s+ID:|\\s+REF:|\\s+MOTIF:|$)");
    private static final Pattern VIR_PATTERN = Pattern.compile(
            "\\d+\\s+VIR\\s+(PERM|EUROPEEN|INSTANTANE).*?POUR:\\s*(.+?)(?:\\s+REF:|\\s+IBAN:|\\s+BQ\\s|\\s+DATE:|$)");
    private static final Pattern RETRAIT_DAB_PATTERN = Pattern.compile(
            "CARTE\\s+\\w+\\d{4}\\s+RETRAIT DAB\\s+\\d{2}/\\d{2}\\s+\\d{2}H\\d{2}\\s+(.+?)\\s+\\d{5,}");

    // Generic cleanup patterns
    private static final Pattern LONG_DIGITS_PATTERN = Pattern.compile("\\d{8,}");
    private static final Pattern AMOUNT_INLINE_PATTERN = Pattern.compile("\\d+,\\d{2}\\s+EUR");
    private static final Pattern COMMERCE_ELEC_PATTERN = Pattern.compile("COMMERCE ELECTRONIQUE");
    private static final Pattern COUNTRY_PATTERN = Pattern.compile(
            "\\s+(PAYS-BAS|IRLANDE|ETATS-UNIS D'AME\\w*|LUXEMBOURG|ROYAUME-UNI|ALLEMAGNE)");
    private static final Pattern IOPD_PATTERN = Pattern.compile("\\d+IOPD");

    public String clean(String rawLabel, List<String> cleanupPatterns) {
        if (rawLabel == null) {
            return "";
        }

        String result = rawLabel.trim();

        // Phase 1: Structural extraction for known patterns
        String extracted = tryStructuralExtraction(result);
        if (extracted != null) {
            return finalize(extracted, rawLabel);
        }

        // Phase 2: Apply profile-specific regex removal patterns
        for (String pattern : cleanupPatterns) {
            try {
                result = result.replaceAll(pattern, " ");
            } catch (Exception e) {
                // Skip invalid patterns
            }
        }

        // Phase 3: Generic cleanup patterns
        result = IOPD_PATTERN.matcher(result).replaceAll(" ");
        result = AMOUNT_INLINE_PATTERN.matcher(result).replaceAll(" ");
        result = COMMERCE_ELEC_PATTERN.matcher(result).replaceAll(" ");
        result = COUNTRY_PATTERN.matcher(result).replaceAll(" ");
        result = LONG_DIGITS_PATTERN.matcher(result).replaceAll(" ");

        return finalize(result, rawLabel);
    }

    public String clean(String rawLabel) {
        return clean(rawLabel, List.of());
    }

    private String tryStructuralExtraction(String label) {
        // PRELEVEMENT EUROPEEN ... DE: [merchant] ID:/REF:/MOTIF:
        Matcher m = PRELEVEMENT_PATTERN.matcher(label);
        if (m.find()) {
            return m.group(1).trim();
        }

        // VIR PERM/EUROPEEN/INSTANTANE ... POUR: [name] REF:/IBAN:/BQ/DATE:
        m = VIR_PATTERN.matcher(label);
        if (m.find()) {
            String type = m.group(1);
            String name = m.group(2).trim();
            return "VIR " + type + " " + name;
        }

        // RETRAIT DAB → extract location
        m = RETRAIT_DAB_PATTERN.matcher(label);
        if (m.find()) {
            return "RETRAIT DAB " + m.group(1).trim();
        }

        return null;
    }

    private String finalize(String result, String rawLabel) {
        // Trim and collapse multiple spaces
        result = result.trim().replaceAll("\\s{2,}", " ");

        if (result.isBlank()) {
            return rawLabel.trim();
        }

        return result;
    }
}
