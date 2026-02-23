# Feature Specification: Formulaire Dette Flutter

**Feature Branch**: `047-flutter-debt-form`
**Created**: 2026-02-23
**Status**: Draft
**Input**: User description: "KKS-108 — Flutter: Formulaire Dette. Modal avec toggle Emprunt/Prêt. Champs: personne, montant, date, catégorie. Mode création/édition + suppression + marquer remboursé."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Créer une dette (Priority: P1)

L'utilisateur souhaite enregistrer une nouvelle dette (emprunt ou prêt) depuis n'importe quel écran de l'application via le bouton flottant (+). Une modale s'ouvre avec un toggle Emprunt/Prêt dans le header. Il remplit les champs obligatoires (personne, montant, date) et optionnellement une catégorie, puis sauvegarde.

**Why this priority**: C'est la fonctionnalité principale — sans création, aucune autre action n'a de sens.

**Independent Test**: Peut être testé en ouvrant la modale dette, remplissant les champs et vérifiant que la dette apparaît dans la liste.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur un écran quelconque, **When** il appuie sur le FAB (+) et sélectionne "Nouvelle dette", **Then** la modale s'ouvre avec le toggle Emprunt/Prêt et les champs vides, la date pré-remplie à aujourd'hui.
2. **Given** la modale de création est ouverte, **When** l'utilisateur remplit personne, montant, date et appuie sur "Enregistrer", **Then** la dette est sauvegardée avec le type sélectionné (emprunt ou prêt) et la modale se ferme.
3. **Given** la modale de création est ouverte, **When** l'utilisateur bascule le toggle de Emprunt à Prêt, **Then** le type de la dette change visuellement et sera sauvegardé comme "Prêt".
4. **Given** la modale de création est ouverte, **When** l'utilisateur sélectionne une catégorie, **Then** la catégorie est associée à la dette.

---

### User Story 2 - Modifier une dette existante (Priority: P2)

L'utilisateur souhaite modifier les informations d'une dette existante. Depuis la liste des dettes, il tape sur une dette pour ouvrir la modale en mode édition, pré-remplie avec les données existantes. Il modifie les champs souhaités et sauvegarde.

**Why this priority**: La modification corrige les erreurs de saisie et maintient les données à jour.

**Independent Test**: Peut être testé en créant une dette, l'ouvrant en édition, modifiant un champ et vérifiant la mise à jour.

**Acceptance Scenarios**:

1. **Given** l'utilisateur tape sur une dette dans la liste, **When** la modale s'ouvre, **Then** tous les champs sont pré-remplis avec les valeurs existantes (personne, montant, date, catégorie, type emprunt/prêt).
2. **Given** la modale d'édition est ouverte, **When** l'utilisateur modifie le montant et appuie sur "Modifier", **Then** la dette est mise à jour avec le nouveau montant.
3. **Given** la modale d'édition est ouverte, **When** l'utilisateur change le type de Emprunt à Prêt via le toggle, **Then** le type est mis à jour lors de la sauvegarde.

---

### User Story 3 - Supprimer une dette (Priority: P3)

L'utilisateur souhaite supprimer définitivement une dette. Depuis la modale d'édition, un bouton de suppression est disponible. Une confirmation est demandée avant la suppression effective.

**Why this priority**: Fonction de nettoyage nécessaire mais moins fréquente que la création/édition.

**Independent Test**: Peut être testé en ouvrant une dette en édition, appuyant sur supprimer, confirmant et vérifiant la disparition de la liste.

**Acceptance Scenarios**:

1. **Given** la modale d'édition est ouverte, **When** l'utilisateur appuie sur l'icône de suppression, **Then** une boîte de dialogue de confirmation s'affiche.
2. **Given** la boîte de confirmation est affichée, **When** l'utilisateur confirme, **Then** la dette est supprimée et la modale se ferme.
3. **Given** la boîte de confirmation est affichée, **When** l'utilisateur annule, **Then** la dette n'est pas supprimée et la modale reste ouverte.

---

### User Story 4 - Marquer une dette comme remboursée (Priority: P2)

L'utilisateur souhaite marquer une dette comme remboursée sans la supprimer, afin de conserver l'historique. Depuis la modale d'édition, un switch permet de basculer l'état de remboursement.

**Why this priority**: Même niveau que l'édition — c'est le cycle de vie naturel d'une dette.

