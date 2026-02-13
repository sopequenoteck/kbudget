package fr.kksdev.budget.api.exception;

public class TokenRevokedException extends RuntimeException {

    public TokenRevokedException() {
        super("Le refresh token a été révoqué.");
    }
}
