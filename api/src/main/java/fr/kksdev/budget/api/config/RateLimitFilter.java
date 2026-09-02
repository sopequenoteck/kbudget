package fr.kksdev.budget.api.config;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Limite le debit sur les endpoints d'authentification (KKS-310).
 *
 * <p>Sans elle, {@code /auth/login} offre du bruteforce sans cout et
 * {@code /auth/invitations/{token}} permet d'enumerer des jetons d'invitation.
 * Acceptable derriere un reseau prive ; plus du tout des lors que des dizaines
 * d'instances sont exposees sur Internet.
 *
 * <p><b>La limitation porte sur l'IP, jamais sur le compte.</b> Verrouiller un
 * compte apres des echecs repetes ouvrirait un deni de service cible : il
 * suffirait de connaitre l'email de quelqu'un pour l'empecher de se connecter.
 *
 * <p>Compteurs en memoire : une instance self-hosted est un processus unique,
 * et la constitution (principe VII) tient PostgreSQL pour seule dependance
 * d'infrastructure. Un redemarrage remet les compteurs a zero — acceptable,
 * l'attaquant y gagne une fenetre, pas un contournement.
 */
@Slf4j
public class RateLimitFilter extends OncePerRequestFilter {

    /**
     * Chemins proteges, prefixe de version compris.
     *
     * <p>{@code /auth/logout} et {@code /auth/first-login-reset} en sont absents :
     * ils exigent deja un JWT valide, le cout d'une tentative n'est donc pas nul
     * pour l'attaquant.
     */
    private static final Set<String> PROTECTED_PATHS = Set.of(
            ApiVersioningConfig.CURRENT_VERSION_PREFIX + "/auth/login",
            ApiVersioningConfig.CURRENT_VERSION_PREFIX + "/auth/refresh",
            ApiVersioningConfig.CURRENT_VERSION_PREFIX + "/auth/accept-invite");

    /** Prefixe protege : le token variable interdit l'exact-match. */
    private static final String INVITATIONS_PREFIX =
            ApiVersioningConfig.CURRENT_VERSION_PREFIX + "/auth/invitations/";

    private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();
    private final ClientIpResolver ipResolver;
    private final ApiErrorWriter errorWriter;
    private final int capacity;
    private final Duration window;

    public RateLimitFilter(ClientIpResolver ipResolver, ApiErrorWriter errorWriter,
                           int capacity, Duration window) {
        this.ipResolver = ipResolver;
        this.errorWriter = errorWriter;
        this.capacity = capacity;
        this.window = window;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        if (!isProtected(path(request))) {
            filterChain.doFilter(request, response);
            return;
        }

        String ip = ipResolver.resolve(request);
        Bucket bucket = buckets.computeIfAbsent(ip, key -> newBucket());

        if (bucket.tryConsume(1)) {
            filterChain.doFilter(request, response);
            return;
        }

        log.warn("Rate limit exceeded: ip={} path={}", ip, path(request));
        errorWriter.write(response, HttpStatus.TOO_MANY_REQUESTS, "TOO_MANY_REQUESTS",
                "Trop de tentatives. Réessayez dans quelques instants.");
    }

    private Bucket newBucket() {
        return Bucket.builder()
                .addLimit(Bandwidth.builder().capacity(capacity).refillGreedy(capacity, window).build())
                .build();
    }

    private boolean isProtected(String path) {
        return PROTECTED_PATHS.contains(path) || path.startsWith(INVITATIONS_PREFIX);
    }

    /**
     * Chemin sans le context-path.
     *
     * <p>{@code getServletPath()} peut etre vide sous MockMvc : on retombe alors
     * sur l'URI, comme le font deja {@code AdminAuthorizationFilter} et
     * {@code PasswordResetRequiredFilter}.
     */
    private String path(HttpServletRequest request) {
        String servletPath = request.getServletPath();
        if (servletPath != null && !servletPath.isEmpty()) {
            return servletPath;
        }
        String uri = request.getRequestURI();
        String contextPath = request.getContextPath();
        if (contextPath != null && !contextPath.isEmpty() && uri != null && uri.startsWith(contextPath)) {
            return uri.substring(contextPath.length());
        }
        return uri != null ? uri : "";
    }
}
