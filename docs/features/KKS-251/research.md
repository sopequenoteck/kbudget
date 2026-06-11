# Research — KKS-251 : Récurrences liste Flutter (alignement DESIGN.md v5)

**Issue** : KKS-251 | **Branche** : `develop`  
**Phase** : Research  
**Date** : 2026-05-21  
**Statut** : Complété

---

## Vue d'ensemble

Analyse des inconnues techniques pour l'alignement de `RecurringListScreen` sur DESIGN.md v5 / Angular v5.
La stack est entièrement connue (Flutter + Riverpod + Freezed + intl). Les principales décisions portent sur :
5 inconnues résolues ci-dessous. Aucune nouvelle dépendance requise.

---

## Inconnues techniques

### IT-001 — `RelativeDateFormatter.formatCompact()` : délégation vs réimplémentation

**Contexte** : NFR-002 demande d'ajouter `formatCompact(DateTime)` à `lib/src/utils/relative_date_formatter.dart`. La spec dit "délègue à `format()`" pour today/hier/demain. Mais `format()` retourne "Aujourd'hui" / "Hier" / "Demain" (majuscules) — incompatibles avec le contexte d'usage `"fréquence · aujourd'hui"` (minuscule).

**Alternatives analysées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Déléguer + `.toLowerCase()` | Moins de code | Couplage fragile, transforme "il y a X jours" → "il y a x jours" non désiré | ❌ |
| B — Réimplémenter les 6 cas dans `formatCompact()` | Lisible, autonome, pas de couplage | ~15 lignes supplémentaires | ✅ |
| C — Nouveau fichier `date_formatter.dart` | Séparation claire | Viole Constitution Principe III (YAGNI) — déjà rejeté en clarify Q-003 | ❌ |

**Décision : Option B**  
`formatCompact()` réimplémente les 6 cas indépendamment dans `relative_date_formatter.dart` :

```
today   → "aujourd'hui"
hier    → "hier"
demain  → "demain"
passé 2-7j  → "il y a X j."  (abrégé vs "il y a X jours" de format())
futur 2-30j → "dans X j."    (nouveau — absent de format())
futur >30j  → DateFormat('dd MMM', 'fr').format(date)  (compact, sans année)
```

**Rationale** : format() gère dates passées et la casse "Aujourd'hui". formatCompact() a un contrat distinct (tout minuscule, futur court, format compact distant). Déléguer créerait une transformation fragile. ~15 lignes, pas de nouveau fichier.

---

### IT-002 — Couleur de fond du groupe : `ListGroup` vs `Container` inline

**Contexte** : FR-008 spécifie que chaque groupe de récurrences doit être dans un `Container(color: colorScheme.surface, ...)`. Le widget `ListGroup` (common_widgets) existe mais utilise `colorScheme.surfaceContainer`.

**Alternatives analysées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `ListGroup` tel quel | Réutilisation | `surfaceContainer` ≠ `surface` (tokens distincts, diverge de FR-008) | ❌ |
| B — Modifier `ListGroup` pour paramétrer la couleur | Flexible | Breaking change sur 2+ screens existants (debts, subscriptions utilisent `ListGroup`) | ❌ |
| C — `Container` inline dans `RecurringListScreen` | Respect exact de FR-008 | Duplication partielle de la logique divider | ✅ |

**Décision : Option C**  
`Container` inline avec `clipBehavior: Clip.antiAlias`, `BorderRadius.circular(AppRadius.xl)`, `color: colorScheme.surface`. Divider entre items : `Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant)`. Pattern identique au code `debt_list_screen.dart` qui construit ses sections inline.

**Rationale** : `colorScheme.surface` et `colorScheme.surfaceContainer` sont des niveaux d'élévation distincts dans Material 3 — les confondre casserait la hiérarchie visuelle. `ListGroup` sert les autres features, ne pas modifier son contrat.

---

### IT-003 — Nouvelles clés l10n et mises à jour des clés existantes

**Contexte** : L'action sheet redessinée (US3) utilise des labels plus longs ("Marquer comme payée" vs "Valider") et de nouveaux UI elements (bouton "Tout payé", monthly summary) nécessitent de nouvelles clés. L'application n'a qu'un fichier ARB (`app_fr.arb`).

**Audit des usages** (`grep -rn "recurringValidate\|recurringSkip\|recurringDeactivate"`) :
Les 3 clés existantes sont uniquement utilisées dans `recurring_list_item.dart` et `recurring_list_screen.dart` — aucun autre screen.

**Décisions par clé** :

