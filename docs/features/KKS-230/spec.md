# Feature Specification: Autocomplete sur le champ libellé de saisie des transactions

**Feature Branch**: `feature/KKS-230-autocomplete-libelle-transactions`
**Created**: 2026-04-13
**Status**: Draft
**Linear Issue**: [KKS-230](https://linear.app/kksdev/issue/KKS-230)
**Priority**: Medium (P2)
**Labels**: Frontend, Backend, Feature

## Contexte

La saisie d'une transaction impose aujourd'hui à l'utilisateur de retaper à chaque fois le libellé (nom du commerce, de la dépense ou du revenu). Cela génère de la friction et des variantes orthographiques accumulées ("Carrefour", "carrefour market", "CARREFOUR").

**Objectif recentré** : réduire la friction de saisie en proposant une autocomplete basée sur les libellés déjà saisis par l'utilisateur. **Pas d'hygiène de données** : aucune entité `Merchant`, aucune normalisation forcée, aucune fusion. YAGNI (constitution #3) — on n'introduit pas de structure tant qu'aucune feature aval ne la consomme.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Suggestions basées sur les libellés existants (Priority: P1)

En tant qu'utilisateur qui saisit une nouvelle transaction, je veux voir apparaître une liste de suggestions de libellés issues de mes transactions précédentes, afin de ne pas avoir à retaper à chaque fois les libellés que j'utilise régulièrement.

**Why this priority** : c'est le cœur de la valeur de la feature. Sans cette US, il n'y a rien. Elle constitue à elle seule un MVP fonctionnel livrable.

**Independent Test** : créer 5 transactions avec des libellés variés pour un utilisateur, ouvrir le formulaire de saisie d'une nouvelle transaction, taper les 2 premiers caractères d'un libellé existant dans le champ libellé → vérifier qu'au moins une suggestion correspondante apparaît.

**Acceptance Scenarios** :

1. **Given** un utilisateur avec au moins une transaction enregistrée contenant le libellé "Carrefour", **When** il tape "Ca" dans le champ libellé, **Then** "Carrefour" apparaît dans la liste des suggestions.
2. **Given** un utilisateur sans aucune transaction, **When** il tape 2 caractères dans le champ libellé, **Then** aucune suggestion n'est affichée et la saisie libre reste possible.
3. **Given** une liste de suggestions affichée, **When** l'utilisateur clique sur une suggestion, **Then** le champ libellé est rempli avec la valeur sélectionnée et la liste se ferme.
4. **Given** un utilisateur qui met simplement le focus sur le champ libellé sans taper, **When** le champ reste vide ou contient moins de 2 caractères, **Then** aucune liste de suggestions n'est affichée et aucune requête backend n'est émise.

---

### User Story 2 — Tri par fréquence d'usage (Priority: P1)

En tant qu'utilisateur, je veux que les libellés que j'utilise le plus souvent apparaissent en premier dans les suggestions, afin que les suggestions les plus pertinentes soient immédiatement accessibles sans scroll.

**Why this priority** : sans tri pertinent, la feature perd sa valeur dès qu'un utilisateur a 20+ libellés distincts. Le tri par fréquence est une attente implicite d'un bon autocomplete.

**Independent Test** : créer 10 transactions avec "Carrefour" et 2 transactions avec "Monoprix" pour un même utilisateur, ouvrir le formulaire → vérifier que "Carrefour" apparaît avant "Monoprix" dans la liste.

**Acceptance Scenarios** :

1. **Given** un utilisateur avec 10 transactions "Carrefour" et 2 transactions "Monoprix", **When** il affiche les suggestions, **Then** "Carrefour" apparaît en première position et "Monoprix" en seconde.
2. **Given** deux libellés utilisés le même nombre de fois, **When** les suggestions sont affichées, **Then** le libellé le plus récemment utilisé apparaît en premier.

---

### User Story 3 — Filtrage en cours de frappe (Priority: P2)

En tant qu'utilisateur, je veux que la liste de suggestions se filtre au fur et à mesure que je tape, afin de restreindre rapidement les choix à ce qui correspond à ma saisie.

**Why this priority** : améliore sensiblement l'ergonomie quand le nombre de libellés distincts est élevé, mais l'US1+US2 fournissent déjà un MVP utilisable sans filtrage dynamique.

**Independent Test** : avec un utilisateur ayant "Carrefour", "Carte bleue", "Cadeau" enregistrés, taper "Car" dans le champ libellé → vérifier que seuls "Carrefour" et "Carte bleue" restent affichés, "Cadeau" disparaît.

**Acceptance Scenarios** :

1. **Given** un utilisateur avec les libellés "Carrefour", "Carte bleue", "Cadeau", **When** il tape "Car" dans le champ, **Then** seuls "Carrefour" et "Carte bleue" restent visibles.
2. **Given** une saisie ne correspondant à aucun libellé existant, **When** l'utilisateur tape, **Then** la liste de suggestions se vide mais la saisie libre reste possible.
3. **Given** une saisie contenant des majuscules, **When** l'utilisateur tape "CARR", **Then** "Carrefour" (en minuscules mixtes) est proposé (filtre case-insensitive).

---

### User Story 4 — Saisie libre toujours possible (Priority: P1)

En tant qu'utilisateur, je veux pouvoir taper un libellé totalement nouveau sans contrainte, afin de ne pas être bloqué par les suggestions si ce que je veux saisir n'existe pas encore.

**Why this priority** : contrainte absolue — forcer une sélection briserait le workflow d'ajout de nouvelles dépenses. C'est une garantie de non-régression.

**Independent Test** : avec un utilisateur ayant des libellés existants, taper un libellé inédit "Nouveau commerce xyz" et valider le formulaire → vérifier que la transaction est créée avec exactement ce libellé.

**Acceptance Scenarios** :

1. **Given** un utilisateur avec des libellés existants, **When** il tape un libellé inédit et valide le formulaire, **Then** la transaction est créée avec le libellé exact tel que saisi.
2. **Given** une liste de suggestions ouverte, **When** l'utilisateur appuie sur Échap ou clique en dehors, **Then** la liste se ferme sans modifier le contenu du champ.

---

### User Story 5 — Isolation des suggestions par utilisateur (Priority: P1)

En tant qu'utilisateur, je veux ne jamais voir les libellés saisis par d'autres utilisateurs de l'application, afin que mes suggestions restent privées et pertinentes pour mes propres habitudes.

**Why this priority** : principe #2 de la constitution (sécurité par défaut, isolation des données). Non négociable.

**Independent Test** : créer deux utilisateurs A et B, saisir "LibelleAlpha" pour A et "LibelleBeta" pour B. Se connecter en tant que A et ouvrir le formulaire → vérifier que "LibelleBeta" n'apparaît jamais.

**Acceptance Scenarios** :

1. **Given** deux utilisateurs A et B avec des libellés distincts, **When** A affiche les suggestions, **Then** seules les libellés de A sont visibles.
2. **Given** un appel direct à l'endpoint `GET /api/transactions/libelles` sans JWT valide, **When** la requête est envoyée, **Then** le serveur répond 401 Unauthorized.

---

### Edge Cases

- **Aucune transaction existante** : l'utilisateur ouvre le formulaire pour la toute première fois → aucune suggestion, champ libre, aucun message d'erreur.
- **Libellés avec espaces, accents, caractères spéciaux** : "Café du coin", "L'épicerie" → conservés tels quels, filtrage case-insensitive et **accent-insensible** (taper "cafe" matche "Café"). Normalisation Unicode (NFD + suppression des diacritiques) appliquée uniquement au moment du filtre, jamais sur la donnée stockée.
- **Libellé très long (> 100 caractères)** : affichage tronqué dans la liste avec ellipsis, valeur complète conservée à la sélection.
- **Performance avec 10 000+ transactions** : la requête doit rester sous 100ms (voir NFR).
- **Suggestion sélectionnée puis modifiée manuellement** : l'utilisateur sélectionne "Carrefour" puis ajoute " Nanterre" → le libellé final est "Carrefour Nanterre" (nouvelle variante acceptée sans friction).
- **Latence réseau** : en cas de lenteur backend, aucun blocage du champ — l'utilisateur peut toujours taper et valider, les suggestions apparaissent quand disponibles.
- **Frappe rapide** : debounce ~200ms pour éviter de saturer le backend.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** : Le système MUST exposer un endpoint `GET /api/transactions/libelles` retournant la liste des libellés distincts existants pour l'utilisateur authentifié.
- **FR-002** : L'endpoint MUST accepter un paramètre optionnel `q` (query string) pour filtrer les libellés en mode case-insensitive.
- **FR-003** : L'endpoint MUST accepter un paramètre optionnel `limit` (défaut 20, maximum 50) pour borner le nombre de résultats.
- **FR-004** : Le système MUST trier les libellés retournés par fréquence d'usage décroissante, puis par date de dernière utilisation décroissante en cas d'égalité.
- **FR-005** : Le système MUST filtrer strictement les libellés par l'utilisateur authentifié (isolation des données, constitution #2).
- **FR-006** : L'endpoint MUST être protégé par JWT — toute requête non authentifiée MUST retourner 401.
- **FR-007** : Le frontend Angular MUST intégrer un composant autocomplete dans le formulaire de création/édition de transaction, connecté au champ libellé.
- **FR-008** : Le frontend Flutter MUST intégrer un composant autocomplete équivalent dans l'écran de saisie de transaction.
- **FR-009** : L'utilisateur MUST pouvoir saisir un libellé totalement nouveau, même si des suggestions sont affichées (saisie libre non bloquante).
- **FR-010** : L'utilisateur MUST pouvoir sélectionner une suggestion via clic (tous supports) et via navigation clavier (Angular : ↑↓ Enter Esc).
- **FR-011** : Le frontend MUST appliquer un debounce (~200ms) avant d'interroger le backend lors de la frappe.
- **FR-012** : Le frontend MUST effectuer un filtrage local additionnel sur les résultats reçus, avec les mêmes règles de normalisation que le backend : **case-insensitive** ET **accent-insensible** (normalisation Unicode NFD + suppression des diacritiques avant comparaison via `includes`). Aucune bibliothèque fuzzy externe.
- **FR-013** : Le backend MUST logger au niveau INFO les appels à l'endpoint `/api/transactions/libelles` (observabilité, constitution #6).
- **FR-014** : Le système MUST documenter l'endpoint dans Swagger UI avec exemples de requête/réponse.
- **FR-015** : Les suggestions s'affichent uniquement **après la saisie d'au moins 2 caractères** dans le champ libellé. Au focus seul (0 ou 1 caractère), aucune liste n'est affichée et aucune requête backend n'est émise.
- **FR-016** : Le nombre maximum de suggestions affichées côté UI est de **5** (sur Angular comme sur Flutter). Le backend peut en retourner jusqu'à 20 (défaut) ou 50 (max), le frontend tronque l'affichage à 5.
- **FR-017** : Le filtre `q` côté backend utilise une logique **`contains` case-insensitive et accent-insensible** (ex : "market" matche "Carrefour Market", "cafe" matche "Café du coin"). Implémentation PostgreSQL : `LOWER(UNACCENT(libelle)) LIKE '%' || LOWER(UNACCENT(:q)) || '%'` — nécessite l'extension `unaccent` (à activer via migration Flyway si non présente).
- **FR-018** : Le composant autocomplete Angular MUST être un composant **maison aligné sur le design system du projet** (DESIGN.md). **Pas de dépendance `@angular/material`** — le projet n'en utilise pas. Pattern : input natif + overlay absolu + navigation clavier signals-first.

### Non-Functional Requirements

- **NFR-001** : La réponse de l'endpoint `GET /api/transactions/libelles` MUST être < 100ms sur un dataset représentatif (10 000 transactions pour un même utilisateur).
- **NFR-002** : L'autocomplete MUST rester utilisable au pouce sur écran mobile (Mobile-First UX, constitution #4) — taille minimale des zones tactiles, lisibilité.
- **NFR-003** : L'interface Angular MUST respecter strictement le design system (DESIGN.md) — uniquement des tokens CSS, aucune valeur hardcodée.
- **NFR-004** : L'interface Flutter MUST utiliser les design tokens centralisés (AppColors, AppSpacing, AppTypography, AppRadius).
- **NFR-005** : L'autocomplete Angular MUST respecter les attributs ARIA (`aria-autocomplete`, `aria-expanded`, `role="listbox"`) pour l'accessibilité.
- **NFR-006** : Le backend MUST avoir des tests d'intégration couvrant : filtrage par user, tri par fréquence, filtrage case-insensitive, respect de la limite, protection JWT (401 si non authentifié).
- **NFR-007** : Les frontends MUST avoir des tests unitaires couvrant : sélection d'une suggestion, navigation clavier (Angular), debounce, saisie libre d'un libellé inédit.
- **NFR-008** : Aucune régression sur le formulaire de saisie existant — les champs autres que le libellé MUST rester inchangés dans leur comportement.

### Key Entities *(include if feature involves data)*

- **Transaction** (existante) : entité existante contenant le champ `libelle` (String). Aucune modification de schéma requise. La feature exploite les lignes existantes via une requête d'agrégation `GROUP BY libelle, user_id ORDER BY COUNT DESC, MAX(date) DESC`.
- **User** (existant) : entité utilisateur authentifié via JWT. Filtre obligatoire sur toutes les requêtes de suggestions.
- **Réponse endpoint** : ✅ tranchée le 2026-04-13 — la convention du projet est que les controllers retournent `ResponseEntity<List<X>>` directement pour les collections (vérifié dans `AccountController`, `BankController`, `BudgetController`). L'endpoint `GET /api/transactions/libelles` MUST donc retourner `ResponseEntity<List<String>>` directement, sans DTO wrapper. YAGNI.

> **Explicitement NON créé** : aucune entité `Merchant`, `Payee`, `Label`, ou table dédiée. Zéro migration de schéma.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** (couvre US1, US2) : Un utilisateur saisissant une transaction avec un libellé déjà utilisé dans ses 20 derniers libellés les plus fréquents peut compléter le champ en **2 interactions maximum** (focus + clic suggestion ou focus + 1 caractère + clic). *Vérification* : test manuel scripté sur Angular et Flutter.
- **SC-002** (couvre US3) : Lorsque l'utilisateur a tapé au moins 2 caractères et continue à taper, la liste de suggestions se rafraîchit correctement en **moins de 300ms perçus** (incluant debounce ~200ms, appel backend et filtrage client). *Vérification* : mesure en conditions réelles + test e2e.
- **SC-003** (couvre NFR-001) : L'endpoint backend répond en **< 100ms** sur un dataset de 10 000 transactions pour un utilisateur. *Vérification* : test de performance JMH ou simple `assertThat(duration).isLessThan(Duration.ofMillis(100))` sur test d'intégration avec seed.
- **SC-004** (couvre US5) : **100% des requêtes** à l'endpoint retournent exclusivement les libellés de l'utilisateur authentifié — **zéro fuite cross-user**. *Vérification* : test d'intégration avec deux utilisateurs et assertions croisées.
- **SC-005** (couvre US4) : **100% des libellés nouveaux** saisis par l'utilisateur sont acceptés et persistés tels quels, sans modification ni validation restrictive. *Vérification* : test e2e + tests unitaires frontend.
- **SC-006** (couvre FR-014) : L'endpoint est **visible et testable** depuis Swagger UI avec exemple de payload. *Vérification* : revue manuelle de `/swagger-ui.html`.
- **SC-007** : **Aucune entité `Merchant` / `Payee`** n'est créée. **Aucune migration Flyway impliquant des tables/colonnes** — seule une migration DDL-only activant l'extension `unaccent` est autorisée (`CREATE EXTENSION IF NOT EXISTS unaccent;`). *Vérification* : revue du diff — absence de `CREATE TABLE` ou `ALTER TABLE` nouveaux, présence autorisée de `V27__enable_unaccent_extension.sql` (ou numéro disponible suivant).

## Contraintes & Dépendances

### Contraintes (constitution du projet)

- **#1 API-First** : implémentation backend d'abord, frontends ensuite, avec DTO (pas d'entité JPA exposée).
- **#2 Sécurité par défaut** : JWT + filtrage utilisateur obligatoire.
- **#3 Simplicité & YAGNI** : Controller → Service → Repository. Aucune abstraction prématurée. Pas d'entité dédiée pour les libellés.
- **#4 Mobile-First UX** : UX utilisable au pouce sur mobile, saisie en 2-3 interactions.
- **#5 Testabilité** : tests d'intégration endpoint + tests unitaires service + tests front.
- **#6 Observabilité** : log INFO sur l'appel endpoint.
- **#7 Self-Hosted Ready** : aucune nouvelle dépendance infra. L'extension PostgreSQL `unaccent` fait partie du paquet `postgresql-contrib` standard et est disponible sur Postgres managé (RDS, Supabase, Neon, etc.) comme self-hosted — pas une dépendance infra nouvelle.

### Dépendances

- **Entité `Transaction` existante** : dépend du champ `libelle` déjà présent dans le schéma (`Transaction.libelle`, `varchar` non-nullable).
- **Système d'authentification JWT existant** : dépend du résolveur d'utilisateur authentifié (`@AuthenticationPrincipal` ou équivalent).
- **Formulaire de saisie transaction existant** : Angular (`app/`) et Flutter (`flutter/`) — la feature s'y greffe, ne le remplace pas.
- **Aucune dépendance externe nouvelle côté code** : pas de lib fuzzy, pas de lib autocomplete tierce. Angular : composant maison aligné DESIGN.md (pas de `@angular/material`). Flutter : widget `Autocomplete<String>` de Material déjà embarqué par le SDK Flutter.
- **Extension PostgreSQL `unaccent`** : activée via une nouvelle migration Flyway `V27__enable_unaccent_extension.sql` (numéro à ajuster selon la numérotation disponible au moment de l'implémentation). Vérifié le 2026-04-13 : aucune extension Postgres n'est actuellement activée dans les migrations existantes (V1 → V26).

### Documentation à mettre à jour

- `docs/api-examples.md` : ajouter exemple de requête/réponse pour `GET /api/transactions/libelles`.
- `docs/dette-technique.md` : ajouter note sur migration future si une entité `Merchant` devient nécessaire (stats par commerçant, recherche par merchant). Référencer KKS-099 pour la logique de dédup Jaro-Winkler déjà disponible.
- `DESIGN.md` (si nouveau pattern introduit) : éventuellement documenter le pattern autocomplete si non déjà présent.

## Assumptions

- **A1** : Le nombre de libellés distincts par utilisateur est raisonnablement borné (< 1000 dans 99% des cas). *Impact si fausse* : la requête SQL reste performante grâce à la limite serveur (50 max), mais l'ergonomie côté UI pourrait souffrir au-delà.
- **A2** : Le champ `libelle` de l'entité `Transaction` est non-nullable et a une taille maximale par défaut `varchar(255)` (pas d'attribut `length` explicite). *Impact si fausse* : vérifier avant implémentation et adapter le DTO.
- **A3** : ✅ **Tranchée le 2026-04-13** — vérification effectuée dans `api/src/main/java/fr/kksdev/budget/api/controller/` : les controllers retournent `ResponseEntity<List<X>>` directement pour les collections. Décision : `ResponseEntity<List<String>>` sans DTO wrapper (voir Key Entities).
- **A4** : ✅ **Tranchée par FR-018** (clarify 2026-04-13) — le projet n'utilise pas `@angular/material`. Le composant autocomplete Angular sera un composant **maison** aligné sur DESIGN.md, intégré dans le formulaire existant. *Impact si non-tenable* : si le formulaire existant impose des contraintes empêchant l'overlay, prévoir un micro-refactor local.
- **A5** : Le formulaire Flutter utilise un `TextFormField` standard — l'intégration de `Autocomplete<String>` (Material) ou d'un widget custom est réalisable sans refonte du formulaire. *Impact si fausse* : refactoring partiel du formulaire.
- **A6** : La base PostgreSQL dispose d'un index sur `(user_id)` de la table `transactions` (`idx_transactions_user_id` vérifié dans `V1__init_schema.sql`), suffisant pour la requête d'agrégation. *Impact si fausse* : perf < 100ms non tenable à 10k transactions, index additionnel sur `(user_id, libelle)` à envisager.

## Questions ouvertes (résolues en `/devflow.clarify` le 2026-04-13)

| # | Question | Statut | Résolution |
|---|----------|--------|------------|
| 1 | Seuil de déclenchement des suggestions | ✅ Résolu | À partir de **2 caractères** tapés (voir FR-015) |
| 2 | Nombre de suggestions affichées côté UI | ✅ Résolu | **5 maximum** côté UI (voir FR-016) |
| 3 | Filtre `q` backend : startsWith vs contains | ✅ Résolu | **`contains`** case-insensitive + accent-insensible (voir FR-017) |
| 4 | Accent-sensitivity du filtre | ✅ Résolu | **Accent-insensible** via `unaccent` PostgreSQL côté backend (voir FR-017) et normalisation NFD côté client |
| 5 | Composant Angular : Material vs maison | ✅ Résolu | **Composant maison** aligné DESIGN.md — le projet n'utilise pas `@angular/material` (voir FR-018) |

## Hors scope (rappel explicite)

- ❌ Entité `Merchant` ou `Payee`
- ❌ Normalisation automatique (lowercase, trim, fuzzy merge)
- ❌ Écran de fusion de doublons
- ❌ Stats par commerçant
- ❌ Auto-catégorisation basée sur le libellé
- ❌ Suggestions cross-user
- ❌ Recherche plein texte (Elasticsearch, etc.)
- ❌ Synchronisation offline-first des suggestions Flutter (les suggestions remote sont suffisantes pour le MVP)
