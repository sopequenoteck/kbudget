# Clarify Log — KKS-240 : Phase 1 / Étape 4 — Refonte 4 écrans liste Flutter

> Date : 2026-05-10
> Issue : KKS-240
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md FR-009 / US-003 §AS-1 | Icône Abonnements hero "N actifs" : `PhosphorCheckCircle` vs `PhosphorRepeat` (Angular) | UX/Interaction | B | B | BAS | `PhosphorRepeat` — aligné sur Angular | Auto |
| CL-002 | spec.md FR-006, FR-010, FR-013 | Type du `date-label` : widget standalone vs `Padding+Text` inline par écran | Contraintes | H | H | CRITIQUE | `Padding(child: Text(...))` inline — aligné sur pattern `<div class="date-label">` Angular | Auto |
| CL-003 | spec.md FR-010 / US-003 §IT | Abonnements : SectionHeaderSticky global absent — spec spécifie 2 SectionHeaderSticky Actifs/Inactifs mais pas de global | UX/Interaction | H | H | CRITIQUE | 1 SectionHeaderSticky global "Abonnements · N actifs" + date-labels Actifs/Inactifs — cohérent avec Transactions/Dettes | Auto |
| CL-004 | spec.md FR-010 | Abonnements sections : SectionHeaderSticky par section vs date-label léger | UX/Interaction | H | H | CRITIQUE | date-labels inline pour "Actifs"/"Inactifs" — SectionHeaderSticky global seul | Auto |
| CL-005 | spec.md SC-005, SC-006 | `find(Key('hero_*'))` : wildcard invalide en Flutter — syntaxe de test impossible | Signaux de complétion | B | B | BAS | Keys concrètes : `'dashboard_hero'`, `'transaction_hero'`, `'subscription_hero'`, `'debt_hero'` — et skeletons `'*_hero_skeleton'` | Auto |
| CL-006 | spec.md A-003 | Total annuel Abonnements : formule `monthlyTotal × 12` — validité sans modifier le notifier | Modèle de données | H | M | HAUT | Validé — `subscription_notifier.dart` normalise déjà : `annuel→montant/12`, `mensuel→montant`, `hebdo→montant×4.33` → `total×12` correct | Auto |
| CL-007 | spec.md FR-006 | Groupes sémantiques Transactions : quid si le mois sélectionné est passé (pas "Aujourd'hui"/"Hier") ? | Edge cases | B | M | BAS | Différé — la sélection de mois reste dans le notifier ; si mois passé tous les items tombent en "Plus ancien" (comportement acceptable) | Différé |

---

## Résolutions détaillées

### CL-001 — Icônes Abonnements hero : `PhosphorRepeat` au lieu de `PhosphorCheckCircle`

- **Catégorie** : UX/Interaction
- **Score** : BAS
- **Contexte** : US-003 Scenario 1 et FR-009 utilisaient `Phosphor CheckCircle` pour la meta-line "N actifs". L'écran Angular correspondant (`subscriptions.html`) utilise `phosphorRepeat` pour la meta-line d'actifs.
- **Analyse** : Lecture de `app/src/app/features/subscriptions/subscriptions.html` — icône `app-phosphor-icon name="repeat"` pour "N actifs" et `app-phosphor-icon name="calendar-blank"` pour "/an".
- **Décision** : `PhosphorRepeat` pour "N actifs", `PhosphorCalendarBlank` pour "≈ X€/an" — parité Angular.
- **Impact sur spec.md** : US-003 §AS-1 + FR-009 mis à jour.

---

### CL-002 — `date-label` : widget inline `Padding+Text`, pas de widget standalone

- **Catégorie** : Contraintes
- **Score** : CRITIQUE
- **Contexte** : Les FRs mentionnaient `date-label` comme concept sans préciser si c'est un widget Flutter dédié (ex. `DateLabelWidget`) ou un pattern inline. Créer un widget standalone introduirait une abstraction inutile et une dépendance croisée entre écrans.
- **Analyse** : Pattern Angular `_list-patterns.scss` : `.date-label` est un simple `<div class="date-label">` stylistique — pas un composant Angular. Principe YAGNI de la constitution.
- **Décision** : `date-label` = `Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2), child: Text(label, style: AppTypography.bodySmall.copyWith(color: color)))` inline dans chaque screen. Pas de widget dédié.
- **Impact sur spec.md** : FR-006 et FR-013 complétés avec la précision "widget inline `Padding(child: Text(...))` — pas de widget standalone dédié".

