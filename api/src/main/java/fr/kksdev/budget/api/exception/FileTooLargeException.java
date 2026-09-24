package fr.kksdev.budget.api.exception;

public class FileTooLargeException extends RuntimeException {
    public FileTooLargeException() {
        super("Maximum file size is 2 MB.");
    }
}
