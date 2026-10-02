package fr.kksdev.budget.api.enums;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class SystemCategoryKeyTest {

    @Test
    void should_returnNull_when_nameOfNullKey() {
        assertThat(SystemCategoryKey.nameOf(null)).isNull();
    }

    @Test
    void should_returnEnumName_when_nameOfNonNullKey() {
        assertThat(SystemCategoryKey.nameOf(SystemCategoryKey.SUBSCRIPTION)).isEqualTo("SUBSCRIPTION");
        assertThat(SystemCategoryKey.nameOf(SystemCategoryKey.DEBT)).isEqualTo("DEBT");
        assertThat(SystemCategoryKey.nameOf(SystemCategoryKey.TRANSFER)).isEqualTo("TRANSFER");
        assertThat(SystemCategoryKey.nameOf(SystemCategoryKey.ADJUSTMENT)).isEqualTo("ADJUSTMENT");
    }
}
