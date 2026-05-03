package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// Self-service profile fields ONLY. Email is admin-managed (cf. KKS-235 §FR-007).
// Do not add fields that require admin authorization.
public record UpdateProfileRequest(
        @NotBlank
        @Size(min = 1, max = 100)
        String name
) {}
