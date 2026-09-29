package com.example.feedbackapp.notifications.messaging;

import com.example.feedbackapp.common.event.FeedbackEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

import java.util.Map;

import com.example.feedbackapp.notifications.config.RabbitMqConfig;
import com.example.feedbackapp.notifications.push.FcmSender;
import com.example.feedbackapp.notifications.service.NotificationService;
import com.example.feedbackapp.notifications.web.NotificationStore;
import com.example.feedbackapp.notifications.web.TokenRegistryService;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Consumes feedback domain events from the notifications queue. Payloads are
 * JSON strings (published with ObjectMapper) and are parsed back into the
 * shared FeedbackEvent contract.
 */
@Component
public class FeedbackEventListener {

    private static final Logger log = LoggerFactory.getLogger(FeedbackEventListener.class);

    private final NotificationStore store;
    private final NotificationService notificationService;
    private final TokenRegistryService tokenRegistry;
    private final FcmSender fcmSender;
    private final ObjectMapper objectMapper;

    public FeedbackEventListener(NotificationStore store,
                                 NotificationService notificationService,
                                 TokenRegistryService tokenRegistry,
                                 FcmSender fcmSender,
                                 ObjectMapper objectMapper) {
        this.store = store;
        this.notificationService = notificationService;
        this.tokenRegistry = tokenRegistry;
        this.fcmSender = fcmSender;
        this.objectMapper = objectMapper;
    }

    @RabbitListener(queues = RabbitMqConfig.NOTIFICATION_QUEUE)
    public void onEvent(@Payload String payload) {
        FeedbackEvent event;
        try {
            event = objectMapper.readValue(payload, FeedbackEvent.class);
        } catch (Exception e) {
            // Poison payload: retrying can never succeed, so drop it instead
            // of letting the container requeue forever.
            log.error("Dropping unparseable event payload: {}", payload, e);
            return;
        }

        store.add(event);
        log.info("Consumed {} for feedback {} ({} -> {})",
                event.type(), event.feedbackId(), event.oldStatus(), event.newStatus());

        if (!FeedbackEvent.STATUS_CHANGED.equals(event.type()) || event.newStatus() == null) {
            return;
        }

        String body = switch (event.newStatus()) {
            case "RESOLVED" -> "Your report has been resolved 🎉";
            case "IN_REVIEW" -> "Your report is now being reviewed";
            default -> "Your report status changed to " + event.newStatus();
        };

        // Persist into the inbox first. A failure here propagates to the
        // container so the whole event is retried (the transaction rolled
        // back, so nothing was written twice).
        notificationService.create(event.userId(), "REPORT_STATUS",
                event.title(), body, event.feedbackId());

        // Push is best-effort: create() above already committed, so retrying
        // the event for a push failure would duplicate the inbox row.
        try {
            String token = tokenRegistry.tokenFor(event.userId());
            if (token != null) {
                fcmSender.pushToToken(token, event.title(), body, Map.of(
                        "reportId", String.valueOf(event.feedbackId()),
                        "newStatus", event.newStatus()));
            } else {
                log.debug("No device token for user {} — push skipped", event.userId());
            }
        } catch (Exception e) {
            log.warn("Push failed for notification of feedback {} — inbox entry kept",
                    event.feedbackId(), e);
        }
    }
}
