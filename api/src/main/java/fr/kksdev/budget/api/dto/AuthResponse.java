package fr.kksdev.budget.api.dto;

public record AuthResponse(
        String token,
        String email,
        String name
) {}
