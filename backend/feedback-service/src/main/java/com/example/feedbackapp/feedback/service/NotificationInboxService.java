package com.example.feedbackapp.feedback.service;

import com.example.feedbackapp.common.error.ValidationFailedException;
import com.example.feedbackapp.feedback.entity.DeviceToken;
import com.example.feedbackapp.feedback.entity.Notification;
import com.example.feedbackapp.feedback.repository.DeviceTokenRepository;
import com.example.feedbackapp.feedback.repository.NotificationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * The citizen's notification inbox. Rows are created in the SAME transaction
 * as the status change that caused them — no broker, no lost notifications.
 */
@Service
public class NotificationInboxService {

    private final NotificationRepository repository;
    private final DeviceTokenRepository deviceTokenRepository;

    public NotificationInboxService(NotificationRepository repository,
                                    DeviceTokenRepository deviceTokenRepository) {
        this.repository = repository;
        this.deviceTokenRepository = deviceTokenRepository;
    }

    @Transactional
    public void registerToken(Long userId, String token) {
        if (token == null || token.isBlank()) {
            throw new ValidationFailedException("Device token must not be empty");
        }
        deviceTokenRepository.save(new com.example.feedbackapp.feedback.entity.DeviceToken(userId, token));
    }

    @Transactional
    public void create(Long userId, String type, String title, String body, Long refId) {
        repository.save(new Notification(userId, type, title, body, refId));
    }

    @Transactional(readOnly = true)
    public List<Notification> inbox(Long userId) {
        return repository.findTop50ByUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional(readOnly = true)
    public long unreadCount(Long userId) {
        return repository.countByUserIdAndReadAtIsNull(userId);
    }

    @Transactional
    public void markRead(Long notificationId, Long userId) {
        repository.findById(notificationId)
                .filter(n -> n.getUserId().equals(userId))
                .orElseThrow(() -> new com.example.feedbackapp.common.error.NotFoundException(
                        "Notification %d not found".formatted(notificationId)))
                .markRead();
    }

    @Transactional
    public int markAllRead(Long userId) {
        List<Notification> unread = repository.findTop50ByUserIdOrderByCreatedAtDesc(userId)
                .stream().filter(Notification::isUnread).toList();
        unread.forEach(Notification::markRead);
        return unread.size();
    }
}
