package fr.kksdev.budget.api.model.converter;

import fr.kksdev.budget.api.enums.Feature;
import jakarta.persistence.Converter;

@Converter
public class FeatureListConverter extends AbstractEnumListConverter<Feature> {
    public FeatureListConverter() {
        super(Feature.class);
    }
}
