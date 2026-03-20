package fr.kksdev.budget.api.dto.response;

public record BankResponse(
        String code,
        String name,
        String country,
        String brandColor,
        String logoUrl
) {}
