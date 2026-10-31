# app/ — conventions Angular

## Signals-First

Approche **signals-first** obligatoire :

| Besoin | Utiliser | Ne PAS utiliser |
|--------|----------|-----------------|
| State | `signal()` | Variables classiques |
| Derived state | `computed()` | Getters manuels |
| Side effects | `effect()` | `ngOnChanges` |
| Inputs | `input()` / `input.required()` | `@Input()` |
| Outputs | `output()` | `@Output()` + `EventEmitter` |
| Queries | `viewChild()`, `contentChild()` | `@ViewChild()`, `@ContentChild()` |
| Two-way binding | `model()` | `@Input()` + `@Output()` combo |

## Regles

- `inject()` uniquement (pas de constructor injection)
- Standalone obligatoire, `ChangeDetectionStrategy.OnPush` sur tous les composants
- Pas de `subscribe()` manuel — utiliser `toSignal()`, `firstValueFrom()` ou pipe `async`
- RxJS limite aux flux HTTP et operateurs complexes
- ESLint + Prettier configures (`ng lint`, `npm run format`). **Ne formater que les fichiers crees** : reformater un fichier existant en fait du nouveau code pour Sonar, et des blocs jumeaux entre composants deviennent de la duplication nouvelle (Quality Gate echoue, KKS-373). plus d'une centaine de fichiers ne passent deja pas Prettier et la CI ne le controle pas
- Locale d'affichage : `LanguageService.displayLocale()` (`fr-FR`, `en-GB`), jamais une locale en dur dans `Intl`, `toLocaleString` ou `localeCompare`. Formatages partages dans `shared/utils/locale-format.utils.ts`. Cles et glossaire : [`docs/i18n.md`](../docs/i18n.md)
- Date metier seule (`AAAA-MM-JJ`) : `parseLocalDate` (`shared/utils/date.utils.ts`), jamais `new Date(x)` qui la lit a minuit UTC, soit la veille dans un fuseau en retard sur UTC. Date du jour a comparer : `toLocalIsoDate(new Date())`, jamais `toISOString()`. La suite vitest tourne par defaut en `America/Los_Angeles` (`vitest.config.ts`, surchargeable par `TZ=`) pour que la CI, en UTC, detecte ces decalages
- Texte traduit : une structure calculee (`computed()`, defaut d'`input()`, constante) porte la **cle**, le template traduit avec le pipe `transloco`. `translate()` en TypeScript seulement au moment d'un evenement (toast, erreur posee dans un handler) : ailleurs il n'est evalue qu'une fois et garderait l'ancienne langue apres une bascule (KKS-374). Exception : un `computed()` qui doit traduire en TS (valeur passee a un composant sans pipe) lit d'abord `LanguageService.activeLanguage()`, la langue **appliquee** apres chargement du catalogue, jamais la preference brute (KKS-380)
- Nom de categorie : toujours via le pipe `categoryName` (ou `categoryDisplayName` en TS), jamais `nom` brut ni le pipe `transloco` sur un nom saisi par l'utilisateur (KKS-395)
- `[innerHTML]` uniquement pour une traduction qui porte du balisage (`<strong>`), et **toute donnee utilisateur interpolee passe par `escapeHtml`** (`shared/utils/html-escape.utils.ts`) : MessageFormat n'echappe pas ses parametres et le sanitizer d'Angular laisse passer `<a>`/`<img>` (KKS-376)

## Design System

Source de verite : [`DESIGN.md`](../DESIGN.md). Quiet utility dark-first. 4 canaux couleur : amber (action), vert (revenu), rouge (depense), gris (structure). Police : Inter.

- `var(--token-name)` uniquement, jamais de hex/rgba hardcode dans les composants
- Patterns partages dans `styles/k/k-patterns.css` (k-design, classes `.k-`, copie a ne pas editer) — les reutiliser, pas les reinventer. Part metier de K-Budget dans `_bottom-sheet.scss` et `_list-patterns.scss`, sous le nom du bloc en `.k-` (KKS-619)
- Avant modification frontend : lire `DESIGN.md` et verifier la conformite
