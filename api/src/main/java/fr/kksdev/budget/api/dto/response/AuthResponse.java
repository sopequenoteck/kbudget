package fr.kksdev.budget.api.dto.response;

public record AuthResponse(
        String token,
        String email,
        String name
) {}
