package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.Currency;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(min = 6) String password,
        @Size(max = 100) String name,
        Currency currency,
        String timezone
) {}
