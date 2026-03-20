# Research: Migration Phosphor Icons

**Branch**: `069-phosphor-icons-migration` | **Date**: 2026-03-05

## R1: Etat actuel des icones systeme

### Angular (app/)

**Decision**: L'application Angular n'utilise PAS FontAwesome. Les icones systeme sont des emojis Unicode.

**Constat**:
- Zero dependance FontAwesome dans package.json
- Zero classe CSS `fa-*`, `fas`, `far`, `fab`
- Toutes les icones systeme sont des caracteres emoji hardcodes dans les composants TypeScript
- Exemples : navigation (🏠, 💰, 🔄, 🤝, 🏪), settings (🏦, 🏷️, 👤, ⚡, 🎨, 💾), FAB (💰, 🔄, 🤝, ↔️, 📦, 💸), shell (⚙️, 🚪)

**Impact sur la spec**: FR-007 (supprimer FontAwesome) est sans objet. La migration Angular consiste a remplacer les emojis systeme par des icones Phosphor.

### Flutter (flutter/)

**Decision**: L'application Flutter utilise ~60 icones Material Icons (`Icons.*`) pour les icones systeme.

**Constat**:
- Navigation : 10 icones (home, receipt_long, autorenew, handshake, storefront — outlined + filled)
- Actions : add, check, delete_outline, close, refresh, swap_horiz
- Formulaires : calendar_today, person_outlined, email_outlined, lock_outlined, visibility_outlined/off
- Settings : person, toggle_on, palette, account_balance, label, storage, lock, info
- Etats : error_outline, check_circle, wifi_find
- Shop : camera_alt, photo_library, add_a_photo, add_shopping_cart, sell, edit_outlined
- Divers : chevron_right/left, more_vert, drag_handle, keyboard_arrow_down, trending_up/down

**Alternatives considerees**: Aucune — Material Icons est la seule source d'icones systeme cote Flutter.

## R2: Package Angular Phosphor

**Decision**: `@ng-icons/core` + `@ng-icons/phosphor-icons` (v33.1.0)

**Rationale**:
- Natif Angular, standalone-compatible, peerDep `>=21.0.0` (Angular 21 OK)
- Tree-shaking par import nomme — seules les icones importees finissent dans le bundle
- Sous-paquets par style (`/regular`, `/bold`, `/fill`, `/thin`, `/light`, `/duotone`)
- Maintenu activement (fev. 2026)

**Alternatives considerees**:

| Package | Raison du rejet |
|---------|-----------------|
| `@phosphor-icons/webcomponents` | Framework-agnostic, pas d'integration Angular native, tree-shaking partiel |
| `ngx-phosphor-icons` | Depend de `@angular/material`, compatibilite Angular 21 non garantie |

**Usage**:
```typescript
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorHouse } from '@ng-icons/phosphor-icons/regular';
import { phosphorHouseFill } from '@ng-icons/phosphor-icons/fill';
import { phosphorPlusBold } from '@ng-icons/phosphor-icons/bold';

@Component({
  imports: [NgIcon],
  providers: [provideIcons({ phosphorHouse, phosphorHouseFill, phosphorPlusBold })],
  template: `<ng-icon name="phosphorHouse" size="24"></ng-icon>`,
})
```

## R3: Package Flutter Phosphor

**Decision**: `phosphor_flutter` v2.1.0

**Rationale**:
- Package officiel Phosphor pour Flutter
- 1300+ icones, 6 styles
- Compatible Flutter >= 3.27

**Alternatives considerees**: Aucune alternative viable — c'est le seul package Phosphor officiel pour Flutter.

**Usage**:
```dart
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Regular
PhosphorIcon(PhosphorIconsRegular.house, size: 24.0)

// Fill (etat actif)
PhosphorIcon(PhosphorIconsFill.house, size: 24.0)

// Bold (actions)
PhosphorIcon(PhosphorIconsBold.plus, size: 24.0)
```

## R4: Convention de nommage des styles

**Decision**: Mapping style → sous-classe/sous-paquet

| Style | Flutter | Angular import path |
|-------|---------|-------------------|
| regular | `PhosphorIconsRegular.*` | `@ng-icons/phosphor-icons/regular` → `phosphorXxx` |
| fill | `PhosphorIconsFill.*` | `@ng-icons/phosphor-icons/fill` → `phosphorXxxFill` |
| bold | `PhosphorIconsBold.*` | `@ng-icons/phosphor-icons/bold` → `phosphorXxxBold` |
| duotone | `PhosphorIconsDuotone.*` | `@ng-icons/phosphor-icons/duotone` → `phosphorXxxDuotone` |

## R5: Corrections appliquees a la spec

Les corrections suivantes ont ete appliquees a la spec :
1. FR-007 reformule — FontAwesome n'etait pas une dependance. FR-007 concerne maintenant le nettoyage des imports Material Icons inutilises dans Flutter
2. FR-001 reformule pour preciser "remplacer les emojis systeme" (Angular) et "Material Icons" (Flutter)
3. SC-003 reformule — inventaire complet documente (pas de FontAwesome a supprimer)
