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

    private final AdminEmailResolver adminEmailResolver;
    private final UserRepository userRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        // servletPath n'inclut pas le context-path (/api) — c'est la bonne valeur pour matcher /admin/
        String servletPath = request.getServletPath();

        if (!servletPath.startsWith("/admin/")) {
            filterChain.doFilter(request, response);
            return;
        }

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth.getPrincipal() == null) {
            // Non authentifié → laisser HttpStatusEntryPoint gérer 401 via la chaîne normale
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
                .map(u -> adminEmailResolver.isAdminEmail(u.getEmail()))
                .orElse(false);

        if (!isAdmin) {
            log.warn("Admin access denied: user={} path={}", userId, servletPath);
            response.sendError(HttpStatus.FORBIDDEN.value(), "Forbidden");
            return;
        }

        filterChain.doFilter(request, response);
    }
}
