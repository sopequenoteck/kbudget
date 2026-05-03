# Research: Alignement Settings Angular sur Flutter

## Decision 1: Strategie pour les compteurs de la page A propos

**Decision**: Utiliser `forkJoin` sur les `getAll()` existants et prendre `.length`
**Rationale**: Aucun service Angular n'expose de methode `count()` dediee. Les endpoints backend retournent la liste complete. Creer un endpoint count serait du over-engineering pour une page "A propos" consultee rarement.
**Alternatives considered**:
- Ajouter un endpoint `/stats` backend — rejete (violation YAGNI, pas necessaire pour 4 compteurs)
- Appeler chaque service individuellement — rejete (moins performant que `forkJoin` en parallele)

## Decision 2: Gestion de la couleur d'icone dans le hub

**Decision**: Utiliser une propriete `iconColor` (string CSS) sur chaque `SettingsSection` et l'appliquer via `[style.background]` sur le cercle d'icone
**Rationale**: Approche directe, pas besoin de classes CSS multiples. Aligne avec Flutter qui utilise `Color` directement.
**Alternatives considered**:
- Classes CSS par section (`.icon--blue`, `.icon--green`...) — rejete (10 classes pour un usage unique = over-engineering)
- CSS custom properties par section — rejete (plus complexe que necessaire)

## Decision 3: Icones a changer pour alignement Flutter

**Decision**: Remplacer `phosphorLightning` par `phosphorToggleRight` et `phosphorFloppyDisk` par `phosphorDatabase`. Ajouter `phosphorLock` pour Securite.
**Rationale**: Alignement exact avec les icones Flutter (`PhosphorIconsRegular.toggleRight`, `PhosphorIconsRegular.database`, `PhosphorIconsRegular.lock`).
**Alternatives considered**:
- Garder les icones Angular actuelles — rejete (contredit l'objectif d'alignement cross-plateforme)

## Decision 4: Gestion du placeholder Securite

**Decision**: Ajouter l'item dans le tableau SECTIONS avec `status: 'placeholder'` et `route: 'security'` pointant vers le composant Placeholder existant
**Rationale**: Reutilise le pattern et le composant Placeholder deja en place (utilise pour Budget). Ajout de route minimale.
**Alternatives considered**:
- Pas de route, bloquer le clic — rejete (inconsistant avec le pattern placeholder existant qui a une route)
- Creer un nouveau composant — rejete (Placeholder est generique et reutilisable)

## Decision 5: Groupement dans le template

**Decision**: Utiliser un computed signal `groupedSections` qui retourne une Map groupee, et iterer dans le template avec `@for` imbrique (groupes puis sections)
**Rationale**: Approche signals-first conforme aux conventions Angular du projet. Le computed se recalcule automatiquement si les sections changent.
**Alternatives considered**:
- Hardcoder 3 blocs HTML separes — rejete (duplication, pas maintenable)
- Pipe de groupement — rejete (computed signal est plus idiomatique Angular 21)
