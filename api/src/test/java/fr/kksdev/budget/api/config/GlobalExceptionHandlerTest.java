package fr.kksdev.budget.api.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.dto.response.ErrorResponse;
import fr.kksdev.budget.api.exception.*;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpInputMessage;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void should_return_stable_codes_for_generic_handlers() {
        assertResponse(handler.handleIllegalArgument(new IllegalArgumentException("Argument invalide")), 400,
                "BAD_REQUEST", "Argument invalide");
        assertResponse(handler.handleIllegalState(new IllegalStateException("Etat invalide")), 400,
                "BAD_REQUEST", "Etat invalide");
        assertResponse(handler.handleAccessDenied(new AccessDeniedException("Acces interdit")), 403,
                "ACCESS_DENIED", "Acces interdit");
        assertResponse(handler.handleFeatureDisabled(new FeatureDisabledException("DEBTS")), 403,
                "FEATURE_DISABLED", "Fonctionnalité DEBTS désactivée");
        assertResponse(handler.handleCsvProfileNotFound(new CsvProfileNotFoundException("Profil absent")), 422,
                "CSV_PROFILE_NOT_FOUND", "Profil absent");
        assertResponse(handler.handleEntityNotFound(new EntityNotFoundException("Transaction non trouvée")), 404,
                "NOT_FOUND", "Transaction non trouvée");
        assertResponse(handler.handleHttpMessageNotReadable(
                        new HttpMessageNotReadableException("technical parser detail", (HttpInputMessage) null)), 400,
                "MALFORMED_REQUEST", "Requete invalide");
    }

    @Test
    void should_return_404_when_route_is_not_mapped() {
        assertResponse(handler.handleNoResourceFound(
                        new NoResourceFoundException(HttpMethod.GET, "/api/route-inconnue", "/route-inconnue")),
                404, "NOT_FOUND", "Ressource introuvable");
    }

    @Test
    void should_return_all_validation_messages() {
        var bindingResult = new BeanPropertyBindingResult(new Object(), "request");
        bindingResult.addError(new FieldError("request", "montant", null, false,
                new String[]{"NotNull"}, null, "must not be null"));
        bindingResult.addError(new FieldError("request", "libelle", "", false,
                new String[]{"NotBlank"}, null, "must not be blank"));

        var response = handler.handleValidation(new MethodArgumentNotValidException(null, bindingResult));

        assertThat(response.getStatusCode().value()).isEqualTo(400);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().error()).isEqualTo("VALIDATION_ERROR");
        assertThat(response.getBody().message())
                .isEqualTo("montant: must not be null; libelle: must not be blank");
        assertThat(response.getBody().details()).containsExactly(
                new fr.kksdev.budget.api.dto.response.ValidationErrorDetail(
                        "montant", "NOT_NULL", "must not be null"),
                new fr.kksdev.budget.api.dto.response.ValidationErrorDetail(
                        "libelle", "NOT_BLANK", "must not be blank")
        );
        assertThat(objectMapper.valueToTree(response.getBody()).fieldNames()).toIterable()
                .containsExactlyInAnyOrder("error", "message", "details");
    }

    @Test
    void should_preserve_specialized_conflicts_and_normalize_other_conflicts() {
        assertResponse(handler.handleConflict(new ConflictException("LAST_ADMIN_CANNOT_BE_DISABLED")), 409,
                "LAST_ADMIN_CANNOT_BE_DISABLED", "Impossible de désactiver le dernier admin actif.");
        assertResponse(handler.handleConflict(new ConflictException("EMAIL_ALREADY_EXISTS")), 409,
                "EMAIL_ALREADY_EXISTS", "Cet email est déjà utilisé par un autre utilisateur.");
        assertResponse(handler.handleConflict(new ConflictException("Un import est deja actif")), 409,
                "CONFLICT", "Un import est deja actif");
        assertResponse(handler.handleConflict(new ConflictException(null)), 409,
                "CONFLICT", "Conflit de donnees");
        assertResponse(handler.handleConflict(new ConflictException("  ")), 409,
                "CONFLICT", "Conflit de donnees");
    }

    @Test
    void should_preserve_specialized_error_contracts() {
        List<ResponseEntity<ErrorResponse>> responses = List.of(
                handler.handleInvalidImageFormat(new InvalidImageFormatException()),
                handler.handleFileTooLarge(new FileTooLargeException()),
                handler.handleAvatarNotFound(new AvatarNotFoundException()),
                handler.handlePasswordIncorrect(new PasswordIncorrectException()),
                handler.handleInvalidExportFormat(new InvalidExportFormatException()),
                handler.handlePasswordUnchanged(new PasswordUnchangedException()),
                handler.handlePasswordResetNotRequired(new PasswordResetNotRequiredException()),
                handler.handleTokenExpired(new TokenExpiredException()),
                handler.handleTokenRevoked(new TokenRevokedException()),
                handler.handleTokenReused(new TokenReusedException()),
                handler.handleTokenInvalid(new TokenInvalidException()),
                handler.handleConfirmationRequired(new ConfirmationRequiredException()),
                handler.handleLastAdminDeletionForbidden(new LastAdminDeletionForbiddenException())
        );
        List<String> codes = List.of("INVALID_IMAGE_FORMAT", "FILE_TOO_LARGE", "AVATAR_NOT_FOUND",
                "PASSWORD_INCORRECT", "INVALID_EXPORT_FORMAT", "PASSWORD_UNCHANGED",
                "PASSWORD_RESET_NOT_REQUIRED", "TOKEN_EXPIRED", "TOKEN_REVOKED", "TOKEN_REUSE_DETECTED",
                "TOKEN_INVALID", "CONFIRMATION_REQUIRED", "LAST_ADMIN_DELETION_FORBIDDEN");

        for (int i = 0; i < responses.size(); i++) {
            assertThat(responses.get(i).getBody()).isNotNull();
            assertThat(responses.get(i).getBody().error()).isEqualTo(codes.get(i));
            assertThat(responses.get(i).getBody().message()).isNotBlank();
            assertOnlyPublicFields(responses.get(i).getBody());
        }
    }

    @Test
    void should_use_non_blank_public_fallbacks() {
        assertResponse(handler.handleIllegalArgument(new IllegalArgumentException((String) null)), 400,
                "BAD_REQUEST", "Requete invalide");
        assertResponse(handler.handleEntityNotFound(new EntityNotFoundException(" ")), 404,
                "NOT_FOUND", "Ressource introuvable");
    }

    @Test
    void should_hide_internal_details_when_unexpected_error() {
        var exception = new RuntimeException("JdbcInternalClass SELECT secret FROM users",
                new IllegalStateException("stack-marker"));

        var response = handler.handleGeneric(exception);

        assertResponse(response, HttpStatus.INTERNAL_SERVER_ERROR.value(), "INTERNAL_ERROR",
                "Une erreur interne est survenue");
        assertThat(response.getBody().message()).doesNotContain("JdbcInternalClass", "SELECT", "stack-marker");
    }

    private void assertResponse(ResponseEntity<ErrorResponse> response, int status, String code, String message) {
        assertThat(response.getStatusCode().value()).isEqualTo(status);
        assertThat(response.getBody()).isEqualTo(new ErrorResponse(code, message));
        assertOnlyPublicFields(response.getBody());
    }

    private void assertOnlyPublicFields(ErrorResponse body) {
        assertThat(body).isNotNull();
        assertThat(body.error()).isNotBlank();
        assertThat(body.message()).isNotBlank();
        assertThat(objectMapper.valueToTree(body).fieldNames()).toIterable()
                .containsExactlyInAnyOrder("error", "message");
        assertThat(objectMapper.valueToTree(body).has("timestamp")).isFalse();
        assertThat(objectMapper.valueToTree(body).has("status")).isFalse();
    }
}
