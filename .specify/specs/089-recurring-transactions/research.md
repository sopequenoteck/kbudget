# Research: Transactions récurrentes & améliorations abonnements

**Feature**: 089-recurring-transactions (consolidée)
**Date**: 2026-03-15
**Status**: Done (rétroactive)

## Decisions

### 1. Modèle de récurrence : enrichissement de Transaction vs entité séparée

**Decision**: Enrichissement de l'entité Transaction existante avec 4 colonnes (+isRecurring, frequency, nextOccurrence, recurringActive)

**Rationale**: Les transactions récurrentes partagent 90% des attributs d'une transaction classique (montant, libellé, type, catégorie, compte). Une entité séparée dupliquerait massivement le schéma et compliquerait les requêtes cross-types. L'enrichissement permet de réutiliser le repository existant avec des filtres simples (isRecurring=true).

**Alternatives considered**:
- Entité `RecurringTransaction` séparée → rejetée car duplication de schéma et complexité de jointure
- Table de liaison recurring → transaction → rejetée car sur-ingénierie pour un usage single-user

### 2. Workflow de validation : automatique vs manuelle

**Decision**: Validation manuelle obligatoire — le scheduler crée des notifications, pas des transactions

**Rationale**: L'utilisateur veut garder le contrôle total (spec KKS-159 : "l'utilisateur reste maître"). Les montants peuvent varier (ex: facture EDF), le timing peut décaler. La notification-puis-action est plus sûre que la création automatique.

**Alternatives considered**:
- Création automatique avec possibilité d'annulation → rejetée car risque de transactions non souhaitées
- Création automatique conditionnelle (si montant fixe) → rejetée car complexité et confusion UX

### 3. Traçabilité abonnement → transactions : FK vs tag

**Decision**: FK subscription_id sur Transaction (nullable)

**Rationale**: Permet des requêtes SQL directes (JOIN, COUNT, SUM) pour l'historique et le cumul. La FK garantit l'intégrité référentielle. Le NULL par défaut n'impacte pas les transactions existantes.

**Alternatives considered**:
- Système de tags/labels → rejeté car pas de garantie d'unicité et requêtes plus complexes
- Table de liaison subscription_payments → rejetée car sur-ingénierie (une FK suffit)

### 4. Scheduler : fréquence et timing

**Decision**: @Scheduled quotidien à 8h pour les récurrences (le scheduler abonnements existant à 6h reste inchangé)

**Rationale**: 8h correspond au début de journée de l'utilisateur. Le scheduler crée des notifications chaque jour tant que l'occurrence n'est pas validée (rappel persistant). Pas de rattrapage automatique des occurrences manquées — une seule notification par jour.

**Alternatives considered**:
- Scheduler toutes les heures → rejeté car inutile pour des échéances journalières
- Cron configurable → rejeté car YAGNI (single-user, une seule timezone)

### 5. Flutter data mode : local+remote vs server-only

**Decision**: Server-only (API REST sans Drift)

**Rationale**: Les transactions récurrentes nécessitent des données fraîches (le scheduler backend met à jour les dates). Le stockage local créerait des conflits de synchronisation. Conforme à l'exception Constitution IV pour les données temps réel.

**Alternatives considered**:
- Drift + sync → rejeté car complexité de synchronisation des états (validate/skip/deactivate)
- Cache local avec invalidation → rejeté car risque de données stale

### 6. Calcul de prochaine occurrence : mêmes règles que les abonnements

**Decision**: Réutiliser la logique existante de calcul de prochaine date (getNextDueDate)

**Rationale**: Hebdomadaire = +7 jours. Mensuel = même jour du mois suivant, tronqué au dernier jour si nécessaire (31 janv → 28/29 fév). Annuel = même jour l'année suivante avec gestion bissextile. Cohérence avec les abonnements existants.

**Alternatives considered**:
- Bibliothèque tierce (Quartz, etc.) → rejetée car YAGNI pour un calcul simple
- Cron expression → rejetée car complexité excessive pour 3 fréquences
