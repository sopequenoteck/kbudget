# Research: Dashboard Redesign

## R1: Couleur sémantique pour les abonnements

**Decision**: Utiliser le bleu (info) comme couleur sémantique pour les abonnements — `--color-subscription`.

**Rationale**: Le bleu est déjà disponible dans la palette (`$info: #3b82f6` dans les primitives). Il n'est pas utilisé comme token sémantique métier. Les autres couleurs métier sont prises : vert (income/on me doit), rouge (expense/je dois), amber (primary). Le bleu offre une distinction visuelle claire.

**Alternatives considered**:
- Violet/purple : non présent dans la palette existante, nécessiterait d'ajouter une nouvelle couleur
- Amber (primary) : déjà utilisé pour le solde et les éléments de navigation, confusion visuelle
- Gris : trop neutre, pas de distinction

**Tokens à créer**:
- Light theme : `--color-subscription: #2563eb` (blue-600, bon contraste sur fond clair)
- Dark theme : `--color-subscription: #60a5fa` (blue-400, lisibilité sur fond sombre)

## R2: Structure HTML de la zone KPI

**Decision**: Utiliser une structure CSS Grid en 2 rangées au sein d'une `<section class="kpi-zone">`. Rang 1 = 3 colonnes (cards principales existantes). Rang 2 = 3 colonnes (mini-cards). Séparateur via `border-bottom` ou élément dédié.

**Rationale**: CSS Grid est déjà le pattern du layout. Les cards du rang 1 utilisent `flex` actuellement — on garde flex à l'intérieur des rangées mais on enveloppe le tout dans un conteneur commun pour le groupement visuel.

**Alternatives considered**:
- Tout en flex : fonctionne aussi mais grid donne un meilleur alignement vertical entre les rangées
- Cards unifiées rang 1 + rang 2 de même taille : testé dans mockup v2, visuellement trop chargé

## R3: Mini-cards cliquables — pattern de navigation

**Decision**: Utiliser `routerLink` directement sur un élément `<a>` englobant la mini-card. Pattern identique aux liens "Voir tout" existants.

**Rationale**: Angular Router est déjà importé dans le dashboard. Un `<a routerLink>` est sémantiquement correct (navigation), accessible (focusable, lecteurs d'écran), et cohérent avec le reste de l'app.

**Alternatives considered**:
- `(click)` + `router.navigate()` : moins accessible, nécessite gestion clavier manuelle
- Composant shared `MiniCardLink` : YAGNI — interne au dashboard suffit

## R4: Comportement des données rang 2 vs sélecteur de mois

**Decision**: Le rang 2 (abos, dettes) charge les données une seule fois au montage du composant et se rafraîchit via les `refreshTrigger` des services. Il ne réagit PAS au changement de mois.

**Rationale**: Clarification validée par l'utilisateur. Les abonnements et dettes sont des états courants (actif/non remboursé), pas des snapshots mensuels. Les computed signals `monthlySubTotal`, `totalJeDois`, `totalOnMeDoit` existent déjà et calculent les bonnes valeurs.

**Alternatives considered**:
- Calculer des snapshots mensuels : nécessiterait une API backend dédiée — hors scope

## R5: Affichage des dettes — montant positif + label contextuel

**Decision**: Modifier le template des items de dette pour afficher le montant sans signe négatif et ajouter un sous-texte "Emprunt" ou "Prêt" (déjà disponible via `debt.sens`).

**Rationale**: Le signe négatif est redondant avec la couleur rouge. Un label textuel est plus clair et cohérent avec la page `/debts` qui distingue aussi visuellement les types.

**Alternatives considered**:
- Garder le signe négatif : incohérent avec les KPI du rang 2 qui affichent des montants positifs
- Icône au lieu de texte : trop subtil sur mobile
