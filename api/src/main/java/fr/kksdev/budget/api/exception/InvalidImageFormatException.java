package fr.kksdev.budget.api.exception;

public class InvalidImageFormatException extends RuntimeException {
    public InvalidImageFormatException() {
        super("Only JPG and PNG formats are accepted.");
    }
}
