package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.TransactionRequest;
import fr.kksdev.budget.api.dto.response.AccountSummary;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.dto.response.MonthlySummaryResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final AccountRepository accountRepository;
    private final PreferenceService preferenceService;
    private final BudgetService budgetService;
    private final DebtRepository debtRepository;
    private final ExchangeRateService exchangeRateService;

    @Transactional
    public TransactionResponse create(TransactionRequest request, UUID userId) {
        if (request.type() == TransactionType.AJUSTEMENT) {
            throw new IllegalArgumentException("Les transactions d'ajustement ne peuvent être créées que via l'endpoint adjust-balance");
        }

        Account account = resolveAccount(request.accountId(), userId);

        Transaction transaction = Transaction.builder()
                .montant(request.montant())
                .libelle(request.libelle())
                .type(request.type())
                .date(request.date())
                .category(resolveCategory(request.categoryId(), userId))
                .note(request.note())
                .account(account)
                .user(userRepository.getReferenceById(userId))
                .build();

        transaction = transactionRepository.save(transaction);
        log.info("Transaction créée: {} pour userId {}", transaction.getId(), userId);
        if (transaction.getType() == TransactionType.DEPENSE && transaction.getCategory() != null) {
            try {
                budgetService.checkThresholdsForCategory(userId, transaction.getCategory().getId());
            } catch (Exception e) {
                log.warn("Erreur vérification seuil budget: {}", e.getMessage());
            }
        }
        return toResponse(transaction);
    }

    public List<TransactionResponse> getAllByUser(UUID userId) {
        return transactionRepository.findByUserIdAndIsRecurringFalseOrderByDateDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public TransactionResponse getById(UUID id, UUID userId) {
        Transaction transaction = findByIdAndUser(id, userId);
        return toResponse(transaction);
    }

    @Transactional
    public TransactionResponse update(UUID id, TransactionRequest request, UUID userId) {
        Transaction transaction = findByIdAndUser(id, userId);

        if (transaction.getType() == TransactionType.AJUSTEMENT) {
            log.warn("Tentative de modification d'une transaction d'ajustement: id={}, userId={}", id, userId);
            throw new AccessDeniedException("Les transactions d'ajustement ne peuvent pas être modifiées");
        }

        // Interdire le changement de type sur les transactions liées à une dette
        if (transaction.getDebt() != null && request.type() != transaction.getType()) {
            throw new IllegalArgumentException("Le type d'une transaction liée à une dette ne peut pas être modifié");
        }

        // Propager le montant si c'est une transaction de virement
        if (transaction.getTransferId() != null && request.montant().compareTo(transaction.getMontant()) != 0) {
            propagateTransferAmount(transaction, request.montant());
        }

        transaction.setMontant(request.montant());
        transaction.setLibelle(request.libelle());
        transaction.setType(request.type());
        transaction.setDate(request.date());
        transaction.setCategory(resolveCategory(request.categoryId(), userId));
        transaction.setNote(request.note());

        transaction = transactionRepository.save(transaction);
        log.info("Transaction mise à jour: {}", transaction.getId());
        if (transaction.getDebt() != null) {
            Debt debt = transaction.getDebt();
            BigDecimal paid = transactionRepository.sumByDebtId(debt.getId());
            BigDecimal remaining = debt.getMontant().subtract(paid != null ? paid : BigDecimal.ZERO);
            debt.setRembourse(remaining.compareTo(BigDecimal.ZERO) <= 0);
            debtRepository.save(debt);
        }
        if (transaction.getType() == TransactionType.DEPENSE && transaction.getCategory() != null) {
            try {
                budgetService.checkThresholdsForCategory(userId, transaction.getCategory().getId());
            } catch (Exception e) {
                log.warn("Erreur vérification seuil budget: {}", e.getMessage());
            }
        }
        return toResponse(transaction);
    }

    @Transactional
    public void delete(UUID id, UUID userId) {
        Transaction transaction = findByIdAndUser(id, userId);

        if (transaction.getType() == TransactionType.AJUSTEMENT) {
            log.warn("Tentative de suppression d'une transaction d'ajustement: id={}, userId={}", id, userId);
            throw new AccessDeniedException("Les transactions d'ajustement ne peuvent pas être supprimées");
        }

        TransactionType deletedType = transaction.getType();
        UUID deletedCategoryId = transaction.getCategory() != null ? transaction.getCategory().getId() : null;

        // Cascade delete pour les virements
        if (transaction.getTransferId() != null) {
            List<Transaction> linked = transactionRepository.findByTransferId(transaction.getTransferId());
            linked.stream()
                    .filter(t -> !t.getId().equals(id))
                    .forEach(t -> {
                        transactionRepository.delete(t);
                        log.info("Transaction liée supprimée (cascade virement): {}", t.getId());
                    });
        }

        transactionRepository.delete(transaction);
        log.info("Transaction supprimée: {}", id);

        // Recalculer rembourse si transaction liée à une dette (FR-023)
        if (transaction.getDebt() != null) {
            Debt debt = transaction.getDebt();
            BigDecimal newPaid = transactionRepository.sumByDebtId(debt.getId());
            BigDecimal newRemaining = debt.getMontant().subtract(newPaid != null ? newPaid : BigDecimal.ZERO);
            if (newRemaining.compareTo(BigDecimal.ZERO) > 0 && Boolean.TRUE.equals(debt.getRembourse())) {
                debt.setRembourse(false);
                debtRepository.save(debt);
                log.info("Dette réouverte après suppression remboursement: debtId={}", debt.getId());
            }
        }

        if (deletedType == TransactionType.DEPENSE && deletedCategoryId != null) {
            try {
                budgetService.checkThresholdsForCategory(userId, deletedCategoryId);
            } catch (Exception e) {
                log.warn("Erreur vérification seuil budget après suppression: {}", e.getMessage());
            }
        }
    }

    public List<TransactionResponse> getByMonth(int month, int year, UUID userId) {
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate from = yearMonth.atDay(1);
        LocalDate to = yearMonth.atEndOfMonth();
        return transactionRepository.findByUserIdAndIsRecurringFalseAndDateBetweenOrderByDateDesc(userId, from, to)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public List<MonthlySummaryResponse> getMonthlySummary(int month, int year, UUID userId) {
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate from = yearMonth.atDay(1);
        LocalDate to = yearMonth.atEndOfMonth();

        List<Transaction> transactions = transactionRepository
                .findByUserIdAndIsRecurringFalseAndDateBetweenOrderByDateDesc(userId, from, to);

        if (transactions.isEmpty()) {
            return List.of();
        }

        // Determine user primary currency
        Currency primaryCurrency = preferenceService.getOrCreatePreference(userId).getCurrencies().getFirst();

        BigDecimal totalRecettes = BigDecimal.ZERO;
        BigDecimal totalDepenses = BigDecimal.ZERO;
        BigDecimal totalAjustements = BigDecimal.ZERO;

        for (Transaction t : transactions) {
            Currency txCurrency = t.getAccount().getCurrency();
            BigDecimal montant = t.getMontant();

            if (txCurrency != primaryCurrency) {
                Optional<BigDecimal> rate = exchangeRateService.getRate(userId, txCurrency, primaryCurrency);
                if (rate.isEmpty()) {
                    log.warn("Taux de change manquant pour {} → {} (userId={}), transaction exclue du bilan", txCurrency, primaryCurrency, userId);
                    continue;
                }
                montant = montant.multiply(rate.get()).setScale(2, RoundingMode.HALF_UP);
            }

            if (t.getType() == TransactionType.RECETTE) {
                totalRecettes = totalRecettes.add(montant);
            } else if (t.getType() == TransactionType.DEPENSE) {
                totalDepenses = totalDepenses.add(montant);
            } else if (t.getType() == TransactionType.AJUSTEMENT) {
                totalAjustements = totalAjustements.add(montant);
            }
        }

        BigDecimal solde = totalRecettes.subtract(totalDepenses).add(totalAjustements);
        log.info("Bilan mensuel {}/{} pour userId={}: agrégé en {}", month, year, userId, primaryCurrency);
        return List.of(new MonthlySummaryResponse(month, year, totalRecettes, totalDepenses, solde, primaryCurrency.name()));
    }

    private void propagateTransferAmount(Transaction transaction, BigDecimal newMontant) {
        List<Transaction> linked = transactionRepository.findByTransferId(transaction.getTransferId());
        linked.stream()
                .filter(t -> !t.getId().equals(transaction.getId()))
                .forEach(t -> {
                    t.setMontant(newMontant);
                    transactionRepository.save(t);
                    log.info("Montant propagé à la transaction liée: {} -> {}", t.getId(), newMontant);
                });
    }

    private Account resolveAccount(UUID accountId, UUID userId) {
        if (accountId == null) {
            return accountRepository.findByUserIdAndIsDefaultTrue(userId)
                    .orElseThrow(() -> new EntityNotFoundException("Aucun compte par défaut trouvé"));
        }
        return accountRepository.findById(accountId)
                .filter(a -> a.getUser().getId().equals(userId))
                .filter(a -> Boolean.TRUE.equals(a.getActif()))
                .orElseThrow(() -> {
                    log.error("Compte non trouvé ou inactif: id={}, userId={}", accountId, userId);
                    return new EntityNotFoundException("Compte non trouvé ou inactif");
                });
    }

    private Transaction findByIdAndUser(UUID id, UUID userId) {
        return transactionRepository.findById(id)
                .filter(t -> t.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Transaction non trouvée: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Transaction non trouvée");
                });
    }

    private Category resolveCategory(UUID categoryId, UUID userId) {
        if (categoryId == null) {
            return null;
        }
        return categoryRepository.findById(categoryId)
                .filter(c -> c.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Catégorie non trouvée: id={}, userId={}", categoryId, userId);
                    return new EntityNotFoundException("Catégorie non trouvée");
                });
    }

    private TransactionResponse toResponse(Transaction transaction) {
        return new TransactionResponse(
                transaction.getId(),
                transaction.getMontant(),
                transaction.getLibelle(),
                transaction.getType(),
                transaction.getDate(),
                CategoryResponse.from(transaction.getCategory()),
                transaction.getNote(),
                AccountSummary.from(transaction.getAccount()),
                transaction.getTransferId(),
                transaction.getDebt() != null ? transaction.getDebt().getId() : null
        );
    }
}
