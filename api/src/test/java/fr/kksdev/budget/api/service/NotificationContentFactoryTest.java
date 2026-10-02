package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.Currency;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.Month;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Contenu (title/message anglais, params) par type de notification (KKS-397).
 * L'API ne traduit jamais : title/message sont des defauts anglais fixes ici,
 * params porte les valeurs brutes que le client compose dans sa langue.
 */
class NotificationContentFactoryTest {

    @Test
    void should_build_subscription_due_content_when_name_given() {
        NotificationContent content = NotificationContentFactory.subscriptionDue("Netflix");

        assertThat(content.title()).isEqualTo("Subscription Netflix");
        assertThat(content.message()).isEqualTo("Netflix is due tomorrow");
        assertThat(content.params()).isEqualTo(Map.of("name", "Netflix"));
    }

    @Test
    void should_build_debt_due_content_when_person_given() {
        NotificationContent content = NotificationContentFactory.debtDue("Alice");

        assertThat(content.title()).isEqualTo("Debt with Alice");
        assertThat(content.message()).isEqualTo("Debt with Alice is due tomorrow");
        assertThat(content.params()).isEqualTo(Map.of("person", "Alice"));
    }

    @Test
    void should_build_debt_reminder_content_when_amount_and_currency_given() {
        NotificationContent content = NotificationContentFactory.debtReminder("Alice", "100.50", Currency.EUR);

        assertThat(content.title()).isEqualTo("Debt reminder - Alice");
        assertThat(content.message()).isEqualTo("Reminder: 100.50 EUR left on the debt with Alice");
        assertThat(content.params()).isEqualTo(Map.of("person", "Alice", "amount", "100.50", "currency", "EUR"));
    }

    @Test
    void should_build_budget_threshold_content_when_category_is_user_defined() {
        NotificationContent content = NotificationContentFactory.budgetThreshold("Alimentation", null, 80);

        assertThat(content.title()).isEqualTo("Budget Alimentation: 80%");
        assertThat(content.message()).isEqualTo("You have reached 80% of the Alimentation budget");
        assertThat(content.params()).isEqualTo(Map.of("category", "Alimentation", "percentage", "80"));
    }

    @Test
    void should_include_categorySystemKey_when_budget_threshold_category_is_system() {
        NotificationContent content = NotificationContentFactory.budgetThreshold("Abonnements", "SUBSCRIPTION", 80);

        assertThat(content.params()).isEqualTo(
                Map.of("category", "Abonnements", "categorySystemKey", "SUBSCRIPTION", "percentage", "80"));
    }

    @Test
    void should_build_budget_exceeded_content_when_category_is_user_defined() {
        NotificationContent content = NotificationContentFactory.budgetExceeded("Alimentation", null, 120);

        assertThat(content.title()).isEqualTo("Budget Alimentation exceeded");
        assertThat(content.message()).isEqualTo("You have exceeded the Alimentation budget (120%)");
        assertThat(content.params()).isEqualTo(Map.of("category", "Alimentation", "percentage", "120"));
    }

    @Test
    void should_include_categorySystemKey_when_budget_exceeded_category_is_system() {
        NotificationContent content = NotificationContentFactory.budgetExceeded("Abonnements", "SUBSCRIPTION", 120);

        assertThat(content.params()).isEqualTo(
                Map.of("category", "Abonnements", "categorySystemKey", "SUBSCRIPTION", "percentage", "120"));
    }

    @Test
    void should_build_recurring_transaction_due_content_when_account_present() {
        LocalDate dueDate = LocalDate.of(2026, Month.JANUARY, 15);

        NotificationContent content = NotificationContentFactory.recurringTransactionDue("Loyer", "800", Currency.EUR, dueDate);

        assertThat(content.title()).isEqualTo("Recurring transaction Loyer");
        assertThat(content.message()).isEqualTo("Loyer 800 EUR due on 2026-01-15");
        assertThat(content.params()).isEqualTo(
                Map.of("label", "Loyer", "amount", "800", "currency", "EUR", "dueDate", "2026-01-15"));
    }

    @Test
    void should_omit_currency_when_recurring_transaction_has_no_account() {
        LocalDate dueDate = LocalDate.of(2026, Month.JANUARY, 15);

        NotificationContent content = NotificationContentFactory.recurringTransactionDue("Loyer", "800", null, dueDate);

        assertThat(content.title()).isEqualTo("Recurring transaction Loyer");
        assertThat(content.message()).isEqualTo("Loyer 800 due on 2026-01-15");
        assertThat(content.params()).isEqualTo(Map.of("label", "Loyer", "amount", "800", "dueDate", "2026-01-15"));
    }
}
