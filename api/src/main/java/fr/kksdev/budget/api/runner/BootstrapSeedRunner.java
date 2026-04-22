package fr.kksdev.budget.api.runner;

import fr.kksdev.budget.api.config.BootstrapProperties;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.UserOnboardingService;
import fr.kksdev.budget.api.service.UserOnboardingService.UserProvisioningRequest;
import fr.kksdev.budget.api.util.PasswordGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

@Component
@Order(1)
@RequiredArgsConstructor
@Slf4j
public class BootstrapSeedRunner implements ApplicationRunner {

    private static final int PASSWORD_LENGTH = 32;

    private final UserRepository userRepository;
    private final UserOnboardingService userOnboardingService;
    private final BootstrapProperties bootstrapProperties;

    @Override
    public void run(ApplicationArguments args) {
        if (userRepository.count() > 0) {
            return;
        }

        String rawPassword = PasswordGenerator.generate(PASSWORD_LENGTH);
        String email = bootstrapProperties.getEmail();

        userOnboardingService.provisionUser(new UserProvisioningRequest(
                email,
                rawPassword,
                "Admin",
                Currency.EUR,
                "Europe/Paris",
                true,
                true
        ));

        log.warn(buildBanner(email, rawPassword));
    }

    private String buildBanner(String email, String password) {
        return """

                ================================================
                 FIRST BOOT — Admin account created
                 Email:    %s
                 Password: %s
                 CHANGE THESE CREDENTIALS IMMEDIATELY
                ================================================
                """.formatted(email, password);
    }
}
