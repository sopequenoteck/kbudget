package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record CreateInvitationRequest(
        @Email @NotBlank String email
) {}
