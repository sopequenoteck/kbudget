package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.config.PasswordPolicy;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record FirstLoginResetRequest(
        @NotBlank @Email @Size(max = 255) String email,
        @NotBlank @Size(min = PasswordPolicy.MIN_LENGTH, max = PasswordPolicy.MAX_LENGTH) String password,
        @NotBlank @Size(min = 1, max = 100) String displayName
) {}
