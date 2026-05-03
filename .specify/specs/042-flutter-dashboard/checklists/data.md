# Checklist: Data & Calculations — Flutter Dashboard

**Purpose**: Valider la qualite, completude et coherence des exigences relatives aux sources de donnees, calculs derives et comportement multi-devises du dashboard.
**Created**: 2026-02-22
**Feature**: 042-flutter-dashboard
**Audience**: Reviewer (PR review)
**Depth**: Standard
**Validated**: 2026-02-22

---

## Requirement Completeness

- [x] CHK001 - Les exigences definissent-elles comment le resume mensuel gere l'affichage multi-devises (un bloc par devise, ou un seul agrege) ? [Completeness, Spec §FR-005] — **Resolu**: Spec clarification + FR-005 : "filtres sur la devise par defaut de l'utilisateur uniquement". Un seul bloc.
- [x] CHK002 - Les exigences specifient-elles l'ordre d'affichage des resumes multi-devises (devise par defaut en premier ?) ? [Completeness, Spec §FR-005] — **N/A**: Seule la devise par defaut est affichee, pas de multi-devises.
- [x] CHK003 - Les exigences definissent-elles le comportement du message de bienvenue en mode local (pas de JWT, donc pas de nom) ? [Completeness, Spec §FR-015] — **Resolu**: Research R-002 : message generique "Bonjour" si nom indisponible (mode local ou name absent).
- [x] CHK004 - Les exigences specifient-elles quelles donnees sont rechargees lors du pull-to-refresh (toutes les sections, ou seulement celles visibles) ? [Completeness, Spec §FR-016] — **Resolu**: FR-016 : "recharger toutes les sections du dashboard simultanement".
- [x] CHK005 - Les exigences definissent-elles le tri des 5 dernieres transactions (par date decroissante ?) et sur quels comptes (tous ou compte hero) ? [Completeness, Spec §FR-007] — **Resolu**: Tri par date decroissante (implicite "dernieres"), tous comptes confondus (coherent avec resume mensuel = vision globale).
- [x] CHK006 - Les exigences definissent-elles la sequence de chargement (parallele ou sequentiel) des 5 sources de donnees du dashboard ? [Gap] — **Resolu**: Detail d'implementation. Les providers Riverpod chargent concurremment. Le DashboardNotifier orchestre via watch/read des providers existants.

## Requirement Clarity

- [x] CHK007 - Le terme "solde" dans le compte hero est-il clarifie : solde initial, solde calcule (initial + transactions), ou solde retourne par l'API ? [Clarity, Spec §FR-001] — **Resolu**: FR-001 : "solde calcule = soldeInitial + somme des transactions du compte".
- [x] CHK008 - La formule de normalisation des abonnements est-elle precise pour les cas limites (montant = 0, abonnement inactif avec frequence annuelle) ? [Clarity, Spec §US4-SC1] — **Resolu**: Research R-003 : filtrer `actif == true` (inactifs exclus). montant = 0 contribue 0. Formule : mensuel ? montant : montant/12.
- [x] CHK009 - Le calcul du solde net des dettes est-il specifie pour le cas multi-devises (un solde net par devise, ou conversion ?) ? [Clarity, Spec §US4-SC2] — **Decision**: Somme toutes devises confondues (app personnelle, single-user, probablement meme devise). Pas de conversion. Afficher sans symbole devise ou avec devise par defaut.
- [x] CHK010 - Le "chiffre cle" et le "sous-texte descriptif" de chaque mini-card sont-ils explicitement definis avec le format attendu ? [Clarity, Spec §FR-010] — **Resolu**: Clarifications spec : Abonnements = montant mensuel normalise + "{n} abonnements actifs". Dettes = solde net + "{n} dettes en cours". T020 documente le format.
- [x] CHK011 - La reference "max(recettes, depenses)" pour les barres de progression est-elle documentee comme etant par devise ou tous devises confondues ? [Clarity, Spec §FR-005] — **Resolu**: Par devise par defaut uniquement (FR-005). Data-model.md documente la formule.
- [x] CHK012 - Le seuil de "5 comptes ou plus" pour "Voir tout" est-il sans ambiguite (inclut-il le compte hero dans le decompte ?) ? [Clarity, Spec §FR-003] — **Decision**: 5 comptes actifs total, hero inclus dans le decompte. 5 actifs = 1 hero + 4 lignes → "Voir tout" apparait.

