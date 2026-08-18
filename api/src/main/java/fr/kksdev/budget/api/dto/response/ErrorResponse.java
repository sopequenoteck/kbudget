package fr.kksdev.budget.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;

@JsonInclude(JsonInclude.Include.NON_EMPTY)
public record ErrorResponse(
        String error,
        String message,
        List<ValidationErrorDetail> details
) {
    public ErrorResponse(String error, String message) {
        this(error, message, List.of());
    }

    public ErrorResponse {
        details = details == null ? List.of() : List.copyOf(details);
    }
}
