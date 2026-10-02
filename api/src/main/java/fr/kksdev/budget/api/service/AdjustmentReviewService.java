package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.AccountSummary;
import fr.kksdev.budget.api.dto.response.AdjustmentReviewResponse;
import fr.kksdev.budget.api.dto.response.AdjustmentReviewResponse.AccountAdjustments;
import fr.kksdev.budget.api.dto.response.AdjustmentReviewResponse.Adjustment;
import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.ImportDraft;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.ImportDraftRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Lists the balance adjustments of a user and tells which ones the bank balance makes
 * look unnecessary (KKS-387). Read only: an adjustment is never deleted here.
 *
 * <p>The bank balance of an account is the one of its latest statement that gave one (KKS-384),
 * the latest balance date winning, the most recently created draft breaking a tie. An adjustment is
 * {@code probablyUnnecessary} when it is dated up to that balance date and the balance of the
 * application at that date, once the adjustment is left out, equals the bank balance to the cent,
 * and no other adjustment already compensates it: an adjustment of the same account, dated the same day
 * or after, whose amount is exactly the opposite (scale ignored), as the counter-adjustment created
 * by {@code adjust-balance} to realign on the bank is dated after the balance date and leaves the
 * balance at that date unchanged. Adjustments are paired in (date, id) order, each at most once.
 * The balance of an account is {@code soldeInitial} plus the signed sum of its transactions, as
 * {@link ImportBalanceService} computes it.
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdjustmentReviewService {

    private final TransactionRepository transactionRepository;
    private final ImportDraftRepository importDraftRepository;

    public AdjustmentReviewResponse review(UUID userId) {
        List<Transaction> adjustments = transactionRepository.findByUserIdAndTypeOrderByDateAscIdAsc(
                userId, TransactionType.AJUSTEMENT);
        if (adjustments.isEmpty()) {
            return new AdjustmentReviewResponse(List.of());
        }
        Map<UUID, ImportDraft> bankBalances = latestBankBalances(userId);
        Map<Account, List<Transaction>> byAccount = adjustments.stream()
                .collect(Collectors.groupingBy(Transaction::getAccount, LinkedHashMap::new, Collectors.toList()));
        List<AccountAdjustments> accounts = byAccount.entrySet().stream()
                .map(entry -> toAccountAdjustments(entry.getKey(), entry.getValue(), bankBalances.get(entry.getKey().getId())))
                .sorted(Comparator.comparing((AccountAdjustments a) -> a.account().nom()).thenComparing(a -> a.account().id()))
                .toList();
        log.info("History cleanup adjustments read: {} adjustments on {} accounts, userId={}",
                adjustments.size(), accounts.size(), userId);
        return new AdjustmentReviewResponse(accounts);
    }

    private Map<UUID, ImportDraft> latestBankBalances(UUID userId) {
        Map<UUID, ImportDraft> latest = new HashMap<>();
        // Sorted latest first: the first draft seen for an account is its latest.
        importDraftRepository.findWithBankBalance(userId, ImportDraftStatus.COMPLETED)
                .forEach(draft -> latest.putIfAbsent(draft.getAccount().getId(), draft));
        return latest;
    }

    private AccountAdjustments toAccountAdjustments(Account account, List<Transaction> adjustments, ImportDraft bankDraft) {
        if (bankDraft == null) {
            return new AccountAdjustments(AccountSummary.from(account), null, null, null,
                    adjustments.stream().map(a -> toAdjustment(a, false)).toList());
        }
        LocalDate balanceDate = bankDraft.getStatementBalanceDate();
        Set<UUID> compensated = compensatedIds(adjustments);
        BigDecimal computed = account.getSoldeInitial()
                .add(transactionRepository.calculateBalanceByAccountIdUntil(account.getId(), balanceDate));
        return new AccountAdjustments(AccountSummary.from(account), bankDraft.getStatementBalance(), balanceDate, computed,
                adjustments.stream()
                        .map(a -> toAdjustment(a, !compensated.contains(a.getId()) && isUnnecessary(a, computed, bankDraft)))
                        .toList());
    }

    /**
     * Ids of the adjustments compensated by a later one. {@code adjustments} are of one account, sorted by
     * (date, id): each adjustment not yet paired takes the first not yet paired one, other than itself, dated
     * the same day or after, whose amount is the opposite. Pairs never overlap; only the earlier member of a
     * pair is compensated, the later one is judged on its own, unless both are dated the same day: nothing then
     * tells which one cancels the other, both are compensated.
     */
    private static Set<UUID> compensatedIds(List<Transaction> adjustments) {
        Set<UUID> compensated = new HashSet<>();
        Set<UUID> paired = new HashSet<>();
        for (Transaction adjustment : adjustments) {
            if (paired.contains(adjustment.getId())) {
                continue;
            }
            adjustments.stream()
                    .filter(other -> !other.getId().equals(adjustment.getId())
                            && !paired.contains(other.getId())
                            && !other.getDate().isBefore(adjustment.getDate())
                            && other.getMontant().compareTo(adjustment.getMontant().negate()) == 0)
                    .findFirst()
                    .ifPresent(other -> {
                        compensated.add(adjustment.getId());
                        if (other.getDate().equals(adjustment.getDate())) {
                            compensated.add(other.getId());
                        }
                        paired.add(adjustment.getId());
                        paired.add(other.getId());
                    });
        }
        return compensated;
    }

    private static boolean isUnnecessary(Transaction adjustment, BigDecimal computedBalance, ImportDraft bankDraft) {
        return !adjustment.getDate().isAfter(bankDraft.getStatementBalanceDate())
                && computedBalance.subtract(adjustment.getMontant()).compareTo(bankDraft.getStatementBalance()) == 0;
    }

    private static Adjustment toAdjustment(Transaction adjustment, boolean probablyUnnecessary) {
        return new Adjustment(adjustment.getId(), adjustment.getDate(), adjustment.getLibelle(),
                adjustment.getMontant(), probablyUnnecessary);
    }
}
