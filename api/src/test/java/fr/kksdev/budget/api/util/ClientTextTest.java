package fr.kksdev.budget.api.util;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ClientTextTest {

    private static final String DEFAULT_VALUE = "Default value";

    @Test
    void should_returnDefault_when_providedIsNull() {
        assertThat(ClientText.orDefault(null, DEFAULT_VALUE)).isEqualTo(DEFAULT_VALUE);
    }

    @Test
    void should_returnDefault_when_providedIsEmpty() {
        assertThat(ClientText.orDefault("", DEFAULT_VALUE)).isEqualTo(DEFAULT_VALUE);
    }

    @Test
    void should_returnDefault_when_providedIsBlank() {
        assertThat(ClientText.orDefault("   ", DEFAULT_VALUE)).isEqualTo(DEFAULT_VALUE);
    }

    @Test
    void should_returnStrippedText_when_providedHasSurroundingWhitespace() {
        assertThat(ClientText.orDefault("  Mon libellé  ", DEFAULT_VALUE)).isEqualTo("Mon libellé");
    }

    @Test
    void should_returnProvidedText_when_valid() {
        assertThat(ClientText.orDefault("Mon libellé", DEFAULT_VALUE)).isEqualTo("Mon libellé");
    }
}
