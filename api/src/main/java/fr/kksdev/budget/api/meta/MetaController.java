package fr.kksdev.budget.api.meta;

import fr.kksdev.budget.api.config.ApiVersioningConfig;
import fr.kksdev.budget.api.dto.response.MetaResponse;
import fr.kksdev.budget.api.enums.Feature;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.info.BuildProperties;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;

/**
 * Expose la description du serveur pour la detection d'incompatibilité (KKS-314).
 *
 * <p><b>Ce controller vit volontairement hors du package
 * {@code fr.kksdev.budget.api.controller}</b> : {@link ApiVersioningConfig} y
 * préfixe tous les controllers avec la version d'API. Servi sous
 * {@code /api/v1/meta}, cet endpoint serait inutilisable — un client ne peut pas
 * deviner le prefixe du serveur qu'il interroge, c'est precisement ce qu'il
 * vient lui demander. Il reste donc sous {@code /api/meta}, quelle que soit la
 * version courante.
 *
 * <p>Public : un client doit pouvoir verifier la compatibilité avant d'avoir
 * des identifiants, et l'écran de configuration serveur s'en sert pour valider
 * l'URL saisie.
 */
@RestController
@RequestMapping("/meta")
@RequiredArgsConstructor
public class MetaController {

    private final BuildProperties buildProperties;

    /**
     * Version de client la plus ancienne acceptee par ce serveur.
     *
     * <p>Property et non constante : elle ne suit pas le rythme du code, elle ne
     * bouge qu'à une rupture de contrat. La coder en dur obligerait à la relire
     * à chaque release pour verifier qu'elle n'a pas derive.
     */
    @Value("${app.meta.min-client-version}")
    private String minClientVersion;

    @GetMapping
    public MetaResponse getMeta() {
        return new MetaResponse(
                buildProperties.getVersion(),
                ApiVersioningConfig.CURRENT_VERSION_PREFIX.substring(1),
                minClientVersion,
                capabilities());
    }

    /**
     * Fonctionnalites connues de cette version du serveur.
     *
     * <p>Ce n'est pas la liste de ce que l'utilisateur a active : c'est ce que le
     * serveur sait faire. Le client croise les deux — une fonctionnalite qu'il
     * connait mais que le serveur ignore doit etre masquee, sans quoi elle
     * echouerait a l'appel.
     */
    private List<String> capabilities() {
        return Arrays.stream(Feature.values()).map(Enum::name).toList();
    }
}
