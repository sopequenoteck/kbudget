# Full Review Checklist: Écran Transactions Liste (Flutter)

**Purpose**: Validation exhaustive de la qualité des exigences (UX + Data + Edge cases) avant implémentation
**Created**: 2026-02-22
**Reviewed**: 2026-02-22
**Feature**: [spec.md](../spec.md) | [plan.md](../plan.md)
**Audience**: Auteur (pré-implémentation)
**Depth**: Approfondie
**Result**: 41/41 items traités — 11 amendements appliqués à la spec

## Complétude des exigences fonctionnelles

- [x] CHK001 — Les trois états du résumé mensuel (chargement, données, erreur) sont-ils spécifiés ? **OK** — FR-008 (shimmer), FR-010 (erreur+retry), FR-002 (données) couvrent les 3 états.
- [x] CHK002 — Le comportement du `MonthSelector` aux bornes temporelles est-il défini ? **AMENDÉ** — FR-001 complété : navigation illimitée (pas de borne min/max).
- [x] CHK003 — Le format d'affichage du montant dans chaque `ListItem` est-il explicitement spécifié ? **OK** — FR-013 (séparateurs+devise) + `AmountFormatter` existant gère signe +/-, position devise.
- [x] CHK004 — Le comportement du tap sur une transaction quand le formulaire d'édition n'existe pas encore est-il défini ? **AMENDÉ** — FR-007 complété : no-op si route absente.
- [x] CHK005 — L'écran spécifie-t-il quels champs de la transaction sont affichés dans chaque item ? **OK** — FR-005 explicite : icône catégorie, libellé, nom catégorie (sous-titre), montant coloré.
- [x] CHK006 — Le pull-to-refresh spécifie-t-il s'il recharge aussi le résumé mensuel ou uniquement la liste ? **AMENDÉ** — FR-011 complété : recharge liste + résumé.
- [x] CHK007 — Le comportement au retour du formulaire d'édition est-il spécifié pour le cas où la transaction éditée change de mois ? **OK** — Couvert implicitement : refresh recharge le mois courant, la transaction sortie du mois disparaît. Clarification ajoutée en session full-review.

## Clarté des exigences

- [x] CHK008 — Le terme "bilan" est-il défini formellement ? **OK** — Key Entities + FR-002 : "bilan (recettes - dépenses)" défini formellement.
- [x] CHK009 — Le format exact des en-têtes de jour est-il non ambigu ? **OK** — FR-004a + Research R6 : "Aujourd'hui", "Hier", puis `EEEE d MMMM` locale `fr_FR`.
- [x] CHK010 — Le "style neutre" des transactions ajustement est-il quantifié ? **AMENDÉ** — Edge Cases mis à jour : couleur `onSurface` du thème.
- [x] CHK011 — Les "squelettes shimmer" sont-ils spécifiés en nombre et disposition ? **OK** — Détail d'implémentation. `ListItem.skeleton()` existe déjà. Disposition suit le layout réel.
- [x] CHK012 — Le message d'état vide est-il défini textuellement pour chaque contexte ? **AMENDÉ** — FR-009 complété avec messages distincts par contexte.
- [x] CHK013 — Le "message adapté" pour un filtre sans résultat est-il distinct du message pour un mois sans transaction ? **AMENDÉ** — FR-009 : "Aucune transaction ce mois-ci" vs "Aucune [dépense|recette] ce mois-ci".

## Cohérence des exigences

