# Feature Specification: Redesign page Dettes (affichage + UX)

**Feature Branch**: `022-debt-page-redesign`
**Created**: 2026-02-13
**Status**: Draft
**Input**: KKS-71 — Revoir la page Dettes : groupement par sens, distinction visuelle Emprunt/Prêt, conformité DESIGN.md

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Distinction immédiate Emprunt vs Prêt (Priority: P1)

L'utilisateur ouvre la page Dettes et voit immédiatement deux sections distinctes : "On me doit" (prêts) et "Je dois" (emprunts). Chaque section a un accent visuel coloré (vert pour les prêts, rouge pour les emprunts) et affiche son total. L'utilisateur comprend en 2 secondes sa situation financière sans avoir à filtrer.

**Why this priority** : C'est le problème principal identifié — la liste plate actuelle ne permet pas de distinguer les emprunts des prêts sans filtrer manuellement.

**Independent Test** : Ouvrir la page `/debts` avec des dettes mixtes (emprunts + prêts) et vérifier que les deux sections s'affichent distinctement avec les bons accents colorés et totaux.

**Acceptance Scenarios** :

1. **Given** l'utilisateur a des emprunts et des prêts en cours, **When** il ouvre la page Dettes, **Then** il voit deux sections séparées "On me doit" et "Je dois" avec un total par section
2. **Given** l'utilisateur n'a que des prêts (pas d'emprunts), **When** il ouvre la page Dettes, **Then** seule la section "On me doit" s'affiche
3. **Given** l'utilisateur n'a aucune dette, **When** il ouvre la page Dettes, **Then** un état vide s'affiche avec un message approprié

---

### User Story 2 - KPI summary et cohérence page transactions (Priority: P1)

L'utilisateur voit en haut de page 3 cartes KPI ("Je dois", "On me doit", "Solde net") stylisées de manière cohérente avec la page transactions : cards blanches élevées par ombres, sans border-top coloré, montants colorés selon le type. Les KPI affichent toujours le total des dettes en cours (non remboursées), indépendamment du filtre statut actif.

**Why this priority** : La cohérence visuelle avec la page transactions est un critère d'acceptation de KKS-71 et les KPI sont la première information vue par l'utilisateur.

**Independent Test** : Ouvrir la page Dettes et la page Transactions côte à côte, vérifier que les KPI cards suivent le même style visuel (cards blanches, ombres, typographie, pas de border-top coloré).

**Acceptance Scenarios** :

1. **Given** des dettes existent, **When** l'utilisateur ouvre la page, **Then** 3 cartes KPI s'affichent en style cohérent avec la page transactions (cards blanches, shadow-md, montants colorés)
2. **Given** le solde net est positif, **When** l'utilisateur regarde la carte Solde, **Then** le montant est coloré en vert
3. **Given** le solde net est négatif, **When** l'utilisateur regarde la carte Solde, **Then** le montant est coloré en rouge
4. **Given** le filtre "Remboursé" est actif, **When** l'utilisateur regarde les KPI, **Then** les montants KPI reflètent uniquement le total des dettes en cours (non remboursées), pas les dettes remboursées affichées dans la liste

---

### User Story 3 - Filtre statut simplifié (Priority: P2)

L'utilisateur dispose d'un seul filtre segmenté pour le statut (Tous / En cours / Remboursé). Le filtre par sens (Je dois / On me doit) est supprimé car rendu inutile par le groupement visuel.

**Why this priority** : Simplifier l'interface en supprimant une redondance. Le groupement par sens remplace visuellement le filtre.

**Independent Test** : Vérifier qu'un seul segmented control s'affiche et que le filtrage par statut fonctionne correctement sur les deux sections.

**Acceptance Scenarios** :

1. **Given** l'utilisateur voit la page Dettes, **When** il clique "En cours", **Then** seules les dettes non remboursées apparaissent dans les deux sections
2. **Given** l'utilisateur filtre "Remboursé", **When** il regarde les sections, **Then** seules les dettes remboursées s'affichent (avec style atténué)
3. **Given** l'utilisateur filtre "En cours" et qu'aucun emprunt en cours n'existe, **When** il regarde la page, **Then** la section "Je dois" ne s'affiche pas

---

### User Story 4 - Dettes remboursées visuellement atténuées (Priority: P2)

Les dettes remboursées sont affichées avec une opacité réduite et un badge inline "Remboursé" à côté du sous-titre, indiquant clairement leur statut sans masquer l'information.

**Why this priority** : Améliore la lisibilité en distinguant visuellement les dettes actives des dettes réglées.

**Independent Test** : Créer une dette remboursée et vérifier qu'elle apparaît atténuée avec le badge "Remboursé".

**Acceptance Scenarios** :

1. **Given** une dette est marquée remboursée, **When** elle s'affiche dans la liste, **Then** l'item a une opacité réduite et un badge inline "Remboursé"
2. **Given** une dette n'est pas remboursée, **When** elle s'affiche, **Then** aucun badge n'apparaît et l'opacité est normale

---

### User Story 5 - Items enrichis avec catégorie et date (Priority: P3)

Chaque item de dette affiche l'icône catégorie (ou un fallback par type), le nom de la personne, le sous-titre (catégorie ou type Emprunt/Prêt), le montant coloré, et la date relative à droite.

**Why this priority** : Enrichit l'information affichée sans changer le fonctionnement.

**Independent Test** : Vérifier qu'un item avec catégorie affiche le nom de la catégorie en sous-titre, et qu'un item sans catégorie affiche "Emprunt" ou "Prêt".

**Acceptance Scenarios** :

1. **Given** une dette a une catégorie assignée, **When** elle s'affiche, **Then** le sous-titre montre le nom de la catégorie et l'icône est l'emoji de la catégorie
2. **Given** une dette n'a pas de catégorie, **When** elle s'affiche, **Then** le sous-titre montre "Emprunt" ou "Prêt" selon le sens
3. **Given** une dette date d'hier, **When** elle s'affiche, **Then** la date relative "Hier" apparaît à droite du montant

---

### Edge Cases

- Que se passe-t-il quand l'utilisateur n'a aucune dette ? Un état vide global s'affiche.
- Que se passe-t-il quand toutes les dettes sont du même sens ? Seule la section correspondante s'affiche.
- Que se passe-t-il quand le filtre "Remboursé" est actif mais qu'aucune dette n'est remboursée ? Un état vide s'affiche.
- Que se passe-t-il quand le filtre rend une section vide mais pas l'autre ? La section vide disparaît, l'autre reste visible.
- Comment se comporte la page en chargement ? Un spinner s'affiche (comportement existant conservé).
- Comment se comporte la page en erreur ? Un message d'erreur avec bouton "Réessayer" (comportement existant conservé).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** : La page DOIT afficher 3 cartes KPI (Je dois, On me doit, Solde net) en style cohérent avec la page transactions (cards blanches, ombres, sans border-top coloré — pas le dashboard)
- **FR-002** : La page DOIT afficher un seul filtre segmenté pour le statut (Tous / En cours / Remboursé)
- **FR-003** : L'ancien filtre par sens (Tous / Je dois / On me doit) DOIT être supprimé
- **FR-004** : La liste DOIT être groupée en deux sections par sens : "On me doit" (prêts) et "Je dois" (emprunts)
- **FR-005** : Chaque section DOIT afficher un header avec le titre et le total correspondant, coloré selon le sens
- **FR-006** : Chaque section DOIT avoir un accent visuel latéral gauche coloré (vert pour prêts, rouge pour emprunts)
- **FR-007** : Une section DOIT disparaître si elle ne contient aucune dette (après application du filtre)
- **FR-008** : Les dettes remboursées DOIVENT s'afficher avec une opacité réduite et un badge inline "Remboursé"
- **FR-009** : Chaque item de dette DOIT afficher : icône catégorie, nom personne, sous-titre (catégorie ou type), montant coloré, date relative
- **FR-010** : La page DOIT respecter les conventions du design system (tokens CSS, ombres, coins arrondis, police Inter)
- **FR-011** : Les KPI DOIVENT toujours afficher le total des dettes en cours (non remboursées), indépendamment du filtre statut actif
- **FR-012** : La page DOIT conserver les comportements existants : clic sur item ouvre la modale, FAB pour créer, états loading/error/empty

### Non-Functional Requirements

- **NFR-001** : La page DOIT rester utilisable sur un écran de 320px de large (mobile-first)
- **NFR-002** : Tous les styles DOIVENT utiliser des tokens CSS (`var(--*)`) — aucune valeur hardcodée (couleur, espacement, typo)
- **NFR-003** : Le filtrage client-side DOIT être instantané (pas de rechargement API à chaque changement de filtre statut)

### Assumptions

- La section "On me doit" (prêts) s'affiche en premier car c'est l'information la plus positive pour l'utilisateur
- Les totaux dans les headers de section reflètent les dettes visibles après filtre
- Les KPI en haut de page reflètent toujours le total des dettes en cours (non remboursées), indépendamment du filtre statut
- Le tri intra-section reste par date décroissante (plus récent en premier)
- Aucun nouveau composant partagé n'est créé — on réutilise `<app-list-item>` existant
- Aucune modification backend — changement purement frontend (3 fichiers)

## Clarifications

### Session 2026-02-13

- Q: Les KPI doivent être cohérents avec quelle page ? → A: La page transactions (cards blanches, ombres, sans border-top coloré), pas le dashboard (mini-cards avec border-top)
- Q: Les KPI reflètent-ils les dettes filtrées ou le total global ? → A: Total des dettes en cours uniquement (non remboursées), indépendant du filtre statut
- Q: Les KPI doivent-ils inclure les dettes remboursées dans leurs totaux ? → A: Non, en cours uniquement — les KPI reflètent la situation financière réelle actuelle

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** : L'utilisateur distingue immédiatement emprunts et prêts sans aucune interaction (0 clic nécessaire)
- **SC-002** : La page affiche 1 seul filtre au lieu de 2, réduisant la charge cognitive
- **SC-003** : Le style visuel des KPI de la page Dettes est cohérent avec la page transactions (mêmes patterns de cards blanches, ombres, typographie)
- **SC-004** : Toutes les fonctionnalités existantes sont préservées (CRUD via modale, filtre statut, états loading/error/empty)
- **SC-005** : La page respecte le design mobile-first et reste utilisable sur un écran de 320px de large
