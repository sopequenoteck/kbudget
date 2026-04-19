package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.request.LoginRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private RefreshTokenService refreshTokenService;

    @InjectMocks
    private AuthService authService;

    @Test
    void should_login_when_credentials_valid() {
        var request = new LoginRequest("test@mail.com", "password123");
        var user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .password("encoded")
                .name("Test User")
                .build();

        when(userRepository.findByEmail("test@mail.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("password123", "encoded")).thenReturn(true);
        when(jwtUtil.generateToken("test@mail.com")).thenReturn("jwt-token");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        AuthResponse response = authService.login(request);

        assertThat(response.token()).isEqualTo("jwt-token");
        assertThat(response.refreshToken()).isEqualTo("refresh-token");
        assertThat(response.email()).isEqualTo("test@mail.com");
    }

    @Test
    void should_throw_when_email_not_found() {
        var request = new LoginRequest("unknown@mail.com", "password123");

        when(userRepository.findByEmail("unknown@mail.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Email ou mot de passe incorrect");

        verify(passwordEncoder, never()).matches(anyString(), anyString());
    }

    @Test
    void should_throw_when_password_wrong() {
        var request = new LoginRequest("test@mail.com", "wrongpassword");
        var user = User.builder()
                .email("test@mail.com")
                .password("encoded")
                .build();

        when(userRepository.findByEmail("test@mail.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("wrongpassword", "encoded")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Email ou mot de passe incorrect");

        verify(jwtUtil, never()).generateToken(anyString());
    }
}
