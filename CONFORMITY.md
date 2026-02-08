# Conformité Budget

> Dernière analyse : 2026-02-08
> Score : 100% | Sources : 80 fichiers (35 Java, 21 TS, 10 SCSS, 14 tests) | 0 écart ouvert

---

## Écarts ouverts

Aucun.

---

## Conforme

### Backend (api/)

| Aspect | Statut |
|--------|--------|
| Architecture Controller → Service → Repository | OK |
| DTOs séparés (request/response), aucune entité exposée | OK |
| JWT sur toutes les routes sauf `/auth/**` et `/error` | OK |
| Filtrage par user authentifié (UUID) | OK |
| Bean Validation (`@Valid`, `@NotNull`, `@Size`) | OK |
| Lombok (`@Data`, `@Builder`, `@RequiredArgsConstructor`) | OK |
| UUID comme clés primaires sur toutes les entités | OK |
| Enums dans le package `enums/` | OK |
| SLF4J/Logback, pas de `System.out.println` | OK |
| Tests : nommage `should_[résultat]_when_[condition]`, pattern AAA | OK |
| Flyway activé, DDL `validate` | OK |
| Records Java pour les DTOs | OK |
| Profil prod avec variables d'environnement obligatoires | OK |

### Frontend (app/)

| Aspect | Statut |
|--------|--------|
| Signals-first (`signal()`, `computed()`, `input()`) | OK |
| `inject()` uniquement (pas de constructor injection) | OK |
| Standalone + `ChangeDetectionStrategy.OnPush` | OK |
| Pas de `@Input()`, `@Output()`, `@ViewChild()` | OK |
| Design System en couches (primitives → tokens → themes) | OK |
| Tokens CSS `var(--token-name)` dans composants SCSS | OK |
| Structure `core/` / `shared/` / `features/` | OK |
| Pas de `console.log` | OK |
| Thèmes Light + Dark avec tokens sémantiques | OK |

### Général

| Aspect | Statut |
|--------|--------|
| Code commenté (> 3 lignes) | 0 |
| TODO/FIXME | 0 |
| Code mort | 0 |
| Fichiers orphelins | 0 |

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

## Corrections appliquées (historique)

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
| CRIT-001 | Critique | Faux positif — `application-dev.yaml` est dans `.gitignore`, fallback dev restauré |
| MAJ-001 | Majeur | Ajout `@Slf4j` sur TransactionController, DebtController, SubscriptionController |
| MAJ-002 | Majeur | Remplacement `.subscribe()` par `firstValueFrom()` dans composant Auth |
| MAJ-003 | Majeur | `console.error` conditionnés à `isDevMode()` dans AuthService |
| MIN-002 | Mineur | Variables SCSS `$sidebar-width`/`$header-height` migrées vers tokens CSS custom properties |

---

## Recommandations

- Augmenter la couverture de tests frontend (3 fichiers .spec.ts pour 21 fichiers TS)
- Documenter les tokens SCSS manquants (`$sidebar-width`, `$header-height`) dans le design system

---

*Rapport généré par conformity-audit*
