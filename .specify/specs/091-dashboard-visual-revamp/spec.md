# Feature Specification: Dashboard Finance — Refonte visuelle premium

**Feature Branch**: `091-dashboard-visual-revamp`
**Created**: 2026-03-15
**Status**: Draft
**Input**: Refonte visuelle du dashboard finance Angular pour une expérience premium inspirée iOS (glassmorphism, gradients, micro-interactions)

## Clarifications

### Session 2026-03-15

- Q: Le glassmorphism doit-il s'appliquer en light mode aussi ? → A: Non, glassmorphism dark mode uniquement. En light mode, les cards Revenus/Dépenses utilisent un fond opaque stylé (pas de backdrop-filter).
- Q: Les barres de budget doivent-elles utiliser des seuils fixes ou le seuilNotification configurable du backend ? → A: Réutiliser le `seuilNotification` du budget (défaut 80%) pour le changement de couleur warning, 100% pour danger.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Hiérarchie visuelle et Hero card patrimoine (Priority: P1)

L'utilisateur ouvre le dashboard et identifie immédiatement son patrimoine total grâce à une card hero visuellement différenciée (gradient, typographie amplifiée, profondeur). Le montant principal est le point focal évident de la page, avec les variations mensuelles affichées sous forme de badges colorés plutôt que de texte inline.

**Why this priority**: Le patrimoine total est l'information la plus importante du dashboard. Sans hiérarchie visuelle claire, l'utilisateur doit scanner l'écran pour trouver cette donnée. C'est le changement à plus fort impact perceptif.

**Independent Test**: Ouvrir le dashboard et vérifier que la zone patrimoine se distingue visuellement de toutes les autres sections (fond différent, taille du montant plus grande, gradient visible).

**Acceptance Scenarios**:

1. **Given** le dashboard en dark mode, **When** l'utilisateur ouvre la page, **Then** la card patrimoine affiche un fond en gradient (pas un aplat uniforme) distinct des autres cards
2. **Given** un patrimoine négatif ce mois-ci, **When** la variation mensuelle s'affiche, **Then** elle apparaît dans un badge arrondi à fond teinté rouge (pas du texte inline brut)
3. **Given** un patrimoine positif ce mois-ci, **When** la variation mensuelle s'affiche, **Then** elle apparaît dans un badge arrondi à fond teinté vert
4. **Given** le dashboard en light mode, **When** l'utilisateur ouvre la page, **Then** la hero card est également visuellement différenciée (gradient adapté au thème clair)

---

### User Story 2 — Glassmorphism et profondeur des cards (Priority: P2)

