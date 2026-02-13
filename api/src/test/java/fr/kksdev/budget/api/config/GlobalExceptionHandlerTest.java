package fr.kksdev.budget.api.config;

import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void should_return_400_when_illegal_argument() {
        var ex = new IllegalArgumentException("Email déjà utilisé");

        var response = handler.handleIllegalArgument(ex);

        assertThat(response.getStatusCode().value()).isEqualTo(HttpStatus.BAD_REQUEST.value());
        assertThat(response.getBody()).containsEntry("status", 400);
        assertThat(response.getBody()).containsEntry("message", "Email déjà utilisé");
        assertThat(response.getBody()).containsKey("timestamp");
    }

    @Test
    void should_return_404_when_entity_not_found() {
        var ex = new EntityNotFoundException("Transaction non trouvée");

        var response = handler.handleEntityNotFound(ex);

        assertThat(response.getStatusCode().value()).isEqualTo(HttpStatus.NOT_FOUND.value());
        assertThat(response.getBody()).containsEntry("status", 404);
        assertThat(response.getBody()).containsEntry("message", "Transaction non trouvée");
    }

    @Test
    void should_return_400_when_validation_fails() {
        var bindingResult = new BeanPropertyBindingResult(new Object(), "request");
        bindingResult.addError(new FieldError("request", "montant", "must not be null"));
        bindingResult.addError(new FieldError("request", "libelle", "must not be blank"));
        var ex = new MethodArgumentNotValidException(null, bindingResult);

        var response = handler.handleValidation(ex);

        assertThat(response.getStatusCode().value()).isEqualTo(HttpStatus.BAD_REQUEST.value());
        assertThat(response.getBody()).containsEntry("status", 400);
        assert response.getBody() != null;
        String message = (String) response.getBody().get("message");
        assertThat(message).contains("montant").contains("libelle");
    }

    @Test
    void should_return_500_when_unexpected_error() {
        var ex = new RuntimeException("Something went wrong");

        var response = handler.handleGeneric(ex);

        assertThat(response.getStatusCode().value()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR.value());
        assertThat(response.getBody()).containsEntry("status", 500);
        assertThat(response.getBody()).containsEntry("message", "Une erreur interne est survenue");
    }

    @SuppressWarnings("unchecked")
    @Test
    void should_include_timestamp_in_all_error_responses() {
        var responses = new Map[]{
                handler.handleIllegalArgument(new IllegalArgumentException("test")).getBody(),
                handler.handleEntityNotFound(new EntityNotFoundException("test")).getBody(),
                handler.handleGeneric(new RuntimeException("test")).getBody()
        };

        for (var body : responses) {
            assertThat(body).containsKey("timestamp");
        }
    }
}
