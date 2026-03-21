package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.request.LoginRequest;
import fr.kksdev.budget.api.dto.request.RegisterRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
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
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
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
    private CategoryService categoryService;

    @Mock
    private AccountService accountService;

    @Mock
    private RefreshTokenService refreshTokenService;

    @Mock
    private PreferenceService preferenceService;

    @InjectMocks
    private AuthService authService;

    @Test
    void should_register_when_email_not_exists() {
        var request = new RegisterRequest("test@mail.com", "password123", "Test User", null, null);
        var savedUser = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .password("encoded")
                .name("Test User")
                .build();

        when(userRepository.existsByEmail("test@mail.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(jwtUtil.generateToken("test@mail.com")).thenReturn("jwt-token");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        AuthResponse response = authService.register(request);

        assertThat(response.token()).isEqualTo("jwt-token");
        assertThat(response.refreshToken()).isEqualTo("refresh-token");
        assertThat(response.email()).isEqualTo("test@mail.com");
        assertThat(response.name()).isEqualTo("Test User");
        verify(userRepository).save(any(User.class));
    }

    @Test
    void should_throw_when_email_already_exists() {
        var request = new RegisterRequest("existing@mail.com", "password123", "User", null, null);

        when(userRepository.existsByEmail("existing@mail.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Email déjà utilisé");

        verify(userRepository, never()).save(any());
    }

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

    // --- T005 : currency + timezone propagation lors du register ---

    @Test
    void should_createAccountWithXOF_when_currencyProvided() {
        var savedUser = User.builder()
                .id(UUID.randomUUID())
                .email("xof@mail.com")
                .password("encoded")
                .build();
        var request = new RegisterRequest("xof@mail.com", "password123", "XOF User", Currency.XOF, null);

        when(userRepository.existsByEmail("xof@mail.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(jwtUtil.generateToken("xof@mail.com")).thenReturn("jwt-token");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        authService.register(request);

        verify(accountService).createDefaultAccount(any(User.class), eq(Currency.XOF));
    }

    @Test
    void should_createAccountWithEUR_when_currencyNull() {
        var request = new RegisterRequest("eur@mail.com", "password123", "EUR User", null, null);

        when(userRepository.existsByEmail("eur@mail.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));
        when(jwtUtil.generateToken("eur@mail.com")).thenReturn("jwt-token");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        authService.register(request);

        verify(accountService).createDefaultAccount(any(User.class), eq(Currency.EUR));
    }

    @Test
    void should_createPreferenceWithTimezone_when_timezoneProvided() {
        var request = new RegisterRequest("tz@mail.com", "password123", "TZ User", null, "Africa/Lome");

        when(userRepository.existsByEmail("tz@mail.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));
        when(jwtUtil.generateToken("tz@mail.com")).thenReturn("jwt-token");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        authService.register(request);

        verify(preferenceService).createInitialPreference(any(User.class), eq(Currency.EUR), eq("Africa/Lome"));
    }

    @Test
    void should_useDefaultTimezone_when_timezoneNull() {
        var request = new RegisterRequest("notz@mail.com", "password123", "No TZ User", null, null);

        when(userRepository.existsByEmail("notz@mail.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));
        when(jwtUtil.generateToken("notz@mail.com")).thenReturn("jwt-token");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        authService.register(request);

        verify(preferenceService).createInitialPreference(any(User.class), eq(Currency.EUR), isNull());
    }
}
