package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.CategorySource;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.util.MerchantKey;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Pre-remplit la categorie des lignes d'un releve (KKS-383), dans cet ordre :
 *
 * <ol>
 *   <li>une regle de l'utilisateur ;</li>
 *   <li>la categorie majoritaire de ses transactions passees chez le meme
 *       commercant, <strong>au meme montant</strong> — c'est ce qui distingue
 *       plusieurs abonnements factures sous un meme libelle ;</li>
 *   <li>la categorie majoritaire chez le meme commercant, tous montants.</li>
 * </ol>
 *
 * Le commercant est compare par sa {@link MerchantKey}, et le sens (depense ou
 * recette) doit etre le meme : un remboursement n'herite pas de la categorie
 * d'un achat. A egalite, la categorie la plus recente l'emporte. Seul
 * l'historique de l'utilisateur est lu.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CategorySuggestionService {

    private final CategoryRuleService categoryRuleService;
    private final TransactionRepository transactionRepository;

    public void suggest(List<ImportDraftLine> lines, UUID userId) {
        categoryRuleService.applyRules(lines, userId);

        List<ImportDraftLine> uncategorized = lines.stream()
                .filter(l -> l.getCategory() == null && l.getStatus() == ImportLineStatus.READY)
                .toList();
        if (uncategorized.isEmpty()) {
            return;
        }

        MerchantHistory history = new MerchantHistory(
                transactionRepository.findByUserIdAndCategoryIsNotNullAndIsRecurringFalse(userId));
        int byHistory = 0;
        for (ImportDraftLine line : uncategorized) {
            Optional<Category> category = history.categoryFor(
                    MerchantKey.of(line.getCleanLabel()), line.getTransactionType(), line.getAmount());
            if (category.isPresent()) {
                line.setCategory(category.get());
                line.setCategorySource(CategorySource.HISTORY);
                byHistory++;
            }
        }
        log.info("Category suggestion: {} lines categorized from history out of {} uncategorized",
                byHistory, uncategorized.size());
    }

    /** Categories deja attribuees, par commercant et sens, puis par commercant, sens et montant. */
    static final class MerchantHistory {

        private final Map<String, Tally> byMerchantAndAmount = new HashMap<>();
        private final Map<String, Tally> byMerchant = new HashMap<>();

        MerchantHistory(List<Transaction> transactions) {
            for (Transaction t : transactions) {
                String merchant = MerchantKey.of(t.getLibelle());
                if (merchant.isEmpty()) {
                    continue;
                }
                byMerchant.computeIfAbsent(merchantKey(merchant, t.getType()), k -> new Tally()).add(t);
                byMerchantAndAmount.computeIfAbsent(amountKey(merchant, t.getType(), t.getMontant()), k -> new Tally()).add(t);
            }
        }

        Optional<Category> categoryFor(String merchant, TransactionType type, BigDecimal amount) {
            if (merchant.isEmpty()) {
                return Optional.empty();
            }
            Tally sameAmount = byMerchantAndAmount.get(amountKey(merchant, type, amount));
            if (sameAmount != null) {
                return Optional.of(sameAmount.best());
            }
            return Optional.ofNullable(byMerchant.get(merchantKey(merchant, type))).map(Tally::best);
        }

        private static String merchantKey(String merchant, TransactionType type) {
            return type + "|" + merchant;
        }

        private static String amountKey(String merchant, TransactionType type, BigDecimal amount) {
            return merchantKey(merchant, type) + "|" + amount.stripTrailingZeros().toPlainString();
        }
    }

    /** Occurrences de chaque categorie pour une cle, et la date de la plus recente. */
    private static final class Tally {

        private final Map<UUID, Count> counts = new HashMap<>();

        void add(Transaction t) {
            counts.computeIfAbsent(t.getCategory().getId(), id -> new Count(t.getCategory())).add(t.getDate());
        }

        Category best() {
            return counts.values().stream()
                    .max(Comparator.comparingInt((Count c) -> c.occurrences).thenComparing(c -> c.latest))
                    .orElseThrow()
                    .category;
        }
    }

    private static final class Count {
        private final Category category;
        private int occurrences;
        private LocalDate latest = LocalDate.MIN;

        Count(Category category) {
            this.category = category;
        }

        void add(LocalDate date) {
            occurrences++;
            if (date != null && date.isAfter(latest)) {
                latest = date;
            }
        }
    }
}