| Clé ARB | Action | Valeur actuelle → Nouvelle valeur |
|---------|--------|-----------------------------------|
| `recurringValidate` | Mise à jour valeur | `"Valider"` → `"Marquer comme payée"` |
| `recurringSkip` | Mise à jour valeur | `"Passer"` → `"Passer cette occurrence"` |
| `recurringDeactivate` | Mise à jour valeur | `"Désactiver"` → `"Désactiver la récurrence"` |
| `recurringValidateAll` | Nouvelle clé | `"Tout payé"` |
| `recurringNextOccurrence` | Nouvelle clé | `"Prochaine : {date}"` (ICU paramètre `date`) |
| `recurringMonthlySummaryTitle` | Nouvelle clé | `"BILAN MENSUEL"` |
| `recurringChargesCount` | Nouvelle clé | `"{count} CHARGES"` (ICU paramètre `count`) |

**Chaîne validateAll success** : interpolation Dart inline `"${ids.length} transaction${ids.length > 1 ? 's' : ''} validée${ids.length > 1 ? 's' : ''}"`. Pas de clé ARB (YAGNI — aligne sur le pattern Angular qui construit aussi cette chaîne en TS).

**Après modification ARB** : relancer `flutter gen-l10n` (génère `app_localizations_fr.dart` + `app_localizations.dart`).

