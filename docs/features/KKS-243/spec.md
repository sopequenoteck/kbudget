# Spec — KKS-243 : Phase 1 / Étape 7 — Refonte 3 écrans S Flutter

> Date : 2026-05-27
> Issue : KKS-243
> Priorité : High (2)
> Labels : Feature

---

## Contexte

Trois écrans Flutter existants et fonctionnels utilisent des tokens Material bruts (`colorScheme.surfaceContainerHighest`, `theme.textTheme.titleSmall`, `FontWeight.w600` hardcodés, etc.) au lieu des tokens design system v5 (AppTypography, AppColors, AppThemeExtension). Les `AlertDialog` natifs doivent être remplacés par `ConfirmDialogCustom` (KKS-238). La couche data (notifiers, repositories) est correcte et n'est pas dans le périmètre.

Les 3 écrans cibles :
1. **Catégories liste** — `category_list_screen.dart` + `category_list_tile.dart`
2. **Settings données** — `data_settings_screen.dart`
3. **Devises & Taux** — `currency_settings_screen.dart`

**Dépendance** : KKS-246 terminé (hub intégré livré, `ConfirmDialogCustom`, `EmptyStateWidget`, `PageHeader` disponibles).

---

## User Stories

### P1 — Critiques

- **US1** : En tant qu'utilisateur, je vois la liste de mes catégories avec les tokens design v5 (couleurs, typographie, surfaces) cohérents avec le reste de l'app.
  - **Why this priority** : Conformité design system — l'incohérence visuelle est visible à chaque ouverture de l'écran.
  - **Given** l'app ouverte, l'utilisateur dans Réglages → Catégories
  - **When** il consulte la liste des catégories
  - **Then** les tiles utilisent les surfaces/textes/couleurs du design system v5 (pas de `colorScheme.surfaceContainerHighest`, pas de Material brut), l'état vide utilise `EmptyStateWidget`
  - **Independent Test** : Ouvrir `/settings/categories` — vérifier visuellement la cohérence avec le hub KKS-246. `flutter analyze` sans warning.

- **US2** : En tant qu'utilisateur, je vois l'écran de configuration des données (mode Local/Serveur + URL) avec les tokens design v5.
  - **Why this priority** : Conformité design system — labels de section et typographie incohérents avec le reste de l'app.
  - **Given** l'utilisateur dans Réglages → Données (depuis le hub)
  - **When** il consulte ou modifie le mode de données ou l'URL serveur
  - **Then** les labels de section utilisent `AppTypography`, les tokens couleurs sont ceux du design system, la confirmation de changement de mode utilise `ConfirmDialogCustom`. Le `TextField` avec `OutlineInputBorder()` est conservé tel quel (écran Flutter-only sans équivalent Angular — pas de référence de style à aligner). L'écran utilise `PageHeader` en remplacement de l'`AppBar` générique.
  - **Independent Test** : Ouvrir `/settings/data` — vérifier la typographie des sections. Tenter un changement de mode → vérifier que `ConfirmDialogCustom` apparaît.

- **US3** : En tant qu'utilisateur, je vois l'écran Devises & Taux avec les tokens design v5 et le pattern liste conforme (pas de cards individuelles).
  - **Why this priority** : DESIGN.md v5 stipule explicitement "Conteneur arrondi surface-default + radius-xl. Items séparés par border-default 1px. Pas de cards individuelles." — les `Card(color: colorScheme.surfaceContainerHighest)` sont une violation directe.
  - **Given** l'utilisateur dans Réglages → Comptes & Devises → Devises & Taux
  - **When** il consulte les taux de conversion
  - **Then** les taux sont affichés en lignes séparées par `border-default` dans un conteneur `surface-default`, sans `Card`, et les confirmations (suppression taux, retrait devise) utilisent `ConfirmDialogCustom`. Les boutons "Ajouter une devise" et "Ajouter un taux" sont remplacés par des boutons `+` circulaires 28px dans les headers de section (pattern Angular `add-btn`). L'écran utilise `PageHeader` en remplacement de l'`AppBar` générique.
  - **Independent Test** : Ouvrir `/settings/accounts/currency` — vérifier que les taux ne sont plus dans des cards Material. Supprimer un taux → vérifier `ConfirmDialogCustom`. Vérifier que les boutons `+` sont dans les headers de section.

---

