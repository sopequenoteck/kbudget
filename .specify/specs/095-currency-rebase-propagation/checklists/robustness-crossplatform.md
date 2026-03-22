# Robustness & Cross-Platform Checklist: Currency Rebase Propagation

**Purpose**: Valider la qualité, complétude et cohérence des exigences de robustesse (transactionalité, edge cases, propagation) et de symétrie cross-platform (Backend/Angular/Flutter).
**Created**: 2026-03-15
**Feature**: [spec.md](../spec.md)
**Depth**: Approfondi
**Audience**: Reviewer (PR / pre-implementation)
**Validated**: 2026-03-15

## Requirement Completeness

- [x] CHK001 - Les exigences de rebase couvrent-elles explicitement le cas où `currencies` est null dans la request (partial update) ? [Completeness, Contract §PUT] — Oui, contrat dit "Si `currencies` est null → aucun rebase (partial update)"
- [x] CHK002 - Les exigences de rebase précisent-elles le comportement quand `currencies[0]` est identique à l'actuel (no-op) ? [Completeness, Contract §PUT] — Oui, FR-006 + contrat : "Si `oldPrimary == newPrimary`, aucun rebase (no-op)"
- [x] CHK003 - FR-001 définit-il explicitement ce qui constitue un "changement de devise principale" (réordonnancement vs ajout/suppression de devise) ? [Completeness, Spec §FR-001] — Oui, FR-001 dit "réordonnancement de la liste des devises", FR-006 compare oldPrimary vs newPrimary
- [x] CHK004 - Les exigences couvrent-elles le cas où l'utilisateur ajoute une nouvelle devise sans changer la devise principale ? [Completeness, Gap] — Oui, couvert implicitement par FR-006 : "Si `oldPrimary == newPrimary`, aucun rebase"
- [x] CHK005 - Les exigences de l'indicateur visuel (FR-005) précisent-elles sur quels écrans exactement il doit apparaître au-delà du dashboard ? [Completeness, Spec §FR-005] — Oui, FR-005 dit explicitement "total agrégé" uniquement (dashboard). Pas d'autres écrans.
- [x] CHK006 - Les exigences définissent-elles le comportement quand l'utilisateur n'a aucun taux de change configuré mais possède des comptes multi-devises ? [Completeness, Gap] — Oui, couvert par FR-005 : indicateur apparaît "quand au moins une conversion a échoué faute de taux de change disponible"

## Requirement Clarity

- [x] CHK007 - "Automatiquement rebasés" (FR-001) est-il défini avec la formule de calcul précise (inversion, cross-rate) ? [Clarity, Spec §FR-001] — Oui, US1 donne des exemples numériques (EUR→XOF), Assumptions référence "inversion + cross-rate", data-model.md détaille la formule
- [x] CHK008 - "Mise à jour en moins de 2 secondes" (SC-002) précise-t-il le point de mesure (depuis le clic utilisateur ou depuis la réponse serveur) ? [Clarity, Spec §SC-002] — Oui, SC-002 dit "après le clic de l'utilisateur"
- [x] CHK009 - "Changements rapides successifs" (FR-006) est-il quantifié avec des seuils précis (SC-004 dit 3+ en 10s, mais FR-006 reste vague) ? [Clarity, Spec §FR-006] — Oui, FR-006 dit "Le dernier changement l'emporte (sérialisation côté serveur via transaction)", SC-004 quantifie "3+ en 10s"
- [x] CHK010 - L'indicateur visuel "icône/tooltip" (FR-005) est-il spécifié avec l'icône exacte et le texte du tooltip ? [Clarity, Spec §FR-005] — Partiellement : FR-005 dit "icône/tooltip", tasks.md précise "ph-warning-circle" + "Certains montants n'ont pas pu être convertis". Niveau spec approprié, détail dans tasks.
- [x] CHK011 - "Rollback complet" (FR-002) précise-t-il explicitement que les taux ET la devise principale restent inchangés ? [Clarity, Spec §FR-002] — Oui, Edge Case dit "la devise principale et les taux restent inchangés", FR-002 dit "le changement de devise principale est annulé (rollback complet)"

## Requirement Consistency

- [x] CHK012 - Les acceptance scenarios de US1 et US2 sont-ils cohérents sur la liste des écrans impactés (dashboard, budgets, dettes, abonnements) ? [Consistency, Spec §US1/US2] — Oui, US1 et US2 mentionnent tous les deux "dashboard, budgets, dettes, abonnements"
- [x] CHK013 - FR-005 mentionne "total agrégé" uniquement, mais US3-AS1 mentionne "solde total converti" — ces termes désignent-ils la même chose ? [Consistency, Spec §FR-005 vs §US3] — Oui, FR-005 les utilise ensemble : "total agrégé (icône/tooltip à côté du solde total converti)"
- [x] CHK014 - US3-AS2 mentionne les dettes avec un comportement (montant natif sans conversion), mais FR-005 dit "indicateur sur le total agrégé uniquement" — y a-t-il un conflit sur le scope de l'indicateur ? [Consistency, Spec §FR-005 vs §US3-AS2] — Non, pas de conflit : FR-005 clarifie "Les montants individuels non convertis restent affichés dans leur devise native — le montant natif est toujours correct, seule la conversion en devise principale est absente"
- [x] CHK015 - Le contrat API mentionne HTTP 500 pour échec du rebase, mais la spec parle de "rollback complet" sans mentionner le code HTTP — sont-ils alignés ? [Consistency, Spec §FR-002 vs Contract] — Oui, contrat dit "HTTP 500 + rollback complet (devise ET taux inchangés)", spec dit "rollback complet" — complémentaires

