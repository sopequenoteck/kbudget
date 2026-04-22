# Quickstart — KKS-233 : Bootstrap du premier admin sur DB vide

> Annexe du [plan.md](./plan.md)
> Date : 2026-04-22

---

## Objectif

Procédure pour valider localement le bootstrap automatique sur une DB vierge et le flux de reset forcé à la première connexion.

---

## Pré-requis

- PostgreSQL local accessible (ou Docker Compose lancé).
- Backend `api/` buildé (`cd api && mvn clean compile`).
- Frontend `app/` démarré (`cd app && ng serve`).
- `docker compose` disponible si test via conteneur.

> **Important — profil Spring** : Le profil `dev` inclut une migration Flyway repeatable `R__dev_seed.sql` qui crée automatiquement un user `dev@local.test` à chaque démarrage. Conséquence : **le `BootstrapSeedRunner` ne se déclenche jamais en profil `dev`** car la condition `userRepository.count() == 0` est immédiatement fausse (comportement attendu par FR-005).
>
> Pour tester réellement le bootstrap sur une instance vierge, exécuter l'app en profil `prod` (défaut quand aucun `spring.profiles.active` n'est spécifié) avec une DB préalablement vidée.

---

## Procédure — Scénario nominal

### 1. DB vierge + démarrage backend (profil prod, pas dev)

```bash
# Réinitialiser la DB (attention : détruit toutes les données)
psql -U postgres -c "DROP DATABASE IF EXISTS budget_db_v; CREATE DATABASE budget_db_v;"

# Démarrer le backend en profil prod (défaut) — aucun BOOTSTRAP_EMAIL défini
# IMPORTANT : ne PAS utiliser -Dspring-boot.run.profiles=dev, car R__dev_seed.sql
# créerait un user dev@local.test et bloquerait le bootstrap.
cd api && mvn spring-boot:run
```

**Attendu dans les logs** :

```
================================================
 FIRST BOOT — Admin account created
 Email:    admin@localhost
 Password: xQ9mK3vP7nR2wL8t5sH4jD8fG1bN6cY3     ← valeur aléatoire 32 chars
 CHANGE THESE CREDENTIALS IMMEDIATELY
================================================
```

### 2. Vérification DB

```sql
SELECT email, is_admin, password_reset_required FROM users;
```

**Attendu** :

| email | is_admin | password_reset_required |
|-------|----------|-------------------------|
| admin@localhost | `t` | `t` |

Un `Account` et une `Preferences` associés doivent exister également.

### 3. Login avec les credentials initiaux

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@localhost","password":"xQ9mK3vP7nR2wL8t5sH4jD8fG1bN6cY3"}'
```

**Attendu** : `200 OK` avec payload :

```json
{
  "token": "eyJ...",
  "refreshToken": "...",
  "email": "admin@localhost",
  "name": "Admin",
  "mustResetCredentials": true
}
```

### 4. Vérifier le gate HTTP

```bash
# Un endpoint protégé standard doit répondre 403 avec le claim mustReset
curl -X GET http://localhost:8080/api/users/me \
  -H "Authorization: Bearer <token>"
```

**Attendu** : `403 Forbidden` avec payload `{"error":"PASSWORD_RESET_REQUIRED","message":"..."}`.

### 5. Reset forcé via l'UI Angular

Ouvrir `http://localhost:4200`, se connecter avec `admin@localhost` + le password initial. L'UI doit automatiquement rediriger vers `http://localhost:4200/first-login-reset`.

Remplir le formulaire :
- Nouvel email : `kelly@exemple.com`
- Nouveau password : `NouveauMotDePasseFort!`
- Confirmation : `NouveauMotDePasseFort!`
- Nom d'affichage : `Kelly`

Soumettre. Après succès, redirection automatique vers `/` (dashboard).

### 6. Vérifier que l'ancien JWT est neutralisé

```bash
curl -X POST http://localhost:8080/api/auth/first-login-reset \
  -H "Authorization: Bearer <ancien-token-avec-claim-mustReset>" \
  -H 'Content-Type: application/json' \
  -d '{"email":"autre@exemple.com","password":"autrepass","displayName":"Autre"}'
```

