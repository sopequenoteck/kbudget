# Clarify Log — KKS-243 : Phase 1 / Étape 7 — Refonte 3 écrans S Flutter

> Date : 2026-05-27
> Issue : KKS-243
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md §Questions ouvertes Q1 + §US1/US2/US3 | PageHeader vs AppBar pour les 3 écrans | 3 — UX/Interaction | H | M | HAUT | PageHeader obligatoire | Auto |
| CL-002 | spec.md §US3 + §Questions ouvertes Q3 | Boutons OutlinedButton "Ajouter" non-conformes au pattern Angular | 3 — UX/Interaction | H | B | HAUT | Remplacer par bouton + circulaire 28px dans header de section | Auto |
| CL-003 | spec.md §US2 + §Questions ouvertes Q2 | TextField OutlineInputBorder dans DataSettingsScreen | 3 — UX/Interaction | M | B | BAS | Acceptable — écran Flutter-only | Auto |
| CL-004 | spec.md §Assumptions A-002 | ConfirmDialogCustom supporte-t-il les callers async ? | 5 — Intégrations | M | B | BAS | Validée — `show()` retourne `Future<bool?>` | Auto |
| CL-005 | spec.md §Assumptions A-003 | EmptyStateWidget supporte-t-il l'état erreur avec CTA ? | 5 — Intégrations | M | B | BAS | Validée — paramètres `ctaLabel`/`onCtaTap` disponibles | Auto |

---

## Résolutions détaillées

### CL-001 — PageHeader vs AppBar

- **Catégorie** : 3 — UX/Interaction
- **Score** : HAUT
- **Contexte** : La spec ne précisait pas si les `AppBar` génériques des 3 écrans devaient migrer vers `PageHeader` (introduit dans KKS-238).
- **Analyse** : Lecture de `categories.html` et `accounts.html` Angular — les deux utilisent le pattern `page-header` avec bouton back (`phosphorCaretLeft`) + titre `h1` + icône. Le widget `PageHeader` Flutter (KKS-238) est l'équivalent direct. Tous les sous-écrans de navigation dans `settings.routes.ts` Angular utilisent ce pattern.
- **Décision** : `PageHeader` obligatoire dans les 3 écrans. FR-010 ajouté à la spec.
- **Impact sur spec.md** : Q1 → Résolu. FR-010 ajouté. SC-007 ajouté. Texte US2 et US3 mis à jour.

---

### CL-002 — Boutons OutlinedButton → bouton + circulaire

- **Catégorie** : 3 — UX/Interaction
- **Score** : HAUT
- **Contexte** : `CurrencySettingsScreen` utilise deux `OutlinedButton.icon` en pied de section pour "Ajouter une devise" et "Ajouter un taux". Conformité Angular à vérifier.
- **Analyse** : Lecture de `currency-list.ts` et `exchange-rate-manager.ts` Angular. Les deux composants utilisent un bouton `add-btn` de 28px dans le header de section (`settings-section__header`) : `border-round`, `border: 1px solid var(--border-default)`, `color: var(--text-tertiary)`. Pas de bouton plein en bas de section.
- **Décision** : `OutlinedButton.icon` non-conforme. Remplacer par `GestureDetector` ou `IconButton` de 28px dans les headers de section. FR-011 ajouté.
- **Impact sur spec.md** : Q3 → Résolu. FR-011 ajouté. SC-008 ajouté. Texte US3 mis à jour.

---

### CL-003 — TextField OutlineInputBorder

- **Catégorie** : 3 — UX/Interaction
- **Score** : BAS
- **Contexte** : Le `TextField` avec `OutlineInputBorder()` dans `DataSettingsScreen` pour la saisie de l'URL serveur — conformité design v5 incertaine.
- **Analyse** : Lecture de `settings.routes.ts` Angular — aucune route `data` n'existe. `DataSettingsScreen` est Flutter-only (mode local/serveur est une feature Flutter exclusive). Aucune référence Angular pour le style d'input de cet écran. Le `TextField` avec `OutlineInputBorder` est le pattern Flutter/Material standard pour les inputs de configuration.
- **Décision** : `OutlineInputBorder` acceptable — aucune dérogation au design system, car aucune référence Angular à aligner. Seuls les labels et tokens couleur/typo autour du champ sont dans le scope.
- **Impact sur spec.md** : Q2 → Résolu. Texte US2 mis à jour.

---

### CL-004 — ConfirmDialogCustom et callbacks async

- **Catégorie** : 5 — Intégrations
- **Score** : BAS
- **Contexte** : `DataSettingsScreen._onModeChanged()` est une méthode async. L'assumption A-002 supposait que `ConfirmDialogCustom` pourrait nécessiter une adaptation.
- **Analyse** : Lecture de `confirm_dialog_custom.dart` — `ConfirmDialogCustom.show()` est déclaré `static Future<bool?> show({...})`. Il retourne un `Future` que le caller peut `await`. Pattern exact : `final confirmed = await ConfirmDialogCustom.show(context: context, title: 'Changer de source ?', message: '...') ?? false;` — totalement compatible avec les callers async.
- **Décision** : Assumption A-002 validée. Aucune adaptation requise.
- **Impact sur spec.md** : A-002 → marquée ✅ Validée avec détail.

---

### CL-005 — EmptyStateWidget état erreur

- **Catégorie** : 5 — Intégrations
- **Score** : BAS
- **Contexte** : `CategoryListScreen` a un état erreur ad hoc (Column avec icône warning + texte + bouton retry). FR-002 demande de le remplacer par `EmptyStateWidget`. L'assumption A-003 supposait que cela n'était peut-être pas possible.
- **Analyse** : Lecture de `empty_state_widget.dart` — le widget accepte `icon` (optional `IconData`), `message` (required), `ctaLabel` (optional), `onCtaTap` (optional VoidCallback). Usage pour état erreur : `EmptyStateWidget(icon: PhosphorIconsRegular.warning, message: 'Erreur de chargement', ctaLabel: 'Réessayer', onCtaTap: refresh)` — tous les paramètres nécessaires sont présents.
- **Décision** : Assumption A-003 validée. `EmptyStateWidget` couvre l'état erreur. FR-002 peut utiliser `EmptyStateWidget` pour les états **vide** ET **erreur** dans `CategoryListScreen`.
- **Impact sur spec.md** : A-003 → marquée ✅ Validée avec détail.

---

## Points différés

> Aucun point différé — tous les points identifiés ont pu être résolus automatiquement dans cette session.

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 5 |
| Catégories couvertes | 2/11 (UX/Interaction, Intégrations) |
| Résolus automatiquement | 5 |
| Résolus interactivement | 0 |
| Différés | 0 |
| Modifications spec.md | FR-010 ajouté, FR-011 ajouté, SC-007 ajouté, SC-008 ajouté, Q1/Q2/Q3 résolus, A-002/A-003 validées, marqueurs NEEDS CLARIFICATION retirés |
