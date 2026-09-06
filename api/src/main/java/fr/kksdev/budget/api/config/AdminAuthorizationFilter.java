package fr.kksdev.budget.api.config;

import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@RequiredArgsConstructor
public class AdminAuthorizationFilter extends OncePerRequestFilter {

    /**
     * Prefixe des routes d'administration, version d'API comprise (KKS-313).
     * Derive de {@link ApiVersioningConfig} : coder "/admin/" en dur ferait
     * silencieusement cesser ce controle d'acces au prochain changement de version.
     */
    private static final String ADMIN_PATH_PREFIX =
            ApiVersioningConfig.CURRENT_VERSION_PREFIX + "/admin/";

    private final UserRepository userRepository;
    private final ApiErrorWriter errorWriter;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String servletPath = request.getServletPath();
        if (servletPath == null || servletPath.isEmpty()) {
            servletPath = stripContextPath(request);
        }

        if (!servletPath.startsWith(ADMIN_PATH_PREFIX)) {
            filterChain.doFilter(request, response);
            return;
        }

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth.getPrincipal() == null) {
            // Non authentifié → laisser l'AuthenticationEntryPoint gérer le 401 unifié
            filterChain.doFilter(request, response);
            return;
        }

        UUID userId;
        try {
            userId = (UUID) auth.getPrincipal();
        } catch (ClassCastException e) {
            filterChain.doFilter(request, response);
            return;
        }

        Optional<User> userOpt = userRepository.findById(userId);
        boolean isAdmin = userOpt
                .map(User::isAdmin)
                .orElse(false);

        if (!isAdmin) {
            log.warn("Admin access denied: user={} path={}", userId, servletPath);
            errorWriter.write(response, HttpStatus.FORBIDDEN, "ACCESS_DENIED", "Access denied");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private String stripContextPath(HttpServletRequest request) {
        String uri = request.getRequestURI();
        String contextPath = request.getContextPath();
        if (contextPath != null && !contextPath.isEmpty() && uri != null && uri.startsWith(contextPath)) {
            return uri.substring(contextPath.length());
        }
        return uri != null ? uri : "";
    }
}
