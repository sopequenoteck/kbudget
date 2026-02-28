package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.UserPreferenceRequest;
import fr.kksdev.budget.api.dto.response.UserPreferenceResponse;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.model.UserPreference;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.UserPreferenceRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PreferenceService {

    private static final List<Feature> DEFAULT_FEATURES = List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP);

    private final UserPreferenceRepository userPreferenceRepository;
    private final UserRepository userRepository;
    private final AccountRepository accountRepository;

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
        if (request.shopAccountId() != null) {
            accountRepository.findById(request.shopAccountId())
                    .filter(a -> a.getUser().getId().equals(userId))
                    .orElseThrow(() -> new EntityNotFoundException("Compte non trouvé"));
            preference.setShopAccountId(request.shopAccountId());
        }
        if (request.includeShopInBalance() != null) {
            preference.setIncludeShopInBalance(request.includeShopInBalance());
        }
        userPreferenceRepository.save(preference);

        log.info("Préférences mises à jour pour l'utilisateur {}: features={}, navOrder={}", userId, enabledFeatures, navOrder);
        return toResponse(preference);
    }

    public boolean isFeatureEnabled(UUID userId, Feature feature) {
        UserPreference preference = getOrCreate(userId);
        return preference.getEnabledFeatures().contains(feature);
    }

    @Transactional
    private UserPreference getOrCreate(UUID userId) {
        return userPreferenceRepository.findByUserId(userId)
                .orElseGet(() -> {
                    log.info("Création des préférences par défaut pour l'utilisateur {}", userId);
                    UserPreference newPreference = UserPreference.builder()
                            .user(userRepository.getReferenceById(userId))
                            .enabledFeatures(new ArrayList<>(DEFAULT_FEATURES))
                            .navOrder(new ArrayList<>(DEFAULT_FEATURES))
                            .includeShopInBalance(false)
                            .build();
                    return userPreferenceRepository.save(newPreference);
                });
    }

    private void validateNavOrder(List<Feature> navOrder, List<Feature> enabledFeatures) {
        Set<Feature> navOrderSet = new HashSet<>();
        for (Feature feature : navOrder) {
            if (!navOrderSet.add(feature)) {
                throw new IllegalArgumentException("L'ordre de navigation ne doit pas contenir de doublons");
            }
        }

        Set<Feature> enabledSet = new HashSet<>(enabledFeatures);
        if (!navOrderSet.equals(enabledSet)) {
            throw new IllegalArgumentException("L'ordre de navigation doit contenir exactement les fonctionnalités activées");
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
    public UserPreference getOrCreatePreference(UUID userId) {
        return getOrCreate(userId);
    }

    private UserPreferenceResponse toResponse(UserPreference preference) {
        return new UserPreferenceResponse(
                preference.getEnabledFeatures(),
                preference.getNavOrder(),
                preference.getShopAccountId(),
                preference.getIncludeShopInBalance()
        );
    }
}
