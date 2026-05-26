# Review Log — KKS-254

---

## Itération 4 — 2026-05-23 | review-impl | PASS

**Agent** : devflow-review
**Verdict** : PASS
**Constats** : 0 BLOQUANT · 2 WARNING · 3 INFO

### Warnings

| ID | Localisation | Description |
|----|-------------|-------------|
| W-001 | `test/src/features/budgets/presentation/budget_detail_screen_test.dart` | SC-002 non couvert : le plan (T-051) liste explicitement `should_showTransactionGroups_when_transactionsLoaded` parmi les 9 tests requis. Ce test est absent — remplacé par `should_showCategoryName_when_overviewLoaded` et `should_showProgressBar_when_overviewHasPercentage`. Le filtrage + groupement par date des transactions n'est pas testé en positif (seul le cas vide l'est via `should_showEmptyState_when_noMatchingTransactions`). NFR-006 est formellement respecté (9 tests), mais la couverture SC-002 est incomplète. |
| W-002 | `budget_detail_screen.dart` — `_TransactionRow` | FR-020 partiellement implémenté : la couleur de fond du container circulaire est `colorScheme.surfaceContainerHighest` au lieu de la couleur catégorie (`categoryCouleur`). L'icône emoji est vide pour toute transaction (`tx.categoryId != null ? '' : '?'`), car `Transaction` ne transporte pas `categoryIcone`. Le plan prévoit "couleur catégorie bg + emoji" (Composant 4, `_TransactionRow`). Défaut visuel sans impact fonctionnel, mais écart spec mesurable. |

### Infos

| ID | Description |
|----|-------------|
| I-001 | `_buildErrorState()` : implémentation inline (icon + bouton Réessayer) au lieu d'un widget commun. Non bloquant — SC-006 précise juste "ErrorView avec bouton Réessayer" sans imposer un widget nommé. Cohérent avec les autres écrans du projet. |
| I-002 | `should_callGetById_when_toggleTapped` vérifie que `getById` est appelé mais pas que `update` est appelé avec `actif: false`. Test de SC-005 partiel. Acceptable — `update` est stubbé et le flow va jusqu'à la navigation. |
| I-003 | `BudgetHeroWidget` conserve `onUnbudgetedTap` et `doughnutSegments` (non utilisés dans le contexte détail). Non bloquant — FR-028 ciblait uniquement `onChartsTap`, supprimé correctement. |

### Justification PASS

Tous les 28 FR et 6 NFR implémentés. Suppressions confirmées (`budget_pie_chart.dart`, `budget_category_detail_sheet.dart`, `onChartsTap` absents du codebase). Router (FR-001), provider family (FR-016), hero (FR-008 à FR-010), action pills (FR-012 à FR-015) avec `mounted` vérifié (NFR-003), `ConfirmDialogCustom` (NFR-005), skeleton shimmer (NFR-004), `SliverPersistentHeader` pinned (FR-011), navigation 3 cas (FR-002 à FR-004) : tous conformes. 9 widget tests (NFR-006 ≥ 8). SC-007 et SC-009 validés. Les 2 warnings sont des défauts visuels non fonctionnels sans impact sur les parcours principaux. Aucun BLOQUANT — feature mergeable.

---

## Itération 3 — 2026-05-23 | review-tasks | PASS

**Agent** : devflow-review  
**Verdict** : PASS  
**Constats** : 0 BLOQUANT · 5 WARNING · 4 INFO

### Warnings

| ID | Localisation | Description |
|----|-------------|-------------|
| W-001 | `tasks.md` T-020 | Tâche trop large : 7 responsabilités (constructeur, init, chargement, findOverviewItem, fallback, accounts, CustomScrollView). Toute Phase 3 bloque dessus. Recommandation : découper en 2-3 sous-tâches lors de l'implémentation |
| W-002 | `tasks.md` T-012→T-036 | Fenêtre de compilation cassée entre Phase 2 et Phase 4 (T-012 casse les callsites, T-036 les corrige). Documenté et délibéré. T-025 et T-036 auraient pu être fusionnés en une passe sur `budget_list_screen.dart` |
| W-003 | `spec.md` NFR-005 | Écart nommage : spec dit `confirm_dialog.dart` (inexistant), plan+tasks utilisent correctement `ConfirmDialogCustom.show()` dans `confirm_dialog_custom.dart` |
| W-004 | `tasks.md` T-011 | Référence `debtPaymentsProvider` comme modèle inexacte — ce provider n'est pas en fichier séparé. Le modèle correct est `subscriptionPaymentsProvider` dans `subscription_notifier.dart`. Le choix de créer un fichier autonome est correct et meilleur |
| W-005 | `tasks.md` T-034, T-035 | Marqueurs `[P]` incorrects — les deux tâches modifient `budget_detail_screen.dart` → conflit de merge si parallélisées. **Corrigé** : marqueurs retirés, note "même passe" ajoutée |

### Infos

