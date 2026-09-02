package com.example.feedbackapp.feedback.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Event bus topology: a topic exchange plus the notification queue. Declared
 * here too so the queue exists even if notification-service starts later.
 */
@Configuration
public class RabbitMqConfig {

    public static final String EXCHANGE = "feedbackapp.events";
    public static final String NOTIFICATION_QUEUE = "notifications.feedback";

    @Bean
    public TopicExchange eventsExchange() {
        return new TopicExchange(EXCHANGE, true, false);
    }

    @Bean
    public Queue notificationQueue() {
        return new Queue(NOTIFICATION_QUEUE, true);
    }

    @Bean
    public Binding notificationBinding(Queue notificationQueue, TopicExchange eventsExchange) {
        return BindingBuilder.bind(notificationQueue).to(eventsExchange).with("feedback.*");
    }
}
