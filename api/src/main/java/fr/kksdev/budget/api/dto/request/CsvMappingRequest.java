package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

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
        String profileName
) {
    public CsvMappingRequest {
        if (encoding == null || encoding.isBlank()) {
            encoding = "UTF-8";
        }
        if (decimalSeparator == null || decimalSeparator.isBlank()) {
            decimalSeparator = ".";
        }
    }
}
