package fr.kksdev.budget.api.exception;

public class FeatureDisabledException extends RuntimeException {

    private final String featureName;

    public FeatureDisabledException(String featureName) {
        super("Fonctionnalité " + featureName + " désactivée");
        this.featureName = featureName;
    }

    public String getFeatureName() {
        return featureName;
    }
}