Les cards Revenus/Dépenses utilisent un effet de glassmorphism (fond semi-transparent, flou d'arrière-plan, bordure subtile) donnant une impression de profondeur et de modernité. Les cards sont interactives au toucher avec un léger effet de pression.

**Why this priority**: Le glassmorphism est la signature visuelle iOS la plus reconnaissable. C'est ce qui donne l'impression "premium" et moderne à l'interface.

**Independent Test**: Vérifier que les cards Revenus/Dépenses ont un effet de flou visible en arrière-plan et réagissent au touch avec un effet scale.

**Acceptance Scenarios**:

1. **Given** le dashboard en dark mode, **When** l'utilisateur regarde les cards Revenus/Dépenses, **Then** elles affichent un fond semi-transparent avec un effet de flou d'arrière-plan
2. **Given** une card cliquable, **When** l'utilisateur appuie dessus (touch), **Then** la card se réduit légèrement (effet pressé) puis revient à sa taille normale au relâchement
3. **Given** un appareil avec `prefers-reduced-motion: reduce`, **When** les cards sont affichées, **Then** aucune animation de transition n'est appliquée (pas de scale, pas de transition)
4. **Given** un appareil ancien ne supportant pas `backdrop-filter`, **When** le dashboard s'affiche, **Then** les cards ont un fond opaque comme fallback sans erreur visuelle

---

### User Story 3 — Barres de budget enrichies (Priority: P2)

Les barres de progression des budgets sont visuellement améliorées : coins arrondis, hauteur augmentée, gradient de remplissage, et animation d'apparition au chargement.

**Why this priority**: Les barres de budget sont le second élément visuel le plus scruté après le patrimoine. Leur aspect actuel (rectangles plats, fins) ne communique pas efficacement l'urgence budgétaire.

**Independent Test**: Ouvrir le dashboard avec des budgets actifs et vérifier que les barres ont des coins arrondis, un remplissage en gradient, et s'animent à l'apparition.

**Acceptance Scenarios**:

1. **Given** un budget à 30% de consommation, **When** la barre s'affiche, **Then** elle a des coins arrondis (pill shape), une hauteur visible (~10px), et un remplissage en couleur primaire
2. **Given** un budget à 90% de consommation, **When** la barre s'affiche, **Then** le remplissage utilise une couleur d'avertissement (orange/jaune)
3. **Given** un budget dépassé (>100%), **When** la barre s'affiche, **Then** le remplissage utilise une couleur de danger (rouge)
4. **Given** le dashboard vient de charger, **When** les barres apparaissent, **Then** elles s'animent de 0% à leur valeur réelle (transition de largeur)
5. **Given** `prefers-reduced-motion: reduce`, **When** les barres apparaissent, **Then** elles s'affichent directement à leur valeur sans animation

---

### User Story 4 — Transactions avec profondeur visuelle (Priority: P3)

La liste des dernières opérations utilise un style "cards individuelles" (gaps entre items au lieu de séparateurs) et les icônes emoji sont entourées d'un cercle coloré teinté pour donner du volume.

**Why this priority**: La liste de transactions est visible à chaque ouverture du dashboard mais les changements sont esthétiques et n'impactent pas la lisibilité fonctionnelle.

**Independent Test**: Vérifier que chaque transaction est visuellement séparée par un espace (pas un trait) et que les icônes ont un fond arrondi teinté.

**Acceptance Scenarios**:

1. **Given** des transactions récentes, **When** la liste s'affiche, **Then** chaque transaction est visuellement séparée par un espace (gap) et non par un trait horizontal
2. **Given** une transaction avec un emoji catégorie, **When** l'icône s'affiche, **Then** l'emoji est contenu dans un cercle avec un fond teinté semi-transparent
3. **Given** le dashboard en light mode, **When** la liste s'affiche, **Then** le style cards individuelles et cercles colorés s'adaptent au thème clair

---

### User Story 5 — Gradient de fond et ambiance page (Priority: P3)

La page dashboard a un gradient radial subtil en haut, créant une ambiance de profondeur au lieu d'un fond uniforme plat.

**Why this priority**: C'est un détail d'ambiance qui contribue à l'impression globale de qualité mais n'est pas indispensable individuellement.

**Independent Test**: Vérifier visuellement que le haut de la page a une teinte légèrement différente du bas (gradient radial subtil).

**Acceptance Scenarios**:

1. **Given** le dashboard en dark mode, **When** la page s'affiche, **Then** un gradient radial subtil (reflet de la couleur primaire) est visible en haut de la page
2. **Given** le dashboard en light mode, **When** la page s'affiche, **Then** le gradient est adapté au thème clair (plus doux, moins saturé)
3. **Given** un scroll vers le bas, **When** l'utilisateur défile, **Then** le gradient reste fixé en haut et disparaît naturellement

---

### Edge Cases

- Que se passe-t-il si `backdrop-filter` n'est pas supporté par le navigateur ? Fallback vers un fond opaque.
- Que se passe-t-il si l'utilisateur a activé `prefers-reduced-motion` ? Toutes les animations (transitions scale, barres de budget, gradient animé) sont désactivées.
- Que se passe-t-il si le dashboard n'a aucun budget actif ? La section budgets n'apparaît pas (comportement existant inchangé).
- Que se passe-t-il si le patrimoine est exactement à 0 ? Le badge de variation affiche "0 ce mois" en style neutre (ni vert ni rouge).
- Le gradient de fond interfère-t-il avec la bottom nav ? Non, le gradient est en haut de la page uniquement et ne touche pas la zone de navigation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le dashboard DOIT afficher la zone patrimoine avec un fond en gradient visuellement distinct des autres sections
- **FR-002**: Le montant principal du patrimoine DOIT utiliser une typographie amplifiée (plus grande et plus bold que l'actuel)
- **FR-003**: Les variations mensuelles (patrimoine, revenus, dépenses) DOIVENT s'afficher dans des badges/chips arrondis avec fond teinté (vert pour positif, rouge pour négatif) au lieu de texte inline
- **FR-004**: Les cards Revenus/Dépenses DOIVENT utiliser un effet glassmorphism (fond semi-transparent + flou d'arrière-plan) en dark mode uniquement. En light mode, elles utilisent un fond opaque stylé sans backdrop-filter
- **FR-005**: Les cards interactives DOIVENT réagir au touch avec un effet de pression subtil (réduction d'échelle)
- **FR-006**: Les barres de budget DOIVENT avoir des coins arrondis (pill shape), une hauteur augmentée, et un code couleur basé sur le `seuilNotification` configurable du budget (défaut 80%) pour l'avertissement et 100% pour le dépassement
- **FR-007**: Les barres de budget DOIVENT s'animer de 0 à leur valeur réelle au chargement initial
- **FR-008**: La liste des transactions DOIT utiliser des espaces (gaps) entre items au lieu de séparateurs horizontaux
- **FR-009**: Les icônes emoji des transactions DOIVENT être entourées d'un cercle avec fond teinté
- **FR-010**: Le fond de la page dashboard DOIT afficher un gradient radial subtil en haut
- **FR-011**: Toutes les animations DOIVENT être désactivées quand `prefers-reduced-motion: reduce` est actif
- **FR-012**: L'effet glassmorphism DOIT avoir un fallback opaque pour les navigateurs ne supportant pas `backdrop-filter`
- **FR-013**: Tous les changements visuels DOIVENT fonctionner correctement en dark mode ET en light mode
- **FR-014**: Le greeting ("Bonjour [Nom]") DOIT conserver son emplacement et sa lisibilité dans la nouvelle hero card

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur identifie la zone patrimoine comme point focal principal en moins de 1 seconde (test de perception visuelle)
- **SC-002**: Les cards du dashboard présentent au minimum 3 niveaux de hiérarchie visuelle distincts (hero, cards secondaires, liste)
- **SC-003**: Toutes les animations respectent `prefers-reduced-motion` — aucune animation visible quand cette préférence est activée
- **SC-004**: Le dashboard s'affiche correctement sur les 3 navigateurs principaux mobiles (Safari iOS, Chrome Android, Chrome Desktop) sans régression visuelle
- **SC-005**: Le temps de rendu du dashboard ne dépasse pas 200ms de plus qu'avant la refonte (performance du `backdrop-filter`)
- **SC-006**: Aucune fonctionnalité existante n'est altérée — tous les tests existants passent sans modification

## Assumptions

- Le dark mode est le mode principal d'utilisation (confirmé par le screenshot fourni), mais le light mode doit rester fonctionnel
- Le gradient de la hero card utilise les couleurs primaire (Amber) et secondaire (Indigo) du design system existant
- L'effet glassmorphism est supporté par tous les navigateurs cibles modernes (Safari 9+, Chrome 76+), avec fallback pour les plus anciens
- Les cercles colorés des icônes transactions utilisent une teinte neutre (gris teinté) plutôt qu'une couleur par catégorie, pour éviter d'ajouter une logique de mapping couleur/catégorie dans le template
- Les micro-interactions tap s'appliquent uniquement aux cards Revenus/Dépenses et à la hero card, pas à la liste de transactions (qui a déjà sa propre navigation)
- Le scope est limité au dashboard Angular (app/) — le dashboard Flutter n'est pas concerné par cette feature
