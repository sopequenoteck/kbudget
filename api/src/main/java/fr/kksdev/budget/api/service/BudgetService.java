package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.BudgetRequest;
import fr.kksdev.budget.api.dto.response.*;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.FeatureDisabledException;
import fr.kksdev.budget.api.model.Budget;
import fr.kksdev.budget.api.model.BudgetSnapshot;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.ExchangeRate;
import fr.kksdev.budget.api.repository.BudgetRepository;
import fr.kksdev.budget.api.repository.BudgetSnapshotRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
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
import java.time.YearMonth;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BudgetService {

    private static final BigDecimal WEEKS_PER_MONTH = BigDecimal.valueOf(4.33);

    private final BudgetRepository budgetRepository;
    private final BudgetSnapshotRepository budgetSnapshotRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final PreferenceService preferenceService;
    private final ExchangeRateRepository exchangeRateRepository;

    @Transactional
    public BudgetResponse create(BudgetRequest request, UUID userId) {
        checkFeatureEnabled(userId);
        Category category = categoryRepository.findById(request.categoryId())
                .filter(c -> c.getUser().getId().equals(userId))
                .orElseThrow(() -> new EntityNotFoundException("Catégorie non trouvée"));
        if (budgetRepository.existsByCategoryIdAndUserId(request.categoryId(), userId)) {
            throw new ConflictException("Un budget existe déjà pour cette catégorie");
        }
        Budget budget = Budget.builder()
                .montant(request.montant())
                .frequence(request.frequence())
                .category(category)
                .user(userRepository.getReferenceById(userId))
                .build();
        if (request.currency() != null) {
            budget.setCurrency(request.currency());
        }
        if (request.seuilNotification() != null) {
            budget.setSeuilNotification(request.seuilNotification());
        }
        Budget saved = budgetRepository.save(budget);
        log.info("Budget créé: id={}, categoryId={}, userId={}", saved.getId(), request.categoryId(), userId);
        return toResponse(saved);
    }

    public List<BudgetResponse> getAll(UUID userId, boolean includeInactive) {
        checkFeatureEnabled(userId);
        List<Budget> budgets = includeInactive
                ? budgetRepository.findByUserId(userId)
                : budgetRepository.findByUserIdAndActifTrue(userId);
        return budgets.stream()
                .map(b -> toResponseWithSpent(b, userId))
                .toList();
    }

    public BudgetResponse getById(UUID id, UUID userId) {
        checkFeatureEnabled(userId);
        Budget budget = findByIdAndUser(id, userId);
        return toResponseWithSpent(budget, userId);
    }

    @Transactional
    public BudgetResponse update(UUID id, BudgetRequest request, UUID userId) {
        checkFeatureEnabled(userId);
        Budget budget = findByIdAndUser(id, userId);
        budget.setMontant(request.montant());
        budget.setFrequence(request.frequence());
        if (request.currency() != null) {
            budget.setCurrency(request.currency());
        }
        if (request.seuilNotification() != null) {
            budget.setSeuilNotification(request.seuilNotification());
        }
        if (request.actif() != null) {
            budget.setActif(request.actif());
        }
        if (!request.categoryId().equals(budget.getCategory().getId())) {
            if (budgetRepository.existsByCategoryIdAndUserId(request.categoryId(), userId)) {
                throw new ConflictException("Un budget existe déjà pour cette catégorie");
            }
            Category newCategory = categoryRepository.findById(request.categoryId())
                    .filter(c -> c.getUser().getId().equals(userId))
                    .orElseThrow(() -> new EntityNotFoundException("Catégorie non trouvée"));
            budget.setCategory(newCategory);
        }
        Budget saved = budgetRepository.save(budget);
        log.info("Budget mis à jour: id={}, userId={}", id, userId);
        return toResponseWithSpent(saved, userId);
    }

    @Transactional
    public void delete(UUID id, UUID userId) {
        checkFeatureEnabled(userId);
        Budget budget = findByIdAndUser(id, userId);
        budgetRepository.delete(budget);
        log.info("Budget supprimé: id={}, userId={}", id, userId);
    }

    public BudgetOverviewResponse getOverview(UUID userId) {
        checkFeatureEnabled(userId);
        List<Budget> budgets = budgetRepository.findByUserIdAndActifTrue(userId);
        Currency primaryCurrency = getPrimaryCurrency(userId);
        LocalDate now = LocalDate.now();
        LocalDate firstDay = now.withDayOfMonth(1);
        LocalDate lastDay = YearMonth.from(now).atEndOfMonth();
        String month = YearMonth.from(now).toString();

        BigDecimal totalBudget = BigDecimal.ZERO;
        BigDecimal totalSpent = BigDecimal.ZERO;
        List<BudgetOverviewItemResponse> items = new ArrayList<>();

        for (Budget budget : budgets) {
            BigDecimal normalised = normalizeMontantMensuel(budget);
            BigDecimal spent = transactionRepository.sumDepenseByUserIdAndCategoryIdAndDateBetween(
                    userId, budget.getCategory().getId(), firstDay, lastDay);

            BigDecimal normalisedConverted = normalised;
            if (budget.getCurrency() != primaryCurrency) {
                BigDecimal rate = getExchangeRate(userId, budget.getCurrency(), primaryCurrency);
                normalisedConverted = normalised.multiply(rate).setScale(2, RoundingMode.HALF_UP);
            }

            BigDecimal percentage = normalisedConverted.compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ZERO
                    : spent.multiply(BigDecimal.valueOf(100)).divide(normalisedConverted, 2, RoundingMode.HALF_UP);

            items.add(new BudgetOverviewItemResponse(
                    budget.getId(),
                    budget.getCategory().getId(),
                    budget.getCategory().getNom(),
                    budget.getCategory().getIcone(),
                    budget.getCategory().getCouleur(),
                    budget.getMontant(),
                    normalisedConverted,
                    budget.getCurrency().name(),
                    spent,
                    percentage,
                    budget.getFrequence().name()
            ));

            totalBudget = totalBudget.add(normalisedConverted);
            totalSpent = totalSpent.add(spent);
        }

        BigDecimal totalPercentage = totalBudget.compareTo(BigDecimal.ZERO) == 0
                ? BigDecimal.ZERO
                : totalSpent.multiply(BigDecimal.valueOf(100)).divide(totalBudget, 2, RoundingMode.HALF_UP);

        return new BudgetOverviewResponse(month, totalBudget, totalSpent, totalPercentage, primaryCurrency.name(), items);
    }

    @Transactional
    public BudgetHistoryResponse getHistory(String month, UUID userId) {
        checkFeatureEnabled(userId);

        YearMonth targetMonth;
        try {
            targetMonth = YearMonth.parse(month);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Format de mois invalide. Utilisez YYYY-MM");
        }

        YearMonth currentMonth = YearMonth.now();
        if (!targetMonth.isBefore(currentMonth)) {
            throw new IllegalArgumentException("Seuls les mois passés sont autorisés");
        }

        Currency primaryCurrency = getPrimaryCurrency(userId);
        List<BudgetSnapshot> snapshots = budgetSnapshotRepository.findByUserIdAndMois(userId, month);

        if (snapshots.isEmpty()) {
            snapshots = createSnapshotsLazily(month, targetMonth, userId, primaryCurrency);
        }

        BigDecimal totalBudget = BigDecimal.ZERO;
        BigDecimal totalSpent = BigDecimal.ZERO;
        List<BudgetHistoryItemResponse> items = new ArrayList<>();

        for (BudgetSnapshot snapshot : snapshots) {
            BigDecimal convertedBudget = snapshot.getMontantBudget();
            if (snapshot.getTauxChange() != null) {
                convertedBudget = snapshot.getMontantBudget().multiply(snapshot.getTauxChange())
                        .setScale(2, RoundingMode.HALF_UP);
            }

            BigDecimal percentage = convertedBudget.compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ZERO
                    : snapshot.getMontantDepense().multiply(BigDecimal.valueOf(100))
                            .divide(convertedBudget, 2, RoundingMode.HALF_UP);

            items.add(new BudgetHistoryItemResponse(
                    snapshot.getCategory().getId(),
                    snapshot.getCategory().getNom(),
                    snapshot.getCategory().getIcone(),
                    snapshot.getCategory().getCouleur(),
                    snapshot.getMontantBudget(),
                    snapshot.getCurrency().name(),
                    snapshot.getTauxChange(),
                    snapshot.getMontantDepense(),
                    percentage,
                    snapshot.getCreatedAt()
            ));

            totalBudget = totalBudget.add(convertedBudget);
            totalSpent = totalSpent.add(snapshot.getMontantDepense());
        }

        BigDecimal totalPercentage = totalBudget.compareTo(BigDecimal.ZERO) == 0
                ? BigDecimal.ZERO
                : totalSpent.multiply(BigDecimal.valueOf(100)).divide(totalBudget, 2, RoundingMode.HALF_UP);

        return new BudgetHistoryResponse(month, totalBudget, totalSpent, totalPercentage, primaryCurrency.name(), items);
    }

    private void checkFeatureEnabled(UUID userId) {
        if (!preferenceService.isFeatureEnabled(userId, Feature.BUDGETS)) {
            throw new FeatureDisabledException("BUDGETS");
        }
    }

    private Budget findByIdAndUser(UUID id, UUID userId) {
        return budgetRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> {
                    log.error("Budget non trouvé: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Budget non trouvé");
                });
    }

    private BudgetResponse toResponse(Budget budget) {
        return new BudgetResponse(
                budget.getId(),
                budget.getMontant(),
                budget.getCurrency().name(),
                budget.getFrequence().name(),
                budget.getSeuilNotification(),
                budget.getActif(),
                toCategoryResponse(budget.getCategory()),
                null,
                budget.getUpdatedAt()
        );
    }

    private BudgetResponse toResponseWithSpent(Budget budget, UUID userId) {
        LocalDate now = LocalDate.now();
        LocalDate firstDay = now.withDayOfMonth(1);
        LocalDate lastDay = YearMonth.from(now).atEndOfMonth();
        BigDecimal spent = transactionRepository.sumDepenseByUserIdAndCategoryIdAndDateBetween(
                userId, budget.getCategory().getId(), firstDay, lastDay);
        return new BudgetResponse(
                budget.getId(),
                budget.getMontant(),
                budget.getCurrency().name(),
                budget.getFrequence().name(),
                budget.getSeuilNotification(),
                budget.getActif(),
                toCategoryResponse(budget.getCategory()),
                spent,
                budget.getUpdatedAt()
        );
    }

    private BigDecimal normalizeMontantMensuel(Budget budget) {
        BigDecimal montant = budget.getMontant();
        Frequency frequence = budget.getFrequence();
        return switch (frequence) {
            case HEBDOMADAIRE -> montant.multiply(WEEKS_PER_MONTH).setScale(2, RoundingMode.HALF_UP);
            case MENSUEL -> montant;
            case ANNUEL -> montant.divide(BigDecimal.valueOf(12), 2, RoundingMode.HALF_UP);
        };
    }

    private CategoryResponse toCategoryResponse(Category cat) {
        return new CategoryResponse(
                cat.getId(),
                cat.getNom(),
                cat.getIcone(),
                cat.getCouleur(),
                cat.getIsSystem()
        );
    }

    private Currency getPrimaryCurrency(UUID userId) {
        var preference = preferenceService.getOrCreatePreference(userId);
        List<Currency> currencies = preference.getCurrencies();
        return (currencies != null && !currencies.isEmpty()) ? currencies.get(0) : Currency.EUR;
    }

    private BigDecimal getExchangeRate(UUID userId, Currency from, Currency to) {
        return exchangeRateRepository.findByUserIdAndBaseCurrencyAndTargetCurrency(userId, from, to)
                .map(ExchangeRate::getRate)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Taux de change manquant pour " + from.name() + " → " + to.name()));
    }

    private List<BudgetSnapshot> createSnapshotsLazily(String month, YearMonth targetMonth, UUID userId, Currency primaryCurrency) {
        List<Budget> budgets = budgetRepository.findByUserIdAndActifTrue(userId);
        LocalDate firstDay = targetMonth.atDay(1);
        LocalDate lastDay = targetMonth.atEndOfMonth();
        List<BudgetSnapshot> snapshots = new ArrayList<>();

        for (Budget budget : budgets) {
            BigDecimal normalised = normalizeMontantMensuel(budget);
            BigDecimal spent = transactionRepository.sumDepenseByUserIdAndCategoryIdAndDateBetween(
                    userId, budget.getCategory().getId(), firstDay, lastDay);

            BigDecimal tauxChange = null;
            if (budget.getCurrency() != primaryCurrency) {
                tauxChange = getExchangeRate(userId, budget.getCurrency(), primaryCurrency);
            }

            BudgetSnapshot snapshot = BudgetSnapshot.builder()
                    .montantBudget(normalised)
                    .currency(budget.getCurrency())
                    .tauxChange(tauxChange)
                    .montantDepense(spent)
                    .mois(month)
                    .category(budget.getCategory())
                    .user(userRepository.getReferenceById(userId))
                    .build();
            snapshots.add(budgetSnapshotRepository.save(snapshot));
        }

        log.info("Snapshots créés: mois={}, count={}, userId={}", month, snapshots.size(), userId);
        return snapshots;
    }
}
