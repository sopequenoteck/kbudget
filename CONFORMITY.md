# Backlog Conformité Budget App

> Dernière analyse : 2026-02-07
> Score global : 80% | Services : 1 (API Backend)
> Constitution : v2.0.0 | Fichiers Java : 22

---

## 🔴 CRITIQUE (score: 100%)

Aucun écart critique restant.

---

## 🟠 MAJEUR (score: 65%)

### Tests

- [ ] **api** : TEST-001 — Couverture de tests insuffisante
  - Fichier : `src/test/java/fr/kksdev/budget/api/ApiApplicationTests.java`
  - Attendu : Tests d'intégration pour endpoints, tests unitaires pour services
  - Actuel : Un seul test trivial `contextLoads()`
  - Impact : Aucune garantie de non-régression
  - Correction : Créer :
    - `AuthControllerTest.java` : tests POST /auth/register, POST /auth/login (201, 200, 400, 409)
    - `AuthServiceTest.java` : tests unitaires avec mock de `UserRepository`, `PasswordEncoder`, `JwtUtil`
    - Cas à couvrir : email déjà existant, mot de passe incorrect, validation Bean Validation

- [ ] **api** : TEST-002 — Repositories non testés
  - Fichiers : `TransactionRepository.java`, `SubscriptionRepository.java`, `DebtRepository.java`
  - Attendu : Tests des méthodes de requêtes personnalisées
  - Actuel : Aucun test
  - Impact : Risque de requêtes SQL incorrectes non détectées
  - Correction : Créer tests d'intégration avec `@DataJpaTest` pour vérifier :
    - `findByUserIdOrderByDateDesc` retourne bien les transactions triées
    - Isolation par `userId` (pas de fuites cross-user)

### API-First

- [ ] **api** : API-001 — Absence de DTOs pour Transaction, Subscription, Debt
  - Fichiers : Entités `Transaction.java`, `Subscription.java`, `Debt.java` (modèle exposé directement)
  - Attendu : DTOs de request/response pour isoler la couche API
  - Actuel : Aucun controller créé, mais repositories prêts
  - Impact : Futur risque d'exposition d'entités JPA directement
  - Correction : Créer :
    - `TransactionRequest.java`, `TransactionResponse.java`
    - `SubscriptionRequest.java`, `SubscriptionResponse.java`
    - `DebtRequest.java`, `DebtResponse.java`

### Configuration

- [ ] **api** : CONF-001 — Secrets en clair dans application-dev.yaml
  - Fichier : `application-dev.yaml:5,15`
  - Attendu : Variables d'environnement même en dev (ou au minimum un commentaire de warning)
  - Actuel : Password DB `REDACTED` hardcodé, JWT secret hardcodé
  - Risque : MAJEUR si application-dev.yaml committé (ce qui est le cas)
  - Correction :
    1. Ajouter `.env` au `.gitignore`
    2. Créer `.env.example` avec placeholders
    3. Migrer vers `${DB_PASSWORD:dev-password}` même en dev
    4. Documenter dans README

---

## 🟢 MINEUR (score: 80%)

### Architecture

- [ ] **api** : ARCH-001 — Entités sans @UpdateTimestamp
  - Fichiers : `Transaction.java`, `Subscription.java`, `Debt.java`
  - Attendu : `@UpdateTimestamp` sur champ `updatedAt` pour traçabilité
  - Actuel : Seulement `@CreationTimestamp` sur `User`
  - Impact : Impossible de savoir quand une transaction a été modifiée
  - Correction : Ajouter `private LocalDateTime updatedAt` avec `@UpdateTimestamp` sur toutes les entités

### Bean Validation

- [ ] **api** : VAL-001 — Validation manquante sur RegisterRequest.name
  - Fichier : `RegisterRequest.java:10`
  - Attendu : `@Size(min = 1, max = 100)` ou `@NotBlank`
  - Actuel : Champ `name` nullable sans contrainte
  - Impact : Possible enregistrement d'utilisateurs sans nom
  - Correction : Décider si `name` est obligatoire et ajouter validation

