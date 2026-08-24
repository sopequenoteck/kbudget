package fr.kksdev.budget.api.runner;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.ActiveAdminInvariantLock;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

@Component
@Order(2)
@RequiredArgsConstructor
@Slf4j
public class AdminSyncRunner implements ApplicationRunner {

    private final AdminEmailResolver adminEmailResolver;
    private final UserRepository userRepository;
    private final ActiveAdminInvariantLock activeAdminInvariantLock;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        Set<String> adminEmails = adminEmailResolver.listAdminEmails();
        boolean lockAcquired = false;
        for (String email : adminEmails) {
            var user = userRepository.findByEmail(email).filter(candidate -> !candidate.isAdmin());
            if (user.isPresent()) {
                if (!lockAcquired) {
                    activeAdminInvariantLock.acquire();
                    lockAcquired = true;
                }
                user.get().setAdmin(true);
                userRepository.save(user.get());
                log.info("Admin promoted via ADMIN_EMAILS sync: {}", email);
            }
        }
    }
}
