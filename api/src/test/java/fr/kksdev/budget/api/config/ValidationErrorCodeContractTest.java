package fr.kksdev.budget.api.config;

import fr.kksdev.budget.api.dto.request.AcceptInviteRequest;
import fr.kksdev.budget.api.dto.request.FirstLoginResetRequest;
import fr.kksdev.budget.api.dto.response.ErrorResponse;
import fr.kksdev.budget.api.dto.response.ValidationErrorDetail;
import fr.kksdev.budget.api.enums.Currency;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.BindingResult;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verrouille les valeurs de {@code details[].code} sur la chaine Bean
 * Validation reelle (KKS-357).
 *
 * <p>Les clients ne lisent pas le {@code message}, ils branchent sur le couple
 * {@code field} / {@code code} : {@code auth.ts} cherche
 * {@code field == "password" && code == "SIZE"} pour traduire l'erreur, et
 * afficherait sinon le texte anglais brut de Bean Validation — ce que KKS-351
 * avait precisement supprime.
 *
 * <p><strong>Ces codes ne sont ecrits nulle part.</strong>
 * {@link GlobalExceptionHandler} les derive du nom de l'annotation qui a
 * echoue : {@code @Size} donne {@code SIZE}, {@code @NotNull} donne
 * {@code NOT_NULL}. Remplacer {@code @Size(min = 12)} par
 * {@code @Length(min = 12)} ne touche aucun DTO expose, ne change aucune
 * signature et n'a aucune raison d'attirer l'attention en revue — mais le code
 * servi devient {@code LENGTH} et le client cesse de reconnaitre l'erreur.
 *
 * <p>D'ou le choix de partir des DTOs reels et du validateur reel plutot que
 * d'un {@code FieldError} construit a la main, comme le fait
 * {@code GlobalExceptionHandlerTest} : un {@code FieldError} fabrique porte le
 * code qu'on lui donne, donc il verifie la normalisation en majuscules, jamais
 * le nom d'annotation dont elle part.
 */
class ValidationErrorCodeContractTest {

    private static final String PASSWORD_FIELD = "password";
    private static final String VALID_PASSWORD = "motdepasse-assez-long";
    private static final String DISPLAY_NAME = "Utilisateur";

    private static LocalValidatorFactoryBean validator;

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @BeforeAll
    static void startValidator() {
        validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();
    }

    @AfterAll
    static void stopValidator() {
        validator.close();
    }

    @Test
    void should_return_size_code_when_password_is_shorter_than_the_policy() {
        var request = new FirstLoginResetRequest("user@local.test", "trop-court", DISPLAY_NAME);

        assertThat(codeFor(request, PASSWORD_FIELD)).isEqualTo("SIZE");
    }

    @Test
    void should_return_not_blank_code_when_password_is_empty() {
        var request = new FirstLoginResetRequest("user@local.test", "", DISPLAY_NAME);

        assertThat(codesFor(request, PASSWORD_FIELD)).contains("NOT_BLANK");
    }

    @Test
    void should_return_not_null_code_when_invitation_token_is_missing() {
        var request = new AcceptInviteRequest(null, VALID_PASSWORD, DISPLAY_NAME, Currency.EUR, "Europe/Paris");

        assertThat(codeFor(request, "token")).isEqualTo("NOT_NULL");
    }

    @Test
    void should_return_email_code_when_email_is_malformed() {
        var request = new FirstLoginResetRequest("pas-un-email", VALID_PASSWORD, DISPLAY_NAME);

        assertThat(codeFor(request, "email")).isEqualTo("EMAIL");
    }

    /**
     * Le champ porte le nom de la propriete du DTO, pas un chemin technique :
     * c'est ce nom que le client compare.
     */
    @Test
    void should_name_the_failing_field_after_the_dto_property() {
        var request = new AcceptInviteRequest(UUID.randomUUID(), "court", DISPLAY_NAME, Currency.EUR, "Europe/Paris");

        assertThat(validate(request).details())
                .extracting(ValidationErrorDetail::field)
                .containsOnly(PASSWORD_FIELD);
    }

    // ------------------------------------------------------------------
    // Chaine reelle : validateur -> BindingResult -> handler -> reponse
    // ------------------------------------------------------------------

    private ErrorResponse validate(Object request) {
        BindingResult bindingResult = new BeanPropertyBindingResult(request, "request");
        validator.validate(request, bindingResult);

        ErrorResponse body = handler.handleValidation(
                new MethodArgumentNotValidException(null, bindingResult)).getBody();
        assertThat(body).isNotNull();
        return body;
    }

    private String codeFor(Object request, String field) {
        var codes = codesFor(request, field);
        assertThat(codes).as("aucune violation sur le champ %s", field).isNotEmpty();
        return codes.getFirst();
    }

    private List<String> codesFor(Object request, String field) {
        return validate(request).details().stream()
                .filter(detail -> field.equals(detail.field()))
                .map(ValidationErrorDetail::code)
                .toList();
    }
}
