# Spec — KKS-253 : Profil / Mon compte Flutter (alignement DESIGN.md v5)

> Date : 2026-05-22
> Issue : KKS-253
> Priorité : High (P2)
> Labels : Feature
> Parent : KKS-242

---

## Contexte

L'écran `ProfileSettingsScreen` Flutter (586L) présente plusieurs déviations par rapport à la source de vérité Angular (`mon-compte.component.html`) :
- Le nom est affiché en lecture seule (`_ReadOnlyField`) au lieu d'être éditable inline
- Les exports JSON/CSV n'ont pas de spinners individuels ni de désactivation croisée
- Le pattern visuel (`settings-section` / `settings-row` avec icônes circulaires, chevrons, container fond) est absent
- Un `_CurrencySelector` non présent côté Angular encombre l'écran
- Les tokens `theme.colorScheme.*` sont utilisés au lieu de `AppThemeExtension`
- Aucun error banner global (remplacé par des SnackBars isolés)

L'objectif est d'aligner `profile_settings_screen.dart` sur Angular v5, section par section.

---

## User Stories

### P1 — Critiques

- **US-001** : En tant qu'utilisateur, je veux éditer mon nom directement dans l'écran profil, afin de le modifier sans naviguer vers un autre écran.
  - **Why this priority** : Fonctionnalité présente dans Angular, absente Flutter — delta fonctionnel visible.
  - **Given** : L'écran profil est chargé, la section Identité est visible
  - **When** : L'utilisateur tape l'icône crayon (pencil) à droite du nom
  - **Then** : Un input inline apparaît avec le nom actuel pré-rempli, et deux boutons (save vert, cancel gris) — Enter sauvegarde, Escape annule
  - **Independent Test** : Naviguer vers Mon compte, tapper le crayon, modifier le nom, tapper le bouton save → le nouveau nom s'affiche

- **US-002** : En tant qu'utilisateur, je veux voir l'écran Mon compte structuré en sections visuelles avec le pattern `settings-section`, afin d'avoir une expérience cohérente avec Angular v5.
  - **Why this priority** : Alignement tokens v5 = objectif premier de la série KKS-242.x — impact visuel majeur.
  - **Given** : L'écran est ouvert
  - **When** : L'utilisateur consulte les 4 sections (Identité, Sécurité, Données, Danger)
  - **Then** : Chaque section a un label uppercase gris, un container `surface-default` avec `border-radius-xl`, des rows avec icônes circulaires 36px colorées, des chevrons, et des séparateurs entre rows
  - **Independent Test** : Vérifier visuellement les 4 sections — containers arrondis, icônes colorées, chevrons présents

### P2 — Importantes

- **US-003** : En tant qu'utilisateur, je veux voir un spinner individuel sur le bouton d'export en cours et les deux boutons désactivés pendant l'export, afin de savoir qu'un téléchargement est en cours et d'éviter les doubles exports.
  - **Why this priority** : Alignement fonctionnel Angular — protection UX contre les doubles clics.
  - **Given** : La section Données est visible
  - **When** : L'utilisateur tape "Exporter mes données (JSON)"
  - **Then** : Un indicateur de chargement apparaît dans la row JSON, le sous-titre change en "Téléchargement en cours…", les deux rows export sont désactivées
  - **Independent Test** : Mocker un export lent, vérifier le spinner + désactivation croisée

- **US-004** : En tant qu'utilisateur, je veux voir un bandeau d'erreur global en haut de l'écran si une action échoue, afin d'avoir un retour clair sans que le message disparaisse automatiquement.
  - **Why this priority** : Alignement comportement Angular — les SnackBars disparaissent trop vite pour les erreurs critiques.
  - **Given** : L'utilisateur est sur l'écran Mon compte
  - **When** : Une action échoue (upload avatar, sauvegarde nom, export)
  - **Then** : Un bandeau rouge apparaît sous le header avec le message d'erreur — il reste visible jusqu'à la prochaine action réussie ou navigation
  - **Independent Test** : Simuler une erreur réseau, vérifier que le bandeau s'affiche et reste

### P3 — Nice to have

- **US-005** : ~~En tant qu'utilisateur, je veux que mon avatar actuel soit affiché dans `AvatarPicker`~~ — **HORS SCOPE (CL-001)** : `currentAvatarUrl: null` conservé. NFR-001 interdit l'ajout de `avatarUrl` au modèle `User`. Ticket dédié requis pour `GET /users/me/avatar` + `avatarUrlProvider`. `AvatarPicker` affiche les initiales en fallback.

