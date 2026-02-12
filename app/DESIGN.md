# Design Direction

## Style

**Apple iOS + Copilot Money** — Interface clean, aérée et lumineuse. Surfaces blanches élevées sur fond gris clair. Hiérarchie forte par la typographie (poids et taille). Coins très arrondis, ombres douces multicouches. Les couleurs sont utilisées avec parcimonie pour guider l'attention : accents amber, vert pour les revenus, rouge pour les dépenses. L'espace blanc est un élément de design à part entière.

## Principes

1. **Clarté avant tout** — Chaque écran doit être compréhensible en 2 secondes. Les montants sont la star.
2. **Élévation par les ombres** — Les cards flottent au-dessus du fond. Pas de bordures visibles sur les cards, uniquement des ombres.
3. **Typographie = hiérarchie** — Le poids et la taille du texte créent la structure, pas les bordures ni les couleurs.
4. **Couleur intentionnelle** — Les couleurs ne décorent pas, elles informent (vert = positif, rouge = négatif, amber = action).
5. **Espace généreux** — Le padding est toujours plus grand que ce qu'on pense nécessaire. L'app respire.

## Palette

- **Primary** : Amber 500 (`#f59e0b`) — accents, CTAs, éléments actifs
- **Background** : Gray 50 (`#f9fafb`) — fond de page principal
- **Surface** : Blanc pur (`#fff`) — cards, modales, éléments élevés
- **Text primary** : Gray 900 (`#111827`) — titres, montants
- **Text secondary** : Gray 500 (`#6b7280`) — labels, sous-titres, dates
- **Text tertiary** : Gray 400 (`#9ca3af`) — placeholders, hints
- **Income** : Green 600 (`#16a34a`) — montants positifs
- **Expense** : Red 600 (`#dc2626`) — montants négatifs
- **Feedback** : success/error/warning/info existants

## Typographie

- **Font** : Inter (déjà en place)
- **Montants principaux** : `font-size-2xl` (24px) + `font-weight-bold` (700) — les montants dominent visuellement
- **Montants secondaires** : `font-size-base` (16px) + `font-weight-semibold` (600)
- **Titres de section** : `font-size-lg` (18px) + `font-weight-semibold` (600)
- **Labels** : `font-size-sm` (14px) + `font-weight-medium` (500) + `text-secondary`
- **Captions/dates** : `font-size-xs` (12px) + `font-weight-normal` (400) + `text-tertiary`

## Composants de référence

### Cards (Summary)

Les cards de résumé (Recettes/Dépenses/Solde) sont les éléments les plus visibles.

- Border-radius : `--radius-xl` (16px)
- Shadow : `--shadow-md` — ombre douce multicouche
- Padding : `--space-5` (20px) vertical, `--space-5` horizontal
- Background : `--surface-raised` (blanc)
- **Pas de bordure** — l'ombre seule crée l'élévation
- Les montants sont en `font-size-2xl` + `font-weight-bold`
- Les labels sont en `font-size-xs` + `text-secondary`, au-dessus du montant
- Icône ou indicateur coloré optionnel (petit dot ou barre latérale)

### Cards (Content)

Les sections de contenu (listes de transactions, abonnements, dettes).

- Border-radius : `--radius-xl` (16px)
- Shadow : `--shadow-sm` — plus subtile que les summary cards
- Padding : `--space-4` (16px)
- Background : `--surface-raised`
- **Pas de bordure extérieure**
- Les items à l'intérieur sont séparés par `border-bottom: 1px solid var(--border-default)` sauf le dernier

### Boutons

- **Primaire** : Background `--color-primary`, texte blanc, `border-radius: --radius-xl` (16px, très arrondi style iOS)
- **Secondaire/Ghost** : Background transparent, texte `--color-primary`, pas de bordure
- **Danger** : Background `--text-error`, texte blanc
- Hauteur minimum : 48px (zone de tap mobile)
- Padding : `--space-3` vertical, `--space-6` horizontal
- Transition douce sur hover (opacity 0.85)

### Listes (List Items)

Style Copilot Money — chaque item est lisible et aéré.

- Padding : `--space-4` vertical, `--space-4` horizontal
- **Icône catégorie** : emoji dans un cercle coloré (40x40px, `border-radius: --radius-round`, background `--color-primary-light` ou couleur de la catégorie en light)
- **Titre** : `font-size-base` + `font-weight-medium`
- **Sous-titre** : `font-size-sm` + `text-secondary` (catégorie ou date)
- **Montant** : `font-size-base` + `font-weight-semibold`, aligné à droite, coloré selon type (income vert, expense rouge)
- **Date** : `font-size-xs` + `text-tertiary`, sous le montant à droite
- Séparateur : `border-bottom` léger `--border-default`, sauf dernier item
- Hover : background `--hover-bg` avec transition douce

