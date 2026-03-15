# Feature Specification: Synchronisation textScale via l'API

**Feature Branch**: `094-sync-text-scale-api`
**Created**: 2026-03-15
**Status**: Draft
**Input**: Synchroniser la préférence de taille de texte (SMALL/MEDIUM/LARGE) via l'API backend, même pattern que timezone/currencies/enabledNotificationTypes

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Persistance serveur de la taille de texte (Priority: P1)

L'utilisateur change la taille du texte dans Paramètres > Apparence. Le choix est sauvegardé sur le serveur dans ses préférences utilisateur, et non plus uniquement dans le navigateur. Quand il se connecte depuis un autre appareil ou navigateur, sa taille de texte préférée est automatiquement restaurée.

**Why this priority**: C'est le coeur de la feature — sans la persistance serveur, le réglage reste local et perdu au changement d'appareil.

**Independent Test**: Changer la taille en "Grand" sur un navigateur. Se connecter depuis un autre navigateur (ou navigation privée). La taille "Grand" est automatiquement appliquée.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est connecté, **When** il change la taille de texte en "Grand", **Then** le choix est envoyé au serveur et persisté dans ses préférences
2. **Given** l'utilisateur s'est déconnecté puis reconnecté, **When** l'application charge, **Then** la taille "Grand" est restaurée depuis le serveur et appliquée
3. **Given** l'utilisateur se connecte depuis un nouveau navigateur, **When** le dashboard s'affiche, **Then** la taille de texte correspond à celle sauvegardée sur le serveur
4. **Given** le serveur est injoignable lors du changement de taille, **When** l'utilisateur modifie la taille, **Then** le changement est appliqué localement immédiatement (optimistic update) et sera synchronisé au prochain appel réussi

---

### User Story 2 — Valeur par défaut pour les utilisateurs existants (Priority: P2)

Les utilisateurs existants qui n'ont jamais configuré de taille de texte reçoivent automatiquement la valeur "Normal" (MEDIUM). Aucune action requise de leur part — le système gère le défaut transparently.

**Why this priority**: Assure la rétro-compatibilité — les utilisateurs existants ne doivent voir aucun changement de comportement.

**Independent Test**: Se connecter avec un compte existant qui n'a jamais touché ce réglage. La taille doit être "Normal".

**Acceptance Scenarios**:

1. **Given** un utilisateur existant sans préférence textScale enregistrée, **When** il ouvre l'application, **Then** la taille par défaut est "Normal" (MEDIUM)
2. **Given** la base de données avec des enregistrements de préférences existants, **When** la migration s'exécute, **Then** tous les enregistrements reçoivent la valeur par défaut MEDIUM sans interruption de service

---

### Edge Cases

- Que se passe-t-il si le serveur renvoie une valeur inconnue (ex: "EXTRA_LARGE") ? Le frontend ignore la valeur et utilise "Normal" par défaut.
- Que se passe-t-il si la requête PUT échoue ? Le changement est appliqué localement (optimistic update), l'erreur est loggée silencieusement.
- Que se passe-t-il si l'utilisateur n'est pas encore connecté (écran de login) ? La taille de texte n'est pas appliquée — elle est chargée après l'authentification.
- Que se passe-t-il si deux onglets modifient la taille en même temps ? Le dernier PUT gagne (last-write-wins), même pattern que les autres préférences.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le serveur DOIT stocker la préférence textScale dans les préférences utilisateur avec 3 valeurs possibles : SMALL, MEDIUM, LARGE
- **FR-002**: La valeur par défaut DOIT être MEDIUM pour tous les utilisateurs (nouveaux et existants)
- **FR-003**: L'endpoint existant GET de préférences DOIT retourner le champ textScale dans sa réponse
- **FR-004**: L'endpoint existant PUT de préférences DOIT accepter le champ textScale (nullable — si absent, la valeur actuelle est conservée)
- **FR-005**: Le frontend DOIT envoyer la nouvelle valeur textScale au serveur quand l'utilisateur change la taille
- **FR-006**: Le frontend DOIT charger la valeur textScale depuis le serveur au démarrage et l'appliquer
- **FR-007**: Le changement de taille DOIT être appliqué immédiatement côté frontend (optimistic update) sans attendre la réponse serveur
- **FR-008**: La migration de base de données DOIT ajouter la colonne avec une valeur par défaut pour ne pas impacter les données existantes
- **FR-009**: Le scope est limité au backend et à l'application Angular — l'application Flutter N'EST PAS concernée

### Key Entities

- **UserPreference** : Entité existante enrichie d'un nouveau champ `textScale` (valeur parmi SMALL, MEDIUM, LARGE, défaut MEDIUM). Relation OneToOne avec User existante inchangée.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: La taille de texte est synchronisée entre navigateurs — un changement sur un appareil est visible sur un autre après reconnexion
- **SC-002**: Les utilisateurs existants voient "Normal" par défaut sans aucune action de leur part
- **SC-003**: Le changement de taille est appliqué en moins de 100ms côté frontend (optimistic update)
- **SC-004**: La migration de base de données s'exécute sans interruption de service et sans perte de données
- **SC-005**: Tous les tests existants (backend + frontend) passent sans modification
- **SC-006**: Le pattern de synchronisation est identique aux autres préférences (timezone, currencies) — pas de mécanisme ad-hoc

## Assumptions

- Le champ textScale suit exactement le même pattern que `timezone` dans UserPreference : champ simple avec valeur par défaut, nullable dans la requête PUT (partial update)
- La migration Flyway est la V21 (prochaine migration disponible)
- Le frontend Angular utilise le `PreferenceService` existant pour la synchronisation serveur, et le `TextScaleService` pour l'application CSS — les deux communiquent via signals
- Pas de mécanisme de sync temps réel (WebSocket) — la valeur est chargée au login et mise à jour au changement
- Le `localStorage` peut être conservé comme cache rapide (éviter un flash de taille incorrecte avant le chargement des préférences), mais la source de vérité est le serveur
