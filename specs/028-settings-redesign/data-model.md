# Data Model: Refonte page Settings (8 sections)

**Date**: 2026-02-16 | **Branch**: `028-settings-redesign`

> Feature frontend-only. Aucune entité JPA ou migration Flyway. Ce document décrit les modèles TypeScript côté frontend.

## Entités frontend

### SettingsSection

Représente une carte de section dans le hub Settings.

```typescript
// Définition inline dans settings.ts (pas de fichier modèle séparé — YAGNI)
interface SettingsSection {
  id: string;          // Identifiant unique (ex: 'accounts', 'categories')
  title: string;       // Titre affiché (ex: 'Comptes bancaires')
  description: string; // Description courte (ex: 'Gérer mes comptes')
  icon: string;        // Emoji ou icône (ex: '🏦')
  route: string;       // Route relative (ex: 'accounts')
  status: 'active' | 'placeholder'; // Section fonctionnelle ou "à venir"
}
```

**Données** (constante statique dans le composant hub) :

| id | title | description | icon | route | status |
|----|-------|-------------|------|-------|--------|
| accounts | Comptes bancaires | Gérer mes comptes | 🏦 | accounts | active |
| categories | Catégories | Gérer mes catégories | 🏷️ | categories | active |
| budget | Budget | Définir mes budgets | 📊 | budget | placeholder |
| notifications | Notifications | Configurer les alertes | 🔔 | notifications | placeholder |
| profile | Profil | Mes informations | 👤 | profile | active |
| appearance | Apparence | Thème et affichage | 🎨 | appearance | active |
| data | Données | Export et gestion | 💾 | data | placeholder |
| about | À propos | Informations sur l'app | ℹ️ | about | active |

**Règles** :
- L'ordre est fixe (FR-014) — pas de réordonnancement dynamique
- Les sections `placeholder` affichent un indicateur visuel "à venir"
- Les sections `active` naviguent vers leur composant dédié

### Theme (type union)

```typescript
// Dans core/services/theme.ts
type Theme = 'light' | 'dark' | 'auto';
```

**Persistance** :
- Clé localStorage : `budget_theme`
- Valeur par défaut (clé absente) : `'light'`
- Pas d'entité backend associée

**Transitions d'état** :

```
┌──────────┐   setTheme('dark')   ┌──────────┐
│  light   │ ──────────────────► │   dark   │
│          │ ◄────────────────── │          │
└──────────┘   setTheme('light')  └──────────┘
     │ ▲                              │ ▲
     │ │ setTheme('light'|'dark')     │ │ setTheme('light'|'dark')
     ▼ │                              ▼ │
┌──────────┐
│   auto   │ — résolu dynamiquement en 'light' ou 'dark'
│          │   via window.matchMedia('(prefers-color-scheme: dark)')
└──────────┘
```

### UserInfo (existant, inchangé)

```typescript
// Dans core/models/user.model.ts — déjà existant
interface UserInfo {
  name: string;
  email: string;
}
```

**Source** : `AuthService.currentUser()` (signal, alimenté au login, restauré depuis localStorage au démarrage).

**Consommé par** : Section Profil (lecture seule).

## Relations entre entités

```
SettingsSection.route ──navigates──► Angular Component (1 par section)
                                          │
                                    ┌─────┴─────┐
                                    │            │
                              ThemeService   AuthService
                              (appearance)   (profile)
                                    │            │
                                    ▼            ▼
                              localStorage   localStorage
                              budget_theme   budget_user
```

## Aucune migration backend

Cette feature n'impacte aucune table PostgreSQL. Pas de migration Flyway nécessaire.
