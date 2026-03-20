# Research: Banques sur les comptes — Angular

**Feature**: 082-angular-bank-accounts | **Date**: 2026-03-13

## R-001: Pattern de service signal-based avec cache

**Decision**: Signal `banks` initialisé à `[]`, chargé via `loadBanks()` appelé au premier accès (lazy). Pas de `refreshTrigger` car liste statique.

**Rationale**: Suit le pattern `PreferenceService` existant. La liste des 29 banques est un registre statique backend — pas de mutations possibles côté client. Un seul appel HTTP est optimal.

**Alternatives considered**:
- `toSignal(http.get())` : trop limité, pas de gestion d'erreur ni retry
- `APP_INITIALIZER` : chargement au démarrage même si l'utilisateur ne touche jamais aux comptes — inutile

## R-002: Dropdown groupé vs SelectPicker étendu

**Decision**: Composant `BankSelectComponent` dédié, standalone, OnPush.

**Rationale**: Le `SelectPicker` existant supporte une liste plate `SelectPickerItem[]` avec icône texte, couleur et recherche. Le sélecteur banque nécessite :
1. Groupement par région (3 groupes + "Autre" en bas)
2. Logos SVG (`<img>`) plutôt qu'emojis
3. Pin de l'option "Autre" même pendant le filtrage

Étendre `SelectPicker` pour ces 3 cas complexifierait un composant utilisé dans 6+ endroits. Un composant dédié est plus simple et plus maintenable.

**Alternatives considered**:
- Étendre `SelectPicker` avec `groups` et `pinnedItems` : ajout de complexité disproportionné pour un seul cas d'usage
- `<select>` natif avec `<optgroup>` : pas de support pour logos/images inline

## R-003: Résolution logo — composant vs pipe

**Decision**: Composant `AccountBankIcon` plutôt que pipe.

**Rationale**: La résolution implique du HTML conditionnel (img vs span), pas juste une transformation de valeur. Un composant encapsule proprement le template, le fallback onerror, et le dimensionnement.

**Alternatives considered**:
- Pipe `bankLogo` : retourne seulement une URL, ne gère pas le fallback img→emoji ni le dimensionnement
- Directive : plus complexe qu'un simple composant pour ce cas

## R-004: Stockage logo custom

**Decision**: Base64 data URI dans `bankCustomLogo`, compression canvas (maxWidth=512, quality=0.8, JPEG).

**Rationale**: Pattern identique au `ProductForm` (068-angular-shop-module). Le backend accepte déjà les data URI dans le champ `bank_custom_logo` (TEXT). La compression à 512px est suffisante pour un logo de banque (affiché en 24-32px).

**Alternatives considered**:
- Upload fichier séparé + URL : nécessiterait un endpoint d'upload dédié côté backend — over-engineering pour un single-user app
- SVG inline : trop risqué (XSS) et complexe à valider

## R-005: Intégration dans les sélecteurs de compte existants

**Decision**: Remplacer l'emoji brut par `<app-account-bank-icon>` dans les composants qui affichent un compte.

**Rationale**: Les sélecteurs de compte utilisent le `SelectPicker` avec un `SelectPickerItem.icon` (emoji). Pour afficher le logo banque, il faut enrichir les items. Deux approches :
1. Utiliser `SelectPickerItem.icon = null` et customiser le template du SelectPicker → trop intrusif
2. Mettre à jour les endroits qui construisent les `SelectPickerItem` pour utiliser le `bankLogoUrl` comme icône

La 2ème approche est retenue : quand un compte a un `bankLogoUrl`, l'afficher comme image dans le picker. Pour les comptes "OTHER" sans logo custom, garder l'emoji.

**Note**: Le `SelectPicker` affiche `icon` comme texte/emoji. Pour supporter les images, soit :
- Ajouter un champ `iconUrl` à `SelectPickerItem` et le rendre en `<img>` si présent
- Soit garder le `SelectPicker` tel quel et ne modifier que la liste des comptes en settings (où on contrôle le template)

**Decision finale**: Modifier le `SelectPicker` pour supporter un `iconUrl` optionnel (changement minimal : une condition `@if` dans le template). Cela bénéficie à tous les usages futurs.
