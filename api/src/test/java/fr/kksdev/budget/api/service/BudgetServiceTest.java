package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.BudgetRequest;
import fr.kksdev.budget.api.dto.response.BudgetHistoryResponse;
import fr.kksdev.budget.api.dto.response.BudgetOverviewResponse;
import fr.kksdev.budget.api.dto.response.BudgetResponse;
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
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.model.UserPreference;
import fr.kksdev.budget.api.repository.BudgetRepository;
import fr.kksdev.budget.api.repository.BudgetSnapshotRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.NotificationRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import java.util.Collections;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.assertj.core.data.Percentage;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BudgetServiceTest {

    @Mock
    private BudgetRepository budgetRepository;

    @Mock
    private BudgetSnapshotRepository budgetSnapshotRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PreferenceService preferenceService;

    @Mock
    private ExchangeRateService exchangeRateService;

    @Mock
    private NotificationService notificationService;

    @Mock
    private NotificationRepository notificationRepository;

    @InjectMocks
    private BudgetService budgetService;

    private final UUID userId = UUID.randomUUID();
    private final UUID budgetId = UUID.randomUUID();
    private final UUID categoryId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        lenient().when(preferenceService.isFeatureEnabled(userId, Feature.BUDGETS)).thenReturn(true);
        var prefs = UserPreference.builder()
                .currencies(List.of(Currency.EUR))
                .build();
        lenient().when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private User buildUser(UUID id) {
        return User.builder()
                .id(id)
                .email("test@mail.com")
                .build();
    }

    private Category buildCategory(UUID id) {
        var user = buildUser(userId);
        return Category.builder()
                .id(id)
                .nom("Alimentation")
                .icone("🍔")
                .couleur("#ff5733")
                .isSystem(false)
                .user(user)
                .build();
    }

    private Budget buildBudget(UUID id, Category cat) {
        return Budget.builder()
                .id(id)
                .montant(new BigDecimal("500.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(true)
                .category(cat)
                .user(buildUser(userId))
                .build();
    }

    private List<Object[]> batchResult(Object[]... rows) {
        List<Object[]> list = new ArrayList<>();
        for (Object[] row : rows) {
            list.add(row);
        }
        return list;
    }

    // -------------------------------------------------------------------------
    // US1 — CRUD tests (T017)
    // -------------------------------------------------------------------------

    @Test
    void should_create_budget_when_valid_request() {
        var category = buildCategory(categoryId);
        var request = new BudgetRequest(categoryId, new BigDecimal("500.00"), Frequency.MENSUEL, Currency.EUR, 80, null);
        var saved = buildBudget(budgetId, category);

        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(budgetRepository.existsByCategoryIdAndUserId(categoryId, userId)).thenReturn(false);
        when(userRepository.getReferenceById(userId)).thenReturn(buildUser(userId));
        when(budgetRepository.save(any(Budget.class))).thenReturn(saved);

        BudgetResponse response = budgetService.create(request, userId);

        assertThat(response.id()).isEqualTo(budgetId);
        assertThat(response.montant()).isEqualByComparingTo("500.00");
        assertThat(response.currency()).isEqualTo("EUR");
        assertThat(response.frequence()).isEqualTo("MENSUEL");
        assertThat(response.seuilNotification()).isEqualTo(80);
        assertThat(response.actif()).isTrue();
        verify(budgetRepository).save(any(Budget.class));
    }

    @Test
    void should_throw_conflict_when_duplicate_category() {
        var category = buildCategory(categoryId);
        var request = new BudgetRequest(categoryId, new BigDecimal("500.00"), Frequency.MENSUEL, null, null, null);

        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(budgetRepository.existsByCategoryIdAndUserId(categoryId, userId)).thenReturn(true);

        assertThatThrownBy(() -> budgetService.create(request, userId))
                .isInstanceOf(ConflictException.class)
                .hasMessage("A budget already exists for this category");

        verify(budgetRepository, never()).save(any());
    }

    @Test
    void should_return_all_active_budgets_when_includeInactive_false() {
        var category = buildCategory(categoryId);
        var budget = buildBudget(budgetId, category);

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(budget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(List.of());

        List<BudgetResponse> result = budgetService.getAll(userId, false);

        assertThat(result).hasSize(1);
        verify(budgetRepository).findByUserIdAndActifTrue(userId);
        verify(budgetRepository, never()).findByUserId(any());
    }

    @Test
    void should_return_all_budgets_when_includeInactive_true() {
        var category = buildCategory(categoryId);
        var activeBudget = buildBudget(budgetId, category);
        var inactiveBudget = Budget.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("200.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(false)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByUserId(userId)).thenReturn(List.of(activeBudget, inactiveBudget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(List.of());

        List<BudgetResponse> result = budgetService.getAll(userId, true);

        assertThat(result).hasSize(2);
        verify(budgetRepository).findByUserId(userId);
        verify(budgetRepository, never()).findByUserIdAndActifTrue(any());
    }

    @Test
    void should_update_budget_when_valid() {
        var category = buildCategory(categoryId);
        var existing = buildBudget(budgetId, category);
        var request = new BudgetRequest(categoryId, new BigDecimal("750.00"), Frequency.HEBDOMADAIRE, Currency.EUR, 90, true);

        when(budgetRepository.findByIdAndUserId(budgetId, userId)).thenReturn(Optional.of(existing));
        when(budgetRepository.save(any(Budget.class))).thenReturn(existing);

        BudgetResponse response = budgetService.update(budgetId, request, userId);

        assertThat(response).isNotNull();
        verify(budgetRepository).save(existing);
    }

    @Test
    void should_throwConflict_when_updatingCategoryToExistingBudget() {
        var category = buildCategory(categoryId);
        var existing = buildBudget(budgetId, category);
        var otherCategoryId = UUID.randomUUID();
        var request = new BudgetRequest(otherCategoryId, new BigDecimal("500.00"), Frequency.MENSUEL, Currency.EUR, 80, true);

        when(budgetRepository.findByIdAndUserId(budgetId, userId)).thenReturn(Optional.of(existing));
        when(categoryRepository.findById(otherCategoryId)).thenReturn(Optional.of(buildCategory(otherCategoryId)));
        when(budgetRepository.existsByCategoryIdAndUserId(otherCategoryId, userId)).thenReturn(true);

        assertThatThrownBy(() -> budgetService.update(budgetId, request, userId))
                .isInstanceOf(ConflictException.class)
                .hasMessage("A budget already exists for this category");

        verify(budgetRepository, never()).save(any());
    }

    @Test
    void should_hard_delete_budget_when_exists() {
        var category = buildCategory(categoryId);
        var budget = buildBudget(budgetId, category);

        when(budgetRepository.findByIdAndUserId(budgetId, userId)).thenReturn(Optional.of(budget));

        budgetService.delete(budgetId, userId);

        verify(budgetRepository).delete(budget);
    }

    @Test
    void should_preserve_snapshots_when_budget_deleted() {
        var category = buildCategory(categoryId);
        var budget = buildBudget(budgetId, category);

        when(budgetRepository.findByIdAndUserId(budgetId, userId)).thenReturn(Optional.of(budget));

        budgetService.delete(budgetId, userId);

        verify(budgetSnapshotRepository, never()).delete(any());
        verify(budgetSnapshotRepository, never()).deleteAll(any());
    }

    @Test
    void should_throw_not_found_when_budget_missing() {
        when(budgetRepository.findByIdAndUserId(budgetId, userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> budgetService.delete(budgetId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Budget not found");
    }

    @Test
    void should_throw_feature_disabled_when_budgets_off() {
        when(preferenceService.isFeatureEnabled(userId, Feature.BUDGETS)).thenReturn(false);
        var request = new BudgetRequest(categoryId, new BigDecimal("500.00"), Frequency.MENSUEL, null, null, null);

        assertThatThrownBy(() -> budgetService.create(request, userId))
                .isInstanceOf(FeatureDisabledException.class)
                .hasMessage("Feature BUDGETS is disabled");
    }

    @Test
    void should_calculate_spent_for_current_month() {
        var category = buildCategory(categoryId);
        var budget = buildBudget(budgetId, category);
        var expectedSpent = new BigDecimal("123.45");

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(budget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(batchResult(new Object[]{categoryId, expectedSpent, "EUR"}));

        List<BudgetResponse> result = budgetService.getAll(userId, false);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().spent()).isEqualByComparingTo("123.45");
        verify(transactionRepository).sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class));
        verify(transactionRepository, never()).sumDepenseByUserIdAndCategoryIdAndDateBetween(
                any(), any(), any(), any());
    }

    @Test
    void should_convertTransactionAmounts_when_budgetAndAccountCurrenciesDiffer() {
        // Budget EUR 800€ MENSUEL, catégorie "Maison"
        // Transactions : 650€ EUR + 20 000 XOF
        // Taux XOF→EUR direct : 0.001524 (≈ 1/655.957)
        // Spent attendu : 650 + 20000 * 0.001524 = 650 + 30.48 = 680.48 EUR
        var category = buildCategory(categoryId);
        var budget = Budget.builder()
                .id(budgetId)
                .montant(new BigDecimal("800.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(true)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(budget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(batchResult(
                        new Object[]{categoryId, new BigDecimal("650.00"), "EUR"},
                        new Object[]{categoryId, new BigDecimal("20000.00"), "XOF"}
                ));
        when(exchangeRateService.getRate(userId, Currency.XOF, Currency.EUR))
                .thenReturn(Optional.of(new BigDecimal("0.001524")));

        List<BudgetResponse> result = budgetService.getAll(userId, false);

        assertThat(result).hasSize(1);
        // 650.00 + 20000 * 0.001524 = 650.00 + 30.48 = 680.48
        assertThat(result.getFirst().spent())
                .isCloseTo(new BigDecimal("680.48"), org.assertj.core.data.Offset.offset(new BigDecimal("0.01")));
    }

    // -------------------------------------------------------------------------
    // US2 — Overview tests (T023)
    // -------------------------------------------------------------------------

    @Test
    void should_normalize_weekly_budget_multiply_4_33() {
        var category = buildCategory(categoryId);
        var weeklyBudget = Budget.builder()
                .id(budgetId)
                .montant(new BigDecimal("100.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.HEBDOMADAIRE)
                .seuilNotification(80)
                .actif(true)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(weeklyBudget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(List.of());

        BudgetOverviewResponse response = budgetService.getOverview(userId);

        // 100 * 4.33 = 433.00
        assertThat(response.totalBudget()).isEqualByComparingTo("433.00");
        assertThat(response.items()).hasSize(1);
        assertThat(response.items().getFirst().montantBudgetNormalise()).isEqualByComparingTo("433.00");
    }

    @Test
    void should_normalize_annual_budget_divide_12() {
        var category = buildCategory(categoryId);
        var annualBudget = Budget.builder()
                .id(budgetId)
                .montant(new BigDecimal("1200.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.ANNUEL)
                .seuilNotification(80)
                .actif(true)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(annualBudget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(List.of());

        BudgetOverviewResponse response = budgetService.getOverview(userId);

        // 1200 / 12 = 100.00
        assertThat(response.totalBudget()).isEqualByComparingTo("100.00");
        assertThat(response.items().getFirst().montantBudgetNormalise()).isEqualByComparingTo("100.00");
    }

    @Test
    void should_calculate_total_budget_and_spent() {
        var catId1 = UUID.randomUUID();
        var catId2 = UUID.randomUUID();
        var cat1 = buildCategory(catId1);
        var cat2 = buildCategory(catId2);

        var budget1 = Budget.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("400.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(true)
                .category(cat1)
                .user(buildUser(userId))
                .build();
        var budget2 = Budget.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("600.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(true)
                .category(cat2)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(budget1, budget2));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(batchResult(
                        new Object[]{catId1, new BigDecimal("100.00"), "EUR"},
                        new Object[]{catId2, new BigDecimal("200.00"), "EUR"}
                ));

        BudgetOverviewResponse response = budgetService.getOverview(userId);

        assertThat(response.totalBudget()).isEqualByComparingTo("1000.00");
        assertThat(response.totalSpent()).isEqualByComparingTo("300.00");
        assertThat(response.items()).hasSize(2);
    }

    @Test
    void should_convert_foreign_currency_budget() {
        var category = buildCategory(categoryId);
        var usdBudget = Budget.builder()
                .id(budgetId)
                .montant(new BigDecimal("100.00"))
                .currency(Currency.USD)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(true)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(usdBudget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(batchResult(new Object[]{categoryId, new BigDecimal("50.00"), "USD"}));
        when(exchangeRateService.getRate(userId, Currency.USD, Currency.EUR))
                .thenReturn(Optional.of(new BigDecimal("0.920000")));

        BudgetOverviewResponse response = budgetService.getOverview(userId);

        // 100 USD * 0.92 = 92.00 EUR
        assertThat(response.totalBudget()).isEqualByComparingTo("92.00");
        assertThat(response.items().getFirst().montantBudgetNormalise()).isEqualByComparingTo("92.00");
        // 50 USD * 0.92 = 46.00 EUR
        assertThat(response.totalSpent()).isEqualByComparingTo("46.00");
        assertThat(response.items().getFirst().montantDepense()).isEqualByComparingTo("46.00");
    }

    @Test
    void should_fallback_to_unconverted_amount_when_exchange_rate_missing() {
        var category = buildCategory(categoryId);
        var usdBudget = Budget.builder()
                .id(budgetId)
                .montant(new BigDecimal("100.00"))
                .currency(Currency.USD)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(true)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(usdBudget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(List.of());
        when(exchangeRateService.getRate(userId, Currency.USD, Currency.EUR))
                .thenReturn(Optional.empty());

        BudgetOverviewResponse response = budgetService.getOverview(userId);

        // Fallback: montant non converti (100 USD utilisé tel quel)
        assertThat(response.totalBudget()).isEqualByComparingTo("100.00");
        assertThat(response.items()).hasSize(1);
        assertThat(response.items().getFirst().montantBudgetNormalise()).isEqualByComparingTo("100.00");
    }

    @Test
    void should_use_inverse_rate_when_direct_rate_missing() {
        var category = buildCategory(categoryId);
        var xofBudget = Budget.builder()
                .id(budgetId)
                .montant(new BigDecimal("65000.00"))
                .currency(Currency.XOF)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(true)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(xofBudget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(batchResult(new Object[]{categoryId, new BigDecimal("32500.00"), "XOF"}));
        // getRate gère le lookup inverse en interne — retourne 1/655.957
        when(exchangeRateService.getRate(userId, Currency.XOF, Currency.EUR))
                .thenReturn(Optional.of(new BigDecimal("0.001524")));

        BudgetOverviewResponse response = budgetService.getOverview(userId);

        // 65000 * (1 / 655.957) ≈ 99.09 EUR
        assertThat(response.totalBudget()).isCloseTo(new BigDecimal("99.09"), Percentage.withPercentage(1));
        // 32500 * (1 / 655.957) ≈ 49.54 EUR
        assertThat(response.totalSpent()).isCloseTo(new BigDecimal("49.54"), Percentage.withPercentage(1));
        assertThat(response.items()).hasSize(1);
    }

    @Test
    void should_return_zero_totals_when_no_active_budgets() {
        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of());

        BudgetOverviewResponse response = budgetService.getOverview(userId);

        assertThat(response.totalBudget()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(response.totalSpent()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(response.percentage()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(response.items()).isEmpty();
    }

    @Test
    void should_return_zero_percentage_when_total_budget_is_zero() {
        var category = buildCategory(categoryId);
        // Budget with zero amount (edge case where normalised = 0)
        var zeroBudget = Budget.builder()
                .id(budgetId)
                .montant(new BigDecimal("0.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(true)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(zeroBudget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(batchResult(new Object[]{categoryId, new BigDecimal("50.00"), "EUR"}));

        BudgetOverviewResponse response = budgetService.getOverview(userId);

        assertThat(response.percentage()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(response.items().getFirst().percentage()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    void should_sum_expenses_regardless_of_budget_frequency() {
        var category = buildCategory(categoryId);
        var weeklyBudget = Budget.builder()
                .id(budgetId)
                .montant(new BigDecimal("50.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.HEBDOMADAIRE)
                .seuilNotification(80)
                .actif(true)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(weeklyBudget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(batchResult(new Object[]{categoryId, new BigDecimal("87.50"), "EUR"}));

        BudgetOverviewResponse response = budgetService.getOverview(userId);

        // Spent comes from transactionRepository, not derived from frequency normalization
        assertThat(response.totalSpent()).isEqualByComparingTo("87.50");
        assertThat(response.items().getFirst().montantDepense()).isEqualByComparingTo("87.50");
    }

    @Test
    void should_batchLoadSpent_when_getAllWithMultipleBudgets() {
        var catId1 = UUID.randomUUID();
        var catId2 = UUID.randomUUID();
        var cat1 = buildCategory(catId1);
        var cat2 = buildCategory(catId2);

        var budget1 = Budget.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("300.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(true)
                .category(cat1)
                .user(buildUser(userId))
                .build();
        var budget2 = Budget.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("500.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(true)
                .category(cat2)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(budget1, budget2));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(batchResult(
                        new Object[]{catId1, new BigDecimal("75.00"), "EUR"},
                        new Object[]{catId2, new BigDecimal("250.00"), "EUR"}
                ));

        List<BudgetResponse> result = budgetService.getAll(userId, false);

        assertThat(result).hasSize(2);
        var response1 = result.stream().filter(r -> r.category().id().equals(catId1)).findFirst().orElseThrow();
        var response2 = result.stream().filter(r -> r.category().id().equals(catId2)).findFirst().orElseThrow();
        assertThat(response1.spent()).isEqualByComparingTo("75.00");
        assertThat(response2.spent()).isEqualByComparingTo("250.00");

        // Vérifier que la méthode batch a été appelée une seule fois
        verify(transactionRepository).sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class));
        // Vérifier que la méthode unitaire n'a jamais été appelée
        verify(transactionRepository, never()).sumDepenseByUserIdAndCategoryIdAndDateBetween(
                any(), any(), any(), any());
    }

    @Test
    void should_returnPrimaryCurrencyInOverviewItems_when_budgetCurrencyDiffers() {
        // Budget en EUR, devise principale XOF, taux EUR→XOF configuré
        var category = buildCategory(categoryId);
        var eurBudget = Budget.builder()
                .id(budgetId)
                .montant(new BigDecimal("100.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(true)
                .category(category)
                .user(buildUser(userId))
                .build();

        // Devise principale = XOF
        var prefs = UserPreference.builder()
                .currencies(List.of(Currency.XOF))
                .build();
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);

        when(budgetRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(eurBudget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), any(List.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(List.of());
        when(exchangeRateService.getRate(userId, Currency.EUR, Currency.XOF))
                .thenReturn(Optional.of(new BigDecimal("655.957000")));

        BudgetOverviewResponse response = budgetService.getOverview(userId);

        assertThat(response.items()).hasSize(1);
        // La devise de l'item doit être la devise principale (XOF), pas celle du budget (EUR)
        assertThat(response.items().getFirst().currency()).isEqualTo("XOF");
        // Le montant converti : 100 EUR * 655.957 = 65595.70 XOF
        assertThat(response.items().getFirst().montantBudgetNormalise()).isEqualByComparingTo("65595.70");
    }

    // -------------------------------------------------------------------------
    // US3 — History tests (T029)
    // -------------------------------------------------------------------------

    @Test
    void should_create_snapshots_lazily_when_none_exist() {
        var category = buildCategory(categoryId);
        var budget = buildBudget(budgetId, category);
        var pastMonth = YearMonth.now().minusMonths(1).toString();

        when(budgetSnapshotRepository.findByUserIdAndMois(userId, pastMonth)).thenReturn(List.of());
        when(budgetRepository.findByUserId(userId)).thenReturn(List.of(budget));
        List<Object[]> batchResult = Collections.singletonList(new Object[]{categoryId, new BigDecimal("150.00"), "EUR"});
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdsAndDateBetween(
                eq(userId), eq(List.of(categoryId)), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(batchResult);

        var snapshot = BudgetSnapshot.builder()
                .id(UUID.randomUUID())
                .montantBudget(new BigDecimal("500.00"))
                .currency(Currency.EUR)
                .tauxChange(null)
                .montantDepense(new BigDecimal("150.00"))
                .mois(pastMonth)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(userRepository.getReferenceById(userId)).thenReturn(buildUser(userId));
        when(budgetSnapshotRepository.saveAll(anyList())).thenReturn(List.of(snapshot));

        BudgetHistoryResponse response = budgetService.getHistory(pastMonth, userId);

        assertThat(response.items()).hasSize(1);
        verify(budgetSnapshotRepository).saveAll(anyList());
    }

    @Test
    void should_return_existing_snapshots_when_available() {
        var category = buildCategory(categoryId);
        var pastMonth = YearMonth.now().minusMonths(1).toString();

        var existingSnapshot = BudgetSnapshot.builder()
                .id(UUID.randomUUID())
                .montantBudget(new BigDecimal("500.00"))
                .currency(Currency.EUR)
                .tauxChange(null)
                .montantDepense(new BigDecimal("200.00"))
                .mois(pastMonth)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetSnapshotRepository.findByUserIdAndMois(userId, pastMonth))
                .thenReturn(List.of(existingSnapshot));

        BudgetHistoryResponse response = budgetService.getHistory(pastMonth, userId);

        assertThat(response.items()).hasSize(1);
        assertThat(response.totalSpent()).isEqualByComparingTo("200.00");
        verify(budgetSnapshotRepository, never()).save(any());
        verify(budgetRepository, never()).findByUserId(any());
    }

    @Test
    void should_return_empty_when_no_budgets_for_month() {
        var pastMonth = YearMonth.now().minusMonths(1).toString();

        when(budgetSnapshotRepository.findByUserIdAndMois(userId, pastMonth)).thenReturn(List.of());
        when(budgetRepository.findByUserId(userId)).thenReturn(List.of());

        BudgetHistoryResponse response = budgetService.getHistory(pastMonth, userId);

        assertThat(response.items()).isEmpty();
        assertThat(response.totalBudget()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(response.totalSpent()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    void should_reject_current_month() {
        var currentMonth = YearMonth.now().toString();

        assertThatThrownBy(() -> budgetService.getHistory(currentMonth, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Only past months are allowed");
    }

    @Test
    void should_reject_future_month() {
        var futureMonth = YearMonth.now().plusMonths(3).toString();

        assertThatThrownBy(() -> budgetService.getHistory(futureMonth, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Only past months are allowed");
    }

    @Test
    void should_preserve_exchange_rate_in_snapshot() {
        var category = buildCategory(categoryId);
        var pastMonth = YearMonth.now().minusMonths(1).toString();
        var tauxChange = new BigDecimal("0.920000");

        var snapshotWithRate = BudgetSnapshot.builder()
                .id(UUID.randomUUID())
                .montantBudget(new BigDecimal("100.00"))
                .currency(Currency.USD)
                .tauxChange(tauxChange)
                .montantDepense(new BigDecimal("50.00"))
                .mois(pastMonth)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetSnapshotRepository.findByUserIdAndMois(userId, pastMonth))
                .thenReturn(List.of(snapshotWithRate));

        BudgetHistoryResponse response = budgetService.getHistory(pastMonth, userId);

        assertThat(response.items()).hasSize(1);
        var item = response.items().getFirst();
        assertThat(item.tauxChange()).isEqualByComparingTo("0.920000");
        // La devise retournée est la devise principale (EUR), pas celle du snapshot (USD)
        assertThat(item.currency()).isEqualTo("EUR");
        // Budget converted: 100 * 0.92 = 92.00
        assertThat(response.totalBudget()).isEqualByComparingTo("92.00");
        // Spent stored in primary currency (no re-conversion by tauxChange)
        assertThat(response.totalSpent()).isEqualByComparingTo("50.00");
        assertThat(item.montantDepense()).isEqualByComparingTo("50.00");
    }

    // -------------------------------------------------------------------------
    // US4 — Threshold notification tests (T040)
    // -------------------------------------------------------------------------

    @Test
    void should_send_threshold_notification_when_spending_reaches_seuil() {
        // Budget 500€ mensuel, seuil 80%, dépenses 400€ → 80% → notification BUDGET_THRESHOLD
        var category = buildCategory(categoryId);
        var budget = buildBudget(budgetId, category); // seuil=80, montant=500€, MENSUEL

        when(budgetRepository.findByCategoryIdAndUserId(categoryId, userId)).thenReturn(Optional.of(budget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdAndDateBetween(
                eq(userId), eq(categoryId), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(new BigDecimal("400.00"));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(
                eq(userId), eq(NotificationType.BUDGET_THRESHOLD), eq(budgetId), any(LocalDateTime.class)))
                .thenReturn(false);

        budgetService.checkThresholdsForCategory(userId, categoryId);

        verify(notificationService).createNotification(
                eq(userId), eq(NotificationType.BUDGET_THRESHOLD),
                any(String.class), any(String.class),
                eq(EntityType.BUDGET), eq(budgetId));
        verify(notificationService, never()).createNotification(
                eq(userId), eq(NotificationType.BUDGET_EXCEEDED),
                any(), any(), any(), any());
    }

    @Test
    void should_send_exceeded_notification_when_spending_reaches_100_percent() {
        // Budget 500€ mensuel, dépenses 500€ → 100% → notification BUDGET_EXCEEDED (et aussi BUDGET_THRESHOLD)
        var category = buildCategory(categoryId);
        var budget = buildBudget(budgetId, category); // seuil=80, montant=500€

        when(budgetRepository.findByCategoryIdAndUserId(categoryId, userId)).thenReturn(Optional.of(budget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdAndDateBetween(
                eq(userId), eq(categoryId), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(new BigDecimal("500.00"));
        // BUDGET_THRESHOLD pas encore envoyé
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(
                eq(userId), eq(NotificationType.BUDGET_THRESHOLD), eq(budgetId), any(LocalDateTime.class)))
                .thenReturn(false);
        // BUDGET_EXCEEDED pas encore envoyé
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(
                eq(userId), eq(NotificationType.BUDGET_EXCEEDED), eq(budgetId), any(LocalDateTime.class)))
                .thenReturn(false);

        budgetService.checkThresholdsForCategory(userId, categoryId);

        verify(notificationService).createNotification(
                eq(userId), eq(NotificationType.BUDGET_THRESHOLD),
                any(String.class), any(String.class),
                eq(EntityType.BUDGET), eq(budgetId));
        verify(notificationService).createNotification(
                eq(userId), eq(NotificationType.BUDGET_EXCEEDED),
                any(String.class), any(String.class),
                eq(EntityType.BUDGET), eq(budgetId));
    }

    @Test
    void should_not_duplicate_threshold_notification_in_same_month() {
        // Notification BUDGET_THRESHOLD déjà envoyée ce mois → aucune nouvelle notification
        var category = buildCategory(categoryId);
        var budget = buildBudget(budgetId, category); // seuil=80, montant=500€

        when(budgetRepository.findByCategoryIdAndUserId(categoryId, userId)).thenReturn(Optional.of(budget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdAndDateBetween(
                eq(userId), eq(categoryId), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(new BigDecimal("400.00")); // 80%
        // Notification déjà envoyée ce mois
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(
                eq(userId), eq(NotificationType.BUDGET_THRESHOLD), eq(budgetId), any(LocalDateTime.class)))
                .thenReturn(true);

        budgetService.checkThresholdsForCategory(userId, categoryId);

        verify(notificationService, never()).createNotification(
                any(), any(), any(), any(), any(), any());
    }

    @Test
    void should_send_exceeded_notification_even_when_threshold_already_notified() {
        // THRESHOLD déjà notifié, dépenses à 100% → EXCEEDED envoyé, THRESHOLD PAS re-envoyé
        var category = buildCategory(categoryId);
        var budget = buildBudget(budgetId, category); // seuil=80, montant=500€

        when(budgetRepository.findByCategoryIdAndUserId(categoryId, userId)).thenReturn(Optional.of(budget));
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdAndDateBetween(
                eq(userId), eq(categoryId), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(new BigDecimal("500.00")); // 100%
        // THRESHOLD déjà envoyé ce mois
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(
                eq(userId), eq(NotificationType.BUDGET_THRESHOLD), eq(budgetId), any(LocalDateTime.class)))
                .thenReturn(true);
        // EXCEEDED pas encore envoyé
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(
                eq(userId), eq(NotificationType.BUDGET_EXCEEDED), eq(budgetId), any(LocalDateTime.class)))
                .thenReturn(false);

        budgetService.checkThresholdsForCategory(userId, categoryId);

        // THRESHOLD ne doit PAS être re-envoyé (déjà notifié)
        verify(notificationService, never()).createNotification(
                eq(userId), eq(NotificationType.BUDGET_THRESHOLD),
                any(String.class), any(String.class),
                eq(EntityType.BUDGET), eq(budgetId));
        // EXCEEDED doit être envoyé
        verify(notificationService).createNotification(
                eq(userId), eq(NotificationType.BUDGET_EXCEEDED),
                any(String.class), any(String.class),
                eq(EntityType.BUDGET), eq(budgetId));
    }

    @Test
    void should_not_check_when_budget_is_inactive() {
        // Budget inactif → aucune notification
        var category = buildCategory(categoryId);
        var inactiveBudget = Budget.builder()
                .id(budgetId)
                .montant(new BigDecimal("500.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(80)
                .actif(false)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByCategoryIdAndUserId(categoryId, userId)).thenReturn(Optional.of(inactiveBudget));

        budgetService.checkThresholdsForCategory(userId, categoryId);

        verify(transactionRepository, never()).sumDepenseByUserIdAndCategoryIdAndDateBetween(
                any(), any(), any(), any());
        verify(notificationService, never()).createNotification(
                any(), any(), any(), any(), any(), any());
    }

    @Test
    void should_not_check_when_no_budget_for_category() {
        // Pas de budget pour la catégorie → aucune notification
        when(budgetRepository.findByCategoryIdAndUserId(categoryId, userId)).thenReturn(Optional.empty());

        budgetService.checkThresholdsForCategory(userId, categoryId);

        verify(transactionRepository, never()).sumDepenseByUserIdAndCategoryIdAndDateBetween(
                any(), any(), any(), any());
        verify(notificationService, never()).createNotification(
                any(), any(), any(), any(), any(), any());
    }

    @Test
    void should_respect_custom_seuil_when_spending_exceeds_it() {
        // Budget avec seuil 60%, dépenses à 65% → notification BUDGET_THRESHOLD
        var category = buildCategory(categoryId);
        var budgetWith60Seuil = Budget.builder()
                .id(budgetId)
                .montant(new BigDecimal("500.00"))
                .currency(Currency.EUR)
                .frequence(Frequency.MENSUEL)
                .seuilNotification(60)
                .actif(true)
                .category(category)
                .user(buildUser(userId))
                .build();

        when(budgetRepository.findByCategoryIdAndUserId(categoryId, userId)).thenReturn(Optional.of(budgetWith60Seuil));
        // 325€ / 500€ = 65% → dépasse le seuil de 60%
        when(transactionRepository.sumDepenseByUserIdAndCategoryIdAndDateBetween(
                eq(userId), eq(categoryId), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(new BigDecimal("325.00"));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(
                eq(userId), eq(NotificationType.BUDGET_THRESHOLD), eq(budgetId), any(LocalDateTime.class)))
                .thenReturn(false);

        budgetService.checkThresholdsForCategory(userId, categoryId);

        verify(notificationService).createNotification(
                eq(userId), eq(NotificationType.BUDGET_THRESHOLD),
                any(String.class), any(String.class),
                eq(EntityType.BUDGET), eq(budgetId));
        verify(notificationService, never()).createNotification(
                eq(userId), eq(NotificationType.BUDGET_EXCEEDED),
                any(), any(), any(), any());
    }
}
