package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.Feature;
import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.UUID;

public record UserPreferenceRequest(
        @NotNull List<Feature> enabledFeatures,
        List<Feature> navOrder,
        UUID shopAccountId,
        Boolean includeShopInBalance
) {}
