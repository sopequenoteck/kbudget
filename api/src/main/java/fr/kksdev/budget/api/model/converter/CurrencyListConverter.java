package fr.kksdev.budget.api.model.converter;

import fr.kksdev.budget.api.enums.Currency;
import jakarta.persistence.Converter;

@Converter
public class CurrencyListConverter extends AbstractEnumListConverter<Currency> {
    public CurrencyListConverter() {
        super(Currency.class);
    }
}
