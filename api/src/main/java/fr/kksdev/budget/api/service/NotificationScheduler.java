package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.EntityType;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.NotificationRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
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
                count += processDebts(userId, tomorrow);

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
                LocalDateTime since = LocalDateTime.now().minusHours(24);
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

    private int processDebts(UUID userId, LocalDate tomorrow) {
        if (!preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_DUE)) {
            return 0;
        }

        int count = 0;
        List<Debt> debts = debtRepository.findByUserIdAndRembourseFalseOrderByDateDesc(userId);
        for (Debt debt : debts) {
            if (debt.getDueDate() != null && debt.getDueDate().equals(tomorrow)) {
                LocalDateTime since = LocalDateTime.now().minusHours(24);
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

    LocalDate getNextDueDate(LocalDate dateDebut, Frequency frequence, ZoneId zoneId) {
        LocalDate today = LocalDate.now(zoneId);
        LocalDate nextDue = dateDebut;
        while (nextDue.isBefore(today)) {
            nextDue = switch (frequence) {
                case HEBDOMADAIRE -> nextDue.plusWeeks(1);
                case MENSUEL -> nextDue.plusMonths(1);
                case ANNUEL -> nextDue.plusYears(1);
            };
        }
        return nextDue;
    }
}
