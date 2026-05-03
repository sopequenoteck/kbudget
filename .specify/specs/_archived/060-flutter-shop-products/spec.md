# Feature Specification: Écran Boutique — Liste produits + stock (Flutter)

**Feature Branch**: `060-flutter-shop-products`
**Created**: 2026-03-01
**Status**: Draft
**Input**: KKS-123 — Flutter: Ecran Boutique — Liste produits + stock
**Linear**: [KKS-123](https://linear.app/kksdev/issue/KKS-123/flutter-ecran-boutique-liste-produits-stock)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter la liste des produits (Priority: P1)

L'utilisateur ouvre l'écran Boutique depuis la navigation principale. Il voit la liste de ses produits actifs. Chaque produit affiche son icône (emoji, ou icône par défaut si absente), son nom, son prix de vente, le stock restant et le nombre total de ventes. Les produits sont triés par nom alphabétique.

**Why this priority**: C'est le cas d'usage principal — consulter l'inventaire est la fonctionnalité de base de la boutique.

**Independent Test**: Peut être testé en ouvrant l'écran Boutique et en vérifiant que les produits s'affichent avec leurs informations (nom, prix, stock, ventes).

**Acceptance Scenarios**:

1. **Given** l'utilisateur a des produits actifs, **When** il ouvre l'écran Boutique, **Then** il voit la liste des produits triés par nom avec icône, nom, prix de vente, stock restant et nombre de ventes.
2. **Given** les produits sont en cours de chargement, **When** l'écran s'affiche, **Then** des squelettes (shimmer) apparaissent à la place de la liste.
3. **Given** l'utilisateur a des produits avec des stocks variés, **When** il consulte la liste, **Then** les produits en rupture de stock (stock = 0) sont visuellement distingués : opacité réduite (0.5) sur l'item entier ET label "Rupture" affiché à la place du compteur de ventes.

---

### User Story 2 - Créer un nouveau produit (Priority: P1)

L'utilisateur accède à la création de produit via le CTA de l'état vide ("Créer un produit") ou, à terme, via un bouton dédié dans l'AppBar. Après création, le nouveau produit apparaît immédiatement dans la liste. Le FAB global (+) reste dédié aux entrées budgétaires.

**Why this priority**: La création de produits est indispensable pour alimenter la boutique — sans produits, l'écran est vide.

**Independent Test**: Peut être testé en vérifiant que le CTA "Créer un produit" de l'état vide déclenche la navigation vers le formulaire (no-op tant que le formulaire n'est pas implémenté).

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran Boutique sans produits (état vide), **When** il appuie sur le CTA "Créer un produit", **Then** la navigation vers le formulaire de création est déclenchée (no-op si formulaire non implémenté).
2. **Given** l'utilisateur crée un produit dans le formulaire et revient à la liste, **When** la liste s'affiche, **Then** le nouveau produit apparaît immédiatement sans rechargement visible.

---

### User Story 3 - Consulter le détail d'un produit (Priority: P2)

L'utilisateur tape sur un produit dans la liste pour naviguer vers l'écran de détail du produit (KKS-125). Le détail affiche toutes les informations du produit et les actions possibles (vendre, réapprovisionner, modifier, etc.).

**Why this priority**: Le détail est le complément naturel de la consultation de la liste, mais peut être développé séparément.

**Independent Test**: Peut être testé en tapant sur un item de la liste et en vérifiant que la navigation mène à l'écran de détail.

**Acceptance Scenarios**:

1. **Given** l'utilisateur voit un produit dans la liste, **When** il tape dessus, **Then** l'écran de détail du produit s'ouvre avec les informations complètes.
2. **Given** l'écran de détail n'est pas encore implémenté, **When** l'utilisateur tape sur un produit, **Then** le tap est un no-op (la navigation est préparée mais inactive).

---

### User Story 4 - Rafraîchir la liste (Priority: P3)

L'utilisateur peut tirer vers le bas (pull-to-refresh) pour recharger les produits depuis le serveur.

**Why this priority**: Le rafraîchissement est un pattern standard mobile attendu mais peu critique.

**Independent Test**: Peut être testé en tirant vers le bas et en vérifiant que les données sont rechargées.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la liste, **When** il tire vers le bas, **Then** un indicateur de rafraîchissement apparaît et les données sont rechargées.
2. **Given** une erreur réseau survient au rafraîchissement, **When** le chargement échoue, **Then** un message d'erreur s'affiche sans perdre les données déjà affichées.

---

### Edge Cases