**Rationale** : Mettre à jour les valeurs existantes (plutôt qu'ajouter `recurringValidateAction` etc.) est plus propre car les 3 clés sont scopées à 1 seule feature. Les pluriels ICU pour `recurringChargesCount` et `recurringNextOccurrence` via le paramètre formel ARB sont la convention du projet.

---

### IT-004 — Structure de scroll : `ListView` vs `CustomScrollView + Slivers`

**Contexte** : L'écran actuel utilise `RefreshIndicator + ListView.builder`. La nouvelle version doit afficher une `_MonthlySummaryCard` en tête de liste, des headers de groupes, et des cartes de groupes — une structure non-homogène incompatible avec un `ListView.builder` pur.

**Alternatives analysées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `ListView` avec items hétérogènes (if/switch) | Simple | Complexité conditionnelle dans `itemBuilder` ; anti-pattern | ❌ |
| B — `CustomScrollView + SliverToBoxAdapter + SliverList` | Propre, extensible | Légère migration depuis `ListView.builder` | ✅ |
| C — `Column` dans `SingleChildScrollView` | Très simple | Pas de lazy loading — OK pour ~20 items max | Acceptable |

**Décision : Option B**  
`CustomScrollView + Slivers`, cohérent avec `debt_list_screen.dart` et `subscription_list_screen.dart` (pattern codebase confirmé). Structure :

```
CustomScrollView
  ├── SliverToBoxAdapter → _MonthlySummaryCard (si liste non vide)
  ├── SliverToBoxAdapter → _StatusGroupSection("EN RETARD") + carte groupe
  ├── SliverToBoxAdapter → _StatusGroupSection("AUJOURD'HUI") + carte groupe
  └── SliverToBoxAdapter → _StatusGroupSection("À VENIR") + carte groupe
```

`RefreshIndicator` enveloppe `CustomScrollView` (pattern identique debt/subscription).

**Rationale** : Cohérence codebase (`debt_list_screen`, `subscription_list_screen` utilisent `CustomScrollView`). Évite la logique conditionnelle dans `itemBuilder`. La monthly summary card est une `SliverToBoxAdapter` naturelle.

---

### IT-005 — Icône `pause` dans l'action sheet (vérification package)

**Contexte** : FR-012 spécifie `PhosphorIconsRegular.pause` pour le bouton "Désactiver" (correction de l'actuel `.x`). Cette icône n'est pas utilisée dans le projet actuellement — vérifier sa disponibilité.

**Vérification** :
```
grep "pause" ~/.pub-cache/hosted/pub.dev/phosphor_flutter-2.1.0/lib/src/phosphor_icons_regular.dart
# → static const pause = PhosphorFlatIconData(0xe39e, 'Regular'); ✓
```

**Décision** : Utiliser `PhosphorIconsRegular.pause` — disponible dans `phosphor_flutter: ^2.1.0`. Pas de risque de compilation.

**Rationale** : Vérification directe dans le package installé. Aucune mise à jour de dépendance requise.

---

## Décisions d'architecture

### Aucune nouvelle dépendance

Toutes les capacités nécessaires existent :

| Capacité | Composant existant | Localisation |
|----------|-------------------|-------------|
| Formatage date relatif compact | `RelativeDateFormatter` (extension) | `lib/src/utils/relative_date_formatter.dart` |
| Conversion devises | `CurrencyConverter.convert()` | `lib/src/utils/currency_converter.dart` |
| Taux de change | `exchangeRateListProvider` | `features/exchange_rates/application/` |
| Devise primaire | `dashboardNotifierProvider.currencies.first` | `features/dashboard/application/` |
| État vide / erreur | `EmptyStateWidget` | `common_widgets/empty_state_widget.dart` |
| Skeleton loading | `shimmer` (déjà dépendance) | `pubspec.yaml` |
| Icônes | `PhosphorIconsRegular` (pause, check, skipForward) | `phosphor_flutter: ^2.1.0` |

### Dépendances screen ajoutées

`RecurringListScreen` devra importer :
- `exchangeRateListProvider` (IT-004 : monthly summary)
- `dashboardNotifierProvider` (IT-004 : primaryCurrency)
- `AppThemeExtension` (couleurs income/expense)
- `EmptyStateWidget` (FR-014, FR-015)
- `CurrencyConverter` (FR-010)
- `AmountFormatter` (montants monthly summary)
- `RelativeDateFormatter` (FR-003 : sous-titre ligne + action sheet)

Ces imports sont tous présents dans `debt_list_screen.dart` — pattern exact à suivre.

### Fichiers modifiés

| Fichier | Nature de modification |
|---------|----------------------|
| `lib/src/features/recurring/presentation/recurring_list_screen.dart` | Refonte complète (US1+US2+US3) |
| `lib/src/features/recurring/presentation/widgets/recurring_list_item.dart` | Interface réduite à `onTap`, suppression `Dismissible`/`_StatusBadge`/`_SwipeBackground` |
| `lib/src/features/recurring/presentation/widgets/recurring_list_skeleton.dart` | 6→5 items, icône carré→cercle, badge→absent côté droit |
| `lib/src/features/recurring/application/recurring_list_notifier.dart` | Ajout `validateAll(List<String> ids)` |
| `lib/src/utils/relative_date_formatter.dart` | Ajout `formatCompact(DateTime)` |
| `lib/src/localization/app_fr.arb` | 3 mises à jour valeurs + 4 nouvelles clés |
| `lib/src/localization/app_localizations_fr.dart` | Régénéré via `flutter gen-l10n` |
| `lib/src/localization/app_localizations.dart` | Régénéré via `flutter gen-l10n` |
| `test/src/features/recurring/presentation/recurring_list_screen_test.dart` | Adaptation + nouveaux tests |
| `test/src/features/recurring/application/recurring_list_notifier_test.dart` | Ajout tests `validateAll` |

### Fichiers NON modifiés (confirmé)

- `RecurringTransaction` (domain model) — aucune modification
- `RecurringStatus` (enum) — aucune modification  
- `RecurringTransactionRepository` (interface + implémentations) — aucune modification
- `ListState<T>` (générique Freezed) — aucune modification
- `CurrencyConverter` — réutilisé tel quel
- `exchangeRateListProvider` — réutilisé tel quel
- `ListGroup` — non utilisé dans cette feature (IT-002)

---

## Risques identifiés

| Risque | Probabilité | Impact | Mitigation |
|--------|------------|--------|------------|
| `app_localizations_fr.dart` est généré et ne doit pas être modifié manuellement | Certain (pattern connu) | Faible | Modifier uniquement `app_fr.arb`, puis `flutter gen-l10n` |
| Test `should_show_recurring_items_sorted` vérifie les badges `_StatusBadge` ("En retard", "À venir") — ces badges sont supprimés | Certain | Moyen | Adapter le test pour vérifier les headers de groupe à la place |
| `validateAll` séquentiel : si 10+ items overdue, latence perceptible | Faible | Faible | Dans le scope accepté (ASS-002 : pas d'endpoint bulk). UX : bouton désactivé pendant l'opération |

---

## Conclusion

Aucune inconnue bloquante. Toutes les décisions techniques sont prises :

1. **`formatCompact()`** : réimplémenter indépendamment (6 cas, ~15 lignes)
2. **Groupe container** : `Container` inline avec `colorScheme.surface` (pas `ListGroup`)
3. **L10n** : 3 mises à jour + 4 nouvelles clés + régénération ARB
4. **Structure scroll** : `CustomScrollView + SliverToBoxAdapter` (cohérence debt/subscription)
5. **Icône pause** : disponible dans `phosphor_flutter ^2.1.0` ✓

Aucune nouvelle dépendance. Aucun changement sur les couches data/domain. Prêt pour `/devflow.plan`.
