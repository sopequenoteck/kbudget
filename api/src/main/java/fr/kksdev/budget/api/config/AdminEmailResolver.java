package fr.kksdev.budget.api.config;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Component
public class AdminEmailResolver {

    @Value("${app.admin-emails:}")
    private List<String> rawAdminEmails;

    private Set<String> adminEmails;

    @PostConstruct
    public void init() {
        adminEmails = rawAdminEmails.stream()
                .map(String::trim)
                .map(String::toLowerCase)
                .filter(e -> !e.isEmpty())
                .collect(Collectors.toUnmodifiableSet());

        if (adminEmails.isEmpty()) {
            log.warn("ADMIN_EMAILS not configured — invitations cannot be issued until an admin is configured.");
        }
    }

    public boolean isAdminEmail(String email) {
        if (email == null) {
            return false;
        }
        return adminEmails.contains(email.trim().toLowerCase());
    }

    public Set<String> listAdminEmails() {
        return adminEmails;
    }
}