---

## ✅ CONFORME (score: 100%)

### Sécurité

| Critère | Statut | Fichier | Commentaire |
|---------|--------|---------|-------------|
| JWT sur routes protégées | ✅ | `SecurityConfig.java:29-31` | Routes `/auth/**` et `/error` publiques, reste authentifié |
| BCrypt pour mots de passe | ✅ | `SecurityConfig.java:37-39`, `AuthService.java:28` | `BCryptPasswordEncoder` configuré et utilisé |
| Secrets via variables env (prod) | ✅ | `application-prod.yaml:3-5,15` | `${DB_URL}`, `${DB_USERNAME}`, `${DB_PASSWORD}`, `${JWT_SECRET}` |
| Bean Validation activée | ✅ | `pom.xml:47`, `AuthController.java:24,29` | `@Valid` sur endpoints |
| Context path `/api` | ✅ | `application.yaml:20` | `server.servlet.context-path: /api` |
| GlobalExceptionHandler | ✅ | `GlobalExceptionHandler.java` | `@RestControllerAdvice` avec gestion 400/404/500, logging intégré |
| Messages d'erreur login unifiés | ✅ | `AuthService.java:40,44` | Message identique "Email ou mot de passe incorrect" pour les 2 cas |

### Observabilité

| Critère | Statut | Fichier | Commentaire |
|---------|--------|---------|-------------|
| Logging SLF4J | ✅ | `AuthService.java`, `AuthController.java`, `JwtFilter.java` | `@Slf4j` + log.info/warn/error sur actions clés |
| Configuration Logback | ✅ | `logback-spring.xml` | Profil dev (console, DEBUG) + prod (console + fichier rotatif 10MB/30j) |

### Architecture

| Critère | Statut | Fichier | Commentaire |
|---------|--------|---------|-------------|
| Package structure conforme | ✅ | Arborescence | `config/`, `controller/`, `service/`, `repository/`, `model/`, `dto/`, `enums/` |
| DTOs utilisés (Auth) | ✅ | `AuthController.java` | `LoginRequest`, `RegisterRequest`, `AuthResponse` |
| Enums dans package dédié | ✅ | `enums/` | `TransactionType`, `Frequency`, `DebtType` |
| Lombok activé | ✅ | `pom.xml:82-83`, entités | `@Builder`, `@Getter`, `@Setter`, `@RequiredArgsConstructor` |
| Un seul module Maven | ✅ | `pom.xml` | Pas de multi-module |
| Controller → Service → Repository | ✅ | `AuthController.java:21` → `AuthService.java:17-19` | Architecture en couches respectée |

### Database

| Critère | Statut | Fichier | Commentaire |
|---------|--------|---------|-------------|
| Entités avec UUID | ✅ | `User.java:20-21`, autres entités | `@GeneratedValue(strategy = GenerationType.UUID)` |
| DDL dev : create-drop | ✅ | `application-dev.yaml:12` | `ddl-auto: create-drop` |
| DDL prod : validate | ✅ | `application-prod.yaml:12` | `ddl-auto: validate` |
| Relations JPA correctes | ✅ | `Transaction.java:41-43`, `Subscription.java:40-42`, `Debt.java:40-42` | `@ManyToOne` avec `@JoinColumn(name = "user_id")` |
| PostgreSQL seule dépendance | ✅ | `pom.xml:76-79` | Driver PostgreSQL en runtime |
| Migrations Flyway | ✅ | `V1__init_schema.sql`, `pom.xml` | Flyway configuré, script initial avec 4 tables + index, activé en prod |

### Configuration

| Critère | Statut | Fichier | Commentaire |
|---------|--------|---------|-------------|
| Profils Spring dev/prod | ✅ | `application.yaml:5`, fichiers séparés | `spring.profiles.active: dev` |
| Isolation des configs | ✅ | `application-dev.yaml`, `application-prod.yaml` | Fichiers séparés |

