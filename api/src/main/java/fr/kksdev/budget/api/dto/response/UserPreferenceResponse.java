package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.Feature;

import java.util.List;
import java.util.UUID;

public record UserPreferenceResponse(
        List<Feature> enabledFeatures,
        List<Feature> navOrder,
        UUID shopAccountId,
        Boolean includeShopInBalance
) {}
