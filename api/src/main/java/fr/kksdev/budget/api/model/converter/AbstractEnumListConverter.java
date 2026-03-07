package fr.kksdev.budget.api.model.converter;

import jakarta.persistence.AttributeConverter;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

public abstract class AbstractEnumListConverter<E extends Enum<E>> implements AttributeConverter<List<E>, String> {

    private final Class<E> enumClass;

    protected AbstractEnumListConverter(Class<E> enumClass) {
        this.enumClass = enumClass;
    }

    @Override
    public String convertToDatabaseColumn(List<E> enums) {
        if (enums == null || enums.isEmpty()) {
            return "";
        }
        return enums.stream().map(Enum::name).collect(Collectors.joining(","));
    }

    @Override
    public List<E> convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return Collections.emptyList();
        }
        return Arrays.stream(dbData.split(","))
                .filter(s -> !s.isBlank())
                .map(s -> Enum.valueOf(enumClass, s))
                .collect(Collectors.toList());
    }
}
