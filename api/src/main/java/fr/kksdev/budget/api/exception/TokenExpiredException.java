package fr.kksdev.budget.api.exception;

public class TokenExpiredException extends RuntimeException {

    public TokenExpiredException() {
        super("The refresh token has expired. Please sign in again.");
    }
}
