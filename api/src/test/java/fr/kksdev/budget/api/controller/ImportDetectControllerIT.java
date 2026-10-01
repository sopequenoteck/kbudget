package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.model.ImportProfile;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.ImportDraftRepository;
import fr.kksdev.budget.api.repository.ImportProfileRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.ImportTestFiles;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Integration test of {@code POST /v1/imports/detect} (KKS-440). */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ImportDetectControllerIT {

    private static final String DETECT_URL = "/v1/imports/detect";

    @Autowired MockMvc mockMvc;
    @Autowired UserRepository userRepository;
    @Autowired ImportProfileRepository importProfileRepository;
    @Autowired ImportDraftRepository importDraftRepository;
    @Autowired JwtUtil jwtUtil;

    private User createUser() {
        return userRepository.save(User.builder()
                .email("detect-" + UUID.randomUUID() + "@example.com")
                .password("unused")
                .name("Detect")
                .passwordResetRequired(false)
                .build());
    }

    private String bearer(User user) {
        return "Bearer " + jwtUtil.generateToken(user.getEmail());
    }

    private static MockMultipartFile csv(String name, byte[] content) {
        return new MockMultipartFile("file", name, "text/csv", content);
    }

    private void saveCustomProfile(User owner) {
        importProfileRepository.save(ImportProfile.builder()
                .user(owner)
                .name("My bank")
                .separator(",")
                .dateFormat("yyyy-MM-dd")
                .dateColumn("Booked")
                .amountColumn("Value")
                .labelColumn("Memo")
                .build());
    }

    @Test
    void should_return200_with_bundled_profile_when_file_is_a_societe_generale_statement() throws Exception {
        User user = createUser();

        mockMvc.perform(multipart(DETECT_URL).file(csv("releve.csv", ImportTestFiles.sgStatement()))
                        .header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.recognized").value(true))
                .andExpect(jsonPath("$.profileSource").value("REGISTRY"))
                .andExpect(jsonPath("$.bankCode").value("SG"))
                .andExpect(jsonPath("$.profileName").value("Société Générale"));
    }

    @Test
    void should_return200_with_recognized_false_when_file_matches_no_profile() throws Exception {
        User user = createUser();

        mockMvc.perform(multipart(DETECT_URL).file(csv("export.csv", ImportTestFiles.otherBankStatement()))
                        .header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.recognized").value(false))
                .andExpect(jsonPath("$.profileSource").value(nullValue()))
                .andExpect(jsonPath("$.bankCode").value(nullValue()))
                .andExpect(jsonPath("$.profileName").value(nullValue()));
    }

    @Test
    void should_return_custom_profile_without_bank_code_when_user_saved_that_format() throws Exception {
        User user = createUser();
        saveCustomProfile(user);

        mockMvc.perform(multipart(DETECT_URL).file(csv("export.csv", ImportTestFiles.otherBankStatement()))
                        .header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.recognized").value(true))
                .andExpect(jsonPath("$.profileSource").value("CUSTOM"))
                .andExpect(jsonPath("$.bankCode").value(nullValue()))
                .andExpect(jsonPath("$.profileName").value("My bank"));
    }

    @Test
    void should_not_recognize_the_format_when_only_another_user_saved_it() throws Exception {
        saveCustomProfile(createUser());
        User user = createUser();

        mockMvc.perform(multipart(DETECT_URL).file(csv("export.csv", ImportTestFiles.otherBankStatement()))
                        .header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.recognized").value(false));
    }

    @Test
    void should_create_no_draft_when_detecting() throws Exception {
        User user = createUser();
        long drafts = importDraftRepository.count();

        mockMvc.perform(multipart(DETECT_URL).file(csv("releve.csv", ImportTestFiles.sgStatement()))
                        .header("Authorization", bearer(user)))
                .andExpect(status().isOk());

        assertThat(importDraftRepository.count()).isEqualTo(drafts);
    }

    @Test
    void should_return401_when_no_token() throws Exception {
        mockMvc.perform(multipart(DETECT_URL).file(csv("releve.csv", ImportTestFiles.sgStatement())))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void should_return400_when_file_is_empty() throws Exception {
        User user = createUser();

        mockMvc.perform(multipart(DETECT_URL).file(csv("empty.csv", new byte[0]))
                        .header("Authorization", bearer(user)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("The file is empty"));
    }

    @Test
    void should_return400_when_file_part_is_absent() throws Exception {
        User user = createUser();

        mockMvc.perform(multipart(DETECT_URL).header("Authorization", bearer(user)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("The file is empty"));
    }

    @ParameterizedTest
    @CsvSource({"statement.pdf,application/pdf", "statement.json,application/json"})
    void should_return400_when_file_is_not_csv(String fileName, String contentType) throws Exception {
        User user = createUser();
        MockMultipartFile file = new MockMultipartFile("file", fileName, contentType, "x".getBytes());

        mockMvc.perform(multipart(DETECT_URL).file(file).header("Authorization", bearer(user)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("The file must be in CSV format"));
    }
}
