package com.example.feedbackapp.notifications.service;

import com.example.feedbackapp.notifications.client.EmailClient;
import com.example.feedbackapp.notifications.entity.Notification;
import com.example.feedbackapp.notifications.repository.NotificationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Owns the citizen notification inbox (notificationdb). The inbox row is
 * written here; the email is then dispatched best-effort. If the email
 * service is down the row still exists and the in-app inbox still works.
 */
@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository repository;
    private final EmailClient emailClient;

    public NotificationService(NotificationRepository repository, EmailClient emailClient) {
        this.repository = repository;
        this.emailClient = emailClient;
    }

    /** Creates the inbox row and then tries the email (failure = log only). */
    @Transactional
    public void createReportStatusNotification(ReportStatusEvent event) {
        String title = "Report update: " + event.reportTitle();
        String body = "Status changed from %s to %s".formatted(event.oldStatus(), event.newStatus());
        repository.save(new Notification(event.userId(), "REPORT_STATUS", title, body, event.reportId()));
        log.info("Inbox row saved for user {} (report {})", event.userId(), event.reportId());

        if (event.email() != null && !event.email().isBlank()) {
            try {
                emailClient.sendReportStatusEmail(new EmailClient.ReportStatusEmail(
                        event.email(), event.name(), event.reportId(),
                        event.reportTitle(), event.oldStatus(), event.newStatus()));
            } catch (Exception e) {
                // The inbox row is already saved; email is best-effort only.
                log.warn("Email dispatch threw for report {} — continuing: {}",
                        event.reportId(), e.getMessage());
            }
        }
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
        Notification notification = repository.findById(notificationId)
                .filter(n -> n.getUserId().equals(userId))
                .orElseThrow(() -> new com.example.feedbackapp.common.error.NotFoundException(
                        "Notification %d not found".formatted(notificationId)));
        notification.markRead();
    }

    @Transactional
    public int markAllRead(Long userId) {
        List<Notification> unread = repository.findTop50ByUserIdOrderByCreatedAtDesc(userId).stream()
                .filter(Notification::isUnread)
                .toList();
        unread.forEach(Notification::markRead);
        return unread.size();
    }

    /** The one internal event the feedback service reports. */
    public record ReportStatusEvent(Long userId, String email, String name, Long reportId,
                                    String reportTitle, String oldStatus, String newStatus) {
    }
}
