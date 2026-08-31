package fr.kksdev.budget.api.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.method.HandlerTypePredicate;
import org.springframework.web.servlet.config.annotation.PathMatchConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Prefixe tous les endpoints metier avec la version d'API courante (KKS-313).
 *
 * <p>Le prefixe est applique globalement plutot que sur chacun des 18
 * {@code @RequestMapping} : le predicat cible le package des controllers, si
 * bien qu'un nouveau controller y est versionne sans intervention.
 *
 * <p>Le predicat porte sur le package et non sur l'annotation
 * {@code @RestController} : {@code HandlerTypePredicate} combine ses selecteurs
 * par OU, si bien qu'ajouter l'annotation elargirait la selection au lieu de la
 * restreindre. Les controllers des bibliotheques tierces seraient alors prefixes
 * eux aussi — springdoc expose {@code /v3/api-docs} de cette facon, et se
 * retrouvait servi sous {@code /v1/v3/api-docs}.
 *
 * <p>Ce qui est hors de ce package n'est pas prefixe, et c'est voulu :
 * {@code /actuator/**} (endpoints Boot), {@code /error}
 * ({@code BasicErrorController}), {@code /bank-logos/**} (ressources statiques),
 * {@code /ws/**} (handshake WebSocket) et la documentation OpenAPI restent hors
 * versionnement.
 *
 * <p>Spring Framework 7 fournit un versionnement natif
 * ({@code ApiVersionConfigurer}, attribut {@code version} sur les mappings).
 * Il n'est volontairement pas utilise ici : son {@code PathApiVersionResolver}
 * extrait la version d'un segment sans reecrire le chemin — un prefixe reste
 * donc necessaire — et il est concu pour faire coexister plusieurs versions,
 * ce que le projet exclut (une seule version servie a la fois).
 */
@Configuration
public class ApiVersioningConfig implements WebMvcConfigurer {

    /**
     * Version d'API courante, prefixee au chemin de tous les controllers.
     *
     * <p>Referencee par {@link SecurityConfig} et par les filtres qui comparent
     * des chemins ({@link AdminAuthorizationFilter},
     * {@link PasswordResetRequiredFilter}) : sans cela, un changement de version
     * desactiverait silencieusement leurs regles.
     */
    public static final String CURRENT_VERSION_PREFIX = "/v1";

    /** Package des controllers de l'application, seuls concernes par le prefixe. */
    private static final String CONTROLLER_BASE_PACKAGE = "fr.kksdev.budget.api.controller";

    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        configurer.addPathPrefix(
                CURRENT_VERSION_PREFIX,
                HandlerTypePredicate.forBasePackage(CONTROLLER_BASE_PACKAGE));
    }
}
