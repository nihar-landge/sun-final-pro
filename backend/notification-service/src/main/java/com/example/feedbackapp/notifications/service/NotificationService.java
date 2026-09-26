package com.example.feedbackapp.notifications.service;

import com.example.feedbackapp.common.error.NotFoundException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.notifications.entity.Notification;
import com.example.feedbackapp.notifications.repository.NotificationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * The citizen's persistent inbox: created by consumed events, read state
 * managed here. Every query is scoped to the caller — a user can never
 * touch another user's notifications.
 */
@Service
public class NotificationService {

    private final NotificationRepository repository;

    public NotificationService(NotificationRepository repository) {
        this.repository = repository;
    }

    /** Called by the event consumer for every notification-worthy event. */
    @Transactional
    public void create(Long userId, String type, String title, String body, Long refId) {
        repository.save(new Notification(userId, type, title, body, refId));
    }

    @Transactional(readOnly = true)
    public List<Notification> inbox(GatewayUser user) {
        return repository.findTop50ByUserIdOrderByCreatedAtDesc(user.id());
    }

    @Transactional(readOnly = true)
    public long unreadCount(GatewayUser user) {
        return repository.countByUserIdAndReadAtIsNull(user.id());
    }

    @Transactional
    public Notification markRead(Long notificationId, GatewayUser user) {
        Notification notification = repository.findById(notificationId)
                .filter(n -> n.getUserId().equals(user.id()))
                .orElseThrow(() -> new NotFoundException(
                        "Notification %d not found".formatted(notificationId)));
        notification.markRead();
        return notification;
    }

    @Transactional
    public int markAllRead(GatewayUser user) {
        List<Notification> unread = repository.findTop50ByUserIdOrderByCreatedAtDesc(user.id())
                .stream().filter(Notification::isUnread).toList();
        unread.forEach(Notification::markRead);
        return unread.size();
    }
}
