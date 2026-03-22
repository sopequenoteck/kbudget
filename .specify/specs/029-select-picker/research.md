# Research: SelectPicker generique

**Feature**: 029-select-picker | **Date**: 2026-02-17

## R1: Pattern ControlValueAccessor avec Angular Signals

**Decision**: Implementer ControlValueAccessor avec signals internes (pas de decorateurs classiques)

**Rationale**: Le category-picker existant utilise deja ce pattern avec succes : `signal()` pour l'etat interne, `computed()` pour les derivations, callbacks `onChange`/`onTouched` stockees dans des variables privees. Ce pattern est eprouve dans le projet et compatible avec OnPush.

**Alternatives considered**:
- Directive ControlValueAccessor separee → complexite inutile, le composant est le controle lui-meme
- Signal-based forms (Angular experimental) → pas encore stable, risque de breaking changes

## R2: Bottom-sheet mobile vs dropdown desktop

**Decision**: Utiliser le meme pattern que le Modal existant : `@media (min-width: 768px)` pour basculer entre bottom-sheet (mobile) et dropdown positionne (desktop)

**Rationale**: Le composant Modal (`modal.scss`) utilise deja ce breakpoint avec `align-items: flex-end` sur mobile et `align-items: center` sur desktop. Animations existantes : `modal-slide-up` (mobile) et `modal-scale-in` (desktop). Le z-index `--z-overlay: 300` est disponible pour le bottom-sheet.

**Alternatives considered**:
- CDK Overlay (@angular/cdk/overlay) → trop complexe pour le besoin (positionnement automatique pas necessaire)
- Meme dropdown partout sans bottom-sheet → mauvaise UX tactile sur mobile (trop petit, scroll difficile)
- Detection viewport via JS (window.matchMedia) → CSS media queries plus simples et performantes

## R3: Rendu personnalisable des items (display function vs templates)

**Decision**: Utiliser une interface `SelectPickerItem` avec champs standardises (id, label, icon, secondaryText) plutot que des templates ng-template

**Rationale**: Les deux cas d'usage existants ont des besoins previsibles :
- Categories : icone + nom
- Comptes : icone + nom + solde

Une interface avec `secondaryText` optionnel couvre ces deux cas sans la complexite de content projection. Si un futur cas necessite un rendu totalement different, on pourra ajouter un template override.

**Alternatives considered**:
- `ng-template` avec `TemplateRef<T>` pour rendu libre → sur-ingenierie pour 2 cas d'usage connus, viole Simplicite & YAGNI
- `displayFn: (item: T) => string` (fonction de formattage) → perd la structure (icone separee du texte), ne permet pas le styling differencie

## R4: Recherche conditionnelle (seuil d'items)

**Decision**: Input `searchThreshold` (defaut: 5). Si le nombre d'items >= seuil, le champ de recherche apparait automatiquement. Input `searchable` overridable pour forcer la recherche (categories: toujours actif).

**Rationale**: Approche pragmatique qui evite de surcharger l'interface pour les petites listes tout en scalant avec les grandes. Le seuil de 5 est choisi car en dessous, un scroll visuel suffit.

**Alternatives considered**:
- Toujours afficher la recherche → encombrement inutile pour 2-3 comptes
- Jamais de recherche pour les comptes → ne scale pas si l'utilisateur a 20+ comptes
- Input boolean `searchable` seul → oblige le parent a gerer la logique de seuil

## R5: Gestion du positionnement dropdown (desktop)

**Decision**: Positionnement absolu avec detection de l'espace disponible via `getBoundingClientRect()`. Si l'espace en dessous est insuffisant (< hauteur max du dropdown), afficher au-dessus.

**Rationale**: Le category-picker actuel utilise `position: absolute; top: calc(100% + var(--space-1))` sans detection de viewport. Ajouter une verification simple via `getBoundingClientRect()` dans un `effect()` resout le cas edge du dropdown coupe en bas de page.

**Alternatives considered**:
- CDK Overlay avec FlexibleConnectedPositionStrategy → overkill pour un simple flip haut/bas
- CSS anchor positioning (CSS Anchor Positioning API) → support navigateur insuffisant (Safari)
- Position fixe centree → perte de contexte visuel entre le champ et ses options

## R6: Migration incrementale des formulaires

**Decision**: Migration en 3 phases : (1) creer SelectPicker, (2) refactorer CategoryPicker en wrapper, (3) remplacer AccountPicker et select natifs. Supprimer AccountPicker a la fin.

**Rationale**: La migration incrementale permet de valider le SelectPicker avec le cas le plus complexe (categories avec recherche et creation) avant de migrer les cas plus simples (comptes). Chaque phase est testable independamment.

**Alternatives considered**:
- Big bang (tout remplacer d'un coup) → risque eleve de regression, difficile a debugger
- Garder AccountPicker comme wrapper (comme CategoryPicker) → pas de valeur ajoutee, AccountPicker n'a pas de fonctionnalite specifique a preserver

## R7: Tests

**Decision**: Vitest avec TestBed, mocking via `vi.fn()`, pattern `TestBed.initTestEnvironment()` en debut de fichier de test

**Rationale**: Pattern identique aux tests existants (category-picker.spec.ts, account-picker.spec.ts). Inputs signals testes via `fixture.componentRef.setInput()`. Mock des services via `{ provide: Service, useValue: mock }`.

**Alternatives considered**:
- Cypress/Playwright component testing → trop lourd pour des tests unitaires de composant
- Testing Library → pas installe dans le projet, ajouterait une dependance
