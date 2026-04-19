package fr.kksdev.budget.api.config;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class AdminEmailResolverTest {

    private AdminEmailResolver buildResolver(List<String> rawEmails) {
        var resolver = new AdminEmailResolver();
        ReflectionTestUtils.setField(resolver, "rawAdminEmails", rawEmails);
        resolver.init();
        return resolver;
    }

    @Test
    void should_return_true_when_email_matches_normalized() {
        var resolver = buildResolver(List.of("admin@example.com"));

        assertThat(resolver.isAdminEmail("admin@example.com")).isTrue();
    }

    @Test
    void should_trim_and_lowercase_admin_emails() {
        var resolver = buildResolver(List.of("  Admin@Example.com ", "other@test.fr"));

        assertThat(resolver.isAdminEmail("admin@example.com")).isTrue();
        assertThat(resolver.isAdminEmail("OTHER@TEST.FR")).isTrue();
    }

    @Test
    void should_return_false_when_email_not_in_list() {
        var resolver = buildResolver(List.of("admin@example.com"));

        assertThat(resolver.isAdminEmail("notadmin@example.com")).isFalse();
    }

    @Test
    void should_return_false_when_email_null() {
        var resolver = buildResolver(List.of("admin@example.com"));

        assertThat(resolver.isAdminEmail(null)).isFalse();
    }

    @Test
    void should_be_empty_when_property_empty() {
        var resolver = buildResolver(List.of());

        assertThat(resolver.listAdminEmails()).isEmpty();
        assertThat(resolver.isAdminEmail("anyone@example.com")).isFalse();
    }
}
