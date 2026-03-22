# Research: Flutter MonthSelector Widget

**Date**: 2026-02-21
**Feature**: 037-flutter-monthselector-widget

## Aucun NEEDS CLARIFICATION détecté

Le contexte technique est entièrement connu. Toutes les dépendances et patterns sont déjà établis dans le projet.

## Décisions techniques

### 1. Formatage du mois en français

- **Décision** : Utiliser `DateFormat('MMMM yyyy', 'fr_FR')` du package `intl` + capitalisation manuelle de la première lettre
- **Justification** : Pattern déjà utilisé dans `RelativeDateFormatter` avec `DateFormat.yMMMMd('fr_FR')`. Le package `intl` est déjà une dépendance via `flutter_localizations`
- **Alternatives considérées** :
  - `toLocaleDateString` (n'existe pas en Dart)
  - Tableau statique des noms de mois en français → fragile, non standard
- **Note** : Les tests doivent appeler `initializeDateFormatting('fr_FR')` dans `setUpAll` (pattern existant dans `relative_date_formatter_test.dart`)

### 2. Gestion de l'état (uncontrolled)

- **Décision** : `StatefulWidget` avec état interne `_month` / `_year`, callback `onChanged`
- **Justification** : Clarifié en session (Option A). Aligné avec la référence Angular qui utilise des signaux internes. Plus simple — le parent n'a pas besoin de gérer l'état du sélecteur
- **Alternatives considérées** :
  - Controlled (parent passe month/year) → plus complexe côté parent, inutile pour ce cas
  - Hybride (initial + didUpdateWidget) → over-engineering pour le besoin actuel

### 3. Icônes de navigation

- **Décision** : `Icons.chevron_left` / `Icons.chevron_right` (Material Icons)
- **Justification** : Conventions Flutter du projet. Les widgets existants (AppModal close button) utilisent Material Icons
- **Alternatives considérées** :
  - Unicode arrows (&#9664; / &#9654;) comme en Angular → non standard en Flutter
  - SVG custom → overkill pour des chevrons

### 4. Style des boutons

- **Décision** : Container rond (48x48dp) avec surface + ombre légère, contenant un `IconButton`
- **Justification** : Reproduit le style Angular (44px rond, ombre sm, surface default) en respectant le minimum 48dp Material. Utilise les mêmes tokens que les boutons existants
- **Alternatives considérées** :
  - `IconButton` nu sans container → pas d'ombre, visuellement différent de la ref Angular
  - `ElevatedButton` → trop opinionated, difficile à personnaliser

### 5. Largeur du label

- **Décision** : `SizedBox` avec `width` fixe suffisante pour "Septembre 2026" (le mois le plus long en français), texte centré
- **Justification** : Évite le décalage des boutons lors du changement de mois (mois de longueurs variables). Pattern identique à l'Angular (min-width: 160px)
- **Alternatives considérées** :
  - `Expanded` → fonctionne mais le widget perdrait sa taille intrinsèque
  - Pas de largeur fixe → les boutons bougent selon la longueur du mois
