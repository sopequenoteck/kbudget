# Review Log — KKS-241

---

## Review #1 — review-spec — 2026-05-11

**Verdict : BLOQUANT → corrigé**

### Constats bloquants (corrigés dans la foulée)

**B-001 — FR-013 : `recurringListNotifierProvider.create()` inexistant**
- `RecurringListNotifier` n'expose que `loadItems()`, `validate()`, `skip()`, `deactivate()`.
- Correction : FR-012 et FR-013 mis à jour — la méthode `create()` est ajoutée à `RecurringListNotifier`, `RecurringTransactionRepository` et `RecurringTransactionRepositoryRemote` dans le périmètre de cette feature. Décision utilisateur : "Ajouter create() au notifier existant".

**B-002 — FR-017 : portée de la suppression `includeInBalance` non spécifiée**
- Le champ `includeInBalance` est dans le modèle `Debt` (`@Default(false)`), actif dans `DebtForm` (state + UI + logique soumission).
- Correction : FR-017 précisé — suppression UI uniquement, champ conservé dans le modèle Drift avec calcul silencieux `includeInBalance = accountId != null`. Décision utilisateur : "UI seulement — champ conservé dans le modèle".

### Warnings documentés (non bloquants)

- **W-001** : FR-009, FR-010, FR-011 sans SC dédié — traçabilité partielle acceptable.
- **W-002** : SC-007 ambigu vis-à-vis des modifications `application/` — corrigé dans spec.md.
- **W-003** : NFR-003 utilise le terme Angular "ChangeDetectionStrategy" — terme incorrect en Flutter, conservé comme commentaire interne (signal de l'intention, non implémentable littéralement).
- **W-004** : Edge case récurrence + échec → corrigé dans spec.md (Snackbar erreur sans rollback transaction).
- **W-005** : SC-004 incohérent avec mise à jour des assertions test → corrigé dans spec.md (US4 scenario 1).

### Infos (non corrigées, documentées)

- **I-001** : Pill devise + sélection compte → comportement non spécifié (remplacement devise par devise du compte). À documenter en plan.
- **I-002** : Layout TransactionForm inversé par rapport au formulaire actuel (libellé gauche → montant gauche). Changement non noté, à mentionner dans le plan.
- **I-003** : `ConfirmDialog` vs `showDeleteConfirmDialog` — deux patterns. À trancher au plan.
- **I-004** : Assumption A-004 sur `LibelleAutocompleteField` incomplète (wiring controller). Sans impact bloquant.

---

**État après corrections** : PASS implicite — tous les BLOQUANT corrigés dans la même session.
**Prochaine étape** : `/devflow.research KKS-241`

---

## Review #1 — review-impl — 2026-05-11

**Verdict : PASS**

### Constats BLOQUANTS

Aucun.

### Warnings documentés (non bloquants)

- **W-001** : FR-013 — icône récurrence non désactivée si `dataModeProvider = DataMode.local` (R-004 non implémenté). SnackBar de fallback présent dans `transaction_form.dart` lignes 186-192. Dette technique mineure.
- **W-002** : `recurring_list_notifier.dart` — méthode `create()` utilise `isLoading: true` global au lieu du pattern `mutatingIds` établi par `deactivate()`. Impact pratique limité (pas d'identifiant à tracker à la création).
- **W-003** : Nommage tests `transaction_form_test.dart` légèrement divergent du plan (cas métier couverts, format `should_[résultat]_when_[condition]` respecté).
- **W-004** : `DebtForm` — fallback `Currency.eur` si compte sans devise. Comportement cohérent avec `SubscriptionForm`, inchangé vs code actuel.

### Infos

- **I-001** : `_MetaPill` / `_DeletePill` dupliqués dans les 3 formulaires (dans le périmètre prévu — candidat future extraction `form_pills.dart`).
- **I-002** : SC-007 entièrement respecté — seuls les fichiers autorisés hors présentation modifiés.
- **I-003** : `_showFormBottomSheet` correctement intégré — `isScrollControlled`, `useSafeArea`, `MediaQuery.viewInsetsOf`, `.then()` pour fermeture modal.
- **I-004** : `showTimePicker()` déclenché directement dans `InlineDatePicker.onChanged` (UX plus fluide que le bouton intermédiaire du plan) — conforme FR-015.
- **I-005** : 28/28 tâches cochées [x].

### Grille FR

17/17 FR couverts. Qualité : 0 `print()`, 0 secret, 0 code mort.

**Prochaine étape** : `/devflow.docs KKS-241`
