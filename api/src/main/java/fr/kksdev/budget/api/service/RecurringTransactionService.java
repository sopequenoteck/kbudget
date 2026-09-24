package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.RecurringTransactionRequest;
import fr.kksdev.budget.api.dto.response.AccountSummary;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.dto.response.RecurringTransactionResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RecurringTransactionService {

    private final TransactionRepository transactionRepository;
    private final AccountRepository accountRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final BudgetService budgetService;

    @Transactional
    public RecurringTransactionResponse create(RecurringTransactionRequest request, UUID userId) {
        Account account = resolveAccount(request.accountId(), userId);
        Category category = resolveCategory(request.categoryId(), userId);

        Transaction recurring = Transaction.builder()
                .montant(request.montant())
                .libelle(request.libelle())
                .type(request.type())
                .date(request.nextOccurrence())
                .category(category)
                .note(request.note())
                .account(account)
                .user(userRepository.getReferenceById(userId))
                .isRecurring(true)
                .frequency(request.frequency())
                .nextOccurrence(request.nextOccurrence())
                .recurringActive(true)
                .build();

        recurring = transactionRepository.save(recurring);
        log.info("Transaction récurrente créée: {} pour userId={}", recurring.getId(), userId);
        return toResponse(recurring);
    }

    public List<RecurringTransactionResponse> listActive(UUID userId) {
        return transactionRepository.findByUserIdAndIsRecurringTrueAndRecurringActiveTrueOrderByNextOccurrenceAsc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public TransactionResponse validate(UUID id, UUID userId) {
        Transaction recurring = findRecurringByIdAndUser(id, userId);

        if (!Boolean.TRUE.equals(recurring.getRecurringActive())) {
            throw new IllegalStateException("The recurring transaction is disabled");
        }

        Account account = recurring.getAccount();
        if (account == null || !Boolean.TRUE.equals(account.getActif())) {
            account = accountRepository.findByUserIdAndIsDefaultTrue(userId)
                    .orElseThrow(() -> new EntityNotFoundException("No default account found"));
        }

        Transaction newTransaction = Transaction.builder()
                .montant(recurring.getMontant())
                .libelle(recurring.getLibelle())
                .type(recurring.getType())
                .date(LocalDate.now())
                .category(recurring.getCategory())
                .note(recurring.getNote())
                .account(account)
                .user(userRepository.getReferenceById(userId))
                .build();

        newTransaction = transactionRepository.save(newTransaction);

        recurring.setNextOccurrence(advanceDate(recurring.getNextOccurrence(), recurring.getFrequency()));
        transactionRepository.save(recurring);

        log.info("Transaction récurrente validée: recurring={}, newTransaction={}, userId={}", id, newTransaction.getId(), userId);

        if (newTransaction.getType() == TransactionType.DEPENSE && newTransaction.getCategory() != null) {
            try {
                budgetService.checkThresholdsForCategory(userId, newTransaction.getCategory().getId());
            } catch (Exception e) {
                log.warn("Erreur vérification seuil budget: {}", e.getMessage());
            }
        }

        return toTransactionResponse(newTransaction);
    }

    @Transactional
    public RecurringTransactionResponse skip(UUID id, UUID userId) {
        Transaction recurring = findRecurringByIdAndUser(id, userId);

        if (!Boolean.TRUE.equals(recurring.getRecurringActive())) {
            throw new IllegalStateException("The recurring transaction is disabled");
        }

        recurring.setNextOccurrence(advanceDate(recurring.getNextOccurrence(), recurring.getFrequency()));
        recurring = transactionRepository.save(recurring);
        log.info("Transaction récurrente passée (skip): id={}, userId={}", id, userId);
        return toResponse(recurring);
    }

    @Transactional
    public RecurringTransactionResponse deactivate(UUID id, UUID userId) {
        Transaction recurring = findRecurringByIdAndUser(id, userId);

        if (!Boolean.TRUE.equals(recurring.getRecurringActive())) {
            throw new IllegalStateException("The recurring transaction is already disabled");
        }

        recurring.setRecurringActive(false);
        recurring = transactionRepository.save(recurring);
        log.info("Transaction récurrente désactivée: id={}, userId={}", id, userId);
        return toResponse(recurring);
    }

    LocalDate advanceDate(LocalDate current, Frequency frequency) {
        return switch (frequency) {
            case HEBDOMADAIRE -> current.plusWeeks(1);
            case MENSUEL -> current.plusMonths(1);
            case ANNUEL -> current.plusYears(1);
        };
    }

    private Transaction findRecurringByIdAndUser(UUID id, UUID userId) {
        return transactionRepository.findById(id)
                .filter(t -> t.getUser().getId().equals(userId))
                .filter(t -> Boolean.TRUE.equals(t.getIsRecurring()))
                .orElseThrow(() -> {
                    log.error("Transaction récurrente non trouvée: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Recurring transaction not found");
                });
    }

    private Account resolveAccount(UUID accountId, UUID userId) {
        if (accountId == null) {
            return accountRepository.findByUserIdAndIsDefaultTrue(userId)
                    .orElseThrow(() -> new EntityNotFoundException("No default account found"));
        }
        return accountRepository.findById(accountId)
                .filter(a -> a.getUser().getId().equals(userId))
                .filter(a -> Boolean.TRUE.equals(a.getActif()))
                .orElseThrow(() -> {
                    log.error("Compte non trouvé ou inactif: id={}, userId={}", accountId, userId);
                    return new EntityNotFoundException("Account not found or inactive");
                });
    }

    private Category resolveCategory(UUID categoryId, UUID userId) {
        if (categoryId == null) return null;
        return categoryRepository.findById(categoryId)
                .filter(c -> c.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Catégorie non trouvée: id={}, userId={}", categoryId, userId);
                    return new EntityNotFoundException("Category not found");
                });
    }

    private RecurringTransactionResponse toResponse(Transaction t) {
        return new RecurringTransactionResponse(
                t.getId(), t.getMontant(), t.getLibelle(), t.getType(),
                t.getFrequency(), t.getNextOccurrence(), t.getRecurringActive(),
                CategoryResponse.from(t.getCategory()), AccountSummary.from(t.getAccount())
        );
    }

    private TransactionResponse toTransactionResponse(Transaction t) {
        return new TransactionResponse(
                t.getId(), t.getMontant(), t.getLibelle(), t.getType(),
                t.getDate(), CategoryResponse.from(t.getCategory()), t.getNote(),
                AccountSummary.from(t.getAccount()), t.getTransferId(),
                t.getDebt() != null ? t.getDebt().getId() : null
        );
    }
}
