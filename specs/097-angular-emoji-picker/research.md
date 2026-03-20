# Research: 097-angular-emoji-picker

**Date**: 2026-03-20
**Spec**: [spec.md](./spec.md)

## R1 — Choix du package emoji picker

**Decision**: `emoji-mart` (vanilla web component) via `@emoji-mart/data` (dataset) + `emoji-mart` (picker element).

**Rationale**:
- Package recommandé dans l'issue KKS-163.
- Web component natif (`<em-emoji-picker>`) — compatible Angular sans wrapper spécifique.
- Features intégrées : catégories, recherche, récents, thème dark/light, i18n.
- ~250KB (data inclus), maintenu activement, ~15k stars GitHub.
- Fonctionne comme custom element : `import { init } from 'emoji-mart'` + `<em-emoji-picker>` dans le template.

**Alternatives considered**:
- `emoji-picker-element` : Plus léger mais moins de features (pas d'i18n intégré, pas de section récents configurable).
- `ngx-emoji-mart` : Wrapper Angular mais abandonné / pas maintenu pour Angular 21.
- Input natif `type="text"` avec regex (actuel) : UX très faible, pas de browsing visuel.

## R2 — Locale française

**Decision**: Utiliser le fichier i18n français de emoji-mart.

**Rationale**:
- emoji-mart supporte l'i18n via un objet de traduction passé à `init()` ou en prop `i18n` du picker.
- Le package expose des locales prêtes à l'emploi ou permet un objet custom.
- Les noms de catégories et la recherche seront en français.

**Alternatives considered**:
- Anglais par défaut : rejeté car l'app est en français (clarification spec).
- i18n custom complet : pas nécessaire, les locales intégrées suffisent.

## R3 — Intégration Angular (custom element)

**Decision**: Utiliser `CUSTOM_ELEMENTS_SCHEMA` dans le composant standalone + `init()` dans le constructeur ou `ngOnInit`.

**Rationale**:
- emoji-mart expose un web component `<em-emoji-picker>`. Angular nécessite `CUSTOM_ELEMENTS_SCHEMA` pour les éléments non-Angular.
- L'initialisation se fait via `init({ data })` une seule fois au démarrage de l'app ou du composant.
- L'événement `emoji-select` est émis par le picker et contient l'objet emoji avec sa propriété `native` (le caractère emoji).

**Alternatives considered**:
- Créer un wrapper Angular complet : sur-ingénierie pour un composant déjà web component.
- Dynamic import : possible mais pas nécessaire vu la taille raisonnable.

## R4 — Popover / overlay

**Decision**: Utiliser Angular CDK Overlay (`@angular/cdk/overlay`) pour le positionnement du picker.

**Rationale**:
- Le CDK est déjà une dépendance du projet (utilisé pour drag-drop dans les feature toggles).
- `CdkOverlayOrigin` + `CdkConnectedOverlay` offrent un positionnement automatique par rapport au trigger, avec repositionnement intelligent si le picker dépasse de l'écran.
- Fermeture sur clic extérieur (`hasBackdrop`) et Escape intégrés.
- Pas de dépendance supplémentaire.

**Alternatives considered**:
- CSS `position: absolute` manuel : fragile, pas de repositionnement, pas de backdrop.
- Angular Material Dialog : trop lourd pour un popover, UX popup plutôt que contextuel.

## R5 — Thème dark/light

**Decision**: Détecter la classe `.theme-dark` sur le document et passer `theme="dark"` ou `theme="light"` au picker.

**Rationale**:
- emoji-mart accepte une prop `theme` (`light` | `dark` | `auto`).
- L'app utilise une classe `.theme-dark` sur le body (pas `prefers-color-scheme` seul).
- Lire la classe et passer la valeur appropriée garantit la cohérence avec le thème app.

**Alternatives considered**:
- `theme="auto"` (suit `prefers-color-scheme`) : ne correspond pas forcément au thème choisi par l'utilisateur dans l'app.
