# Research: 016-modal-service

**Date**: 2026-02-12

## Résumé

Aucun NEEDS CLARIFICATION dans le Technical Context. Recherche focalisée sur les best practices et les décisions de design.

## R1 — Pattern de service modal avec Angular Signals

**Decision**: Service injectable `providedIn: 'root'` avec `WritableSignal` pour l'état et `computed` pour les dérivés.

**Rationale**: Angular Signals est le pattern recommandé depuis Angular 16+. Un service singleton avec signals offre :
- Réactivité native sans RxJS
- Accès direct depuis n'importe quel composant via `inject()`
- Compatibilité OnPush (les signals déclenchent le change detection)
- Testabilité simple (pas de subscribe/unsubscribe)

**Alternatives considered**:
- RxJS BehaviorSubject : plus verbeux, nécessite subscribe/unsubscribe, pattern legacy
- NgRx/ComponentStore : sur-ingénierie pour un état local simple (violation YAGNI)
- Output chaining (parent-enfant) : couplage fort, difficile quand les composants ne sont pas en relation directe

## R2 — Typage de l'entité en édition

**Decision**: Utiliser un signal unique `editingEntity` avec un type union `Transaction | Subscription | Debt | null` plutôt que 3 signaux séparés.

**Rationale**: Le signal `activeModal` (de type `ModalType`) sert déjà de discriminant. Quand `activeModal === 'transaction'`, l'entity est forcément une `Transaction`. Un seul signal simplifie l'API du service (2 signaux au lieu de 4) et correspond exactement à la spécification KKS-58.

**Alternatives considered**:
- 3 signaux séparés (`editingTransaction`, `editingSubscription`, `editingDebt`) : pattern actuel du Shell, plus typé mais plus verbeux. Rejeté car l'information de type est déjà portée par `activeModal`.

## R3 — Mécanisme de confirmation de suppression

**Decision**: Confirmation inline dans le formulaire. Au clic sur "Supprimer", le bouton se transforme en zone de confirmation avec "Confirmer" + "Annuler", sans modale séparée ni `window.confirm()`.

**Rationale**:
- Mobile-first : `window.confirm()` a un rendu natif différent selon les navigateurs et n'est pas stylisable
- UX fluide : pas de superposition modale (modale dans modale)
- Simplicité : état local au formulaire (`showDeleteConfirm` signal), pas besoin de service externe

**Alternatives considered**:
- `window.confirm()` : non stylisable, bloquant, mauvaise UX mobile
- Modale de confirmation séparée : complexité inutile, double overlay
- Snackbar avec undo : plus complexe, nécessite un timer, pas adapté pour un delete irréversible côté serveur

## R4 — Gestion du delete dans le flux formulaire

**Decision**: Les formulaires émettent un nouvel output `deleted` avec l'ID de l'entité. Le Shell (ou le composant parent qui écoute) appelle le service CRUD approprié pour effectuer la suppression.

**Rationale**: Cohérent avec le pattern existant où les formulaires sont présentationnels et émettent des événements (`saved`, `cancelled`). Le formulaire ne connaît pas les services CRUD — c'est le Shell qui orchestre les opérations.

**Alternatives considered**:
- Le formulaire injecte le service CRUD et delete directement : viole la séparation présentationnel/logique métier, rend le formulaire non réutilisable
- Le ModalService gère le delete : centralise trop de responsabilités dans un service qui ne devrait gérer que l'état UI

## R5 — Fermeture modale à la navigation

**Decision**: Réutiliser l'effect existant dans le Shell qui réagit à `NavigationEnd` pour fermer la modale. Appeler `modalService.closeModal()` dans cet effect.

**Rationale**: Le Shell a déjà un effect qui écoute `NavigationEnd` et ferme la modale + le speed dial. Il suffit de remplacer `this.activeModal.set(null)` par `this.modalService.closeModal()`.

**Alternatives considered**:
- Écouter NavigationEnd dans le ModalService : déplacerait une responsabilité de routing dans un service UI, couplage inutile
- Guard ou interceptor : sur-ingénierie pour un simple reset d'état
