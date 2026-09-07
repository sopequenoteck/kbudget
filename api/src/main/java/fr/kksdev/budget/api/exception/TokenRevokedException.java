package fr.kksdev.budget.api.exception;

public class TokenRevokedException extends RuntimeException {

    public TokenRevokedException() {
        super("The refresh token has been revoked.");
    }
}
