package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.response.AdminUserResponse;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.AdminUserService;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AdminUserController.class)
@Import(SecurityConfig.class)
class AdminUserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminUserService adminUserService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID adminId = UUID.randomUUID();
    private User adminUser;

    @BeforeEach
    void setUp() {
        adminUser = User.builder().id(adminId).email("admin@example.com").name("Admin").isAdmin(true).build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("admin@example.com");
        when(userRepository.findByEmailAndDisabledAtIsNull("admin@example.com")).thenReturn(Optional.of(adminUser));
        when(userRepository.findById(adminId)).thenReturn(Optional.of(adminUser));
    }

    // ---- GET /admin/users ----

    @Test
    void should_return_list_of_users_on_get() throws Exception {
        UUID userId = UUID.randomUUID();
        List<AdminUserResponse> users = List.of(
                new AdminUserResponse(userId, "user@example.com", "User", LocalDateTime.now(), null, false),
                new AdminUserResponse(adminId, "admin@example.com", "Admin", LocalDateTime.now(), null, true)
        );
        when(adminUserService.list()).thenReturn(users);

        mockMvc.perform(get("/v1/admin/users")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].email").value("user@example.com"))
                .andExpect(jsonPath("$[1].isAdmin").value(true));
    }

    @Test
    void should_return_401_when_not_authenticated_on_get() throws Exception {
        mockMvc.perform(get("/v1/admin/users"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("UNAUTHENTICATED"))
                .andExpect(jsonPath("$.message").value("Authentication required"))
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void should_return_unified_403_when_authenticated_user_is_not_admin() throws Exception {
        adminUser.setAdmin(false);
        when(userRepository.findById(adminId)).thenReturn(Optional.of(adminUser));

        mockMvc.perform(get("/v1/admin/users").header("Authorization", BEARER_TOKEN))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("ACCESS_DENIED"))
                .andExpect(jsonPath("$.message").value("Access denied"))
                .andExpect(jsonPath("$.length()").value(2));
    }

    // ---- PATCH /admin/users/{id}/disable ----

    @Test
    void should_return_204_when_disable_active_user() throws Exception {
        UUID targetId = UUID.randomUUID();
        doNothing().when(adminUserService).disable(eq(targetId), any(User.class));

        mockMvc.perform(patch("/v1/admin/users/" + targetId + "/disable")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());

        verify(adminUserService).disable(eq(targetId), any(User.class));
    }

    @Test
    void should_return_404_when_user_not_found_on_disable() throws Exception {
        UUID targetId = UUID.randomUUID();
        doThrow(new EntityNotFoundException("User not found"))
                .when(adminUserService).disable(eq(targetId), any(User.class));

        mockMvc.perform(patch("/v1/admin/users/" + targetId + "/disable")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound());
    }

    @Test
    void should_return_409_when_last_admin_tries_to_disable_himself() throws Exception {
        doThrow(new ConflictException("LAST_ADMIN_CANNOT_BE_DISABLED"))
                .when(adminUserService).disable(eq(adminId), any(User.class));

        mockMvc.perform(patch("/v1/admin/users/" + adminId + "/disable")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("LAST_ADMIN_CANNOT_BE_DISABLED"))
                .andExpect(jsonPath("$.message").value("The last active administrator cannot be disabled."));
    }

    // ---- PATCH /admin/users/{id}/enable ----

    @Test
    void should_return_204_when_enable_disabled_user() throws Exception {
        UUID targetId = UUID.randomUUID();
        doNothing().when(adminUserService).enable(eq(targetId), any(User.class));

        mockMvc.perform(patch("/v1/admin/users/" + targetId + "/enable")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());

        verify(adminUserService).enable(eq(targetId), any(User.class));
    }

    @Test
    void should_return_404_when_user_not_found_on_enable() throws Exception {
        UUID targetId = UUID.randomUUID();
        doThrow(new EntityNotFoundException("User not found"))
                .when(adminUserService).enable(eq(targetId), any(User.class));

        mockMvc.perform(patch("/v1/admin/users/" + targetId + "/enable")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound());
    }

    // ---- SC-007 : couvert par JwtFilterTest.should_not_authenticate_when_user_disabled ----
    // Un user dont disabled_at est non null reçoit 401 — géré au niveau du JwtFilter,
    // indépendamment de ce controller.
}
