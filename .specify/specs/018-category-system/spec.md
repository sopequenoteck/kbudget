# Feature Specification: Système de Catégories

**Feature Branch**: `018-category-system`
**Created**: 2026-02-12
**Status**: Draft
**Input**: User description: "Système de catégories complet pour organiser transactions, abonnements et dettes. CRUD backend, composant autocomplete frontend avec création à la volée (modal : nom + emoji, couleur aléatoire), catégories système (Abonnement, Dette)."

## Clarifications

### Session 2026-02-12

- Q: Les catégories système sont-elles globales (sans propriétaire) ou créées par utilisateur ? → A: Par utilisateur — chaque nouvel utilisateur reçoit ses propres copies des catégories système à l'inscription.
- Q: Où l'utilisateur accède-t-il à la gestion des catégories (lister, modifier, supprimer) ? → A: Dans une section dédiée de l'écran Paramètres/Réglages.
- Q: Quelle stratégie de migration pour les données existantes (champ texte catégorie + utilisateurs sans catégories système) ? → A: Migration Flyway simple — créer les catégories système pour les utilisateurs existants, mettre le champ catégorie à null sur les transactions existantes (perte du texte).
- Q: L'utilisateur peut-il modifier le nom et/ou l'emoji des catégories système ? → A: Non — les catégories système sont entièrement verrouillées (nom et emoji non modifiables, suppression interdite).
- Q: Quelle longueur maximale pour le nom d'une catégorie ? → A: 30 caractères.
- Q: Quel format et quelle taille pour la palette de couleurs aléatoires ? → A: 12 couleurs hex prédéfinies (constante backend + frontend), stockage hex en base (#xxxxxx).
- Q: Les catégories système sont-elles visibles dans le picker des transactions ? → A: Oui — toutes les catégories (système + personnalisées) sont visibles dans le picker, sans distinction, quel que soit le type d'entité.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sélectionner une catégorie existante lors de la saisie (Priority: P1)

L'utilisateur crée une transaction et choisit une catégorie parmi celles qu'il a déjà créées. En tapant dans le champ catégorie, les catégories existantes sont filtrées en temps réel. Il sélectionne celle qui correspond et valide le formulaire.

**Why this priority**: Sans la sélection de catégorie, le système de catégories n'a aucune valeur d'usage. C'est le flux principal utilisé à chaque saisie quotidienne.

**Independent Test**: Peut être testé en créant une transaction avec une catégorie existante et en vérifiant qu'elle apparaît correctement dans la liste des transactions avec son icône.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 5 catégories existantes (Courses, Loyer, Transport, Loisirs, Santé), **When** il tape "Lo" dans le champ catégorie, **Then** seuls "Loyer" et "Loisirs" apparaissent dans la liste de suggestions.
2. **Given** la liste de suggestions est visible, **When** l'utilisateur clique sur "Courses", **Then** le champ affiche "🛒 Courses" et la catégorie est associée à la transaction.
3. **Given** l'utilisateur a sélectionné une catégorie, **When** il soumet le formulaire, **Then** la transaction est créée avec cette catégorie et apparaît dans la liste avec l'emoji correspondant.

---

### User Story 2 - Créer une nouvelle catégorie à la volée (Priority: P1)

L'utilisateur saisit un nom de catégorie qui n'existe pas encore. Le système lui propose de la créer. Une modal s'ouvre avec le nom pré-rempli, il choisit un emoji et valide. La catégorie est créée et automatiquement sélectionnée dans le formulaire.

**Why this priority**: La création à la volée est essentielle pour ne pas interrompre le flux de saisie. Sans cette fonctionnalité, l'utilisateur devrait quitter le formulaire pour créer une catégorie, ce qui casse l'expérience mobile.

**Independent Test**: Peut être testé en saisissant un nom de catégorie inexistant, en créant la catégorie via la modal, et en vérifiant qu'elle est sélectionnée et disponible pour les futures saisies.

**Acceptance Scenarios**:

1. **Given** aucune catégorie "Voyages" n'existe, **When** l'utilisateur tape "Voyages" dans le champ catégorie, **Then** un bouton "Créer Voyages" apparaît en bas de la liste (vide ou filtrée).
2. **Given** l'utilisateur clique sur "Créer Voyages", **When** la modal de création s'ouvre, **Then** le nom "Voyages" est pré-rempli et une grille d'emojis fréquents est affichée.
3. **Given** l'utilisateur sélectionne l'emoji ✈️ et clique "Créer", **When** la catégorie est sauvegardée, **Then** la modal se ferme, la catégorie "✈️ Voyages" est automatiquement sélectionnée dans le formulaire, et une couleur aléatoire lui a été attribuée.
4. **Given** la catégorie "Voyages" vient d'être créée, **When** l'utilisateur ouvre un autre formulaire, **Then** "Voyages" apparaît dans les suggestions.

---

### User Story 3 - Voir les catégories dans les listes d'items (Priority: P2)

L'utilisateur consulte ses listes de transactions, abonnements ou dettes. Chaque item affiche l'emoji de sa catégorie, permettant une identification visuelle rapide du type de dépense.

**Why this priority**: L'affichage des catégories dans les listes donne une valeur immédiate au système de catégorisation et améliore la lisibilité quotidienne.

**Independent Test**: Peut être testé en vérifiant que les listes affichent l'emoji de catégorie pour chaque item catégorisé, et un état par défaut pour les items sans catégorie.

**Acceptance Scenarios**:

1. **Given** une transaction "Carrefour" catégorisée "🛒 Courses", **When** l'utilisateur consulte la liste des transactions, **Then** l'emoji 🛒 est affiché à côté de "Carrefour".
2. **Given** une transaction sans catégorie, **When** l'utilisateur consulte la liste des transactions, **Then** un emoji par défaut (📋) est affiché à la place.
3. **Given** un abonnement sans catégorie personnalisée, **When** l'utilisateur consulte la liste des abonnements, **Then** l'emoji de la catégorie système "Abonnement" (🔄) est affiché par défaut.
4. **Given** une dette sans catégorie personnalisée, **When** l'utilisateur consulte la liste des dettes, **Then** l'emoji de la catégorie système "Dette" (💰) est affiché par défaut.

---

### User Story 4 - Catégories système automatiques pour abonnements et dettes (Priority: P2)

Les abonnements et les dettes ont des catégories système attribuées par défaut ("Abonnement" et "Dette"). L'utilisateur peut les remplacer par une catégorie personnalisée s'il le souhaite, mais les catégories système ne peuvent pas être supprimées.

**Why this priority**: Les catégories système assurent une cohérence de base sans intervention de l'utilisateur et préparent le terrain pour la future transformation abonnement → transaction.

**Independent Test**: Peut être testé en créant un abonnement sans choisir de catégorie et en vérifiant que la catégorie système "Abonnement" est attribuée automatiquement.

**Acceptance Scenarios**:

1. **Given** l'utilisateur crée un abonnement, **When** il ne choisit pas de catégorie, **Then** la catégorie système "🔄 Abonnement" est attribuée automatiquement.
2. **Given** l'utilisateur crée une dette, **When** il ne choisit pas de catégorie, **Then** la catégorie système "💰 Dette" est attribuée automatiquement.
3. **Given** l'utilisateur consulte la liste des catégories dans le picker, **When** il cherche les catégories système, **Then** elles sont visibles mais non supprimables (pas d'option de suppression).
4. **Given** l'utilisateur crée un abonnement, **When** il souhaite le catégoriser autrement, **Then** il peut sélectionner une catégorie personnalisée à la place de la catégorie système.

