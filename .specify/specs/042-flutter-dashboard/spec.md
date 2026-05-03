# Feature Specification: Flutter Dashboard Complet

**Feature Branch**: `042-flutter-dashboard`
**Created**: 2026-02-22
**Status**: Draft
**Input**: KKS-102 — Redesign complet du dashboard Flutter avec 4 sections verticales (Hero Compte, Résumé mensuel, Mini-cards features, Dernières opérations)

## Clarifications

### Session 2026-02-22

- Q: Le résumé mensuel agrège-t-il tous les comptes ou seulement le compte héro ? → A: Tous les comptes agrégés (vision globale du mois)
- Q: Les comptes inactifs apparaissent-ils dans la section héro du dashboard ? → A: Masqués — seuls les comptes actifs apparaissent
- Q: Les barres recettes/dépenses sont proportionnelles par rapport à quelle référence ? → A: Relative à un objectif budget mensuel configuré par l'utilisateur. Fallback sur max(recettes, dépenses) si aucun objectif défini.
- Q: Le résumé mensuel est-il calculé localement ou via l'API ? → A: Via l'endpoint API existant `GET /transactions/summary` avec un nouveau provider Riverpod dédié côté Flutter.
- Q: L'objectif budget mensuel existe-t-il ou doit-il être créé ? → A: Reporté — utiliser uniquement le fallback max(recettes, dépenses) pour cette feature.
- Q: Combien de transactions récentes afficher (3 à 5) ? → A: Toujours 5 maximum (afficher ce qui existe si moins).
- Q: Le dashboard supporte-t-il le pull-to-refresh ? → A: Oui, pull-to-refresh recharge toutes les sections.
- Q: Que se passe-t-il au tap sur un compte (héro ou ligne) ? → A: Navigation vers le détail/transactions du compte.
- Q: Comment le dashboard détermine-t-il si un module est activé ? → A: Abonnements et Dettes sont toujours actifs (hardcodés). Boutique exclu (non implémenté). Pas de système de toggles pour cette feature.
- Q: Quel chiffre clé pour la mini-card Dettes ? → A: Solde net (prêts - emprunts non remboursés) + nombre de dettes en cours.
- Q: Comment calculer le montant total des abonnements (fréquences mixtes) ? → A: Normalisé en mensuel (annuel ÷ 12 + mensuel).
- Q: Quel solde afficher dans le héro compte ? → A: Solde calculé (soldeInitial + somme des transactions du compte).
- Q: Comment afficher le résumé mensuel multi-devises ? → A: Afficher uniquement la devise par défaut de l'utilisateur.
- Q: Comportement en cas d'échec partiel (une source KO, les autres OK) ? → A: Sections réussies affichées normalement, erreur inline par section en échec.
- Q: Quelles sont les bornes du sélecteur de mois ? → A: Max = mois courant (pas de futur), pas de borne inférieure.
- Q: Couleur du solde quand il est exactement 0 ? → A: Couleur neutre (couleur texte par défaut du thème).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Voir le solde de ses comptes d'un coup d'oeil (Priority: P1)

En ouvrant l'application, l'utilisateur voit immédiatement son compte par défaut en grand (icône, nom, solde) suivi de ses autres comptes en lignes simples. Cela lui permet de connaître sa situation financière globale sans navigation.

**Why this priority**: C'est l'information la plus consultée au quotidien. Un dashboard sans solde visible n'a aucune utilité.

**Independent Test**: Peut être testé en vérifiant que l'écran dashboard affiche le compte par défaut en héro et les autres comptes en liste, avec les soldes corrects.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a un compte par défaut, **When** il ouvre le dashboard, **Then** le compte par défaut s'affiche en grand avec son icône, son nom et son solde
2. **Given** l'utilisateur a plusieurs comptes, **When** il ouvre le dashboard, **Then** les autres comptes s'affichent en lignes simples sous le héro (icône + nom + montant)
3. **Given** l'utilisateur a 5 comptes ou plus, **When** il ouvre le dashboard, **Then** un lien "Voir tout" apparaît pour accéder à la liste complète
4. **Given** l'utilisateur n'a qu'un seul compte, **When** il ouvre le dashboard, **Then** seul le héro s'affiche sans liste supplémentaire ni lien "Voir tout"
5. **Given** les comptes ont des devises différentes, **When** il ouvre le dashboard, **Then** chaque compte affiche son montant dans sa propre devise (pas de conversion)

---

### User Story 2 - Consulter le résumé financier du mois (Priority: P1)

L'utilisateur peut voir un résumé de ses recettes et dépenses pour un mois donné, avec des barres de progression visuelles et le solde du mois. Il peut naviguer entre les mois via un sélecteur.

**Why this priority**: Le résumé mensuel est le deuxième besoin fondamental après les soldes — comprendre où en est le budget du mois en cours.

**Independent Test**: Peut être testé en vérifiant que le résumé affiche les totaux recettes/dépenses du mois sélectionné avec barres visuelles et solde coloré.

**Acceptance Scenarios**:

