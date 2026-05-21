# Documentation — KKS-251 : Récurrences liste Flutter (alignement DESIGN.md v5)

**Issue** : KKS-251 | **Parent** : KKS-242  
**Date de livraison** : 2026-05-21 | **Branch** : `develop`  
**Statut** : Done

---

## Résumé

Refonte complète de l'écran Récurrences Flutter pour aligner son design et ses interactions sur la source de vérité Angular (DESIGN.md v5). L'écran adopte le grouping visuel par statut avec headers colorés, une carte de bilan mensuel, une action sheet redessinée, et supprime les swipe gestures au profit d'un paradigme tap-only. Deux utilitaires ont été étendus : `validateAll()` dans le notifier et `formatCompact()` dans `RelativeDateFormatter`. Aucune couche data/domain n'a été touchée.

---

## Guide utilisateur

### Écran Récurrences — nouvelles fonctionnalités

#### Groupes visuels par statut

Les récurrences sont maintenant organisées en 3 groupes distincts, chacun avec un header coloré et une carte arrondie :

| Groupe | Couleur du header | Contenu |
|--------|------------------|---------|
| **EN RETARD** | Rouge (`expenseColor`) | Récurrences dont la date est dépassée |
| **AUJOURD'HUI** | Bleu (`colorScheme.primary`) | Récurrences dues aujourd'hui |
| **À VENIR** | Gris (`onSurfaceVariant`) | Récurrences futures |

Les groupes sans items ne s'affichent pas.

#### Bilan mensuel

