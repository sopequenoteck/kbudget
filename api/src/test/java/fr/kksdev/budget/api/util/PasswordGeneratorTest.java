package fr.kksdev.budget.api.util;

import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class PasswordGeneratorTest {

    @Test
    void should_return_string_of_requested_length_when_generating_password() {
        String password32 = PasswordGenerator.generate(32);
        assertThat(password32).hasSize(32);

        String password16 = PasswordGenerator.generate(16);
        assertThat(password16).hasSize(16);
    }

    @Test
    void should_contain_only_alphanumeric_chars_when_generating_password() {
        String password = PasswordGenerator.generate(1000);
        assertThat(password).matches("^[A-Za-z0-9]+$");
    }

    @Test
    void should_produce_different_outputs_across_calls() {
        Set<String> generated = new HashSet<>();
        for (int i = 0; i < 100; i++) {
            generated.add(PasswordGenerator.generate(32));
        }
        assertThat(generated).hasSize(100);
    }
}
