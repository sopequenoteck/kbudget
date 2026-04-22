package fr.kksdev.budget.api.runner;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.repository.UserRepository;
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

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        Set<String> adminEmails = adminEmailResolver.listAdminEmails();
        for (String email : adminEmails) {
            userRepository.findByEmail(email)
                    .filter(user -> !user.isAdmin())
                    .ifPresent(user -> {
                        user.setAdmin(true);
                        userRepository.save(user);
                        log.info("Admin promoted via ADMIN_EMAILS sync: {}", email);
                    });
        }
    }
}
