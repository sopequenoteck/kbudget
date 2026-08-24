package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import fr.kksdev.budget.api.enums.Currency;

@Service
@RequiredArgsConstructor
@Transactional
public class UserOnboardingService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final CategoryService categoryService;
    private final AccountService accountService;
    private final PreferenceService preferenceService;
    private final ActiveAdminInvariantLock activeAdminInvariantLock;

    public record UserProvisioningRequest(
            String email,
            String rawPassword,
            String displayName,
            Currency currency,
            String timezone,
            boolean isAdmin,
            boolean passwordResetRequired
    ) {}

    public User provisionUser(UserProvisioningRequest request) {
        if (request.isAdmin()) {
            activeAdminInvariantLock.acquire();
        }
        User user = User.builder()
                .email(request.email())
                .password(passwordEncoder.encode(request.rawPassword()))
                .name(request.displayName())
                .isAdmin(request.isAdmin())
                .passwordResetRequired(request.passwordResetRequired())
                .build();
        userRepository.save(user);
        categoryService.seedSystemCategories(user);
        accountService.createDefaultAccount(user, request.currency());
        preferenceService.createInitialPreference(user, request.currency(), request.timezone());
        return user;
    }
}
