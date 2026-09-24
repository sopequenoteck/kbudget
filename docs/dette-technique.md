# Dette technique

Dettes identifiees au fil du projet. A traiter par lot lors des phases de refactoring.

## Format

Chaque entree suit : description, impact, correction proposee, date d'identification.

---

### DT-001 — Deux formats d'erreur API coexistent — RESOLU 2026-08-18

**Identifie** : 2026-03-30
**Resolu** : 2026-08-18

**Description initiale** : Le format standard (`{ timestamp, status, message }` via `GlobalExceptionHandler.errorBody()`) et le format JWT (`{ error, message }` via le record `ErrorResponse`) coexistaient. Le frontend devait gerer deux structures differentes selon le code HTTP.

**Impact** : Contrat d'API incoherent. Chaque nouveau client doit connaitre l'exception au format.

**Correction appliquee** : Toutes les erreurs HTTP JSON utilisent `{ error, message }`. Le gestionnaire global, les points d'entree Spring Security et les filtres servlet partagent le meme contrat. Les 401 sans authentification utilisent `UNAUTHENTICATED`; les refus utilisent `ACCESS_DENIED` ou un code specialise.

**Fichiers concernes** : `GlobalExceptionHandler.java`, `ErrorResponse.java`, `ApiErrorWriter.java`, `SecurityConfig.java`, filtres de securite, intercepteur Angular, `api-errors.md`

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

### DT-006 — Isolation TestBed instable avec vitest + Angular 21 (APP) — RESOLU 2026-09-03

**Identifie** : 2026-06-14
**Resolu** : 2026-09-03 (KKS-312)

**Symptome** : des que plusieurs fichiers `.spec.ts` partageaient un worker
vitest — `--no-file-parallelism`, ou CI sur runner a faible nombre de coeurs —
le TestBed etait contamine : `Cannot configure the test module when the test
module has already been instantiated`. Repro : 46 fichiers et 415 tests en
echec sur 52 et 507.

**Cause reelle** : `setupFiles` ne s'executait **jamais**. `tsconfig.spec.json`
n'incluait que `src/**/*.d.ts` et `src/**/*.spec.ts` ; `src/test-setup.ts`
etait absent du programme TypeScript. Le plugin Angular compile les `.ts` via
ce programme et produit une sortie vide pour un fichier qu'il ne connait pas :
vitest chargeait donc un module vide, **sans erreur ni avertissement**. Verifie
par elimination — un `test-setup.js` au contenu identique s'executait, le `.ts`
non.

Consequence en chaine : sans `setupFiles`, les hooks de nettoyage du TestBed
(`ɵgetCleanupHook`, ce que Karma/Jasmine installent d'office) n'etaient jamais
poses. L'init manuelle repetee dans 47 specs compensait le symptome, et
fonctionnait tant que chaque fichier disposait de son propre worker.

**Ce qui avait egare le diagnostic** : la tentative documentee — centraliser
`initTestEnvironment` dans `test-setup.ts` — echouait avec `Need to call
TestBed.initTestEnvironment() first`. Message coherent avec un probleme de
chargement `setupFiles` propre a Angular 21, alors que le fichier n'etait tout
simplement jamais lu. Les trois pistes envisagees (reset inter-fichiers,
`pool`/`isolate` cote vitest, evolution du plugin) portaient toutes a cote :
verifie, `--isolate` et `--max-workers=1` ne changent rien.

**Correction** :

1. `src/test-setup.ts` ajoute a l'`include` de `tsconfig.spec.json`
2. `test-setup.ts` utilise `setupTestBed()` de `@analogjs/vitest-angular`, qui
   installe les hooks de nettoyage et initialise l'environnement une seule fois
3. Init manuelle retiree des 47 specs concernes
4. `@analogjs/vite-plugin-angular` declare dans `package.json` — `vitest.config.ts`
   l'importait alors qu'il n'etait present que comme dependance transitive
5. Job `test-app` du gate de release bascule sur `ubuntu-latest` ; job
   `app-tests` ajoute a `ci-app.yml` sur runner GitHub

**Verifie** : 507 tests verts en parallele, en `--no-file-parallelism`, en
`--max-workers=1` et apres un `npm ci` sur arbre de dependances neuf.

**Reste sur runner self-hosted** : le job `app-analysis` de `ci-app.yml`, qui
joint SonarQube par le reseau Docker interne `ci-stack_ci-net`. Cette
dependance-la n'a rien a voir avec DT-006 et ne peut pas etre levee sans
exposer Sonar.

**API et Flutter avaient le meme manque**, traite seulement le 2026-09-05
(KKS-358) : `ci-api.yml` n'avait alors qu'un seul job, self-hosted, donc une
pull request de fork touchant `api/` ne declenchait aucun test. La correction
ci-dessus ne portait que sur APP.

