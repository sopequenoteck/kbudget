package fr.kksdev.budget.api.exception;

public class PasswordResetNotRequiredException extends RuntimeException {
    public PasswordResetNotRequiredException() {
        super("Le reset des credentials n'est pas requis pour cet utilisateur.");
    }
}
