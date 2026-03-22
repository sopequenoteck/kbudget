# Implementation vs Spec Checklist: Ecran Transactions Liste (Flutter)

**Purpose**: Valider que les exigences sont suffisamment precises pour verifier la couverture de l'implementation post-developpement
**Created**: 2026-02-23
**Feature**: [spec.md](../spec.md) | [plan.md](../plan.md) | [tasks.md](../tasks.md)
**Audience**: Auteur (post-implementation)
**Depth**: Approfondie
**Domain**: Implementation vs Specification

## Tracabilite FR -> Implementation

- [ ] CHK001 — FR-001 (MonthSelector) est-il suffisamment specifie pour verifier son integration dans le screen (position, callbacks, etat initial) ? [Completeness, Spec §FR-001]
- [ ] CHK002 — FR-002 (resume mensuel) definit-il explicitement le comportement quand `MonthlySummary` est `null` (mois sans donnees) ? [Gap, Spec §FR-002]
- [ ] CHK003 — FR-003 (filtre segmente) specifie-t-il les 3 labels exacts et leur ordre d'affichage ? [Clarity, Spec §FR-003]
- [ ] CHK004 — FR-004 (groupement par jour) definit-il l'algorithme de groupement et le tri intra-jour ? [Clarity, Spec §FR-004]
- [ ] CHK005 — FR-004a (en-tetes relatifs) specifie-t-il la capitalisation de la premiere lettre du format complet ? [Gap, Spec §FR-004a]
- [ ] CHK006 — FR-005 (contenu ListItem) definit-il le comportement exact quand `categoryId` est `null` (icone par defaut, texte "Sans categorie") ? [Completeness, Spec §FR-005, Edge Cases]
- [ ] CHK007 — FR-006 (filtrage client) specifie-t-il explicitement que les ajustements sont visibles dans "Tous" mais exclus de "Depenses" et "Recettes" ? [Clarity, Spec §FR-006, Assumptions]
- [ ] CHK008 — FR-007 (tap navigation) definit-il le mecanisme de no-op de maniere verifiable (try-catch vs methode vide vs condition) ? [Measurability, Spec §FR-007]
- [ ] CHK009 — FR-008 (shimmer loading) specifie-t-il le nombre de squelettes et s'ils couvrent le resume ET la liste ? [Completeness, Spec §FR-008]
- [ ] CHK010 — FR-009 (etat vide) definit-il les messages exacts pour chaque contexte de filtre ? [Clarity, Spec §FR-009]
- [ ] CHK011 — FR-010 (etat erreur) specifie-t-il le contenu visuel de l'etat d'erreur (icone, message, bouton) ? [Completeness, Spec §FR-010]
- [x] CHK012 — FR-011 (pull-to-refresh) definit-il le comportement quand le refresh echoue — les donnees existantes restent-elles visibles ou sont-elles remplacees par l'etat erreur ? [Ambiguity, Spec §FR-011, US5-AS2] **CORRIGE** — `refresh()` conserve maintenant les donnees existantes et affiche un SnackBar en cas d'erreur.
- [ ] CHK013 — FR-013 (formatage montants) est-il verifiable sans connaitre le detail de `AmountFormatter` ? [Measurability, Spec §FR-013]
- [ ] CHK014 — FR-016 (race condition mois) specifie-t-il le mecanisme de protection de maniere verifiable (annulation vs ignore) ? [Measurability, Spec §FR-016]

## Tracabilite NFR -> Implementation

- [ ] CHK015 — NFR-001 (semantic labels) definit-il le format exact du label (ex: "$libelle, $montant") et sur quel widget il doit etre applique ? [Clarity, Spec §NFR-001]
- [x] CHK016 — NFR-001 est-il verifiable dans le code — des `Semantics` widgets ou `semanticLabel` sont-ils requis explicitement ? [Gap, Spec §NFR-001] **OK** — `ListItem` (ligne 146-160) inclut deja `Semantics(label: '$title, $value')`.
- [ ] CHK017 — NFR-002 (contrastes couleurs) definit-il des criteres mesurables (ratio WCAG) ou delegue-t-il au theme existant ? [Measurability, Spec §NFR-002]

## Couverture i18n

