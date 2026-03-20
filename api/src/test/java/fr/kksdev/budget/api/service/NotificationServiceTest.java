package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.NotificationResponse;
import fr.kksdev.budget.api.enums.EntityType;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.model.Notification;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.NotificationRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    @InjectMocks
    private NotificationService notificationService;

    private final UUID userId = UUID.randomUUID();
    private final UUID notificationId = UUID.randomUUID();
    private final UUID entityId = UUID.randomUUID();

    private User buildUser(UUID id) {
        return User.builder().id(id).email("test@mail.com").name("Test").build();
    }

    private Notification buildNotification(User user, boolean read) {
        return Notification.builder()
                .id(notificationId)
                .user(user)
                .type(NotificationType.SUBSCRIPTION_DUE)
                .title("Abonnement Netflix")
                .message("Abonnement Netflix — échéance demain")
                .entityType(EntityType.SUBSCRIPTION)
                .entityId(entityId)
                .read(read)
                .readAt(read ? LocalDateTime.now() : null)
                .createdAt(LocalDateTime.now())
                .build();
    }

    @Test
    void should_create_notification_when_valid_params() {
        var user = buildUser(userId);
        var saved = buildNotification(user, false);

        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(notificationRepository.save(any(Notification.class))).thenReturn(saved);

        NotificationResponse response = notificationService.createNotification(
                userId,
                NotificationType.SUBSCRIPTION_DUE,
                "Abonnement Netflix",
                "Abonnement Netflix — échéance demain",
                EntityType.SUBSCRIPTION,
                entityId
        );

        assertThat(response.id()).isEqualTo(notificationId);
        assertThat(response.type()).isEqualTo(NotificationType.SUBSCRIPTION_DUE);
        assertThat(response.title()).isEqualTo("Abonnement Netflix");
        assertThat(response.read()).isFalse();
        verify(notificationRepository).save(any(Notification.class));
        verify(messagingTemplate).convertAndSendToUser(
                eq(userId.toString()),
                eq("/queue/notifications"),
                any(NotificationResponse.class)
        );
    }

    @Test
    void should_return_paginated_notifications_when_user_has_notifications() {
        var user = buildUser(userId);
        var notification = buildNotification(user, false);
        var pageable = PageRequest.of(0, 20);
        var page = new PageImpl<>(List.of(notification), pageable, 1);

        when(notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)).thenReturn(page);

        var result = notificationService.getNotifications(userId, pageable, null);

        assertThat(result.getTotalElements()).isEqualTo(1);
        assertThat(result.getContent().getFirst().id()).isEqualTo(notificationId);
        assertThat(result.getContent().getFirst().title()).isEqualTo("Abonnement Netflix");
    }

    @Test
    void should_filter_unread_notifications_when_unread_param_is_true() {
        var user = buildUser(userId);
        var notification = buildNotification(user, false);
        var pageable = PageRequest.of(0, 20);
        var page = new PageImpl<>(List.of(notification), pageable, 1);

        when(notificationRepository.findByUserIdAndReadOrderByCreatedAtDesc(userId, false, pageable)).thenReturn(page);

        var result = notificationService.getNotifications(userId, pageable, true);

        assertThat(result.getTotalElements()).isEqualTo(1);
        verify(notificationRepository).findByUserIdAndReadOrderByCreatedAtDesc(userId, false, pageable);
    }

    @Test
    void should_mark_as_read_when_notification_exists() {
        var user = buildUser(userId);
        var notification = buildNotification(user, false);

        when(notificationRepository.findByIdAndUserId(notificationId, userId)).thenReturn(Optional.of(notification));
        when(notificationRepository.save(notification)).thenReturn(notification);

        NotificationResponse response = notificationService.markAsRead(userId, notificationId);

        assertThat(response).isNotNull();
        assertThat(notification.isRead()).isTrue();
        assertThat(notification.getReadAt()).isNotNull();
        verify(notificationRepository).save(notification);
    }

    @Test
    void should_throw_when_marking_other_user_notification() {
        when(notificationRepository.findByIdAndUserId(notificationId, userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> notificationService.markAsRead(userId, notificationId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Notification non trouvée");
    }

    @Test
    void should_throw_when_notification_not_found_on_mark_as_read() {
        when(notificationRepository.findByIdAndUserId(notificationId, userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> notificationService.markAsRead(userId, notificationId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Notification non trouvée");
    }

    @Test
    void should_delete_notification_when_owned() {
        var user = buildUser(userId);
        var notification = buildNotification(user, false);

        when(notificationRepository.findByIdAndUserId(notificationId, userId)).thenReturn(Optional.of(notification));

        notificationService.deleteNotification(userId, notificationId);

        verify(notificationRepository).delete(notification);
    }

    @Test
    void should_throw_when_deleting_other_user_notification() {
        when(notificationRepository.findByIdAndUserId(notificationId, userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> notificationService.deleteNotification(userId, notificationId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Notification non trouvée");
    }

    @Test
    void should_purge_old_notifications_when_older_than_90_days() {
        ArgumentCaptor<LocalDateTime> cutoffCaptor = ArgumentCaptor.forClass(LocalDateTime.class);

        notificationService.purgeOldNotifications(userId);

        verify(notificationRepository).deleteByUserIdAndCreatedAtBefore(eq(userId), cutoffCaptor.capture());
        LocalDateTime captured = cutoffCaptor.getValue();
        assertThat(captured).isBefore(LocalDateTime.now().minusDays(89));
    }
}
