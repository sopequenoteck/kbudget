package fr.kksdev.budget.api.config;

import fr.kksdev.budget.api.dto.response.ErrorResponse;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.FeatureDisabledException;
import fr.kksdev.budget.api.exception.TokenExpiredException;
import fr.kksdev.budget.api.exception.TokenInvalidException;
import fr.kksdev.budget.api.exception.TokenReusedException;
import fr.kksdev.budget.api.exception.TokenRevokedException;
import jakarta.persistence.EntityNotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex) {
        log.warn("Bad request: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorBody(
                HttpStatus.BAD_REQUEST.value(),
                ex.getMessage()
        ));
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalState(IllegalStateException ex) {
        log.warn("Bad request (illegal state): {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorBody(
                HttpStatus.BAD_REQUEST.value(),
                ex.getMessage()
        ));
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, Object>> handleAccessDenied(AccessDeniedException ex) {
        log.warn("Access denied: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorBody(
                HttpStatus.FORBIDDEN.value(),
                ex.getMessage()
        ));
    }

    @ExceptionHandler(FeatureDisabledException.class)
    public ResponseEntity<Map<String, Object>> handleFeatureDisabled(FeatureDisabledException ex) {
        log.warn("Feature disabled: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorBody(
                HttpStatus.FORBIDDEN.value(),
                ex.getMessage()
        ));
    }

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<Map<String, Object>> handleConflict(ConflictException ex) {
        log.warn("Conflict: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT).body(errorBody(
                HttpStatus.CONFLICT.value(),
                ex.getMessage()
        ));
    }

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleEntityNotFound(EntityNotFoundException ex) {
        log.warn("Entity not found: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorBody(
                HttpStatus.NOT_FOUND.value(),
                ex.getMessage()
        ));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> handleHttpMessageNotReadable(HttpMessageNotReadableException ex) {
        log.warn("Malformed request: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorBody(
                HttpStatus.BAD_REQUEST.value(),
                "Requête invalide"
        ));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .reduce((a, b) -> a + "; " + b)
                .orElse("Validation error");
        log.warn("Validation failed: {}", message);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorBody(
                HttpStatus.BAD_REQUEST.value(),
                message
        ));
    }

    @ExceptionHandler(TokenExpiredException.class)
    public ResponseEntity<ErrorResponse> handleTokenExpired(TokenExpiredException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(new ErrorResponse("TOKEN_EXPIRED", ex.getMessage()));
    }

    @ExceptionHandler(TokenRevokedException.class)
    public ResponseEntity<ErrorResponse> handleTokenRevoked(TokenRevokedException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(new ErrorResponse("TOKEN_REVOKED", ex.getMessage()));
    }

    @ExceptionHandler(TokenReusedException.class)
    public ResponseEntity<ErrorResponse> handleTokenReused(TokenReusedException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(new ErrorResponse("TOKEN_REUSE_DETECTED", ex.getMessage()));
    }

    @ExceptionHandler(TokenInvalidException.class)
    public ResponseEntity<ErrorResponse> handleTokenInvalid(TokenInvalidException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(new ErrorResponse("TOKEN_INVALID", ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGeneric(Exception ex) {
        log.error("Unexpected error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorBody(
                HttpStatus.INTERNAL_SERVER_ERROR.value(),
                "Une erreur interne est survenue"
        ));
    }

    private Map<String, Object> errorBody(int status, String message) {
        return Map.of(
                "timestamp", LocalDateTime.now().toString(),
                "status", status,
                "message", message
        );
    }
}
