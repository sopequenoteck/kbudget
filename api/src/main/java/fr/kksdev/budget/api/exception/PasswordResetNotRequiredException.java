package fr.kksdev.budget.api.exception;

public class PasswordResetNotRequiredException extends RuntimeException {
    public PasswordResetNotRequiredException() {
        super("Credentials reset is not required for this user.");
    }
}
