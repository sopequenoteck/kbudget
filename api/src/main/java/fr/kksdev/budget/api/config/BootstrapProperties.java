package fr.kksdev.budget.api.config;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.validation.annotation.Validated;

@Component
@ConfigurationProperties(prefix = "app.bootstrap")
@Validated
@Data
public class BootstrapProperties {

    @NotBlank
    @Email
    private String email = "admin@localhost";
}
