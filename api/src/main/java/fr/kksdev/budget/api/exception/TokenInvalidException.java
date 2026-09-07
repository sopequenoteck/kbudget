package fr.kksdev.budget.api.exception;

public class TokenInvalidException extends RuntimeException {

    public TokenInvalidException() {
        super("Invalid refresh token.");
    }
}
