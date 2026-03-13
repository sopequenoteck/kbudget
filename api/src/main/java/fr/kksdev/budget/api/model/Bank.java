package fr.kksdev.budget.api.model;

public record Bank(
        String code,
        String name,
        String country,
        String brandColor,
        String logoUrl
) {}
