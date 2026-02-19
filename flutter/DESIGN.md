# Design Direction — Flutter

## Style

**Apple iOS natif + Copilot Money** — Interface épurée, aérée, élégante sans effort. Surfaces blanches élevées par des ombres douces sur fond gris clair. Hiérarchie créée par la typographie, pas par les bordures ni les couleurs. Les couleurs sont rares et intentionnelles. L'espace blanc respire. Chaque écran doit être compréhensible en 2 secondes.

> Less is more. Si un élément n'a pas besoin d'être là, il ne doit pas être là.

## Principes

1. **Clarté avant tout** — Les montants sont la star. Tout le reste est secondaire.
2. **Élévation par les ombres** — Pas de bordures sur les cards. L'ombre seule crée la profondeur.
3. **Typographie = hiérarchie** — Le poids et la taille du texte structurent l'écran.
4. **Couleur intentionnelle** — Les couleurs informent (vert = positif, rouge = négatif, amber = action). Elles ne décorent pas.
5. **Espace généreux** — En cas de doute, prendre le spacing au-dessus. L'app respire.
6. **Simple, classe, élégant** — Pas besoin d'en faire trop pour être beau.

---

## Tokens — ThemeExtension

Tous les tokens de design sont exposés via `ThemeExtension` sur le `ThemeData` Flutter. Les widgets lisent les tokens depuis `Theme.of(context)` — jamais de valeurs hardcodées.

Cela garantit :
- Basculement light/dark automatique
- Cohérence globale
- Point unique de modification

### Couleurs

#### Surfaces & Backgrounds

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `bgPrimary` | Gray 50 (`#f9fafb`) | Gray 900 (`#111827`) | Fond de page |
| `bgSecondary` | Gray 100 (`#f3f4f6`) | Gray 800 (`#1f2937`) | Fond secondaire, inputs iOS |
| `bgTertiary` | Gray 200 (`#e5e7eb`) | Gray 700 (`#374151`) | Container tabs, filtres |
| `surfaceDefault` | White (`#ffffff`) | Gray 800 (`#1f2937`) | Cards, éléments élevés |
| `surfaceRaised` | White (`#ffffff`) | Gray 700 (`#374151`) | Cards avec élévation forte |
| `surfaceOverlay` | Black 50% | Black 60% | Overlay modales |

#### Texte

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `textPrimary` | Gray 900 (`#111827`) | Gray 50 (`#f9fafb`) | Titres, montants |
| `textSecondary` | Gray 500 (`#6b7280`) | Gray 400 (`#9ca3af`) | Labels, sous-titres |
| `textTertiary` | Gray 400 (`#9ca3af`) | Gray 500 (`#6b7280`) | Placeholders, hints, dates |
| `textInverse` | White | Gray 900 | Texte sur fond primaire |

#### Accent & Actions

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `colorPrimary` | Amber 500 (`#f59e0b`) | Amber 400 (`#fbbf24`) | CTAs, éléments actifs, FAB |
| `colorPrimaryLight` | Amber 50 (`#fffbeb`) | Amber 900/20% | Fond icônes, highlights |
| `colorPrimaryHover` | Amber 600 (`#d97706`) | Amber 300 (`#fcd34d`) | État hover/press |

#### Sémantique métier

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `colorIncome` | Green 500 (`#10b981`) | Green 400 (`#34d399`) | Montants positifs, revenus |
| `colorExpense` | Red 500 (`#ef4444`) | Red 400 (`#f87171`) | Montants négatifs, dépenses |
| `colorDebtOwe` | Amber 500 (`#f59e0b`) | Amber 400 (`#fbbf24`) | Dettes qu'on doit |
| `colorDebtOwed` | Blue 500 (`#3b82f6`) | Blue 400 (`#60a5fa`) | Dettes qu'on nous doit |
| `colorSubscription` | Violet 500 (`#8b5cf6`) | Violet 400 (`#a78bfa`) | Abonnements |

#### Bordures

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `borderDefault` | Gray 200 (`#e5e7eb`) | Gray 700 (`#374151`) | Séparateurs de liste |
| `borderStrong` | Gray 300 (`#d1d5db`) | Gray 600 (`#4b5563`) | Séparateurs emphase |

