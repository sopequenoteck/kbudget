package fr.kksdev.budget.api.model.converter;

import fr.kksdev.budget.api.enums.Currency;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Converter
public class CurrencyListConverter implements AttributeConverter<List<Currency>, String> {

    @Override
    public String convertToDatabaseColumn(List<Currency> currencies) {
        if (currencies == null || currencies.isEmpty()) {
            return "";
        }
        return currencies.stream()
                .map(Currency::name)
                .collect(Collectors.joining(","));
    }

    @Override
    public List<Currency> convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return Collections.emptyList();
        }
        return Arrays.stream(dbData.split(","))
                .filter(s -> !s.isBlank())
                .map(Currency::valueOf)
                .collect(Collectors.toList());
    }
}
