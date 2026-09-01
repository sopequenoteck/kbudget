package fr.kksdev.budget.api.dto.response;

import java.util.List;

/**
 * Description que le serveur donne de lui-meme (KKS-314).
 *
 * <p>Contrat le plus stable de l'API : c'est lui qui sert a detecter les
 * incompatibilites, il ne doit donc jamais casser. Aucun champ ne peut etre
 * retire ou renomme, y compris lors d'un changement de version majeure.
 *
 * @param serverVersion    version du serveur, derivee du build Maven
 * @param apiVersion       version d'API servie, sans le slash (ex. {@code v1})
 * @param minClientVersion version de client la plus ancienne acceptee
 * @param capabilities     fonctionnalites que cette version du serveur connait,
 *                         a croiser par le client avec les preferences utilisateur
 */
public record MetaResponse(
        String serverVersion,
        String apiVersion,
        String minClientVersion,
        List<String> capabilities
) {}
