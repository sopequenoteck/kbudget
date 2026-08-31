package fr.kksdev.budget.api.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Frontiere du versionnement d'API (KKS-313).
 *
 * <p>Verifie les deux versants : les endpoints metier ne sont servis que sous
 * {@code /v1}, et ce qui est hors du contrat applicatif reste accessible sans
 * version. Le second point n'est couvert par aucun autre test alors que le
 * healthcheck Docker et les deux clients en dependent.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ApiVersioningIT {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void should_serve_health_without_version_prefix() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk());
    }

    @Test
    void should_not_serve_health_under_version_prefix() throws Exception {
        // 401 et non 404 : `anyRequest().authenticated()` intercepte tout chemin
        // non mappe et non listé en permitAll avant le DispatcherServlet. Ce qui
        // est verifie ici est qu'actuator n'est PAS servi sous /v1.
        mockMvc.perform(get("/v1/actuator/health"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void should_serve_business_endpoint_under_version_prefix() throws Exception {
        // /banks est public : un 200 prouve le mapping sans dependre d'un JWT.
        mockMvc.perform(get("/v1/banks"))
                .andExpect(status().isOk());
    }

    @Test
    void should_not_serve_business_endpoint_without_version_prefix() throws Exception {
        // L'ancien chemin ne sert plus l'endpoint. Il repond 401 et non 404 car
        // il n'est plus en permitAll : Spring Security le rejette avant le
        // routage. Un 401 est preferable ici, il ne revele pas si la route existe.
        mockMvc.perform(get("/banks"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void should_keep_login_public_under_version_prefix() throws Exception {
        // Regression : si les requestMatchers de SecurityConfig gardaient les
        // chemins non prefixes, le login repondrait 401 au lieu d'une erreur metier.
        mockMvc.perform(post("/v1/auth/login")
                        .contentType("application/json")
                        .content("{\"email\":\"absent@mail.com\",\"password\":\"wrong\"}"))
                .andExpect(status().is4xxClientError())
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    if (status == 401 && result.getResponse().getContentAsString().isEmpty()) {
                        throw new AssertionError(
                                "401 vide : la route de login n'est plus en permitAll");
                    }
                });
    }
}
