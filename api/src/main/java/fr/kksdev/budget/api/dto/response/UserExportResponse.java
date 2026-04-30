package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public record UserExportResponse(
        String schemaVersion,
        Instant exportedAt,
        UserExportResponse.UserDto user,
        UserExportResponse.UserPreferenceDto preferences,
        List<UserExportResponse.AccountDto> accounts,
        List<UserExportResponse.CategoryDto> categories,
        List<UserExportResponse.TransactionDto> transactions,
        List<UserExportResponse.BudgetDto> budgets,
        List<UserExportResponse.BudgetSnapshotDto> budgetSnapshots,
        List<UserExportResponse.SubscriptionDto> subscriptions,
        List<UserExportResponse.DebtDto> debts,
        List<UserExportResponse.CategoryRuleDto> categoryRules,
        List<UserExportResponse.ImportProfileDto> importProfiles,
        List<UserExportResponse.ImportHistoryDto> importHistory,
        List<UserExportResponse.InvitationDto> invitations
) {

    // DTO interne SANS le champ password (sécurité — R-007)
    public record UserDto(
            String id,
            String email,
            String name,
            boolean isAdmin,
            boolean passwordResetRequired,
            LocalDateTime createdAt,
            String avatarPath
    ) {}

    public record UserPreferenceDto(
            String id,
            List<String> enabledFeatures,
            List<String> navOrder,
            List<String> currencies,
            List<String> enabledNotificationTypes,
            String timezone,
            String textScale,
            LocalDateTime updatedAt
    ) {}

    public record AccountDto(
            String id,
            String nom,
            String type,
            BigDecimal soldeInitial,
            String icone,
            String couleur,
            boolean isDefault,
            String currency,
            boolean actif,
            String bankCode,
            String bankCustomName,
            LocalDateTime updatedAt
    ) {}

    public record CategoryDto(
            String id,
            String nom,
            String icone,
            String couleur,
            boolean isSystem,
            LocalDateTime updatedAt
    ) {}

    public record TransactionDto(
            String id,
            BigDecimal montant,
            String libelle,
            String type,
            LocalDate date,
            String categoryId,
            String note,
            String accountId,
            String transferId,
            String debtId,
            boolean isRecurring,
            String frequency,
            LocalDate nextOccurrence,
            boolean recurringActive,
            String subscriptionId,
            LocalDateTime updatedAt
    ) {}

    public record BudgetDto(
            String id,
            BigDecimal montant,
            String currency,
            String frequence,
            int seuilNotification,
            boolean actif,
            String categoryId,
            LocalDateTime updatedAt
    ) {}

    public record BudgetSnapshotDto(
            String id,
            BigDecimal montantBudget,
            String currency,
            BigDecimal tauxChange,
            BigDecimal montantDepense,
            String mois,
            String categoryId,
            LocalDateTime createdAt
    ) {}

    public record SubscriptionDto(
            String id,
            String nom,
            BigDecimal montant,
            String frequence,
            LocalDate dateDebut,
            String currency,
            boolean actif,
            String categoryId,
            String accountId,
            LocalDateTime updatedAt
    ) {}

    public record DebtDto(
            String id,
            String personne,
            BigDecimal montant,
            String sens,
            LocalDate date,
            String currency,
            boolean rembourse,
            LocalDate dueDate,
            String accountId,
            boolean includeInBalance,
            LocalDate reminderDate,
            String categoryId,
            LocalDateTime updatedAt
    ) {}

    public record CategoryRuleDto(
            String id,
            String pattern,
            String categoryId,
            LocalDateTime createdAt
    ) {}

    public record ImportProfileDto(
            String id,
            String name,
            String separator,
            String dateFormat,
            String dateColumn,
            String amountColumn,
            String debitColumn,
            String creditColumn,
            String labelColumn,
            String encoding,
            String decimalSeparator,
            int skipHeaderLines,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) {}

    public record ImportHistoryDto(
            String id,
            String accountId,
            int transactionCount,
            String fileName,
            LocalDateTime importedAt
    ) {}

    public record InvitationDto(
            String id,
            String token,
            String email,
            Instant expiresAt,
            Instant usedAt,
            Instant revokedAt,
            Instant createdAt
    ) {}
}