---

## Requirements fonctionnels

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-001 | Inline name edit : row Nom avec trigger pencil (icône crayon) à droite | P1 | US-001 |
| FR-002 | Inline name edit : tap pencil → input pré-rempli + bouton save (vert) + bouton cancel (gris) | P1 | US-001 |
| FR-003 | Inline name edit : Enter → save, Escape → cancel, trim + non vide + max 100 chars | P1 | US-001 |
| FR-004 | Sauvegarde nom : `(await ref.read(userProfileRepositoryProvider.future)).updateName(name.trim())` puis `ref.read(userProfileNotifierProvider.notifier).loadProfile()` | P1 | US-001 |
| FR-005 | Structure settings-section : 4 sections (Identité, Sécurité, Données, Zone de danger) | P1 | US-002 |
| FR-006 | Section label uppercase gris (`text-tertiary`, `font-size-xs`, `font-weight-semibold`) | P1 | US-002 |
| FR-007 | Container section : fond `surface-default`, `border-radius-xl`, overflow hidden | P1 | US-002 |
| FR-008 | Rows avec icônes circulaires 36px (fond coloré selon section), title/description, chevron trailing | P1 | US-002 |
| FR-009 | Séparateurs : `Divider(height: 0, thickness: 0.5, color: colorScheme.outlineVariant)` entre chaque row (absent après le dernier) | P1 | US-002 |
| FR-010 | Section Danger zone : row Logout (neutre), row Delete account (titre rouge, sans icône) | P1 | US-002 |
| FR-011 | Supprimer `_CurrencySelector`, `_hasChanged`, `_isSaving`, bouton save dans l'AppBar | P1 | US-002 |
| FR-012 | Export JSON : spinner individuel (`isExportingJson`) + sous-titre "Téléchargement en cours…" | P2 | US-003 |
| FR-013 | Export CSV : spinner individuel (`isExportingCsv`) + sous-titre "Téléchargement en cours…" | P2 | US-003 |
| FR-014 | Désactivation croisée exports : les deux rows désactivées si `isExportingJson \|\| isExportingCsv` | P2 | US-003 |
| FR-015 | Error banner global : bandeau rouge inline sous le header si `_errorMessage != null` | P2 | US-004 |
| FR-016 | Error banner effacé automatiquement au début de chaque nouvelle action | P2 | US-004 |
| FR-017 | ~~Avatar câblage~~ — **HORS SCOPE (CL-001)** : `currentAvatarUrl: null` conservé, ticket dédié requis | — | US-005 |

---

## Requirements non-fonctionnels

| ID | Description | Catégorie |
|----|-------------|-----------|
| NFR-001 | Aucune modification des couches data/domain : `UserProfileRepository`, modèle `User`, `UserProfileNotifier` (seul `updateProfile` peut être appelé si déjà exposé) | Architecture |
| NFR-002 | Tokens `AppThemeExtension` pour tokens custom (`iconCircleBg`, `primarySubtle`, `incomeColor`, `expenseColor`) + `colorScheme` Material 3 pour tokens structurels (`surfaceContainerHighest` pour containers, `onSurfaceVariant` pour texte tertiaire, `outlineVariant` pour séparateurs) — convention établie dans les screens settings existants | Design tokens |
| NFR-003 | `ChangePasswordSheet` et `DeleteAccountSheet` conservés sans modification | Compatibilité |
| NFR-004 | `AvatarPicker` conservé sans modification de son interface publique | Compatibilité |
| NFR-005 | `ProfileSettingsSkeleton` conservé ou adapté (structure sections) | Compatibilité |
| NFR-006 | Tests widget : couverture des 3 comportements clés (inline edit, export spinner, error banner) | Qualité |

---

## Contraintes et dépendances

- **Contraintes techniques** :
  - `User` model n'expose pas `avatarUrl` — câblage avatar conditionnel à la résolution de la clarification
  - `updateProfile` doit exister sur `userProfileNotifierProvider.notifier` (ou équivalent)
  - `_CurrencySelector` retiré définitivement (CL-004 — confirmé utilisateur). La modification de devise par défaut reste accessible via `CurrencyPillSelector` du Dashboard (persiste via `preferenceRemoteDataSourceProvider`)
