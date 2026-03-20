package fr.kksdev.budget.api.dto.response;

import java.util.List;

public record CsvPreviewResponse(
        List<String> headers,
        List<List<String>> rows,
        String detectedSeparator,
        String detectedEncoding,
        int totalRows
) {}