**Independent Test**: Peut être testé en ouvrant une dette non remboursée, activant le switch "Remboursé" et vérifiant que l'état est mis à jour.

**Acceptance Scenarios**:

1. **Given** la modale d'édition est ouverte pour une dette non remboursée, **When** l'utilisateur active le switch "Remboursé" et sauvegarde, **Then** l'état est sauvegardé comme remboursé.
2. **Given** la modale d'édition est ouverte pour une dette remboursée, **When** l'utilisateur désactive le switch "Remboursé" et sauvegarde, **Then** l'état repasse à non remboursé.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur soumet le formulaire sans remplir le champ personne ? → Message d'erreur de validation affiché sous le champ.
- Que se passe-t-il si le montant saisi est zéro ou négatif ? → Message d'erreur de validation affiché sous le champ montant.
- Que se passe-t-il si l'utilisateur annule le formulaire avec des données modifiées ? → La modale se ferme sans sauvegarder (cohérent avec les formulaires existants).
- Que se passe-t-il si l'utilisateur modifie le toggle emprunt/prêt en mode édition ? → Le changement est pris en compte et sauvegardé normalement.
- Que se passe-t-il si aucune catégorie n'est sélectionnée ? → La dette est sauvegardée sans catégorie (champ optionnel).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher une modale de formulaire dette accessible depuis le bouton flottant (+) avec un toggle Emprunt/Prêt dans le header.
- **FR-002**: Le formulaire DOIT contenir les champs : personne (texte, obligatoire), montant (numérique, obligatoire, positif), date (sélecteur de date, obligatoire, pré-remplie à aujourd'hui), catégorie (sélecteur optionnel).
- **FR-003**: Le formulaire DOIT supporter le mode création (champs vides sauf date) et le mode édition (champs pré-remplis avec les données existantes).
- **FR-004**: En mode édition, le système DOIT afficher un bouton de suppression avec confirmation avant suppression définitive.
- **FR-005**: En mode édition, le système DOIT afficher un switch "Remboursé" permettant de basculer l'état de remboursement de la dette.
- **FR-006**: Le système DOIT valider les champs obligatoires avant soumission et afficher les messages d'erreur sous chaque champ invalide.
- **FR-007**: Le layout du formulaire DOIT suivre le pattern des formulaires existants : personne et montant côte à côte en première ligne, puis date, catégorie, et switch remboursé.
- **FR-008**: Le système DOIT sauvegarder la dette via le repository existant (local ou distant selon le mode de données configuré).

### Key Entities

- **Debt**: Représente une dette (emprunt ou prêt). Attributs clés : personne (nom du débiteur/créancier), montant, type (emprunt/prêt), date, état de remboursement, catégorie optionnelle. Pas de lien avec un compte bancaire.
- **Category**: Catégorie optionnelle associée à la dette pour le classement. Attributs : nom, icône (emoji), couleur.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut créer une dette (emprunt ou prêt) en moins de 15 secondes via 3 interactions maximum (ouvrir modale, remplir champs, sauvegarder).
- **SC-002**: L'utilisateur peut modifier n'importe quel champ d'une dette existante et sauvegarder en moins de 10 secondes.
- **SC-003**: L'utilisateur peut marquer une dette comme remboursée en 2 interactions (ouvrir modale, activer switch + sauvegarder).
- **SC-004**: 100% des erreurs de validation sont visibles sous le champ concerné avant soumission.
- **SC-005**: Le formulaire dette suit visuellement le même design que les formulaires transaction et abonnement existants, assurant une expérience cohérente.

## Assumptions

- Le formulaire suit exactement les mêmes patterns UI que les formulaires transaction et abonnement existants (layout, validation, boutons d'action).
- Le système de modale et le toggle Emprunt/Prêt sont déjà configurés dans l'application (ModalType.debt avec les labels et le defaultSubType).
- La couche data (repository, notifier, DAO, DTOs) est déjà complète et fonctionnelle pour les opérations CRUD sur les dettes.
- Le champ catégorie est optionnel, comme dans le modèle de données existant.
- Le champ devise (currency) utilise la devise par défaut (EUR) et n'est pas exposé dans le formulaire.
- Le switch "Remboursé" n'est affiché qu'en mode édition (une dette nouvellement créée est par défaut non remboursée).
