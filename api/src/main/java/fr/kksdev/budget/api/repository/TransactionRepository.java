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

    @Query(value = "SELECT COALESCE(SUM(CASE WHEN t.type = 'RECETTE' THEN t.montant ELSE -t.montant END), 0) " +
            "FROM transactions t WHERE t.account_id = :accountId", nativeQuery = true)
    BigDecimal calculateBalanceByAccountId(@Param("accountId") UUID accountId);

    List<Transaction> findByTransferId(UUID transferId);

    boolean existsByAccountId(UUID accountId);
}