- [ ] CHK018 — La spec definit-elle explicitement que TOUTES les chaines affichees doivent utiliser `AppLocalizations` plutot que des chaines hardcodees ? [Gap]
- [ ] CHK019 — Les chaines du `DayHeaderFormatter` ("Aujourd'hui", "Hier") sont-elles couvertes par les exigences i18n ? [Coverage, Gap]
- [x] CHK020 — Le label "Sans categorie" utilise dans `TransactionDayGroup` est-il trace vers une exigence i18n ? [Coverage, Gap] **CORRIGE** — Utilise maintenant `l10n.transactionsNoCategory`.
- [x] CHK021 — Les labels du filtre segmente ("Tous", "Depenses", "Recettes") sont-ils traces vers des exigences i18n ? [Traceability] **CORRIGE** — Utilise `l10n.transactionsFilterAll/Depenses/Recettes`.

## Coherence Spec <-> Implementation

- [x] CHK022 — T027 (remplacement chaines hardcodees par i18n) est-il marque termine alors que le code utilise encore des chaines hardcodees dans `TransactionSummaryCard`, `TransactionListScreen` et `DayHeaderFormatter` ? [Conflict, tasks.md T027] **CORRIGE** — `TransactionSummaryCard`, `TransactionListScreen` et `TransactionDayGroup` utilisent maintenant `AppLocalizations`. Seul `DayHeaderFormatter` conserve des strings hardcodees (methode statique sans context).
- [ ] CHK023 — Le plan (T020) specifie `context.push().then(refresh)` pour le tap, mais l'implementation est un no-op vide — la spec est-elle assez precise pour determiner lequel est correct ? [Conflict, plan.md T020 vs Spec §FR-007]
- [ ] CHK024 — La spec definit-elle si le resume shimmer et la liste shimmer doivent s'afficher simultanement ou si seule la liste affiche des squelettes ? [Ambiguity, Spec §FR-008]
- [ ] CHK025 — Le `TransactionSummaryCard` affiche un skeleton quand `isLoading=true` mais affiche `0` quand `summary==null` et `isLoading==false` — ce comportement est-il couvert par les exigences ? [Gap, Spec §FR-002]

## Couverture des criteres d'acceptation

- [ ] CHK026 — SC-001 (< 2s chargement) est-il verifiable sans benchmark automatise — la spec definit-elle comment le mesurer ? [Measurability, Spec §SC-001]
- [ ] CHK027 — SC-004 (3 etats) definit-il si les 3 etats sont mutuellement exclusifs ou s'ils peuvent coexister (ex: erreur + donnees partielles) ? [Ambiguity, Spec §SC-004]
- [ ] CHK028 — SC-005 (ouverture en un tap) est-il verifiable alors que l'implementation actuelle est un no-op ? [Measurability, Spec §SC-005]
- [ ] CHK029 — SC-006 (resume coherent) definit-il le comportement exact du bilan quand `bilan > 0`, `bilan < 0` et `bilan == 0` (couleur differente) ? [Coverage, Spec §SC-006]

## Ecarts detectes (Implementation non tracee)

- [ ] CHK030 — Le padding en bas du `SliverList` (`SizedBox(height: AppSpacing.space12 * 2)`) pour le FAB est-il trace vers une exigence ? [Gap]
- [ ] CHK031 — Le chargement automatique des categories dans `initState` est-il couvert par une exigence ou assumption ? [Gap]
- [ ] CHK032 — La couleur conditionnelle du bilan (vert si > 0, rouge si < 0, neutre si == 0) dans `TransactionSummaryCard` est-elle specifiee ? [Gap]
- [ ] CHK033 — L'overflow `TextOverflow.ellipsis` sur les montants du resume est-il trace vers une exigence de troncature ? [Gap, Spec §Edge Cases]

## Hypotheses et dependances

- [x] CHK034 — L'hypothese "Le `ListItem` existant gere les semantic labels" est-elle validee dans le code du widget `ListItem` ? [Assumption] **OK** — Valide : `ListItem` (ligne 146-160) genere `Semantics(label: '$title, $value')` automatiquement.
- [ ] CHK035 — L'hypothese "Les fichiers `.freezed.dart` et `.g.dart` sont regeneres et commites" est-elle verifiable dans l'etat git actuel ? [Assumption, tasks.md]
- [ ] CHK036 — La dependance vers `AmountFormatter.amountColor()` retournant `null` pour les ajustements est-elle documentee dans la spec ? [Dependency, Spec §Edge Cases]

## Notes

- Focus : post-implementation — evaluation de la qualite des exigences pour valider la couverture du code
- 36 items au total couvrant 7 categories
- Chaque item reference la source spec/plan/tasks quand applicable
- Les items marques [Gap] identifient des exigences manquantes dans la spec
- Les items marques [Conflict] identifient des incoherences spec <-> code ou plan <-> code
