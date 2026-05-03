# Research: Formulaire Abonnement (Flutter)

**Date**: 2026-02-23
**Feature**: 045-flutter-subscription-form

## Résumé

Aucun "NEEDS CLARIFICATION" identifié dans le contexte technique. L'API backend existe, les widgets communs sont en place, et le formulaire de transaction fournit un pattern complet à suivre.

## Décisions

### D1 — Pattern du formulaire

- **Décision** : `ConsumerStatefulWidget` avec callbacks (`onSaved`, `onDeleted`, `onCancelled`)
- **Raisonnement** : Pattern identique au `TransactionForm` existant. `ConsumerStatefulWidget` permet l'accès Riverpod (`ref`) et la gestion de `TextEditingController` avec `initState`/`dispose`
- **Alternatives considérées** :
  - `ConsumerWidget` + `StateProvider` pour chaque champ → rejeté car over-engineering pour un formulaire simple
  - `HookConsumerWidget` (flutter_hooks) → rejeté car non utilisé dans le projet

### D2 — Toggle fréquence : emplacement

- **Décision** : Toggle dans le header de la modal via `headerActions` + `inlineHeaderActions: true`
- **Raisonnement** : Le `ModalType.subscription` est déjà configuré avec `hasToggle: true` et `toggleLabels: ['Mensuel', 'Annuel']` dans `modal_type.dart`. Le pattern est identique aux transactions (toggle Dépense/Recette en header)
- **Alternatives considérées** :
  - Toggle dans le body du formulaire → rejeté car le modal system est déjà configuré pour le header
  - `SegmentedButton` Flutter natif → rejeté car `AppToggle` existe et est cohérent avec le design system

### D3 — Gestion du toggle "actif"

- **Décision** : `Switch` Flutter natif dans le body du formulaire, visible en mode création ET édition
- **Raisonnement** : Le champ `actif` est un booléen simple. Un `Switch` est plus naturel qu'un toggle deux options pour un état on/off. Visible en création pour permettre de pré-planifier un abonnement inactif
- **Alternatives considérées** :
  - Masquer en création (actif par défaut silencieusement) → rejeté car réduit le contrôle utilisateur
  - `AppToggle` labels ["Actif", "Inactif"] → rejeté car un Switch est plus idiomatique pour un booléen

### D4 — Ordre des champs dans le formulaire

- **Décision** : Nom → Montant (sur la même ligne) → Date de début → Compte → Catégorie → Actif (switch)
- **Raisonnement** : Aligné avec le formulaire de transaction (Libellé + Montant en première ligne, puis Date, Compte, Catégorie). Le switch "Actif" en dernier car rarement modifié
- **Alternatives considérées** :
  - Montant sur ligne séparée → rejeté car gaspille de l'espace vertical sur mobile

### D5 — Intégration dans le routing/modal system

- **Décision** : Utiliser le `ModalNotifier` existant avec `ModalType.subscription`. Le `app_router.dart` gère l'écoute du state modal et ouvre `AppModal.show()` avec le `SubscriptionForm` comme child
- **Raisonnement** : Le système modal centralisé existe déjà et gère `ModalType.subscription`. Il suffit d'ajouter le `case ModalType.subscription:` dans le switch du router
- **Alternatives considérées** :
  - Ouvrir la modal directement depuis `SubscriptionListScreen` → rejeté car contourne le système modal centralisé

### D6 — Validation : timing

- **Décision** : Afficher les erreurs uniquement après la première tentative de soumission (`_showErrors` flag), puis en temps réel
- **Raisonnement** : Pattern identique au `TransactionForm`. Évite de montrer des erreurs avant que l'utilisateur ait eu la chance de remplir les champs
- **Alternatives considérées** :
  - Validation immédiate dès le premier caractère → rejeté car UX agressive
  - Validation uniquement à la soumission → rejeté car pas de feedback en temps réel

### D7 — Gestion de la date de début par défaut

- **Décision** : Date du jour en mode création
- **Raisonnement** : Convention naturelle — la plupart des abonnements commencent "maintenant". L'utilisateur peut la modifier si besoin
- **Alternatives considérées** :
  - Premier jour du mois courant → trop présomptif
  - Champ vide (obligatoire) → ajoute une interaction inutile
