package fr.kksdev.budget.api.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Clock;

/**
 * Horloge injectable, plutot que des appels directs a {@code LocalDate.now()}.
 *
 * <p>Deux benefices : la zone est explicite au lieu d'etre celle de la machine
 * par accident, et un test peut fournir une horloge fixe — donc verifier un
 * comportement date sans dependre du jour ou il s'execute (KKS-355).
 */
@Configuration
public class ClockConfig {

    @Bean
    public Clock clock() {
        return Clock.systemDefaultZone();
    }
}
