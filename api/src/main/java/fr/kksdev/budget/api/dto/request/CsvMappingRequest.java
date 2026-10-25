package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

public record CsvMappingRequest(
        @NotBlank String separator,
        @NotBlank String dateFormat,
        @NotBlank String dateColumn,
        String amountColumn,
        String debitColumn,
        String creditColumn,
        @NotBlank String labelColumn,
        String encoding,
        String decimalSeparator,
        @Min(0) int skipHeaderLines,
        boolean saveAsProfile,
        String profileName,
        List<String> cleanupPatterns
) {
    private static final int MAX_CLEANUP_PATTERNS = 20;
    private static final int MAX_CLEANUP_PATTERN_LENGTH = 200;

    public CsvMappingRequest {
        if (encoding == null || encoding.isBlank()) {
            encoding = "UTF-8";
        }
        if (decimalSeparator == null || decimalSeparator.isBlank()) {
            decimalSeparator = ".";
        }
        cleanupPatterns = validateCleanupPatterns(cleanupPatterns);
    }

    // Bean Validation does not run on this record (the controller reads the JSON by hand),
    // so the rules live here. Messages name the rank, never the pattern itself.
    private static List<String> validateCleanupPatterns(List<String> patterns) {
        if (patterns == null) {
            return List.of();
        }
        if (patterns.size() > MAX_CLEANUP_PATTERNS) {
            throw new IllegalArgumentException(
                    "cleanupPatterns must contain at most " + MAX_CLEANUP_PATTERNS + " patterns");
        }
        List<String> trimmed = new ArrayList<>(patterns.size());
        for (int i = 0; i < patterns.size(); i++) {
            String pattern = patterns.get(i) == null ? "" : patterns.get(i).trim();
            if (pattern.isEmpty()) {
                throw new IllegalArgumentException("cleanupPatterns[" + i + "] must not be blank");
            }
            if (pattern.length() > MAX_CLEANUP_PATTERN_LENGTH) {
                throw new IllegalArgumentException(
                        "cleanupPatterns[" + i + "] must be at most " + MAX_CLEANUP_PATTERN_LENGTH + " characters");
            }
            try {
                Pattern.compile(pattern);
            } catch (PatternSyntaxException e) {
                // Replaced without cause: its message and trace would carry the pattern
                throw new IllegalArgumentException(
                        "cleanupPatterns[" + i + "] is not a valid regular expression");
            }
            trimmed.add(pattern);
        }
        return List.copyOf(trimmed);
    }
}
