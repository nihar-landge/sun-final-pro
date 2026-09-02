package com.example.feedbackapp.notifications.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Declares the same topology as the publishing services so the queue exists
 * regardless of which service boots first.
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
