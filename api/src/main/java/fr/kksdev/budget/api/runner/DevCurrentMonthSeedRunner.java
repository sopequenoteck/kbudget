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

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final AccountRepository accountRepository;

    @Override
    public void run(ApplicationArguments args) {
        Optional<User> devUser = userRepository.findByEmail(DEV_USER_EMAIL);
        if (devUser.isEmpty()) {
            log.info("Dev user {} not found, skipping current-month seed", DEV_USER_EMAIL);
            return;
        }

        User user = devUser.get();
        LocalDate today = LocalDate.now();
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

        addIfCategoryPresent(transactions, categoriesByName, "Salaire", user, account,
                new BigDecimal("2800.00"), "Salaire", TransactionType.RECETTE, dayOfMonth(firstDayOfMonth, today, 1));
        addIfCategoryPresent(transactions, categoriesByName, "Logement", user, account,
                new BigDecimal("750.00"), "Loyer", TransactionType.DEPENSE, dayOfMonth(firstDayOfMonth, today, 1));
        addIfCategoryPresent(transactions, categoriesByName, "Alimentation", user, account,
                new BigDecimal("67.40"), "Carrefour Market", TransactionType.DEPENSE, dayOfMonth(firstDayOfMonth, today, 3));
        addIfCategoryPresent(transactions, categoriesByName, "Transport", user, account,
                new BigDecimal("1.90"), "Ticket metro", TransactionType.DEPENSE, dayOfMonth(firstDayOfMonth, today, 4));
        addIfCategoryPresent(transactions, categoriesByName, "Alimentation", user, account,
                new BigDecimal("12.50"), "Boulangerie", TransactionType.DEPENSE, dayOfMonth(firstDayOfMonth, today, 5));
        addIfCategoryPresent(transactions, categoriesByName, "Restaurant", user, account,
                new BigDecimal("14.90"), "Dejeuner kebab", TransactionType.DEPENSE, dayOfMonth(firstDayOfMonth, today, 6));
        addIfCategoryPresent(transactions, categoriesByName, "Courses", user, account,
                new BigDecimal("43.20"), "Lidl", TransactionType.DEPENSE, dayOfMonth(firstDayOfMonth, today, 8));
        addIfCategoryPresent(transactions, categoriesByName, "Transport", user, account,
                new BigDecimal("48.00"), "Plein essence", TransactionType.DEPENSE, dayOfMonth(firstDayOfMonth, today, 10));
        addIfCategoryPresent(transactions, categoriesByName, "Loisirs", user, account,
                new BigDecimal("32.00"), "Cinema", TransactionType.DEPENSE, dayOfMonth(firstDayOfMonth, today, 12));
        addIfCategoryPresent(transactions, categoriesByName, "Alimentation", user, account,
                new BigDecimal("58.90"), "Courses semaine", TransactionType.DEPENSE, dayOfMonth(firstDayOfMonth, today, 14));

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

    private void addIfCategoryPresent(List<Transaction> transactions, Map<String, Category> categoriesByName,
                                       String categoryName, User user, Account account, BigDecimal montant,
                                       String libelle, TransactionType type, LocalDate date) {
        Category category = categoriesByName.get(categoryName);
        if (category == null) {
            return;
        }
        transactions.add(Transaction.builder()
                .montant(montant)
                .libelle(libelle)
                .type(type)
                .date(date)
                .user(user)
                .category(category)
                .account(account)
                .build());
    }
}
