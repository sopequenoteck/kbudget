# Research: Configuration de la navigation — Flutter

**Branch**: `059-flutter-settings-bottom-nav` | **Date**: 2026-02-28

## R1 — État actuel de navOrder dans le codebase

**Decision**: `navOrder` existe déjà dans les DTOs Flutter et le backend, mais n'est ni stocké localement ni utilisé.

**Rationale**: L'infrastructure réseau est prête (DTOs `UserPreferenceRequest.navOrder` optional, `UserPreferenceResponse.navOrder` required). Il manque :
- Le champ `navOrder` dans `AppConfig` (stockage local)
- Les méthodes dans `AppConfigRepository`
- Le champ dans `FeatureConfigState`
- La logique dans `FeatureConfigNotifier`
- L'utilisation dans `_ShellScaffold`

**Alternatives considered**: Aucune — le chemin est clair, l'infrastructure partiellement prête.

## R2 — Stratégie de stockage de navOrder

**Decision**: `navOrder` stocke TOUTES les features (activées et désactivées) pour conserver l'ordre de chaque feature même quand elle est désactivée.

**Rationale**: Quand une feature est réactivée, l'utilisateur s'attend à retrouver sa position. Si on ne stockait que les features activées, la position serait perdue à la désactivation. Le filtrage (enabled + navOrder) se fait à l'affichage.

**Alternatives considered**:
- Stocker uniquement les features activées → Perte de position à la désactivation, mauvaise UX.

## R3 — Flutter ReorderableListView vs packages tiers

**Decision**: Utiliser `ReorderableListView.builder` natif Flutter.

**Rationale**: Le widget natif couvre parfaitement le besoin (liste verticale, 1-3 items, drag handle). Pas de dépendance externe nécessaire. Les limites du widget natif (pas de drag cross-list, animations limitées) ne s'appliquent pas ici (liste unique, très courte).

**Alternatives considered**:
- `flutter_reorderable_list` / `reorderable_list` → Dépendance externe inutile pour 3 items.
- `drag_and_drop_lists` → Sur-dimensionné (groupes, cross-list), complexité accrue.

## R4 — Placement de la section Navigation dans l'UI

**Decision**: Ajouter la section "Navigation" dans l'écran `FeatureSettingsScreen` existant, sous la section "Modules". Renommer le titre de la page de "Fonctionnalités" à "Fonctionnalités & Navigation".

**Rationale**: L'issue Linear spécifie explicitement "Section Navigation dans la page Features & Navigation des Settings". C'est cohérent fonctionnellement : features et ordre de navigation sont intimement liés.

**Alternatives considered**:
- Page séparée dédiée à la navigation → Fragmente l'expérience, contredit l'issue.

## R5 — Preview du Bottom Nav

**Decision**: Widget inline (non sticky) en bas de la section Navigation, simulant visuellement la `BottomNavigationBar` avec les icônes et libellés dans l'ordre résultant.

**Rationale**: La preview est dans un `ListView` scrollable. Elle n'a pas besoin d'être fixe — la page a peu de contenu (3 toggles + 3-5 items de navigation + preview). Le widget réutilise les métadonnées de `NavDestination` / `Feature` enum.

**Alternatives considered**:
- Preview fixe (sticky bottom) → Prend de l'espace permanent, complexifie le layout, inutile pour une page aussi courte.
- Pas de preview → Contredit la spec et l'issue.

## R6 — Icônes outlined pour la preview et le noyau fixe

**Decision**: Ajouter un getter `outlinedIcon` au `Feature` enum. Pour le noyau fixe (Dashboard, Transactions), définir les métadonnées dans une constante locale.

**Rationale**: Le `_ShellScaffold` utilise des icônes outlined (inactive) et filled (active). La preview doit être cohérente avec le vrai bottom nav. Le Feature enum a déjà `.icon` (filled) — on ajoute `.outlinedIcon`.

**Alternatives considered**:
- Map locale dans le widget preview → Duplication, moins maintenable.

## R7 — Mise à jour du hub Settings

**Decision**: Mettre à jour le titre et la description de la section "Fonctionnalités" dans `settings_section.dart` pour refléter "Fonctionnalités & Navigation".

**Rationale**: La page englobe maintenant les toggles ET l'ordre de navigation. Le libellé doit être cohérent.
