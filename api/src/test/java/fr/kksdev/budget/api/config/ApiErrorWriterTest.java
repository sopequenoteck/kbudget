package fr.kksdev.budget.api.config;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.assertj.core.api.Assertions.assertThat;

class ApiErrorWriterTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final ApiErrorWriter writer = new ApiErrorWriter(objectMapper);

    @Test
    void should_write_the_unified_error_contract() throws Exception {
        var response = new MockHttpServletResponse();

        writer.write(response, HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Authentification requise");

        assertThat(response.getStatus()).isEqualTo(401);
        assertThat(response.getContentType()).startsWith(MediaType.APPLICATION_JSON_VALUE);
        assertThat(response.getCharacterEncoding()).isEqualTo("UTF-8");

        JsonNode body = objectMapper.readTree(response.getContentAsByteArray());
        assertThat(body.get("error").asText()).isEqualTo("UNAUTHENTICATED");
        assertThat(body.get("message").asText()).isEqualTo("Authentification requise");
        assertThat(body.size()).isEqualTo(2);
    }
}