### Dette technique

| Critère | Statut | Commentaire |
|---------|--------|-------------|
| Pas de `System.out.println` | ✅ | Aucun trouvé dans le code |
| Pas de TODO/FIXME | ✅ | Aucun trouvé dans le code |
| Pas de code deprecated | ✅ | Aucun `@Deprecated` trouvé |

---

## 📊 Tableau de bord

| Principe | Score | Écarts critiques | Écarts majeurs | Écarts mineurs |
|----------|-------|------------------|----------------|----------------|
| I. API-First | 75% | 0 | 1 | 0 |
| II. Sécurité par défaut | 100% | 0 | 0 | 0 |
| III. Simplicité & YAGNI | 100% | 0 | 0 | 0 |
| IV. Mobile-First UX | N/A | — | — | — |
| V. Testabilité | 20% | 0 | 2 | 0 |
| VI. Observabilité | 100% | 0 | 0 | 0 |
| VII. Self-Hosted Ready | 85% | 0 | 1 | 0 |

**Score global pondéré** : 80%
- CRITIQUE (×3) : 0 écart → 0 points
- MAJEUR (×2) : 4 écarts → -8 points
- MINEUR (×1) : 2 écarts → -2 points

---

## 🎯 Actions immédiates (Sprint en cours)

### ✅ Critiques résolus

1. ~~**OBS-001** : Ajouter logging SLF4J~~ → `@Slf4j` sur AuthService, AuthController, JwtFilter
2. ~~**OBS-002** : Créer logback-spring.xml~~ → Profils dev (console) + prod (fichier rotatif)
3. ~~**SEC-001** : Créer GlobalExceptionHandler~~ → `@RestControllerAdvice` avec 400/404/500
4. ~~**DB-001** : Migrer vers Flyway~~ → `V1__init_schema.sql` + config dev/prod

### Top 3 priorité MAJEUR (amélioration qualité)

1. **TEST-001** : Créer tests d'intégration pour `AuthController`
   - Gain : Filet de sécurité pour non-régression
   - Effort : 4h

2. **CONF-001** : Migrer secrets vers variables d'environnement en dev
   - Gain : Sécurité du repository
   - Effort : 1h

3. **API-001** : Créer DTOs pour Transaction, Subscription, Debt
   - Gain : Respect du principe API-First
   - Effort : 2h (futur, lors de création des controllers)

---

## 📝 Notes d'implémentation

### Conformité générale

Le projet respecte bien les fondations :
- Architecture en couches claire
- Lombok utilisé efficacement
- Sécurité JWT bien configurée
- Profils Spring dev/prod séparés
- Structure de packages conforme
- Observabilité en place (SLF4J + Logback)
- Exceptions gérées globalement
- Migrations Flyway prêtes pour la prod

### Points positifs remarquables

- Utilisation correcte de `@Valid` pour Bean Validation
- Relations JPA bien mappées avec `@ManyToOne` et isolation par `user_id`
- Context path `/api` respecté
- Pas de dette technique (TODO/FIXME/System.out)
- Enums bien placés dans package dédié
- Messages d'erreur de login unifiés (pas d'énumération d'emails)

### Priorité d'actions

**Phase 1 (avant production) : ✅ TERMINÉE**
1. ~~Logging (OBS-001, OBS-002)~~
2. ~~GlobalExceptionHandler (SEC-001)~~
3. ~~Migrations Flyway (DB-001)~~

**Phase 2 (amélioration) :**
4. Tests (TEST-001, TEST-002)
5. Sécurité secrets (CONF-001)

**Phase 3 (futur) :**
6. DTOs pour nouvelles entités (API-001)
7. UpdateTimestamp (ARCH-001)
8. Validation name (VAL-001)

---

*Rapport mis à jour manuellement — 2026-02-07*
