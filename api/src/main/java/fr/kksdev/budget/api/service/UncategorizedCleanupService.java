package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CategoryApplyRequest;
import fr.kksdev.budget.api.dto.response.CategoryApplyResponse;
import fr.kksdev.budget.api.dto.response.CategoryProposalsResponse;
import fr.kksdev.budget.api.dto.response.CategoryProposalsResponse.Group;
import fr.kksdev.budget.api.dto.response.CategoryProposalsResponse.Suggestion;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.dto.response.CleanupTransactionResponse;
import fr.kksdev.budget.api.enums.CleanupSuggestionSource;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.CategoryRule;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.CategoryRuleRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.util.MerchantKey;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Proposes a category for the transactions that have none, and applies the one the user
 * chooses (KKS-387). Reading changes nothing.
 *
 * <p>Transactions are grouped by merchant ({@link MerchantKey}) and type, the same grouping as
 * {@link CategorySuggestionService}. The category proposed for a transaction is, in this order:
 * the first rule of the user that matches its label, the majority category of the user's
 * categorized transactions with the same merchant and type at the same amount, then at any amount.
 * A merchant whose transactions get different proposals (several subscriptions under one label,
 * told apart by their amount) is split by amount, each amount being a group of its own.
 * Groups without proposal are listed as well, for the user to choose.
 *
 * <p>Applying a category touches only the user's transactions that still have none, and
 * remembers the choice as an automatic rule for the merchant, as the review of an import does;
 * a rule typed by the user is never modified.
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UncategorizedCleanupService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final CategoryRuleRepository categoryRuleRepository;
    private final CategoryRuleService categoryRuleService;

    private record MerchantKeyAndType(String merchantKey, TransactionType type) {}

    private record Proposal(Category category, CleanupSuggestionSource source) {}

    public CategoryProposalsResponse findProposals(UUID userId) {
        List<Transaction> uncategorized = transactionRepository.findUncategorizedByUserId(userId, TransactionType.AJUSTEMENT);
        if (uncategorized.isEmpty()) {
            return new CategoryProposalsResponse(List.of());
        }
        CategorySuggestionService.MerchantHistory history = new CategorySuggestionService.MerchantHistory(
                transactionRepository.findByUserIdAndCategoryIsNotNullAndIsRecurringFalse(userId));
        List<CategoryRule> rules = categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(userId);

        Map<MerchantKeyAndType, List<Transaction>> byMerchant = uncategorized.stream()
                .collect(Collectors.groupingBy(
                        t -> new MerchantKeyAndType(MerchantKey.of(t.getLibelle()), t.getType()),
                        LinkedHashMap::new, Collectors.toList()));
        List<Group> groups = new ArrayList<>();
        byMerchant.forEach((key, transactions) -> groups.addAll(toGroups(key, transactions, history, rules)));
        groups.sort(Comparator.comparing((Group g) -> g.suggestion() == null)
                .thenComparing(Comparator.comparingInt(Group::count).reversed())
                .thenComparing(Group::merchantKey));
        log.info("History cleanup categories read: {} groups for {} transactions, userId={}",
                groups.size(), uncategorized.size(), userId);
        return new CategoryProposalsResponse(groups);
    }

    /**
     * Gives the category to the transactions of the request that have none.
     *
     * @throws EntityNotFoundException when the category or a transaction is not the user's: nothing is changed
     */
    @Transactional
    public CategoryApplyResponse apply(CategoryApplyRequest request, UUID userId) {
        Category category = categoryRepository.findById(request.categoryId())
                .filter(c -> c.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Category not found: id={}, userId={}", request.categoryId(), userId);
                    return new EntityNotFoundException("Category not found");
                });
        Set<UUID> ids = new LinkedHashSet<>(request.transactionIds());
        List<Transaction> found = transactionRepository.findByUserIdAndIdIn(userId, ids);
        if (found.size() != ids.size()) {
            log.error("Transaction to categorize not found: userId={}", userId);
            throw new EntityNotFoundException("Transaction not found");
        }

        List<Transaction> eligible = found.stream()
                .filter(t -> t.getCategory() == null && t.getType() != TransactionType.AJUSTEMENT
                        && !Boolean.TRUE.equals(t.getIsRecurring()))
                .toList();
        eligible.forEach(t -> t.setCategory(category));
        transactionRepository.saveAll(eligible);
        if (request.rememberRule()) {
            rememberRule(eligible, category, userId);
        }
        log.info("Category {} applied to {} transactions, {} skipped, userId={}",
                category.getId(), eligible.size(), found.size() - eligible.size(), userId);
        return new CategoryApplyResponse(eligible.size(), found.size() - eligible.size());
    }

    /** The rule is for one merchant: none is made when the transactions of the request span several. */
    private void rememberRule(List<Transaction> categorized, Category category, UUID userId) {
        Set<String> merchants = categorized.stream()
                .map(t -> MerchantKey.of(t.getLibelle()))
                .collect(Collectors.toSet());
        if (merchants.size() == 1) {
            categoryRuleService.rememberCorrection(merchants.iterator().next(), category, userId);
        }
    }

    private List<Group> toGroups(MerchantKeyAndType key, List<Transaction> transactions,
                                 CategorySuggestionService.MerchantHistory history, List<CategoryRule> rules) {
        Function<Transaction, Optional<Proposal>> proposalOf = t -> propose(key.merchantKey(), t, history, rules);
        long distinct = transactions.stream()
                .map(t -> proposalOf.apply(t).map(p -> p.category().getId()))
                .distinct()
                .count();
        if (distinct <= 1) {
            return List.of(toGroup(key, null, transactions, proposalOf));
        }
        Map<BigDecimal, List<Transaction>> byAmount = transactions.stream()
                .collect(Collectors.groupingBy(t -> t.getMontant().stripTrailingZeros(), LinkedHashMap::new, Collectors.toList()));
        return byAmount.entrySet().stream()
                .map(entry -> toGroup(key, entry.getKey(), entry.getValue(), proposalOf))
                .toList();
    }

    private static Group toGroup(MerchantKeyAndType key, BigDecimal amount, List<Transaction> transactions,
                                 Function<Transaction, Optional<Proposal>> proposalOf) {
        Suggestion suggestion = proposalOf.apply(transactions.getFirst())
                .map(p -> new Suggestion(CategoryResponse.from(p.category()), p.source()))
                .orElse(null);
        BigDecimal total = transactions.stream().map(Transaction::getMontant).reduce(BigDecimal.ZERO, BigDecimal::add);
        return new Group(key.merchantKey(), key.type(), amount, transactions.size(), total, suggestion,
                transactions.stream().map(CleanupTransactionResponse::from).toList());
    }

    private static Optional<Proposal> propose(String merchant, Transaction transaction,
                                              CategorySuggestionService.MerchantHistory history, List<CategoryRule> rules) {
        Optional<Category> byRule = CategoryRuleService.firstMatch(rules, transaction.getLibelle());
        if (byRule.isPresent()) {
            return Optional.of(new Proposal(byRule.get(), CleanupSuggestionSource.RULE));
        }
        Optional<Category> byAmount = history.categoryForAmount(merchant, transaction.getType(), transaction.getMontant());
        if (byAmount.isPresent()) {
            return Optional.of(new Proposal(byAmount.get(), CleanupSuggestionSource.HISTORY_AMOUNT));
        }
        return history.categoryForMerchant(merchant, transaction.getType())
                .map(category -> new Proposal(category, CleanupSuggestionSource.HISTORY_MERCHANT));
    }
}