## Requirement Consistency

- [x] CHK013 - La clarification "3 a 5 transactions" (US3) est-elle coherente avec FR-007 qui dit "5 maximum" ? [Consistency, Spec §US3 vs §FR-007] — **Corrige**: Fix I1 applique — US3 dit maintenant "jusqu'a 5 maximum", aligne avec FR-007.
- [x] CHK014 - L'Independent Test de US4 mentionne "modules actives" alors que la clarification confirme que les modules sont hardcodes. Les deux formulations sont-elles alignees ? [Consistency, Spec §US4] — **Accepte**: Formulation approximative mais non-bloquante. "Modules actives" = les 2 modules hardcodes sont toujours actifs.
- [x] CHK015 - La clarification initiale mentionne un "objectif budget mensuel" (ligne 14) tandis que la clarification suivante le reporte. La spec contient-elle encore des references residuelles a cet objectif ? [Consistency, Spec §Clarifications] — **Resolu**: FR-005 documente explicitement le report. Clarification : "utiliser uniquement le fallback max(recettes, depenses)". Pas de reference residuelle active.

## Acceptance Criteria Quality

- [x] CHK016 - Les criteres de succes SC-001 ("< 2 secondes") et SC-003 ("< 1 seconde") sont-ils mesurables dans le contexte Flutter (comment les verifier ?) ? [Measurability, Spec §SC-001/SC-003] — **Accepte**: Guidelines UX verifiables par profiling Flutter (DevTools timeline). Pas de test automatise requis pour une app personnelle.
- [x] CHK017 - Le critere SC-005 ("donnees agregees justes") definit-il des valeurs attendues verifiables ou reste-t-il qualitatif ? [Measurability, Spec §SC-005] — **Accepte**: Verifiable via unit tests sur les calculs du DashboardNotifier (formules documentees dans data-model.md).
- [x] CHK018 - Le critere SC-002 ("~1.5 ecrans") est-il quantifiable objectivement (quelle resolution de reference ?) ? [Measurability, Spec §SC-002] — **Accepte**: Guideline UX approximative. Verification visuelle sur device standard (iPhone 14 / Pixel 7 ~390x844pt). Le "~" indique explicitement l'approximation.

## Scenario Coverage

- [x] CHK019 - Les exigences definissent-elles le comportement quand aucun compte n'a `isDefault == true` (tous les comptes actifs mais aucun par defaut) ? [Coverage, Edge Case] — **Decision**: Premier compte actif de la liste (ordre retourne par le notifier, typiquement par date de creation). Documente dans T013.
- [x] CHK020 - Les exigences definissent-elles le comportement quand le chargement d'une seule section echoue (ex: summary API en erreur mais comptes charges) ? [Coverage, Exception Flow] — **Resolu**: Edge case spec : "sections reussies affichees normalement, sections en echec affichent un message d'erreur inline avec option de reessayer". Fix C1 applique dans tasks T014/T016/T018/T020.
- [x] CHK021 - Les exigences definissent-elles si les transactions de type "ajustement" (AJUSTEMENT) apparaissent dans les 5 dernieres transactions ? [Coverage, Spec §FR-007] — **Decision**: Oui, inclure tous types de transactions (AJUSTEMENT inclus). Ce sont des operations valides que l'utilisateur doit voir.
- [x] CHK022 - Les exigences definissent-elles le comportement des mini-cards quand l'utilisateur n'a aucun abonnement ou aucune dette (compteur = 0, montant = 0) ? [Coverage, Edge Case] — **Resolu**: Cards toujours visibles (hardcodees). Montant = 0 et count = 0 sont des valeurs valides affichees normalement.

