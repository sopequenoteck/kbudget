package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.LogoutRequest;
import fr.kksdev.budget.api.dto.request.RefreshRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.exception.TokenExpiredException;
import fr.kksdev.budget.api.exception.TokenInvalidException;
import fr.kksdev.budget.api.exception.TokenReusedException;
import fr.kksdev.budget.api.exception.TokenRevokedException;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.AcceptInviteService;
import fr.kksdev.budget.api.service.AuthService;
import fr.kksdev.budget.api.service.InvitationService;
import fr.kksdev.budget.api.service.RefreshTokenService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.TestPropertySource;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
// Rate limiting neutralise : cette suite enchaine bien plus de tentatives
// d'authentification qu'un utilisateur reel, toutes depuis la meme IP MockMvc.
// Le comportement de limitation est verifie par RateLimitIT (KKS-310).
@TestPropertySource(properties = "app.security.rate-limit.capacity=100000")
@Import(SecurityConfig.class)
class AuthControllerRefreshTest {

    @Autowired
    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @MockitoBean
    private AuthService authService;

    @MockitoBean
    private RefreshTokenService refreshTokenService;

    @MockitoBean
    private AcceptInviteService acceptInviteService;

    @MockitoBean
    private InvitationService invitationService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    @Test
    void should_return_200_when_refresh_success() throws Exception {
        var request = new RefreshRequest("valid-refresh-token");
        var response = new AuthResponse("new-access-token", "new-refresh-token", "test@mail.com", "Test User", false);

        when(refreshTokenService.refreshAccessToken("valid-refresh-token")).thenReturn(response);

        mockMvc.perform(post("/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("new-access-token"))
                .andExpect(jsonPath("$.refreshToken").value("new-refresh-token"))
                .andExpect(jsonPath("$.email").value("test@mail.com"))
                .andExpect(jsonPath("$.name").value("Test User"))
                .andExpect(jsonPath("$.mustResetCredentials").value(false));
    }

    @Test
    void should_return_401_when_refresh_token_expired() throws Exception {
        var request = new RefreshRequest("expired-token");

        when(refreshTokenService.refreshAccessToken("expired-token"))
                .thenThrow(new TokenExpiredException());

        mockMvc.perform(post("/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("TOKEN_EXPIRED"));
    }

    @Test
    void should_return_401_when_refresh_token_invalid() throws Exception {
        var request = new RefreshRequest("unknown-token");

        when(refreshTokenService.refreshAccessToken("unknown-token"))
                .thenThrow(new TokenInvalidException());

        mockMvc.perform(post("/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("TOKEN_INVALID"));
    }

    @Test
    void should_return_401_when_refresh_token_revoked() throws Exception {
        var request = new RefreshRequest("revoked-token");

        when(refreshTokenService.refreshAccessToken("revoked-token"))
                .thenThrow(new TokenRevokedException());

        mockMvc.perform(post("/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("TOKEN_REVOKED"));
    }

    @Test
    void should_return_401_when_reuse_detected() throws Exception {
        var request = new RefreshRequest("consumed-token");

        when(refreshTokenService.refreshAccessToken("consumed-token"))
                .thenThrow(new TokenReusedException());

        mockMvc.perform(post("/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("TOKEN_REUSE_DETECTED"));
    }

    @Test
    void should_return_204_when_logout_success() throws Exception {
        var request = new LogoutRequest("valid-refresh-token");

        doNothing().when(refreshTokenService).revokeRefreshToken("valid-refresh-token");

        mockMvc.perform(post("/v1/auth/logout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_return_401_when_logout_token_invalid() throws Exception {
        var request = new LogoutRequest("invalid-token");

        doThrow(new TokenInvalidException()).when(refreshTokenService).revokeRefreshToken("invalid-token");

        mockMvc.perform(post("/v1/auth/logout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("TOKEN_INVALID"));
    }

    @Test
    void should_return_400_when_refresh_body_blank() throws Exception {
        mockMvc.perform(post("/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.message").isNotEmpty())
                .andExpect(jsonPath("$.details.length()").value(1))
                .andExpect(jsonPath("$.details[0].field").value("refreshToken"))
                .andExpect(jsonPath("$.details[0].code").value("NOT_BLANK"))
                .andExpect(jsonPath("$.details[0].message").isNotEmpty());
    }

    @Test
    void should_succeed_without_authorization_header() throws Exception {
        var request = new RefreshRequest("valid-refresh-token");
        var response = new AuthResponse("new-access-token", "new-refresh-token", "test@mail.com", "Test User", false);

        when(refreshTokenService.refreshAccessToken("valid-refresh-token")).thenReturn(response);

        mockMvc.perform(post("/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("new-access-token"));
    }
}
