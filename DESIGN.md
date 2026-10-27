# Design — Quiet Utility Dark-First

Reference design pour K-Budget. Source de verite pour tout composant frontend Angular.
Pour l'historique des decisions : voir `DESIGN-REFONTE.md` (20 sessions).

## Principes

1. **Couleur = information** : vert = revenu, rouge = depense, amber = action/CTA. Jamais de couleur decorative.
2. **Typographie + spacing** : la hierarchie vient des tailles, graisses et espacements — pas des bordures ni des ombres.
3. **Dark-first** : le dark mode est l'experience primaire. Elevation par luminosite (fond sombre < surface < raised).
4. **Un seul niveau de surface modale** : bottom sheet OU dialog centre. Jamais deux empiles.
5. **Tokens uniquement** : `var(--k-*)` partout (k-design), `var(--x)` pour les seuls tokens locaux de `styles/_app-tokens.scss`. Jamais de hex/rgba hardcode dans les composants. Controle par `cd app && npm run lint:styles` (Stylelint, variables inconnues, selecteurs en double dans la feuille globale ; job CI **Styles APP**, KKS-590) ; une exception se nomme sur sa ligne (`stylelint-disable-next-line … -- raison`).

## Anti-patterns

- Gradients decoratifs, glassmorphism, radial gradients, ombres colorees
- Cards individuelles par item (preferer conteneur groupe + dividers)
- `<input type="date">` natif dans les bottom sheets (preferer InlineDatePicker)
- Spinners CSS (preferer skeleton pulse)
- Segmented controls pour filtrer (preferer groupement + sections)
- Couleur secondaire sans role semantique

## Tokens : k-design

Les valeurs ne sont plus donnees ici. Elles vivent dans **k-design** (`tokens.json`, decisions D1–D16 dans `docs/decisions.md`) et dans le design system Quiet Utility qu'il genere ; K-Budget en recoit une copie par son `scripts/sync.mjs` (manifeste `k-design.json`) : `app/src/styles/k/k-tokens.css` (`--k-*`) pour le web, `flutter/lib/src/theme/k_tokens.dart` (`KTokens`) pour Flutter, ou `AppColors` en est un alias (KKS-589). Les tableaux ci-dessous donnent le role de chaque token.

## Couleurs — 4 canaux

| Canal | Token | Usage |
|-------|-------|-------|
| Action | `--k-color-primary` (texte dessus : `--k-color-primary-contrast`) | CTA, toggles actifs, FAB, liens |
| Revenu | `--k-color-income` | Montants positifs, prets |
| Depense | `--k-color-expense` | Montants negatifs, emprunts |
| Structure | `--k-text-primary/secondary/tertiary` | Texte, icones, labels |

Pas de couleur secondaire. L'indigo (`#6366f1`) existe uniquement dans les palettes utilisateur (categories/comptes).

## Surfaces — 3 niveaux

| Niveau | Token | Usage |
|--------|-------|-------|
| Fond page | `--k-bg-primary` | Background global |
| Contenu | `--k-surface-default` | Cards, conteneurs, listes |
| Chrome | `--k-surface-raised` | Header, bottom nav, FAB, sticky headers |

## Typographie

Police : Inter Variable, embarquee par k-design (`--k-font-family`).

| Role | Token | Poids |
|------|-------|-------|
| Hero montant | `--k-font-size-3xl` | bold |
| Titre page | `--k-font-size-lg` | bold |
| Section header | `--k-font-size-base` | semibold, `--k-text-secondary` |
| List row titre | `--k-font-size-sm` | medium, `--k-text-secondary` |
| List row montant | `--k-font-size-xs` | medium |
| Label uppercase | `--k-font-size-xs` | medium, uppercase, letter-spacing 0.05em, `--k-text-tertiary` |
| Meta/hints | `--k-font-size-xs` | normal, `--k-text-tertiary` |

## Patterns

### Hero

Bloc financier dominant en haut de chaque page. Structure :

- Label uppercase xs/tertiary (ex: "PATRIMOINE TOTAL", "SOLDE")
- Montant 3xl bold, couleur selon sens (income/expense/neutre)
- Conversion devise secondaire en italique xs/tertiary
- Meta-lines avec icones Phosphor 14px/text-tertiary (ex: revenus, depenses, compteurs)
- Toggle devise ancre a un element existant (label ou nav mois)

Classes : `.hero`, `.hero__amount-value`, `.hero__meta`, `.hero__meta-line`

### Page header (sous-pages)

Fleche retour ronde 36px + titre aligne a droite. Utilise sur les pages detail et les sous-pages.

Classe : `.page-header`, `.page-header__back`, `.page-header__title`

### Auth identity

Bloc identite fort en haut des pages d'authentification. Composition :

