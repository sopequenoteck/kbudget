package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.LoginRequest;
import fr.kksdev.budget.api.dto.request.RegisterRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.AuthService;
import fr.kksdev.budget.api.service.RefreshTokenService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@Import(SecurityConfig.class)
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @MockitoBean
    private AuthService authService;

    @MockitoBean
    private RefreshTokenService refreshTokenService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @Test
    void should_return_201_when_register_success() throws Exception {
        var request = new RegisterRequest("test@mail.com", "password123", "Test User", null, null);
        var response = new AuthResponse("jwt-token", "refresh-token", "test@mail.com", "Test User");

        when(authService.register(any(RegisterRequest.class))).thenReturn(response);

        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").value("jwt-token"))
                .andExpect(jsonPath("$.email").value("test@mail.com"))
                .andExpect(jsonPath("$.name").value("Test User"));
    }

    @Test
    void should_return_200_when_login_success() throws Exception {
        var request = new LoginRequest("test@mail.com", "password123");
        var response = new AuthResponse("jwt-token", "refresh-token", "test@mail.com", "Test User");

        when(authService.login(any(LoginRequest.class))).thenReturn(response);

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("jwt-token"))
                .andExpect(jsonPath("$.email").value("test@mail.com"));
    }

    @Test
    void should_return_400_when_register_email_invalid() throws Exception {
        var request = new RegisterRequest("not-an-email", "password123", "Test User", null, null);

        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_register_password_too_short() throws Exception {
        var request = new RegisterRequest("test@mail.com", "short", "Test User", null, null);

        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_login_email_blank() throws Exception {
        var request = new LoginRequest("", "password123");

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_email_already_exists() throws Exception {
        var request = new RegisterRequest("existing@mail.com", "password123", "User", null, null);

        when(authService.register(any(RegisterRequest.class)))
                .thenThrow(new IllegalArgumentException("Email déjà utilisé"));

        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Email déjà utilisé"));
    }

    @Test
    void should_return_400_when_login_credentials_wrong() throws Exception {
        var request = new LoginRequest("test@mail.com", "wrongpassword");

        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new IllegalArgumentException("Email ou mot de passe incorrect"));

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Email ou mot de passe incorrect"));
    }

    // --- T008 : currency + timezone dans le register ---

    @Test
    void should_registerWithCurrency_when_currencyProvided() throws Exception {
        var response = new AuthResponse("jwt-token", "refresh-token", "test@x.com", "Test");

        when(authService.register(any(RegisterRequest.class))).thenReturn(response);

        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"test@x.com\",\"password\":\"test123\",\"currency\":\"XOF\"}"))
                .andExpect(status().isCreated());
    }

    @Test
    void should_registerWithDefaults_when_noCurrencyOrTimezone() throws Exception {
        var response = new AuthResponse("jwt-token", "refresh-token", "test2@x.com", "Test");

        when(authService.register(any(RegisterRequest.class))).thenReturn(response);

        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"test2@x.com\",\"password\":\"test123\"}"))
                .andExpect(status().isCreated());
    }

    @Test
    void should_rejectRegistration_when_invalidCurrency() throws Exception {
        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"test3@x.com\",\"password\":\"test123\",\"currency\":\"BTC\"}"))
                .andExpect(status().isBadRequest());
    }
}
