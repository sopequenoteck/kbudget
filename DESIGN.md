# Design — Quiet Utility Dark-First

Reference design pour K-Budget. Source de verite pour tout composant frontend Angular.
Pour l'historique des decisions : voir `DESIGN-REFONTE.md` (20 sessions).

## Principes

1. **Couleur = information** : vert = revenu, rouge = depense, amber = action/CTA. Jamais de couleur decorative.
2. **Typographie + spacing** : la hierarchie vient des tailles, graisses et espacements — pas des bordures ni des ombres.
3. **Dark-first** : le dark mode est l'experience primaire. Elevation par luminosite (fond sombre < surface < raised).
4. **Un seul niveau de surface modale** : bottom sheet OU dialog centre. Jamais deux empiles.
5. **Tokens uniquement** : `var(--token)` partout. Jamais de hex/rgba hardcode dans les composants.

## Anti-patterns

- Gradients decoratifs, glassmorphism, radial gradients, ombres colorees
- Cards individuelles par item (preferer conteneur groupe + dividers)
- `<input type="date">` natif dans les bottom sheets (preferer InlineDatePicker)
- Spinners CSS (preferer skeleton pulse)
- Segmented controls pour filtrer (preferer groupement + sections)
- Couleur secondaire sans role semantique

## Couleurs — 4 canaux

| Canal | Token | Dark | Light | Usage |
|-------|-------|------|-------|-------|
| Action | `--color-primary` | #e0a820 | amber-600 | CTA, toggles actifs, FAB, liens |
| Revenu | `--color-income` | #6dc990 | #16a34a | Montants positifs, prets |
| Depense | `--color-expense` | #d97777 | #dc2626 | Montants negatifs, emprunts |
| Structure | `--text-primary/secondary/tertiary` | gray-50/400/500 | gray-900/600/400 | Texte, icones, labels |

Pas de couleur secondaire. L'indigo (`#6366f1`) existe uniquement dans les palettes utilisateur (categories/comptes).

## Surfaces — 3 niveaux

| Niveau | Token | Dark | Light | Usage |
|--------|-------|------|-------|-------|
| Fond page | `--bg-primary` | #0a0a0a | #f0f0f0 | Background global |
| Contenu | `--surface-default` | gray-800 | #fff | Cards, conteneurs, listes |
| Chrome | `--surface-raised` | gray-700 | gray-100 | Header, bottom nav, FAB, sticky headers |

## Typographie

| Role | Token | Taille | Poids |
|------|-------|--------|-------|
| Hero montant | `--font-size-3xl` | 30px | bold |
| Titre page | `--font-size-lg` | 18px | bold |
| Section header | `--font-size-base` | 16px | semibold, `--text-secondary` |
| List row titre | `--font-size-sm` | 14px | medium, `--text-secondary` |
| List row montant | `--font-size-xs` | 12px | medium |
| Label uppercase | `--font-size-xs` | 12px | medium, uppercase, letter-spacing 0.05em, `--text-tertiary` |
| Meta/hints | `--font-size-xs` | 12px | normal, `--text-tertiary` |

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

- Logo SVG 64px + wordmark 3xl bold / `--text-primary` + sous-titre sm / `--text-secondary`
- Aligne a gauche, padding vertical genereux (`--space-8` en haut), pas de border-bottom separatrice
- Formulaire rendu directement sur `--bg-primary` — pas de card ni de `.form-block` wrapper

Composant : `<app-auth-shell>` (inputs : `title`, `tagline`, `error`, `size`) — footer discret en bas a gauche affichant la version (`vX.Y.Z`, xs/tertiary, sans bordure ni fond)

Sections avec labels uppercase (accept-invite uniquement) : regroupement "VOTRE IDENTITE" et "PREFERENCES" via la classe `.form-section` + `.form-section__label` (xs/medium/uppercase/letter-spacing 0.05em/`--text-tertiary`). Spacing entre sections : `--space-8`. Devise et fuseau horaire en grille 2 colonnes (`grid-template-columns: 1fr 1fr`, retour 1 colonne sous 360px).

Exception input prefix icon : les inputs des pages auth (login, accept-invite, first-login-reset) utilisent une icone prefix Phosphor 16px en `--text-tertiary` (envelope/lock/user/coin/globe) via l'input optionnel `prefixIcon` de `<app-form-field>`. Pattern non propage au reste de l'app.

### Section header (sticky)

Titre + compteur + icones action. Sticky sous le header app. Fond dynamique quand colle (surface-raised).

Classes : `.section-header`, `.section-header.stuck`, `.section-header__title`, `.section-header__count`, `.section-header__action-btn`

### Liste groupee

Conteneur arrondi `surface-default` + `radius-xl`. Items separes par `border-default` 1px. Pas de cards individuelles.

- Icone cercle 36px (`--icon-circle-bg`) + couleur categorie en fond 15%
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

Style : tokens uniquement, pattern `.cs__*` derive de `_list-patterns.scss` (icon-circle 36px avec fond colore a 15% via suffixe hex `+ '26'`, selection en `--primary-subtle`).

Composant : `<app-category-select>` dans `app/src/app/shared/components/category-select/`

### Skeleton loading

Imite la forme du contenu reel. Cercle 36px + lignes largeurs variees. Animation pulse 1.5s.

Classes : `.skeleton-item`, `.skeleton-circle`, `.skeleton-line`, `.skeleton-hero`

## Tokens interactifs

| Token | Usage |
|-------|-------|
| `--hover-bg` | Fond hover sur rows et boutons |
| `--hover-subtle` | Fond tres leger (4%) |
| `--primary-subtle` | Fond amber 10% (selection legere) |
| `--primary-muted` | Fond amber 15% (boutons soft) |
| `--primary-border` | Bordure amber 25% |
| `--icon-circle-bg` | Fond cercle icone (6% blanc dark, 4% noir light) |
| `--highlight-subtle` | Press feedback (10%) |

## Fichiers SCSS partages

| Fichier | Contenu |
|---------|---------|
| `styles/tokens/_primitives.scss` | Variables SCSS (palettes, spacing, typo) |
| `styles/tokens/_tokens.scss` | CSS custom properties sur :root |
| `styles/themes/_dark.scss` | Tokens semantiques dark |
| `styles/themes/_light.scss` | Tokens semantiques light |
| `styles/_list-patterns.scss` | Hero, section-header, list-group, list-row, skeleton |
| `styles/_bottom-sheet.scss` | Bottom sheet 4 rows, pills, expand, actions |
| `styles/_forms.scss` | Inputs, selects, textareas, utilities |