---

### User Story 5 - Gérer ses catégories (consulter, modifier, supprimer) (Priority: P3)

L'utilisateur souhaite gérer ses catégories : voir la liste complète, modifier le nom ou l'emoji d'une catégorie, ou supprimer une catégorie qu'il n'utilise plus. Cette gestion est accessible depuis une section dédiée dans l'écran Paramètres/Réglages.

**Why this priority**: La gestion des catégories est un besoin secondaire. L'utilisateur crée et utilise les catégories au quotidien (P1/P2), mais la gestion (renommage, suppression) est plus rare.

**Independent Test**: Peut être testé en modifiant le nom/emoji d'une catégorie existante et en vérifiant que le changement se reflète dans les items associés.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 10 catégories, **When** il accède à la section Catégories dans les Paramètres, **Then** toutes ses catégories sont listées avec emoji, nom et couleur.
2. **Given** l'utilisateur modifie la catégorie "Courses" en "Alimentation" avec un nouvel emoji et une nouvelle couleur, **When** il valide, **Then** toutes les transactions associées affichent le nouveau nom, emoji et couleur.
3. **Given** l'utilisateur supprime la catégorie "Loisirs", **When** des items (transactions, abonnements ou dettes) sont liés à cette catégorie, **Then** le système l'avertit et les items concernés perdent leur catégorie (champ null).
4. **Given** une catégorie système "Abonnement", **When** l'utilisateur tente de la supprimer, **Then** l'action est refusée avec un message explicatif.
5. **Given** une catégorie système "Abonnement", **When** l'utilisateur consulte ses détails, **Then** les champs nom et emoji sont en lecture seule (non modifiables).

