package fr.kksdev.budget.api.config;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.validation.annotation.Validated;

@Component
@ConfigurationProperties(prefix = "app.storage")
@Validated
@Data
public class StorageProperties {

    @NotNull
    @Valid
    private Avatars avatars = new Avatars();

    @Data
    public static class Avatars {

        @NotBlank
        private String path = "./data/avatars";
    }
}
