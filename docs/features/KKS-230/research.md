# Research — KKS-230 Autocomplete sur le champ libellé de saisie des transactions

**Date** : 2026-04-13
**Spec** : `docs/features/KKS-230/spec.md`
**Clarify** : `docs/features/KKS-230/clarify-log.md`
**Constitution** : v2.1.1 (7 principes)

## Résumé

La majorité des inconnues UX/fonctionnelles ont été tranchées en `/devflow.clarify` (5 points, FR-015 à FR-018). Ce document traite les **inconnues techniques restantes**, vérifiées par lecture du codebase.

| # | Inconnue | Catégorie | Décision |
|---|----------|-----------|----------|
| R1 | Nom réel du champ : `label` vs `libelle` | Modèle | `libelle` (entité existante) — endpoint nommé `/api/transactions/libelles` |
| R2 | Requête SQL agrégation + `unaccent` | Backend | Native query JPQL/SQL sur `TransactionRepository`, `GROUP BY libelle` avec `unaccent` |
| R3 | Extension PostgreSQL `unaccent` | Infra | Activée via `V27__enable_unaccent_extension.sql` |
| R4 | Index supplémentaire pour perf | Backend | Aucun index additionnel en v1 — mesurer avant d'ajouter |
| R5 | Longueur max du champ `libelle` | Modèle | 255 par défaut Hibernate — pas de modification |
| R6 | Composant autocomplete Angular (localisation, pattern) | Frontend | Composant partagé dans `app/src/app/shared/components/autocomplete/` |
| R7 | Widget autocomplete Flutter | Frontend | `RawAutocomplete` de Flutter (stylable) — pas de dépendance ajoutée |
| R8 | DTO réponse endpoint | Backend | `ResponseEntity<List<String>>` direct (confirmé par clarify) |

---

## R1 — Nom du champ : `label` vs `libelle`

### Contexte
La spec parle systématiquement du champ « label », mais l'entité existante utilise `libelle` (FR).

### Vérification codebase
`api/src/main/java/fr/kksdev/budget/api/model/Transaction.java:34`
```java
@Column(nullable = false)
private String libelle;
```

Aucun champ `label` n'existe sur `Transaction`.

### Décision
- **Endpoint** : `GET /api/transactions/libelles` (cohérent avec le vocabulaire du domaine existant — le projet utilise le français dans les entités : `libelle`, `montant`, `categorie`).
- **Paramètres** : `q`, `limit` (inchangés).
- **Réponse** : `List<String>` de libellés distincts.
- **Spec** : à corriger en `/devflow.plan` ou en annotation dans le plan (les FR-001/FR-017 parlent de `label` → à remplacer par `libelle`).

### Rationale
Respecter le vocabulaire existant évite un renommage partiel incohérent. Le champ `libelle` est utilisé dans tout le back (repo, service, DTO `TransactionResponse`) et dans les fronts. Renommer juste pour l'endpoint ajouterait une traduction mentale inutile.

### Alternatives rejetées
| Option | Avantage | Inconvénient | Score |
|--------|----------|--------------|-------|
| `/api/transactions/labels` | Anglais "REST-idiomatic" | Incohérent avec `libelle` partout ailleurs | ❌ |
| Renommer `libelle` → `label` sur l'entité | Homogénéisation anglaise | Hors scope feature + migration SQL + impact massif | ❌ |
| `/api/transactions/libelles` | Cohérence domaine | Anglicisme abandonné | ✅ Retenu |

---

## R2 — Requête d'agrégation

### Contexte
FR-004 exige tri par fréquence puis date de dernière utilisation. FR-017 exige filtre `contains` case-insensitive + accent-insensible via `unaccent`.

### Décision
Native query sur `TransactionRepository` :

```sql
SELECT t.libelle
FROM transactions t
WHERE t.user_id = :userId
  AND (:q IS NULL OR LOWER(UNACCENT(t.libelle)) LIKE '%' || LOWER(UNACCENT(:q)) || '%')
GROUP BY t.libelle
ORDER BY COUNT(*) DESC, MAX(t.date) DESC
LIMIT :limit
```