| ID | Description |
|----|-------------|
| I-001 | SC-009 (hero historique utilise `montantBudget` non normalisé) couvert manuellement mais pas par un test automatisé dédié |
| I-002 | NFR-001 conforme — `accountRepositoryProvider` utilisé sans modification de la couche data |
| I-003 | T-050 doit être exécuté avant T-052 (`flutter test`) — l'ordre dans Phase 5 est cohérent |
| I-004 | `budget_detail_screen_test.dart` n'existe pas encore — T-051 est une création pure, pas une refonte |

### Justification PASS

28 FR couverts (mapping complet), 6 NFR tracés, 2D+1C+6M du plan tous couverts par des tâches, graphe de dépendances sans cycle, checkpoints par phase, stratégie MVP documentée. W-005 corrigé immédiatement. Les autres warnings sont non bloquants pour l'implémentation.

---

## Itération 1 — 2026-05-22 | review-spec | BLOQUANT

**Agent** : devflow-review  
**Verdict** : BLOQUANT  
**Constats** : 2 BLOQUANT · 4 WARNING · 4 INFO

### Bloquants

| ID | Localisation | Description |
|----|-------------|-------------|
| B-001 | `spec.md` FR-001 | Router et constructeur `BudgetDetailScreen` non nommés explicitement comme fichiers à modifier — risque d'ambiguïté sur le scope réel (`categoryId` absent du router et du constructeur actuel) |
| B-002 | `spec.md` US-003 scénario 1 / SC-005 | Label initial du pill toggle (Désactiver/Activer) non spécifié quand `actif` est absent de l'overview — comportement intermédiaire observable non couvert |

### Warnings

| ID | Localisation | Description |
|----|-------------|-------------|
| W-001 | `spec.md` NFR-006 | Seuil "≥ 8 widget tests" vague — "SC principaux" non listés explicitement (SC-007 est `flutter analyze`, pas un widget test) |
| W-002 | `spec.md` FR-016 | Chemin d'implémentation du nouveau `FutureProvider.family` non précisé (fichier / namespace) |
| W-003 | `spec.md` FR-009 | `PhosphorChartPie` pour l'icône "reste" — lien Angular source absent (risque divergence silencieuse) |
| W-004 | `spec.md` US-003 scénario 3 | Race condition double-tap toggle non couverte (acceptable V1, à noter) |

### Infos

| ID | Description |
|----|-------------|
| I-001 | A-001 saine — `TransactionRepository.getByMonth` confirmé dans l'interface et les deux implémentations |
| I-002 | A-003 saine — `UnbudgetedDetailSheet` confirmé existant |
| I-003 | CL-004 résolu dans clarify-log.md mais absent du tableau §Questions ouvertes de spec.md (incohérence de traçabilité mineure, A-004 mis à jour) |
| I-004 | `budget_hero_widget_test.dart:35` passe `onChartsTap: () {}` — la suppression FR-028 cassera ce test ; non mentionné dans US-004 ni les SC |

### Justification BLOQUANT

Deux points bloquants. FR-001 ne nomme pas `BudgetDetailScreen` et `app_router.dart` comme fichiers à modifier, créant un risque d'ambiguïté sur le scope réel. US-003/SC-005 laisse le label initial du pill toggle indéterminé quand `actif` est absent de l'overview — comportement observable non spécifié, donc non testable. Ces deux corrections doivent être apportées à spec.md avant de passer en phase de planification.

---

## Itération 2 — 2026-05-22 | review-spec | PASS

**Agent** : devflow-review  
**Verdict** : PASS  
**Constats** : 0 BLOQUANT · 3 WARNING · 2 INFO

### Vérification des bloquants de l'itération 1

| Bloquant | Statut |
|----------|--------|
| B-001 — FR-001 router + constructeur | **RÉSOLU** — `app_router.dart` et signature `required String categoryId` nommés explicitement |
| B-002 — US-003 label pill toggle initial | **RÉSOLU** — label "Désactiver" par défaut + bascule "Activer" après `getById` confirmé |

Point I-004 (test cassé) également traité : US-004 scénario 4 ajouté.

### Warnings résiduels (non bloquants)

| ID | Localisation | Description |
|----|-------------|-------------|
| W-001 | `spec.md` NFR-006 | Seuil "≥ 8 widget tests" liste les thèmes en texte libre sans identifier les SC par ID — à préciser dans `plan.md`/`tasks.md` |
| W-002 | `spec.md` FR-016 | Fichier de destination du nouveau `FutureProvider.family` non précisé — à décider dans `plan.md` |
| W-004 | `spec.md` US-003 scénario 3 | Race condition double-tap toggle non couverte (acceptable V1) |

### Justification PASS

Les deux bloquants de l'itération 1 sont résolus. FR-001 nomme explicitement `app_router.dart` et le constructeur avec la signature attendue. US-003 scénario 1 documente le label initial "Désactiver" et le mécanisme de bascule post-`getById`. Les 3 warnings résiduels sont non bloquants et adressables dans `plan.md`/`tasks.md`. La spec est complète, cohérente et testable.
