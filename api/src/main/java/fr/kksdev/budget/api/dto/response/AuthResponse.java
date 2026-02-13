package fr.kksdev.budget.api.dto.response;

public record AuthResponse(
        String token,
        String refreshToken,
        String email,
        String name
) {}
