package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.DebtType;
import fr.kksdev.budget.api.enums.EntityType;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.NotificationRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationSchedulerTest {

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Mock
    private DebtRepository debtRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private NotificationService notificationService;

    @Mock
    private PreferenceService preferenceService;

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private NotificationScheduler notificationScheduler;

    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    private final UUID userId = UUID.randomUUID();
    private final UUID subscriptionId = UUID.randomUUID();
    private final UUID debtId = UUID.randomUUID();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").name("Test").build();
    }

    private Subscription buildSubscription(LocalDate dateDebut, Frequency frequence) {
        return Subscription.builder()
                .id(subscriptionId)
                .nom("Netflix")
                .montant(BigDecimal.valueOf(15.99))
                .frequence(frequence)
                .dateDebut(dateDebut)
                .actif(true)
                .build();
    }

    private Debt buildDebt(LocalDate date, LocalDate dueDate) {
        return Debt.builder()
                .id(debtId)
                .personne("Alice")
                .montant(BigDecimal.valueOf(100))
                .sens(DebtType.EMPRUNT)
                .date(date)
                .dueDate(dueDate)
                .rembourse(false)
                .build();
    }

    @Test
    void should_create_subscription_notification_when_due_tomorrow() {
        var user = buildUser();
        var tomorrow = LocalDate.now(PARIS).plusDays(1);
        var sub = buildSubscription(tomorrow, Frequency.MENSUEL);

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.SUBSCRIPTION_DUE)).thenReturn(true);
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_DUE)).thenReturn(false);
        when(subscriptionRepository.findByUserIdAndActifTrueOrderByNomAsc(userId)).thenReturn(List.of(sub));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(eq(userId), eq(NotificationType.SUBSCRIPTION_DUE), eq(subscriptionId), any(LocalDateTime.class))).thenReturn(false);

        notificationScheduler.runDailyJob();

        verify(notificationService).createNotification(
                eq(userId),
                eq(NotificationType.SUBSCRIPTION_DUE),
                eq("Abonnement Netflix"),
                eq("Abonnement Netflix — échéance demain"),
                eq(EntityType.SUBSCRIPTION),
                eq(subscriptionId)
        );
        verify(notificationService).purgeOldNotifications(userId);
    }

    @Test
    void should_create_debt_notification_when_due_tomorrow() {
        var user = buildUser();
        var tomorrow = LocalDate.now(PARIS).plusDays(1);
        var debt = buildDebt(tomorrow, tomorrow);

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.SUBSCRIPTION_DUE)).thenReturn(false);
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_DUE)).thenReturn(true);
        when(debtRepository.findByUserIdAndRembourseFalseOrderByDateDesc(userId)).thenReturn(List.of(debt));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(eq(userId), eq(NotificationType.DEBT_DUE), eq(debtId), any(LocalDateTime.class))).thenReturn(false);

        notificationScheduler.runDailyJob();

        verify(notificationService).createNotification(
                eq(userId),
                eq(NotificationType.DEBT_DUE),
                eq("Dette Alice"),
                eq("Dette envers Alice — échéance demain"),
                eq(EntityType.DEBT),
                eq(debtId)
        );
        verify(notificationService).purgeOldNotifications(userId);
    }

    @Test
    void should_not_create_notification_when_type_disabled() {
        var user = buildUser();

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.SUBSCRIPTION_DUE)).thenReturn(false);
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_DUE)).thenReturn(false);

        notificationScheduler.runDailyJob();

        verify(notificationService, never()).createNotification(any(), any(), any(), any(), any(), any());
        verify(subscriptionRepository, never()).findByUserIdAndActifTrueOrderByNomAsc(any());
        verify(debtRepository, never()).findByUserIdAndRembourseFalseOrderByDateDesc(any());
    }

    @Test
    void should_not_create_notification_when_subscription_inactive() {
        var user = buildUser();

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.SUBSCRIPTION_DUE)).thenReturn(true);
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_DUE)).thenReturn(false);
        when(subscriptionRepository.findByUserIdAndActifTrueOrderByNomAsc(userId)).thenReturn(List.of());

        notificationScheduler.runDailyJob();

        verify(subscriptionRepository).findByUserIdAndActifTrueOrderByNomAsc(userId);
        verify(notificationService, never()).createNotification(any(), any(), any(), any(), any(), any());
    }

    @Test
    void should_calculate_next_due_date_when_monthly() {
        ZoneId zoneId = ZoneId.of("Europe/Paris");
        LocalDate dateDebut = LocalDate.now(zoneId).withDayOfMonth(15).minusMonths(3);

        LocalDate result = notificationScheduler.getNextDueDate(dateDebut, Frequency.MENSUEL, zoneId);

        assertThat(result).isAfterOrEqualTo(LocalDate.now(zoneId));
        assertThat(result.getDayOfMonth()).isEqualTo(15);
    }

    @Test
    void should_calculate_next_due_date_when_yearly() {
        ZoneId zoneId = ZoneId.of("Europe/Paris");
        LocalDate dateDebut = LocalDate.now(zoneId).withDayOfMonth(15).minusYears(3);

        LocalDate result = notificationScheduler.getNextDueDate(dateDebut, Frequency.ANNUEL, zoneId);

        assertThat(result).isAfterOrEqualTo(LocalDate.now(zoneId));
        assertThat(result.getDayOfMonth()).isEqualTo(15);
        assertThat(result.getMonthValue()).isEqualTo(dateDebut.getMonthValue());
    }

    @Test
    void should_clamp_day_when_month_has_fewer_days() {
        ZoneId zoneId = ZoneId.of("Europe/Paris");
        LocalDate dateDebut = LocalDate.of(2025, 1, 31);

        LocalDate result = notificationScheduler.getNextDueDate(dateDebut, Frequency.MENSUEL, zoneId);

        assertThat(result).isAfterOrEqualTo(LocalDate.now(zoneId));
        assertThat(result.getDayOfMonth()).isLessThanOrEqualTo(31);
    }

    @Test
    void should_purge_old_notifications_when_job_runs() {
        var user = buildUser();

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.SUBSCRIPTION_DUE)).thenReturn(false);
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_DUE)).thenReturn(false);

        notificationScheduler.runDailyJob();

        verify(notificationService).purgeOldNotifications(userId);
    }

    @Test
    void should_not_create_debt_notification_when_due_date_is_null() {
        var user = buildUser();
        var tomorrow = LocalDate.now(PARIS).plusDays(1);
        var debt = buildDebt(tomorrow, null);

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.SUBSCRIPTION_DUE)).thenReturn(false);
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_DUE)).thenReturn(true);
        when(debtRepository.findByUserIdAndRembourseFalseOrderByDateDesc(userId)).thenReturn(List.of(debt));

        notificationScheduler.runDailyJob();

        verify(notificationService, never()).createNotification(any(), any(), any(), any(), any(), any());
    }

    @Test
    void should_not_create_duplicate_notification_when_already_exists_today() {
        var user = buildUser();
        var tomorrow = LocalDate.now(PARIS).plusDays(1);
        var debt = buildDebt(tomorrow, tomorrow);

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.SUBSCRIPTION_DUE)).thenReturn(false);
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_DUE)).thenReturn(true);
        when(debtRepository.findByUserIdAndRembourseFalseOrderByDateDesc(userId)).thenReturn(List.of(debt));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(eq(userId), eq(NotificationType.DEBT_DUE), eq(debtId), any(LocalDateTime.class))).thenReturn(true);

        notificationScheduler.runDailyJob();

        verify(notificationService, never()).createNotification(any(), any(), any(), any(), any(), any());
    }

    // -------------------------------------------------------------------------
    // T030 — US4: checkDebtReminders (scheduler chaque minute)
    // -------------------------------------------------------------------------

    private Debt buildDebtWithReminder(LocalDate reminderDate, LocalTime reminderTime) {
        return Debt.builder()
                .id(debtId)
                .personne("Alice")
                .montant(BigDecimal.valueOf(100))
                .sens(DebtType.EMPRUNT)
                .date(LocalDate.of(2026, 1, 1))
                .currency(Currency.EUR)
                .rembourse(false)
                .reminderDate(reminderDate)
                .reminderTime(reminderTime)
                .build();
    }

    @Test
    void should_createNotification_when_reminderDue() {
        var user = buildUser();
        var now = LocalDate.now(PARIS);
        var time = LocalTime.now();
        var debt = buildDebtWithReminder(now, time.minusMinutes(1));

        when(debtRepository.findUsersWithActiveReminders()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_REMINDER)).thenReturn(true);
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(debtRepository.findDueReminders(eq(userId), any(LocalDate.class), any(LocalTime.class))).thenReturn(List.of(debt));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(eq(userId), eq(NotificationType.DEBT_REMINDER), eq(debtId), any(LocalDateTime.class))).thenReturn(false);
        when(transactionRepository.sumByDebtId(debtId)).thenReturn(BigDecimal.ZERO);

        notificationScheduler.checkDebtReminders();

        verify(notificationService).createNotification(
                eq(userId),
                eq(NotificationType.DEBT_REMINDER),
                eq("Rappel dette - Alice"),
                any(String.class),
                eq(EntityType.DEBT),
                eq(debtId)
        );
    }

    @Test
    void should_skipNotification_when_debtRepaid() {
        var user = buildUser();

        when(debtRepository.findUsersWithActiveReminders()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_REMINDER)).thenReturn(true);
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(debtRepository.findDueReminders(eq(userId), any(LocalDate.class), any(LocalTime.class))).thenReturn(List.of());

        notificationScheduler.checkDebtReminders();

        verify(notificationService, never()).createNotification(any(), any(), any(), any(), any(), any());
    }

    @Test
    void should_skipNotification_when_alreadyNotified24h() {
        var user = buildUser();
        var now = LocalDate.now(PARIS);
        var debt = buildDebtWithReminder(now, LocalTime.of(10, 0));

        when(debtRepository.findUsersWithActiveReminders()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_REMINDER)).thenReturn(true);
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(debtRepository.findDueReminders(eq(userId), any(LocalDate.class), any(LocalTime.class))).thenReturn(List.of(debt));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(eq(userId), eq(NotificationType.DEBT_REMINDER), eq(debtId), any(LocalDateTime.class))).thenReturn(true);

        notificationScheduler.checkDebtReminders();

        verify(notificationService, never()).createNotification(any(), any(), any(), any(), any(), any());
    }

    @Test
    void should_skipNotification_when_reminderTypeDisabled() {
        var user = buildUser();

        when(debtRepository.findUsersWithActiveReminders()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_REMINDER)).thenReturn(false);

        notificationScheduler.checkDebtReminders();

        verify(debtRepository, never()).findDueReminders(any(), any(), any());
    }

    // -------------------------------------------------------------------------
    // T017/T018 — US3: checkRecurringTransactions (scheduler 8h)
    // -------------------------------------------------------------------------

    private Account buildAccount() {
        return Account.builder()
                .id(UUID.randomUUID())
                .nom("Compte courant")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("💳")
                .couleur("#000000")
                .currency(Currency.EUR)
                .build();
    }

    private Transaction buildRecurringTransaction(UUID id, LocalDate nextOccurrence, boolean recurringActive) {
        return Transaction.builder()
                .id(id)
                .montant(BigDecimal.valueOf(800))
                .libelle("Loyer")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.now(PARIS))
                .isRecurring(true)
                .frequency(Frequency.MENSUEL)
                .nextOccurrence(nextOccurrence)
                .recurringActive(recurringActive)
                .account(buildAccount())
                .user(buildUser())
                .build();
    }

    @Test
    void should_createNotification_when_recurringTransactionDue() {
        var user = buildUser();
        var recurringId = UUID.randomUUID();
        var recurring = buildRecurringTransaction(recurringId, LocalDate.now(PARIS), true);

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.RECURRING_TRANSACTION_DUE)).thenReturn(true);
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(transactionRepository.findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual(eq(userId), any(LocalDate.class))).thenReturn(List.of(recurring));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(eq(userId), eq(NotificationType.RECURRING_TRANSACTION_DUE), eq(recurringId), any(LocalDateTime.class))).thenReturn(false);

        notificationScheduler.checkRecurringTransactions();

        verify(notificationService).createNotification(
                eq(userId),
                eq(NotificationType.RECURRING_TRANSACTION_DUE),
                eq("Transaction récurrente Loyer"),
                any(String.class),
                eq(EntityType.TRANSACTION),
                eq(recurringId)
        );
    }

    @Test
    void should_notCreateNotification_when_noRecurringDue() {
        var user = buildUser();

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.RECURRING_TRANSACTION_DUE)).thenReturn(true);
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(transactionRepository.findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual(eq(userId), any(LocalDate.class))).thenReturn(List.of());

        notificationScheduler.checkRecurringTransactions();

        verify(notificationService, never()).createNotification(any(), eq(NotificationType.RECURRING_TRANSACTION_DUE), any(), any(), any(), any());
    }

    @Test
    void should_createNotificationDaily_when_notValidatedYesterday() {
        var user = buildUser();
        var recurringId = UUID.randomUUID();
        var recurring = buildRecurringTransaction(recurringId, LocalDate.now(PARIS), true);

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.RECURRING_TRANSACTION_DUE)).thenReturn(true);
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(transactionRepository.findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual(eq(userId), any(LocalDate.class))).thenReturn(List.of(recurring));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(eq(userId), eq(NotificationType.RECURRING_TRANSACTION_DUE), eq(recurringId), any(LocalDateTime.class))).thenReturn(false);

        notificationScheduler.checkRecurringTransactions();

        verify(notificationService).createNotification(
                eq(userId),
                eq(NotificationType.RECURRING_TRANSACTION_DUE),
                any(String.class),
                any(String.class),
                eq(EntityType.TRANSACTION),
                eq(recurringId)
        );
    }

    @Test
    void should_notDuplicate_when_schedulerRunsTwiceSameDay() {
        var user = buildUser();
        var recurringId = UUID.randomUUID();
        var recurring = buildRecurringTransaction(recurringId, LocalDate.now(PARIS), true);

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.RECURRING_TRANSACTION_DUE)).thenReturn(true);
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(transactionRepository.findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual(eq(userId), any(LocalDate.class))).thenReturn(List.of(recurring));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(eq(userId), eq(NotificationType.RECURRING_TRANSACTION_DUE), eq(recurringId), any(LocalDateTime.class))).thenReturn(true);

        notificationScheduler.checkRecurringTransactions();

        verify(notificationService, never()).createNotification(any(), eq(NotificationType.RECURRING_TRANSACTION_DUE), any(), any(), any(), any());
    }

    @Test
    void should_skipNotification_when_recurringTransactionDueDisabled() {
        var user = buildUser();

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.RECURRING_TRANSACTION_DUE)).thenReturn(false);

        notificationScheduler.checkRecurringTransactions();

        verify(transactionRepository, never()).findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual(any(), any());
        verify(notificationService, never()).createNotification(any(), eq(NotificationType.RECURRING_TRANSACTION_DUE), any(), any(), any(), any());
    }

    @Test
    void should_notNotify_when_recurrenceInactive() {
        var user = buildUser();

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.RECURRING_TRANSACTION_DUE)).thenReturn(true);
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        // La query filtre recurringActive=true, donc elle renvoie une liste vide
        when(transactionRepository.findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual(eq(userId), any(LocalDate.class))).thenReturn(List.of());

        notificationScheduler.checkRecurringTransactions();

        verify(notificationService, never()).createNotification(any(), eq(NotificationType.RECURRING_TRANSACTION_DUE), any(), any(), any(), any());
    }

    @Test
    void should_notCreateTransaction_when_schedulerRuns() {
        var user = buildUser();
        var recurringId = UUID.randomUUID();
        var recurring = buildRecurringTransaction(recurringId, LocalDate.now(PARIS), true);

        when(userRepository.findAll()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.RECURRING_TRANSACTION_DUE)).thenReturn(true);
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(transactionRepository.findByUserIdAndIsRecurringTrueAndRecurringActiveTrueAndNextOccurrenceLessThanEqual(eq(userId), any(LocalDate.class))).thenReturn(List.of(recurring));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(eq(userId), eq(NotificationType.RECURRING_TRANSACTION_DUE), eq(recurringId), any(LocalDateTime.class))).thenReturn(false);

        notificationScheduler.checkRecurringTransactions();

        verify(transactionRepository, never()).save(any());
    }

    @Test
    void should_processMultipleDebts_when_multipleDue() {
        var user = buildUser();
        var now = LocalDate.now(PARIS);
        var debt1 = buildDebtWithReminder(now, LocalTime.of(10, 0));
        var debt2Id = UUID.randomUUID();
        var debt2 = Debt.builder()
                .id(debt2Id)
                .personne("Bob")
                .montant(BigDecimal.valueOf(200))
                .sens(DebtType.PRET)
                .date(LocalDate.of(2026, 1, 1))
                .currency(Currency.EUR)
                .rembourse(false)
                .reminderDate(now)
                .reminderTime(LocalTime.of(9, 0))
                .build();

        when(debtRepository.findUsersWithActiveReminders()).thenReturn(List.of(user));
        when(preferenceService.isNotificationTypeEnabled(userId, NotificationType.DEBT_REMINDER)).thenReturn(true);
        when(preferenceService.getUserTimezone(userId)).thenReturn("Europe/Paris");
        when(debtRepository.findDueReminders(eq(userId), any(LocalDate.class), any(LocalTime.class))).thenReturn(List.of(debt1, debt2));
        when(notificationRepository.existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(eq(userId), eq(NotificationType.DEBT_REMINDER), any(UUID.class), any(LocalDateTime.class))).thenReturn(false);
        when(transactionRepository.sumByDebtId(debtId)).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumByDebtId(debt2Id)).thenReturn(BigDecimal.valueOf(50));

        notificationScheduler.checkDebtReminders();

        verify(notificationService).createNotification(eq(userId), eq(NotificationType.DEBT_REMINDER), eq("Rappel dette - Alice"), any(String.class), eq(EntityType.DEBT), eq(debtId));
        verify(notificationService).createNotification(eq(userId), eq(NotificationType.DEBT_REMINDER), eq("Rappel dette - Bob"), any(String.class), eq(EntityType.DEBT), eq(debt2Id));
    }
}
