package fr.kksdev.budget.api.exception;

public class InvalidExportFormatException extends RuntimeException {
    public InvalidExportFormatException() {
        super("Format d'export invalide. Formats acceptés : json, csv.");
    }
}
