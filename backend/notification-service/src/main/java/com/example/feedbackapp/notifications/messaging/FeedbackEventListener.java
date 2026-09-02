package com.example.feedbackapp.notifications.messaging;

import com.example.feedbackapp.common.event.FeedbackEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

import com.example.feedbackapp.notifications.config.RabbitMqConfig;
import com.example.feedbackapp.notifications.web.NotificationStore;
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
    private final ObjectMapper objectMapper;

    public FeedbackEventListener(NotificationStore store, ObjectMapper objectMapper) {
        this.store = store;
        this.objectMapper = objectMapper;
    }

    @RabbitListener(queues = RabbitMqConfig.NOTIFICATION_QUEUE)
    public void onEvent(@Payload String payload) {
        try {
            FeedbackEvent event = objectMapper.readValue(payload, FeedbackEvent.class);
            store.add(event);
            log.info("Consumed {} for feedback {} ({} -> {})",
                    event.type(), event.feedbackId(), event.oldStatus(), event.newStatus());
        } catch (Exception e) {
            // Never rethrow: a malformed message should not requeue forever.
            log.error("Failed to process event payload: {}", payload, e);
        }
    }
}
