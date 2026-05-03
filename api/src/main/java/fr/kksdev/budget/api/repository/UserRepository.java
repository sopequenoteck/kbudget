package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    Optional<User> findByEmailAndDisabledAtIsNull(String email);

    @Query("SELECT COUNT(u) FROM User u WHERE u.isAdmin = true AND u.disabledAt IS NULL")
    long countActiveAdmins();
}