1. **Given** le dashboard est affiché, **When** l'utilisateur regarde la section résumé, **Then** il voit le mois courant sélectionné avec un sélecteur de mois (flèches gauche/droite)
2. **Given** le mois courant a des transactions, **When** le résumé s'affiche, **Then** les totaux recettes et dépenses s'affichent avec des barres de progression proportionnelles
3. **Given** le solde du mois est positif, **When** le résumé s'affiche, **Then** le solde est affiché en vert
4. **Given** le solde du mois est négatif, **When** le résumé s'affiche, **Then** le solde est affiché en rouge
5. **Given** l'utilisateur navigue vers un autre mois, **When** il tape sur la flèche gauche ou droite, **Then** le résumé se met à jour avec les données du mois sélectionné

---

### User Story 3 - Voir les dernières opérations (Priority: P2)

L'utilisateur peut voir ses dernières transactions (jusqu'à 5 maximum) directement sur le dashboard, avec les informations essentielles (catégorie, libellé, montant, date relative). Un lien permet d'accéder à la liste complète.

**Why this priority**: Les dernières opérations donnent un aperçu rapide de l'activité récente sans quitter le dashboard.

**Independent Test**: Peut être testé en vérifiant que les dernières transactions s'affichent avec les bonnes informations et que le lien "Voir tout" navigue vers la page Transactions.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a des transactions récentes, **When** il regarde la section dernières opérations, **Then** il voit jusqu'à 5 items avec : emoji catégorie, libellé, montant, catégorie et date relative
2. **Given** la section dernières opérations est affichée, **When** l'utilisateur tape sur "Voir tout", **Then** il est redirigé vers la page Transactions
3. **Given** l'utilisateur n'a aucune transaction, **When** il regarde cette section, **Then** un message d'état vide s'affiche (ex: "Aucune opération récente")

---

### User Story 4 - Accéder rapidement aux modules via les mini-cards (Priority: P2)

L'utilisateur voit 2 mini-cards (Abonnements, Dettes) qui affichent un chiffre clé et permettent de naviguer directement vers la page dédiée. Les cards sont toujours visibles (modules hardcodés actifs).

**Why this priority**: Les mini-cards offrent un raccourci vers les modules secondaires et une vue agrégée de leur état, mais ne sont pas essentielles pour l'usage quotidien de base.

**Independent Test**: Peut être testé en vérifiant que les cards s'affichent dynamiquement selon les modules activés, montrent les bonnes données et naviguent vers les bonnes pages.

**Acceptance Scenarios**:

1. **Given** le dashboard s'affiche, **When** l'utilisateur regarde la mini-card Abonnements, **Then** elle affiche l'icône, le montant total normalisé en mensuel (annuel ÷ 12 + mensuel) et le nombre d'abonnements actifs
2. **Given** le dashboard s'affiche, **When** l'utilisateur regarde la mini-card Dettes, **Then** elle affiche l'icône, le solde net (prêts - emprunts non remboursés) et le nombre de dettes en cours
3. **Given** l'utilisateur tape sur une mini-card, **When** il appuie dessus, **Then** il est redirigé vers la page dédiée du module
4. **Given** le dashboard s'affiche, **When** les deux mini-cards sont rendues, **Then** elles occupent chacune la moitié de la largeur disponible (layout en row)

---

### User Story 5 - Scroll fluide et contenu condensé (Priority: P3)

L'ensemble du dashboard tient en environ 1.5 écrans de scroll vertical, sans scroll horizontal. L'expérience est fluide et les sections sont empilées verticalement.

**Why this priority**: L'ergonomie globale est importante mais dépend de la réalisation des sections individuelles.

**Independent Test**: Peut être testé en vérifiant que le dashboard complet s'affiche verticalement sans scroll horizontal et que le contenu total ne dépasse pas ~1.5 écrans.

**Acceptance Scenarios**:

1. **Given** toutes les sections sont chargées, **When** l'utilisateur scrolle, **Then** le contenu défile verticalement de manière fluide
2. **Given** le dashboard est affiché, **When** l'utilisateur essaie de scroller horizontalement, **Then** aucun scroll horizontal n'est possible
3. **Given** le dashboard est affiché sur un écran standard mobile, **When** toutes les sections sont visibles, **Then** le contenu total ne dépasse pas ~1.5 écrans de hauteur

---

### Edge Cases