## Acceptance Criteria Quality

- [x] CHK016 - SC-001 ("100% des taux rebasés") est-il mesurable avec un scénario de test précis (nombre de taux, devises impliquées) ? [Measurability, Spec §SC-001] — Oui, US1-AS1 fournit un scénario concret (EUR→XOF + EUR→USD, vérifier que tous les taux sont rebasés)
- [x] CHK017 - SC-003 précise-t-il les conditions exactes de déclenchement de l'indicateur (au moins 1 conversion échouée parmi combien ?) ? [Measurability, Spec §SC-003] — Oui, FR-005 dit "quand au moins une conversion a échoué faute de taux de change disponible"
- [ ] CHK018 - SC-004 ("3+ changements en 10 secondes") définit-il comment mesurer "pas de corruption" (comparaison des taux avant/après, valeurs attendues) ? [Measurability, Spec §SC-004] — Partiel : FR-006 décrit le mécanisme (sérialisation, dernier l'emporte) mais pas de méthode de mesure explicite. Acceptable : vérifiable en comparant l'état final avec le résultat attendu du dernier changement.
- [ ] CHK019 - SC-005 ("snapshots inchangés") définit-il quels champs des snapshots doivent être comparés ? [Measurability, Spec §SC-005] — Partiel : FR-007 dit "taux capturés au moment du snapshot sont immuables". Le champ clé est `tauxChange` dans BudgetSnapshot. Non explicite dans la spec mais dérivable du data-model existant.

## Scenario Coverage — Robustesse

- [x] CHK020 - Les exigences définissent-elles le comportement quand `rebaseRates()` réussit partiellement (certains taux rebasés, d'autres non) ? [Coverage, Exception Flow] — N/A : FR-002 est transactionnel (all-or-nothing). Un succès partiel est impossible par design.
- [x] CHK021 - Les exigences couvrent-elles le cas d'une erreur réseau côté frontend lors du rechargement des taux (GET /exchange-rates échoue après un PUT réussi) ? [Coverage, Exception Flow] — Oui, FR-008 couvre : "message d'erreur + retry + indicateur taux périmés"
- [x] CHK022 - Les exigences précisent-elles le comportement si le frontend envoie un PUT avec la même devise principale mais un ordre différent des devises secondaires ? [Coverage, Alternate Flow] — Oui, FR-006 : "Si `oldPrimary == newPrimary`, aucun rebase (no-op)" — les devises secondaires changent mais pas de rebase
- [ ] CHK023 - Les exigences couvrent-elles le cas d'un taux de change avec une valeur de 0 ou négative pendant le rebase ? [Coverage, Edge Case] — Non couvert explicitement. Géré par la validation existante dans ExchangeRateService (taux > 0). Risque faible.
- [x] CHK024 - Les exigences définissent-elles la précision d'arrondi attendue après un rebase (nombre de décimales) ? [Coverage, Spec §data-model] — Oui, data-model.md : "precision 20, scale 6" et "Arrondi : HALF_UP, 6 décimales"
- [ ] CHK025 - Les exigences couvrent-elles le comportement quand le rebase produit un taux extrêmement petit (ex: 0.000001) ou extrêmement grand ? [Coverage, Edge Case] — Non couvert explicitement. Le schéma DB (precision 20 scale 6) supporte ces valeurs. Risque faible pour ~7 devises.

## Scenario Coverage — Cross-Platform

- [x] CHK026 - Les exigences de rechargement des taux (FR-003) sont-elles symétriques entre Angular et Flutter (même séquence d'appels API) ? [Coverage, Spec §FR-003] — Oui, FR-003 + contrat + FR-009 (WebSocket) s'appliquent aux deux plateformes de manière identique
- [x] CHK027 - Les exigences de l'indicateur visuel (FR-005) spécifient-elles la même icône et le même texte de tooltip sur Angular et Flutter ? [Coverage, Spec §FR-005] — Oui, tasks.md spécifie Phosphor "warning-circle" pour les deux (ph-warning-circle Angular, PhosphorIcons.warningCircle Flutter)
- [x] CHK028 - Les exigences définissent-elles le comportement de l'indicateur taux manquant quand l'utilisateur passe d'Angular à Flutter (ou inversement) après un changement de devise ? [Coverage, Gap] — Oui, les deux plateformes consomment la même API (GET /exchange-rates). Le rebase est serveur-side, FR-009 push WebSocket aux deux.
- [x] CHK029 - Les exigences de propagation UI (FR-004) précisent-elles quels écrans Flutter doivent se mettre à jour (dashboard, dettes, abonnements) de manière symétrique avec Angular ? [Coverage, Spec §FR-004] — Oui, US2-AS3 dit "les mêmes mises à jour instantanées se produisent que sur la version web"
- [x] CHK030 - Les exigences couvrent-elles le cas où Flutter est en mode local (Drift/SQLite) et que les taux doivent quand même être rechargés depuis l'API ? [Coverage, Gap] — Oui, Assumptions dit "Les taux de change sont server-only dans Flutter (pas de table Drift). En mode local, les taux ne sont pas disponibles et aucun rebase n'est nécessaire."

## Edge Case Coverage

- [x] CHK031 - Le edge case "une seule devise" précise-t-il que le rebase ne doit PAS être déclenché (et pas simplement "aucun changement visible") ? [Edge Case, Spec §Edge Cases] — Oui, Edge Case dit "Aucun rebase nécessaire" + FR-006 "Si `oldPrimary == newPrimary`, aucun rebase (no-op)"
- [x] CHK032 - Le edge case "changements rapides" définit-il si les requêtes doivent être sérialisées ou si le dernier changement l'emporte ? [Edge Case, Spec §Edge Cases] — Oui, FR-006 + Edge Case : "Le dernier changement l'emporte (sérialisation via transaction côté serveur)"
- [ ] CHK033 - Les exigences couvrent-elles le cas où l'utilisateur supprime toutes les devises sauf une pendant le même appel qui change la devise principale ? [Edge Case, Gap] — Non couvert explicitement. Géré par la validation existante de PreferenceService (currencies non-vide, min 1). Risque faible.
- [x] CHK034 - Les exigences définissent-elles le comportement si `rebaseRates()` est appelé avec oldPrimary == newPrimary (guard clause) ? [Edge Case, Gap] — Oui, FR-006 dit "Si `oldPrimary == newPrimary`, aucun rebase n'est déclenché (no-op)"

## Non-Functional Requirements

- [x] CHK035 - Les exigences de logging (VI. Observabilité) spécifient-elles le niveau de log et le format du message pour le rebase automatique ? [Non-Functional, Spec §plan Constitution Check] — Oui, plan Constitution Check VI + tasks T002 : "log INFO pour le déclenchement automatique"
- [ ] CHK036 - Les exigences de performance sont-elles définies pour le rebase côté serveur (temps max pour N taux) ? [Non-Functional, Gap] — Non explicite. SC-002 dit "< 2 secondes" total (incluant rebase + rechargement). À l'échelle du projet (~10-20 taux), le rebase serveur est trivial (<50ms). Risque négligeable.
- [x] CHK037 - Les exigences de sécurité précisent-elles que le rebase ne doit affecter que les taux de l'utilisateur authentifié (isolation des données) ? [Non-Functional, Spec §Constitution II] — Oui, plan Constitution Check II : "Le rebase utilise le userId authentifié"

## Dependencies & Assumptions

- [x] CHK038 - L'assumption que `rebaseRates()` "fonctionne correctement" est-elle validée par des tests existants référencés ? [Assumption, Spec §Assumptions] — Oui, research.md R1 : "testée et utilisée dans d'autres contextes (feature 070)"
- [x] CHK039 - L'assumption que les frameworks frontend "propagent automatiquement" est-elle documentée avec les mécanismes spécifiques (quels signals/providers) ? [Assumption, Spec §Assumptions] — Oui, research.md R3 (chaîne Angular Signals) et R4 (chaîne Flutter Riverpod) détaillent les mécanismes
- [x] CHK040 - L'assumption "single-user" est-elle cohérente avec un éventuel usage multi-device simultané (même utilisateur, 2 navigateurs) ? [Assumption, Spec §Assumptions] — Oui, Assumptions mis à jour : "Le multi-device simultané est géré via WebSocket STOMP (push d'événement après rebase)" + FR-009

## Notes

- Focus : Robustesse + Cross-Platform (approfondi)
- **Résultat : 34/40 items passent (85%)**
- 6 items restent non cochés (CHK018, CHK019, CHK023, CHK025, CHK033, CHK036) — tous à risque faible :
  - CHK018/019 : mesurabilité partielle des SC-004/SC-005, vérifiable lors de l'écriture des tests
  - CHK023/025 : taux extrêmes/invalides — gérés par les validations et contraintes DB existantes
  - CHK033 : suppression de devises simultanée — gérée par la validation existante de PreferenceService
  - CHK036 : perf serveur non explicite — trivial à l'échelle du projet (~10-20 taux)
- Aucun item critique ou bloquant restant
