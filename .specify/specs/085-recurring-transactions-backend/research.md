# Research: Transactions Recurrentes & Paiements Abonnements (Backend)

**Date**: 2026-03-14 | **Branch**: `085-recurring-transactions-backend`

## R1: Calcul de nextOccurrence — reutilisation du pattern existant

**Decision**: Extraire la methode `getNextDueDate()` de `NotificationScheduler` dans un utilitaire partage, ou la dupliquer dans les services dedies.

**Rationale**: `NotificationScheduler.getNextDueDate(LocalDate dateDebut, Frequency frequence, ZoneId zoneId)` (ligne 171-195) implemente deja le calcul exact dont on a besoin. Il gere correctement les 3 frequences (HEBDOMADAIRE via `ChronoUnit.WEEKS`, MENSUEL via `ChronoUnit.MONTHS`, ANNUEL via `ChronoUnit.YEARS`) avec gestion des fins de mois par `java.time` natif.

**Alternatives considered**:
- Extraire dans une classe utilitaire `FrequencyUtils` → ajout d'une abstraction pour un seul appel, viole YAGNI
- Dupliquer dans chaque service → code mort potentiel si la logique change
- **Choix retenu**: Reutiliser directement dans les services en calculant la prochaine occurrence avec la meme approche (`dateDebut.plus{Weeks|Months|Years}(1)` selon la frequence). La logique est simple (3 lignes switch) et ne justifie pas une extraction.

## R2: Difference entre notifications de recurrences et notifications d'abonnements existantes

**Decision**: Les notifications de recurrences s'envoient **le jour meme** (nextOccurrence <= today), pas la veille comme les abonnements existants.

**Rationale**: Le scheduler existant (`runDailyJob`, cron 6h) notifie la **veille** (`tomorrow = today + 1`). Pour les recurrences, la spec demande de notifier quand `nextOccurrence <= today` — c'est-a-dire le jour meme ou en retard. Cette difference est volontaire : les abonnements previennent en avance, les recurrences rappellent qu'il faut valider.

**Alternatives considered**:
- Unifier le comportement (tout la veille ou tout le jour meme) → changerait le comportement existant des abonnements, risque de regression
- **Choix retenu**: Deux comportements distincts. Les recurrences utilisent un job separe dans `NotificationScheduler` avec `nextOccurrence <= today`.

## R3: Pattern des notifications quotidiennes persistantes (pas de dedup)

**Decision**: Pour les recurrences, creer une notification chaque jour tant que non validee. Pour les paiements d'abonnements, conserver le pattern existant (notification la veille uniquement).

**Rationale**: Clarification Q1 de la spec — l'utilisateur veut un rappel persistant pour ne pas oublier de valider. Le pattern existant de dedup 24h (`existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter`) empeche les doublons le meme jour mais autorise une nouvelle notification le lendemain, ce qui correspond exactement au comportement souhaite.

**Alternatives considered**:
- Pas de dedup du tout → spam si le scheduler est relance plusieurs fois par jour
- **Choix retenu**: Garder le dedup 24h existant. Il autorise naturellement 1 notification/jour, ce qui est le comportement voulu.

## R4: Ajout des endpoints de paiement sur SubscriptionController vs nouveau controller

**Decision**: Ajouter les endpoints `/subscriptions/{id}/payments` et `/subscriptions/{id}/pay` sur le `SubscriptionController` existant. Creer un `RecurringTransactionController` separe pour les recurrences.

**Rationale**: Les paiements sont une sous-ressource des abonnements (`/subscriptions/{id}/payments`), il est naturel de les placer sur le meme controller. Les recurrences sont une sous-ressource des transactions (`/transactions/recurring`), un controller dedie evite de surcharger `TransactionController` qui est deja complexe (6 endpoints + logique transfert/produit/dette).

**Alternatives considered**:
- Tout dans TransactionController → trop de responsabilites, 12+ endpoints
- Un seul nouveau controller pour tout → melange recurrences et paiements abonnements, pas cohesif
- **Choix retenu**: SubscriptionController enrichi + RecurringTransactionController dedie

## R5: Resolution du compte pour la validation de recurrence

**Decision**: Lors de la validation d'une recurrence, utiliser le compte de la transaction recurrente template. Si le compte est null ou inactif, utiliser le compte par defaut de l'utilisateur.

**Rationale**: La transaction recurrente sert de template. Son compte est le choix naturel. Le fallback sur le compte par defaut (`accountRepository.findByUserIdAndIsDefaultTrue()`) est coherent avec le pattern existant dans `TransactionService.resolveAccount()`.

**Alternatives considered**:
- Refuser la validation si le compte est null → bloquant pour l'utilisateur
- **Choix retenu**: Fallback silencieux sur le compte par defaut

## R6: Nouveaux types d'enum necessaires

**Decision**: Ajouter `RECURRING_TRANSACTION_DUE` dans `NotificationType` et `TRANSACTION` dans `EntityType`.

**Rationale**:
- `NotificationType`: le type existant `SUBSCRIPTION_DUE` est reserve aux abonnements (notification la veille). Les recurrences ont un comportement different (jour meme, rappel quotidien) → un type dedie permet de les configurer independamment dans les preferences utilisateur.
- `EntityType`: necessaire pour lier la notification a l'entite Transaction (recurrence source). Les types existants sont SUBSCRIPTION, DEBT, BUDGET.

**Alternatives considered**:
- Reutiliser SUBSCRIPTION_DUE pour les recurrences → confusion, impossible de configurer independamment
- **Choix retenu**: Nouveaux types dedies