### Navigation (Sidebar)

Style iOS Settings — propre et minimal.

- Background : `--surface-default` (blanc)
- Largeur : 240px (existant)
- Items : padding `--space-3` vertical, `--space-5` horizontal
- Item actif : background `--color-primary-light`, texte `--color-primary`, `border-radius: --radius-lg` avec marge horizontale de `--space-2`
- Item hover : background `--hover-bg`
- Séparation bas (Déconnexion) : `border-top` + `margin-top: auto`
- Pas de bordure droite visible — utiliser une ombre subtile `box-shadow: 1px 0 0 var(--border-default)` ou rien

### Formulaires

Style iOS natif — inputs propres et spacieux.

- Border-radius : `--radius-xl` (16px)
- Border : `1px solid var(--border-default)`
- Padding : `--space-3` (`12px`) vertical, `--space-4` (`16px`) horizontal
- Focus : border `--color-primary` + `box-shadow: 0 0 0 4px var(--color-primary-light)`
- Labels : `font-size-sm` + `font-weight-medium` + `text-secondary`, au-dessus de l'input avec `--space-2` de gap
- Grouper les inputs dans des cards blanches avec `--radius-xl`

### Modales

- Border-radius : `--radius-xl` (16px) en haut (bottom sheet sur mobile)
- Shadow : `--shadow-lg`
- Overlay : `--surface-overlay`
- Header : titre centré + bouton fermer discret
- Padding contenu : `--space-5`

### Tabs / Filtres

Style iOS segmented control — pas des boutons plats.

- Container : background `--bg-tertiary` (gris clair), `border-radius: --radius-lg`, padding `--space-1`
- Tab active : background `--surface-raised` (blanc), `border-radius: --radius-md`, `--shadow-sm`
- Tab inactive : transparent, texte `--text-secondary`
- Transition : `--duration-normal` ease sur background et shadow
- **Pas de fond amber** sur la tab active — le blanc élevé sur fond gris suffit

### FAB (Floating Action Button)

- Taille : 56x56px
- Border-radius : `--radius-round`
- Background : `--color-primary`
- Shadow : `--shadow-lg` + ombre colorée amber (`0 4px 14px rgb(245 158 11 / 0.4)`)
- Icône : blanc, 24px
- Position : `bottom: --space-6`, `right: --space-6`

### Month Selector

- Boutons flèches : cercles 44x44px, background `--surface-raised`, `--shadow-sm`, `--radius-round`
- **Pas de bordure** sur les boutons — ombre seule
- Mois : `font-size-xl` + `font-weight-bold`

## Spacing

- Unité de base : 4px (existant)
- **Échelle utilisée** :
  - `xs` = `--space-1` (4px) — gap entre label et valeur
  - `sm` = `--space-2` (8px) — gap interne compact
  - `md` = `--space-4` (16px) — padding standard, gap entre éléments
  - `lg` = `--space-6` (24px) — padding sections, gap entre cards
  - `xl` = `--space-8` (32px) — marges de page, séparations majeures
- **Règle** : en cas de doute, prendre la taille au-dessus

## Animations

- Durée standard : `--duration-normal` (200ms)
- Easing : `--easing-default` (cubic-bezier 0.4, 0, 0.2, 1)
- Transitions sur : background-color, box-shadow, transform, opacity
- Hover : transition opacity ou background-color
- Modales : slide-up depuis le bas + fade overlay
- Tabs : background slide avec `--duration-normal`

## Tokens existants à utiliser

Ne JAMAIS hardcoder de valeurs. Utiliser exclusivement ces tokens :

### Couleurs
`--color-primary`, `--color-primary-hover`, `--color-primary-light`, `--color-primary-contrast`
`--bg-primary`, `--bg-secondary`, `--bg-tertiary`
`--surface-default`, `--surface-raised`, `--surface-overlay`
`--text-primary`, `--text-secondary`, `--text-tertiary`, `--text-inverse`
`--border-default`, `--border-strong`
`--hover-bg`, `--focus-ring`
`--color-income`, `--color-expense`, `--color-debt-owe`, `--color-debt-owed`

### Spacing
`--space-0` à `--space-12`

### Radius
`--radius-sm`, `--radius-md`, `--radius-lg`, `--radius-xl`, `--radius-round`

### Shadows
`--shadow-sm`, `--shadow-md`, `--shadow-lg`

### Typography
`--font-size-xs` à `--font-size-3xl`
`--font-weight-normal`, `--font-weight-medium`, `--font-weight-semibold`, `--font-weight-bold`

### Animations
`--duration-fast`, `--duration-normal`, `--duration-slow`
`--easing-default`, `--easing-in`, `--easing-out`
