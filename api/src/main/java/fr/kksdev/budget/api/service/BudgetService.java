package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.BudgetRequest;
import fr.kksdev.budget.api.dto.response.*;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.EntityType;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.FeatureDisabledException;
import fr.kksdev.budget.api.model.Budget;
import fr.kksdev.budget.api.model.BudgetSnapshot;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.repository.BudgetRepository;
import fr.kksdev.budget.api.repository.BudgetSnapshotRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.NotificationRepository;
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
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
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
    private final ExchangeRateService exchangeRateService;
    private final NotificationService notificationService;
    private final NotificationRepository notificationRepository;

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
        LocalDate now = LocalDate.now();
        LocalDate firstDay = now.withDayOfMonth(1);
        LocalDate lastDay = YearMonth.from(now).atEndOfMonth();
        Map<UUID, BigDecimal> spentMap = getSpentByCategory(budgets, userId, firstDay, lastDay);
        return budgets.stream()
                .map(b -> toResponse(b, spentMap.getOrDefault(b.getCategory().getId(), BigDecimal.ZERO)))
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
            Category newCategory = categoryRepository.findById(request.categoryId())
                    .filter(c -> c.getUser().getId().equals(userId))
                    .orElseThrow(() -> new EntityNotFoundException("Catégorie non trouvée"));
            if (budgetRepository.existsByCategoryIdAndUserId(request.categoryId(), userId)) {
                throw new ConflictException("Un budget existe déjà pour cette catégorie");
            }
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

        Map<UUID, BigDecimal> spentMap = getSpentByCategory(budgets, userId, firstDay, lastDay);

        for (Budget budget : budgets) {
            BigDecimal normalised = normalizeMontantMensuel(budget);
            BigDecimal spent = spentMap.getOrDefault(budget.getCategory().getId(), BigDecimal.ZERO);

            BigDecimal normalisedConverted = normalised;
            BigDecimal spentConverted = spent; // already in primary currency from getSpentByCategory
            if (budget.getCurrency() != primaryCurrency) {
                Optional<BigDecimal> rate = exchangeRateService.getRate(userId, budget.getCurrency(), primaryCurrency);
                if (rate.isPresent()) {
                    normalisedConverted = normalised.multiply(rate.get()).setScale(2, RoundingMode.HALF_UP);
                }
            }

            BigDecimal percentage = normalisedConverted.compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ZERO
                    : spentConverted.multiply(BigDecimal.valueOf(100)).divide(normalisedConverted, 2, RoundingMode.HALF_UP);

            items.add(new BudgetOverviewItemResponse(
                    budget.getId(),
                    budget.getCategory().getId(),
                    budget.getCategory().getNom(),
                    budget.getCategory().getIcone(),
                    budget.getCategory().getCouleur(),
                    budget.getMontant(),
                    normalisedConverted,
                    primaryCurrency.name(),
                    spentConverted,
                    percentage,
                    budget.getFrequence().name()
            ));

            totalBudget = totalBudget.add(normalisedConverted);
            totalSpent = totalSpent.add(spentConverted);
        }

        BigDecimal totalPercentage = totalBudget.compareTo(BigDecimal.ZERO) == 0
                ? BigDecimal.ZERO
                : totalSpent.multiply(BigDecimal.valueOf(100)).divide(totalBudget, 2, RoundingMode.HALF_UP);

        List<UnbudgetedItemResponse> unbudgetedItems = getUnbudgetedSpending(userId, YearMonth.from(now), primaryCurrency);
        BigDecimal unbudgetedTotal = calculateUnbudgetedTotal(unbudgetedItems);

        return new BudgetOverviewResponse(month, totalBudget, totalSpent, totalPercentage, primaryCurrency.name(), items, unbudgetedItems, unbudgetedTotal);
    }

    /**
     * Récupère l'historique d'un mois passé. Nécessite @Transactional (read-write)
     * car crée les snapshots de manière lazy si absents ({@link #createSnapshotsLazily}).
     */
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
            BigDecimal spentConverted = snapshot.getMontantDepense(); // already in primary currency
            if (snapshot.getTauxChange() != null) {
                convertedBudget = snapshot.getMontantBudget().multiply(snapshot.getTauxChange())
                        .setScale(2, RoundingMode.HALF_UP);
            }

            BigDecimal percentage = convertedBudget.compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ZERO
                    : spentConverted.multiply(BigDecimal.valueOf(100))
                            .divide(convertedBudget, 2, RoundingMode.HALF_UP);

            items.add(new BudgetHistoryItemResponse(
                    snapshot.getCategory().getId(),
                    snapshot.getCategory().getNom(),
                    snapshot.getCategory().getIcone(),
                    snapshot.getCategory().getCouleur(),
                    snapshot.getMontantBudget(),
                    primaryCurrency.name(),
                    snapshot.getTauxChange(),
                    spentConverted,
                    percentage,
                    snapshot.getCreatedAt()
            ));

            totalBudget = totalBudget.add(convertedBudget);
            totalSpent = totalSpent.add(spentConverted);
        }

        BigDecimal totalPercentage = totalBudget.compareTo(BigDecimal.ZERO) == 0
                ? BigDecimal.ZERO
                : totalSpent.multiply(BigDecimal.valueOf(100)).divide(totalBudget, 2, RoundingMode.HALF_UP);

        List<UnbudgetedItemResponse> unbudgetedItems = getUnbudgetedSpending(userId, targetMonth, primaryCurrency);
        BigDecimal unbudgetedTotal = calculateUnbudgetedTotal(unbudgetedItems);

        return new BudgetHistoryResponse(month, totalBudget, totalSpent, totalPercentage, primaryCurrency.name(), items, unbudgetedItems, unbudgetedTotal);
    }

    private List<UnbudgetedItemResponse> getUnbudgetedSpending(UUID userId, YearMonth month, Currency primaryCurrency) {
        LocalDate firstDay = month.atDay(1);
        LocalDate lastDay = month.atEndOfMonth();
        List<Object[]> results = transactionRepository.findUnbudgetedSpendingByMonth(userId, firstDay, lastDay);
        Map<UUID, UnbudgetedItemResponse> merged = new HashMap<>();
        for (Object[] row : results) {
            UUID catId = (UUID) row[0];
            String nom = (String) row[1];
            String icone = (String) row[2];
            String couleur = (String) row[3];
            BigDecimal montant = (BigDecimal) row[4];
            String currencyCode = (String) row[5];
            Currency rowCurrency = Currency.valueOf(currencyCode);
            BigDecimal montantConverti = montant;
            if (rowCurrency != primaryCurrency) {
                Optional<BigDecimal> rate = exchangeRateService.getRate(userId, rowCurrency, primaryCurrency);
                if (rate.isPresent()) {
                    montantConverti = montant.multiply(rate.get()).setScale(2, RoundingMode.HALF_UP);
                } else {
                    log.warn("Taux de change manquant pour {} → {} (userId={}), montant utilisé sans conversion", rowCurrency, primaryCurrency, userId);
                }
            }
            if (merged.containsKey(catId)) {
                UnbudgetedItemResponse existing = merged.get(catId);
                BigDecimal newTotal = existing.montantDepense().add(montantConverti);
                merged.put(catId, new UnbudgetedItemResponse(catId, nom, icone, couleur, newTotal, primaryCurrency.name()));
            } else {
                merged.put(catId, new UnbudgetedItemResponse(catId, nom, icone, couleur, montantConverti, primaryCurrency.name()));
            }
        }
        return new ArrayList<>(merged.values());
    }

    private BigDecimal calculateUnbudgetedTotal(List<UnbudgetedItemResponse> items) {
        return items.stream()
                .map(UnbudgetedItemResponse::montantDepense)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    @Transactional
    public void checkThresholdsForCategory(UUID userId, UUID categoryId) {
        if (userId == null || categoryId == null) {
            return;
        }
        Optional<Budget> budgetOpt = budgetRepository.findByCategoryIdAndUserId(categoryId, userId);
        if (budgetOpt.isEmpty() || !budgetOpt.get().getActif()) {
            return;
        }
        Budget budget = budgetOpt.get();

        LocalDate now = LocalDate.now();
        LocalDate firstDay = now.withDayOfMonth(1);
        LocalDate lastDay = YearMonth.from(now).atEndOfMonth();
        BigDecimal spent = transactionRepository.sumDepenseByUserIdAndCategoryIdAndDateBetween(
                userId, categoryId, firstDay, lastDay);

        BigDecimal monthlyBudget = normalizeMontantMensuel(budget);
        if (monthlyBudget.compareTo(BigDecimal.ZERO) == 0) {
            return;
        }

        BigDecimal percentage = spent.multiply(BigDecimal.valueOf(100))
                .divide(monthlyBudget, 2, RoundingMode.HALF_UP);

        LocalDateTime monthStart = firstDay.atStartOfDay();

        int seuil = budget.getSeuilNotification();
        if (percentage.compareTo(BigDecimal.valueOf(seuil)) >= 0) {
            boolean alreadyNotified = notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(
                    userId, NotificationType.BUDGET_THRESHOLD, budget.getId(), monthStart);
            if (!alreadyNotified) {
                String categoryName = budget.getCategory().getNom();
                String title = "Budget " + categoryName + " : " + percentage.intValue() + "%";
                String body = "Vous avez atteint " + percentage.intValue() + "% du budget " + categoryName;
                notificationService.createNotification(userId, NotificationType.BUDGET_THRESHOLD, title, body, EntityType.BUDGET, budget.getId());
                log.info("Notification BUDGET_THRESHOLD envoyée: category={}, percentage={}%, budgetId={}", categoryName, percentage, budget.getId());
            }
        }

        if (percentage.compareTo(BigDecimal.valueOf(100)) >= 0) {
            boolean alreadyNotified = notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(
                    userId, NotificationType.BUDGET_EXCEEDED, budget.getId(), monthStart);
            if (!alreadyNotified) {
                String categoryName = budget.getCategory().getNom();
                String title = "Budget " + categoryName + " dépassé !";
                String body = "Vous avez dépassé le budget " + categoryName + " (" + percentage.intValue() + "%)";
                notificationService.createNotification(userId, NotificationType.BUDGET_EXCEEDED, title, body, EntityType.BUDGET, budget.getId());
                log.info("Notification BUDGET_EXCEEDED envoyée: category={}, percentage={}%, budgetId={}", categoryName, percentage, budget.getId());
            }
        }
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
                CategoryResponse.from(budget.getCategory()),
                null,
                budget.getUpdatedAt()
        );
    }

    private BudgetResponse toResponse(Budget budget, BigDecimal spent) {
        return new BudgetResponse(
                budget.getId(), budget.getMontant(), budget.getCurrency().name(),
                budget.getFrequence().name(), budget.getSeuilNotification(),
                budget.getActif(), CategoryResponse.from(budget.getCategory()),
                spent, budget.getUpdatedAt());
    }

    private Map<UUID, BigDecimal> getSpentByCategory(List<Budget> budgets, UUID userId,
            LocalDate firstDay, LocalDate lastDay) {
        List<UUID> categoryIds = budgets.stream()
                .map(b -> b.getCategory().getId())
                .toList();
        if (categoryIds.isEmpty()) return Map.of();
        Currency primaryCurrency = getPrimaryCurrency(userId);
        List<Object[]> results = transactionRepository
                .sumDepenseByUserIdAndCategoryIdsAndDateBetween(userId, categoryIds, firstDay, lastDay);
        Map<UUID, BigDecimal> map = new HashMap<>();
        for (Object[] row : results) {
            UUID catId = (UUID) row[0];
            BigDecimal montant = (BigDecimal) row[1];
            String currencyCode = (String) row[2];
            Currency rowCurrency = Currency.valueOf(currencyCode);
            BigDecimal montantConverti = montant;
            if (rowCurrency != primaryCurrency) {
                Optional<BigDecimal> rate = exchangeRateService.getRate(userId, rowCurrency, primaryCurrency);
                if (rate.isPresent()) {
                    montantConverti = montant.multiply(rate.get()).setScale(2, RoundingMode.HALF_UP);
                } else {
                    log.warn("Taux de change manquant pour {} → {} (userId={}), montant utilisé sans conversion", rowCurrency, primaryCurrency, userId);
                }
            }
            map.merge(catId, montantConverti, BigDecimal::add);
        }
        return map;
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
                CategoryResponse.from(budget.getCategory()),
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


    private Currency getPrimaryCurrency(UUID userId) {
        var preference = preferenceService.getOrCreatePreference(userId);
        List<Currency> currencies = preference.getCurrencies();
        return (currencies != null && !currencies.isEmpty()) ? currencies.get(0) : Currency.EUR;
    }

    private List<BudgetSnapshot> createSnapshotsLazily(String month, YearMonth targetMonth, UUID userId, Currency primaryCurrency) {
        List<Budget> budgets = budgetRepository.findByUserId(userId);
        LocalDate firstDay = targetMonth.atDay(1);
        LocalDate lastDay = targetMonth.atEndOfMonth();
        List<BudgetSnapshot> unsaved = new ArrayList<>();

        Map<UUID, BigDecimal> spentByCategory = getSpentByCategory(budgets, userId, firstDay, lastDay);
        var userRef = userRepository.getReferenceById(userId);

        for (Budget budget : budgets) {
            BigDecimal normalised = normalizeMontantMensuel(budget);
            BigDecimal spent = spentByCategory.getOrDefault(budget.getCategory().getId(), BigDecimal.ZERO);

            BigDecimal tauxChange = null;
            if (budget.getCurrency() != primaryCurrency) {
                tauxChange = exchangeRateService.getRate(userId, budget.getCurrency(), primaryCurrency).orElse(null);
            }

            BudgetSnapshot snapshot = BudgetSnapshot.builder()
                    .montantBudget(normalised)
                    .currency(budget.getCurrency())
                    .tauxChange(tauxChange)
                    .montantDepense(spent)
                    .mois(month)
                    .category(budget.getCategory())
                    .user(userRef)
                    .build();
            unsaved.add(snapshot);
        }
        List<BudgetSnapshot> snapshots = budgetSnapshotRepository.saveAll(unsaved);

        log.info("Snapshots créés: mois={}, count={}, userId={}", month, snapshots.size(), userId);
        return snapshots;
    }
}
