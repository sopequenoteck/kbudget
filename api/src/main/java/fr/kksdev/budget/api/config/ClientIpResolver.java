package fr.kksdev.budget.api.config;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;

import java.util.List;

/**
 * Resout l'IP du client, en tenant compte des reverse proxies (KKS-310).
 *
 * <p><b>{@code X-Forwarded-For} n'est lu que si la requete vient d'un proxy de
 * confiance.</b> Cet en-tete est fourni par le client : n'importe qui peut
 * l'envoyer. Lu sans condition, il suffirait d'y mettre une valeur differente a
 * chaque requete pour contourner toute limitation — la protection serait
 * decorative.
 *
 * <p>La liste des proxies de confiance est configurable
 * ({@code TRUSTED_PROXIES}). Par defaut : les plages privees, qui couvrent le
 * deploiement fourni par le projet — Caddy et le container nginx joignent l'API
 * depuis le reseau Docker ou le LAN.
 *
 * <p>Une instance exposee directement sur Internet, sans proxy, ne fait
 * confiance a personne : l'IP retenue est l'adresse TCP reelle, non falsifiable.
 */
@Slf4j
public class ClientIpResolver {

    private static final String FORWARDED_FOR = "X-Forwarded-For";

    private final List<String> trustedProxyPrefixes;

    public ClientIpResolver(List<String> trustedProxies) {
        this.trustedProxyPrefixes = trustedProxies.stream().map(String::trim).toList();
        log.info("Client IP resolution trusts {} proxy prefix(es)", trustedProxyPrefixes.size());
    }

    /**
     * IP a laquelle imputer la requete.
     *
     * <p>Retourne le premier maillon de {@code X-Forwarded-For} — le client
     * d'origine — quand la requete arrive d'un proxy de confiance. Sinon
     * l'adresse TCP de l'appelant.
     */
    public String resolve(HttpServletRequest request) {
        String remoteAddr = request.getRemoteAddr();
        if (remoteAddr == null) {
            return "unknown";
        }
        if (!isTrustedProxy(remoteAddr)) {
            return remoteAddr;
        }

        String forwarded = request.getHeader(FORWARDED_FOR);
        if (forwarded == null || forwarded.isBlank()) {
            return remoteAddr;
        }

        // Format : "client, proxy1, proxy2". Le premier maillon est le client
        // d'origine ; les suivants sont les proxies traverses.
        String first = forwarded.split(",")[0].trim();
        return first.isEmpty() ? remoteAddr : first;
    }

    private boolean isTrustedProxy(String remoteAddr) {
        return trustedProxyPrefixes.stream().anyMatch(remoteAddr::startsWith);
    }
}
