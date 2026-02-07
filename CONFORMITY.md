# Conformité Budget API

> Dernière analyse : 2026-02-07
> Score : 100% | Sources : 34 fichiers | Tests : 84 (14 fichiers) | 0 écart ouvert

---

## Conforme

### Sécurité

| Aspect | Détails |
|--------|---------|
| JWT | Token stateless, secret via env var, expiration configurée |
| Routes protégées | Toutes sauf `/auth/**` et `/error` nécessitent JWT |
| Filtrage par user | Tous les services filtrent par `userId` (UUID) |
| Bean Validation | `@Valid` sur tous les endpoints, `@Size` sur champs String |
| Password encoding | BCrypt |
| Secrets | Aucun secret hardcodé |
| CSRF | Désactivé (API REST stateless) |

### Architecture

| Aspect | Détails |
|--------|---------|
| Couches | Controller → Service → Repository |
| DTOs | Aucune entité JPA exposée, packages `dto/request/` et `dto/response/` |
| Enums | Valeurs fixes dans `enums/` |
| Lombok | `@Data`, `@Builder`, `@RequiredArgsConstructor` |
| UUID | Toutes les entités |
| YAGNI | Pas de sur-ingénierie |

### Logging

| Aspect | Détails |
|--------|---------|
| Framework | SLF4J/Logback, pas de System.out.println |
| Config | Profils dev/prod, rotation, niveaux corrects |
| Niveaux | INFO actions, DEBUG auth JWT, WARN échecs, ERROR exceptions |
| Démarrage | `log.info("Budget API started")` |

### Database

| Aspect | Détails |
|--------|---------|
| JPA | `open-in-view: false`, `format_sql: true` |
| Flyway | V1 init + V2 updated_at, activé en dev |
| Relations | `@ManyToOne(fetch = LAZY)` |
| DDL | `validate` en dev et prod |

### Tests

| Aspect | Détails |
|--------|---------|
| Coverage | Services (4/4), controllers (4/4), repositories (3/3), config (2/2) |
| Nommage | `should_[résultat]_when_[condition]` |
| Pattern | AAA (Arrange-Act-Assert) |
| Frameworks | JUnit 5, Mockito, MockMvc, AssertJ |

### Code Quality

| Aspect | Détails |
|--------|---------|
| Records | DTOs en records Java |
| Code mort | 0 |
| Duplication | Patterns factorisés (`toResponse`, `findByIdAndUser`) |
| TODO/FIXME | 0 |
| Code commenté | 0 |

---

## Constitution (7 principes)

| Principe | Score |
|----------|-------|
| 1. API-First | 100% |
| 2. Sécurité par défaut | 100% |
| 3. Simplicité & YAGNI | 100% |
| 4. Mobile-First UX | N/A |
| 5. Testabilité | 100% |
| 6. Observabilité | 100% |
| 7. Self-Hosted Ready | 100% |

---

## Corrections appliquées

| ID | Sévérité | Description |
|----|----------|-------------|
| ARCH-001 | Majeur | Entité User retirée des controllers, UUID comme principal |
| LOMBOK-001 | Majeur | `@Getter/@Setter` → `@Data` sur 4 entités |
| LOG-001 | Majeur | Log DEBUG dans JwtFilter pour auth réussie |
| TEST-001 | Majeur | +13 tests (JwtUtil, GlobalExceptionHandler) |
| DB-001 | Majeur | Flyway activé en dev, DDL validate |
| VALID-001 | Mineur | `@Size` sur champs String des DTOs |
| LOG-002 | Mineur | Log de démarrage dans ApiApplication |
| CONFIG-001 | Mineur | application-dev.yaml ignoré par `.gitignore` |
| ARCH-002 | Mineur | DTOs séparés en `dto/request/` et `dto/response/` |

---

*Rapport généré par conformity-audit*
