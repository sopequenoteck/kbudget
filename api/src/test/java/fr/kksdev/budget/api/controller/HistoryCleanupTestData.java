package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.DebtType;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.enums.SystemCategoryKey;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.ImportDraft;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.ImportDraftRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;

import org.springframework.context.ApplicationContext;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Month;
import java.util.List;
import java.util.UUID;

/** Synthetic fixtures of the history cleanup tests (KKS-387): users, accounts, transactions, never real data. */
final class HistoryCleanupTestData {

    static final LocalDate DAY = LocalDate.of(2026, Month.SEPTEMBER, 15);

    private final UserRepository userRepository;
    private final AccountRepository accountRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final DebtRepository debtRepository;
    private final ImportDraftRepository importDraftRepository;
    private final JwtUtil jwtUtil;

    HistoryCleanupTestData(ApplicationContext context) {
        this.userRepository = context.getBean(UserRepository.class);
        this.accountRepository = context.getBean(AccountRepository.class);
        this.categoryRepository = context.getBean(CategoryRepository.class);
        this.transactionRepository = context.getBean(TransactionRepository.class);
        this.subscriptionRepository = context.getBean(SubscriptionRepository.class);
        this.debtRepository = context.getBean(DebtRepository.class);
        this.importDraftRepository = context.getBean(ImportDraftRepository.class);
        this.jwtUtil = context.getBean(JwtUtil.class);
    }

    User user() {
        return userRepository.save(User.builder()
                .email("cleanup-" + UUID.randomUUID() + "@example.com")
                .password("unused")
                .name("Cleanup")
                .passwordResetRequired(false)
                .build());
    }

    String bearer(User user) {
        return "Bearer " + jwtUtil.generateToken(user.getEmail());
    }

    Account account(User owner, String opening) {
        return accountRepository.save(Account.builder()
                .nom("Compte " + UUID.randomUUID().toString().substring(0, 8))
                .type(AccountType.COURANT)
                .soldeInitial(new BigDecimal(opening))
                .icone("🏦")
                .couleur("#000000")
                .bankCode("SG")
                .user(owner)
                .build());
    }

    Category category(User owner, String name) {
        return categoryRepository.save(Category.builder()
                .nom(name).icone("🏷️").couleur("#111111").user(owner).build());
    }

    Category adjustmentCategory(User owner) {
        return categoryRepository.save(Category.builder()
                .nom("Adjustment").icone("⚖️").couleur("#6b7280").isSystem(true)
                .systemKey(SystemCategoryKey.ADJUSTMENT).user(owner).build());
    }

    Subscription subscription(User owner, String name, String amount, LocalDate start) {
        return subscriptionRepository.save(Subscription.builder()
                .nom(name).montant(new BigDecimal(amount)).frequence(Frequency.MENSUEL)
                .dateDebut(start).actif(true).user(owner).build());
    }

    Debt debt(User owner, String amount, boolean repaid) {
        return debtRepository.save(Debt.builder()
                .personne("Alex").montant(new BigDecimal(amount)).sens(DebtType.PRET)
                .date(DAY).rembourse(repaid).user(owner).build());
    }

    /** A transaction entered by hand: expense, no category, no link, no fingerprint. */
    Transaction manual(User owner, Account account, String label, String amount, LocalDate date) {
        return transactionRepository.save(base(owner, account, label, amount, date).build());
    }

    /** A transaction imported from a statement: it carries a fingerprint. */
    Transaction imported(User owner, Account account, String label, String amount, LocalDate date) {
        return transactionRepository.save(base(owner, account, label, amount, date)
                .importFingerprint(UUID.randomUUID().toString().replace("-", ""))
                .build());
    }

    Transaction.TransactionBuilder base(User owner, Account account, String label, String amount, LocalDate date) {
        return Transaction.builder()
                .libelle(label)
                .montant(new BigDecimal(amount))
                .type(TransactionType.DEPENSE)
                .date(date)
                .account(account)
                .user(owner);
    }

    Transaction save(Transaction.TransactionBuilder builder) {
        return transactionRepository.save(builder.build());
    }

    Transaction adjustment(User owner, Account account, String amount, LocalDate date) {
        return save(base(owner, account, "Balance adjustment", amount, date)
                .type(TransactionType.AJUSTEMENT).category(adjustmentCategory(owner)));
    }

    /** A completed import whose statement gave a bank balance. */
    ImportDraft bankBalance(User owner, Account account, String balance, LocalDate balanceDate) {
        return bankBalance(owner, account, balance, balanceDate, ImportDraftStatus.COMPLETED);
    }

    ImportDraft bankBalance(User owner, Account account, String balance, LocalDate balanceDate, ImportDraftStatus status) {
        return importDraftRepository.save(ImportDraft.builder()
                .user(owner).account(account).status(status)
                .statementBalance(new BigDecimal(balance)).statementBalanceDate(balanceDate)
                .expiresAt(LocalDateTime.of(2030, Month.JANUARY, 1, 0, 0))
                .build());
    }

    /** What a read must not change: every transaction of the user, with what a cleanup could touch. */
    List<String> snapshot(UUID userId) {
        return transactionRepository.findByUserIdOrderByDateDesc(userId).stream()
                .map(t -> String.join("|", t.getId().toString(), t.getLibelle(), t.getMontant().toPlainString(),
                        String.valueOf(t.getDate()), String.valueOf(t.getImportFingerprint()),
                        String.valueOf(t.getCategory() == null ? null : t.getCategory().getId()),
                        String.valueOf(t.getDebt() == null ? null : t.getDebt().getId()),
                        String.valueOf(t.getSubscription() == null ? null : t.getSubscription().getId())))
                .sorted()
                .toList();
    }
}
