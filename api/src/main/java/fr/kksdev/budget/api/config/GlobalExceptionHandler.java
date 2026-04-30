package fr.kksdev.budget.api.config;

import fr.kksdev.budget.api.dto.response.ErrorResponse;
import fr.kksdev.budget.api.exception.AvatarNotFoundException;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.CsvProfileNotFoundException;
import fr.kksdev.budget.api.exception.FeatureDisabledException;
import fr.kksdev.budget.api.exception.FileTooLargeException;
import fr.kksdev.budget.api.exception.InvalidImageFormatException;
import fr.kksdev.budget.api.exception.PasswordIncorrectException;
import fr.kksdev.budget.api.exception.PasswordResetNotRequiredException;
import fr.kksdev.budget.api.exception.PasswordUnchangedException;
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

    @ExceptionHandler(CsvProfileNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleCsvProfileNotFound(CsvProfileNotFoundException ex) {
        log.warn("CSV profile not found: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(errorBody(
                HttpStatus.UNPROCESSABLE_ENTITY.value(),
                ex.getMessage()
        ));
    }

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<Map<String, Object>> handleConflict(ConflictException ex) {
        log.warn("Conflict: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                "timestamp", LocalDateTime.now().toString(),
                "status", HttpStatus.CONFLICT.value(),
                "error", ex.getMessage(),
                "message", resolveConflictMessage(ex.getMessage())
        ));
    }

    private String resolveConflictMessage(String errorCode) {
        return switch (errorCode) {
            case "LAST_ADMIN_CANNOT_BE_DISABLED" -> "Impossible de désactiver le dernier admin actif.";
            case "EMAIL_ALREADY_EXISTS" -> "Cet email est déjà utilisé par un autre utilisateur.";
            default -> errorCode;
        };
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

    @ExceptionHandler(InvalidImageFormatException.class)
    public ResponseEntity<ErrorResponse> handleInvalidImageFormat(InvalidImageFormatException ex) {
        log.warn("Invalid image format: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse("INVALID_IMAGE_FORMAT", ex.getMessage()));
    }

    @ExceptionHandler(FileTooLargeException.class)
    public ResponseEntity<ErrorResponse> handleFileTooLarge(FileTooLargeException ex) {
        log.warn("File too large: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE)
                .body(new ErrorResponse("FILE_TOO_LARGE", ex.getMessage()));
    }

    @ExceptionHandler(AvatarNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleAvatarNotFound(AvatarNotFoundException ex) {
        log.warn("Avatar not found: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ErrorResponse("AVATAR_NOT_FOUND", ex.getMessage()));
    }

    @ExceptionHandler(PasswordIncorrectException.class)
    public ResponseEntity<ErrorResponse> handlePasswordIncorrect(PasswordIncorrectException ex) {
        log.warn("Password incorrect: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(new ErrorResponse("PASSWORD_INCORRECT", ex.getMessage()));
    }

    @ExceptionHandler(PasswordUnchangedException.class)
    public ResponseEntity<ErrorResponse> handlePasswordUnchanged(PasswordUnchangedException ex) {
        log.warn("Password unchanged: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse("PASSWORD_UNCHANGED", ex.getMessage()));
    }

    @ExceptionHandler(PasswordResetNotRequiredException.class)
    public ResponseEntity<ErrorResponse> handlePasswordResetNotRequired(PasswordResetNotRequiredException ex) {
        log.warn("Password reset not required: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(new ErrorResponse("PASSWORD_RESET_NOT_REQUIRED", ex.getMessage()));
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