- Que se passe-t-il quand l'utilisateur n'a aucun produit (nouvel utilisateur) ? Un état vide accueillant s'affiche avec un CTA invitant à créer un premier produit.
- Que se passe-t-il en cas d'erreur réseau au chargement initial ? Un état d'erreur s'affiche avec un bouton de retry.
- Que se passe-t-il avec des noms de produit très longs ? Le texte est tronqué avec ellipsis.
- Que se passe-t-il avec des prix très élevés (> 999 999) ? Le formatage reste lisible avec séparateurs de milliers.
- Que se passe-t-il quand un produit a un stock de 0 ? Il est affiché avec opacité réduite (0.5) ET le label "Rupture" à la place du compteur de ventes.
- Que se passe-t-il quand la feature Boutique est désactivée ? L'onglet Boutique n'apparaît pas dans la navigation (géré par le système de feature toggles existant).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher la liste des produits actifs de l'utilisateur, triés par nom alphabétique.
- **FR-002**: Chaque item de la liste DOIT afficher : l'icône du produit (emoji, ou icône par défaut si absente), le nom du produit, le prix de vente formaté, le stock restant et le nombre total de ventes.
- **FR-003**: Les produits en rupture de stock (stock = 0) DOIVENT être visuellement distingués : opacité réduite (0.5) sur l'item entier ET label "Rupture" affiché à la place du compteur de ventes.
- **FR-004**: L'utilisateur DOIT pouvoir taper sur un produit pour naviguer vers l'écran de détail (KKS-125). Si l'écran de détail n'est pas encore implémenté, le tap est un no-op.
- **FR-005**: L'écran Boutique DOIT fournir un accès à la création de produit via le CTA de l'état vide ("Créer un produit"). Un accès depuis l'AppBar ou un bouton dédié sera ajouté lors de l'implémentation du formulaire (feature future). Le FAB global (+) reste dédié aux entrées budgétaires (transactions, abonnements, dettes). Si le formulaire n'est pas encore implémenté, les actions de création sont un no-op.
- **FR-006**: Le système DOIT afficher un état de chargement (squelettes shimmer) pendant le chargement initial.
- **FR-007**: Le système DOIT afficher un état vide avec un message et un bouton CTA ("Créer un produit") lorsque l'utilisateur n'a aucun produit.
- **FR-008**: Le système DOIT afficher un état d'erreur avec possibilité de réessayer en cas d'échec de chargement.
- **FR-009**: L'utilisateur DOIT pouvoir rafraîchir les données par pull-to-refresh.
- **FR-010**: Les montants (prix de vente) DOIVENT être formatés avec séparateurs de milliers et le symbole de devise de l'utilisateur.
- **FR-011**: Le système DOIT charger uniquement les produits actifs depuis la source de données (l'endpoint backend filtre déjà les produits inactifs).
- **FR-012**: Le stock et le nombre de ventes DOIVENT être affichés de manière concise via des labels compacts (ex: "Stock: 12", "Ventes: 5").

### Key Entities

- **Product**: Article en vente avec nom, description optionnelle, icône (emoji) optionnelle, image optionnelle, prix d'achat, prix de vente, stock restant, nombre total de ventes, statut actif/inactif, dates de création et mise à jour.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter la liste de ses produits en moins de 2 secondes après ouverture de l'écran.
- **SC-002**: L'écran gère correctement les trois états : chargement (shimmer), vide (message + CTA), erreur (retry).
- **SC-003**: Chaque produit affiche toutes les informations clés (nom, prix, stock, ventes) en un coup d'œil sans ouvrir le détail.
- **SC-004**: L'utilisateur identifie instantanément les produits en rupture de stock grâce à la distinction visuelle.
- **SC-005**: L'utilisateur peut naviguer vers la création ou le détail d'un produit en un seul tap.

## Assumptions

- Le backend Product CRUD est déjà implémenté et opérationnel (endpoints `/api/products`).
- La feature Boutique est gérée par le système de feature toggles existant (enum `Feature.shop`).
- Le widget `ListItem` existant dans `common_widgets/` est réutilisé pour chaque produit de la liste.
- Le modèle Freezed `Product` sera créé dans `domain/models/` avec les champs correspondant au `ProductResponse` du backend.
- Le `ProductRepository` (interface + implémentation remote) sera créé pour cette feature.
- Le `ProductListNotifier` suivra le pattern CRUD Notifier existant avec `ListState<Product>`.
- L'écran de détail produit (KKS-125) et le formulaire sont développés séparément — la navigation est préparée mais inactive si non implémenté.
- Seul le mode serveur (API REST via Dio) est supporté pour cette feature — pas de Drift/SQLite local.
- La devise est celle configurée dans les préférences utilisateur (pattern existant via `amount_formatter`).
- La création de produit est accessible via le CTA de l'état vide et (futur) un bouton dans l'AppBar. Le FAB global reste dédié aux entrées budgétaires.
