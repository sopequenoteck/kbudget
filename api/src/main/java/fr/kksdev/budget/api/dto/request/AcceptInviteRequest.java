package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.Currency;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record AcceptInviteRequest(
        @NotNull UUID token,
        @NotBlank @Size(min = 8, max = 100) String password,
        @NotBlank @Size(max = 100) String displayName,
        @NotNull Currency currency,
        @NotBlank String timezone
) {}