#### Feedback

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `success` | `#10b981` | `#34d399` | Confirmations |
| `error` | `#ef4444` | `#f87171` | Erreurs |
| `warning` | `#f59e0b` | `#fbbf24` | Avertissements |
| `info` | `#3b82f6` | `#60a5fa` | Informations |

### Spacing

Grille de base : **4px**. Utiliser exclusivement les tokens `AppSpacing`.

| Token | Valeur | Usage |
|-------|--------|-------|
| `space1` | 4px | Gap micro (label ↔ valeur) |
| `space2` | 8px | Gap interne compact |
| `space3` | 12px | Padding boutons vertical |
| `space4` | 16px | Padding standard, gap entre éléments |
| `space5` | 20px | Padding cards |
| `space6` | 24px | Gap entre cards, padding sections |
| `space8` | 32px | Marges de page, séparations majeures |

**Règle** : en cas de doute, prendre la taille au-dessus.

### Radius

| Token | Valeur | Usage |
|-------|--------|-------|
| `sm` | 4px | Badges, petits éléments |
| `md` | 8px | Tabs actives internes |
| `lg` | 12px | Boutons secondaires, nav items actifs |
| `xl` | 16px | Cards, boutons primaires, inputs, modales |
| `round` | 999px | FAB, avatars, cercles catégorie |

### Shadows

Ombres multicouches (2 layers) pour un rendu réaliste. **Pas de bordures sur les cards** — l'ombre seule crée l'élévation.

| Token | Usage | Specs |
|-------|-------|-------|
| `sm` | List items, tabs actives | blur 2, offset 0/1, opacity 5% |
| `md` | Cards de contenu | blur 6, offset 0/2, opacity 10% |
| `lg` | Modales, FAB | blur 15, offset 0/4, opacity 10% |
| `colored(color)` | FAB amber glow | blur 8, offset 0/2, couleur 30% |

---

## Typographie

**Police** : Inter (bundled, pas de dépendance Google Fonts runtime).

### Taille utilisateur — 3 niveaux

L'utilisateur choisit son niveau de densité texte dans les Settings (persisté dans `AppConfig`). Toutes les tailles de police sont relatives à ce choix.

| Rôle | SM (compact) | MD (défaut) | XL (large) |
|------|-------------|-------------|------------|
| Montant principal | 20px | 24px | 30px |
| Montant secondaire | 14px | 16px | 19px |
| Titre section | 15px | 18px | 22px |
| Body | 13px | 16px | 19px |
| Label | 12px | 14px | 17px |
| Caption/date | 10px | 12px | 14px |

### Styles sémantiques

Les widgets utilisent des styles nommés par rôle métier, pas par taille générique :

| Style | Taille (MD) | Poids | Couleur |
|-------|-------------|-------|---------|
| `amountPrimary` | 24px | Bold (700) | `textPrimary` |
| `amountSecondary` | 16px | Semibold (600) | `textPrimary` |
| `amountIncome` | 16px | Semibold (600) | `colorIncome` |
| `amountExpense` | 16px | Semibold (600) | `colorExpense` |
| `sectionTitle` | 18px | Semibold (600) | `textPrimary` |
| `body` | 16px | Regular (400) | `textPrimary` |
| `label` | 14px | Medium (500) | `textSecondary` |
| `caption` | 12px | Regular (400) | `textTertiary` |

---

## Composants

### Cards

Deux variantes, même base :

**Base commune** :
- Border-radius : `xl` (16px)
- Background : `surfaceRaised`
- **Pas de bordure** — ombre seule
- Padding : `space5` (20px)

**Summary card** (dashboard) :
- Shadow : `md`
- Label en `caption` au-dessus du montant
- Montant en `amountPrimary`

**Content card** (listes) :
- Shadow : `sm`
- Padding : `space4` (16px)
- Items séparés par `borderDefault`, sauf le dernier

### List Items

Structure : icône | texte | montant

