package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CategoryRuleRequest(
        @NotBlank @Size(max = 200) String pattern,
        @NotNull UUID categoryId
) {}
