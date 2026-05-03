package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.enums.TokenStatus;
import fr.kksdev.budget.api.exception.TokenExpiredException;
import fr.kksdev.budget.api.exception.TokenInvalidException;
import fr.kksdev.budget.api.exception.TokenReusedException;
import fr.kksdev.budget.api.exception.TokenRevokedException;
import fr.kksdev.budget.api.model.RefreshToken;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.RefreshTokenRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RefreshTokenServiceTest {

    @Mock
    private RefreshTokenRepository refreshTokenRepository;

    @Mock
    private JwtUtil jwtUtil;

    @InjectMocks
    private RefreshTokenService refreshTokenService;

    private User testUser;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(refreshTokenService, "refreshExpiration", 2592000000L);
        testUser = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .name("Test User")
                .build();
    }

    @Test
    void should_generateRefreshToken_when_userProvided() {
        when(refreshTokenRepository.save(any(RefreshToken.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        String token = refreshTokenService.generateRefreshToken(testUser);

        assertThat(token).isNotBlank();
        assertThat(token).hasSize(43);

        ArgumentCaptor<RefreshToken> captor = ArgumentCaptor.forClass(RefreshToken.class);
        verify(refreshTokenRepository).save(captor.capture());

        RefreshToken saved = captor.getValue();
        assertThat(saved.getToken()).isEqualTo(token);
        assertThat(saved.getStatus()).isEqualTo(TokenStatus.ACTIVE);
        assertThat(saved.getUser()).isEqualTo(testUser);
        assertThat(saved.getExpiresAt()).isAfter(LocalDateTime.now().plusDays(29));
    }

    @Test
    void should_returnNewTokenPair_when_validRefreshToken() {
        RefreshToken existingToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .token("valid-token")
                .status(TokenStatus.ACTIVE)
                .user(testUser)
                .expiresAt(LocalDateTime.now().plusDays(15))
                .build();

        when(refreshTokenRepository.findByToken("valid-token")).thenReturn(Optional.of(existingToken));
        when(refreshTokenRepository.save(any(RefreshToken.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(jwtUtil.generateToken(eq("test@mail.com"), eq(Map.of()))).thenReturn("new-access-token");

        var response = refreshTokenService.refreshAccessToken("valid-token");

        assertThat(response.token()).isEqualTo("new-access-token");
        assertThat(response.refreshToken()).isNotBlank();
        assertThat(response.email()).isEqualTo("test@mail.com");
        assertThat(response.name()).isEqualTo("Test User");
    }

    @Test
    void should_markOldTokenConsumed_when_refreshSucceeds() {
        RefreshToken existingToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .token("old-token")
                .status(TokenStatus.ACTIVE)
                .user(testUser)
                .expiresAt(LocalDateTime.now().plusDays(15))
                .build();

        when(refreshTokenRepository.findByToken("old-token")).thenReturn(Optional.of(existingToken));
        when(refreshTokenRepository.save(any(RefreshToken.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(jwtUtil.generateToken(eq("test@mail.com"), eq(Map.of()))).thenReturn("new-access-token");

        refreshTokenService.refreshAccessToken("old-token");

        assertThat(existingToken.getStatus()).isEqualTo(TokenStatus.CONSUMED);
    }

    @Test
    void should_revokeToken_when_logoutCalled() {
        RefreshToken activeToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .token("active-token")
                .status(TokenStatus.ACTIVE)
                .user(testUser)
                .expiresAt(LocalDateTime.now().plusDays(15))
                .build();

        when(refreshTokenRepository.findByToken("active-token")).thenReturn(Optional.of(activeToken));
        when(refreshTokenRepository.save(any(RefreshToken.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        refreshTokenService.revokeRefreshToken("active-token");

        assertThat(activeToken.getStatus()).isEqualTo(TokenStatus.REVOKED);
        verify(refreshTokenRepository).save(activeToken);
    }

    @Test
    void should_throwException_when_tokenAlreadyRevoked() {
        RefreshToken revokedToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .token("revoked-token")
                .status(TokenStatus.REVOKED)
                .user(testUser)
                .expiresAt(LocalDateTime.now().plusDays(15))
                .build();

        when(refreshTokenRepository.findByToken("revoked-token")).thenReturn(Optional.of(revokedToken));

        assertThatThrownBy(() -> refreshTokenService.revokeRefreshToken("revoked-token"))
                .isInstanceOf(TokenInvalidException.class);
    }

    @Test
    void should_revokeAllUserTokens_when_consumedTokenReused() {
        RefreshToken consumedToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .token("consumed-token")
                .status(TokenStatus.CONSUMED)
                .user(testUser)
                .expiresAt(LocalDateTime.now().plusDays(15))
                .build();

        RefreshToken activeToken1 = RefreshToken.builder()
                .id(UUID.randomUUID())
                .token("active-1")
                .status(TokenStatus.ACTIVE)
                .user(testUser)
                .expiresAt(LocalDateTime.now().plusDays(15))
                .build();

        RefreshToken activeToken2 = RefreshToken.builder()
                .id(UUID.randomUUID())
                .token("active-2")
                .status(TokenStatus.ACTIVE)
                .user(testUser)
                .expiresAt(LocalDateTime.now().plusDays(15))
                .build();

        when(refreshTokenRepository.findByToken("consumed-token")).thenReturn(Optional.of(consumedToken));
        when(refreshTokenRepository.findByUserAndStatus(testUser, TokenStatus.ACTIVE))
                .thenReturn(List.of(activeToken1, activeToken2));

        assertThatThrownBy(() -> refreshTokenService.refreshAccessToken("consumed-token"))
                .isInstanceOf(TokenReusedException.class);

        assertThat(activeToken1.getStatus()).isEqualTo(TokenStatus.REVOKED);
        assertThat(activeToken2.getStatus()).isEqualTo(TokenStatus.REVOKED);
        verify(refreshTokenRepository).saveAll(List.of(activeToken1, activeToken2));
    }

    @Test
    void should_throwRevokedError_when_revokedTokenPresented() {
        RefreshToken revokedToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .token("revoked-token")
                .status(TokenStatus.REVOKED)
                .user(testUser)
                .expiresAt(LocalDateTime.now().plusDays(15))
                .build();

        when(refreshTokenRepository.findByToken("revoked-token")).thenReturn(Optional.of(revokedToken));

        assertThatThrownBy(() -> refreshTokenService.refreshAccessToken("revoked-token"))
                .isInstanceOf(TokenRevokedException.class);
    }

    @Test
    void should_returnExpiredError_when_tokenExpired() {
        RefreshToken expiredToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .token("expired-token")
                .status(TokenStatus.ACTIVE)
                .user(testUser)
                .expiresAt(LocalDateTime.now().minusDays(1))
                .build();

        when(refreshTokenRepository.findByToken("expired-token")).thenReturn(Optional.of(expiredToken));

        assertThatThrownBy(() -> refreshTokenService.refreshAccessToken("expired-token"))
                .isInstanceOf(TokenExpiredException.class);
    }

    @Test
    void should_throwInvalidError_when_tokenNotFound() {
        when(refreshTokenRepository.findByToken("unknown-token")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> refreshTokenService.refreshAccessToken("unknown-token"))
                .isInstanceOf(TokenInvalidException.class);
    }
}
