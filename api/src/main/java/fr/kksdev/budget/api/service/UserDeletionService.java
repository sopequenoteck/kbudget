package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.DeleteAccountRequest;
import fr.kksdev.budget.api.exception.ConfirmationRequiredException;
import fr.kksdev.budget.api.exception.LastAdminDeletionForbiddenException;
import fr.kksdev.budget.api.exception.PasswordIncorrectException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserDeletionService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final RefreshTokenService refreshTokenService;

    @Transactional
    public void softDelete(User user, DeleteAccountRequest request) {
        if (!request.confirmed()) {
            log.warn("Account deletion rejected: confirmation required (userId={})", user.getId());
            throw new ConfirmationRequiredException();
        }

        if (!passwordEncoder.matches(request.currentPassword(), user.getPassword())) {
            log.warn("Account deletion rejected: incorrect password (userId={})", user.getId());
            throw new PasswordIncorrectException();
        }

        if (user.isAdmin() && userRepository.countActiveAdmins() <= 1) {
            log.warn("Account deletion rejected: last active admin (userId={})", user.getId());
            throw new LastAdminDeletionForbiddenException();
        }

        user.setDisabledAt(LocalDateTime.now());
        userRepository.save(user);

        refreshTokenService.revokeAllUserTokens(user);

        log.info("User {} soft-deleted (disabled_at={})", user.getId(), user.getDisabledAt());
    }
}
