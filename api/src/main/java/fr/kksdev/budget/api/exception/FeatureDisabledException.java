package fr.kksdev.budget.api.exception;

public class FeatureDisabledException extends RuntimeException {

    private final String featureName;

    public FeatureDisabledException(String featureName) {
        super("Feature " + featureName + " is disabled");
        this.featureName = featureName;
    }

    public String getFeatureName() {
        return featureName;
    }
}
