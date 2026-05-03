package fr.kksdev.budget.api.exception;

public class PasswordIncorrectException extends RuntimeException {
    public PasswordIncorrectException() {
        super("Mot de passe incorrect.");
    }
}
