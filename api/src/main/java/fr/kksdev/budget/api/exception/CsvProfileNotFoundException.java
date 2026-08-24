package fr.kksdev.budget.api.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.UNPROCESSABLE_CONTENT)
public class CsvProfileNotFoundException extends RuntimeException {
    public CsvProfileNotFoundException(String message) {
        super(message);
    }
}
