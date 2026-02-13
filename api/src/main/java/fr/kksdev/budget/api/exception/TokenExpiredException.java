package fr.kksdev.budget.api.exception;

public class TokenExpiredException extends RuntimeException {

    public TokenExpiredException() {
        super("Le refresh token a expiré. Veuillez vous reconnecter.");
    }
}
