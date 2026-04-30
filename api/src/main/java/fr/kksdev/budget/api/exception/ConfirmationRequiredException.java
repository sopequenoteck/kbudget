package fr.kksdev.budget.api.exception;

public class ConfirmationRequiredException extends RuntimeException {
    public ConfirmationRequiredException() {
        super("Confirmation explicite requise.");
    }
}
