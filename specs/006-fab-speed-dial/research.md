# Research: Bouton flottant (+) avec Speed Dial

**Feature**: 006-fab-speed-dial | **Date**: 2026-02-09

## Résumé

Feature purement UI Angular. Aucun NEEDS CLARIFICATION identifié lors de l'analyse du Technical Context. Les technologies et patterns sont tous déjà utilisés dans le projet ou standards Angular (`@angular/cdk`). Cette recherche documente les décisions techniques validées.

## R1 — Intégration FAB dans le Shell existant

**Decision**: Le FAB et le Modal sont des composants standalone dans `shared/components/`, orchestrés par le Shell via signals.

**Rationale**: Le Shell gère déjà le layout authentifié (header, sidebar, contenu) et le state de la sidebar via `signal<boolean>`. Ajouter le state du FAB/modal dans le Shell est cohérent avec ce pattern. Pas de service dédié car le state est local à cette vue.

**Alternatives considered**:
- Service global `FabService` — rejeté car sur-ingénierie. Le state est local au Shell, pas partagé entre composants non-liés.
- FAB dans `app.component` — rejeté car le FAB ne doit pas être visible sur `/auth` (login). Le Shell est déjà protégé par `authGuard`.

## R2 — Position fixed pour le FAB

**Decision**: `position: fixed` avec `bottom: 16px; right: 16px`.

**Rationale**: Le FAB doit rester visible quel que soit le scroll. `position: fixed` est relatif au viewport. En mode desktop, la sidebar (240px) est à gauche et le FAB en bas à droite ne la chevauche jamais car le contenu a déjà `margin-left: var(--sidebar-width)`.

**Alternatives considered**:
- `position: absolute` dans `.shell-content` — rejeté car le FAB disparaîtrait au scroll.
- `position: sticky` — rejeté car fonctionne mal avec les layouts flexbox complexes.

## R3 — Animations CSS pures

**Decision**: Animations CSS pures via transitions, pas de `@angular/animations`.

**Rationale**: Les animations requises (rotation, fade, translate, scale) sont simples et GPU-accélérées (transform, opacity). Les tokens existants (`--duration-normal: 200ms`, `--easing-default`) garantissent la cohérence. Le media query `prefers-reduced-motion` est déjà géré (durées à 0ms).

**Alternatives considered**:
- `@angular/animations` — rejeté car ajouterait une dépendance pour des animations simples.
- Web Animations API — rejeté car moins lisible pour des transitions simples.

## R4 — Stagger animation via CSS

**Decision**: `transition-delay` CSS via `nth-child` pour les 3 items du speed dial (0ms, 50ms, 100ms).

**Rationale**: Les 3 items sont connus à la compilation (pas dynamique). Les pseudo-classes `nth-child` évitent les styles inline et sont plus propres. Durée totale ~200ms conforme à la spec.

**Alternatives considered**:
- `[style.transition-delay]` inline — possible mais les pseudo-classes CSS sont plus propres pour un nombre fixe d'items.

## R5 — Focus trap et accessibilité clavier via @angular/cdk

**Decision**: Utiliser `@angular/cdk/a11y` (`CdkTrapFocus`) pour le focus trap dans le modal et le speed dial. Navigation clavier personnalisée (ArrowUp/Down, Enter, Escape) via event binding `(keydown)`.

**Rationale**: `CdkTrapFocus` est la directive standard Angular pour piéger le focus dans un conteneur. Compatible standalone components Angular 21. Le CDK est maintenu par l'équipe Angular, version alignée avec Angular 21. La navigation clavier ArrowUp/Down n'est pas fournie par le CDK (il gère uniquement Tab/Shift+Tab), donc elle reste manuelle via `(keydown)` handler.

**Alternatives considered**:
- Focus trap entièrement manuel (keydown Tab/Shift+Tab) — rejeté car fragile et réinvente la roue pour la gestion Tab.
- CDK Dialog (`@angular/cdk/dialog`) — rejeté car impose son propre lifecycle et structure DOM.

## R6 — Modal avec ng-content

**Decision**: Modal avec `<ng-content>` pour le body, input `title` pour le header, output `closed` pour la fermeture.

**Rationale**: Le modal sera réutilisé par les futures features de formulaires. L'API minimale (title + ng-content + closed) couvre tous les cas sans sur-ingénierie.

**Alternatives considered**:
- Service modal avec portail dynamique — rejeté car sur-ingénierie.
- Dialog HTML natif (`<dialog>`) — support du styling/animations limité et le comportement Escape doit être customisé.

## R7 — Z-index : nouveau token --z-fab

**Decision**: Nouveau token `$z-fab: 250` / `--z-fab: 250` ajouté entre `--z-sticky` (200) et `--z-overlay` (300).

**Rationale**: Le FAB doit être au-dessus du contenu normal et du header sticky (200) mais en dessous de l'overlay speed dial (300) et du modal (400). L'overlay du speed dial utilise `--z-overlay` (300) et le FAB lui-même est à 250, ce qui assure l'empilement correct.

**Alternatives considered**:
- `$z-fab: 350` (entre overlay et modal) — rejeté car le FAB n'a pas besoin d'être au-dessus de l'overlay. L'overlay speed dial couvre le FAB ce qui est le comportement attendu.
- Offsets locaux (`calc(var(--z-overlay) + 10)`) — rejeté car moins explicite qu'un token nommé.

## R8 — Scroll lock du modal

**Decision**: Toggle `overflow: hidden` sur `document.body.style` dans un `effect()` Angular.

**Rationale**: Pattern simple et direct. L'`effect()` réagit au signal `isOpen` du modal et applique/retire le style. Cleanup automatique via la fonction de retour de l'effect. Le `BlockScrollStrategy` du CDK Overlay est conçu pour les overlays CDK complets — surdimensionné pour notre modal standalone.

**Alternatives considered**:
- `@angular/cdk/overlay` `BlockScrollStrategy` — rejeté car nécessite un overlay CDK complet.
- `overscroll-behavior: contain` — ne bloque pas le scroll du body.
- Service dédié ScrollLockService — over-engineered pour un seul composant.
