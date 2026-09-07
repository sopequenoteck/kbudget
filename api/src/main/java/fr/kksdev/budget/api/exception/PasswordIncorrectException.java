package fr.kksdev.budget.api.exception;

public class PasswordIncorrectException extends RuntimeException {
    public PasswordIncorrectException() {
        super("Incorrect password.");
    }
}
