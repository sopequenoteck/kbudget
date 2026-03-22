# Feature Specification: Écran Transactions Liste (Flutter)

**Feature Branch**: `043-flutter-transactions-list`
**Created**: 2026-02-22
**Status**: Draft
**Input**: KKS-103 — Flutter: Écran Transactions liste
**Linear**: [KKS-103](https://linear.app/kksdev/issue/KKS-103/flutter-ecran-transactions-liste)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter ses transactions du mois (Priority: P1)

L'utilisateur ouvre l'écran des transactions depuis la navigation principale. Il voit immédiatement le mois en cours avec un résumé chiffré (total recettes, total dépenses, bilan) et la liste de ses transactions triées par date décroissante. Chaque transaction affiche l'icône de sa catégorie, le libellé, le nom de catégorie et le montant coloré selon le type (vert pour recette, rouge pour dépense).

**Why this priority**: C'est le cas d'usage principal — consulter l'historique des transactions est la fonctionnalité de base d'une app budget.

**Independent Test**: Peut être testé en ouvrant l'écran et en vérifiant que les transactions du mois courant s'affichent avec le résumé correct.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a des transactions en février 2026, **When** il ouvre l'écran transactions, **Then** il voit le sélecteur sur "Février 2026", le résumé recettes/dépenses/bilan, et la liste des transactions de ce mois triées par date décroissante.
2. **Given** l'utilisateur a des transactions de types variés, **When** il consulte la liste, **Then** chaque transaction affiche l'icône catégorie, le libellé, le nom de catégorie et le montant coloré (vert=recette, rouge=dépense).
3. **Given** les transactions sont en cours de chargement, **When** l'écran s'affiche, **Then** des squelettes (shimmer) apparaissent à la place du résumé et de la liste.

---

### User Story 2 - Naviguer entre les mois (Priority: P1)

L'utilisateur utilise le sélecteur de mois pour consulter ses transactions passées ou futures. Chaque changement de mois met à jour le résumé et la liste des transactions.

**Why this priority**: La navigation temporelle est indissociable de la consultation — les utilisateurs consultent rarement un seul mois.

**Independent Test**: Peut être testé en changeant de mois via le sélecteur et en vérifiant que le résumé et la liste se mettent à jour avec les données du mois sélectionné.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur février 2026, **When** il appuie sur la flèche précédente, **Then** le sélecteur passe à "Janvier 2026" et la liste affiche les transactions de janvier.
2. **Given** l'utilisateur change de mois, **When** les données sont en cours de chargement, **Then** un état de chargement (shimmer) s'affiche le temps du chargement.
3. **Given** l'utilisateur navigue vers un mois sans transactions, **When** le chargement est terminé, **Then** un état vide s'affiche avec un message invitant à ajouter une transaction.

---

### User Story 3 - Filtrer par type de transaction (Priority: P2)

L'utilisateur peut filtrer la liste pour n'afficher que les dépenses, que les recettes, ou toutes les transactions. Le filtre s'applique sur les données du mois en cours et le résumé se met à jour en conséquence.

**Why this priority**: Le filtrage améliore significativement l'expérience mais n'est pas bloquant pour la consultation de base.

**Independent Test**: Peut être testé en sélectionnant un filtre et en vérifiant que seules les transactions du type choisi sont affichées.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la liste complète, **When** il sélectionne "Dépenses", **Then** seules les transactions de type dépense sont affichées et le résumé reste inchangé (recettes/dépenses/bilan du mois complet).
2. **Given** le filtre "Recettes" est actif, **When** l'utilisateur sélectionne "Tous", **Then** toutes les transactions réapparaissent et le résumé reste inchangé.
3. **Given** le filtre "Recettes" est actif, **When** il n'y a aucune recette ce mois, **Then** un état vide s'affiche avec un message adapté.

---

### User Story 4 - Ouvrir une transaction en édition (Priority: P2)

L'utilisateur tape sur une transaction dans la liste pour ouvrir le formulaire d'édition pré-rempli avec les données de cette transaction.

**Why this priority**: L'édition est le complément naturel de la consultation, mais nécessite que le formulaire d'édition existe déjà.

**Independent Test**: Peut être testé en tapant sur un item de la liste et en vérifiant que la navigation mène au formulaire pré-rempli.

**Acceptance Scenarios**:

1. **Given** l'utilisateur voit une transaction dans la liste, **When** il tape dessus, **Then** le formulaire de transaction s'ouvre avec les champs pré-remplis (montant, libellé, type, date, catégorie, compte, note).
2. **Given** l'utilisateur modifie une transaction dans le formulaire et revient à la liste, **When** la liste s'affiche, **Then** la transaction modifiée reflète immédiatement les nouvelles données sans rechargement visible.
3. **Given** l'utilisateur est en cours de mutation sur un item (suppression/mise à jour), **When** il essaie de taper dessus, **Then** l'interaction est bloquée (item visuellement désactivé).

---

### User Story 5 - Rafraîchir la liste (Priority: P3)

L'utilisateur peut tirer vers le bas (pull-to-refresh) pour recharger les données du mois en cours depuis la source de données.

**Why this priority**: Le rafraîchissement est un pattern standard mobile attendu mais peu critique.

**Independent Test**: Peut être testé en tirant vers le bas et en vérifiant que les données sont rechargées.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la liste, **When** il tire vers le bas, **Then** un indicateur de rafraîchissement apparaît et les données sont rechargées.
2. **Given** une erreur réseau survient au rafraîchissement, **When** le chargement échoue, **Then** un message d'erreur s'affiche sans perdre les données déjà affichées.

---

### Edge Cases

- Que se passe-t-il quand l'utilisateur n'a aucune transaction (nouvel utilisateur) ? Un état vide accueillant s'affiche.
- Que se passe-t-il en cas d'erreur réseau au chargement initial ? Un état d'erreur s'affiche avec un bouton de retry.
- Que se passe-t-il avec des montants très élevés (> 999 999) ? Le formatage reste lisible avec séparateurs de milliers.
- Que se passe-t-il avec des libellés très longs ? Le texte est tronqué avec ellipsis.
- Que se passe-t-il quand une transaction n'a pas de catégorie ? Une icône et un libellé par défaut sont affichés.
- Comment les transactions de type "ajustement" sont-elles affichées ? Elles apparaissent dans la liste "Tous" avec la couleur neutre du thème (`onSurface`) — ni vert ni rouge.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher un sélecteur de mois en haut de l'écran, initialisé au mois courant, permettant de naviguer mois par mois. La navigation est illimitée (pas de borne min/max).
- **FR-002**: Le système DOIT afficher un résumé mensuel comprenant le total des recettes, le total des dépenses et le bilan (recettes - dépenses) pour le mois sélectionné. Les transactions de type "ajustement" sont exclues de ces trois métriques.
- **FR-003**: Le système DOIT afficher un filtre segmenté avec trois options : "Tous", "Dépenses", "Recettes". Le filtre "Tous" est sélectionné par défaut.
- **FR-004**: Le système DOIT afficher la liste des transactions du mois sélectionné, groupées par jour avec des en-têtes de section, triées par date décroissante (plus récentes en premier).
- **FR-004a**: Les en-têtes de jour DOIVENT utiliser un format relatif pour les dates proches ("Aujourd'hui", "Hier") puis un format complet pour les dates antérieures (ex: "Lundi 20 février").
- **FR-005**: Chaque item de la liste DOIT afficher : l'icône de la catégorie (ou icône par défaut si absente), le libellé, le nom de la catégorie en sous-titre et le montant coloré selon le type. La date n'est pas répétée dans l'item car elle figure déjà dans l'en-tête de jour (FR-004a).
- **FR-006**: Le filtre DOIT être appliqué côté client sur les transactions déjà chargées du mois (pas de rechargement serveur).
- **FR-007**: L'utilisateur DOIT pouvoir taper sur une transaction pour naviguer vers le formulaire d'édition pré-rempli. Si le formulaire d'édition n'est pas encore implémenté, le tap est un no-op (la navigation est préparée mais inactive).
- **FR-008**: Le système DOIT afficher un état de chargement (squelettes shimmer) pendant le chargement initial et les changements de mois.
- **FR-009**: Le système DOIT afficher un état vide avec message lorsqu'aucune transaction ne correspond au mois et filtre sélectionnés. Les messages sont distincts selon le contexte : "Aucune transaction ce mois-ci" pour un mois vide, "Aucune [dépense|recette] ce mois-ci" pour un filtre sans résultat.
- **FR-010**: Le système DOIT afficher un état d'erreur avec possibilité de réessayer en cas d'échec de chargement.
- **FR-011**: L'utilisateur DOIT pouvoir rafraîchir les données par pull-to-refresh. Le rafraîchissement recharge la liste des transactions ET le résumé mensuel du mois sélectionné.
- **FR-012**: Le résumé mensuel DOIT toujours afficher les 3 métriques du mois complet (recettes, dépenses, bilan) indépendamment du filtre actif. Le filtre n'affecte que la liste des transactions. Les ajustements sont exclus du résumé.
- **FR-013**: Les montants DOIVENT être formatés avec séparateurs de milliers et le symbole de devise de l'utilisateur.
- **FR-014**: Le système DOIT afficher les transactions de TOUS les comptes — vue globale mensuelle (pas de filtre par compte).
- **FR-015**: Le système DOIT charger les transactions par mois sélectionné via `getByMonth(month, year)` (pas de chargement global).
- **FR-016**: En cas de changements rapides de mois (double-tap), seul le dernier mois demandé DOIT être chargé. Les requêtes intermédiaires sont annulées ou ignorées.

### Non-Functional Requirements

- **NFR-001**: Chaque item de la liste DOIT avoir un semantic label décrivant la transaction (libellé + montant) pour les lecteurs d'écran.
- **NFR-002**: Les couleurs sémantiques (recette/dépense/ajustement) DOIVENT respecter les contrastes définis dans le thème light et dark existant.

### Key Entities

- **Transaction**: Opération financière avec montant, libellé, type (dépense/recette/ajustement), date, catégorie optionnelle, compte associé et note optionnelle.
- **Category**: Catégorie de classement avec nom, icône (emoji) et couleur.
- **MonthlySummary**: Agrégation mensuelle : total recettes, total dépenses, bilan (recettes - dépenses). Les transactions de type "ajustement" sont exclues des trois métriques.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter ses transactions du mois courant en moins de 2 secondes après ouverture de l'écran.
- **SC-002**: Le changement de mois met à jour la liste et le résumé en moins de 1 seconde (données locales) ou 2 secondes (données serveur).
- **SC-003**: Le filtrage par type est instantané (< 100ms) car appliqué côté client.
- **SC-004**: L'écran gère correctement les trois états : chargement (shimmer), vide (message), erreur (retry).
- **SC-005**: L'utilisateur peut ouvrir le formulaire d'édition d'une transaction en un seul tap.
- **SC-006**: Le résumé mensuel (recettes/dépenses/bilan) est toujours cohérent avec le mois complet sélectionné, indépendamment du filtre actif (ajustements exclus du calcul).

## Clarifications

### Session 2026-02-22

- Q: Le bouton d'ajout de transaction (FAB) doit-il être inclus dans le scope ? → A: Non, le FAB existe déjà au niveau de la navigation/shell.
- Q: Quand un filtre type est actif, le résumé s'adapte-t-il ? → A: Non, le résumé affiche toujours les 3 métriques du mois complet (recettes/dépenses/bilan) ; le filtre n'affecte que la liste.
- Q: Comportement au retour du formulaire d'édition ? → A: Mise à jour automatique via l'état partagé (réactivité Riverpod) — pas de rechargement explicite.
- Q: Les transactions sont-elles groupées par jour avec des en-têtes de section ? → A: Oui, groupées par jour avec en-têtes de section (ex: "Samedi 22 Fév").
- Q: L'écran affiche les transactions de tous les comptes ou du compte sélectionné ? → A: Tous les comptes — vue globale mensuelle.
- Q: Les actions par swipe (swipe-to-delete) sont-elles dans le scope ? → A: Non, hors scope — suppression uniquement depuis le formulaire d'édition.
- Q: Faut-il charger toutes les transactions ou uniquement celles du mois sélectionné ? → A: Charger par mois via un nouveau `getByMonth(month, year)` sur le repository.
- Q: Quel format pour les en-têtes de jour ? → A: Relatif + fallback : "Aujourd'hui", "Hier", puis "Lundi 20 février" pour les dates antérieures.
- Q: Comment les ajustements impactent-ils le calcul du résumé mensuel ? → A: Ajustements exclus du résumé (ni recettes, ni dépenses, ni bilan) — visibles uniquement dans la liste. Le terme "solde" est remplacé par "bilan" dans toute la spec.

### Session full-review 2026-02-22

- Q: Le MonthSelector a-t-il des bornes temporelles (min/max) ? → A: Non, navigation illimitée. Hors scope v1.
- Q: Que se passe-t-il au tap quand le formulaire n'existe pas encore ? → A: No-op — la navigation est préparée mais inactive tant que la route n'est pas implémentée.
- Q: Le pull-to-refresh recharge-t-il aussi le résumé ? → A: Oui, il recharge liste + résumé du mois sélectionné.
- Q: Quelle couleur pour le "style neutre" des ajustements ? → A: Couleur `onSurface` du thème (ni vert ni rouge).
- Q: Les messages d'état vide sont-ils différenciés ? → A: Oui — "Aucune transaction ce mois-ci" (mois vide) vs "Aucune [dépense|recette] ce mois-ci" (filtre sans résultat).
- Q: La date est-elle affichée dans chaque item sachant qu'il y a des en-têtes de jour ? → A: Non, la date est dans l'en-tête de jour. L'item affiche le nom de catégorie en sous-titre à la place.
- Q: En cas de changements rapides de mois, comment gérer les race conditions ? → A: Seul le dernier mois demandé est chargé, les requêtes intermédiaires sont ignorées.
- Q: Que se passe-t-il quand une transaction éditée change de mois ? → A: Elle disparaît de la liste au retour (le mois courant est rechargé, la transaction n'en fait plus partie).

## Assumptions

- Le widget `MonthSelector` existant est réutilisé tel quel pour la navigation mensuelle.
- Le widget `SegmentedFilter<T>` existant est réutilisé pour le filtre de type.
- Le widget `ListItem` existant est réutilisé pour chaque transaction de la liste.
- Le `TransactionNotifier` et `ListState<Transaction>` existants sont étendus ou adaptés pour supporter le filtrage par mois et par type.
- Le `TransactionRepository.getMonthlySummary(month, year)` fournit les données du résumé.
- Le formulaire de transaction (édition) existe ou sera développé séparément — cet écran se contente de naviguer vers lui.
- Les actions par swipe (swipe-to-delete, etc.) sont hors scope — la suppression se fait uniquement depuis le formulaire d'édition.
- Le repository sera étendu avec `getByMonth(int month, int year)` pour charger uniquement les transactions du mois sélectionné.
- Les transactions de type "ajustement" sont affichées dans "Tous" mais exclues des filtres "Dépenses" et "Recettes".
- La devise est celle configurée dans les préférences utilisateur (pattern existant via `amount_formatter`).
