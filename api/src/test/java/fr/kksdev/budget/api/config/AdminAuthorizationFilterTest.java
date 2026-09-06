package fr.kksdev.budget.api.config;

import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminAuthorizationFilterTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private ApiErrorWriter errorWriter;

    @Mock
    private HttpServletRequest request;

    @Mock
    private HttpServletResponse response;

    @Mock
    private FilterChain filterChain;

    @InjectMocks
    private AdminAuthorizationFilter filter;

    @AfterEach
    void clearContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void should_pass_through_when_path_not_admin() throws Exception {
        when(request.getServletPath()).thenReturn("/v1/users/me");

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verifyNoInteractions(userRepository);
    }

    @Test
    void should_pass_through_when_dashboard_path() throws Exception {
        when(request.getServletPath()).thenReturn("/dashboard");

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verifyNoInteractions(userRepository);
    }

    @Test
    void should_resolve_admin_path_from_request_uri_when_servlet_path_is_empty() throws Exception {
        UUID userId = UUID.randomUUID();
        when(request.getServletPath()).thenReturn("");
        when(request.getRequestURI()).thenReturn("/api/v1/admin/users");
        when(request.getContextPath()).thenReturn("/api");
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(userId, null, List.of()));
        when(userRepository.findById(userId)).thenReturn(Optional.of(
                User.builder().id(userId).email("user@mail.com").isAdmin(false).build()));

        filter.doFilterInternal(request, response, filterChain);

        verify(errorWriter).write(response, org.springframework.http.HttpStatus.FORBIDDEN,
                "ACCESS_DENIED", "Access denied");
        verify(filterChain, never()).doFilter(any(), any());
    }

    @Test
    void should_pass_through_when_not_authenticated_on_admin_path() throws Exception {
        // SecurityContext vide — le filter laisse passer, HttpStatusEntryPoint gérera 401
        when(request.getServletPath()).thenReturn("/v1/admin/invitations");

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verifyNoInteractions(userRepository);
    }

    @Test
    void should_send_403_when_authenticated_user_not_admin() throws Exception {
        UUID userId = UUID.randomUUID();
        when(request.getServletPath()).thenReturn("/v1/admin/invitations");

        var auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        SecurityContextHolder.getContext().setAuthentication(auth);

        User user = User.builder().id(userId).email("user@mail.com").isAdmin(false).build();
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        filter.doFilterInternal(request, response, filterChain);

        verify(errorWriter).write(response, org.springframework.http.HttpStatus.FORBIDDEN,
                "ACCESS_DENIED", "Access denied");
        verify(filterChain, never()).doFilter(any(), any());
    }

    @Test
    void should_pass_through_when_authenticated_user_is_admin() throws Exception {
        UUID userId = UUID.randomUUID();
        when(request.getServletPath()).thenReturn("/v1/admin/invitations");

        var auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        SecurityContextHolder.getContext().setAuthentication(auth);

        User user = User.builder().id(userId).email("admin@mail.com").isAdmin(true).build();
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verifyNoInteractions(errorWriter);
    }

    @Test
    void should_send_403_when_principal_user_not_found_in_db() throws Exception {
        // Edge case : UUID dans JWT mais user supprimé → 403, pas 500
        UUID userId = UUID.randomUUID();
        when(request.getServletPath()).thenReturn("/v1/admin/users");

        var auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        SecurityContextHolder.getContext().setAuthentication(auth);

        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        filter.doFilterInternal(request, response, filterChain);

        verify(errorWriter).write(response, org.springframework.http.HttpStatus.FORBIDDEN,
                "ACCESS_DENIED", "Access denied");
        verify(filterChain, never()).doFilter(any(), any());
    }

    @Test
    void should_pass_through_when_principal_not_uuid() throws Exception {
        // Edge case : mauvais type de principal
        when(request.getServletPath()).thenReturn("/v1/admin/invitations");

        var auth = new UsernamePasswordAuthenticationToken("not-a-uuid", null, List.of());
        SecurityContextHolder.getContext().setAuthentication(auth);

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verifyNoInteractions(userRepository);
    }
}
