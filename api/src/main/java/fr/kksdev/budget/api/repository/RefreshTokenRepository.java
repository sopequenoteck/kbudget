package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.enums.TokenStatus;
import fr.kksdev.budget.api.model.RefreshToken;
import fr.kksdev.budget.api.model.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<RefreshToken> findByToken(String token);

    List<RefreshToken> findByUserAndStatus(User user, TokenStatus status);

    void deleteByExpiresAtBefore(LocalDateTime date);
}
