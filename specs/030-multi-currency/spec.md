# Feature Specification: Gestion des devises (multi-currency)

**Feature Branch**: `030-multi-currency`
**Created**: 2026-02-17
**Status**: Draft
**Input**: User description: "Ajouter un support multi-devises à l'application budget. La devise est attachée au compte bancaire. Chaque compte a une devise fixe (code ISO 4217). L'utilisateur a une devise par défaut configurable. Pas de conversion automatique entre devises. Les totaux ne mélangent pas les devises. Les dettes ont aussi un champ currency."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Créer un compte avec une devise spécifique (Priority: P1)

Un utilisateur au Togo crée un compte bancaire en Franc CFA (XOF) pour gérer ses finances dans sa devise locale. Lors de la création du compte, il choisit la devise parmi une liste de devises supportées. Une fois le compte créé, tous les montants associés (transactions, abonnements) s'affichent dans cette devise.

**Why this priority**: C'est la fonctionnalité fondamentale. Sans la possibilité d'attacher une devise à un compte, aucune autre story n'a de sens. C'est le MVP minimal qui apporte de la valeur immédiate aux utilisateurs hors zone Euro.

**Independent Test**: Peut être testé en créant un compte avec devise XOF, puis en vérifiant que le solde et les montants s'affichent avec le symbole CFA.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté, **When** il crée un nouveau compte, **Then** il peut sélectionner une devise parmi la liste des devises supportées
2. **Given** un utilisateur connecté, **When** il crée un compte sans choisir de devise, **Then** la devise par défaut de l'utilisateur est automatiquement sélectionnée
3. **Given** un compte créé en XOF, **When** l'utilisateur consulte son compte, **Then** le solde est affiché avec le symbole et le format appropriés à la devise XOF
4. **Given** un compte existant en EUR, **When** l'utilisateur modifie le compte, **Then** la devise ne peut pas être changée (elle est fixée à la création)

---

### User Story 2 - Configurer sa devise par défaut (Priority: P2)

Un utilisateur peut définir sa devise par défaut dans ses paramètres. Cette devise est automatiquement pré-sélectionnée lors de la création de nouveaux comptes et de nouvelles dettes. Les nouveaux utilisateurs ont EUR comme devise par défaut.

**Why this priority**: Permet d'éviter de sélectionner manuellement la devise à chaque création de compte ou dette. Améliore l'expérience pour les utilisateurs qui opèrent principalement dans une seule devise.

**Independent Test**: Peut être testé en changeant la devise par défaut dans les paramètres, puis en vérifiant que la création de compte pré-sélectionne cette devise.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté, **When** il accède à ses paramètres, **Then** il voit un champ pour choisir sa devise par défaut
2. **Given** un utilisateur avec devise par défaut XOF, **When** il crée un nouveau compte, **Then** XOF est pré-sélectionné dans le champ devise
3. **Given** un nouvel utilisateur qui s'inscrit, **When** son profil est créé, **Then** sa devise par défaut est EUR
4. **Given** un utilisateur avec devise par défaut XOF, **When** il crée une nouvelle dette, **Then** XOF est pré-sélectionné

---

### User Story 3 - Voir les transactions formatées dans la devise du compte (Priority: P1)

Un utilisateur qui a des comptes dans plusieurs devises voit chaque transaction affichée avec le formatage correct de la devise du compte associé. Le symbole, le séparateur décimal et le nombre de décimales correspondent à la devise.

**Why this priority**: L'affichage correct des montants est essentiel à l'utilisabilité. Un montant en XOF affiché avec le symbole € serait confus et inutile. Priorité P1 car indissociable de la Story 1.

**Independent Test**: Peut être testé en consultant les transactions d'un compte XOF et en vérifiant le formatage (symbole FCFA, pas de décimales pour XOF).

**Acceptance Scenarios**:

1. **Given** une transaction sur un compte en XOF, **When** elle est affichée dans la liste, **Then** le montant utilise le format XOF (ex: 15 000 FCFA)
2. **Given** une transaction sur un compte en EUR, **When** elle est affichée dans la liste, **Then** le montant utilise le format EUR (ex: 150,00 €)
3. **Given** un abonnement lié à un compte en XOF, **When** il est affiché, **Then** le montant est formaté en XOF

