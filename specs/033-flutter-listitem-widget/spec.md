# Feature Specification: Widget ListItem réutilisable (Flutter)

**Feature Branch**: `033-flutter-listitem-widget`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "Composant partagé ListItem (icône cercle catégorie + titre + sous-titre + montant coloré + date relative). Utilisé sur dashboard, transactions, abonnements, dettes. Ref: app-list-item Angular."
**Linear**: KKS-93

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Affichage d'une transaction dans une liste (Priority: P1)

En tant qu'utilisateur, je vois chaque transaction dans une liste avec une icône de catégorie dans un cercle coloré, le libellé de la transaction, le nom de la catégorie, le montant formaté avec signe et couleur sémantique, et la date relative.

**Why this priority**: C'est le cas d'usage principal et le plus fréquent. Les transactions représentent l'activité quotidienne de l'utilisateur et sont affichées sur le dashboard et l'écran transactions.

**Independent Test**: Peut être testé en instanciant le widget avec des données de transaction et en vérifiant le rendu visuel de chaque zone (icône, titre, sous-titre, montant, date).

**Acceptance Scenarios**:

1. **Given** un ListItem avec icon="🛒", title="Courses Lidl", subtitle="Alimentation", value="-45,90 €", rightSubtitle="Hier", **When** le widget est affiché, **Then** les 5 zones sont visibles et correctement positionnées (icône à gauche, contenu au centre, montant et date à droite)
2. **Given** un ListItem avec un montant de type dépense, **When** le widget est affiché, **Then** le montant apparaît en rouge avec le préfixe "-"
3. **Given** un ListItem avec un montant de type recette, **When** le widget est affiché, **Then** le montant apparaît en vert avec le préfixe "+"
4. **Given** un ListItem avec `onPressed` fourni, **When** l'utilisateur appuie dessus, **Then** un widget interactif (`InkWell`) est présent dans l'arbre et le callback est déclenché

---

### User Story 2 - Affichage avec données partielles (Priority: P2)

En tant qu'utilisateur, je vois un ListItem cohérent même lorsque certaines informations sont absentes (pas de catégorie, pas de sous-titre droit).

**Why this priority**: Les données réelles sont souvent incomplètes. Le widget doit rester élégant sans sous-titre ni date relative.

**Independent Test**: Peut être testé en instanciant le widget avec uniquement les champs obligatoires (icon, title, value) et en vérifiant que les zones optionnelles ne laissent pas de vide visuel.

**Acceptance Scenarios**:

1. **Given** un ListItem sans subtitle, **When** le widget est affiché, **Then** la zone sous-titre est absente et le titre occupe toute la hauteur du contenu
2. **Given** un ListItem sans rightSubtitle, **When** le widget est affiché, **Then** seul le montant est affiché dans la zone droite

---

### User Story 3 - Adaptabilité aux contextes métier (Priority: P2)

En tant que développeur, je réutilise le même widget ListItem pour les 4 écrans métier (dashboard, transactions, abonnements, dettes) en ne changeant que les données passées en paramètre.

**Why this priority**: La réutilisabilité est le but central de ce composant. Il doit être assez flexible pour couvrir les 4 contextes sans modification.

**Independent Test**: Peut être testé en instanciant le widget avec des données de chaque type métier (transaction, abonnement, dette) et en vérifiant un rendu correct dans chaque cas.

**Acceptance Scenarios**:

1. **Given** un abonnement Netflix avec icône 📺, nom "Netflix", montant "12,99 €", fréquence "Mensuel", **When** affiché dans un ListItem, **Then** le widget rend correctement toutes les informations
2. **Given** une dette envers "Jean Dupont" de 150 €, type prêt, **When** affiché dans un ListItem, **Then** le montant est en vert et le sous-titre indique le type de dette

---

### User Story 4 - Accessibilité et interaction tactile (Priority: P3)

En tant qu'utilisateur mobile, je peux appuyer sur un ListItem et percevoir un feedback visuel (effet ripple/splash), et le composant est accessible aux lecteurs d'écran.

**Why this priority**: L'application est mobile-first. Le feedback tactile et l'accessibilité sont importants mais secondaires par rapport au rendu visuel.

**Independent Test**: Peut être testé en appuyant sur le widget et en vérifiant le déclenchement du callback et la présence d'un feedback visuel.

**Acceptance Scenarios**:

1. **Given** un ListItem affiché, **When** l'utilisateur appuie dessus, **Then** un effet de feedback visuel apparaît et le callback onPressed est déclenché
2. **Given** un lecteur d'écran actif, **When** le ListItem est focalisé, **Then** le contenu sémantique (titre, montant) est annoncé correctement

---

### Edge Cases

