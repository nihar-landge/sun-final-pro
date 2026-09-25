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
    private final TokenRegistryService tokenRegistry;
    private final FcmSender fcmSender;
    private final ObjectMapper objectMapper;

    public FeedbackEventListener(NotificationStore store,
                                 TokenRegistryService tokenRegistry,
                                 FcmSender fcmSender,
                                 ObjectMapper objectMapper) {
        this.store = store;
        this.tokenRegistry = tokenRegistry;
        this.fcmSender = fcmSender;
        this.objectMapper = objectMapper;
    }

    @RabbitListener(queues = RabbitMqConfig.NOTIFICATION_QUEUE)
    public void onEvent(@Payload String payload) {
        try {
            FeedbackEvent event = objectMapper.readValue(payload, FeedbackEvent.class);
            store.add(event);
            log.info("Consumed {} for feedback {} ({} -> {})",
                    event.type(), event.feedbackId(), event.oldStatus(), event.newStatus());

            // Push the report's author when staff touches their report.
            if (FeedbackEvent.STATUS_CHANGED.equals(event.type()) && event.newStatus() != null) {
                String token = tokenRegistry.tokenFor(event.userId());
                if (token != null) {
                    String body = switch (event.newStatus()) {
                        case "RESOLVED" -> "Your report has been resolved 🎉";
                        case "IN_REVIEW" -> "Your report is now being reviewed";
                        default -> "Your report status changed to " + event.newStatus();
                    };
                    fcmSender.pushToToken(token, event.title(), body, Map.of(
                            "reportId", String.valueOf(event.feedbackId()),
                            "newStatus", event.newStatus()));
                } else {
                    log.debug("No device token for user {} — push skipped", event.userId());
                }
            }
        } catch (Exception e) {
            // Never rethrow: a malformed message should not requeue forever.
            log.error("Failed to process event payload: {}", payload, e);
        }
    }
}
