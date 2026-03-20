package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.SubscriptionPaymentResponse;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SubscriptionPaymentService {

    private final SubscriptionRepository subscriptionRepository;
    private final TransactionRepository transactionRepository;
    private final AccountRepository accountRepository;
    private final UserRepository userRepository;
    private final BudgetService budgetService;

    @Transactional
    public SubscriptionPaymentResponse pay(UUID subscriptionId, UUID userId) {
        Subscription sub = subscriptionRepository.findById(subscriptionId)
                .filter(s -> s.getUser().getId().equals(userId))
                .orElseThrow(() -> new EntityNotFoundException("Abonnement non trouvé"));

        if (!Boolean.TRUE.equals(sub.getActif())) {
            throw new IllegalStateException("L'abonnement est inactif");
        }

        Account account = sub.getAccount();
        if (account == null || !Boolean.TRUE.equals(account.getActif())) {
            account = accountRepository.findByUserIdAndIsDefaultTrue(userId)
                    .orElseThrow(() -> new EntityNotFoundException("Aucun compte par défaut trouvé"));
        }

        Transaction payment = Transaction.builder()
                .montant(sub.getMontant())
                .libelle(sub.getNom())
                .type(TransactionType.DEPENSE)
                .date(LocalDate.now())
                .category(sub.getCategory())
                .account(account)
                .user(userRepository.getReferenceById(userId))
                .subscription(sub)
                .build();

        payment = transactionRepository.save(payment);
        log.info("Paiement abonnement créé: transactionId={}, subscriptionId={}, userId={}", payment.getId(), subscriptionId, userId);

        if (payment.getCategory() != null) {
            try {
                budgetService.checkThresholdsForCategory(userId, payment.getCategory().getId());
            } catch (Exception e) {
                log.warn("Erreur vérification seuil budget: {}", e.getMessage());
            }
        }

        return new SubscriptionPaymentResponse(
                payment.getId(), payment.getMontant(), payment.getDate(),
                sub.getNom(), account.getNom()
        );
    }

    public List<SubscriptionPaymentResponse> getPayments(UUID subscriptionId, UUID userId) {
        subscriptionRepository.findById(subscriptionId)
                .filter(s -> s.getUser().getId().equals(userId))
                .orElseThrow(() -> new EntityNotFoundException("Abonnement non trouvé"));

        return transactionRepository.findBySubscriptionIdAndUserIdOrderByDateDesc(subscriptionId, userId)
                .stream()
                .map(t -> new SubscriptionPaymentResponse(
                        t.getId(), t.getMontant(), t.getDate(),
                        t.getSubscription().getNom(), t.getAccount().getNom()
                ))
                .toList();
    }

    public Map<String, Object> getTotalPaid(UUID subscriptionId, UUID userId) {
        Subscription sub = subscriptionRepository.findById(subscriptionId)
                .filter(s -> s.getUser().getId().equals(userId))
                .orElseThrow(() -> new EntityNotFoundException("Abonnement non trouvé"));

        BigDecimal total = transactionRepository.sumBySubscriptionIdAndUserId(subscriptionId, userId);
        long count = transactionRepository.countBySubscriptionIdAndUserId(subscriptionId, userId);

        return Map.of(
                "subscriptionId", subscriptionId,
                "subscriptionName", sub.getNom(),
                "totalPaid", total,
                "paymentCount", count
        );
    }
}
