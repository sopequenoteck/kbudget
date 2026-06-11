# Clarify Log — KKS-239 : BottomSheet4RowsWidget composable

> Date : 2026-05-10
> Issue : KKS-239
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md §Edge Cases + §Q1 | Row 3 vide : `SizedBox.shrink()` ou hauteur min 32px si `metaPills` vide ET `iconButtons` null ? | 6 - Edge cases | H | M | HAUT | Résolu | Auto |
| CL-002 | spec.md §FR-005 + §Q4 | Annuler omis ou rendu en plus si `footerLeading != null` ? | 3 - UX/Interaction | H | B | HAUT | Résolu | Auto |
| CL-003 | spec.md §A-003 | API slots `Widget?` vs builder `Widget Function(BuildContext)` — un slot doit-il accéder au context interne du squelette ? | 7 - Contraintes | H | M | HAUT | Résolu | Auto |
| CL-004 | spec.md §Edge Cases + §Q2 | Zone expand gelée ou libre pendant `loading: true` ? | 3 - UX/Interaction | M | M | MOYEN | Résolu | Auto |
| CL-005 | spec.md §Q3 | `BSheetSubmitVariant.danger` : couleur fond `colorScheme.error` ou `colorScheme.errorContainer` ou transparent ? | 10 - Placeholders | M | M | MOYEN | Résolu | Auto (audit SCSS) |
| CL-006 | spec.md §Q5 | Exposer `bsheet__amount--md/--sm` si `notePreview` consomme verticale ? | 1 - Scope | B | B | BAS | Différé | — |
| CL-007 | spec.md §A-001 | `AppThemeExtension` (16 props post-KKS-237) couvre-t-elle tous les tokens du squelette ? | 5 - Intégrations | M | B | BAS | Différé | — |
| CL-008 | spec.md §A-004 | `AnimatedSize` suffit pour 60 fps sur Android low-end ? | 4 - Non-fonctionnel | M | B | BAS | Différé | — |

---

## Résolutions détaillées

### CL-001 — Row 3 vide : SizedBox.shrink ou hauteur minimale

- **Catégorie** : 6 - Edge cases
- **Score** : HAUT
- **Contexte** : spec.md §Edge Cases posait `[NEEDS CLARIFICATION: comportement Row 3 si metaPills vide ET iconButtons vide]`. Q1 formulait deux options : hauteur 32px (cohérent avec `bsheet__icon-btn`) ou `SizedBox.shrink()`.
- **Analyse** : FR-003 applique déjà `SizedBox.shrink()` pour la zone expand quand `expandedContent == null`. La constitution III (YAGNI) proscrit les rendus inutiles. Rendre une Row 3 vide visible introduirait une hauteur fantôme incohérente avec le rendu de l'expand. La symétrie structurelle est préférable.
- **Décision** : Row 3 est `SizedBox.shrink()` — entièrement absente de l'arbre — si `metaPills.isEmpty && iconButtons == null`. Le widget ne rend aucune hauteur minimale vide.
- **Impact sur spec.md** : Marqueur `[NEEDS CLARIFICATION]` retiré de §Edge Cases ligne 139. Q1 §Open Questions passé à "Résolu ✓".

---

### CL-002 — Annuler omis si footerLeading != null

- **Catégorie** : 3 - UX/Interaction
- **Score** : HAUT
- **Contexte** : Q4 posait 3 options (a) omis, (b) toujours rendu, (c) rendu si `onCancel` non null. La question était marquée comme ouverte alors que FR-005 et SC-014 avaient déjà documenté la réponse (option a).
- **Analyse** : FR-005 ligne 162 : *"onCancel : VoidCallback? (rendu en pill cancel par défaut dans footerLeading quand footerLeading == null ; ignoré si footerLeading non null — le parent prend alors la responsabilité complète de la zone gauche, y compris le bouton Annuler)"*. SC-014 confirme les 3 cas : (a) `footerLeading: null` → Annuler affiché ; (b) `[supprimer]` → Annuler non rendu ; (c) `[supprimer, status]` → Annuler non rendu. La cohérence interne de la spec était déjà acquise.
- **Décision** : Option (a) confirmée. `onCancel` est ignoré quand `footerLeading != null`. Le parent qui passe `footerLeading` doit inclure lui-même son bouton Annuler dans la liste s'il le veut.
- **Impact sur spec.md** : Q4 §Open Questions passé à "Résolu ✓". Aucune modification fonctionnelle (FR-005 + SC-014 déjà corrects).

---

### CL-003 — API slots Widget? vs builder Widget Function(BuildContext)

