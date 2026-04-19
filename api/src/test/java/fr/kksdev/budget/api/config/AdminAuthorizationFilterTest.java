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

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminAuthorizationFilterTest {

    @Mock
    private AdminEmailResolver adminEmailResolver;

    @Mock
    private UserRepository userRepository;

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
        when(request.getServletPath()).thenReturn("/users/me");

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verifyNoInteractions(adminEmailResolver, userRepository);
    }

    @Test
    void should_pass_through_when_dashboard_path() throws Exception {
        when(request.getServletPath()).thenReturn("/dashboard");

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verifyNoInteractions(adminEmailResolver, userRepository);
    }

    @Test
    void should_pass_through_when_not_authenticated_on_admin_path() throws Exception {
        // SecurityContext vide — le filter laisse passer, HttpStatusEntryPoint gérera 401
        when(request.getServletPath()).thenReturn("/admin/invitations");

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verifyNoInteractions(adminEmailResolver, userRepository);
    }

    @Test
    void should_send_403_when_authenticated_user_not_admin() throws Exception {
        UUID userId = UUID.randomUUID();
        when(request.getServletPath()).thenReturn("/admin/invitations");

        var auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        SecurityContextHolder.getContext().setAuthentication(auth);

        User user = User.builder().id(userId).email("user@mail.com").build();
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(adminEmailResolver.isAdminEmail("user@mail.com")).thenReturn(false);

        filter.doFilterInternal(request, response, filterChain);

        verify(response).sendError(eq(403), eq("Forbidden"));
        verify(filterChain, never()).doFilter(any(), any());
    }

    @Test
    void should_pass_through_when_authenticated_user_is_admin() throws Exception {
        UUID userId = UUID.randomUUID();
        when(request.getServletPath()).thenReturn("/admin/invitations");

        var auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        SecurityContextHolder.getContext().setAuthentication(auth);

        User user = User.builder().id(userId).email("admin@mail.com").build();
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(adminEmailResolver.isAdminEmail("admin@mail.com")).thenReturn(true);

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verify(response, never()).sendError(anyInt(), anyString());
    }

    @Test
    void should_send_403_when_principal_user_not_found_in_db() throws Exception {
        // Edge case : UUID dans JWT mais user supprimé → 403, pas 500
        UUID userId = UUID.randomUUID();
        when(request.getServletPath()).thenReturn("/admin/users");

        var auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        SecurityContextHolder.getContext().setAuthentication(auth);

        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        filter.doFilterInternal(request, response, filterChain);

        verify(response).sendError(eq(403), eq("Forbidden"));
        verify(filterChain, never()).doFilter(any(), any());
    }

    @Test
    void should_pass_through_when_principal_not_uuid() throws Exception {
        // Edge case : mauvais type de principal
        when(request.getServletPath()).thenReturn("/admin/invitations");

        var auth = new UsernamePasswordAuthenticationToken("not-a-uuid", null, List.of());
        SecurityContextHolder.getContext().setAuthentication(auth);

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        verifyNoInteractions(adminEmailResolver, userRepository);
    }
}
