package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.response.NotificationResponse;
import fr.kksdev.budget.api.enums.EntityType;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.NotificationService;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(NotificationController.class)
@Import(SecurityConfig.class)
class NotificationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private NotificationService notificationService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final UUID notificationId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        var testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmailAndDisabledAtIsNull("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    private NotificationResponse buildNotificationResponse(UUID id, boolean read) {
        return new NotificationResponse(
                id,
                NotificationType.SUBSCRIPTION_DUE,
                "Abonnement Netflix",
                "Abonnement Netflix — échéance demain",
                EntityType.SUBSCRIPTION,
                UUID.randomUUID(),
                read,
                read ? LocalDateTime.now() : null,
                LocalDateTime.now()
        );
    }

    @Test
    void should_return_paginated_notifications_when_authenticated() throws Exception {
        var notification = buildNotificationResponse(notificationId, false);
        var page = new PageImpl<>(List.of(notification), PageRequest.of(0, 20), 1);

        when(notificationService.getNotifications(eq(userId), any(), any())).thenReturn(page);

        mockMvc.perform(get("/notifications")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].id").value(notificationId.toString()))
                .andExpect(jsonPath("$.content[0].title").value("Abonnement Netflix"))
                .andExpect(jsonPath("$.content[0].read").value(false))
                .andExpect(jsonPath("$.totalElements").value(1));
    }

    @Test
    void should_return_unread_count_when_has_unread() throws Exception {
        when(notificationService.getUnreadCount(userId)).thenReturn(3L);

        mockMvc.perform(get("/notifications/unread-count")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count").value(3));
    }

    @Test
    void should_mark_as_read_when_valid_id() throws Exception {
        var notification = buildNotificationResponse(notificationId, true);

        when(notificationService.markAsRead(userId, notificationId)).thenReturn(notification);

        mockMvc.perform(put("/notifications/{id}/read", notificationId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(notificationId.toString()))
                .andExpect(jsonPath("$.read").value(true));
    }

    @Test
    void should_mark_all_as_read_when_has_unread() throws Exception {
        doNothing().when(notificationService).markAllAsRead(userId);

        mockMvc.perform(put("/notifications/read-all")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_delete_notification_when_valid_id() throws Exception {
        doNothing().when(notificationService).deleteNotification(userId, notificationId);

        mockMvc.perform(delete("/notifications/{id}", notificationId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_delete_all_notifications_when_authenticated() throws Exception {
        doNothing().when(notificationService).deleteAllNotifications(userId);

        mockMvc.perform(delete("/notifications")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_return_404_when_notification_not_found() throws Exception {
        UUID randomId = UUID.randomUUID();
        when(notificationService.markAsRead(eq(userId), eq(randomId)))
                .thenThrow(new EntityNotFoundException("Notification non trouvée"));

        mockMvc.perform(put("/notifications/{id}/read", randomId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Notification non trouvée"));
    }

    @Test
    void should_return_403_when_marking_other_user_notification_as_read() throws Exception {
        UUID otherNotificationId = UUID.randomUUID();
        when(notificationService.markAsRead(eq(userId), eq(otherNotificationId)))
                .thenThrow(new org.springframework.security.access.AccessDeniedException("Accès refusé"));

        mockMvc.perform(put("/notifications/{id}/read", otherNotificationId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isForbidden());
    }

    @Test
    void should_return_403_when_deleting_other_user_notification() throws Exception {
        UUID otherNotificationId = UUID.randomUUID();
        doThrow(new org.springframework.security.access.AccessDeniedException("Accès refusé"))
                .when(notificationService).deleteNotification(eq(userId), eq(otherNotificationId));

        mockMvc.perform(delete("/notifications/{id}", otherNotificationId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isForbidden());
    }

    @Test
    void should_return_401_when_no_token() throws Exception {
        mockMvc.perform(get("/notifications"))
                .andExpect(status().isUnauthorized());
    }
}
