package fr.kksdev.budget.api.exception;

public class LastAdminDeletionForbiddenException extends RuntimeException {
    public LastAdminDeletionForbiddenException() {
        super("At least one active administrator must remain.");
    }
}
