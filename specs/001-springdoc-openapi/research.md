# Research: Documentation API OpenAPI / Swagger UI

**Branch**: `001-springdoc-openapi` | **Date**: 2026-02-07

## R1: Bibliotheque de documentation OpenAPI pour Spring Boot 4.x

**Decision**: springdoc-openapi-starter-webmvc-ui 3.0.1

**Rationale**:
- Version 3.0.1 supporte officiellement Spring Boot 4.0.x et Java 21
- Auto-configuration zero-config : ajouter la dependance suffit a exposer Swagger UI et la spec JSON
- Compatible Jackson 3 (utilise par Spring Boot 4)
- Package d'annotations : `io.swagger.v3.oas.annotations` (OpenAPI 3.1)
- Artefact Maven : `org.springdoc:springdoc-openapi-starter-webmvc-ui:3.0.1`

**Alternatives considerees**:
- springfox : abandonne, incompatible Spring Boot 3+
- springdoc 2.x : supporte Spring Boot 3.x uniquement, pas Spring Boot 4.x
- Fichier OpenAPI statique ecrit a la main : perd la synchronisation automatique avec le code

## R2: Routes a ouvrir dans SecurityConfig

**Decision**: Ajouter `/v3/api-docs/**`, `/swagger-ui/**` et `/swagger-ui.html` aux `requestMatchers.permitAll()`

**Rationale**:
- Les chemins sont relatifs au context-path `/api` dans la config Spring Security
- springdoc expose par defaut :
  - `/v3/api-docs` (spec JSON) et `/v3/api-docs/**` (sous-ressources)
  - `/swagger-ui.html` (redirect) et `/swagger-ui/**` (assets statiques)
- Sans ces routes en permitAll, les assets Swagger retournent 401/403

**Alternatives considerees**:
- Desactiver Spring Security pour le filtre sur ces chemins via WebSecurityCustomizer.ignoring() : fonctionne mais deconseille par Spring Security (bypass complet du filtre chain)

## R3: Configuration OpenAPI (metadata + securite JWT)

**Decision**: Creer une classe `OpenApiConfig` dans `config/` avec un bean `OpenAPI`

**Rationale**:
- Le bean `OpenAPI` de springdoc permet de definir :
  - `Info` : titre, description, version
  - `SecurityScheme` : type HTTP Bearer format JWT
  - `SecurityRequirement` : applique le schema JWT globalement
- Cela active le bouton "Authorize" dans Swagger UI pour saisir un token JWT
- Approche standard springdoc, pas de config YAML custom necessaire

**Alternatives considerees**:
- Config dans application.yaml via `springdoc.*` : ne permet pas de definir un SecurityScheme
- Annotations `@SecurityScheme` sur une classe : fonctionne mais moins lisible qu'un bean Java

## R4: Niveau d'annotations sur les controllers

**Decision**: Annotations minimales — `@Tag` sur les classes, `@Operation(summary=...)` sur les methodes

**Rationale**:
- springdoc auto-detecte deja : les chemins, methodes HTTP, parametres, request/response bodies, Bean Validation constraints, enums
- `@Tag` organise les endpoints en groupes lisibles (Authentification, Transactions, etc.)
- `@Operation(summary=...)` ajoute une phrase de resume par endpoint
- Pas de `@ApiResponse` detaille ni de `@Schema` sur les DTOs : les records Java + Bean Validation suffisent
- Conforme au principe III (YAGNI) de la constitution

**Alternatives considerees**:
- Annotations completes (@ApiResponse pour chaque code HTTP, @Schema sur chaque champ DTO) : surcharge le code pour un gain marginal, les types Java sont deja explicites
- Zero annotation : fonctionnel mais les groupements dans Swagger UI sont moins clairs (tout sous un seul tag par defaut)

## R5: Impact sur les tests existants

**Decision**: Aucune modification des tests necessaire

**Rationale**:
- springdoc est une dependance runtime qui expose de nouveaux endpoints, elle n'affecte pas les endpoints existants
- Les tests MockMvc existants ne chargent pas le contexte springdoc (ils mockent les services)
- L'ajout de `@Tag` et `@Operation` sont des annotations purement descriptives, sans impact comportemental
- La modification de SecurityConfig (ajout de routes permitAll) ne change pas le comportement des routes existantes

**Alternatives considerees**: N/A — aucun risque identifie
