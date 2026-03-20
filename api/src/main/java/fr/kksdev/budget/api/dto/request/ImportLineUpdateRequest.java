package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.Size;

import java.util.UUID;

public record ImportLineUpdateRequest(
        UUID categoryId,
        @Size(max = 20) String status
) {}
