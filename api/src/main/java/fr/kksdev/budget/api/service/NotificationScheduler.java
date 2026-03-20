package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.EntityType;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.NotificationRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationScheduler {

    private final SubscriptionRepository subscriptionRepository;
    private final DebtRepository debtRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final PreferenceService preferenceService;
    private final NotificationRepository notificationRepository;
    private final TransactionRepository transactionRepository;

    @Scheduled(cron = "0 0 6 * * *")
    public void runDailyJob() {
        log.info("Démarrage du job quotidien de notifications");
        int count = 0;

        List<User> users = userRepository.findAll();
        for (User user : users) {
            UUID userId = user.getId();
            try {
                log.info("Traitement des notifications pour userId={}", userId);
                String timezone = preferenceService.getUserTimezone(userId);
                ZoneId zoneId = ZoneId.of(timezone);
                LocalDate tomorrow = LocalDate.now(zoneId).plusDays(1);

                count += processSubscriptions(userId, tomorrow, zoneId);
                count += processDebts(userId, tomorrow, zoneId);

                log.info("Purge des anciennes notifications pour userId={}", userId);
                notificationService.purgeOldNotifications(userId);
            } catch (Exception e) {
                log.error("Erreur lors du traitement des notifications pour userId={}", userId, e);
            }
        }

        log.info("Job quotidien terminé: {} notifications générées", count);
    }

    private int processSubscriptions(UUID userId, LocalDate tomorrow, ZoneId zoneId) {
        if (!preferenceService.isNotificationTypeEnabled(userId, NotificationType.SUBSCRIPTION_DUE)) {
            return 0;
        }

        int count = 0;
        List<Subscription> subscriptions = subscriptionRepository.findByUserIdAndActifTrueOrderByNomAsc(userId);
        for (Subscription sub : subscriptions) {
            LocalDate nextDue = getNextDueDate(sub.getDateDebut(), sub.getFrequence(), zoneId);
            if (nextDue.equals(tomorrow)) {
                LocalDateTime since = LocalDateTime.now(zoneId).minusHours(24);
                if (notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(userId, NotificationType.SUBSCRIPTION_DUE, sub.getId(), since)) {
                    continue;
                }
                notificationService.createNotification(
                        userId,
                        NotificationType.SUBSCRIPTION_DUE,
                        "Abonnement " + sub.getNom(),
                        "Abonnement " + sub.getNom() + " — échéance demain",
                        EntityType.SUBSCRIPTION,
                        sub.getId()
                );
                log.info("Notification abonnement créée: {} pour userId={}", sub.getNom(), userId);
                count++;
            }
        }
        return count;
    }

    private int processDebts(UUID userId, LocalDate tomorrow, ZoneId zoneId) {
        if (!preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_DUE)) {
            return 0;
        }

        int count = 0;
        List<Debt> debts = debtRepository.findByUserIdAndRembourseFalseOrderByDateDesc(userId);
        for (Debt debt : debts) {
            if (debt.getDueDate() != null && debt.getDueDate().equals(tomorrow)) {
                LocalDateTime since = LocalDateTime.now(zoneId).minusHours(24);
                if (notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(userId, NotificationType.DEBT_DUE, debt.getId(), since)) {
                    continue;
                }
                notificationService.createNotification(
                        userId,
                        NotificationType.DEBT_DUE,
                        "Dette " + debt.getPersonne(),
                        "Dette envers " + debt.getPersonne() + " — échéance demain",
                        EntityType.DEBT,
                        debt.getId()
                );
                log.info("Notification dette créée: {} pour userId={}", debt.getPersonne(), userId);
                count++;
            }
        }
        return count;
    }

    @Scheduled(fixedDelay = 60_000)
    public void checkDebtReminders() {
        List<User> users = debtRepository.findUsersWithActiveReminders();
        int count = 0;
        for (User user : users) {
            UUID userId = user.getId();
            try {
                if (!preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_REMINDER)) {
                    continue;
                }
                String timezone = preferenceService.getUserTimezone(userId);
                ZoneId zoneId = ZoneId.of(timezone);
                LocalDate dateInTz = LocalDate.now(zoneId);
                LocalTime timeInTz = LocalTime.now(zoneId);

                List<Debt> dueDebts = debtRepository.findDueReminders(userId, dateInTz, timeInTz);
                for (Debt debt : dueDebts) {
                    LocalDateTime since = LocalDateTime.now(zoneId).minusHours(24);
                    if (notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(
                            userId, NotificationType.DEBT_REMINDER, debt.getId(), since)) {
                        continue;
                    }

                    BigDecimal paid = transactionRepository.sumByDebtId(debt.getId());
                    BigDecimal remaining = debt.getMontant().subtract(paid != null ? paid : BigDecimal.ZERO);

                    notificationService.createNotification(
                            userId,
                            NotificationType.DEBT_REMINDER,
                            "Rappel dette - " + debt.getPersonne(),
                            "Rappel : dette envers " + debt.getPersonne() + " — " + remaining + " " + debt.getCurrency().getSymbol() + " restant",
                            EntityType.DEBT,
                            debt.getId()
                    );
                    count++;
                    log.info("Notification rappel dette créée: {} pour userId={}", debt.getPersonne(), userId);
                }
            } catch (Exception e) {
                log.error("Erreur traitement rappels dette pour userId={}", userId, e);
            }
        }
        if (count > 0) {
            log.info("Rappels dette traités: {} notifications générées", count);
        }
    }

    @Scheduled(cron = "0 0 8 * * *")
    public void checkRecurringTransactions() {
        log.info("Démarrage du job récurrences");
        int count = 0;

        List<User> users = userRepository.findAll();
        for (User user : users) {
            UUID userId = user.getId();
            try {
                count += processRecurringTransactions(userId);
            } catch (Exception e) {
                log.error("Erreur traitement récurrences pour userId={}", userId, e);
            }
        }

        log.info("Job récurrences terminé: {} notifications générées", count);
    }

    private int processRecurringTransactions(UUID userId) {
        if (!preferenceService.isNotificationTypeEnabled(userId, NotificationType.RECURRING_TRANSACTION_DUE)) {
            return 0;
        }

        String timezone = preferenceService.getUserTimezone(userId);
        ZoneId zoneId = ZoneId.of(timezone);
        LocalDate today = LocalDate.now(zoneId);

        int count = 0;
        List<Transaction> dueRecurrences = transactionRepository
                .findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual(userId, today);

        for (Transaction recurring : dueRecurrences) {
            LocalDateTime since = LocalDateTime.now(zoneId).minusHours(24);
            if (notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(
                    userId, NotificationType.RECURRING_TRANSACTION_DUE, recurring.getId(), since)) {
                continue;
            }

            String currency = recurring.getAccount() != null ? recurring.getAccount().getCurrency().getSymbol() : "€";
            notificationService.createNotification(
                    userId,
                    NotificationType.RECURRING_TRANSACTION_DUE,
                    "Transaction récurrente " + recurring.getLibelle(),
                    recurring.getLibelle() + " " + recurring.getMontant() + currency + " — échéance " + recurring.getNextOccurrence(),
                    EntityType.TRANSACTION,
                    recurring.getId()
            );
            log.info("Notification récurrence créée: {} pour userId={}", recurring.getLibelle(), userId);
            count++;
        }
        return count;
    }

    LocalDate getNextDueDate(LocalDate dateDebut, Frequency frequence, ZoneId zoneId) {
        LocalDate today = LocalDate.now(zoneId);
        if (!dateDebut.isBefore(today)) return dateDebut;

        long periodsElapsed = switch (frequence) {
            case HEBDOMADAIRE -> ChronoUnit.WEEKS.between(dateDebut, today);
            case MENSUEL -> ChronoUnit.MONTHS.between(dateDebut, today);
            case ANNUEL -> ChronoUnit.YEARS.between(dateDebut, today);
        };

        LocalDate nextDue = switch (frequence) {
            case HEBDOMADAIRE -> dateDebut.plusWeeks(periodsElapsed);
            case MENSUEL -> dateDebut.plusMonths(periodsElapsed);
            case ANNUEL -> dateDebut.plusYears(periodsElapsed);
        };

        if (nextDue.isBefore(today)) {
            nextDue = switch (frequence) {
                case HEBDOMADAIRE -> nextDue.plusWeeks(1);
                case MENSUEL -> nextDue.plusMonths(1);
                case ANNUEL -> nextDue.plusYears(1);
            };
        }
        return nextDue;
    }
}
