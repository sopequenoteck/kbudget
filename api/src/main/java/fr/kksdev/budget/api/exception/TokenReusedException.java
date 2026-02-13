package fr.kksdev.budget.api.exception;

public class TokenReusedException extends RuntimeException {

    public TokenReusedException() {
        super("Réutilisation de token détectée. Tous vos tokens ont été révoqués par sécurité.");
    }
}
