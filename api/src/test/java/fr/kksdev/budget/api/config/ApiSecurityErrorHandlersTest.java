package fr.kksdev.budget.api.config;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.InsufficientAuthenticationException;

import static org.assertj.core.api.Assertions.assertThat;

class ApiSecurityErrorHandlersTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final ApiErrorWriter writer = new ApiErrorWriter(objectMapper);

    @Test
    void should_return_unified_401() throws Exception {
        var response = new MockHttpServletResponse();
        var handler = new ApiAuthenticationEntryPoint(writer);

        handler.commence(new MockHttpServletRequest(), response,
                new InsufficientAuthenticationException("internal detail"));

        assertError(response, 401, "UNAUTHENTICATED", "Authentification requise");
    }

    @Test
    void should_return_unified_403() throws Exception {
        var response = new MockHttpServletResponse();
        var handler = new ApiAccessDeniedHandler(writer);

        handler.handle(new MockHttpServletRequest(), response, new AccessDeniedException("internal detail"));

        assertError(response, 403, "ACCESS_DENIED", "Accès refusé");
    }

    private void assertError(MockHttpServletResponse response, int status, String code, String message)
            throws Exception {
        assertThat(response.getStatus()).isEqualTo(status);
        JsonNode body = objectMapper.readTree(response.getContentAsByteArray());
        assertThat(body.get("error").asText()).isEqualTo(code);
        assertThat(body.get("message").asText()).isEqualTo(message);
        assertThat(body.size()).isEqualTo(2);
        assertThat(response.getContentAsString()).doesNotContain("internal detail");
    }
}
