package fr.kksdev.budget.api.config;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Limitation de debit sur les endpoints d'authentification (KKS-310).
 *
 * <p>Capacite ramenee a 3 pour garder les tests lisibles ; la fenetre reste
 * large pour qu'aucun rechargement de jeton ne survienne pendant l'execution.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "app.security.rate-limit.capacity=3",
        "app.security.rate-limit.window-seconds=3600",
        "app.security.trusted-proxies=127.0.0.1"
})
class RateLimitIT {

    @Autowired
    private MockMvc mockMvc;

    private static final String BAD_LOGIN = """
            {"email":"absent@mail.com","password":"wrong"}""";

    @Test
    void should_reject_with_429_and_unified_error_contract_when_limit_exceeded() throws Exception {
        String ip = "203.0.113.10";

        for (int i = 0; i < 3; i++) {
            mockMvc.perform(post("/v1/auth/login").with(r -> { r.setRemoteAddr(ip); return r; })
                            .contentType(MediaType.APPLICATION_JSON).content(BAD_LOGIN))
                    .andExpect(status().is4xxClientError());
        }

        mockMvc.perform(post("/v1/auth/login").with(r -> { r.setRemoteAddr(ip); return r; })
                        .contentType(MediaType.APPLICATION_JSON).content(BAD_LOGIN))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.error").value("TOO_MANY_REQUESTS"))
                .andExpect(jsonPath("$.message").exists());
    }

    @Test
    void should_log_the_ip_and_mask_the_invitation_token_when_an_invitation_request_is_rate_limited()
            throws Exception {
        String ip = "203.0.113.90";
        String token = "7f3c9a2e-5b1d-4e8a-9c6f-0d2b8a4e1f37";
        Logger filterLogger = (Logger) LoggerFactory.getLogger(RateLimitFilter.class);
        ListAppender<ILoggingEvent> logAppender = new ListAppender<>();
        logAppender.start();
        filterLogger.addAppender(logAppender);
        try {
            for (int i = 0; i < 4; i++) {
                mockMvc.perform(get("/v1/auth/invitations/" + token).with(r -> { r.setRemoteAddr(ip); return r; }));
            }
        } finally {
            filterLogger.detachAppender(logAppender);
        }

        List<String> messages = logAppender.list.stream().map(ILoggingEvent::getFormattedMessage).toList();
        assertThat(messages)
                .containsExactly("Rate limit exceeded: ip=" + ip + " path=/v1/auth/invitations/***")
                .noneMatch(message -> message.contains(token));
    }

    @Test
    void should_count_separately_per_ip() throws Exception {
        // Une IP epuisee ne doit pas bloquer les autres : sinon un seul
        // attaquant coupe le service a tout le monde.
        String attacker = "203.0.113.20";
        for (int i = 0; i < 4; i++) {
            mockMvc.perform(post("/v1/auth/login").with(r -> { r.setRemoteAddr(attacker); return r; })
                    .contentType(MediaType.APPLICATION_JSON).content(BAD_LOGIN));
        }

        mockMvc.perform(post("/v1/auth/login").with(r -> { r.setRemoteAddr("203.0.113.21"); return r; })
                        .contentType(MediaType.APPLICATION_JSON).content(BAD_LOGIN))
                // Le code exact importe peu (401 ou 400 selon la validation) :
                // ce qui compte est que ce ne soit pas 429.
                .andExpect(result -> assertThat(result.getResponse().getStatus())
                        .as("la seconde IP ne doit pas heriter du quota de la premiere")
                        .isNotEqualTo(429));
    }

    @Test
    void should_not_limit_endpoints_outside_the_protected_set() throws Exception {
        // /actuator/health n'est pas concerne : le healthcheck Docker
        // l'interroge en boucle.
        String ip = "203.0.113.30";
        for (int i = 0; i < 10; i++) {
            mockMvc.perform(get("/actuator/health").with(r -> { r.setRemoteAddr(ip); return r; }))
                    .andExpect(status().isOk());
        }
    }

    @Test
    void should_protect_invitation_lookup_despite_variable_token() throws Exception {
        // /auth/invitations/{token} permettrait d'enumerer des jetons. Le token
        // variant a chaque tentative, la protection doit porter sur le prefixe.
        String ip = "203.0.113.40";

        for (int i = 0; i < 3; i++) {
            final int n = i;
            mockMvc.perform(get("/v1/auth/invitations/token-" + n)
                    .with(r -> { r.setRemoteAddr(ip); return r; }));
        }

        mockMvc.perform(get("/v1/auth/invitations/token-99")
                        .with(r -> { r.setRemoteAddr(ip); return r; }))
                .andExpect(status().isTooManyRequests());
    }

    @Test
    void should_not_let_forged_header_bypass_the_limit() throws Exception {
        // La requete vient d'une IP non fiable : X-Forwarded-For est ignore.
        // Sans cette propriete, varier l'en-tete donnerait un quota neuf a
        // chaque tentative et la limitation serait decorative.
        String realIp = "203.0.113.50";

        for (int i = 0; i < 3; i++) {
            final int n = i;
            mockMvc.perform(post("/v1/auth/login")
                    .with(r -> { r.setRemoteAddr(realIp); return r; })
                    .header("X-Forwarded-For", "10.9.9." + n)
                    .contentType(MediaType.APPLICATION_JSON).content(BAD_LOGIN));
        }

        mockMvc.perform(post("/v1/auth/login")
                        .with(r -> { r.setRemoteAddr(realIp); return r; })
                        .header("X-Forwarded-For", "10.9.9.42")
                        .contentType(MediaType.APPLICATION_JSON).content(BAD_LOGIN))
                .andExpect(status().isTooManyRequests());
    }
}