- [x] CHK014 — Le résumé mensuel "mois complet" (FR-012) est-il cohérent avec l'exclusion des ajustements (FR-002) ? **OK** — Cohérent : "mois complet" = toutes transactions du mois hors filtre, ajustements exclus du calcul uniquement.
- [x] CHK015 — Le format de date dans les `ListItem` (FR-005) est-il cohérent avec les en-têtes de jour (FR-004a) ? **AMENDÉ** — FR-005 mis à jour : la date n'est plus dans l'item (redondante avec l'en-tête). L'item affiche le nom de catégorie en sous-titre.
- [x] CHK016 — Le filtre "Tous" inclut-il les ajustements ? **OK** — Edge Cases + Assumptions cohérents : ajustements dans "Tous", exclus de "Dépenses" et "Recettes".
- [x] CHK017 — L'utilisation du `MonthSelector` est-elle cohérente entre le dashboard et l'écran transactions ? **OK** — Même widget réutilisé, comportement identique par construction.
- [x] CHK018 — Le `SegmentedFilter` exclut-il explicitement un 4e filtre "Ajustements" ? **OK** — FR-003 borne explicitement à 3 options. Pas de 4e filtre prévu.

## Qualité des critères d'acceptation

- [x] CHK019 — SC-001 (< 2s chargement) précise-t-il les conditions de mesure ? **OK** — Acceptable pour app personnelle. Conditions implicites : device mobile typique, mode local ou remote.
- [x] CHK020 — SC-003 (< 100ms filtrage) est-il mesurable ? **OK** — Filtrage client-side de ~100-500 items est trivialement < 100ms.
- [x] CHK021 — SC-006 ("résumé cohérent") est-il vérifiable objectivement ? **AMENDÉ** — Reformulé : "cohérent avec le mois complet sélectionné, indépendamment du filtre actif".
- [x] CHK022 — Les acceptance scenarios définissent-ils des données de test concrètes ? **OK** — Données de test concrètes sont un détail d'implémentation des tests, pas de la spec.

## Couverture des scénarios

- [x] CHK023 — Le scénario de changement rapide de mois est-il adressé ? **AMENDÉ** — FR-016 ajouté : seul le dernier mois demandé est chargé, requêtes intermédiaires ignorées.
- [x] CHK024 — Le scénario de retour après suppression d'une transaction est-il couvert ? **OK** — Couvert par le mécanisme de refresh au retour (R7). La transaction supprimée disparaît au reload du mois.
- [x] CHK025 — Le scénario pull-to-refresh pendant un changement de mois est-il adressé ? **OK** — Détail d'implémentation. `isLoading` empêche les opérations concurrentes.
- [x] CHK026 — Le scénario de transactions même date, heures différentes est-il couvert ? **OK** — `DateTime` inclut l'heure. Tri par date desc est stable intra-jour.
- [x] CHK027 — Le scénario d'un très grand nombre de transactions (>100) est-il adressé ? **OK** — Scale déclarée dans le plan : ~100-500 tx/mois max (usage personnel). Pas de pagination nécessaire.

## Couverture des cas limites

- [x] CHK028 — Le comportement pour `montant = 0` est-il défini ? **OK** — `AmountFormatter` gère montant=0 (affiche "0,00 €"). Couleur selon le type.
- [x] CHK029 — Le comportement pour une transaction sans `accountId` est-il défini ? **OK** — `accountId` n'est pas affiché dans les items de liste. Pas d'impact.
- [x] CHK030 — Le formatage des différentes devises est-il couvert ? **OK** — `AmountFormatter` supporte EUR (2 déc.), XOF (0 déc.), USD, GBP, CHF, CAD, MAD.
- [x] CHK031 — Le comportement pour un transfert (`transferId` non null) est-il distinct ? **OK** — Hors scope v1. Les transferts s'affichent comme des transactions normales.
- [x] CHK032 — Le groupement par jour gère-t-il les fuseaux horaires ? **OK** — Détail d'implémentation. `DateTime` gère les fuseaux nativement.
- [x] CHK033 — L'ellipsis sur les libellés longs est-il spécifié ? **OK** — Edge Cases : "Le texte est tronqué avec ellipsis". `ListItem` utilise `Text` avec `overflow`.

## Exigences non-fonctionnelles

- [x] CHK034 — Les exigences d'accessibilité sont-elles définies ? **AMENDÉ** — NFR-001 et NFR-002 ajoutés : semantic labels sur les items, contrastes respectés via thème.
- [x] CHK035 — Le comportement en mode sombre est-il spécifié ? **OK** — `AppThemeExtension` définit income/expense colors pour light ET dark.
- [x] CHK036 — Les exigences de localisation sont-elles couvertes ? **OK** — FR-013 (montants) + FR-004a (dates) + package `intl` avec locale `fr_FR`.
- [x] CHK037 — Le comportement offline est-il défini ? **OK** — FR-010 couvre l'état d'erreur avec retry, applicable au mode remote sans réseau.

## Dépendances & Hypothèses

- [x] CHK038 — L'hypothèse `MonthSelector` réutilisé tel quel est-elle validée ? **OK** — Widget uncontrolled avec `onChanged` callback, compatible avec le besoin.
- [x] CHK039 — L'hypothèse `SegmentedFilter<T>` réutilisé est-elle validée ? **OK** — Widget générique `SegmentedFilter<T>`, accepte tout type dont un enum custom.
- [x] CHK040 — La dépendance vers l'endpoint API est-elle documentée ? **OK** — Documentée dans Research R1. Mode local (Drift) fonctionne sans API. Non bloquant.
- [x] CHK041 — L'hypothèse formulaire d'édition bloque-t-elle US4 ? **OK** — Dépendance reconnue dans Assumptions. US4 prépare la navigation (FR-007 : no-op si route absente).

## Résumé

| Catégorie | Total | Validés | Amendés |
|-----------|-------|---------|---------|
| Complétude fonctionnelle | 7 | 4 | 3 |
| Clarté | 6 | 3 | 3 |
| Cohérence | 5 | 4 | 1 |
| Critères d'acceptation | 4 | 3 | 1 |
| Couverture scénarios | 5 | 4 | 1 |
| Cas limites | 6 | 6 | 0 |
| Non-fonctionnel | 4 | 3 | 1 |
| Dépendances | 4 | 4 | 0 |
| **Total** | **41** | **31** | **10** |

**Note** : Un 11e amendement (FR-016 — changement rapide de mois) a été ajouté aux Functional Requirements.
