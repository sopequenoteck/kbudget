# Research: Bottom Nav Revamp

**Branch**: `092-bottom-nav-revamp` | **Date**: 2026-03-15

## R1 — Pill indicator : technique CSS

**Decision**: Pseudo-élément `::before` sur `.nav-item.active` positionné en absolute.

**Rationale**: Le pill est un élément visuel décoratif qui ne doit pas affecter le layout. Un pseudo-élément est la solution standard pour ce pattern (Material Design 3, iOS tab bar). Il évite d'ajouter un élément DOM supplémentaire.

**Implementation**:
```scss
.nav-item {
  position: relative;

  &.active::before {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -70%); // centré sur l'icône, pas le label
    width: 56px;
    height: 32px;
    border-radius: var(--radius-round);
    background-color: var(--color-primary-light);
    z-index: -1;
    transition: opacity var(--duration-normal) var(--easing-default);
  }
}
```

**Alternatives rejected**:
- Élément DOM dédié `<div class="pill">` : over-engineering, nécessite un changement template
- CSS `background` sur le nav-item lui-même : ne permet pas de limiter le pill à la zone icône

## R2 — Glassmorphism : réutilisation tokens 091

**Decision**: Réutiliser `--glass-bg`, `--glass-border`, `--glass-blur` de la feature 091 sans créer de nouveaux tokens.

**Rationale**: Les tokens créés dans 091 (`_dark.scss` et `_light.scss`) sont des tokens sémantiques "glass" applicables à tout composant nécessitant l'effet. En dark mode : fond semi-transparent + blur. En light mode : fond opaque + blur 0px. Le fallback `@supports` est identique.

**Note**: La shadow hardcodée actuelle `box-shadow: 0 -1px 8px rgb(0 0 0 / 0.08)` est remplacée par `border-top: 1px solid var(--glass-border)`. En dark mode, ça donne une ligne subtile rgba(255,255,255,0.08). En light mode, c'est `var(--border-default)`.

## R3 — Police réduite : approche data-attribute

**Decision**: Utiliser `[attr.data-item-count]` sur le host pour un ciblage CSS pur.

**Rationale**: Angular permet de binder un attribut sur le host via `host: { '[attr.data-item-count]': 'items().length' }`. Le CSS cible ensuite `:host([data-item-count="6"])` pour réduire la police. Pas de logique conditionnelle TypeScript, pas de signal supplémentaire.

**Implementation**:
```scss
:host([data-item-count="6"]) .nav-item__label {
  font-size: 0.625rem; // 10px
}
```

**Alternatives rejected**:
- `@HostBinding('class.many-items')` : nécessite un computed signal, plus de code
- Media query `container` : support navigateur insuffisant pour certains anciens mobiles