---

### CL-003 + CL-004 — Abonnements : 1 SectionHeaderSticky global + date-labels Actifs/Inactifs

- **Catégorie** : UX/Interaction
- **Score** : CRITIQUE
- **Contexte** : La spec initiale décrivait 2 `SectionHeaderSticky` séparés pour Actifs et Inactifs, sans mentionner de SectionHeaderSticky global. Cela violait le pattern des 3 autres écrans (1 global par écran) et créait une incohérence visible.
- **Analyse** :
  - Transactions : 1 SectionHeaderSticky "Transactions" global + date-labels sémantiques
  - Dettes : 1 SectionHeaderSticky "Dettes · K en cours" global + date-labels temporels
  - Angular Abonnements : `<app-section-header-sticky [title]="'Abonnements · ' + activeCount + ' actifs'"` = 1 global, puis date-labels par bucket
- **Décision** : 1 `SectionHeaderSticky` global "Abonnements · N actifs" + date-labels inline "Actifs"/"Inactifs" (couleur `onSurfaceVariant`). Cohérence parfaite entre les 4 écrans.
- **Impact sur spec.md** : US-003 §Independent Test + §AS-2 + FR-010 réécrits. FR-014 ajouté (Keys structurelles).

---

### CL-005 — SC-005/SC-006 : Keys Flutter concrètes

- **Catégorie** : Signaux de complétion
- **Score** : BAS
- **Contexte** : `find(Key('hero_*'))` utilise un wildcard qui n'existe pas en Flutter — `Key` est une valeur exacte, pas un pattern glob. Le test échouerait à la compilation.
- **Analyse** : Flutter `find.byKey(Key('...'))` requiert une chaîne exacte. Pattern validé dans les tests existants du projet (`bottom_sheet_4_rows_widget_test.dart`).
- **Décision** : Keys concrètes déclarées dans FR-014 et SC-005/SC-006 : `'dashboard_hero'`, `'transaction_hero'`, `'subscription_hero'`, `'debt_hero'` ; skeletons : `'dashboard_hero_skeleton'`, etc.
- **Impact sur spec.md** : FR-014 ajouté ; SC-005 et SC-006 mis à jour.

---

### CL-006 — A-003 : total annuel Abonnements calculable sans modifier le notifier

- **Catégorie** : Modèle de données
- **Score** : HAUT
- **Contexte** : A-003 affirmait que le total annuel pouvait être calculé côté widget sans modifier `SubscriptionNotifier`, mais la formule n'était pas vérifiée.
- **Analyse** : Lecture de `flutter/lib/src/features/subscriptions/application/subscription_notifier.dart` — `monthlyTotals` est déjà calculé avec normalisation : `Frequency.annuel → montant/12`, `Frequency.mensuel → montant`, `Frequency.hebdomadaire → montant×4.33`. Le widget peut donc faire `monthlyTotal × 12` pour obtenir le total annuel.
- **Décision** : A-003 marquée "Validé" avec source documentée. Aucune modification du notifier requise.
- **Impact sur spec.md** : A-003 mise à jour avec formule et source.

---

## Points différés

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Raison du report |
|---|--------|-----------------|-----------|--------|-------------|-------|------------------|
| CL-007 | spec.md FR-006 | Groupes sémantiques Transactions si mois passé sélectionné (tous → "Plus ancien") | Edge cases | B | M | BAS | Comportement par défaut acceptable ; hors scope de cette clarification. À mentionner en plan si nécessaire. |

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 7 |
| Catégories couvertes | 4/11 (UX/Interaction, Contraintes, Signaux de complétion, Modèle de données, Edge cases) |
| Résolus automatiquement | 6 |
| Résolus interactivement | 0 |
| Différés | 1 |
| Modifications spec.md | 8 (US-003 ×2, FR-006, FR-009, FR-010, FR-013, FR-014 ajouté, FR-015/FR-016/FR-017 renumérotés, SC-005, SC-006, A-003) |