---

### User Story 4 - Enregistrer une dette avec une devise (Priority: P2)

Un utilisateur peut enregistrer une dette (emprunt ou prêt) avec une devise spécifique, indépendamment de ses comptes bancaires. La devise est sélectionnable lors de la création de la dette.

**Why this priority**: Les dettes ne sont pas liées à un compte bancaire, mais doivent quand même avoir une devise pour un affichage correct. Priorité P2 car la fonctionnalité est nécessaire mais plus simple que les comptes.

**Independent Test**: Peut être testé en créant une dette en XOF et en vérifiant son affichage.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté, **When** il crée une nouvelle dette, **Then** il peut sélectionner une devise
2. **Given** une dette créée en XOF, **When** elle est affichée, **Then** le montant est formaté en XOF
3. **Given** un utilisateur avec devise par défaut EUR, **When** il crée une dette sans changer la devise, **Then** la dette est en EUR

---

### User Story 5 - Dashboard avec totaux groupés par devise (Priority: P3)

Sur le dashboard, les totaux (solde global, dépenses du mois, etc.) ne mélangent pas les devises. Si un utilisateur a des comptes en EUR et en XOF, il voit deux sections séparées avec les totaux dans chaque devise.

**Why this priority**: Fonctionnalité d'affichage avancée. Le dashboard reste utilisable sans cette story (chaque compte affiche son solde individuellement), mais l'agrégation par devise améliore la lisibilité.

**Independent Test**: Peut être testé en ayant des comptes dans deux devises et en vérifiant que le dashboard affiche les totaux séparément.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec des comptes en EUR et XOF, **When** il consulte le dashboard, **Then** les totaux sont affichés séparément par devise
2. **Given** un utilisateur avec uniquement des comptes en EUR, **When** il consulte le dashboard, **Then** l'affichage reste identique à l'actuel (un seul total)
3. **Given** un utilisateur avec des comptes dans 3 devises, **When** il consulte le dashboard, **Then** trois groupes de totaux sont affichés

---

### Edge Cases

- Que se passe-t-il si un utilisateur tente un virement entre deux comptes de devises différentes ? Le virement est interdit (pas de conversion automatique) avec un message d'erreur explicite.
- Comment sont affichées les données existantes sans devise après la migration ? Tous les comptes, dettes et abonnements existants sont migrés avec EUR comme devise par défaut.
- Que se passe-t-il si un utilisateur supprime tous ses comptes dans une devise mais a encore des dettes dans cette devise ? Les dettes restent affichées normalement dans leur devise.
- Comment se comporte la liste de devises supportées ? C'est une liste fermée maintenue dans le code, extensible par simple ajout. Pas de configuration dynamique ni d'API externe.
- Que se passe-t-il pour les abonnements liés à un compte ? Leur devise est forcée à celle du compte associé (non modifiable indépendamment). Si l'utilisateur change le compte lié, la devise s'aligne automatiquement sur le nouveau compte. Si l'utilisateur retire le compte lié (accountId → null), la devise conserve sa valeur actuelle et redevient modifiable.
- Que se passe-t-il pour les abonnements sans compte associé (account nullable) ? Ils ont leur propre champ devise, pré-rempli avec la devise par défaut de l'utilisateur à la création. La devise est persistée et ne change pas si l'utilisateur modifie sa devise par défaut.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre d'associer une devise (code ISO 4217) à chaque compte bancaire lors de sa création
- **FR-002**: La devise d'un compte DOIT être immuable après création (non modifiable en édition)
- **FR-003**: Le système DOIT proposer une liste fermée de devises supportées (au minimum : EUR, XOF, USD, GBP, CHF, CAD, MAD)
- **FR-004**: L'utilisateur DOIT pouvoir configurer sa devise par défaut dans les paramètres
- **FR-005**: La devise par défaut d'un nouvel utilisateur DOIT être EUR
- **FR-006**: Lors de la création d'un compte, la devise par défaut de l'utilisateur DOIT être pré-sélectionnée
- **FR-007**: Tous les montants DOIVENT être formatés selon les conventions de la devise concernée (symbole, décimales, séparateurs)
- **FR-008**: Le système DOIT permettre d'associer une devise à chaque dette lors de sa création
- **FR-009**: Le système DOIT permettre d'associer une devise à chaque abonnement. Si l'abonnement est lié à un compte, la devise DOIT être identique à celle du compte (non modifiable indépendamment). Si l'abonnement n'est pas lié à un compte, la devise est pré-remplie depuis la devise par défaut de l'utilisateur et reste modifiable
- **FR-010**: Les virements entre comptes de devises différentes DOIVENT être interdits avec un message d'erreur explicite
- **FR-011**: Les totaux du dashboard DOIVENT être groupés par devise (pas de mélange)
- **FR-012**: La migration des données existantes DOIT attribuer EUR comme devise à tous les comptes, dettes et abonnements existants
- **FR-013**: Le système NE DOIT PAS proposer de conversion automatique entre devises

