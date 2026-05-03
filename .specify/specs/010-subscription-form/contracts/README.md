# Contracts: Formulaire Subscription (modal)

Pas de nouveau endpoint backend pour cette feature. Le formulaire utilise les endpoints existants via `SubscriptionService` :

- `POST /api/subscriptions` — Creation (via `SubscriptionService.create()`)
- `PUT /api/subscriptions/:id` — Mise a jour (via `SubscriptionService.update()`)

Les DTOs `SubscriptionRequest` et `Subscription` sont deja definis dans `app/src/app/core/models/subscription.model.ts`.