```
[Cercle catégorie]  Titre                    -25,00 €
                    Catégorie                      7j
```

- **Cercle catégorie** : 40x40px, `round`, fond = couleur catégorie en version light, emoji centré
- **Titre** : `body` + Medium (500)
- **Sous-titre** : `label` (catégorie)
- **Montant** : `amountSecondary`, coloré (income vert, expense rouge), aligné à droite
- **Date** : `caption`, format court (`7j`, `1sem`, `2m`)
- **Séparateur** : `borderDefault`, sauf dernier item
- **Padding** : `space4` vertical et horizontal

### Boutons

**Primaire** :
- Background : `colorPrimary`
- Texte : `textInverse`, Semibold
- Radius : `xl` (16px) — style iOS très arrondi
- Hauteur min : 48px (zone de tap)
- Padding : `space3` vertical, `space6` horizontal
- Press : opacity 0.85

**Secondaire/Ghost** :
- Background : transparent
- Texte : `colorPrimary`, Semibold
- Pas de bordure

**Danger** :
- Background : `error`
- Texte : `textInverse`

### FAB (Floating Action Button)

Le bouton d'action principal de l'app.

- Taille : 56x56px
- Radius : `round`
- Background : `colorPrimary`
- Shadow : `lg` + ombre colorée amber (`colored(amber)`)
- Icône : `textInverse`, 24px
- Position : bottom `space6`, right `space6`

**Interactions** :
- **Tap** → Crée directement une transaction (action à 80%)
- **Long press** → Menu expandé : abonnement, dette
- Animation d'ouverture du menu : scale + fade depuis le FAB

### Formulaires — Style iOS

Inputs propres et spacieux, look natif iOS :

- **Background** : `bgSecondary` (gris clair)
- **Bordure** : aucune en état normal
- **Radius** : `xl` (16px)
- **Padding** : `space3` vertical, `space4` horizontal
- **Focus** : léger changement de teinte + ring subtil `colorPrimaryLight`
- **Labels** : `label` style, au-dessus de l'input avec `space2` de gap
- **Groupement** : inputs groupés dans des cards `surfaceRaised` avec `xl` radius
- **Placeholder** : `textTertiary`

### Navigation

**Mobile (< 768px)** : barre en bas
- Background : `surfaceDefault`
- Item actif : icône + texte `colorPrimary`
- Item inactif : icône + texte `textTertiary`

**Desktop/Tablette (>= 768px)** : sidebar
- Largeur : 240px
- Background : `surfaceDefault`
- Item actif : fond `colorPrimaryLight`, texte `colorPrimary`, radius `lg`
- Pas de bordure droite — ombre subtile ou rien

### Modales / Bottom Sheets

- Radius : `xl` en haut (bottom sheet mobile)
- Shadow : `lg`
- Overlay : `surfaceOverlay`
- Padding : `space5`
- Handle : barre grise centrée en haut (4x32px, radius `round`, `bgTertiary`)

### Tabs / Filtres — Style iOS Segmented Control

- Container : `bgTertiary`, radius `lg`, padding `space1`
- Tab active : `surfaceRaised` (blanc), radius `md`, shadow `sm`
- Tab inactive : transparent, texte `textSecondary`
- Transition : 200ms ease

---

## Animations

- **Durée standard** : 200ms
- **Easing** : cubic-bezier(0.4, 0, 0.2, 1)
- **Transitions sur** : background-color, box-shadow, transform, opacity
- **Press** : opacity 0.85 ou scale 0.97
- **Modales** : slide-up + fade overlay
- **Tabs** : background slide 200ms
- **Navigation** : crossfade entre les écrans

---

## Règles absolues

1. **Jamais de valeur hardcodée** — toujours un token du ThemeExtension
2. **Jamais de bordure sur une card** — ombre only
3. **Jamais d'emoji ou d'icône décorative** — chaque élément visuel a un rôle
4. **Les montants dominent visuellement** — c'est une app de budget
5. **Dark mode = citoyen de première classe** — pas un afterthought, testé systématiquement
6. **Tester les 3 tailles texte** (SM/MD/XL) — vérifier que rien ne casse
