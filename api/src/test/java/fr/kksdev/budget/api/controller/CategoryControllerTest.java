package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.CategoryRequest;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.CategoryService;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(CategoryController.class)
@Import(SecurityConfig.class)
class CategoryControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private CategoryService categoryService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final UUID categoryId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        var testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmailAndDisabledAtIsNull("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    private String categoryJson(String nom, String icone, String couleur) {
        return """
                {
                    "nom": "%s",
                    "icone": "%s",
                    "couleur": "%s"
                }
                """.formatted(nom, icone, couleur);
    }

    @Test
    void should_return_201_when_create_category() throws Exception {
        var response = new CategoryResponse(categoryId, "Alimentation", "\uD83C\uDF54", "#FF5733", false);

        when(categoryService.create(any(CategoryRequest.class), any(UUID.class))).thenReturn(response);

        mockMvc.perform(post("/categories")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryJson("Alimentation", "\uD83C\uDF54", "#FF5733")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(categoryId.toString()))
                .andExpect(jsonPath("$.nom").value("Alimentation"))
                .andExpect(jsonPath("$.couleur").value("#FF5733"))
                .andExpect(jsonPath("$.isSystem").value(false));
    }

    @Test
    void should_return_200_when_get_all_categories() throws Exception {
        var response = new CategoryResponse(categoryId, "Alimentation", "\uD83C\uDF54", "#FF5733", false);

        when(categoryService.getAllByUser(userId)).thenReturn(List.of(response));

        mockMvc.perform(get("/categories")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].nom").value("Alimentation"))
                .andExpect(jsonPath("$[0].isSystem").value(false));
    }

    @Test
    void should_return_200_when_get_category_by_id() throws Exception {
        var response = new CategoryResponse(categoryId, "Alimentation", "\uD83C\uDF54", "#FF5733", false);

        when(categoryService.getById(categoryId, userId)).thenReturn(response);

        mockMvc.perform(get("/categories/{id}", categoryId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nom").value("Alimentation"));
    }

    @Test
    void should_return_200_when_update_category() throws Exception {
        var response = new CategoryResponse(categoryId, "Transport", "\uD83D\uDE97", "#3498DB", false);

        when(categoryService.update(eq(categoryId), any(CategoryRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/categories/{id}", categoryId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryJson("Transport", "\uD83D\uDE97", "#3498DB")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nom").value("Transport"));
    }

    @Test
    void should_return_204_when_delete_category() throws Exception {
        doNothing().when(categoryService).delete(categoryId, userId);

        mockMvc.perform(delete("/categories/{id}", categoryId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_return_404_when_category_not_found() throws Exception {
        when(categoryService.getById(categoryId, userId))
                .thenThrow(new EntityNotFoundException("Catégorie non trouvée"));

        mockMvc.perform(get("/categories/{id}", categoryId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Catégorie non trouvée"));
    }

    @Test
    void should_return_400_when_create_with_missing_fields() throws Exception {
        mockMvc.perform(post("/categories")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_create_with_invalid_color() throws Exception {
        mockMvc.perform(post("/categories")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryJson("Test", "\uD83C\uDF54", "invalid")))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_create_with_duplicate_name() throws Exception {
        when(categoryService.create(any(CategoryRequest.class), any(UUID.class)))
                .thenThrow(new IllegalArgumentException("Une catégorie avec ce nom existe déjà"));

        mockMvc.perform(post("/categories")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryJson("Existing", "\uD83C\uDF54", "#FF5733")))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_deleteSystemCategory() throws Exception {
        doThrow(new IllegalArgumentException("Les catégories système ne peuvent pas être supprimées"))
                .when(categoryService).delete(categoryId, userId);

        mockMvc.perform(delete("/categories/{id}", categoryId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_updateSystemCategory() throws Exception {
        when(categoryService.update(eq(categoryId), any(CategoryRequest.class), eq(userId)))
                .thenThrow(new IllegalArgumentException("Les catégories système ne peuvent pas être modifiées"));

        mockMvc.perform(put("/categories/{id}", categoryId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryJson("Renamed", "\uD83D\uDD04", "#6366f1")))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_401_when_no_token() throws Exception {
        mockMvc.perform(get("/categories"))
                .andExpect(status().isUnauthorized());
    }
}
