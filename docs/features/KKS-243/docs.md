# Documentation — KKS-243 : Phase 1 / Étape 7 — Refonte 3 écrans S Flutter

> Date : 2026-05-27
> Issue : KKS-243

---

## Résumé

KKS-243 aligne 3 écrans Flutter settings (Catégories, Données, Devises & Taux) sur le design system v5 : remplacement des tokens Material bruts (`colorScheme.surfaceContainerHighest`, `theme.textTheme.titleSmall`, `FontWeight.w600`) par les constantes `AppTypography` et `AppThemeExtension`, migration des `AppBar` génériques vers `PageHeader`, remplacement des `AlertDialog` natifs par `ConfirmDialogCustom`, et refonte du pattern liste taux (suppression des `Card` individuelles). Aucune couche data (notifiers, repositories, modèles) n'a été modifiée.

---

## Guide utilisateur

### Écran Catégories

**Ce qui change** : le bouton retour (flèche) et le titre "Catégories" sont affichés dans le header standardisé (`PageHeader`). Le bouton "ajouter une catégorie" (➕) se trouve désormais en **bouton flottant** en bas à droite, conformément au principe Mobile-First de l'application. En cas de liste vide ou d'erreur de chargement, un état vide unifié s'affiche avec un message et, pour l'erreur, un lien "Réessayer".

**Ce qui reste identique** : navigation, CRUD catégories, icônes emoji, pastilles couleur.

---

### Écran Source de données

**Ce qui change** : le titre et le bouton retour sont dans le `PageHeader`. Les labels de section ("Source de données", "URL du serveur") sont en **majuscules avec espacement de lettres** (style v5). La confirmation de changement de mode (Local ↔ Serveur) utilise désormais la boîte de dialogue de confirmation unifiée (`ConfirmDialogCustom`) à la place du dialog natif Material.

**Ce qui reste identique** : sélecteur Local/Serveur, champ URL serveur (OutlineInputBorder conservé — écran Flutter-only sans équivalent Angular), bouton Enregistrer, validation d'URL.

---

### Écran Devises & Taux

**Ce qui change** :
- Titre et bouton retour dans le `PageHeader`
- Labels de section ("MES DEVISES", "TAUX DE CONVERSION", "CALCULATEUR") en majuscules v5
- Boutons "Ajouter" — remplacés par des **boutons circulaires ➕ 28px dans les headers de section** (pattern Angular `add-btn`), à la place des boutons en pied de section
- Taux de conversion — affichés en **liste avec séparateurs** dans un conteneur arrondi (suppression des cards Material individuelles)
- Confirmations de suppression de taux et de retrait de devise — via `ConfirmDialogCustom` (variant danger)

**Ce qui reste identique** : liste des devises actives, réorganisation par drag-and-drop, formulaire d'ajout/modification de taux (`RateForm`), calculateur de taux (`RateCalculator`).

---

## Changements techniques

### Fichiers créés

Aucun.

### Fichiers modifiés

| Fichier | Nature du changement |
|---------|---------------------|
| `flutter/lib/src/features/categories/presentation/widgets/category_list_tile.dart` | FR-001 : `colorScheme.surfaceContainerHighest` → `themeExt?.iconCircleBg ?? colorScheme.surface` pour le fond du cercle icône |
| `flutter/lib/src/features/categories/presentation/screens/category_list_screen.dart` | FR-002, FR-010 : `AppBar` → `PageHeader` ; états vide+erreur ad hoc → `EmptyStateWidget` ; bouton "ajouter" migré de `AppBar.actions` vers `FloatingActionButton` |
| `flutter/lib/src/features/settings/presentation/data_settings_screen.dart` | FR-003/004, FR-005, FR-010 : `AppBar` → `PageHeader` ; labels `titleSmall+w600` → `AppTypography` uppercase ; `AlertDialog` → `ConfirmDialogCustom.primary` |
| `flutter/lib/src/features/exchange_rates/presentation/currency_settings_screen.dart` | FR-006/007/008, FR-010/011 : `AppBar` → `PageHeader` ; labels uppercase ; `Card` → `Container+Divider` ; `OutlinedButton.icon` → `_AddButton` circulaire 28px ; `AlertDialog ×2` → `ConfirmDialogCustom.danger ×2` |

### Dépendances ajoutées

Aucune. Les widgets utilisés (`PageHeader`, `EmptyStateWidget`, `ConfirmDialogCustom`) étaient déjà disponibles via KKS-238 et KKS-246.

---

## Configuration

Aucune configuration requise. Les tokens design system v5 (`AppTypography`, `AppThemeExtension`, `AppRadius`) sont des constantes statiques déjà importées dans les fichiers de constantes de l'application.

---

## Tests et validation

### Success Criteria (automatiques)

| SC | Description | Statut |
|----|-------------|--------|
| SC-001 | `dart analyze` — 0 issue dans les 4 fichiers | ✅ PASS — `No issues found` |
| SC-002 | Zéro `surfaceContainerHighest`, `textTheme.titleSmall` dans les 4 fichiers | ✅ PASS |
| SC-003 | Zéro `AlertDialog` dans les 3 fichiers settings | ✅ PASS |
| SC-004 | Zéro `Card(` dans `currency_settings_screen.dart` | ✅ PASS |
| SC-005 | `EmptyStateWidget` ×2 dans `category_list_screen.dart` (vide + erreur) | ✅ PASS |
| SC-007 | Zéro `AppBar(` dans les 3 écrans | ✅ PASS |
| SC-008 | Zéro `OutlinedButton` pour actions "Ajouter" dans `currency_settings_screen.dart` | ✅ PASS |

### Validation manuelle (SC-006)

- [ ] **Catégories** : navigation depuis hub → liste → PageHeader visible → FAB ➕ fonctionnel → ajouter/modifier/supprimer catégorie → état vide visible → état erreur avec "Réessayer"
- [ ] **Données** : navigation depuis hub → PageHeader → labels uppercase → changer mode (Local ↔ Serveur) → `ConfirmDialogCustom` s'affiche → annuler ne change pas le mode → confirmer redémarre l'app
- [ ] **Devises & Taux** : navigation depuis hub → PageHeader → labels uppercase → boutons ➕ dans headers → ajouter devise → réordonner → retirer devise → `ConfirmDialogCustom.danger` → ajouter taux → modifier taux → supprimer taux → `ConfirmDialogCustom.danger` → calculateur fonctionnel

### Couverture Requirements → Tâches

| FR | Tâche | Statut |
|----|-------|--------|
| FR-001 | T-021 | ✅ |
| FR-002 | T-023 | ✅ |
| FR-003/004 | T-025 | ✅ |
| FR-005 | T-026 | ✅ |
| FR-006 | T-030 | ✅ |
| FR-007 | T-028 | ✅ |
| FR-008 | T-031 | ✅ |
| FR-009 | — (hors scope, conservé) | ✅ |
| FR-010 | T-022, T-024, T-027 | ✅ |
| FR-011 | T-029 | ✅ |
