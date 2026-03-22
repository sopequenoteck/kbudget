# Feature Specification: Améliorations dettes — compte bancaire, solde, rappels, remboursement

**Feature Branch**: `080-debt-enhancements`
**Created**: 2026-03-13
**Status**: Implemented
**Input**: User description: "KKS-160 Améliorations dettes — compte bancaire, solde, rappels, remboursement"
**Linear**: [KKS-160](https://linear.app/kksdev/issue/KKS-160/ameliorations-dettes-compte-bancaire-solde-rappels-remboursement)

**Note**: Les 3 sous-tâches (backend KKS-194, Angular KKS-195, Flutter KKS-196) sont terminées. Cette spec documente la feature complète telle qu'implémentée.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rembourser une dette partiellement ou totalement (Priority: P1)

L'utilisateur consulte une dette en cours et effectue un remboursement. Le système crée automatiquement une transaction liée, met à jour le montant restant, et marque la dette comme remboursée si le solde atteint zéro.

**Why this priority**: Le remboursement est le coeur fonctionnel de la gestion des dettes — sans lui, les dettes restent figées et ne reflètent pas la réalité financière.

**Independent Test**: Peut être testé en créant une dette, puis en effectuant un remboursement partiel et un remboursement total. Vérifier que le montant restant est mis à jour et que la dette passe en statut "remboursé" au solde zéro.

**Acceptance Scenarios**:

1. **Given** une dette de 200€ non remboursée, **When** l'utilisateur rembourse 50€ en sélectionnant un compte source, **Then** une transaction de 50€ est créée (liée à la dette), le montant restant passe à 150€, et la dette reste active.
2. **Given** une dette de 150€ restant, **When** l'utilisateur rembourse 150€, **Then** la dette est marquée comme remboursée et le montant restant est 0€.
3. **Given** une dette remboursée, **When** l'utilisateur consulte la dette, **Then** un badge "Remboursé" est affiché et le bouton rembourser est masqué.

---

### User Story 2 - Associer une dette à un compte bancaire (Priority: P1)

L'utilisateur peut attacher une dette à un compte bancaire existant. La devise de la dette est alors forcée à celle du compte. Si la dette avait une devise différente, une conversion est effectuée via les taux de change configurés.

**Why this priority**: L'association compte-dette est fondamentale pour le suivi patrimonial et le calcul correct du solde total.

**Independent Test**: Créer une dette sans compte, puis l'associer à un compte. Vérifier que la devise est forcée et que la dette apparaît dans le solde du compte.

**Acceptance Scenarios**:

1. **Given** un formulaire de création de dette, **When** l'utilisateur sélectionne un compte bancaire, **Then** la devise de la dette est automatiquement celle du compte (non modifiable).
2. **Given** une dette existante en EUR sans compte, **When** l'utilisateur l'associe à un compte en USD, **Then** le montant est converti EUR→USD via le taux de change configuré.
3. **Given** une dette sans compte sélectionné, **When** l'utilisateur valide, **Then** la devise est celle par défaut de l'utilisateur.

---

### User Story 3 - Consulter l'historique des paiements (Priority: P2)

L'utilisateur consulte le détail d'une dette et voit l'historique complet des remboursements effectués, avec une barre de progression indiquant le pourcentage remboursé.

**Why this priority**: Le suivi visuel des paiements donne confiance et visibilité sur la progression du remboursement.

**Independent Test**: Effectuer plusieurs remboursements partiels sur une dette puis consulter le détail. Vérifier que tous les paiements apparaissent et que la barre de progression reflète le ratio.

**Acceptance Scenarios**:

1. **Given** une dette avec 3 paiements effectués, **When** l'utilisateur ouvre le détail de la dette, **Then** les 3 paiements sont listés avec date, montant et compte source.
2. **Given** une dette de 500€ avec 200€ remboursés, **When** l'utilisateur consulte le détail, **Then** la barre de progression affiche 40% et le montant restant est 300€.

---

### User Story 4 - Inclure/exclure une dette du patrimoine (Priority: P2)

Pour les dettes sans compte bancaire, l'utilisateur peut décider si la dette est incluse dans le calcul du solde total (patrimoine). Les dettes attachées à un compte sont automatiquement incluses via le solde du compte.

**Why this priority**: Permet un contrôle fin sur le calcul du patrimoine sans obliger l'utilisateur à attacher chaque dette à un compte.

**Independent Test**: Créer une dette sans compte, activer le toggle "Inclure dans le patrimoine", vérifier que le solde total est impacté.

**Acceptance Scenarios**:

1. **Given** une dette de type PRET de 100€ sans compte, **When** l'utilisateur active "Inclure dans le patrimoine", **Then** le solde total augmente de 100€ (on nous doit de l'argent).
2. **Given** une dette attachée à un compte, **When** l'utilisateur édite la dette, **Then** le toggle "Inclure dans le patrimoine" n'est pas visible (inclusion automatique via le compte).

