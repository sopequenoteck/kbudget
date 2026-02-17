package fr.kksdev.budget.api.dto.response;

public record UserResponse(
        String name,
        String email,
        String defaultCurrency
) {}
