package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.SubscriptionRequest;
import fr.kksdev.budget.api.dto.response.AccountSummary;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.dto.response.SubscriptionResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
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
    private final AccountRepository accountRepository;
    private final PreferenceService preferenceService;

    @Transactional
    public SubscriptionResponse create(SubscriptionRequest request, UUID userId) {
        Account account = resolveAccount(request.accountId(), userId);
        User user = userRepository.getReferenceById(userId);
        Currency currency = resolveCurrency(request.currency(), account, user);

        Subscription subscription = Subscription.builder()
                .nom(request.nom())
                .montant(request.montant())
                .frequence(request.frequence())
                .dateDebut(request.dateDebut())
                .actif(request.actif() != null ? request.actif() : true)
                .category(resolveCategory(request.categoryId(), userId))
                .account(account)
                .currency(currency)
                .user(user)
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
        Account account = resolveAccount(request.accountId(), userId);
        User user = userRepository.getReferenceById(userId);
        Currency currency = resolveCurrency(request.currency(), account, user);

        subscription.setNom(request.nom());
        subscription.setMontant(request.montant());
        subscription.setFrequence(request.frequence());
        subscription.setDateDebut(request.dateDebut());
        if (request.actif() != null) {
            subscription.setActif(request.actif());
        }
        subscription.setCategory(resolveCategory(request.categoryId(), userId));
        subscription.setAccount(account);
        subscription.setCurrency(currency);

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

    private Currency resolveCurrency(Currency requestCurrency, Account account, User user) {
        if (account != null) {
            return account.getCurrency();
        }
        if (requestCurrency != null) {
            return requestCurrency;
        }
        return preferenceService.getOrCreatePreference(user.getId()).getCurrencies().get(0);
    }

    private Account resolveAccount(UUID accountId, UUID userId) {
        if (accountId == null) {
            return null;
        }
        return accountRepository.findById(accountId)
                .filter(a -> a.getUser().getId().equals(userId))
                .filter(a -> Boolean.TRUE.equals(a.getActif()))
                .orElseThrow(() -> {
                    log.error("Compte non trouvé ou inactif: id={}, userId={}", accountId, userId);
                    return new EntityNotFoundException("Account not found or inactive");
                });
    }

    private Subscription findByIdAndUser(UUID id, UUID userId) {
        return subscriptionRepository.findById(id)
                .filter(s -> s.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Abonnement non trouvé: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Subscription not found");
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
                    return new EntityNotFoundException("Category not found");
                });
    }

    private SubscriptionResponse toResponse(Subscription subscription) {
        return new SubscriptionResponse(
                subscription.getId(),
                subscription.getNom(),
                subscription.getMontant(),
                subscription.getFrequence(),
                subscription.getDateDebut(),
                subscription.getActif(),
                CategoryResponse.from(subscription.getCategory()),
                AccountSummary.from(subscription.getAccount()),
                subscription.getCurrency().name()
        );
    }
}
