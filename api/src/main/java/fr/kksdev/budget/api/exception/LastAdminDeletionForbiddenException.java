package fr.kksdev.budget.api.exception;

public class LastAdminDeletionForbiddenException extends RuntimeException {
    public LastAdminDeletionForbiddenException() {
        super("Au moins un administrateur actif doit exister.");
    }
}
