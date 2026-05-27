# Review Log — KKS-246

---

## review-spec — 2026-05-27

**Verdict : PASS**

### Warnings (non-bloquants)

- **W-01** — FR-010 : comportement "features désactivées avec toggle" ambigu dans la section Navigation — distinguer visuellement features désactivées dans la liste (position, opacity) à préciser en plan.
- **W-02** — NFR-003 : critère drag feedback "elevation + opacité" non quantifié — à préciser à l'implémentation.
- **W-03** — FR-015 : requirement de nettoyage `settings_section.dart` sans US ni SC associé — à rattacher à SC-005 ou vérifier explicitement dans les tasks.
- **W-04** — US4 scénario 3 : cas symétrique debtDue / feature Dettes désactivée non testé explicitement.
- **W-05** — Health check : erreurs HTTP non-timeout (500, 401, 404) non spécifiées — à traiter comme "Hors ligne" par défaut (à confirmer en plan).

### Infos

- I-01 : SC-006 sans scénario G/W/T explicite pour les routes conservées.
- I-02 : FR-009 ne précise pas le mécanisme de persistance notifications (SharedPreferences vs Drift).
- I-03 : FR-016 sans version précise de `package_info_plus`.

**Commentaire** : Spec complète et cohérente avec la constitution v3.0.0. Aucun bloquant. Les warnings sont des zones de précision à adresser en phase plan/tasks.

---

## review-tasks — 2026-05-27

**Verdict : PASS**

### Warnings (non-bloquants)

- **W-01** — T-013 dépend de T-012 mais pas explicitement de T-014 — ordre recommandé : T-014 avant T-013 (ou simultané).
- **W-02** — Nommage incohérent : tâches T-033 à T-036 taggées `[US3]` mais section nommée "US2b" — tag `[US3]` est correct (aligné spec), titre de section à harmoniser.
- **W-03** — T-036 : dépendances T-034 + T-035 correctes dans le graphe Phase 5 mais déclaration inline inégale.
- **W-04** *(faux positif)* — `textScaleNotifierProvider` signalé absent : existe déjà dans `application/text_scale_notifier.dart`. Pas d'action requise.
- **W-05** — NFR-002 (< 100ms) sans tâche de validation formelle en Phase 4.
- **W-06** *(faux positif)* — `quickstart.md` signalé manquant : créé en phase plan à `docs/features/KKS-246/quickstart.md`. Pas d'action requise.

### Infos

- I-01 : T-022, T-023, T-024 parallélisables (mentionné en Phase 5) mais non marquées `[P]` dans Phase 3.
- I-02 : `HealthCheckResult` créé implicitement dans T-045 — acceptable.
- I-03 : Phase 1 = 1 seule tâche (acceptable pour isolation précoce des conflits de dépendances).

**Commentaire** : 17 FR couverts, 5 US couvertes, ordonnancement sans cycle. Les faux positifs W-04 et W-06 sont levés. Seul point de vigilance réel : confirmer l'ordre T-014 → T-013 à l'implémentation.

---

## implement gate — 2026-05-27

**Gate checklist** : mode dégradé — `checklist.md` absent, gate ignorée.  
**Scan tech** : Flutter `.gitignore` présent et complet. ✅  
**Décision** : implémentation lancée sans blocage.
