# Feature Specification: Gestion des devises — Dashboard unifié & taux de conversion manuels

**Feature Branch**: `070-currency-dashboard`
**Created**: 2026-03-06
**Status**: Draft
**Input**: Linear KKS-156 — Dashboard unifié multi-devises avec taux de conversion manuels
**Dependency**: Aucune (indépendant de KKS-155 — s'intègre au dashboard actuel)

## Clarifications

### Session 2026-03-06

- Q: Quand l'utilisateur change sa devise principale, les taux stockés sont-ils re-persistés avec la nouvelle base, ou le client calcule l'inversion à la volée ? → A: Le backend re-persiste automatiquement les taux inversés (base = toujours la devise principale).
- Q: Quelle précision maximale pour le stockage des taux de conversion ? → A: 6 décimales maximum (couvre les inversions de taux élevés comme XOF→EUR).
- Q: Les montants convertis doivent-ils toujours avoir 2 décimales ou respecter le `decimalPlaces` de la devise cible ? → A: Utiliser le `decimalPlaces` de la devise cible (0 pour XOF, 2 pour EUR/USD...).
- Q: Comment faciliter la saisie des taux sans dépendance externe ? → A: Taux fixes pré-remplis (EUR/XOF=655.957) + calculateur de taux pour les devises flottantes (« J'ai X [EUR] = Y [USD] » → taux = Y/X).
- Q: La liste ordonnée de devises dans UserPreference remplace-t-elle User.defaultCurrency ? → A: Oui, la liste ordonnée remplace User.defaultCurrency (single source of truth). La première devise de la liste = devise principale.
- Q: Cette feature dépend-elle strictement de KKS-155 (Refonte écran par écran) ? → A: Non, feature indépendante — s'intègre au dashboard actuel.
- Q: Quand le changement de devise principale depuis le dashboard est-il persisté ? → A: Persistance au quitter du dashboard (ou après debounce 2000ms d'inactivité) — un seul appel API.
- Q: Où la conversion de montants est-elle calculée dans l'architecture Flutter ? → A: Dans la presentation layer via un helper/extension réutilisable (pas dans les Notifiers).
- Q: Quelle stratégie de migration pour remplacer User.defaultCurrency par la liste ordonnée ? → A: Migration Flyway : initialise currencies avec [defaultCurrency], supprime defaultCurrency dans une migration ultérieure.
- Q: Quelles plateformes sont dans le scope de cette feature ? → A: Full stack — Backend (API REST + Flyway) + Flutter + Angular.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Voir le patrimoine total dans ma devise principale (Priority: P1)

En tant qu'utilisateur ayant des comptes dans plusieurs devises (EUR, XOF, USD...), je veux voir tous mes totaux agrégés dans une seule devise pour avoir une vue claire de ma situation financière, sans calculer moi-même les conversions.

**Why this priority**: C'est la valeur fondamentale de la feature — sans conversion unifiée, les totaux séparés par devise sont inutilisables pour une vue d'ensemble.

**Independent Test**: Peut être testé avec 2 comptes dans 2 devises différentes + 1 taux saisi. Le dashboard affiche le patrimoine total converti.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec un compte EUR (1000 EUR) et un compte XOF (500 000 XOF), et un taux 1 EUR = 655.957 XOF, **When** il consulte le dashboard avec EUR comme devise principale, **Then** le patrimoine total affiché est ~1762 EUR (1000 + 500000/655.957).
2. **Given** un utilisateur avec un seul compte dans sa devise principale, **When** il consulte le dashboard, **Then** les totaux s'affichent normalement sans mention de conversion.
3. **Given** un utilisateur avec un compte dans une devise sans taux renseigné, **When** il consulte le dashboard, **Then** un avertissement indique que le montant de ce compte n'est pas inclus dans le total et mentionne la devise concernée.

---

### User Story 2 - Saisir et gérer mes taux de conversion (Priority: P1)

En tant qu'utilisateur, je veux saisir manuellement les taux de conversion entre mes devises pour que les calculs de conversion soient corrects selon les taux que je choisis.

**Why this priority**: Sans taux, aucune conversion n'est possible. C'est un prérequis technique pour US1.

**Independent Test**: Peut être testé en allant dans Paramètres > Devises & Taux, en saisissant un taux EUR->XOF, et en vérifiant qu'il est persisté et récupérable.

**Acceptance Scenarios**:

1. **Given** un utilisateur dans les paramètres Devises & Taux, **When** il saisit le taux 1 EUR = 655.957 XOF, **Then** le taux est sauvegardé et visible dans la liste.
2. **Given** un taux EUR->XOF existant, **When** l'utilisateur modifie le taux à 660, **Then** la mise à jour remplace l'ancien taux (upsert).
3. **Given** un taux existant, **When** l'utilisateur le supprime, **Then** le taux est supprimé et les conversions concernées affichent un avertissement.
4. **Given** un utilisateur qui ajoute la devise XOF, **When** le formulaire de taux s'affiche, **Then** le taux EUR/XOF est pré-rempli à 655.957 (parité fixe) et l'utilisateur peut l'accepter ou le modifier.
5. **Given** un utilisateur qui ajoute la devise USD (taux flottant), **When** le formulaire de taux s'affiche, **Then** un calculateur propose « J'ai [montant] EUR = [montant] USD » et calcule le taux automatiquement à partir des deux montants saisis.

---

### User Story 3 - Changer rapidement de devise principale depuis le dashboard (Priority: P2)

En tant qu'utilisateur, je veux pouvoir basculer rapidement entre mes devises depuis le dashboard via un pill selector, pour voir mes finances dans n'importe quelle devise en un tap.

**Why this priority**: Apporte de la fluidité dans l'utilisation quotidienne. Dépend de US1 et US2 pour fonctionner.

**Independent Test**: Peut être testé avec 2 devises configurées. Tap sur la 2e devise, le dashboard se recalcule dans cette devise.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec EUR (principal) et XOF configurés, **When** il tape sur le pill XOF, **Then** le dashboard se recalcule en XOF (tous les montants convertis) et le pill XOF passe en première position.
2. **Given** un changement de devise, **When** le recalcul a lieu, **Then** il se fait instantanément côté client sans appel serveur.
3. **Given** un changement de devise, **When** l'utilisateur quitte le dashboard, **Then** le choix est persisté comme nouvelle devise principale.

---

### User Story 4 - Voir les montants convertis dans les listes (Priority: P2)

En tant qu'utilisateur, je veux voir le montant original et le montant converti dans ma devise principale sur chaque transaction, abonnement et dette, pour comprendre la valeur réelle de chaque opération.

**Why this priority**: Complète l'expérience multi-devises au-delà du dashboard. Dépend de US1 et US2.

**Independent Test**: Peut être testé en affichant une liste de transactions contenant des montants en devise étrangère — chaque item affiche le montant original + un sous-texte converti.

**Acceptance Scenarios**:

1. **Given** une transaction de 50 000 XOF avec un taux 1 EUR = 655.957 XOF et EUR comme devise principale, **When** l'utilisateur consulte la liste des transactions, **Then** l'item affiche « 50 000 XOF » avec un sous-texte « ~ 76 EUR ».
2. **Given** une transaction en EUR et EUR comme devise principale, **When** l'utilisateur consulte la liste, **Then** aucun sous-texte de conversion n'est affiché.
3. **Given** une transaction dans une devise sans taux renseigné, **When** l'utilisateur consulte la liste, **Then** le montant original est affiché sans conversion, avec un indicateur visuel signalant l'absence de taux.

---

### User Story 5 - Gérer les devises dans les paramètres (Priority: P2)

En tant qu'utilisateur, je veux ajouter, retirer et ordonner mes devises depuis les paramètres, pour contrôler quelles devises apparaissent dans le sélecteur du dashboard et définir ma devise principale.

**Why this priority**: Permet la personnalisation et le contrôle. La première devise de la liste = devise principale.

**Independent Test**: Peut être testé en ajoutant une devise, en la réordonnant en première position, et en vérifiant que le dashboard utilise cette devise comme principale.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec EUR configuré, **When** il ajoute USD dans les paramètres, **Then** USD apparaît dans le sélecteur du dashboard.
2. **Given** un utilisateur avec [EUR, XOF, USD], **When** il réordonne en [XOF, EUR, USD], **Then** XOF devient la devise principale et le dashboard se recalcule.
3. **Given** un utilisateur avec 2 devises, **When** il retire une devise qui a des comptes associés, **Then** un avertissement l'informe que les conversions pour ces comptes ne seront plus disponibles.

---

### User Story 6 - Proposition automatique du taux lors de la création d'un compte (Priority: P3)

En tant qu'utilisateur créant un compte dans une devise non encore configurée, je veux être invité à saisir le taux de conversion immédiatement, pour éviter d'oublier et d'avoir des avertissements de taux manquant.

**Why this priority**: Amélioration UX qui réduit les frictions mais n'est pas bloquante.

**Independent Test**: Peut être testé en créant un compte en GBP quand aucun taux EUR->GBP n'existe — un dialogue propose la saisie du taux.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec EUR comme devise principale et aucun taux EUR->GBP, **When** il crée un compte en GBP, **Then** un dialogue propose de saisir le taux EUR->GBP.
2. **Given** le dialogue de saisie du taux, **When** l'utilisateur ignore le dialogue, **Then** le compte est créé sans taux et un avertissement est visible sur le dashboard.
3. **Given** le dialogue de saisie du taux, **When** l'utilisateur saisit le taux, **Then** le taux est enregistré et la conversion fonctionne immédiatement.

---

### Edge Cases

- Que se passe-t-il quand le taux est 0 ou négatif ? Le système refuse les valeurs non positives.
- Que se passe-t-il quand l'utilisateur n'a qu'une seule devise ? Le sélecteur de devises n'est pas affiché, le dashboard fonctionne normalement.
- Que se passe-t-il quand tous les taux sont manquants ? Le dashboard affiche les totaux par devise séparément (fallback au comportement actuel) avec un message invitant à configurer les taux.
- Que se passe-t-il quand l'utilisateur supprime sa devise principale ? Impossible — la devise principale (première de la liste) ne peut être retirée, seulement réordonnée.
- Que se passe-t-il en cas de perte de précision sur les conversions ? Les montants convertis sont arrondis selon le `decimalPlaces` de la devise cible et préfixés par « ~ » pour indiquer une approximation.
- Que se passe-t-il quand l'utilisateur change de devise principale ? Le backend re-persiste automatiquement tous les taux inversés (base = nouvelle devise principale). Le client affiche instantanément les montants recalculés via inversion en mémoire avant confirmation serveur (voir FR-016).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT stocker des taux de conversion manuels par utilisateur (devise de base, devise cible, taux).
- **FR-002**: Le système DOIT permettre la création, modification (upsert) et suppression de taux de conversion.
- **FR-003**: Le système DOIT valider que les taux sont strictement positifs (> 0) et limités à 6 décimales maximum.
- **FR-004**: Le système DOIT stocker l'ordre des devises par utilisateur, la première devise étant la devise principale.
- **FR-005**: Le système DOIT permettre l'ajout, le retrait et la réorganisation des devises dans la liste utilisateur.
- **FR-006**: Le système DOIT effectuer toutes les conversions côté client — les montants stockés ne changent jamais. Sur Flutter, la conversion est un concern de la presentation layer (helper/extension réutilisable), pas des Notifiers.
- **FR-007**: Le système DOIT afficher un avertissement visuel quand un taux est manquant pour une conversion nécessaire.
- **FR-008**: Le système DOIT afficher les montants convertis avec le préfixe « ~ » pour indiquer une approximation.
- **FR-009**: Le sélecteur de devises du dashboard DOIT permettre un changement de devise instantané sans appel serveur.
- **FR-010**: Le système DOIT persister le changement de devise principale quand l'utilisateur quitte le dashboard ou après un debounce de 2000ms d'inactivité — un seul appel API (`PUT /users/me/preferences`).
- **FR-011**: Le système DOIT recalculer et re-persister tous les taux de conversion côté serveur lorsque la devise principale change (inversion automatique : base = toujours la devise principale).
- **FR-016**: Le client DOIT pouvoir calculer l'inversion temporaire d'un taux (1/rate) en mémoire pour un affichage instantané avant la persistance serveur.
- **FR-012**: Le système DOIT proposer la saisie d'un taux de conversion lors de la création d'un compte dans une nouvelle devise.
- **FR-013**: Le système DOIT empêcher la suppression de la devise principale (première de la liste).
- **FR-014**: Le système DOIT afficher les totaux par devise séparément en fallback quand aucun taux n'est disponible.
- **FR-015**: Le système DOIT arrondir les montants convertis selon le `decimalPlaces` de la devise cible (ex : 0 pour XOF, 2 pour EUR/USD).
- **FR-017**: Le système DOIT pré-remplir automatiquement les taux à parité fixe connue (EUR/XOF = 655.957) lors de l'ajout d'une devise concernée.
- **FR-018**: Le système DOIT proposer un calculateur de taux pour les devises à taux flottant : l'utilisateur saisit deux montants équivalents (ex : « 100 EUR = 108 USD ») et le taux est calculé automatiquement (108/100 = 1.08).
- **FR-019**: Les taux à parité fixe pré-remplis DOIVENT être modifiables par l'utilisateur (valeurs par défaut, pas verrouillées).

### Key Entities

- **ExchangeRate** : Taux de conversion entre deux devises pour un utilisateur. Attributs : devise de base, devise cible, taux (6 décimales max), date de mise à jour. Contrainte d'unicité sur (utilisateur, devise de base, devise cible).
- **UserPreference (enrichi)** : Ajout du champ `currencies` (liste ordonnée de `Currency`). La première devise de la liste est la devise principale de l'utilisateur. Ce champ **remplace** `User.defaultCurrency` (single source of truth). Migration Flyway : initialise `currencies` avec `[User.defaultCurrency]`, puis supprime `User.defaultCurrency` dans une migration ultérieure.
- **Currency** : Enum des devises supportées (EUR, USD, XOF, GBP, CHF, CAD, MAD). Inclut une métadonnée de parité fixe pour les paires connues (EUR/XOF).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut voir son patrimoine total agrégé dans une devise unique en moins de 2 secondes après l'ouverture du dashboard.
- **SC-002**: Le changement de devise principale via le sélecteur est instantané (< 200ms perçu par l'utilisateur, sans chargement visible).
- **SC-003**: 100% des montants en devise étrangère affichent un sous-texte converti dans la devise principale (quand le taux est disponible).
- **SC-004**: L'utilisateur peut saisir un nouveau taux de conversion en moins de 30 secondes (3 champs : devise base, devise cible, taux).
- **SC-005**: Aucune donnée de montant stockée n'est modifiée par le système de conversion — toutes les conversions sont calculées à la volée.
- **SC-006**: L'utilisateur est averti visuellement pour chaque montant dont la conversion est impossible (taux manquant).

## Assumptions

- Les devises supportées sont un ensemble fini défini par un enum (pas de saisie libre).
- Le sens du taux est « devise principale comme base » (ex : 1 EUR = 655.957 XOF).
- Un seul taux est stocké par paire de devises — pas d'historique de taux.
- Le changement de devise principale ne nécessite pas de confirmation utilisateur (action fréquente et fluide). La persistance est différée (debounce 2000ms ou quitter le dashboard).
- La migration de `User.defaultCurrency` vers `UserPreference.currencies` se fait en deux étapes Flyway : ajout + initialisation, puis suppression de l'ancien champ.
- La conversion côté client est acceptable en termes de performance pour le volume de données d'un utilisateur unique.
- Le scope couvre les trois couches : Backend (API REST + migrations Flyway), Flutter, et Angular (full stack).
- Les montants convertis affichés sont informatifs (approximation) et ne remplacent jamais les montants originaux.