- Logo SVG 64px + wordmark 3xl bold / `--k-text-primary` + sous-titre sm / `--k-text-secondary`
- Aligne a gauche, padding vertical genereux (`--k-space-8` en haut), pas de border-bottom separatrice
- Formulaire rendu directement sur `--k-bg-primary` — pas de card ni de `.form-block` wrapper

Composant : `<app-auth-shell>` (inputs : `title`, `tagline`, `error`, `size`) — footer discret en bas a gauche affichant la version (`vX.Y.Z`, xs/tertiary, sans bordure ni fond)

Sections avec labels uppercase (accept-invite uniquement) : regroupement "VOTRE IDENTITE" et "PREFERENCES" via la classe `.form-section` + `.form-section__label` (xs/medium/uppercase/letter-spacing 0.05em/`--k-text-tertiary`). Spacing entre sections : `--k-space-8`. Devise et fuseau horaire en grille 2 colonnes (`grid-template-columns: 1fr 1fr`, retour 1 colonne sous 360px).

Exception input prefix icon : les inputs des pages auth (login, accept-invite, first-login-reset) utilisent une icone prefix Phosphor 16px en `--k-text-tertiary` (envelope/lock/user/coin/globe) via l'input optionnel `prefixIcon` de `<app-form-field>`. Pattern non propage au reste de l'app.

### Section header (sticky)

Titre + compteur + icones action. Sticky sous le header app. Fond dynamique quand colle (surface-raised).

Classes : `.section-header`, `.section-header.stuck`, `.section-header__title`, `.section-header__count`, `.section-header__action-btn`

### Liste groupee

Conteneur arrondi `surface-default` + `radius-xl`. Items separes par `border-default` 1px. Pas de cards individuelles.