---

### User Story 5 - Configurer des rappels de dette avec actions (Priority: P3)

L'utilisateur définit une date et heure de rappel sur une dette. À l'échéance, une notification est envoyée avec deux actions : "Reporter" (snooze) et "Rembourser".

**Why this priority**: Les rappels sont un confort important mais la feature fonctionne sans eux.

**Independent Test**: Configurer un rappel sur une dette, attendre l'échéance, vérifier la notification et tester les deux actions.

**Acceptance Scenarios**:

1. **Given** une dette avec rappel configuré au 15/03 à 10h, **When** la date/heure est atteinte, **Then** une notification "Dette Paul 200€ — échéance demain" est créée.
2. **Given** une notification de rappel de dette, **When** l'utilisateur clique "Reporter", **Then** un formulaire rapide permet de choisir une nouvelle date/heure de rappel.
3. **Given** une notification de rappel de dette, **When** l'utilisateur clique "Rembourser", **Then** le flux de remboursement s'ouvre (sélection compte + montant).

---

### Edge Cases

- Que se passe-t-il si l'utilisateur tente de rembourser plus que le montant restant ? Le système DOIT rejeter la requête avec une erreur 400 (montant > restant dû).
- Que se passe-t-il si le compte source du remboursement a un solde insuffisant ? Le remboursement est quand même autorisé (pas de contrôle de solde négatif — cohérent avec le comportement des transactions).
- Que se passe-t-il si l'utilisateur supprime un compte associé à une dette ? L'association est retirée (account_id mis à null).
- Que se passe-t-il si aucun taux de change n'est configuré lors d'une association tardive ? Le système refuse l'opération et demande de configurer le taux d'abord.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre d'associer une dette à un compte bancaire existant, avec forçage de la devise à celle du compte.
- **FR-002**: Le système DOIT permettre le remboursement partiel ou total d'une dette via un endpoint dédié, créant automatiquement une transaction liée.
- **FR-003**: Le système DOIT calculer le montant restant d'une dette comme : montant initial − somme des transactions de remboursement liées.
- **FR-004**: Le système DOIT marquer automatiquement une dette comme remboursée lorsque le montant restant atteint zéro.
- **FR-005**: Le système DOIT fournir l'historique des paiements d'une dette (liste des transactions liées).
- **FR-006**: Le système DOIT permettre un toggle "Inclure dans le patrimoine" pour les dettes sans compte bancaire.
- **FR-007**: Le système DOIT inclure automatiquement les dettes attachées à un compte dans le calcul du solde total (via le compte).
- **FR-008**: Le système DOIT permettre de configurer une date et heure de rappel sur une dette.
- **FR-009**: Le système DOIT générer des notifications à l'échéance des rappels de dette, avec actions "Reporter" et "Rembourser".
- **FR-010**: Le système DOIT effectuer une conversion de devise via les taux de change configurés lors d'une association tardive d'une dette à un compte avec une devise différente.
- **FR-011**: Le système DOIT permettre de reporter un rappel de dette (snooze) en choisissant une nouvelle date.
- **FR-012**: Le système DOIT agréger le solde total par devise en incluant les soldes des comptes et les dettes éligibles.

### Key Entities

- **Debt** (enrichie) : personne, montant, sens (EMPRUNT/PRET), date, devise, remboursé, compte bancaire associé (optionnel), inclusion patrimoine (toggle), date/heure rappel (optionnel).
- **Transaction** (enrichie) : référence optionnelle vers une dette (pour les transactions de remboursement).
- **Notification** : type DEBT_REMINDER, entité liée (dette), titre, corps, actions (Reporter/Rembourser).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut rembourser une dette (partiellement ou totalement) en moins de 3 interactions (bouton rembourser → sélection compte → validation).
- **SC-002**: Le montant restant d'une dette est mis à jour en temps réel après chaque remboursement.
- **SC-003**: Le solde total par devise reflète correctement les dettes incluses dans le patrimoine.
- **SC-004**: Les rappels de dette déclenchent une notification à la date/heure configurée avec les actions "Reporter" et "Rembourser" disponibles.
- **SC-005**: L'historique des paiements d'une dette affiche tous les remboursements effectués avec date, montant et compte source.

## Assumptions

- Les taux de change sont déjà configurés par l'utilisateur (KKS-156 / feature 070-currency-dashboard terminée).
- Le système de notifications est opérationnel (KKS-158 / feature 072-notification-system terminée).
- Le contrôle de solde négatif n'est pas appliqué sur les comptes (cohérent avec le comportement existant des transactions).
- Une dette ne peut pas être associée à plusieurs comptes simultanément.

## Dependencies

- **KKS-156** (Gestion des devises) : taux de conversion pour association tardive dette-compte.
- **KKS-158** (Système de notifications) : infrastructure push/WebSocket pour les rappels de dette.
