package fr.kksdev.budget.api.dto.response;

public record ValidationErrorDetail(
        String field,
        String code,
        String message
) {}
