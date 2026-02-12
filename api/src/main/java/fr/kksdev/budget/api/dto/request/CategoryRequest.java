package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CategoryRequest(
        @NotBlank @Size(max = 30) String nom,
        @NotBlank @Size(max = 50) String icone,
        @NotBlank @Size(max = 7) @Pattern(regexp = "^#[0-9A-Fa-f]{6}$") String couleur
) {}