Une carte synthèse apparaît en haut de la liste (quand elle n'est pas vide) :

- **BILAN MENSUEL** : net mensuel total (+/- en vert/rouge), calculé en normalisant toutes les récurrences en montant mensuel (hebdomadaire × 4.33, annuel ÷ 12) et en convertissant en devise principale.
- **N CHARGES** : nombre de dépenses actives + total mensuel estimé.

#### Bouton "Tout payé"

Le groupe **EN RETARD** affiche un bouton "Tout payé" à droite du header. Il valide séquentiellement toutes les récurrences en retard. Pendant l'opération, le bouton est remplacé par un spinner. En cas d'erreur, l'opération s'arrête et un message d'erreur s'affiche.

#### Ligne de récurrence

Chaque ligne affiche :
- **Icône catégorie** : cercle 36px (fond couleur catégorie avec transparence, ou gris par défaut)
- **Libellé** en gras
- **Sous-titre** : fréquence · date relative (ex : `/mois · dans 3 j.`, `hier`, `aujourd'hui`)
- **Montant** coloré à droite : rouge pour les dépenses, vert pour les recettes

#### Action sheet (tap sur une ligne)

Taper sur n'importe quelle ligne ouvre un bottom sheet avec :

1. **Résumé** : fréquence, montant coloré en grand, date de prochaine occurrence
2. **3 boutons** :
   - **Marquer comme payée** (fond bleu) — crée une transaction et avance la date
   - **Passer cette occurrence** (fond neutre) — avance la date sans créer de transaction
   - **Désactiver la récurrence** (texte rouge) — désactive directement, sans confirmation

> La confirmation par `AlertDialog` a été supprimée : la désactivation est immédiate depuis l'action sheet.

#### États de l'écran

| État | Affichage |
|------|-----------|
| Chargement | Skeleton 5 lignes avec icône cercle |
| Vide | Message "Aucune récurrence active" avec icône |
| Erreur | Message d'erreur avec bouton "Réessayer" |

---

## Changements techniques

### Fichiers modifiés

| Fichier | Nature du changement |
|---------|---------------------|
| `flutter/lib/src/utils/relative_date_formatter.dart` | Ajout de `formatCompact(DateTime)` : 6 cas (aujourd'hui/hier/demain/il y a Nj/dans Nj/dd MMM) |
| `flutter/lib/src/features/recurring/application/recurring_list_notifier.dart` | Ajout de `validateAll(List<String> ids)` avec sentinel `'__all__'` dans `mutatingIds` |
| `flutter/lib/src/features/recurring/presentation/recurring_list_screen.dart` | Refonte complète : `CustomScrollView` + 3 groupes + `_MonthlySummaryCard` + `_StatusGroupSection` + `_ActionButton` + `_showActionSheet()` + suppression `AlertDialog` |
| `flutter/lib/src/features/recurring/presentation/widgets/recurring_list_item.dart` | `ConsumerWidget` → `StatelessWidget` · interface `{onTap}` · cercle 36px · sous-titre · montant coloré · suppression `Dismissible`/`_StatusBadge`/`_SwipeBackground` |
| `flutter/lib/src/features/recurring/presentation/widgets/recurring_list_skeleton.dart` | 6 → 5 items · icône carré → cercle 36px · suppression placeholder badge droit |
| `flutter/lib/src/localization/app_fr.arb` | 3 valeurs mises à jour + 4 nouvelles clés (`recurringValidateAll`, `recurringNextOccurrence`, `recurringMonthlySummaryTitle`, `recurringChargesCount`) |
| `flutter/lib/src/localization/app_localizations.dart` | Régénéré via `flutter gen-l10n` |
| `flutter/lib/src/localization/app_localizations_fr.dart` | Régénéré via `flutter gen-l10n` |

### Aucun fichier créé

Tous les changements sont des modifications de fichiers existants. Aucune nouvelle dépendance ajoutée.

### Couches non touchées

Conformément à NFR-003, les couches suivantes n'ont pas été modifiées :

- `RecurringTransactionRepository` (interface + implémentations)
- Domain model `RecurringTransaction`, `RecurringStatus`
- DTOs (`RecurringTransactionCreateRequest`)

### Changements l10n

| Clé | Ancienne valeur | Nouvelle valeur |
|-----|----------------|----------------|
| `recurringValidate` | "Valider" | "Marquer comme payée" |
| `recurringSkip` | "Passer" | "Passer cette occurrence" |
| `recurringDeactivate` | "Désactiver" | "Désactiver la récurrence" |
| `recurringValidateAll` | *(nouvelle)* | "Tout payé" |
| `recurringNextOccurrence` | *(nouvelle)* | "Prochaine : {date}" |
| `recurringMonthlySummaryTitle` | *(nouvelle)* | "BILAN MENSUEL" |
| `recurringChargesCount` | *(nouvelle)* | "{count} CHARGES" |

### Widgets privés ajoutés dans `recurring_list_screen.dart`

| Widget/Méthode | Rôle |
|---------------|------|
| `_MonthlySummaryCard` | Carte bilan mensuel (normalisation + conversion devise) |
| `_StatusGroupSection` | Section groupe (header coloré + bouton "Tout payé" + carte arrondie + items) |
| `_ActionButton` | Bouton pleine largeur avec spinner pour l'action sheet |
| `_showActionSheet()` | Méthode screen ouvrant le `showModalBottomSheet` avec résumé + 3 actions |
| `_handleValidateAll()` | Handler async + SnackBar résultat pour "Tout payé" |

---

## Configuration

Aucune configuration supplémentaire requise.

L'écran utilise des providers déjà configurés dans l'application :
- `exchangeRateListProvider` — taux de change (pour la monthly summary)
- `dashboardNotifierProvider` — devise principale de l'utilisateur
- `recurringListNotifierProvider` — état et actions sur les récurrences

---

## Tests et validation

### Tests automatisés

| Fichier | Tests | Résultat |
|---------|-------|---------|
| `recurring_list_notifier_test.dart` | 10 tests (7 existants + 3 nouveaux `validateAll`) | ✅ 10/10 PASS |
| `recurring_list_screen_test.dart` | 3 tests (adaptés : overrides providers additionnels, assertions headers) | ✅ 3/3 PASS |
| **Total** | **13 tests** | **✅ 13/13 PASS** |

#### Nouveaux tests `validateAll` (notifier)

- `should_validateAll_call_validate_for_each_id_and_clear_sentinel` — vérifie l'appel séquentiel et la suppression du sentinel `'__all__'`
- `should_validateAll_stop_at_first_failure_and_clear_sentinel` — vérifie l'arrêt au premier échec et le nettoyage `finally`
- `should_validateAll_return_immediately_when_ids_empty` — guard `ids.isEmpty`

#### Adaptations tests screen

- `buildApp()` : 2 overrides additionnels (`exchangeRateListProvider`, `dashboardNotifierProvider`) via mock notifiers
- Assertions headers : `find.text('EN RETARD')` / `find.text('À VENIR')` (remplacent les badges inline supprimés)

### Analyse statique

```
flutter analyze lib/src/features/recurring/ lib/src/utils/relative_date_formatter.dart
→ No issues found!
```

### Validation manuelle recommandée

1. Ouvrir l'écran Récurrences avec des récurrences dans les 3 statuts → vérifier les 3 groupes colorés
2. Vérifier la monthly summary en haut (bilan net + charges)
3. Vérifier le bouton "Tout payé" uniquement sur "EN RETARD"
4. Taper "Tout payé" → spinner → toutes les récurrences validées → groupe disparaît
5. Taper une ligne → action sheet avec résumé (fréquence uppercase, montant large, date relative)
6. Taper "Désactiver" → désactivation directe sans AlertDialog
7. État vide → `EmptyStateWidget` avec icône repeat
8. État erreur → `EmptyStateWidget` avec bouton Réessayer
9. Loading → skeleton 5 items avec icônes cercle

---

## Notes de review post-implémentation

La review post-implémentation (devflow-review, 2026-05-21) a produit un verdict **PASS** avec 0 constat bloquant.

Points mineurs identifiés (non bloquants) :
- W-001 : montant action sheet en `semiBold` au lieu de `bold` (1 ligne à corriger si alignement strict souhaité)
- W-003 : SnackBar "Tout payé" affiche "Transaction créée" au lieu d'un message avec count (`"{N} transaction(s) validée(s)"`)
- I-003 : clé l10n `recurringDeactivateConfirm` orpheline (AlertDialog supprimé), nettoyage différé
