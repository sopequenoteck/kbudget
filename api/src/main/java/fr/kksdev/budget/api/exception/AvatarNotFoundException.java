package fr.kksdev.budget.api.exception;

public class AvatarNotFoundException extends RuntimeException {
    public AvatarNotFoundException() {
        super("Avatar non trouvé.");
    }
}
