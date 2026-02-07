package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.SubscriptionRequest;
import fr.kksdev.budget.api.dto.SubscriptionResponse;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;

    public SubscriptionResponse create(SubscriptionRequest request, User user) {
        Subscription subscription = Subscription.builder()
                .nom(request.nom())
                .montant(request.montant())
                .frequence(request.frequence())
                .dateDebut(request.dateDebut())
                .actif(request.actif() != null ? request.actif() : true)
                .user(user)
                .build();

        subscription = subscriptionRepository.save(subscription);
        log.info("Abonnement créé: {} pour user {}", subscription.getId(), user.getEmail());
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

    public SubscriptionResponse update(UUID id, SubscriptionRequest request, UUID userId) {
        Subscription subscription = findByIdAndUser(id, userId);

        subscription.setNom(request.nom());
        subscription.setMontant(request.montant());
        subscription.setFrequence(request.frequence());
        subscription.setDateDebut(request.dateDebut());
        if (request.actif() != null) {
            subscription.setActif(request.actif());
        }

        subscription = subscriptionRepository.save(subscription);
        log.info("Abonnement mis à jour: {}", subscription.getId());
        return toResponse(subscription);
    }

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

    private SubscriptionResponse toResponse(Subscription subscription) {
        return new SubscriptionResponse(
                subscription.getId(),
                subscription.getNom(),
                subscription.getMontant(),
                subscription.getFrequence(),
                subscription.getDateDebut(),
                subscription.getActif()
        );
    }
}
