# Research: Feature Toggles Angular

**Branch**: `064-angular-feature-toggles` | **Date**: 2026-03-01

## R1 — Pattern de state management pour les préférences

**Decision**: Signal-based service avec `signal()` pour l'état des features et `computed()` pour les dérivations (navigation items, feature guards).

**Rationale**: Le projet Angular suit le pattern signals-first (constitution + CLAUDE.md). Les services existants (AccountService, SubscriptionService) utilisent `signal()` + `refreshTrigger`. Un `PreferenceService` avec signals s'intègre naturellement et permet une réactivité immédiate dans le Shell et le FAB via `computed()`.

**Alternatives considered**:
- RxJS BehaviorSubject : rejeté — le projet évite `subscribe()` manuel et favorise les signals
- NgRx / signal store : rejeté — sur-ingénierie pour un état simple (YAGNI, constitution III)

## R2 — Mécanisme de protection des routes désactivées

**Decision**: Guard fonctionnel `featureGuard` (Angular `CanActivateFn`) qui vérifie l'état du `PreferenceService` avant d'activer une route. Redirige vers `/dashboard` si la feature est désactivée.

**Rationale**: Le projet utilise déjà un guard fonctionnel (`authGuard`). Un `featureGuard` paramétré par feature s'intègre dans le même pattern. Les routes restent toujours enregistrées (comme Flutter) — seul l'accès est conditionné.

**Alternatives considered**:
- Directive `*ngIf` sur les composants : rejeté — ne protège pas l'accès direct par URL
- Supprimer/ajouter dynamiquement les routes : rejeté — complexité inutile, risque de 404

## R3 — Drag & drop pour le réordonnancement

**Decision**: Angular CDK `DragDropModule` (`@angular/cdk/drag-drop`), déjà installé (`^21.1.3`).

**Rationale**: CDK est déjà une dépendance du projet. Le module `DragDropModule` fournit `cdkDropList`, `cdkDrag`, `cdkDragHandle` et l'event `cdkDropListDropped` — tout ce qu'il faut pour le réordonnancement.

**Alternatives considered**:
- Librairie tierce (ngx-sortablejs, etc.) : rejeté — dépendance inutile, CDK suffit
- Boutons up/down : rejeté — moins intuitif que le drag & drop (Flutter utilise le DnD)

## R4 — Vérification des données existantes pour la confirmation

**Decision**: Le composant features vérifie le `refreshTrigger` des services métier (SubscriptionService, DebtService) puis charge les données pour vérifier si elles existent. Utilise `firstValueFrom()` pour un check ponctuel.

**Rationale**: Pattern cohérent avec l'existant. Les services Angular exposent `getAll()` qui retourne un Observable. Un `firstValueFrom(service.getAll())` suivi d'un check `length > 0` est simple et fiable. Comme Flutter, on vérifie en local pour décider si le dialogue apparaît.

**Alternatives considered**:
- Endpoint API dédié `/has-data` : rejeté — sur-ingénierie, les données sont déjà chargées si le module est actif
- Toujours afficher le dialogue : rejeté — mauvaise UX si aucune donnée n'existe

## R5 — Chargement initial des préférences

**Decision**: Le `PreferenceService` charge les préférences depuis l'API au moment de la restauration de session (après `authService.restoreSession()`). Le Shell utilise `computed()` basé sur les signals du service — la sidebar se met à jour automatiquement quand les données arrivent.

**Rationale**: Angular est server-only (pas de stockage local). Le chargement se fait une seule fois au login/refresh de session. L'état par défaut (avant chargement) montre Accueil + Transactions uniquement — les modules optionnels apparaissent après le chargement API.

**Alternatives considered**:
- APP_INITIALIZER : rejeté — bloquerait le rendu initial, mauvaise UX
- Chargement lazy au premier accès settings : rejeté — la sidebar a besoin de l'état dès le départ

## R6 — Page placeholder Boutique

**Decision**: Composant standalone minimal `ShopPlaceholder` avec message "Coming soon" et icône. Route `/shop` ajoutée au routeur, protégée par `featureGuard`.

**Rationale**: Spec clarifiée (session 2026-03-01) : le toggle Boutique est actif et le lien sidebar mène à un placeholder. Cela permet la persistance de la préférence (synchro Flutter) sans nécessiter l'implémentation complète du module.

**Alternatives considered**:
- Réutiliser le composant `Placeholder` existant des settings : possible mais ce composant est dans le contexte settings, pas adapté pour une route de premier niveau
