# Feature Specification: Flutter — Écran Dettes Liste

**Feature Branch**: `048-flutter-debts-list`
**Created**: 2026-02-23
**Status**: Draft
**Input**: User description: "KKS-107 — Flutter: Écran Dettes liste. Résumé (Emprunts/Prêts/Solde net par devise) + filtre (Tous/En cours/Remboursé) + sections séparées Prêts et Emprunts avec sous-totaux. Tap ouvre formulaire."
**Linear**: [KKS-107](https://linear.app/kksdev/issue/KKS-107/flutter-ecran-dettes-liste)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter la liste des dettes (Priority: P1)

L'utilisateur ouvre l'écran Dettes et voit l'ensemble de ses dettes organisées en deux sections distinctes : "Prêts" (argent prêté à quelqu'un) et "Emprunts" (argent emprunté à quelqu'un). Chaque section affiche un sous-total par devise. Chaque item affiche le nom de la personne, le montant formaté avec la devise, l'icône et la couleur de la catégorie, et la date de la dette. Les dettes remboursées portent un badge "Remboursé" visuellement distinct.

**Why this priority**: C'est la fonctionnalité fondamentale de l'écran — sans liste organisée, rien d'autre n'a de sens.

**Independent Test**: Peut être testé en ouvrant l'écran avec des dettes existantes et en vérifiant l'affichage correct de chaque item et la séparation en sections.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 3 prêts et 2 emprunts, **When** il ouvre l'écran Dettes, **Then** les dettes s'affichent dans deux sections titrées "Prêts" et "Emprunts", triées par date décroissante au sein de chaque section.
2. **Given** une section "Prêts" contient 2 prêts de 50 € et 30 €, **When** l'écran s'affiche, **Then** le sous-total de la section "Prêts" indique "80,00 €".
3. **Given** une dette est remboursée, **When** l'écran s'affiche, **Then** cette dette porte un badge "Remboursé" visuellement distinct (texte en couleur d'erreur du thème) affiché sous la valeur de l'item.
4. **Given** l'utilisateur n'a aucune dette, **When** il ouvre l'écran, **Then** un état vide s'affiche avec une icône, le message "Aucune dette" et le FAB reste accessible pour en créer une.
5. **Given** une section n'a aucune dette (ex: aucun prêt), **When** l'écran s'affiche, **Then** cette section n'est pas affichée.

---

### User Story 2 - Voir le résumé financier des dettes (Priority: P2)

Au-dessus de la liste, une carte récapitulative affiche trois informations par devise : le total des emprunts (ce que l'utilisateur doit), le total des prêts (ce qu'on lui doit), et le solde net (prêts − emprunts). Seules les dettes non remboursées sont comptabilisées dans le résumé. Si l'utilisateur a des dettes dans plusieurs devises, un résumé est affiché par devise.

**Why this priority**: Le résumé donne une vision synthétique de la situation financière en matière de dettes — information clé pour savoir où l'on en est.

**Independent Test**: Peut être testé en créant des dettes de différents types et devises, puis en vérifiant le calcul des totaux affichés.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 2 emprunts non remboursés (100 € et 50 €) et 1 prêt non remboursé (200 €), **When** l'écran s'affiche, **Then** la carte récapitulative montre "Emprunts : 150,00 €", "Prêts : 200,00 €", "Solde net : +50,00 €".
2. **Given** le solde net est positif (prêts > emprunts), **When** l'écran s'affiche, **Then** le solde net est affiché avec un signe "+" et une couleur positive (vert/succès du thème).
3. **Given** le solde net est négatif (emprunts > prêts), **When** l'écran s'affiche, **Then** le solde net est affiché avec un signe "−" et une couleur négative (rouge/erreur du thème).
4. **Given** l'utilisateur a des dettes en EUR et en XOF, **When** l'écran s'affiche, **Then** deux résumés distincts sont affichés, un par devise.
5. **Given** toutes les dettes sont remboursées, **When** l'écran s'affiche, **Then** la carte récapitulative n'est pas affichée.

---

### User Story 3 - Filtrer par statut de remboursement (Priority: P2)

Un filtre segmenté (Tous / En cours / Remboursé) permet de filtrer la liste des dettes affichées. Le filtre par défaut est "Tous". Le résumé financier ne change pas selon le filtre (il reflète toujours les dettes non remboursées uniquement). Le filtrage se fait côté client sur les données déjà chargées. Les sections Prêts/Emprunts et leurs sous-totaux s'adaptent au filtre actif.

**Why this priority**: Le filtre aide à identifier rapidement les dettes en cours à rembourser ou l'historique des dettes remboursées.

**Independent Test**: Peut être testé en sélectionnant chaque option du filtre et en vérifiant que la liste et les sous-totaux correspondent au statut sélectionné.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 3 dettes en cours et 2 remboursées, **When** il sélectionne "En cours", **Then** seules les 3 dettes non remboursées sont affichées et les sous-totaux de section reflètent uniquement ces dettes.
2. **Given** l'utilisateur a 3 dettes en cours et 2 remboursées, **When** il sélectionne "Remboursé", **Then** seules les 2 dettes remboursées sont affichées.
3. **Given** le filtre est sur "En cours", **When** l'utilisateur sélectionne "Tous", **Then** toutes les 5 dettes s'affichent à nouveau.
4. **Given** le filtre est sur "Remboursé" et aucune dette remboursée n'existe, **When** l'utilisateur voit la liste, **Then** un état vide adapté au filtre s'affiche (ex: "Aucune dette remboursée").

---

### User Story 4 - Ouvrir le formulaire d'édition (Priority: P3)

Lorsque l'utilisateur tape sur une dette dans la liste, le formulaire d'édition s'ouvre en modal avec les données pré-remplies. Le toggle Emprunt/Prêt dans le header de la modal reflète le type de la dette.

**Why this priority**: L'édition existe déjà via le DebtForm (branche 047) — il s'agit ici uniquement de connecter le tap au formulaire existant.

**Independent Test**: Peut être testé en tapant sur un item et en vérifiant que la modal s'ouvre avec les bonnes données pré-remplies.

**Acceptance Scenarios**:

1. **Given** un emprunt de 100 € à "Alice" existe, **When** l'utilisateur tape dessus, **Then** le formulaire s'ouvre en modal avec personne="Alice", montant=100, type=Emprunt et les autres champs pré-remplis.
2. **Given** un prêt remboursé existe, **When** l'utilisateur tape dessus, **Then** le formulaire d'édition s'ouvre avec le switch "Remboursé" activé et le toggle positionné sur "Prêt".

---

### Edge Cases

- Que se passe-t-il si le chargement échoue ? → État erreur avec bouton "Réessayer" et pull-to-refresh disponible.
- Que se passe-t-il pendant le chargement ? → Affichage de skeletons (shimmer) à la place des items et de la carte résumé.
- Que se passe-t-il si une dette n'a pas de catégorie ? → Icône et couleur par défaut.
- Que se passe-t-il au pull-to-refresh ? → Les données sont rechargées et le filtre actif est conservé.
- Que se passe-t-il si le solde net est exactement zéro ? → Le solde net affiche "0,00 €" sans couleur positive ni négative (couleur neutre).
- Que se passe-t-il si toutes les dettes d'une section sont filtrées ? → La section entière disparaît (pas de section vide affichée).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: L'écran DOIT afficher la liste de toutes les dettes de l'utilisateur organisées en deux sections distinctes : "Prêts" et "Emprunts".
- **FR-002**: Chaque section DOIT afficher un sous-total par devise, calculé sur les dettes visibles (tenant compte du filtre actif).
- **FR-003**: Une section sans dette visible NE DOIT PAS être affichée.
- **FR-004**: Au sein de chaque section, les dettes DOIVENT être triées par date décroissante (la plus récente en premier).
- **FR-005**: Chaque item DOIT afficher le nom de la personne, le montant formaté avec la devise, l'icône et couleur de la catégorie, et la date.
- **FR-006**: Les dettes remboursées DOIVENT porter un badge "Remboursé" visuellement distinct (texte en couleur d'erreur du thème) affiché via le sous-titre droit de l'item.
- **FR-007**: Une carte récapitulative DOIT afficher pour chaque devise : le total des emprunts non remboursés, le total des prêts non remboursés, et le solde net (prêts − emprunts).
- **FR-008**: Le solde net DOIT utiliser une couleur positive (succès du thème) si positif, négative (erreur du thème) si négatif, et neutre si zéro.
- **FR-009**: La carte récapitulative NE DOIT PAS s'afficher si aucune dette non remboursée n'existe.
- **FR-010**: La carte récapitulative DOIT toujours refléter les dettes non remboursées, indépendamment du filtre actif.
- **FR-011**: Un filtre segmenté à 3 options (Tous / En cours / Remboursé) DOIT permettre de filtrer la liste. Le filtre par défaut est "Tous".
- **FR-012**: Le filtrage DOIT être effectué côté client sur les données déjà chargées (pas de nouvel appel réseau).
- **FR-013**: Le tap sur un item DOIT ouvrir le formulaire d'édition en modal avec les données pré-remplies.
- **FR-014**: L'écran DOIT gérer les états de chargement (skeleton shimmer), d'erreur (bouton réessayer) et vide (message adapté au filtre actif).
- **FR-015**: Le pull-to-refresh DOIT recharger les données tout en conservant le filtre actif.
- **FR-016**: Le FAB "Nouvelle dette" DOIT rester accessible quel que soit l'état de l'écran ou le filtre sélectionné.

### Key Entities

- **Debt**: Représente une dette (emprunt ou prêt). Attributs clés : personne, montant, type (emprunt/prêt via DebtType), date, état de remboursement (rembourse), devise (currency), catégorie optionnelle.
- **Category**: Catégorie optionnelle associée à une dette, fournissant icône et couleur pour l'affichage dans la liste.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut visualiser la liste complète de ses dettes en moins de 2 secondes après ouverture de l'écran.
- **SC-002**: Les totaux affichés (emprunts, prêts, solde net, sous-totaux de section) sont toujours exacts par rapport aux dettes concernées, regroupés par devise.
- **SC-003**: Le changement de filtre met à jour la liste, les sections et les sous-totaux de manière instantanée (sans temps de chargement perceptible).
- **SC-004**: L'utilisateur peut identifier visuellement le type de dette (prêt vs emprunt) et son statut (remboursé ou non) sans ouvrir le détail.
- **SC-005**: L'utilisateur peut passer de la liste à l'édition d'une dette en un seul tap.
- **SC-006**: L'utilisateur peut distinguer en un coup d'œil sa situation financière nette grâce au résumé coloré (positif/négatif/neutre).

## Assumptions

- Le formulaire d'édition des dettes (DebtForm) est déjà implémenté et fonctionnel (branche 047).
- Les widgets communs SegmentedFilter et ListItem sont disponibles et fonctionnels.
- Le DebtNotifier avec CRUD de base existe déjà (ListState<Debt> générique).
- Le filtrage se fait côté client car le repository Flutter charge déjà toutes les dettes sans paramètre de filtre.
- La devise par défaut est EUR si non spécifiée sur la dette.
- Le tri au sein de chaque section est par date décroissante, cohérent avec le tri par défaut du DebtNotifier.

## Dependencies

- **KKS-99**: Widget filtres segmentés (SegmentedFilter) — requis pour le filtre de statut.
- **KKS-93**: Widget ListItem réutilisable — requis pour l'affichage des items.
- **KKS-115**: Notifiers Riverpod CRUD — requis pour le chargement et la gestion d'état des dettes.
