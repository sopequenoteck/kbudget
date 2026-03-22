# Data Model: Alignement Settings Angular sur Flutter

## Entites modifiees

### SettingsSection (enrichi)

| Champ | Type | Description |
|-------|------|-------------|
| id | string | Identifiant unique de la section |
| title | string | Titre affiche |
| description | string | Description courte |
| icon | string | Nom de l'icone Phosphor |
| iconColor | string | **NOUVEAU** — Couleur CSS hex (ex: '#3b82f6') |
| route | string | Route relative sous /settings |
| status | 'active' \| 'placeholder' | Statut de la section |
| group | SettingsGroup | **NOUVEAU** — Groupe d'appartenance |

### SettingsGroup (nouveau)

Type union TypeScript : `'general' | 'management' | 'other'`

| Valeur | Label affiche | Sections |
|--------|--------------|----------|
| general | General | Profil, Fonctionnalites & Navigation, Apparence, Notifications |
| management | Gestion | Comptes, Categories, Devises & Taux, Donnees |
| other | Autre | Securite, A propos |

### GROUP_LABELS (nouveau)

Map de traduction `SettingsGroup` → label affiche :
- `general` → `'General'`
- `management` → `'Gestion'`
- `other` → `'Autre'`

## Donnees dynamiques (page A propos)

### AppStats (nouveau, interface)

| Champ | Type | Source |
|-------|------|--------|
| transactions | number \| null | TransactionService.getAll().length |
| accounts | number \| null | AccountService.getAll().length |
| subscriptions | number \| null | SubscriptionService.getAll().length |
| debts | number \| null | DebtService.getAll().length |

### HealthStatus (reutilise)

Existant dans `HealthService` : `HealthCheckResult` avec `status: 'online' | 'offline' | 'checking'`

### ServerInfo (reutilise)

Existant dans `HealthService` : `ServerInfo` avec `apiUrl: string`, `environment: string`
