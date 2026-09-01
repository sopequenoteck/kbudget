package fr.kksdev.budget.api.meta;

import fr.kksdev.budget.api.enums.Feature;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;

import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.matchesPattern;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Contrat de {@code /api/meta} (KKS-314).
 *
 * <p>C'est l'endpoint qui sert a detecter les incompatibilites : il ne doit
 * jamais casser. Ces tests verrouillent les deux proprietes dont depend cette
 * garantie — absence d'authentification et absence de prefixe de version.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MetaControllerIT {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void should_expose_meta_without_authentication() throws Exception {
        mockMvc.perform(get("/meta"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.serverVersion").exists())
                .andExpect(jsonPath("$.apiVersion").value("v1"))
                .andExpect(jsonPath("$.minClientVersion").exists())
                .andExpect(jsonPath("$.capabilities").isArray());
    }

    @Test
    void should_not_serve_meta_under_version_prefix() throws Exception {
        // Un client ne peut pas deviner le prefixe du serveur qu'il interroge :
        // c'est precisement ce qu'il vient lui demander. Si ce test casse, le
        // controller a ete deplace dans le package des controllers versionnes.
        mockMvc.perform(get("/v1/meta"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void should_derive_server_version_from_build() throws Exception {
        // Le format suffit : coder la valeur attendue en dur ferait echouer le
        // test a chaque release, et ne prouverait pas qu'elle vient du build.
        mockMvc.perform(get("/meta"))
                .andExpect(jsonPath("$.serverVersion", matchesPattern("\\d+\\.\\d+\\.\\d+.*")));
    }

    @Test
    void should_list_every_known_feature_as_capability() throws Exception {
        String[] expected = Arrays.stream(Feature.values()).map(Enum::name).toArray(String[]::new);
        mockMvc.perform(get("/meta"))
                .andExpect(jsonPath("$.capabilities", hasSize(expected.length)))
                .andExpect(jsonPath("$.capabilities", containsInAnyOrder(expected)));
    }
}
