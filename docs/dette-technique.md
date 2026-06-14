# Dette technique

Dettes identifiees au fil du projet. A traiter par lot lors des phases de refactoring.

## Format

Chaque entree suit : description, impact, correction proposee, date d'identification.

---

### DT-001 — Deux formats d'erreur API coexistent

**Identifie** : 2026-03-30

**Description** : Le format standard (`{ timestamp, status, message }` via `GlobalExceptionHandler.errorBody()`) et le format JWT (`{ error, message }` via le record `ErrorResponse`) coexistent. Le frontend doit gerer deux structures differentes selon le code HTTP.

**Impact** : Contrat d'API incoherent. Chaque nouveau client doit connaitre l'exception au format.

**Correction proposee** : Unifier sur `{ error, message }` partout. Le status HTTP est deja dans la reponse, le timestamp est rarement exploite cote client. Migrer `GlobalExceptionHandler.errorBody()` vers `ErrorResponse` avec un champ `error` generique (ex: `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `INTERNAL_ERROR`).

**Fichiers concernes** : `GlobalExceptionHandler.java`, `ErrorResponse.java`, intercepteur Angular, api-errors.md

---

### DT-002 — Libelles transactions sans entite Merchant (KKS-230)

**Identifie** : 2026-04-13

**Description** : L'autocomplete libelle (KKS-230) exploite directement le champ `Transaction.libelle` via une agregation `GROUP BY libelle`. Aucune entite `Merchant`/`Payee` n'est creee (YAGNI, constitution #3). Les variantes orthographiques s'accumulent ("Carrefour", "carrefour market", "CARREFOUR").

**Impact** : Le jour ou une feature aval necessitera des stats par commercant (top merchants, depenses par enseigne, auto-categorisation), une migration sera necessaire sur des libelles potentiellement sales.

**Correction proposee** : Quand ce besoin apparaitra, prevoir :
1. Creer une entite `Merchant` liee a `Transaction` via `merchant_id` nullable.
2. Ecran de fusion manuelle des doublons.
3. Dedup automatique reutilisant la logique Jaro-Winkler deja disponible dans l'import CSV (KKS-099 — `api/src/main/java/fr/kksdev/budget/api/service/importcsv/`).
4. Job de backfill des transactions existantes.

**Fichiers concernes** (futurs) : nouvelle entite `Merchant`, `TransactionService`, migration Flyway de schema, ecran de fusion frontend.

**Dependance** : blocs sont interdependants — ne pas demarrer avant d'avoir un cas d'usage metier concret qui justifie la complexite.

---

### DT-003 — AutocompleteComponent sans ControlValueAccessor (KKS-230) — RESOLU 2026-04-14

**Identifie** : 2026-04-14
**Resolu** : 2026-04-14

**Description initiale** : Le composant `autocomplete.ts` utilisait l'API signals-first (`model<string>`, `[value]/(valueChange)`) sans implementer `ControlValueAccessor`, empechant la propagation des classes `ng-invalid`, `ng-touched`, `ng-dirty` sur le host.

**Correction appliquee** :
- `Autocomplete` implemente `ControlValueAccessor` (provider `NG_VALUE_ACCESSOR` + `forwardRef`)
- `value` passe de `model<string>` a `signal<string>` interne, pilote par `writeValue`
- `disabled` passe de `input<boolean>` a `signal<boolean>` pilote par `setDisabledState`
- `onChange` appele dans `onInput` et `selectAt` ; `onTouched` appele dans nouveau handler `(blur)` et `selectAt`
- `transaction-form.html` : `[value]`/`(valueChange)` -> `formControlName="libelle"`
- `transaction-form.ts` : suppression du wiring manuel (`onLibelleChange`, getter `libelleValue`)
- `_bottom-sheet.scss` : ajout du selecteur imbrique `.bsheet__libelle.ng-invalid.ng-touched input` pour couvrir le cas wrapper `app-autocomplete` (en plus du selecteur input direct pour `subscription-form`)

**Resultat** : l'etat `ng-invalid.ng-touched` se propage a nouveau sur le host, la bordure rouge du libelle est restauree automatiquement via `_bottom-sheet.scss`. Tests `autocomplete.spec.ts` verts (23/23).

---

### DT-004 — Icone recurrence non desactivee en mode local-first (KKS-241 / W-001)

**Identifie** : 2026-05-12

**Description** : Dans `TransactionForm`, l'icone de recurrence (bouton PhRepeat) est toujours active meme quand `dataModeProvider = DataMode.local`. R-004 (masquer ou desactiver l'icone en mode local) n'a pas ete implemente. Un SnackBar d'erreur est declenche si la creation echoue cote reseau, mais l'icone reste accessible et induira une erreur silencieuse pour l'utilisateur offline.

**Impact** : Faible — fallback SnackBar present. Pas de crash, pas de perte de donnees.

**Fichier concerne** : `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart`

**Correction proposee** : Lire `ref.watch(dataModeProvider)` dans `TransactionForm` et passer `isActive: dataModeProvider == DataMode.remote` sur le bouton repeat (ou masquer le widget entierement).

---

### DT-005 — RecurringListNotifier.create() utilise isLoading global (KKS-241 / W-002)

**Identifie** : 2026-05-12

**Description** : La methode `create()` ajoutee dans `RecurringListNotifier` (KKS-241) utilise `state = state.copyWith(isLoading: true)` au lieu du pattern `mutatingIds` etabli par `deactivate()`, `validate()`, `skip()`. A la creation, il n'y a pas encore d'identifiant a tracker, mais cela cree une incoherence de pattern dans le notifier.

**Impact** : Cosmétique — aucun impact fonctionnel. L'indicateur de chargement global masque toute la liste au lieu d'un seul item.

**Fichier concerne** : `flutter/lib/src/features/recurring/application/recurring_list_notifier.dart`

**Correction proposee** : Revenir a `isLoading` global pour `create()` (pas d'id a tracker) et documenter cette exception dans le notifier, OU introduire un `isCreating: bool` separe dans `ListState<T>` si le besoin se generalise.

---

### DT-006 — Isolation TestBed instable avec vitest + Angular 21 (APP)

**Identifie** : 2026-06-14

**Description** : Les tests APP appellent `getTestBed().initTestEnvironment(...)` directement dans chaque fichier `.spec.ts` (contournement d'un probleme de chargement de `setupFiles` avec Angular 21 + vitest, documente dans `app/src/test-setup.ts`). Aucun `TestBed.resetTestingModule()` n'est effectue entre les fichiers. Tant que vitest isole chaque fichier dans son propre worker (cas de `npm test` en parallele avec assez de coeurs), tout passe. Mais des que plusieurs fichiers partagent un worker — `npx vitest run --no-file-parallelism`, ou CI sur runner a faible nombre de coeurs — le singleton TestBed est contamine : `Cannot configure the test module when the test module has already been instantiated`. Repro : `--no-file-parallelism` -> 406+/475 tests en echec.

**Impact** : `npm test` est flaky selon la repartition en workers (donc selon la machine). Contournement actuel : le gate de release et la CI-APP utilisent `npm run test:coverage` (le coverage v8 change le parallelisme et ne declenche pas la collision). La divergence `npm test` (flaky) vs `test:coverage` (stable) subsiste pour le dev local.

**Tentative echouee** (patch sauvegarde, `/tmp/isolation-attempt.patch`) : centraliser `initTestEnvironment` + `beforeEach(resetTestingModule)` dans `test-setup.ts` casse tout (`Need to call TestBed.initTestEnvironment() first`, injector null) — c'est precisement le probleme de chargement `setupFiles` Angular 21 que le contournement evitait. **Ne pas refaire cette approche.**

**Correction proposee** : A traiter a froid. Pistes : (1) garder l'init dans les specs mais ajouter un reset inter-fichiers fiable sans casser le chargement ; (2) regler l'isolation cote `vitest.config.ts` (pool/isolate) pour garantir un worker frais par fichier meme a faible nombre de coeurs ; (3) suivre l'evolution du support vitest dans `@analogjs/vite-plugin-angular` pour Angular 21.

**Fichiers concernes** : `app/src/test-setup.ts`, `app/vitest.config.ts`, l'ensemble des `app/src/**/*.spec.ts`.
