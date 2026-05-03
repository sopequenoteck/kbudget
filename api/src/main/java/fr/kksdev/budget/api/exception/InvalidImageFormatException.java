package fr.kksdev.budget.api.exception;

public class InvalidImageFormatException extends RuntimeException {
    public InvalidImageFormatException() {
        super("Seuls les formats JPG et PNG sont acceptés.");
    }
}
