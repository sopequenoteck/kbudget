# Clarify Log — KKS-253 : Profil / Mon compte Flutter (alignement DESIGN.md v5)

> Date : 2026-05-22
> Issue : KKS-253
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md US-005, NC-1 | Comment câbler `currentAvatarUrl` dans `AvatarPicker` — modèle `User` sans `avatarUrl`, NFR-001 bloque l'ajout | 5 Intégrations | H | M | HAUT | US-005 différée hors scope — `currentAvatarUrl: null` conservé, initiales en fallback | Auto |
| CL-002 | spec.md FR-004, A-001, Q3 | Via quel provider appeler `updateName` — `UserProfileNotifier` n'expose que `updateCurrency` | 5 Intégrations | H | B | HAUT | `userProfileRepositoryProvider` + `updateName(name)` + `loadProfile()` refresh | Auto |
| CL-003 | spec.md NFR-002, A-002 | Quels tokens `AppThemeExtension` couvrent les besoins de settings-section/row | 7 Contraintes | M | M | MOYEN | `iconCircleBg` ✓, `primarySubtle` ✓, `incomeColor` ✓, `expenseColor` ✓ — containers : `colorScheme.surfaceContainerHighest` (convention settings existants) | Auto |
| CL-004 | spec.md NC-2, Q2 | `_CurrencySelector` retiré — migrer la sélection de devise ailleurs ou abandonner | 1 Scope | M | B | BAS | Confirmé par l'utilisateur : retrait sans migration. Accès via `CurrencyPillSelector` du Dashboard | Auto |
| CL-005 | spec.md FR-009 | Traduction de `border-bottom` entre rows en Flutter | 3 UX/Interaction | B | B | BAS | `Divider` avec hauteur 0 et couleur `colorScheme.outlineVariant` entre chaque `SettingsRow`, sauf dernier | Auto |

---

## Résolutions détaillées

### CL-001 — Avatar URL câblage (US-005 hors scope)

- **Catégorie** : 5 Intégrations
- **Score** : HAUT
- **Contexte** : `AvatarPicker` reçoit `currentAvatarUrl: null` (TODO dans le code). Le modèle `User` n'a pas de champ `avatarUrl`. `AvatarMetadata.url` est retourné après upload mais non persisté. `NFR-001` interdit de modifier la couche domain.
- **Analyse** : Résoudre proprement nécessite soit (A) ajouter `avatarUrl` au modèle `User` (interdit par NFR-001), soit (B) créer un `FutureProvider<String?>` appelant `GET /users/me/avatar` — nouvel endpoint/méthode repository, hors scope. `AvatarPicker` affiche déjà les initiales de façon gracieuse quand `currentAvatarUrl == null`. L'option "Supprimer la photo" disparaît du menu tap-long quand null (comportement correct : pas de photo à supprimer).
- **Décision** : US-005 différée. `currentAvatarUrl: null` conservé pour ce ticket. Ticket dédié requis pour `GET /users/me/avatar` + `avatarUrlProvider`.
- **Impact sur spec.md** : US-005 marquée "Hors scope — ticket dédié". FR-017 retiré. NC-1 remplacé par note. Q1 → Résolu.

### CL-002 — updateName via userProfileRepositoryProvider

- **Catégorie** : 5 Intégrations
- **Score** : HAUT
- **Contexte** : `UserProfileNotifier` n'expose que `updateCurrency(Currency)`. Pour le nom, il faut une autre voie. La spec dit d'appeler `userProfileNotifierProvider.notifier.updateProfile({name})` — méthode inexistante.
- **Analyse** : `UserProfileRepository.updateName(String name)` existe et est implémenté (`PUT /users/me {'name': name}`). Accessible via `userProfileRepositoryProvider.future`. Pattern identique à `_exportJson()`/`_exportCsv()` déjà dans le screen. Après `updateName`, appel `userProfileNotifierProvider.notifier.loadProfile()` pour synchroniser le state.
- **Décision** : Dans le state du screen : `(await ref.read(userProfileRepositoryProvider.future)).updateName(editedName.trim())` puis `ref.read(userProfileNotifierProvider.notifier).loadProfile()`. FR-004 mis à jour avec ce pattern précis.
- **Impact sur spec.md** : FR-004 mis à jour. A-001 mis à jour. Q3 → Résolu.

### CL-003 — Tokens AppThemeExtension disponibles

- **Catégorie** : 7 Contraintes
- **Score** : MOYEN
- **Contexte** : `AppThemeExtension` est la source de vérité tokens. Certains tokens Angular (`surface-default`, `text-tertiary`, `border-default`) n'ont pas de pendant direct dans l'extension.
- **Analyse** : Tokens disponibles : `iconCircleBg` (fond icônes neutres), `primarySubtle` (fond icône amber), `incomeColor` (fond icône verte), `expenseColor` (couleur danger). Pour `surface-default` (container section) : convention des screens settings existants (`feature_settings_screen.dart`, `settings_item.dart`) → `colorScheme.surfaceContainerHighest`. Pour `text-tertiary` → `colorScheme.onSurfaceVariant`. Pour `border-default` → `colorScheme.outlineVariant`.
- **Décision** : NFR-002 précisé : `AppThemeExtension` pour tokens custom, `colorScheme` (Material 3) pour tokens structurels (surface, text, border) en suivant la convention des screens settings existants.
- **Impact sur spec.md** : NFR-002 précisé. A-002 mis à jour.

### CL-004 — Sélecteur devise retiré sans migration

- **Catégorie** : 1 Scope fonctionnel
- **Score** : BAS
- **Contexte** : `_CurrencySelector` dans Flutter permet de changer la devise par défaut — fonctionnalité absente côté Angular. L'utilisateur a confirmé le retrait ("oui").
- **Analyse** : La modification de devise est accessible via `CurrencyPillSelector` dans le Dashboard — le changement persiste via `preferenceRemoteDataSourceProvider`. Retirer `_CurrencySelector` de Mon compte ne prive pas l'utilisateur de la fonctionnalité.
- **Décision** : `_CurrencySelector`, `_hasChanged`, `_isSaving`, bouton save AppBar supprimés. Aucune migration vers un autre écran. NC-2 / Q2 clos.
- **Impact sur spec.md** : NC-2 remplacé par note de décision. Q2 → Résolu.

### CL-005 — Border-bottom entre rows en Flutter

- **Catégorie** : 3 UX/Interaction
- **Score** : BAS
- **Contexte** : Le pattern Angular `border-bottom` entre rows dans un container n'est pas directement disponible en Flutter.
- **Analyse** : Convention des écrans settings existants : `Divider` avec `height: 0` et `thickness: 0.5`, couleur `colorScheme.outlineVariant`, inséré entre chaque row (pas après le dernier). Alternative : `DecoratedBox` avec `Border(bottom: BorderSide(...))` — plus verbeux.
- **Décision** : Utiliser `Divider(height: 0, thickness: 0.5, color: colorScheme.outlineVariant)` entre chaque row. FR-009 mis à jour.
- **Impact sur spec.md** : FR-009 mis à jour avec l'implémentation Flutter précise.

---

## Points différés

> Aucun point différé — tous les 5 points ont été résolus dans cette session.

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 5 |
| Catégories couvertes | 3/11 (Scope, Intégrations, Contraintes, UX) |
| Résolus automatiquement | 5 |
| Résolus interactivement | 0 |
| Différés | 0 |
| Modifications spec.md | 8 (US-005, FR-004, FR-017, NFR-002, A-001, A-002, Q1/Q2/Q3, NC-1/NC-2) |
