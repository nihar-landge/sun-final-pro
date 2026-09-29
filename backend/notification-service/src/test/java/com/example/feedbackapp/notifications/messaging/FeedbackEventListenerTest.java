package com.example.feedbackapp.notifications.messaging;

import com.example.feedbackapp.common.event.FeedbackEvent;
import com.example.feedbackapp.notifications.push.FcmSender;
import com.example.feedbackapp.notifications.service.NotificationService;
import com.example.feedbackapp.notifications.web.NotificationStore;
import com.example.feedbackapp.notifications.web.TokenRegistryService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FeedbackEventListenerTest {

    @Mock
    private NotificationStore store;
    @Mock
    private NotificationService notificationService;
    @Mock
    private TokenRegistryService tokenRegistry;
    @Mock
    private FcmSender fcmSender;

    private ObjectMapper objectMapper;
    private FeedbackEventListener listener;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
        listener = new FeedbackEventListener(store, notificationService, tokenRegistry, fcmSender, objectMapper);
    }

    private String payload(FeedbackEvent event) throws Exception {
        return objectMapper.writeValueAsString(event);
    }

    private FeedbackEvent statusChanged() {
        return new FeedbackEvent(FeedbackEvent.STATUS_CHANGED, 7L, 2L, "Street light broken",
                "INFRASTRUCTURE", "SUBMITTED", "RESOLVED", Instant.parse("2026-09-01T10:00:00Z"));
    }

    @Test
    @DisplayName("unparseable payload is dropped without touching any collaborator")
    void poisonPayloadDropped() {
        assertThatCode(() -> listener.onEvent("{not-json")).doesNotThrowAnyException();
        verifyNoInteractions(store, notificationService, tokenRegistry, fcmSender);
    }

    @Test
    @DisplayName("inbox persistence failures propagate so the container retries")
    void createFailurePropagates() throws Exception {
        org.mockito.Mockito.doThrow(new RuntimeException("db down"))
                .when(notificationService).create(eq(2L), eq("REPORT_STATUS"), anyString(), anyString(), eq(7L));

        assertThatThrownBy(() -> listener.onEvent(payload(statusChanged())))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("db down");
    }

    @Test
    @DisplayName("push failures stay best-effort after the inbox row is created")
    void pushFailureSwallowed() throws Exception {
        when(tokenRegistry.tokenFor(2L)).thenReturn("device-token");
        when(fcmSender.pushToToken(eq("device-token"), anyString(), anyString(), any(Map.class)))
                .thenThrow(new RuntimeException("fcm down"));

        assertThatCode(() -> listener.onEvent(payload(statusChanged()))).doesNotThrowAnyException();
        verify(notificationService).create(2L, "REPORT_STATUS", "Street light broken",
                "Your report has been resolved 🎉", 7L);
    }

    @Test
    @DisplayName("status change without a device token skips push but keeps the inbox row")
    void missingTokenSkipsPush() throws Exception {
        when(tokenRegistry.tokenFor(2L)).thenReturn(null);

        assertThatCode(() -> listener.onEvent(payload(statusChanged()))).doesNotThrowAnyException();
        verify(notificationService).create(eq(2L), eq("REPORT_STATUS"), anyString(), anyString(), eq(7L));
        verify(fcmSender, never()).pushToToken(anyString(), anyString(), anyString(), any(Map.class));
    }

    @Test
    @DisplayName("non status-change events only feed the store")
    void otherEventsOnlyFeedStore() throws Exception {
        FeedbackEvent created = new FeedbackEvent(FeedbackEvent.CREATED, 7L, 2L, "Street light broken",
                "INFRASTRUCTURE", null, null, Instant.parse("2026-09-01T10:00:00Z"));

        listener.onEvent(payload(created));

        verify(store).add(any(FeedbackEvent.class));
        verifyNoInteractions(notificationService, tokenRegistry, fcmSender);
    }
}
