# Research: 007-format-pipes

**Date**: 2026-02-09
**Status**: Complete

## R1: Formatage des montants avec Intl.NumberFormat

**Decision**: Utiliser `Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR' })` pour le formatage de base, puis préfixer manuellement le signe `+` ou `-` selon le type métier.

**Rationale**:
- `Intl.NumberFormat` est natif au navigateur, pas de dépendance externe
- Gère automatiquement le séparateur de milliers (espace insécable), la virgule décimale et le symbole €
- Le mode `currency` avec `signDisplay: 'never'` permet de contrôler le signe manuellement
- Compatible avec tous les navigateurs modernes ciblés par la PWA

**Alternatives considered**:
- `DecimalPipe` Angular natif : ne gère pas le signe conditionnel ni le formatage monétaire fr-FR complet
- `CurrencyPipe` Angular natif : ne permet pas de préfixer +/- selon un type métier custom
- Bibliothèque tierce (accounting.js, dinero.js) : over-engineering pour un cas simple (YAGNI)

## R2: Calcul des dates relatives

**Decision**: Calcul manuel des différences en jours via soustraction de timestamps, avec seuils fixes (0=aujourd'hui, 1=hier, 2-7=jours, 8-30=semaines, >30=date longue). Utiliser `Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })` pour le format long.

**Rationale**:
- Calcul simple et déterministe sans dépendance
- Les seuils sont figés (pas de configuration nécessaire)
- `Intl.DateTimeFormat` gère correctement les noms de mois en français
- Pas besoin de `Intl.RelativeTimeFormat` car les libellés sont en français hardcodé (plus simple)

**Alternatives considered**:
- `Intl.RelativeTimeFormat` : plus complexe pour gérer les seuils de basculement jour→semaine→date
- date-fns `formatRelative` / `formatDistance` : dépendance externe inutile (YAGNI)
- Moment.js : déprécié, bundle size excessif
- `DatePipe` Angular natif : ne gère pas le relatif ("Aujourd'hui", "Hier")

## R3: Mapping type métier → signe

**Decision**: Le pipe AmountPipe accepte un paramètre `type` de type `string | null | undefined`. Le mapping signe est :
- `'RECETTE'` ou `'ON_ME_DOIT'` → préfixe `+`
- `'DEPENSE'` ou `'JE_DOIS'` → préfixe `-`
- `null`, `undefined`, ou toute autre valeur → pas de signe

**Rationale**:
- Accepter `string` plutôt qu'un union type spécifique permet la réutilisation dans différents contextes sans couplage fort aux enums
- Le mapping est centralisé dans le pipe : un seul endroit à modifier si les types évoluent
- Compatible avec `TransactionType` et `DebtType` sans import croisé obligatoire

**Alternatives considered**:
- Union type strict `TransactionType | DebtType` : crée un couplage entre le pipe shared et les modèles core
- Deux pipes séparés (AmountTransactionPipe, AmountDebtPipe) : duplication, violation YAGNI
- Paramètre boolean `isPositive` : moins expressif, perd le contexte métier

## R4: Stratégie de test pour pipes purs

**Decision**: Tester les pipes comme des classes pures (instanciation directe `new AmountPipe()`) sans TestBed Angular. Couvrir tous les cas de la spec : nominal, limites, null/undefined.

**Rationale**:
- Les pipes purs n'ont pas de dépendances injectées → pas besoin de TestBed
- Instanciation directe = tests plus rapides et plus simples
- Conforme au principe V (Testabilité) : tester le comportement, pas l'infra

**Alternatives considered**:
- TestBed complet : overhead inutile pour des pipes sans DI
- Tests e2e uniquement : insuffisant, les pipes doivent être validés unitairement