---

### Edge Cases

- Que se passe-t-il quand l'utilisateur tape un nom de catégorie identique à une catégorie existante dans la modal de création ? Le système doit empêcher la création de doublons et proposer de sélectionner l'existante.
- Que se passe-t-il quand l'utilisateur tente de créer une catégorie avec le nom "Abonnement" ou "Dette" (noms des catégories système) ? La contrainte d'unicité case-insensitive bloque la création. Le même message d'erreur "nom déjà utilisé" s'affiche.
- Comment le système gère-t-il une catégorie supprimée alors que des items y sont encore liés ? Les items perdent leur catégorie (champ null) et affichent un état visuel par défaut.
- Que se passe-t-il quand l'utilisateur modifie une transaction en mode édition et change sa catégorie ? La nouvelle catégorie remplace l'ancienne sans impact sur les autres transactions.
- Comment le système se comporte-t-il lors de la première utilisation (aucune catégorie créée) ? Seules les catégories système sont disponibles. Le picker affiche un état vide avec le bouton "Créer" mis en avant.
- Que se passe-t-il quand la recherche dans l'autocomplete ne retourne aucun résultat et que l'utilisateur ne crée pas de catégorie ? Le champ catégorie reste vide (optionnel pour les transactions).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre à l'utilisateur de créer une catégorie avec un nom, un emoji et une couleur générée aléatoirement.
- **FR-002**: Le système DOIT permettre à l'utilisateur de rechercher ses catégories par nom via un champ de saisie avec filtrage en temps réel.
- **FR-003**: Le système DOIT permettre la sélection d'une catégorie existante depuis les résultats filtrés.
- **FR-004**: Le système DOIT permettre la création d'une nouvelle catégorie directement depuis le champ de recherche lorsqu'aucun résultat ne correspond, via une modal dédiée.
- **FR-005**: Le système DOIT pré-remplir le nom dans la modal de création avec le texte saisi dans le champ de recherche.
- **FR-006**: Le système DOIT proposer une grille d'emojis fréquents pour le choix de l'icône lors de la création d'une catégorie.
- **FR-007**: Le système DOIT attribuer automatiquement une couleur aléatoire à chaque nouvelle catégorie créée (parmi une palette de 12 couleurs hex prédéfinies, stockées en base au format `#xxxxxx`).
- **FR-008**: Le système DOIT fournir des catégories système ("Abonnement", "Dette") créées automatiquement pour chaque utilisateur à l'inscription, non supprimables et non modifiables (nom et emoji verrouillés).
- **FR-009**: Le système DOIT attribuer la catégorie système "Abonnement" par défaut aux abonnements créés sans catégorie explicite.
- **FR-010**: Le système DOIT attribuer la catégorie système "Dette" par défaut aux dettes créées sans catégorie explicite.
- **FR-011**: Le système DOIT permettre à l'utilisateur de remplacer une catégorie système par une catégorie personnalisée sur un abonnement ou une dette.
- **FR-012**: Le système DOIT afficher l'emoji de la catégorie dans les listes de transactions, abonnements et dettes.
- **FR-013**: Le système DOIT empêcher la création de catégories avec un nom identique (insensible à la casse) pour un même utilisateur.
- **FR-014**: Le système DOIT permettre à l'utilisateur de modifier le nom, l'emoji et la couleur d'une catégorie personnalisée existante (choix parmi la palette prédéfinie).
- **FR-015**: Le système DOIT permettre à l'utilisateur de supprimer une catégorie personnalisée, avec avertissement si des items y sont liés.
- **FR-016**: Le système DOIT isoler les catégories par utilisateur — chaque utilisateur ne voit que ses propres catégories (système + personnalisées, sans distinction, dans tous les pickers).
- **FR-017**: La catégorie DOIT être optionnelle sur les transactions (l'utilisateur peut saisir une transaction sans catégorie).

### Key Entities

- **Category**: Représente une catégorie de dépense/recette. Attributs clés : nom (unique par utilisateur, max 30 caractères), icône (emoji), couleur, indicateur système (oui/non). Appartient à un utilisateur (y compris les catégories système, qui sont des copies par utilisateur). Peut être liée à plusieurs transactions, abonnements et dettes.
- **Transaction** (existant, modifié) : Reçoit une association optionnelle vers une catégorie, remplaçant le champ texte actuel.
- **Subscription** (existant, modifié) : Reçoit une association optionnelle vers une catégorie, avec catégorie système "Abonnement" par défaut.
- **Debt** (existant, modifié) : Reçoit une association optionnelle vers une catégorie, avec catégorie système "Dette" par défaut.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut créer une catégorie et l'associer à une transaction en moins de 10 secondes depuis le formulaire de saisie (création à la volée incluse).
- **SC-002**: La recherche de catégories dans l'autocomplete affiche les résultats filtrés instantanément (filtrage côté client, pas de requête réseau par frappe).
- **SC-003**: 100% des abonnements et dettes créés sans catégorie explicite reçoivent automatiquement leur catégorie système respective.
- **SC-004**: Les listes de transactions, abonnements et dettes affichent systématiquement l'icône de catégorie pour chaque item catégorisé.
- **SC-005**: Les catégories système ne peuvent en aucun cas être supprimées par l'utilisateur.
- **SC-006**: Le flux de saisie d'une transaction avec sélection de catégorie existante ne nécessite pas plus de 2 interactions supplémentaires (taper + sélectionner).

## Assumptions

- L'application est mono-utilisateur en pratique (self-hosted), mais le système de catégories respecte l'isolation par utilisateur pour la cohérence architecturale.
- La grille d'emojis fréquents contient un ensemble prédéfini d'emojis pertinents pour les catégories de budget (alimentation, transport, logement, loisirs, santé, etc.) — pas un emoji picker complet.
- La couleur aléatoire est choisie parmi une palette de 12 couleurs hex prédéfinies (constante partagée backend + frontend), stockée en base au format `#xxxxxx`.
- Lors de la suppression d'une catégorie liée à des items, les items perdent leur catégorie (champ null) plutôt que d'être réattribués à une catégorie par défaut.
- Le champ catégorie est optionnel sur les transactions mais la catégorie système est obligatoirement attribuée aux abonnements et dettes si aucune catégorie personnalisée n'est choisie.
- La migration Flyway crée les catégories système pour les utilisateurs existants et met le champ catégorie des transactions existantes à null (pas de mapping best-effort depuis l'ancien champ texte).
