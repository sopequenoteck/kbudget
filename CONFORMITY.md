# Backlog Conformité Budget App

> Dernière analyse : 2026-02-07
> Score global : 96% | Services : 1 (API Backend)
> Constitution : v2.0.0 | Fichiers Java : 22

---

## 🔴 CRITIQUE (score: 100%)

Aucun écart critique restant.

---

## 🟠 MAJEUR (score: 95%)

### API-First

- [ ] **api** : API-001 — Absence de DTOs pour Transaction, Subscription, Debt
  - Fichiers : Entités `Transaction.java`, `Subscription.java`, `Debt.java` (modèle exposé directement)
  - Attendu : DTOs de request/response pour isoler la couche API
  - Actuel : DTOs créés localement mais non commitées (pas de controllers encore)
  - Impact : Futur risque d'exposition d'entités JPA directement
  - Correction : Commiter les DTOs lors de la création des controllers correspondants

---

## 🟢 MINEUR (score: 100%)

Aucun écart mineur restant.

---

## ✅ CONFORME (score: 100%)

### Sécurité

| Critère | Statut | Fichier | Commentaire |
|---------|--------|---------|-------------|
| JWT sur routes protégées | ✅ | `SecurityConfig.java:29-31` | Routes `/auth/**` et `/error` publiques, reste authentifié |
| BCrypt pour mots de passe | ✅ | `SecurityConfig.java:37-39`, `AuthService.java:28` | `BCryptPasswordEncoder` configuré et utilisé |
| Secrets via variables env (prod) | ✅ | `application-prod.yaml:3-5,15` | `${DB_URL}`, `${DB_USERNAME}`, `${DB_PASSWORD}`, `${JWT_SECRET}` |
| Secrets via variables env (dev) | ✅ | `application-dev.yaml:3-5,18` | `${DB_URL:...}`, `${DB_PASSWORD:...}`, `${JWT_SECRET:...}` avec defaults |
| Bean Validation activée | ✅ | `pom.xml:47`, `AuthController.java:24,29` | `@Valid` sur endpoints |
| Context path `/api` | ✅ | `application.yaml:20` | `server.servlet.context-path: /api` |
| GlobalExceptionHandler | ✅ | `GlobalExceptionHandler.java` | `@RestControllerAdvice` avec gestion 400/404/500, logging intégré |
| Messages d'erreur login unifiés | ✅ | `AuthService.java:40,44` | Message identique "Email ou mot de passe incorrect" pour les 2 cas |

### Observabilité

| Critère | Statut | Fichier | Commentaire |
|---------|--------|---------|-------------|
| Logging SLF4J | ✅ | `AuthService.java`, `AuthController.java`, `JwtFilter.java` | `@Slf4j` + log.info/warn/error sur actions clés |
| Configuration Logback | ✅ | `logback-spring.xml` | Profil dev (console, DEBUG) + prod (console + fichier rotatif 10MB/30j) |

### Testabilité

| Critère | Statut | Fichier | Commentaire |
|---------|--------|---------|-------------|
| Tests unitaires AuthService | ✅ | `AuthServiceTest.java` | 5 tests : register OK/KO, login OK/KO email/KO password |
| Tests intégration AuthController | ✅ | `AuthControllerTest.java` | 7 tests : 201, 200, 400 validation, 400 email existant, 400 login KO |
| Tests TransactionRepository | ✅ | `TransactionRepositoryTest.java` | 3 tests : tri date desc, isolation userId, filtre date between |
| Tests SubscriptionRepository | ✅ | `SubscriptionRepositoryTest.java` | 2 tests : tri nom, filtre actifs |
| Tests DebtRepository | ✅ | `DebtRepositoryTest.java` | 2 tests : tri date desc, filtre non remboursés |
| Base de test H2 | ✅ | `application-test.yaml` | H2 in-memory, profil test dédié |

### Architecture

| Critère | Statut | Fichier | Commentaire |
|---------|--------|---------|-------------|
| Package structure conforme | ✅ | Arborescence | `config/`, `controller/`, `service/`, `repository/`, `model/`, `dto/`, `enums/` |
| DTOs utilisés (Auth) | ✅ | `AuthController.java` | `LoginRequest`, `RegisterRequest`, `AuthResponse` |
| Enums dans package dédié | ✅ | `enums/` | `TransactionType`, `Frequency`, `DebtType` |
| Lombok activé | ✅ | `pom.xml:82-83`, entités | `@Builder`, `@Getter`, `@Setter`, `@RequiredArgsConstructor` |
| Un seul module Maven | ✅ | `pom.xml` | Pas de multi-module |
| Controller → Service → Repository | ✅ | `AuthController.java:21` → `AuthService.java:17-19` | Architecture en couches respectée |
| @UpdateTimestamp sur entités | ✅ | `Transaction.java`, `Subscription.java`, `Debt.java` | Champ `updatedAt` avec `@UpdateTimestamp` pour traçabilité |
| Validation RegisterRequest.name | ✅ | `RegisterRequest.java:10` | `@Size(max = 100)` — champ optionnel avec contrainte de longueur |

