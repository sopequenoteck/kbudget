package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.SubscriptionRequest;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.dto.response.SubscriptionResponse;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final CategoryService categoryService;

    @Transactional
    public SubscriptionResponse create(SubscriptionRequest request, UUID userId) {
        Subscription subscription = Subscription.builder()
                .nom(request.nom())
                .montant(request.montant())
                .frequence(request.frequence())
                .dateDebut(request.dateDebut())
                .actif(request.actif() != null ? request.actif() : true)
                .category(resolveCategory(request.categoryId(), userId))
                .user(userRepository.getReferenceById(userId))
                .build();

        subscription = subscriptionRepository.save(subscription);
        log.info("Abonnement créé: {} pour userId {}", subscription.getId(), userId);
        return toResponse(subscription);
    }

    public List<SubscriptionResponse> getAllByUser(UUID userId) {
        return subscriptionRepository.findByUserIdOrderByNomAsc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public List<SubscriptionResponse> getActiveByUser(UUID userId) {
        return subscriptionRepository.findByUserIdAndActifTrueOrderByNomAsc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public SubscriptionResponse getById(UUID id, UUID userId) {
        Subscription subscription = findByIdAndUser(id, userId);
        return toResponse(subscription);
    }

    @Transactional
    public SubscriptionResponse update(UUID id, SubscriptionRequest request, UUID userId) {
        Subscription subscription = findByIdAndUser(id, userId);

        subscription.setNom(request.nom());
        subscription.setMontant(request.montant());
        subscription.setFrequence(request.frequence());
        subscription.setDateDebut(request.dateDebut());
        if (request.actif() != null) {
            subscription.setActif(request.actif());
        }
        subscription.setCategory(resolveCategory(request.categoryId(), userId));

        subscription = subscriptionRepository.save(subscription);
        log.info("Abonnement mis à jour: {}", subscription.getId());
        return toResponse(subscription);
    }

    @Transactional
    public void delete(UUID id, UUID userId) {
        Subscription subscription = findByIdAndUser(id, userId);
        subscriptionRepository.delete(subscription);
        log.info("Abonnement supprimé: {}", id);
    }

    private Subscription findByIdAndUser(UUID id, UUID userId) {
        return subscriptionRepository.findById(id)
                .filter(s -> s.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Abonnement non trouvé: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Abonnement non trouvé");
                });
    }

    private Category resolveCategory(UUID categoryId, UUID userId) {
        if (categoryId == null) {
            return categoryService.findSystemCategoryByNom("Abonnement", userId);
        }
        return categoryRepository.findById(categoryId)
                .filter(c -> c.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Catégorie non trouvée: id={}, userId={}", categoryId, userId);
                    return new EntityNotFoundException("Catégorie non trouvée");
                });
    }

    private CategoryResponse toCategoryResponse(Category category) {
        if (category == null) {
            return null;
        }
        return new CategoryResponse(
                category.getId(),
                category.getNom(),
                category.getIcone(),
                category.getCouleur(),
                Boolean.TRUE.equals(category.getIsSystem())
        );
    }

    private SubscriptionResponse toResponse(Subscription subscription) {
        return new SubscriptionResponse(
                subscription.getId(),
                subscription.getNom(),
                subscription.getMontant(),
                subscription.getFrequence(),
                subscription.getDateDebut(),
                subscription.getActif(),
                toCategoryResponse(subscription.getCategory())
        );
    }
}
