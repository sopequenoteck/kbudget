package fr.kksdev.budget.api.config;

import fr.kksdev.budget.api.dto.response.ErrorResponse;
import fr.kksdev.budget.api.exception.AvatarNotFoundException;
import fr.kksdev.budget.api.exception.ConfirmationRequiredException;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.CsvProfileNotFoundException;
import fr.kksdev.budget.api.exception.FeatureDisabledException;
import fr.kksdev.budget.api.exception.FileTooLargeException;
import fr.kksdev.budget.api.exception.InvalidExportFormatException;
import fr.kksdev.budget.api.exception.InvalidImageFormatException;
import fr.kksdev.budget.api.exception.LastAdminDeletionForbiddenException;
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

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> handleIllegalArgument(IllegalArgumentException ex) {
        log.warn("Bad request: {}", ex.getMessage());
        return error(HttpStatus.BAD_REQUEST, "BAD_REQUEST", ex.getMessage(), "Requete invalide");
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<ErrorResponse> handleIllegalState(IllegalStateException ex) {
        log.warn("Bad request (illegal state): {}", ex.getMessage());
        return error(HttpStatus.BAD_REQUEST, "BAD_REQUEST", ex.getMessage(), "Requete invalide");
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDenied(AccessDeniedException ex) {
        log.warn("Access denied: {}", ex.getMessage());
        return error(HttpStatus.FORBIDDEN, "ACCESS_DENIED", ex.getMessage(), "Acces refuse");
    }

    @ExceptionHandler(FeatureDisabledException.class)
    public ResponseEntity<ErrorResponse> handleFeatureDisabled(FeatureDisabledException ex) {
        log.warn("Feature disabled: {}", ex.getMessage());
        return error(HttpStatus.FORBIDDEN, "FEATURE_DISABLED", ex.getMessage(), "Fonctionnalite desactivee");
    }

    @ExceptionHandler(CsvProfileNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleCsvProfileNotFound(CsvProfileNotFoundException ex) {
        log.warn("CSV profile not found: {}", ex.getMessage());
        return error(HttpStatus.UNPROCESSABLE_ENTITY, "CSV_PROFILE_NOT_FOUND", ex.getMessage(),
                "Profil CSV introuvable");
    }

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<ErrorResponse> handleConflict(ConflictException ex) {
        log.warn("Conflict: {}", ex.getMessage());
        String code = isSpecializedConflict(ex.getMessage()) ? ex.getMessage() : "CONFLICT";
        return error(HttpStatus.CONFLICT, code, resolveConflictMessage(ex.getMessage()), "Conflit de donnees");
    }

    private boolean isSpecializedConflict(String value) {
        return "LAST_ADMIN_CANNOT_BE_DISABLED".equals(value) || "EMAIL_ALREADY_EXISTS".equals(value);
    }

    private String resolveConflictMessage(String errorCode) {
        return switch (errorCode == null ? "" : errorCode) {
            case "LAST_ADMIN_CANNOT_BE_DISABLED" -> "Impossible de désactiver le dernier admin actif.";
            case "EMAIL_ALREADY_EXISTS" -> "Cet email est déjà utilisé par un autre utilisateur.";
            default -> errorCode;
        };
    }

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleEntityNotFound(EntityNotFoundException ex) {
        log.warn("Entity not found: {}", ex.getMessage());
        return error(HttpStatus.NOT_FOUND, "NOT_FOUND", ex.getMessage(), "Ressource introuvable");
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleHttpMessageNotReadable(HttpMessageNotReadableException ex) {
        log.warn("Malformed request: {}", ex.getMessage());
        return error(HttpStatus.BAD_REQUEST, "MALFORMED_REQUEST", "Requete invalide", "Requete invalide");
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .reduce((a, b) -> a + "; " + b)
                .orElse("Validation error");
        log.warn("Validation failed: {}", message);
        return error(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", message, "Requete invalide");
    }

    @ExceptionHandler(InvalidImageFormatException.class)
    public ResponseEntity<ErrorResponse> handleInvalidImageFormat(InvalidImageFormatException ex) {
        log.warn("Invalid image format: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse("INVALID_IMAGE_FORMAT", nonBlank(ex.getMessage(), "Format d'image invalide")));
    }

    @ExceptionHandler(FileTooLargeException.class)
    public ResponseEntity<ErrorResponse> handleFileTooLarge(FileTooLargeException ex) {
        log.warn("File too large: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE)
                .body(new ErrorResponse("FILE_TOO_LARGE", nonBlank(ex.getMessage(), "Fichier trop volumineux")));
    }

    @ExceptionHandler(AvatarNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleAvatarNotFound(AvatarNotFoundException ex) {
        log.warn("Avatar not found: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ErrorResponse("AVATAR_NOT_FOUND", nonBlank(ex.getMessage(), "Avatar introuvable")));
    }

    @ExceptionHandler(PasswordIncorrectException.class)
    public ResponseEntity<ErrorResponse> handlePasswordIncorrect(PasswordIncorrectException ex) {
        log.warn("Password incorrect: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(new ErrorResponse("PASSWORD_INCORRECT", ex.getMessage()));
    }

    @ExceptionHandler(InvalidExportFormatException.class)
    public ResponseEntity<ErrorResponse> handleInvalidExportFormat(InvalidExportFormatException ex) {
        log.warn("Invalid export format: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse("INVALID_EXPORT_FORMAT", ex.getMessage()));
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

    @ExceptionHandler(ConfirmationRequiredException.class)
    public ResponseEntity<ErrorResponse> handleConfirmationRequired(ConfirmationRequiredException ex) {
        log.warn("Confirmation required: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse("CONFIRMATION_REQUIRED", ex.getMessage()));
    }

    @ExceptionHandler(LastAdminDeletionForbiddenException.class)
    public ResponseEntity<ErrorResponse> handleLastAdminDeletionForbidden(LastAdminDeletionForbiddenException ex) {
        log.warn("Last admin deletion forbidden: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(new ErrorResponse("LAST_ADMIN_DELETION_FORBIDDEN", ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(Exception ex) {
        log.error("Unexpected error", ex);
        return error(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                "Une erreur interne est survenue", "Une erreur interne est survenue");
    }

    private ResponseEntity<ErrorResponse> error(HttpStatus status, String code, String message, String fallback) {
        return ResponseEntity.status(status).body(new ErrorResponse(code, nonBlank(message, fallback)));
    }

    private String nonBlank(String message, String fallback) {
        return message == null || message.isBlank() ? fallback : message;
    }
}
