package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.UserPreferenceRequest;
import fr.kksdev.budget.api.dto.response.UserPreferenceResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.model.UserPreference;
import fr.kksdev.budget.api.repository.UserPreferenceRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DateTimeException;
import java.time.ZoneId;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PreferenceService {

    private static final List<Feature> DEFAULT_FEATURES = List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS);

    private final UserPreferenceRepository userPreferenceRepository;
    private final UserRepository userRepository;
    private final ExchangeRateService exchangeRateService;
    private final SimpMessagingTemplate messagingTemplate;

    public UserPreferenceResponse getPreferences(UUID userId) {
        UserPreference preference = getOrCreate(userId);
        return toResponse(preference);
    }

    @Transactional
    public UserPreferenceResponse updatePreferences(UserPreferenceRequest request, UUID userId) {
        UserPreference preference = getOrCreate(userId);

        List<Feature> enabledFeatures = request.enabledFeatures();

        List<Feature> navOrder;
        if (request.navOrder() != null) {
            validateNavOrder(request.navOrder(), enabledFeatures);
            navOrder = request.navOrder();
        } else {
            navOrder = autoManageNavOrder(preference.getNavOrder(), enabledFeatures);
        }

        preference.setEnabledFeatures(enabledFeatures);
        preference.setNavOrder(navOrder);
        if (request.currencies() != null) {
            validateCurrencies(request.currencies());
            Currency oldPrimary = preference.getCurrencies().isEmpty() ? null : preference.getCurrencies().get(0);
            preference.setCurrencies(new ArrayList<>(request.currencies()));
            Currency newPrimary = request.currencies().get(0);
            if (oldPrimary != null && oldPrimary != newPrimary) {
                exchangeRateService.rebaseRates(userId, oldPrimary, newPrimary);
                log.info("Devise principale changée: {} -> {} pour userId={}", oldPrimary, newPrimary, userId);
                messagingTemplate.convertAndSendToUser(
                        userId.toString(),
                        "/queue/exchange-rates",
                        Map.of("type", "EXCHANGE_RATES_UPDATED")
                );
            }
        }
        if (request.enabledNotificationTypes() != null) {
            preference.setEnabledNotificationTypes(request.enabledNotificationTypes());
        }
        if (request.timezone() != null) {
            try {
                ZoneId.of(request.timezone());
            } catch (DateTimeException e) {
                throw new IllegalArgumentException("Invalid timezone: " + request.timezone());
            }
            preference.setTimezone(request.timezone());
        }
        if (request.textScale() != null) {
            preference.setTextScale(request.textScale());
        }
        userPreferenceRepository.save(preference);

        log.info("Préférences mises à jour pour l'utilisateur {}: features={}, navOrder={}", userId, enabledFeatures, navOrder);
        return toResponse(preference);
    }

    public boolean isFeatureEnabled(UUID userId, Feature feature) {
        UserPreference preference = getOrCreate(userId);
        return preference.getEnabledFeatures().contains(feature);
    }

    /**
     * Vérifie si un type de notification est activé pour l'utilisateur.
     * Par défaut (liste null ou vide), tous les types sont considérés activés (opt-out).
     */
    public boolean isNotificationTypeEnabled(UUID userId, NotificationType type) {
        UserPreference preference = getOrCreate(userId);
        if (preference.getEnabledNotificationTypes() == null || preference.getEnabledNotificationTypes().isEmpty()) {
            return true;
        }
        return preference.getEnabledNotificationTypes().contains(type);
    }

    public String getUserTimezone(UUID userId) {
        UserPreference preference = getOrCreate(userId);
        return preference.getTimezone() != null ? preference.getTimezone() : "Europe/Paris";
    }

    private UserPreference getOrCreate(UUID userId) {
        return userPreferenceRepository.findByUserId(userId)
                .orElseGet(() -> {
                    log.info("Création des préférences par défaut pour l'utilisateur {}", userId);
                    UserPreference newPreference = UserPreference.builder()
                            .user(userRepository.getReferenceById(userId))
                            .enabledFeatures(new ArrayList<>(DEFAULT_FEATURES))
                            .navOrder(new ArrayList<>(DEFAULT_FEATURES))
                            .currencies(new ArrayList<>(List.of(Currency.EUR)))
                            .build();
                    return userPreferenceRepository.save(newPreference);
                });
    }

    private void validateNavOrder(List<Feature> navOrder, List<Feature> enabledFeatures) {
        Set<Feature> navOrderSet = new HashSet<>();
        for (Feature feature : navOrder) {
            if (!navOrderSet.add(feature)) {
                throw new IllegalArgumentException("Navigation order must not contain duplicates");
            }
        }

        Set<Feature> enabledSet = new HashSet<>(enabledFeatures);
        if (!navOrderSet.equals(enabledSet)) {
            throw new IllegalArgumentException("Navigation order must contain exactly the enabled features");
        }
    }

    private List<Feature> autoManageNavOrder(List<Feature> currentNavOrder, List<Feature> enabledFeatures) {
        Set<Feature> enabledSet = new HashSet<>(enabledFeatures);

        // Garder l'ordre existant pour les features encore activées
        List<Feature> newNavOrder = currentNavOrder.stream()
                .filter(enabledSet::contains)
                .collect(Collectors.toCollection(ArrayList::new));

        // Ajouter les features nouvellement activées en fin
        for (Feature feature : enabledFeatures) {
            if (!newNavOrder.contains(feature)) {
                newNavOrder.add(feature);
            }
        }

        return newNavOrder;
    }

    @Transactional
    public void createInitialPreference(User user, Currency currency, String timezone) {
        String validTimezone = "Europe/Paris";
        if (timezone != null && !timezone.isBlank()) {
            try {
                ZoneId.of(timezone);
                validTimezone = timezone;
            } catch (DateTimeException e) {
                log.warn("Timezone invalide à l'inscription: '{}', utilisation du fallback Europe/Paris", timezone);
            }
        }
        UserPreference preference = UserPreference.builder()
                .user(user)
                .enabledFeatures(new ArrayList<>(DEFAULT_FEATURES))
                .navOrder(new ArrayList<>(DEFAULT_FEATURES))
                .currencies(new ArrayList<>(List.of(currency)))
                .build();
        preference.setTimezone(validTimezone);
        userPreferenceRepository.save(preference);
        log.info("Préférences initiales créées pour userId={}, currency={}, timezone={}", user.getId(), currency, validTimezone);
    }

    @Transactional
    public UserPreference getOrCreatePreference(UUID userId) {
        return getOrCreate(userId);
    }

    private void validateCurrencies(List<Currency> currencies) {
        if (currencies.isEmpty()) {
            throw new IllegalArgumentException("At least one currency is required");
        }
        Set<Currency> seen = new HashSet<>();
        for (Currency currency : currencies) {
            if (!seen.add(currency)) {
                throw new IllegalArgumentException("The currency list must not contain duplicates");
            }
        }
    }

    private UserPreferenceResponse toResponse(UserPreference preference) {
        return new UserPreferenceResponse(
                preference.getEnabledFeatures(),
                preference.getNavOrder(),
                preference.getCurrencies(),
                preference.getEnabledNotificationTypes(),
                preference.getTimezone(),
                preference.getTextScale()
        );
    }
}
