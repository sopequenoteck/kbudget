# Feature Specification: Entité Product + CRUD complet (Backend)

**Feature Branch**: `056-backend-product-crud`
**Created**: 2026-02-27
**Status**: Draft
**Input**: Linear KKS-118 — Créer l'entité Product et le CRUD REST pour la fonctionnalité Boutique
**Linear**: [KKS-118](https://linear.app/kksdev/issue/KKS-118/backend-entite-product-crud-complet)
**Blocks**: KKS-124 (Flutter: Formulaire Produit)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Créer un produit (Priority: P1)

En tant qu'utilisateur, je veux pouvoir créer un produit dans ma boutique avec un nom, un prix d'achat, un prix de vente et un stock disponible, afin de référencer les articles que je vends.

**Why this priority**: C'est la fonctionnalité fondamentale — sans création de produit, aucune autre opération n'est possible. Bloque directement le formulaire Flutter (KKS-124).

**Independent Test**: Peut être testé en envoyant une requête POST avec les champs obligatoires et en vérifiant que le produit est persisté et retourné avec un identifiant unique.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifié, **When** il envoie une requête de création avec nom, prix d'achat, prix de vente et stock, **Then** le produit est créé et retourné avec un identifiant unique, les valeurs par défaut (actif=true, totalVendu=0) et les timestamps.
2. **Given** un utilisateur authentifié, **When** il envoie une requête de création avec des champs optionnels (description, icône, imageUrl), **Then** le produit est créé avec ces champs renseignés.
3. **Given** un utilisateur authentifié, **When** il envoie une requête de création avec des données invalides (nom vide, prix négatif, stock négatif), **Then** le système retourne une erreur de validation détaillée.

---

### User Story 2 - Lister ses produits (Priority: P1)

En tant qu'utilisateur, je veux voir la liste de mes produits actifs, afin de gérer mon inventaire.

**Why this priority**: Permet de visualiser les produits créés. Essentiel pour toute interaction avec la boutique.

**Independent Test**: Peut être testé en créant plusieurs produits puis en récupérant la liste, en vérifiant que seuls les produits de l'utilisateur authentifié sont retournés.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifié avec des produits, **When** il demande la liste de ses produits, **Then** il reçoit uniquement ses propres produits (pas ceux d'autres utilisateurs).
2. **Given** un utilisateur authentifié sans produit, **When** il demande la liste, **Then** il reçoit une liste vide.
3. **Given** un utilisateur authentifié avec des produits actifs et inactifs, **When** il demande la liste, **Then** il reçoit uniquement les produits actifs (actif=true), triés par date de création décroissante.

---

### User Story 3 - Consulter un produit (Priority: P2)

En tant qu'utilisateur, je veux consulter le détail d'un de mes produits, afin de voir toutes ses informations.

**Why this priority**: Nécessaire pour l'affichage détaillé dans le frontend, mais la liste couvre déjà le besoin minimal.

**Independent Test**: Peut être testé en créant un produit puis en le récupérant par son identifiant.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifié et un produit lui appartenant, **When** il demande le détail de ce produit, **Then** il reçoit toutes les informations du produit.
2. **Given** un utilisateur authentifié, **When** il demande un produit appartenant à un autre utilisateur, **Then** le système retourne une erreur "non trouvé".
3. **Given** un utilisateur authentifié, **When** il demande un produit avec un identifiant inexistant, **Then** le système retourne une erreur "non trouvé".

---

### User Story 4 - Modifier un produit (Priority: P2)

En tant qu'utilisateur, je veux modifier les informations d'un de mes produits (nom, prix, stock, description, etc.), afin de garder mon catalogue à jour.

**Why this priority**: Fonctionnalité courante mais non bloquante pour le MVP.

**Independent Test**: Peut être testé en créant un produit, le modifiant, puis en vérifiant que les nouvelles valeurs sont persistées.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifié et un produit lui appartenant, **When** il envoie une modification avec des données valides, **Then** le produit est mis à jour et le timestamp de modification est actualisé.
2. **Given** un utilisateur authentifié, **When** il tente de modifier un produit d'un autre utilisateur, **Then** le système retourne une erreur "non trouvé".
3. **Given** un utilisateur authentifié, **When** il envoie une modification avec des données invalides, **Then** le système retourne une erreur de validation.

---

### User Story 5 - Supprimer un produit (Priority: P3)

En tant qu'utilisateur, je veux supprimer définitivement un produit de ma boutique, afin de nettoyer mon catalogue.

**Why this priority**: La suppression est définitive (suppression physique). Moins prioritaire car désactiver un produit couvre le besoin courant.

**Independent Test**: Peut être testé en créant un produit, le supprimant, puis en vérifiant qu'il n'existe plus en base et n'est plus accessible.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifié et un produit lui appartenant, **When** il supprime ce produit, **Then** le produit est supprimé définitivement de la base de données.
2. **Given** un utilisateur authentifié, **When** il tente de supprimer un produit d'un autre utilisateur, **Then** le système retourne une erreur "non trouvé".
3. **Given** un utilisateur authentifié, **When** il tente de consulter un produit supprimé, **Then** le système retourne une erreur "non trouvé".

---

### Edge Cases

