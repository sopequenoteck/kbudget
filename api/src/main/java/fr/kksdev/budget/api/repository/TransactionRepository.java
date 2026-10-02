package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    List<Transaction> findByUserIdOrderByDateDesc(UUID userId);

    List<Transaction> findByUserIdAndIsRecurringFalseOrderByDateDesc(UUID userId);

    List<Transaction> findByUserIdAndIsRecurringFalseAndDateBetweenOrderByDateDesc(UUID userId, LocalDate from, LocalDate to);

    List<Transaction> findByUserIdAndIsRecurringTrueAndRecurringActiveTrueOrderByNextOccurrenceAsc(UUID userId);

    List<Transaction> findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual(UUID userId, LocalDate date);

    List<Transaction> findBySubscriptionIdAndUserIdOrderByDateDesc(UUID subscriptionId, UUID userId);

    /** Payments of a subscription dated within {@code from} to {@code to}, both included, oldest first (KKS-385). */
    List<Transaction> findBySubscriptionIdAndUserIdAndDateBetweenOrderByDateAscIdAsc(
            UUID subscriptionId, UUID userId, LocalDate from, LocalDate to);

    @Query("SELECT COALESCE(SUM(t.montant), 0) FROM Transaction t WHERE t.subscription.id = :subscriptionId AND t.user.id = :userId")
    BigDecimal sumBySubscriptionIdAndUserId(@Param("subscriptionId") UUID subscriptionId, @Param("userId") UUID userId);

    @Query("SELECT COUNT(t) FROM Transaction t WHERE t.subscription.id = :subscriptionId AND t.user.id = :userId")
    long countBySubscriptionIdAndUserId(@Param("subscriptionId") UUID subscriptionId, @Param("userId") UUID userId);

    @Query(value = "SELECT COALESCE(SUM(CASE WHEN t.type = 'RECETTE' THEN t.montant " +
            "WHEN t.type = 'AJUSTEMENT' THEN t.montant ELSE -t.montant END), 0) " +
            "FROM transactions t WHERE t.account_id = :accountId", nativeQuery = true)
    BigDecimal calculateBalanceByAccountId(@Param("accountId") UUID accountId);

    /** Same sum as {@link #calculateBalanceByAccountId}, limited to transactions dated up to {@code date} (KKS-384). */
    @Query(value = "SELECT COALESCE(SUM(CASE WHEN t.type = 'RECETTE' THEN t.montant " +
            "WHEN t.type = 'AJUSTEMENT' THEN t.montant ELSE -t.montant END), 0) " +
            "FROM transactions t WHERE t.account_id = :accountId AND t.date <= :date", nativeQuery = true)
    BigDecimal calculateBalanceByAccountIdUntil(@Param("accountId") UUID accountId, @Param("date") LocalDate date);

    List<Transaction> findByTransferId(UUID transferId);

    boolean existsByAccountId(UUID accountId);

    @Query(value = "SELECT COALESCE(SUM(t.montant), 0) FROM transactions t " +
            "WHERE t.user_id = :userId AND t.category_id = :categoryId " +
            "AND t.type = 'DEPENSE' AND t.is_recurring = false AND t.date >= :from AND t.date <= :to",
            nativeQuery = true)
    BigDecimal sumDepenseByUserIdAndCategoryIdAndDateBetween(
            @Param("userId") UUID userId,
            @Param("categoryId") UUID categoryId,
            @Param("from") LocalDate from,
            @Param("to") LocalDate to);

    @Query(value = "SELECT t.category_id, COALESCE(SUM(t.montant), 0), a.currency FROM transactions t " +
            "JOIN accounts a ON t.account_id = a.id " +
            "WHERE t.user_id = :userId AND t.category_id IN :categoryIds " +
            "AND t.type = 'DEPENSE' AND t.is_recurring = false AND t.date >= :from AND t.date <= :to " +
            "GROUP BY t.category_id, a.currency",
            nativeQuery = true)
    List<Object[]> sumDepenseByUserIdAndCategoryIdsAndDateBetween(
            @Param("userId") UUID userId,
            @Param("categoryIds") List<UUID> categoryIds,
            @Param("from") LocalDate from,
            @Param("to") LocalDate to);

    @Query(value = "SELECT COALESCE(SUM(t.montant), 0) FROM transactions t WHERE t.debt_id = :debtId", nativeQuery = true)
    BigDecimal sumByDebtId(@Param("debtId") UUID debtId);

    @Query(value = "SELECT t.debt_id, COALESCE(SUM(t.montant), 0) FROM transactions t WHERE t.debt_id IN :debtIds GROUP BY t.debt_id", nativeQuery = true)
    List<Object[]> sumByDebtIds(@Param("debtIds") List<UUID> debtIds);

    List<Transaction> findByDebtIdOrderByDateDesc(UUID debtId);

    List<Transaction> findByUserIdAndAccountIdAndDateBetween(UUID userId, UUID accountId, LocalDate from, LocalDate to);

    List<Transaction> findByUserIdAndAccountIdAndImportFingerprintIn(UUID userId, UUID accountId, Collection<String> fingerprints);

    List<Transaction> findByUserIdAndAccountIdAndIdIn(UUID userId, UUID accountId, Collection<UUID> ids);

    List<Transaction> findByUserIdAndIdIn(UUID userId, Collection<UUID> ids);

    List<Transaction> findByUserIdAndTypeOrderByDateAscIdAsc(UUID userId, TransactionType type);

    /**
     * Transactions of the user that the history cleanup may merge, oldest first (KKS-387): neither an
     * adjustment, nor a recurring template, nor one leg of a transfer.
     */
    @Query("SELECT t FROM Transaction t LEFT JOIN FETCH t.category LEFT JOIN FETCH t.account " +
            "LEFT JOIN FETCH t.subscription " +
            "WHERE t.user.id = :userId AND t.type <> :excludedType AND t.isRecurring = false " +
            "AND t.transferId IS NULL ORDER BY t.date ASC, t.id ASC")
    List<Transaction> findMergeableByUserId(@Param("userId") UUID userId,
                                            @Param("excludedType") TransactionType excludedType);

    /** Transactions of the user with no category, oldest first, recurring templates and {@code excludedType} left out (KKS-387). */
    @Query("SELECT t FROM Transaction t LEFT JOIN FETCH t.account " +
            "WHERE t.user.id = :userId AND t.category IS NULL AND t.type <> :excludedType " +
            "AND t.isRecurring = false ORDER BY t.date ASC, t.id ASC")
    List<Transaction> findUncategorizedByUserId(@Param("userId") UUID userId,
                                                @Param("excludedType") TransactionType excludedType);

    List<Transaction> findByUserIdAndCategoryIsNotNullAndIsRecurringFalse(UUID userId);

    boolean existsByUserIdAndDateBetween(UUID userId, LocalDate from, LocalDate to);

    @Query(value = "SELECT t.category_id, c.nom, c.icone, c.couleur, c.is_system, COUNT(t.id) as cnt, c.system_key " +
            "FROM transactions t JOIN categories c ON t.category_id = c.id " +
            "WHERE t.user_id = :userId AND t.is_recurring = false " +
            "AND t.date >= :since AND t.category_id IS NOT NULL " +
            "GROUP BY t.category_id, c.nom, c.icone, c.couleur, c.is_system, c.system_key " +
            "ORDER BY cnt DESC LIMIT :limit",
            nativeQuery = true)
    List<Object[]> findMostUsedCategories(
            @Param("userId") UUID userId,
            @Param("since") LocalDate since,
            @Param("limit") int limit);

    @Query(value = "SELECT t.category_id, c.nom, c.icone, c.couleur, COALESCE(SUM(t.montant), 0), a.currency, c.system_key " +
            "FROM transactions t JOIN categories c ON t.category_id = c.id " +
            "JOIN accounts a ON t.account_id = a.id " +
            "WHERE t.user_id = :userId AND t.type = 'DEPENSE' AND t.is_recurring = false " +
            "AND t.date >= :startDate AND t.date <= :endDate " +
            "AND t.category_id IS NOT NULL " +
            "AND t.category_id NOT IN (SELECT b.category_id FROM budgets b WHERE b.user_id = :userId AND b.actif = true) " +
            "GROUP BY t.category_id, c.nom, c.icone, c.couleur, a.currency, c.system_key",
            nativeQuery = true)
    List<Object[]> findUnbudgetedSpendingByMonth(
            @Param("userId") UUID userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    @Query(value = """
            SELECT t.libelle
            FROM transactions t
            WHERE t.user_id = :userId
              AND (:q IS NULL OR LOWER(UNACCENT(t.libelle)) LIKE '%' || LOWER(UNACCENT(CAST(:q AS TEXT))) || '%')
            GROUP BY t.libelle
            ORDER BY COUNT(*) DESC, MAX(t.date) DESC
            LIMIT :limit
            """, nativeQuery = true)
    List<String> findLibelleSuggestions(
            @Param("userId") UUID userId,
            @Param("q") String q,
            @Param("limit") int limit);
}
