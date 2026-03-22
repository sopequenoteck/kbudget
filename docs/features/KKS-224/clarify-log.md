# Clarify Log: KKS-224

**Issue**: Mettre a jour DESIGN.md avec les patterns du dashboard redesigne
**Date**: 2026-03-22
**Points trouves**: 5
**Resolus automatiquement**: 5
**Resolus interactivement**: 0
**Differes**: 0
**Categories couvertes**: 3/11

---

## Points de clarification

### CL-001 : Tokens CSS manquants dans les fichiers SCSS

| Champ | Valeur |
|-------|--------|
| **Categorie** | 1 - Scope fonctionnel |
| **Impact** | Haut |
| **Incertitude** | Haute |
| **Score** | CRITIQUE |
| **Source** | spec.md Edge Cases, marqueur `[NEEDS CLARIFICATION]` |
| **Resolution** | Automatique |

**Question** : Faut-il creer les tokens CSS manquants dans les fichiers SCSS, ou uniquement documenter ceux qui existent deja dans le code ?

**Reponse** : Les 11 tokens listes dans l'issue existent deja dans le code SCSS :
- `app/src/styles/themes/_light.scss` (lignes 40-69)
- `app/src/styles/themes/_dark.scss` (lignes 39-71)

Le scope de cette issue est uniquement la documentation. Aucun token a creer.

**Source de verification** : `grep` sur `app/src/styles/themes/` — 11/11 tokens trouves dans les deux themes.

---

### CL-002 : Correspondance exacte tokens issue vs code

| Champ | Valeur |
|-------|--------|
| **Categorie** | 8 - Terminologie |
| **Impact** | Haut |
| **Incertitude** | Moyenne |
| **Score** | HAUT |
| **Source** | spec.md NFR-002, marqueur `[NEEDS CLARIFICATION]` |
| **Resolution** | Automatique |

**Question** : Les noms de tokens listes dans l'issue correspondent-ils exactement aux variables CSS du code ?

**Reponse** : Oui, correspondance exacte pour les 11 tokens :

| Token issue | `_light.scss` | `_dark.scss` |
|-------------|---------------|--------------|
| `--hero-gradient` | L63 | L65 |
| `--glass-bg` | L64 | L66 |
| `--glass-border` | L65 | L67 |
| `--glass-blur` | L66 | L68 |
| `--page-gradient-color` | L67 | L69 |
| `--font-size-hero` | L68 | L70 |
| `--shadow-hero-text` | L69 | L71 |
| `--bg-success` | L40 | L39 |
| `--text-success` | L46 | L45 |
| `--bg-error` | L41 | L40 |
| `--text-error` | L47 | L46 |

---

### CL-003 : Scope Angular vs Flutter

| Champ | Valeur |
|-------|--------|
| **Categorie** | 1 - Scope fonctionnel |
| **Impact** | Haut |
| **Incertitude** | Moyenne |
| **Score** | HAUT |
| **Source** | spec.md A-003, marqueur `[NEEDS CLARIFICATION]` |
| **Resolution** | Automatique |

**Question** : Les patterns documentes concernent-ils aussi Flutter ou uniquement Angular ?

**Reponse** : Angular uniquement. Justification :
1. Le milestone est "Refonte UX pages interieures **(Angular)**"
2. L'issue ne mentionne que `app/DESIGN.md` dans les fichiers concernes
3. `DESIGN.md` est un fichier specifique a l'app Angular (`app/`)
4. Flutter a ses propres constantes dans `flutter/lib/src/constants/`

---

### CL-004 : Gestion dark vs light pour le glassmorphism

| Champ | Valeur |
|-------|--------|
| **Categorie** | 6 - Edge cases |
| **Impact** | Moyen |
| **Incertitude** | Moyenne |
| **Score** | MOYEN |
| **Source** | spec.md Edge Cases |
| **Resolution** | Automatique |

**Question** : Comment gerer les tokens specifiques au theme dark vs light pour le glassmorphism ?

**Reponse** : Les tokens sont deja theme-aware par design. Les valeurs changent significativement entre themes :

| Token | Light | Dark |
|-------|-------|------|
| `--glass-bg` | `var(--surface-raised)` (opaque) | `rgba(31, 41, 55, 0.6)` (translucide) |
| `--glass-border` | `var(--border-default)` | `rgba(255, 255, 255, 0.08)` |
| `--glass-blur` | `0px` (pas de blur) | `20px` (blur actif) |
| `--shadow-hero-text` | `none` | `0 2px 8px rgba(0, 0, 0, 0.3)` |
| `--hero-gradient` | `amber-50 → indigo-50` | `amber-900 → indigo-900` |

DESIGN.md doit documenter les deux variantes pour les tokens avec des valeurs significativement differentes (glassmorphism = effet visible en dark, desactive en light).

---

### CL-005 : Validation de l'assumption A-001 (tokens existants)

| Champ | Valeur |
|-------|--------|
| **Categorie** | 1 - Scope fonctionnel |
| **Impact** | Haut |
| **Incertitude** | Basse |
| **Score** | HAUT |
| **Source** | spec.md Assumptions A-001 |
| **Resolution** | Automatique |

**Question** : Les tokens listes dans l'issue existent-ils deja dans le code SCSS ?

**Reponse** : Oui, confirme. L'assumption A-001 est validee. Les 11 tokens sont definis dans les deux themes (light et dark). Le pattern `scale(0.97)` est egalement present dans `dashboard.scss` (lignes 52 et 158).

---

## Points differes

Aucun.

## Modifications appliquees a spec.md

1. Edge Cases : remplacement des 2 marqueurs `[NEEDS CLARIFICATION]` par les resolutions
2. NFR-002 : remplacement du marqueur `[NEEDS CLARIFICATION]` par la verification
3. A-003 : remplacement du marqueur `[NEEDS CLARIFICATION]` par la confirmation
