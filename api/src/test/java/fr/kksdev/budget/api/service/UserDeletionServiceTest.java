package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.DeleteAccountRequest;
import fr.kksdev.budget.api.exception.ConfirmationRequiredException;
import fr.kksdev.budget.api.exception.LastAdminDeletionForbiddenException;
import fr.kksdev.budget.api.exception.PasswordIncorrectException;
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
class UserDeletionServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private RefreshTokenService refreshTokenService;

    @InjectMocks
    private UserDeletionService userDeletionService;

    @Test
    void should_soft_delete_user_when_password_correct() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .password("encoded-password")
                .isAdmin(false)
                .build();
        var req = new DeleteAccountRequest("CorrectPassword1!", true);

        when(passwordEncoder.matches("CorrectPassword1!", "encoded-password")).thenReturn(true);
        when(userRepository.save(any(User.class))).thenReturn(user);

        userDeletionService.softDelete(user, req);

        assertThat(user.getDisabledAt()).isNotNull();
        verify(userRepository).save(user);
        verify(refreshTokenService).revokeAllUserTokens(user);
    }

    @Test
    void should_throw_when_password_incorrect() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .password("encoded-password")
                .build();
        var req = new DeleteAccountRequest("WrongPassword1!", true);

        when(passwordEncoder.matches("WrongPassword1!", "encoded-password")).thenReturn(false);

        assertThatThrownBy(() -> userDeletionService.softDelete(user, req))
                .isInstanceOf(PasswordIncorrectException.class);

        verify(userRepository, never()).save(any());
        verify(refreshTokenService, never()).revokeAllUserTokens(any());
    }

    @Test
    void should_throw_when_confirmed_false() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .password("encoded-password")
                .build();
        var req = new DeleteAccountRequest("CorrectPassword1!", false);

        assertThatThrownBy(() -> userDeletionService.softDelete(user, req))
                .isInstanceOf(ConfirmationRequiredException.class);

        verify(userRepository, never()).save(any());
        verify(refreshTokenService, never()).revokeAllUserTokens(any());
    }

    @Test
    void should_throw_when_last_admin() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("admin@mail.com")
                .password("encoded-password")
                .isAdmin(true)
                .build();
        var req = new DeleteAccountRequest("CorrectPassword1!", true);

        when(passwordEncoder.matches("CorrectPassword1!", "encoded-password")).thenReturn(true);
        when(userRepository.countActiveAdmins()).thenReturn(1L);

        assertThatThrownBy(() -> userDeletionService.softDelete(user, req))
                .isInstanceOf(LastAdminDeletionForbiddenException.class);

        verify(userRepository, never()).save(any());
        verify(refreshTokenService, never()).revokeAllUserTokens(any());
    }

    @Test
    void should_succeed_when_admin_not_alone() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("admin@mail.com")
                .password("encoded-password")
                .isAdmin(true)
                .build();
        var req = new DeleteAccountRequest("CorrectPassword1!", true);

        when(passwordEncoder.matches("CorrectPassword1!", "encoded-password")).thenReturn(true);
        when(userRepository.countActiveAdmins()).thenReturn(2L);
        when(userRepository.save(any(User.class))).thenReturn(user);

        userDeletionService.softDelete(user, req);

        assertThat(user.getDisabledAt()).isNotNull();
        verify(userRepository).save(user);
        verify(refreshTokenService).revokeAllUserTokens(user);
    }

    @Test
    void should_revoke_all_refresh_tokens_on_soft_delete() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .password("encoded-password")
                .isAdmin(false)
                .build();
        var req = new DeleteAccountRequest("CorrectPassword1!", true);

        when(passwordEncoder.matches("CorrectPassword1!", "encoded-password")).thenReturn(true);
        when(userRepository.save(any(User.class))).thenReturn(user);

        userDeletionService.softDelete(user, req);

        verify(refreshTokenService).revokeAllUserTokens(user);
    }

    @Test
    void should_keep_user_data_after_soft_delete() {
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .name("Test User")
                .password("encoded-password")
                .isAdmin(false)
                .build();
        var req = new DeleteAccountRequest("CorrectPassword1!", true);

        when(passwordEncoder.matches("CorrectPassword1!", "encoded-password")).thenReturn(true);
        when(userRepository.save(any(User.class))).thenReturn(user);

        userDeletionService.softDelete(user, req);

        assertThat(user.getDisabledAt()).isNotNull();
        assertThat(user.getEmail()).isEqualTo("test@mail.com");
        assertThat(user.getName()).isEqualTo("Test User");
        verify(userRepository).save(user);
    }
}
