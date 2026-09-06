package fr.kksdev.budget.api.exception;

public class TokenReusedException extends RuntimeException {

    public TokenReusedException() {
        super("Token reuse detected. All your tokens have been revoked for security.");
    }
}
