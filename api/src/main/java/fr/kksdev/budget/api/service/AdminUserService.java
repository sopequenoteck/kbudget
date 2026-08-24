package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.AdminUserResponse;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdminUserService {

    private final UserRepository userRepository;
    private final ActiveAdminInvariantLock activeAdminInvariantLock;

    @Transactional(readOnly = true)
    public List<AdminUserResponse> list() {
        return userRepository.findAll().stream()
                .sorted(Comparator.comparing(User::getCreatedAt))
                .map(u -> new AdminUserResponse(
                        u.getId(),
                        u.getEmail(),
                        u.getName(),
                        u.getCreatedAt(),
                        u.getDisabledAt(),
                        u.isAdmin()
                ))
                .toList();
    }

    @Transactional
    public void disable(UUID userId, User admin) {
        activeAdminInvariantLock.acquire();
        User target = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable"));
        guardLastActiveAdmin(target);
        target.setDisabledAt(LocalDateTime.now());
        userRepository.save(target);
        log.info("Admin action: user.disable by {} target=user:{}", admin.getEmail(), userId);
    }

    @Transactional
    public void enable(UUID userId, User admin) {
        activeAdminInvariantLock.acquire();
        User target = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable"));
        target.setDisabledAt(null);
        userRepository.save(target);
        log.info("Admin action: user.enable by {} target=user:{}", admin.getEmail(), userId);
    }

    private void guardLastActiveAdmin(User target) {
        if (!target.isAdmin()) {
            return;
        }
        long otherActiveAdmins = userRepository.findAll().stream()
                .filter(u -> !u.getId().equals(target.getId()))
                .filter(u -> u.getDisabledAt() == null)
                .filter(User::isAdmin)
                .count();
        if (otherActiveAdmins == 0) {
            log.warn("Admin action refused: user.disable would leave zero active admin. target=user:{}", target.getId());
            throw new ConflictException("LAST_ADMIN_CANNOT_BE_DISABLED");
        }
    }
}
