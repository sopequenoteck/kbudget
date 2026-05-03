package fr.kksdev.budget.api.config;

import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

import static org.assertj.core.api.Assertions.assertThat;

class BootstrapPropertiesTest {

    private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
            .withUserConfiguration(BootstrapPropertiesTestConfig.class);

    @Test
    void should_fail_to_start_context_when_bootstrap_email_is_invalid() {
        contextRunner
                .withPropertyValues("app.bootstrap.email=not-an-email")
                .run(context -> {
                    assertThat(context).hasFailed();
                    assertThat(context.getStartupFailure()).isNotNull();
                });
    }

    @Test
    void should_start_context_when_bootstrap_email_is_valid() {
        contextRunner
                .withPropertyValues("app.bootstrap.email=kelly@exemple.com")
                .run(context -> {
                    assertThat(context).hasNotFailed();
                    assertThat(context.getBean(BootstrapProperties.class).getEmail())
                            .isEqualTo("kelly@exemple.com");
                });
    }

    @EnableConfigurationProperties(BootstrapProperties.class)
    static class BootstrapPropertiesTestConfig {
    }
}