**Attendu** : `403 Forbidden` (flag DB déjà à `false`).

### 7. Login avec les nouveaux credentials

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"kelly@exemple.com","password":"NouveauMotDePasseFort!"}'
```

**Attendu** : `200 OK` avec `mustResetCredentials: false`.

### 8. Vérifier la préservation du rôle admin après reset

```sql
SELECT email, is_admin, password_reset_required FROM users;
```

**Attendu** :

| email | is_admin | password_reset_required |
|-------|----------|-------------------------|
| kelly@exemple.com | `t` | `f` |

Appel d'un endpoint admin :

```bash
curl -X GET http://localhost:8080/api/admin/users \
  -H "Authorization: Bearer <nouveau-token>"
```

**Attendu** : `200 OK` avec la liste des users (l'accès admin persiste même si `kelly@exemple.com` n'est pas dans `ADMIN_EMAILS`).

---

## Scénario — DB déjà peuplée

Démarrer le backend sur une DB qui contient déjà au moins un user.

**Attendu** :
- Aucune bannière `FIRST BOOT` dans les logs.
- Aucun nouveau user créé.
- `SELECT COUNT(*) FROM users` retourne la valeur pré-existante.

---

## Scénario — `BOOTSTRAP_EMAIL` personnalisé

```bash
BOOTSTRAP_EMAIL=kelly@exemple.com mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

(DB vierge requise)

**Attendu** : la bannière affiche `Email: kelly@exemple.com` et l'user seedé porte cet email.

---

## Scénario — `BOOTSTRAP_EMAIL` invalide (fail-fast)

```bash
BOOTSTRAP_EMAIL=pas-un-email mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

**Attendu** : l'app refuse de démarrer avec un message du type :

```
APPLICATION FAILED TO START
***************************
Property: app.bootstrap.email
Value: "pas-un-email"
Reason: doit être une adresse électronique syntaxiquement correcte
```

Aucun user ne doit être créé en DB.

---

## Scénario — Redémarrage avant reset

1. Démarrer l'app (DB vierge) → le seed a lieu, le password est loggé.
2. Arrêter le container (`Ctrl+C` / `docker compose down`).
3. Redémarrer.

**Attendu** :
- Aucune nouvelle bannière dans les logs.
- Le password initialement loggé reste valide pour se connecter.

---

## Validation via `docker compose up -d`

Scénario de production self-hoster :

```bash
# Répertoire racine du projet
docker compose down -v            # détruit les volumes (DB vierge)
docker compose up -d

# Récupérer le password
docker compose logs api | grep -A 5 "FIRST BOOT"
```

**Attendu** :
- Bannière présente dans les logs.
- Login fonctionnel sur l'UI build production avec les credentials loggés.

---

## Tests automatisés à exécuter

```bash
# Backend
cd api && mvn test -Dtest=BootstrapSeedRunnerTest
cd api && mvn test -Dtest=AdminSyncRunnerTest
cd api && mvn test -Dtest=PasswordResetRequiredFilterTest
cd api && mvn test -Dtest=AuthControllerFirstLoginResetIT
cd api && mvn test -Dtest=PasswordGeneratorTest
cd api && mvn test -Dtest=BootstrapPropertiesTest
cd api && mvn test -Dtest=UserOnboardingServiceTest

# Frontend
cd app && ng test --include='**/first-login-reset/**'
cd app && ng test --include='**/password-reset.guard.spec.ts'
cd app && ng test --include='**/not-password-reset.guard.spec.ts'
```

---

## Rollback

Si la feature doit être retirée d'une branche sans merge :

```bash
git checkout develop
git branch -D feature/KKS-233
```

Si la feature est mergée et qu'un rollback production est nécessaire :

1. Reverser le commit ou la PR via Git.
2. **Ne pas** supprimer les migrations V30 et V31 (elles restent appliquées en production même si le code les annule). Si nécessaire, écrire des migrations inverses V32/V33 (`ALTER TABLE users DROP COLUMN is_admin`, `DROP COLUMN password_reset_required`).
3. Restaurer la configuration admin via `ADMIN_EMAILS` dans le `.env`.
