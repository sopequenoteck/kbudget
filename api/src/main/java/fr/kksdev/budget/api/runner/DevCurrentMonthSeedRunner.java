package fr.kksdev.budget.api.runner;

import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Genere quelques transactions sur le mois courant pour le user dev@local.test (KKS-355).
 * <p>
 * R__dev_seed.sql fixe ses dates relativement a CURRENT_DATE au moment ou son checksum
 * change, mais ne rejoue pas ensuite (migration repeatable). Une base de dev conservee
 * plusieurs mois sans etre recreee se retrouve alors sans aucune transaction sur le mois
 * en cours. Ce runner comble cet ecart a chaque demarrage, en profil dev uniquement — un
 * profil mal garde injecterait de fausses transactions chez un self-hoster en prod.
 */
@Component
@Order(3)
@Profile("dev")
@RequiredArgsConstructor
@Slf4j
public class DevCurrentMonthSeedRunner implements ApplicationRunner {

    private static final String DEV_USER_EMAIL = "dev@local.test";

    // Categories du seed de dev, designees par leur nom : le runner les retrouve a
    // l'execution plutot que de les recreer.
    private static final String CAT_SALAIRE = "Salaire";
    private static final String CAT_LOGEMENT = "Logement";
    private static final String CAT_ALIMENTATION = "Alimentation";
    private static final String CAT_TRANSPORT = "Transport";
    private static final String CAT_RESTAURANT = "Restaurant";
    private static final String CAT_COURSES = "Courses";
    private static final String CAT_LOISIRS = "Loisirs";

    /** Les ecritures du mois, en table plutot qu'en suite d'appels : plus lisible a relire. */
    private static final List<SeedEntry> SEED_ENTRIES = List.of(
            new SeedEntry(CAT_SALAIRE, new BigDecimal("2800.00"), "Salaire mensuel", TransactionType.RECETTE, 1),
            new SeedEntry(CAT_LOGEMENT, new BigDecimal("750.00"), "Loyer", TransactionType.DEPENSE, 1),
            new SeedEntry(CAT_ALIMENTATION, new BigDecimal("67.40"), "Carrefour Market", TransactionType.DEPENSE, 3),
            new SeedEntry(CAT_TRANSPORT, new BigDecimal("1.90"), "Ticket metro", TransactionType.DEPENSE, 4),
            new SeedEntry(CAT_ALIMENTATION, new BigDecimal("12.50"), "Boulangerie", TransactionType.DEPENSE, 5),
            new SeedEntry(CAT_RESTAURANT, new BigDecimal("14.90"), "Dejeuner kebab", TransactionType.DEPENSE, 6),
            new SeedEntry(CAT_COURSES, new BigDecimal("43.20"), "Lidl", TransactionType.DEPENSE, 8),
            new SeedEntry(CAT_TRANSPORT, new BigDecimal("48.00"), "Plein essence", TransactionType.DEPENSE, 10),
            new SeedEntry(CAT_LOISIRS, new BigDecimal("32.00"), "Cinema", TransactionType.DEPENSE, 12),
            new SeedEntry(CAT_ALIMENTATION, new BigDecimal("58.90"), "Courses semaine", TransactionType.DEPENSE, 14));

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final AccountRepository accountRepository;
    private final Clock clock;

    @Override
    public void run(ApplicationArguments args) {
        Optional<User> devUser = userRepository.findByEmail(DEV_USER_EMAIL);
        if (devUser.isEmpty()) {
            log.info("Dev user {} not found, skipping current-month seed", DEV_USER_EMAIL);
            return;
        }

        User user = devUser.get();
        LocalDate today = LocalDate.now(clock);
        LocalDate firstDayOfMonth = today.withDayOfMonth(1);

        // Garde d'idempotence : deux demarrages successifs ne doivent rien creer de plus.
        if (transactionRepository.existsByUserIdAndDateBetween(user.getId(), firstDayOfMonth, today)) {
            log.info("Current month already has transactions for {}, skipping current-month seed", DEV_USER_EMAIL);
            return;
        }

        Optional<Account> defaultAccount = accountRepository.findByUserIdAndIsDefaultTrue(user.getId());
        if (defaultAccount.isEmpty()) {
            log.info("No default account found for {}, skipping current-month seed", DEV_USER_EMAIL);
            return;
        }

        Map<String, Category> categoriesByName = categoryRepository.findByUserIdOrderByNomAsc(user.getId()).stream()
                .collect(Collectors.toMap(Category::getNom, Function.identity(), (first, second) -> first));

        List<Transaction> transactions = buildTransactions(user, defaultAccount.get(), categoriesByName, firstDayOfMonth, today);
        if (transactions.isEmpty()) {
            log.info("No matching category found for {}, skipping current-month seed", DEV_USER_EMAIL);
            return;
        }

        transactionRepository.saveAll(transactions);
        log.info("Seeded {} current-month transactions for {}", transactions.size(), DEV_USER_EMAIL);
    }

    private List<Transaction> buildTransactions(User user, Account account, Map<String, Category> categoriesByName,
                                                 LocalDate firstDayOfMonth, LocalDate today) {
        List<Transaction> transactions = new ArrayList<>();
        for (SeedEntry entry : SEED_ENTRIES) {
            Category category = categoriesByName.get(entry.categoryName());
            if (category == null) {
                continue;
            }
            transactions.add(Transaction.builder()
                    .montant(entry.montant())
                    .libelle(entry.libelle())
                    .type(entry.type())
                    .date(dayOfMonth(firstDayOfMonth, today, entry.dayOffset()))
                    .user(user)
                    .category(category)
                    .account(account)
                    .build());
        }
        return transactions;
    }

    /**
     * Ramene le jour souhaite (1-based depuis le debut du mois) sur aujourd'hui si le mois
     * courant n'est pas assez avance — garantit l'absence de toute date future (KKS-355),
     * y compris le 1er du mois ou un seul jour est deja ecoule.
     */
    private LocalDate dayOfMonth(LocalDate firstDayOfMonth, LocalDate today, int dayOffset) {
        LocalDate candidate = firstDayOfMonth.plusDays(dayOffset - 1L);
        return candidate.isAfter(today) ? today : candidate;
    }

    /**
     * Une ecriture a generer. Les categories sont designees par leur nom : celles du seed
     * de dev, qu'on retrouve a l'execution plutot que de les recreer. Une entree dont la
     * categorie manque est simplement ignoree.
     */
    private record SeedEntry(String categoryName, BigDecimal montant, String libelle,
                             TransactionType type, int dayOffset) {
    }
}
