package fr.kksdev.budget.api.config;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDateTime;
import java.util.List;
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

    private ListAppender<ILoggingEvent> logAppender;
    private Logger filterLogger;

    @BeforeEach
    void setUpLogCapture() {
        filterLogger = (Logger) LoggerFactory.getLogger(JwtFilter.class);
        logAppender = new ListAppender<>();
        logAppender.start();
        filterLogger.addAppender(logAppender);
    }

    @AfterEach
    void clearContext() {
        filterLogger.detachAppender(logAppender);
        SecurityContextHolder.clearContext();
    }

    @Test
    void should_not_authenticate_when_user_disabled() throws Exception {
        // Arrange
        String token = jwtUtil.generateToken(EMAIL);
        JwtFilter jwtFilter = new JwtFilter(jwtUtil, userRepository);

        when(userRepository.findByEmailAndDisabledAtIsNull(EMAIL)).thenReturn(Optional.empty());

        HttpServletRequest request = mock(HttpServletRequest.class);
        HttpServletResponse response = mock(HttpServletResponse.class);
        FilterChain chain = mock(FilterChain.class);

        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);

        // Act
        jwtFilter.doFilterInternal(request, response, chain);

        // Assert
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test
    void should_log_no_identifier_when_token_email_matches_no_account() throws Exception {
        String token = jwtUtil.generateToken(EMAIL);
        JwtFilter jwtFilter = new JwtFilter(jwtUtil, userRepository);

        when(userRepository.findByEmailAndDisabledAtIsNull(EMAIL)).thenReturn(Optional.empty());
        when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.empty());

        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);

        jwtFilter.doFilterInternal(request, mock(HttpServletResponse.class), mock(FilterChain.class));

        List<String> messages = logAppender.list.stream().map(ILoggingEvent::getFormattedMessage).toList();
        assertThat(messages).containsExactly("User authentication blocked (no matching account)");
    }

    @Test
    void should_log_user_id_and_not_email_when_user_disabled() throws Exception {
        UUID userId = UUID.randomUUID();
        String token = jwtUtil.generateToken(EMAIL);
        JwtFilter jwtFilter = new JwtFilter(jwtUtil, userRepository);

        when(userRepository.findByEmailAndDisabledAtIsNull(EMAIL)).thenReturn(Optional.empty());
        when(userRepository.findByEmail(EMAIL))
                .thenReturn(Optional.of(User.builder().id(userId).email(EMAIL).disabledAt(LocalDateTime.now()).build()));

        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);

        jwtFilter.doFilterInternal(request, mock(HttpServletResponse.class), mock(FilterChain.class));

        List<String> messages = logAppender.list.stream().map(ILoggingEvent::getFormattedMessage).toList();
        assertThat(messages)
                .containsExactly("User authentication blocked (account disabled): userId=" + userId)
                .noneMatch(message -> message.contains(EMAIL));
    }
}
