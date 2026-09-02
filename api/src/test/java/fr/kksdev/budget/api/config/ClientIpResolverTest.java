package fr.kksdev.budget.api.config;

import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Resolution de l'IP client (KKS-310).
 *
 * <p>Ces tests protegent la propriete dont depend toute l'efficacite du rate
 * limiting : {@code X-Forwarded-For} est fourni par le client, le croire sans
 * condition rendrait la limitation contournable en changeant sa valeur a chaque
 * requete.
 */
class ClientIpResolverTest {

    private static final List<String> TRUSTED = List.of("10.", "192.168.", "127.0.0.1");

    private HttpServletRequest request(String remoteAddr, String forwardedFor) {
        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getRemoteAddr()).thenReturn(remoteAddr);
        when(request.getHeader("X-Forwarded-For")).thenReturn(forwardedFor);
        return request;
    }

    @Test
    void should_use_forwarded_header_when_request_comes_from_trusted_proxy() {
        var resolver = new ClientIpResolver(TRUSTED);

        String ip = resolver.resolve(request("192.168.1.10", "203.0.113.7"));

        assertThat(ip).isEqualTo("203.0.113.7");
    }

    @Test
    void should_ignore_forwarded_header_when_request_comes_from_untrusted_source() {
        // Le coeur de la protection : un attaquant qui joint l'API directement
        // et forge l'en-tete reste compte sur son adresse TCP reelle.
        var resolver = new ClientIpResolver(TRUSTED);

        String ip = resolver.resolve(request("203.0.113.99", "1.2.3.4"));

        assertThat(ip).isEqualTo("203.0.113.99");
    }

    @Test
    void should_keep_same_ip_when_attacker_varies_the_forged_header() {
        // Sans cette propriete, il suffirait d'incrementer l'en-tete a chaque
        // requete pour obtenir un quota neuf a chaque fois.
        var resolver = new ClientIpResolver(TRUSTED);

        String first = resolver.resolve(request("203.0.113.99", "1.2.3.4"));
        String second = resolver.resolve(request("203.0.113.99", "5.6.7.8"));

        assertThat(first).isEqualTo(second);
    }

    @Test
    void should_take_first_hop_when_header_lists_several() {
        // "client, proxy1, proxy2" : le premier maillon est le client d'origine.
        var resolver = new ClientIpResolver(TRUSTED);

        String ip = resolver.resolve(request("10.0.0.1", "203.0.113.7, 10.0.0.5, 10.0.0.9"));

        assertThat(ip).isEqualTo("203.0.113.7");
    }

    @Test
    void should_fall_back_to_remote_address_when_header_is_absent() {
        var resolver = new ClientIpResolver(TRUSTED);

        assertThat(resolver.resolve(request("192.168.1.10", null))).isEqualTo("192.168.1.10");
        assertThat(resolver.resolve(request("192.168.1.10", "  "))).isEqualTo("192.168.1.10");
    }

    @Test
    void should_trust_nobody_when_list_is_empty() {
        // Instance exposee directement, sans proxy : aucune confiance accordee.
        var resolver = new ClientIpResolver(List.of());

        String ip = resolver.resolve(request("203.0.113.99", "1.2.3.4"));

        assertThat(ip).isEqualTo("203.0.113.99");
    }

    @Test
    void should_return_placeholder_when_remote_address_is_null() {
        var resolver = new ClientIpResolver(TRUSTED);

        assertThat(resolver.resolve(request(null, "1.2.3.4"))).isEqualTo("unknown");
    }
}
