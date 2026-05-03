package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.DebtRepayRequest;
import fr.kksdev.budget.api.dto.request.DebtRequest;
import fr.kksdev.budget.api.dto.request.DebtSnoozeRequest;
import fr.kksdev.budget.api.dto.response.AccountSummary;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.dto.response.DebtPaymentResponse;
import fr.kksdev.budget.api.dto.response.DebtResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.DebtType;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.ExchangeRate;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.ExchangeRateRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DebtService {

    private final DebtRepository debtRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final AccountRepository accountRepository;
    private final TransactionRepository transactionRepository;
    private final CategoryService categoryService;
    private final PreferenceService preferenceService;
    private final ExchangeRateRepository exchangeRateRepository;

    @Transactional
    public DebtResponse create(DebtRequest request, UUID userId) {
        User user = userRepository.getReferenceById(userId);

        validateReminderFields(request);

        Account account = resolveAccount(request.accountId(), userId);
        Currency currency;
        if (account != null) {
            currency = account.getCurrency();
        } else {
            currency = request.currency() != null ? request.currency()
                    : preferenceService.getOrCreatePreference(userId).getCurrencies().getFirst();
        }
        boolean includeInBalance = account == null && Boolean.TRUE.equals(request.includeInBalance());

        Debt debt = Debt.builder()
                .personne(request.personne())
                .montant(request.montant())
                .sens(request.sens())
                .date(request.date())
                .dueDate(request.dueDate())
                .rembourse(request.rembourse() != null ? request.rembourse() : false)
                .category(resolveCategory(request.categoryId(), userId))
                .currency(currency)
                .account(account)
                .includeInBalance(includeInBalance)
                .reminderDate(request.reminderDate())
                .reminderTime(request.reminderTime())
                .user(user)
                .build();

        debt = debtRepository.save(debt);
        log.info("Dette créée: {} pour userId {}", debt.getId(), userId);
        return toResponse(debt);
    }

    public List<DebtResponse> getAllByUser(UUID userId) {
        List<Debt> debts = debtRepository.findByUserIdOrderByDateDesc(userId);
        if (debts.isEmpty()) return List.of();
        Map<UUID, BigDecimal> paidMap = buildPaidMap(debts);
        return debts.stream()
                .map(d -> toResponse(d, paidMap.getOrDefault(d.getId(), BigDecimal.ZERO)))
                .toList();
    }

    public List<DebtResponse> getUnpaidByUser(UUID userId) {
        List<Debt> debts = debtRepository.findByUserIdAndRembourseFalseOrderByDateDesc(userId);
        if (debts.isEmpty()) return List.of();
        Map<UUID, BigDecimal> paidMap = buildPaidMap(debts);
        return debts.stream()
                .map(d -> toResponse(d, paidMap.getOrDefault(d.getId(), BigDecimal.ZERO)))
                .toList();
    }

    public DebtResponse getById(UUID id, UUID userId) {
        Debt debt = findByIdAndUser(id, userId);
        return toResponse(debt);
    }

    @Transactional
    public DebtResponse update(UUID id, DebtRequest request, UUID userId) {
        Debt debt = findByIdAndUser(id, userId);

        validateReminderFields(request);

        Account account = resolveAccount(request.accountId(), userId);
        boolean includeInBalance = account == null && Boolean.TRUE.equals(request.includeInBalance());

        debt.setPersonne(request.personne());
        debt.setSens(request.sens());
        debt.setDate(request.date());
        debt.setDueDate(request.dueDate());
        if (request.rembourse() != null) {
            debt.setRembourse(request.rembourse());
        }
        debt.setCategory(resolveCategory(request.categoryId(), userId));

        // Logique devise/compte (US2)
        if (account != null) {
            Currency newCurrency = account.getCurrency();
            if (debt.getCurrency() != newCurrency) {
                BigDecimal rate = findPivotRate(userId, debt.getCurrency(), newCurrency);
                if (rate == null) {
                    throw new IllegalArgumentException("Taux de change indisponible pour " + debt.getCurrency() + " → " + newCurrency);
                }
                // request.montant() est dans la devise source (ancienne) — conversion vers la nouvelle devise du compte
                debt.setMontant(request.montant().multiply(rate).setScale(2, RoundingMode.HALF_UP));
                debt.setCurrency(newCurrency);
                List<Transaction> payments = transactionRepository.findByDebtIdOrderByDateDesc(debt.getId());
                for (Transaction tx : payments) {
                    tx.setMontant(tx.getMontant().multiply(rate).setScale(2, RoundingMode.HALF_UP));
                    transactionRepository.save(tx);
                }
            } else {
                debt.setMontant(request.montant());
            }
        } else {
            debt.setMontant(request.montant());
            // Dissociation: conserver la devise actuelle sauf si explicitement fournie
            if (request.currency() != null) {
                debt.setCurrency(request.currency());
            }
        }

        debt.setAccount(account);
        debt.setIncludeInBalance(includeInBalance);
        debt.setReminderDate(request.reminderDate());
        debt.setReminderTime(request.reminderTime());

        debt = debtRepository.save(debt);
        log.info("Dette mise à jour: {}", debt.getId());
        return toResponse(debt);
    }

    @Transactional
    public DebtResponse repay(UUID debtId, DebtRepayRequest request, UUID userId) {
        Debt debt = debtRepository.findByIdForUpdate(debtId)
                .filter(d -> d.getUser().getId().equals(userId))
                .orElseThrow(() -> new EntityNotFoundException("Dette non trouvée"));

        if (Boolean.TRUE.equals(debt.getRembourse())) {
            throw new IllegalArgumentException("Cette dette est déjà remboursée");
        }

        BigDecimal paid = transactionRepository.sumByDebtId(debt.getId());
        BigDecimal montantRestant = debt.getMontant().subtract(paid != null ? paid : BigDecimal.ZERO);

        BigDecimal amount = request.amount() != null ? request.amount() : montantRestant;
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Le montant du remboursement doit être positif");
        }
        if (amount.compareTo(montantRestant) > 0) {
            throw new IllegalArgumentException("Le montant dépasse le montant restant (" + montantRestant + ")");
        }

        Account account = accountRepository.findById(request.accountId())
                .filter(a -> a.getUser().getId().equals(userId))
                .orElseThrow(() -> new EntityNotFoundException("Compte non trouvé"));
        if (!Boolean.TRUE.equals(account.getActif())) {
            throw new IllegalArgumentException("Le compte est inactif");
        }

        TransactionType txType = debt.getSens() == DebtType.EMPRUNT
                ? TransactionType.DEPENSE : TransactionType.RECETTE;

        Transaction transaction = Transaction.builder()
                .montant(amount)
                .libelle("Remboursement - " + debt.getPersonne())
                .type(txType)
                .date(LocalDate.now())
                .category(debt.getCategory())
                .account(account)
                .debt(debt)
                .user(userRepository.getReferenceById(userId))
                .build();
        transactionRepository.save(transaction);

        // Recalculer si dette totalement remboursée
        BigDecimal newPaid = (paid != null ? paid : BigDecimal.ZERO).add(amount);
        BigDecimal newRemaining = debt.getMontant().subtract(newPaid);
        if (newRemaining.compareTo(BigDecimal.ZERO) <= 0) {
            debt.setRembourse(true);
            debtRepository.save(debt);
        }

        log.info("Remboursement effectué: debtId={}, montant={}, userId={}", debtId, amount, userId);
        return toResponse(debt, newPaid);
    }

    public List<DebtPaymentResponse> getPayments(UUID debtId, UUID userId) {
        findByIdAndUser(debtId, userId);
        return transactionRepository.findByDebtIdOrderByDateDesc(debtId).stream()
                .map(t -> new DebtPaymentResponse(
                        t.getId(),
                        t.getMontant(),
                        t.getDate(),
                        t.getAccount() != null ? t.getAccount().getNom() : null
                ))
                .toList();
    }

    @Transactional
    public DebtResponse snooze(UUID debtId, DebtSnoozeRequest request, UUID userId) {
        Debt debt = findByIdAndUser(debtId, userId);

        if (debt.getReminderDate() == null || debt.getReminderTime() == null) {
            throw new IllegalArgumentException("Cette dette n'a pas de rappel configuré");
        }

        debt.setReminderDate(request.reminderDate());
        debt.setReminderTime(request.reminderTime());
        debt = debtRepository.save(debt);
        log.info("Rappel reporté: debtId={}, nouvelleDate={}, userId={}", debtId, request.reminderDate(), userId);
        return toResponse(debt);
    }

    @Transactional
    public void delete(UUID id, UUID userId) {
        Debt debt = findByIdAndUser(id, userId);
        List<Transaction> payments = transactionRepository.findByDebtIdOrderByDateDesc(id);
        for (Transaction tx : payments) {
            tx.setDebt(null);
            tx.setLibelle(tx.getLibelle() + " (dette supprimée - " + debt.getPersonne() + ")");
            transactionRepository.save(tx);
        }
        debtRepository.delete(debt);
        log.info("Dette supprimée: {}", id);
    }

    private void validateReminderFields(DebtRequest request) {
        boolean hasDate = request.reminderDate() != null;
        boolean hasTime = request.reminderTime() != null;
        if (hasDate ^ hasTime) {
            throw new IllegalArgumentException("reminderDate et reminderTime doivent être fournis ensemble");
        }
    }

    private Account resolveAccount(UUID accountId, UUID userId) {
        if (accountId == null) {
            return null;
        }
        return accountRepository.findById(accountId)
                .filter(a -> a.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Compte non trouvé: id={}, userId={}", accountId, userId);
                    return new EntityNotFoundException("Compte non trouvé");
                });
    }

    private Debt findByIdAndUser(UUID id, UUID userId) {
        return debtRepository.findById(id)
                .filter(d -> d.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Dette non trouvée: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Dette non trouvée");
                });
    }

    private Category resolveCategory(UUID categoryId, UUID userId) {
        if (categoryId == null) {
            return categoryService.findSystemCategoryByNom("Dette", userId);
        }
        return categoryRepository.findById(categoryId)
                .filter(c -> c.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Catégorie non trouvée: id={}, userId={}", categoryId, userId);
                    return new EntityNotFoundException("Catégorie non trouvée");
                });
    }

    private BigDecimal findPivotRate(UUID userId, Currency from, Currency to) {
        List<ExchangeRate> rates = exchangeRateRepository.findAllByUserId(userId);
        for (ExchangeRate r : rates) {
            if (r.getBaseCurrency() == from && r.getTargetCurrency() == to) return r.getRate();
        }
        for (ExchangeRate r : rates) {
            if (r.getBaseCurrency() == to && r.getTargetCurrency() == from) {
                return BigDecimal.ONE.divide(r.getRate(), 6, RoundingMode.HALF_UP);
            }
        }
        return null;
    }

    private DebtResponse toResponse(Debt debt) {
        BigDecimal paid = transactionRepository.sumByDebtId(debt.getId());
        return toResponse(debt, paid);
    }

    private DebtResponse toResponse(Debt debt, BigDecimal paid) {
        BigDecimal montantRestant = debt.getMontant().subtract(paid != null ? paid : BigDecimal.ZERO);
        return new DebtResponse(
                debt.getId(),
                debt.getPersonne(),
                debt.getMontant(),
                debt.getSens(),
                debt.getDate(),
                debt.getDueDate(),
                debt.getCurrency().name(),
                debt.getRembourse(),
                montantRestant,
                CategoryResponse.from(debt.getCategory()),
                AccountSummary.from(debt.getAccount()),
                debt.getIncludeInBalance(),
                debt.getReminderDate(),
                debt.getReminderTime()
        );
    }

    private Map<UUID, BigDecimal> buildPaidMap(List<Debt> debts) {
        List<UUID> debtIds = debts.stream().map(Debt::getId).toList();
        List<Object[]> rows = transactionRepository.sumByDebtIds(debtIds);
        Map<UUID, BigDecimal> map = new HashMap<>();
        for (Object[] row : rows) {
            UUID debtId = (UUID) row[0];
            BigDecimal sum = (BigDecimal) row[1];
            map.put(debtId, sum);
        }
        return map;
    }
}