### Database

| Critère | Statut | Fichier | Commentaire |
|---------|--------|---------|-------------|
| Entités avec UUID | ✅ | `User.java:20-21`, autres entités | `@GeneratedValue(strategy = GenerationType.UUID)` |
| DDL dev : create-drop | ✅ | `application-dev.yaml:12` | `ddl-auto: create-drop` |
| DDL prod : validate | ✅ | `application-prod.yaml:12` | `ddl-auto: validate` |
| Relations JPA correctes | ✅ | `Transaction.java`, `Subscription.java`, `Debt.java` | `@ManyToOne` avec `@JoinColumn(name = "user_id")` |
| PostgreSQL seule dépendance | ✅ | `pom.xml:76-79` | Driver PostgreSQL en runtime |
| Migrations Flyway | ✅ | `V1__init_schema.sql`, `V2__add_updated_at.sql` | Flyway configuré, 2 migrations, activé en prod |

### Configuration

| Critère | Statut | Fichier | Commentaire |
|---------|--------|---------|-------------|
| Profils Spring dev/prod | ✅ | `application.yaml:5`, fichiers séparés | `spring.profiles.active: dev` |
| Isolation des configs | ✅ | `application-dev.yaml`, `application-prod.yaml` | Fichiers séparés |
| `.env.example` documenté | ✅ | `.env.example` | Placeholders pour DB_URL, DB_USERNAME, DB_PASSWORD, JWT_SECRET |
| `.env` dans `.gitignore` | ✅ | `.gitignore` | `.env` et `**/.env` exclus |

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
| V. Testabilité | 100% | 0 | 0 | 0 |
| VI. Observabilité | 100% | 0 | 0 | 0 |
| VII. Self-Hosted Ready | 100% | 0 | 0 | 0 |

**Score global pondéré** : 96%
- CRITIQUE (×3) : 0 écart → 0 points
- MAJEUR (×2) : 1 écart → -2 points
- MINEUR (×1) : 0 écart → 0 points

---

## 🎯 Actions immédiates (Sprint en cours)

### ✅ Critiques résolus

1. ~~**OBS-001** : Ajouter logging SLF4J~~ → `@Slf4j` sur AuthService, AuthController, JwtFilter
2. ~~**OBS-002** : Créer logback-spring.xml~~ → Profils dev (console) + prod (fichier rotatif)
3. ~~**SEC-001** : Créer GlobalExceptionHandler~~ → `@RestControllerAdvice` avec 400/404/500
4. ~~**DB-001** : Migrer vers Flyway~~ → `V1__init_schema.sql` + config dev/prod

### ✅ Majeurs résolus

5. ~~**TEST-001** : Tests AuthController + AuthService~~ → 12 tests (5 unitaires + 7 intégration)
6. ~~**TEST-002** : Tests repositories~~ → 7 tests @DataJpaTest avec H2
7. ~~**CONF-001** : Secrets vers variables d'environnement~~ → `${VAR:default}` + `.env.example`

### ✅ Mineurs résolus

8. ~~**ARCH-001** : @UpdateTimestamp sur entités~~ → `updatedAt` sur Transaction, Subscription, Debt + migration V2
9. ~~**VAL-001** : Validation RegisterRequest.name~~ → `@Size(max = 100)` sur champ optionnel

### Restant

10. **API-001** : DTOs pour Transaction, Subscription, Debt
    - Statut : DTOs prêts localement, à commiter avec les controllers
    - Effort : inclus dans le développement des controllers

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
- Migrations Flyway prêtes pour la prod (V1 + V2)
- Suite de tests complète (19 tests)
- Secrets externalisés en dev et prod
- Traçabilité des modifications (@UpdateTimestamp)

### Points positifs remarquables

- Utilisation correcte de `@Valid` pour Bean Validation
- Relations JPA bien mappées avec `@ManyToOne` et isolation par `user_id`
- Context path `/api` respecté
- Pas de dette technique (TODO/FIXME/System.out)
- Enums bien placés dans package dédié
- Messages d'erreur de login unifiés (pas d'énumération d'emails)
- 19 tests couvrant controllers, services et repositories

### Priorité d'actions

**Phase 1 (avant production) : ✅ TERMINÉE**
1. ~~Logging (OBS-001, OBS-002)~~
2. ~~GlobalExceptionHandler (SEC-001)~~
3. ~~Migrations Flyway (DB-001)~~

**Phase 2 (amélioration) : ✅ TERMINÉE**
4. ~~Tests (TEST-001, TEST-002)~~
5. ~~Sécurité secrets (CONF-001)~~

**Phase 3 (mineurs) : ✅ TERMINÉE**
6. ~~UpdateTimestamp (ARCH-001)~~
7. ~~Validation name (VAL-001)~~

**Phase 4 (futur) :**
8. DTOs pour nouvelles entités (API-001) — avec les controllers

---

*Rapport mis à jour manuellement — 2026-02-07*
