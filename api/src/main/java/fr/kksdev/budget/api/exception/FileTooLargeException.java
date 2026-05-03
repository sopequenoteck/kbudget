package fr.kksdev.budget.api.exception;

public class FileTooLargeException extends RuntimeException {
    public FileTooLargeException() {
        super("La taille maximale est 2 MB.");
    }
}
