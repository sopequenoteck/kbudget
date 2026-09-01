package fr.kksdev.budget.api.config;

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
import java.util.Set;

@Slf4j
@RequiredArgsConstructor
public class PasswordResetRequiredFilter extends OncePerRequestFilter {

    /**
     * Chemins accessibles a un utilisateur soumis au reset force, version d'API
     * comprise (KKS-313). Derive de {@link ApiVersioningConfig} : sans le prefixe,
     * l'exact-match ci-dessous echouerait et l'utilisateur ne pourrait plus
     * effectuer le reset qui debloque son compte.
     */
    private static final Set<String> ALLOWED_PATHS = Set.of(
            ApiVersioningConfig.CURRENT_VERSION_PREFIX + "/auth/first-login-reset",
            ApiVersioningConfig.CURRENT_VERSION_PREFIX + "/auth/logout",
            // /meta n'expose aucune donnee utilisateur et sert a la detection
            // d'incompatibilite au demarrage (KKS-314). Le bloquer ferait conclure
            // le client a un serveur incompatible alors que le compte attend
            // simplement un reset.
            "/meta"
    );

    private final JwtUtil jwtUtil;
    private final ApiErrorWriter errorWriter;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            chain.doFilter(request, response);
            return;
        }

        String token = extractBearerToken(request);
        if (token == null) {
            chain.doFilter(request, response);
            return;
        }

        Object claim = jwtUtil.extractClaim(token, "mustResetCredentials");
        boolean mustReset = Boolean.TRUE.equals(claim);

        if (!mustReset) {
            chain.doFilter(request, response);
            return;
        }

        // getServletPath() peut être vide dans certains contextes (MockMvc @SpringBootTest)
        // On dérive le path depuis l'URI en retirant le context-path si nécessaire
        String servletPath = request.getServletPath();
        String path = (servletPath != null && !servletPath.isEmpty())
                ? servletPath
                : stripContextPath(request);

        if (isAllowedPath(path)) {
            chain.doFilter(request, response);
            return;
        }

        log.info("Request blocked by password-reset gate: path={}", path);
        errorWriter.write(response, HttpStatus.FORBIDDEN, "PASSWORD_RESET_REQUIRED",
                "Credentials reset required before accessing this resource.");
    }

    private String extractBearerToken(HttpServletRequest request) {
        String h = request.getHeader("Authorization");
        return (h != null && h.startsWith("Bearer ")) ? h.substring(7) : null;
    }

    /**
     * Vérifie si le path est dans la liste des paths autorisés.
     * Exact-match : le context-path est déjà retiré par stripContextPath si nécessaire.
     */
    private boolean isAllowedPath(String path) {
        return ALLOWED_PATHS.contains(path);
    }

    /**
     * Dérive le chemin de la requête depuis l'URI en retirant le context-path.
     * Fallback quand getServletPath() retourne une chaîne vide.
     */
    private String stripContextPath(HttpServletRequest request) {
        String uri = request.getRequestURI();
        String contextPath = request.getContextPath();
        if (contextPath != null && !contextPath.isEmpty() && uri.startsWith(contextPath)) {
            return uri.substring(contextPath.length());
        }
        return uri != null ? uri : "";
    }
}
