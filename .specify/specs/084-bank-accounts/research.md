# Research: Banques sur les comptes

**Date**: 2026-03-14
**Status**: Done (rétroactif)

## R1 — Stockage des banques : table BDD vs registre statique

- **Decision**: Registre statique de banques pré-définies embarqué dans le code (record Java `Bank` + `BankRegistry`)
- **Rationale**: Liste fixe de 29 banques, single-user, pas de CRUD dynamique nécessaire. Un record Java est plus simple qu'une table + migration + repository + service CRUD. Les logos sont des assets statiques, pas des données utilisateur.
- **Alternatives considered**:
  - Table `banks` en BDD : overhead inutile (migration, entity, repository, seed data) pour des données qui ne changent jamais en runtime
  - Enum Java : trop rigide pour les champs multiples (name, country, brandColor, logoUrl), enum ne supporte pas facilement l'ajout de nouvelles banques sans recompilation

## R2 — Stockage des logos custom : fichier serveur vs base64 en BDD

- **Decision**: Base64 data URI stocké en colonne TEXT (`bank_custom_logo`)
- **Rationale**: Application single-user self-hosted, pas de gestion de fichiers uploadés (pas de stockage objet, pas de CDN). Le base64 simplifie la synchronisation entre plateformes (Angular et Flutter reçoivent le même data URI via l'API).
- **Alternatives considered**:
  - Upload fichier sur le serveur : nécessite un volume persistant, un endpoint de téléchargement, un nettoyage des fichiers orphelins
  - Service de stockage cloud (S3, etc.) : contredit le principe VII (Self-Hosted Ready)
- **Mitigation taille** : compression côté client (512px Flutter via image_picker, 1024px Angular via canvas) avant envoi

## R3 — Résolution de l'affichage : cascade de fallback

- **Decision**: Cascade SVG banque connue → base64 custom → emoji fallback
- **Rationale**: Couvre 100% des cas sans erreur d'affichage. Les banques connues ont un logo SVG embarqué (assets statiques, pas de requête réseau). Les banques custom peuvent avoir un logo uploadé. Le fallback emoji garantit toujours un affichage.
- **Alternatives considered**:
  - Pas de fallback (erreur si logo manquant) : mauvaise UX
  - Icône générique pour toutes les banques : perd l'identité visuelle

## R4 — Endpoint GET /banks : public vs authentifié

- **Decision**: Endpoint public (pas d'authentification requise)
- **Rationale**: Données statiques, aucune information sensible. Permet au client de pré-charger la liste avant connexion si nécessaire. Cohérent avec le fait que les logos sont des assets publics servis en statique.
- **Alternatives considered**:
  - Endpoint authentifié : overhead inutile, les données sont les mêmes pour tous les utilisateurs

## R5 — Format des logos : SVG vs PNG vs WebP

- **Decision**: SVG
- **Rationale**: Scalable (retina, différentes tailles dans l'app), léger (282–9167 bytes), pas de pixelisation. Supporté nativement par Angular (img) et Flutter (flutter_svg déjà dans les dépendances).
- **Alternatives considered**:
  - PNG/WebP : nécessite plusieurs résolutions (@2x, @3x), fichiers plus lourds, pixelisation possible
