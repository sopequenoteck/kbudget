package fr.kksdev.budget.api.exception;

public class InvalidExportFormatException extends RuntimeException {
    public InvalidExportFormatException() {
        super("Invalid export format. Accepted formats: json, csv.");
    }
}
