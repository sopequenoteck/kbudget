package fr.kksdev.budget.api.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PasswordResetRequiredFilterTest {

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private ApiErrorWriter errorWriter;

    @Mock
    private HttpServletRequest request;

    @Mock
    private HttpServletResponse response;

    @Mock
    private FilterChain filterChain;

    @InjectMocks
    private PasswordResetRequiredFilter filter;

    @AfterEach
    void clearContext() {
        SecurityContextHolder.clearContext();
    }

    private void setAuthenticatedContext() {
        UUID userId = UUID.randomUUID();
        var auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    void should_allow_access_when_no_auth_in_context() throws Exception {
        // SecurityContext vide

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verifyNoInteractions(jwtUtil);
    }

    @Test
    void should_allow_access_when_no_bearer_token() throws Exception {
        setAuthenticatedContext();
        when(request.getHeader("Authorization")).thenReturn(null);

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verifyNoInteractions(jwtUtil);
    }

    @Test
    void should_allow_access_when_claim_is_absent() throws Exception {
        setAuthenticatedContext();
        when(request.getHeader("Authorization")).thenReturn("Bearer some-token");
        when(jwtUtil.extractClaim("some-token", "mustResetCredentials")).thenReturn(null);

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
    }

    @Test
    void should_allow_access_to_first_login_reset_when_claim_is_true() throws Exception {
        setAuthenticatedContext();
        when(request.getHeader("Authorization")).thenReturn("Bearer reset-token");
        when(jwtUtil.extractClaim("reset-token", "mustResetCredentials")).thenReturn(true);
        when(request.getServletPath()).thenReturn("/v1/auth/first-login-reset");

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verify(response, never()).setStatus(anyInt());
    }

    @Test
    void should_allow_access_to_logout_when_claim_is_true() throws Exception {
        setAuthenticatedContext();
        when(request.getHeader("Authorization")).thenReturn("Bearer reset-token");
        when(jwtUtil.extractClaim("reset-token", "mustResetCredentials")).thenReturn(true);
        when(request.getServletPath()).thenReturn("/v1/auth/logout");

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verify(response, never()).setStatus(anyInt());
    }

    @ParameterizedTest
    @ValueSource(strings = {"/v1/users/me", "/v1/accounts", "/v1/transactions", "/v1/admin/users"})
    void should_return_403_when_claim_is_true_and_path_is_not_allowlisted(String path) throws Exception {
        setAuthenticatedContext();
        when(request.getHeader("Authorization")).thenReturn("Bearer reset-token");
        when(jwtUtil.extractClaim("reset-token", "mustResetCredentials")).thenReturn(true);
        when(request.getServletPath()).thenReturn(path);

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain, never()).doFilter(any(), any());
        verify(errorWriter).write(response, HttpStatus.FORBIDDEN, "PASSWORD_RESET_REQUIRED",
                "Credentials reset required before accessing this resource.");
    }

    @Test
    void should_allow_access_when_claim_is_false() throws Exception {
        setAuthenticatedContext();
        when(request.getHeader("Authorization")).thenReturn("Bearer normal-token");
        when(jwtUtil.extractClaim("normal-token", "mustResetCredentials")).thenReturn(false);

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verify(response, never()).setStatus(anyInt());
    }
}
