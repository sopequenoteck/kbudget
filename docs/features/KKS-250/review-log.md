# Review Log — KKS-250

---

## Review KKS-250 — review-impl
Date : 2026-05-21

### Verdict : PASS

### FR couverts

- **FR-001** : PASS — Conteneur `width: size, height: size`. SVG `size*(2/3)`, emoji `size*0.55`. `size: AppSpacing.space8` dans tile. Skeleton aussi `space8`.
- **FR-002** : PASS — Nom `sizeSm`/`medium`/`onSurfaceVariant`.
- **FR-003** : PASS — `_subtitle()` : `bankName·type` si bankName non null/vide, sinon type seul.
- **FR-004** : PASS — Solde `sizeSm`/`semiBold`/`expenseColor` si `<0`, `onSurfaceVariant` sinon.
- **FR-005** : PASS — Badge `Border.all(outlineVariant)`, `AppRadius.round`, `size2Xs`, `onSurfaceVariant`, padding `h:6/v:1`.
- **FR-006** : PASS — Row inline trash(expenseColor)+Spacer+star(?)+edit. Aucun `PopupMenuButton`.
- **FR-007** : PASS — `Container(surface, radius-xl, Clip.antiAlias)` + Divider `outlineVariant` entre items. `SliverToBoxAdapter`. `RefreshIndicator` préservé.
- **FR-008** : PASS — Section header `{N} COMPTES` (`sizeXs`/`semiBold`/`labelLetterSpacingForSize12`). `_AddButton` 28px circulaire. AppBar sans `actions`.
- **FR-009** : PASS — Empty : `EmptyStateWidget(bank, accountsEmpty, 'Créer un compte')`.
- **FR-010** : PASS — Error : `EmptyStateWidget(warning, accountErrorLoad, accountsRetry)`.
- **FR-011** : PASS — Skeleton `List.generate(3, ...)`.
- **FR-012** : PASS — Trash → `_requestDelete`, state `_confirmDeleteId` au niveau screen. Aucun `AlertDialog`.
- **FR-013** : PASS — `_ConfirmDeleteBlock` : texte, `OutlinedButton(Annuler)`, `FilledButton(Supprimer, expenseColor)`.
- **FR-014** : PASS — `deleteError` affiché conditionellement dans `_ConfirmDeleteBlock`.

### NFR couverts

- **NFR-001** : PASS — API tile étendue avec 6 paramètres. `ConsumerWidget` préservé.
- **NFR-002** : PASS — Aucun nouveau widget en `common_widgets`. Sous-widgets privés dans leurs fichiers.
- **NFR-003** : PASS — 54 tests PASS (6 adaptés + 2 nouveaux _ConfirmDeleteBlock).
- **NFR-004** : PASS — Aucune modification notifier/repository/data layer.

### Constats BLOQUANTS

Aucun.

### Constats mineurs

1. `letterSpacing: 0.6` vs `0.5` spécifié — `labelLetterSpacingForSize12` est le token canonique (0.05em×12px), delta 0.1px négligeable.
2. `foregroundColor: colorScheme.onError` sur bouton Supprimer — à vérifier visuellement que c'est bien blanc dans les deux thèmes.
3. Bottom padding `AppSpacing.space12 * 2` calculé hors token — cosmétique.
