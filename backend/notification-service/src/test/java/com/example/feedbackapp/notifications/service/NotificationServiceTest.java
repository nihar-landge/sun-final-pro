package com.example.feedbackapp.notifications.service;

import com.example.feedbackapp.common.error.NotFoundException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.notifications.entity.Notification;
import com.example.feedbackapp.notifications.repository.NotificationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private NotificationRepository repository;

    private NotificationService service;

    private static final GatewayUser USER = new GatewayUser(2L, "CITIZEN", "Nihar");
    private static final GatewayUser OTHER = new GatewayUser(9L, "CITIZEN", "Someone else");

    @BeforeEach
    void setUp() {
        service = new NotificationService(repository);
    }

    private Notification notification(long id, Long userId, boolean unread) {
        Notification n = new Notification(userId, "REPORT_STATUS", "Title", "Body", 7L);
        org.springframework.test.util.ReflectionTestUtils.setField(n, "id", id);
        if (!unread) {
            n.markRead();
        }
        return n;
    }

    @Test
    @DisplayName("create persists an inbox row")
    void create() {
        service.create(2L, "REPORT_STATUS", "T", "B", 7L);
        verify(repository).save(any(Notification.class));
    }

    @Test
    @DisplayName("owner can mark read")
    void markReadOwner() {
        when(repository.findById(5L)).thenReturn(Optional.of(notification(5, 2L, true)));
        Notification n = service.markRead(5L, USER);
        assertThat(n.isUnread()).isFalse();
    }

    @Test
    @DisplayName("a different user gets 404 for someone else's notification")
    void markReadForeign() {
        when(repository.findById(5L)).thenReturn(Optional.of(notification(5, 2L, true)));
        assertThatThrownBy(() -> service.markRead(5L, OTHER))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    @DisplayName("markAllRead delegates to the bulk update covering every unread row")
    void markAllRead() {
        when(repository.markAllRead(eq(2L), any(LocalDateTime.class))).thenReturn(3);
        assertThat(service.markAllRead(USER)).isEqualTo(3);
    }
}
