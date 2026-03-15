package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.enums.TextScale;

import java.util.List;
import java.util.UUID;

public record UserPreferenceResponse(
        List<Feature> enabledFeatures,
        List<Feature> navOrder,
        UUID shopAccountId,
        Boolean includeShopInBalance,
        List<Currency> currencies,
        List<NotificationType> enabledNotificationTypes,
        String timezone,
        TextScale textScale
) {}
