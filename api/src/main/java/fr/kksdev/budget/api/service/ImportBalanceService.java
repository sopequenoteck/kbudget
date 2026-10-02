package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.ImportBalanceCheckResponse;
import fr.kksdev.budget.api.dto.response.ImportBalanceCheckResponse.SuspectTransaction;
import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.ImportDraft;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.ImportHistoryRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * Uses the balance given by the bank in a statement header (KKS-384): the balance
 * the application would have if a draft were confirmed, the opening balance that
 * would make both agree, and the check run once the import is created.
 *
 * <p>The balance of an account is always {@code soldeInitial + sum of its
 * transactions}, signed as in {@code TransactionRepository#calculateBalanceByAccountId};
 * it is limited here to the transactions dated up to the balance date of the statement.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ImportBalanceService {

    /**
     * @param projectedBalance      balance of the application at the date of the statement balance
     *                              if the draft is confirmed as it stands
     * @param proposedOpeningBalance opening balance that makes {@code projectedBalance} equal the
     *                              bank balance; only for the first import of the account
     */
    public record DraftBalances(BigDecimal projectedBalance, BigDecimal proposedOpeningBalance) {

        static final DraftBalances NONE = new DraftBalances(null, null);
    }

    private final TransactionRepository transactionRepository;
    private final ImportHistoryRepository importHistoryRepository;

    /**
     * Balances of a draft that is still awaiting confirmation and whose statement
     * gave a balance and its date; {@link DraftBalances#NONE} otherwise.
     */
    public DraftBalances draftBalances(ImportDraft draft, List<ImportDraftLine> lines, UUID userId) {
        if (draft.getStatus() != ImportDraftStatus.PENDING || !hasBankBalance(draft)) {
            return DraftBalances.NONE;
        }
        Account account = draft.getAccount();
        LocalDate balanceDate = draft.getStatementBalanceDate();
        BigDecimal openingBalance = account.getSoldeInitial();
        BigDecimal projected = openingBalance
                .add(transactionRepository.calculateBalanceByAccountIdUntil(account.getId(), balanceDate))
                .add(sumOfReadyLinesUntil(lines, balanceDate));
        boolean firstImport = !importHistoryRepository.existsByUserIdAndAccountId(userId, account.getId());
        BigDecimal proposed = firstImport
                ? draft.getStatementBalance().subtract(projected).add(openingBalance)
                : null;
        return new DraftBalances(projected, proposed);
    }

    /**
     * Compares the balance of the bank with the one of the application, once the
     * transactions of the import exist. {@code null} when the statement gave no balance.
     *
     * @param lines      every line of the draft
     * @param createdIds ids of the transactions the import has just created
     */
    public ImportBalanceCheckResponse check(ImportDraft draft, List<ImportDraftLine> lines,
                                            Collection<UUID> createdIds, UUID userId) {
        if (!hasBankBalance(draft)) {
            return null;
        }
        Account account = draft.getAccount();
        BigDecimal computed = account.getSoldeInitial()
                .add(transactionRepository.calculateBalanceByAccountIdUntil(
                        account.getId(), draft.getStatementBalanceDate()));
        return new ImportBalanceCheckResponse(
                draft.getStatementBalance(),
                draft.getStatementBalanceDate(),
                computed,
                computed.subtract(draft.getStatementBalance()),
                suspects(account.getId(), lines, createdIds, draft.getStatementBalanceDate(), userId));
    }

    /**
     * Transactions of the account within the period of the statement (earliest date of its
     * lines to the latest of its lines and of the balance date, since the bank balance covers
     * every operation up to that date) that no line accounts for: neither created by this import nor
     * recognized as an existing transaction. Adjustments are left out, they are deliberate.
     * A line whose date could not be read has no date and does not stretch the period.
     */
    private List<SuspectTransaction> suspects(UUID accountId, List<ImportDraftLine> lines,
                                              Collection<UUID> createdIds, LocalDate balanceDate,
                                              UUID userId) {
        List<LocalDate> dates = lines.stream()
                .filter(line -> line.getStatusMessage() == null)
                .map(ImportDraftLine::getDate)
                .toList();
        if (dates.isEmpty()) {
            return List.of();
        }
        Set<UUID> accountedFor = new HashSet<>(createdIds);
        lines.stream()
                .filter(line -> line.getStatus() == ImportLineStatus.SKIPPED)
                .map(ImportDraftLine::getDuplicateTransactionId)
                .filter(Objects::nonNull)
                .forEach(accountedFor::add);

        return transactionRepository
                .findByUserIdAndAccountIdAndDateBetween(userId, accountId, Collections.min(dates),
                        latest(Collections.max(dates), balanceDate))
                .stream()
                .filter(t -> t.getType() != TransactionType.AJUSTEMENT)
                .filter(t -> !accountedFor.contains(t.getId()))
                .sorted(Comparator.comparing(Transaction::getDate)
                        .thenComparing(Transaction::getLibelle)
                        .thenComparing(Transaction::getId))
                .map(t -> new SuspectTransaction(t.getId(), t.getDate(), t.getLibelle(), t.getMontant(), t.getType()))
                .toList();
    }

    private static LocalDate latest(LocalDate first, LocalDate second) {
        return first.isAfter(second) ? first : second;
    }

    private static boolean hasBankBalance(ImportDraft draft) {
        return draft.getStatementBalance() != null && draft.getStatementBalanceDate() != null;
    }

    private static BigDecimal sumOfReadyLinesUntil(List<ImportDraftLine> lines, LocalDate balanceDate) {
        return lines.stream()
                .filter(line -> line.getStatus() == ImportLineStatus.READY)
                .filter(line -> !line.getDate().isAfter(balanceDate))
                .map(line -> line.getTransactionType() == TransactionType.DEPENSE
                        ? line.getAmount().negate()
                        : line.getAmount())
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
