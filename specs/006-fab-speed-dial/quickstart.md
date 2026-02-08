# Quickstart: Bouton flottant (+) avec Speed Dial

**Feature**: 006-fab-speed-dial | **Date**: 2026-02-09

## Prérequis

- Node.js installé
- Projet cloné et dépendances installées (`cd app && npm install`)
- Branche `006-fab-speed-dial` active

## Développement

```bash
# Lancer le serveur de développement
cd app && ng serve
# → http://localhost:4200

# Lancer les tests
cd app && npx vitest run

# Lancer les tests en mode watch
cd app && npx vitest

# Linter
cd app && ng lint

# Formatter
cd app && npm run format:check
```

## Fichiers de la feature

### Nouveaux composants

| Fichier | Description |
|---------|-------------|
| `app/src/app/shared/components/fab/fab.ts` | Composant FAB + speed dial |
| `app/src/app/shared/components/fab/fab.html` | Template FAB |
| `app/src/app/shared/components/fab/fab.scss` | Styles FAB + animations |
| `app/src/app/shared/components/modal/modal.ts` | Composant modal réutilisable |
| `app/src/app/shared/components/modal/modal.html` | Template modal |
| `app/src/app/shared/components/modal/modal.scss` | Styles modal + animations |

### Fichiers modifiés

| Fichier | Modification |
|---------|-------------|
| `app/src/app/shared/components/shell/shell.ts` | Ajout orchestration FAB + modal (signals, imports, Router events) |
| `app/src/app/shared/components/shell/shell.html` | Ajout `<app-fab>` et `<app-modal>` |
| `app/src/styles/tokens/_primitives.scss` | Ajout `$z-fab: 250` |
| `app/src/styles/tokens/_tokens.scss` | Ajout `--z-fab` |
| `app/package.json` | Ajout `@angular/cdk` |

### Tests

| Fichier | Scénarios |
|---------|-----------|
| `app/src/app/shared/components/fab/fab.spec.ts` | ~6 tests (affichage, toggle, actions, clavier, anti-rebond) |
| `app/src/app/shared/components/modal/modal.spec.ts` | ~5 tests (ouverture, fermeture ×/overlay/Escape, scroll lock, a11y) |
| `app/src/app/shared/components/shell/shell.spec.ts` | ~4 tests (orchestration, FAB masqué, navigation) |

## Tokens CSS utilisés

| Token | Usage |
|-------|-------|
| `--color-primary` | Couleur de fond du FAB |
| `--color-primary-hover` | Hover du FAB |
| `--color-primary-contrast` | Couleur de l'icône +/× |
| `--surface-overlay` | Overlay semi-transparent (speed dial + modal) |
| `--surface-raised` | Fond des items speed dial |
| `--surface-default` | Fond du modal |
| `--radius-round` | Forme ronde du FAB |
| `--radius-lg` | Border radius du modal |
| `--shadow-lg` | Ombre du FAB et du modal |
| `--shadow-md` | Ombre des items speed dial |
| `--duration-normal` | Durée animations (200ms) |
| `--easing-default` | Courbe d'animation |
| `--z-fab` | Z-index du FAB (250) |
| `--z-overlay` | Z-index overlay speed dial (300) |
| `--z-modal` | Z-index du modal (400) |
| `--space-4` | Espacement FAB (16px bottom/right) |

## Conventions à respecter

- **Signals-first** : `signal()`, `computed()`, `input()`, `output()`, `effect()`
- **OnPush** : `ChangeDetectionStrategy.OnPush` sur tous les composants
- **Standalone** : Pas de NgModules
- **inject()** : Pas de constructor injection
- **Tokens CSS** : Utiliser `var(--token)`, jamais d'import SCSS direct
- **Tests** : Pattern AAA, nommage `should_[résultat]_when_[condition]`
- **CDK** : `CdkTrapFocus` pour focus trap (modal + speed dial)

## Vérification rapide

Après implémentation, vérifier :

1. FAB visible sur `/dashboard`, `/transactions`, `/subscriptions`, `/debts`
2. FAB absent sur `/auth`
3. Speed dial : 3 actions (Transaction, Abonnement, Dette)
4. Modal s'ouvre avec placeholder au clic sur une action
5. FAB masqué quand modal ouvert
6. Fermeture modal : bouton ×, overlay, Echap
7. Navigation clavier : ArrowUp/Down, Enter, Escape
8. Responsive : FAB correctement positionné avec sidebar desktop
9. Animation fluide (60 FPS, DevTools Performance)
10. Scroll lock actif quand modal ouvert
11. Modal : largeur mobile 100%-32px, desktop max-width 480px
