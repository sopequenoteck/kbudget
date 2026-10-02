package fr.kksdev.budget.api.model.converter;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class UuidListConverterTest {

    private static final UUID FIRST = UUID.fromString("00000000-0000-0000-0000-000000000001");
    private static final UUID SECOND = UUID.fromString("00000000-0000-0000-0000-000000000002");

    private final UuidListConverter converter = new UuidListConverter();

    @Test
    void should_join_the_identifiers_with_commas_in_the_given_order() {
        assertThat(converter.convertToDatabaseColumn(List.of(SECOND, FIRST)))
                .isEqualTo("00000000-0000-0000-0000-000000000002,00000000-0000-0000-0000-000000000001");
    }

    @Test
    void should_store_nothing_for_a_null_or_empty_list() {
        assertThat(converter.convertToDatabaseColumn(null)).isNull();
        assertThat(converter.convertToDatabaseColumn(List.of())).isNull();
    }

    @Test
    void should_read_back_what_it_stored() {
        List<UUID> ids = List.of(FIRST, SECOND);

        assertThat(converter.convertToEntityAttribute(converter.convertToDatabaseColumn(ids))).isEqualTo(ids);
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {" "})
    void should_read_an_empty_list_when_the_column_is_null_or_blank(String column) {
        assertThat(converter.convertToEntityAttribute(column)).isEmpty();
    }
}
