package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.request.ChangePasswordRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.exception.PasswordIncorrectException;
import fr.kksdev.budget.api.exception.PasswordUnchangedException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserPasswordServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private RefreshTokenService refreshTokenService;

    @InjectMocks
    private UserPasswordService userPasswordService;

    @Test
    void should_change_password_when_valid() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .name("Test")
                .password("encoded-old")
                .passwordResetRequired(false)
                .build();
        var req = new ChangePasswordRequest("OldPassword123!", "NewPassword123!");

        when(passwordEncoder.matches("OldPassword123!", "encoded-old")).thenReturn(true);
        when(passwordEncoder.matches("NewPassword123!", "encoded-old")).thenReturn(false);
        when(passwordEncoder.encode("NewPassword123!")).thenReturn("encoded-new");
        when(userRepository.save(any(User.class))).thenReturn(user);
        when(jwtUtil.generateToken("test@mail.com")).thenReturn("new-jwt");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("new-refresh");

        AuthResponse response = userPasswordService.changePassword(user, req);

        assertThat(response.token()).isEqualTo("new-jwt");
        assertThat(response.refreshToken()).isEqualTo("new-refresh");
        assertThat(response.email()).isEqualTo("test@mail.com");
        assertThat(response.mustResetCredentials()).isFalse();
        verify(refreshTokenService).revokeAllUserTokens(user);
        verify(userRepository).save(user);
    }

    @Test
    void should_reject_when_current_incorrect() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .password("encoded-old")
                .build();
        var req = new ChangePasswordRequest("WrongPassword1!", "NewPassword123!");

        when(passwordEncoder.matches("WrongPassword1!", "encoded-old")).thenReturn(false);

        assertThatThrownBy(() -> userPasswordService.changePassword(user, req))
                .isInstanceOf(PasswordIncorrectException.class);

        verify(userRepository, never()).save(any());
        verify(refreshTokenService, never()).revokeAllUserTokens(any());
    }

    @Test
    void should_reject_when_new_equals_current() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .password("encoded-same")
                .build();
        var req = new ChangePasswordRequest("SamePassword123!", "SamePassword123!");

        when(passwordEncoder.matches("SamePassword123!", "encoded-same")).thenReturn(true);

        assertThatThrownBy(() -> userPasswordService.changePassword(user, req))
                .isInstanceOf(PasswordUnchangedException.class);

        verify(userRepository, never()).save(any());
    }

    @Test
    void should_revoke_all_refresh_tokens_when_password_changed() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .name("Test")
                .password("encoded-old")
                .passwordResetRequired(false)
                .build();
        var req = new ChangePasswordRequest("OldPassword123!", "NewPassword123!");

        when(passwordEncoder.matches("OldPassword123!", "encoded-old")).thenReturn(true);
        when(passwordEncoder.matches("NewPassword123!", "encoded-old")).thenReturn(false);
        when(passwordEncoder.encode("NewPassword123!")).thenReturn("encoded-new");
        when(userRepository.save(any(User.class))).thenReturn(user);
        when(jwtUtil.generateToken("test@mail.com")).thenReturn("new-jwt");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("new-refresh");

        userPasswordService.changePassword(user, req);

        verify(refreshTokenService).revokeAllUserTokens(user);
    }

    @Test
    void should_return_new_jwt_when_password_changed() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .name("Test")
                .password("encoded-old")
                .passwordResetRequired(false)
                .build();
        var req = new ChangePasswordRequest("OldPassword123!", "NewPassword123!");

        when(passwordEncoder.matches("OldPassword123!", "encoded-old")).thenReturn(true);
        when(passwordEncoder.matches("NewPassword123!", "encoded-old")).thenReturn(false);
        when(passwordEncoder.encode("NewPassword123!")).thenReturn("encoded-new");
        when(userRepository.save(any(User.class))).thenReturn(user);
        when(jwtUtil.generateToken("test@mail.com")).thenReturn("brand-new-jwt");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("brand-new-refresh");

        AuthResponse response = userPasswordService.changePassword(user, req);

        assertThat(response.token()).isEqualTo("brand-new-jwt");
        assertThat(response.refreshToken()).isEqualTo("brand-new-refresh");
    }
}