### Key Entities

- **Account** : ajout d'un champ devise (code ISO 4217, 3 caractères), obligatoire, immuable après création. Chaque compte a exactement une devise.
- **User** : ajout d'un champ devise par défaut (code ISO 4217, 3 caractères), obligatoire, modifiable. Défaut : EUR.
- **Debt** : ajout d'un champ devise (code ISO 4217, 3 caractères), obligatoire. Indépendant des comptes.
- **Subscription** : ajout d'un champ devise (code ISO 4217, 3 caractères), obligatoire. Si lié à un compte : devise forcée = devise du compte (non modifiable indépendamment). Si pas de compte : pré-rempli depuis la devise par défaut de l'utilisateur, modifiable.
- **Transaction** : pas de nouveau champ. La devise est déduite du compte associé (relation existante).

## Clarifications

### Session 2026-02-17

- Q: Pourquoi ne pas utiliser la devise par défaut de l'utilisateur pour les dettes au lieu d'un champ dédié ? → A: On conserve un champ devise visible et modifiable sur Debt (option C). L'utilisateur peut choisir une devise différente de sa devise par défaut lors de la création d'une dette. Cela couvre le cas d'un prêt/emprunt dans une devise étrangère.
- Q: Même logique pour les abonnements sans compte ? → A: Initialement pas de champ devise (option A), mais après analyse de l'impact du changement de devise par défaut, on ajoute un champ devise sur Subscription (option C). La devise est pré-remplie depuis le compte (si lié) ou depuis la devise par défaut (si pas de compte), et reste modifiable.
- Q: Si l'utilisateur change sa devise par défaut, les abonnements sans compte changeraient de devise implicitement. Acceptable ? → A: Non, on ajoute un champ devise persisté sur Subscription (option C) pour éviter ce problème. La devise est figée à la création.
- Q: Faut-il contraindre la devise d'un abonnement lié à un compte à correspondre à la devise du compte ? → A: Oui, devise forcée = devise du compte si lié (option A). Modifiable uniquement si l'abonnement n'est pas lié à un compte. Cela garantit la cohérence des données et des totaux par devise.

## Assumptions

- La liste des devises supportées est maintenue en dur dans le code (pas de table en base ni d'API externe). Extensible par simple ajout de code.
- Les devises supportées initiales couvrent les besoins identifiés : EUR (Europe), XOF (Afrique de l'Ouest/Togo), USD, GBP, CHF, CAD, MAD.
- Le formatage des montants utilise les standards internationaux côté affichage. Le stockage ne contient que le code ISO.
- Les utilisateurs existants reçoivent EUR comme devise par défaut lors de la migration.
- Il n'y a pas de notion de taux de change dans le système. Aucune conversion n'est proposée.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un utilisateur peut créer un compte dans n'importe quelle devise supportée en moins de 30 secondes (même workflow qu'actuellement, un champ de plus)
- **SC-002**: Tous les montants affichés dans l'application utilisent le symbole et le formatage corrects de la devise concernée
- **SC-003**: Les données existantes continuent de fonctionner sans action de l'utilisateur après la migration (rétrocompatibilité totale)
- **SC-004**: Le dashboard affiche les totaux séparément par devise sans mélange de devises
- **SC-005**: Les virements entre comptes de devises différentes sont bloqués avec un message compréhensible
- **SC-006**: 100% des utilisateurs existants ont EUR comme devise par défaut après migration
