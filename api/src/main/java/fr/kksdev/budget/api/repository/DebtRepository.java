package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DebtRepository extends JpaRepository<Debt, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT d FROM Debt d WHERE d.id = :id")
    Optional<Debt> findByIdForUpdate(@Param("id") UUID id);

    List<Debt> findByUserIdOrderByDateDesc(UUID userId);

    List<Debt> findByUserIdAndRembourseFalseOrderByDateDesc(UUID userId);

    List<Debt> findByUserIdAndRembourseFalse(UUID userId);

    @Query("SELECT d FROM Debt d WHERE d.user.id = :userId AND d.reminderDate = :date AND d.reminderTime <= :time AND d.rembourse = false")
    List<Debt> findDueReminders(@Param("userId") UUID userId, @Param("date") LocalDate date, @Param("time") LocalTime time);

    @Query("SELECT DISTINCT d.user FROM Debt d WHERE d.rembourse = false AND d.reminderDate IS NOT NULL AND d.reminderTime IS NOT NULL")
    List<User> findUsersWithActiveReminders();
}