- Déclarée avec `@Query(value = "...", nativeQuery = true)` sur `TransactionRepository`.
- `limit` paramétrable (défaut 20, max 50).
- Validation `limit` côté service (clamp `[1, 50]`).

### Rationale
- JPQL ne supporte pas `UNACCENT` → native query obligatoire.
- `GROUP BY libelle` sans normalisation : on garde la casse exacte pour l'affichage ("Carrefour" reste "Carrefour"), seule la comparaison est normalisée.
- `COUNT(*) DESC, MAX(date) DESC` couvre FR-004 en un seul passage DB.

### Alternatives rejetées
| Option | Avantage | Inconvénient |
|--------|----------|--------------|
| JPQL `LOWER()` sans `unaccent` | Pas de dépendance extension | Casse FR-017 (accent-insensible) |
| Chargement complet en mémoire puis agrégation Java | Simple | Casse NFR-001 (< 100ms) à 10k transactions |
| Vue matérialisée `libelles_par_user` | Performance | YAGNI (constitution #3), maintenance, invalidation |
| Table `transaction_labels` agrégée mise à jour par trigger | Ultra rapide | Hors scope (spec interdit entité dédiée) |

---

## R3 — Extension PostgreSQL `unaccent`

### Contexte
Vérification `api/src/main/resources/db/migration/` : dernière migration `V26__drop_shop.sql`. Aucune migration n'active `unaccent` ou `pg_trgm`.

### Décision
Créer `V27__enable_unaccent_extension.sql` :

```sql
CREATE EXTENSION IF NOT EXISTS unaccent;
```

### Rationale
- `unaccent` fait partie de `postgresql-contrib`, standard sur toutes les distributions et Postgres managés (RDS, Supabase, Neon).
- `IF NOT EXISTS` rend la migration idempotente, sans effet de bord en dev/test.
- `V27` est le prochain numéro disponible (V24, V25 absents du repo mais V26 est la dernière ; vérifier au moment de l'implémentation et prendre le numéro disponible suivant).

### Vérification self-hosted
Constitution #7 : la dépendance infra reste PostgreSQL seule. `unaccent` est une extension du serveur existant, pas un nouveau service — contrainte respectée.

### Alternatives rejetées
| Option | Raison rejet |
|--------|--------------|
| `pg_trgm` + index GIN trigram | Plus lourd, inutile au volume attendu (< 10k / user) |
| Normalisation côté Java (Normalizer NFD) au runtime | Impossible avec filtre SQL `LIKE` sur colonne non normalisée — forcerait un full scan Java |
| Colonne dénormalisée `libelle_normalized` | Migration de schéma + trigger → hors scope YAGNI |

---

## R4 — Stratégie d'index

### Contexte
NFR-001 impose < 100ms sur 10 000 transactions pour un utilisateur. Index existants sur `transactions` :
- `idx_transactions_user_id` sur `(user_id)` — `V1__init_schema.sql:43`
- `idx_transactions_debt_id` — non pertinent ici

### Décision
**Aucun index additionnel en v1.** L'index `(user_id)` suffit pour cadrer le scan à ~10k lignes maximum ; l'agrégation `GROUP BY libelle` sur 10k lignes s'exécute en général en < 20ms sur PostgreSQL moderne.

**Plan de contingence** : si NFR-001 n'est pas tenu en test de perf, évaluer dans cet ordre :
1. Index composite `(user_id, libelle)` — coût faible, pas d'extension.
2. Index GIN `pg_trgm` sur `LOWER(UNACCENT(libelle))` — si le filtre `contains` reste lent.

Ces options sont à envisager dans `/devflow.plan` ou en phase d'optimisation post-merge, pas maintenant.

### Rationale
YAGNI (constitution #3) : pas d'index préventif sans mesure. Le coût d'un index = ralentissement des writes + espace disque ; il doit être justifié par une mesure.

---

## R5 — Longueur max du champ `libelle`

### Contexte
A2 de la spec : vérifier la taille max du champ.

### Vérification
`Transaction.java:34` : `@Column(nullable = false) private String libelle;` — pas d'attribut `length`. Hibernate applique la valeur par défaut `varchar(255)`.

### Décision
Conserver 255. Côté DTO de requête (si applicable pour `q`) : `@Size(max = 255)` pour cohérence. Côté affichage (FR-016) : troncature à l'affichage via ellipsis CSS/widget, valeur complète conservée à la sélection (edge case déjà spec).

---

## R6 — Composant autocomplete Angular

### Contexte
FR-018 : composant maison, pas de `@angular/material`. Signals-first obligatoire (CLAUDE.md).

### Vérification codebase
- Formulaire existant : `app/src/app/features/transactions/components/transaction-form/transaction-form.ts` (à greffer dessus).
- Convention « lib-first » (CLAUDE.md global) : composants réutilisables dans une lib projet. Pour Angular, le dossier partagé du projet est `app/src/app/shared/components/`.

### Décision
- **Localisation** : `app/src/app/shared/components/autocomplete/autocomplete.ts` + SCSS associé.
- **API** (signals-first) :
  - `input<string>()` valeur (two-way via `model()`)
  - `input<string[]>()` suggestions
  - `input<number>('minChars', 2)` seuil (FR-015)
  - `input<number>('maxDisplay', 5)` troncature (FR-016)
  - `output<string>()` `queryChange` (émis avec debounce par le parent ou en interne via `debouncedSignal`)
  - `output<string>()` `selected`
- **Pattern** :
  - Input natif `<input>` + overlay absolu (pas de CDK Overlay — stack minimal).
  - Navigation clavier : `keydown` sur input → gère `ArrowUp/Down/Enter/Escape`.
  - ARIA : `role="combobox"` sur input, `role="listbox"` sur overlay, `aria-activedescendant` sur l'option focalisée, `aria-expanded`, `aria-autocomplete="list"`.
  - `ChangeDetectionStrategy.OnPush`.
  - Fermeture sur clic extérieur via `HostListener('document:click')` ou `@HostListener` avec `event.target` test de containment.
- **Debounce** : `toSignal` sur un `Subject<string>` piped avec `debounceTime(200)` + `distinctUntilChanged`. RxJS autorisé car opérateur asynchrone (CLAUDE.md).
- **Style** : tokens DESIGN.md uniquement (patterns list + overlay/bottom-sheet si applicable au mobile).

### Rationale
Composant réutilisable → `shared/components/` suit les conventions du projet. Approche input natif + overlay absolu = le strict nécessaire, aucune nouvelle dépendance.

### Alternatives rejetées
| Option | Rejet |
|--------|-------|
| `@angular/material` `mat-autocomplete` | FR-018 interdit, dépendance massive |
| CDK `Overlay` (`@angular/cdk`) | Pas utilisé ailleurs dans le projet → éviter nouvelle dépendance |
| Composant dédié dans `features/transactions/` | Moins réutilisable ; d'autres champs libres (notes ? catégories free-text ?) bénéficieront du pattern |

### À vérifier en `/devflow.plan`
- Le projet a-t-il déjà un pattern overlay/bottom-sheet réutilisable (`_bottom-sheet.scss` mentionné dans CLAUDE.md) ? Si oui, le mobile pourrait ouvrir l'autocomplete en bottom-sheet plutôt qu'en overlay (meilleur mobile-first).

---

## R7 — Widget autocomplete Flutter

### Contexte
FR-008 : composant équivalent côté Flutter. Formulaire existant : `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart`.

### Décision
Utiliser **`RawAutocomplete<String>`** du SDK Flutter (package `flutter/material.dart`, pas de dépendance ajoutée).

- `RawAutocomplete<String>` permet un `optionsViewBuilder` entièrement custom → stylable via `AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`, `AppShadows` (CLAUDE.md).
- `optionsBuilder` : appel repository → `List<String>` suggestions distantes (accompagné d'un debounce Dart de 200ms via `Timer` dans un `StateProvider` ou `Notifier` dédié).
- Seuil 2 caractères → `optionsBuilder` retourne liste vide si `textEditingValue.text.length < 2`.
- Troncature à 5 → `.take(5)` dans `optionsBuilder`.
- Data source : nouveau `Provider` `libelleSuggestionsProvider.family(query)` qui délègue au `TransactionRepository` (pattern existant : repo abstrait + impl local/remote, bascule via `dataModeProvider`).

### Rationale
`RawAutocomplete` est dans Flutter SDK, aucune dépendance ajoutée (constitution #7). Équivalent Material `Autocomplete<String>` apporte un style imposé qu'on ne peut pas totalement piloter — on perd les tokens AppX. `RawAutocomplete` laisse toute liberté de styling.

### Alternatives rejetées
| Option | Rejet |
|--------|-------|
| `Autocomplete<String>` (Material) | Styling partiel imposé, moins aligné tokens |
| Widget 100% maison | Réinvente clavier/focus management inutilement |
| Package `flutter_typeahead` | Nouvelle dépendance externe, YAGNI |

### À vérifier en `/devflow.plan`
- Le `TransactionRepository` Flutter (abstrait) doit recevoir une méthode `getLibelleSuggestions(query, limit)`.
- Implémentation `RepositoryLocal` (Drift) : `SELECT libelle FROM transactions WHERE user_id = ? GROUP BY libelle ORDER BY COUNT(*) DESC, MAX(date) DESC` — attention : Drift ne gère pas `unaccent`, filtre accent-insensible à faire en Dart (Normalizer/`removeDiacritics`). Package `diacritic` déjà présent ? À vérifier. Sinon normalisation manuelle sur chaînes courtes.
- Implémentation `RepositoryRemote` (Dio) : appel `GET /api/transactions/libelles?q=...&limit=20`.

---

## R8 — DTO réponse endpoint

### Contexte
Question A3 de la spec, déjà tranchée au clarify.

### Vérification
`TransactionController.java` retourne déjà `ResponseEntity<List<TransactionResponse>>` et `ResponseEntity<List<MonthlySummaryResponse>>` — pattern confirmé pour collections.

### Décision
`ResponseEntity<List<String>>` direct, aucun DTO wrapper. Aligné avec les conventions des autres controllers (`AccountController`, `BankController`, `BudgetController`).

### Rationale
YAGNI. Un wrapper `LabelSuggestionResponse { List<String> values }` n'apporte rien tant qu'aucun métadonnée supplémentaire (pagination, total…) n'est requise.

---

## Nouvelles dépendances

| Type | Dépendance | Source | Impact |
|------|-----------|--------|--------|
| Extension Postgres | `unaccent` | `postgresql-contrib` (standard) | Migration `V27__enable_unaccent_extension.sql` |
| Lib Java | — | — | Aucune |
| Lib npm Angular | — | — | Aucune |
| Lib pub.dev Flutter | — (éventuellement `diacritic` à vérifier) | — | À confirmer en plan |

Constitution #7 : respecté — pas de nouveau service infra.

---

## Points à clarifier en `/devflow.plan`

1. **Numéro de migration Flyway** : prendre le prochain disponible (V27 ou suivant selon l'état du repo au moment de l'implémentation).
2. **Naming endpoint final** : `/api/transactions/libelles` ou confirmer cette forme avec l'utilisateur (correction du spec FR-001).
3. **Pattern overlay Angular vs bottom-sheet mobile** : vérifier `_bottom-sheet.scss` existant pour harmonisation mobile.
4. **Package `diacritic` Flutter** : présent ou à ajouter ? Si nouvelle dépendance, discuter avec l'utilisateur (constitution #7).
5. **Debounce signals-first Angular** : valider le pattern `Subject + toSignal` ou utiliser une utility existante du projet (`app/src/app/shared/utils/` s'il en existe une).

Ces points n'empêchent pas de démarrer le plan — ce sont des choix d'implémentation fine.
