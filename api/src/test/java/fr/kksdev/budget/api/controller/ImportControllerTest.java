package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.CategoryRuleService;
import fr.kksdev.budget.api.service.ImportService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.nio.charset.StandardCharsets;
import java.util.Optional;
import java.util.UUID;

import static org.hamcrest.Matchers.allOf;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.startsWith;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ImportController.class)
@Import(SecurityConfig.class)
class ImportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ImportService importService;

    @MockitoBean
    private CategoryRuleService categoryRuleService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        var testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmailAndDisabledAtIsNull("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    @Test
    void should_return400WithoutRequestFragment_when_mappingJsonIsInvalid() throws Exception {
        var file = new MockMultipartFile("file", "releve.csv", "text/csv",
                "date;libelle;montant".getBytes(StandardCharsets.UTF_8));

        mockMvc.perform(multipart("/v1/imports/upload-with-mapping")
                        .file(file)
                        .param("accountId", UUID.randomUUID().toString())
                        .param("mapping", "{\"skipHeaderLines\":\"SENTINEL\"}")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("BAD_REQUEST"))
                .andExpect(jsonPath("$.message").value(
                        allOf(startsWith("Invalid JSON mapping ("), not(containsString("SENTINEL")))));
    }

    private static final String VALID_MAPPING = "{\"separator\":\",\",\"dateFormat\":\"yyyy-MM-dd\","
            + "\"dateColumn\":\"Booked\",\"labelColumn\":\"Memo\",\"amountColumn\":\"Value\"";

    private org.springframework.test.web.servlet.ResultActions uploadWithMapping(String mappingJson) throws Exception {
        var file = new MockMultipartFile("file", "releve.csv", "text/csv",
                "date;libelle;montant".getBytes(StandardCharsets.UTF_8));
        return mockMvc.perform(multipart("/v1/imports/upload-with-mapping")
                .file(file)
                .param("accountId", UUID.randomUUID().toString())
                .param("mapping", mappingJson)
                .header("Authorization", BEARER_TOKEN));
    }

    @Test
    void should_return400WithRank_when_cleanupPatternIsNotAValidRegex() throws Exception {
        uploadWithMapping(VALID_MAPPING + ",\"cleanupPatterns\":[\"CARTE\",\"(SECRET\"]}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("BAD_REQUEST"))
                .andExpect(jsonPath("$.message").value("cleanupPatterns[1] is not a valid regular expression"));

        verifyNoInteractions(importService);
    }

    @Test
    void should_return400WithRank_when_cleanupPatternIsBlank() throws Exception {
        uploadWithMapping(VALID_MAPPING + ",\"cleanupPatterns\":[\" \"]}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("BAD_REQUEST"))
                .andExpect(jsonPath("$.message").value("cleanupPatterns[0] must not be blank"));

        verifyNoInteractions(importService);
    }

    @Test
    void should_return201_when_mappingHasNoCleanupPatterns() throws Exception {
        uploadWithMapping(VALID_MAPPING + "}").andExpect(status().isCreated());
    }

    @Test
    void should_return201_when_cleanupPatternsAreValid() throws Exception {
        uploadWithMapping(VALID_MAPPING + ",\"cleanupPatterns\":[\"CARTE\\\\s+\"]}")
                .andExpect(status().isCreated());
    }
}
