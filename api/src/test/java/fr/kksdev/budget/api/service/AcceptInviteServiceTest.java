package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.request.AcceptInviteRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.model.Invitation;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AcceptInviteServiceTest {

    @Mock
    private InvitationService invitationService;

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
    private AcceptInviteService acceptInviteService;

    private Invitation buildActiveInvitation(String email) {
        return Invitation.builder()
                .id(1L)
                .token(UUID.randomUUID())
                .email(email)
                .expiresAt(Instant.now().plus(7, ChronoUnit.DAYS))
                .build();
    }

    private AcceptInviteRequest buildRequest(UUID token) {
        return new AcceptInviteRequest(token, "password123", "Alice", Currency.EUR, "Europe/Paris");
    }

    @Test
    void should_create_user_with_all_dependencies_when_invitation_valid() {
        Invitation invitation = buildActiveInvitation("alice@example.com");
        AcceptInviteRequest request = buildRequest(invitation.getToken());

        when(invitationService.validatePublic(request.token())).thenReturn(Optional.of(invitation));
        when(userRepository.existsByEmail("alice@example.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));
        when(jwtUtil.generateToken("alice@example.com")).thenReturn("jwt-token");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        acceptInviteService.acceptInvite(request);

        verify(userRepository).save(any(User.class));
        verify(categoryService).seedSystemCategories(any(User.class));
        verify(accountService).createDefaultAccount(any(User.class), eq(Currency.EUR));
        verify(preferenceService).createInitialPreference(any(User.class), eq(Currency.EUR), eq("Europe/Paris"));
        verify(invitationService).markUsed(invitation);
    }

    @Test
    void should_use_email_from_invitation_not_from_body() {
        Invitation invitation = buildActiveInvitation("real@example.com");
        AcceptInviteRequest request = buildRequest(invitation.getToken());

        when(invitationService.validatePublic(request.token())).thenReturn(Optional.of(invitation));
        when(userRepository.existsByEmail("real@example.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encoded");
        when(jwtUtil.generateToken("real@example.com")).thenReturn("jwt-token");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        when(userRepository.save(userCaptor.capture())).thenAnswer(i -> i.getArgument(0));

        AuthResponse response = acceptInviteService.acceptInvite(request);

        assertThat(userCaptor.getValue().getEmail()).isEqualTo("real@example.com");
        assertThat(response.email()).isEqualTo("real@example.com");
    }

    @Test
    void should_throw_EntityNotFoundException_when_token_not_active() {
        UUID token = UUID.randomUUID();
        AcceptInviteRequest request = buildRequest(token);

        when(invitationService.validatePublic(token)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> acceptInviteService.acceptInvite(request))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Invitation invalide.");

        verify(userRepository, never()).save(any());
    }

    @Test
    void should_throw_IllegalArgumentException_when_email_already_exists() {
        Invitation invitation = buildActiveInvitation("existing@example.com");
        AcceptInviteRequest request = buildRequest(invitation.getToken());

        when(invitationService.validatePublic(request.token())).thenReturn(Optional.of(invitation));
        when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

        assertThatThrownBy(() -> acceptInviteService.acceptInvite(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Email déjà utilisé");

        verify(userRepository, never()).save(any());
        verify(invitationService, never()).markUsed(any());
    }

    @Test
    void should_generate_jwt_and_refresh_token_when_success() {
        Invitation invitation = buildActiveInvitation("alice@example.com");
        AcceptInviteRequest request = buildRequest(invitation.getToken());

        when(invitationService.validatePublic(request.token())).thenReturn(Optional.of(invitation));
        when(userRepository.existsByEmail("alice@example.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));
        when(jwtUtil.generateToken("alice@example.com")).thenReturn("jwt-token");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        AuthResponse response = acceptInviteService.acceptInvite(request);

        verify(jwtUtil).generateToken("alice@example.com");
        verify(refreshTokenService).generateRefreshToken(any(User.class));
        assertThat(response.token()).isEqualTo("jwt-token");
        assertThat(response.refreshToken()).isEqualTo("refresh-token");
    }

    @Test
    void should_preserve_currency_and_timezone_from_request() {
        Invitation invitation = buildActiveInvitation("alice@example.com");
        AcceptInviteRequest request = new AcceptInviteRequest(
                invitation.getToken(), "password123", "Alice", Currency.XOF, "Africa/Lome");

        when(invitationService.validatePublic(request.token())).thenReturn(Optional.of(invitation));
        when(userRepository.existsByEmail("alice@example.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));
        when(jwtUtil.generateToken("alice@example.com")).thenReturn("jwt-token");
        when(refreshTokenService.generateRefreshToken(any(User.class))).thenReturn("refresh-token");

        acceptInviteService.acceptInvite(request);

        verify(accountService).createDefaultAccount(any(User.class), eq(Currency.XOF));
        verify(preferenceService).createInitialPreference(any(User.class), eq(Currency.XOF), eq("Africa/Lome"));
    }
}