- Que se passe-t-il quand l'utilisateur n'a aucun compte ? Le dashboard affiche un état vide avec incitation à créer un compte.
- Que se passe-t-il quand les données sont en cours de chargement ? Des skeletons/shimmer sont affichés pour chaque section.
- Que se passe-t-il quand le chargement échoue (erreur réseau) ? Chaque section gère son erreur indépendamment : les sections réussies s'affichent normalement, les sections en échec affichent un message d'erreur inline avec option de réessayer.
- Que se passe-t-il quand un mois n'a aucune transaction ? Le résumé affiche 0 pour recettes et dépenses, barres vides, solde à 0.
- Que se passe-t-il quand le compte par défaut est supprimé ou désactivé ? Le prochain compte actif disponible prend la place du héro.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher le compte par défaut actif de l'utilisateur en position héro (icône, nom, solde calculé = soldeInitial + somme des transactions du compte) en haut du dashboard
- **FR-002**: Le système DOIT lister les autres comptes actifs de l'utilisateur sous le héro en lignes simples (icône, nom, montant dans la devise du compte). Les comptes inactifs sont exclus du dashboard.
- **FR-003**: Le système DOIT afficher un lien "Voir tout" si l'utilisateur possède 5 comptes actifs ou plus
- **FR-004**: Le système DOIT afficher un sélecteur de mois permettant de naviguer entre les mois (flèches gauche/droite). La borne maximale est le mois courant (pas de navigation dans le futur). Pas de borne inférieure.
- **FR-005**: Le système DOIT afficher les totaux recettes et dépenses du mois sélectionné via l'endpoint API `GET /transactions/summary`, filtrés sur la devise par défaut de l'utilisateur uniquement, avec des barres de progression proportionnelles à max(recettes, dépenses). L'objectif budget mensuel est reporté à une future feature.
- **FR-006**: Le système DOIT afficher le solde du mois en vert si positif, en rouge si négatif, en couleur neutre (texte par défaut du thème) si exactement zéro
- **FR-007**: Le système DOIT afficher les 5 dernières transactions maximum (ou moins si insuffisant) avec : emoji catégorie, libellé, montant, nom de catégorie et date relative
- **FR-008**: Le système DOIT fournir un lien "Voir tout" dans la section dernières opérations qui navigue vers la page Transactions
- **FR-009**: Le système DOIT afficher 2 mini-cards statiques : Abonnements et Dettes (toujours visibles, pas de système de toggles). Le module Boutique est exclu de cette itération (non implémenté).
- **FR-010**: Chaque mini-card DOIT afficher une icône, un nom, un chiffre clé et un sous-texte descriptif
- **FR-011**: Le tap sur une mini-card DOIT naviguer vers la page dédiée du module correspondant
- **FR-013**: Le système DOIT afficher des états de chargement (skeletons) pendant le chargement des données
- **FR-014**: Le système DOIT afficher un état vide adapté quand aucun compte n'existe
- **FR-015**: Le système DOIT afficher un message de bienvenue personnalisé avec le prénom de l'utilisateur
- **FR-016**: Le système DOIT supporter le pull-to-refresh pour recharger toutes les sections du dashboard simultanément
- **FR-017**: Le tap sur le compte héro ou une ligne de compte DOIT naviguer vers le détail/transactions du compte sélectionné

### Key Entities

- **Compte** : Représente un compte bancaire de l'utilisateur. Attributs clés : nom, type, solde, icône, couleur, devise, indicateur par défaut.
- **Transaction** : Opération financière. Attributs clés : montant, libellé, type (recette/dépense), date, catégorie associée.
- **Abonnement** : Paiement récurrent. Attributs clés : nom, montant, fréquence, état actif/inactif.
- **Dette** : Somme due ou prêtée. Attributs clés : personne, montant, sens (emprunt/prêt), état remboursé/en cours.
- **Catégorie** : Classification des opérations. Attributs clés : nom, icône, couleur.
- **Résumé mensuel** : Agrégation des transactions d'un mois sur tous les comptes de l'utilisateur. Attributs calculés : total recettes, total dépenses, solde du mois.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur voit le solde de son compte principal en moins de 2 secondes après l'ouverture de l'application
- **SC-002**: L'ensemble du dashboard est visible en ~1.5 écrans de scroll vertical maximum
- **SC-003**: Le changement de mois dans le résumé met à jour les données en moins de 1 seconde
- **SC-004**: L'utilisateur peut accéder à n'importe quel module (Transactions, Abonnements, Dettes) en un seul tap depuis le dashboard
- **SC-005**: Les 2 mini-cards (Abonnements, Dettes) s'affichent correctement côte à côte avec les données agrégées justes
- **SC-006**: Les états de chargement (skeletons) s'affichent immédiatement, sans écran blanc intermédiaire

## Assumptions

- Le widget MonthSelector (KKS-100) est disponible et fonctionnel
- Les notifiers Riverpod CRUD (KKS-115) pour les entités Account, Transaction, Subscription, Debt sont implémentés
- Le widget ListItem (KKS-93) est disponible pour afficher les dernières opérations
- L'endpoint API `GET /transactions/summary?month=X&year=Y` existe et retourne une liste de `MonthlySummaryResponse` par devise (totalRecettes, totalDepenses, solde, currency). Un nouveau provider Riverpod dédié doit être créé côté Flutter pour l'appeler.
- Les modules Abonnements et Dettes sont considérés toujours actifs (hardcodés). Le module Boutique est exclu de cette itération. Un système de toggles de modules pourra être ajouté dans une future feature.
- Le seuil de 5 comptes pour "Voir tout" est un paramètre raisonnable basé sur l'usage typique
- Les dates relatives suivent le format courant (il y a Xj, il y a X sem, etc.)
- Le message de bienvenue utilise le prénom de l'utilisateur connecté (champ name de l'entité User)
- L'objectif budget mensuel n'existe pas encore. Les barres de progression utilisent le fallback max(recettes, dépenses). L'objectif configurable est reporté à une future feature dédiée.