- Que se passe-t-il quand le titre est très long (> 30 caractères) ? Le texte est tronqué avec ellipsis.
- Que se passe-t-il quand le montant est 0 ? Il s'affiche sans signe ni couleur sémantique.
- Que se passe-t-il quand l'icône est un emoji multi-byte (ex: drapeau) ? L'icône doit rester centrée dans le cercle.
- Que se passe-t-il en mode sombre ? Les couleurs sémantiques (income/expense) utilisent les variantes dark du thème.
- Que se passe-t-il quand subtitle et rightSubtitle sont tous les deux absents ? Le widget affiche uniquement l'icône, le titre et le montant sur une seule ligne.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le widget DOIT afficher une icône dans un cercle coloré à gauche. La couleur de fond du cercle est paramétrable via `iconBackgroundColor` (défaut : `AppColors.amber100`, statique light/dark — les écrans appelants fournissent la couleur adaptée au thème si nécessaire)
- **FR-002**: Le widget DOIT afficher un titre principal (texte tronqué avec ellipsis si trop long)
- **FR-003**: Le widget DOIT afficher une valeur formatée alignée à droite avec un poids typographique semibold
- **FR-004**: Le widget DOIT permettre une couleur dynamique sur la valeur via un paramètre dédié
- **FR-005**: Le widget DOIT accepter un sous-titre optionnel sous le titre (texte secondaire tronqué)
- **FR-006**: Le widget DOIT accepter un sous-titre droit optionnel sous la valeur (texte secondaire)
- **FR-007**: Le widget DOIT émettre un événement au tap utilisateur avec feedback visuel (splash/ripple) quand `onPressed` est fourni. Quand `onPressed` est null, le widget est non-interactif (pas de ripple, pas de sémantique bouton)
- **FR-008**: Le widget DOIT utiliser uniquement les design tokens du thème (couleurs, espacements, typographie)
- **FR-009**: Le widget DOIT supporter les thèmes clair et sombre via les tokens existants
- **FR-010**: Le widget DOIT respecter l'accessibilité via un wrapper `Semantics` dont le `label` combine le titre et la valeur (ex: "Courses Lidl, -45,90 €"). Le flag `button` DOIT être `true` uniquement quand `onPressed` est fourni
- **FR-011**: Le widget DOIT proposer un constructeur nommé `ListItem.skeleton()` affichant des placeholders shimmer animés pour l'état de chargement (P3)

### Paramètres du widget

- **Icon** (obligatoire) : texte emoji affiché dans le cercle gauche
- **Title** (obligatoire) : texte principal
- **Value** (obligatoire) : texte formaté du montant affiché à droite
- **Subtitle** (optionnel) : texte secondaire sous le titre
- **RightSubtitle** (optionnel) : texte secondaire sous la valeur
- **ValueColor** (optionnel) : couleur appliquée au texte de la valeur
- **IconBackgroundColor** (optionnel) : couleur de fond du cercle icône (défaut : `AppColors.amber100`). Valeur statique — les écrans appelants fournissent la couleur adaptée au thème ou au contexte si nécessaire (ex : couleur de catégorie).
- **OnPressed** (optionnel) : callback déclenché au tap

### Key Entities

- **ListItem** : composant widget réutilisable sans logique métier. Reçoit des données déjà formatées (texte, couleur). Ne connaît pas les concepts de transaction, abonnement ou dette.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Le widget est utilisable dans les 4 contextes métier (dashboard, transactions, abonnements, dettes) sans modification du composant
- **SC-002**: Le rendu visuel est cohérent en thème clair et sombre (via tokens)
- **SC-003**: 100% des tests unitaires passent, couvrant les cas nominaux et les cas limites (données partielles, texte long)
- **SC-004**: Le widget ne contient aucune logique métier — il reçoit uniquement des données formatées en entrée
- **SC-005**: Le scroll d'une liste de 50+ items reste fluide sans jank perceptible

## Assumptions

- Le formatage des montants et des dates est déjà géré en amont par `AmountFormatter` et `RelativeDateFormatter` (KKS-101, terminé)
- Le thème de l'application (`AppThemeExtension`, design tokens) est déjà en place
- Le widget sera placé dans `lib/src/common_widgets/` conformément à l'architecture Flutter existante
- Les couleurs sémantiques (income/expense) sont fournies au widget par le parent, le widget ne les détermine pas lui-même
- L'icône est toujours un emoji texte (pas d'icône Material ni d'image)

## Clarifications

### Session 2026-02-21

- Q: Faut-il ajouter un paramètre optionnel `iconBackgroundColor` pour personnaliser la couleur du cercle icône ? → A: Oui, ajouter `iconBackgroundColor` optionnel avec défaut primary light.
- Q: Comportement quand `onPressed` est null ? → A: Non-interactif (pas de ripple, pas de sémantique bouton, rendu statique).
- Q: Prévoir un constructeur `ListItem.skeleton()` pour l'état de chargement ? → A: Oui, avec placeholders shimmer animés. Priorité P3.

## Dependencies

- **KKS-101** (terminé) : AmountFormatter et RelativeDateFormatter pour le formatage des données en amont
- **Design tokens Flutter** : `AppThemeExtension`, `AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`
