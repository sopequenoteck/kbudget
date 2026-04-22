package fr.kksdev.budget.api.exception;

public class PasswordUnchangedException extends RuntimeException {
    public PasswordUnchangedException() {
        super("Le nouveau mot de passe doit être différent de l'actuel.");
    }
}
