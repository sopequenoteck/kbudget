# API Contracts: Refonte page Settings

**Statut** : N/A — Feature frontend-only.

Cette feature ne crée aucun nouvel endpoint API. Les données consommées proviennent de :

| Donnée | Source | Endpoint existant |
|--------|--------|-------------------|
| Liste comptes | `AccountService.getAll()` | `GET /api/accounts` |
| Liste catégories | `CategoryService.getAll()` | `GET /api/categories` |
| Profil utilisateur | `AuthService.currentUser()` | Aucun (données stockées au login via `POST /api/auth/login`) |
| Thème | `ThemeService` | Aucun (localStorage uniquement) |

Aucun contrat OpenAPI à générer pour cette feature.