## Edge Case Coverage — Data

- [x] CHK023 - Les exigences definissent-elles le comportement quand `totalRecettes == 0 AND totalDepenses == 0` pour les barres de progression (division par zero) ? [Edge Case, Spec §FR-005] — **Resolu**: Data-model.md : `maxRef > 0 ? totalRecettes / maxRef : 0`. Pas de division par zero, barres a 0.
- [x] CHK024 - Les exigences definissent-elles la couleur du solde quand il est exactement egal a zero (ni vert ni rouge ?) ? [Edge Case, Spec §FR-006] — **Resolu**: Clarification spec : "Couleur neutre (couleur texte par defaut du theme)". FR-006 le confirme.
- [x] CHK025 - Les exigences definissent-elles le comportement quand le JWT est expire ou malformed pour l'extraction du nom utilisateur ? [Edge Case, Spec §FR-015] — **Resolu**: Approche corrigee (R-002 mis a jour) : le nom est lu depuis FlutterSecureStorage (persiste au login), pas depuis le JWT. Si absent → fallback null → message generique "Bonjour".
- [x] CHK026 - Les exigences definissent-elles les bornes de navigation du selecteur de mois (peut-on aller dans le futur ? jusqu'a quand dans le passe ?) ? [Edge Case, Spec §FR-004] — **Resolu**: Clarification spec : "Max = mois courant (pas de futur), pas de borne inferieure."
- [x] CHK027 - Les exigences definissent-elles la devise d'affichage du montant mensuel des abonnements quand ils sont en devises mixtes ? [Edge Case, Spec §US4-SC1] — **Decision**: Somme toutes devises confondues (meme raisonnement que CHK009 — app personnelle, single-user). Afficher avec devise par defaut de l'utilisateur.

## Non-Functional Requirements — Data

- [x] CHK028 - Les exigences definissent-elles une strategie de cache ou de fraicheur des donnees du dashboard (combien de temps garder les donnees en memoire) ? [Gap, NFR] — **Accepte**: Pas de cache explicite. State Riverpod en memoire, rafraichi par pull-to-refresh ou navigation. Suffisant pour app personnelle.
- [x] CHK029 - Les exigences definissent-elles le comportement offline en mode serveur (donnees cachees localement ou erreur ?) ? [Gap, NFR] — **Resolu**: Gere par l'erreur inline par section (fix C1). En mode serveur offline → chaque section affiche son erreur avec retry.
- [x] CHK030 - Les exigences definissent-elles la taille maximale attendue des jeux de donnees (nombre max de comptes, transactions, abonnements, dettes) pour garantir la performance ? [Gap, NFR] — **Accepte**: App personnelle single-user. Datasets attendus < 20 comptes, < 10000 transactions, < 50 abonnements, < 50 dettes. Performance non critique a cette echelle.

## Dependencies & Assumptions

- [x] CHK031 - L'hypothese que le claim `name` est present dans le JWT est-elle validee avec le backend (quel claim exact : `name`, `sub`, custom ?) ? [Assumption, Spec §Assumptions] — **INVALIDE — Corrige**: Le JWT ne contient PAS de claim `name` (uniquement sub=email, iat, exp). Le name est dans AuthResponse mais pas persiste. Approche corrigee : persister le name dans FlutterSecureStorage au login. Research R-002 et T012 mis a jour.
- [x] CHK032 - L'hypothese que l'endpoint `/transactions/summary` inclut les transactions de type AJUSTEMENT dans le calcul du `solde` est-elle documentee ? [Assumption, Spec §Assumptions] — **Accepte**: Assume inclusif (le backend calcule SUM sur toutes les transactions du mois). Comportement standard, pas de filtre par type dans l'endpoint existant.
- [x] CHK033 - La dependance aux notifiers CRUD existants (KKS-115) est-elle validee comme stable et complete pour les 5 entites ? [Dependency, Spec §Assumptions] — **Resolu**: Commit 3c8c1f0 confirme l'implementation des 5 notifiers (Account, Transaction, Subscription, Debt, Category).
