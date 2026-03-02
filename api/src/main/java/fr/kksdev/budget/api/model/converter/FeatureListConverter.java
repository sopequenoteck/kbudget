package fr.kksdev.budget.api.model.converter;

import fr.kksdev.budget.api.enums.Feature;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Converter
public class FeatureListConverter implements AttributeConverter<List<Feature>, String> {

    @Override
    public String convertToDatabaseColumn(List<Feature> features) {
        if (features == null || features.isEmpty()) {
            return "";
        }
        return features.stream()
                .map(Feature::name)
                .collect(Collectors.joining(","));
    }

    @Override
    public List<Feature> convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return Collections.emptyList();
        }
        return Arrays.stream(dbData.split(","))
                .filter(s -> !s.isBlank())
                .map(Feature::valueOf)
                .collect(Collectors.toList());
    }
}
