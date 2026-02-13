package fr.kksdev.budget.api.dto.response;

public record ErrorResponse(
        String error,
        String message
) {}
