# Clarify Log — KKS-251

**Feature** : Récurrences liste Flutter (alignement DESIGN.md v5)  
**Session** : 2026-05-21  
**Points trouvés** : 5 | **Résolus auto** : 4 | **Résolus interactif** : 1 | **Différés** : 0

---

## Résumé

| # | Question | Catégorie | Impact | Incertitude | Score | Résolution |
|---|----------|-----------|--------|-------------|-------|------------|
| Q-004 | Architecture bottom sheet — screen vs item | UX/Interaction | Haut | Bas | **HAUT** | Auto |
| Q-001 | Monthly summary — conversion multi-devises | Scope fonctionnel | Moyen | Bas | **MOYEN** | Interactif |
| Q-005 | `validateAll` état "in progress" Flutter | Intégrations | Moyen | Moyen | **MOYEN** | Auto |
| Q-003 | `date_formatter.dart` nouveau fichier vs extension | Contraintes | Bas | Bas | **BAS** | Auto |
| NFR-002 (skeleton) | Skeleton côté droit non décrit | UX/Interaction | Bas | Bas | **BAS** | Auto |

---

## Détail des résolutions

### Q-004 — Architecture bottom sheet (HAUT) — Résolution automatique

**Question** : Le bottom sheet d'actions (validate / skip / deactivate) doit-il être géré dans `RecurringListScreen` ou dans `RecurringListItem` ?

**Analyse** : Scan de tous les `showModalBottomSheet` du codebase Flutter :
- `users_screen.dart:71` → dans le screen
- `account_form_screen.dart:146` → dans le screen
- `budget_category_detail_sheet.dart`, `unbudgeted_detail_sheet.dart` → dans des widgets dédiés (pas dans les items de liste)
- `recurring_list_item.dart:154` → cas actuel problématique (seul contre-exemple)
- `subscription_list_screen`, `debt_list_screen` → gèrent les actions métier dans le screen

**Source** : Pattern codebase + Constitution Principe III (simplicité, éviter la complexité dans les widgets feuilles).

**Résolution** : Bottom sheet géré dans `RecurringListScreen`. `RecurringListItem` expose uniquement `onTap: VoidCallback`. Suppression de `_showActionsSheet()` du widget item.

**Impact sur spec** : NFR-005 mis à jour, marqueur retiré.

---

### Q-001 — Monthly summary multi-devises (MOYEN) — Résolution interactif

**Question** : La monthly summary doit-elle ignorer la conversion multi-devises et afficher en valeur nominale ?

**Réponse utilisateur** : "se baser sur l'application angular"

**Analyse codebase post-réponse** : Flutter dispose déjà de l'infrastructure nécessaire :
- `CurrencyConverter.convert()` dans `lib/src/utils/currency_converter.dart`
- `exchangeRateListProvider` dans `lib/src/features/exchange_rates/application/`
- Pattern déjà implémenté : `subscription_list_screen.dart:332` et `debt_list_screen.dart:381`

Mécanisme : `CurrencyConverter.convert(amount: monthly, fromCurrency: item.accountCurrency, toCurrency: primaryCurrency, rates: exchangeRates)`. Fallback valeur nominale si taux absent.

**Source** : Décision utilisateur + codebase Flutter (pattern existant).

**Résolution** : Utiliser `CurrencyConverter` + `exchangeRateListProvider`, aligné sur Angular. ASS-001 invalidée.

**Impact sur spec** : US2 scenario 4 mis à jour, FR-010 mis à jour, ASS-001 barrée et remplacée.

---

### Q-005 — `validateAll` état "in progress" (MOYEN) — Résolution automatique

**Question** : Quel mécanisme Flutter pour signaler que `validateAll` est en cours ? Options : (a) id fictif `'__all__'` dans `mutatingIds`, (b) bool `isValidatingAll` dans `ListState<T>` (breaking change), (c) état local screen.

**Analyse** :
- `ListState<T>` a déjà `mutatingIds: Set<String>` (Freezed, partagé par toutes les features)
- Option (b) est un breaking change sur le modèle générique → viole Constitution Principe III YAGNI
- Option (c) : état local = logique dupliquée hors notifier, incohérent avec le pattern
- Option (a) : `mutatingIds.contains('__all__')` ou `mutatingIds.isNotEmpty` → suffisant pour désactiver les boutons, sans breaking change. Angular équivalent : `actionInProgress.set('all')`

**Source** : Constitution Principe III (YAGNI, pas de breaking change) + pattern `mutatingIds` existant.

**Résolution** : Option (a) — id fictif `'__all__'` dans `mutatingIds`.

**Impact sur spec** : NFR-006 mis à jour, marqueur retiré.

---

### Q-003 — `date_formatter.dart` vs extension (BAS) — Résolution automatique

**Question** : Créer un nouveau fichier `date_formatter.dart` ou étendre `RelativeDateFormatter` existant ?

**Analyse** : `relative_date_formatter.dart` existe et couvre déjà passé/présent. Divergences vs Angular sur 3 points (abréviation passé, futur ≤30j, format distant). Ajouter `formatCompact(DateTime)` = ~10 lignes.

**Source** : Constitution Principe III ("Trois lignes similaires valent mieux qu'une abstraction prématurée" — a fortiori, pas de nouveau fichier pour 10 lignes).

**Résolution** : Étendre `RelativeDateFormatter` avec `formatCompact(DateTime)`.

**Impact sur spec** : NFR-002 réécrit, marqueur retiré.

---

### NFR-002 (skeleton côté droit) — Résolution automatique

**Point** : FR-016 ne décrivait pas le changement du côté droit du skeleton (actuellement : badge-round 60px + montant ; avec la suppression de `_StatusBadge`, la structure change).

**Source** : Analyse du code `recurring_list_skeleton.dart` + impact de FR-005 (suppression `_StatusBadge`).

**Résolution** : FR-016 mis à jour — côté droit : supprimer le placeholder badge-round, conserver uniquement un placeholder montant (80px, `AppRadius.sm`).

**Impact sur spec** : FR-016 mis à jour.

---

## Modifications spec.md

| Section | Modification |
|---------|-------------|
| US2 Scenario 4 | Retiré `[NEEDS CLARIFICATION]`, ajout conversion + fallback |
| FR-010 | Ajout `CurrencyConverter` + `exchangeRateListProvider` |
| FR-016 | Ajout description côté droit skeleton |
| NFR-002 | Réécriture : `formatCompact()` sur fichier existant |
| NFR-005 | Ajout confirmation pattern codebase, retiré marqueur |
| NFR-006 | Option retenue `'__all__'`, retiré marqueur |
| ASS-001 | Invalidée et remplacée |
| Questions ouvertes | Q-001, Q-003, Q-004, Q-005 → Résolu |
