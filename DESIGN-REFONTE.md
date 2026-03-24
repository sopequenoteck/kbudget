# Refonte Design — Quiet Utility Dark-First

## Objectif

Transformer l'interface de K-Budget d'un style "dashboard corporate" vers un style **quiet utility dark-first**, inspire par TickTick, Stoic et Apple Journal. L'app doit etre calme, sobre, et laisser les donnees parler d'elles-memes.

## Direction validee

- **Dark-first** : tous les appareils de Kelly sont en dark mode. C'est l'experience primaire.
- **Quiet utility** : pas d'effets decoratifs. Pas de gradients. Pas de glass. L'interface s'efface derriere le contenu.
- **Couleur = information** : vert = revenu, rouge = depense, amber = action/CTA. Jamais de couleur decorative.
- **Typographie + spacing font tout le travail** : la hierarchie visuelle vient des tailles, graisses et espacements, pas des bordures ni des ombres.
- **Elevation par luminosite** : en dark mode, les surfaces plus claires sont plus "elevees". 3 niveaux : fond noir (#0a0a0a) > surface default (#141414) > surface raised (#1e1e1e).

## Processus

**Validation visuelle iterative**, pas de formalisation prealable. On change, on regarde, on reagit, on ajuste. Le DESIGN.md sera reecrit APRES que le resultat soit valide visuellement.

## Ce qui a ete fait (session 1)

### Primitives
- Palette gray remplacee : Tailwind (bleu-teinte) -> gris neutres purs (#0a0a0a a #fafafa)
- Plus aucun sous-ton bleu dans les fonds

### Theme dark — tokens
- Hero gradient : supprime (surface plate)
- Glassmorphism : supprime (glass-bg, glass-border, glass-blur -> surfaces solides)
- Radial gradient fond de page : supprime sur toutes les pages (dashboard, transactions, abonnements, dettes)
- Ombre coloree FAB : neutralisee (noir au lieu d'amber)
- Shadow hero text : supprime
- Couleurs metier attenuees : vert #4ade80 -> #6dc990, rouge #f87171 -> #d97777 (moins saturees)
- Couleurs feedback attenuees dans la meme logique
- Primary amber adouci : #fbbf24 -> #e0a820
- Sidebar active : rgba(255,255,255,0.08) au lieu d'amber-900

### Dashboard — structure
- **Hero section** : greeting + patrimoine + revenus/depenses fusionnes en une seule section (etaient 2 sections separees)
- Greeting passe de titre dominant a texte secondaire discret (sm, text-secondary)
- Revenus/Depenses : plus de cards separees avec dots/variation bars. Maintenant inline dans un conteneur arrondi avec divider
- Variation badges : plus de fond colore (etaient des barres full-width). Maintenant texte simple
- Gap entre hero et sections detail : space-8 (32px) au lieu de space-5 (20px) — le hero respire

### Dashboard — composants
- **Budget items** : plus de cards individuelles. Un seul conteneur arrondi (surface-default), items separes par border-bottom. Emojis sans cercle colore.
- **Operations** : meme traitement — un conteneur arrondi, items plats avec separateurs
- **Progress bars budgets** : 4px au lieu de 10px, opacity 0.7

### Typographie — hierarchie
- Hero amount : 3xl (30px) bold — LE chiffre dominant
- Section titles : base (16px) semibold, text-secondary — fonctionnels, pas imposants
- Summary values : sm (14px) semibold — secondaires
- List titles : sm (14px) medium
- List amounts : sm (14px) semibold
- Labels : xs (12px) medium
- Tertiary (dates, converted) : xs (12px) normal, text-tertiary

### Shell — header et bottom nav
- Header : 56px -> 64px, logo 28px -> 34px, nom xl, padding space-5, surface-raised
- Bottom nav : 64px -> 72px, icones 1.625rem, surface-raised
- Les deux utilisent border (pas shadow) et surface-raised pour se detacher du fond

### List item (composant partage)
- Cercles emoji : plus de fond color-primary-light. Maintenant rgba(255,255,255,0.06), taille reduite
- Titres : sm au lieu de base
- Sous-titres : xs, text-tertiary

## Ce qui reste a faire

### Priorite haute
- [ ] Propager le style aux autres pages (Transactions, Abonnements, Dettes, Budgets) — memes principes de conteneurs, typographie, spacing
- [ ] Revoir la page Budgets complete (progress bars, chart donut)
- [ ] Page Settings (pas encore vue)
- [ ] Modales et formulaires (bottom sheets)

### Priorite moyenne
- [ ] Micro-interactions (transitions de page, feedback tactile)
- [ ] Empty states (illustrations ou messages soignes)
- [ ] Skeleton loading au lieu de spinners

### A faire en dernier
- [ ] Reecrire DESIGN.md a partir du resultat valide
- [ ] Aligner les tokens Flutter (DESIGN.md Flutter) avec les nouvelles valeurs
- [ ] Appliquer la meme direction a Kassist

## References visuelles

- **TickTick** : clean, utilitaire, listes propres, accent discret
- **Stoic** : calme, minimal, couleurs douces
- **Apple Journal** : natif iOS, invisible, contenu-first

## Anti-patterns identifies

Ce qu'on a retire et qu'il ne faut PAS reintroduire :
- Gradients decoratifs (hero card amber->indigo)
- Glassmorphism / backdrop-filter blur
- Ombres colorees (FAB amber glow)
- Radial gradients en fond de page
- Couleurs saturees Tailwind 400 en dark mode
- Cards individuelles par item de liste (preferer un conteneur groupe)
- Variation badges avec fond colore full-width
