# Clarify Log — KKS-232 : Onboarding contrôlé : flux d'invitation admin (remplace inscription publique)

> Date : 2026-04-19
> Issue : KKS-232
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md §US-007 + Q1 | Code HTTP exact pour le refus de désactivation du dernier admin | 6 Edge cases | M | B | MOYEN | 409 Conflict via `ConflictException` existante, payload `{ error: "LAST_ADMIN_CANNOT_BE_DISABLED", message: "..." }` | Auto |
| CL-002 | spec.md §US-008 + Q2 | Filtres / pagination à exposer sur `GET /api/admin/invitations` | 1 Scope fonctionnel | M | M | MOYEN | Pas de pagination ni de filtres serveur en v1 (YAGNI). Tri serveur `createdAt DESC`, statut dérivé dans le DTO, filtrage côté client | Auto |
| CL-003 | spec.md §Q3 | Granularité audit log actions admin (logs INFO dédiés vs table d'audit) | 4 Non-fonctionnel | M | M | MOYEN | Logs SLF4J INFO standards (NFR-002) — format `"Admin action: <action> by <adminEmail> target=<resource>:<id>"`. Pas de table d'audit dédiée en v1 | Auto |
| CL-004 | spec.md §Q4 | Layout exact de la page publique `/accept-invite/:token` | 3 UX/Interaction | B | M | BAS | Reporté à la phase `/devflow.plan` + `design-coherence`. Contrat fonctionnel figé dans US-002 / US-013 / FR-022-023 | Auto |
| CL-005 | spec.md §Q5 | Comportement si `ADMIN_EMAILS` vide ou sans user actif correspondant | 6 Edge cases | B | B | BAS | WARN SLF4J au boot dans `AdminEmailResolver`. Rien en runtime (403 natif sur endpoints admin) | Auto |

## Résolutions détaillées

### CL-001 — Code HTTP refus garde-fou dernier admin

- **Catégorie** : 6 Edge cases
- **Score** : MOYEN (Impact M × Incertitude B)
- **Contexte** : La spec marquait `[NEEDS CLARIFICATION]` sur le choix entre 400, 409 et 422 pour le refus du self-disable du dernier admin.
- **Analyse** :
  - Consultation de `api/src/main/java/fr/kksdev/budget/api/exception/ConflictException.java` + `config/GlobalExceptionHandler.java` — le projet dispose déjà d'un pattern `ConflictException → 409`.
  - Convention REST : 409 Conflict signale un conflit d'état empêchant l'opération, ce qui correspond exactement au cas "règle métier : le dernier admin ne peut pas être désactivé".
  - 400 Bad Request serait un faux signal (la requête est syntaxiquement valide).
  - 422 Unprocessable Entity (WebDAV) est peu utilisé côté frontend Angular / Flutter du projet.
- **Décision** : Retourner **HTTP 409 Conflict** avec payload `{ error: "LAST_ADMIN_CANNOT_BE_DISABLED", message: "Impossible de désactiver le dernier admin actif." }`.
- **Impact sur spec.md** :
  - US-007 : `[NEEDS CLARIFICATION]` remplacé par la résolution.
  - FR-017 : précisé avec `ConflictException` + payload.
  - SC-008 : reformulé en critère testable `error=LAST_ADMIN_CANNOT_BE_DISABLED`.
  - Q1 : statut `Résolu` + réponse.

### CL-002 — Filtres / pagination `GET /api/admin/invitations`

- **Catégorie** : 1 Scope fonctionnel
- **Score** : MOYEN (Impact M × Incertitude M)
- **Contexte** : L'issue Linear indiquait "filtres à définir" et la spec marquait `[NEEDS CLARIFICATION]` sur la combinatoire (statut, email, invitedBy, pagination).
- **Analyse** :
  - Principe III (YAGNI) + constitution §"Contexte d'usage" : instance ~10-20 comptes actifs. Volume d'invitations attendu : quelques dizaines max sur la durée de vie de l'instance.
  - Une liste non paginée est suffisante et idiomatique pour ce volume.
  - Le filtrage par statut est la seule dimension pertinente côté UX (les listes Angular / Flutter permettront de masquer les entrées `USED` / `REVOKED`).
- **Décision** :
  - Pas de pagination serveur en v1.
  - Pas de query param de filtre serveur.
  - Tri serveur : `createdAt DESC`.
  - Statut dérivé (`ACTIVE` / `EXPIRED` / `USED` / `REVOKED`) calculé dans le DTO `InvitationResponse`.
  - Filtrage par statut assuré côté client (Angular + Flutter).
- **Impact sur spec.md** :
  - US-008 : `[NEEDS CLARIFICATION]` remplacé, enum `status` ajoutée.
  - Q2 : statut `Résolu` + réponse.

### CL-003 — Granularité audit log actions admin

- **Catégorie** : 4 Non-fonctionnel (observabilité)
- **Score** : MOYEN (Impact M × Incertitude M)
- **Contexte** : La spec marquait `[NEEDS CLARIFICATION]` sur la question d'ajouter une table ou un stream d'audit dédié pour les actions admin.
- **Analyse** :
  - Principe VI : tous les endpoints DOIVENT logger en INFO (création / modification / suppression) via SLF4J.
  - NFR-002 couvre déjà les 6 événements clés (création / révocation / acceptation invitation + disable / enable user + refus garde-fou).
  - Principe III (YAGNI) : ajouter une table `audit_log` serait de la sur-ingénierie pour une instance self-hosted à ~16 users où les logs applicatifs sont directement lisibles par l'admin.
- **Décision** :
  - Logs SLF4J INFO standards suffisent.
  - Format unifié : `"Admin action: <action> by <adminEmail> target=<resource>:<id>"`.
  - Pas de table d'audit dédiée en v1.
- **Impact sur spec.md** :
  - NFR-002 : format de log précisé.
  - Q3 : `[NEEDS CLARIFICATION]` retiré, statut `Résolu`.

### CL-004 — Layout page publique `/accept-invite/:token`

- **Catégorie** : 3 UX/Interaction
- **Score** : BAS (Impact B × Incertitude M)
- **Contexte** : Question ouverte Q4 sur le branding, le contenu avant le formulaire, le message post-soumission.
- **Analyse** :
  - Le contrat fonctionnel est complet dans US-002, US-013 et FR-022 / FR-023 : email verrouillé, 4 champs de saisie, auto-login → dashboard.
  - Le layout visuel relève de la phase `/devflow.plan` (où `design-coherence` intervient pour garantir la conformité avec `DESIGN.md`).
- **Décision** : Reporter à la phase plan. Pas de modification du contrat fonctionnel dans spec.md.
- **Impact sur spec.md** :
  - Q4 : statut `Résolu`, report explicite vers phase plan + `design-coherence`.

### CL-005 — Comportement `ADMIN_EMAILS` vide / sans match

- **Catégorie** : 6 Edge cases
- **Score** : BAS (Impact B × Incertitude B)
- **Contexte** : Question ouverte Q5. A-002 suggérait déjà un WARN au boot.
- **Analyse** :
  - Si `ADMIN_EMAILS` est vide OU si aucun user actif (non `disabled_at`) ne correspond → aucun admin ne peut émettre d'invitation (deadlock), sauf à redémarrer avec la bonne variable d'env.
  - Pas de mitigation à chaud sans endpoint bootstrap (hors scope, ticket séparé).
  - Le garde-fou naturel est le 403 renvoyé par `/api/admin/*` — aucune action fausse possible.
  - Un WARN au boot améliore le diagnostic sans complexité additionnelle.
- **Décision** :
  - `AdminEmailResolver` émet un `log.warn(...)` au boot si la liste est vide OU si aucun user actif n'y correspond.
  - Message : `"ADMIN_EMAILS not configured or no matching active user — invitations cannot be issued until an admin is configured."`
  - Aucun comportement additionnel en runtime.
- **Impact sur spec.md** :
  - NFR-008 : précision du WARN au boot ajoutée.
  - Q5 : statut `Résolu`.

## Points différés

> Points non résolus dans cette session (au-delà du top 5), à traiter lors d'une prochaine itération.

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Raison du report |
|---|--------|-----------------|-----------|--------|-------------|-------|------------------|
| — | — | Aucun point différé. Les 5 points identifiés ont tous été résolus. | — | — | — | — | — |

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 5 |
| Catégories couvertes | 3 / 11 (Scope fonctionnel, Non-fonctionnel, UX/Interaction, Edge cases) |
| Résolus automatiquement | 5 |
| Résolus interactivement | 0 |
| Différés | 0 |
| Modifications spec.md | 8 (US-007, US-008, FR-017, NFR-002, NFR-008, SC-008, Q1-Q5) |
