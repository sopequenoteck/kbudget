package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.NotificationResponse;
import fr.kksdev.budget.api.enums.EntityType;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.model.Notification;
import fr.kksdev.budget.api.repository.NotificationRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    @Transactional
    public NotificationResponse createNotification(UUID userId, NotificationType type, String title, String message, EntityType entityType, UUID entityId) {
        Notification notification = Notification.builder()
                .user(userRepository.getReferenceById(userId))
                .type(type)
                .title(title)
                .message(message)
                .entityType(entityType)
                .entityId(entityId)
                .build();
        notification = notificationRepository.save(notification);
        log.info("Notification créée: type={}, userId={}", type, userId);
        NotificationResponse response = toResponse(notification);
        messagingTemplate.convertAndSendToUser(
                userId.toString(),
                "/queue/notifications",
                response
        );
        return response;
    }

    public Page<NotificationResponse> getNotifications(UUID userId, Pageable pageable, Boolean unread) {
        Page<Notification> page;
        if (unread != null && unread) {
            page = notificationRepository.findByUserIdAndReadOrderByCreatedAtDesc(userId, false, pageable);
        } else {
            page = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
        }
        return page.map(this::toResponse);
    }

    public long getUnreadCount(UUID userId) {
        return notificationRepository.countByUserIdAndRead(userId, false);
    }

    @Transactional
    public NotificationResponse markAsRead(UUID userId, UUID notificationId) {
        Notification notification = notificationRepository.findByIdAndUserId(notificationId, userId)
                .orElseThrow(() -> new EntityNotFoundException("Notification non trouvée"));
        notification.setRead(true);
        notification.setReadAt(LocalDateTime.now());
        notification = notificationRepository.save(notification);
        log.info("Notification lue: id={}, userId={}", notificationId, userId);
        return toResponse(notification);
    }

    @Transactional
    public void markAllAsRead(UUID userId) {
        int count = notificationRepository.markAllAsReadByUserId(userId, LocalDateTime.now());
        log.info("Toutes les notifications marquées lues: userId={}, count={}", userId, count);
    }

    @Transactional
    public void deleteNotification(UUID userId, UUID notificationId) {
        Notification notification = notificationRepository.findByIdAndUserId(notificationId, userId)
                .orElseThrow(() -> new EntityNotFoundException("Notification non trouvée"));
        notificationRepository.delete(notification);
        log.info("Notification supprimée: id={}, userId={}", notificationId, userId);
    }

    @Transactional
    public void deleteAllNotifications(UUID userId) {
        notificationRepository.deleteByUserId(userId);
        log.info("Toutes les notifications supprimées: userId={}", userId);
    }

    @Transactional
    public void purgeOldNotifications(UUID userId) {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(90);
        notificationRepository.deleteByUserIdAndCreatedAtBefore(userId, cutoff);
        log.info("Purge des notifications > 90 jours: userId={}", userId);
    }

    private NotificationResponse toResponse(Notification notification) {
        return new NotificationResponse(
                notification.getId(),
                notification.getType(),
                notification.getTitle(),
                notification.getMessage(),
                notification.getEntityType(),
                notification.getEntityId(),
                notification.isRead(),
                notification.getReadAt(),
                notification.getCreatedAt()
        );
    }
}