- Icone cercle 36px (`--k-icon-circle-bg`) + couleur categorie en fond 15%
- Titre sm/text-secondary + subtitle xs/text-tertiary
- Montant xs/medium a droite + conversion italique
- Date labels (tertiary, amber si aujourd'hui, rouge si en retard)
- Groupes collapsibles avec chevron + compteur

Classes : `.list-group`, `.list-row`, `.list-row__icon`, `.list-row__title`, `.list-row__amount`, `.date-label`, `.group-label`

### Bottom sheet (formulaires)

Conteneur unique pour creation/edition. 4 rows :

1. **Handle + titre** : barre 36x4px centree + titre entite (icone + nom) + toggle type (si applicable)
2. **Montant + libelle** : montant hero 30px (couleur contextuelle) + libelle aligne droite (underline)
3. **Icones + pills** : icones secondaires a gauche (note, recurrence) + pills meta a droite (date, categorie, compte) scrollables
4. **Actions** : Annuler/Supprimer a gauche | Enregistrer a droite, border-top separator

Sections expandables : une seule active a la fois. InlineDatePicker pour les dates.

Retour arriere (geste Android, bouton precedent, KKS-447) : replie d'abord la section depliee (saisie intacte), puis ferme la feuille. Toute surface modale s'enregistre aupres de `HistoryLayerService` (`bindHistoryLayer`, `bindExpandedSectionLayer`) ; une surface ouverte au-dessus d'une feuille (confirm, select-picker) est fermee la premiere.

Classes : `.bsheet__handle`, `.bsheet__main-row`, `.bsheet__amount`, `.bsheet__meta-row`, `.bsheet__tool-pill`, `.bsheet__expand`, `.bsheet__bottom-row`, `.bsheet__action-pill`

### Empty state

Icone Phosphor 48px (opacity 50%) + message sm/text-secondary + CTA text link amber optionnel. Centre, padding space-10.

Composant : `<app-empty-state>`

### Confirm dialog

Toujours centre (jamais bottom sheet). Icone metier + titre concret (nom + montant) + message question. Boutons pills compacts. Variantes `default` (amber) et `danger` (rouge).

Service : `ConfirmService.confirm()`

### Autocomplete

Champ input natif surmonte d'un overlay absolu listant les suggestions. Utilise pour le libelle de transaction (KKS-230) et potentiellement d'autres champs libres avec suggestions historiques.

Contrat signals-first : `value` (model), `suggestions` (input), `minChars` (defaut 2), `maxDisplay` (defaut 5), outputs `selected` et `queryChange` (debounce 200ms).

Comportement :
- Seuil `minChars` avant ouverture — aucune requete en dessous
- Debounce 200ms sur `queryChange`
- Filtrage local additionnel case/accent-insensible (NFD + suppression diacritiques)
- Navigation clavier : ArrowDown/Up (wrap), Enter (select), Escape (close sans modification)
- ARIA : `role="combobox"`, `aria-autocomplete="list"`, `aria-expanded`, `role="listbox"`, `role="option"`, `aria-activedescendant`
- Saisie libre toujours possible (aucun lock sur la valeur)

Style : tokens CSS uniquement, overlay en `surface-raised` avec `radius-md` et shadow legere. Items actifs en `hover-bg`.

Composant : `<app-autocomplete>` dans `app/src/app/shared/components/autocomplete/`

### Category Select (inline expand)

Selecteur de categorie dedie au contexte bottom-sheet. Remplace l'ancien `app-category-picker` qui empilait un second sheet (violation du principe #4). Utilise en tant que dumb component dans les formulaires `transaction-form`, `subscription-form` et `debt-form` via leur signal `expandedSection` (KKS-231).

Contrat signals-first : `value` (model via CVA `formControlName`), `categories` (input — liste prechargee par le parent), outputs `selected` (id), `created` (nouvelle categorie), `isCreating` (bascule list ↔ create).

Comportement :
- Rendu inline dans un `bsheet__expand` (aucun overlay, aucun second bottom-sheet)
- Recherche insensible a la casse et aux accents (helper partage `normalize()` — NFD + suppression diacritiques)
- Scroll interne `max-height: 60vh` + `overflow-y: auto` sur la liste — footer du sheet toujours accessible
- Bouton `+ Creer « terme »` quand la recherche ne matche aucune categorie
- Mode creation inline : push/pop dans l'expand avec nom pre-rempli depuis la recherche ; en-tete `← Retour` + `✓ Creer` ; footer du sheet parent desactive (pas masque) pendant la creation
- Retour depuis la creation : la recherche est conservee
- Apres creation reussie : la nouvelle categorie est automatiquement selectionnee et l'expand se collapse
- Navigation clavier : ArrowDown/Up (wrap), Enter (select), Escape (pop to list en mode creation, reset search en mode list)
- ARIA : `role="combobox"`, `aria-autocomplete="list"`, `aria-expanded`, `role="listbox"`, `role="option"`, `aria-activedescendant`

Integration cote parent : precharger les categories via `toSignal(CategoryService.getAll())` converti en signal mutable, ecouter `(created)` pour ajouter la nouvelle categorie au cache local, `(selected)` pour collapser l'expand (`expandedSection.set(null)`), `(isCreating)` pour desactiver le footer du sheet.

Style : tokens uniquement, pattern `.cs__*` derive de `_list-patterns.scss` (icon-circle 36px avec fond colore a 15% via suffixe hex `+ '26'`, selection en `--k-primary-subtle`).

Composant : `<app-category-select>` dans `app/src/app/shared/components/category-select/`

### Skeleton loading

Imite la forme du contenu reel. Cercle 36px + lignes largeurs variees. Animation pulse 1.5s.

Classes : `.skeleton-item`, `.skeleton-circle`, `.skeleton-line`, `.skeleton-hero`

## Tokens interactifs

| Token | Usage |
|-------|-------|
| `--k-hover-bg` | Fond hover sur rows et boutons |
| `--k-hover-subtle` | Fond tres leger (4%) |
| `--k-primary-subtle` | Fond amber 10% (selection legere) |
| `--k-primary-muted` | Fond amber 15% (boutons soft) |
| `--k-primary-border` | Bordure amber 25% |
| `--k-icon-circle-bg` | Fond cercle icone (6% blanc dark, 4% noir light) |
| `--k-highlight-subtle` | Press feedback (10%) |

## Zones sures (PWA installee)

`viewport-fit=cover` : le contenu passe sous l'encoche et la barre de gestes. Tout element colle a un bord (en-tete, barre du bas, FAB, feuilles, toasts, panneaux) ajoute `--safe-top` / `--safe-right` / `--safe-bottom` / `--safe-left` (`env(safe-area-inset-*)`, 0 hors iPhone a encoche). `--header-height` et `--bottom-nav-height` incluent deja la zone sure. Barre d'etat iOS en `black-translucent` : l'en-tete passe dessous (texte de la barre blanc, illisible en theme clair, limite acceptee) ; `theme-color` suit `--k-surface-raised` (Android, Safari hors PWA).

## Fichiers SCSS partages

| Fichier | Contenu |
|---------|---------|
| `styles/k/k-tokens.css` | Tokens k-design (`--k-*`), copie generee, ne pas editer (k-design D14). Charge avant `styles.scss` par `angular.json`. Theme : `data-theme="dark|light"` sur `<html>`, sombre par defaut, pose par `ThemeService` |
| `styles/_app-tokens.scss` | Tokens propres a K-Budget, non portes par k-design : zones sures, hauteurs d'en-tete et de barre basse, durees et easings (KKS-597) |
| `styles/_list-patterns.scss` | Hero, section-header, list-group, list-row, skeleton |
| `styles/_bottom-sheet.scss` | Bottom sheet 4 rows, pills, expand, actions |
| `styles/_forms.scss` | Inputs, selects, textareas, utilities |