- **Dépendances internes** :
  - `userProfileNotifierProvider` (application layer)
  - `userProfileRepositoryProvider` (export JSON/CSV)
  - `AppThemeExtension`, `AppColors`, `AppSpacing`, `AppRadius` (design tokens)
  - `ChangePasswordSheet`, `DeleteAccountSheet`, `AvatarPicker` (widgets existants)

---

## Questions ouvertes

| # | Question | Statut | Réponse |
|---|----------|--------|---------|
| Q1 | L'URL de l'avatar actuel est-elle accessible via le profil User ou via un endpoint dédié ? | Résolu (CL-001) | US-005 hors scope — `currentAvatarUrl: null` conservé, ticket dédié requis pour GET /users/me/avatar |
| Q2 | La sélection de devise par défaut retirée de cet écran — migrer ou abandonner sur mobile ? | Résolu (CL-004) | Retrait sans migration — accès conservé via CurrencyPillSelector Dashboard |
| Q3 | `updateProfile` est-il déjà exposé sur `userProfileNotifierProvider.notifier` pour le nom ? | Résolu (CL-002) | Non — utiliser `userProfileRepositoryProvider` + `updateName(name)` + `loadProfile()` |

---

## Success Criteria

| ID | Description | Méthode de vérification | User Story |
|----|-------------|------------------------|------------|
| SC-001 | Tap pencil → input inline visible avec nom actuel pré-rempli | Widget test | US-001 |
| SC-002 | Enter ou tap save → nom mis à jour, input fermé, nom affiché | Widget test | US-001 |
| SC-003 | Escape ou tap cancel → input fermé, nom inchangé | Widget test | US-001 |
| SC-004 | 4 sections visibles avec container arrondi surface-default et label uppercase | Manuel | US-002 |
| SC-005 | Icônes circulaires colorées présentes dans les rows Sécurité et Données | Manuel | US-002 |
| SC-006 | `_CurrencySelector` absent, AppBar sans bouton save | Widget test | US-002 |
| SC-007 | Tap Export JSON → spinner visible dans la row JSON, sous-titre "Téléchargement en cours…" | Widget test | US-003 |
| SC-008 | Pendant export JSON : row CSV également désactivée | Widget test | US-003 |
| SC-009 | Erreur action → bandeau rouge visible sous le header, reste jusqu'à prochaine action | Widget test | US-004 |
| SC-010 | `flutter analyze lib/src/features/user_profile/` → No issues | Auto | Transverse |
| SC-011 | `flutter test test/src/features/user_profile/` → tous PASS, aucune régression | Auto | Transverse |

---

## Key Entities

| Entité | Description | Relations principales |
|--------|-------------|----------------------|
| `User` | Profil utilisateur (`email`, `name`, `defaultCurrency`) | Chargé via `userProfileNotifierProvider` |
| `UserProfileRepository` | Interface data : `getProfile()`, `updateProfile()`, `exportJson()`, `exportCsv()`, `deleteAccount()` | Implémenté par `UserProfileRepositoryRemote` |
| `UserProfileNotifier` | State management du profil (`loadProfile()`, `updateProfile()`) | Expose `AsyncValue<User>` |

---

## Assumptions

| # | Hypothèse | Impact si fausse | Validation prévue |
|---|-----------|-----------------|-------------------|
| A-001 | `UserProfileNotifier` expose déjà `updateProfile({name})` ou le repository expose `updateProfile(UpdateProfileRequest)` | — | **Résolu (CL-002)** : `UserProfileNotifier` n'expose pas `updateName`. Utiliser `userProfileRepositoryProvider` + `UserProfileRepository.updateName(String)` (PUT /users/me) + `loadProfile()` |
| A-002 | Les tokens `AppThemeExtension` couvrent toutes les couleurs nécessaires | — | **Résolu (CL-003)** : `iconCircleBg` ✓, `primarySubtle` ✓, `incomeColor` ✓, `expenseColor` ✓. Manquants → `colorScheme.surfaceContainerHighest` (containers), `colorScheme.onSurfaceVariant` (text-tertiary), `colorScheme.outlineVariant` (border) |
| A-003 | Le retrait de `_CurrencySelector` ne casse pas de test existant hors du screen | Si test existant dépend du selector : le supprimer aussi | **Résolu (CL-004)** : confirmé — retrait sans régression attendue. Tests screen à adapter lors de l'implémentation |
