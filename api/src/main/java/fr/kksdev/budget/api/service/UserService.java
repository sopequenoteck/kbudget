package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.UserUpdateRequest;
import fr.kksdev.budget.api.dto.response.UserResponse;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;

    public UserResponse getProfile(UUID userId) {
        User user = findById(userId);
        return toResponse(user);
    }

    @Transactional
    public UserResponse updateProfile(UUID userId, UserUpdateRequest request) {
        User user = findById(userId);
        if (request.name() != null) {
            user.setName(request.name());
        }
        user = userRepository.save(user);
        log.info("Profil mis à jour: userId={}", userId);
        return toResponse(user);
    }

    private User findById(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> {
                    log.error("Utilisateur non trouvé: userId={}", userId);
                    return new EntityNotFoundException("Utilisateur non trouvé");
                });
    }

    private UserResponse toResponse(User user) {
        return new UserResponse(
                user.getName(),
                user.getEmail(),
                user.isAdmin()
        );
    }
}