- Que se passe-t-il quand un utilisateur crée un produit avec un nom identique à un produit existant ? Le système autorise les doublons (pas de contrainte d'unicité sur le nom).
- Que se passe-t-il quand le stock est à 0 ? Le produit reste actif et visible, seul le stock est à zéro.
- Que se passe-t-il quand un produit désactivé (actif=false) est demandé par son identifiant ? Le détail est toujours accessible via GET par ID, mais le produit n'apparaît plus dans la liste.
- Que se passe-t-il quand un produit désactivé est réactivé via PUT avec actif=true ? Le produit réapparaît dans la liste des produits actifs.
- Que se passe-t-il quand un produit supprimé (DELETE) est demandé ? Le système retourne une erreur "non trouvé" car le produit n'existe plus en base.
- Que se passe-t-il avec des valeurs limites pour les prix (très petits, très grands) ? Le système accepte tout montant positif, limité par la précision NUMERIC(12,2) soit un maximum de 9 999 999 999,99.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre la création d'un produit avec les champs obligatoires : nom, prix d'achat, prix de vente, stock disponible.
- **FR-002**: Le système DOIT valider les données d'entrée : nom non vide (max 100 caractères), description optionnelle (max 500 caractères), prix strictement positifs avec 2 décimales maximum, stock >= 0.
- **FR-003**: Le système DOIT initialiser automatiquement les valeurs par défaut : actif=true, totalVendu=0, timestamps de création et modification.
- **FR-004**: Le système DOIT retourner la liste des produits actifs (actif=true) appartenant uniquement à l'utilisateur authentifié, triés par date de création décroissante. Les produits inactifs sont filtrés de la liste par défaut ; le champ `actif` est un toggle de visibilité indépendant de la suppression.
- **FR-005**: Le système DOIT permettre la consultation d'un produit par son identifiant, uniquement si celui-ci appartient à l'utilisateur authentifié.
- **FR-006**: Le système DOIT permettre la modification d'un produit via remplacement complet (PUT) — tous les champs éditables sont requis dans chaque requête. Seuls l'identifiant et les timestamps auto-gérés sont exclus. Modification uniquement par le propriétaire.
- **FR-007**: Le système DOIT implémenter la suppression comme une suppression physique (suppression définitive en base de données), uniquement par le propriétaire du produit.
- **FR-008**: Le système DOIT isoler les données de chaque utilisateur — aucun utilisateur ne peut accéder aux produits d'un autre.
- **FR-009**: Le système DOIT retourner des erreurs de validation détaillées pour chaque champ invalide.
- **FR-010**: Le système DOIT supporter les champs optionnels : description, icône (emoji), URL d'image.
- **FR-011**: Le système DOIT mettre à jour automatiquement le timestamp de modification lors de chaque mise à jour.
- **FR-012**: Le système DOIT permettre l'activation/désactivation d'un produit via PUT en modifiant le champ `actif`. Un produit désactivé n'apparaît plus dans la liste mais reste en base de données.
- **FR-013**: Le système DOIT protéger les endpoints Product derrière le feature toggle `SHOP` (enum `Feature`). Les endpoints ne sont accessibles que si l'utilisateur a activé le toggle `SHOP` dans ses préférences.

### Key Entities

- **Product** : Représente un article de la boutique de l'utilisateur. Identifiant : UUID. Attributs clés : nom (VARCHAR 100), description (VARCHAR 500, optionnel), icône emoji (optionnel), URL d'image (optionnel), prix d'achat (NUMERIC(12,2)), prix de vente (NUMERIC(12,2)), stock disponible (INTEGER), total vendu (INTEGER, défaut 0), statut actif/inactif (BOOLEAN, défaut true), timestamps (createdAt, updatedAt). Appartient à un seul utilisateur (FK → User).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut créer un produit en une seule opération avec validation immédiate des données.
- **SC-002**: La liste des produits retourne uniquement les produits actifs de l'utilisateur authentifié, sans fuite de données entre utilisateurs.
- **SC-003**: Les 5 opérations CRUD (créer, lister, consulter, modifier, supprimer) fonctionnent de bout en bout avec isolation des données par utilisateur.
- **SC-004**: 100% des champs obligatoires sont validés, avec messages d'erreur explicites pour chaque champ invalide.
- **SC-005**: Les tests d'intégration couvrent les scénarios nominaux, les cas d'erreur (validation, accès interdit) et les cas limites (produit inexistant, produit d'un autre utilisateur).

## Clarifications

### Session 2026-02-27

- Q: Sémantique de mise à jour — remplacement complet (PUT) ou partiel (PATCH) ? → A: Remplacement complet (PUT), tous les champs éditables requis dans chaque requête.
- Q: Un produit soft-deleted peut-il être réactivé ? → A: Oui, le champ `actif` est modifiable via PUT, permettant la réactivation d'un produit.
- Q: Suppression = soft delete ou hard delete ? → A: Hard delete (suppression physique). Le champ `actif` est un toggle de visibilité indépendant, pas un mécanisme de suppression.
- Q: Type d'identifiant pour Product — UUID ou Long auto-incrémenté ? → A: UUID (cohérent avec l'entité User existante).
- Q: Précision des prix (prixAchat, prixVente) — quel type de données ? → A: BigDecimal avec 2 décimales (NUMERIC(12,2) en base).
- Q: Ordre par défaut de la liste des produits ? → A: Par date de création décroissante (plus récent en premier).
- Q: La boutique doit-elle être protégée par un feature toggle ? → A: Oui, ajouter `SHOP` à l'enum `Feature`. Endpoints accessibles uniquement si le toggle est activé.

## Assumptions

- Les noms de produits ne sont pas uniques (pas de contrainte d'unicité).
- La suppression (DELETE) est physique et définitive. Le champ `actif` est un toggle de visibilité indépendant (activer/désactiver un produit sans le supprimer).
- Le champ `totalVendu` est initialisé à 0 et sera incrémenté par une future feature de vente.
- La liste ne retourne que les produits actifs (actif=true) ; le détail par ID retourne le produit quel que soit son statut actif/inactif.
- Pas de pagination requise pour cette phase (sera ajoutée si nécessaire ultérieurement).
- Pas de recherche/filtre avancé pour cette phase.
