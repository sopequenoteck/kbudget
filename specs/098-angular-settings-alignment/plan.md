# Implementation Plan: Alignement Settings Angular sur Flutter

**Branch**: `098-angular-settings-alignment` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/098-angular-settings-alignment/spec.md`

## Summary

Aligner le hub Settings Angular sur le modele Flutter (3 groupes avec headers, couleurs d'icones variees, reordonnement, retrait Budget, ajout Securite placeholder) et enrichir la page A propos (statut serveur, stats dynamiques, contact). Feature frontend-only (Angular), pas de changement backend.

## Technical Context

**Language/Version**: TypeScript 5.9
**Primary Dependencies**: Angular 21, @ng-icons/phosphor-icons, Angular Signals
**Storage**: N/A (pas de persistance, donnees depuis API)
**Testing**: Vitest
**Target Platform**: PWA mobile-first (navigateurs modernes)
**Project Type**: Web application (frontend Angular)
**Performance Goals**: Page A propos chargee en < 2s
**Constraints**: Pas de nouveau endpoint backend, reutiliser services existants
**Scale/Scope**: 2 composants modifies (settings hub + about), 1 route supprimee (budget), 1 route ajoutee (security vers Placeholder)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Notes |
|----------|--------|-------|
| I. API-First | N/A | Pas de changement backend |
| II. Securite par defaut | OK | Pas de nouvelle route publique |
| III. Simplicite & YAGNI | OK | Reutilise services existants, pas de nouvelle abstraction |
| IV. Mobile-First UX | OK | Hub groupe ameliore la navigation mobile |
| V. Testabilite | OK | Tests unitaires prevus |
| VI. Observabilite | N/A | Frontend uniquement |
| VII. Self-Hosted Ready | N/A | Pas de nouvelle dependance infra |

Aucune violation. Gate PASS.

## Project Structure

### Documentation (this feature)

```text
specs/098-angular-settings-alignment/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md
```

### Source Code (repository root)

```text
app/src/app/features/settings/
├── settings.ts              # Hub component (MODIFIER: ajouter groupes, couleurs, reordonnement)
├── settings.html            # Hub template (MODIFIER: ajouter headers de groupe)
├── settings.scss            # Hub styles (MODIFIER: ajouter styles headers + couleurs icones)
├── settings.routes.ts       # Routes (MODIFIER: retirer route budget)
└── components/
    └── about/
        ├── about.ts         # About component (MODIFIER: enrichir avec health, stats)
        ├── about.html       # About template (MODIFIER: 3 cards)
        └── about.scss       # About styles (MODIFIER: refonte complete)
```

**Structure Decision**: Feature frontend-only, modification de fichiers existants dans `app/src/app/features/settings/`. Pas de nouveau fichier a creer (sauf potentiellement un placeholder component pour Securite, mais on reutilise le Placeholder existant qui n'a plus de route — le placeholder est gere visuellement dans le hub).

## Design Details

### Hub Settings — Groupement

**Modele de donnees** : Ajouter un type `SettingsGroup` (enum-like) et une propriete `group` + `iconColor` sur `SettingsSection`.

```typescript
type SettingsGroup = 'general' | 'management' | 'other';

interface SettingsSection {
  id: string;
  title: string;
  description: string;
  icon: string;
  iconColor: string;        // NOUVEAU: couleur CSS (ex: '#3b82f6')
  route: string;
  status: 'active' | 'placeholder';
  group: SettingsGroup;      // NOUVEAU: groupe d'appartenance
}
```

**Sections par groupe** (alignees sur Flutter) :

| Groupe | Sections | Icone Phosphor | Couleur |
|--------|----------|----------------|---------|
| General | Profil | phosphorUser | blue (#3b82f6) |
| General | Fonctionnalites & Navigation | phosphorToggleRight | green (#22c55e) |
| General | Apparence | phosphorPalette | purple (#a855f7) |
| General | Notifications | phosphorBell | amber (#f59e0b) |
| Gestion | Comptes | phosphorBank | teal (#14b8a6) |
| Gestion | Categories | phosphorTag | orange (#f97316) |
| Gestion | Devises & Taux | phosphorCurrencyCircleDollar | amber (#f59e0b) |
| Gestion | Donnees | phosphorDatabase | indigo (#6366f1) |
| Autre | Securite | phosphorLock | red (#ef4444) |
| Autre | A propos | phosphorInfo | grey (#6b7280) |

**Changements d'icones** par rapport a l'actuel :
- Fonctionnalites : `phosphorLightning` → `phosphorToggleRight` (alignement Flutter)
- Donnees : `phosphorFloppyDisk` → `phosphorDatabase` (alignement Flutter)
- Nouveaux : `phosphorToggleRight`, `phosphorDatabase`, `phosphorLock`

**Template hub** : Iterer `GROUPS` au lieu de `sections` directement. Chaque groupe a un header `<h3>` puis ses items. L'icone utilise `[style.background]` avec la couleur au lieu du `--color-primary-light` global.

### Page A propos — Enrichissement

**Injections** :
- `HealthService` (existant) pour statut serveur + info environnement
- `TransactionService`, `AccountService`, `SubscriptionService`, `DebtService` (existants) pour les compteurs

**Strategie compteurs** : Aucun service n'expose de methode `count`. Utiliser `forkJoin` sur les `getAll()` et prendre `.length`. Convertir en signals via `toSignal()` avec valeur par defaut `null` (etat loading).

**Structure template** :
1. Card "Application" : icone app + nom + version | pill statut | badge env
2. Card "Mes donnees" : grille 2x2 (transactions, comptes, abonnements, dettes)
3. Card "Contact" : icone email + nom auteur + email mailto

**Statut serveur** : Appeler `healthService.checkHealth()` au `ngOnInit`. Signal `healthStatus` avec 3 etats : `checking` → `online` / `offline`.

**Environnement** : `healthService.getServerInfo().environment` retourne `'production'` ou `'development'`.

### Routes

- Retirer la route `budget` de `settings.routes.ts`
- La section "Securite" a une route vers le composant Placeholder existant (meme pattern que l'ancien Budget)

## Complexity Tracking

Aucune violation de constitution. Tableau non necessaire.
