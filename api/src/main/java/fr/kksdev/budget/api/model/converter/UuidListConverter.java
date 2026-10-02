package fr.kksdev.budget.api.model.converter;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/** List of identifiers stored in one text column, separated by commas (KKS-385). */
@Converter
public class UuidListConverter implements AttributeConverter<List<UUID>, String> {

    @Override
    public String convertToDatabaseColumn(List<UUID> ids) {
        if (ids == null || ids.isEmpty()) {
            return null;
        }
        return ids.stream().map(UUID::toString).collect(Collectors.joining(","));
    }

    @Override
    public List<UUID> convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return List.of();
        }
        return Arrays.stream(dbData.split(",")).map(UUID::fromString).toList();
    }
}
