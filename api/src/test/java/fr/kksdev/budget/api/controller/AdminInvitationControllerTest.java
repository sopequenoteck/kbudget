package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.CreateInvitationRequest;
import fr.kksdev.budget.api.dto.response.InvitationResponse;
import fr.kksdev.budget.api.enums.InvitationStatus;
import fr.kksdev.budget.api.model.Invitation;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.InvitationService;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AdminInvitationController.class)
@Import(SecurityConfig.class)
class AdminInvitationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @MockitoBean
    private InvitationService invitationService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private User adminUser;

    @BeforeEach
    void setUp() {
        adminUser = User.builder().id(userId).email("admin@example.com").name("Admin").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("admin@example.com");
        when(userRepository.findByEmail("admin@example.com")).thenReturn(Optional.of(adminUser));
        when(userRepository.findById(userId)).thenReturn(Optional.of(adminUser));
    }

    // ---- US-001 : POST /admin/invitations ----

    @Test
    void should_return_201_when_create_invitation_success() throws Exception {
        UUID token = UUID.randomUUID();
        Instant expiresAt = Instant.now().plus(7, ChronoUnit.DAYS);

        Invitation invitation = Invitation.builder()
                .id(1L)
                .token(token)
                .email("new@example.com")
                .invitedBy(adminUser)
                .expiresAt(expiresAt)
                .build();

        when(invitationService.create(any(User.class), eq("new@example.com"))).thenReturn(invitation);

        mockMvc.perform(post("/admin/invitations")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new CreateInvitationRequest("new@example.com"))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").value(token.toString()));
    }

    @Test
    void should_return_400_when_email_invalid() throws Exception {
        mockMvc.perform(post("/admin/invitations")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"not-an-email\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_401_when_not_authenticated() throws Exception {
        mockMvc.perform(post("/admin/invitations")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"new@example.com\"}"))
                .andExpect(status().isUnauthorized());
    }

    // ---- US-003 : DELETE /admin/invitations/{id} ----

    @Test
    void should_return_204_when_revoke_active_invitation() throws Exception {
        doNothing().when(invitationService).revoke(eq(42L), any(User.class));

        mockMvc.perform(delete("/admin/invitations/42")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());

        verify(invitationService).revoke(eq(42L), any(User.class));
    }

    @Test
    void should_return_404_when_revoke_nonexistent_invitation() throws Exception {
        doThrow(new EntityNotFoundException("Invitation introuvable"))
                .when(invitationService).revoke(eq(99L), any(User.class));

        mockMvc.perform(delete("/admin/invitations/99")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound());
    }

    // ---- US-008 : GET /admin/invitations ----

    @Test
    void should_return_200_with_all_invitations_when_list() throws Exception {
        Instant now = Instant.now();

        List<InvitationResponse> invitations = List.of(
                new InvitationResponse(4L, "revoked@x.com", "admin@example.com", InvitationStatus.REVOKED,
                        now, now.plus(7, ChronoUnit.DAYS), null, now.minus(1, ChronoUnit.HOURS)),
                new InvitationResponse(3L, "used@x.com", "admin@example.com", InvitationStatus.USED,
                        now.minus(1, ChronoUnit.DAYS), now.plus(6, ChronoUnit.DAYS), now.minus(1, ChronoUnit.HOURS), null),
                new InvitationResponse(2L, "expired@x.com", "admin@example.com", InvitationStatus.EXPIRED,
                        now.minus(8, ChronoUnit.DAYS), now.minus(1, ChronoUnit.DAYS), null, null),
                new InvitationResponse(1L, "active@x.com", "admin@example.com", InvitationStatus.ACTIVE,
                        now, now.plus(7, ChronoUnit.DAYS), null, null)
        );

        when(invitationService.list()).thenReturn(invitations);

        mockMvc.perform(get("/admin/invitations")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(4))
                .andExpect(jsonPath("$[0].status").value("REVOKED"))
                .andExpect(jsonPath("$[1].status").value("USED"))
                .andExpect(jsonPath("$[2].status").value("EXPIRED"))
                .andExpect(jsonPath("$[3].status").value("ACTIVE"));
    }

    @Test
    void should_return_200_with_empty_list_when_no_invitations() throws Exception {
        when(invitationService.list()).thenReturn(List.of());

        mockMvc.perform(get("/admin/invitations")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }
}