## Requirements fonctionnels

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-001 | Remplacer `colorScheme.surfaceContainerHighest` et `colorScheme.onSurface` par les tokens AppColors/AppThemeExtension dans `CategoryListTile` | P1 | US1 |
| FR-002 | Remplacer l'état vide ad hoc (`Column` avec `PhosphorIcon` + `Text`) par `EmptyStateWidget` dans `CategoryListScreen` | P1 | US1 |
| FR-003 | Remplacer les labels de section (`theme.textTheme.titleSmall?.copyWith(...)`) par `AppTypography` constants dans `DataSettingsScreen` | P1 | US2 |
| FR-004 | Remplacer `FontWeight.w600` hardcodé par `AppTypography.semibold` dans `DataSettingsScreen` | P1 | US2 |
| FR-005 | Remplacer `AlertDialog` natif par `ConfirmDialogCustom` dans `DataSettingsScreen` (confirmation changement de mode) | P1 | US2 |
| FR-006 | Remplacer `Card(color: colorScheme.surfaceContainerHighest)` par pattern liste (`surface-default` + `border-default` 1px) pour les taux dans `CurrencySettingsScreen` | P1 | US3 |
| FR-007 | Remplacer les labels de section (`theme.textTheme.titleSmall?.copyWith(...)`) par `AppTypography` constants dans `CurrencySettingsScreen` | P1 | US3 |
| FR-008 | Remplacer `AlertDialog` natif (suppression taux + retrait devise) par `ConfirmDialogCustom` dans `CurrencySettingsScreen` | P1 | US3 |
| FR-009 | Conserver `RateCalculator` sans modification (Flutter-only, pas d'équivalent Angular, conforme) | — | — |
| FR-010 | Remplacer `AppBar` générique par `PageHeader` (KKS-238) dans les 3 écrans : `CategoryListScreen`, `DataSettingsScreen`, `CurrencySettingsScreen` — alignement pattern `page-header` Angular | P1 | US1, US2, US3 |
| FR-011 | Remplacer `OutlinedButton.icon` "Ajouter une devise" et "Ajouter un taux" par des boutons `+` circulaires 28px dans les headers de section dans `CurrencySettingsScreen` — pattern Angular `add-btn` | P1 | US3 |

---

## Requirements non-fonctionnels

| ID | Description | Catégorie |
|----|-------------|-----------|
| NFR-001 | `flutter analyze` sans warning après toutes les modifications | Qualité |
| NFR-002 | Aucune régression fonctionnelle : les 3 écrans doivent rester pleinement opérationnels (chargement, actions CRUD, navigation) | Fiabilité |
| NFR-003 | Aucune modification de la couche data (notifiers, repositories, modèles Freezed) | Architecture |
| NFR-004 | Les tokens utilisés doivent être uniquement ceux du design system v5 (AppTypography, AppColors, AppThemeExtension, AppSpacing, AppRadius) — zéro valeur hardcodée | Conformité design |

---

## Contraintes et dépendances

- **Contraintes techniques** :
  - Seuls les fichiers de présentation listés dans le plan sont modifiables
  - Les fichiers `.freezed.dart` et `.g.dart` ne sont jamais modifiés manuellement
  - Pas de `build_runner` requis (aucun modèle Freezed touché)

- **Dépendances externes** :
  - KKS-246 terminé (livré) — `ConfirmDialogCustom`, `EmptyStateWidget` disponibles dans `common_widgets`
  - KKS-238 terminé — `PageHeader`, `EmptyStateWidget` disponibles

- **Dépendances internes** :
  - `flutter/lib/src/common_widgets/confirm_dialog_custom.dart` — `ConfirmDialogCustom`
  - `flutter/lib/src/common_widgets/empty_state_widget.dart` — `EmptyStateWidget`
  - `flutter/lib/src/constants/app_typography.dart` — `AppTypography`
  - `flutter/lib/src/constants/app_colors.dart` — `AppColors`
  - `flutter/lib/src/theme/app_theme_extension.dart` — `AppThemeExtension`

---

## Questions ouvertes

| # | Question | Statut | Réponse |
|---|----------|--------|---------|
| Q1 | PageHeader vs AppBar : les 3 écrans doivent-ils migrer vers `PageHeader` (KKS-238) ou l'AppBar Flutter standard est-il acceptable ? | Résolu | **PageHeader obligatoire** — tous les sous-écrans Angular (`categories.html`, `accounts.html`) utilisent le pattern `page-header` avec back button + titre + icône. `PageHeader` Flutter = équivalent direct. |
| Q2 | TextField avec `OutlineInputBorder()` dans DataSettingsScreen : conforme v5 ou à remplacer ? | Résolu | **OutlineInputBorder acceptable** — `DataSettingsScreen` est Flutter-only (pas de route `data` dans `settings.routes.ts` Angular). Aucune référence Angular pour le style d'input. |
| Q3 | Boutons "Ajouter une devise" / "Ajouter un taux" (`OutlinedButton.icon`) : acceptable ou à remplacer ? | Résolu | **Non-conforme** — Angular utilise un bouton `+` circulaire 28px (`add-btn`) dans les headers de section (`CurrencyList`, `ExchangeRateManager`). `OutlinedButton.icon` en pied de section ne correspond pas au pattern. |

---

## Success Criteria

| ID | Description | Méthode de vérification | User Story |
|----|-------------|------------------------|------------|
| SC-001 | `flutter analyze` sans warning après modifications | Auto — `flutter analyze` | Toutes |
| SC-002 | Zéro occurrence de `colorScheme.surfaceContainerHighest`, `colorScheme.onSurface`, `theme.textTheme.titleSmall` dans les fichiers modifiés | Auto — `grep` | US1, US2, US3 |
| SC-003 | Zéro `AlertDialog` natif dans les 3 fichiers modifiés (remplacés par `ConfirmDialogCustom`) | Auto — `grep` | US2, US3 |
| SC-004 | Zéro `Card(` dans `currency_settings_screen.dart` | Auto — `grep` | US3 |
| SC-005 | `EmptyStateWidget` utilisé dans `CategoryListScreen` pour les états vide et erreur | Manuel + code review | US1 |
| SC-006 | Les 3 écrans restent fonctionnels : chargement, affichage, CRUD, navigation | Manuel — parcours utilisateur | Toutes |
| SC-007 | `PageHeader` présent dans les 3 écrans en remplacement de `AppBar` — zéro `AppBar(` dans les 3 fichiers modifiés | Auto — `grep` | US1, US2, US3 |
| SC-008 | Zéro `OutlinedButton` pour les actions "Ajouter" dans `currency_settings_screen.dart` — remplacés par boutons `+` circulaires | Auto — `grep` | US3 |

---

## Key Entities

| Entité | Description | Relations principales |
|--------|-------------|----------------------|
| `Category` | Catégorie utilisateur (icône, couleur, nom) | Liée à transactions, catégoriNotifier |
| `DataMode` | Enum local/server — source de données active | Utilisé par DataSettingsNotifier + DataModeProvider |
| `ExchangeRate` | Taux de conversion entre deux devises | Lié à ExchangeRateNotifier |
| `Currency` | Enum des devises supportées (EUR, XOF, USD…) | Lié à CurrencyConfigNotifier |

---

## Assumptions

| # | Hypothèse | Impact si fausse | Validation prévue |
|---|-----------|-----------------|-------------------|
| A-001 | La couche data (notifiers, repositories) pour les 3 features est correcte et n'est pas à modifier | Scope augmente significativement | Vérifié par grep des erreurs existantes |
| A-002 | `ConfirmDialogCustom` accepte les callbacks async (nécessaire pour `switchDataMode` qui est `async`) | ✅ **Validée** — `ConfirmDialogCustom.show()` retourne `Future<bool?>`. Pattern : `final confirmed = await ConfirmDialogCustom.show(...) ?? false;` — compatible avec les callers async. | Vérifié sur `confirm_dialog_custom.dart` |
| A-003 | `EmptyStateWidget` supporte un état d'erreur avec CTA "Réessayer" (pas seulement l'état vide) | ✅ **Validée** — `EmptyStateWidget` accepte `icon`, `message`, `ctaLabel`, `onCtaTap`. Usage erreur : `EmptyStateWidget(icon: PhosphorIconsRegular.warning, message: 'Erreur de chargement', ctaLabel: 'Réessayer', onCtaTap: refresh)` — pleinement supporté. | Vérifié sur `empty_state_widget.dart` |
| A-004 | Les routes et la navigation vers les 3 écrans depuis le hub KKS-246 sont correctes | Nécessité de modifier app_router | Vérifié — routes présentes dans app_router.dart |
