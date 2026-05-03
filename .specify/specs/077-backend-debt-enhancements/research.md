# Research: Backend Debt Enhancements

**Feature**: 077-backend-debt-enhancements | **Date**: 2026-03-09

## R1 — Lien Transaction ↔ Debt

**Decision**: Ajouter un champ `debt` (FK nullable) sur l'entité `Transaction`.
**Rationale**: Pattern cohérent avec `product` (FK nullable existante sur Transaction). Le lien est N:1 (plusieurs remboursements pour une dette). Pas de table intermédiaire nécessaire.
**Alternatives considered**:
- Table intermédiaire `debt_payments` → Rejetée : surcharge inutile pour un simple lien FK, incohérent avec les patterns existants (transferId, product).
- Champ `debtId` UUID sans FK JPA → Rejetée : perd l'intégrité référentielle et les cascades JPA.

## R2 — Calcul dynamique du montant restant

**Decision**: Calcul via `SELECT SUM(montant) FROM transactions WHERE debt_id = ?` soustrait du montant initial. Pas de champ persisté.
**Rationale**: Single-source-of-truth. Cohérent avec le pattern `calculateBalanceByAccountId` existant dans `TransactionRepository` (requête native SUM). App single-user, pas de problème de performance.
**Alternatives considered**:
- Champ `montantRestant` persisté sur Debt → Rejeté : risque de désynchronisation, double source de vérité.

## R3 — Association Debt ↔ Account

**Decision**: Ajouter un champ `account` (FK nullable, ManyToOne lazy) sur `Debt`. La devise est forcée à celle du compte.
**Rationale**: Pattern identique à Transaction.account. La devise de la dette suit celle du compte pour cohérence financière.
**Alternatives considered**:
- Pas de FK, juste un `accountId` UUID → Rejeté : perd la validation JPA et les jointures.

## R4 — Champ `includeInBalance`

**Decision**: Boolean sur Debt, default `false`. Disponible uniquement si `accountId IS NULL`.
**Rationale**: Les dettes avec compte sont déjà reflétées dans le solde du compte. Le toggle ne concerne que les dettes hors-compte.
**Alternatives considered**:
- Flag global (toutes les dettes incluses/exclues) → Rejeté : granularité insuffisante.

## R5 — Rappels de dette (reminderDate + reminderTime)

**Decision**: Deux champs séparés `reminderDate` (LocalDate) et `reminderTime` (LocalTime) sur Debt. Nouveau `@Scheduled` méthode dans `NotificationScheduler` tournant chaque minute.
**Rationale**: Le scheduler existant tourne à 6h00 quotidiennement (`cron = "0 0 6 * * *"`). Les rappels personnalisés nécessitent une granularité à la minute. Séparer les champs permet une UI date/heure distincte.
**Alternatives considered**:
- Un seul champ `reminderAt` (LocalDateTime) → Acceptable mais moins flexible pour l'UI.
- Réutiliser le scheduler quotidien → Rejeté : ne supporte pas les rappels intra-journaliers.

## R6 — NotificationType pour rappels

**Decision**: Ajouter `DEBT_REMINDER` à l'enum `NotificationType`.
**Rationale**: Distinct de `DEBT_DUE` (qui est déclenché par le scheduler quotidien pour les dettes arrivant à échéance). `DEBT_REMINDER` est un rappel personnalisé configurable par l'utilisateur.
**Alternatives considered**:
- Réutiliser `DEBT_DUE` → Rejeté : sémantique différente (due date vs reminder).

## R7 — Endpoint patrimoine total

**Decision**: `GET /accounts/total-balance` retournant une liste groupée par devise : solde comptes actifs + dettes `includeInBalance=true`.
**Rationale**: Aucun endpoint de patrimoine global n'existe. Les frontends agrègent côté client. Un endpoint serveur garantit un calcul cohérent.
**Alternatives considered**:
- Enrichir `GET /accounts` avec un total → Rejeté : mélange liste de ressources et agrégation.

## R8 — Migration Flyway V18

**Decision**: Un seul script `V18__add_debt_enhancements.sql` couvrant :
- `debts` : ajout `account_id` (FK nullable), `include_in_balance` (boolean, default false), `reminder_date` (date nullable), `reminder_time` (time nullable)
- `transactions` : ajout `debt_id` (FK nullable, SET NULL on delete)
- Données existantes : `currency` déjà présent sur `debts` (ajouté précédemment), `account_id = NULL`, `include_in_balance = false`, `reminder = NULL`, `debt_id = NULL`
**Rationale**: Toutes les modifications sont liées à la même feature. Pattern cohérent avec V15 (notifications) et V17 (budgets).

## R9 — Conversion devise lors d'association tardive

**Decision**: Utiliser `ExchangeRateService.findPivotRate()` existant pour convertir le montant. Refuser si aucun taux disponible.
**Rationale**: Le service existe déjà avec la logique de recherche directe + inversion. Pattern utilisé dans BudgetService pour l'agrégation multi-devise.
**Alternatives considered**:
- Pas de conversion (juste changer la devise) → Rejeté : incohérence comptable.

## R10 — Suppression cascade Transaction ↔ Debt

**Decision**: `ON DELETE SET NULL` sur `transactions.debt_id`. Quand une dette est supprimée, les transactions de remboursement sont conservées avec `debt_id = NULL`.
**Rationale**: Préserve l'intégrité comptable. Les transactions sont des faits financiers qui ne doivent pas être supprimés.
**Alternatives considered**:
- `ON DELETE CASCADE` → Rejeté : suppression silencieuse de transactions = perte de données financières.
