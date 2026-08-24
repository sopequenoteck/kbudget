package fr.kksdev.budget.api.service;

import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.jdbc.datasource.DataSourceUtils;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Serializes every application mutation of the active-administrator set.
 * The key is global, stable across JVMs, and reserved for this invariant.
 */
@Component
@RequiredArgsConstructor
public class ActiveAdminInvariantLock {

    static final long LOCK_KEY = 4_542_971_083_311_007L;

    private final EntityManager entityManager;
    private final DataSource dataSource;

    public void acquire() {
        if (!TransactionSynchronizationManager.isActualTransactionActive()) {
            throw new IllegalStateException("The active-admin invariant lock requires an active transaction");
        }
        String databaseProduct = databaseProductName();
        if (databaseProduct.equals("H2")) {
            // H2 backs unit and slice tests only. The concurrency integration test uses PostgreSQL.
            return;
        }
        if (!databaseProduct.equals("PostgreSQL")) {
            throw new IllegalStateException(
                    "The active-admin invariant lock is unsupported on database: " + databaseProduct);
        }
        entityManager.createNativeQuery("SELECT pg_advisory_xact_lock(?1)")
                .setParameter(1, LOCK_KEY)
                .getSingleResult();
    }

    private String databaseProductName() {
        Connection connection = DataSourceUtils.getConnection(dataSource);
        try {
            return connection.getMetaData().getDatabaseProductName();
        } catch (SQLException exception) {
            throw new IllegalStateException("Unable to identify database for active-admin invariant lock", exception);
        } finally {
            DataSourceUtils.releaseConnection(connection, dataSource);
        }
    }
}
