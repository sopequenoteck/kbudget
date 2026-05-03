package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;

public record DeleteAccountRequest(
        @NotBlank
        String currentPassword,

        @AssertTrue(message = "Confirmation explicite requise")
        boolean confirmed
) {}
