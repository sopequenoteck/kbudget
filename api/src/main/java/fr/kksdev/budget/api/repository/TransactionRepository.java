package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    List<Transaction> findByUserIdOrderByDateDesc(UUID userId);

    List<Transaction> findByUserIdAndDateBetweenOrderByDateDesc(UUID userId, LocalDate from, LocalDate to);

    @Query(value = "SELECT COALESCE(SUM(CASE WHEN t.type = 'RECETTE' THEN t.montant " +
            "WHEN t.type = 'AJUSTEMENT' THEN t.montant ELSE -t.montant END), 0) " +
            "FROM transactions t WHERE t.account_id = :accountId", nativeQuery = true)
    BigDecimal calculateBalanceByAccountId(@Param("accountId") UUID accountId);

    List<Transaction> findByTransferId(UUID transferId);

    boolean existsByAccountId(UUID accountId);

    List<Transaction> findByProductIdAndUserIdOrderByDateDesc(UUID productId, UUID userId);

    @Query(value = "SELECT COALESCE(SUM(t.montant), 0) FROM transactions t " +
            "WHERE t.user_id = :userId AND t.category_id = :categoryId " +
            "AND t.type = 'DEPENSE' AND t.date >= :from AND t.date <= :to",
            nativeQuery = true)
    BigDecimal sumDepenseByUserIdAndCategoryIdAndDateBetween(
            @Param("userId") UUID userId,
            @Param("categoryId") UUID categoryId,
            @Param("from") LocalDate from,
            @Param("to") LocalDate to);

    @Query(value = "SELECT t.category_id, COALESCE(SUM(t.montant), 0) FROM transactions t " +
            "WHERE t.user_id = :userId AND t.category_id IN :categoryIds " +
            "AND t.type = 'DEPENSE' AND t.date >= :from AND t.date <= :to " +
            "GROUP BY t.category_id",
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

    @Query(value = "SELECT t.category_id, c.nom, c.icone, c.couleur, COALESCE(SUM(t.montant), 0), a.currency " +
            "FROM transactions t JOIN categories c ON t.category_id = c.id " +
            "JOIN accounts a ON t.account_id = a.id " +
            "WHERE t.user_id = :userId AND t.type = 'DEPENSE' " +
            "AND t.date >= :startDate AND t.date <= :endDate " +
            "AND t.category_id IS NOT NULL " +
            "AND t.category_id NOT IN (SELECT b.category_id FROM budgets b WHERE b.user_id = :userId AND b.actif = true) " +
            "GROUP BY t.category_id, c.nom, c.icone, c.couleur, a.currency",
            nativeQuery = true)
    List<Object[]> findUnbudgetedSpendingByMonth(
            @Param("userId") UUID userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
}