- **Catégorie** : 7 - Contraintes
- **Score** : HAUT
- **Contexte** : A-003 exprimait une hypothèse non validée : `Widget?` suffit sans imposer un builder pattern. Le risque identifié était qu'un slot doive accéder au context interne du squelette.
- **Analyse** : En Flutter, un widget passé via constructeur parent est construit dans le `build()` du parent — le parent a accès à son propre `BuildContext` et peut appeler `Theme.of(context)` ou toute donnée inherited avant de passer le widget. L'accès au context *interne* du squelette (après sa position dans l'arbre) n'est nécessaire que si le slot doit consommer un `InheritedWidget` fourni par le squelette lui-même. `BottomSheet4RowsWidget` est un widget 100% UI sans `InheritedWidget` propre — aucun slot n'a besoin du context interne. `Widget?` est suffisant pour tous les slots.
- **Décision** : A-003 validée. L'API `Widget?` et `List<Widget>?` suffit. Pas de builder pattern nécessaire pour cette étape.
- **Impact sur spec.md** : A-003 §Assumptions "Validation prévue" → "Validée (2026-05-10)".

---

### CL-004 — Zone expand pendant loading: true

- **Catégorie** : 3 - UX/Interaction
- **Score** : MOYEN
- **Contexte** : spec.md §Edge Cases posait `[NEEDS CLARIFICATION: comportement zone expand quand loading: true]`. Q2 formulait : geler les interactions ou laisser libres.
- **Analyse** : Aucun formulaire Angular (`transaction-form`, `subscription-form`, `debt-form`) ne gèle la zone expand pendant la soumission. Le SCSS ne prévoit pas d'état disabled pour `.bsheet__expand`. Constitution III (YAGNI) : ne pas ajouter de logique spéculative. Le parent peut toujours surcouvrir via `IgnorePointer(ignoring: loading, child: expandedContent)` si son cas métier l'exige — sans modifier le squelette.
- **Décision** : Interactions dans la zone expand **laissées libres** pendant `loading: true`. Le widget ne gère pas ce cas. Alignement exact avec le comportement Angular de référence.
- **Impact sur spec.md** : Marqueur `[NEEDS CLARIFICATION]` retiré de §Edge Cases ligne 140. Q2 §Open Questions passé à "Résolu ✓".

---

### CL-005 — BSheetSubmitVariant.danger : couleur exacte

- **Catégorie** : 10 - Placeholders
- **Score** : MOYEN
- **Contexte** : Q3 posait la question de la couleur du fond de `.bsheet__action-pill--danger`. La proposition par défaut dans la spec mentionnait `colorScheme.error` pour texte/bordure. L'audit SCSS était nécessaire pour confirmer.
- **Analyse** : Audit de `app/src/styles/_bottom-sheet.scss` lignes 385-390 :
  ```scss
  &--danger {
    color: var(--color-expense);   // texte : couleur dépense (rouge/ambre)
    padding: 5px 8px;
    &:hover { background: var(--bg-error); border-color: var(--color-expense); }
  }
  ```
  État au repos : texte `--color-expense`, bordure héritée (`--border-default`), fond transparent. `--color-expense` mappe sur `AppThemeExtension.expenseColor` en Flutter (pas `colorScheme.error` qui est le rouge Material). La proposition de la spec était inexacte sur ce point.
- **Décision** : `BSheetSubmitVariant.danger` → texte `ext.expenseColor`, bordure `ext.expenseColor`, fond `Colors.transparent`. Au survol (état pressed Flutter) : fond `colorScheme.errorContainer`. La spec corrigée sur ce point dans FR-005 / §Q3.
- **Impact sur spec.md** : Q3 §Open Questions corrigé et passé à "Résolu ✓". Mention explicite de `ext.expenseColor` (pas `colorScheme.error`).

---

## Points différés

> Points non résolus dans cette session, à traiter lors d'une prochaine itération.

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Raison du report |
|---|--------|-----------------|-----------|--------|-------------|-------|------------------|
| CL-006 | spec.md §Q5 | Exposer `bsheet__amount--md/--sm` quand `notePreview` consomme de la verticale ? | 1 - Scope | B | B | BAS | YAGNI — aucun des 3 formulaires n'utilise ces modificateurs. Résolution évidente mais hors top 5. |
| CL-007 | spec.md §A-001 | `AppThemeExtension` (16 props) couvre-t-elle tous les tokens du squelette ? | 5 - Intégrations | M | B | BAS | Probable (audit rapide indique oui), mais à confirmer token-par-token en phase plan. |
| CL-008 | spec.md §A-004 | `AnimatedSize` suffit pour 60 fps sur Android low-end avec `InlineDatePicker` imbriqué ? | 4 - Non-fonctionnel | M | B | BAS | À valider par POC en phase research — non bloquant pour la spec. |

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 8 |
| Catégories couvertes | 6/11 (Edge cases, UX/Interaction, Contraintes, Placeholders, Scope, Intégrations) |
| Résolus automatiquement | 5 |
| Résolus interactivement | 0 |
| Différés | 3 |
| Modifications spec.md | 7 (Q1–Q5 fermées, 2 marqueurs NEEDS CLARIFICATION retirés, A-003 validée, Q3 corrigée) |
