package fr.kksdev.budget.api.config;

import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JwtFilterTest {

    private static final String SECRET = "test-secret-key-budget-app-min-256-bits-long-enough-for-hmac-sha";
    private static final long EXPIRATION = 86400000L;
    private static final String EMAIL = "user@mail.com";

    @Mock
    private UserRepository userRepository;

    private final JwtUtil jwtUtil = new JwtUtil(SECRET, EXPIRATION);

    @AfterEach
    void clearContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void should_not_authenticate_when_user_disabled() throws Exception {
        // Arrange
        String token = jwtUtil.generateToken(EMAIL);
        JwtFilter jwtFilter = new JwtFilter(jwtUtil, userRepository);

        User disabledUser = User.builder()
                .id(UUID.randomUUID())
                .email(EMAIL)
                .password("hashed")
                .disabledAt(LocalDateTime.now().minusDays(1))
                .build();

        when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.of(disabledUser));

        HttpServletRequest request = mock(HttpServletRequest.class);
        HttpServletResponse response = mock(HttpServletResponse.class);
        FilterChain chain = mock(FilterChain.class);

        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);

        // Act
        jwtFilter.doFilterInternal(request, response, chain);

        // Assert
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }
}
