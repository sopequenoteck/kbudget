package fr.kksdev.budget.api.service;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.request.FirstLoginResetRequest;
import fr.kksdev.budget.api.dto.request.LoginRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.PasswordResetNotRequiredException;
import fr.kksdev.budget.api.exception.PasswordUnchangedException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
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

    private ListAppender<ILoggingEvent> logAppender;
    private Logger serviceLogger;

    @BeforeEach
    void setUpLogCapture() {
        serviceLogger = (Logger) LoggerFactory.getLogger(AuthService.class);
        logAppender = new ListAppender<>();
        logAppender.start();
        serviceLogger.addAppender(logAppender);
    }

    @AfterEach
    void tearDownLogCapture() {
        serviceLogger.detachAppender(logAppender);
    }

    // ---- Login ----

    @Test
    void should_login_when_credentials_valid() {
        var request = new LoginRequest("test@mail.com", "password123");
        var user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .password("encoded")
                .name("Test User")
                .passwordResetRequired(false)
                .build();

        when(userRepository.findByEmailAndDisabledAtIsNull("test@mail.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("password123", "encoded")).thenReturn(true);
        when(jwtUtil.generateToken(eq("test@mail.com"), eq(Map.of()))).thenReturn("jwt-token");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        AuthResponse response = authService.login(request);

        assertThat(response.token()).isEqualTo("jwt-token");
        assertThat(response.refreshToken()).isEqualTo("refresh-token");
        assertThat(response.email()).isEqualTo("test@mail.com");
        assertThat(response.mustResetCredentials()).isFalse();
    }

    @Test
    void should_include_mustReset_claim_when_password_reset_required() {
        var request = new LoginRequest("admin@mail.com", "temp-password");
        var user = User.builder()
                .id(UUID.randomUUID())
                .email("admin@mail.com")
                .password("encoded")
                .name("Admin")
                .passwordResetRequired(true)
                .build();

        when(userRepository.findByEmailAndDisabledAtIsNull("admin@mail.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("temp-password", "encoded")).thenReturn(true);
        when(jwtUtil.generateToken(eq("admin@mail.com"), eq(Map.of("mustResetCredentials", true))))
                .thenReturn("jwt-with-claim");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        AuthResponse response = authService.login(request);

        assertThat(response.mustResetCredentials()).isTrue();
        assertThat(response.token()).isEqualTo("jwt-with-claim");
        verify(jwtUtil).generateToken(eq("admin@mail.com"), eq(Map.of("mustResetCredentials", true)));
    }

    @Test
    void should_throw_when_email_not_found() {
        var request = new LoginRequest("unknown@mail.com", "password123");

        when(userRepository.findByEmailAndDisabledAtIsNull("unknown@mail.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Invalid email or password");

        verify(passwordEncoder, never()).matches(anyString(), anyString());
    }

    @Test
    void should_log_no_identifier_when_login_fails_for_unknown_email() {
        var request = new LoginRequest("unknown@mail.com", "password123");

        when(userRepository.findByEmailAndDisabledAtIsNull("unknown@mail.com")).thenReturn(Optional.empty());
        when(userRepository.findByEmail("unknown@mail.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(request)).isInstanceOf(IllegalArgumentException.class);

        List<ILoggingEvent> errors = logAppender.list.stream()
                .filter(e -> e.getLevel() == Level.ERROR)
                .toList();
        assertThat(errors).hasSize(1);
        assertThat(errors.get(0).getFormattedMessage()).isEqualTo("Login failed: no matching account");
        assertThat(errors.get(0).getArgumentArray()).isNull();
    }

    @Test
    void should_log_user_id_and_not_email_when_login_fails_for_disabled_account() {
        UUID userId = UUID.randomUUID();
        var request = new LoginRequest("disabled@mail.com", "password123");
        var user = User.builder().id(userId).email("disabled@mail.com").password("encoded").build();

        when(userRepository.findByEmailAndDisabledAtIsNull("disabled@mail.com")).thenReturn(Optional.empty());
        when(userRepository.findByEmail("disabled@mail.com")).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> authService.login(request)).isInstanceOf(IllegalArgumentException.class);

        List<String> messages = logAppender.list.stream().map(ILoggingEvent::getFormattedMessage).toList();
        assertThat(messages)
                .containsExactly("Login failed: account disabled (userId=" + userId + ")")
                .noneMatch(message -> message.contains("disabled@mail.com"));
    }

    @Test
    void should_log_user_id_and_not_email_when_login_fails_for_wrong_password() {
        UUID userId = UUID.randomUUID();
        var request = new LoginRequest("test@mail.com", "wrongpassword");
        var user = User.builder().id(userId).email("test@mail.com").password("encoded").build();

        when(userRepository.findByEmailAndDisabledAtIsNull("test@mail.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("wrongpassword", "encoded")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(request)).isInstanceOf(IllegalArgumentException.class);

        List<String> messages = logAppender.list.stream().map(ILoggingEvent::getFormattedMessage).toList();
        assertThat(messages)
                .containsExactly("Login failed: wrong password (userId=" + userId + ")")
                .noneMatch(message -> message.contains("test@mail.com"));
    }

    @Test
    void should_throw_when_password_wrong() {
        var request = new LoginRequest("test@mail.com", "wrongpassword");
        var user = User.builder()
                .email("test@mail.com")
                .password("encoded")
                .build();

        when(userRepository.findByEmailAndDisabledAtIsNull("test@mail.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("wrongpassword", "encoded")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Invalid email or password");

        verify(jwtUtil, never()).generateToken(anyString(), any());
    }

    // ---- firstLoginReset ----

    @Test
    void should_reset_credentials_when_all_valid() {
        UUID userId = UUID.randomUUID();
        var user = User.builder()
                .id(userId)
                .email("old@mail.com")
                .password("encoded-old")
                .name("Old Name")
                .passwordResetRequired(true)
                .build();
        var request = new FirstLoginResetRequest("new@mail.com", "newPassword1!", "New Name");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(userRepository.existsByEmail("new@mail.com")).thenReturn(false);
        when(passwordEncoder.matches("newPassword1!", "encoded-old")).thenReturn(false);
        when(passwordEncoder.encode("newPassword1!")).thenReturn("encoded-new");
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));
        when(jwtUtil.generateToken("new@mail.com")).thenReturn("new-jwt");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("new-refresh");

        AuthResponse response = authService.firstLoginReset(userId, request);

        assertThat(response.token()).isEqualTo("new-jwt");
        assertThat(response.email()).isEqualTo("new@mail.com");
        assertThat(response.name()).isEqualTo("New Name");
        assertThat(response.mustResetCredentials()).isFalse();
        assertThat(user.isPasswordResetRequired()).isFalse();
    }

    @Test
    void should_throw_PasswordUnchangedException_when_same_password() {
        UUID userId = UUID.randomUUID();
        var user = User.builder()
                .id(userId)
                .email("admin@mail.com")
                .password("encoded-old")
                .passwordResetRequired(true)
                .build();
        var request = new FirstLoginResetRequest("admin@mail.com", "samePassword", "Admin");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("samePassword", "encoded-old")).thenReturn(true);

        assertThatThrownBy(() -> authService.firstLoginReset(userId, request))
                .isInstanceOf(PasswordUnchangedException.class);
    }

    @Test
    void should_throw_PasswordResetNotRequiredException_when_flag_already_false() {
        UUID userId = UUID.randomUUID();
        var user = User.builder()
                .id(userId)
                .email("user@mail.com")
                .password("encoded")
                .passwordResetRequired(false)
                .build();
        var request = new FirstLoginResetRequest("user@mail.com", "newPassword1!", "User");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> authService.firstLoginReset(userId, request))
                .isInstanceOf(PasswordResetNotRequiredException.class);
    }

    @Test
    void should_throw_ConflictException_when_email_already_used_by_another_user() {
        UUID userId = UUID.randomUUID();
        var user = User.builder()
                .id(userId)
                .email("old@mail.com")
                .password("encoded")
                .passwordResetRequired(true)
                .build();
        var request = new FirstLoginResetRequest("taken@mail.com", "newPassword1!", "Admin");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(userRepository.existsByEmail("taken@mail.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.firstLoginReset(userId, request))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void should_throw_EntityNotFoundException_when_user_not_found() {
        UUID userId = UUID.randomUUID();
        var request = new FirstLoginResetRequest("admin@mail.com", "newPassword1!", "Admin");

        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.firstLoginReset(userId, request))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    void should_allow_reset_when_keeping_same_email() {
        UUID userId = UUID.randomUUID();
        var user = User.builder()
                .id(userId)
                .email("admin@mail.com")
                .password("encoded-old")
                .name("Admin")
                .passwordResetRequired(true)
                .build();
        // Même email, password différent
        var request = new FirstLoginResetRequest("admin@mail.com", "newPassword1!", "Admin");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        // Pas d'appel à existsByEmail car emails identiques (equalsIgnoreCase)
        when(passwordEncoder.matches("newPassword1!", "encoded-old")).thenReturn(false);
        when(passwordEncoder.encode("newPassword1!")).thenReturn("encoded-new");
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));
        when(jwtUtil.generateToken("admin@mail.com")).thenReturn("new-jwt");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("new-refresh");

        AuthResponse response = authService.firstLoginReset(userId, request);

        assertThat(response.mustResetCredentials()).isFalse();
        verify(userRepository, never()).existsByEmail(anyString());
    }
}
