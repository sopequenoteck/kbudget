package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.enums.TextScale;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import java.util.List;

public record UserPreferenceRequest(
        @NotNull List<Feature> enabledFeatures,
        List<Feature> navOrder,
        List<Currency> currencies,
        List<NotificationType> enabledNotificationTypes,
        String timezone,
        TextScale textScale,
        @Pattern(regexp = "^[a-z]{2}(-[A-Z]{2})?$") String language
) {}
