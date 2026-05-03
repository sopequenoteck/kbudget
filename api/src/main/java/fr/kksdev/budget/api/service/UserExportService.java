package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.UserExportResponse;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.*;
import fr.kksdev.budget.api.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserExportService {

    private final AccountRepository accountRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final BudgetRepository budgetRepository;
    private final BudgetSnapshotRepository budgetSnapshotRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final DebtRepository debtRepository;
    private final CategoryRuleRepository categoryRuleRepository;
    private final ImportProfileRepository importProfileRepository;
    private final ImportHistoryRepository importHistoryRepository;
    private final InvitationRepository invitationRepository;
    private final UserPreferenceRepository userPreferenceRepository;

    public UserExportResponse exportJson(User user) {
        List<Account> accounts = accountRepository.findByUserId(user.getId());
        List<Category> categories = categoryRepository.findByUserIdOrderByNomAsc(user.getId());
        List<Transaction> transactions = transactionRepository.findByUserIdOrderByDateDesc(user.getId());
        List<Budget> budgets = budgetRepository.findByUserId(user.getId());
        List<BudgetSnapshot> snapshots = budgetSnapshotRepository.findByUserId(user.getId());
        List<Subscription> subscriptions = subscriptionRepository.findByUserIdOrderByNomAsc(user.getId());
        List<Debt> debts = debtRepository.findByUserIdOrderByDateDesc(user.getId());
        List<CategoryRule> categoryRules = categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(user.getId());
        List<ImportProfile> importProfiles = importProfileRepository.findByUserIdOrderByNameAsc(user.getId());
        List<ImportHistory> importHistory = importHistoryRepository.findByUserId(user.getId());
        List<Invitation> invitations = invitationRepository.findByInvitedById(user.getId());
        UserPreference preference = userPreferenceRepository.findByUserId(user.getId()).orElse(null);

        log.info("User {} exported data (format=json)", user.getId());

        return new UserExportResponse(
                "1.0.0",
                Instant.now(),
                toUserDto(user),
                toPreferenceDto(preference),
                accounts.stream().map(this::toAccountDto).toList(),
                categories.stream().map(this::toCategoryDto).toList(),
                transactions.stream().map(this::toTransactionDto).toList(),
                budgets.stream().map(this::toBudgetDto).toList(),
                snapshots.stream().map(this::toSnapshotDto).toList(),
                subscriptions.stream().map(this::toSubscriptionDto).toList(),
                debts.stream().map(this::toDebtDto).toList(),
                categoryRules.stream().map(this::toCategoryRuleDto).toList(),
                importProfiles.stream().map(this::toImportProfileDto).toList(),
                importHistory.stream().map(this::toImportHistoryDto).toList(),
                invitations.stream().map(this::toInvitationDto).toList()
        );
    }

    public void exportCsv(User user, OutputStream out) throws IOException {
        // BOM UTF-8
        out.write(0xEF);
        out.write(0xBB);
        out.write(0xBF);

        OutputStreamWriter writer = new OutputStreamWriter(out, StandardCharsets.UTF_8);
        CSVFormat format = CSVFormat.RFC4180.builder()
                .setHeader("Date", "Libellé", "Montant", "Devise", "Compte", "Catégorie", "Type")
                .build();

        try (CSVPrinter printer = new CSVPrinter(writer, format)) {
            List<Transaction> transactions = transactionRepository.findByUserIdOrderByDateDesc(user.getId());
            for (Transaction t : transactions) {
                String accountNom = t.getAccount() != null ? t.getAccount().getNom() : "";
                String currency = t.getAccount() != null ? t.getAccount().getCurrency().name() : "";
                String categoryNom = t.getCategory() != null ? t.getCategory().getNom() : "";
                printer.printRecord(
                        t.getDate() != null ? t.getDate().toString() : "",
                        t.getLibelle(),
                        t.getMontant(),
                        currency,
                        accountNom,
                        categoryNom,
                        translateType(t.getType())
                );
            }
            printer.flush();
            writer.flush();
            log.info("User {} exported transactions (format=csv, count={})", user.getId(), transactions.size());
        }
    }

    private String translateType(TransactionType type) {
        if (type == null) return "";
        return switch (type) {
            case RECETTE -> "Revenu";
            case DEPENSE -> "Dépense";
            case AJUSTEMENT -> "Ajustement";
        };
    }

    // --- Mappers ---

    private UserExportResponse.UserDto toUserDto(User user) {
        return new UserExportResponse.UserDto(
                user.getId().toString(),
                user.getEmail(),
                user.getName(),
                user.isAdmin(),
                user.isPasswordResetRequired(),
                user.getCreatedAt(),
                user.getAvatarPath()
        );
    }

    private UserExportResponse.UserPreferenceDto toPreferenceDto(UserPreference pref) {
        if (pref == null) return null;
        return new UserExportResponse.UserPreferenceDto(
                pref.getId().toString(),
                pref.getEnabledFeatures() != null
                        ? pref.getEnabledFeatures().stream().map(Enum::name).toList()
                        : List.of(),
                pref.getNavOrder() != null
                        ? pref.getNavOrder().stream().map(Enum::name).toList()
                        : List.of(),
                pref.getCurrencies() != null
                        ? pref.getCurrencies().stream().map(Enum::name).toList()
                        : List.of(),
                pref.getEnabledNotificationTypes() != null
                        ? pref.getEnabledNotificationTypes().stream().map(Enum::name).toList()
                        : List.of(),
                pref.getTimezone(),
                pref.getTextScale() != null ? pref.getTextScale().name() : null,
                pref.getUpdatedAt()
        );
    }

    private UserExportResponse.AccountDto toAccountDto(Account a) {
        return new UserExportResponse.AccountDto(
                a.getId().toString(),
                a.getNom(),
                a.getType() != null ? a.getType().name() : null,
                a.getSoldeInitial(),
                a.getIcone(),
                a.getCouleur(),
                a.getIsDefault() != null && a.getIsDefault(),
                a.getCurrency() != null ? a.getCurrency().name() : null,
                a.getActif() != null && a.getActif(),
                a.getBankCode(),
                a.getBankCustomName(),
                a.getUpdatedAt()
        );
    }

    private UserExportResponse.CategoryDto toCategoryDto(Category c) {
        return new UserExportResponse.CategoryDto(
                c.getId().toString(),
                c.getNom(),
                c.getIcone(),
                c.getCouleur(),
                c.getIsSystem() != null && c.getIsSystem(),
                c.getUpdatedAt()
        );
    }

    private UserExportResponse.TransactionDto toTransactionDto(Transaction t) {
        return new UserExportResponse.TransactionDto(
                t.getId().toString(),
                t.getMontant(),
                t.getLibelle(),
                t.getType() != null ? t.getType().name() : null,
                t.getDate(),
                t.getCategory() != null ? t.getCategory().getId().toString() : null,
                t.getNote(),
                t.getAccount() != null ? t.getAccount().getId().toString() : null,
                t.getTransferId() != null ? t.getTransferId().toString() : null,
                t.getDebt() != null ? t.getDebt().getId().toString() : null,
                t.getIsRecurring() != null && t.getIsRecurring(),
                t.getFrequency() != null ? t.getFrequency().name() : null,
                t.getNextOccurrence(),
                t.getRecurringActive() != null && t.getRecurringActive(),
                t.getSubscription() != null ? t.getSubscription().getId().toString() : null,
                t.getUpdatedAt()
        );
    }

    private UserExportResponse.BudgetDto toBudgetDto(Budget b) {
        return new UserExportResponse.BudgetDto(
                b.getId().toString(),
                b.getMontant(),
                b.getCurrency() != null ? b.getCurrency().name() : null,
                b.getFrequence() != null ? b.getFrequence().name() : null,
                b.getSeuilNotification(),
                b.getActif() != null && b.getActif(),
                b.getCategory() != null ? b.getCategory().getId().toString() : null,
                b.getUpdatedAt()
        );
    }

    private UserExportResponse.BudgetSnapshotDto toSnapshotDto(BudgetSnapshot s) {
        return new UserExportResponse.BudgetSnapshotDto(
                s.getId().toString(),
                s.getMontantBudget(),
                s.getCurrency() != null ? s.getCurrency().name() : null,
                s.getTauxChange(),
                s.getMontantDepense(),
                s.getMois(),
                s.getCategory() != null ? s.getCategory().getId().toString() : null,
                s.getCreatedAt()
        );
    }

    private UserExportResponse.SubscriptionDto toSubscriptionDto(Subscription s) {
        return new UserExportResponse.SubscriptionDto(
                s.getId().toString(),
                s.getNom(),
                s.getMontant(),
                s.getFrequence() != null ? s.getFrequence().name() : null,
                s.getDateDebut(),
                s.getCurrency() != null ? s.getCurrency().name() : null,
                s.getActif() != null && s.getActif(),
                s.getCategory() != null ? s.getCategory().getId().toString() : null,
                s.getAccount() != null ? s.getAccount().getId().toString() : null,
                s.getUpdatedAt()
        );
    }

    private UserExportResponse.DebtDto toDebtDto(Debt d) {
        return new UserExportResponse.DebtDto(
                d.getId().toString(),
                d.getPersonne(),
                d.getMontant(),
                d.getSens() != null ? d.getSens().name() : null,
                d.getDate(),
                d.getCurrency() != null ? d.getCurrency().name() : null,
                d.getRembourse() != null && d.getRembourse(),
                d.getDueDate(),
                d.getAccount() != null ? d.getAccount().getId().toString() : null,
                d.getIncludeInBalance() != null && d.getIncludeInBalance(),
                d.getReminderDate(),
                d.getCategory() != null ? d.getCategory().getId().toString() : null,
                d.getUpdatedAt()
        );
    }

    private UserExportResponse.CategoryRuleDto toCategoryRuleDto(CategoryRule r) {
        return new UserExportResponse.CategoryRuleDto(
                r.getId().toString(),
                r.getPattern(),
                r.getCategory() != null ? r.getCategory().getId().toString() : null,
                r.getCreatedAt()
        );
    }

    private UserExportResponse.ImportProfileDto toImportProfileDto(ImportProfile p) {
        return new UserExportResponse.ImportProfileDto(
                p.getId().toString(),
                p.getName(),
                p.getSeparator(),
                p.getDateFormat(),
                p.getDateColumn(),
                p.getAmountColumn(),
                p.getDebitColumn(),
                p.getCreditColumn(),
                p.getLabelColumn(),
                p.getEncoding(),
                p.getDecimalSeparator(),
                p.getSkipHeaderLines(),
                p.getCreatedAt(),
                p.getUpdatedAt()
        );
    }

    private UserExportResponse.ImportHistoryDto toImportHistoryDto(ImportHistory h) {
        return new UserExportResponse.ImportHistoryDto(
                h.getId().toString(),
                h.getAccount() != null ? h.getAccount().getId().toString() : null,
                h.getTransactionCount(),
                h.getFileName(),
                h.getImportedAt()
        );
    }

    private UserExportResponse.InvitationDto toInvitationDto(Invitation i) {
        return new UserExportResponse.InvitationDto(
                i.getId().toString(),
                i.getToken().toString(),
                i.getEmail(),
                i.getExpiresAt(),
                i.getUsedAt(),
                i.getRevokedAt(),
                i.getCreatedAt()
        );
    }
}
